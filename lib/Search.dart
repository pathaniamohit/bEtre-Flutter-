import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'CommentScreen.dart';
import 'OtherUserProfileScreen.dart';

class SearchUserScreen extends StatefulWidget {
  @override
  _SearchUserScreenState createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final DatabaseReference _postRef = FirebaseDatabase.instance.ref().child('posts');
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref().child('users');
  final TextEditingController _searchController = TextEditingController();
  List<Map<dynamic, dynamic>> _users = [];
  List<Map<dynamic, dynamic>> _posts = [];
  bool _isLoading = false;

  User? _currentUser;
  Set<String> _followingUserIds = {}; // To store the user IDs the current user is following

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _fetchFollowingUsers(); // Fetch the list of users the current user is following
  }

  void _fetchFollowingUsers() {
    if (_currentUser == null) return;

    DatabaseReference followingRef = FirebaseDatabase.instance.ref('following/${_currentUser!.uid}');
    followingRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        setState(() {
          _followingUserIds = event.snapshot.children.map((child) => child.key!).toSet();
        });
      } else {
        setState(() {
          _followingUserIds = {};
        });
      }
      // After updating the following list, fetch the posts again
      _fetchAllPosts();
    });
  }

  void _fetchAllPosts() {
    setState(() {
      _isLoading = true;
    });

    if (_currentUser == null) return;

    // Fetch all posts with real-time updates
    DatabaseReference postsRef = FirebaseDatabase.instance.ref('posts');
    postsRef.onValue.listen((event) async {
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> postsData = event.snapshot.value as Map<dynamic, dynamic>;
        List<Map<dynamic, dynamic>> allPosts = [];

        for (var key in postsData.keys) {
          Map<dynamic, dynamic> post = Map<dynamic, dynamic>.from(postsData[key]);
          post['postId'] = key;

          // Exclude the current user's posts and posts from users the current user is following
          if (post['userId'] != _currentUser!.uid && !_followingUserIds.contains(post['userId'])) {
            // Calculate isLiked and likesCount
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

            allPosts.add(post);
          }
        }

        setState(() {
          _posts = allPosts;
          _isLoading = false;
        });
      } else {
        print("No posts found in Firebase");
        setState(() {
          _posts = [];
          _isLoading = false;
        });
      }
    }, onError: (error) {
      print("Error fetching posts: $error");
      setState(() {
        _isLoading = false;
      });
    });
  }

  Future<void> _searchUsers() async {
    setState(() {
      _isLoading = true;
      _users = [];
    });

    try {
      String query = _searchController.text.trim();
      if (query.isNotEmpty) {
        DatabaseReference userRef = FirebaseDatabase.instance.ref('users');
        DataSnapshot snapshot = await userRef.get();

        if (snapshot.exists) {
          Map<dynamic, dynamic> userData = snapshot.value as Map<dynamic, dynamic>;
          List<Map<dynamic, dynamic>> usersList = [];

          userData.forEach((key, value) {
            if (value['username'].toString().toLowerCase().contains(query.toLowerCase())
                && key != _currentUser!.uid) {
              Map<dynamic, dynamic> user = Map<dynamic, dynamic>.from(value);
              user['uid'] = key;
              usersList.add(user);
            }
          });

          setState(() {
            _users = usersList;
          });
        }
      }
    } catch (e) {
      print("Error searching users: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToUserProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtherUserProfileScreen(userId: userId),
      ),
    );
  }

  Future<void> _followUser(String userId) async {
    if (_currentUser == null) return;

    DatabaseReference followingRef = FirebaseDatabase.instance.ref('following/${_currentUser!.uid}/$userId');
    DatabaseReference followersRef = FirebaseDatabase.instance.ref('followers/$userId/${_currentUser!.uid}');

    await followingRef.set(true);
    await followersRef.set(true);

    setState(() {
      _followingUserIds.add(userId);
      // Remove the user's posts from the _posts list
      _posts.removeWhere((post) => post['userId'] == userId);
    });
  }

  Future<void> _unfollowUser(String userId) async {
    if (_currentUser == null) return;

    DatabaseReference followingRef = FirebaseDatabase.instance.ref('following/${_currentUser!.uid}/$userId');
    DatabaseReference followersRef = FirebaseDatabase.instance.ref('followers/$userId/${_currentUser!.uid}');

    await followingRef.remove();
    await followersRef.remove();

    setState(() {
      _followingUserIds.remove(userId);
      // Re-fetch the posts to include the unfollowed user's posts
      _fetchAllPosts();
    });
  }

  Widget _buildPostCard(Map<dynamic, dynamic> post) {
    return FutureBuilder(
      future: _userRef.child(post['userId']).get(),
      builder: (context, AsyncSnapshot<DataSnapshot> snapshot) {
        if (snapshot.hasData && snapshot.data!.value != null) {
          Map<dynamic, dynamic> userData = snapshot.data!.value as Map<dynamic, dynamic>;
          String postUserId = post['userId'];

          bool isFollowing = _followingUserIds.contains(postUserId);

          return Card(
            margin: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: userData['profileImageUrl'] != null && userData['profileImageUrl'].isNotEmpty
                        ? NetworkImage(userData['profileImageUrl'])
                        : AssetImage('assets/profile_placeholder.png') as ImageProvider,
                  ),
                  title: Text(userData['username'] ?? 'Unknown User'),
                  subtitle: Text(post['location'] ?? ''),
                  trailing: ElevatedButton(
                    onPressed: () {
                      if (isFollowing) {
                        _unfollowUser(postUserId);
                      } else {
                        _followUser(postUserId);
                      }
                    },
                    child: Text(isFollowing ? 'Unfollow' : 'Follow'),
                  ),
                ),
                if (post['imageUrl'] != null && post['imageUrl'].isNotEmpty)
                  Image.network(post['imageUrl']),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(post['content'] ?? ''),
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

  Widget _buildPostFooter(Map<dynamic, dynamic> post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          // Like button and count
          IconButton(
            icon: Icon(Icons.favorite,
                color: post['isLiked'] == true ? Colors.red : Colors.grey),
            onPressed: () => _toggleLike(post),
          ),
          Text('${post['likesCount'] ?? 0}'),
          SizedBox(width: 16),

          // Comment button and count
          IconButton(
            icon: Icon(Icons.comment),
            onPressed: () => _navigateToComments(post),
          ),
          Text('${post['commentsCount'] ?? 0}'),
          Spacer(),

          // Report button
          IconButton(
            icon: Icon(Icons.flag),
            onPressed: () => _reportPost(post),
          ),
        ],
      ),
    );
  }

  void _toggleLike(Map<dynamic, dynamic> post) async {
    try {
      final postId = post['postId'];
      final userId = _currentUser!.uid;
      final likesRef = _postRef.child(postId).child('likes');
      final userLikeRef = likesRef.child(userId);

      final DataSnapshot snapshot = await userLikeRef.get();
      bool isLiked = snapshot.exists;

      if (isLiked) {
        // Unlike the post
        await userLikeRef.remove();
        // No need to update local post data here, as the listener will handle it
      } else {
        // Like the post
        await userLikeRef.set(true);
        // Notify the post owner
        _notifyPostOwner(post, 'liked your post');
        // No need to update local post data here, as the listener will handle it
      }
    } catch (e) {
      print('Error in _toggleLike: $e');
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

  // void _reportPost(Map<dynamic, dynamic> post) async {
  //   final postId = post['postId'];
  //   final userId = _currentUser!.uid;
  //   final reportsRef = _postRef.child(postId).child('reports');
  //   final userReportRef = reportsRef.child(userId);
  //
  //   final DataSnapshot snapshot = await userReportRef.get();
  //   bool isReported = snapshot.exists;
  //
  //   if (isReported) {
  //     Fluttertoast.showToast(msg: 'You have already reported this post.');
  //   } else {
  //     await userReportRef.set(true);
  //     Fluttertoast.showToast(msg: 'Post reported.');
  //     // Optionally, notify admins or take further actions
  //   }
  // }

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


  void _navigateToComments(Map<dynamic, dynamic> post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentScreen(postId: post['postId'], postOwnerId: post['userId'],canReport: false,),
      ),
    );
  }

  Widget _buildUserListTile(Map<dynamic, dynamic> user) {
    String userId = user['uid'];

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user['profileImageUrl'] != null && user['profileImageUrl'].isNotEmpty
            ? NetworkImage(user['profileImageUrl'])
            : AssetImage('assets/profile_placeholder.png') as ImageProvider,
      ),
      title: Text(user['username']),
      subtitle: Text(user['email']),
      onTap: () => _navigateToUserProfile(userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Users'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by username...',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchUsers,
                ),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _users.isNotEmpty
                ? ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                var user = _users[index];
                return _buildUserListTile(user);
              },
            )
                : _posts.isNotEmpty
                ? ListView.builder(
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                var post = _posts[index];
                return _buildPostCard(post);
              },
            )
                : Center(child: Text('No posts found.')),
          ),
        ],
      ),
    );
  }
}
