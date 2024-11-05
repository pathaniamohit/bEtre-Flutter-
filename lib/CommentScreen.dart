
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CommentScreen extends StatefulWidget {
  final String postId;
  final String postOwnerId; // To know who owns the post
  final bool canReport;

  CommentScreen({
    required this.postId,
    required this.postOwnerId,
    this.canReport = false,
  });

  @override
  _CommentScreenState createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final DatabaseReference _commentsRef = FirebaseDatabase.instance.ref().child('comments');
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

  /// Loads comments from the global 'comments' node where 'postId' matches
  void _loadComments() {
    _commentsRef.orderByChild('postId').equalTo(widget.postId).onValue.listen((event) {
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

  /// Adds a comment to the global 'comments' node
  void _addComment() async {
    if (_commentController.text.isEmpty) return;

    try {
      // Fetch current user's data
      DataSnapshot userSnapshot = await _userRef.child(_currentUser!.uid).get();
      if (!userSnapshot.exists) {
        Fluttertoast.showToast(msg: 'User data not found.');
        return;
      }
      Map<String, dynamic> userData = Map<String, dynamic>.from(userSnapshot.value as Map);

      // Add comment to the global "comments" node
      final newCommentRef = _commentsRef.push();
      final newComment = {
        'content': _commentController.text,
        'userId': _currentUser!.uid,
        'postId': widget.postId, // Link comment to its post
        'username': userData['username'] ?? 'Unknown',
        'userProfileImageUrl': userData['profileImageUrl'] ?? '',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await newCommentRef.set(newComment);

      // Notify the post owner
      _notifyPostOwner('commented on your post', newComment);

      _commentController.clear();
      Fluttertoast.showToast(msg: 'Comment added successfully.', gravity: ToastGravity.BOTTOM);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error adding comment: $e', gravity: ToastGravity.BOTTOM);
    }
  }

  /// Notifies the post owner about the new comment
  void _notifyPostOwner(String action, Map<String, dynamic> commentData) async {
    final postOwnerId = widget.postOwnerId;
    final currentUserId = _currentUser!.uid;
    if (postOwnerId == currentUserId) return; // Don't notify if the user is commenting on their own post

    try {
      // Replace 'inbox' with 'notifications'
      final notificationsRef = FirebaseDatabase.instance.ref().child('notifications').child(postOwnerId);
      await notificationsRef.push().set({
        'fromUserId': currentUserId,
        'action': action,
        'postId': widget.postId,
        'commentContent': commentData['content'],
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error notifying post owner: $e', gravity: ToastGravity.BOTTOM);
    }
  }

  /// Deletes a comment from the global 'comments' node
  void _deleteComment(Map<dynamic, dynamic> comment) async {
    final commentUserId = comment['userId'];
    final currentUserId = _currentUser!.uid;

    // Only the comment owner or the post owner can delete the comment
    if (currentUserId == commentUserId || currentUserId == widget.postOwnerId) {
      try {
        await _commentsRef.child(comment['commentId']).remove();
        Fluttertoast.showToast(msg: 'Comment deleted successfully.', gravity: ToastGravity.BOTTOM);
      } catch (e) {
        Fluttertoast.showToast(msg: 'Error deleting comment: $e', gravity: ToastGravity.BOTTOM);
      }
    } else {
      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You cannot delete this comment')),
      );
    }
  }

  /// Reports a comment by adding it to the 'reportcomment' node
  void _reportComment(Map<dynamic, dynamic> comment) {
    if (!widget.canReport) return;
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

                try {
                  // Proceed to report the comment
                  String commentId = comment['commentId'];
                  String commentOwnerId = comment['userId'];
                  String reporterId = _currentUser!.uid;

                  // Check if the user has already reported this comment
                  DataSnapshot existingReport = await FirebaseDatabase.instance
                      .ref()
                      .child('reportcomment')
                      .orderByChild('reporterId')
                      .equalTo(reporterId)
                      .get();

                  bool alreadyReported = false;
                  if (existingReport.exists) {
                    Map<dynamic, dynamic> reports = Map<dynamic, dynamic>.from(existingReport.value as Map<dynamic, dynamic>);
                    reports.forEach((key, report) {
                      if (report['commentId'] == commentId) {
                        alreadyReported = true;
                      }
                    });
                  }

                  if (alreadyReported) {
                    Fluttertoast.showToast(
                      msg: 'You have already reported this comment.',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                    );
                    Navigator.pop(context);
                    return;
                  }

                  // Fetch reporter details
                  DataSnapshot reporterSnapshot = await _userRef.child(reporterId).get();
                  if (!reporterSnapshot.exists) {
                    Fluttertoast.showToast(msg: 'Reporter user does not exist.');
                    Navigator.pop(context);
                    return;
                  }
                  Map<String, dynamic> reporterData = Map<String, dynamic>.from(reporterSnapshot.value as Map);
                  String reporterUsername = reporterData['username'] ?? 'Unknown User';
                  String reporterEmail = reporterData['email'] ?? 'No Email';

                  // Fetch comment owner details
                  DataSnapshot commentOwnerSnapshot = await _userRef.child(commentOwnerId).get();
                  if (!commentOwnerSnapshot.exists) {
                    Fluttertoast.showToast(msg: 'Comment owner does not exist.');
                    Navigator.pop(context);
                    return;
                  }
                  Map<String, dynamic> commentOwnerData = Map<String, dynamic>.from(commentOwnerSnapshot.value as Map);
                  String commentOwnerUsername = commentOwnerData['username'] ?? 'Unknown User';
                  String commentOwnerEmail = commentOwnerData['email'] ?? 'No Email';

                  // Fetch postId from comment
                  String postId = widget.postId; // Since all comments loaded are for this post

                  DatabaseReference reportRef = FirebaseDatabase.instance.ref().child('reportcomment').push();
                  await reportRef.set({
                    'reportId': reportRef.key,
                    'postId': postId, // Include postId
                    'commentId': commentId,
                    'commentContent': comment['content'] ?? '',
                    'commentUserId': commentOwnerId,
                    'commentOwnerUsername': commentOwnerUsername,
                    'commentOwnerEmail': commentOwnerEmail,
                    'reporterId': reporterId,
                    'reporterUsername': reporterUsername,
                    'reporterEmail': reporterEmail,
                    'reason': reason,
                    'timestamp': DateTime.now().millisecondsSinceEpoch,
                  });

                  Navigator.pop(context); // Close the dialog
                  Fluttertoast.showToast(msg: 'Comment reported.');
                } catch (e) {
                  Navigator.pop(context); // Close the dialog
                  Fluttertoast.showToast(msg: 'Error reporting comment: $e');
                }
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  /// Builds the UI for each comment
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
            tooltip: 'Report Comment',
          ),
          if (comment['userId'] == _currentUser!.uid || widget.postOwnerId == _currentUser!.uid)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deleteComment(comment),
              tooltip: 'Delete Comment',
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
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _addComment,
                  tooltip: 'Send Comment',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
