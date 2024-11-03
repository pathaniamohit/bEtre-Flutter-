// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'dart:io';
//
// class PostsSection extends StatefulWidget {
//   final DatabaseReference dbRef;
//   final bool isModerator;
//
//   PostsSection({required this.dbRef, this.isModerator = false});
//
//   @override
//   _PostsSectionState createState() => _PostsSectionState();
// }
//
// class _PostsSectionState extends State<PostsSection> {
//   List<Map<String, dynamic>> postsList = [];
//   Map<String, Map<String, String>> usersCache = {};
//   final ImagePicker _picker = ImagePicker();
//
//   @override
//   void initState() {
//     super.initState();
//     loadPosts();
//   }
//
//   void loadPosts() {
//     widget.dbRef.child('posts').onValue.listen((event) async {
//       final data = event.snapshot.value as Map<dynamic, dynamic>?;
//       if (data != null) {
//         List<Map<String, dynamic>> tempPostsList = [];
//         for (var entry in data.entries) {
//           final postData = Map<String, dynamic>.from(entry.value as Map<dynamic, dynamic>);
//           postData['postId'] = entry.key.toString();
//           final userId = postData['userId'];
//
//           if (userId != null) {
//             if (!usersCache.containsKey(userId)) {
//               final userDetails = await getUserDetails(userId);
//               usersCache[userId] = userDetails;
//             }
//             postData['username'] = usersCache[userId]?['username'] ?? 'Unknown User';
//             postData['email'] = usersCache[userId]?['email'] ?? 'No Email';
//           }
//
//           tempPostsList.add(postData);
//         }
//         setState(() {
//           postsList = tempPostsList;
//         });
//       } else {
//         setState(() {
//           postsList = [];
//         });
//       }
//     });
//   }
//
//   Future<Map<String, String>> getUserDetails(String userId) async {
//     final snapshot = await widget.dbRef.child('users').child(userId).get();
//     if (snapshot.exists) {
//       final data = Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
//       return {
//         'username': data['username'] ?? 'Unknown User',
//         'email': data['email'] ?? 'No Email',
//       };
//     }
//     return {'username': 'Unknown User', 'email': 'No Email'};
//   }
//
//   Future<void> removePost(String postId) async {
//     await widget.dbRef.child('posts').child(postId).remove();
//   }
//
//   Future<void> updatePost(String postId, String newContent, String? newImageUrl) async {
//     Map<String, dynamic> updatedData = {'content': newContent};
//     if (newImageUrl != null) {
//       updatedData['imageUrl'] = newImageUrl;
//     }
//     await widget.dbRef.child('posts').child(postId).update(updatedData);
//   }
//
//   Future<String?> uploadImage(File image) async {
//     final storageRef = FirebaseStorage.instance.ref().child('post_images/${DateTime.now().toIso8601String()}');
//     final uploadTask = storageRef.putFile(image);
//     final snapshot = await uploadTask.whenComplete(() {});
//     return await snapshot.ref.getDownloadURL();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: ListView.builder(
//         itemCount: postsList.length,
//         itemBuilder: (context, index) {
//           final post = postsList[index];
//           final imageUrl = post['imageUrl'] as String?;
//           final username = post['username'] ?? 'Unknown User';
//           final email = post['email'] ?? 'No Email';
//
//           return Card(
//             margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10.0),
//             ),
//             elevation: 3,
//             child: Padding(
//               padding: const EdgeInsets.all(12.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   if (imageUrl != null && imageUrl.isNotEmpty)
//                     Image.network(
//                       imageUrl,
//                       height: 150,
//                       width: double.infinity,
//                       fit: BoxFit.cover,
//                       errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
//                     )
//                   else
//                     Container(
//                       height: 150,
//                       color: Colors.grey[300],
//                       child: Icon(Icons.image, size: 50, color: Colors.grey[700]),
//                     ),
//                   SizedBox(height: 8.0),
//                   Text(
//                     post['content'] ?? 'No content',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   SizedBox(height: 8.0),
//                   Text(
//                     'Posted by: $username',
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey[700],
//                     ),
//                   ),
//                   Text(
//                     'Email: $email',
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                   SizedBox(height: 8.0),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       if (!widget.isModerator)
//                         IconButton(
//                           icon: Icon(
//                             Icons.edit,
//                             color: Colors.blue,
//                           ),
//                           onPressed: () {
//                             showEditDialog(post);
//                           },
//                         ),
//                       IconButton(
//                         icon: Icon(
//                           Icons.delete,
//                           color: Colors.red,
//                         ),
//                         onPressed: () async {
//                           final confirmDelete = await showDialog<bool>(
//                             context: context,
//                             builder: (context) {
//                               return AlertDialog(
//                                 title: Text("Confirm Deletion"),
//                                 content: Text("Are you sure you want to delete this post?"),
//                                 actions: [
//                                   TextButton(
//                                     onPressed: () => Navigator.of(context).pop(false),
//                                     child: Text("Cancel"),
//                                   ),
//                                   TextButton(
//                                     onPressed: () => Navigator.of(context).pop(true),
//                                     child: Text("Delete"),
//                                   ),
//                                 ],
//                               );
//                             },
//                           );
//
//                           if (confirmDelete == true) {
//                             await removePost(post['postId']);
//                           }
//                         },
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   void showEditDialog(Map<String, dynamic> post) {
//     TextEditingController contentController = TextEditingController(text: post['content']);
//     File? newImageFile;
//
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text("Edit Post"),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: contentController,
//                 decoration: InputDecoration(labelText: 'Content'),
//               ),
//               SizedBox(height: 10),
//               ElevatedButton(
//                 onPressed: () async {
//                   final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
//                   if (pickedFile != null) {
//                     setState(() {
//                       newImageFile = File(pickedFile.path);
//                     });
//                   }
//                 },
//                 child: Text("Change Image"),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: Text("Cancel"),
//             ),
//             TextButton(
//               onPressed: () async {
//                 String? newImageUrl;
//                 if (newImageFile != null) {
//                   newImageUrl = await uploadImage(newImageFile!);
//                 }
//                 await updatePost(post['postId'], contentController.text, newImageUrl);
//                 Fluttertoast.showToast(
//                   msg: "Post updated successfully!",
//                   toastLength: Toast.LENGTH_SHORT,
//                   gravity: ToastGravity.BOTTOM,
//                   timeInSecForIosWeb: 1,
//                 );
//                 Navigator.of(context).pop();
//               },
//               child: Text("Save"),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

// PostsSection.dart

// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'dart:io';
//
// class PostsSection extends StatefulWidget {
//   final DatabaseReference dbRef;
//   final bool isModerator;
//
//   PostsSection({required this.dbRef, this.isModerator = false});
//
//   @override
//   _PostsSectionState createState() => _PostsSectionState();
// }
//
// class _PostsSectionState extends State<PostsSection> {
//   List<Map<String, dynamic>> reportedPostsList = [];
//   Map<String, Map<String, String>> usersCache = {};
//   final ImagePicker _picker = ImagePicker();
//
//   // Mapping of postId to list of reports
//   Map<String, List<Map<String, dynamic>>> reportedPosts = {};
//
//   @override
//   void initState() {
//     super.initState();
//     loadReportsAndPosts();
//   }
//
//   /// Loads reports and fetches associated posts
//   void loadReportsAndPosts() {
//     // Listen to the 'reports' node
//     widget.dbRef.child('reports').onValue.listen((event) async {
//       final data = event.snapshot.value as Map<dynamic, dynamic>?;
//
//       Map<String, List<Map<String, dynamic>>> tempReportedPosts = {};
//
//       if (data != null) {
//         data.forEach((reportId, reportData) {
//           var reportMap = Map<String, dynamic>.from(reportData as Map);
//           if (reportMap['type'] == 'post') {
//             String reportedPostId = reportMap['reportedItemId'];
//             if (!tempReportedPosts.containsKey(reportedPostId)) {
//               tempReportedPosts[reportedPostId] = [];
//             }
//             tempReportedPosts[reportedPostId]!.add(reportMap);
//           }
//         });
//       }
//
//       // Fetch post details for each reported postId
//       List<Map<String, dynamic>> tempReportedPostsList = [];
//
//       for (var postId in tempReportedPosts.keys) {
//         DataSnapshot postSnapshot = await widget.dbRef.child('posts').child(postId).get();
//         if (postSnapshot.exists) {
//           var postData = Map<String, dynamic>.from(postSnapshot.value as Map);
//           postData['postId'] = postId;
//
//           final userId = postData['userId'];
//           if (userId != null) {
//             if (!usersCache.containsKey(userId)) {
//               final userDetails = await getUserDetails(userId);
//               usersCache[userId] = userDetails;
//             }
//             postData['username'] = usersCache[userId]?['username'] ?? 'Unknown User';
//             postData['email'] = usersCache[userId]?['email'] ?? 'No Email';
//           }
//
//           tempReportedPostsList.add(postData);
//         }
//       }
//
//       setState(() {
//         reportedPosts = tempReportedPosts;
//         reportedPostsList = tempReportedPostsList;
//       });
//     });
//   }
//
//   /// Fetches user details based on userId
//   Future<Map<String, String>> getUserDetails(String userId) async {
//     final snapshot = await widget.dbRef.child('users').child(userId).get();
//     if (snapshot.exists) {
//       final data = Map<String, dynamic>.from(snapshot.value as Map);
//       return {
//         'username': data['username'] ?? 'Unknown User',
//         'email': data['email'] ?? 'No Email',
//       };
//     }
//     return {'username': 'Unknown User', 'email': 'No Email'};
//   }
//
//   /// Removes a post from the 'posts' node
//   Future<void> removePost(String postId) async {
//     try {
//       // Remove the post
//       await widget.dbRef.child('posts').child(postId).remove();
//
//       // Optionally, remove the image from Firebase Storage
//       // Assuming images are stored under 'post_images/{postId}.jpg'
//       try {
//         await FirebaseStorage.instance.ref('post_images/$postId.jpg').delete();
//       } catch (e) {
//         // Handle if image doesn't exist
//         print("No image found for post $postId");
//       }
//
//       Fluttertoast.showToast(msg: "Post deleted successfully.", gravity: ToastGravity.BOTTOM);
//     } catch (e) {
//       Fluttertoast.showToast(msg: "Error deleting post: $e", gravity: ToastGravity.BOTTOM);
//     }
//   }
//
//   /// Updates a post's content and optionally its image
//   Future<void> updatePost(String postId, String newContent, String? newImageUrl) async {
//     Map<String, dynamic> updatedData = {'content': newContent};
//     if (newImageUrl != null) {
//       updatedData['imageUrl'] = newImageUrl;
//     }
//     try {
//       await widget.dbRef.child('posts').child(postId).update(updatedData);
//       Fluttertoast.showToast(msg: "Post updated successfully.", gravity: ToastGravity.BOTTOM);
//     } catch (e) {
//       Fluttertoast.showToast(msg: "Error updating post: $e", gravity: ToastGravity.BOTTOM);
//     }
//   }
//
//   /// Uploads an image to Firebase Storage and returns its download URL
//   Future<String?> uploadImage(File image, String postId) async {
//     try {
//       final storageRef = FirebaseStorage.instance.ref().child('post_images/$postId.jpg');
//       final uploadTask = storageRef.putFile(image);
//       final snapshot = await uploadTask.whenComplete(() {});
//       return await snapshot.ref.getDownloadURL();
//     } catch (e) {
//       Fluttertoast.showToast(msg: "Error uploading image: $e", gravity: ToastGravity.BOTTOM);
//       return null;
//     }
//   }
//
//   /// Removes all reports associated with a post
//   Future<void> removeReports(String postId) async {
//     try {
//       // Query reports related to the postId
//       DatabaseReference reportsRef = widget.dbRef.child('reports');
//       Query query = reportsRef.orderByChild('reportedItemId').equalTo(postId);
//       DataSnapshot snapshot = await query.get();
//
//       if (snapshot.exists) {
//         Map<dynamic, dynamic> reports = Map<dynamic, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
//         for (var reportId in reports.keys) {
//           await reportsRef.child(reportId).remove();
//         }
//         Fluttertoast.showToast(msg: 'Reports removed successfully.', gravity: ToastGravity.BOTTOM);
//       } else {
//         Fluttertoast.showToast(msg: 'No reports found for this post.', gravity: ToastGravity.BOTTOM);
//       }
//     } catch (e) {
//       Fluttertoast.showToast(msg: 'Error removing reports: $e', gravity: ToastGravity.BOTTOM);
//     }
//   }
//
//   /// Views all reports associated with a post
//   void viewReports(List<Map<String, dynamic>> postReports) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text('Reports for this Post'),
//           content: Container(
//             width: double.maxFinite,
//             child: postReports.isNotEmpty
//                 ? ListView.builder(
//               shrinkWrap: true,
//               itemCount: postReports.length,
//               itemBuilder: (context, index) {
//                 final report = postReports[index];
//                 return ListTile(
//                   leading: Icon(Icons.report, color: Colors.red),
//                   title: Text('Reporter ID: ${report['reporterId']}'),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('Reason: ${report['reason']}'),
//                       Text('Timestamp: ${DateTime.fromMillisecondsSinceEpoch(report['timestamp'])}'),
//                     ],
//                   ),
//                 );
//               },
//             )
//                 : Text('No reports found for this post.'),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: Text('Close'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   /// Confirms deletion of a post
//   void confirmDeletePost(String postId) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text('Confirm Deletion'),
//           content: Text('Are you sure you want to delete this post? This action cannot be undone.'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(false),
//               child: Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(true),
//               child: Text('Delete', style: TextStyle(color: Colors.red)),
//             ),
//           ],
//         );
//       },
//     );
//
//     if (confirm == true) {
//       await removeReports(postId); // Remove associated reports
//       await removePost(postId); // Delete the post
//     }
//   }
//
//   /// Shows the edit dialog for a post
//   void showEditDialog(Map<String, dynamic> post) {
//     TextEditingController contentController = TextEditingController(text: post['content']);
//     File? newImageFile;
//     String postId = post['postId'];
//
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text("Edit Post"),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // Content TextField
//                 TextField(
//                   controller: contentController,
//                   decoration: InputDecoration(labelText: 'Content'),
//                 ),
//                 SizedBox(height: 10),
//                 // Change Image Button
//                 ElevatedButton(
//                   onPressed: () async {
//                     final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
//                     if (pickedFile != null) {
//                       setState(() {
//                         newImageFile = File(pickedFile.path);
//                       });
//                       Fluttertoast.showToast(msg: "New image selected.", gravity: ToastGravity.BOTTOM);
//                     }
//                   },
//                   child: Text("Change Image"),
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             // Cancel Button
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: Text("Cancel"),
//             ),
//             // Save Button
//             TextButton(
//               onPressed: () async {
//                 String? newImageUrl;
//                 if (newImageFile != null) {
//                   newImageUrl = await uploadImage(newImageFile!, postId);
//                 }
//                 await updatePost(postId, contentController.text, newImageUrl);
//                 Fluttertoast.showToast(
//                   msg: "Post updated successfully!",
//                   toastLength: Toast.LENGTH_SHORT,
//                   gravity: ToastGravity.BOTTOM,
//                   timeInSecForIosWeb: 1,
//                 );
//                 Navigator.of(context).pop();
//               },
//               child: Text("Save"),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: reportedPostsList.isNotEmpty
//           ? ListView.builder(
//         itemCount: reportedPostsList.length,
//         itemBuilder: (context, index) {
//           final post = reportedPostsList[index];
//           final imageUrl = post['imageUrl'] as String?;
//           final username = post['username'] ?? 'Unknown User';
//           final email = post['email'] ?? 'No Email';
//           final postId = post['postId'];
//
//           List<Map<String, dynamic>> postReports = reportedPosts[postId]!;
//
//           return Card(
//             margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10.0),
//             ),
//             elevation: 3,
//             child: Padding(
//               padding: const EdgeInsets.all(12.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Post Image
//                   if (imageUrl != null && imageUrl.isNotEmpty)
//                     Image.network(
//                       imageUrl,
//                       height: 150,
//                       width: double.infinity,
//                       fit: BoxFit.cover,
//                       loadingBuilder: (BuildContext context, Widget child,
//                           ImageChunkEvent? loadingProgress) {
//                         if (loadingProgress == null) return child;
//                         return Center(
//                           child: CircularProgressIndicator(
//                             value: loadingProgress.expectedTotalBytes != null
//                                 ? loadingProgress.cumulativeBytesLoaded /
//                                 loadingProgress.expectedTotalBytes!
//                                 : null,
//                           ),
//                         );
//                       },
//                       errorBuilder: (BuildContext context, Object exception,
//                           StackTrace? stackTrace) {
//                         return Icon(Icons.error);
//                       },
//                     )
//                   else
//                     Container(
//                       height: 150,
//                       color: Colors.grey[300],
//                       child: Icon(Icons.image, size: 50, color: Colors.grey[700]),
//                     ),
//                   SizedBox(height: 8.0),
//
//                   // Post Content
//                   Text(
//                     post['content'] ?? 'No content',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   SizedBox(height: 8.0),
//
//                   // User Information
//                   Text(
//                     'Posted by: $username',
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey[700],
//                     ),
//                   ),
//                   Text(
//                     'Email: $email',
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                   SizedBox(height: 8.0),
//
//                   // Like and Comment Counts
//                   Row(
//                     children: [
//                       Icon(
//                         Icons.favorite,
//                         color: Colors.redAccent,
//                         size: 16,
//                       ),
//                       SizedBox(width: 2),
//                       Text(
//                         '${post['likesCount']}',
//                         style: TextStyle(color: Colors.black, fontSize: 12),
//                       ),
//                       SizedBox(width: 16),
//                       Icon(
//                         Icons.comment,
//                         color: Colors.black,
//                         size: 16,
//                       ),
//                       SizedBox(width: 2),
//                       Text(
//                         '${post['commentsCount']}',
//                         style: TextStyle(color: Colors.black, fontSize: 12),
//                       ),
//                     ],
//                   ),
//
//                   // Action Buttons (Visible Only to Moderators and if the Post is Reported)
//                   if (widget.isModerator)
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.end,
//                       children: [
//                         // View Reports Button
//                         ElevatedButton.icon(
//                           onPressed: () => viewReports(postReports),
//                           icon: Icon(Icons.list),
//                           label: Text('View Reports'),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.blue,
//                           ),
//                         ),
//                         SizedBox(width: 8),
//                         // Delete Post Button
//                         ElevatedButton.icon(
//                           onPressed: () => confirmDeletePost(postId),
//                           icon: Icon(Icons.delete),
//                           label: Text('Delete Post'),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.red,
//                           ),
//                         ),
//                         SizedBox(width: 8),
//                         // Remove Report Button
//                         ElevatedButton.icon(
//                           onPressed: () => removeReports(postId),
//                           icon: Icon(Icons.remove_circle),
//                           label: Text('Remove Report'),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.orange,
//                           ),
//                         ),
//                       ],
//                     ),
//                 ],
//               ),
//             ),
//           );
//         },
//       )
//           : Center(
//         child: Text(
//           widget.isModerator
//               ? 'No reported posts available.'
//               : 'No posts available.',
//           style: TextStyle(fontSize: 16, color: Colors.grey),
//         ),
//       ),
//     );
//   }
// }
// PostsSection.dart

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';

class PostsSection extends StatefulWidget {
  final DatabaseReference dbRef;
  final bool isModerator;

  PostsSection({required this.dbRef, this.isModerator = false});

  @override
  _PostsSectionState createState() => _PostsSectionState();
}

class _PostsSectionState extends State<PostsSection> {
  List<Map<String, dynamic>> reportedPostsList = [];
  Map<String, Map<String, String>> usersCache = {};
  final ImagePicker _picker = ImagePicker();

  // Mapping of postId to list of reports
  Map<String, List<Map<String, dynamic>>> reportedPosts = {};

  @override
  void initState() {
    super.initState();
    loadReportsAndPosts();
  }

  /// Loads reports and fetches associated posts
  void loadReportsAndPosts() {
    // Listen to the 'reports' node
    widget.dbRef.child('reports').onValue.listen((event) async {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      Map<String, List<Map<String, dynamic>>> tempReportedPosts = {};

      if (data != null) {
        data.forEach((reportId, reportData) {
          var reportMap = Map<String, dynamic>.from(reportData as Map);
          if (reportMap['type'] == 'post') {
            String reportedPostId = reportMap['reportedItemId'];
            if (!tempReportedPosts.containsKey(reportedPostId)) {
              tempReportedPosts[reportedPostId] = [];
            }
            tempReportedPosts[reportedPostId]!.add(reportMap);
          }
        });
      }

      // Fetch post details for each reported postId
      List<Map<String, dynamic>> tempReportedPostsList = [];

      for (var postId in tempReportedPosts.keys) {
        DataSnapshot postSnapshot = await widget.dbRef.child('posts').child(postId).get();
        if (postSnapshot.exists) {
          var postData = Map<String, dynamic>.from(postSnapshot.value as Map);
          postData['postId'] = postId;

          final userId = postData['userId'];
          if (userId != null) {
            if (!usersCache.containsKey(userId)) {
              final userDetails = await getUserDetails(userId);
              usersCache[userId] = userDetails;
            }
            postData['username'] = usersCache[userId]?['username'] ?? 'Unknown User';
            postData['email'] = usersCache[userId]?['email'] ?? 'No Email';
          }

          tempReportedPostsList.add(postData);
        }
      }

      setState(() {
        reportedPosts = tempReportedPosts;
        reportedPostsList = tempReportedPostsList;
      });
    });
  }

  /// Fetches user details based on userId
  Future<Map<String, String>> getUserDetails(String userId) async {
    final snapshot = await widget.dbRef.child('users').child(userId).get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return {
        'username': data['username'] ?? 'Unknown User',
        'email': data['email'] ?? 'No Email',
      };
    }
    return {'username': 'Unknown User', 'email': 'No Email'};
  }

  /// Removes a post from the 'posts' node
  Future<void> removePost(String postId) async {
    try {
      // Remove the post
      await widget.dbRef.child('posts').child(postId).remove();

      // Optionally, remove the image from Firebase Storage
      // Assuming images are stored under 'post_images/{postId}.jpg'
      try {
        await FirebaseStorage.instance.ref('post_images/$postId.jpg').delete();
      } catch (e) {
        // Handle if image doesn't exist
        print("No image found for post $postId");
      }

      Fluttertoast.showToast(msg: "Post deleted successfully.", gravity: ToastGravity.BOTTOM);
    } catch (e) {
      Fluttertoast.showToast(msg: "Error deleting post: $e", gravity: ToastGravity.BOTTOM);
    }
  }

  /// Updates a post's content and optionally its image
  Future<void> updatePost(String postId, String newContent, String? newImageUrl) async {
    Map<String, dynamic> updatedData = {'content': newContent};
    if (newImageUrl != null) {
      updatedData['imageUrl'] = newImageUrl;
    }
    try {
      await widget.dbRef.child('posts').child(postId).update(updatedData);
      Fluttertoast.showToast(msg: "Post updated successfully.", gravity: ToastGravity.BOTTOM);
    } catch (e) {
      Fluttertoast.showToast(msg: "Error updating post: $e", gravity: ToastGravity.BOTTOM);
    }
  }

  /// Uploads an image to Firebase Storage and returns its download URL
  Future<String?> uploadImage(File image, String postId) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child('post_images/$postId.jpg');
      final uploadTask = storageRef.putFile(image);
      final snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      Fluttertoast.showToast(msg: "Error uploading image: $e", gravity: ToastGravity.BOTTOM);
      return null;
    }
  }

  /// Removes all reports associated with a post
  Future<void> removeReports(String postId) async {
    try {
      // Query reports related to the postId
      DatabaseReference reportsRef = widget.dbRef.child('reports');
      Query query = reportsRef.orderByChild('reportedItemId').equalTo(postId);
      DataSnapshot snapshot = await query.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> reports = Map<dynamic, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
        for (var reportId in reports.keys) {
          await reportsRef.child(reportId).remove();
        }
        Fluttertoast.showToast(msg: 'Reports removed successfully.', gravity: ToastGravity.BOTTOM);
      } else {
        Fluttertoast.showToast(msg: 'No reports found for this post.', gravity: ToastGravity.BOTTOM);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error removing reports: $e', gravity: ToastGravity.BOTTOM);
    }
  }

  /// Views all reports associated with a post
  void viewReports(List<Map<String, dynamic>> postReports) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Reports for this Post'),
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
                : Text('No reports found for this post.'),
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

  /// Confirms deletion of a post
  void confirmDeletePost(String postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this post? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await removeReports(postId); // Remove associated reports
      await removePost(postId); // Delete the post
    }
  }

  /// Shows the edit dialog for a post
  void showEditDialog(Map<String, dynamic> post) {
    TextEditingController contentController = TextEditingController(text: post['content']);
    File? newImageFile;
    String postId = post['postId'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Post"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Content TextField
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(labelText: 'Content'),
                ),
                SizedBox(height: 10),
                // Change Image Button
                ElevatedButton(
                  onPressed: () async {
                    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setState(() {
                        newImageFile = File(pickedFile.path);
                      });
                      Fluttertoast.showToast(msg: "New image selected.", gravity: ToastGravity.BOTTOM);
                    }
                  },
                  child: Text("Change Image"),
                ),
              ],
            ),
          ),
          actions: [
            // Cancel Button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            // Save Button
            TextButton(
              onPressed: () async {
                String? newImageUrl;
                if (newImageFile != null) {
                  newImageUrl = await uploadImage(newImageFile!, postId);
                }
                await updatePost(postId, contentController.text, newImageUrl);
                Fluttertoast.showToast(
                  msg: "Post updated successfully!",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  timeInSecForIosWeb: 1,
                );
                Navigator.of(context).pop();
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: reportedPostsList.isNotEmpty
          ? ListView.builder(
        itemCount: reportedPostsList.length,
        itemBuilder: (context, index) {
          final post = reportedPostsList[index];
          final imageUrl = post['imageUrl'] as String?;
          final username = post['username'] ?? 'Unknown User';
          final email = post['email'] ?? 'No Email';
          final postId = post['postId'];

          List<Map<String, dynamic>> postReports = reportedPosts[postId]!;

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
                  // Post Image
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (BuildContext context, Widget child,
                          ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (BuildContext context, Object exception,
                          StackTrace? stackTrace) {
                        return Icon(Icons.error);
                      },
                    )
                  else
                    Container(
                      height: 150,
                      color: Colors.grey[300],
                      child: Icon(Icons.image, size: 50, color: Colors.grey[700]),
                    ),
                  SizedBox(height: 8.0),

                  // Post Content
                  Text(
                    post['content'] ?? 'No content',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.0),

                  // User Information
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

                  // Like and Comment Counts
                  Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        color: Colors.redAccent,
                        size: 16,
                      ),
                      SizedBox(width: 2),
                      Text(
                        '${post['likesCount']}',
                        style: TextStyle(color: Colors.black, fontSize: 12),
                      ),
                      SizedBox(width: 16),
                      Icon(
                        Icons.comment,
                        color: Colors.black,
                        size: 16,
                      ),
                      SizedBox(width: 2),
                      Text(
                        '${post['commentsCount']}',
                        style: TextStyle(color: Colors.black, fontSize: 12),
                      ),
                    ],
                  ),

                  // Action Buttons (Visible Only to Moderators)

                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // View Reports Button
                        ElevatedButton.icon(
                          onPressed: () => viewReports(postReports),
                          icon: Icon(Icons.list),
                          label: Text('View Reports'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                        ),
                        SizedBox(width: 4),
                        // Delete Post Button
                        ElevatedButton.icon(
                          onPressed: () => confirmDeletePost(postId),
                          icon: Icon(Icons.delete),
                          label: Text('Delete Post'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                        SizedBox(width: 4),
                        // Remove Report Button
                        ElevatedButton.icon(
                          onPressed: () => removeReports(postId),
                          icon: Icon(Icons.remove_circle),
                          label: Text('Dismiss Report'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                        ),
                        SizedBox(width: 4,)
                      ],
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
              ? 'No reported posts available.'
              : 'No posts available.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}
