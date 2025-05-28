import 'package:flutter/material.dart';
import '../services/play_history_service.dart';
import 'home_customization_screen.dart';
import 'profile_screen.dart';
import 'backend_url_screen.dart';

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
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFF1A1A1A),
            child: ListTile(
              leading: const Icon(
                Icons.dashboard_customize,
                color: Color(0xFFF5D505),
              ),
              title: const Text(
                'Customize Home Screen',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Personalize your home screen layout and appearance',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeCustomizationScreen(),
                  ),
                );
                
                if (result == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Home screen updated'),
                      backgroundColor: Color(0xFF1A1A1A),
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFF1A1A1A),
            child: ListTile(
              leading: const Icon(
                Icons.settings_remote,
                color: Color(0xFFF5D505),
              ),
              title: const Text(
                'Update Backend URL',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Change the backend server URL',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BackendUrlScreen(),
                  ),
                );
                
                if (result == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Backend URL updated'),
                      backgroundColor: Color(0xFF1A1A1A),
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFF1A1A1A),
            child: ListTile(
              leading: const Icon(
                Icons.person,
                color: Color(0xFFF5D505),
              ),
              title: const Text(
                'Profile',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'View and edit your profile settings',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 