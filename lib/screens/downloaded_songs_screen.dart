import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/download_service.dart';

class DownloadedSongsScreen extends StatefulWidget {
  const DownloadedSongsScreen({super.key});

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
      body: _downloadedSongs.isEmpty
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
                return ListTile(
                  leading: const Icon(Icons.music_note, color: Color(0xFFF5D505)),
                  title: Text(
                    song.title,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    song.artist,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteSong(song),
                  ),
                );
              },
            ),
    );
  }
} 