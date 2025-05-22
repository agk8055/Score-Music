import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchGitHub() async {
    final Uri url = Uri.parse('https://github.com/agk8055');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'About',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF5D505),
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Developed by AGK',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _launchGitHub,
              icon: const Icon(
                Icons.code,
                color: Color(0xFFF5D505),
              ),
              label: const Text(
                'GitHub Profile',
                style: TextStyle(
                  color: Color(0xFFF5D505),
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 