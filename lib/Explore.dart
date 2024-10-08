import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ExploreScreen extends StatefulWidget {
  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final DatabaseReference _postRef = FirebaseDatabase.instance.ref().child('posts');
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref().child('users');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Explore'),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: _postRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            Map<dynamic, dynamic> posts = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            List<dynamic> postList = posts.values.toList();

            return ListView.builder(
              itemCount: postList.length,
              itemBuilder: (context, index) {
                var post = postList[index];
                return _buildPostCard(post);
              },
            );
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
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
                if (post['imageUrl'] != null && post['imageUrl'].isNotEmpty)  // Ensure the image URL exists and is not empty
                  Image.network(post['imageUrl']),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(post['content'] ?? 'No content'),  // Fallback to 'No content' if content is null
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
        backgroundImage: userData['profilePictureUrl'] != null && userData['profilePictureUrl'].isNotEmpty
            ? NetworkImage(userData['profilePictureUrl'])
            : AssetImage('assets/default_profile.png'),
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
        Text('${post['count_like'] ?? 0} Likes'),  // Fallback to 0 if count_like is null
        Text('${post['count_comment'] ?? 0} Comments'),  // Fallback to 0 if count_comment is null
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
    // Add navigation logic to comments screen
  }
}
