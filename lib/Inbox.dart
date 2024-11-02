import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'PostDetailScreen.dart';

class InboxScreen extends StatefulWidget {
  @override
  _InboxScreenState createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
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

  void _loadNotifications() {
    _dbRef.child('inbox').child(_user!.uid).orderByChild('timestamp').onValue.listen((event) {
      List<Map<String, dynamic>> notifications = [];
      if (event.snapshot.exists) {
        for (var notificationSnapshot in event.snapshot.children) {
          Map<String, dynamic> notificationData = Map<String, dynamic>.from(notificationSnapshot.value as Map);
          notificationData['notificationId'] = notificationSnapshot.key;
          notifications.add(notificationData);
        }
        // Sort notifications by timestamp descending
        notifications.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

        setState(() {
          _notifications = notifications;
        });
      } else {
        setState(() {
          _notifications = [];
        });
      }
    });
  }

  Future<Map<String, dynamic>> _getUserInfo(String userId) async {
    DataSnapshot snapshot = await _dbRef.child('users').child(userId).get();
    if (snapshot.exists) {
      Map<String, dynamic> userData = Map<String, dynamic>.from(snapshot.value as Map);
      return userData;
    } else {
      return {'username': 'Unknown User', 'profileImageUrl': null};
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inbox'),
      ),
      body: _notifications.isNotEmpty
          ? ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          var notification = _notifications[index];
          bool isWarning = notification['type'] == 'warning';

          return FutureBuilder(
            future: _getUserInfo(notification['fromUserId']),
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
                String action = notification['action'] ?? '';
                String content = notification['commentContent'] ?? '';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(profileImageUrl)
                        : AssetImage('assets/profile_placeholder.png') as ImageProvider,
                  ),
                  title: Text(isWarning ? 'Warning from Admin' : '$username $action'),
                  subtitle: isWarning
                      ? Text(
                    notification['message'] ?? 'You have received a warning',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  )
                      : content.isNotEmpty
                      ? Text(content)
                      : null,
                  onTap: isWarning
                      ? null
                      : () {
                    if (notification['postId'] != null) {
                      _viewPostDetails(notification['postId']);
                    }
                  },
                );
              }
            },
          );
        },
      )
          : Center(child: Text('No recent activity')),
    );
  }
}
