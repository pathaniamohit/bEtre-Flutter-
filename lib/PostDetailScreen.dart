// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// class PostDetailScreen extends StatefulWidget {
//   final Map<String, dynamic> post;
//   final User? currentUser;
//
//   PostDetailScreen({required this.post, this.currentUser});
//
//   @override
//   _PostDetailScreenState createState() => _PostDetailScreenState();
// }
//
// class _PostDetailScreenState extends State<PostDetailScreen> {
//   List<Map<String, dynamic>> _comments = [];
//   TextEditingController _commentController = TextEditingController();
//   late DatabaseReference _commentsRef;
//   late DatabaseReference _usersRef;
//   bool isPostLikedByCurrentUser = false;
//   int likesCount = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     _commentsRef = FirebaseDatabase.instance
//         .ref()
//         .child("posts")
//         .child(widget.post['postId'])
//         .child("comments");
//     _usersRef = FirebaseDatabase.instance.ref().child('users');
//     isPostLikedByCurrentUser = widget.post['isLikedByCurrentUser'];
//     likesCount = widget.post['likesCount'];
//     _loadComments();
//   }
//
//   Future<void> _loadComments() async {
//     _commentsRef.onValue.listen((event) async {
//       List<Map<String, dynamic>> comments = [];
//       for (var commentSnapshot in event.snapshot.children) {
//         var commentData = Map<String, dynamic>.from(commentSnapshot.value as Map);
//         commentData['commentId'] = commentSnapshot.key;
//
//         // Fetch commenter username and profile image
//         String commenterId = commentData['userId'];
//         DataSnapshot userSnapshot = await _usersRef.child(commenterId).get();
//         if (userSnapshot.exists) {
//           Map<String, dynamic> userData = Map<String, dynamic>.from(userSnapshot.value as Map);
//           commentData['username'] = userData['username'] ?? 'Unknown User';
//           commentData['userProfileImageUrl'] = userData['profileImageUrl'] ?? null;
//         } else {
//           commentData['username'] = 'Unknown User';
//           commentData['userProfileImageUrl'] = null;
//         }
//
//         comments.add(commentData);
//       }
//       setState(() {
//         _comments = comments;
//       });
//     });
//   }
//
//   Future<void> _addComment() async {
//     if (widget.currentUser != null && _commentController.text.trim().isNotEmpty) {
//       String newCommentId = _commentsRef.push().key!;
//       final newComment = {
//         'userId': widget.currentUser!.uid,
//         'content': _commentController.text.trim(),
//         'timestamp': ServerValue.timestamp,
//       };
//       await _commentsRef.child(newCommentId).set(newComment);
//
//       _commentController.clear();
//     }
//   }
//
//   Future<void> _deleteComment(String commentId) async {
//     if (widget.currentUser != null) {
//       // Retrieve the comment to check ownership
//       DataSnapshot commentSnapshot = await _commentsRef.child(commentId).get();
//       if (commentSnapshot.exists) {
//         Map<String, dynamic> commentData = Map<String, dynamic>.from(commentSnapshot.value as Map);
//         String commentUserId = commentData['userId'];
//         String postOwnerId = widget.post['userId'];
//
//         // Check if current user is the comment owner or the post owner
//         if (widget.currentUser!.uid == commentUserId || widget.currentUser!.uid == postOwnerId) {
//           await _commentsRef.child(commentId).remove();
//         } else {
//           // Show an error message
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('You cannot delete this comment')),
//           );
//         }
//       }
//     }
//   }
//
//   Future<void> _toggleLike(String postId, bool isCurrentlyLiked) async {
//     if (widget.currentUser != null) {
//       DatabaseReference likesRef = FirebaseDatabase.instance
//           .ref()
//           .child("posts")
//           .child(postId)
//           .child("likes")
//           .child(widget.currentUser!.uid);
//
//       if (isCurrentlyLiked) {
//         // Unlike the post
//         await likesRef.remove();
//         setState(() {
//           widget.post['isLikedByCurrentUser'] = false;
//           widget.post['likesCount'] -= 1;
//           isPostLikedByCurrentUser = false;
//           likesCount -= 1;
//         });
//       } else {
//         // Like the post
//         await likesRef.set(true);
//         setState(() {
//           widget.post['isLikedByCurrentUser'] = true;
//           widget.post['likesCount'] += 1;
//           isPostLikedByCurrentUser = true;
//           likesCount += 1;
//         });
//       }
//     }
//   }
//
//   Future<void> _showLikes() async {
//     DatabaseReference likesRef = FirebaseDatabase.instance
//         .ref()
//         .child("posts")
//         .child(widget.post['postId'])
//         .child("likes");
//
//     DataSnapshot likesSnapshot = await likesRef.get();
//     if (likesSnapshot.exists) {
//       List<String> userIds = likesSnapshot.children.map((e) => e.key!).toList();
//       List<String> usernames = [];
//
//       for (String userId in userIds) {
//         DataSnapshot userSnapshot = await _usersRef.child(userId).child('username').get();
//         if (userSnapshot.exists) {
//           usernames.add(userSnapshot.value as String);
//         } else {
//           usernames.add('Unknown User');
//         }
//       }
//
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: Text('Likes'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: usernames.map((username) => Text(username)).toList(),
//           ),
//         ),
//       );
//     }
//   }
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     String postOwnerId = widget.post['userId'];
//     bool isPostOwner = widget.currentUser?.uid == postOwnerId;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Post Details'),
//         actions: [],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView(
//               padding: EdgeInsets.zero,
//               children: [
//                 if (widget.post['imageUrl'] != null && widget.post['imageUrl'] != '')
//                   Image.network(widget.post['imageUrl']),
//                 SizedBox(height: 8),
//
//                 // Display location if available
//                 if (widget.post['location'] != null && widget.post['location'].isNotEmpty)
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                     child: Row(
//                       children: [
//                         Icon(Icons.location_on, color: Colors.grey),
//                         SizedBox(width: 4),
//                         Expanded(
//                           child: Text(
//                             widget.post['location'],
//                             style: TextStyle(fontSize: 16, color: Colors.blue),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                 SizedBox(height: 8),
//                 if (widget.post['content'] != null && widget.post['content'] != '')
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                     child: Text(widget.post['content']),
//                   ),
//                 SizedBox(height: 8),
//                 Row(
//                   children: [
//                     IconButton(
//                       icon: Icon(
//                         isPostLikedByCurrentUser ? Icons.favorite : Icons.favorite_border,
//                         color: isPostLikedByCurrentUser ? Colors.red : Colors.black,
//                       ),
//                       onPressed: () => _toggleLike(widget.post['postId'], isPostLikedByCurrentUser),
//                     ),
//                     GestureDetector(
//                       onTap: _showLikes,
//                       child: Text('$likesCount likes'),
//                     ),
//                   ],
//                 ),
//                 Divider(),
//                 // Comments Section
//                 ListView.builder(
//                   shrinkWrap: true,
//                   physics: NeverScrollableScrollPhysics(),
//                   itemCount: _comments.length,
//                   itemBuilder: (context, index) {
//                     var comment = _comments[index];
//                     bool isCommentByCurrentUser = comment['userId'] == widget.currentUser?.uid;
//                     bool canDeleteComment = isCommentByCurrentUser || isPostOwner;
//
//                     return ListTile(
//                       leading: CircleAvatar(
//                         backgroundImage: comment['userProfileImageUrl'] != null
//                             ? NetworkImage(comment['userProfileImageUrl'])
//                             : AssetImage('assets/profile_placeholder.png') as ImageProvider,
//                       ),
//                       title: Text(comment['username']),
//                       subtitle: Text(comment['content']),
//                       trailing: canDeleteComment
//                           ? IconButton(
//                         icon: Icon(Icons.delete),
//                         onPressed: () => _deleteComment(comment['commentId']),
//                       )
//                           : null,
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ),
//           Divider(height: 1),
//           Container(
//             color: Colors.white,
//             padding: EdgeInsets.symmetric(horizontal: 8.0),
//             child: SafeArea(
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: _commentController,
//                       decoration: InputDecoration(
//                         hintText: 'Add a comment...',
//                         border: InputBorder.none,
//                       ),
//                     ),
//                   ),
//                   IconButton(
//                     icon: Icon(Icons.send),
//                     onPressed: _addComment,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:geocoding/geocoding.dart';
//
// class PostDetailScreen extends StatefulWidget {
//   final Map<String, dynamic> post;
//   final User? currentUser;
//
//   PostDetailScreen({required this.post, this.currentUser});
//
//   @override
//   _PostDetailScreenState createState() => _PostDetailScreenState();
// }
//
// class _PostDetailScreenState extends State<PostDetailScreen> {
//   List<Map<String, dynamic>> _comments = [];
//   TextEditingController _commentController = TextEditingController();
//   late DatabaseReference _commentsRef;
//   late DatabaseReference _usersRef;
//   bool isPostLikedByCurrentUser = false;
//   int likesCount = 0;
//
//   String _humanReadableLocation = '';
//
//   @override
//   void initState() {
//     super.initState();
//     _commentsRef = FirebaseDatabase.instance
//         .ref()
//         .child("posts")
//         .child(widget.post['postId'])
//         .child("comments");
//     _usersRef = FirebaseDatabase.instance.ref().child('users');
//     isPostLikedByCurrentUser = widget.post['isLikedByCurrentUser'];
//     likesCount = widget.post['likesCount'];
//
//     _loadComments();
//
//     // Convert coordinates to human-readable address
//     if (widget.post['location'] != null) {
//       if (widget.post['location'] is Map) {
//         // Location is stored as a Map (latitude and longitude)
//         Map<String, dynamic> locationData = Map<String, dynamic>.from(widget.post['location']);
//         _convertCoordinatesToAddress(locationData);
//       } else if (widget.post['location'] is String) {
//         // Location is stored as a String, possibly a URL
//         _parseLocationStringAndConvert(widget.post['location']);
//       }
//     } else {
//       _humanReadableLocation = '';
//     }
//   }
//
//   Future<void> _convertCoordinatesToAddress(Map<String, dynamic> locationData) async {
//     try {
//       double latitude = locationData['latitude'];
//       double longitude = locationData['longitude'];
//
//       List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
//       if (placemarks.isNotEmpty) {
//         Placemark place = placemarks.first;
//         setState(() {
//           _humanReadableLocation = '${place.locality}, ${place.country}';
//         });
//       } else {
//         setState(() {
//           _humanReadableLocation = 'Unknown location';
//         });
//       }
//     } catch (e) {
//       print('Error during reverse geocoding: $e');
//       setState(() {
//         _humanReadableLocation = 'Location not available';
//       });
//     }
//   }
//
//   void _parseLocationStringAndConvert(String locationString) {
//     try {
//       Uri uri = Uri.parse(locationString);
//       String? query = uri.queryParameters['q'];
//       if (query != null) {
//         List<String> coords = query.split(',');
//         if (coords.length == 2) {
//           double latitude = double.parse(coords[0]);
//           double longitude = double.parse(coords[1]);
//           _convertCoordinatesToAddress({'latitude': latitude, 'longitude': longitude});
//         } else {
//           setState(() {
//             _humanReadableLocation = 'Location not available';
//           });
//         }
//       } else {
//         setState(() {
//           _humanReadableLocation = 'Location not available';
//         });
//       }
//     } catch (e) {
//       print('Error parsing location string: $e');
//       setState(() {
//         _humanReadableLocation = 'Location not available';
//       });
//     }
//   }
//
//   // ... Existing methods like _loadComments(), _addComment(), etc.
//
//     Future<void> _loadComments() async {
//     _commentsRef.onValue.listen((event) async {
//       List<Map<String, dynamic>> comments = [];
//       for (var commentSnapshot in event.snapshot.children) {
//         var commentData = Map<String, dynamic>.from(commentSnapshot.value as Map);
//         commentData['commentId'] = commentSnapshot.key;
//
//         // Fetch commenter username and profile image
//         String commenterId = commentData['userId'];
//         DataSnapshot userSnapshot = await _usersRef.child(commenterId).get();
//         if (userSnapshot.exists) {
//           Map<String, dynamic> userData = Map<String, dynamic>.from(userSnapshot.value as Map);
//           commentData['username'] = userData['username'] ?? 'Unknown User';
//           commentData['userProfileImageUrl'] = userData['profileImageUrl'] ?? null;
//         } else {
//           commentData['username'] = 'Unknown User';
//           commentData['userProfileImageUrl'] = null;
//         }
//
//         comments.add(commentData);
//       }
//       setState(() {
//         _comments = comments;
//       });
//     });
//   }
//
//   Future<void> _addComment() async {
//     if (widget.currentUser != null && _commentController.text.trim().isNotEmpty) {
//       String newCommentId = _commentsRef.push().key!;
//       final newComment = {
//         'userId': widget.currentUser!.uid,
//         'content': _commentController.text.trim(),
//         'timestamp': ServerValue.timestamp,
//       };
//       await _commentsRef.child(newCommentId).set(newComment);
//
//       _commentController.clear();
//     }
//   }
//
//   Future<void> _deleteComment(String commentId) async {
//     if (widget.currentUser != null) {
//       // Retrieve the comment to check ownership
//       DataSnapshot commentSnapshot = await _commentsRef.child(commentId).get();
//       if (commentSnapshot.exists) {
//         Map<String, dynamic> commentData = Map<String, dynamic>.from(commentSnapshot.value as Map);
//         String commentUserId = commentData['userId'];
//         String postOwnerId = widget.post['userId'];
//
//         // Check if current user is the comment owner or the post owner
//         if (widget.currentUser!.uid == commentUserId || widget.currentUser!.uid == postOwnerId) {
//           await _commentsRef.child(commentId).remove();
//         } else {
//           // Show an error message
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('You cannot delete this comment')),
//           );
//         }
//       }
//     }
//   }
//
//   Future<void> _toggleLike(String postId, bool isCurrentlyLiked) async {
//     if (widget.currentUser != null) {
//       DatabaseReference likesRef = FirebaseDatabase.instance
//           .ref()
//           .child("posts")
//           .child(postId)
//           .child("likes")
//           .child(widget.currentUser!.uid);
//
//       if (isCurrentlyLiked) {
//         // Unlike the post
//         await likesRef.remove();
//         setState(() {
//           widget.post['isLikedByCurrentUser'] = false;
//           widget.post['likesCount'] -= 1;
//           isPostLikedByCurrentUser = false;
//           likesCount -= 1;
//         });
//       } else {
//         // Like the post
//         await likesRef.set(true);
//         setState(() {
//           widget.post['isLikedByCurrentUser'] = true;
//           widget.post['likesCount'] += 1;
//           isPostLikedByCurrentUser = true;
//           likesCount += 1;
//         });
//       }
//     }
//   }
//
//   Future<void> _showLikes() async {
//     DatabaseReference likesRef = FirebaseDatabase.instance
//         .ref()
//         .child("posts")
//         .child(widget.post['postId'])
//         .child("likes");
//
//     DataSnapshot likesSnapshot = await likesRef.get();
//     if (likesSnapshot.exists) {
//       List<String> userIds = likesSnapshot.children.map((e) => e.key!).toList();
//       List<String> usernames = [];
//
//       for (String userId in userIds) {
//         DataSnapshot userSnapshot = await _usersRef.child(userId).child('username').get();
//         if (userSnapshot.exists) {
//           usernames.add(userSnapshot.value as String);
//         } else {
//           usernames.add('Unknown User');
//         }
//       }
//
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: Text('Likes'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: usernames.map((username) => Text(username)).toList(),
//           ),
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     String postOwnerId = widget.post['userId'];
//     bool isPostOwner = widget.currentUser?.uid == postOwnerId;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Post Details'),
//         actions: [],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView(
//               padding: EdgeInsets.zero,
//               children: [
//                 if (widget.post['imageUrl'] != null && widget.post['imageUrl'] != '')
//                   Image.network(widget.post['imageUrl']),
//                 SizedBox(height: 8),
//
//                 // Display location if available
//                 if (_humanReadableLocation.isNotEmpty)
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                     child: Row(
//                       children: [
//                         Icon(Icons.location_on, color: Colors.grey),
//                         SizedBox(width: 4),
//                         Expanded(
//                           child: Text(
//                             _humanReadableLocation,
//                             style: TextStyle(fontSize: 16, color: Colors.blue),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                 SizedBox(height: 8),
//                 if (widget.post['content'] != null && widget.post['content'] != '')
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                     child: Text(widget.post['content']),
//                   ),
//                 SizedBox(height: 8),
//                 Row(
//                   children: [
//                     IconButton(
//                       icon: Icon(
//                         isPostLikedByCurrentUser ? Icons.favorite : Icons.favorite_border,
//                         color: isPostLikedByCurrentUser ? Colors.red : Colors.black,
//                       ),
//                       onPressed: () => _toggleLike(widget.post['postId'], isPostLikedByCurrentUser),
//                     ),
//                     GestureDetector(
//                       onTap: _showLikes,
//                       child: Text('$likesCount likes'),
//                     ),
//                   ],
//                 ),
//                 Divider(),
//                 // Comments Section
//                 ListView.builder(
//                   shrinkWrap: true,
//                   physics: NeverScrollableScrollPhysics(),
//                   itemCount: _comments.length,
//                   itemBuilder: (context, index) {
//                     var comment = _comments[index];
//                     bool isCommentByCurrentUser = comment['userId'] == widget.currentUser?.uid;
//                     bool canDeleteComment = isCommentByCurrentUser || isPostOwner;
//
//                     return ListTile(
//                       leading: CircleAvatar(
//                         backgroundImage: comment['userProfileImageUrl'] != null
//                             ? NetworkImage(comment['userProfileImageUrl'])
//                             : AssetImage('assets/profile_placeholder.png') as ImageProvider,
//                       ),
//                       title: Text(comment['username']),
//                       subtitle: Text(comment['content']),
//                       trailing: canDeleteComment
//                           ? IconButton(
//                         icon: Icon(Icons.delete),
//                         onPressed: () => _deleteComment(comment['commentId']),
//                       )
//                           : null,
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ),
//           Divider(height: 1),
//           Container(
//             color: Colors.white,
//             padding: EdgeInsets.symmetric(horizontal: 8.0),
//             child: SafeArea(
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: _commentController,
//                       decoration: InputDecoration(
//                         hintText: 'Add a comment...',
//                         border: InputBorder.none,
//                       ),
//                     ),
//                   ),
//                   IconButton(
//                     icon: Icon(Icons.send),
//                     onPressed: _addComment,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// PostDetailScreen.dart

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  final User? currentUser;

  PostDetailScreen({required this.post, this.currentUser});

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  List<Map<String, dynamic>> _comments = [];
  TextEditingController _commentController = TextEditingController();
  late DatabaseReference _commentsRef;
  late DatabaseReference _usersRef;
  bool isPostLikedByCurrentUser = false;
  int likesCount = 0;

  String _humanReadableLocation = '';

  @override
  void initState() {
    super.initState();
    _commentsRef = FirebaseDatabase.instance
        .ref()
        .child("posts")
        .child(widget.post['postId'])
        .child("comments");
    _usersRef = FirebaseDatabase.instance.ref().child('users');
    isPostLikedByCurrentUser = widget.post['isLikedByCurrentUser'];
    likesCount = widget.post['likesCount'];

    _loadComments();

    // Convert coordinates to human-readable address
    if (widget.post['location'] != null) {
      if (widget.post['location'] is Map) {
        // Location is stored as a Map (latitude and longitude)
        Map<String, dynamic> locationData = Map<String, dynamic>.from(widget.post['location']);
        _convertCoordinatesToAddress(locationData);
      } else if (widget.post['location'] is String) {
        // Location is stored as a String, possibly a URL
        _parseLocationStringAndConvert(widget.post['location']);
      }
    } else {
      _humanReadableLocation = '';
    }
  }

  Future<void> _convertCoordinatesToAddress(Map<String, dynamic> locationData) async {
    try {
      double latitude = locationData['latitude'];
      double longitude = locationData['longitude'];

      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _humanReadableLocation = '${place.locality}, ${place.country}';
        });
      } else {
        setState(() {
          _humanReadableLocation = 'Unknown location';
        });
      }
    } catch (e) {
      print('Error during reverse geocoding: $e');
      setState(() {
        _humanReadableLocation = 'Location not available';
      });
    }
  }

  void _parseLocationStringAndConvert(String locationString) {
    try {
      Uri uri = Uri.parse(locationString);
      String? query = uri.queryParameters['q'];
      if (query != null) {
        List<String> coords = query.split(',');
        if (coords.length == 2) {
          double latitude = double.parse(coords[0]);
          double longitude = double.parse(coords[1]);
          _convertCoordinatesToAddress({'latitude': latitude, 'longitude': longitude});
        } else {
          setState(() {
            _humanReadableLocation = 'Location not available';
          });
        }
      } else {
        setState(() {
          _humanReadableLocation = 'Location not available';
        });
      }
    } catch (e) {
      print('Error parsing location string: $e');
      setState(() {
        _humanReadableLocation = 'Location not available';
      });
    }
  }

  Future<void> _loadComments() async {
    _commentsRef.onValue.listen((event) async {
      List<Map<String, dynamic>> comments = [];
      for (var commentSnapshot in event.snapshot.children) {
        var commentData = Map<String, dynamic>.from(commentSnapshot.value as Map);
        commentData['commentId'] = commentSnapshot.key;

        // Fetch commenter username and profile image
        String commenterId = commentData['userId'];
        DataSnapshot userSnapshot = await _usersRef.child(commenterId).get();
        if (userSnapshot.exists) {
          Map<String, dynamic> userData = Map<String, dynamic>.from(userSnapshot.value as Map);
          commentData['username'] = userData['username'] ?? 'Unknown User';
          commentData['userProfileImageUrl'] = userData['profileImageUrl'] ?? null;
        } else {
          commentData['username'] = 'Unknown User';
          commentData['userProfileImageUrl'] = null;
        }

        comments.add(commentData);
      }
      setState(() {
        _comments = comments;
      });
    });
  }

  Future<void> _addComment() async {
    if (widget.currentUser != null && _commentController.text.trim().isNotEmpty) {
      String newCommentId = _commentsRef.push().key!;
      final newComment = {
        'userId': widget.currentUser!.uid,
        'content': _commentController.text.trim(),
        'timestamp': ServerValue.timestamp,
      };
      await _commentsRef.child(newCommentId).set(newComment);

      // Notify the post owner
      _notifyPostOwner('commented on your post', newComment);

      _commentController.clear();
    }
  }

  Future<void> _deleteComment(String commentId) async {
    if (widget.currentUser != null) {
      // Retrieve the comment to check ownership
      DataSnapshot commentSnapshot = await _commentsRef.child(commentId).get();
      if (commentSnapshot.exists) {
        Map<String, dynamic> commentData = Map<String, dynamic>.from(commentSnapshot.value as Map);
        String commentUserId = commentData['userId'];
        String postOwnerId = widget.post['userId'];

        // Check if current user is the comment owner or the post owner
        if (widget.currentUser!.uid == commentUserId || widget.currentUser!.uid == postOwnerId) {
          await _commentsRef.child(commentId).remove();
        } else {
          // Show an error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You cannot delete this comment')),
          );
        }
      }
    }
  }

  Future<void> _toggleLike(String postId, bool isCurrentlyLiked) async {
    if (widget.currentUser != null) {
      DatabaseReference likesRef = FirebaseDatabase.instance
          .ref()
          .child("posts")
          .child(postId)
          .child("likes")
          .child(widget.currentUser!.uid);

      if (isCurrentlyLiked) {
        // Unlike the post
        await likesRef.remove();
        setState(() {
          widget.post['isLikedByCurrentUser'] = false;
          widget.post['likesCount'] -= 1;
          isPostLikedByCurrentUser = false;
          likesCount -= 1;
        });
      } else {
        // Like the post
        await likesRef.set(true);
        setState(() {
          widget.post['isLikedByCurrentUser'] = true;
          widget.post['likesCount'] += 1;
          isPostLikedByCurrentUser = true;
          likesCount += 1;
        });

        // Notify the post owner
        _notifyPostOwner('liked your post', widget.post);
      }
    }
  }

  void _notifyPostOwner(String action, Map<String, dynamic> post) async {
    final postOwnerId = post['userId'];
    final currentUserId = widget.currentUser!.uid;
    if (postOwnerId == currentUserId) return; // Don't notify if the user is liking their own post

    // Replace 'inbox' with 'notifications'
    final notificationsRef = FirebaseDatabase.instance.ref().child('notifications').child(postOwnerId);
    await notificationsRef.push().set({
      'fromUserId': currentUserId,
      'action': action,
      'postId': post['postId'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _showLikes() async {
    DatabaseReference likesRef = FirebaseDatabase.instance
        .ref()
        .child("posts")
        .child(widget.post['postId'])
        .child("likes");

    DataSnapshot likesSnapshot = await likesRef.get();
    if (likesSnapshot.exists) {
      List<String> userIds = likesSnapshot.children.map((e) => e.key!).toList();
      List<String> usernames = [];

      for (String userId in userIds) {
        DataSnapshot userSnapshot = await _usersRef.child(userId).child('username').get();
        if (userSnapshot.exists) {
          usernames.add(userSnapshot.value as String);
        } else {
          usernames.add('Unknown User');
        }
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Likes'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: usernames.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(usernames[index]),
                );
              },
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String postOwnerId = widget.post['userId'];
    bool isPostOwner = widget.currentUser?.uid == postOwnerId;

    return Scaffold(
      appBar: AppBar(
        title: Text('Post Details'),
        actions: [],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (widget.post['imageUrl'] != null && widget.post['imageUrl'] != '')
                  Image.network(widget.post['imageUrl']),
                SizedBox(height: 8),

                // Display location if available
                if (_humanReadableLocation.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.grey),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _humanReadableLocation,
                            style: TextStyle(fontSize: 16, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: 8),
                if (widget.post['content'] != null && widget.post['content'] != '')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(widget.post['content']),
                  ),
                SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isPostLikedByCurrentUser ? Icons.favorite : Icons.favorite_border,
                        color: isPostLikedByCurrentUser ? Colors.red : Colors.black,
                      ),
                      onPressed: () => _toggleLike(widget.post['postId'], isPostLikedByCurrentUser),
                    ),
                    GestureDetector(
                      onTap: _showLikes,
                      child: Text('$likesCount likes'),
                    ),
                  ],
                ),
                Divider(),
                // Comments Section
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    var comment = _comments[index];
                    bool isCommentByCurrentUser = comment['userId'] == widget.currentUser?.uid;
                    bool canDeleteComment = isCommentByCurrentUser || isPostOwner;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: comment['userProfileImageUrl'] != null
                            ? NetworkImage(comment['userProfileImageUrl'])
                            : AssetImage('assets/profile_placeholder.png') as ImageProvider,
                      ),
                      title: Text(comment['username']),
                      subtitle: Text(comment['content']),
                      trailing: canDeleteComment
                          ? IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deleteComment(comment['commentId']),
                      )
                          : null,
                    );
                  },
                ),
              ],
            ),
          ),
          Divider(height: 1),
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        border: InputBorder.none,
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
          ),
        ],
      ),
    );
  }
}
