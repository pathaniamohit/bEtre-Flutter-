import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'OtherUserProfileScreen.dart'; // Add this import

class SearchUserScreen extends StatefulWidget {
  @override
  _SearchUserScreenState createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<dynamic, dynamic>> _users = [];
  List<Map<dynamic, dynamic>> _posts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAllPosts(); // Fetch all posts when the screen initializes
  }

  Future<void> _fetchAllPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch the current user
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Fetch the list of users the current user is following
      DatabaseReference followingRef = FirebaseDatabase.instance.ref('following/${currentUser.uid}');
      DataSnapshot followingSnapshot = await followingRef.get();

      List<String> followedUserIds = [];
      if (followingSnapshot.exists) {
        followingSnapshot.children.forEach((child) {
          followedUserIds.add(child.key!); // Get followed user IDs
        });
      }

      // Fetch all posts
      DatabaseReference postsRef = FirebaseDatabase.instance.ref('posts');
      DataSnapshot snapshot = await postsRef.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> postsData = snapshot.value as Map<dynamic, dynamic>;
        List<Map<dynamic, dynamic>> allPosts = [];

        postsData.forEach((key, value) {
          Map<dynamic, dynamic> post = Map<dynamic, dynamic>.from(value);

          // Exclude the current user's posts and followed users' posts
          if (post['userId'] != currentUser.uid && !followedUserIds.contains(post['userId'])) {
            post['postId'] = key;
            allPosts.add(post);
          }
        });

        setState(() {
          _posts = allPosts;
        });
      } else {
        print("No posts found in Firebase");
      }
    } catch (e) {
      print("Error fetching posts: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

          userData.forEach((key, value) {
            if (value['username'].toString().toLowerCase().contains(query.toLowerCase())) {
              Map<dynamic, dynamic> user = Map<dynamic, dynamic>.from(value);
              user['uid'] = key;
              _users.add(user);
            }
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


  Widget _buildPostCard(Map<dynamic, dynamic> post) {
    return FutureBuilder(
      future: FirebaseDatabase.instance.ref('users/${post['userId']}').get(),
      builder: (context, AsyncSnapshot<DataSnapshot> snapshot) {
        if (snapshot.hasData && snapshot.data!.value != null) {
          Map<dynamic, dynamic> userData = snapshot.data!.value as Map<dynamic, dynamic>;
          return Card(
            margin: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: userData['profileImageUrl'] != null
                        ? NetworkImage(userData['profileImageUrl'])
                        : AssetImage('assets/profile_placeholder.png') as ImageProvider,
                  ),
                  title: Text(userData['username'] ?? 'Unknown User'),
                  subtitle: Text(post['location'] ?? ''),
                ),
                if (post['imageUrl'] != null && post['imageUrl'].isNotEmpty)
                  Image.network(post['imageUrl']),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(post['content'] ?? ''),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: Icon(Icons.favorite_border),
                      onPressed: () {
                        // Implement like functionality
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.comment),
                      onPressed: () {
                        // Implement comment functionality
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        }
        return SizedBox.shrink();
      },
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
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user['profileImageUrl'] != null
                        ? NetworkImage(user['profileImageUrl'])
                        : AssetImage('assets/profile_placeholder.png') as ImageProvider,
                  ),
                  title: Text(user['username']),
                  subtitle: Text(user['email']),
                  onTap: () => _navigateToUserProfile(user['uid']),
                );
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

