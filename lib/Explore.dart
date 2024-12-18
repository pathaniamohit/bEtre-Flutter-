import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'CommentScreen.dart';
import 'PostDetailScreen.dart';

class ExploreScreen extends StatefulWidget {
  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final DatabaseReference _postRef = FirebaseDatabase.instance.ref().child('posts');
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref().child('users');
  final DatabaseReference _followingRef = FirebaseDatabase.instance.ref().child('following');

  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<dynamic, dynamic>> _posts = [];
  User? _currentUser;
  Set<String> _followingUserIds = {}; // Store the IDs of users the current user follows

  @override
  void initState() {
    super.initState();

    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      _fetchFollowingUsers();
    }
  }

  Future<void> _fetchFollowingUsers() async {
    DatabaseReference followingRef = _followingRef.child(_currentUser!.uid);
    followingRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        setState(() {
          _followingUserIds = event.snapshot.children.map((e) => e.key.toString()).toSet();
        });
        _loadFollowedUsersPosts();
      } else {
        setState(() {
          _followingUserIds = {};
          _posts = []; // No followed users, so clear posts
        });
      }
    });
  }

  Future<void> _loadFollowedUsersPosts() async {
    _postRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> postsData = event.snapshot.value as Map<dynamic, dynamic>;
        List<Map<dynamic, dynamic>> followedPosts = [];

        postsData.forEach((key, value) {
          Map<dynamic, dynamic> post = Map<dynamic, dynamic>.from(value);
          post['postId'] = key;

          if (_followingUserIds.contains(post['userId'])) {
            followedPosts.add(post);
          }
        });

        setState(() {
          _posts = followedPosts;
        });
      } else {
        setState(() {
          _posts = [];
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Explore'),
        centerTitle: true,
      ),

      body: _posts.isNotEmpty
          ? ListView.builder(
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          var post = _posts[index];
          return _buildPostCard(post);
        },
      )
          : Center(child: Text('No posts to show')),
    );
  }

  Widget _buildPostCard(Map<dynamic, dynamic> post) {
    return FutureBuilder(
      future: _userRef.child(post['userId']).once(),
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          Map<dynamic, dynamic> userData = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map<dynamic, dynamic>);

          // Check if the current user has liked the post
          bool isLiked = false;
          int likesCount = 0;
          if (post['likes'] != null) {
            Map<dynamic, dynamic> likesMap = post['likes'];
            likesCount = likesMap.length;
            isLiked = likesMap.containsKey(_currentUser!.uid);
          }
          post['isLiked'] = isLiked;
          post['likesCount'] = likesCount;

          // Get comments count
          int commentsCount = 0;
          if (post['comments'] != null) {
            commentsCount = (post['comments'] as Map<dynamic, dynamic>).length;
          }
          post['commentsCount'] = commentsCount;

          return Card(
            margin: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPostHeader(userData, post),
                if (post['imageUrl'] != null && post['imageUrl'].isNotEmpty)
                  Image.network(post['imageUrl']),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(post['content'] ?? 'No content'),
                ),
                _buildPostFooter(post),
              ],
            ),
          );
        }
        return SizedBox.shrink();
      },
    );
  }

  Widget _buildPostHeader(Map<dynamic, dynamic> userData, Map<dynamic, dynamic> post) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: userData['profileImageUrl'] != null && userData['profileImageUrl'].isNotEmpty
            ? NetworkImage(userData['profileImageUrl'])
            : AssetImage('assets/profile_placeholder.png') as ImageProvider,
      ),
      title: Text(userData['username'] ?? 'Unknown User'),
      subtitle: Text(post['location'] ?? 'Unknown Location'),
    );
  }

  Widget _buildPostFooter(Map<dynamic, dynamic> post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          // Like button with count
          IconButton(
            icon: Icon(Icons.favorite, color: post['isLiked'] == true ? Colors.red : Colors.grey),
            onPressed: () => _toggleLike(post),
          ),
          Text('${post['likesCount']}'),
          SizedBox(width: 16),
          // Comment icon
          IconButton(
            icon: Icon(Icons.comment),
            onPressed: () => _navigateToComments(post),
          ),
          // Optionally, you can display the comments count
          // Text('${post['commentsCount'] ?? 0}'),
          Spacer(),
          // Report icon
          IconButton(
            icon: Icon(Icons.flag),
            onPressed: () => _reportPost(post),
          ),
        ],
      ),
    );
  }

  void _toggleLike(Map<dynamic, dynamic> post) async {
    final postId = post['postId'];
    final userId = _currentUser!.uid;
    final likesRef = FirebaseDatabase.instance.ref().child('likes').child(postId).child('users').child(userId);
    final ownerIdRef = FirebaseDatabase.instance.ref().child('likes').child(postId).child('ownerId');
    final postOwnerId = post['userId'];

    print("Attempting to toggle like for post: $postId by user: $userId");

    try {
      final DataSnapshot snapshot = await likesRef.get();
      bool isLiked = snapshot.exists;
      print("Like status for user $userId on post $postId: ${isLiked ? 'Liked' : 'Not liked'}");

      if (isLiked) {
        // Unlike the post
        await likesRef.remove();
        print("Removed like for post: $postId by user: $userId");

        // Optionally update UI (if local representation of likes is needed)
        setState(() {
          post['isLiked'] = false;
          post['likesCount'] = (post['likesCount'] ?? 1) - 1;
        });
      } else {
        // Like the post
        await likesRef.set({
          'likedAt': DateTime.now().millisecondsSinceEpoch, // Save the timestamp of the like
        });
        print("Added like for post: $postId by user: $userId with timestamp");

        // Set the ownerId for the post under likes node
        await ownerIdRef.set(postOwnerId);
        print("Set ownerId for post: $postId as $postOwnerId");

        // Notify the post owner if necessary
        _notifyPostOwner(post, 'liked your post');
        print("Notification sent to post owner: $postOwnerId for like action by $userId");

        // Optionally update UI (if local representation of likes is needed)
        setState(() {
          post['isLiked'] = true;
          post['likesCount'] = (post['likesCount'] ?? 0) + 1;
        });
      }
    } catch (error) {
      print("Error in toggling like for post $postId by user $userId: $error");
    }
  }

  void _notifyPostOwner(Map<dynamic, dynamic> post, String action) async {
    String postOwnerId = post['userId'];
    String currentUserId = _currentUser!.uid;

    // Avoid notifying self if the user is liking their own post
    if (postOwnerId == currentUserId) return;

    final notificationsRef = FirebaseDatabase.instance.ref().child('notifications').child(postOwnerId);

    await notificationsRef.push().set({
      'fromUserId': currentUserId,
      'action': action, // e.g., 'liked your post'
      'postId': post['postId'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    print('Notification sent to $postOwnerId: $action');
  }

  void _navigateToComments(Map<dynamic, dynamic> post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentScreen(
          postId: post['postId'],
          postOwnerId: post['userId'],
          canReport: false,
        ),
      ),
    );
  }

  void _reportPost(Map<dynamic, dynamic> post) {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController _reasonController = TextEditingController();

        return AlertDialog(
          title: Text('Report Post'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Please specify the reason for reporting this post:'),
              TextField(
                controller: _reasonController,
                decoration: InputDecoration(
                  hintText: 'Enter reason',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                String reason = _reasonController.text.trim();
                if (reason.isEmpty) {
                  Fluttertoast.showToast(msg: 'Please enter a reason.');
                  return;
                }

                // Proceed to report the post
                String postId = post['postId'];
                String postOwnerId = post['userId'];
                String reporterId = _currentUser!.uid;
                String reporterName = _currentUser!.displayName ?? 'Unknown';

                DatabaseReference reportRef = FirebaseDatabase.instance.ref().child('reports').push();
                await reportRef.set({
                  'type': 'post',
                  'reportedItemId': postId,
                  'reportedUserId': postOwnerId,
                  'reporterId': reporterId,
                  'reporterName': reporterName,
                  'timestamp': DateTime.now().millisecondsSinceEpoch,
                  'reason': reason,
                  'content': post['content'] ?? '',
                });

                Navigator.pop(context); // Close the dialog
                Fluttertoast.showToast(msg: 'Post reported.');
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}
