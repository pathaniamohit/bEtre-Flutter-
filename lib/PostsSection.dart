import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class PostsSection extends StatefulWidget {
  final DatabaseReference dbRef;

  PostsSection({required this.dbRef});

  @override
  _PostsSectionState createState() => _PostsSectionState();
}

class _PostsSectionState extends State<PostsSection> {
  List<Map<String, dynamic>> posts = [];
  Map<String, List<Map<String, dynamic>>> postComments = {};
  List<Map<String, dynamic>> filteredPosts = []; // List to hold filtered posts
  String searchQuery = ""; // Search query string

  @override
  void initState() {
    super.initState();
    loadPostsAndComments();
  }

  /// Loads posts and their associated comments from the database
  void loadPostsAndComments() async {
    await loadPosts(); // Load all posts
    await loadComments(); // Load all comments and associate them with their posts
    setState(() {
      filteredPosts = posts; // Initialize filteredPosts with all posts
    });
  }

  /// Loads all posts from the database
  Future<void> loadPosts() async {
    final postsSnapshot = await widget.dbRef.child('posts').get();
    if (postsSnapshot.exists) {
      posts = [];
      for (var postSnapshot in postsSnapshot.children) {
        var postId = postSnapshot.key!;
        var postData = Map<String, dynamic>.from(postSnapshot.value as Map);
        postData['postId'] = postId;
        posts.add(postData);
      }
    }
  }

  /// Loads all comments and maps them to their respective posts based on post_Id
  Future<void> loadComments() async {
    final commentsSnapshot = await widget.dbRef.child('comments').get();
    if (commentsSnapshot.exists) {
      postComments = {}; // Reset comments map
      for (var commentSnapshot in commentsSnapshot.children) {
        var commentData = Map<String, dynamic>.from(commentSnapshot.value as Map);
        var postId = commentData['post_Id'];
        if (postId != null) {
          // Add comment to the respective post's comment list
          postComments.putIfAbsent(postId, () => []).add(commentData);
        }
      }
    }
  }

  /// Deletes a specific post and all its associated comments
  Future<void> deletePost(String postId) async {
    await widget.dbRef.child('posts').child(postId).remove(); // Remove the post

    // Remove associated comments
    final commentsSnapshot = await widget.dbRef.child('comments').orderByChild('post_Id').equalTo(postId).get();
    if (commentsSnapshot.exists) {
      for (var commentSnapshot in commentsSnapshot.children) {
        await widget.dbRef.child('comments').child(commentSnapshot.key!).remove();
      }
    }

    setState(() {
      posts.removeWhere((post) => post['postId'] == postId); // Update the post list in memory
      postComments.remove(postId); // Remove associated comments from memory
      applySearchFilter(); // Update filtered list after deletion
    });
  }

  /// Applies the search filter to posts based on the search query
  void applySearchFilter() {
    setState(() {
      filteredPosts = posts.where((post) {
        final content = post['content']?.toLowerCase() ?? '';
        final location = post['location']?.toLowerCase() ?? '';
        return content.contains(searchQuery.toLowerCase()) ||
            location.contains(searchQuery.toLowerCase());
      }).toList();
    });
  }

  /// Displays a confirmation dialog before deleting a post
  void confirmDeletePost(String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Post"),
        content: Text("Are you sure you want to delete this post and its comments?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              deletePost(postId);
              Navigator.pop(context);
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Posts Section"),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: "Search by content or location",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value; // Update the search query
                  applySearchFilter(); // Apply filter based on search query
                });
              },
            ),
          ),
          // Display posts
          Expanded(
            child: filteredPosts.isNotEmpty
                ? ListView.builder(
              itemCount: filteredPosts.length,
              itemBuilder: (context, index) {
                final post = filteredPosts[index];
                final postId = post['postId'];
                final comments = postComments[postId] ?? []; // Get comments for this post

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display post image if available
                        if (post['imageUrl'] != null && post['imageUrl'].isNotEmpty)
                          Image.network(
                            post['imageUrl'],
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
                          )
                        else
                          Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: Icon(Icons.image, size: 50, color: Colors.grey[700]),
                          ),
                        SizedBox(height: 10),

                        // Display post content
                        Text(post['content'] ?? 'No content', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        Text("Location: ${post['location'] ?? 'Unknown location'}", style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 10),

                        // Display comments for the post
                        if (comments.isNotEmpty) ...[
                          Text("Comments:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          for (var comment in comments)
                            ListTile(
                              leading: Icon(Icons.comment, color: Colors.grey),
                              title: Text(comment['username'] ?? 'Anonymous'),
                              subtitle: Text(comment['content'] ?? 'No content'),
                              trailing: Text(
                                DateTime.fromMillisecondsSinceEpoch(comment['timestamp'].toInt()).toString(),
                                style: TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ),
                        ] else
                          Text("No comments for this post", style: TextStyle(color: Colors.grey)),

                        // Delete button for post
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => confirmDeletePost(postId),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
                : Center(
              child: Text("No posts available"),
            ),
          ),
        ],
      ),
    );
  }
}
