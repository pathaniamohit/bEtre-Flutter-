import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class PostsModSection extends StatefulWidget {
  final DatabaseReference dbRef;

  PostsModSection({Key? key, required this.dbRef}) : super(key: key);

  @override
  _PostsModSectionState createState() => _PostsModSectionState();
}

class _PostsModSectionState extends State<PostsModSection> {
  List<Map<String, dynamic>> postsList = [];
  Map<String, Map<String, String>> usersCache = {};

  @override
  void initState() {
    super.initState();
    loadPosts();
  }

  void loadPosts() {
    widget.dbRef.child('posts').onValue.listen((event) async {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        List<Map<String, dynamic>> tempPostsList = [];
        for (var entry in data.entries) {
          final postData = Map<String, dynamic>.from(entry.value as Map<dynamic, dynamic>);
          postData['postId'] = entry.key.toString();
          final userId = postData['userId'];

          if (userId != null) {
            if (!usersCache.containsKey(userId)) {
              final userDetails = await getUserDetails(userId);
              usersCache[userId] = userDetails;
            }
            postData['username'] = usersCache[userId]?['username'] ?? 'Unknown User';
            postData['email'] = usersCache[userId]?['email'] ?? 'No Email';

            // Fetch total likes and comments for the post
            final likes = await widget.dbRef.child('likes').child(postData['postId']).get();
            final comments = await widget.dbRef.child('comments').child(postData['postId']).get();
            postData['likesCount'] = likes.children.length;
            postData['commentsCount'] = comments.children.length;
          }

          tempPostsList.add(postData);
        }
        setState(() {
          postsList = tempPostsList;
        });
      } else {
        setState(() {
          postsList = [];
        });
      }
    });
  }

  Future<Map<String, String>> getUserDetails(String userId) async {
    final snapshot = await widget.dbRef.child('users').child(userId).get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
      return {
        'username': data['username'] ?? 'Unknown User',
        'email': data['email'] ?? 'No Email',
      };
    }
    return {'username': 'Unknown User', 'email': 'No Email'};
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: postsList.length,
        itemBuilder: (context, index) {
          final post = postsList[index];
          final username = post['username'] ?? 'Unknown User';
          final email = post['email'] ?? 'No Email';
          final likesCount = post['likesCount'] ?? 0;
          final commentsCount = post['commentsCount'] ?? 0;
          final imageUrl = post['imageUrl'] as String?;

          return Card(
            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display image if it exists
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
                    )
                  else
                    Container(
                      height: 150,
                      color: Colors.grey[300],
                      child: Icon(Icons.image, size: 50, color: Colors.grey[700]),
                    ),
                  SizedBox(height: 8.0),
                  Text(
                    post['content'] ?? 'No content',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    'Posted by: $username',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    'Email: $email',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Row(
                    children: [
                      Text('Likes: $likesCount'),
                      SizedBox(width: 16),
                      Text('Comments: $commentsCount'),
                    ],
                  ),
                  SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.comment,
                          color: Colors.blue,
                        ),
                        onPressed: () {
                          showCommentsDialog(post['postId']);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void showCommentsDialog(String postId) async {
    final commentsSnapshot = await widget.dbRef.child('comments').child(postId).get();
    List<Map<String, dynamic>> commentsList = [];

    if (commentsSnapshot.exists) {
      for (var comment in commentsSnapshot.children) {
        if (comment.value is Map) {
          final commentData = Map<String, dynamic>.from(comment.value as Map);
          commentsList.add(commentData);
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Comments"),
          content: commentsList.isNotEmpty
              ? Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: commentsList.length,
              itemBuilder: (context, index) {
                final comment = commentsList[index];
                final timestamp = comment['timestamp'] != null
                    ? DateFormat('yyyy-MM-dd HH:mm:ss')
                    .format(DateTime.fromMillisecondsSinceEpoch(comment['timestamp']))
                    : 'No Timestamp';
                return ListTile(
                  title: Text(comment['username'] ?? 'Anonymous'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(comment['content'] ?? 'No comment content'),
                      Text('Time: $timestamp'),
                    ],
                  ),
                );
              },
            ),
          )
              : Text("No comments available"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }
}
