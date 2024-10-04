import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'bEtre',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: Text(
                '''bEtre is a social media platform built for authentic self-expression. Inspired by the French word "être," meaning "to be," bEtre empowers users to share who they truly are.

Our app allows users to create posts, add location-based tags, and engage in meaningful conversations. Whether you're connecting with friends or exploring new content, bEtre helps you discover and express yourself in a genuine way.

We believe in building a safe and respectful community. With tools for moderation and user management, bEtre ensures a positive environment for everyone.

At its heart, bEtre is about being real, being connected, and being yourself.''',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: 16),

            Center(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
                child: Text(
                  'Contact us at: support@bEtre.com',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
