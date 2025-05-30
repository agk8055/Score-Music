import 'package:flutter/material.dart';
import '../models/play_history_item.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/playlist.dart';
import '../services/play_history_service.dart';
import '../services/music_player_service.dart';
import '../services/playlist_service.dart';
import '../screens/album_details_screen.dart';
import '../screens/playlist_details_screen.dart';
import 'skeleton_loader.dart'; // Import skeleton loader

class PlayHistorySection extends StatelessWidget {
  final PlayHistoryService historyService;
  final MusicPlayerService playerService;
  final PlaylistService playlistService;

  const PlayHistorySection({
    Key? key,
    required this.historyService,
    required this.playerService,
    required this.playlistService,
  }) : super(key: key);

  void _handleItemTap(BuildContext context, PlayHistoryItem item) {
    switch (item.type) {
      case PlayHistoryItemType.song:
        if (item.song != null) {
          playerService.playSong(item.song!);
        }
        break;
      case PlayHistoryItemType.album:
        if (item.album != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AlbumDetailsScreen(
                album: item.album!,
                playerService: playerService,
                playlistService: playlistService,
              ),
            ),
          );
        }
        break;
      case PlayHistoryItemType.playlist:
        if (item.playlist != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaylistDetailsScreen(
                playlistUrl: item.playlist!.url,
                playerService: playerService,
                initialPlaylist: item.playlist,
                playlistService: playlistService,
              ),
            ),
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = historyService.history;
    
    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Recently Played',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 12, right: 12),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return GestureDetector(
                onTap: () => _handleItemTap(context, item),
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Circular image with border
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(90),
                          border: Border.all(
                            color: const Color(0xFFF5D505),
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(70),
                          child: Image.network(
                            item.image,
                            width: 136,
                            height: 136,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 136,
                                height: 136,
                                color: Colors.grey[900],
                                child: const Icon(Icons.music_note, 
                                    color: Colors.white54, size: 40),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Title
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Subtitle
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}