import 'package:flutter/material.dart';
import 'Explore.dart';
import 'Search.dart';
import 'Create.dart';
import 'Inbox.dart';
import 'Profile.dart';

class MaisonScreen extends StatefulWidget {
  const MaisonScreen({super.key});

  @override
  _MaisonScreenState createState() => _MaisonScreenState();
}

class _MaisonScreenState extends State<MaisonScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = <Widget>[
    ExploreScreen(),
    SearchScreen(),
    CreateScreen(),
    InboxScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox),
            label: 'Inbox',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
