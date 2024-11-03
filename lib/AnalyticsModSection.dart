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
        });
      }
    });
  }

  // Toggle suspend/unsuspend user
  void _toggleUserStatus(String userId, String currentStatus) {
    final userRef = widget.dbRef.child('users/$userId');
    String newStatus = currentStatus == 'active' ? 'suspended' : 'active';
    userRef.update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "Active & Suspended Accounts",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: allUsers.length,
            itemBuilder: (context, index) {
              final user = allUsers[index];
              // Adjust this key to match the Firebase structure
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
