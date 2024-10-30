import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CommentsScreen extends StatelessWidget {
  final String postId;

  CommentsScreen({required this.postId});

  @override
  Widget build(BuildContext context) {
    final DatabaseReference _commentsRef = FirebaseDatabase.instance.ref().child('comments').child(postId);

    return Scaffold(
      appBar: AppBar(
        title: Text('Comments'),
      ),
      body: StreamBuilder(
        stream: _commentsRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            // Debugging output for the entire snapshot
            print("Snapshot data: ${snapshot.data?.snapshot.value}");

            if (snapshot.data!.snapshot.value != null) {
              try {
                Map<dynamic, dynamic> comments = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                List<dynamic> commentList = comments.values.toList();

                // Log the individual comments
                commentList.forEach((comment) {
                  print("Comment: $comment");
                });

                return ListView.builder(
                  itemCount: commentList.length,
                  itemBuilder: (context, index) {
                    var comment = commentList[index];

                    // Assign default values if fields are missing
                    String content = comment['content'] ?? 'No content';
                    String username = comment['username'] ?? 'Unknown User';
                    String timestamp = comment['timestamp']?.toString() ?? 'No timestamp';

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(username.isNotEmpty ? username[0] : 'U'), // Show the first letter of the username or 'U'
                      ),
                      title: Text(username),
                      subtitle: Text(content),
                      trailing: Text(timestamp),
                    );
                  },
                );
              } catch (e) {
                print("Error processing comments: $e");
                return Center(child: Text("Error displaying comments"));
              }
            } else {
              print("No comments found in Firebase for post ID $postId");
              return Center(child: Text("No comments yet"));
            }
          } else if (snapshot.hasError) {
            return Center(child: Text("Error loading comments"));
          } else {
            return Center(child: Text("No comments yet"));
          }
        },
      ),
    );
  }
}
