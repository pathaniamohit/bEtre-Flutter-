import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentScreen extends StatefulWidget {
  final String postId;

  CommentScreen({required this.postId});

  @override
  _CommentScreenState createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final DatabaseReference _commentsRef = FirebaseDatabase.instance.ref().child('comments');
  List<Map<dynamic, dynamic>> _comments = [];
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  void _loadComments() {
    _commentsRef.child(widget.postId).onValue.listen((event) {
      if (event.snapshot.exists) {
        List<Map<dynamic, dynamic>> loadedComments = [];
        event.snapshot.children.forEach((comment) {
          Map<dynamic, dynamic> commentData = Map<dynamic, dynamic>.from(comment.value as Map);
          commentData['commentId'] = comment.key;
          loadedComments.add(commentData);
        });

        setState(() {
          _comments = loadedComments;
        });
      }
    });
  }

  void _addComment() {
    if (_commentController.text.isEmpty) return;

    final newComment = {
      'content': _commentController.text,
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    _commentsRef.child(widget.postId).push().set(newComment);

    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comments'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                var comment = _comments[index];
                return ListTile(
                  title: Text(comment['content']),
                  subtitle: Text('User: ${comment['userId']}'),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      labelText: 'Add a comment',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
