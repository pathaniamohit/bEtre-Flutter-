// // import 'package:flutter/material.dart';
// // import 'package:firebase_database/firebase_database.dart';
// // import 'package:fluttertoast/fluttertoast.dart';
// //
// // class ReportsSection extends StatelessWidget {
// //   final DatabaseReference dbRef;
// //
// //   ReportsSection({required this.dbRef});
// //
// //   Future<void> issueWarning(String userId) async {
// //     await dbRef.child('users').child(userId).child('warnings').push().set({
// //       'timestamp': DateTime.now().toIso8601String(),
// //       'reason': 'Violation of community guidelines'
// //     });
// //     Fluttertoast.showToast(
// //       msg: "Warning issued to User ID: $userId",
// //       toastLength: Toast.LENGTH_SHORT,
// //       gravity: ToastGravity.BOTTOM,
// //       timeInSecForIosWeb: 1,
// //     );
// //   }
// //
// //   Future<void> deleteReportedContent(String itemId, String type) async {
// //     if (type == 'post') {
// //       await dbRef.child('posts').child(itemId).remove();
// //     } else if (type == 'comment') {
// //       await dbRef.child('comments').child(itemId).remove();
// //     }
// //     Fluttertoast.showToast(
// //       msg: "$type deleted successfully.",
// //       toastLength: Toast.LENGTH_SHORT,
// //       gravity: ToastGravity.BOTTOM,
// //       timeInSecForIosWeb: 1,
// //     );
// //   }
// //
// //   Future<void> discardReport(String reportId) async {
// //     await dbRef.child('reports').child(reportId).remove();
// //     Fluttertoast.showToast(
// //       msg: "Report approved and discarded.",
// //       toastLength: Toast.LENGTH_SHORT,
// //       gravity: ToastGravity.BOTTOM,
// //       timeInSecForIosWeb: 1,
// //     );
// //   }
// //
// //   Future<Map<String, dynamic>> getReporterDetails(String userId) async {
// //     final snapshot = await dbRef.child('users').child(userId).get();
// //     if (snapshot.exists) {
// //       return Map<String, dynamic>.from(snapshot.value as Map);
// //     }
// //     return {};
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return StreamBuilder(
// //       stream: dbRef.child('reports').onValue,
// //       builder: (context, snapshot) {
// //         if (!snapshot.hasData || snapshot.data == null || (snapshot.data! as DatabaseEvent).snapshot.value == null) {
// //           return const Center(child: CircularProgressIndicator());
// //         }
// //
// //         final data = (snapshot.data! as DatabaseEvent).snapshot.value;
// //         if (data is! Map<dynamic, dynamic>) {
// //           return const Center(child: Text("No reports available"));
// //         }
// //
// //         final reports = Map<String, dynamic>.from(data);
// //
// //         // Separate reports by type, and gather comments from both the main reports and the 'comments' sub-node
// //         final postReports = reports.entries.where((entry) => entry.value['type'] == 'post').toList();
// //         final userReports = reports.entries.where((entry) => entry.value['type'] == 'profile').toList();
// //
// //         // Gather comments from both `type == 'comment'` entries and from the dedicated 'comments' sub-node
// //         final commentReports = reports.entries
// //             .where((entry) => entry.value['type'] == 'comment')
// //             .toList();
// //
// //         if (reports.containsKey('comments') && reports['comments'] is Map) {
// //           final commentsSubNode = Map<String, dynamic>.from(reports['comments']);
// //           commentReports.addAll(commentsSubNode.entries);
// //         }
// //
// //         return Column(
// //           children: [
// //             Expanded(
// //               child: ListView(
// //                 children: [
// //                   _buildReportSection("Post Reports", postReports, 'post'),
// //                   _buildReportSection("Comment Reports", commentReports, 'comment'),
// //                   _buildReportSection("User Reports", userReports, 'profile'),
// //                 ],
// //               ),
// //             ),
// //           ],
// //         );
// //       },
// //     );
// //   }
// //
// //   Widget _buildReportSection(String title, List<MapEntry<String, dynamic>> reports, String type) {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Padding(
// //           padding: const EdgeInsets.all(8.0),
// //           child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
// //         ),
// //         ...reports.map((entry) => _buildReportTile(entry, type)).toList(),
// //       ],
// //     );
// //   }
// //
// //   Widget _buildReportTile(MapEntry<String, dynamic> entry, String type) {
// //     final reportId = entry.key;
// //     final reportData = Map<String, dynamic>.from(entry.value);
// //     final reportedItemId = reportData['reportedItemId'] ?? 'Unknown';
// //     final reportedUserId = reportData['reportedUserId'] ?? 'Unknown';
// //     final reporterId = reportData['reporterId'] ?? 'Unknown';
// //     final reason = reportData['reason'] ?? 'No reason provided';
// //
// //     return FutureBuilder(
// //       future: dbRef.child(type == 'post' ? 'posts' : 'comments').child(reportedItemId).get(),
// //       builder: (context, snapshot) {
// //         if (snapshot.connectionState == ConnectionState.waiting) {
// //           return const CircularProgressIndicator();
// //         }
// //         if (!snapshot.hasData || !snapshot.data!.exists) {
// //           return ListTile(title: Text("No $type found for Report ID: $reportId"));
// //         }
// //
// //         final itemData = Map<String, dynamic>.from(snapshot.data!.value as Map);
// //         final itemImageUrl = type == 'post' ? itemData['imageUrl'] : null;
// //         final itemContent = itemData['content'] ?? '';
// //
// //         return ListTile(
// //           leading: itemImageUrl != null
// //               ? Image.network(
// //             itemImageUrl,
// //             width: 50,
// //             height: 50,
// //             fit: BoxFit.cover,
// //           )
// //               : Icon(type == 'post' ? Icons.post_add : Icons.comment),
// //           title: Text('Reported $type: $itemContent'),
// //           subtitle: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               Text('Reason: $reason'),
// //               FutureBuilder(
// //                 future: getReporterDetails(reporterId),
// //                 builder: (context, reporterSnapshot) {
// //                   if (reporterSnapshot.connectionState == ConnectionState.waiting) {
// //                     return const Text("Loading reporter info...");
// //                   }
// //                   if (!reporterSnapshot.hasData || reporterSnapshot.data!.isEmpty) {
// //                     return const Text("Reporter: Unknown");
// //                   }
// //
// //                   final reporterDetails = reporterSnapshot.data!;
// //                   final reporterUsername = reporterDetails['username'] ?? 'Unknown';
// //                   return Text('Reported by: $reporterUsername');
// //                 },
// //               ),
// //               Text('Reported User ID: $reportedUserId'),
// //             ],
// //           ),
// //           trailing: Row(
// //             mainAxisSize: MainAxisSize.min,
// //             children: [
// //               IconButton(
// //                 icon: Icon(Icons.check, color: Colors.green),
// //                 onPressed: () => discardReport(reportId),
// //                 tooltip: 'Approve Content',
// //               ),
// //               IconButton(
// //                 icon: Icon(Icons.delete, color: Colors.red),
// //                 onPressed: () => deleteReportedContent(reportedItemId, type),
// //                 tooltip: 'Delete Content',
// //               ),
// //               IconButton(
// //                 icon: Icon(Icons.warning, color: Colors.orange),
// //                 onPressed: () => issueWarning(reportedUserId),
// //                 tooltip: 'Issue Warning',
// //               ),
// //             ],
// //           ),
// //         );
// //       },
// //     );
// //   }
// // }
//
// // ReportsSection.dart
//
// // import 'package:flutter/material.dart';
// // import 'package:firebase_database/firebase_database.dart';
// // import 'package:fluttertoast/fluttertoast.dart';
// //
// // class ReportsSection extends StatefulWidget {
// //   final DatabaseReference dbRef;
// //   final bool isAdmin; // Renamed to isAdmin for clarity
// //
// //   ReportsSection({required this.dbRef, this.isAdmin = false});
// //
// //   @override
// //   _ReportsSectionState createState() => _ReportsSectionState();
// // }
// //
// // class _ReportsSectionState extends State<ReportsSection> {
// //   // List to store all reported comments
// //   List<Map<String, dynamic>> reportedCommentsList = [];
// //
// //   // Cache to store user details to minimize database reads
// //   Map<String, Map<String, String>> usersCache = {};
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     if (widget.isAdmin) {
// //       loadReportedComments();
// //     }
// //   }
// //
// //   /// Loads reports from 'reportcomment' and fetches associated comment and reporter details
// //   void loadReportedComments() {
// //     // Listen to the 'reportcomment' node
// //     widget.dbRef.child('reportcomment').onValue.listen((event) async {
// //       final data = event.snapshot.value as Map<dynamic, dynamic>?;
// //
// //       // Temporary list to hold reported comments
// //       List<Map<String, dynamic>> tempReportedCommentsList = [];
// //
// //       if (data != null) {
// //         for (var entry in data.entries) {
// //           String reportId = entry.key;
// //           Map<String, dynamic> reportData = Map<String, dynamic>.from(entry.value);
// //
// //           String commentId = reportData['reportedItemId'] ?? '';
// //           String reporterId = reportData['reporterId'] ?? '';
// //           String reason = reportData['reason'] ?? 'No reason provided';
// //           int timestamp = reportData['timestamp'] ?? 0;
// //
// //           // Fetch comment details
// //           DataSnapshot commentSnapshot = await widget.dbRef.child('comments').child(commentId).get();
// //           if (commentSnapshot.exists) {
// //             Map<String, dynamic> commentData = Map<String, dynamic>.from(commentSnapshot.value as Map);
// //             String commentContent = commentData['content'] ?? 'No content';
// //             String commentUserId = commentData['userId'] ?? 'Unknown User';
// //
// //             // Fetch reporter details
// //             Map<String, String> reporterDetails = await getUserDetails(reporterId);
// //             String reporterUsername = reporterDetails['username'] ?? 'Unknown User';
// //             String reporterEmail = reporterDetails['email'] ?? 'No Email';
// //
// //             // Fetch comment owner details
// //             Map<String, String> commentOwnerDetails = await getUserDetails(commentUserId);
// //             String commentOwnerUsername = commentOwnerDetails['username'] ?? 'Unknown User';
// //             String commentOwnerEmail = commentOwnerDetails['email'] ?? 'No Email';
// //
// //             tempReportedCommentsList.add({
// //               'reportId': reportId,
// //               'commentId': commentId,
// //               'commentContent': commentContent,
// //               'commentUserId': commentUserId,
// //               'commentOwnerUsername': commentOwnerUsername,
// //               'commentOwnerEmail': commentOwnerEmail,
// //               'reporterId': reporterId,
// //               'reporterUsername': reporterUsername,
// //               'reporterEmail': reporterEmail,
// //               'reason': reason,
// //               'timestamp': timestamp,
// //             });
// //           } else {
// //             // If the comment no longer exists, remove the report
// //             await widget.dbRef.child('reportcomment').child(reportId).remove();
// //             Fluttertoast.showToast(
// //               msg: "Removed report for non-existent comment (ID: $commentId).",
// //               toastLength: Toast.LENGTH_SHORT,
// //               gravity: ToastGravity.BOTTOM,
// //             );
// //           }
// //         }
// //       }
// //
// //       setState(() {
// //         reportedCommentsList = tempReportedCommentsList;
// //       });
// //     });
// //   }
// //
// //   /// Fetches user details based on userId
// //   Future<Map<String, String>> getUserDetails(String userId) async {
// //     // Check if user details are already cached
// //     if (usersCache.containsKey(userId)) {
// //       return usersCache[userId]!;
// //     }
// //
// //     // Fetch user details from 'users' node
// //     DataSnapshot snapshot = await widget.dbRef.child('users').child(userId).get();
// //
// //     if (snapshot.exists) {
// //       Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);
// //       String username = data['username'] ?? 'Unknown User';
// //       String email = data['email'] ?? 'No Email';
// //
// //       // Cache the user details
// //       usersCache[userId] = {
// //         'username': username,
// //         'email': email,
// //       };
// //
// //       return usersCache[userId]!;
// //     }
// //
// //     // Return default values if user does not exist
// //     return {
// //       'username': 'Unknown User',
// //       'email': 'No Email',
// //     };
// //   }
// //
// //   /// Deletes a comment from the 'comments' node
// //   Future<void> deleteComment(String commentId) async {
// //     try {
// //       await widget.dbRef.child('comments').child(commentId).remove();
// //       Fluttertoast.showToast(
// //         msg: "Comment deleted successfully.",
// //         toastLength: Toast.LENGTH_SHORT,
// //         gravity: ToastGravity.BOTTOM,
// //       );
// //     } catch (e) {
// //       Fluttertoast.showToast(
// //         msg: "Error deleting comment: $e",
// //         toastLength: Toast.LENGTH_SHORT,
// //         gravity: ToastGravity.BOTTOM,
// //       );
// //     }
// //   }
// //
// //   /// Removes a report from the 'reportcomment' node
// //   Future<void> removeReport(String reportId) async {
// //     try {
// //       await widget.dbRef.child('reportcomment').child(reportId).remove();
// //       Fluttertoast.showToast(
// //         msg: "Report removed successfully.",
// //         toastLength: Toast.LENGTH_SHORT,
// //         gravity: ToastGravity.BOTTOM,
// //       );
// //     } catch (e) {
// //       Fluttertoast.showToast(
// //         msg: "Error removing report: $e",
// //         toastLength: Toast.LENGTH_SHORT,
// //         gravity: ToastGravity.BOTTOM,
// //       );
// //     }
// //   }
// //
// //   /// Issues a warning to a user by adding an entry to their 'warnings' node
// //   Future<void> issueWarning(String userId) async {
// //     try {
// //       await widget.dbRef.child('users').child(userId).child('warnings').push().set({
// //         'timestamp': DateTime.now().toIso8601String(),
// //         'reason': 'Violation of community guidelines',
// //       });
// //       Fluttertoast.showToast(
// //         msg: "Warning issued to User ID: $userId",
// //         toastLength: Toast.LENGTH_SHORT,
// //         gravity: ToastGravity.BOTTOM,
// //         timeInSecForIosWeb: 1,
// //       );
// //     } catch (e) {
// //       Fluttertoast.showToast(
// //         msg: "Error issuing warning: $e",
// //         toastLength: Toast.LENGTH_SHORT,
// //         gravity: ToastGravity.BOTTOM,
// //       );
// //     }
// //   }
// //
// //   /// Displays a confirmation dialog before deleting a comment
// //   void confirmDeleteComment(String commentId) {
// //     showDialog(
// //       context: context,
// //       builder: (BuildContext context) {
// //         return AlertDialog(
// //           title: Text('Delete Comment'),
// //           content: Text('Are you sure you want to delete this comment? This action cannot be undone.'),
// //           actions: [
// //             TextButton(
// //               onPressed: () => Navigator.of(context).pop(), // Cancel
// //               child: Text('Cancel'),
// //             ),
// //             TextButton(
// //               onPressed: () {
// //                 Navigator.of(context).pop(); // Close the dialog
// //                 deleteComment(commentId); // Proceed with deletion
// //               },
// //               child: Text('Delete', style: TextStyle(color: Colors.red)),
// //             ),
// //           ],
// //         );
// //       },
// //     );
// //   }
// //
// //   /// Displays a confirmation dialog before removing a report
// //   void confirmRemoveReport(String reportId) {
// //     showDialog(
// //       context: context,
// //       builder: (BuildContext context) {
// //         return AlertDialog(
// //           title: Text('Remove Report'),
// //           content: Text('Are you sure you want to remove this report?'),
// //           actions: [
// //             TextButton(
// //               onPressed: () => Navigator.of(context).pop(), // Cancel
// //               child: Text('Cancel'),
// //             ),
// //             TextButton(
// //               onPressed: () {
// //                 Navigator.of(context).pop(); // Close the dialog
// //                 removeReport(reportId); // Proceed with removing the report
// //               },
// //               child: Text('Remove', style: TextStyle(color: Colors.orange)),
// //             ),
// //           ],
// //         );
// //       },
// //     );
// //   }
// //
// //   /// Displays a confirmation dialog before issuing a warning
// //   void confirmIssueWarning(String userId) {
// //     showDialog(
// //       context: context,
// //       builder: (BuildContext context) {
// //         return AlertDialog(
// //           title: Text('Issue Warning'),
// //           content: Text('Are you sure you want to issue a warning to this user?'),
// //           actions: [
// //             TextButton(
// //               onPressed: () => Navigator.of(context).pop(), // Cancel
// //               child: Text('Cancel'),
// //             ),
// //             TextButton(
// //               onPressed: () {
// //                 Navigator.of(context).pop(); // Close the dialog
// //                 issueWarning(userId); // Proceed with issuing the warning
// //               },
// //               child: Text('Issue Warning', style: TextStyle(color: Colors.orange)),
// //             ),
// //           ],
// //         );
// //       },
// //     );
// //   }
// //
// //   /// Builds the UI for each reported comment
// //   Widget _buildReportTile(Map<String, dynamic> report) {
// //     String reportId = report['reportId'] ?? '';
// //     String commentId = report['commentId'] ?? '';
// //     String commentContent = report['commentContent'] ?? 'No content';
// //     String commentUserId = report['commentUserId'] ?? 'Unknown User';
// //     String commentOwnerUsername = report['commentOwnerUsername'] ?? 'Unknown User';
// //     String commentOwnerEmail = report['commentOwnerEmail'] ?? 'No Email';
// //     String reporterId = report['reporterId'] ?? 'Unknown';
// //     String reporterUsername = report['reporterUsername'] ?? 'Unknown User';
// //     String reporterEmail = report['reporterEmail'] ?? 'No Email';
// //     String reason = report['reason'] ?? 'No reason provided';
// //     int timestamp = report['timestamp'] ?? 0;
// //
// //     DateTime reportDateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
// //
// //     return Card(
// //       margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
// //       shape: RoundedRectangleBorder(
// //         borderRadius: BorderRadius.circular(10.0),
// //       ),
// //       elevation: 3,
// //       child: Padding(
// //         padding: const EdgeInsets.all(12.0),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             // Reporter Information
// //             Row(
// //               children: [
// //                 Icon(Icons.report, color: Colors.redAccent),
// //                 SizedBox(width: 8),
// //                 Expanded(
// //                   child: Text(
// //                     'Reported by: $reporterUsername (${reporterEmail})',
// //                     style: TextStyle(
// //                       fontSize: 14,
// //                       fontWeight: FontWeight.bold,
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //             SizedBox(height: 8.0),
// //
// //             // Report Details
// //             Text(
// //               'Reason: $reason',
// //               style: TextStyle(
// //                 fontSize: 14,
// //                 color: Colors.black87,
// //               ),
// //             ),
// //             SizedBox(height: 4.0),
// //             Text(
// //               'Reported At: ${reportDateTime.toLocal()}',
// //               style: TextStyle(
// //                 fontSize: 12,
// //                 color: Colors.grey[600],
// //               ),
// //             ),
// //             Divider(height: 20, thickness: 1),
// //
// //             // Comment Information
// //             Text(
// //               'Comment Content:',
// //               style: TextStyle(
// //                 fontSize: 14,
// //                 fontWeight: FontWeight.bold,
// //               ),
// //             ),
// //             SizedBox(height: 4.0),
// //             Text(
// //               commentContent,
// //               style: TextStyle(
// //                 fontSize: 14,
// //                 color: Colors.black87,
// //               ),
// //             ),
// //             SizedBox(height: 8.0),
// //             Text(
// //               'Comment Owner: $commentOwnerUsername (${commentOwnerEmail})',
// //               style: TextStyle(
// //                 fontSize: 12,
// //                 color: Colors.grey[700],
// //               ),
// //             ),
// //
// //             SizedBox(height: 12.0),
// //
// //             // Action Buttons
// //             Row(
// //               mainAxisAlignment: MainAxisAlignment.end,
// //               children: [
// //                 // Delete Comment Button
// //                 IconButton(
// //                   icon: Icon(Icons.delete, color: Colors.red),
// //                   tooltip: 'Delete Comment',
// //                   onPressed: () => confirmDeleteComment(commentId),
// //                 ),
// //                 // Remove Report Button
// //                 IconButton(
// //                   icon: Icon(Icons.remove_circle, color: Colors.orange),
// //                   tooltip: 'Remove Report',
// //                   onPressed: () => confirmRemoveReport(reportId),
// //                 ),
// //                 // Issue Warning Button
// //                 IconButton(
// //                   icon: Icon(Icons.warning, color: Colors.blue),
// //                   tooltip: 'Issue Warning',
// //                   onPressed: () => confirmIssueWarning(commentUserId),
// //                 ),
// //               ],
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //
// //
// //     return StreamBuilder(
// //       stream: widget.dbRef.child('reportcomment').onValue,
// //       builder: (context, snapshot) {
// //         if (snapshot.connectionState == ConnectionState.waiting) {
// //           return const Center(child: CircularProgressIndicator());
// //         }
// //
// //         if (!snapshot.hasData ||
// //             snapshot.data == null ||
// //             (snapshot.data! as DatabaseEvent).snapshot.value == null) {
// //           return const Center(child: Text("No reports available."));
// //         }
// //
// //         final data = (snapshot.data! as DatabaseEvent).snapshot.value;
// //         if (data is! Map<dynamic, dynamic>) {
// //           return const Center(child: Text("No reports available."));
// //         }
// //
// //         // The reportedCommentsList is already populated via the listener in initState
// //         if (reportedCommentsList.isEmpty) {
// //           return const Center(child: Text("No reported comments available."));
// //         }
// //
// //         return ListView.builder(
// //           itemCount: reportedCommentsList.length,
// //           itemBuilder: (context, index) {
// //             final report = reportedCommentsList[index];
// //             return _buildReportTile(report);
// //           },
// //         );
// //       },
// //     );
// //   }
// // }
//
// // ReportsSection.dart
//
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:fluttertoast/fluttertoast.dart';
//
// class ReportsSection extends StatefulWidget {
//   final DatabaseReference dbRef;
//    // Renamed to isAdmin for clarity
//
//   ReportsSection({required this.dbRef});
//
//   @override
//   _ReportsSectionState createState() => _ReportsSectionState();
// }
//
// class _ReportsSectionState extends State<ReportsSection> {
//   // List to store all reported comments
//   List<Map<String, dynamic>> reportedCommentsList = [];
//
//   // Cache to store user details to minimize database reads
//   Map<String, Map<String, String>> usersCache = {};
//
//   @override
//   void initState() {
//     super.initState();
//     {
//       loadReportedComments();
//     }
//   }
//
//   /// Loads reports from 'reportcomment' and fetches associated comment and reporter details
//   void loadReportedComments() {
//     // Listen to the 'reportcomment' node
//     widget.dbRef.child('reportcomment').onValue.listen((event) async {
//       final data = event.snapshot.value as Map<dynamic, dynamic>?;
//
//       // Temporary list to hold reported comments
//       List<Map<String, dynamic>> tempReportedCommentsList = [];
//
//       if (data != null) {
//         for (var entry in data.entries) {
//           String reportId = entry.key;
//           Map<String, dynamic> reportData = Map<String, dynamic>.from(entry.value);
//
//           String commentId = reportData['reportedItemId'] ?? '';
//           String reporterId = reportData['reporterId'] ?? '';
//           String reason = reportData['reason'] ?? 'No reason provided';
//           int timestamp = reportData['timestamp'] ?? 0;
//
//           // Fetch comment details
//           DataSnapshot commentSnapshot = await widget.dbRef.child('comments').child(commentId).get();
//           if (commentSnapshot.exists) {
//             Map<String, dynamic> commentData = Map<String, dynamic>.from(commentSnapshot.value as Map);
//             String commentContent = commentData['content'] ?? 'No content';
//             String commentUserId = commentData['userId'] ?? 'Unknown User';
//
//             // Fetch reporter details
//             Map<String, String> reporterDetails = await getUserDetails(reporterId);
//             String reporterUsername = reporterDetails['username'] ?? 'Unknown User';
//             String reporterEmail = reporterDetails['email'] ?? 'No Email';
//
//             // Fetch comment owner details
//             Map<String, String> commentOwnerDetails = await getUserDetails(commentUserId);
//             String commentOwnerUsername = commentOwnerDetails['username'] ?? 'Unknown User';
//             String commentOwnerEmail = commentOwnerDetails['email'] ?? 'No Email';
//
//             tempReportedCommentsList.add({
//               'reportId': reportId,
//               'commentId': commentId,
//               'commentContent': commentContent,
//               'commentUserId': commentUserId,
//               'commentOwnerUsername': commentOwnerUsername,
//               'commentOwnerEmail': commentOwnerEmail,
//               'reporterId': reporterId,
//               'reporterUsername': reporterUsername,
//               'reporterEmail': reporterEmail,
//               'reason': reason,
//               'timestamp': timestamp,
//             });
//           } else {
//             // If the comment no longer exists, remove the report
//             await widget.dbRef.child('reportcomment').child(reportId).remove();
//             Fluttertoast.showToast(
//               msg: "Removed report for non-existent comment (ID: $commentId).",
//               toastLength: Toast.LENGTH_SHORT,
//               gravity: ToastGravity.BOTTOM,
//             );
//           }
//         }
//       }
//
//       setState(() {
//         reportedCommentsList = tempReportedCommentsList;
//       });
//     });
//   }
//
//   /// Fetches user details based on userId
//   Future<Map<String, String>> getUserDetails(String userId) async {
//     // Check if user details are already cached
//     if (usersCache.containsKey(userId)) {
//       return usersCache[userId]!;
//     }
//
//     // Fetch user details from 'users' node
//     DataSnapshot snapshot = await widget.dbRef.child('users').child(userId).get();
//
//     if (snapshot.exists) {
//       Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);
//       String username = data['username'] ?? 'Unknown User';
//       String email = data['email'] ?? 'No Email';
//
//       // Cache the user details
//       usersCache[userId] = {
//         'username': username,
//         'email': email,
//       };
//
//       return usersCache[userId]!;
//     }
//
//     // Return default values if user does not exist
//     return {
//       'username': 'Unknown User',
//       'email': 'No Email',
//     };
//   }
//
//   /// Deletes a comment from the 'comments' node
//   Future<void> deleteComment(String commentId) async {
//     try {
//       await widget.dbRef.child('comments').child(commentId).remove();
//       Fluttertoast.showToast(
//         msg: "Comment deleted successfully.",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//       );
//     } catch (e) {
//       Fluttertoast.showToast(
//         msg: "Error deleting comment: $e",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//       );
//     }
//   }
//
//   /// Removes a report from the 'reportcomment' node
//   Future<void> removeReport(String reportId) async {
//     try {
//       await widget.dbRef.child('reportcomment').child(reportId).remove();
//       Fluttertoast.showToast(
//         msg: "Report removed successfully.",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//       );
//     } catch (e) {
//       Fluttertoast.showToast(
//         msg: "Error removing report: $e",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//       );
//     }
//   }
//
//   /// Issues a warning to a user by adding an entry to their 'warnings' node
//   Future<void> issueWarning(String userId) async {
//     try {
//       await widget.dbRef.child('users').child(userId).child('warnings').push().set({
//         'timestamp': DateTime.now().toIso8601String(),
//         'reason': 'Violation of community guidelines',
//       });
//       Fluttertoast.showToast(
//         msg: "Warning issued to User ID: $userId",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//         timeInSecForIosWeb: 1,
//       );
//     } catch (e) {
//       Fluttertoast.showToast(
//         msg: "Error issuing warning: $e",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//       );
//     }
//   }
//
//   /// Displays a confirmation dialog before deleting a comment
//   void confirmDeleteComment(String commentId) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Delete Comment'),
//           content: Text('Are you sure you want to delete this comment? This action cannot be undone.'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(), // Cancel
//               child: Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close the dialog
//                 deleteComment(commentId); // Proceed with deletion
//               },
//               child: Text('Delete', style: TextStyle(color: Colors.red)),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   /// Displays a confirmation dialog before removing a report
//   void confirmRemoveReport(String reportId) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Remove Report'),
//           content: Text('Are you sure you want to remove this report?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(), // Cancel
//               child: Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close the dialog
//                 removeReport(reportId); // Proceed with removing the report
//               },
//               child: Text('Remove', style: TextStyle(color: Colors.orange)),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   /// Displays a confirmation dialog before issuing a warning
//   void confirmIssueWarning(String userId) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Issue Warning'),
//           content: Text('Are you sure you want to issue a warning to this user?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(), // Cancel
//               child: Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close the dialog
//                 issueWarning(userId); // Proceed with issuing the warning
//               },
//               child: Text('Issue Warning', style: TextStyle(color: Colors.orange)),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   /// Builds the UI for each reported comment
//   Widget _buildReportTile(Map<String, dynamic> report) {
//     String reportId = report['reportId'] ?? '';
//     String commentId = report['commentId'] ?? '';
//     String commentContent = report['commentContent'] ?? 'No content';
//     String commentUserId = report['commentUserId'] ?? 'Unknown User';
//     String commentOwnerUsername = report['commentOwnerUsername'] ?? 'Unknown User';
//     String commentOwnerEmail = report['commentOwnerEmail'] ?? 'No Email';
//     String reporterId = report['reporterId'] ?? 'Unknown';
//     String reporterUsername = report['reporterUsername'] ?? 'Unknown User';
//     String reporterEmail = report['reporterEmail'] ?? 'No Email';
//     String reason = report['reason'] ?? 'No reason provided';
//     int timestamp = report['timestamp'] ?? 0;
//
//     DateTime reportDateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
//
//     return Card(
//       margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10.0),
//       ),
//       elevation: 3,
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Reporter Information
//             Row(
//               children: [
//                 Icon(Icons.report, color: Colors.redAccent),
//                 SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     'Reported by: $reporterUsername (${reporterEmail})',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 8.0),
//
//             // Report Details
//             Text(
//               'Reason: $reason',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.black87,
//               ),
//             ),
//             SizedBox(height: 4.0),
//             Text(
//               'Reported At: ${reportDateTime.toLocal()}',
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.grey[600],
//               ),
//             ),
//             Divider(height: 20, thickness: 1),
//
//             // Comment Information
//             Text(
//               'Comment Content:',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             SizedBox(height: 4.0),
//             Text(
//               commentContent,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.black87,
//               ),
//             ),
//             SizedBox(height: 8.0),
//             Text(
//               'Comment Owner: $commentOwnerUsername (${commentOwnerEmail})',
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.grey[700],
//               ),
//             ),
//
//             SizedBox(height: 12.0),
//
//             // Action Buttons
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 // Delete Comment Button
//                 IconButton(
//                   icon: Icon(Icons.delete, color: Colors.red),
//                   tooltip: 'Delete Comment',
//                   onPressed: () => confirmDeleteComment(commentId),
//                 ),
//                 // Remove Report Button
//                 IconButton(
//                   icon: Icon(Icons.remove_circle, color: Colors.orange),
//                   tooltip: 'Remove Report',
//                   onPressed: () => confirmRemoveReport(reportId),
//                 ),
//                 // Issue Warning Button
//                 IconButton(
//                   icon: Icon(Icons.warning, color: Colors.blue),
//                   tooltip: 'Issue Warning',
//                   onPressed: () => confirmIssueWarning(commentUserId),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//
//       // If the user is not an admin, display an unauthorized message
//
//
//     return StreamBuilder(
//       stream: widget.dbRef.child('reportcomment').onValue,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }
//
//         if (!snapshot.hasData ||
//             snapshot.data == null ||
//             (snapshot.data! as DatabaseEvent).snapshot.value == null) {
//           return const Center(child: Text("No reports available."));
//         }
//
//         final data = (snapshot.data! as DatabaseEvent).snapshot.value;
//         if (data is! Map<dynamic, dynamic>) {
//           return const Center(child: Text("No reports available."));
//         }
//
//         // The reportedCommentsList is already populated via the listener in initState
//         if (reportedCommentsList.isEmpty) {
//           return const Center(child: Text("No reported comments available."));
//         }
//
//         return ListView.builder(
//           itemCount: reportedCommentsList.length,
//           itemBuilder: (context, index) {
//             final report = reportedCommentsList[index];
//             return _buildReportTile(report);
//           },
//         );
//       },
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ReportsSection extends StatefulWidget {
  final DatabaseReference dbRef;

  ReportsSection({required this.dbRef});

  @override
  _ReportsSectionState createState() => _ReportsSectionState();
}

class _ReportsSectionState extends State<ReportsSection> {
  // List to store all reported comments
  List<Map<String, dynamic>> reportedCommentsList = [];

  // Cache to store user details to minimize database reads
  Map<String, Map<String, String>> usersCache = {};

  @override
  void initState() {
    super.initState();
    loadReportedComments();
  }

  /// Loads reports from 'reportcomment' and fetches associated comment and reporter details
  void loadReportedComments() {
    // Listen to the 'reportcomment' node
    widget.dbRef.child('reportcomment').onValue.listen((event) async {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      // Temporary list to hold reported comments
      List<Map<String, dynamic>> tempReportedCommentsList = [];

      if (data != null) {
        for (var entry in data.entries) {
          String reportId = entry.key;
          Map<String, dynamic> reportData = Map<String, dynamic>.from(entry.value);

          String postId = reportData['postId'] ?? '';
          String commentId = reportData['commentId'] ?? '';
          String reporterId = reportData['reporterId'] ?? '';
          String reason = reportData['reason'] ?? 'No reason provided';
          int timestamp = reportData['timestamp'] ?? 0;

          if (postId.isEmpty || commentId.isEmpty) {
            // Invalid report data, skip
            continue;
          }

          // Fetch comment details
          DataSnapshot commentSnapshot = await widget.dbRef
              .child('posts')
              .child(postId)
              .child('comments')
              .child(commentId)
              .get();

          if (commentSnapshot.exists) {
            Map<String, dynamic> commentData = Map<String, dynamic>.from(commentSnapshot.value as Map);
            String commentContent = commentData['content'] ?? 'No content';
            String commentUserId = commentData['userId'] ?? 'Unknown User';

            // Fetch reporter details
            Map<String, String> reporterDetails = await getUserDetails(reporterId);
            String reporterUsername = reporterDetails['username'] ?? 'Unknown User';
            String reporterEmail = reporterDetails['email'] ?? 'No Email';

            // Fetch comment owner details
            Map<String, String> commentOwnerDetails = await getUserDetails(commentUserId);
            String commentOwnerUsername = commentOwnerDetails['username'] ?? 'Unknown User';
            String commentOwnerEmail = commentOwnerDetails['email'] ?? 'No Email';

            tempReportedCommentsList.add({
              'reportId': reportId,
              'postId': postId,
              'commentId': commentId,
              'commentContent': commentContent,
              'commentUserId': commentUserId,
              'commentOwnerUsername': commentOwnerUsername,
              'commentOwnerEmail': commentOwnerEmail,
              'reporterId': reporterId,
              'reporterUsername': reporterUsername,
              'reporterEmail': reporterEmail,
              'reason': reason,
              'timestamp': timestamp,
            });
          } else {
            // If the comment no longer exists, remove the report
            await widget.dbRef.child('reportcomment').child(reportId).remove();
            Fluttertoast.showToast(
              msg: "Removed report for non-existent comment (ID: $commentId).",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
            );
          }
        }
      }

      setState(() {
        reportedCommentsList = tempReportedCommentsList;
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
      Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);
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

  /// Deletes a comment from the 'posts/postId/comments' node
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await widget.dbRef.child('posts').child(postId).child('comments').child(commentId).remove();
      Fluttertoast.showToast(
        msg: "Comment deleted successfully.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );

      // Optionally, remove all reports related to this comment
      Query relatedReports = widget.dbRef.child('reportcomment').orderByChild('commentId').equalTo(commentId);
      DataSnapshot snapshot = await relatedReports.get();
      if (snapshot.exists) {
        for (var report in snapshot.children) {
          await report.ref.remove();
        }
        Fluttertoast.showToast(
          msg: "All related reports removed.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error deleting comment: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  /// Removes a report from the 'reportcomment' node
  Future<void> removeReport(String reportId) async {
    try {
      await widget.dbRef.child('reportcomment').child(reportId).remove();
      Fluttertoast.showToast(
        msg: "Report removed successfully.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error removing report: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  /// Issues a warning to a user by adding an entry to their 'warnings' node
  Future<void> issueWarning(String userId) async {
    try {
      await widget.dbRef.child('users').child(userId).child('warnings').push().set({
        'timestamp': DateTime.now().toIso8601String(),
        'reason': 'Violation of community guidelines',
      });
      Fluttertoast.showToast(
        msg: "Warning issued to User ID: $userId",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error issuing warning: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  /// Displays a confirmation dialog before deleting a comment
  void confirmDeleteComment(String postId, String commentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Comment'),
          content: Text('Are you sure you want to delete this comment? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Cancel
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                deleteComment(postId, commentId); // Proceed with deletion
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  /// Displays a confirmation dialog before removing a report
  void confirmRemoveReport(String reportId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove Report'),
          content: Text('Are you sure you want to remove this report?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Cancel
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                removeReport(reportId); // Proceed with removing the report
              },
              child: Text('Remove', style: TextStyle(color: Colors.orange)),
            ),
          ],
        );
      },
    );
  }

  /// Displays a confirmation dialog before issuing a warning
  void confirmIssueWarning(String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Issue Warning'),
          content: Text('Are you sure you want to issue a warning to this user?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Cancel
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                issueWarning(userId); // Proceed with issuing the warning
              },
              child: Text('Issue Warning', style: TextStyle(color: Colors.orange)),
            ),
          ],
        );
      },
    );
  }

  /// Builds the UI for each reported comment
  Widget _buildReportTile(Map<String, dynamic> report) {
    String reportId = report['reportId'] ?? '';
    String postId = report['postId'] ?? '';
    String commentId = report['commentId'] ?? '';
    String commentContent = report['commentContent'] ?? 'No content';
    String commentUserId = report['commentUserId'] ?? 'Unknown User';
    String commentOwnerUsername = report['commentOwnerUsername'] ?? 'Unknown User';
    String commentOwnerEmail = report['commentOwnerEmail'] ?? 'No Email';
    String reporterId = report['reporterId'] ?? 'Unknown';
    String reporterUsername = report['reporterUsername'] ?? 'Unknown User';
    String reporterEmail = report['reporterEmail'] ?? 'No Email';
    String reason = report['reason'] ?? 'No reason provided';
    int timestamp = report['timestamp'] ?? 0;

    DateTime reportDateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

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
            // Reporter Information
            Row(
              children: [
                Icon(Icons.report, color: Colors.redAccent),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reported by: $reporterUsername (${reporterEmail})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.0),

            // Report Details
            Text(
              'Reason: $reason',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 4.0),
            Text(
              'Reported At: ${reportDateTime.toLocal()}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Divider(height: 20, thickness: 1),

            // Comment Information
            Text(
              'Comment Content:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.0),
            Text(
              commentContent,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              'Comment Owner: $commentOwnerUsername (${commentOwnerEmail})',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),

            SizedBox(height: 12.0),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Delete Comment Button
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete Comment',
                  onPressed: () => confirmDeleteComment(postId, commentId),
                ),
                // Remove Report Button
                IconButton(
                  icon: Icon(Icons.remove_circle, color: Colors.orange),
                  tooltip: 'Remove Report',
                  onPressed: () => confirmRemoveReport(reportId),
                ),
                // Issue Warning Button
                IconButton(
                  icon: Icon(Icons.warning, color: Colors.blue),
                  tooltip: 'Issue Warning',
                  onPressed: () => confirmIssueWarning(commentUserId),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: widget.dbRef.child('reportcomment').onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData ||
            snapshot.data == null ||
            (snapshot.data! as DatabaseEvent).snapshot.value == null) {
          return const Center(child: Text("No reports available."));
        }

        final data = (snapshot.data! as DatabaseEvent).snapshot.value;
        if (data is! Map<dynamic, dynamic>) {
          return const Center(child: Text("No reports available."));
        }

        // The reportedCommentsList is already populated via the listener in initState
        if (reportedCommentsList.isEmpty) {
          return const Center(child: Text("No reported comments available."));
        }

        return ListView.builder(
          itemCount: reportedCommentsList.length,
          itemBuilder: (context, index) {
            final report = reportedCommentsList[index];
            return _buildReportTile(report);
          },
        );
      },
    );
  }
}
