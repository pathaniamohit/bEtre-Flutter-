import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'ProfileAdmin.dart';
import 'FlaggedContentSection.dart';
import 'PostsSection.dart';
import 'ReportsSection.dart';
import 'UsersSection.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
  int _selectedIndex = 0; // Track the currently selected index

  // List of pages for each section
  late final List<Widget> _sections;

  @override
  void initState() {
    super.initState();
    _sections = [
      UsersSection(dbRef: dbRef),
      PostsSection(dbRef: dbRef),
      FlaggedContentSection(dbRef: dbRef),
      ReportsSection(dbRef: dbRef),
      ProfileAdmin(dbRef: dbRef),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      // Use IndexedStack to maintain the state of each tab
      body: IndexedStack(
        index: _selectedIndex,
        children: _sections,
      ),
      // Define the BottomNavigationBar with custom colors
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blueGrey.shade900, // Dark background for contrast
        selectedItemColor: Colors.orangeAccent, // Color for selected tab icons and text
        unselectedItemColor: Colors.white, // Color for unselected tab icons and text
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Ensures all items are visible
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.post_add),
            label: 'Posts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag),
            label: 'Flagged Content',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
