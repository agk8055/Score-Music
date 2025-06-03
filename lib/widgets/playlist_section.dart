import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../services/api_service.dart';
import '../services/music_player_service.dart';
import '../services/download_service.dart';
import '../services/playlist_service.dart';
import 'playlist_selection_dialog.dart';

class PlaylistSection extends StatefulWidget {
  final MusicPlayerService playerService;
  final String playlistUrl;
  final PlaylistService playlistService;

  const PlaylistSection({
    Key? key,
    required this.playerService,
    required this.playlistUrl,
    required this.playlistService,
  }) : super(key: key);

  @override
  State<PlaylistSection> createState() => _PlaylistSectionState();
}

class _PlaylistSectionState extends State<PlaylistSection> {
  final ApiService _apiService = ApiService();
  final DownloadService _downloadService = DownloadService();
  Playlist? _playlist;
  List<Song> _songs = [];
  bool _isLoading = true;
  String? _error;
  Map<String, bool> _downloadedSongs = {};

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
  }

  Future<void> _loadPlaylist() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final playlist = await _apiService.getPlaylistDetails(widget.playlistUrl);
      final songs = await _apiService.getPlaylistSongs(playlist.contentList);

      // Check download status for all songs
      for (var song in songs) {
        _downloadedSongs[song.id] = await _downloadService.isDownloaded(song);
      }

      setState(() {
        _playlist = playlist;
        _songs = songs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleDownload(Song song) async {
    try {
      if (!(_downloadedSongs[song.id] ?? false)) {
        await _downloadService.showDownloadOptions(context, song);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Download started'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading song: $e'),
          ),
        );
      }
    }
  }

  void _showAddToPlaylistDialog(Song song) {
    showDialog(
      context: context,
      builder: (context) => PlaylistSelectionDialog(
        playlistService: widget.playlistService,
        songId: song.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_playlist == null || _songs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _playlist!.image,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[800],
                      child: const Icon(Icons.playlist_play),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _playlist!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_playlist!.fanCount} Fans',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _songs.length,
          itemBuilder: (context, index) {
            final song = _songs[index];
            final isDownloaded = _downloadedSongs[song.id] ?? false;
            
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  song.image,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 56,
                      height: 56,
                      color: Colors.grey[800],
                      child: const Icon(Icons.music_note),
                    );
                  },
                ),
              ),
              title: Text(
                song.title,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                song.primaryArtists,
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white70),
                onSelected: (value) async {
                  if (value == 'play') {
                    widget.playerService.playSong(song);
                  } else if (value == 'add_to_queue') {
                    widget.playerService.addToQueue(song);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Added to queue'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } else if (value == 'download') {
                    await _handleDownload(song);
                  } else if (value == 'add_to_playlist') {
                    _showAddToPlaylistDialog(song);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'play',
                    child: Text('Play Now'),
                  ),
                  const PopupMenuItem(
                    value: 'add_to_queue',
                    child: Text('Add to Queue'),
                  ),
                  PopupMenuItem(
                    value: 'download',
                    child: Text(isDownloaded ? 'Downloaded' : 'Download'),
                  ),
                  const PopupMenuItem(
                    value: 'add_to_playlist',
                    child: Text('Add to Playlist'),
                  ),
                ],
              ),
              onTap: () {
                widget.playerService.playSong(song);
              },
            );
          },
        ),
      ],
    );
  }
} 