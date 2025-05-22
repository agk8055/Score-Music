import 'package:flutter/material.dart';
import '../services/play_history_service.dart';

class SettingsScreen extends StatelessWidget {
  final PlayHistoryService historyService;

  const SettingsScreen({
    Key? key,
    required this.historyService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF5D505),
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFF5D505)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            color: const Color(0xFF1A1A1A),
            child: ListTile(
              leading: const Icon(
                Icons.history,
                color: Color(0xFFF5D505),
              ),
              title: const Text(
                'Clear Recently Played',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Remove all songs from your recently played history',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1A1A1A),
                    title: const Text(
                      'Clear History',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      'Are you sure you want to clear your recently played history?',
                      style: TextStyle(color: Colors.white),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Clear',
                          style: TextStyle(color: Color(0xFFF5D505)),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await historyService.clearHistory();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Recently played history cleared'),
                        backgroundColor: Color(0xFF1A1A1A),
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
} 