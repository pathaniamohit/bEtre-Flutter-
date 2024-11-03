// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:fluttertoast/fluttertoast.dart';
//
// import 'PostDetailScreen.dart';
//
// class OtherUserProfileScreen extends StatefulWidget {
//   final String userId;
//
//   OtherUserProfileScreen({required this.userId});
//
//   @override
//   _OtherUserProfileScreenState createState() => _OtherUserProfileScreenState();
// }
//
// class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
//   final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
//
//   String? _profileImageUrl;
//   String _username = "Username";
//   String _email = "Email";
//   int _photosCount = 0;
//   int _followersCount = 0;
//   int _followsCount = 0;
//
//   List<Map<String, dynamic>> _posts = [];
//
//   User? _currentUser;
//   bool _isFollowing = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _currentUser = FirebaseAuth.instance.currentUser;
//     _loadUserProfile();
//     _loadUserStats();
//     _loadUserPosts();
//     _checkIfFollowing();
//   }
//
//   Future<void> _loadUserProfile() async {
//     _dbRef.child("users").child(widget.userId).once().then((snapshot) {
//       if (snapshot.snapshot.exists) {
//         var userData = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
//         setState(() {
//           _username = userData['username'] ?? 'Username';
//           _email = userData['email'] ?? 'Email';
//           _profileImageUrl = userData['profileImageUrl'];
//         });
//       }
//     });
//   }
//
//   Future<void> _loadUserStats() async {
//     _dbRef.child("followers").child(widget.userId).onValue.listen((event) {
//       final dataSnapshot = event.snapshot;
//       setState(() {
//         _followersCount = dataSnapshot.exists ? dataSnapshot.children.length : 0;
//       });
//     });
//
//     _dbRef.child("following").child(widget.userId).onValue.listen((event) {
//       final dataSnapshot = event.snapshot;
//       setState(() {
//         _followsCount = dataSnapshot.exists ? dataSnapshot.children.length : 0;
//       });
//     });
//
//     _dbRef.child("posts").orderByChild("userId").equalTo(widget.userId).onValue.listen((event) {
//       final dataSnapshot = event.snapshot;
//       setState(() {
//         _photosCount = dataSnapshot.exists ? dataSnapshot.children.length : 0;
//       });
//     });
//   }
//
//   Future<void> _loadUserPosts() async {
//     _dbRef.child("posts").orderByChild("userId").equalTo(widget.userId).onValue.listen((event) {
//       List<Map<String, dynamic>> posts = [];
//       for (var post in event.snapshot.children) {
//         var postData = Map<String, dynamic>.from(post.value as Map);
//         postData['postId'] = post.key;
//
//         int likesCount = 0;
//         bool isLikedByCurrentUser = false;
//         if (postData['likes'] != null) {
//           Map<dynamic, dynamic> likesMap = postData['likes'];
//           likesCount = likesMap.length;
//           if (_currentUser != null && likesMap.containsKey(_currentUser!.uid)) {
//             isLikedByCurrentUser = true;
//           }
//         }
//         postData['likesCount'] = likesCount;
//         postData['isLikedByCurrentUser'] = isLikedByCurrentUser;
//
//         int commentsCount = 0;
//         if (postData['comments'] != null) {
//           commentsCount = (postData['comments'] as Map).length;
//         }
//         postData['commentsCount'] = commentsCount;
//
//         posts.add(postData);
//       }
//       setState(() {
//         _posts = posts;
//       });
//     });
//   }
//
//   Future<void> _checkIfFollowing() async {
//     if (_currentUser != null) {
//       _dbRef.child("following").child(_currentUser!.uid).child(widget.userId).once().then((snapshot) {
//         setState(() {
//           _isFollowing = snapshot.snapshot.exists;
//         });
//       });
//     }
//   }
//
//   Future<void> _toggleFollow() async {
//     if (_currentUser != null) {
//       DatabaseReference followingRef = _dbRef.child("following").child(_currentUser!.uid).child(widget.userId);
//       DatabaseReference followersRef = _dbRef.child("followers").child(widget.userId).child(_currentUser!.uid);
//
//       if (_isFollowing) {
//         await followingRef.remove();
//         await followersRef.remove();
//       } else {
//         await followingRef.set(true);
//         await followersRef.set(true);
//       }
//
//       setState(() {
//         _isFollowing = !_isFollowing;
//       });
//     }
//   }
//
//   Future<void> _toggleLike(String postId, bool isCurrentlyLiked) async {
//     if (_currentUser != null) {
//       DatabaseReference likesRef = _dbRef.child("posts").child(postId).child("likes").child(_currentUser!.uid);
//       if (isCurrentlyLiked) {
//         await likesRef.remove();
//       } else {
//         await likesRef.set(true);
//       }
//     }
//   }
//
//   void _viewPostDetails(Map<String, dynamic> post) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => PostDetailScreen(post: post, currentUser: _currentUser)),
//     );
//   }
//
//   void _reportProfile() async {
//     String reportedUserId = widget.userId;
//     String reporterId = _currentUser!.uid;
//
//     DatabaseReference reportRef = FirebaseDatabase.instance.ref().child('reports').push();
//     await reportRef.set({
//       'type': 'profile',
//       'reportedItemId': reportedUserId,
//       'reportedUserId': reportedUserId,
//       'reporterId': reporterId,
//       'timestamp': DateTime.now().millisecondsSinceEpoch,
//       'reason': 'Inappropriate profile',
//     });
//
//     Fluttertoast.showToast(msg: 'Profile reported.');
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_username),
//           actions: [
//       IconButton(
//       icon: Icon(Icons.flag),
//       onPressed: _reportProfile,
//       ),
//           ],
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             SizedBox(height: 16),
//             CircleAvatar(
//               radius: 50,
//               backgroundImage: _profileImageUrl != null
//                   ? NetworkImage(_profileImageUrl!)
//                   : AssetImage('assets/profile_placeholder.png') as ImageProvider,
//             ),
//             SizedBox(height: 8),
//             Text(
//               _username,
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             Text(
//               _email,
//               style: TextStyle(fontSize: 16, color: Colors.grey),
//             ),
//             ElevatedButton(
//               onPressed: _toggleFollow,
//               child: Text(_isFollowing ? 'Unfollow' : 'Follow'),
//             ),
//             Padding(
//               padding: const EdgeInsets.symmetric(vertical: 16.0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   _buildStatItem('Photos', _photosCount.toString()),
//                   _buildStatItem('Followers', _followersCount.toString()),
//                   _buildStatItem('Follows', _followsCount.toString()),
//                 ],
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: GridView.builder(
//                 physics: NeverScrollableScrollPhysics(),
//                 shrinkWrap: true,
//                 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 3,
//                   crossAxisSpacing: 10,
//                   mainAxisSpacing: 10,
//                 ),
//                 itemCount: _posts.length,
//                 itemBuilder: (context, index) {
//                   final post = _posts[index];
//                   return GestureDetector(
//                     onTap: () => _viewPostDetails(post),
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
//                                   Icon(
//                                     Icons.comment,
//                                     color: Colors.white,
//                                     size: 16,
//                                   ),
//                                   SizedBox(width: 2),
//                                   Text(
//                                     '${post['commentsCount']}',
//                                     style: TextStyle(color: Colors.white, fontSize: 12),
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
//
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
// }

//OtherUserProfileScreen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
    }).catchError((e) {
      Fluttertoast.showToast(msg: "Error loading user profile: $e", gravity: ToastGravity.BOTTOM);
    });
  }

  Future<void> _loadUserStats() async {
    _dbRef.child("followers").child(widget.userId).onValue.listen((event) {
      final dataSnapshot = event.snapshot;
      setState(() {
        _followersCount = dataSnapshot.exists ? dataSnapshot.children.length : 0;
      });
    });

    _dbRef.child("following").child(widget.userId).onValue.listen((event) {
      final dataSnapshot = event.snapshot;
      setState(() {
        _followsCount = dataSnapshot.exists ? dataSnapshot.children.length : 0;
      });
    });

    _dbRef.child("posts").orderByChild("userId").equalTo(widget.userId).onValue.listen((event) {
      final dataSnapshot = event.snapshot;
      setState(() {
        _photosCount = dataSnapshot.exists ? dataSnapshot.children.length : 0;
      });
    });
  }

  Future<void> _loadUserPosts() async {
    _dbRef.child("posts").orderByChild("userId").equalTo(widget.userId).onValue.listen((event) {
      List<Map<String, dynamic>> posts = [];
      for (var post in event.snapshot.children) {
        var postData = Map<String, dynamic>.from(post.value as Map);
        postData['postId'] = post.key;

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
    }).onError((error) {
      Fluttertoast.showToast(msg: "Error loading posts: $error", gravity: ToastGravity.BOTTOM);
    });
  }

  Future<void> _checkIfFollowing() async {
    if (_currentUser != null) {
      _dbRef.child("following").child(_currentUser!.uid).child(widget.userId).once().then((snapshot) {
        setState(() {
          _isFollowing = snapshot.snapshot.exists;
        });
      }).catchError((e) {
        Fluttertoast.showToast(msg: "Error checking follow status: $e", gravity: ToastGravity.BOTTOM);
      });
    }
  }

  /// Method to notify a user about follow/unfollow actions
  Future<void> _notifyUser(String userId, String action) async {
    final notificationsRef = FirebaseDatabase.instance.ref().child('notifications').child(userId);
    await notificationsRef.push().set({
      'fromUserId': _currentUser!.uid,
      'action': action, // e.g., 'started following you' or 'unfollowed you'
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _toggleFollow() async {
    if (_currentUser != null) {
      DatabaseReference followingRef = _dbRef.child("following").child(_currentUser!.uid).child(widget.userId);
      DatabaseReference followersRef = _dbRef.child("followers").child(widget.userId).child(_currentUser!.uid);

      try {
        if (_isFollowing) {
          await followingRef.remove();
          await followersRef.remove();
          Fluttertoast.showToast(msg: 'Unfollowed successfully.', gravity: ToastGravity.BOTTOM);

          // Notify the user about the unfollow
          _notifyUser(widget.userId, 'unfollowed you');
        } else {
          await followingRef.set(true);
          await followersRef.set(true);
          Fluttertoast.showToast(msg: 'Followed successfully.', gravity: ToastGravity.BOTTOM);

          // Notify the user about the follow
          _notifyUser(widget.userId, 'started following you');
        }

        setState(() {
          _isFollowing = !_isFollowing;
        });
      } catch (e) {
        Fluttertoast.showToast(msg: "Error toggling follow: $e", gravity: ToastGravity.BOTTOM);
      }
    } else {
      Fluttertoast.showToast(msg: 'You must be logged in to follow/unfollow.', gravity: ToastGravity.BOTTOM);
    }
  }



  Future<void> _toggleLike(String postId, bool isCurrentlyLiked) async {
    if (_currentUser != null) {
      DatabaseReference likesRef = _dbRef.child("posts").child(postId).child("likes").child(_currentUser!.uid);
      try {
        if (isCurrentlyLiked) {
          await likesRef.remove();
          Fluttertoast.showToast(msg: 'Post unliked.', gravity: ToastGravity.BOTTOM);
        } else {
          await likesRef.set(true);
          Fluttertoast.showToast(msg: 'Post liked.', gravity: ToastGravity.BOTTOM);
        }
      } catch (e) {
        Fluttertoast.showToast(msg: "Error toggling like: $e", gravity: ToastGravity.BOTTOM);
      }
    } else {
      Fluttertoast.showToast(msg: 'You must be logged in to like posts.', gravity: ToastGravity.BOTTOM);
    }
  }

  void _viewPostDetails(Map<String, dynamic> post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PostDetailScreen(post: post, currentUser: _currentUser)),
    );
  }

  void _reportProfile() async {
    if (_currentUser == null) {
      Fluttertoast.showToast(msg: 'You must be logged in to report a profile.', gravity: ToastGravity.BOTTOM);
      return;
    }

    String reportedUserId = widget.userId;
    String reporterId = _currentUser!.uid;

    // Prompt user to enter a reason for reporting
    String? reason = await _showReportReasonDialog();
    if (reason == null || reason.trim().isEmpty) {
      Fluttertoast.showToast(msg: 'Report cancelled or no reason provided.', gravity: ToastGravity.BOTTOM);
      return;
    }

    DatabaseReference reportRef = FirebaseDatabase.instance.ref().child('reported_profiles').push();
    try {
      await reportRef.set({
        'type': 'profile',
        'reportedItemId': reportedUserId,
        'reportedUserId': reportedUserId,
        'reporterId': reporterId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'reason': reason.trim(),
      });

      Fluttertoast.showToast(msg: 'Profile reported successfully.', gravity: ToastGravity.BOTTOM);
    } catch (e) {
      Fluttertoast.showToast(msg: "Error reporting profile: $e", gravity: ToastGravity.BOTTOM);
    }
  }

  Future<String?> _showReportReasonDialog() async {
    TextEditingController _reasonController = TextEditingController();
    String? userReason;

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Report Profile'),
          content: TextField(
            controller: _reasonController,
            decoration: InputDecoration(
              hintText: 'Enter reason for reporting',
            ),
            maxLines: 3,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Return null if cancelled
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                userReason = _reasonController.text;
                Navigator.of(context).pop(); // Return the entered reason
              },
              child: Text('Report'),
            ),
          ],
        );
      },
    );

    return userReason;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_username),
        actions: [
          IconButton(
            icon: Icon(Icons.flag),
            onPressed: _reportProfile,
            tooltip: 'Report Profile',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
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
            ElevatedButton(
              onPressed: _toggleFollow,
              child: Text(_isFollowing ? 'Unfollow' : 'Follow'),
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
                            loadingBuilder: (BuildContext context, Widget child,
                                ImageChunkEvent? loadingProgress) {
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
                            errorBuilder: (BuildContext context, Object exception,
                                StackTrace? stackTrace) {
                              return Icon(Icons.error);
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

