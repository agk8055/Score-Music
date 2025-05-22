import 'package:flutter/material.dart';
import '../services/music_player_service.dart';
import 'playlist_card.dart';

class PlaylistCategorySection extends StatefulWidget {
  final MusicPlayerService playerService;
  final String title;
  final List<String> playlistUrls;

  const PlaylistCategorySection({
    Key? key,
    required this.playerService,
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
          padding: const EdgeInsets.all(16.0),
          child: Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.playlistUrls.length,
            itemBuilder: (context, index) {
              return PlaylistCard(
                playlistUrl: widget.playlistUrls[index],
                playerService: widget.playerService,
              );
            },
          ),
        ),
      ],
    );
  }
} 