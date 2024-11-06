import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ReportsSection extends StatefulWidget {
  final DatabaseReference dbRef;

  ReportsSection({Key? key, required this.dbRef}) : super(key: key);

  @override
  _ReportsSectionState createState() => _ReportsSectionState();
}

class _ReportsSectionState extends State<ReportsSection> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  List<Report> reports = [];
  Map<String, String> postImages = {}; // Map to store post ID and image URL

  @override
  void initState() {
    super.initState();
    loadReports();
  }

  void loadReports() {
    print("Starting to load reports...");

    // Load only post reports
    widget.dbRef.child("reports").onValue.listen((event) {
      List<Report> loadedReports = [];
      print("Loading post reports...");
      for (var snapshot in event.snapshot.children) {
        print("Fetched post report with ID: ${snapshot.key}");
        final report = Report.fromSnapshot(snapshot, "post");
        loadedReports.add(report);

        // Check if postId is not null before attempting to load the image
        if (report.postId != null) {
          loadPostImage(report.postId!);
        }
      }
      setState(() {
        reports = loadedReports;
      });
      print("Total post reports loaded: ${loadedReports.length}");
    });
  }

  void loadPostImage(String postId) async {
    try {
      String imageUrl = await FirebaseStorage.instance
          .ref('post_images/$postId.png')
          .getDownloadURL();
      setState(() {
        postImages[postId] = imageUrl;
      });
    } catch (e) {
      print("Error fetching image for post $postId: ${e.toString()}");
      setState(() {
        postImages[postId] = ""; // Store an empty string for failed fetches
      });
    }
  }

  void handleDelete(Report report) async {
    try {
      // Delete the post from "posts" node if postId is available
      if (report.postId != null) {
        await widget.dbRef.child("posts").child(report.postId!).remove();
        print("Post deleted from 'posts' node.");
      }

      // Delete the report from "reports" node
      await widget.dbRef.child("reports").child(report.id).remove();
      print("Report deleted from 'reports' node.");

      Fluttertoast.showToast(msg: "Post and report deleted.");
      loadReports(); // Refresh reports after deletion
    } catch (e) {
      print("Error deleting report: $e");
      Fluttertoast.showToast(msg: "Error deleting report.");
    }
  }

  void handleWarning(Report report) async {
    // Show a dialog to input custom reason
    TextEditingController reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Issue Warning"),
          content: TextField(
            controller: reasonController,
            decoration: InputDecoration(
              labelText: "Enter warning reason",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                // Proceed to issue warning with the provided reason
                Navigator.of(context).pop(); // Close dialog
                await issueWarning(report, reasonController.text);
              },
              child: Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  Future<void> issueWarning(Report report, String customReason) async {
    try {
      // Ensure reportedBy field is not null
      if (report.reportedBy != null) {
        String warningId =
        widget.dbRef.child("warnings").child(report.reportedBy!).push().key!;

        // Add the warning in the "warnings" node with custom reason
        await widget.dbRef
            .child("warnings")
            .child(report.reportedBy!)
            .child(warningId)
            .set({
          "userId": report.reportedBy!,
          "reason": customReason.isNotEmpty
              ? customReason
              : (report.reason ?? "No reason provided"),
          "timestamp": DateTime.now().millisecondsSinceEpoch,
        });
        print("Warning added for user ${report.reportedBy}.");

        // Delete the report from "reports" node
        await widget.dbRef.child("reports").child(report.id).remove();
        print("Report deleted from 'reports' node after issuing warning.");

        Fluttertoast.showToast(msg: "Warning issued to user and report deleted.");
        loadReports(); // Refresh reports after issuing warning
      } else {
        print("ReportedBy userId is null.");
        Fluttertoast.showToast(msg: "Unable to issue warning; userId is null.");
      }
    } catch (e) {
      print("Error issuing warning: $e");
      Fluttertoast.showToast(msg: "Error issuing warning.");
    }
  }

  void handleDiscard(Report report) async {
    try {
      // Remove the report from "reports" node
      await widget.dbRef.child("reports").child(report.id).remove();
      print("Report discarded and removed from 'reports' node.");

      Fluttertoast.showToast(msg: "Report discarded.");
      loadReports(); // Refresh reports after discarding
    } catch (e) {
      print("Error discarding report: $e");
      Fluttertoast.showToast(msg: "Error discarding report.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reported Posts"),
      ),
      body: ListView.builder(
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          final postId = report.postId;
          final imageUrl = postId != null &&
              postImages.containsKey(postId) &&
              postImages[postId]!.isNotEmpty
              ? postImages[postId]!
              : null;

          return ListTile(
            title: Text("POST Report"),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl != null)
                  Image.network(
                    imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Text('Image not available'),
                  ),
                Text("Reason: ${report.reason ?? 'N/A'}"),
                Text("Content: ${report.content ?? 'N/A'}"),
                Text("Reported by: ${report.reportedBy ?? 'Unknown'}"),
                Text(
                    "Timestamp: ${DateTime.fromMillisecondsSinceEpoch(report.timestamp ?? 0).toString()}"),
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
  final String? postId;
  final String? content;
  final String? reason;
  final int? timestamp;
  final String? reportedBy;

  Report({
    required this.id,
    required this.type,
    this.postId,
    this.content,
    this.reason,
    this.timestamp,
    this.reportedBy,
  });

  // Factory constructor to create a Report object from a DataSnapshot
  factory Report.fromSnapshot(DataSnapshot snapshot, String type) {
    print(
        "Creating Report object from snapshot for type: $type, ID: ${snapshot.key}");
    return Report(
      id: snapshot.key!,
      type: type,
      postId: snapshot.child("postId").value as String?,
      content: snapshot.child("content").value as String?,
      reason: snapshot.child("reason").value as String?,
      timestamp:
      (snapshot.child("timestamp").value as num?)?.toInt() ?? 0, // Defaulting to 0 if null
      reportedBy: snapshot.child("reportedBy").value as String?,
    );
  }
}
