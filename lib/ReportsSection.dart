import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ReportsSection extends StatelessWidget {
  final DatabaseReference dbRef;

  ReportsSection({required this.dbRef});

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

  Future<void> discardReport(String reportId) async {
    await dbRef.child('reports').child(reportId).remove();
    Fluttertoast.showToast(
      msg: "Report approved and discarded.",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
    );
  }

  Future<Map<String, dynamic>> getReporterDetails(String userId) async {
    final snapshot = await dbRef.child('users').child(userId).get();
    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return {};
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

        // Separate reports by type, and gather comments from both the main reports and the 'comments' sub-node
        final postReports = reports.entries.where((entry) => entry.value['type'] == 'post').toList();
        final userReports = reports.entries.where((entry) => entry.value['type'] == 'profile').toList();

        // Gather comments from both `type == 'comment'` entries and from the dedicated 'comments' sub-node
        final commentReports = reports.entries
            .where((entry) => entry.value['type'] == 'comment')
            .toList();

        if (reports.containsKey('comments') && reports['comments'] is Map) {
          final commentsSubNode = Map<String, dynamic>.from(reports['comments']);
          commentReports.addAll(commentsSubNode.entries);
        }

        return Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  _buildReportSection("Post Reports", postReports, 'post'),
                  _buildReportSection("Comment Reports", commentReports, 'comment'),
                  _buildReportSection("User Reports", userReports, 'profile'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReportSection(String title, List<MapEntry<String, dynamic>> reports, String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ...reports.map((entry) => _buildReportTile(entry, type)).toList(),
      ],
    );
  }

  Widget _buildReportTile(MapEntry<String, dynamic> entry, String type) {
    final reportId = entry.key;
    final reportData = Map<String, dynamic>.from(entry.value);
    final reportedItemId = reportData['reportedItemId'] ?? 'Unknown';
    final reportedUserId = reportData['reportedUserId'] ?? 'Unknown';
    final reporterId = reportData['reporterId'] ?? 'Unknown';
    final reason = reportData['reason'] ?? 'No reason provided';

    return FutureBuilder(
      future: dbRef.child(type == 'post' ? 'posts' : 'comments').child(reportedItemId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return ListTile(title: Text("No $type found for Report ID: $reportId"));
        }

        final itemData = Map<String, dynamic>.from(snapshot.data!.value as Map);
        final itemImageUrl = type == 'post' ? itemData['imageUrl'] : null;
        final itemContent = itemData['content'] ?? '';

        return ListTile(
          leading: itemImageUrl != null
              ? Image.network(
            itemImageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          )
              : Icon(type == 'post' ? Icons.post_add : Icons.comment),
          title: Text('Reported $type: $itemContent'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reason: $reason'),
              FutureBuilder(
                future: getReporterDetails(reporterId),
                builder: (context, reporterSnapshot) {
                  if (reporterSnapshot.connectionState == ConnectionState.waiting) {
                    return const Text("Loading reporter info...");
                  }
                  if (!reporterSnapshot.hasData || reporterSnapshot.data!.isEmpty) {
                    return const Text("Reporter: Unknown");
                  }

                  final reporterDetails = reporterSnapshot.data!;
                  final reporterUsername = reporterDetails['username'] ?? 'Unknown';
                  return Text('Reported by: $reporterUsername');
                },
              ),
              Text('Reported User ID: $reportedUserId'),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.check, color: Colors.green),
                onPressed: () => discardReport(reportId),
                tooltip: 'Approve Content',
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => deleteReportedContent(reportedItemId, type),
                tooltip: 'Delete Content',
              ),
              IconButton(
                icon: Icon(Icons.warning, color: Colors.orange),
                onPressed: () => issueWarning(reportedUserId),
                tooltip: 'Issue Warning',
              ),
            ],
          ),
        );
      },
    );
  }
}
