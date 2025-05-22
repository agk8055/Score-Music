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
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Recently Played',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: GestureDetector(
                  onTap: () => _handleItemTap(context, item),
                  child: Column(
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(item.image),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 140,
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        child: Text(
                          item.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
} 