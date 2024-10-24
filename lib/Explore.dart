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

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    // _loadFollowedUsersPosts();
    _loadExplorePosts();
  }

  Future<void> _loadExplorePosts() async {
    _postRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> postsData = event.snapshot.value as Map<dynamic, dynamic>;
        List<Map<dynamic, dynamic>> explorePosts = [];

        postsData.forEach((key, value) {
          Map<dynamic, dynamic> post = Map<dynamic, dynamic>.from(value);
          post['postId'] = key;


          if (post['userId'] != _currentUser!.uid) {
            explorePosts.add(post);
          }
        });

        setState(() {
          _posts = explorePosts;
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
      trailing: ElevatedButton(
        onPressed: () => _followUser(post['userId']),
        child: Text('Follow'),
      ),
    );
  }

  Widget _buildPostFooter(Map<dynamic, dynamic> post) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        IconButton(
          icon: Icon(Icons.favorite, color: post['isLiked'] == true ? Colors.red : Colors.grey),
          onPressed: () => _toggleLike(post),
        ),
        IconButton(
          icon: Icon(Icons.comment),
          onPressed: () => _navigateToComments(post),
        ),
        Text('${post['count_like'] ?? 0} Likes'),
        Text('${post['count_comment'] ?? 0} Comments'),
      ],
    );
  }

  void _followUser(String userId) {
    // Add logic to follow the user
  }

  void _toggleLike(Map<dynamic, dynamic> post) {
    final postId = post['postId'];
    final isLiked = post['isLiked'] ?? false;
    int likeCount = post['count_like'] ?? 0;

    _postRef.child(postId).update({
      'isLiked': !isLiked,
      'count_like': isLiked ? likeCount - 1 : likeCount + 1,
    });
  }



  void _navigateToComments(Map<dynamic, dynamic> post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentScreen(postId: post['postId']),
      ),
    );
  }

}

