import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/music_player_service.dart';
import 'music_controller.dart';

class BaseScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final MusicPlayerService playerService;

  const BaseScaffold({
    super.key,
    required this.body,
    required this.playerService,
    this.appBar,
    this.drawer,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      bottomNavigationBar: bottomNavigationBar,
      body: StreamBuilder<Song?>(
        stream: playerService.currentSongStream,
        builder: (context, snapshot) {
          final song = snapshot.data;
          final showController = song != null;
          return Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: showController ? 85 : 0),
                child: body,
              ),
              if (showController)
                Positioned(
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
                ),
            ],
          );
        },
      ),
    );
  }
} 