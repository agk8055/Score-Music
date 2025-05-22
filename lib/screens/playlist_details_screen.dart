import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../services/api_service.dart';
import '../services/music_player_service.dart';
import '../services/playlist_cache_service.dart';
import '../services/download_service.dart';
import '../services/playlist_service.dart';
import '../widgets/base_scaffold.dart';
import '../widgets/playlist_selection_dialog.dart';

class PlaylistDetailsScreen extends StatefulWidget {
  final MusicPlayerService playerService;
  final String playlistUrl;
  final Playlist? initialPlaylist;
  final PlaylistService playlistService;

  const PlaylistDetailsScreen({
    Key? key,
    required this.playerService,
    required this.playlistUrl,
    required this.playlistService,
    this.initialPlaylist,
  }) : super(key: key);

  @override
  State<PlaylistDetailsScreen> createState() => _PlaylistDetailsScreenState();
}

class _PlaylistDetailsScreenState extends State<PlaylistDetailsScreen> {
  final ApiService _apiService = ApiService();
  final PlaylistCacheService _cacheService = PlaylistCacheService();
  final ScrollController _scrollController = ScrollController();
  Playlist? _playlist;
  List<Song> _songs = [];
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
    _loadPlaylist();
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

  Future<void> _loadPlaylist() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Use initial playlist if provided
      if (widget.initialPlaylist != null) {
        _playlist = widget.initialPlaylist;
      } else {
        // Check cache first
        if (_cacheService.hasCachedPlaylist(widget.playlistUrl)) {
          _playlist = _cacheService.getCachedPlaylist(widget.playlistUrl);
        } else {
          _playlist = await _apiService.getPlaylistDetails(widget.playlistUrl);
          _cacheService.cachePlaylist(_playlist!);
        }
      }

      // Load initial songs
      final initialSongs = await _apiService.getPlaylistSongs(
        _playlist!.contentList.sublist(0, _songsPerPage),
      );

      setState(() {
        _songs = initialSongs;
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
    if (_isLoadingMore || _playlist == null) return;

    final startIndex = _currentPage * _songsPerPage;
    if (startIndex >= _playlist!.contentList.length) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final endIndex = (startIndex + _songsPerPage) > _playlist!.contentList.length
          ? _playlist!.contentList.length
          : startIndex + _songsPerPage;

      final moreSongs = await _apiService.getPlaylistSongs(
        _playlist!.contentList.sublist(startIndex, endIndex),
      );

      setState(() {
        _songs.addAll(moreSongs);
        _currentPage++;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
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
    return BaseScaffold(
      playerService: widget.playerService,
      appBar: AppBar(
        title: Text(
          _playlist?.name ?? 'Playlist',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : _playlist == null
              ? const Center(child: Text('Playlist not found'))
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
                              _playlist!.image,
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
                                        _playlist!.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        if (_songs.isNotEmpty) {
                                          widget.playerService.playSong(_songs[0], playlist: _playlist);
                                          // Add remaining songs to queue
                                          for (var i = 1; i < _songs.length; i++) {
                                            widget.playerService.addToQueue(_songs[i]);
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
                                  '${_playlist!.fanCount} Fans',
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
                                if (index == _songs.length && _isLoadingMore) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                final song = _songs[index];
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
                                        widget.playerService.playSong(song, playlist: _playlist);
                                        // Add remaining songs to queue
                                        final currentIndex = _songs.indexOf(song);
                                        for (var i = currentIndex + 1; i < _songs.length; i++) {
                                          widget.playerService.addToQueue(_songs[i]);
                                        }
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
                                          if (!cancelToken.cancelled) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Song downloaded successfully'),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (cancelToken.cancelled) {
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
                                      } else if (value == 'add_to_playlist') {
                                        _showAddToPlaylistDialog(song);
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
                                        value: 'add_to_playlist',
                                        child: Row(
                                          children: [
                                            Icon(Icons.playlist_add, color: Colors.white),
                                            SizedBox(width: 8),
                                            Text('Add to Playlist'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    widget.playerService.playSong(song, playlist: _playlist);
                                    // Add remaining songs to queue
                                    final currentIndex = _songs.indexOf(song);
                                    for (var i = currentIndex + 1; i < _songs.length; i++) {
                                      widget.playerService.addToQueue(_songs[i]);
                                    }
                                  },
                                );
                              },
                              childCount: _songs.length + (_isLoadingMore ? 1 : 0),
                            ),
                          ),
                  ],
                ),
    );
  }
} 