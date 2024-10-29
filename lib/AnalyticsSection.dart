import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AnalyticsSection extends StatelessWidget {
  final DatabaseReference dbRef;
  AnalyticsSection({required this.dbRef});

  Future<int> getTotalPosts() async {
    final snapshot = await dbRef.child('posts').get();
    return snapshot.children.length;
  }

  Future<int> getSuspendedUsersCount() async {
    final snapshot = await dbRef.child('users').orderByChild('suspended').equalTo(true).get();
    return snapshot.children.length;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FutureBuilder<int>(
          future: getTotalPosts(),
          builder: (context, snapshot) {
            return ListTile(
              title: Text('Total Posts'),
              subtitle: Text(snapshot.hasData ? snapshot.data.toString() : 'Loading...'),
            );
          },
        ),
        FutureBuilder<int>(
          future: getSuspendedUsersCount(),
          builder: (context, snapshot) {
            return ListTile(
              title: Text('Suspended Users'),
              subtitle: Text(snapshot.hasData ? snapshot.data.toString() : 'Loading...'),
            );
          },
        ),
      ],
    );
  }
}
