import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'PostDetailScreen.dart';

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
    print("Current user ID: ${_user?.uid}");
    if (_user != null) {
      _loadAllNotifications();
    } else {
      print("User not authenticated. Notifications will not load.");
    }
  }

  /// Loads all notifications by fetching different types from multiple nodes.
  void _loadAllNotifications() async {
    List<Map<String, dynamic>> loadedNotifications = [];
    print("Starting to load all notifications...");

    // Load notifications in parallel
    await Future.wait([
      _loadFollowNotifications(loadedNotifications),
      _loadLikeNotifications(loadedNotifications),
      _loadCommentNotifications(loadedNotifications),
      _loadWarningNotifications(loadedNotifications),
    ]);

    // Sort notifications by timestamp
    loadedNotifications.sort((a, b) {
      int timestampA = _convertTimestamp(a['timestamp']);
      int timestampB = _convertTimestamp(b['timestamp']);
      return timestampB.compareTo(timestampA);
    });

    setState(() {
      _notifications = loadedNotifications;
    });
    print("All notifications loaded: ${_notifications.length}");
  }

  /// Loads follow notifications
  Future<void> _loadFollowNotifications(List<Map<String, dynamic>> notifications) async {
    print("Loading follow notifications...");
    try {
      final followersRef = _dbRef.child('followers').child(_user!.uid);
      final snapshot = await followersRef.get();

      if (snapshot.exists) {
        for (var followerSnapshot in snapshot.children) {
          if (followerSnapshot.value == true) {
            String followerId = followerSnapshot.key!;
            String username = await _fetchUsername(followerId);

            notifications.add({
              'type': 'follow',
              'userId': followerId,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'username': username,
              'message': '$username started following you.'
            });
          }
        }
        print("Follow notifications loaded: ${notifications.length}");
      } else {
        print("No follow notifications found.");
      }
    } catch (e) {
      print("Error loading follow notifications: $e");
    }
  }

  /// Loads like notifications
  Future<void> _loadLikeNotifications(List<Map<String, dynamic>> notifications) async {
    print("Loading like notifications...");
    try {
      final likesRef = _dbRef.child('likes');
      final snapshot = await likesRef.get();

      if (snapshot.exists) {
        for (var postSnapshot in snapshot.children) {
          String postId = postSnapshot.key!;
          String? postOwnerId = postSnapshot.child('ownerId').value as String?;

          if (postOwnerId == _user!.uid) {
            for (var userSnapshot in postSnapshot.child('users').children) {
              String likerUserId = userSnapshot.key!;
              int likedAt = _convertTimestamp(userSnapshot.child('likedAt').value);
              String likerUsername = await _fetchUsername(likerUserId);

              notifications.add({
                'type': 'like',
                'userId': likerUserId,
                'postId': postId,
                'timestamp': likedAt,
                'username': likerUsername,
                'message': '$likerUsername liked your post.'
              });
            }
          } else {
            print("Post $postId does not belong to the current user, skipping.");
          }
        }
        print("Like notifications loaded: ${notifications.length}");
      } else {
        print("No like notifications found.");
      }
    } catch (e) {
      print("Error loading like notifications: $e");
    }
  }

  /// Loads comment notifications
  Future<void> _loadCommentNotifications(List<Map<String, dynamic>> notifications) async {
    print("Loading comment notifications...");
    try {
      final commentsRef = _dbRef.child('comments');
      final snapshot = await commentsRef.get();

      if (snapshot.exists) {
        for (var commentSnapshot in snapshot.children) {
          Map<String, dynamic> commentData = Map<String, dynamic>.from(commentSnapshot.value as Map);

          // Use null-aware operators or default values
          String postId = commentData['post_Id'] ?? '';
          String commenterId = commentData['userId'] ?? '';
          String commentContent = commentData['content'] ?? '';
          int timestamp = _convertTimestamp(commentData['timestamp']);

          // Skip entries where any required field is missing or invalid
          if (postId.isEmpty || commenterId.isEmpty || commentContent.isEmpty) {
            print("Skipping incomplete comment data: $commentData");
            continue;
          }

          String commenterUsername = await _fetchUsername(commenterId);

          // Verify that the post belongs to the current user
          final postOwnerId = (await _dbRef.child('posts').child(postId).child('userId').get()).value;
          if (postOwnerId == _user!.uid) {
            notifications.add({
              'type': 'comment',
              'userId': commenterId,
              'postId': postId,
              'timestamp': timestamp,
              'username': commenterUsername,
              'commentContent': commentContent,
              'message': '$commenterUsername commented: "$commentContent"'
            });
          } else {
            print("Post $postId does not belong to the current user, skipping.");
          }
        }
        print("Comment notifications loaded: ${notifications.length}");
      } else {
        print("No comment notifications found.");
      }
    } catch (e) {
      print("Error loading comment notifications: $e");
    }
  }

  /// Loads warning notifications
  Future<void> _loadWarningNotifications(List<Map<String, dynamic>> notifications) async {
    print("Loading warning notifications...");
    try {
      final warningsRef = _dbRef.child('warnings').child(_user!.uid);
      final snapshot = await warningsRef.get();

      if (snapshot.exists) {
        for (var warningSnapshot in snapshot.children) {
          Map<String, dynamic> warningData = Map<String, dynamic>.from(warningSnapshot.value as Map);
          String reason = warningData['reason'];
          int timestamp = _convertTimestamp(warningData['timestamp']);

          notifications.add({
            'type': 'warning',
            'timestamp': timestamp,
            'message': 'Admin warned you: $reason'
          });
        }
        print("Warning notifications loaded: ${notifications.length}");
      } else {
        print("No warning notifications found.");
      }
    } catch (e) {
      print("Error loading warning notifications: $e");
    }
  }

  /// Fetches a user's username
  Future<String> _fetchUsername(String userId) async {
    try {
      final userSnapshot = await _dbRef.child('users').child(userId).child('username').get();
      return userSnapshot.value as String? ?? 'Unknown User';
    } catch (e) {
      print("Error fetching username for user $userId: $e");
      return 'Unknown User';
    }
  }

  /// Converts timestamp to int, handling both int and double types
  int _convertTimestamp(dynamic timestamp) {
    if (timestamp == null) return 0; // Default to 0 or another appropriate value
    if (timestamp is int) return timestamp;
    if (timestamp is double) return timestamp.toInt();
    return 0;
  }


  /// Formats timestamp to a readable date string
  String _formatTimestamp(int timestamp) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal();
    return DateFormat('h:mm a').format(date); // 12-hour format with AM/PM
  }

  /// Builds individual notification tiles based on their type
  Widget _buildNotificationTile(Map<String, dynamic> notification) {
    String message = notification['message'];
    int timestamp = _convertTimestamp(notification['timestamp']);
    bool isWarning = notification['type'] == 'warning';
    bool isComment = notification['type'] == 'comment';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          leading: isWarning
              ? CircleAvatar(
            backgroundColor: Colors.red,
            child: Icon(Icons.warning, color: Colors.white),
          )
              : CircleAvatar(
            backgroundImage: AssetImage('assets/profile_placeholder.png'),
          ),
          title: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: isComment
                      ? message.split(': ')[0] + ': ' // Username part
                      : message, // Full message for non-comment notifications
                  style: TextStyle(
                    fontWeight: isWarning ? FontWeight.bold : FontWeight.normal,
                    color: isWarning ? Colors.red : Colors.black,
                  ),
                ),
                if (isComment)
                  TextSpan(
                    text: message.split(': ').length > 1 ? message.split(': ')[1] : "",
                    style: TextStyle(
                      color: Colors.blue, // Comment content in blue color
                      fontWeight: FontWeight.normal,
                    ),
                  ),
              ],
            ),
          ),
          subtitle: Text(
            _formatTimestamp(timestamp),
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        centerTitle: true,
      ),
      body: _notifications.isNotEmpty
          ? ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          return _buildNotificationTile(_notifications[index]);
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
