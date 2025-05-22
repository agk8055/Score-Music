import 'package:flutter/material.dart';
import '../services/music_player_service.dart';
import '../services/play_history_service.dart';
import '../widgets/base_scaffold.dart';
import '../widgets/play_history_section.dart';

class HomeScreen extends StatelessWidget {
  final MusicPlayerService playerService;
  final PlayHistoryService historyService;

  const HomeScreen({
    Key? key,
    required this.playerService,
    required this.historyService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        PlayHistorySection(
          historyService: historyService,
          onSongTap: (song) => playerService.playSong(song),
        ),
        // Add more sections here as needed
      ],
    );
  }
} 