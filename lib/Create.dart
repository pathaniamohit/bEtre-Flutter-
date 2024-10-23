import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:geocoding/geocoding.dart';

const kGoogleApiKey = "AIzaSyDCjCxf0f11NcCZVrR5XZLxT_xrNdmO7-8";
GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);

class CreateScreen extends StatefulWidget {
  @override
  _CreateScreenState createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('posts');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? _user;
  String? _profileImageUrl;
  String _username = "Username";
  File? _selectedImage;
  String _selectedLocation = "";
  LatLng? _selectedLatLng; // Store selected latitude and longitude
  final _postContentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    if (_user != null) {
      _loadUserProfile();
    }
  }

  Future<void> _loadUserProfile() async {
    if (_user != null) {
      try {
        DataSnapshot snapshot = await _dbRef.child("users").child(_user!.uid).get();
        if (snapshot.exists) {
          var userData = Map<String, dynamic>.from(snapshot.value as Map);
          setState(() {
            _username = userData['username'] ?? 'Username';
            _profileImageUrl = userData['profileImageUrl'];
          });
        }
      } catch (error) {
        Fluttertoast.showToast(msg: "Error loading profile: $error");
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    } else {
      Fluttertoast.showToast(msg: "No image selected");
    }
  }

  Future<void> _showLocationDialog() async {
    try {
      // Add a loading indicator or print logs to debug the location dialog
      print('Location search started');
      Prediction? prediction = await PlacesAutocomplete.show(
        context: context,
        apiKey: kGoogleApiKey,
        mode: Mode.overlay,
        language: "en",
        components: [Component(Component.country, "us")], // Change "us" to your country if needed
      );

      if (prediction != null) {
        print('Place selected: ${prediction.description}');
        PlacesDetailsResponse detail = await _places.getDetailsByPlaceId(prediction.placeId!);
        double lat = detail.result.geometry!.location.lat;
        double lng = detail.result.geometry!.location.lng;

        setState(() {
          _selectedLocation = prediction.description!;
          _selectedLatLng = LatLng(lat, lng);
        });
      }
    } catch (error) {
      print('Error in location selection: $error');
      Fluttertoast.showToast(msg: "Error selecting location: $error");
    }
  }

  Future<String> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return "${place.locality}, ${place.administrativeArea}, ${place.country}";
      }
    } catch (error) {
      Fluttertoast.showToast(msg: "Error getting address: $error");
    }
    return "Unknown location";
  }

  Future<void> _createPost() async {
    String content = _postContentController.text.trim();

    if (content.isEmpty) {
      Fluttertoast.showToast(msg: "Content cannot be empty");
      return;
    }

    if (_selectedImage == null) {
      Fluttertoast.showToast(msg: "Please select an image");
      return;
    }

    if (_selectedLatLng == null) {
      Fluttertoast.showToast(msg: "Please add a location");
      return;
    }

    try {
      String userId = _user!.uid;
      String fileName = 'posts/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload image to Firebase Storage
      TaskSnapshot uploadTask = await _storage.ref(fileName).putFile(_selectedImage!);
      String downloadUrl = await uploadTask.ref.getDownloadURL();

      // Get a readable address from the LatLng
      String address = await _getAddressFromLatLng(_selectedLatLng!);

      // Create post data
      Map<String, dynamic> postData = {
        'userId': userId,
        'username': _username,
        'content': content,
        'location': address,
        'imageUrl': downloadUrl,
        'latitude': _selectedLatLng!.latitude,
        'longitude': _selectedLatLng!.longitude,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await _dbRef.push().set(postData);
      Fluttertoast.showToast(msg: "Post created successfully");
      _resetFields();

    } catch (error) {
      Fluttertoast.showToast(msg: "Failed to create post: $error");
    }
  }

  void _resetFields() {
    setState(() {
      _postContentController.clear();
      _selectedImage = null;
      _selectedLocation = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Create Post', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : AssetImage('assets/profile_placeholder.png') as ImageProvider,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _username,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _postContentController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: "What's on your mind?",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: _pickImage,
                    child: Row(
                      children: [
                        Icon(Icons.image, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Select Image',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _showLocationDialog,
                    child: Row(
                      children: [
                        Icon(Icons.location_on, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Add Location',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetFields,
                    child: Text('Discard', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _createPost,
                    child: Text('Post', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
