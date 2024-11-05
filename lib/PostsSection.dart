import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PostsSection extends StatefulWidget {
  final DatabaseReference dbRef;

  PostsSection({required this.dbRef});

  @override
  _PostsSectionState createState() => _PostsSectionState();
}

class _PostsSectionState extends State<PostsSection> {
  List<Map<String, dynamic>> posts = [];
  Map<String, List<Map<String, dynamic>>> postComments = {};
  Map<String, Map<String, dynamic>> userProfiles = {}; // Cache for user profiles
  Map<String, String> profileImageUrls = {}; // Cache for profile image URLs
  List<Map<String, dynamic>> filteredPosts = []; // List to hold filtered posts
  String searchQuery = ""; // Search query string

  @override
  void initState() {
    super.initState();
    loadPostsAndComments();
  }

  /// Loads posts, comments, and user profile data from the database
  void loadPostsAndComments() async {
    await loadPosts(); // Load all posts
    await loadComments(); // Load all comments and associate them with their posts
    await loadUserProfiles(); // Load user profiles for each post owner
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

  /// Loads user profile data for each post owner, including profile image URL
  Future<void> loadUserProfiles() async {
    for (var post in posts) {
      final userId = post['userId'];
      if (userId != null && !userProfiles.containsKey(userId)) {
        final userSnapshot = await widget.dbRef.child('users').child(userId).get();
        if (userSnapshot.exists) {
          userProfiles[userId] = Map<String, dynamic>.from(userSnapshot.value as Map);
          userProfiles[userId]?['profileImageUrl'] = await fetchProfileImageUrl(userId);
        }
      }
    }
  }

  /// Fetches the profile image URL for a given userId from Firebase Storage
  Future<String> fetchProfileImageUrl(String userId) async {
    if (profileImageUrls.containsKey(userId)) {
      return profileImageUrls[userId]!; // Return cached URL if available
    }
    try {
      final ref = FirebaseStorage.instance.ref().child('users/$userId/profile.jpg');
      String url = await ref.getDownloadURL();
      profileImageUrls[userId] = url; // Cache the URL
      return url;
    } catch (e) {
      print("Error fetching profile image for user $userId: $e");
      return ''; // Return an empty string if the image is not found
    }
  }

  /// Deletes a specific post and all its associated comments
  Future<void> deletePost(String postId) async {
    try {
      // Remove the post
      await widget.dbRef.child('posts').child(postId).remove();
      print("Post with ID $postId deleted successfully.");

      // Remove associated comments
      final commentsSnapshot = await widget.dbRef.child('comments').orderByChild('post_Id').equalTo(postId).get();
      if (commentsSnapshot.exists) {
        for (var commentSnapshot in commentsSnapshot.children) {
          await widget.dbRef.child('comments').child(commentSnapshot.key!).remove();
          print("Comment with ID ${commentSnapshot.key} for post $postId deleted.");
        }
      }

      setState(() {
        posts.removeWhere((post) => post['postId'] == postId); // Update the post list in memory
        postComments.remove(postId); // Remove associated comments from memory
        applySearchFilter(); // Update filtered list after deletion
      });
    } catch (e) {
      print("Error deleting post with ID $postId: $e");
    }
  }

  /// Deletes a specific comment
  Future<void> deleteComment(String commentId, String postId) async {
    try {
      await widget.dbRef.child('comments').child(commentId).remove();
      print("Comment with ID $commentId deleted successfully.");

      setState(() {
        // Update the local comments list after deletion
        postComments[postId]?.removeWhere((comment) => comment['commentId'] == commentId);
      });
    } catch (e) {
      print("Error deleting comment with ID $commentId: $e");
    }
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
  Future<void> confirmDeletePost(String postId) async {
    final bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Post"),
        content: Text("Are you sure you want to delete this post and its comments?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Return false if cancelled
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Return true if confirmed
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      await deletePost(postId); // Proceed with deletion if confirmed
    }
  }

  /// Displays a confirmation dialog before deleting a comment
  Future<void> confirmDeleteComment(String commentId, String postId) async {
    final bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Comment"),
        content: Text("Are you sure you want to delete this comment?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Return false if cancelled
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Return true if confirmed
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      await deleteComment(commentId, postId); // Proceed with deletion if confirmed
    }
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
                final userId = post['userId'] ?? '';
                final comments = postComments[postId] ?? [];
                final user = userProfiles[userId] ?? {};
                final profileImageUrl = user['profileImageUrl'] ?? '';

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display post owner's profile information
                        ListTile(
                          leading: CircleAvatar(
                            backgroundImage: profileImageUrl.isNotEmpty
                                ? NetworkImage(profileImageUrl)
                                : AssetImage('assets/profile_placeholder.png') as ImageProvider,
                          ),
                          title: Text(user['username'] ?? 'Unknown User'),
                          subtitle: Text(user['email'] ?? 'No email'),
                        ),
                        // Display post image if available
                        if (post['imageUrl'] != null && post['imageUrl'].isNotEmpty)
                          Image.network(
                            post['imageUrl'],
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
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
                            ),
                        ] else
                          Text("No comments for this post", style: TextStyle(color: Colors.grey)),
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
