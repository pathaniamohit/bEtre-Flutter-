import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AnalyticsModSection extends StatefulWidget {
  final DatabaseReference dbRef;

  const AnalyticsModSection({Key? key, required this.dbRef}) : super(key: key);

  @override
  _AnalyticsModSectionState createState() => _AnalyticsModSectionState();
}

class _AnalyticsModSectionState extends State<AnalyticsModSection> {
  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // Fetch all users from Firebase
  void _fetchUsers() {
    widget.dbRef.child('users').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        final List<Map<String, dynamic>> users = [];

        data.forEach((key, value) {
          final user = Map<String, dynamic>.from(value);
          user['id'] = key;
          users.add(user);
        });

        setState(() {
          allUsers = users;
          _filterUsers(); // Filter users based on initial (empty) search query
        });
      }
    });
  }

  // Filter users based on search query
  void _filterUsers() {
    setState(() {
      filteredUsers = allUsers.where((user) {
        final userName = user['username']?.toLowerCase() ?? '';
        final email = user['email']?.toLowerCase() ?? '';
        return userName.contains(_searchQuery) || email.contains(_searchQuery);
      }).toList();
    });
  }

  // Toggle suspend/unsuspend user
  void _toggleUserStatus(String userId, String currentStatus) {
    final userRef = widget.dbRef.child('users/$userId');
    String newStatus = currentStatus == 'active' ? 'suspended' : 'active';

    userRef.update({'status': newStatus}).then((_) {
      // Show a SnackBar with a message after updating the status
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'suspended'
                ? 'User has been suspended.'
                : 'User has been unsuspended.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }).catchError((error) {
      // Show an error message if the update fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update user status: $error'),
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                _filterUsers(); // Filter users as search query changes
              });
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "Active & Suspended Accounts",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              final String userName = user['username'] ?? 'No Username';
              final String email = user['email'] ?? 'No Email';
              final String status = user['status'] ?? 'active';
              final bool isSuspended = status == 'suspended';

              return ListTile(
                title: Text(userName),
                subtitle: Text("Email: $email"),
                trailing: IconButton(
                  icon: Icon(
                    isSuspended ? Icons.lock_open : Icons.block,
                    color: isSuspended ? Colors.green : Colors.red,
                  ),
                  onPressed: () => _toggleUserStatus(user['id'], status),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
