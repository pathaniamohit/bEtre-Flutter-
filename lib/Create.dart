import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:geocoding/geocoding.dart';

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
  String? _selectedLocationName;
  LatLng? _selectedLatLng;
  String? _locationLink;
  final _postContentController = TextEditingController();
  GoogleMapController? _mapController;
  final String googleApiKey = 'AIzaSyDCjCxf0f11NcCZVrR5XZLxT_xrNdmO7-8';
  final GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: 'AIzaSyDCjCxf0f11NcCZVrR5XZLxT_xrNdmO7-8');

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
        DataSnapshot snapshot = await FirebaseDatabase.instance
            .ref()
            .child("users")
            .child(_user!.uid)
            .get();
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

  Future<void> _selectLocation() async {
    try {
      Prediction? prediction = await PlacesAutocomplete.show(
        context: context,
        apiKey: googleApiKey,
        mode: Mode.overlay,
        types: [],
        strictbounds: false,
        components: [Component(Component.country, "us")], // Adjust country as needed
      );

      if (prediction != null) {
        PlacesDetailsResponse details = await _places.getDetailsByPlaceId(prediction.placeId!);

        if (details.status == "OK") {
          final lat = details.result.geometry!.location.lat;
          final lng = details.result.geometry!.location.lng;

          setState(() {
            _selectedLatLng = LatLng(lat, lng);
            _selectedLocation = details.result.formattedAddress ?? "Selected Location";
            _selectedLocationName = details.result.name ?? details.result.formattedAddress;
            _locationLink = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
          });

          // Move the map to the selected location
          _mapController?.animateCamera(CameraUpdate.newLatLng(_selectedLatLng!));
        } else {
          print("Error fetching place details: ${details.errorMessage}");
          Fluttertoast.showToast(msg: "Failed to retrieve location details.");
        }
      }
    } catch (error) {
      print("Error selecting location: $error");
      Fluttertoast.showToast(msg: "Error selecting location: $error");
    }
  }

  Future<void> _createPost() async {
    if (_user == null) {
      Fluttertoast.showToast(msg: "User not authenticated");
      return;
    }

    String content = _postContentController.text.trim();

    if (_selectedImage == null) {
      Fluttertoast.showToast(msg: "Please select an image");
      return;
    }

    try {
      String userId = _user!.uid;
      String imageId = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      String filePath = 'post_images/$imageId';

      SettableMetadata metadata = SettableMetadata(customMetadata: {
        'userId': userId,
      });

      UploadTask uploadTask = _storage.ref(filePath).putFile(_selectedImage!, metadata);
      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      Map<String, dynamic> postData = {
        'userId': userId,
        'username': _username,
        'imageUrl': downloadUrl,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      if (content.isNotEmpty) {
        postData['content'] = content;
      }

      if (_selectedLatLng != null) {
        postData['location'] = _locationLink;
        postData['latitude'] = _selectedLatLng!.latitude;
        postData['longitude'] = _selectedLatLng!.longitude;
        postData['address'] = _selectedLocation; // Full address
        postData['locationName'] = _selectedLocationName;
      }

      await _dbRef.push().set(postData).then((_) {
        print('Post created successfully under posts node');
        Fluttertoast.showToast(msg: "Post created successfully");
        _resetFields();
      }).catchError((error) {
        print('Error creating post: $error');
        Fluttertoast.showToast(msg: "Failed to create post: $error");
      });
    } catch (error) {
      print("Error creating post: $error");
      Fluttertoast.showToast(msg: "Failed to create post: $error");
    }
  }



  void _resetFields() {
    setState(() {
      _postContentController.clear();
      _selectedImage = null;
      _selectedLocation = "";
      _selectedLatLng = null;
      _locationLink = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Post',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
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
                            : AssetImage('assets/profile_placeholder.png')
                        as ImageProvider,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _username,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_selectedImage != null)
                    Center(
                      child: Image.file(
                        _selectedImage!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _postContentController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: "Write a caption...",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedLocation.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedLocation,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
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
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.image, color: Colors.blue, size: 28),
                  onPressed: _pickImage,
                ),
                IconButton(
                  icon: Icon(Icons.location_on, color: Colors.red, size: 28),
                  onPressed: _selectLocation,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
