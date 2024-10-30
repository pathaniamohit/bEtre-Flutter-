
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'AnalyticsSection.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: DefaultTabController(
        length: 5,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Users'),
                Tab(text: 'Posts'),
                Tab(text: 'Flagged Content'),
                Tab(text: 'Reports'),
                Tab(text: 'Analytics'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  UsersSection(dbRef: dbRef),
                  PostsSection(dbRef: dbRef),
                  FlaggedContentSection(dbRef: dbRef),
                  ReportsSection(dbRef: dbRef),
                  AnalyticsSection(dbRef: dbRef),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}