import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class PostsSection extends StatefulWidget {
  final DatabaseReference dbRef;
  PostsSection({required this.dbRef});

  @override
  _PostsSectionState createState() => _PostsSectionState();
}

class _PostsSectionState extends State<PostsSection> {
  List<Map<String, dynamic>> postsList = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadPosts();
  }

  void loadPosts() {
    widget.dbRef.child('posts').onValue.listen((event) {
      final data = Map<String, dynamic>.from((event.snapshot.value ?? {}) as Map);
      setState(() {
        postsList = data.entries.map((entry) => Map<String, dynamic>.from(entry.value)).toList();
      });
    });
  }

  Future<void> removePost(String postId) async {
    await widget.dbRef.child('posts').child(postId).remove();
  }

  List<Map<String, dynamic>> filterPosts(String query) {
    return postsList.where((post) {
      final content = post['content'] ?? '';
      final date = post['timestamp'] ?? '';
      return content.contains(query) || date.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: searchController,
          decoration: InputDecoration(labelText: 'Search posts by keywords or date'),
          onChanged: (query) {
            setState(() {
              postsList = filterPosts(query);
            });
          },
        ),
        Expanded(
          child: ListView(
            children: postsList.map((post) {
              return ListTile(
                title: Text(post['content'] ?? 'Post'),
                subtitle: Text('Posted by: ${post['userId']}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => removePost(post['postId']),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
