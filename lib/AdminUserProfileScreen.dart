// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'PostDetailScreen.dart';
//
// class AdminUserProfileScreen extends StatefulWidget {
//   final DatabaseReference dbRef;
//   final String userId;
//
//   AdminUserProfileScreen({required this.dbRef, required this.userId});
//
//   @override
//   _AdminUserProfileScreenState createState() => _AdminUserProfileScreenState();
// }
//
// class _AdminUserProfileScreenState extends State<AdminUserProfileScreen> {
//   Map<String, dynamic>? _userData;
//   List<Map<String, dynamic>> _userPosts = [];
//   bool _isLoading = true;
//
//   int _photosCount = 0;
//   int _followersCount = 0;
//   int _followsCount = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     print('AdminUserProfileScreen initialized for userId: ${widget.userId}');
//     _fetchUserData();
//     _fetchUserPosts();
//     _fetchUserStats();
//   }
//
//   // Fetch user profile data
//   Future<void> _fetchUserData() async {
//     try {
//       DataSnapshot snapshot =
//       await widget.dbRef.child('users').child(widget.userId).get();
//       if (snapshot.exists) {
//         setState(() {
//           _userData = Map<String, dynamic>.from(snapshot.value as Map);
//           _isLoading = false;
//         });
//         print('User data fetched: $_userData');
//       } else {
//         setState(() {
//           _isLoading = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("User not found"),
//             backgroundColor: Colors.red,
//           ),
//         );
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Error fetching user data: $e"),
//           backgroundColor: Colors.red,
//         ),
//       );
//       Navigator.pop(context);
//     }
//   }
//
//   // Fetch user posts
//   Future<void> _fetchUserPosts() async {
//     try {
//       DataSnapshot snapshot = await widget.dbRef
//           .child('posts')
//           .orderByChild('userId')
//           .equalTo(widget.userId)
//           .get();
//
//       if (snapshot.exists) {
//         List<Map<String, dynamic>> posts = [];
//         for (var post in snapshot.children) {
//           var postData = Map<String, dynamic>.from(post.value as Map);
//           postData['postId'] = post.key;
//           posts.add(postData);
//           print('Fetched post: ${post.key} - Content: ${postData['content']}');
//         }
//         setState(() {
//           _userPosts = posts;
//           _photosCount = posts.length;
//         });
//         print('Total posts fetched: ${posts.length}');
//       } else {
//         print('No posts found for userId: ${widget.userId}');
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Error fetching user posts: $e"),
//           backgroundColor: Colors.red,
//         ),
//       );
//       print('Error in _fetchUserPosts: $e');
//     }
//   }
//
//   // Fetch user statistics
//   Future<void> _fetchUserStats() async {
//     try {
//       // Fetch followers count
//       DataSnapshot followersSnapshot =
//       await widget.dbRef.child('followers').child(widget.userId).get();
//       setState(() {
//         _followersCount = followersSnapshot.exists
//             ? followersSnapshot.children.length
//             : 0;
//       });
//       print('Followers count: $_followersCount');
//
//       // Fetch following count
//       DataSnapshot followingSnapshot =
//       await widget.dbRef.child('following').child(widget.userId).get();
//       setState(() {
//         _followsCount = followingSnapshot.exists
//             ? followingSnapshot.children.length
//             : 0;
//       });
//       print('Follows count: $_followsCount');
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Error fetching user stats: $e"),
//           backgroundColor: Colors.red,
//         ),
//       );
//       print('Error in _fetchUserStats: $e');
//     }
//   }
//
//   // View post details
//   void _viewPostDetails(Map<String, dynamic> post) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => PostDetailScreen(
//           post: post,
//           currentUser: null, // Admin view; adjust if necessary
//         ),
//       ),
//     );
//   }
//
//   // Build user information section
//   Widget _buildUserInfo() {
//     return Column(
//       children: [
//         SizedBox(height: 16),
//         CircleAvatar(
//           radius: 50,
//           backgroundImage: _userData!['profileImageUrl'] != null
//               ? NetworkImage(_userData!['profileImageUrl'])
//               : AssetImage('assets/profile_placeholder.png') as ImageProvider,
//         ),
//         SizedBox(height: 8),
//         Text(
//           _userData!['username'] ?? 'Username',
//           style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//         ),
//         Text(
//           _userData!['email'] ?? 'Email',
//           style: TextStyle(fontSize: 16, color: Colors.grey),
//         ),
//         SizedBox(height: 8),
//         if (_userData!['bio'] != null && _userData!['bio'].isNotEmpty)
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0),
//             child: Text(
//               _userData!['bio'],
//               style: TextStyle(fontSize: 14, color: Colors.black87),
//               textAlign: TextAlign.center,
//             ),
//           ),
//         SizedBox(height: 16),
//         // Statistics Display
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _buildStatItem('Photos', _photosCount.toString()),
//               _buildStatItem('Followers', _followersCount.toString()),
//               _buildStatItem('Follows', _followsCount.toString()),
//             ],
//           ),
//         ),
//         SizedBox(height: 16),
//       ],
//     );
//   }
//
//   // Build statistics item
//   Widget _buildStatItem(String label, String count) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Text(label, style: TextStyle(color: Colors.grey)),
//         SizedBox(height: 4),
//         Text(count,
//             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//       ],
//     );
//   }
//
//   // Build user posts section
//   Widget _buildUserPosts() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _userPosts.isNotEmpty
//             ? Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0),
//           child: GridView.builder(
//             physics: NeverScrollableScrollPhysics(),
//             shrinkWrap: true,
//             gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 3,
//               crossAxisSpacing: 10,
//               mainAxisSpacing: 10,
//               childAspectRatio: 1, // Ensures each grid item is square
//             ),
//             itemCount: _userPosts.length,
//             itemBuilder: (context, index) {
//               final post = _userPosts[index];
//               return GestureDetector(
//                 onTap: () => _viewPostDetails(post),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.grey.shade300),
//                     color: Colors.black12,
//                   ),
//                   child: Stack(
//                     fit: StackFit.expand,
//                     children: [
//                       Image.network(
//                         post['imageUrl'],
//                         fit: BoxFit.cover,
//                       ),
//                       Positioned(
//                         bottom: 4,
//                         left: 4,
//                         child: Container(
//                           padding: EdgeInsets.symmetric(
//                               horizontal: 4, vertical: 2),
//                           color: Colors.black54,
//                           child: Row(
//                             children: [
//                               Icon(
//                                 Icons.favorite,
//                                 color: Colors.redAccent,
//                                 size: 16,
//                               ),
//                               SizedBox(width: 2),
//                               Text(
//                                 '${post['likesCount']}',
//                                 style: TextStyle(
//                                     color: Colors.white, fontSize: 12),
//                               ),
//                               SizedBox(width: 8),
//                               Icon(
//                                 Icons.comment,
//                                 color: Colors.white,
//                                 size: 16,
//                               ),
//                               SizedBox(width: 2),
//                               Text(
//                                 '${post['commentsCount']}',
//                                 style: TextStyle(
//                                     color: Colors.white, fontSize: 12),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         )
//             : Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Text("This user hasn't made any posts yet."),
//         ),
//         // Temporary Debug Widget
//         SizedBox(height: 20),
//         Text(
//           'Total Posts: ${_userPosts.length}',
//           style: TextStyle(color: Colors.red),
//         ),
//       ],
//     );
//   }
//
//   // Build the entire UI
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Admin - User Profile'),
//       ),
//       body: _isLoading
//           ? Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//         child: Column(
//           children: [
//             _buildUserInfo(),
//             Divider(),
//             _buildUserPosts(),
//             Divider(),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'PostDetailScreen.dart';
// import 'package:cached_network_image/cached_network_image.dart';

class AdminUserProfileScreen extends StatefulWidget {
  final DatabaseReference dbRef;
  final String userId;

  AdminUserProfileScreen({required this.dbRef, required this.userId});

  @override
  _AdminUserProfileScreenState createState() => _AdminUserProfileScreenState();
}

class _AdminUserProfileScreenState extends State<AdminUserProfileScreen> {
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _userPosts = [];
  bool _isLoading = true;

  int _photosCount = 0;
  int _followersCount = 0;
  int _followsCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchUserPosts();
    _fetchUserStats();
  }

  // Fetch user profile data
  Future<void> _fetchUserData() async {
    try {
      DataSnapshot snapshot =
      await widget.dbRef.child('users').child(widget.userId).get();
      if (snapshot.exists) {
        setState(() {
          _userData = Map<String, dynamic>.from(snapshot.value as Map);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(
            msg: "User not found", gravity: ToastGravity.BOTTOM);
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(
          msg: "Error fetching user data: $e", gravity: ToastGravity.BOTTOM);
      Navigator.pop(context);
    }
  }

  // Fetch user posts
  Future<void> _fetchUserPosts() async {
    try {
      DataSnapshot snapshot = await widget.dbRef
          .child('posts')
          .orderByChild('userId')
          .equalTo(widget.userId)
          .get();

      if (snapshot.exists) {
        List<Map<String, dynamic>> posts = [];
        for (var post in snapshot.children) {
          var postData = Map<String, dynamic>.from(post.value as Map);
          postData['postId'] = post.key;

          // Fetch likesCount and commentsCount
          int likesCount = postData['likes'] != null
              ? (postData['likes'] as Map).length
              : 0;
          int commentsCount = postData['comments'] != null
              ? (postData['comments'] as Map).length
              : 0;

          postData['likesCount'] = likesCount;
          postData['commentsCount'] = commentsCount;

          posts.add(postData);
        }
        setState(() {
          _userPosts = posts;
          _photosCount = posts.length;
        });
      }
    } catch (e) {
      Fluttertoast.showToast(
          msg: "Error fetching user posts: $e", gravity: ToastGravity.BOTTOM);
    }
  }

  // Fetch user statistics
  Future<void> _fetchUserStats() async {
    try {
      // Fetch followers count
      DataSnapshot followersSnapshot =
      await widget.dbRef.child('followers').child(widget.userId).get();
      setState(() {
        _followersCount = followersSnapshot.exists
            ? followersSnapshot.children.length
            : 0;
      });

      // Fetch following count
      DataSnapshot followingSnapshot =
      await widget.dbRef.child('following').child(widget.userId).get();
      setState(() {
        _followsCount = followingSnapshot.exists
            ? followingSnapshot.children.length
            : 0;
      });
    } catch (e) {
      Fluttertoast.showToast(
          msg: "Error fetching user stats: $e", gravity: ToastGravity.BOTTOM);
    }
  }

  // View post details
  void _viewPostDetails(Map<String, dynamic> post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(
          post: post,
          currentUser: null, // Admin view; adjust if necessary
        ),
      ),
    );
  }

  // Build user information section
  Widget _buildUserInfo() {
    return Column(
      children: [
        SizedBox(height: 16),
        CircleAvatar(
          radius: 50,
          backgroundImage: _userData!['profileImageUrl'] != null
              ? NetworkImage(_userData!['profileImageUrl'])
              : AssetImage('assets/profile_placeholder.png') as ImageProvider,
        ),
        SizedBox(height: 8),
        Text(
          _userData!['username'] ?? 'Username',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          _userData!['email'] ?? 'Email',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        SizedBox(height: 8),
        if (_userData!['bio'] != null && _userData!['bio'].isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              _userData!['bio'],
              style: TextStyle(fontSize: 14, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ),
        SizedBox(height: 16),
        // Statistics Display
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Photos', _photosCount.toString()),
              _buildStatItem('Followers', _followersCount.toString()),
              _buildStatItem('Follows', _followsCount.toString()),
            ],
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  // Build statistics item
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

  // Build user posts section
  Widget _buildUserPosts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _userPosts.isNotEmpty
            ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GridView.builder(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1, // Ensures each grid item is square
            ),
            itemCount: _userPosts.length,
            itemBuilder: (context, index) {
              final post = _userPosts[index];
              return GestureDetector(
                onTap: () => _viewPostDetails(post),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.black12,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        post['imageUrl'],
                        fit: BoxFit.cover,
                        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                          return Icon(Icons.error);
                        },
                      ),

                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          color: Colors.black54,
                          child: Row(
                            children: [
                              Icon(
                                Icons.favorite,
                                color: Colors.redAccent,
                                size: 16,
                              ),
                              SizedBox(width: 2),
                              Text(
                                '${post['likesCount']}',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.comment,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 2),
                              Text(
                                '${post['commentsCount']}',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        )
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text("This user hasn't made any posts yet."),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  // Build the entire UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_userData != null ? _userData!['username'] : 'User Profile'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildUserInfo(),
            Divider(),
            _buildUserPosts(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
