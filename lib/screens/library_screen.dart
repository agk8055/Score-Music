import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_playlist.dart';
import '../models/song.dart';
import '../services/playlist_service.dart';
import '../services/music_player_service.dart';
import '../services/api_service.dart';
import 'downloaded_songs_screen.dart';
import 'user_playlist_details_screen.dart';

class LibraryScreen extends StatefulWidget {
  final MusicPlayerService playerService;

  const LibraryScreen({
    super.key,
    required this.playerService,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late PlaylistService _playlistService;
  final ApiService _apiService = ApiService();
  List<UserPlaylist> _playlists = [];
  Map<String, String> _playlistImages = {};

  @override
  void initState() {
    super.initState();
    _initializePlaylistService();
  }

  Future<void> _initializePlaylistService() async {
    final prefs = await SharedPreferences.getInstance();
    _playlistService = PlaylistService(prefs);
    _loadPlaylists();
  }

  void _loadPlaylists() {
    setState(() {
      _playlists = _playlistService.getUserPlaylists();
    });
    _loadPlaylistImages();
  }

  Future<void> _loadPlaylistImages() async {
    for (final playlist in _playlists) {
      if (playlist.songIds.isNotEmpty) {
        try {
          final songs = await _apiService.getPlaylistSongs([playlist.songIds[0]]);
          if (songs.isNotEmpty) {
            setState(() {
              _playlistImages[playlist.id] = songs[0].image;
            });
          }
        } catch (e) {
          print('Error loading playlist image: $e');
        }
      }
    }
  }

  void _showCreatePlaylistDialog() {
    final TextEditingController playlistNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Playlist'),
          content: TextField(
            controller: playlistNameController,
            decoration: const InputDecoration(
              hintText: 'Enter playlist name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (playlistNameController.text.isNotEmpty) {
                  await _playlistService.createUserPlaylist(playlistNameController.text);
                  _loadPlaylists();
                  if (mounted) Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5D505),
                foregroundColor: Colors.black,
              ),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DownloadedSongsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.download_done),
              label: const Text('Downloaded Songs'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5D505),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showCreatePlaylistDialog,
              icon: const Icon(Icons.playlist_add),
              label: const Text('Create Playlist'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5D505),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Playlists',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _playlists.length,
                itemBuilder: (context, index) {
                  final playlist = _playlists[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: _playlistImages[playlist.id] != null
                            ? Image.network(
                                _playlistImages[playlist.id]!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 56,
                                    height: 56,
                                    color: const Color(0xFFF5D505),
                                    child: Text(
                                      playlist.name.isNotEmpty ? playlist.name[0].toUpperCase() : 'P',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                width: 56,
                                height: 56,
                                color: const Color(0xFFF5D505),
                                child: Text(
                                  playlist.name.isNotEmpty ? playlist.name[0].toUpperCase() : 'P',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                      title: Text(
                        playlist.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text('${playlist.songIds.length} songs'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await _playlistService.deleteUserPlaylist(playlist.id);
                          _loadPlaylists();
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserPlaylistDetailsScreen(
                              playlist: playlist,
                              playerService: widget.playerService,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 