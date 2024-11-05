import 'package:betreflutter/Settings.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ProfileAdmin extends StatefulWidget {
  @override
  _ProfileAdminState createState() => _ProfileAdminState();
}

class _ProfileAdminState extends State<ProfileAdmin> {
  final DatabaseReference databaseRef = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int suspendedCount = 0;
  int activeCount = 0;
  int totalPosts = 0;
  int totalUsers = 0;
  int totalLikes = 0;
  int totalComments = 0;
  int totalModerators = 0;
  int uniqueReportedUsers = 0;
  int reportedPosts = 0;
  int reportedComments = 0;
  int reportedProfiles = 0;
  double malePercentage = 0;
  double femalePercentage = 0;
  String username = "Username";
  String email = "Email";
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    fetchData();
    fetchUserProfile();
    fetchTotalReportedUsers();
    fetchReportedData();
  }

  void fetchData() {
    fetchUserSuspensionData();
    fetchGenderData();
    fetchTotalUsers();
    fetchTotalPosts();
    fetchTotalLikes();
    fetchTotalComments();
    fetchTotalModerators();
  }

  Future<void> fetchUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      databaseRef.child("users").child(user.uid).once().then((snapshot) {
        if (snapshot.snapshot.exists) {
          var userData = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
          setState(() {
            username = userData['username'] ?? 'Username';
            email = userData['email'] ?? 'Email';
            profileImageUrl = userData['profileImageUrl'];
          });
        }
      });
    }
  }

  Future<void> fetchTotalReportedUsers() async {
    Set<String> uniqueReportedUserIds = {};

    // Fetch reported users from "reports" node
    await databaseRef.child("reports").get().then((snapshot) {
      for (var report in snapshot.children) {
        String? reportedUserId = report.child("reportedBy").value as String?;
        if (reportedUserId != null) {
          uniqueReportedUserIds.add(reportedUserId);
        }
      }
    });

    // Fetch reported users from "report_comments" node
    await databaseRef.child("report_comments").get().then((snapshot) {
      for (var report in snapshot.children) {
        String? reportedUserId = report.child("reportedCommentUserId").value as String?;
        if (reportedUserId != null) {
          uniqueReportedUserIds.add(reportedUserId);
        }
      }
    });

    // Fetch reported users from "reported_profiles" node
    await databaseRef.child("reported_profiles").get().then((snapshot) {
      for (var report in snapshot.children) {
        String? reportedUserId = report.child("reportedUserId").value as String?;
        if (reportedUserId != null) {
          uniqueReportedUserIds.add(reportedUserId);
        }
      }
    });

    // Validate each unique reported user ID
    int validReportedUserCount = 0;
    for (String userId in uniqueReportedUserIds) {
      final snapshot = await databaseRef.child("users").child(userId).get();
      if (snapshot.exists) {
        validReportedUserCount++;
      }
    }

    setState(() {
      uniqueReportedUsers = validReportedUserCount;
    });
  }

  Future<void> fetchUserSuspensionData() async {
    databaseRef.child("users").onValue.listen((DatabaseEvent event) {
      int suspended = 0;
      int active = 0;
      for (var user in event.snapshot.children) {
        bool isSuspended = user.child("suspended").value as bool? ?? false;
        if (isSuspended) {
          suspended++;
        } else {
          active++;
        }
      }
      setState(() {
        suspendedCount = suspended;
        activeCount = active;
      });
    });
  }

  Future<void> fetchReportedData() async {
    int postReports = 0;
    int commentReports = 0;
    int profileReports = 0;

    // Fetch reported posts
    await databaseRef.child("reports").get().then((snapshot) {
      for (var report in snapshot.children) {
        String? type = report.child("type").value as String?;
          postReports++;

      }
    });

    // Fetch reported comments
    await databaseRef.child("report_comments").get().then((snapshot) {
      commentReports = snapshot.children.length;
    });

    // Fetch reported profiles
    await databaseRef.child("reported_profiles").get().then((snapshot) {
      profileReports = snapshot.children.length;
    });

    setState(() {
      reportedPosts = postReports;
      reportedComments = commentReports;
      reportedProfiles = profileReports;
    });
  }

  Future<void> fetchGenderData() async {
    databaseRef.child("users").onValue.listen((DatabaseEvent event) {
      int maleCount = 0;
      int femaleCount = 0;
      for (var user in event.snapshot.children) {
        String gender = user.child("gender").value as String? ?? "";
        if (gender.toLowerCase() == "male") {
          maleCount++;
        } else if (gender.toLowerCase() == "female") {
          femaleCount++;
        }
      }
      int total = maleCount + femaleCount;
      setState(() {
        malePercentage = total > 0 ? (maleCount / total) * 100 : 0;
        femalePercentage = total > 0 ? (femaleCount / total) * 100 : 0;
      });
    });
  }

  Future<void> fetchTotalUsers() async {
    databaseRef.child("users").onValue.listen((DatabaseEvent event) {
      int userCount = 0;

      for (var user in event.snapshot.children) {
        String? role = user.child("role").value as String?;
        String? email = user.child("email").value as String?;

        if (role != "admin" && role != "moderator" && email != null && email.isNotEmpty) {
          userCount++;
        }
      }

      setState(() {
        totalUsers = userCount;
      });
    });
  }


  Future<void> fetchTotalPosts() async {
    databaseRef.child("posts").onValue.listen((DatabaseEvent event) {
      setState(() {
        totalPosts = event.snapshot.children.length;
      });
    });
  }

  Future<void> fetchTotalLikes() async {
    databaseRef.child("likes").onValue.listen((DatabaseEvent event) {
      int likesCount = 0;
      for (var post in event.snapshot.children) {
        likesCount += post.child("users").children.length;
      }
      setState(() {
        totalLikes = likesCount;
      });
    });
  }

  Future<void> fetchTotalComments() async {
    databaseRef.child("comments").onValue.listen((DatabaseEvent event) {
      setState(() {
        totalComments = event.snapshot.children.length;
      });
    });
  }

  Future<void> fetchTotalModerators() async {
    databaseRef.child("users").onValue.listen((DatabaseEvent event) {
      int moderatorCount = 0;
      for (var user in event.snapshot.children) {
        String? role = user.child("role").value as String?;
        if (role == "moderator") {
          moderatorCount++;
        }
      }
      setState(() {
        totalModerators = moderatorCount;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(profileImageUrl!)
                        : AssetImage('assets/profile_placeholder.png') as ImageProvider,
                  ),
                  SizedBox(height: 8),
                  Text(username, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(email, style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Stats Cards Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  StatsCard(title: "Total Users", value: totalUsers, color: Colors.blue),
                  StatsCard(title: "Total Posts", value: totalPosts, color: Colors.green),
                  StatsCard(title: "Total Likes", value: totalLikes, color: Colors.orange),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  StatsCard(title: "Total Comments", value: totalComments, color: Colors.purple),
                  StatsCard(title: "Reported Users", value: uniqueReportedUsers, color: Colors.red),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Suspended vs Active Users Pie Chart
            Text("Suspended vs Active Users", textAlign: TextAlign.center),
            SfCircularChart(
              series: <CircularSeries>[
                PieSeries<_ChartData, String>(
                  dataSource: [
                    _ChartData('Suspended', suspendedCount.toDouble()),
                    _ChartData('Active', activeCount.toDouble()),
                  ],
                  xValueMapper: (_ChartData data, _) => data.label,
                  yValueMapper: (_ChartData data, _) => data.value,
                  dataLabelSettings: DataLabelSettings(isVisible: true),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Reported Data Overview Bar Chart
            Text("Reported Data Overview", textAlign: TextAlign.center),
            SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              series: <ChartSeries>[
                ColumnSeries<_ChartData, String>(
                  dataSource: [
                    _ChartData('Posts', reportedPosts.toDouble()),
                    _ChartData('Comments', reportedComments.toDouble()),
                    _ChartData('Profiles', reportedProfiles.toDouble()),
                  ],
                  xValueMapper: (_ChartData data, _) => data.label,
                  yValueMapper: (_ChartData data, _) => data.value,
                  dataLabelSettings: DataLabelSettings(isVisible: true),
                  color: Colors.purpleAccent,
                ),
              ],
            ),
            SizedBox(height: 20),
            // Gender Distribution Pie Chart
            Text("Gender Distribution", textAlign: TextAlign.center),
            SfCircularChart(
              series: <CircularSeries>[
                PieSeries<_ChartData, String>(
                  dataSource: [
                    _ChartData('Male', malePercentage),
                    _ChartData('Female', femalePercentage),
                  ],
                  xValueMapper: (_ChartData data, _) => data.label,
                  yValueMapper: (_ChartData data, _) => data.value,
                  dataLabelSettings: DataLabelSettings(isVisible: true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Stats Card for displaying key metrics
class StatsCard extends StatelessWidget {
  final String title;
  final int value;
  final Color color;

  StatsCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(title, style: TextStyle(fontSize: 16, color: Colors.grey)),
              SizedBox(height: 8),
              Text("$value", style: TextStyle(fontSize: 24, color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartData {
  _ChartData(this.label, this.value);
  final String label;
  final double value;
}
