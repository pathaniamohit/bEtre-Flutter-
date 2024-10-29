// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// import 'CommentScreen.dart';
//
// class ExploreScreen extends StatefulWidget {
//   @override
//   _ExploreScreenState createState() => _ExploreScreenState();
// }
//
// class _ExploreScreenState extends State<ExploreScreen> {
//   final DatabaseReference _postRef = FirebaseDatabase.instance.ref().child('posts');
//   final DatabaseReference _userRef = FirebaseDatabase.instance.ref().child('users');
//   final DatabaseReference _followingRef = FirebaseDatabase.instance.ref().child('following');
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//
//   List<Map<dynamic, dynamic>> _posts = [];
//   User? _currentUser;
//   Set<String> _followingUserIds = {}; // Store the IDs of users the current user follows
//
//   @override
//   void initState() {
//     super.initState();
//     _currentUser = _auth.currentUser;
//     if (_currentUser != null) {
//       _fetchFollowingUsers(); // Fetch followed users first
//     }
//   }
//
//   Future<void> _fetchFollowingUsers() async {
//     DatabaseReference followingRef = _followingRef.child(_currentUser!.uid);
//     followingRef.onValue.listen((event) {
//       if (event.snapshot.exists) {
//         setState(() {
//           _followingUserIds = event.snapshot.children.map((e) => e.key.toString()).toSet();
//         });
//         _loadFollowedUsersPosts();
//       } else {
//         setState(() {
//           _followingUserIds = {};
//           _posts = []; // No followed users, so clear posts
//         });
//       }
//     });
//   }
//
//   Future<void> _loadFollowedUsersPosts() async {
//     _postRef.onValue.listen((event) {
//       if (event.snapshot.exists) {
//         Map<dynamic, dynamic> postsData = event.snapshot.value as Map<dynamic, dynamic>;
//         List<Map<dynamic, dynamic>> followedPosts = [];
//
//         postsData.forEach((key, value) {
//           Map<dynamic, dynamic> post = Map<dynamic, dynamic>.from(value);
//           post['postId'] = key;
//
//           if (_followingUserIds.contains(post['userId'])) {
//             followedPosts.add(post);
//           }
//         });
//
//         setState(() {
//           _posts = followedPosts;
//         });
//       } else {
//         setState(() {
//           _posts = [];
//         });
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Explore'),
//         centerTitle: true,
//       ),
//       body: _posts.isNotEmpty
//           ? ListView.builder(
//         itemCount: _posts.length,
//         itemBuilder: (context, index) {
//           var post = _posts[index];
//           return _buildPostCard(post);
//         },
//       )
//           : Center(child: Text('No posts to show')),
//     );
//   }
//
//   Widget _buildPostCard(Map<dynamic, dynamic> post) {
//     return FutureBuilder(
//       future: _userRef.child(post['userId']).once(),
//       builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
//         if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
//           Map<dynamic, dynamic> userData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
//
//           // Check if the current user has liked the post
//           bool isLiked = false;
//           int likesCount = 0;
//           if (post['likes'] != null) {
//             Map<dynamic, dynamic> likesMap = post['likes'];
//             likesCount = likesMap.length;
//             isLiked = likesMap.containsKey(_currentUser!.uid);
//           }
//           post['isLiked'] = isLiked;
//           post['likesCount'] = likesCount;
//
//           // Get comments count
//           int commentsCount = 0;
//           if (post['comments'] != null) {
//             commentsCount = (post['comments'] as Map<dynamic, dynamic>).length;
//           }
//           post['commentsCount'] = commentsCount;
//
//           return Card(
//             margin: const EdgeInsets.all(10),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildPostHeader(userData, post),
//                 if (post['imageUrl'] != null && post['imageUrl'].isNotEmpty)
//                   Image.network(post['imageUrl']),
//                 Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Text(post['content'] ?? 'No content'),
//                 ),
//                 _buildPostFooter(post),
//               ],
//             ),
//           );
//         }
//         return SizedBox.shrink();
//       },
//     );
//   }
//
//   Widget _buildPostHeader(Map<dynamic, dynamic> userData, Map<dynamic, dynamic> post) {
//     return ListTile(
//       leading: CircleAvatar(
//         backgroundImage: userData['profileImageUrl'] != null && userData['profileImageUrl'].isNotEmpty
//             ? NetworkImage(userData['profileImageUrl'])
//             : AssetImage('assets/profile_placeholder.png') as ImageProvider,
//       ),
//       title: Text(userData['username'] ?? 'Unknown User'),
//       subtitle: Text(post['location'] ?? 'Unknown Location'),
//     );
//   }
//
//   Widget _buildPostFooter(Map<dynamic, dynamic> post) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceAround,
//       children: [
//         IconButton(
//           icon: Icon(Icons.favorite, color: post['isLiked'] == true ? Colors.red : Colors.grey),
//           onPressed: () => _toggleLike(post),
//         ),
//         IconButton(
//           icon: Icon(Icons.comment),
//           onPressed: () => _navigateToComments(post),
//         ),
//         Text('${post['likesCount'] ?? 0} Likes'),
//         Text('${post['commentsCount'] ?? 0} Comments'),
//       ],
//     );
//   }
//
//   void _toggleLike(Map<dynamic, dynamic> post) async {
//     final postId = post['postId'];
//     final userId = _currentUser!.uid;
//     final likesRef = _postRef.child(postId).child('likes');
//     final userLikeRef = likesRef.child(userId);
//
//     final DataSnapshot snapshot = await userLikeRef.get();
//     bool isLiked = snapshot.exists;
//
//     if (isLiked) {
//       // Unlike the post
//       await userLikeRef.remove();
//       // Update local post data
//       setState(() {
//         post['isLiked'] = false;
//         post['likesCount'] = (post['likesCount'] ?? 1) - 1;
//       });
//     } else {
//       // Like the post
//       await userLikeRef.set(true);
//       // Notify the post owner
//       _notifyPostOwner(post, 'liked your post');
//       // Update local post data
//       setState(() {
//         post['isLiked'] = true;
//         post['likesCount'] = (post['likesCount'] ?? 0) + 1;
//       });
//     }
//   }
//
//   void _notifyPostOwner(Map<dynamic, dynamic> post, String action) async {
//     final postOwnerId = post['userId'];
//     final currentUserId = _currentUser!.uid;
//     if (postOwnerId == currentUserId) return; // Don't notify if the user is liking their own post
//
//     final inboxRef = FirebaseDatabase.instance.ref().child('inbox').child(postOwnerId);
//     await inboxRef.push().set({
//       'fromUserId': currentUserId,
//       'action': action,
//       'postId': post['postId'],
//       'timestamp': DateTime.now().millisecondsSinceEpoch,
//     });
//   }
//
//   void _navigateToComments(Map<dynamic, dynamic> post) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => CommentScreen(postId: post['postId'], postOwnerId: post['userId']),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'CommentScreen.dart';

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
      _fetchFollowingUsers(); // Fetch followed users first
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
          Map<dynamic, dynamic> userData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

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
          Text('${post['likesCount'] ?? 0}'),
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
            icon: Icon(Icons.report),
            onPressed: () => _reportPost(post),
          ),
        ],
      ),
    );
  }

  void _toggleLike(Map<dynamic, dynamic> post) async {
    final postId = post['postId'];
    final userId = _currentUser!.uid;
    final likesRef = _postRef.child(postId).child('likes');
    final userLikeRef = likesRef.child(userId);

    final DataSnapshot snapshot = await userLikeRef.get();
    bool isLiked = snapshot.exists;

    if (isLiked) {
      // Unlike the post
      await userLikeRef.remove();
      // Update local post data
      setState(() {
        post['isLiked'] = false;
        post['likesCount'] = (post['likesCount'] ?? 1) - 1;
      });
    } else {
      // Like the post
      await userLikeRef.set(true);
      // Notify the post owner
      _notifyPostOwner(post, 'liked your post');
      // Update local post data
      setState(() {
        post['isLiked'] = true;
        post['likesCount'] = (post['likesCount'] ?? 0) + 1;
      });
    }
  }

  void _notifyPostOwner(Map<dynamic, dynamic> post, String action) async {
    final postOwnerId = post['userId'];
    final currentUserId = _currentUser!.uid;
    if (postOwnerId == currentUserId) return; // Don't notify if the user is liking their own post

    final inboxRef = FirebaseDatabase.instance.ref().child('inbox').child(postOwnerId);
    await inboxRef.push().set({
      'fromUserId': currentUserId,
      'action': action,
      'postId': post['postId'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void _navigateToComments(Map<dynamic, dynamic> post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentScreen(postId: post['postId'], postOwnerId: post['userId']),
      ),
    );
  }

  void _reportPost(Map<dynamic, dynamic> post) {
    // Implement your report functionality here
    // For now, we'll just show a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report Post'),
        content: Text('Are you sure you want to report this post for inappropriate content?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Report the post
              _sendReport(post);
              Navigator.pop(context);
            },
            child: Text('Report', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _sendReport(Map<dynamic, dynamic> post) async {
    // Send the report to your database or backend
    final reportsRef = FirebaseDatabase.instance.ref().child('reports');
    await reportsRef.push().set({
      'reportedBy': _currentUser!.uid,
      'postId': post['postId'],
      'postOwnerId': post['userId'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    // Show a confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Post reported. Thank you for your feedback.')),
    );
  }
}

