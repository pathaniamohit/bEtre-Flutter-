// ProfileSection.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'PostDetailScreen.dart';
import 'CommentScreen.dart';
import 'Settings.dart';
import 'dart:async';

class ProfileSection extends StatefulWidget {
  final DatabaseReference dbRef;

  const ProfileSection({Key? key, required this.dbRef}) : super(key: key);

  @override
  _ProfileSectionState createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection> {

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

  /// Toggles like/unlike on a post
  Future<void> _toggleLike(String postId, bool isCurrentlyLiked) async {
    if (_user != null) {
      DatabaseReference likesRef = _dbRef.child("posts").child(postId).child("likes").child(_user!.uid);
      if (isCurrentlyLiked) {
        // Unlike the post
        await likesRef.remove();
        print('Post $postId unliked by user ${_user!.uid}');
      } else {
        // Like the post
        await likesRef.set(true);
        print('Post $postId liked by user ${_user!.uid}');
      }
    }
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
  // ... (All the existing code from ProfileScreen, but remove the Scaffold)

  // Replace the build method to return the content without Scaffold
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
          SizedBox(height: 16),
          Divider(thickness: 1),
          // Recent Activity
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          SizedBox(height: 16),
          Divider(thickness: 1),
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
    );
  }
}
