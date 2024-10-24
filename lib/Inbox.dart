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

  List<Widget> _activityWidgets = [];

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    if (_user != null) {
      _loadRecentActivity();
    }
  }

  void _loadRecentActivity() {
    List<Widget> activityWidgets = [];

    _dbRef.child('posts').orderByChild('userId').equalTo(_user!.uid).onValue.listen((event) {
      activityWidgets.clear();
      if (event.snapshot.exists) {
        for (var post in event.snapshot.children) {
          var postData = Map<String, dynamic>.from(post.value as Map);
          postData['postId'] = post.key;

          // Fetch comments from other users
          if (postData['comments'] != null) {
            postData['comments'].forEach((commentId, commentData) {
              if (commentData['userId'] != _user!.uid) {
                activityWidgets.add(_buildActivityItem(commentData['userId'], 'commented on your post', commentData['content'], postData));
              }
            });
          }

          // Fetch likes from other users
          if (postData['likes'] != null) {
            postData['likes'].forEach((userId, _) {
              if (userId != _user!.uid) {
                activityWidgets.add(_buildActivityItem(userId, 'liked your post', null, postData));
              }
            });
          }
        }

        setState(() {
          _activityWidgets = activityWidgets;
        });
      }
    });
  }

  Map<String, Map<String, String?>> _userInfoCache = {};

  Future<Map<String, String?>> _getUserInfo(String userId) async {
    if (_userInfoCache.containsKey(userId)) {
      return _userInfoCache[userId]!;
    } else {
      DataSnapshot snapshot = await _dbRef.child('users').child(userId).get();
      if (snapshot.exists) {
        Map<String, dynamic> userData = Map<String, dynamic>.from(snapshot.value as Map);
        String? username = userData['username'];
        String? profileImageUrl = userData['profileImageUrl'];

        Map<String, String?> userInfo = {
          'username': username,
          'profileImageUrl': profileImageUrl,
        };
        _userInfoCache[userId] = userInfo;
        return userInfo;
      } else {
        return {
          'username': 'Unknown User',
          'profileImageUrl': null,
        };
      }
    }
  }

  Widget _buildActivityItem(String userId, String action, String? content, Map<String, dynamic> postData) {
    return FutureBuilder(
      future: _getUserInfo(userId),
      builder: (context, AsyncSnapshot<Map<String, String?>> snapshot) {
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

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: profileImageUrl != null
                  ? NetworkImage(profileImageUrl)
                  : AssetImage('assets/profile_placeholder.png') as ImageProvider,
            ),
            title: Text('$username $action'),
            subtitle: content != null ? Text(content) : null,
            onTap: () => _viewPostDetails(postData),
          );
        }
      },
    );
  }

  void _viewPostDetails(Map<String, dynamic> post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PostDetailScreen(post: post, currentUser: _user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inbox'),
      ),
      body: _activityWidgets.isNotEmpty
          ? ListView(children: _activityWidgets)
          : Center(child: Text('No recent activity')),
    );
  }
}
