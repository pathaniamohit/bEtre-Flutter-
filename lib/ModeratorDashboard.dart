import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'PostsModSection.dart';
import 'ReportsSection.dart';
import 'ProfileModSection.dart';
import 'AnalyticsModSection.dart';

class ModeratorDashboard extends StatefulWidget {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

  ModeratorDashboard({Key? key}) : super(key: key);

  @override
  _ModeratorDashboardState createState() => _ModeratorDashboardState();
}

class _ModeratorDashboardState extends State<ModeratorDashboard> {
  int _selectedIndex = 0; // Track the selected index for bottom navigation bar

  // List of widgets for each tab
  final List<Widget> _sections = [];

  @override
  void initState() {
    super.initState();
    _sections.addAll([
      PostsModSection(dbRef: widget.dbRef),
      AnalyticsModSection(dbRef: widget.dbRef),
      ReportsSection(dbRef: widget.dbRef),
      ProfileModSection(dbRef: widget.dbRef),
    ]);
  }

  // Method to handle bottom navigation bar item taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Moderator Dashboard"),
      ),
      body: _sections[_selectedIndex], // Display the selected section
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.blueGrey.shade900, // Dark background for contrast
        selectedItemColor: Colors.orangeAccent, // Color for selected tab icons and text
        unselectedItemColor: Colors.white, // Color for unselected tab icons and text
        type: BottomNavigationBarType.fixed, // Ensures all items are visible
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.post_add),
            label: "Posts",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: "Analytics",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: "Reports",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
