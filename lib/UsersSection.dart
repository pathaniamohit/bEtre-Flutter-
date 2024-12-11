import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'UserAnalytics.dart';

class UsersSection extends StatefulWidget {
  final DatabaseReference dbRef;

  UsersSection({required this.dbRef});

  @override
  _UsersSectionState createState() => _UsersSectionState();
}

class _UsersSectionState extends State<UsersSection> {
  String _searchQuery = "";
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    _checkUserRole();
  }

  // Initialize Firebase
  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
  }

  // Check if the logged-in user is an admin
  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userSnapshot = await widget.dbRef.child('users').child(user.uid).get();
      if (userSnapshot.exists) {
        final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
        setState(() {
          _isAdmin = userData['role'] == 'admin';
        });
      }
    }
  }

  // Toggle suspension status by updating the user's role
  Future<void> toggleSuspension(String userId, bool isSuspended) async {
    try {
      final newRole = isSuspended ? 'user' : 'suspended';
      await widget.dbRef.child('users').child(userId).update({'role': newRole});
      Fluttertoast.showToast(
          msg: isSuspended ? 'User unsuspended' : 'User suspended',
          gravity: ToastGravity.BOTTOM);
    } catch (e) {
      Fluttertoast.showToast(
          msg: 'Error updating suspension: $e',
          gravity: ToastGravity.BOTTOM);
    }
  }

  // Delete a user
  Future<void> deleteUser(String userId) async {
    bool confirm = await _showDeleteConfirmationDialog();
    if (!confirm) return;

    try {
      await widget.dbRef.child('users').child(userId).remove();

      // Delete user posts, followers, and following data
      await widget.dbRef.child('posts').orderByChild('userId').equalTo(userId).get().then((snapshot) {
        for (var post in snapshot.children) {
          widget.dbRef.child('posts').child(post.key!).remove();
        }
      });
      await widget.dbRef.child('followers').child(userId).remove();
      await widget.dbRef.child('following').child(userId).remove();

      // Delete user from Firebase Auth via Cloud Function
      await _deleteUserAuth(userId);

      Fluttertoast.showToast(msg: "User deleted successfully", gravity: ToastGravity.BOTTOM);
    } catch (e) {
      Fluttertoast.showToast(msg: "Error deleting user: $e", gravity: ToastGravity.BOTTOM);
    }
  }

  // Call Cloud Function to delete user from Firebase Auth
  Future<void> _deleteUserAuth(String userId) async {
    try {
      HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('deleteUserAuth');
      await callable.call({'uid': userId});
      Fluttertoast.showToast(msg: "User removed from Auth", gravity: ToastGravity.BOTTOM);
    } catch (e) {
      Fluttertoast.showToast(msg: "Error deleting user from Auth: $e", gravity: ToastGravity.BOTTOM);
    }
  }

  // Show delete confirmation dialog
  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete User'),
          content: Text('Are you sure you want to delete this user? This action cannot be undone.'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false); // Return false
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(true); // Return true
              },
            ),
          ],
        );
      },
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              labelText: "Search by username or email",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: widget.dbRef.child('users').onValue,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                return Center(child: Text("No users available."));
              }

              final data = Map<String, dynamic>.from((snapshot.data! as DatabaseEvent).snapshot.value as Map);
              final filteredData = data.entries.where((entry) {
                final userData = Map<String, dynamic>.from(entry.value);
                final username = userData['username']?.toLowerCase() ?? '';
                final email = userData['email']?.toLowerCase() ?? '';
                return username.contains(_searchQuery) || email.contains(_searchQuery);
              }).toList();

              if (filteredData.isEmpty) {
                return Center(child: Text("No users match your search."));
              }

              return ListView(
                children: filteredData.map((entry) {
                  final userData = Map<String, dynamic>.from(entry.value);
                  final isOnline = userData['isOnline'] == true;
                  final isSuspended = userData['role'] == 'suspended';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isOnline ? Colors.green : Colors.grey,
                      radius: 6,
                    ),
                    title: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserAnalytics(userId: entry.key),
                          ),
                        );
                      },
                      child: Text(
                        userData['username'] ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    subtitle: Text(userData['email'] ?? 'No email'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            isSuspended ? Icons.lock : Icons.lock_open,
                            color: isSuspended ? Colors.red : Colors.green,
                          ),
                          tooltip: isSuspended ? 'Unsuspend User' : 'Suspend User',
                          onPressed: () => toggleSuspension(entry.key, isSuspended),
                        ),
                        if (_isAdmin)
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete User',
                            onPressed: () => deleteUser(entry.key),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}
