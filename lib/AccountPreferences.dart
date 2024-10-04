import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Privacy'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(35),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '''Your privacy is important to us. We ensure that your data is protected and managed securely. Here are some key points about our privacy policy:
                
• We do not share your personal information with third parties without your consent.
• Your data is stored securely and is protected by encryption.
• You can control privacy settings and manage what information is shared.
• We comply with all data protection regulations to ensure your information is safe.''',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
