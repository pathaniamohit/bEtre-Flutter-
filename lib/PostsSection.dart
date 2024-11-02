import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';

class PostsSection extends StatefulWidget {
  final DatabaseReference dbRef;
  final bool isModerator;

  PostsSection({required this.dbRef, this.isModerator = false});

  @override
  _PostsSectionState createState() => _PostsSectionState();
}

class _PostsSectionState extends State<PostsSection> {
  List<Map<String, dynamic>> postsList = [];
  Map<String, Map<String, String>> usersCache = {};
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadPosts();
  }

  void loadPosts() {
    widget.dbRef.child('posts').onValue.listen((event) async {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        List<Map<String, dynamic>> tempPostsList = [];
        for (var entry in data.entries) {
          final postData = Map<String, dynamic>.from(entry.value as Map<dynamic, dynamic>);
          postData['postId'] = entry.key.toString();
          final userId = postData['userId'];

          if (userId != null) {
            if (!usersCache.containsKey(userId)) {
              final userDetails = await getUserDetails(userId);
              usersCache[userId] = userDetails;
            }
            postData['username'] = usersCache[userId]?['username'] ?? 'Unknown User';
            postData['email'] = usersCache[userId]?['email'] ?? 'No Email';
          }

          tempPostsList.add(postData);
        }
        setState(() {
          postsList = tempPostsList;
        });
      } else {
        setState(() {
          postsList = [];
        });
      }
    });
  }

  Future<Map<String, String>> getUserDetails(String userId) async {
    final snapshot = await widget.dbRef.child('users').child(userId).get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
      return {
        'username': data['username'] ?? 'Unknown User',
        'email': data['email'] ?? 'No Email',
      };
    }
    return {'username': 'Unknown User', 'email': 'No Email'};
  }

  Future<void> removePost(String postId) async {
    await widget.dbRef.child('posts').child(postId).remove();
  }

  Future<void> updatePost(String postId, String newContent, String? newImageUrl) async {
    Map<String, dynamic> updatedData = {'content': newContent};
    if (newImageUrl != null) {
      updatedData['imageUrl'] = newImageUrl;
    }
    await widget.dbRef.child('posts').child(postId).update(updatedData);
  }

  Future<String?> uploadImage(File image) async {
    final storageRef = FirebaseStorage.instance.ref().child('post_images/${DateTime.now().toIso8601String()}');
    final uploadTask = storageRef.putFile(image);
    final snapshot = await uploadTask.whenComplete(() {});
    return await snapshot.ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: postsList.length,
        itemBuilder: (context, index) {
          final post = postsList[index];
          final imageUrl = post['imageUrl'] as String?;
          final username = post['username'] ?? 'Unknown User';
          final email = post['email'] ?? 'No Email';

          return Card(
            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
                    )
                  else
                    Container(
                      height: 150,
                      color: Colors.grey[300],
                      child: Icon(Icons.image, size: 50, color: Colors.grey[700]),
                    ),
                  SizedBox(height: 8.0),
                  Text(
                    post['content'] ?? 'No content',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    'Posted by: $username',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    'Email: $email',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!widget.isModerator)
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: Colors.blue,
                          ),
                          onPressed: () {
                            showEditDialog(post);
                          },
                        ),
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () async {
                          final confirmDelete = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text("Confirm Deletion"),
                                content: Text("Are you sure you want to delete this post?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: Text("Delete"),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirmDelete == true) {
                            await removePost(post['postId']);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void showEditDialog(Map<String, dynamic> post) {
    TextEditingController contentController = TextEditingController(text: post['content']);
    File? newImageFile;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Post"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: contentController,
                decoration: InputDecoration(labelText: 'Content'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      newImageFile = File(pickedFile.path);
                    });
                  }
                },
                child: Text("Change Image"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                String? newImageUrl;
                if (newImageFile != null) {
                  newImageUrl = await uploadImage(newImageFile!);
                }
                await updatePost(post['postId'], contentController.text, newImageUrl);
                Fluttertoast.showToast(
                  msg: "Post updated successfully!",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  timeInSecForIosWeb: 1,
                );
                Navigator.of(context).pop();
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }
}
