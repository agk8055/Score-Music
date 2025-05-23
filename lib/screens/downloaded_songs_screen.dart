import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/download_service.dart';
import '../services/music_player_service.dart';
import '../services/playlist_service.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/music_controller.dart';

class DownloadedSongsScreen extends StatefulWidget {
  final MusicPlayerService playerService;
  final PlaylistService playlistService;
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const DownloadedSongsScreen({
    super.key,
    required this.playerService,
    required this.playlistService,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  State<DownloadedSongsScreen> createState() => _DownloadedSongsScreenState();
}

class _DownloadedSongsScreenState extends State<DownloadedSongsScreen> {
  final DownloadService _downloadService = DownloadService();
  List<Song> _downloadedSongs = [];

  @override
  void initState() {
    super.initState();
    _loadDownloadedSongs();
  }

  Future<void> _loadDownloadedSongs() async {
    final songs = await _downloadService.getDownloadedSongs();
    setState(() {
      _downloadedSongs = songs;
    });
  }

  Future<void> _playSong(Song song) async {
    try {
      final localPath = await _downloadService.getLocalPath(song);
      if (localPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Song file not found')),
        );
        return;
      }

      // Create a copy of the song with the local path as the media URL
      final localSong = Song(
        id: song.id,
        title: song.title,
        album: song.album,
        albumUrl: song.albumUrl,
        image: song.image,
        mediaUrl: localPath, // Use local path instead of remote URL
        mediaPreviewUrl: song.mediaPreviewUrl,
        duration: song.duration,
        language: song.language,
        artistMap: song.artistMap,
        primaryArtists: song.primaryArtists,
        singers: song.singers,
        music: song.music,
        year: song.year,
        playCount: song.playCount,
        isDrm: song.isDrm,
        hasLyrics: song.hasLyrics,
        permaUrl: song.permaUrl,
        releaseDate: song.releaseDate,
        label: song.label,
        copyrightText: song.copyrightText,
        is320kbps: song.is320kbps,
        disabledText: song.disabledText,
        isDisabled: song.isDisabled,
      );

      // Play the song using the music player service
      await widget.playerService.playSong(localSong);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing song: $e')),
      );
    }
  }

  Future<void> _deleteSong(Song song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Song'),
        content: Text('Are you sure you want to delete "${song.title}"?'),
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
      // Stop playback if this song is currently playing
      if (widget.playerService.currentSong?.id == song.id) {
        await widget.playerService.pause();
      }
      await _downloadService.deleteSong(song);
      await _loadDownloadedSongs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Downloaded Songs',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF5D505),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _downloadedSongs.isEmpty
                ? const Center(
                    child: Text(
                      'No downloaded songs yet',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : ListView.builder(
                    itemCount: _downloadedSongs.length,
                    itemBuilder: (context, index) {
                      final song = _downloadedSongs[index];
                      final isPlaying = widget.playerService.currentSong?.id == song.id;
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFF5D505),
                          child: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.black,
                          ),
                        ),
                        title: Text(
                          song.title != 'Unknown Title' ? song.title : 'Unknown Song',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          song.primaryArtists != 'Unknown Artist' ? song.primaryArtists : 'Unknown Artist',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                color: const Color(0xFFF5D505),
                              ),
                              onPressed: () => _playSong(song),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteSong(song),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          MusicController(
            playerService: widget.playerService,
            playlistService: widget.playlistService,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigation(
        selectedIndex: widget.selectedIndex,
        onDestinationSelected: widget.onDestinationSelected,
      ),
    );
  }
} 