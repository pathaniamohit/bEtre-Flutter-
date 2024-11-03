import 'dart:async';
import 'dart:io';
import 'package:betreflutter/CommentScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'PostDetailScreen.dart';
import 'Settings.dart';

class ProfileAdmin extends StatefulWidget {
  final DatabaseReference dbRef;

  ProfileAdmin({Key? key, required this.dbRef}) : super(key: key);

  @override
  _ProfileAdminState createState() => _ProfileAdminState();
}

class _ProfileAdminState extends State<ProfileAdmin> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? _user;
  String? _profileImageUrl;
  String _username = "Username";
  String _email = "Email";
  int _photosCount = 0;
  int _followersCount = 0;
  int _followsCount = 0;

  List<Map<String, dynamic>> _posts = [];
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
      widget.dbRef.child("users").child(_user!.uid).once().then((snapshot) {
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
      widget.dbRef.child("followers").child(_user!.uid).onValue.listen((event) {
        final dataSnapshot = event.snapshot;
        setState(() {
          _followersCount = dataSnapshot.exists ? dataSnapshot.children.length : 0;
        });
      });

      widget.dbRef.child("following").child(_user!.uid).onValue.listen((event) {
        final dataSnapshot = event.snapshot;
        setState(() {
          _followsCount = dataSnapshot.exists ? dataSnapshot.children.length : 0;
        });
      });

      widget.dbRef.child("posts").orderByChild("userId").equalTo(_user!.uid).onValue.listen((event) {
        final dataSnapshot = event.snapshot;
        setState(() {
          _photosCount = dataSnapshot.exists ? dataSnapshot.children.length : 0;
        });
      });
    }
  }

  Future<void> _loadUserPosts() async {
    if (_user != null) {
      widget.dbRef
          .child("posts")
          .orderByChild("userId")
          .equalTo(_user!.uid)
          .onValue
          .listen((event) {
        List<Map<String, dynamic>> posts = [];
        for (var post in event.snapshot.children) {
          var postData = Map<String, dynamic>.from(post.value as Map);
          postData['postId'] = post.key;
          posts.add(postData);
        }
        setState(() {
          _posts = posts.reversed.toList();
        });
      });
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

  Future<void> _uploadProfileImage(File image) async {
    if (_user != null) {
      try {
        String path = 'users/${_user!.uid}/profile.jpg';
        TaskSnapshot uploadTask = await _storage.ref(path).putFile(image);
        String downloadUrl = await uploadTask.ref.getDownloadURL();

        widget.dbRef.child("users").child(_user!.uid).update({
          "profileImageUrl": downloadUrl,
        });

        setState(() {
          _profileImageUrl = downloadUrl;
        });

        Fluttertoast.showToast(msg: "Profile image updated successfully", gravity: ToastGravity.BOTTOM);
      } catch (e) {
        Fluttertoast.showToast(msg: "Failed to upload profile image: $e", gravity: ToastGravity.BOTTOM);
      }
    }
  }

  Future<void> _onPostTripleTap(String postId) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Post'),
          content: Text('Are you sure you want to delete this post?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deletePost(postId);
                Navigator.pop(context);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePost(String postId) async {
    if (_user != null) {
      await widget.dbRef.child("posts").child(postId).remove();
      Fluttertoast.showToast(msg: "Post deleted successfully", gravity: ToastGravity.BOTTOM);
      _loadUserPosts();
    }
  }

  Future<void> _onPostDoubleTap(String postId, String currentContent) async {
    TextEditingController _contentController = TextEditingController(text: currentContent);
    File? selectedImage;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Post'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _contentController,
                decoration: InputDecoration(labelText: 'Edit Content'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final ImagePicker _picker = ImagePicker();
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    selectedImage = File(image.path);
                    Fluttertoast.showToast(msg: "New image selected", gravity: ToastGravity.BOTTOM);
                  }
                },
                child: Text("Change Image"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _updatePost(postId, _contentController.text.trim(), selectedImage);
                Navigator.pop(context);
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updatePost(String postId, String newContent, File? newImage) async {
    if (_user != null) {
      Map<String, dynamic> updatedData = {"content": newContent};

      try {
        if (newImage != null) {
          String path = 'post_images/$postId.jpg';
          TaskSnapshot uploadTask = await _storage.ref(path).putFile(newImage);
          String downloadUrl = await uploadTask.ref.getDownloadURL();
          updatedData['imageUrl'] = downloadUrl;
        }

        await widget.dbRef.child("posts").child(postId).update(updatedData);
        Fluttertoast.showToast(msg: "Post updated successfully", gravity: ToastGravity.BOTTOM);
        _loadUserPosts();
      } catch (e) {
        Fluttertoast.showToast(msg: "Failed to update post: $e", gravity: ToastGravity.BOTTOM);
      }
    }
  }

  void _viewPostDetails(Map<String, dynamic> post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PostDetailScreen(post: post, currentUser: _user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text('My Profile', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      iconSize: 36,
                      icon: Icon(Icons.settings),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen()));
                      },
                    ),
                  ),
                ],
              ),
            ),
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
            Text(_username, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(_email, style: TextStyle(fontSize: 16, color: Colors.grey)),
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
            GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final post = _posts[index];
                return GestureDetector(
                  onTap: () => _viewPostDetails(post),
                  onDoubleTap: () => _onPostDoubleTap(post['postId'], post['content']),
                  onLongPress: () => _onPostTripleTap(post['postId']),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(post['imageUrl'], fit: BoxFit.cover),
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Row(
                          children: [
                            Icon(Icons.favorite, color: Colors.redAccent, size: 16),
                            SizedBox(width: 2),
                            Text('${post['likesCount']}', style: TextStyle(color: Colors.white, fontSize: 12)),
                            SizedBox(width: 8),
                            Icon(Icons.comment, color: Colors.white, size: 16),
                            SizedBox(width: 2),
                            Text('${post['commentsCount']}', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String count) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}
