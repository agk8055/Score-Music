import 'package:flutter/material.dart';
import '../models/user_playlist.dart';
import '../services/playlist_service.dart';

class PlaylistSelectionDialog extends StatefulWidget {
  final PlaylistService playlistService;
  final String songId;

  const PlaylistSelectionDialog({
    Key? key,
    required this.playlistService,
    required this.songId,
  }) : super(key: key);

  @override
  State<PlaylistSelectionDialog> createState() => _PlaylistSelectionDialogState();
}

class _PlaylistSelectionDialogState extends State<PlaylistSelectionDialog> {
  List<UserPlaylist> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  void _loadPlaylists() {
    setState(() {
      _playlists = widget.playlistService.getUserPlaylists();
      _isLoading = false;
    });
  }

  Future<void> _createNewPlaylist() async {
    final TextEditingController controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Playlist'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter playlist name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context, controller.text);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null) {
      await widget.playlistService.createUserPlaylist(result);
      await widget.playlistService.addSongToUserPlaylist(
        DateTime.now().millisecondsSinceEpoch.toString(),
        widget.songId,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Song added to new playlist'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add to Playlist',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_playlists.isEmpty)
              const Center(
                child: Text(
                  'No playlists found',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = _playlists[index];
                    return ListTile(
                      title: Text(
                        playlist.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '${playlist.songIds.length} songs',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      onTap: () async {
                        await widget.playlistService.addSongToUserPlaylist(
                          playlist.id,
                          widget.songId,
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Song added to playlist'),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createNewPlaylist,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5D505),
                foregroundColor: Colors.black,
              ),
              child: const Text('Create New Playlist'),
            ),
          ],
        ),
      ),
    );
  }
} 