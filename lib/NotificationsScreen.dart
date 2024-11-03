// NotificationsScreen.dart

// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'PostDetailScreen.dart';
//
// class NotificationsScreen extends StatefulWidget {
//   @override
//   _NotificationsScreenState createState() => _NotificationsScreenState();
// }
//
// class _NotificationsScreenState extends State<NotificationsScreen> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
//   User? _user;
//
//   List<Map<String, dynamic>> _notifications = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _user = _auth.currentUser;
//     if (_user != null) {
//       _loadNotifications();
//     }
//   }
//
//   /// Loads notifications from the 'notifications' node
//   void _loadNotifications() {
//     _dbRef.child('notifications').child(_user!.uid).orderByChild('timestamp').onValue.listen((event) {
//       List<Map<String, dynamic>> notifications = [];
//       if (event.snapshot.exists) {
//         for (var notificationSnapshot in event.snapshot.children) {
//           Map<String, dynamic> notificationData = Map<String, dynamic>.from(notificationSnapshot.value as Map);
//           notificationData['notificationId'] = notificationSnapshot.key;
//           notifications.add(notificationData);
//         }
//         // Sort notifications by timestamp descending
//         notifications.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
//
//         setState(() {
//           _notifications = notifications;
//         });
//       } else {
//         setState(() {
//           _notifications = [];
//         });
//       }
//     }, onError: (error) {
//       print('Error loading notifications: $error');
//       // Optionally, display an error message to the user
//     });
//   }
//
//   /// Fetches user information based on userId
//   Future<Map<String, dynamic>> _getUserInfo(String userId) async {
//     DataSnapshot snapshot = await _dbRef.child('users').child(userId).get();
//     if (snapshot.exists) {
//       Map<String, dynamic> userData = Map<String, dynamic>.from(snapshot.value as Map);
//       return userData;
//     } else {
//       return {'username': 'Unknown User', 'profileImageUrl': null};
//     }
//   }
//
//   /// Navigates to PostDetailScreen
//   void _viewPostDetails(String postId) async {
//     DataSnapshot postSnapshot = await _dbRef.child('posts').child(postId).get();
//     if (postSnapshot.exists) {
//       Map<String, dynamic> postData = Map<String, dynamic>.from(postSnapshot.value as Map);
//       postData['postId'] = postId;
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) => PostDetailScreen(post: postData, currentUser: _user)),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Post not found')),
//       );
//     }
//   }
//
//   /// Marks a notification as read
//   Future<void> _markAsRead(String notificationId) async {
//     await _dbRef.child('notifications').child(_user!.uid).child(notificationId).update({'read': true});
//   }
//
//   /// Builds individual notification tiles based on their type
//   Widget _buildNotificationTile(Map<String, dynamic> notification) {
//     bool isWarning = notification['type'] == 'warning';
//     String action = notification['action'] ?? '';
//     String fromUserId = notification['fromUserId'] ?? '';
//     String? postId = notification['postId'];
//     bool isRead = notification['read'] ?? false;
//
//     return FutureBuilder(
//       future: _getUserInfo(fromUserId),
//       builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return ListTile(
//             leading: CircleAvatar(child: CircularProgressIndicator()),
//             title: Text('Loading...'),
//           );
//         } else if (snapshot.hasError || !snapshot.hasData) {
//           return ListTile(
//             leading: CircleAvatar(child: Icon(Icons.error)),
//             title: Text('Error loading user'),
//           );
//         } else {
//           String username = snapshot.data!['username'] ?? 'Unknown User';
//           String? profileImageUrl = snapshot.data!['profileImageUrl'];
//           String? message = '';
//
//           // Determine the message based on the action
//           switch (action) {
//             case 'liked your post':
//               message = '$username liked your post.';
//               break;
//             case 'unliked your post':
//               message = '$username unliked your post.';
//               break;
//             case 'commented on your post':
//               String commentContent = notification['commentContent'] ?? '';
//               message = '$username commented: "$commentContent"';
//               break;
//             case 'started following you':
//               message = '$username started following you.';
//               break;
//             case 'unfollowed you':
//               message = '$username unfollowed you.';
//               break;
//             case 'warning':
//               message = notification['message'] ?? 'You have received a warning.';
//               break;
//             default:
//               message = 'You have a new notification.';
//           }
//
//           // Optionally, handle navigation based on action
//           void _handleTap() {
//             if (!isWarning && postId != null) {
//               _viewPostDetails(postId);
//               _markAsRead(notification['notificationId']);
//             }
//             // Add more navigation based on different actions if needed
//           }
//
//           return ListTile(
//             leading: isWarning
//                 ? CircleAvatar(
//               backgroundColor: Colors.red,
//               child: Icon(Icons.warning, color: Colors.white),
//             )
//                 : CircleAvatar(
//               backgroundImage: profileImageUrl != null
//                   ? NetworkImage(profileImageUrl)
//                   : AssetImage('assets/profile_placeholder.png') as ImageProvider,
//             ),
//             // title: Text(
//             //   isWarning ? 'Warning from Admin' : message,
//             //   style: TextStyle(
//             //     fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
//             //     color: isWarning ? Colors.red : Colors.black,
//             //   ),
//             // ),
//             subtitle: Text(
//               DateTime.fromMillisecondsSinceEpoch(notification['timestamp']).toLocal().toString(),
//               style: TextStyle(fontSize: 12, color: Colors.grey),
//             ),
//             trailing: !isRead
//                 ? Icon(Icons.circle, color: Colors.blue, size: 10)
//                 : null,
//             onTap: isWarning ? null : _handleTap,
//           );
//         }
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Notifications'),
//       ),
//       body: _notifications.isNotEmpty
//           ? ListView.builder(
//         itemCount: _notifications.length,
//         itemBuilder: (context, index) {
//           var notification = _notifications[index];
//           return _buildNotificationTile(notification);
//         },
//       )
//           : Center(
//         child: Text(
//           'No notifications yet.',
//           style: TextStyle(color: Colors.grey, fontSize: 16),
//         ),
//       ),
//     );
//   }
// }
// NotificationsScreen.dart

// NotificationsScreen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'PostDetailScreen.dart';
import 'package:intl/intl.dart'; // For better date formatting

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  User? _user;

  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    if (_user != null) {
      _loadNotifications();
    }
  }

  /// Loads notifications from the 'notifications' node
  void _loadNotifications() {
    _dbRef.child('notifications').child(_user!.uid).orderByChild('timestamp').onValue.listen((event) {
      List<Map<String, dynamic>> notifications = [];
      if (event.snapshot.exists) {
        for (var notificationSnapshot in event.snapshot.children) {
          Map<String, dynamic> notificationData = Map<String, dynamic>.from(notificationSnapshot.value as Map);
          notificationData['notificationId'] = notificationSnapshot.key;
          notifications.add(notificationData);
        }
        // Sort notifications by timestamp descending
        notifications.sort((a, b) {
          int timestampA = _convertTimestamp(a['timestamp']);
          int timestampB = _convertTimestamp(b['timestamp']);
          return timestampB.compareTo(timestampA);
        });

        setState(() {
          _notifications = notifications;
        });
      } else {
        setState(() {
          _notifications = [];
        });
      }
    }, onError: (error) {
      print('Error loading notifications: $error');
      // Optionally, display an error message to the user
    });
  }

  /// Converts timestamp to int, handling both int and double types
  int _convertTimestamp(dynamic timestamp) {
    if (timestamp is int) {
      return timestamp;
    } else if (timestamp is double) {
      return timestamp.toInt();
    } else {
      // Handle unexpected types or provide a default value
      return 0;
    }
  }

  /// Fetches user information based on userId
  Future<Map<String, dynamic>> _getUserInfo(String userId) async {
    DataSnapshot snapshot = await _dbRef.child('users').child(userId).get();
    if (snapshot.exists) {
      Map<String, dynamic> userData = Map<String, dynamic>.from(snapshot.value as Map);
      return userData;
    } else {
      return {'username': 'Unknown User', 'profileImageUrl': null};
    }
  }

  /// Navigates to PostDetailScreen
  void _viewPostDetails(String postId) async {
    DataSnapshot postSnapshot = await _dbRef.child('posts').child(postId).get();
    if (postSnapshot.exists) {
      Map<String, dynamic> postData = Map<String, dynamic>.from(postSnapshot.value as Map);
      postData['postId'] = postId;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PostDetailScreen(post: postData, currentUser: _user)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post not found')),
      );
    }
  }

  /// Marks a notification as read
  Future<void> _markAsRead(String notificationId) async {
    await _dbRef.child('notifications').child(_user!.uid).child(notificationId).update({'read': true});
  }

  /// Formats timestamp to a readable date string
  String _formatTimestamp(int timestamp) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal();
    return DateFormat('yyyy-MM-dd – kk:mm').format(date);
  }

  /// Builds individual notification tiles based on their type
  Widget _buildNotificationTile(Map<String, dynamic> notification) {
    bool isWarning = notification['type'] == 'warning';
    String action = notification['action'] ?? '';
    String fromUserId = notification['fromUserId'] ?? '';
    String? postId = notification['postId'];
    bool isRead = notification['read'] ?? false;
    int timestamp = _convertTimestamp(notification['timestamp']);

    return FutureBuilder(
      future: _getUserInfo(fromUserId),
      builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListTile(
            leading: CircleAvatar(child: CircularProgressIndicator()),
            title: Text('Loading...'),
          );
        } else if (snapshot.hasError || !snapshot.hasData) {
          return ListTile(
            leading: CircleAvatar(child: Icon(Icons.error)),
            title: Text('Error loading user'),
          );
        } else {
          String username = snapshot.data!['username'] ?? 'Unknown User';
          String? profileImageUrl = snapshot.data!['profileImageUrl'];
          String message = '';

          // Determine the message based on the action
          switch (action) {
            case 'liked your post':
              message = '$username liked your post.';
              break;
            case 'unliked your post':
              message = '$username unliked your post.';
              break;
            case 'commented on your post':
              String commentContent = notification['commentContent'] ?? '';
              message = '$username commented: "$commentContent"';
              break;
            case 'started following you':
              message = '$username started following you.';
              break;
            case 'unfollowed you':
              message = '$username unfollowed you.';
              break;
            case 'warning':
              message = notification['message'] ?? 'You have received a warning.';
              break;
            default:
              message = 'You have a new notification.';
          }

          // Optionally, handle navigation based on action
          void _handleTap() {
            if (!isWarning && postId != null) {
              _viewPostDetails(postId);
              _markAsRead(notification['notificationId']);
            }
            // Add more navigation based on different actions if needed
          }

          return ListTile(
            leading: isWarning
                ? CircleAvatar(
              backgroundColor: Colors.red,
              child: Icon(Icons.warning, color: Colors.white),
            )
                : CircleAvatar(
              backgroundImage: profileImageUrl != null
                  ? NetworkImage(profileImageUrl)
                  : AssetImage('assets/profile_placeholder.png') as ImageProvider,
            ),
            title: Text(
              isWarning ? 'Warning from Admin' : message,
              style: TextStyle(
                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                color: isWarning ? Colors.red : Colors.black,
              ),
            ),
            subtitle: Text(
              _formatTimestamp(timestamp),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            trailing: !isRead
                ? Icon(Icons.circle, color: Colors.blue, size: 10)
                : null,
            onTap: isWarning ? null : _handleTap,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: _notifications.isNotEmpty
          ? ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          var notification = _notifications[index];
          return _buildNotificationTile(notification);
        },
      )
          : Center(
        child: Text(
          'No notifications yet.',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ),
    );
  }
}
