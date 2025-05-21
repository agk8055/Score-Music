import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/music_player_service.dart';
import 'music_controller.dart';

class BaseScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final MusicPlayerService playerService;

  const BaseScaffold({
    super.key,
    required this.body,
    required this.playerService,
    this.appBar,
    this.drawer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 85),
            child: body,
          ),
          StreamBuilder<Song?>(
            stream: playerService.currentSongStream,
            builder: (context, snapshot) {
              final song = snapshot.data;
              if (song == null) return const SizedBox.shrink();

              return Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 85,
                  child: MusicController(
                    playerService: playerService,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
} 