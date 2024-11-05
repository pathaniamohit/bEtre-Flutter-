import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FlaggedContentSection extends StatefulWidget {
  final DatabaseReference dbRef;
  final bool isModerator;

  FlaggedContentSection({required this.dbRef, this.isModerator = false});

  @override
  _FlaggedContentSectionState createState() => _FlaggedContentSectionState();
}

class _FlaggedContentSectionState extends State<FlaggedContentSection> {
  List<Map<String, dynamic>> reportedCommentsList = [];
  Map<String, Map<String, String>> usersCache = {};

  @override
  void initState() {
    super.initState();
    loadReportedComments();
  }

  void loadReportedComments() {
    widget.dbRef.child('report_comments').onValue.listen((event) async {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      List<Map<String, dynamic>> tempReportedCommentsList = [];

      if (data != null) {
        for (var entry in data.entries) {
          var reportData = Map<String, dynamic>.from(entry.value);
          Map<String, String> userDetails = await getUserDetails(reportData['reportedCommentUserId']);

          tempReportedCommentsList.add({
            'commentId': entry.key,
            'postId': reportData['postId'] ?? 'Unknown Post',
            'content': reportData['content'] ?? 'No content',
            'reason': reportData['reason'] ?? 'No reason provided',
            'reportedById': reportData['reportedBy'] ?? 'Unknown Reporter',
            'reportedCommentUserId': reportData['reportedCommentUserId'] ?? 'Unknown User',
            'username': userDetails['username'],
            'email': userDetails['email'],
          });
        }
      }

      setState(() {
        reportedCommentsList = tempReportedCommentsList;
      });
    });
  }

  Future<Map<String, String>> getUserDetails(String userId) async {
    if (usersCache.containsKey(userId)) return usersCache[userId]!;

    DataSnapshot snapshot = await widget.dbRef.child('users').child(userId).get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      usersCache[userId] = {'username': data['username'] ?? 'Unknown User', 'email': data['email'] ?? 'No Email'};
      return usersCache[userId]!;
    }
    return {'username': 'Unknown User', 'email': 'No Email'};
  }

  Future<void> suspendUser(String userId, String commentId) async {
    try {
      await widget.dbRef.child('users').child(userId).update({'role': 'suspended'});
      await widget.dbRef.child('report_comments').child(commentId).remove(); // Remove the reported comment
      Fluttertoast.showToast(msg: 'User suspended and report removed successfully.', gravity: ToastGravity.BOTTOM);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error suspending user: $e', gravity: ToastGravity.BOTTOM);
    }
  }

  Future<void> markReportAsReviewed(String commentId) async {
    await widget.dbRef.child('report_comments').child(commentId).remove();
    Fluttertoast.showToast(msg: 'Report marked as reviewed.', gravity: ToastGravity.BOTTOM);
    loadReportedComments();
  }

  void showWarningDialog(String userId) {
    String warningMessage = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Send Warning', style: TextStyle(color: Colors.orange)),
          content: TextField(
            onChanged: (value) => warningMessage = value,
            decoration: InputDecoration(
              labelText: 'Enter warning message',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                sendWarning(userId, warningMessage);
                Navigator.pop(context);
              },
              child: Text('Send', style: TextStyle(color: Colors.orange)),
            ),
          ],
        );
      },
    );
  }

  Future<void> sendWarning(String userId, String message) async {
    final warningRef = widget.dbRef.child('warnings').child(userId).push();
    await warningRef.set({
      'userId': userId,
      'reason': message,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    Fluttertoast.showToast(msg: 'Warning sent successfully.', gravity: ToastGravity.BOTTOM);
  }

  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await widget.dbRef.child('comments').child(postId).child(commentId).remove(); // Remove from comments node
      await widget.dbRef.child('report_comments').child(commentId).remove(); // Remove from report_comments node
      Fluttertoast.showToast(msg: 'Comment deleted successfully.', gravity: ToastGravity.BOTTOM);
      loadReportedComments();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error deleting comment: $e', gravity: ToastGravity.BOTTOM);
    }
  }

  void _showConfirmationDialog(String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                onConfirm();
                Navigator.pop(context);
              },
              child: Text('Confirm', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Reported Comments',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: reportedCommentsList.isNotEmpty
                ? ListView.builder(
              itemCount: reportedCommentsList.length,
              itemBuilder: (context, index) {
                final report = reportedCommentsList[index];
                final username = report['username'] ?? 'Unknown User';
                final email = report['email'] ?? 'No Email';
                final commentId = report['commentId'];
                final content = report['content'] ?? 'No content';
                final reason = report['reason'] ?? 'No reason provided';

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
                        Text("Comment: $content", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text("User: $username", style: TextStyle(color: Colors.blue)),
                        Text("Reason: $reason", style: TextStyle(color: Colors.red)),
                        SizedBox(height: 10.0),

                        Align(
                          alignment: Alignment.centerRight,
                          child: PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert),
                            onSelected: (value) {
                              switch (value) {
                                case 'Suspend User':
                                  _showConfirmationDialog(
                                    'Suspend User',
                                    'Are you sure you want to suspend this user?',
                                        () => suspendUser(report['reportedCommentUserId'], commentId),
                                  );
                                  break;
                                case 'Reviewed':
                                  _showConfirmationDialog(
                                    'Mark as Reviewed',
                                    'Are you sure you want to mark this report as reviewed?',
                                        () => markReportAsReviewed(commentId),
                                  );
                                  break;
                                case 'Warning':
                                  showWarningDialog(report['reportedCommentUserId']);
                                  break;
                                case 'Delete Comment':
                                  _showConfirmationDialog(
                                    'Delete Comment',
                                    'Are you sure you want to delete this comment?',
                                        () => deleteComment(report['postId'], commentId),
                                  );
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(value: 'Suspend User', child: Text('Suspend User')),
                              PopupMenuItem(value: 'Reviewed', child: Text('Reviewed')),
                              PopupMenuItem(value: 'Warning', child: Text('Warning')),
                              PopupMenuItem(value: 'Delete Comment', child: Text('Delete Comment')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
                : Center(
              child: Text(
                widget.isModerator ? 'No reported comments available.' : 'No flagged content available.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
