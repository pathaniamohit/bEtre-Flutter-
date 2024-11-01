import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CommentScreen extends StatefulWidget {
  final String postId;
  final String postOwnerId; // Add postOwnerId to know who owns the post

  CommentScreen({required this.postId, required this.postOwnerId});

  @override
  _CommentScreenState createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final DatabaseReference _commentsRef = FirebaseDatabase.instance.ref().child('posts');
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref().child('users');
  List<Map<dynamic, dynamic>> _comments = [];
  final TextEditingController _commentController = TextEditingController();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _loadComments();
  }

  void _loadComments() {
    _commentsRef.child(widget.postId).child('comments').onValue.listen((event) {
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
      } else {
        setState(() {
          _comments = [];
        });
      }
    });
  }

  void _addComment() async {
    if (_commentController.text.isEmpty) return;

    // Fetch current user's data
    DataSnapshot userSnapshot = await _userRef.child(_currentUser!.uid).get();
    Map<String, dynamic> userData = Map<String, dynamic>.from(userSnapshot.value as Map);

    final newCommentRef = _commentsRef.child(widget.postId).child('comments').push();
    final newComment = {
      'content': _commentController.text,
      'userId': _currentUser!.uid,
      'username': userData['username'] ?? 'Unknown',
      'userProfileImageUrl': userData['profileImageUrl'] ?? '',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await newCommentRef.set(newComment);

    // Notify the post owner
    _notifyPostOwner('commented on your post', newComment);

    _commentController.clear();
  }

  void _notifyPostOwner(String action, Map<String, dynamic> commentData) async {
    final postOwnerId = widget.postOwnerId;
    final currentUserId = _currentUser!.uid;
    if (postOwnerId == currentUserId) return; // Don't notify if the user is commenting on their own post

    final inboxRef = FirebaseDatabase.instance.ref().child('inbox').child(postOwnerId);
    await inboxRef.push().set({
      'fromUserId': currentUserId,
      'action': action,
      'postId': widget.postId,
      'commentContent': commentData['content'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void _deleteComment(Map<dynamic, dynamic> comment) async {
    final commentUserId = comment['userId'];
    final currentUserId = _currentUser!.uid;

    // Only the comment owner or the post owner can delete the comment
    if (currentUserId == commentUserId || currentUserId == widget.postOwnerId) {
      await _commentsRef.child(widget.postId).child('comments').child(comment['commentId']).remove();
    } else {
      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You cannot delete this comment')),
      );
    }
  }

  // void _reportComment(Map<dynamic, dynamic> comment) async {
  //   String commentId = comment['commentId'];
  //   String commentOwnerId = comment['userId'];
  //   String reporterId = _currentUser!.uid;
  //
  //   DatabaseReference reportRef = FirebaseDatabase.instance.ref().child('reports').push();
  //   await reportRef.set({
  //     'type': 'comment',
  //     'reportedItemId': commentId,
  //     'reportedUserId': commentOwnerId,
  //     'reporterId': reporterId,
  //     'timestamp': DateTime.now().millisecondsSinceEpoch,
  //     'reason': 'Inappropriate comment',
  //   });
  //
  //   Fluttertoast.showToast(msg: 'Comment reported.');
  // }

  void _reportComment(Map<dynamic, dynamic> comment) {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController _reasonController = TextEditingController();

        return AlertDialog(
          title: Text('Report Comment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Please specify the reason for reporting this comment:'),
              TextField(
                controller: _reasonController,
                decoration: InputDecoration(
                  hintText: 'Enter reason',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                String reason = _reasonController.text.trim();
                if (reason.isEmpty) {
                  Fluttertoast.showToast(msg: 'Please enter a reason.');
                  return;
                }

                // Proceed to report the comment
                String commentId = comment['commentId'];
                String commentOwnerId = comment['userId'];
                String reporterId = _currentUser!.uid;
                String reporterName = _currentUser!.displayName ?? 'Unknown';

                DatabaseReference reportRef = FirebaseDatabase.instance.ref().child('reports').push();
                await reportRef.set({
                  'type': 'comment',
                  'reportedItemId': commentId,
                  'reportedUserId': commentOwnerId,
                  'reporterId': reporterId,
                  'reporterName': reporterName,
                  'timestamp': DateTime.now().millisecondsSinceEpoch,
                  'reason': reason,
                  'content': comment['content'] ?? '',
                });

                Navigator.pop(context); // Close the dialog
                Fluttertoast.showToast(msg: 'Comment reported.');
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }


  Widget _buildCommentListTile(Map<dynamic, dynamic> comment) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: comment['userProfileImageUrl'] != null && comment['userProfileImageUrl'] != ''
            ? NetworkImage(comment['userProfileImageUrl'])
            : AssetImage('assets/profile_placeholder.png') as ImageProvider,
      ),
      title: Text(comment['username'] ?? 'Unknown User'),
      subtitle: Text(comment['content']),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.flag),
            onPressed: () => _reportComment(comment),
          ),
          if (comment['userId'] == _currentUser!.uid || widget.postOwnerId == _currentUser!.uid)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deleteComment(comment),
            ),
        ],
      ),
    );
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
            child: _comments.isNotEmpty
                ? ListView.builder(
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                var comment = _comments[index];
                return _buildCommentListTile(comment);
                // return ListTile(
                //   leading: CircleAvatar(
                //     backgroundImage: comment['userProfileImageUrl'] != null && comment['userProfileImageUrl'] != ''
                //         ? NetworkImage(comment['userProfileImageUrl'])
                //         : AssetImage('assets/profile_placeholder.png') as ImageProvider,
                //   ),
                //   title: Text(comment['username'] ?? 'Unknown User'),
                //   subtitle: Text(comment['content']),
                //   trailing: (comment['userId'] == _currentUser!.uid || widget.postOwnerId == _currentUser!.uid)
                //       ? IconButton(
                //     icon: Icon(Icons.delete),
                //     onPressed: () => _deleteComment(comment),
                //   )
                //       : null,
                // );
              },
            )
                : Center(child: Text('No comments')),
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
