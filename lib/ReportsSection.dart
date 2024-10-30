import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ReportsSection extends StatelessWidget {
  final DatabaseReference dbRef;
  ReportsSection({required this.dbRef});

  Future<void> issueWarning(String userId) async {
    await dbRef.child('users').child(userId).child('warnings').push().set({
      'timestamp': DateTime.now().toIso8601String(),
      'reason': 'Violation of community guidelines'
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: dbRef.child('reports').onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null || (snapshot.data! as DatabaseEvent).snapshot.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = (snapshot.data! as DatabaseEvent).snapshot.value;
        if (data is! Map<dynamic, dynamic>) {
          return const Center(child: Text("No reports available"));
        }

        final reports = Map<String, dynamic>.from(data);

        return ListView(
          children: reports.entries.map((entry) {
            final report = Map<String, dynamic>.from(entry.value);
            return ListTile(
              title: Text(report['content'] ?? 'Report'),
              subtitle: Text('Reported by: ${report['reporterId'] ?? 'Unknown'}'),
              trailing: IconButton(
                icon: Icon(Icons.warning),
                onPressed: () => issueWarning(report['reportedUserId']),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
