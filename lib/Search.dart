import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class SearchUserScreen extends StatefulWidget {
  @override
  _SearchUserScreenState createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<dynamic, dynamic>> _users = [];
  List<String> _userImages = []; // List to hold user images
  bool _isLoading = false;

  // Method to search users
  Future<void> _searchUsers() async {
    setState(() {
      _isLoading = true;
      _users = []; // Clear previous results
      _userImages = []; // Clear previous images
    });

    try {
      String query = _searchController.text.trim();
      if (query.isNotEmpty) {
        DatabaseReference userRef = FirebaseDatabase.instance.ref('users');
        DataSnapshot snapshot = await userRef.get();

        // Check if data is present
        if (snapshot.exists) {
          Map<dynamic, dynamic>? userData = snapshot.value as Map<dynamic, dynamic>?;
          print('User data found: $userData'); // Debugging

          if (userData != null) {
            // Filter users based on the search query
            for (MapEntry<dynamic, dynamic> entry in userData.entries) {
              if (entry.value['name'].toString().toLowerCase().contains(query.toLowerCase())) {
                print('User matched: ${entry.value['name']}'); // Debugging
                _users.add(entry.value); // Add matching users

                // Fetch images for the matched user
                await _fetchUserImages(entry.key);
              }
            }
          }
        } else {
          print("No users found in Firebase");
        }
      }
    } catch (e) {
      print("Error searching users: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to fetch user images
  Future<void> _fetchUserImages(String userId) async {
    try {
      DatabaseReference postsRef = FirebaseDatabase.instance.ref('users/$userId/posts');
      DataSnapshot snapshot = await postsRef.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic>? postsData = snapshot.value as Map<dynamic, dynamic>?;
        print('Posts data for $userId: $postsData'); // Debugging

        if (postsData != null) {
          postsData.forEach((key, value) {
            if (value['imageUrl'] != null) {
              _userImages.add(value['imageUrl']); // Add image URLs to the list
              print('Image added: ${value['imageUrl']}'); // Debugging
            }
          });
        }
      } else {
        print('No posts found for user: $userId');
      }
    } catch (e) {
      print("Error fetching user images: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Users'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchUsers,
                ),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : Expanded(
              child: _userImages.isNotEmpty
                  ? GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // Number of columns in grid
                  childAspectRatio: 1, // Aspect ratio for grid items
                ),
                itemCount: _userImages.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: Image.network(
                      _userImages[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(child: Text('Image not found'));
                      },
                    ),
                  );
                },
              )
                  : Center(child: Text('No images found for this user.')),
            ),
          ],
        ),
      ),
    );
  }
}
