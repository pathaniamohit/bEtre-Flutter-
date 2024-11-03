// // flagged_content_section.dart
//
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
//
// class FlaggedContentSection extends StatelessWidget {
//   final DatabaseReference dbRef;
//
//   FlaggedContentSection({required this.dbRef});
//
//   Future<void> resolveFlaggedPost(String postId, bool approve) async {
//     if (approve) {
//       await dbRef.child('posts').child(postId).update({'flagged': false});
//     } else {
//       await dbRef.child('posts').child(postId).remove();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder(
//       stream: dbRef.child('posts').orderByChild('flagged').equalTo(true).onValue,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return CircularProgressIndicator();
//         }
//
//         if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
//           return Center(child: Text("No flagged content available."));
//         }
//
//         final data = Map<String, dynamic>.from((snapshot.data as DatabaseEvent).snapshot.value as Map);
//         return ListView(
//           children: data.entries.map((entry) {
//             final postData = Map<String, dynamic>.from(entry.value);
//             return ListTile(
//               title: Text(postData['content'] ?? 'Flagged Post'),
//               subtitle: Text('Flagged by: ${postData['flaggedBy'] ?? 'Unknown'}'),
//               trailing: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   IconButton(
//                     icon: Icon(Icons.check),
//                     onPressed: () => resolveFlaggedPost(entry.key, true),
//                   ),
//                   IconButton(
//                     icon: Icon(Icons.delete),
//                     onPressed: () => resolveFlaggedPost(entry.key, false),
//                   ),
//                 ],
//               ),
//             );
//           }).toList(),
//         );
//       },
//     );
//   }
// }

// FlaggedContentSection.dart

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
  // List to store unique reported profiles
  List<Map<String, dynamic>> reportedProfilesList = [];

  // Cache to store user details to minimize database reads
  Map<String, Map<String, String>> usersCache = {};

  @override
  void initState() {
    super.initState();
    loadReportedProfiles();
  }

  /// Loads reports from 'reported_profiles' and fetches associated user details
  void loadReportedProfiles() {
    // Listen to the 'reported_profiles' node
    widget.dbRef.child('reported_profiles').onValue.listen((event) async {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      // Temporary map to hold reports grouped by reportedUserId
      Map<String, List<Map<String, dynamic>>> tempReportedProfiles = {};

      if (data != null) {
        data.forEach((reportId, reportData) {
          var reportMap = Map<String, dynamic>.from(reportData as Map);
          String reportedUserId = reportMap['reportedUserId'];

          if (!tempReportedProfiles.containsKey(reportedUserId)) {
            tempReportedProfiles[reportedUserId] = [];
          }
          tempReportedProfiles[reportedUserId]!.add(reportMap);
        });
      }

      // Temporary list to hold unique reported profiles
      List<Map<String, dynamic>> tempReportedProfilesList = [];

      for (var userId in tempReportedProfiles.keys) {
        // Fetch user details from 'users' node
        Map<String, String> userDetails = await getUserDetails(userId);
        int reportCount = tempReportedProfiles[userId]!.length;

        tempReportedProfilesList.add({
          'userId': userId,
          'username': userDetails['username'],
          'email': userDetails['email'],
          'reportCount': reportCount,
          'reports': tempReportedProfiles[userId],
        });
      }

      setState(() {
        reportedProfilesList = tempReportedProfilesList;
      });
    });
  }

  /// Fetches user details based on userId
  Future<Map<String, String>> getUserDetails(String userId) async {
    // Check if user details are already cached
    if (usersCache.containsKey(userId)) {
      return usersCache[userId]!;
    }

    // Fetch user details from 'users' node
    DataSnapshot snapshot = await widget.dbRef.child('users').child(userId).get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      String username = data['username'] ?? 'Unknown User';
      String email = data['email'] ?? 'No Email';

      // Cache the user details
      usersCache[userId] = {
        'username': username,
        'email': email,
      };

      return usersCache[userId]!;
    }

    // Return default values if user does not exist
    return {
      'username': 'Unknown User',
      'email': 'No Email',
    };
  }

  /// Removes all reports associated with a profile
  Future<void> removeReports(String userId) async {
    try {
      // Query reports related to the userId
      Query query = widget.dbRef.child('reported_profiles').orderByChild('reportedUserId').equalTo(userId);
      DataSnapshot snapshot = await query.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> reports = Map<dynamic, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);

        for (var reportId in reports.keys) {
          await widget.dbRef.child('reported_profiles').child(reportId).remove();
        }

        Fluttertoast.showToast(msg: 'Reports dismissed successfully.', gravity: ToastGravity.BOTTOM);
      } else {
        Fluttertoast.showToast(msg: 'No reports found for this profile.', gravity: ToastGravity.BOTTOM);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error removing reports: $e', gravity: ToastGravity.BOTTOM);
    }
  }

  /// Views all reports associated with a profile
  void viewReports(List<Map<String, dynamic>> postReports) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Reports for this Profile'),
          content: Container(
            width: double.maxFinite,
            child: postReports.isNotEmpty
                ? ListView.builder(
              shrinkWrap: true,
              itemCount: postReports.length,
              itemBuilder: (context, index) {
                final report = postReports[index];
                return ListTile(
                  leading: Icon(Icons.report, color: Colors.red),
                  title: Text('Reporter ID: ${report['reporterId']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reason: ${report['reason']}'),
                      Text('Timestamp: ${DateTime.fromMillisecondsSinceEpoch(report['timestamp'])}'),
                    ],
                  ),
                );
              },
            )
                : Text('No reports found for this profile.'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: reportedProfilesList.isNotEmpty
          ? ListView.builder(
        itemCount: reportedProfilesList.length,
        itemBuilder: (context, index) {
          final profile = reportedProfilesList[index];
          final username = profile['username'] ?? 'Unknown User';
          final email = profile['email'] ?? 'No Email';
          final userId = profile['userId'];
          final reportCount = profile['reportCount'] ?? 0;
          final reports = profile['reports'] as List<dynamic>? ?? [];

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
                  // Profile Information
                  Text(
                    username,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8.0),

                  // Report Count
                  Text(
                    'Reports: $reportCount',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.0),

                  // Action Button: View Reports

                    ElevatedButton.icon(
                      onPressed: () => viewReports(List<Map<String, dynamic>>.from(reports)),
                      icon: Icon(Icons.list),
                      label: Text('View Reports'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),

                  // Action Button: Remove Reports

                    ElevatedButton.icon(
                      onPressed: () => removeReports(userId),
                      icon: Icon(Icons.remove_circle),
                      label: Text('Dismiss Reports'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
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
          widget.isModerator
              ? 'No reported profiles available.'
              : 'No flagged content available.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}
