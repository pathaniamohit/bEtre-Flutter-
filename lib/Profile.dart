// // // import 'dart:io';
// // // import 'package:betreflutter/CommentScreen.dart';
// // // import 'package:flutter/material.dart';
// // // import 'package:firebase_auth/firebase_auth.dart';
// // // import 'package:firebase_database/firebase_database.dart';
// // // import 'package:firebase_storage/firebase_storage.dart';
// // // import 'package:image_picker/image_picker.dart';
// // // import 'package:fluttertoast/fluttertoast.dart';
// // // import 'PostDetailScreen.dart';
// // // import 'Settings.dart';
// // // import 'dart:async';
// // //
// // // class ProfileScreen extends StatefulWidget {
// // //   @override
// // //   _ProfileScreenState createState() => _ProfileScreenState();
// // // }
// // //
// // // class _ProfileScreenState extends State<ProfileScreen> {
// // //   final FirebaseAuth _auth = FirebaseAuth.instance;
// // //   final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
// // //   final FirebaseStorage _storage = FirebaseStorage.instance;
// // //
// // //   User? _user;
// // //   String? _profileImageUrl;
// // //   String _username = "Username";
// // //   String _email = "Email";
// // //   int _photosCount = 0;
// // //   int _followersCount = 0;
// // //   int _followsCount = 0;
// // //   String _bio = '';
// // //
// // //   List<Map<String, dynamic>> _posts = []; // Modify to store post details
// // //   File? _image;
// // //   int _tapCount = 0;
// // //   Timer? _tapTimer;
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _user = _auth.currentUser;
// // //     if (_user != null) {
// // //       _loadUserProfile();
// // //       _loadUserStats();
// // //       _loadUserPosts();
// // //     }
// // //   }
// // //
// // //   Future<void> _loadUserProfile() async {
// // //     if (_user != null) {
// // //       _dbRef.child("users").child(_user!.uid).once().then((snapshot) {
// // //         if (snapshot.snapshot.exists) {
// // //           var userData = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
// // //           setState(() {
// // //             _username = userData['username'] ?? 'Username';
// // //             _email = userData['email'] ?? 'Email';
// // //             _profileImageUrl = userData['profileImageUrl'];
// // //           });
// // //         }
// // //       });
// // //     }
// // //   }
// // //
// // //   Future<void> _loadUserStats() async {
// // //     if (_user != null) {
// // //       _dbRef.child("followers").child(_user!.uid).onValue.listen((event) {
// // //         final dataSnapshot = event.snapshot;
// // //         if (dataSnapshot.exists) {
// // //           setState(() {
// // //             _followersCount = dataSnapshot.children.length;
// // //           });
// // //         } else {
// // //           setState(() {
// // //             _followersCount = 0;
// // //           });
// // //         }
// // //       });
// // //
// // //       _dbRef.child("following").child(_user!.uid).onValue.listen((event) {
// // //         final dataSnapshot = event.snapshot;
// // //         if (dataSnapshot.exists) {
// // //           setState(() {
// // //             _followsCount = dataSnapshot.children.length;
// // //           });
// // //         } else {
// // //           setState(() {
// // //             _followsCount = 0;
// // //           });
// // //         }
// // //       });
// // //
// // //       _dbRef.child("posts").orderByChild("userId").equalTo(_user!.uid).onValue.listen((event) {
// // //         final dataSnapshot = event.snapshot;
// // //         if (dataSnapshot.exists) {
// // //           setState(() {
// // //             _photosCount = dataSnapshot.children.length;
// // //           });
// // //         } else {
// // //           setState(() {
// // //             _photosCount = 0;
// // //           });
// // //         }
// // //       });
// // //     }
// // //   }
// // //
// // //
// // //   Future<void> _loadUserPosts() async {
// // //     if (_user != null) {
// // //       _dbRef
// // //           .child("posts")
// // //           .orderByChild("userId")
// // //           .equalTo(_user!.uid)
// // //           .onValue
// // //           .listen((event) {
// // //         List<Map<String, dynamic>> posts = [];
// // //         for (var post in event.snapshot.children) {
// // //           var postData = Map<String, dynamic>.from(post.value as Map);
// // //           postData['postId'] = post.key; // Store post ID for later use
// // //
// // //           // Get likes
// // //           int likesCount = 0;
// // //           bool isLikedByCurrentUser = false;
// // //           if (postData['likes'] != null) {
// // //             Map<dynamic, dynamic> likesMap = postData['likes'];
// // //             likesCount = likesMap.length;
// // //             if (likesMap.containsKey(_user!.uid)) {
// // //               isLikedByCurrentUser = true;
// // //             }
// // //           }
// // //           postData['likesCount'] = likesCount;
// // //           postData['isLikedByCurrentUser'] = isLikedByCurrentUser;
// // //
// // //           // Get comments count
// // //           int commentsCount = 0;
// // //           if (postData['comments'] != null) {
// // //             Map<dynamic, dynamic> commentsMap = postData['comments'];
// // //             commentsCount = commentsMap.length;
// // //           }
// // //           postData['commentsCount'] = commentsCount;
// // //
// // //           posts.add(postData);
// // //         }
// // //
// // //         // Reverse the list for Instagram-like ordering (newest to oldest)
// // //         posts = posts.reversed.toList();
// // //
// // //         setState(() {
// // //           _posts = posts;
// // //         });
// // //       });
// // //     }
// // //   }
// // //
// // //
// // //
// // //
// // //   Future<void> _onPostTripleTap(String postId) async {
// // //     showDialog(
// // //       context: context,
// // //       builder: (context) {
// // //         return AlertDialog(
// // //           title: Text('Delete Post'),
// // //           content: Text('Are you sure you want to delete this post?'),
// // //           actions: [
// // //             TextButton(
// // //               onPressed: () {
// // //                 Navigator.pop(context);
// // //               },
// // //               child: Text('Cancel'),
// // //             ),
// // //             TextButton(
// // //               onPressed: () {
// // //                 _deletePost(postId);
// // //                 Navigator.pop(context);
// // //               },
// // //               child: Text('Delete'),
// // //             ),
// // //           ],
// // //         );
// // //       },
// // //     );
// // //   }
// // //
// // //   Future<void> _deletePost(String postId) async {
// // //     if (_user != null) {
// // //       await _dbRef.child("posts").child(postId).remove();
// // //       Fluttertoast.showToast(msg: "Post deleted successfully", gravity: ToastGravity.BOTTOM);
// // //     }
// // //   }
// // //
// // //   Future<void> _onPostDoubleTap(String postId, String currentContent) async {
// // //     TextEditingController _contentController = TextEditingController(text: currentContent);
// // //     File? selectedImage;
// // //
// // //     showDialog(
// // //       context: context,
// // //       builder: (context) {
// // //         return AlertDialog(
// // //           title: Text('Edit Post'),
// // //           content: Column(
// // //             mainAxisSize: MainAxisSize.min,
// // //             children: [
// // //               TextField(
// // //                 controller: _contentController,
// // //                 decoration: InputDecoration(labelText: 'Edit Content'),
// // //               ),
// // //               SizedBox(height: 10),
// // //               ElevatedButton(
// // //                 onPressed: () async {
// // //                   final ImagePicker _picker = ImagePicker();
// // //                   final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
// // //                   if (image != null) {
// // //                     selectedImage = File(image.path);
// // //                     Fluttertoast.showToast(msg: "New image selected", gravity: ToastGravity.BOTTOM);
// // //                   }
// // //                 },
// // //                 child: Text("Change Image"),
// // //               ),
// // //             ],
// // //           ),
// // //           actions: [
// // //             TextButton(
// // //               onPressed: () {
// // //                 Navigator.pop(context);
// // //               },
// // //               child: Text('Cancel'),
// // //             ),
// // //             TextButton(
// // //               onPressed: () {
// // //                 _updatePost(postId, _contentController.text.trim(), selectedImage);
// // //                 Navigator.pop(context);
// // //               },
// // //               child: Text('Update'),
// // //             ),
// // //           ],
// // //         );
// // //       },
// // //     );
// // //   }
// // //
// // //   Future<void> _updatePost(String postId, String newContent, File? newImage) async {
// // //     if (_user != null) {
// // //       Map<String, dynamic> updatedData = {"content": newContent};
// // //
// // //       try {
// // //         // Update the image if a new image was selected
// // //         if (newImage != null) {
// // //           String path = 'post_images/${postId}.jpg';
// // //           SettableMetadata metadata = SettableMetadata(customMetadata: {
// // //             'userId': _user!.uid,
// // //           });
// // //
// // //           TaskSnapshot uploadTask = await _storage.ref(path).putFile(newImage, metadata);
// // //           String downloadUrl = await uploadTask.ref.getDownloadURL();
// // //           updatedData['imageUrl'] = downloadUrl;
// // //         }
// // //
// // //         await _dbRef.child("posts").child(postId).update(updatedData);
// // //         Fluttertoast.showToast(msg: "Post updated successfully", gravity: ToastGravity.BOTTOM);
// // //
// // //         // Reload the posts to reflect the changes
// // //         _loadUserPosts();
// // //       } catch (e) {
// // //         Fluttertoast.showToast(msg: "Failed to update post: $e", gravity: ToastGravity.BOTTOM);
// // //       }
// // //     }
// // //   }
// // //
// // //
// // //
// // //   Future<void> _toggleLike(String postId, bool isCurrentlyLiked) async {
// // //     if (_user != null) {
// // //       DatabaseReference likesRef = _dbRef.child("posts").child(postId).child("likes").child(_user!.uid);
// // //       if (isCurrentlyLiked) {
// // //         // Unlike the post
// // //         await likesRef.remove();
// // //       } else {
// // //         // Like the post
// // //         await likesRef.set(true);
// // //       }
// // //     }
// // //   }
// // //
// // //
// // //
// // //   Future<void> _uploadProfileImage(File image) async {
// // //     if (_user != null) {
// // //       try {
// // //         String path = 'users/${_user!.uid}/profile.jpg';
// // //         TaskSnapshot uploadTask = await _storage.ref(path).putFile(image);
// // //         String downloadUrl = await uploadTask.ref.getDownloadURL();
// // //
// // //         _dbRef.child("users").child(_user!.uid).update({
// // //           "profileImageUrl": downloadUrl,
// // //         });
// // //
// // //         setState(() {
// // //           _profileImageUrl = downloadUrl;
// // //         });
// // //
// // //         Fluttertoast.showToast(msg: "Profile image updated successfully", gravity: ToastGravity.BOTTOM);
// // //       } catch (e) {
// // //         Fluttertoast.showToast(msg: "Failed to upload profile image: $e", gravity: ToastGravity.BOTTOM);
// // //       }
// // //     }
// // //   }
// // //
// // //   Future<void> _pickImage() async {
// // //     final ImagePicker _picker = ImagePicker();
// // //     final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
// // //
// // //     if (image != null) {
// // //       setState(() {
// // //         _image = File(image.path);
// // //       });
// // //       _uploadProfileImage(_image!);
// // //     }
// // //   }
// // //
// // //   void _viewPostDetails(Map<String, dynamic> post) {
// // //     Navigator.push(
// // //       context,
// // //       MaterialPageRoute(builder: (context) => PostDetailScreen(post: post, currentUser: _user)),
// // //     );
// // //   }
// // //
// // //   void _navigateToComments(Map<dynamic, dynamic> post) {
// // //     Navigator.push(
// // //       context,
// // //       MaterialPageRoute(
// // //         builder: (context) => CommentScreen(
// // //           postId: post['postId'],
// // //           postOwnerId: post['userId'],
// // //           canReport: true,// Pass the post owner's ID
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       body: SingleChildScrollView(
// // //         child: Column(
// // //           children: [
// // //             Padding(
// // //               padding: const EdgeInsets.all(16.0),
// // //               child: Stack(
// // //                 alignment: Alignment.center,
// // //                 children: [
// // //                   Align(
// // //                     alignment: Alignment.center,
// // //                     child: Text(
// // //                       'My Profile',
// // //                       style: TextStyle(
// // //                         fontSize: 30,
// // //                         fontWeight: FontWeight.bold,
// // //                       ),
// // //                     ),
// // //                   ),
// // //
// // //
// // //                   Align(
// // //                     alignment: Alignment.centerRight,
// // //                     child: Padding(
// // //                       padding: const EdgeInsets.all(8.0),
// // //                       child: Container(
// // //                         margin: EdgeInsets.only(right: 10,top: 10),
// // //                         child: IconButton(
// // //                           iconSize: 36,
// // //                           icon: Icon(Icons.settings),
// // //                           onPressed: () {
// // //                             Navigator.push(
// // //                               context,
// // //                               MaterialPageRoute(builder: (context) => SettingsScreen()),
// // //                             );
// // //                           },
// // //                         ),
// // //                       ),
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //
// // //             GestureDetector(
// // //               onTap: _pickImage,
// // //               child: CircleAvatar(
// // //                 radius: 50,
// // //                 backgroundImage: _profileImageUrl != null
// // //                     ? NetworkImage(_profileImageUrl!)
// // //                     : AssetImage('assets/profile_placeholder.png') as ImageProvider,
// // //                 child: Align(
// // //                   alignment: Alignment.bottomRight,
// // //                   child: Icon(Icons.camera_alt, size: 24, color: Colors.white),
// // //                 ),
// // //               ),
// // //             ),
// // //             SizedBox(height: 8),
// // //             Text(
// // //               _username,
// // //               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
// // //             ),
// // //             Text(
// // //               _email,
// // //               style: TextStyle(fontSize: 16, color: Colors.grey),
// // //             ),
// // //
// // //             Padding(
// // //               padding: const EdgeInsets.symmetric(vertical: 16.0),
// // //               child: Row(
// // //                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// // //                 children: [
// // //                   _buildStatItem('Photos', _photosCount.toString()),
// // //                   _buildStatItem('Followers', _followersCount.toString()),
// // //                   _buildStatItem('Follows', _followsCount.toString()),
// // //                 ],
// // //               ),
// // //             ),
// // //
// // //             Padding(
// // //               padding: const EdgeInsets.all(16.0),
// // //               child: GridView.builder(
// // //                 physics: NeverScrollableScrollPhysics(),
// // //                 shrinkWrap: true,
// // //                 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
// // //                   crossAxisCount: 3,
// // //                   crossAxisSpacing: 10,
// // //                   mainAxisSpacing: 10,
// // //                   childAspectRatio: 1, // Ensures each grid item is square
// // //                 ),
// // //                 itemCount: _posts.length,
// // //                 itemBuilder: (context, index) {
// // //                   final post = _posts[index];
// // //                   return GestureDetector(
// // //                     onTap: () => _viewPostDetails(post),
// // //                     onDoubleTap: () => _onPostDoubleTap(post['postId'], post['content']), // Edit post
// // //                     onLongPress: () => _onPostTripleTap(post['postId']), // Delete post
// // //                     child: Container(
// // //                       decoration: BoxDecoration(
// // //                         border: Border.all(color: Colors.grey.shade300),
// // //                         color: Colors.black12,
// // //                       ),
// // //                       child: Stack(
// // //                         fit: StackFit.expand,
// // //                         children: [
// // //                           Image.network(
// // //                             post['imageUrl'],
// // //                             fit: BoxFit.cover,
// // //                           ),
// // //                           Positioned(
// // //                             bottom: 4,
// // //                             left: 4,
// // //                             child: Container(
// // //                               padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
// // //                               color: Colors.black54,
// // //                               child: Row(
// // //                                 children: [
// // //                                   Icon(
// // //                                     Icons.favorite,
// // //                                     color: Colors.redAccent,
// // //                                     size: 16,
// // //                                   ),
// // //                                   SizedBox(width: 2),
// // //                                   Text(
// // //                                     '${post['likesCount']}',
// // //                                     style: TextStyle(color: Colors.white, fontSize: 12),
// // //                                   ),
// // //                                   // SizedBox(width: 8),
// // //                                   // Icon(
// // //                                   //   Icons.comment,
// // //                                   //   color: Colors.white,
// // //                                   //   size: 16,
// // //                                   // ),
// // //
// // //                                   // IconButton(
// // //                                   //   icon: Icon(Icons.comment_bank, color: Colors.white, size: 20),
// // //                                   //   tooltip: 'View Comments',
// // //                                   //   onPressed: () => _navigateToComments(post),
// // //                                   // ),
// // //                                   IconButton(
// // //                                     icon: Icon(Icons.comment_bank, color: Colors.white, size: 20),
// // //                                     tooltip: 'View Comments',
// // //                                     onPressed: () => _navigateToComments(post),
// // //                                   ),
// // //                                   // SizedBox(width: 2),
// // //                                   // Text(
// // //                                   //   '${post['commentsCount']}',
// // //                                   //   style: TextStyle(color: Colors.white, fontSize: 12),
// // //                                   //
// // //                                   // ),
// // //                                 ],
// // //                               ),
// // //                             ),
// // //                           ),
// // //                         ],
// // //                       ),
// // //                     ),
// // //
// // //                   );
// // //                 },
// // //               ),
// // //             )
// // //
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _buildStatItem(String label, String count) {
// // //     return Column(
// // //       mainAxisAlignment: MainAxisAlignment.center,
// // //       children: [
// // //         Text(label, style: TextStyle(color: Colors.grey)),
// // //         SizedBox(height: 4),
// // //         Text(count, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
// // //       ],
// // //     );
// // //   }
// // //
// // //   Widget _buildRecentActivity() {
// // //     List<Widget> activityWidgets = [];
// // //
// // //     for (var post in _posts) {
// // //       // Fetch comments from other users
// // //       if (post['comments'] != null) {
// // //         post['comments'].forEach((commentId, commentData) {
// // //           if (commentData['userId'] != _user!.uid) {
// // //             activityWidgets.add(ListTile(
// // //               leading: Icon(Icons.comment),
// // //               title: Text('User ${commentData['userId']} commented on your post'),
// // //               subtitle: Text(commentData['content']),
// // //               onTap: () => _viewPostDetails(post),
// // //             ));
// // //           }
// // //         });
// // //       }
// // //
// // //       // Fetch likes from other users
// // //       if (post['likes'] != null) {
// // //         post['likes'].forEach((userId, _) {
// // //           if (userId != _user!.uid) {
// // //             activityWidgets.add(ListTile(
// // //               leading: Icon(Icons.favorite),
// // //               title: Text('User $userId liked your post'),
// // //               onTap: () => _viewPostDetails(post),
// // //             ));
// // //           }
// // //         });
// // //       }
// // //     }
// // //
// // //     return Column(
// // //       crossAxisAlignment: CrossAxisAlignment.start,
// // //       children: activityWidgets,
// // //     );
// // //   }
// // //
// // // }
// // //
// // // ProfileScreen.dart
// //
// // import 'dart:io';
// // import 'package:betreflutter/CommentScreen.dart';
// // import 'package:flutter/material.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:firebase_database/firebase_database.dart';
// // import 'package:firebase_storage/firebase_storage.dart';
// // import 'package:image_picker/image_picker.dart';
// // import 'package:fluttertoast/fluttertoast.dart';
// // import 'PostDetailScreen.dart';
// // import 'Settings.dart';
// // import 'dart:async';
// //
// // class ProfileScreen extends StatefulWidget {
// //   @override
// //   _ProfileScreenState createState() => _ProfileScreenState();
// // }
// //
// // class _ProfileScreenState extends State<ProfileScreen> {
// //   final FirebaseAuth _auth = FirebaseAuth.instance;
// //   final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
// //   final FirebaseStorage _storage = FirebaseStorage.instance;
// //
// //   User? _user;
// //   String? _profileImageUrl;
// //   String _username = "Username";
// //   String _email = "Email";
// //   int _photosCount = 0;
// //   int _followersCount = 0;
// //   int _followsCount = 0;
// //   String _bio = '';
// //
// //   List<Map<String, dynamic>> _posts = []; // To store post details
// //   File? _image;
// //   int _tapCount = 0;
// //   Timer? _tapTimer;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _user = _auth.currentUser;
// //     if (_user != null) {
// //       _loadUserProfile();
// //       _loadUserStats();
// //       _loadUserPosts();
// //     }
// //   }
// //
// //   /// Loads the user's profile information
// //   Future<void> _loadUserProfile() async {
// //     if (_user != null) {
// //       _dbRef.child("users").child(_user!.uid).once().then((snapshot) {
// //         if (snapshot.snapshot.exists) {
// //           var userData = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
// //           setState(() {
// //             _username = userData['username'] ?? 'Username';
// //             _email = userData['email'] ?? 'Email';
// //             _profileImageUrl = userData['profileImageUrl'];
// //             _bio = userData['bio'] ?? '';
// //           });
// //         }
// //       });
// //     }
// //   }
// //
// //   /// Loads the user's statistics (followers, following, photos)
// //   Future<void> _loadUserStats() async {
// //     if (_user != null) {
// //       // Followers count
// //       _dbRef.child("followers").child(_user!.uid).onValue.listen((event) {
// //         final dataSnapshot = event.snapshot;
// //         if (dataSnapshot.exists) {
// //           setState(() {
// //             _followersCount = dataSnapshot.children.length;
// //           });
// //         } else {
// //           setState(() {
// //             _followersCount = 0;
// //           });
// //         }
// //       });
// //
// //       // Following count
// //       _dbRef.child("following").child(_user!.uid).onValue.listen((event) {
// //         final dataSnapshot = event.snapshot;
// //         if (dataSnapshot.exists) {
// //           setState(() {
// //             _followsCount = dataSnapshot.children.length;
// //           });
// //         } else {
// //           setState(() {
// //             _followsCount = 0;
// //           });
// //         }
// //       });
// //
// //       // Photos count
// //       _dbRef.child("posts").orderByChild("userId").equalTo(_user!.uid).onValue.listen((event) {
// //         final dataSnapshot = event.snapshot;
// //         if (dataSnapshot.exists) {
// //           setState(() {
// //             _photosCount = dataSnapshot.children.length;
// //           });
// //         } else {
// //           setState(() {
// //             _photosCount = 0;
// //           });
// //         }
// //       });
// //     }
// //   }
// //
// //   /// Loads the user's posts from the 'posts' node
// //   Future<void> _loadUserPosts() async {
// //     if (_user != null) {
// //       _dbRef
// //           .child("posts")
// //           .orderByChild("userId")
// //           .equalTo(_user!.uid)
// //           .onValue
// //           .listen((event) {
// //         List<Map<String, dynamic>> posts = [];
// //         for (var post in event.snapshot.children) {
// //           var postData = Map<String, dynamic>.from(post.value as Map);
// //           postData['postId'] = post.key; // Store post ID for later use
// //
// //           // Get likes
// //           int likesCount = 0;
// //           bool isLikedByCurrentUser = false;
// //           if (postData['likes'] != null) {
// //             Map<dynamic, dynamic> likesMap = postData['likes'];
// //             likesCount = likesMap.length;
// //             if (likesMap.containsKey(_user!.uid)) {
// //               isLikedByCurrentUser = true;
// //             }
// //           }
// //           postData['likesCount'] = likesCount;
// //           postData['isLikedByCurrentUser'] = isLikedByCurrentUser;
// //
// //           // Get comments count from the global 'comments' node
// //           _dbRef
// //               .child("comments")
// //               .orderByChild("postId")
// //               .equalTo(postData['postId'])
// //               .once()
// //               .then((commentSnapshot) {
// //             int commentsCount = 0;
// //             if (commentSnapshot.snapshot.exists) {
// //               commentsCount = (commentSnapshot.snapshot.value as Map<dynamic, dynamic>).length;
// //             }
// //             setState(() {
// //               postData['commentsCount'] = commentsCount;
// //             });
// //           });
// //
// //           posts.add(postData);
// //         }
// //
// //         // Reverse the list for Instagram-like ordering (newest to oldest)
// //         posts = posts.reversed.toList();
// //
// //         setState(() {
// //           _posts = posts;
// //         });
// //       });
// //     }
// //   }
// //
// //   /// Handles triple-tap to delete a post
// //   Future<void> _onPostTripleTap(String postId) async {
// //     showDialog(
// //       context: context,
// //       builder: (context) {
// //         return AlertDialog(
// //           title: Text('Delete Post'),
// //           content: Text('Are you sure you want to delete this post? This action cannot be undone.'),
// //           actions: [
// //             TextButton(
// //               onPressed: () {
// //                 Navigator.pop(context);
// //               },
// //               child: Text('Cancel'),
// //             ),
// //             TextButton(
// //               onPressed: () {
// //                 _deletePost(postId);
// //                 Navigator.pop(context);
// //               },
// //               child: Text('Delete', style: TextStyle(color: Colors.red)),
// //             ),
// //           ],
// //         );
// //       },
// //     );
// //   }
// //
// //   /// Deletes a post from the 'posts' node
// //   Future<void> _deletePost(String postId) async {
// //     if (_user != null) {
// //       try {
// //         // Remove the post
// //         await _dbRef.child("posts").child(postId).remove();
// //
// //         // Optionally, remove all related comments from the 'comments' node
// //         Query relatedComments = _dbRef.child('comments').orderByChild('postId').equalTo(postId);
// //         DataSnapshot commentsSnapshot = await relatedComments.get();
// //         if (commentsSnapshot.exists) {
// //           for (var comment in commentsSnapshot.children) {
// //             await comment.ref.remove();
// //           }
// //         }
// //
// //         Fluttertoast.showToast(msg: "Post deleted successfully", gravity: ToastGravity.BOTTOM);
// //       } catch (e) {
// //         Fluttertoast.showToast(msg: "Error deleting post: $e", gravity: ToastGravity.BOTTOM);
// //       }
// //     }
// //   }
// //
// //   /// Handles double-tap to edit a post
// //   Future<void> _onPostDoubleTap(String postId, String currentContent) async {
// //     TextEditingController _contentController = TextEditingController(text: currentContent);
// //     File? selectedImage;
// //
// //     showDialog(
// //       context: context,
// //       builder: (context) {
// //         return AlertDialog(
// //           title: Text('Edit Post'),
// //           content: Column(
// //             mainAxisSize: MainAxisSize.min,
// //             children: [
// //               TextField(
// //                 controller: _contentController,
// //                 decoration: InputDecoration(labelText: 'Edit Content'),
// //               ),
// //               SizedBox(height: 10),
// //               ElevatedButton(
// //                 onPressed: () async {
// //                   final ImagePicker _picker = ImagePicker();
// //                   final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
// //                   if (image != null) {
// //                     selectedImage = File(image.path);
// //                     Fluttertoast.showToast(msg: "New image selected", gravity: ToastGravity.BOTTOM);
// //                   }
// //                 },
// //                 child: Text("Change Image"),
// //               ),
// //             ],
// //           ),
// //           actions: [
// //             TextButton(
// //               onPressed: () {
// //                 Navigator.pop(context);
// //               },
// //               child: Text('Cancel'),
// //             ),
// //             TextButton(
// //               onPressed: () {
// //                 _updatePost(postId, _contentController.text.trim(), selectedImage);
// //                 Navigator.pop(context);
// //               },
// //               child: Text('Update'),
// //             ),
// //           ],
// //         );
// //       },
// //     );
// //   }
// //
// //   /// Updates a post's content and image
// //   Future<void> _updatePost(String postId, String newContent, File? newImage) async {
// //     if (_user != null) {
// //       Map<String, dynamic> updatedData = {"content": newContent};
// //
// //       try {
// //         // Update the image if a new image was selected
// //         if (newImage != null) {
// //           String path = 'post_images/${postId}.jpg';
// //           SettableMetadata metadata = SettableMetadata(customMetadata: {
// //             'userId': _user!.uid,
// //           });
// //
// //           TaskSnapshot uploadTask = await _storage.ref(path).putFile(newImage, metadata);
// //           String downloadUrl = await uploadTask.ref.getDownloadURL();
// //           updatedData['imageUrl'] = downloadUrl;
// //         }
// //
// //         await _dbRef.child("posts").child(postId).update(updatedData);
// //         Fluttertoast.showToast(msg: "Post updated successfully", gravity: ToastGravity.BOTTOM);
// //
// //         // Reload the posts to reflect the changes
// //         _loadUserPosts();
// //       } catch (e) {
// //         Fluttertoast.showToast(msg: "Failed to update post: $e", gravity: ToastGravity.BOTTOM);
// //       }
// //     }
// //   }
// //
// //   /// Toggles like/unlike on a post
// //   Future<void> _toggleLike(String postId, bool isCurrentlyLiked) async {
// //     if (_user != null) {
// //       DatabaseReference likesRef = _dbRef.child("posts").child(postId).child("likes").child(_user!.uid);
// //       if (isCurrentlyLiked) {
// //         // Unlike the post
// //         await likesRef.remove();
// //       } else {
// //         // Like the post
// //         await likesRef.set(true);
// //       }
// //     }
// //   }
// //
// //   /// Uploads a profile image to Firebase Storage and updates the user's profile
// //   Future<void> _uploadProfileImage(File image) async {
// //     if (_user != null) {
// //       try {
// //         String path = 'users/${_user!.uid}/profile.jpg';
// //         TaskSnapshot uploadTask = await _storage.ref(path).putFile(image);
// //         String downloadUrl = await uploadTask.ref.getDownloadURL();
// //
// //         await _dbRef.child("users").child(_user!.uid).update({
// //           "profileImageUrl": downloadUrl,
// //         });
// //
// //         setState(() {
// //           _profileImageUrl = downloadUrl;
// //         });
// //
// //         Fluttertoast.showToast(msg: "Profile image updated successfully", gravity: ToastGravity.BOTTOM);
// //       } catch (e) {
// //         Fluttertoast.showToast(msg: "Failed to upload profile image: $e", gravity: ToastGravity.BOTTOM);
// //       }
// //     }
// //   }
// //
// //   /// Picks an image from the gallery
// //   Future<void> _pickImage() async {
// //     final ImagePicker _picker = ImagePicker();
// //     final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
// //
// //     if (image != null) {
// //       setState(() {
// //         _image = File(image.path);
// //       });
// //       _uploadProfileImage(_image!);
// //     }
// //   }
// //
// //   /// Navigates to the post details screen
// //   void _viewPostDetails(Map<String, dynamic> post) {
// //     Navigator.push(
// //       context,
// //       MaterialPageRoute(builder: (context) => PostDetailScreen(post: post, currentUser: _user)),
// //     );
// //   }
// //
// //   /// Navigates to the comments screen for a specific post
// //   void _navigateToComments(Map<dynamic, dynamic> post) {
// //     Navigator.push(
// //       context,
// //       MaterialPageRoute(
// //         builder: (context) => CommentScreen(
// //           postId: post['postId'],
// //           postOwnerId: post['userId'],
// //           canReport: true, // Enable reporting
// //         ),
// //       ),
// //     );
// //   }
// //
// //   /// Builds a statistics item (Photos, Followers, Follows)
// //   Widget _buildStatItem(String label, String count) {
// //     return Column(
// //       mainAxisAlignment: MainAxisAlignment.center,
// //       children: [
// //         Text(label, style: TextStyle(color: Colors.grey)),
// //         SizedBox(height: 4),
// //         Text(count, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
// //       ],
// //     );
// //   }
// //
// //   /// Builds the recent activity section
// //   Widget _buildRecentActivity() {
// //     List<Widget> activityWidgets = [];
// //
// //     for (var post in _posts) {
// //       // Fetch comments from the global 'comments' node where 'postId' matches
// //       _dbRef.child("comments").orderByChild("postId").equalTo(post['postId']).once().then((commentSnapshot) {
// //         if (commentSnapshot.snapshot.exists) {
// //           Map<dynamic, dynamic> commentsMap = Map<dynamic, dynamic>.from(commentSnapshot.snapshot.value as Map);
// //           commentsMap.forEach((commentId, commentData) {
// //             if (commentData['userId'] != _user!.uid) {
// //               activityWidgets.add(ListTile(
// //                 leading: Icon(Icons.comment),
// //                 title: Text('User ${commentData['username']} commented on your post'),
// //                 subtitle: Text(commentData['content']),
// //                 onTap: () => _viewPostDetails(post),
// //               ));
// //             }
// //           });
// //         }
// //       });
// //
// //       // Fetch likes from the 'likes' node
// //       _dbRef.child("posts").child(post['postId']).child("likes").once().then((likeSnapshot) {
// //         if (likeSnapshot.snapshot.exists) {
// //           Map<dynamic, dynamic> likesMap = Map<dynamic, dynamic>.from(likeSnapshot.snapshot.value as Map);
// //           likesMap.forEach((userId, _) {
// //             if (userId != _user!.uid) {
// //               activityWidgets.add(ListTile(
// //                 leading: Icon(Icons.favorite, color: Colors.red),
// //                 title: Text('User $userId liked your post'),
// //                 onTap: () => _viewPostDetails(post),
// //               ));
// //             }
// //           });
// //         }
// //       });
// //     }
// //
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: activityWidgets,
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text('My Profile'),
// //         actions: [
// //           IconButton(
// //             icon: Icon(Icons.settings),
// //             onPressed: () {
// //               Navigator.push(
// //                 context,
// //                 MaterialPageRoute(builder: (context) => SettingsScreen()),
// //               );
// //             },
// //             tooltip: 'Settings',
// //           ),
// //         ],
// //       ),
// //       body: SingleChildScrollView(
// //         child: Column(
// //           children: [
// //             // Profile Picture
// //             GestureDetector(
// //               onTap: _pickImage,
// //               child: Stack(
// //                 alignment: Alignment.bottomRight,
// //                 children: [
// //                   CircleAvatar(
// //                     radius: 50,
// //                     backgroundImage: _profileImageUrl != null
// //                         ? NetworkImage(_profileImageUrl!)
// //                         : AssetImage('assets/profile_placeholder.png') as ImageProvider,
// //                   ),
// //                   CircleAvatar(
// //                     radius: 16,
// //                     backgroundColor: Colors.black54,
// //                     child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //             SizedBox(height: 8),
// //             // Username and Email
// //             Text(
// //               _username,
// //               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
// //             ),
// //             Text(
// //               _email,
// //               style: TextStyle(fontSize: 16, color: Colors.grey),
// //             ),
// //             SizedBox(height: 16),
// //             // Statistics (Photos, Followers, Follows)
// //             Padding(
// //               padding: const EdgeInsets.symmetric(horizontal: 16.0),
// //               child: Row(
// //                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// //                 children: [
// //                   _buildStatItem('Photos', _photosCount.toString()),
// //                   _buildStatItem('Followers', _followersCount.toString()),
// //                   _buildStatItem('Follows', _followsCount.toString()),
// //                 ],
// //               ),
// //             ),
// //             SizedBox(height: 16),
// //             // Bio
// //             Padding(
// //               padding: const EdgeInsets.symmetric(horizontal: 16.0),
// //               child: Align(
// //                 alignment: Alignment.centerLeft,
// //                 child: Text(
// //                   _bio,
// //                   style: TextStyle(fontSize: 14, color: Colors.black87),
// //                 ),
// //               ),
// //             ),
// //             SizedBox(height: 16),
// //             Divider(thickness: 1),
// //             // Recent Activity
// //             Padding(
// //               padding: const EdgeInsets.all(16.0),
// //               child: Align(
// //                 alignment: Alignment.centerLeft,
// //                 child: Text(
// //                   'Recent Activity',
// //                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //                 ),
// //               ),
// //             ),
// //             _buildRecentActivity(),
// //             SizedBox(height: 16),
// //             Divider(thickness: 1),
// //             // User's Posts
// //             Padding(
// //               padding: const EdgeInsets.all(16.0),
// //               child: Align(
// //                 alignment: Alignment.centerLeft,
// //                 child: Text(
// //                   'My Posts',
// //                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //                 ),
// //               ),
// //             ),
// //             // Grid of Posts
// //             Padding(
// //               padding: const EdgeInsets.all(16.0),
// //               child: GridView.builder(
// //                 physics: NeverScrollableScrollPhysics(),
// //                 shrinkWrap: true,
// //                 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
// //                   crossAxisCount: 3,
// //                   crossAxisSpacing: 10,
// //                   mainAxisSpacing: 10,
// //                   childAspectRatio: 1, // Ensures each grid item is square
// //                 ),
// //                 itemCount: _posts.length,
// //                 itemBuilder: (context, index) {
// //                   final post = _posts[index];
// //                   return GestureDetector(
// //                     onTap: () => _viewPostDetails(post),
// //                     onDoubleTap: () => _onPostDoubleTap(post['postId'], post['content']), // Edit post
// //                     onLongPress: () => _onPostTripleTap(post['postId']), // Delete post
// //                     child: Container(
// //                       decoration: BoxDecoration(
// //                         border: Border.all(color: Colors.grey.shade300),
// //                         color: Colors.black12,
// //                       ),
// //                       child: Stack(
// //                         fit: StackFit.expand,
// //                         children: [
// //                           Image.network(
// //                             post['imageUrl'],
// //                             fit: BoxFit.cover,
// //                           ),
// //                           Positioned(
// //                             bottom: 4,
// //                             left: 4,
// //                             child: Container(
// //                               padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
// //                               color: Colors.black54,
// //                               child: Row(
// //                                 children: [
// //                                   Icon(
// //                                     Icons.favorite,
// //                                     color: Colors.redAccent,
// //                                     size: 16,
// //                                   ),
// //                                   SizedBox(width: 2),
// //                                   Text(
// //                                     '${post['likesCount']}',
// //                                     style: TextStyle(color: Colors.white, fontSize: 12),
// //                                   ),
// //                                   SizedBox(width: 8),
// //                                   IconButton(
// //                                     icon: Icon(Icons.comment_bank, color: Colors.white, size: 20),
// //                                     tooltip: 'View Comments',
// //                                     onPressed: () => _navigateToComments(post),
// //                                   ),
// //                                 ],
// //                               ),
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                   );
// //                 },
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
//
//
// // ProfileScreen.dart
//
// import 'dart:io';
// import 'package:betreflutter/CommentScreen.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'PostDetailScreen.dart';
// import 'Settings.dart';
// import 'dart:async';
//
// class ProfileScreen extends StatefulWidget {
//   @override
//   _ProfileScreenState createState() => _ProfileScreenState();
// }
//
// class _ProfileScreenState extends State<ProfileScreen> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
//   final FirebaseStorage _storage = FirebaseStorage.instance;
//
//   User? _user;
//   String? _profileImageUrl;
//   String _username = "Username";
//   String _email = "Email";
//   int _photosCount = 0;
//   int _followersCount = 0;
//   int _followsCount = 0;
//   String _bio = '';
//
//   List<Map<String, dynamic>> _posts = []; // To store post details
//   File? _image;
//   Timer? _tapTimer;
//
//   @override
//   void initState() {
//     super.initState();
//     _user = _auth.currentUser;
//     if (_user != null) {
//       _loadUserProfile();
//       _loadUserStats();
//       _loadUserPosts();
//     }
//   }
//
//   /// Loads the user's profile information
//   Future<void> _loadUserProfile() async {
//     if (_user != null) {
//       _dbRef.child("users").child(_user!.uid).once().then((snapshot) {
//         if (snapshot.snapshot.exists) {
//           var userData = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
//           setState(() {
//             _username = userData['username'] ?? 'Username';
//             _email = userData['email'] ?? 'Email';
//             _profileImageUrl = userData['profileImageUrl'];
//             _bio = userData['bio'] ?? '';
//           });
//         }
//       });
//     }
//   }
//
//   /// Loads the user's statistics (followers, following, photos)
//   Future<void> _loadUserStats() async {
//     if (_user != null) {
//       // Followers count
//       _dbRef.child("followers").child(_user!.uid).onValue.listen((event) {
//         final dataSnapshot = event.snapshot;
//         if (dataSnapshot.exists) {
//           setState(() {
//             _followersCount = dataSnapshot.children.length;
//           });
//         } else {
//           setState(() {
//             _followersCount = 0;
//           });
//         }
//       });
//
//       // Following count
//       _dbRef.child("following").child(_user!.uid).onValue.listen((event) {
//         final dataSnapshot = event.snapshot;
//         if (dataSnapshot.exists) {
//           setState(() {
//             _followsCount = dataSnapshot.children.length;
//           });
//         } else {
//           setState(() {
//             _followsCount = 0;
//           });
//         }
//       });
//
//       // Photos count
//       _dbRef.child("posts").orderByChild("userId").equalTo(_user!.uid).onValue.listen((event) {
//         final dataSnapshot = event.snapshot;
//         if (dataSnapshot.exists) {
//           setState(() {
//             _photosCount = dataSnapshot.children.length;
//           });
//         } else {
//           setState(() {
//             _photosCount = 0;
//           });
//         }
//       });
//     }
//   }
//
//   /// Loads the user's posts from the 'posts' node
//   Future<void> _loadUserPosts() async {
//     if (_user != null) {
//       _dbRef
//           .child("posts")
//           .orderByChild("userId")
//           .equalTo(_user!.uid)
//           .onValue
//           .listen((event) async {
//         List<Map<String, dynamic>> posts = [];
//         for (var post in event.snapshot.children) {
//           var postData = Map<String, dynamic>.from(post.value as Map);
//           postData['postId'] = post.key; // Store post ID for later use
//
//           // Get likes
//           int likesCount = 0;
//           bool isLikedByCurrentUser = false;
//           if (postData['likes'] != null) {
//             Map<dynamic, dynamic> likesMap = Map<dynamic, dynamic>.from(postData['likes']);
//             likesCount = likesMap.length;
//             if (likesMap.containsKey(_user!.uid)) {
//               isLikedByCurrentUser = true;
//             }
//           }
//           postData['likesCount'] = likesCount;
//           postData['isLikedByCurrentUser'] = isLikedByCurrentUser;
//
//           // Get comments count from the global 'comments' node
//           DataSnapshot commentSnapshot = await _dbRef
//               .child("comments")
//               .orderByChild("postId")
//               .equalTo(postData['postId'])
//               .get();
//           int commentsCount = 0;
//           if (commentSnapshot.exists) {
//             commentsCount = (commentSnapshot.value as Map<dynamic, dynamic>).length;
//           }
//           postData['commentsCount'] = commentsCount;
//
//           posts.add(postData);
//         }
//
//         // Reverse the list for Instagram-like ordering (newest to oldest)
//         posts = posts.reversed.toList();
//
//         setState(() {
//           _posts = posts;
//         });
//       });
//     }
//   }
//
//   /// Handles triple-tap to delete a post
//   Future<void> _onPostTripleTap(String postId) async {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text('Delete Post'),
//           content: Text('Are you sure you want to delete this post? This action cannot be undone.'),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               child: Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 _deletePost(postId);
//                 Navigator.pop(context);
//               },
//               child: Text('Delete', style: TextStyle(color: Colors.red)),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   /// Deletes a post from the 'posts' node
//   Future<void> _deletePost(String postId) async {
//     if (_user != null) {
//       try {
//         // Remove the post
//         await _dbRef.child("posts").child(postId).remove();
//
//         // Optionally, remove all related comments from the 'comments' node
//         Query relatedComments = _dbRef.child('comments').orderByChild('postId').equalTo(postId);
//         DataSnapshot commentsSnapshot = await relatedComments.get();
//         if (commentsSnapshot.exists) {
//           for (var comment in commentsSnapshot.children) {
//             await comment.ref.remove();
//           }
//         }
//
//         Fluttertoast.showToast(msg: "Post deleted successfully", gravity: ToastGravity.BOTTOM);
//       } catch (e) {
//         Fluttertoast.showToast(msg: "Error deleting post: $e", gravity: ToastGravity.BOTTOM);
//       }
//     }
//   }
//
//   /// Handles double-tap to edit a post
//   Future<void> _onPostDoubleTap(String postId, String currentContent) async {
//     TextEditingController _contentController = TextEditingController(text: currentContent);
//     File? selectedImage;
//
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text('Edit Post'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: _contentController,
//                 decoration: InputDecoration(labelText: 'Edit Content'),
//               ),
//               SizedBox(height: 10),
//               ElevatedButton(
//                 onPressed: () async {
//                   final ImagePicker _picker = ImagePicker();
//                   final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
//                   if (image != null) {
//                     selectedImage = File(image.path);
//                     Fluttertoast.showToast(msg: "New image selected", gravity: ToastGravity.BOTTOM);
//                   }
//                 },
//                 child: Text("Change Image"),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               child: Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 _updatePost(postId, _contentController.text.trim(), selectedImage);
//                 Navigator.pop(context);
//               },
//               child: Text('Update'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   /// Updates a post's content and image
//   Future<void> _updatePost(String postId, String newContent, File? newImage) async {
//     if (_user != null) {
//       Map<String, dynamic> updatedData = {"content": newContent};
//
//       try {
//         // Update the image if a new image was selected
//         if (newImage != null) {
//           String path = 'post_images/${postId}.jpg';
//           SettableMetadata metadata = SettableMetadata(customMetadata: {
//             'userId': _user!.uid,
//           });
//
//           TaskSnapshot uploadTask = await _storage.ref(path).putFile(newImage, metadata);
//           String downloadUrl = await uploadTask.ref.getDownloadURL();
//           updatedData['imageUrl'] = downloadUrl;
//         }
//
//         await _dbRef.child("posts").child(postId).update(updatedData);
//         Fluttertoast.showToast(msg: "Post updated successfully", gravity: ToastGravity.BOTTOM);
//
//         // Reload the posts to reflect the changes
//         _loadUserPosts();
//       } catch (e) {
//         Fluttertoast.showToast(msg: "Failed to update post: $e", gravity: ToastGravity.BOTTOM);
//       }
//     }
//   }
//
//   /// Toggles like/unlike on a post
//   Future<void> _toggleLike(String postId, bool isCurrentlyLiked) async {
//     if (_user != null) {
//       DatabaseReference likesRef = _dbRef.child("posts").child(postId).child("likes").child(_user!.uid);
//       if (isCurrentlyLiked) {
//         // Unlike the post
//         await likesRef.remove();
//       } else {
//         // Like the post
//         await likesRef.set(true);
//       }
//     }
//   }
//
//   /// Uploads a profile image to Firebase Storage and updates the user's profile
//   Future<void> _uploadProfileImage(File image) async {
//     if (_user != null) {
//       try {
//         String path = 'users/${_user!.uid}/profile.jpg';
//         TaskSnapshot uploadTask = await _storage.ref(path).putFile(image);
//         String downloadUrl = await uploadTask.ref.getDownloadURL();
//
//         await _dbRef.child("users").child(_user!.uid).update({
//           "profileImageUrl": downloadUrl,
//         });
//
//         setState(() {
//           _profileImageUrl = downloadUrl;
//         });
//
//         Fluttertoast.showToast(msg: "Profile image updated successfully", gravity: ToastGravity.BOTTOM);
//       } catch (e) {
//         Fluttertoast.showToast(msg: "Failed to upload profile image: $e", gravity: ToastGravity.BOTTOM);
//       }
//     }
//   }
//
//   /// Picks an image from the gallery
//   Future<void> _pickImage() async {
//     final ImagePicker _picker = ImagePicker();
//     final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
//
//     if (image != null) {
//       setState(() {
//         _image = File(image.path);
//       });
//       _uploadProfileImage(_image!);
//     }
//   }
//
//   /// Navigates to the post details screen
//   void _viewPostDetails(Map<String, dynamic> post) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => PostDetailScreen(post: post, currentUser: _user)),
//     );
//   }
//
//   /// Navigates to the comments screen for a specific post
//   void _navigateToComments(Map<dynamic, dynamic> post) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => CommentScreen(
//           postId: post['postId'],
//           postOwnerId: post['userId'],
//           canReport: true, // Enable reporting
//         ),
//       ),
//     );
//   }
//
//   /// Builds a statistics item (Photos, Followers, Follows)
//   Widget _buildStatItem(String label, String count) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Text(label, style: TextStyle(color: Colors.grey)),
//         SizedBox(height: 4),
//         Text(count, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//       ],
//     );
//   }
//
//   /// Builds the recent activity section with reporting functionality
//   Widget _buildRecentActivity() {
//     List<Widget> activityWidgets = [];
//
//     for (var post in _posts) {
//       // Fetch comments from the global 'comments' node where 'postId' matches
//       _dbRef.child("comments").orderByChild("postId").equalTo(post['postId']).onValue.listen((commentEvent) {
//         if (commentEvent.snapshot.exists) {
//           Map<dynamic, dynamic> commentsMap = Map<dynamic, dynamic>.from(commentEvent.snapshot.value as Map);
//           commentsMap.forEach((commentId, commentData) {
//             if (commentData['userId'] != _user!.uid) {
//               activityWidgets.add(ListTile(
//                 leading: CircleAvatar(
//                   backgroundImage: commentData['userProfileImageUrl'] != null && commentData['userProfileImageUrl'] != ''
//                       ? NetworkImage(commentData['userProfileImageUrl'])
//                       : AssetImage('assets/profile_placeholder.png') as ImageProvider,
//                 ),
//                 title: Text('User ${commentData['username']} commented on your post'),
//                 subtitle: Text(commentData['content']),
//                 trailing: IconButton(
//                   icon: Icon(Icons.flag, color: Colors.redAccent),
//                   tooltip: 'Report Comment',
//                   onPressed: () => _reportComment(commentId, commentData),
//                 ),
//                 onTap: () => _viewPostDetails(post),
//               ));
//             }
//           });
//         }
//       });
//
//       // Fetch likes from the 'likes' node
//       _dbRef.child("posts").child(post['postId']).child("likes").onValue.listen((likeEvent) {
//         if (likeEvent.snapshot.exists) {
//           Map<dynamic, dynamic> likesMap = Map<dynamic, dynamic>.from(likeEvent.snapshot.value as Map);
//           likesMap.forEach((userId, _) {
//             if (userId != _user!.uid) {
//               activityWidgets.add(ListTile(
//                 leading: Icon(Icons.favorite, color: Colors.red),
//                 title: Text('User $userId liked your post'),
//                 onTap: () => _viewPostDetails(post),
//               ));
//             }
//           });
//         }
//       });
//     }
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: activityWidgets.isNotEmpty
//           ? activityWidgets
//           : [
//         Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Text(
//             'No recent activity.',
//             style: TextStyle(color: Colors.grey),
//           ),
//         ),
//       ],
//     );
//   }
//
//   // /// Reports a comment by adding it to the 'reportcomment' node
//   // void _reportComment(String commentId, Map<dynamic, dynamic> commentData) {
//   //
//   //   showDialog(
//   //     context: context,
//   //     builder: (context) {
//   //       TextEditingController _reasonController = TextEditingController();
//   //
//   //       return AlertDialog(
//   //         title: Text('Report Comment'),
//   //         content: Column(
//   //           mainAxisSize: MainAxisSize.min,
//   //           children: [
//   //             Text('Please specify the reason for reporting this comment:'),
//   //             TextField(
//   //               controller: _reasonController,
//   //               decoration: InputDecoration(
//   //                 hintText: 'Enter reason',
//   //               ),
//   //             ),
//   //           ],
//   //         ),
//   //         actions: [
//   //           TextButton(
//   //             onPressed: () {
//   //               Navigator.pop(context); // Close the dialog
//   //             },
//   //             child: Text('Cancel'),
//   //           ),
//   //           TextButton(
//   //             onPressed: () async {
//   //               String reason = _reasonController.text.trim();
//   //               if (reason.isEmpty) {
//   //                 Fluttertoast.showToast(msg: 'Please enter a reason.');
//   //                 return;
//   //               }
//   //
//   //               try {
//   //                 // Proceed to report the comment
//   //                 String commentOwnerId = commentData['userId'];
//   //                 String reporterId = _user!.uid;
//   //
//   //                 // Check if the user has already reported this comment
//   //                 DataSnapshot existingReport = await _dbRef
//   //                     .child('reportcomment')
//   //                     .orderByChild('reporterId')
//   //                     .equalTo(reporterId)
//   //                     .get();
//   //
//   //                 bool alreadyReported = false;
//   //                 if (existingReport.exists) {
//   //                   Map<dynamic, dynamic> reports = Map<dynamic, dynamic>.from(existingReport.value as Map<dynamic, dynamic>);
//   //                   reports.forEach((key, report) {
//   //                     if (report['commentId'] == commentId) {
//   //                       alreadyReported = true;
//   //                     }
//   //                   });
//   //                 }
//   //
//   //                 if (alreadyReported) {
//   //                   Fluttertoast.showToast(
//   //                     msg: 'You have already reported this comment.',
//   //                     toastLength: Toast.LENGTH_SHORT,
//   //                     gravity: ToastGravity.BOTTOM,
//   //                   );
//   //                   Navigator.pop(context);
//   //                   return;
//   //                 }
//   //
//   //                 // Fetch reporter details
//   //                 DataSnapshot reporterSnapshot = await _dbRef.child('users').child(reporterId).get();
//   //                 if (!reporterSnapshot.exists) {
//   //                   Fluttertoast.showToast(msg: 'Reporter user does not exist.');
//   //                   Navigator.pop(context);
//   //                   return;
//   //                 }
//   //                 Map<String, dynamic> reporterData = Map<String, dynamic>.from(reporterSnapshot.value as Map);
//   //                 String reporterUsername = reporterData['username'] ?? 'Unknown User';
//   //                 String reporterEmail = reporterData['email'] ?? 'No Email';
//   //
//   //                 // Fetch comment owner details
//   //                 DataSnapshot commentOwnerSnapshot = await _dbRef.child('users').child(commentOwnerId).get();
//   //                 if (!commentOwnerSnapshot.exists) {
//   //                   Fluttertoast.showToast(msg: 'Comment owner does not exist.');
//   //                   Navigator.pop(context);
//   //                   return;
//   //                 }
//   //                 Map<String, dynamic> commentOwnerData = Map<String, dynamic>.from(commentOwnerSnapshot.value as Map);
//   //                 String commentOwnerUsername = commentOwnerData['username'] ?? 'Unknown User';
//   //                 String commentOwnerEmail = commentOwnerData['email'] ?? 'No Email';
//   //
//   //                 // Create the report entry
//   //                 DatabaseReference reportRef = _dbRef.child('reportcomment').push();
//   //                 await reportRef.set({
//   //                   'reportId': reportRef.key,
//   //                   'postId': widget.postId,
//   //                   'commentId': commentId,
//   //                   'commentContent': commentData['content'] ?? '',
//   //                   'commentUserId': commentOwnerId,
//   //                   'commentOwnerUsername': commentOwnerUsername,
//   //                   'commentOwnerEmail': commentOwnerEmail,
//   //                   'reporterId': reporterId,
//   //                   'reporterUsername': reporterUsername,
//   //                   'reporterEmail': reporterEmail,
//   //                   'reason': reason,
//   //                   'timestamp': DateTime.now().millisecondsSinceEpoch,
//   //                 });
//   //
//   //                 Navigator.pop(context); // Close the dialog
//   //                 Fluttertoast.showToast(msg: 'Comment reported.');
//   //               } catch (e) {
//   //                 Navigator.pop(context); // Close the dialog
//   //                 Fluttertoast.showToast(msg: 'Error reporting comment: $e');
//   //               }
//   //             },
//   //             child: Text('Submit'),
//   //           ),
//   //         ],
//   //       );
//   //     },
//   //   );
//   // }
//
//   /// Reports a comment by adding it to the 'reportcomment' node
//   void _reportComment(String commentId, Map<dynamic, dynamic> commentData) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         TextEditingController _reasonController = TextEditingController();
//
//         return AlertDialog(
//           title: Text('Report Comment'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text('Please specify the reason for reporting this comment:'),
//               TextField(
//                 controller: _reasonController,
//                 decoration: InputDecoration(
//                   hintText: 'Enter reason',
//                 ),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context); // Close the dialog
//               },
//               child: Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () async {
//                 String reason = _reasonController.text.trim();
//                 if (reason.isEmpty) {
//                   Fluttertoast.showToast(msg: 'Please enter a reason.');
//                   return;
//                 }
//
//                 try {
//                   // Proceed to report the comment
//                   String commentOwnerId = commentData['userId'];
//                   String reporterId = _user!.uid;
//
//                   // Check if the user has already reported this comment
//                   DataSnapshot existingReport = await _dbRef
//                       .child('reportcomment')
//                       .orderByChild('reporterId')
//                       .equalTo(reporterId)
//                       .get();
//
//                   bool alreadyReported = false;
//                   if (existingReport.exists) {
//                     Map<dynamic, dynamic> reports = Map<dynamic, dynamic>.from(existingReport.value as Map<dynamic, dynamic>);
//                     reports.forEach((key, report) {
//                       if (report['commentId'] == commentId) {
//                         alreadyReported = true;
//                       }
//                     });
//                   }
//
//                   if (alreadyReported) {
//                     Fluttertoast.showToast(
//                       msg: 'You have already reported this comment.',
//                       toastLength: Toast.LENGTH_SHORT,
//                       gravity: ToastGravity.BOTTOM,
//                     );
//                     Navigator.pop(context);
//                     return;
//                   }
//
//                   // Fetch reporter details
//                   DataSnapshot reporterSnapshot = await _dbRef.child('users').child(reporterId).get();
//                   if (!reporterSnapshot.exists) {
//                     Fluttertoast.showToast(msg: 'Reporter user does not exist.');
//                     Navigator.pop(context);
//                     return;
//                   }
//                   Map<String, dynamic> reporterData = Map<String, dynamic>.from(reporterSnapshot.value as Map);
//                   String reporterUsername = reporterData['username'] ?? 'Unknown User';
//                   String reporterEmail = reporterData['email'] ?? 'No Email';
//
//                   // Fetch comment owner details
//                   DataSnapshot commentOwnerSnapshot = await _dbRef.child('users').child(commentOwnerId).get();
//                   if (!commentOwnerSnapshot.exists) {
//                     Fluttertoast.showToast(msg: 'Comment owner does not exist.');
//                     Navigator.pop(context);
//                     return;
//                   }
//                   Map<String, dynamic> commentOwnerData = Map<String, dynamic>.from(commentOwnerSnapshot.value as Map);
//                   String commentOwnerUsername = commentOwnerData['username'] ?? 'Unknown User';
//                   String commentOwnerEmail = commentOwnerData['email'] ?? 'No Email';
//
//                   // Create the report entry
//                   DatabaseReference reportRef = _dbRef.child('reportcomment').push();
//                   await reportRef.set({
//                     'reportId': reportRef.key,
//                     'postId': commentData['postId'], // Corrected line
//                     'commentId': commentId,
//                     'commentContent': commentData['content'] ?? '',
//                     'commentUserId': commentOwnerId,
//                     'commentOwnerUsername': commentOwnerUsername,
//                     'commentOwnerEmail': commentOwnerEmail,
//                     'reporterId': reporterId,
//                     'reporterUsername': reporterUsername,
//                     'reporterEmail': reporterEmail,
//                     'reason': reason,
//                     'timestamp': DateTime.now().millisecondsSinceEpoch,
//                   });
//
//                   Navigator.pop(context); // Close the dialog
//                   Fluttertoast.showToast(msg: 'Comment reported.');
//                 } catch (e) {
//                   Navigator.pop(context); // Close the dialog
//                   Fluttertoast.showToast(msg: 'Error reporting comment: $e');
//                 }
//               },
//               child: Text('Submit'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//
//   /// Builds the UI for each comment in recent activity with reporting option
//   Widget _buildReportTile(Map<String, dynamic> report) {
//     String reportId = report['reportId'] ?? '';
//     String postId = report['postId'] ?? '';
//     String commentId = report['commentId'] ?? '';
//     String commentContent = report['commentContent'] ?? 'No content';
//     String commentUserId = report['commentUserId'] ?? 'Unknown User';
//     String commentOwnerUsername = report['commentOwnerUsername'] ?? 'Unknown User';
//     String commentOwnerEmail = report['commentOwnerEmail'] ?? 'No Email';
//     String reporterId = report['reporterId'] ?? 'Unknown';
//     String reporterUsername = report['reporterUsername'] ?? 'Unknown User';
//     String reporterEmail = report['reporterEmail'] ?? 'No Email';
//     String reason = report['reason'] ?? 'No reason provided';
//     int timestamp = report['timestamp'] ?? 0;
//
//     DateTime reportDateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
//
//     return Card(
//       margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10.0),
//       ),
//       elevation: 3,
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Reporter Information
//             Row(
//               children: [
//                 Icon(Icons.report, color: Colors.redAccent),
//                 SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     'Reported by: $reporterUsername (${reporterEmail})',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 8.0),
//
//             // Report Details
//             Text(
//               'Reason: $reason',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.black87,
//               ),
//             ),
//             SizedBox(height: 4.0),
//             Text(
//               'Reported At: ${reportDateTime.toLocal()}',
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.grey[600],
//               ),
//             ),
//             Divider(height: 20, thickness: 1),
//
//             // Comment Information
//             Text(
//               'Comment Content:',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             SizedBox(height: 4.0),
//             Text(
//               commentContent,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.black87,
//               ),
//             ),
//             SizedBox(height: 8.0),
//             Text(
//               'Comment Owner: $commentOwnerUsername (${commentOwnerEmail})',
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.grey[700],
//               ),
//             ),
//
//             SizedBox(height: 12.0),
//
//             // Action Buttons
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 // Delete Comment Button
//                 IconButton(
//                   icon: Icon(Icons.delete, color: Colors.red),
//                   tooltip: 'Delete Comment',
//                   onPressed: () => confirmDeleteComment(postId, commentId),
//                 ),
//                 // Remove Report Button
//                 IconButton(
//                   icon: Icon(Icons.remove_circle, color: Colors.orange),
//                   tooltip: 'Remove Report',
//                   onPressed: () => confirmRemoveReport(reportId),
//                 ),
//                 // Issue Warning Button
//                 IconButton(
//                   icon: Icon(Icons.warning, color: Colors.blue),
//                   tooltip: 'Issue Warning',
//                   onPressed: () => confirmIssueWarning(commentUserId),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// Confirms deletion of a comment
//   void confirmDeleteComment(String postId, String commentId) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Delete Comment'),
//           content: Text('Are you sure you want to delete this comment? This action cannot be undone.'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(), // Cancel
//               child: Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close the dialog
//                 _deleteCommentById(postId, commentId); // Proceed with deletion
//               },
//               child: Text('Delete', style: TextStyle(color: Colors.red)),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   /// Deletes a comment by its ID
//   void _deleteCommentById(String postId, String commentId) async {
//     try {
//       await _dbRef.child('comments').child(commentId).remove();
//       Fluttertoast.showToast(msg: 'Comment deleted successfully.', gravity: ToastGravity.BOTTOM);
//     } catch (e) {
//       Fluttertoast.showToast(msg: 'Error deleting comment: $e', gravity: ToastGravity.BOTTOM);
//     }
//   }
//
//   /// Confirms removal of a report
//   void confirmRemoveReport(String reportId) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Remove Report'),
//           content: Text('Are you sure you want to remove this report?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(), // Cancel
//               child: Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close the dialog
//                 _removeReport(reportId); // Proceed with removing the report
//               },
//               child: Text('Remove', style: TextStyle(color: Colors.orange)),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   /// Removes a report from the 'reportcomment' node
//   void _removeReport(String reportId) async {
//     try {
//       await _dbRef.child('reportcomment').child(reportId).remove();
//       Fluttertoast.showToast(
//         msg: "Report removed successfully.",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//       );
//     } catch (e) {
//       Fluttertoast.showToast(
//         msg: "Error removing report: $e",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//       );
//     }
//   }
//
//   /// Confirms issuing a warning to a user
//   void confirmIssueWarning(String userId) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Issue Warning'),
//           content: Text('Are you sure you want to issue a warning to this user?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(), // Cancel
//               child: Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close the dialog
//                 _issueWarning(userId); // Proceed with issuing the warning
//               },
//               child: Text('Issue Warning', style: TextStyle(color: Colors.orange)),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   /// Issues a warning to a user by adding an entry to their 'warnings' node
//   void _issueWarning(String userId) async {
//     try {
//       await _dbRef.child('users').child(userId).child('warnings').push().set({
//         'timestamp': DateTime.now().millisecondsSinceEpoch,
//         'reason': 'Violation of community guidelines',
//       });
//       Fluttertoast.showToast(
//         msg: "Warning issued to User ID: $userId",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//         timeInSecForIosWeb: 1,
//       );
//     } catch (e) {
//       Fluttertoast.showToast(
//         msg: "Error issuing warning: $e",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//       );
//     }
//   }
//
//   /// Builds the UI for each comment in recent activity with reporting option
//   Widget _buildRecentActivityList() {
//     List<Widget> activityWidgets = [];
//
//     for (var post in _posts) {
//       // Fetch comments from the global 'comments' node where 'postId' matches
//       _dbRef.child("comments").orderByChild("postId").equalTo(post['postId']).onValue.listen((commentEvent) {
//         if (commentEvent.snapshot.exists) {
//           Map<dynamic, dynamic> commentsMap = Map<dynamic, dynamic>.from(commentEvent.snapshot.value as Map);
//           commentsMap.forEach((commentId, commentData) {
//             if (commentData['userId'] != _user!.uid) {
//               activityWidgets.add(ListTile(
//                 leading: CircleAvatar(
//                   backgroundImage: commentData['userProfileImageUrl'] != null && commentData['userProfileImageUrl'] != ''
//                       ? NetworkImage(commentData['userProfileImageUrl'])
//                       : AssetImage('assets/profile_placeholder.png') as ImageProvider,
//                 ),
//                 title: Text('User ${commentData['username']} commented on your post'),
//                 subtitle: Text(commentData['content']),
//                 trailing: IconButton(
//                   icon: Icon(Icons.flag, color: Colors.redAccent),
//                   tooltip: 'Report Comment',
//                   onPressed: () => _reportComment(commentId, commentData),
//                 ),
//                 onTap: () => _viewPostDetails(post),
//               ));
//             }
//           });
//         }
//       });
//
//       // Fetch likes from the 'likes' node
//       _dbRef.child("posts").child(post['postId']).child("likes").onValue.listen((likeEvent) {
//         if (likeEvent.snapshot.exists) {
//           Map<dynamic, dynamic> likesMap = Map<dynamic, dynamic>.from(likeEvent.snapshot.value as Map);
//           likesMap.forEach((userId, _) {
//             if (userId != _user!.uid) {
//               activityWidgets.add(ListTile(
//                 leading: Icon(Icons.favorite, color: Colors.red),
//                 title: Text('User $userId liked your post'),
//                 onTap: () => _viewPostDetails(post),
//               ));
//             }
//           });
//         }
//       });
//     }
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: activityWidgets.isNotEmpty
//           ? activityWidgets
//           : [
//         Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Text(
//             'No recent activity.',
//             style: TextStyle(color: Colors.grey),
//           ),
//         ),
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('My Profile'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.settings),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => SettingsScreen()),
//               );
//             },
//             tooltip: 'Settings',
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             // Profile Picture
//             GestureDetector(
//               onTap: _pickImage,
//               child: Stack(
//                 alignment: Alignment.bottomRight,
//                 children: [
//                   CircleAvatar(
//                     radius: 50,
//                     backgroundImage: _profileImageUrl != null
//                         ? NetworkImage(_profileImageUrl!)
//                         : AssetImage('assets/profile_placeholder.png') as ImageProvider,
//                   ),
//                   CircleAvatar(
//                     radius: 16,
//                     backgroundColor: Colors.black54,
//                     child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 8),
//             // Username and Email
//             Text(
//               _username,
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             Text(
//               _email,
//               style: TextStyle(fontSize: 16, color: Colors.grey),
//             ),
//             SizedBox(height: 16),
//             // Statistics (Photos, Followers, Follows)
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   _buildStatItem('Photos', _photosCount.toString()),
//                   _buildStatItem('Followers', _followersCount.toString()),
//                   _buildStatItem('Follows', _followsCount.toString()),
//                 ],
//               ),
//             ),
//             SizedBox(height: 16),
//             // Bio
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   _bio,
//                   style: TextStyle(fontSize: 14, color: Colors.black87),
//                 ),
//               ),
//             ),
//             SizedBox(height: 16),
//             Divider(thickness: 1),
//             // Recent Activity
//
//
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   'My Posts',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ),
//             // Grid of Posts
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: GridView.builder(
//                 physics: NeverScrollableScrollPhysics(),
//                 shrinkWrap: true,
//                 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 3,
//                   crossAxisSpacing: 10,
//                   mainAxisSpacing: 10,
//                   childAspectRatio: 1, // Ensures each grid item is square
//                 ),
//                 itemCount: _posts.length,
//                 itemBuilder: (context, index) {
//                   final post = _posts[index];
//                   return GestureDetector(
//                     onTap: () => _viewPostDetails(post),
//                     onDoubleTap: () => _onPostDoubleTap(post['postId'], post['content']), // Edit post
//                     onLongPress: () => _onPostTripleTap(post['postId']), // Delete post
//                     child: Container(
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.grey.shade300),
//                         color: Colors.black12,
//                       ),
//                       child: Stack(
//                         fit: StackFit.expand,
//                         children: [
//                           Image.network(
//                             post['imageUrl'],
//                             fit: BoxFit.cover,
//                           ),
//                           Positioned(
//                             bottom: 4,
//                             left: 4,
//                             child: Container(
//                               padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
//                               color: Colors.black54,
//                               child: Row(
//                                 children: [
//                                   Icon(
//                                     Icons.favorite,
//                                     color: Colors.redAccent,
//                                     size: 16,
//                                   ),
//                                   SizedBox(width: 2),
//                                   Text(
//                                     '${post['likesCount']}',
//                                     style: TextStyle(color: Colors.white, fontSize: 12),
//                                   ),
//                                   SizedBox(width: 8),
//                                   IconButton(
//                                     icon: Icon(Icons.comment_bank, color: Colors.white, size: 20),
//                                     tooltip: 'View Comments',
//                                     onPressed: () => _navigateToComments(post),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// import 'dart:io';
// import 'package:betreflutter/CommentScreen.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'PostDetailScreen.dart';
// import 'Settings.dart';
// import 'dart:async';
//
// class ProfileScreen extends StatefulWidget {
//   @override
//   _ProfileScreenState createState() => _ProfileScreenState();
// }
//
// class _ProfileScreenState extends State<ProfileScreen> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
//   final FirebaseStorage _storage = FirebaseStorage.instance;
//
//   User? _user;
//   String? _profileImageUrl;
//   String _username = "Username";
//   String _email = "Email";
//   int _photosCount = 0;
//   int _followersCount = 0;
//   int _followsCount = 0;
//   String _bio = '';
//
//   List<Map<String, dynamic>> _posts = []; // To store post details
//   File? _image;
//   Timer? _tapTimer;
//
//   @override
//   void initState() {
//     super.initState();
//     _user = _auth.currentUser;
//     if (_user != null) {
//       _loadUserProfile();
//       _loadUserStats();
//       _loadUserPosts();
//     }
//   }
//
//   /// Loads the user's profile information
//   Future<void> _loadUserProfile() async {
//     if (_user != null) {
//       _dbRef.child("users").child(_user!.uid).once().then((snapshot) {
//         if (snapshot.snapshot.exists) {
//           var userData = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
//           setState(() {
//             _username = userData['username'] ?? 'Username';
//             _email = userData['email'] ?? 'Email';
//             _profileImageUrl = userData['profileImageUrl'];
//             _bio = userData['bio'] ?? '';
//           });
//           print('Loaded user profile: $_username, $_email');
//         } else {
//           print('User profile does not exist.');
//         }
//       }).catchError((error) {
//         print('Error loading user profile: $error');
//       });
//     }
//   }
//
//   /// Loads the user's statistics (followers, following, photos)
//   Future<void> _loadUserStats() async {
//     if (_user != null) {
//       // Followers count
//       _dbRef.child("followers").child(_user!.uid).onValue.listen((event) {
//         final dataSnapshot = event.snapshot;
//         if (dataSnapshot.exists) {
//           setState(() {
//             _followersCount = dataSnapshot.children.length;
//           });
//           print('Followers Count: $_followersCount');
//         } else {
//           setState(() {
//             _followersCount = 0;
//           });
//           print('Followers Count: $_followersCount');
//         }
//       });
//
//       // Following count
//       _dbRef.child("following").child(_user!.uid).onValue.listen((event) {
//         final dataSnapshot = event.snapshot;
//         if (dataSnapshot.exists) {
//           setState(() {
//             _followsCount = dataSnapshot.children.length;
//           });
//           print('Following Count: $_followsCount');
//         } else {
//           setState(() {
//             _followsCount = 0;
//           });
//           print('Following Count: $_followsCount');
//         }
//       });
//
//       // Photos count
//       _dbRef.child("posts").orderByChild("userId").equalTo(_user!.uid).onValue.listen((event) async {
//         final dataSnapshot = event.snapshot;
//         if (dataSnapshot.exists) {
//           setState(() {
//             _photosCount = dataSnapshot.children.length;
//           });
//           print('Photos Count: $_photosCount');
//         } else {
//           setState(() {
//             _photosCount = 0;
//           });
//           print('Photos Count: $_photosCount');
//         }
//       });
//     }
//   }
//
//
//
//   Future<void> _loadUserPosts() async {
//     if (_user != null) {
//       print('Loading posts for user: ${_user!.uid}');
//       _dbRef
//           .child("posts")
//           .orderByChild("userId")
//           .equalTo(_user!.uid)
//           .onValue
//           .listen((event) async {
//         print('Posts listener triggered');
//         if (event.snapshot.exists) {
//           print('Posts found for user ${_user!.uid}');
//           List<Map<String, dynamic>> posts = [];
//           for (var post in event.snapshot.children) {
//             var postData = Map<String, dynamic>.from(post.value as Map);
//             postData['postId'] = post.key;
//
//             // Initialize likes and comments
//             int likesCount = 0;
//             bool isLikedByCurrentUser = false;
//             if (postData['likes'] != null) {
//               Map<dynamic, dynamic> likesMap = Map<dynamic, dynamic>.from(postData['likes']);
//               likesCount = likesMap.length;
//               if (likesMap.containsKey(_user!.uid)) {
//                 isLikedByCurrentUser = true;
//               }
//             }
//             postData['likesCount'] = likesCount;
//             postData['isLikedByCurrentUser'] = isLikedByCurrentUser;
//
//             // Get comments count from the 'comments' node under this post
//             DataSnapshot commentSnapshot = await _dbRef
//                 .child("posts")
//                 .child(postData['postId'])
//                 .child('comments')
//                 .get();
//             int commentsCount = 0;
//             if (commentSnapshot.exists) {
//               commentsCount = commentSnapshot.children.length;
//             }
//             postData['commentsCount'] = commentsCount;
//
//             posts.add(postData);
//           }
//           setState(() {
//             _posts = posts.reversed.toList();
//           });
//         } else {
//           print('No posts found for user ${_user!.uid}');
//           setState(() {
//             _posts = [];
//           });
//         }
//       }, onError: (error) {
//         print('Error loading posts: $error');
//       });
//     }
//   }
//
//
//   /// Handles triple-tap to delete a post
//   Future<void> _onPostTripleTap(String postId) async {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text('Delete Post'),
//           content: Text('Are you sure you want to delete this post? This action cannot be undone.'),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               child: Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 _deletePost(postId);
//                 Navigator.pop(context);
//               },
//               child: Text('Delete', style: TextStyle(color: Colors.red)),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   /// Deletes a post from the 'posts' node
//   Future<void> _deletePost(String postId) async {
//     if (_user != null) {
//       try {
//         // Remove the post
//         await _dbRef.child("posts").child(postId).remove();
//         print('Post $postId deleted.');
//
//         // Optionally, remove all related comments from the 'comments' node
//         Query relatedComments = _dbRef.child('comments').orderByChild('postId').equalTo(postId);
//         DataSnapshot commentsSnapshot = await relatedComments.get();
//         if (commentsSnapshot.exists) {
//           for (var comment in commentsSnapshot.children) {
//             await comment.ref.remove();
//             print('Comment ${comment.key} deleted.');
//           }
//         }
//
//         Fluttertoast.showToast(msg: "Post deleted successfully", gravity: ToastGravity.BOTTOM);
//       } catch (e) {
//         print("Error deleting post: $e");
//         Fluttertoast.showToast(msg: "Error deleting post: $e", gravity: ToastGravity.BOTTOM);
//       }
//     }
//   }
//
//   /// Handles double-tap to edit a post
//   Future<void> _onPostDoubleTap(String postId, String currentContent) async {
//     TextEditingController _contentController = TextEditingController(text: currentContent);
//     File? selectedImage;
//
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text('Edit Post'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: _contentController,
//                 decoration: InputDecoration(labelText: 'Edit Content'),
//               ),
//               SizedBox(height: 10),
//               ElevatedButton(
//                 onPressed: () async {
//                   final ImagePicker _picker = ImagePicker();
//                   final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
//                   if (image != null) {
//                     setState(() {
//                       selectedImage = File(image.path);
//                     });
//                     Fluttertoast.showToast(msg: "New image selected", gravity: ToastGravity.BOTTOM);
//                   }
//                 },
//                 child: Text("Change Image"),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               child: Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 _updatePost(postId, _contentController.text.trim(), selectedImage);
//                 Navigator.pop(context);
//               },
//               child: Text('Update'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   /// Updates a post's content and image
//   Future<void> _updatePost(String postId, String newContent, File? newImage) async {
//     if (_user != null) {
//       Map<String, dynamic> updatedData = {"content": newContent};
//
//       try {
//         // Update the image if a new image was selected
//         if (newImage != null) {
//           String path = 'post_images/${postId}.jpg';
//           SettableMetadata metadata = SettableMetadata(customMetadata: {
//             'userId': _user!.uid,
//           });
//
//           UploadTask uploadTask = _storage.ref(path).putFile(newImage, metadata);
//           TaskSnapshot uploadSnapshot = await uploadTask.whenComplete(() => null);
//           String downloadUrl = await uploadSnapshot.ref.getDownloadURL();
//
//           updatedData['imageUrl'] = downloadUrl;
//           print('Post $postId image updated. New URL: $downloadUrl');
//         }
//
//         await _dbRef.child("posts").child(postId).update(updatedData);
//         Fluttertoast.showToast(msg: "Post updated successfully", gravity: ToastGravity.BOTTOM);
//
//         // Reload the posts to reflect the changes
//         _loadUserPosts();
//       } catch (e) {
//         print("Failed to update post: $e");
//         Fluttertoast.showToast(msg: "Failed to update post: $e", gravity: ToastGravity.BOTTOM);
//       }
//     }
//   }
//
//   /// Toggles like/unlike on a post
//   // Future<void> _toggleLike(String postId, bool isCurrentlyLiked) async {
//   //   if (_user != null) {
//   //     DatabaseReference likesRef = _dbRef.child("posts").child(postId).child("likes").child(_user!.uid);
//   //     if (isCurrentlyLiked) {
//   //       // Unlike the post
//   //       await likesRef.remove();
//   //       print('Post $postId unliked by user ${_user!.uid}');
//   //     } else {
//   //       // Like the post
//   //       await likesRef.set(true);
//   //       print('Post $postId liked by user ${_user!.uid}');
//   //     }
//   //   }
//   // }
//
//
//
//   /// Uploads a profile image to Firebase Storage and updates the user's profile
//   Future<void> _uploadProfileImage(File image) async {
//     if (_user != null) {
//       try {
//         String path = 'users/${_user!.uid}/profile.jpg';
//         UploadTask uploadTask = _storage.ref(path).putFile(image);
//         TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
//         String downloadUrl = await taskSnapshot.ref.getDownloadURL();
//
//         await _dbRef.child("users").child(_user!.uid).update({
//           "profileImageUrl": downloadUrl,
//         });
//
//         setState(() {
//           _profileImageUrl = downloadUrl;
//         });
//
//         print('Profile image updated. New URL: $downloadUrl');
//         Fluttertoast.showToast(msg: "Profile image updated successfully", gravity: ToastGravity.BOTTOM);
//       } catch (e) {
//         print("Failed to upload profile image: $e");
//         Fluttertoast.showToast(msg: "Failed to upload profile image: $e", gravity: ToastGravity.BOTTOM);
//       }
//     }
//   }
//
//   /// Picks an image from the gallery
//   Future<void> _pickImage() async {
//     final ImagePicker _picker = ImagePicker();
//     final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
//
//     if (image != null) {
//       setState(() {
//         _image = File(image.path);
//       });
//       _uploadProfileImage(_image!);
//     } else {
//       Fluttertoast.showToast(msg: "No image selected");
//     }
//   }
//
//   /// Navigates to the post details screen
//   void _viewPostDetails(Map<String, dynamic> post) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => PostDetailScreen(post: post, currentUser: _user)),
//     );
//   }
//
//   /// Navigates to the comments screen for a specific post
//   void _navigateToComments(Map<dynamic, dynamic> post) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => CommentScreen(
//           postId: post['postId'],
//           postOwnerId: post['userId'],
//           canReport: true, // Enable reporting
//         ),
//       ),
//     );
//   }
//
//   /// Builds a statistics item (Photos, Followers, Follows)
//   Widget _buildStatItem(String label, String count) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Text(label, style: TextStyle(color: Colors.grey)),
//         SizedBox(height: 4),
//         Text(count, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//       ],
//     );
//   }
//
//   /// Reports a comment by adding it to the 'reportcomment' node
//   // void _reportComment(String commentId, Map<dynamic, dynamic> commentData) {
//   //   showDialog(
//   //     context: context,
//   //     builder: (context) {
//   //       TextEditingController _reasonController = TextEditingController();
//   //
//   //       return AlertDialog(
//   //         title: Text('Report Comment'),
//   //         content: Column(
//   //           mainAxisSize: MainAxisSize.min,
//   //           children: [
//   //             Text('Please specify the reason for reporting this comment:'),
//   //             TextField(
//   //               controller: _reasonController,
//   //               decoration: InputDecoration(
//   //                 hintText: 'Enter reason',
//   //               ),
//   //             ),
//   //           ],
//   //         ),
//   //         actions: [
//   //           TextButton(
//   //             onPressed: () {
//   //               Navigator.pop(context); // Close the dialog
//   //             },
//   //             child: Text('Cancel'),
//   //           ),
//   //           TextButton(
//   //             onPressed: () async {
//   //               String reason = _reasonController.text.trim();
//   //               if (reason.isEmpty) {
//   //                 Fluttertoast.showToast(msg: 'Please enter a reason.');
//   //                 return;
//   //               }
//   //
//   //               try {
//   //                 // Proceed to report the comment
//   //                 String commentOwnerId = commentData['userId'];
//   //                 String reporterId = _user!.uid;
//   //
//   //                 // Check if the user has already reported this comment
//   //                 DataSnapshot existingReport = await _dbRef
//   //                     .child('reportcomment')
//   //                     .orderByChild('reporterId')
//   //                     .equalTo(reporterId)
//   //                     .get();
//   //
//   //                 bool alreadyReported = false;
//   //                 if (existingReport.exists) {
//   //                   Map<dynamic, dynamic> reports = Map<dynamic, dynamic>.from(existingReport.value as Map<dynamic, dynamic>);
//   //                   reports.forEach((key, report) {
//   //                     if (report['commentId'] == commentId) {
//   //                       alreadyReported = true;
//   //                     }
//   //                   });
//   //                 }
//   //
//   //                 if (alreadyReported) {
//   //                   Fluttertoast.showToast(
//   //                     msg: 'You have already reported this comment.',
//   //                     toastLength: Toast.LENGTH_SHORT,
//   //                     gravity: ToastGravity.BOTTOM,
//   //                   );
//   //                   Navigator.pop(context);
//   //                   return;
//   //                 }
//   //
//   //                 // Fetch reporter details
//   //                 DataSnapshot reporterSnapshot = await _dbRef.child('users').child(reporterId).get();
//   //                 if (!reporterSnapshot.exists) {
//   //                   Fluttertoast.showToast(msg: 'Reporter user does not exist.');
//   //                   Navigator.pop(context);
//   //                   return;
//   //                 }
//   //                 Map<String, dynamic> reporterData = Map<String, dynamic>.from(reporterSnapshot.value as Map);
//   //                 String reporterUsername = reporterData['username'] ?? 'Unknown User';
//   //                 String reporterEmail = reporterData['email'] ?? 'No Email';
//   //
//   //                 // Fetch comment owner details
//   //                 DataSnapshot commentOwnerSnapshot = await _dbRef.child('users').child(commentOwnerId).get();
//   //                 if (!commentOwnerSnapshot.exists) {
//   //                   Fluttertoast.showToast(msg: 'Comment owner does not exist.');
//   //                   Navigator.pop(context);
//   //                   return;
//   //                 }
//   //                 Map<String, dynamic> commentOwnerData = Map<String, dynamic>.from(commentOwnerSnapshot.value as Map);
//   //                 String commentOwnerUsername = commentOwnerData['username'] ?? 'Unknown User';
//   //                 String commentOwnerEmail = commentOwnerData['email'] ?? 'No Email';
//   //
//   //                 // Create the report entry
//   //                 DatabaseReference reportRef = _dbRef.child('reportcomment').push();
//   //                 await reportRef.set({
//   //                   'reportId': reportRef.key,
//   //                   'postId': commentData['postId'], // Corrected line
//   //                   'commentId': commentId,
//   //                   'commentContent': commentData['content'] ?? '',
//   //                   'commentUserId': commentOwnerId,
//   //                   'commentOwnerUsername': commentOwnerUsername,
//   //                   'commentOwnerEmail': commentOwnerEmail,
//   //                   'reporterId': reporterId,
//   //                   'reporterUsername': reporterUsername,
//   //                   'reporterEmail': reporterEmail,
//   //                   'reason': reason,
//   //                   'timestamp': DateTime.now().millisecondsSinceEpoch,
//   //                 });
//   //
//   //                 print('Comment $commentId reported by user $reporterId');
//   //                 Fluttertoast.showToast(msg: 'Comment reported.');
//   //                 Navigator.pop(context); // Close the dialog
//   //               } catch (e) {
//   //                 print('Error reporting comment: $e');
//   //                 Navigator.pop(context); // Close the dialog
//   //                 Fluttertoast.showToast(msg: 'Error reporting comment: $e');
//   //               }
//   //             },
//   //             child: Text('Submit'),
//   //           ),
//   //         ],
//   //       );
//   //     },
//   //   );
//   // }
//
//   // void _reportComment(String commentId, Map<dynamic, dynamic> commentData, String postId) {
//   //   print('[_reportComment] Called with commentId: $commentId, postId: $postId');
//   //   showDialog(
//   //     context: context,
//   //     builder: (context) {
//   //       TextEditingController _reasonController = TextEditingController();
//   //
//   //       return AlertDialog(
//   //         title: Text('Report Comment'),
//   //         content: Column(
//   //           mainAxisSize: MainAxisSize.min,
//   //           children: [
//   //             Text('Please specify the reason for reporting this comment:'),
//   //             TextField(
//   //               controller: _reasonController,
//   //               decoration: InputDecoration(
//   //                 hintText: 'Enter reason',
//   //               ),
//   //             ),
//   //           ],
//   //         ),
//   //         actions: [
//   //           TextButton(
//   //             onPressed: () {
//   //               Navigator.pop(context); // Close the dialog
//   //             },
//   //             child: Text('Cancel'),
//   //           ),
//   //           TextButton(
//   //             onPressed: () async {
//   //               String reason = _reasonController.text.trim();
//   //               if (reason.isEmpty) {
//   //                 Fluttertoast.showToast(msg: 'Please enter a reason.');
//   //                 return;
//   //               }
//   //
//   //               try {
//   //                 // Proceed to report the comment
//   //                 String commentOwnerId = commentData['userId'];
//   //                 String reporterId = _user!.uid;
//   //
//   //                 // Check if the user has already reported this comment
//   //                 DataSnapshot existingReport = await _dbRef
//   //                     .child('reportcomment')
//   //                     .orderByChild('reporterId')
//   //                     .equalTo(reporterId)
//   //                     .get();
//   //
//   //                 bool alreadyReported = false;
//   //                 if (existingReport.exists) {
//   //                   Map<dynamic, dynamic> reports = Map<dynamic, dynamic>.from(existingReport.value as Map<dynamic, dynamic>);
//   //                   reports.forEach((key, report) {
//   //                     if (report['commentId'] == commentId) {
//   //                       alreadyReported = true;
//   //                     }
//   //                   });
//   //                 }
//   //
//   //                 if (alreadyReported) {
//   //                   Fluttertoast.showToast(
//   //                     msg: 'You have already reported this comment.',
//   //                     toastLength: Toast.LENGTH_SHORT,
//   //                     gravity: ToastGravity.BOTTOM,
//   //                   );
//   //                   Navigator.pop(context);
//   //                   return;
//   //                 }
//   //
//   //                 // Fetch reporter details
//   //                 DataSnapshot reporterSnapshot = await _dbRef.child('users').child(reporterId).get();
//   //                 if (!reporterSnapshot.exists) {
//   //                   Fluttertoast.showToast(msg: 'Reporter user does not exist.');
//   //                   Navigator.pop(context);
//   //                   return;
//   //                 }
//   //                 Map<String, dynamic> reporterData = Map<String, dynamic>.from(reporterSnapshot.value as Map);
//   //                 String reporterUsername = reporterData['username'] ?? 'Unknown User';
//   //                 String reporterEmail = reporterData['email'] ?? 'No Email';
//   //
//   //                 // Fetch comment owner details
//   //                 DataSnapshot commentOwnerSnapshot = await _dbRef.child('users').child(commentOwnerId).get();
//   //                 if (!commentOwnerSnapshot.exists) {
//   //                   Fluttertoast.showToast(msg: 'Comment owner does not exist.');
//   //                   Navigator.pop(context);
//   //                   return;
//   //                 }
//   //                 Map<String, dynamic> commentOwnerData = Map<String, dynamic>.from(commentOwnerSnapshot.value as Map);
//   //                 String commentOwnerUsername = commentOwnerData['username'] ?? 'Unknown User';
//   //                 String commentOwnerEmail = commentOwnerData['email'] ?? 'No Email';
//   //
//   //                 // Create the report entry
//   //                 DatabaseReference reportRef = _dbRef.child('reportcomment').push();
//   //                 await reportRef.set({
//   //                   'reportId': reportRef.key,
//   //                   'postId': postId,
//   //                   'commentId': commentId,
//   //                   'commentContent': commentData['content'] ?? '',
//   //                   'commentUserId': commentOwnerId,
//   //                   'commentOwnerUsername': commentOwnerUsername,
//   //                   'commentOwnerEmail': commentOwnerEmail,
//   //                   'reporterId': reporterId,
//   //                   'reporterUsername': reporterUsername,
//   //                   'reporterEmail': reporterEmail,
//   //                   'reason': reason,
//   //                   'timestamp': DateTime.now().millisecondsSinceEpoch,
//   //                 });
//   //
//   //                 print('Comment $commentId reported by user $reporterId');
//   //                 Fluttertoast.showToast(msg: 'Comment reported.');
//   //                 Navigator.pop(context); // Close the dialog
//   //               } catch (e) {
//   //                 print('Error reporting comment: $e');
//   //                 Navigator.pop(context); // Close the dialog
//   //                 Fluttertoast.showToast(msg: 'Error reporting comment: $e');
//   //               }
//   //             },
//   //             child: Text('Submit'),
//   //           ),
//   //         ],
//   //       );
//   //     },
//   //   );
//   // }
//
//
//
//
//   Future<void> _reportComment(String commentId, Map<dynamic, dynamic> commentData, String postId) async {
//     print('[_reportComment] Called with commentId: $commentId, postId: $postId');
//
//     showDialog(
//       context: context,
//       builder: (context) {
//         TextEditingController _reasonController = TextEditingController();
//
//         return AlertDialog(
//           title: Text('Report Comment'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text('Please specify the reason for reporting this comment:'),
//               TextField(
//                 controller: _reasonController,
//                 decoration: InputDecoration(
//                   hintText: 'Enter reason',
//                 ),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 print('[_reportComment] Report dialog canceled');
//                 Navigator.pop(context); // Close the dialog
//               },
//               child: Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () async {
//                 print('[_reportComment] Submit pressed');
//                 String reason = _reasonController.text.trim();
//                 if (reason.isEmpty) {
//                   print('[_reportComment] Reason is empty');
//                   Fluttertoast.showToast(msg: 'Please enter a reason.');
//                   return;
//                 }
//
//                 try {
//                   print('[_reportComment] Checking existing reports');
//                   DataSnapshot existingReport = await _dbRef
//                       .child('reportcomment')
//                       .orderByChild('reporterId')
//                       .equalTo(_user!.uid)
//                       .get();
//
//                   bool alreadyReported = false;
//                   if (existingReport.exists) {
//                     Map<dynamic, dynamic> reports = Map<dynamic, dynamic>.from(existingReport.value as Map<dynamic, dynamic>);
//                     reports.forEach((key, report) {
//                       if (report['commentId'] == commentId) {
//                         alreadyReported = true;
//                       }
//                     });
//                   }
//
//                   if (alreadyReported) {
//                     print('[_reportComment] Already reported this comment.');
//                     Fluttertoast.showToast(msg: 'You have already reported this comment.');
//                     Navigator.pop(context);
//                     return;
//                   }
//
//                   print('[_reportComment] Fetching reporter details');
//                   DataSnapshot reporterSnapshot = await _dbRef.child('users').child(_user!.uid).get();
//                   if (!reporterSnapshot.exists) {
//                     print('[_reportComment] Reporter user does not exist.');
//                     Fluttertoast.showToast(msg: 'Reporter user does not exist.');
//                     Navigator.pop(context);
//                     return;
//                   }
//                   Map<String, dynamic> reporterData = Map<String, dynamic>.from(reporterSnapshot.value as Map);
//                   String reporterUsername = reporterData['username'] ?? 'Unknown User';
//                   String reporterEmail = reporterData['email'] ?? 'No Email';
//
//                   print('[_reportComment] Fetching comment owner details');
//                   DataSnapshot commentOwnerSnapshot = await _dbRef.child('users').child(commentData['userId']).get();
//                   if (!commentOwnerSnapshot.exists) {
//                     print('[_reportComment] Comment owner does not exist.');
//                     Fluttertoast.showToast(msg: 'Comment owner does not exist.');
//                     Navigator.pop(context);
//                     return;
//                   }
//                   Map<String, dynamic> commentOwnerData = Map<String, dynamic>.from(commentOwnerSnapshot.value as Map);
//                   String commentOwnerUsername = commentOwnerData['username'] ?? 'Unknown User';
//                   String commentOwnerEmail = commentOwnerData['email'] ?? 'No Email';
//
//                   print('[_reportComment] Creating new report');
//                   DatabaseReference reportRef = _dbRef.child('reportcomment').push();
//                   await reportRef.set({
//                     'reportId': reportRef.key,
//                     'postId': postId,
//                     'commentId': commentId,
//                     'commentContent': commentData['content'] ?? '',
//                     'commentUserId': commentData['userId'],
//                     'commentOwnerUsername': commentOwnerUsername,
//                     'commentOwnerEmail': commentOwnerEmail,
//                     'reporterId': _user!.uid,
//                     'reporterUsername': reporterUsername,
//                     'reporterEmail': reporterEmail,
//                     'reason': reason,
//                     'timestamp': DateTime.now().millisecondsSinceEpoch,
//                   });
//
//                   print('[_reportComment] Report created with reportId: ${reportRef.key}');
//                   Fluttertoast.showToast(msg: 'Comment reported.');
//                   Navigator.pop(context);
//                 } catch (e) {
//                   print('[_reportComment] Error reporting comment: $e');
//                   Fluttertoast.showToast(msg: 'Error reporting comment: $e');
//                 }
//               },
//               child: Text('Submit'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//
//   /// Confirms deletion of a comment
//   void confirmDeleteComment(String postId, String commentId) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Delete Comment'),
//           content: Text('Are you sure you want to delete this comment? This action cannot be undone.'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(), // Cancel
//               child: Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close the dialog
//                 _deleteCommentById(postId, commentId); // Proceed with deletion
//               },
//               child: Text('Delete', style: TextStyle(color: Colors.red)),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   /// Deletes a comment by its ID
//   void _deleteCommentById(String postId, String commentId) async {
//     try {
//       await _dbRef.child('comments').child(commentId).remove();
//       print('Comment $commentId deleted from post $postId.');
//       Fluttertoast.showToast(msg: 'Comment deleted successfully.', gravity: ToastGravity.BOTTOM);
//     } catch (e) {
//       print('Error deleting comment: $e');
//       Fluttertoast.showToast(msg: 'Error deleting comment: $e', gravity: ToastGravity.BOTTOM);
//     }
//   }
//
//   /// Confirms removal of a report
//   void confirmRemoveReport(String reportId) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Remove Report'),
//           content: Text('Are you sure you want to remove this report?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(), // Cancel
//               child: Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close the dialog
//                 _removeReport(reportId); // Proceed with removing the report
//               },
//               child: Text('Remove', style: TextStyle(color: Colors.orange)),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   /// Removes a report from the 'reportcomment' node
//   void _removeReport(String reportId) async {
//     try {
//       await _dbRef.child('reportcomment').child(reportId).remove();
//       print('Report $reportId removed.');
//       Fluttertoast.showToast(
//         msg: "Report removed successfully.",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//       );
//     } catch (e) {
//       print('Error removing report: $e');
//       Fluttertoast.showToast(
//         msg: "Error removing report: $e",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//       );
//     }
//   }
//
//   /// Confirms issuing a warning to a user
//   void confirmIssueWarning(String userId) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Issue Warning'),
//           content: Text('Are you sure you want to issue a warning to this user?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(), // Cancel
//               child: Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close the dialog
//                 _issueWarning(userId); // Proceed with issuing the warning
//               },
//               child: Text('Issue Warning', style: TextStyle(color: Colors.orange)),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   /// Issues a warning to a user by adding an entry to their 'warnings' node
//   void _issueWarning(String userId) async {
//     try {
//       await _dbRef.child('users').child(userId).child('warnings').push().set({
//         'timestamp': DateTime.now().millisecondsSinceEpoch,
//         'reason': 'Violation of community guidelines',
//       });
//       print('Warning issued to user $userId.');
//       Fluttertoast.showToast(
//         msg: "Warning issued to User ID: $userId",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//         timeInSecForIosWeb: 1,
//       );
//     } catch (e) {
//       print('Error issuing warning: $e');
//       Fluttertoast.showToast(
//         msg: "Error issuing warning: $e",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//       );
//     }
//   }
//
//   /// Builds the recent activity section with reporting functionality
//   Widget _buildRecentActivityList() {
//     List<Widget> activityWidgets = [];
//
//     for (var post in _posts) {
//       // Fetch comments from the global 'comments' node where 'postId' matches
//       _dbRef.child("comments").orderByChild("postId").equalTo(post['postId']).onValue.listen((commentEvent) {
//         if (commentEvent.snapshot.exists) {
//           Map<dynamic, dynamic> commentsMap = Map<dynamic, dynamic>.from(commentEvent.snapshot.value as Map);
//           commentsMap.forEach((commentId, commentData) {
//             if (commentData['userId'] != _user!.uid) {
//               activityWidgets.add(ListTile(
//                 leading: CircleAvatar(
//                   backgroundImage: commentData['userProfileImageUrl'] != null && commentData['userProfileImageUrl'] != ''
//                       ? NetworkImage(commentData['userProfileImageUrl'])
//                       : AssetImage('assets/profile_placeholder.png') as ImageProvider,
//                 ),
//                 title: Text('User ${commentData['username']} commented on your post'),
//                 subtitle: Text(commentData['content']),
//                 trailing: IconButton(
//                   icon: Icon(Icons.flag, color: Colors.redAccent),
//                   tooltip: 'Report Comment',
//                   onPressed: () => _reportComment(commentId, commentData, post['postId']),
//                 ),
//                 onTap: () => _viewPostDetails(post),
//               ));
//             }
//           });
//         }
//       });
//
//       // Fetch likes from the 'likes' node
//       _dbRef.child("posts").child(post['postId']).child("likes").onValue.listen((likeEvent) {
//         if (likeEvent.snapshot.exists) {
//           Map<dynamic, dynamic> likesMap = Map<dynamic, dynamic>.from(likeEvent.snapshot.value as Map);
//           likesMap.forEach((userId, _) {
//             if (userId != _user!.uid) {
//               activityWidgets.add(ListTile(
//                 leading: Icon(Icons.favorite, color: Colors.red),
//                 title: Text('User $userId liked your post'),
//                 onTap: () => _viewPostDetails(post),
//               ));
//             }
//           });
//         }
//       });
//     }
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: activityWidgets.isNotEmpty
//           ? activityWidgets
//           : [
//         Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Text(
//             'No recent activity.',
//             style: TextStyle(color: Colors.grey),
//           ),
//         ),
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('My Profile'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.settings),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => SettingsScreen()),
//               );
//             },
//             tooltip: 'Settings',
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             // Profile Picture
//             GestureDetector(
//               onTap: _pickImage,
//               child: Stack(
//                 alignment: Alignment.bottomRight,
//                 children: [
//                   CircleAvatar(
//                     radius: 50,
//                     backgroundImage: _profileImageUrl != null
//                         ? NetworkImage(_profileImageUrl!)
//                         : AssetImage('assets/profile_placeholder.png') as ImageProvider,
//                   ),
//                   CircleAvatar(
//                     radius: 16,
//                     backgroundColor: Colors.black54,
//                     child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 8),
//             // Username and Email
//             Text(
//               _username,
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             Text(
//               _email,
//               style: TextStyle(fontSize: 16, color: Colors.grey),
//             ),
//             SizedBox(height: 16),
//             // Statistics (Photos, Followers, Follows)
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   _buildStatItem('Photos', _photosCount.toString()),
//                   _buildStatItem('Followers', _followersCount.toString()),
//                   _buildStatItem('Follows', _followsCount.toString()),
//                 ],
//               ),
//             ),
//             SizedBox(height: 16),
//             // Bio
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   _bio,
//                   style: TextStyle(fontSize: 14, color: Colors.black87),
//                 ),
//               ),
//             ),
//             SizedBox(height: 16),
//             Divider(thickness: 1),
//             // Recent Activity
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   'Recent Activity',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ),
//             _buildRecentActivityList(),
//             SizedBox(height: 16),
//             Divider(thickness: 1),
//             // User's Posts
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   'My Posts',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ),
//             // Grid of Posts
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: GridView.builder(
//                 physics: NeverScrollableScrollPhysics(),
//                 shrinkWrap: true,
//                 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 3,
//                   crossAxisSpacing: 10,
//                   mainAxisSpacing: 10,
//                   childAspectRatio: 1, // Ensures each grid item is square
//                 ),
//                 itemCount: _posts.length,
//                 itemBuilder: (context, index) {
//                   final post = _posts[index];
//                   return GestureDetector(
//                     onTap: () => _viewPostDetails(post),
//                     onDoubleTap: () => _onPostDoubleTap(post['postId'], post['content']), // Edit post
//                     onLongPress: () => _onPostTripleTap(post['postId']), // Delete post
//                     child: Container(
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.grey.shade300),
//                         color: Colors.black12,
//                       ),
//                       child: Stack(
//                         fit: StackFit.expand,
//                         children: [
//                           Image.network(
//                             post['imageUrl'],
//                             fit: BoxFit.cover,
//                             errorBuilder: (context, error, stackTrace) {
//                               print('Error loading image for post ${post['postId']}: $error');
//                               return Center(child: Icon(Icons.error, color: Colors.red));
//                             },
//                             loadingBuilder: (context, child, loadingProgress) {
//                               if (loadingProgress == null) return child;
//                               return Center(child: CircularProgressIndicator());
//                             },
//                           ),
//                           Positioned(
//                             bottom: 4,
//                             left: 4,
//                             child: Container(
//                               padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
//                               color: Colors.black54,
//                               child: Row(
//                                 children: [
//                                   Icon(
//                                     Icons.favorite,
//                                     color: Colors.redAccent,
//                                     size: 16,
//                                   ),
//                                   SizedBox(width: 2),
//                                   Text(
//                                     '${post['likesCount']}',
//                                     style: TextStyle(color: Colors.white, fontSize: 12),
//                                   ),
//                                   SizedBox(width: 8),
//                                   IconButton(
//                                     icon: Icon(Icons.comment_bank, color: Colors.white, size: 20),
//                                     tooltip: 'View Comments',
//                                     onPressed: () => _navigateToComments(post),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// ProfileScreen.dart

import 'dart:io';
import 'package:betreflutter/CommentScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'NotificationsScreen.dart';
import 'PostDetailScreen.dart';
import 'Settings.dart';
import 'dart:async';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? _user;
  String? _profileImageUrl;
  String _username = "Username";
  String _email = "Email";
  int _photosCount = 0;
  int _followersCount = 0;
  int _followsCount = 0;
  String _bio = '';

  List<Map<String, dynamic>> _posts = []; // To store post details
  File? _image;
  Timer? _tapTimer;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    if (_user != null) {
      _loadUserProfile();
      _loadUserStats();
      _loadUserPosts();
    }
  }

  /// Loads the user's profile information
  Future<void> _loadUserProfile() async {
    if (_user != null) {
      _dbRef.child("users").child(_user!.uid).once().then((snapshot) {
        if (snapshot.snapshot.exists) {
          var userData = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
          setState(() {
            _username = userData['username'] ?? 'Username';
            _email = userData['email'] ?? 'Email';
            _profileImageUrl = userData['profileImageUrl'];
            _bio = userData['bio'] ?? '';
          });
          print('Loaded user profile: $_username, $_email');
        } else {
          print('User profile does not exist.');
        }
      }).catchError((error) {
        print('Error loading user profile: $error');
      });
    }
  }

  /// Loads the user's statistics (followers, following, photos)
  Future<void> _loadUserStats() async {
    if (_user != null) {
      // Followers count
      _dbRef.child("followers").child(_user!.uid).onValue.listen((event) {
        final dataSnapshot = event.snapshot;
        if (dataSnapshot.exists) {
          setState(() {
            _followersCount = dataSnapshot.children.length;
          });
          print('Followers Count: $_followersCount');
        } else {
          setState(() {
            _followersCount = 0;
          });
          print('Followers Count: $_followersCount');
        }
      });

      // Following count
      _dbRef.child("following").child(_user!.uid).onValue.listen((event) {
        final dataSnapshot = event.snapshot;
        if (dataSnapshot.exists) {
          setState(() {
            _followsCount = dataSnapshot.children.length;
          });
          print('Following Count: $_followsCount');
        } else {
          setState(() {
            _followsCount = 0;
          });
          print('Following Count: $_followsCount');
        }
      });

      // Photos count
      _dbRef.child("posts").orderByChild("userId").equalTo(_user!.uid).onValue.listen((event) async {
        final dataSnapshot = event.snapshot;
        if (dataSnapshot.exists) {
          setState(() {
            _photosCount = dataSnapshot.children.length;
          });
          print('Photos Count: $_photosCount');
        } else {
          setState(() {
            _photosCount = 0;
          });
          print('Photos Count: $_photosCount');
        }
      });
    }
  }

  /// Loads the user's posts and initializes likes and comments counts
  Future<void> _loadUserPosts() async {
    if (_user != null) {
      print('Loading posts for user: ${_user!.uid}');
      _dbRef
          .child("posts")
          .orderByChild("userId")
          .equalTo(_user!.uid)
          .onValue
          .listen((event) async {
        print('Posts listener triggered');
        if (event.snapshot.exists) {
          print('Posts found for user ${_user!.uid}');
          List<Map<String, dynamic>> posts = [];
          for (var post in event.snapshot.children) {
            var postData = Map<String, dynamic>.from(post.value as Map);
            postData['postId'] = post.key;

            // Initialize likes and comments
            int likesCount = 0;
            bool isLikedByCurrentUser = false;
            if (postData['likes'] != null) {
              Map<dynamic, dynamic> likesMap = Map<dynamic, dynamic>.from(postData['likes']);
              likesCount = likesMap.length;
              if (likesMap.containsKey(_user!.uid)) {
                isLikedByCurrentUser = true;
              }
            }
            postData['likesCount'] = likesCount;
            postData['isLikedByCurrentUser'] = isLikedByCurrentUser;

            // Get comments count from the 'comments' node under this post
            DataSnapshot commentSnapshot = await _dbRef
                .child("posts")
                .child(postData['postId'])
                .child('comments')
                .get();
            int commentsCount = 0;
            if (commentSnapshot.exists) {
              commentsCount = commentSnapshot.children.length;
            }
            postData['commentsCount'] = commentsCount;

            posts.add(postData);
          }
          setState(() {
            _posts = posts.reversed.toList();
          });
        } else {
          print('No posts found for user ${_user!.uid}');
          setState(() {
            _posts = [];
          });
        }
      }, onError: (error) {
        print('Error loading posts: $error');
      });
    }
  }

  /// Handles triple-tap to delete a post
  Future<void> _onPostTripleTap(String postId) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Post'),
          content: Text('Are you sure you want to delete this post? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deletePost(postId);
                Navigator.pop(context);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  /// Deletes a post from the 'posts' node
  Future<void> _deletePost(String postId) async {
    if (_user != null) {
      try {
        // Remove the post
        await _dbRef.child("posts").child(postId).remove();
        print('Post $postId deleted.');

        // Optionally, remove all related comments from the 'comments' node
        Query relatedComments = _dbRef.child('comments').orderByChild('postId').equalTo(postId);
        DataSnapshot commentsSnapshot = await relatedComments.get();
        if (commentsSnapshot.exists) {
          for (var comment in commentsSnapshot.children) {
            await comment.ref.remove();
            print('Comment ${comment.key} deleted.');
          }
        }

        // Optionally, notify the user that their post was deleted
        Fluttertoast.showToast(msg: "Post deleted successfully", gravity: ToastGravity.BOTTOM);
      } catch (e) {
        print("Error deleting post: $e");
        Fluttertoast.showToast(msg: "Error deleting post: $e", gravity: ToastGravity.BOTTOM);
      }
    }
  }

  /// Handles double-tap to edit a post
  Future<void> _onPostDoubleTap(String postId, String currentContent) async {
    TextEditingController _contentController = TextEditingController(text: currentContent);
    File? selectedImage;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Post'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _contentController,
                decoration: InputDecoration(labelText: 'Edit Content'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final ImagePicker _picker = ImagePicker();
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      selectedImage = File(image.path);
                    });
                    Fluttertoast.showToast(msg: "New image selected", gravity: ToastGravity.BOTTOM);
                  }
                },
                child: Text("Change Image"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _updatePost(postId, _contentController.text.trim(), selectedImage);
                Navigator.pop(context);
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  /// Updates a post's content and image
  Future<void> _updatePost(String postId, String newContent, File? newImage) async {
    if (_user != null) {
      Map<String, dynamic> updatedData = {"content": newContent};

      try {
        // Update the image if a new image was selected
        if (newImage != null) {
          String path = 'post_images/${postId}.jpg';
          SettableMetadata metadata = SettableMetadata(customMetadata: {
            'userId': _user!.uid,
          });

          UploadTask uploadTask = _storage.ref(path).putFile(newImage, metadata);
          TaskSnapshot uploadSnapshot = await uploadTask.whenComplete(() => null);
          String downloadUrl = await uploadSnapshot.ref.getDownloadURL();

          updatedData['imageUrl'] = downloadUrl;
          print('Post $postId image updated. New URL: $downloadUrl');

          // Optionally, notify the post owner about the update
          // Since the user is updating their own post, this might not be necessary
        }

        await _dbRef.child("posts").child(postId).update(updatedData);
        Fluttertoast.showToast(msg: "Post updated successfully", gravity: ToastGravity.BOTTOM);

        // Reload the posts to reflect the changes
        _loadUserPosts();
      } catch (e) {
        print("Failed to update post: $e");
        Fluttertoast.showToast(msg: "Failed to update post: $e", gravity: ToastGravity.BOTTOM);
      }
    }
  }

  /// Toggles like/unlike on a post and sends a notification
  Future<void> _toggleLike(Map<dynamic, dynamic> post) async {
    if (_user != null) {
      String postId = post['postId'];
      bool isCurrentlyLiked = post['isLikedByCurrentUser'] ?? false;

      DatabaseReference likesRef = _dbRef.child("posts").child(postId).child("likes").child(_user!.uid);

      try {
        if (isCurrentlyLiked) {
          // Unlike the post
          await likesRef.remove();
          print('Post $postId unliked by user ${_user!.uid}');
          Fluttertoast.showToast(msg: 'Post unliked.', gravity: ToastGravity.BOTTOM);

          // Notify the post owner about the unlike
          await _notifyPostOwner(post, 'unliked your post');
        } else {
          // Like the post
          await likesRef.set(true);
          print('Post $postId liked by user ${_user!.uid}');
          Fluttertoast.showToast(msg: 'Post liked.', gravity: ToastGravity.BOTTOM);

          // Notify the post owner about the like
          await _notifyPostOwner(post, 'liked your post');
        }
      } catch (e) {
        print('Error toggling like: $e');
        Fluttertoast.showToast(msg: "Error toggling like: $e", gravity: ToastGravity.BOTTOM);
      }
    } else {
      Fluttertoast.showToast(msg: 'You must be logged in to like posts.', gravity: ToastGravity.BOTTOM);
    }
  }

  /// Notifies the post owner about like/unlike actions
  Future<void> _notifyPostOwner(Map<dynamic, dynamic> post, String action) async {
    String postOwnerId = post['userId'];
    String currentUserId = _user!.uid;

    // Avoid notifying self if the user likes/unlikes their own post
    if (postOwnerId == currentUserId) return;

    DatabaseReference notificationsRef = _dbRef.child('notifications').child(postOwnerId).push();

    await notificationsRef.set({
      'fromUserId': currentUserId,
      'action': action, // e.g., 'liked your post', 'unliked your post'
      'postId': post['postId'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    print('Notification sent to $postOwnerId: $action');
  }

  /// Uploads a profile image to Firebase Storage and updates the user's profile
  Future<void> _uploadProfileImage(File image) async {
    if (_user != null) {
      try {
        String path = 'users/${_user!.uid}/profile.jpg';
        UploadTask uploadTask = _storage.ref(path).putFile(image);
        TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
        String downloadUrl = await taskSnapshot.ref.getDownloadURL();

        await _dbRef.child("users").child(_user!.uid).update({
          "profileImageUrl": downloadUrl,
        });

        setState(() {
          _profileImageUrl = downloadUrl;
        });

        print('Profile image updated. New URL: $downloadUrl');
        Fluttertoast.showToast(msg: "Profile image updated successfully", gravity: ToastGravity.BOTTOM);
      } catch (e) {
        print("Failed to upload profile image: $e");
        Fluttertoast.showToast(msg: "Failed to upload profile image: $e", gravity: ToastGravity.BOTTOM);
      }
    }
  }

  /// Picks an image from the gallery
  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
      _uploadProfileImage(_image!);
    } else {
      Fluttertoast.showToast(msg: "No image selected");
    }
  }

  /// Navigates to the post details screen
  void _viewPostDetails(Map<String, dynamic> post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PostDetailScreen(post: post, currentUser: _user)),
    );
  }

  /// Navigates to the comments screen for a specific post
  void _navigateToComments(Map<dynamic, dynamic> post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentScreen(
          postId: post['postId'],
          postOwnerId: post['userId'],
          canReport: true, // Enable reporting
        ),
      ),
    );
  }

  /// Builds a statistics item (Photos, Followers, Follows)
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

  /// Reports a comment by adding it to the 'reportcomment' node
  Future<void> _reportComment(String commentId, Map<dynamic, dynamic> commentData, String postId) async {
    print('[_reportComment] Called with commentId: $commentId, postId: $postId');

    showDialog(
      context: context,
      builder: (context) {
        TextEditingController _reasonController = TextEditingController();

        return AlertDialog(
          title: Text('Report Comment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Please specify the reason for reporting this comment:'),
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
                print('[_reportComment] Report dialog canceled');
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                print('[_reportComment] Submit pressed');
                String reason = _reasonController.text.trim();
                if (reason.isEmpty) {
                  print('[_reportComment] Reason is empty');
                  Fluttertoast.showToast(msg: 'Please enter a reason.');
                  return;
                }

                try {
                  print('[_reportComment] Checking existing reports');
                  DataSnapshot existingReport = await _dbRef
                      .child('reportcomment')
                      .orderByChild('reporterId')
                      .equalTo(_user!.uid)
                      .get();

                  bool alreadyReported = false;
                  if (existingReport.exists) {
                    Map<dynamic, dynamic> reports = Map<dynamic, dynamic>.from(existingReport.value as Map<dynamic, dynamic>);
                    reports.forEach((key, report) {
                      if (report['commentId'] == commentId) {
                        alreadyReported = true;
                      }
                    });
                  }

                  if (alreadyReported) {
                    print('[_reportComment] Already reported this comment.');
                    Fluttertoast.showToast(msg: 'You have already reported this comment.');
                    Navigator.pop(context);
                    return;
                  }

                  print('[_reportComment] Fetching reporter details');
                  DataSnapshot reporterSnapshot = await _dbRef.child('users').child(_user!.uid).get();
                  if (!reporterSnapshot.exists) {
                    print('[_reportComment] Reporter user does not exist.');
                    Fluttertoast.showToast(msg: 'Reporter user does not exist.');
                    Navigator.pop(context);
                    return;
                  }
                  Map<String, dynamic> reporterData = Map<String, dynamic>.from(reporterSnapshot.value as Map);
                  String reporterUsername = reporterData['username'] ?? 'Unknown User';
                  String reporterEmail = reporterData['email'] ?? 'No Email';

                  print('[_reportComment] Fetching comment owner details');
                  DataSnapshot commentOwnerSnapshot = await _dbRef.child('users').child(commentData['userId']).get();
                  if (!commentOwnerSnapshot.exists) {
                    print('[_reportComment] Comment owner does not exist.');
                    Fluttertoast.showToast(msg: 'Comment owner does not exist.');
                    Navigator.pop(context);
                    return;
                  }
                  Map<String, dynamic> commentOwnerData = Map<String, dynamic>.from(commentOwnerSnapshot.value as Map);
                  String commentOwnerUsername = commentOwnerData['username'] ?? 'Unknown User';
                  String commentOwnerEmail = commentOwnerData['email'] ?? 'No Email';

                  print('[_reportComment] Creating new report');
                  DatabaseReference reportRef = _dbRef.child('reportcomment').push();
                  await reportRef.set({
                    'reportId': reportRef.key,
                    'postId': postId,
                    'commentId': commentId,
                    'commentContent': commentData['content'] ?? '',
                    'commentUserId': commentData['userId'],
                    'commentOwnerUsername': commentOwnerUsername,
                    'commentOwnerEmail': commentOwnerEmail,
                    'reporterId': _user!.uid,
                    'reporterUsername': reporterUsername,
                    'reporterEmail': reporterEmail,
                    'reason': reason,
                    'timestamp': DateTime.now().millisecondsSinceEpoch,
                  });

                  print('[_reportComment] Report created with reportId: ${reportRef.key}');
                  Fluttertoast.showToast(msg: 'Comment reported.');
                  Navigator.pop(context);
                } catch (e) {
                  print('[_reportComment] Error reporting comment: $e');
                  Fluttertoast.showToast(msg: 'Error reporting comment: $e');
                }
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  /// Confirms deletion of a comment
  void confirmDeleteComment(String postId, String commentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Comment'),
          content: Text('Are you sure you want to delete this comment? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Cancel
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _deleteCommentById(postId, commentId); // Proceed with deletion
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  /// Deletes a comment by its ID
  void _deleteCommentById(String postId, String commentId) async {
    try {
      await _dbRef.child('comments').child(commentId).remove();
      print('Comment $commentId deleted from post $postId.');
      Fluttertoast.showToast(msg: 'Comment deleted successfully.', gravity: ToastGravity.BOTTOM);
    } catch (e) {
      print('Error deleting comment: $e');
      Fluttertoast.showToast(msg: 'Error deleting comment: $e', gravity: ToastGravity.BOTTOM);
    }
  }

  /// Confirms removal of a report
  void confirmRemoveReport(String reportId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove Report'),
          content: Text('Are you sure you want to remove this report?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Cancel
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _removeReport(reportId); // Proceed with removing the report
              },
              child: Text('Remove', style: TextStyle(color: Colors.orange)),
            ),
          ],
        );
      },
    );
  }

  /// Removes a report from the 'reportcomment' node
  void _removeReport(String reportId) async {
    try {
      await _dbRef.child('reportcomment').child(reportId).remove();
      print('Report $reportId removed.');
      Fluttertoast.showToast(
        msg: "Report removed successfully.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      print('Error removing report: $e');
      Fluttertoast.showToast(
        msg: "Error removing report: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  /// Confirms issuing a warning to a user
  void confirmIssueWarning(String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Issue Warning'),
          content: Text('Are you sure you want to issue a warning to this user?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Cancel
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _issueWarning(userId); // Proceed with issuing the warning
              },
              child: Text('Issue Warning', style: TextStyle(color: Colors.orange)),
            ),
          ],
        );
      },
    );
  }

  /// Issues a warning to a user by adding an entry to their 'warnings' node
  void _issueWarning(String userId) async {
    try {
      await _dbRef.child('users').child(userId).child('warnings').push().set({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'reason': 'Violation of community guidelines',
      });
      print('Warning issued to user $userId.');
      Fluttertoast.showToast(
        msg: "Warning issued to User ID: $userId",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
      );
    } catch (e) {
      print('Error issuing warning: $e');
      Fluttertoast.showToast(
        msg: "Error issuing warning: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  /// Builds the recent activity section with reporting functionality
  Widget _buildRecentActivityList() {
    List<Widget> activityWidgets = [];

    for (var post in _posts) {
      // Fetch comments from the global 'comments' node where 'postId' matches
      _dbRef.child("comments").orderByChild("postId").equalTo(post['postId']).onValue.listen((commentEvent) {
        if (commentEvent.snapshot.exists) {
          Map<dynamic, dynamic> commentsMap = Map<dynamic, dynamic>.from(commentEvent.snapshot.value as Map);
          commentsMap.forEach((commentId, commentData) {
            if (commentData['userId'] != _user!.uid) {
              activityWidgets.add(ListTile(
                leading: CircleAvatar(
                  backgroundImage: commentData['userProfileImageUrl'] != null && commentData['userProfileImageUrl'] != ''
                      ? NetworkImage(commentData['userProfileImageUrl'])
                      : AssetImage('assets/profile_placeholder.png') as ImageProvider,
                ),
                title: Text('User ${commentData['username']} commented on your post'),
                subtitle: Text(commentData['content']),
                trailing: IconButton(
                  icon: Icon(Icons.flag, color: Colors.redAccent),
                  tooltip: 'Report Comment',
                  onPressed: () => _reportComment(commentId, commentData, post['postId']),
                ),
                onTap: () => _viewPostDetails(post),
              ));
            }
          });
        }
      });

      // Fetch likes from the 'likes' node
      _dbRef.child("posts").child(post['postId']).child("likes").onValue.listen((likeEvent) {
        if (likeEvent.snapshot.exists) {
          Map<dynamic, dynamic> likesMap = Map<dynamic, dynamic>.from(likeEvent.snapshot.value as Map);
          likesMap.forEach((userId, _) {
            if (userId != _user!.uid) {
              activityWidgets.add(ListTile(
                leading: Icon(Icons.favorite, color: Colors.red),
                title: Text('User $userId liked your post'),
                onTap: () => _viewPostDetails(post),
              ));
            }
          });
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: activityWidgets.isNotEmpty
          ? activityWidgets
          : [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No recent activity.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  /// Sends a notification to the user about following/unfollowing
  Future<void> _notifyUser(String userId, String action) async {
    final DatabaseReference notificationsRef = _dbRef.child('notifications').child(userId).push();

    await notificationsRef.set({
      'fromUserId': _user!.uid,
      'action': action, // e.g., 'started following you', 'unfollowed you'
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    print('Notification sent to $userId: $action');
  }

  /// Navigates to the notifications screen
  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NotificationsScreen()), // Ensure NotificationsScreen.dart is properly implemented
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: _navigateToNotifications,
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Picture
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!)
                        : AssetImage('assets/profile_placeholder.png') as ImageProvider,
                  ),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            // Username and Email
            Text(
              _username,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              _email,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 16),
            // Statistics (Photos, Followers, Follows)
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
            // Bio
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _bio,
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
            ),

            // User's Posts
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'My Posts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            // Grid of Posts
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1, // Ensures each grid item is square
                ),
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  return GestureDetector(
                    onTap: () => _viewPostDetails(post),
                    onDoubleTap: () => _onPostDoubleTap(post['postId'], post['content']), // Edit post
                    onLongPress: () => _onPostTripleTap(post['postId']), // Delete post
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
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading image for post ${post['postId']}: $error');
                              return Center(child: Icon(Icons.error, color: Colors.red));
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(child: CircularProgressIndicator());
                            },
                          ),
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              color: Colors.black54,
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _toggleLike(post),
                                    child: Icon(
                                      Icons.favorite,
                                      color: post['isLikedByCurrentUser'] == true ? Colors.redAccent : Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    '${post['likesCount']}',
                                    style: TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                  SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(Icons.comment_bank, color: Colors.white, size: 20),
                                    tooltip: 'View Comments',
                                    onPressed: () => _navigateToComments(post),
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
            ),
          ],
        ),
      ),
    );
  }
}
