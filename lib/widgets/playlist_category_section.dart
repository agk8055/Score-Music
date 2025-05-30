import 'package:flutter/material.dart';
import '../services/music_player_service.dart';
import '../services/playlist_service.dart';
import 'playlist_card.dart';
import 'skeleton_loader.dart'; // Import skeleton loader

class PlaylistCategorySection extends StatefulWidget {
  final MusicPlayerService playerService;
  final PlaylistService playlistService;
  final String title;
  final List<String> playlistUrls;

  const PlaylistCategorySection({
    Key? key,
    required this.playerService,
    required this.playlistService,
    required this.title,
    required this.playlistUrls,
  }) : super(key: key);

  @override
  State<PlaylistCategorySection> createState() => _PlaylistCategorySectionState();
}

class _PlaylistCategorySectionState extends State<PlaylistCategorySection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 12, right: 12),
            itemCount: widget.playlistUrls.length,
            itemBuilder: (context, index) {
              return PlaylistCard(
                playlistUrl: widget.playlistUrls[index],
                playerService: widget.playerService,
                playlistService: widget.playlistService,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}