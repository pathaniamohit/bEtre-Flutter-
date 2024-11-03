// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
//
// class UsersSection extends StatefulWidget {
//   final DatabaseReference dbRef;
//
//   UsersSection({required this.dbRef});
//
//   @override
//   _UsersSectionState createState() => _UsersSectionState();
// }
//
// class _UsersSectionState extends State<UsersSection> {
//   String _searchQuery = "";
//
//   Future<void> toggleSuspension(String userId, bool suspended) async {
//     try {
//       await widget.dbRef.child('users').child(userId).update({'suspended': suspended});
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(suspended ? 'User suspended' : 'User unsuspended')));
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating suspension: $e')));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: TextField(
//             decoration: InputDecoration(
//               labelText: "Search by username or email",
//               prefixIcon: Icon(Icons.search),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             onChanged: (value) {
//               setState(() {
//                 _searchQuery = value.toLowerCase();
//               });
//             },
//           ),
//         ),
//         Expanded(
//           child: StreamBuilder(
//             stream: widget.dbRef.child('users').onValue,
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return Center(child: CircularProgressIndicator());
//               }
//
//               if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
//                 return Center(child: Text("No users available."));
//               }
//
//               final data = Map<String, dynamic>.from((snapshot.data! as DatabaseEvent).snapshot.value as Map);
//
//               final filteredData = data.entries.where((entry) {
//                 final userData = Map<String, dynamic>.from(entry.value);
//                 final username = userData['username']?.toLowerCase() ?? '';
//                 final email = userData['email']?.toLowerCase() ?? '';
//                 return username.contains(_searchQuery) || email.contains(_searchQuery);
//               }).toList();
//
//               if (filteredData.isEmpty) {
//                 return Center(child: Text("No users match your search."));
//               }
//
//               return ListView(
//                 children: filteredData.map((entry) {
//                   final userData = Map<String, dynamic>.from(entry.value);
//                   return ListTile(
//                     title: Text(userData['username'] ?? 'Unknown'),
//                     subtitle: Text(userData['email'] ?? 'No email'),
//                     trailing: IconButton(
//                       icon: Icon(userData['suspended'] == true ? Icons.lock : Icons.lock_open),
//                       onPressed: () => toggleSuspension(entry.key, userData['suspended'] != true),
//                     ),
//                   );
//                 }).toList(),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core

class UsersSection extends StatefulWidget {
  final DatabaseReference dbRef;

  UsersSection({required this.dbRef});

  @override
  _UsersSectionState createState() => _UsersSectionState();
}

class _UsersSectionState extends State<UsersSection> {
  String _searchQuery = "";
  bool _isAdmin = false; // Track if current user is admin

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    _checkAdminPrivileges(); // Check if current user is admin
  }

  // Initialize Firebase
  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
  }

  // Function to check if current user is admin
  Future<void> _checkAdminPrivileges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Force token refresh to get latest claims
      await user.getIdToken(true);
      final idTokenResult = await user.getIdTokenResult();
      setState(() {
        _isAdmin = idTokenResult.claims?['admin'] ?? false;
      });
    }
  }

  // Function to toggle suspension status
  Future<void> toggleSuspension(String userId, bool suspended) async {
    try {
      await widget.dbRef.child('users').child(userId).update({'suspended': suspended});
      Fluttertoast.showToast(
          msg: suspended ? 'User suspended' : 'User unsuspended',
          gravity: ToastGravity.BOTTOM);
    } catch (e) {
      Fluttertoast.showToast(
          msg: 'Error updating suspension: $e',
          gravity: ToastGravity.BOTTOM);
    }
  }

  // Function to delete a user
  Future<void> deleteUser(String userId) async {
    bool confirm = await _showDeleteConfirmationDialog();
    if (!confirm) return;

    setState(() {
      // Optional: Show a loading indicator or disable UI interactions
    });

    try {
      // 1. Delete user data from 'users' node
      await widget.dbRef.child('users').child(userId).remove();

      // 2. Delete user posts
      DataSnapshot postsSnapshot = await widget.dbRef
          .child('posts')
          .orderByChild('userId')
          .equalTo(userId)
          .get();
      if (postsSnapshot.exists) {
        for (var post in postsSnapshot.children) {
          await widget.dbRef.child('posts').child(post.key!).remove();
        }
      }

      // 3. Delete followers
      await widget.dbRef.child('followers').child(userId).remove();

      // 4. Delete following
      await widget.dbRef.child('following').child(userId).remove();

      // 5. Delete user from Firebase Auth via Cloud Function
      await _deleteUserAuth(userId);

      Fluttertoast.showToast(
          msg: "User deleted successfully",
          gravity: ToastGravity.BOTTOM);

    } catch (e) {
      Fluttertoast.showToast(
          msg: "Error deleting user: $e",
          gravity: ToastGravity.BOTTOM);
    } finally {
      setState(() {
        // Optional: Hide the loading indicator or re-enable UI interactions
      });
    }
  }

  // Function to call Cloud Function to delete user from Firebase Auth
  Future<void> _deleteUserAuth(String userId) async {
    try {
      HttpsCallable callable =
      FirebaseFunctions.instance.httpsCallable('deleteUserAuth');
      final response = await callable.call({'uid': userId});
      Fluttertoast.showToast(
          msg: response.data['message'],
          gravity: ToastGravity.BOTTOM);
    } catch (e) {
      Fluttertoast.showToast(
          msg: "Error deleting user from Auth: $e",
          gravity: ToastGravity.BOTTOM);
      throw e; // Re-throw to handle in deleteUser()
    }
  }

  // Show delete confirmation dialog
  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete User'),
          content: Text(
              'Are you sure you want to delete this user? This action cannot be undone.'),
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
        false; // Return false if dialog is dismissed
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
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
        // Users List
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

              final data = Map<String, dynamic>.from(
                  (snapshot.data! as DatabaseEvent).snapshot.value as Map);

              final filteredData = data.entries.where((entry) {
                final userData = Map<String, dynamic>.from(entry.value);
                final username = userData['username']?.toLowerCase() ?? '';
                final email = userData['email']?.toLowerCase() ?? '';
                return username.contains(_searchQuery) ||
                    email.contains(_searchQuery);
              }).toList();

              if (filteredData.isEmpty) {
                return Center(child: Text("No users match your search."));
              }

              return ListView(
                children: filteredData.map((entry) {
                  final userData = Map<String, dynamic>.from(entry.value);
                  final bool isSuspended = userData['suspended'] == true;

                  return ListTile(
                    title: Text(userData['username'] ?? 'Unknown'),
                    subtitle: Text(userData['email'] ?? 'No email'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Suspension Toggle Button
                        IconButton(
                          icon: Icon(
                            isSuspended ? Icons.lock : Icons.lock_open,
                            color: isSuspended ? Colors.red : Colors.green,
                          ),
                          tooltip: isSuspended
                              ? 'Unsuspend User'
                              : 'Suspend User',
                          onPressed: () => toggleSuspension(
                              entry.key, userData['suspended'] != true),
                        ),
                        // Delete Button
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
