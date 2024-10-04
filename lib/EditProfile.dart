import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.reference();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? _user;
  String? _profileImageUrl;
  String _username = "Username";
  String _email = "Email";
  String _phone = "Phone Number";
  File? _image;
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    if (_user != null) {
      _loadUserProfile();
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
            _phone = userData['phone'] ?? 'Phone Number';
          });
          _usernameController.text = _username;
          _phoneController.text = _phone;
        }
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

        _dbRef.child("users").child(_user!.uid).update({
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

  Future<void> _updateUserProfile() async {
    if (_user != null) {
      String newUsername = _usernameController.text.trim();
      String newPhone = _phoneController.text.trim();

      if (newUsername.isEmpty || newUsername.length < 3) {
        Fluttertoast.showToast(msg: "Username must be at least 3 characters long");
        return;
      }

      if (newPhone.isEmpty || newPhone.length != 10) {
        Fluttertoast.showToast(msg: "Phone number must be 10 digits");
        return;
      }

      _dbRef.child("users").child(_user!.uid).update({
        "username": newUsername,
        "phone": newPhone,
      }).then((_) {
        Fluttertoast.showToast(msg: "Profile updated successfully", gravity: ToastGravity.BOTTOM);
      }).catchError((error) {
        Fluttertoast.showToast(msg: "Failed to update profile: $error", gravity: ToastGravity.BOTTOM);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'RobotoSerif',
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
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
                'Change Picture',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'RobotoSerif'),
              ),
              SizedBox(height: 16),
              _buildInputField("Username", _usernameController),
              SizedBox(height: 16),
              _buildInputField("E-mail Address", TextEditingController(text: _email), isReadOnly: true),
              SizedBox(height: 16),
              _buildInputField("Phone Number", _phoneController),
              SizedBox(height: 24),
              _buildActionButton("Change Password", _showChangePasswordDialog),
              SizedBox(height: 12),
              _buildActionButton("Save Changes", _updateUserProfile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {bool isReadOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'RobotoSerif'),
        ),
        SizedBox(height: 5),
        SizedBox(
          width: double.infinity,
          child: TextField(
            controller: controller,
            readOnly: isReadOnly,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: EdgeInsets.symmetric(vertical: 15),
        ),
        child: Text(label, style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }
}
