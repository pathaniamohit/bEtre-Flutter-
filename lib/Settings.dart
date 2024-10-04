import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';

import 'EditProfile.dart';
import 'About.dart';
import 'AccountPreferences.dart';

class SettingsScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  final Reference _storage = FirebaseStorage.instance.ref().child('profile_pictures');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context, 'Settings'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSettingsOption(
              context,
              title: "Edit Profile",
              icon: Icons.edit,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditProfileScreen()),
                );
              },
            ),
            const Divider(),
            _buildSettingsOption(
              context,
              title: "Account and Privacy",
              icon: Icons.security,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PrivacyScreen()),
                );
              },
            ),
            const Divider(),
            _buildSettingsOption(
              context,
              title: "About",
              icon: Icons.info,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AboutScreen()),
                );
              },
            ),
            const Divider(),
            _buildSettingsOption(
              context,
              title: "Logout",
              icon: Icons.logout,
              onTap: () {
                _showLogoutDialog(context);
              },
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, String title) {
    return AppBar(
      centerTitle: true,
      title: Text(
        title,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildSettingsOption(BuildContext context, {required String title, required IconData icon, required Function() onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () => onTap(),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("No"),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                _auth.signOut();
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }
}
