import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../services/api_service.dart';
import '../services/music_player_service.dart';
import '../services/playlist_cache_service.dart';
import '../services/playlist_service.dart';
import '../screens/playlist_details_screen.dart';
import 'skeleton_loader.dart';

class PlaylistCard extends StatefulWidget {
  final String playlistUrl;
  final MusicPlayerService playerService;
  final PlaylistService playlistService;

  const PlaylistCard({
    Key? key,
    required this.playlistUrl,
    required this.playerService,
    required this.playlistService,
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
      if (_cacheService.hasCachedPlaylist(widget.playlistUrl)) {
        setState(() {
          _playlist = _cacheService.getCachedPlaylist(widget.playlistUrl);
          _isLoading = false;
        });
        return;
      }

      final playlist = await _apiService.getPlaylistDetails(widget.playlistUrl);
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
    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: _playlist == null ? null : () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaylistDetailsScreen(
                playerService: widget.playerService,
                playlistUrl: widget.playlistUrl,
                initialPlaylist: _playlist,
                playlistService: widget.playlistService,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image container with fixed height
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _isLoading
                  ? const SkeletonLoader(width: 160, height: 160, borderRadius: 16)
                  : (_error != null || _playlist == null)
                      ? Container(
                          color: Colors.grey[900],
                          child: const Center(
                            child: Icon(Icons.error_outline, color: Colors.white54, size: 40),
                          ),
                        )
                      : Image.network(
                          _playlist!.image,
                          width: 160,
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 160,
                              height: 160,
                              color: Colors.grey[900],
                              child: const Icon(Icons.playlist_play, size: 50, color: Colors.white54),
                            );
                          },
                        ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Text content
            if (!_isLoading && _playlist != null && _error == null) ...[
              Text(
                _playlist!.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${_playlist!.fanCount} Fans',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            // Skeleton text placeholders
            if (_isLoading) ...[
              const SizedBox(height: 8),
              const SkeletonLoader(width: 140, height: 14, borderRadius: 4),
              const SizedBox(height: 4),
              const SkeletonLoader(width: 80, height: 12, borderRadius: 4),
            ],
          ],
        ),
      ),
    );
  }
}