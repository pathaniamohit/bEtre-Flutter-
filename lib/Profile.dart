import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.reference();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? _user;
  String? _profileImageUrl;
  String _username = "Username";
  String _email = "Email";
  int _photosCount = 0;
  int _followersCount = 0;
  int _followsCount = 0;

  List<String> _posts = [];
  File? _image;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    if (_user != null) {
      _loadUserProfile();
      _loadUserStats();
      _loadUserPosts();
    }
  }

  Future<void> _loadUserProfile() async {
    if (_user != null) {
      _dbRef.child("users").child(_user!.uid).once().then((snapshot) {
        if (snapshot.snapshot.exists) {
          var userData = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
          setState(() {
            _username = userData['username'] ?? 'Username';
            _email = userData['email'] ?? 'Email';
            _profileImageUrl = userData['profileImageUrl'];
          });
        }
      });
    }
  }

  Future<void> _loadUserStats() async {
    if (_user != null) {
      // Load followers count
      _dbRef.child("followers").child(_user!.uid).onValue.listen((event) {
        final dataSnapshot = event.snapshot;
        if (dataSnapshot.exists) {
          int count = dataSnapshot.children.length;
          setState(() {
            _followersCount = count;
          });
        } else {
          setState(() {
            _followersCount = 0;
          });
        }
      });

      // Load follows count
      _dbRef.child("following").child(_user!.uid).onValue.listen((event) {
        final dataSnapshot = event.snapshot;
        if (dataSnapshot.exists) {
          int count = dataSnapshot.children.length;
          setState(() {
            _followsCount = count;
          });
        } else {
          setState(() {
            _followsCount = 0;
          });
        }
      });

      // Load photos count
      _dbRef.child("posts").orderByChild("userId").equalTo(_user!.uid).onValue.listen((event) {
        final dataSnapshot = event.snapshot;
        if (dataSnapshot.exists) {
          int count = dataSnapshot.children.length;
          setState(() {
            _photosCount = count;
          });
        } else {
          setState(() {
            _photosCount = 0;
          });
        }
      });
    }
  }

  Future<void> _loadUserPosts() async {
    if (_user != null) {
      _dbRef.child("posts").orderByChild("userId").equalTo(_user!.uid).onValue.listen((event) {
        List<String> posts = [];
        for (var post in event.snapshot.children) {
          var postData = post.value as Map;
          if (postData['imageUrl'] != null) {
            posts.add(postData['imageUrl']);
          }
        }
        setState(() {
          _posts = posts;
        });
      });
    }
  }

  Future<void> _uploadProfileImage(File image) async {
    if (_user != null) {
      try {
        String path = 'users/${_user!.uid}/profile.jpg';
        TaskSnapshot uploadTask = await _storage.ref(path).putFile(image);
        String downloadUrl = await uploadTask.ref.getDownloadURL();

        _dbRef.child("users").child(_user!.uid).update({
          "profileImageUrl": downloadUrl,
        });

        setState(() {
          _profileImageUrl = downloadUrl;
        });

        // Show a success toast
        Fluttertoast.showToast(msg: "Profile image updated successfully", gravity: ToastGravity.BOTTOM);
      } catch (e) {
        // Show a failure toast
        Fluttertoast.showToast(msg: "Failed to upload profile image: $e", gravity: ToastGravity.BOTTOM);
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
      _uploadProfileImage(_image!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'My Profile',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: Icon(Icons.settings),
                      onPressed: () {
                        // Navigate to Settings
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Profile Picture and Info Section
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profileImageUrl != null
                    ? NetworkImage(_profileImageUrl!)
                    : AssetImage('assets/profile_placeholder.png') as ImageProvider,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(Icons.camera_alt, size: 24, color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              _username,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              _email,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),

            // Stats Section (Photos, Followers, Follows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('Photos', _photosCount.toString()),
                  _buildStatItem('Followers', _followersCount.toString()),
                  _buildStatItem('Follows', _followsCount.toString()),
                ],
              ),
            ),

            // User Posts Grid
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                physics: NeverScrollableScrollPhysics(), // Disable scrolling in grid view
                shrinkWrap: true, // Wraps grid view inside SingleChildScrollView
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 3 items per row
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _posts.length, // Number of images
                itemBuilder: (context, index) {
                  return Image.network(_posts[index], fit: BoxFit.cover);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to display stats (Photos, Followers, Follows)
  Widget _buildStatItem(String label, String count) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(color: Colors.grey)),
        SizedBox(height: 4),
        Text(count, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
