import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'PostsSection.dart';
import 'ReportsSection.dart';

class ModeratorDashboard extends StatelessWidget {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();


  ModeratorDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Moderator Dashboard"),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: "Posts"),
                Tab(text: "Reports"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  PostsSection(dbRef: dbRef),
                  ReportsSection(dbRef: dbRef),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
