import 'package:flutter/material.dart';
import '../models/album.dart';
import '../models/song.dart';
import '../services/api_service.dart';
import '../services/music_player_service.dart';
import '../services/download_service.dart';
import '../services/playlist_service.dart';
import '../widgets/base_scaffold.dart';
import '../widgets/bottom_navigation.dart';
import 'package:dio/dio.dart';

class AlbumDetailsScreen extends StatefulWidget {
  final Album album;
  final MusicPlayerService playerService;
  final PlaylistService playlistService;

  const AlbumDetailsScreen({
    super.key,
    required this.album,
    required this.playerService,
    required this.playlistService,
  });

  @override
  State<AlbumDetailsScreen> createState() => _AlbumDetailsScreenState();
}

class _AlbumDetailsScreenState extends State<AlbumDetailsScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  List<Song> _albumSongs = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 0;
  static const int _songsPerPage = 10;

  // Download progress tracking
  final Map<String, double> _downloadProgress = {};
  String? _downloadingSongId;
  final Map<String, CancelToken> _cancelTokens = {};

  @override
  void initState() {
    super.initState();
    _loadAlbumSongs();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreSongs();
    }
  }

  Future<void> _loadAlbumSongs() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final allSongs = await _apiService.getAlbumDetails(widget.album.url);
      final initialSongs = allSongs.sublist(0, _songsPerPage > allSongs.length ? allSongs.length : _songsPerPage);

      setState(() {
        _albumSongs = initialSongs;
        _isLoading = false;
        _currentPage = 1;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreSongs() async {
    if (_isLoadingMore) return;

    final allSongs = await _apiService.getAlbumDetails(widget.album.url);
    final startIndex = _currentPage * _songsPerPage;
    if (startIndex >= allSongs.length) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final endIndex = (startIndex + _songsPerPage) > allSongs.length
          ? allSongs.length
          : startIndex + _songsPerPage;

      final moreSongs = allSongs.sublist(startIndex, endIndex);

      setState(() {
        _albumSongs.addAll(moreSongs);
        _currentPage++;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      playerService: widget.playerService,
      playlistService: widget.playlistService,
      appBar: AppBar(
        title: Text(
          widget.album.name,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AspectRatio(
                            aspectRatio: 1,
                            child: Image.network(
                              widget.album.image,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.album,
                                    size: 100,
                                    color: Colors.white54,
                                  ),
                                );
                              },
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
                                        widget.album.name,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        if (_albumSongs.isNotEmpty) {
                                          widget.playerService.playSong(_albumSongs[0], album: widget.album);
                                          // Add remaining songs to queue
                                          for (var i = 1; i < _albumSongs.length; i++) {
                                            widget.playerService.addToQueue(_albumSongs[i]);
                                          }
                                        }
                                      },
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
                                  widget.album.primaryArtists,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.album.year} • ${widget.album.language}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _isLoadingMore
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
                                if (index == _albumSongs.length && _isLoadingMore) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                final song = _albumSongs[index];
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
                                    widget.playerService.playSong(song, album: widget.album);
                                    // Add remaining songs to queue
                                    final currentIndex = _albumSongs.indexOf(song);
                                    for (var i = currentIndex + 1; i < _albumSongs.length; i++) {
                                      widget.playerService.addToQueue(_albumSongs[i]);
                                    }
                                  },
                                );
                              },
                              childCount: _albumSongs.length + (_isLoadingMore ? 1 : 0),
                            ),
                          ),
                  ],
                ),
    );
  }
} 