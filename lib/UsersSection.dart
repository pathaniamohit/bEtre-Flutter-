import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class UsersSection extends StatefulWidget {
  final DatabaseReference dbRef;

  UsersSection({required this.dbRef});

  @override
  _UsersSectionState createState() => _UsersSectionState();
}

class _UsersSectionState extends State<UsersSection> {
  String _searchQuery = ""; // Holds the search query input

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
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
                _searchQuery = value.toLowerCase(); // Update search query
              });
            },
          ),
        ),

        // User data
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

              // Filter users based on search query
              final filteredData = data.entries.where((entry) {
                final userData = Map<String, dynamic>.from(entry.value);
                final username = userData['username']?.toLowerCase() ?? '';
                final email = userData['email']?.toLowerCase() ?? '';
                return username.contains(_searchQuery) || email.contains(_searchQuery);
              }).toList();

              if (filteredData.isEmpty) {
                return Center(child: Text("No users match your search."));
              }

              return DataTable(
                columns: const [
                  DataColumn(label: Text('Username')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Role')),
                ],
                rows: filteredData.map((entry) {
                  final userData = Map<String, dynamic>.from(entry.value);
                  return DataRow(
                    cells: [
                      DataCell(Text(userData['username'] ?? 'Unknown')),
                      DataCell(Text(userData['email'] ?? 'No email')),
                      DataCell(Text(userData['role'] ?? 'user')),
                    ],
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
