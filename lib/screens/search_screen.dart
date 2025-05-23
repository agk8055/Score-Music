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
import '../services/download_service.dart';
import '../services/playlist_service.dart';
import 'package:dio/dio.dart';

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

  // Download progress tracking
  final Map<String, double> _downloadProgress = {};
  String? _downloadingSongId;
  final Map<String, CancelToken> _cancelTokens = {};

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
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) => const SongSkeletonLoader(),
          ),
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
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.searchStateProvider.searchResults.length,
          itemBuilder: (context, index) {
            final song = widget.searchStateProvider.searchResults[index];
            return ListTile(
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
                        if (_downloadingSongId == song.id && _downloadProgress[song.id] != null)
                          CircularProgressIndicator(
                            value: _downloadProgress[song.id],
                            strokeWidth: 4,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF5D505)),
                          ),
                      ],
                    ),
                  ),
                  if (_downloadingSongId == song.id && _downloadProgress[song.id] != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          _cancelTokens[song.id]?.cancel();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(Icons.close, size: 16, color: Colors.white),
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
                    setState(() {
                      _downloadingSongId = song.id;
                      _downloadProgress[song.id] = 0.0;
                    });
                    final downloadService = DownloadService();
                    final cancelToken = CancelToken();
                    _cancelTokens[song.id] = cancelToken;
                    try {
                      await downloadService.downloadSong(
                        song,
                        onProgress: (progress) {
                          setState(() {
                            _downloadProgress[song.id] = progress;
                          });
                        },
                        cancelToken: cancelToken,
                      );
                      if (!cancelToken.isCancelled) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Song downloaded successfully'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (cancelToken.isCancelled) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Download cancelled'),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Download failed: $e'),
                          ),
                        );
                      }
                    } finally {
                      setState(() {
                        _downloadingSongId = null;
                        _downloadProgress.remove(song.id);
                        _cancelTokens.remove(song.id);
                      });
                    }
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
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) => const AlbumSkeletonLoader(),
          ),
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
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.searchStateProvider.albumResults.length,
          itemBuilder: (context, index) {
            final album = widget.searchStateProvider.albumResults[index];
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
                      playlistService: widget.playlistService,
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
                  : ListView(
                      children: [
                        _buildSongList(),
                        _buildAlbumList(),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
} 