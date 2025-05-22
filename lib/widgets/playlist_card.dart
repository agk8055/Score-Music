import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../services/api_service.dart';
import '../services/music_player_service.dart';
import '../services/playlist_cache_service.dart';
import '../screens/playlist_details_screen.dart';

class PlaylistCard extends StatefulWidget {
  final String playlistUrl;
  final MusicPlayerService playerService;

  const PlaylistCard({
    Key? key,
    required this.playlistUrl,
    required this.playerService,
  }) : super(key: key);

  @override
  State<PlaylistCard> createState() => _PlaylistCardState();
}

class _PlaylistCardState extends State<PlaylistCard> {
  final ApiService _apiService = ApiService();
  final PlaylistCacheService _cacheService = PlaylistCacheService();
  Playlist? _playlist;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
  }

  Future<void> _loadPlaylist() async {
    try {
      // Check cache first
      if (_cacheService.hasCachedPlaylist(widget.playlistUrl)) {
        setState(() {
          _playlist = _cacheService.getCachedPlaylist(widget.playlistUrl);
          _isLoading = false;
        });
        return;
      }

      final playlist = await _apiService.getPlaylistDetails(widget.playlistUrl);
      // Cache the playlist
      _cacheService.cachePlaylist(playlist);
      
      setState(() {
        _playlist = playlist;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: 160,
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _playlist == null) {
      return Container(
        width: 160,
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.error_outline, color: Colors.white54),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaylistDetailsScreen(
              playerService: widget.playerService,
              playlistUrl: widget.playlistUrl,
              initialPlaylist: _playlist,
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _playlist!.image,
                width: 160,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 160,
                    height: 160,
                    color: Colors.grey[800],
                    child: const Icon(Icons.playlist_play, size: 50, color: Colors.white54),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 160,
              child: Text(
                _playlist!.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 160,
              child: Text(
                '${_playlist!.fanCount} Fans',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 