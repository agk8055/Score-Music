import 'package:flutter/material.dart';
import 'dart:async';
import '../models/song.dart';
import '../models/album.dart';
import '../services/api_service.dart';
import '../services/music_player_service.dart';
import '../services/search_cache_service.dart';
import '../screens/album_details_screen.dart';
import '../widgets/skeleton_loader.dart';
import '../main.dart';  // Import SearchStateProvider
import '../services/playlist_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SearchScreen extends StatefulWidget {
  final MusicPlayerService playerService;
  final SearchCacheService searchCacheService;
  final SearchStateProvider searchStateProvider;
  final PlaylistService playlistService;

  const SearchScreen({
    super.key,
    required this.playerService,
    required this.searchCacheService,
    required this.searchStateProvider,
    required this.playlistService,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Set the initial search text if there's a previous query
    if (widget.searchStateProvider.currentQuery.isNotEmpty) {
      _searchController.text = widget.searchStateProvider.currentQuery;
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query.length >= 2) {
        widget.searchStateProvider.performSearch(query);
      } else {
        widget.searchStateProvider.clearSearch();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.searchStateProvider,
      builder: (context, _) {
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
                onSubmitted: widget.searchStateProvider.performSearch,
              ),
            ),
            Expanded(
              child: widget.searchStateProvider.error != null
                  ? Center(child: Text(widget.searchStateProvider.error!, style: const TextStyle(color: Colors.red)))
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 180.0),
                        child: Column(
                          children: [
                            _buildSongList(),
                            _buildAlbumList(),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSongList() {
    if (widget.searchStateProvider.isLoading && widget.searchStateProvider.searchResults.isEmpty) {
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
          ...List.generate(5, (index) => const SongSkeletonLoader()),
        ],
      );
    }

    if (widget.searchStateProvider.searchResults.isEmpty) return const SizedBox.shrink();

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
        ...widget.searchStateProvider.searchResults.map((song) => ListTile(
          leading: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
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
                  ],
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
                widget.playerService.playSong(song);
              } else if (value == 'add_to_queue') {
                widget.playerService.addToQueue(song);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Added to queue'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else if (value == 'download') {
                await _downloadInBrowser(song);
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
              const PopupMenuItem(
                value: 'download',
                child: Text('Download in Browser'),
              ),
            ],
          ),
          onTap: () {
            widget.playerService.playSong(song);
          },
        )).toList(),
      ],
    );
  }

  Widget _buildAlbumList() {
    if (widget.searchStateProvider.isLoading && widget.searchStateProvider.albumResults.isEmpty) {
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
          ...List.generate(3, (index) => const AlbumSkeletonLoader()),
        ],
      );
    }

    if (widget.searchStateProvider.albumResults.isEmpty) return const SizedBox.shrink();

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
        ...widget.searchStateProvider.albumResults.map((album) => ListTile(
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
                  playlistService: widget.playlistService,
                ),
              ),
            );
          },
        )).toList(),
      ],
    );
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
} 