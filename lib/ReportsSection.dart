import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ReportsSection extends StatefulWidget {
  final DatabaseReference dbRef;

  ReportsSection({Key? key, required this.dbRef}) : super(key: key);

  @override
  _ReportsSectionState createState() => _ReportsSectionState();
}

class _ReportsSectionState extends State<ReportsSection> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  List<Report> reports = [];

  @override
  void initState() {
    super.initState();
    loadReports();
  }

  void loadReports() {
    widget.dbRef.child("reports").onValue.listen((event) {
      List<Report> loadedReports = [];
      for (var snapshot in event.snapshot.children) {
        loadedReports.add(Report.fromSnapshot(snapshot, "post"));
      }
      setState(() {
        reports = loadedReports;
      });
    });

    // Load comment reports
    widget.dbRef.child("report_comments").onValue.listen((event) {
      for (var snapshot in event.snapshot.children) {
        setState(() {
          reports.add(Report.fromSnapshot(snapshot, "comment"));
        });
      }
    });

    // Load profile reports
    widget.dbRef.child("reported_profiles").onValue.listen((event) {
      for (var snapshot in event.snapshot.children) {
        setState(() {
          reports.add(Report.fromSnapshot(snapshot, "profile"));
        });
      }
    });
  }

  void handleDelete(Report report) async {
    await widget.dbRef.child("reports").child(report.id).remove();
    Fluttertoast.showToast(msg: "Report deleted.");
    loadReports(); // Refresh reports after deletion
  }

  void handleWarning(Report report) async {
    String userId = report.reportedBy!;
    String warningId = widget.dbRef.child("warnings").child(userId).push().key!;
    await widget.dbRef.child("warnings").child(userId).child(warningId).set({
      "userId": userId,
      "reason": report.reason,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    });
    Fluttertoast.showToast(msg: "Warning issued to user.");
  }

  void handleDiscard(Report report) async {
    await widget.dbRef.child("reports").child(report.id).update({"status": "resolved"});
    Fluttertoast.showToast(msg: "Report discarded.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reports"),
      ),
      body: ListView.builder(
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return ListTile(
            title: Text("${report.type.toUpperCase()} Report"),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Reason: ${report.reason}"),
                Text("Content: ${report.content ?? 'N/A'}"),
                Text("Reported by: ${report.reportedBy}"),
                Text("Timestamp: ${DateTime.fromMillisecondsSinceEpoch(report.timestamp)}"),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  handleDelete(report);
                } else if (value == 'warn') {
                  handleWarning(report);
                } else if (value == 'discard') {
                  handleDiscard(report);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'delete', child: Text("Delete")),
                PopupMenuItem(value: 'warn', child: Text("Warn User")),
                PopupMenuItem(value: 'discard', child: Text("Discard")),
              ],
            ),
          );
        },
      ),
    );
  }
}

class Report {
  final String id;
  final String type;
  final String? content;
  final String? reason;
  final int timestamp;
  final String? reportedBy;

  Report({
    required this.id,
    required this.type,
    this.content,
    this.reason,
    required this.timestamp,
    this.reportedBy,
  });

  // Factory constructor to create a Report object from a DataSnapshot
  factory Report.fromSnapshot(DataSnapshot snapshot, String type) {
    return Report(
      id: snapshot.key!,
      type: type,
      content: snapshot.child("content").value as String?,
      reason: snapshot.child("reason").value as String?,
      timestamp: snapshot.child("timestamp").value as int? ?? 0,
      reportedBy: snapshot.child("reportedBy").value as String?,
    );
  }
}
