import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'PostDetailScreen.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final String userId;

  OtherUserProfileScreen({required this.userId});

  @override
  _OtherUserProfileScreenState createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  String? _profileImageUrl;
  String _username = "Username";
  String _email = "Email";
  int _photosCount = 0;
  int _followersCount = 0;
  int _followsCount = 0;

  List<Map<String, dynamic>> _posts = [];

  User? _currentUser;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _loadUserProfile();
    _loadUserStats();
    _loadUserPosts();
    _checkIfFollowing();
  }

  Future<void> _loadUserProfile() async {
    _dbRef.child("users").child(widget.userId).once().then((snapshot) {
      if (snapshot.snapshot.exists) {
        var userData = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        setState(() {
          _username = userData['username'] ?? 'Username';
          _email = userData['email'] ?? 'Email';
          _profileImageUrl = userData['profileImageUrl'];
        });
      }
    });
  }

  Future<void> _loadUserStats() async {
    _dbRef.child("followers").child(widget.userId).onValue.listen((event) {
      final dataSnapshot = event.snapshot;
      if (dataSnapshot.exists) {
        setState(() {
          _followersCount = dataSnapshot.children.length;
        });
      } else {
        setState(() {
          _followersCount = 0;
        });
      }
    });

    _dbRef.child("following").child(widget.userId).onValue.listen((event) {
      final dataSnapshot = event.snapshot;
      if (dataSnapshot.exists) {
        setState(() {
          _followsCount = dataSnapshot.children.length;
        });
      } else {
        setState(() {
          _followsCount = 0;
        });
      }
    });

    _dbRef.child("posts").orderByChild("userId").equalTo(widget.userId).onValue.listen((event) {
      final dataSnapshot = event.snapshot;
      if (dataSnapshot.exists) {
        setState(() {
          _photosCount = dataSnapshot.children.length;
        });
      } else {
        setState(() {
          _photosCount = 0;
        });
      }
    });
  }

  Future<void> _loadUserPosts() async {
    _dbRef.child("posts").orderByChild("userId").equalTo(widget.userId).onValue.listen((event) {
      List<Map<String, dynamic>> posts = [];
      for (var post in event.snapshot.children) {
        var postData = Map<String, dynamic>.from(post.value as Map);
        postData['postId'] = post.key; // Store post ID for later use

        // Get likes
        int likesCount = 0;
        bool isLikedByCurrentUser = false;
        if (postData['likes'] != null) {
          Map<dynamic, dynamic> likesMap = postData['likes'];
          likesCount = likesMap.length;
          if (_currentUser != null && likesMap.containsKey(_currentUser!.uid)) {
            isLikedByCurrentUser = true;
          }
        }
        postData['likesCount'] = likesCount;
        postData['isLikedByCurrentUser'] = isLikedByCurrentUser;

        // Get comments count
        int commentsCount = 0;
        if (postData['comments'] != null) {
          commentsCount = (postData['comments'] as Map).length;
        }
        postData['commentsCount'] = commentsCount;

        posts.add(postData);
      }
      setState(() {
        _posts = posts;
      });
    });
  }

  Future<void> _checkIfFollowing() async {
    if (_currentUser != null) {
      _dbRef.child("following").child(_currentUser!.uid).child(widget.userId).once().then((snapshot) {
        setState(() {
          _isFollowing = snapshot.snapshot.exists;
        });
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_currentUser != null) {
      DatabaseReference followingRef = _dbRef.child("following").child(_currentUser!.uid).child(widget.userId);
      DatabaseReference followersRef = _dbRef.child("followers").child(widget.userId).child(_currentUser!.uid);

      if (_isFollowing) {
        // Unfollow
        await followingRef.remove();
        await followersRef.remove();
      } else {
        // Follow
        await followingRef.set(true);
        await followersRef.set(true);
      }

      setState(() {
        _isFollowing = !_isFollowing;

      });
    }
  }

  Future<void> _toggleLike(String postId, bool isCurrentlyLiked) async {
    if (_currentUser != null) {
      DatabaseReference likesRef = _dbRef.child("posts").child(postId).child("likes").child(_currentUser!.uid);
      if (isCurrentlyLiked) {
        // Unlike the post
        await likesRef.remove();
      } else {
        // Like the post
        await likesRef.set(true);
      }
    }
  }

  void _viewPostDetails(Map<String, dynamic> post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PostDetailScreen(post: post, currentUser: _currentUser)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_username),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile picture and info
            SizedBox(height: 16),
            CircleAvatar(
              radius: 50,
              backgroundImage: _profileImageUrl != null
                  ? NetworkImage(_profileImageUrl!)
                  : AssetImage('assets/profile_placeholder.png') as ImageProvider,
            ),
            SizedBox(height: 8),
            Text(
              _username,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              _email,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            // Follow button
            ElevatedButton(
              onPressed: _toggleFollow,
              child: Text(_isFollowing ? 'Unfollow' : 'Follow'),
            ),
            // Stats
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('Photos', _photosCount.toString()),
                  _buildStatItem('Followers', _followersCount.toString()),
                  _buildStatItem('Follows', _followsCount.toString()),
                ],
              ),
            ),
            // Posts grid
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  return GestureDetector(
                    onTap: () => _viewPostDetails(post),
                    child: Stack(
                      children: [
                        Image.network(post['imageUrl'], fit: BoxFit.cover),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  post['isLikedByCurrentUser'] ? Icons.favorite : Icons.favorite_border,
                                  color: post['isLikedByCurrentUser'] ? Colors.red : Colors.white,
                                ),
                                onPressed: () => _toggleLike(post['postId'], post['isLikedByCurrentUser']),
                              ),
                              Text(
                                '${post['likesCount']}',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String count) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(color: Colors.grey)),
        SizedBox(height: 4),
        Text(count, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}