import 'package:flutter/material.dart';
import 'dart:async';
import '../models/song.dart';
import '../models/album.dart';
import '../services/api_service.dart';
import '../services/music_player_service.dart';
import '../screens/album_details_screen.dart';
import '../widgets/skeleton_loader.dart';

class SearchScreen extends StatefulWidget {
  final MusicPlayerService playerService;

  const SearchScreen({
    super.key,
    required this.playerService,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  List<Song> _searchResults = [];
  List<Album> _albumResults = [];
  bool _isLoading = false;
  String? _error;
  Timer? _debounce;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query.length >= 2) {
        _performSearch(query);
      } else {
        setState(() {
          _searchResults = [];
          _albumResults = [];
          _error = null;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // First load songs
      final results = await _apiService.search(query);
      setState(() {
        _searchResults = results['songs'] as List<Song>;
        _isLoading = false;
      });

      // Then load albums in the background
      final albums = await _apiService.loadAlbumsForSongs(_searchResults);
      if (mounted) {
        setState(() {
          _albumResults = albums;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Widget _buildSongList() {
    if (_isLoading && _searchResults.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Songs',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5, // Show 5 skeleton items
            itemBuilder: (context, index) => const SongSkeletonLoader(),
          ),
        ],
      );
    }

    if (_searchResults.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Songs',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final song = _searchResults[index];
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
                onSelected: (value) {
                  if (value == 'play') {
                    widget.playerService.playSong(song);
                  } else if (value == 'add_to_queue') {
                    widget.playerService.addToQueue(song);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Added to queue'),
                        duration: Duration(seconds: 2),
                      ),
                    );
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

  Widget _buildAlbumList() {
    if (_isLoading && _albumResults.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Albums',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3, // Show 3 skeleton items
            itemBuilder: (context, index) => const AlbumSkeletonLoader(),
          ),
        ],
      );
    }

    if (_albumResults.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Albums',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _albumResults.length,
          itemBuilder: (context, index) {
            final album = _albumResults[index];
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  album.image,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 56,
                      height: 56,
                      color: Colors.grey[800],
                      child: const Icon(Icons.album),
                    );
                  },
                ),
              ),
              title: Text(
                album.name,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                album.primaryArtists,
                style: const TextStyle(color: Colors.white70),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AlbumDetailsScreen(
                      album: album,
                      playerService: widget.playerService,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search songs...',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
            ),
            onChanged: _onSearchChanged,
            onSubmitted: _performSearch,
          ),
        ),
        Expanded(
          child: _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : ListView(
                  children: [
                    _buildSongList(),
                    _buildAlbumList(),
                  ],
                ),
        ),
      ],
    );
  }
} 