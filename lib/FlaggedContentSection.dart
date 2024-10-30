// flagged_content_section.dart

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class FlaggedContentSection extends StatelessWidget {
  final DatabaseReference dbRef;

  FlaggedContentSection({required this.dbRef});

  Future<void> resolveFlaggedPost(String postId, bool approve) async {
    if (approve) {
      await dbRef.child('posts').child(postId).update({'flagged': false});
    } else {
      await dbRef.child('posts').child(postId).remove();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: dbRef.child('posts').orderByChild('flagged').equalTo(true).onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return Center(child: Text("No flagged content available."));
        }

        final data = Map<String, dynamic>.from((snapshot.data as DatabaseEvent).snapshot.value as Map);
        return ListView(
          children: data.entries.map((entry) {
            final postData = Map<String, dynamic>.from(entry.value);
            return ListTile(
              title: Text(postData['content'] ?? 'Flagged Post'),
              subtitle: Text('Flagged by: ${postData['flaggedBy'] ?? 'Unknown'}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.check),
                    onPressed: () => resolveFlaggedPost(entry.key, true),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => resolveFlaggedPost(entry.key, false),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
