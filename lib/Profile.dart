import 'dart:io';
import 'package:betreflutter/CommentScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'PostDetailScreen.dart';
import 'Settings.dart';

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

  List<Map<String, dynamic>> _posts = []; // Modify to store post details
  File? _image;

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

  Future<void> _loadUserProfile() async {
    if (_user != null) {
      _dbRef.child("users").child(_user!.uid).once().then((snapshot) {
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
  }

  Future<void> _loadUserStats() async {
    if (_user != null) {
      _dbRef.child("followers").child(_user!.uid).onValue.listen((event) {
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

      _dbRef.child("following").child(_user!.uid).onValue.listen((event) {
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

      _dbRef.child("posts").orderByChild("userId").equalTo(_user!.uid).onValue.listen((event) {
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
  }


  Future<void> _loadUserPosts() async {
    if (_user != null) {
      _dbRef
          .child("posts")
          .orderByChild("userId")
          .equalTo(_user!.uid)
          .onValue
          .listen((event) {
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
            if (likesMap.containsKey(_user!.uid)) {
              isLikedByCurrentUser = true;
            }
          }
          postData['likesCount'] = likesCount;
          postData['isLikedByCurrentUser'] = isLikedByCurrentUser;

          // Get comments count
          int commentsCount = 0;
          if (postData['comments'] != null) {
            Map<dynamic, dynamic> commentsMap = postData['comments'];
            commentsCount = commentsMap.length;
          }
          postData['commentsCount'] = commentsCount;

          posts.add(postData);
        }
        setState(() {
          _posts = posts;
        });
      });
    }
  }


  Future<void> _onPostTripleTap(String postId) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Post'),
          content: Text('Are you sure you want to delete this post?'),
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
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePost(String postId) async {
    if (_user != null) {
      await _dbRef.child("posts").child(postId).remove();
      Fluttertoast.showToast(msg: "Post deleted successfully", gravity: ToastGravity.BOTTOM);
    }
  }



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
                    selectedImage = File(image.path);
                    Fluttertoast.showToast(msg: "Image selected", gravity: ToastGravity.BOTTOM);
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



  Future<void> _updatePost(String postId, String newContent, File? newImage) async {
    if (_user != null) {
      Map<String, dynamic> updatedData = {"content": newContent};

      if (newImage != null) {
        String path = 'posts/${_user!.uid}/${postId}.jpg';
        TaskSnapshot uploadTask = await _storage.ref(path).putFile(newImage);
        String downloadUrl = await uploadTask.ref.getDownloadURL();
        updatedData['imageUrl'] = downloadUrl;
      }

      await _dbRef.child("posts").child(postId).update(updatedData);
      Fluttertoast.showToast(msg: "Post updated successfully", gravity: ToastGravity.BOTTOM);
    }
  }


  Future<void> _toggleLike(String postId, bool isCurrentlyLiked) async {
    if (_user != null) {
      DatabaseReference likesRef = _dbRef.child("posts").child(postId).child("likes").child(_user!.uid);
      if (isCurrentlyLiked) {
        // Unlike the post
        await likesRef.remove();
      } else {
        // Like the post
        await likesRef.set(true);
      }
    }
  }


  Future<void> _uploadProfileImage(File image) async {
    if (_user != null) {
      try {
        String path = 'users/${_user!.uid}/profile.jpg';
        TaskSnapshot uploadTask = await _storage.ref(path).putFile(image);
        String downloadUrl = await uploadTask.ref.getDownloadURL();

        _dbRef.child("users").child(_user!.uid).update({
          "profileImageUrl": downloadUrl,
        });

        setState(() {
          _profileImageUrl = downloadUrl;
        });

        Fluttertoast.showToast(msg: "Profile image updated successfully", gravity: ToastGravity.BOTTOM);
      } catch (e) {
        Fluttertoast.showToast(msg: "Failed to upload profile image: $e", gravity: ToastGravity.BOTTOM);
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
      _uploadProfileImage(_image!);
    }
  }

  void _viewPostDetails(Map<String, dynamic> post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PostDetailScreen(post: post, currentUser: _user)),
    );
  }

  void _navigateToComments(Map<dynamic, dynamic> post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentScreen(
          postId: post['postId'],
          postOwnerId: post['userId'], // Pass the post owner's ID
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'My Profile',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),


                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        margin: EdgeInsets.only(right: 10,top: 10),
                        child: IconButton(
                          iconSize: 36,
                          icon: Icon(Icons.settings),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SettingsScreen()),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profileImageUrl != null
                    ? NetworkImage(_profileImageUrl!)
                    : AssetImage('assets/profile_placeholder.png') as ImageProvider,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(Icons.camera_alt, size: 24, color: Colors.white),
                ),
              ),
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

            // Padding(
            //   padding: const EdgeInsets.all(16.0),
            //   child: GridView.builder(
            //     physics: NeverScrollableScrollPhysics(),
            //     shrinkWrap: true,
            //     gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            //       crossAxisCount: 3,
            //       crossAxisSpacing: 10,
            //       mainAxisSpacing: 10,
            //       childAspectRatio: 1, // Ensures each grid item is square
            //     ),
            //     itemCount: _posts.length,
            //     itemBuilder: (context, index) {
            //       final post = _posts[index];
            //       return GestureDetector(
            //         onTap: () => _viewPostDetails(post),
            //         child: Container(
            //           decoration: BoxDecoration(
            //             border: Border.all(color: Colors.grey.shade300),
            //             color: Colors.black12,
            //           ),
            //           child: Stack(
            //             fit: StackFit.expand,
            //             children: [
            //               Image.network(
            //                 post['imageUrl'],
            //                 fit: BoxFit.cover,
            //               ),
            //               Positioned(
            //                 bottom: 4,
            //                 left: 4,
            //                 child: Container(
            //                   padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            //                   color: Colors.black54,
            //                   child: Row(
            //                     children: [
            //                       Icon(
            //                         Icons.favorite,
            //                         color: Colors.redAccent,
            //                         size: 16,
            //                       ),
            //                       SizedBox(width: 2),
            //                       Text(
            //                         '${post['likesCount']}',
            //                         style: TextStyle(color: Colors.white, fontSize: 12),
            //                       ),
            //                       SizedBox(width: 8),
            //                       Icon(
            //                         Icons.comment,
            //                         color: Colors.white,
            //                         size: 16,
            //                       ),
            //                       SizedBox(width: 2),
            //                       Text(
            //                         '${post['commentsCount']}',
            //                         style: TextStyle(color: Colors.white, fontSize: 12),
            //                       ),
            //
            //                     ],
            //                   ),
            //                 ),
            //               ),
            //             ],
            //           ),
            //         ),
            //       );
            //     },
            //   ),
            // ),
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
                          ),
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
                                    style: TextStyle(color: Colors.white, fontSize: 12),
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
                                    style: TextStyle(color: Colors.white, fontSize: 12),
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

  Widget _buildRecentActivity() {
    List<Widget> activityWidgets = [];

    for (var post in _posts) {
      // Fetch comments from other users
      if (post['comments'] != null) {
        post['comments'].forEach((commentId, commentData) {
          if (commentData['userId'] != _user!.uid) {
            activityWidgets.add(ListTile(
              leading: Icon(Icons.comment),
              title: Text('User ${commentData['userId']} commented on your post'),
              subtitle: Text(commentData['content']),
              onTap: () => _viewPostDetails(post),
            ));
          }
        });
      }

      // Fetch likes from other users
      if (post['likes'] != null) {
        post['likes'].forEach((userId, _) {
          if (userId != _user!.uid) {
            activityWidgets.add(ListTile(
              leading: Icon(Icons.favorite),
              title: Text('User $userId liked your post'),
              onTap: () => _viewPostDetails(post),
            ));
          }
        });
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: activityWidgets,
    );
  }

}

