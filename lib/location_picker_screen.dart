// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
//
// class LocationPickerScreen extends StatefulWidget {
//   @override
//   _LocationPickerScreenState createState() => _LocationPickerScreenState();
// }
//
// class _LocationPickerScreenState extends State<LocationPickerScreen> {
//   LatLng _initialPosition = LatLng(37.7749, -122.4194); // Default location
//   LatLng? _selectedPosition;
//   GoogleMapController? _mapController;
//   bool _loading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _determinePosition();
//   }
//
//   Future<void> _determinePosition() async {
//     try {
//       Position position = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.high);
//
//       setState(() {
//         _initialPosition = LatLng(position.latitude, position.longitude);
//         _loading = false;
//       });
//     } catch (e) {
//       // If unable to get the user's location, proceed with default location
//       setState(() {
//         _loading = false;
//       });
//       Fluttertoast.showToast(msg: "Could not get current location.");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Select Location'),
//         actions: [
//           TextButton(
//             onPressed: _selectedPosition == null
//                 ? null
//                 : () {
//               Navigator.pop(context, _selectedPosition);
//             },
//             child: Text(
//               'Done',
//               style: TextStyle(
//                   color: _selectedPosition != null ? Colors.white : Colors.grey),
//             ),
//           ),
//         ],
//       ),
//       body: _loading
//           ? Center(child: CircularProgressIndicator())
//           : GoogleMap(
//         initialCameraPosition: CameraPosition(
//           target: _initialPosition,
//           zoom: 14.0,
//         ),
//         onMapCreated: (controller) {
//           _mapController = controller;
//         },
//         onTap: (position) {
//           setState(() {
//             _selectedPosition = position;
//           });
//         },
//         markers: _selectedPosition != null
//             ? {
//           Marker(
//             markerId: MarkerId('selected_location'),
//             position: _selectedPosition!,
//           ),
//         }
//             : {},
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class LocationPickerScreen extends StatefulWidget {
  @override
  _LocationPickerScreenState createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng _initialPosition = LatLng(37.7749, -122.4194);
  LatLng? _selectedPosition;
  GoogleMapController? _mapController;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: "Location services are disabled.");
      setState(() {
        _loading = false;
      });
      return;
    }

    // Check for permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(
          msg: "Location permissions are permanently denied.");
      setState(() {
        _loading = false;
      });
      return;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        Fluttertoast.showToast(msg: "Location permissions are denied.");
        setState(() {
          _loading = false;
        });
        return;
      }
    }

    // Get current location
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _initialPosition = LatLng(position.latitude, position.longitude);
        _loading = false;
      });
    } catch (e) {
      // If unable to get the user's location, proceed with default location
      setState(() {
        _loading = false;
      });
      Fluttertoast.showToast(msg: "Could not get current location.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Location'),
        actions: [
          TextButton(
            onPressed: _selectedPosition == null
                ? null
                : () {
              Navigator.pop(context, _selectedPosition);
            },
            child: Text(
              'Done',
              style: TextStyle(
                  color: _selectedPosition != null ? Colors.white : Colors.grey),
            ),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 14.0,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
        },
        myLocationEnabled: true, // Show current location
        myLocationButtonEnabled: true,
        onTap: (position) {
          setState(() {
            _selectedPosition = position;
          });
        },
        markers: _selectedPosition != null
            ? {
          Marker(
            markerId: MarkerId('selected_location'),
            position: _selectedPosition!,
          ),
        }
            : {},
      ),
    );
  }
}
