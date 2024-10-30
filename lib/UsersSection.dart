import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class UsersSection extends StatefulWidget {
  final DatabaseReference dbRef;

  UsersSection({required this.dbRef});

  @override
  _UsersSectionState createState() => _UsersSectionState();
}

class _UsersSectionState extends State<UsersSection> {
  String _searchQuery = "";

  Future<void> toggleSuspension(String userId, bool suspended) async {
    try {
      await widget.dbRef.child('users').child(userId).update({'suspended': suspended});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(suspended ? 'User suspended' : 'User unsuspended')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating suspension: $e')));
    }
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
                  return ListTile(
                    title: Text(userData['username'] ?? 'Unknown'),
                    subtitle: Text(userData['email'] ?? 'No email'),
                    trailing: IconButton(
                      icon: Icon(userData['suspended'] == true ? Icons.lock : Icons.lock_open),
                      onPressed: () => toggleSuspension(entry.key, userData['suspended'] != true),
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
