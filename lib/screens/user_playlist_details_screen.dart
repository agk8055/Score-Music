import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_playlist.dart';
import '../models/song.dart';
import '../services/music_player_service.dart';
import '../services/playlist_service.dart';
import '../services/api_service.dart';
import '../widgets/base_scaffold.dart';
import '../widgets/bottom_navigation.dart';
import 'package:url_launcher/url_launcher.dart';

class UserPlaylistDetailsScreen extends StatefulWidget {
  final UserPlaylist playlist;
  final MusicPlayerService playerService;

  const UserPlaylistDetailsScreen({
    Key? key,
    required this.playlist,
    required this.playerService,
  }) : super(key: key);

  @override
  State<UserPlaylistDetailsScreen> createState() => _UserPlaylistDetailsScreenState();
}

class _UserPlaylistDetailsScreenState extends State<UserPlaylistDetailsScreen> {
  final ApiService _apiService = ApiService();
  late PlaylistService _playlistService;
  final ScrollController _scrollController = ScrollController();
  List<Song> _songs = [];
  bool _isLoading = true;
  String? _error;
  String? _playlistImage;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _initializeServices() async {
    final prefs = await SharedPreferences.getInstance();
    _playlistService = PlaylistService(prefs);
    _loadSongs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      // Implement pagination if needed
    }
  }

  Future<void> _loadSongs() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final songs = await _apiService.getPlaylistSongs(widget.playlist.songIds);
      
      setState(() {
        _songs = songs;
        _isLoading = false;
        if (songs.isNotEmpty) {
          _playlistImage = songs[0].image;
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _removeSongFromPlaylist(Song song) async {
    try {
      await _playlistService.removeSongFromUserPlaylist(widget.playlist.id, song.id);
      setState(() {
        _songs.removeWhere((s) => s.id == song.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Song removed from playlist')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove song: $e')),
      );
    }
  }

  void _playSong(Song song) {
    widget.playerService.playSong(song);
  }

  void _addToQueue(Song song) {
    widget.playerService.addToQueue(song);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to queue')),
    );
  }

  void _playAll() {
    if (_songs.isNotEmpty) {
      widget.playerService.playSong(_songs[0]);
      for (var i = 1; i < _songs.length; i++) {
        widget.playerService.addToQueue(_songs[i]);
      }
    }
  }

  Future<void> _downloadInBrowser(Song song) async {
    final Uri url = Uri.parse(song.mediaUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open browser for download'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      playerService: widget.playerService,
      playlistService: _playlistService,
      appBar: AppBar(
        title: Text(
          widget.playlist.name,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Playlist'),
                  content: const Text('Are you sure you want to delete this playlist?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await _playlistService.deleteUserPlaylist(widget.playlist.id);
                if (mounted) {
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigation(
        selectedIndex: 2,
        onDestinationSelected: (index) {},
        isLibraryScreen: true,
      ),
      body: _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: _playlistImage != null
                            ? Image.network(
                                _playlistImage!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[800],
                                    child: const Icon(
                                      Icons.playlist_play,
                                      size: 100,
                                      color: Colors.white54,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[800],
                                child: const Icon(
                                  Icons.playlist_play,
                                  size: 100,
                                  color: Colors.white54,
                                ),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.playlist.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _playAll,
                                  icon: const Icon(
                                    Icons.play_circle_fill,
                                    size: 48,
                                    color: Color(0xFFF5D505),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_songs.length} songs',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _isLoading
                    ? SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[800],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: 120,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[800],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          childCount: 10,
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final song = _songs[index];
                            return ListTile(
                              leading: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 64,
                                    height: 64,
                                    child: ClipRRect(
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
                                  ),
                                ],
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
                                    _playSong(song);
                                  } else if (value == 'add_to_queue') {
                                    _addToQueue(song);
                                  } else if (value == 'download') {
                                    await _downloadInBrowser(song);
                                  } else if (value == 'remove') {
                                    await _removeSongFromPlaylist(song);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'play',
                                    child: Row(
                                      children: [
                                        Icon(Icons.play_arrow, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text('Play Now'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'add_to_queue',
                                    child: Row(
                                      children: [
                                        Icon(Icons.queue_music, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text('Add to Queue'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'download',
                                    child: Row(
                                      children: [
                                        Icon(Icons.download, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text('Download'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'remove',
                                    child: Row(
                                      children: [
                                        Icon(Icons.remove_circle_outline, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Remove from Playlist', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _playSong(song),
                            );
                          },
                          childCount: _songs.length,
                        ),
                      ),
              ],
            ),
    );
  }
} 