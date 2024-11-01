import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ReportsSection extends StatelessWidget {
  final DatabaseReference dbRef;

  ReportsSection({required this.dbRef});

  // Issue a warning to a user
  Future<void> issueWarning(String userId) async {
    await dbRef.child('users').child(userId).child('warnings').push().set({
      'timestamp': DateTime.now().toIso8601String(),
      'reason': 'Violation of community guidelines'
    });
    Fluttertoast.showToast(
      msg: "Warning issued to User ID: $userId",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
    );
  }

  // Delete the reported content (post or comment)
  Future<void> deleteReportedContent(String itemId, String type) async {
    if (type == 'post') {
      await dbRef.child('posts').child(itemId).remove();
    } else if (type == 'comment') {
      await dbRef.child('comments').child(itemId).remove();
    }
    Fluttertoast.showToast(
      msg: "$type deleted successfully.",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
    );
  }

  // Discard report and approve content
  Future<void> discardReport(String reportId) async {
    await dbRef.child('reports').child(reportId).remove();
    Fluttertoast.showToast(
      msg: "Report approved and discarded.",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
    );
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
            final reportId = entry.key;
            final reportData = Map<String, dynamic>.from(entry.value);
            final reportedItemId = reportData['reportedItemId'] ?? 'Unknown';
            final reportedUserId = reportData['reportedUserId'] ?? 'Unknown';
            final reporterId = reportData['reporterId'] ?? 'Unknown';
            final reason = reportData['reason'] ?? 'No reason provided';
            final type = reportData['type'] ?? 'Unknown';
            final content = reportData['content'] ?? '';

            return ListTile(
              title: Text('Reported $type: $content'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reason: $reason'),
                  Text('Reported by User ID: $reporterId'),
                  Text('Reported User ID: $reportedUserId'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.check, color: Colors.green),
                    onPressed: () => discardReport(reportId), // Approve content
                    tooltip: 'Approve Content',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteReportedContent(reportedItemId, type), // Delete content
                    tooltip: 'Delete Content',
                  ),
                  IconButton(
                    icon: Icon(Icons.warning, color: Colors.orange),
                    onPressed: () => issueWarning(reportedUserId), // Issue warning
                    tooltip: 'Issue Warning',
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
