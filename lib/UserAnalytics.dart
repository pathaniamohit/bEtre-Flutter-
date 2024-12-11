import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserAnalytics extends StatefulWidget {
  final String userId;

  UserAnalytics({required this.userId});

  @override
  _UserAnalyticsState createState() => _UserAnalyticsState();
}

class _UserAnalyticsState extends State<UserAnalytics> {
  final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
  final FirebaseStorage storageReference = FirebaseStorage.instance;

  String? username;
  String? email;
  String? profilePictureUrl;
  int followersCount = 0;
  int followingCount = 0;
  int likesCount = 0;
  int postsCount = 0;
  int commentsCount = 0;
  int commentsCountGot = 0;

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
    fetchFollowersCount();
    fetchFollowingCount();
    fetchUserLikesCount();
    fetchUserPostsCount();
    fetchUserCommentsCount();
    fetchUserCommentsCountGot(widget.userId);
  }

  Future<void> fetchUserCommentsCountGot(String selectedUserId) async {
    DatabaseReference commentsRef = FirebaseDatabase.instance.ref("comments");
    DatabaseReference postsRef = FirebaseDatabase.instance.ref("posts");

    int tempCommentsCount = 0;

    try {
      final commentsSnapshot = await commentsRef.get();

      if (commentsSnapshot.exists) {
        final commentsData = commentsSnapshot.value as Map<dynamic, dynamic>;

        for (var commentEntry in commentsData.entries) {
          final postId = commentEntry.value["post_Id"];

          if (postId != null) {
            final postSnapshot = await postsRef.child(postId).get();

            if (postSnapshot.exists) {
              final postData = postSnapshot.value as Map<dynamic, dynamic>;
              final postUserId = postData["userId"];

              if (postUserId == selectedUserId) {
                tempCommentsCount++;
              }
            }
          }
        }

        setState(() {
          commentsCountGot = tempCommentsCount;
        });

        debugPrint("Total matching comments: $commentsCountGot");
      } else {
        debugPrint("No comments data found.");
        setState(() {
          commentsCountGot = 0;
        });
      }
    } catch (error) {
      debugPrint("Error fetching user comments count: $error");
      setState(() {
        commentsCountGot = 0;
      });
    }
  }

  Future<void> fetchUserDetails() async {
    try {
      debugPrint("Fetching details for userId: ${widget.userId}");

      final snapshot = await databaseReference.child("users").child(widget.userId).once();

      if (snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>;

        debugPrint("User details fetched: $data");

        setState(() {
          username = data["username"] ?? "N/A";
          email = data["email"] ?? "N/A";
        });

        final profilePicturePath = data["profilePicturePath"] ?? "";

        debugPrint("Profile picture path from database: $profilePicturePath");

        if (profilePicturePath.isEmpty) {
          fetchProfilePictureFromStorageDirectly(widget.userId);
        } else {
          fetchProfilePictureFromStorage(profilePicturePath);
        }
      } else {
        debugPrint("No data found for userId: ${widget.userId}");
      }
    } catch (error) {
      debugPrint("Error fetching user details: $error");
    }
  }

  Future<void> fetchProfilePictureFromStorage(String profilePicturePath) async {
    try {
      debugPrint("Fetching profile picture from path: $profilePicturePath");

      final url = await storageReference.ref(profilePicturePath).getDownloadURL();

      debugPrint("Profile picture URL fetched successfully: $url");

      setState(() {
        profilePictureUrl = url;
      });
    } catch (e) {
      debugPrint("Error fetching profile picture: $e");
    }
  }

  Future<void> fetchProfilePictureFromStorageDirectly(String userId) async {
    try {
      debugPrint("Fetching profile picture directly for userId: $userId");

      final storagePath = 'users/$userId/profile.jpg';

      final url = await FirebaseStorage.instance.ref().child(storagePath).getDownloadURL();

      debugPrint("Direct profile picture URL fetched successfully: $url");

      setState(() {
        profilePictureUrl = url;
      });
    } catch (e) {
      debugPrint("Error fetching profile picture directly: $e");
    }
  }

  Future<void> fetchFollowersCount() async {
    try {
      final snapshot = await databaseReference.child("followers").child(widget.userId).once();

      setState(() {
        if (snapshot.snapshot.value != null) {
          final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;
          followersCount = data?.length ?? 0;
        } else {
          followersCount = 0;
        }
      });
    } catch (error) {
      debugPrint("Error fetching followers count: $error");
    }
  }


  Future<void> fetchFollowingCount() async {
    try {
      final snapshot = await databaseReference.child("following").child(widget.userId).once();

      setState(() {
        if (snapshot.snapshot.value != null) {
          final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;
          followingCount = data?.length ?? 0;
        } else {
          followingCount = 0;
        }
      });
    } catch (error) {
      debugPrint("Error fetching following count: $error");
    }
  }


  Future<void> fetchUserLikesCount() async {
    databaseReference.child("likes").once().then((snapshot) {
      int count = 0;
      if (snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          if (value["ownerId"] == widget.userId) count++;
        });
      }
      setState(() {
        likesCount = count;
      });
    }).catchError((error) {
      debugPrint("Error fetching likes count: $error");
    });
  }

  Future<void> fetchUserPostsCount() async {
    databaseReference.child("posts").once().then((snapshot) {
      int count = 0;
      if (snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          if (value["userId"] == widget.userId) count++;
        });
      }
      setState(() {
        postsCount = count;
      });
    }).catchError((error) {
      debugPrint("Error fetching posts count: $error");
    });
  }

  Future<void> fetchUserCommentsCount() async {
    databaseReference.child("comments").once().then((snapshot) {
      int count = 0;
      if (snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          if (value["userId"] == widget.userId) count++;
        });
      }
      setState(() {
        commentsCount = count;
      });
    }).catchError((error) {
      debugPrint("Error fetching comments count: $error");
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  "Data Analytics",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: profilePictureUrl != null
                          ? CachedNetworkImageProvider(profilePictureUrl!)
                          : const AssetImage("assets/profile_placeholder.png") as ImageProvider,
                      backgroundColor: Colors.grey[300],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      username ?? "N/A",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      email ?? "N/A",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildAnalyticsCard(title: "Total Posts", value: postsCount.toString()),
              _buildAnalyticsCard(title: "Total Likes", value: likesCount.toString()),
              _buildAnalyticsCard(title: "Total Comments (he made)", value: commentsCount.toString()),
              _buildAnalyticsCard(title: "Total Comments (he recieved)", value: commentsCountGot.toString()),
              _buildAnalyticsCard(title: "Total Followers", value: followersCount.toString()),
              _buildAnalyticsCard(title: "Total Followings", value: followingCount.toString()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard({required String title, required String value}) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
