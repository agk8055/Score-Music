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
import '../widgets/bottom_navigation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';  // Import main.dart to access MyHomePage and SearchStateProvider
import '../services/play_history_service.dart';
import '../services/search_cache_service.dart';

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
  static const int _songsPerPage = 5;

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

      if (widget.initialPlaylist != null) {
        _playlist = widget.initialPlaylist;
      } else {
        if (_cacheService.hasCachedPlaylist(widget.playlistUrl)) {
          _playlist = _cacheService.getCachedPlaylist(widget.playlistUrl);
        } else {
          _playlist = await _apiService.getPlaylistDetails(widget.playlistUrl);
          _cacheService.cachePlaylist(_playlist!);
        }
      }

      final initialSongIds = _playlist!.contentList.sublist(0, _songsPerPage);
      List<Song> initialSongs = _cacheService.getCachedSongs(initialSongIds);
      
      if (initialSongs.length < initialSongIds.length) {
        final missingIds = initialSongIds.where(
          (id) => !initialSongs.any((song) => song.id == id)
        ).toList();
        
        if (missingIds.isNotEmpty) {
          final newSongs = await _apiService.getPlaylistSongs(missingIds);
          _cacheService.cacheSongs(newSongs);
          initialSongs.addAll(newSongs);
        }
      }

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

      final moreSongIds = _playlist!.contentList.sublist(startIndex, endIndex);
      List<Song> moreSongs = _cacheService.getCachedSongs(moreSongIds);
      
      if (moreSongs.length < moreSongIds.length) {
        final missingIds = moreSongIds.where(
          (id) => !moreSongs.any((song) => song.id == id)
        ).toList();
        
        if (missingIds.isNotEmpty) {
          final newSongs = await _apiService.getPlaylistSongs(missingIds);
          _cacheService.cacheSongs(newSongs);
          moreSongs.addAll(newSongs);
        }
      }

      if (mounted) {
        setState(() {
          _songs.addAll(moreSongs);
          _currentPage++;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
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
      playlistService: widget.playlistService,
      appBar: null,
      bottomNavigationBar: BottomNavigation(
        selectedIndex: 2,
        onDestinationSelected: (index) async {
          if (index == 2) {
            Navigator.pop(context);
          } else {
            final prefs = await SharedPreferences.getInstance();
            final historyService = PlayHistoryService(prefs);
            final searchCacheService = SearchCacheService(prefs);
            final searchStateProvider = SearchStateProvider(searchCacheService);
            
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MyHomePage(
                  playerService: widget.playerService,
                  historyService: historyService,
                  searchCacheService: searchCacheService,
                  searchStateProvider: searchStateProvider,
                  playlistService: widget.playlistService,
                  initialIndex: index,
                ),
              ),
            );
          }
        },
        isLibraryScreen: true,
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
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 280,
                      collapsedHeight: 80,
                      pinned: true,
                      automaticallyImplyLeading: false,
                      backgroundColor: Colors.black,
                      stretch: true,
                      flexibleSpace: FlexibleSpaceBar(
                        stretchModes: const [
                          StretchMode.zoomBackground,
                          StretchMode.blurBackground,
                        ],
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              _playlist!.image,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: const Color(0xFF1A1A1A),
                                  child: const Icon(
                                    Icons.playlist_play,
                                    size: 100,
                                    color: Colors.white54,
                                  ),
                                );
                              },
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.4),
                                    Colors.black.withOpacity(0.8),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 20,
                              left: 20,
                              right: 20,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _playlist!.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF5D505),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${_playlist!.fanCount} Fans',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    if (_songs.isNotEmpty) {
                                      widget.playerService.playSong(_songs[0], playlist: _playlist);
                                      for (var i = 1; i < _songs.length; i++) {
                                        widget.playerService.addToQueue(_songs[i]);
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.play_arrow, size: 24),
                                  label: const Text('PLAY ALL',
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF5D505),
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFF5D505)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  onPressed: () {},
                                  icon: const Icon(Icons.shuffle, color: Color(0xFFF5D505)),
                                  padding: const EdgeInsets.all(16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            '${_songs.length} Songs',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ]),
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
                                        borderRadius: BorderRadius.circular(8),
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
                        : SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  if (index == _songs.length && _isLoadingMore) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: CircularProgressIndicator(
                                          color: Color(0xFFF5D505),
                                        ),
                                      ),
                                    );
                                  }
                                  final song = _songs[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[900]?.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                      leading: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Image.network(
                                              song.image,
                                              width: 56,
                                              height: 56,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  width: 56,
                                                  height: 56,
                                                  color: Colors.grey[800],
                                                  child: const Icon(Icons.music_note,
                                                      color: Colors.white54),
                                                );
                                              },
                                            ),
                                            if (_downloadingSongId == song.id && _downloadProgress[song.id] != null)
                                              Positioned.fill(
                                                child: Container(
                                                  color: Colors.black.withOpacity(0.7),
                                                  child: Center(
                                                    child: CircularProgressIndicator(
                                                      value: _downloadProgress[song.id],
                                                      strokeWidth: 3,
                                                      backgroundColor: Colors.white24,
                                                      valueColor: AlwaysStoppedAnimation<Color>(
                                                          const Color(0xFFF5D505)),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      title: Text(
                                        song.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        song.primaryArtists,
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (_downloadingSongId == song.id)
                                            IconButton(
                                              icon: const Icon(Icons.close,
                                                  color: Colors.white, size: 20),
                                              onPressed: () {
                                                _cancelTokens[song.id]?.cancel();
                                              },
                                            ),
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert,
                                                color: Colors.white70),
                                            onSelected: (value) async {
                                              if (value == 'play') {
                                                widget.playerService.playSong(song, playlist: _playlist);
                                                for (var i = _songs.indexOf(song) + 1; 
                                                    i < _playlist!.contentList.length; i++) {
                                                  if (i < _songs.length) {
                                                    widget.playerService.addToQueue(_songs[i]);
                                                  } else {
                                                    _apiService.getPlaylistSongs([_playlist!.contentList[i]])
                                                        .then((newSongs) {
                                                      if (newSongs.isNotEmpty) {
                                                        widget.playerService.addToQueue(newSongs[0]);
                                                      }
                                                    });
                                                  }
                                                }
                                              } else if (value == 'add_to_queue') {
                                                widget.playerService.addToQueue(song);
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: const Text('Added to queue'),
                                                      backgroundColor: const Color(0xFFF5D505),
                                                      behavior: SnackBarBehavior.floating,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
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
                                                  if (!cancelToken.isCancelled) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: const Text('Song downloaded successfully'),
                                                        backgroundColor: const Color(0xFFF5D505),
                                                        behavior: SnackBarBehavior.floating,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                } catch (e) {
                                                  if (cancelToken.isCancelled) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: const Text('Download cancelled'),
                                                        backgroundColor: Colors.grey[800],
                                                        behavior: SnackBarBehavior.floating,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                      ),
                                                    );
                                                  } else {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Download failed: $e'),
                                                        backgroundColor: Colors.red[800],
                                                        behavior: SnackBarBehavior.floating,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
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
                                                    Text('Play Now', style: TextStyle(color: Colors.white)),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'add_to_queue',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.queue_music, color: Colors.white),
                                                    SizedBox(width: 8),
                                                    Text('Add to Queue', style: TextStyle(color: Colors.white)),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'download',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.download, color: Colors.white),
                                                    SizedBox(width: 8),
                                                    Text('Download', style: TextStyle(color: Colors.white)),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'add_to_playlist',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.playlist_add, color: Colors.white),
                                                    SizedBox(width: 8),
                                                    Text('Add to Playlist', style: TextStyle(color: Colors.white)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        widget.playerService.playSong(song, playlist: _playlist);
                                        for (var i = _songs.indexOf(song) + 1; 
                                            i < _playlist!.contentList.length; i++) {
                                          if (i < _songs.length) {
                                            widget.playerService.addToQueue(_songs[i]);
                                          } else {
                                            _apiService.getPlaylistSongs([_playlist!.contentList[i]])
                                                .then((newSongs) {
                                              if (newSongs.isNotEmpty) {
                                                widget.playerService.addToQueue(newSongs[0]);
                                              }
                                            });
                                          }
                                        }
                                      },
                                    ),
                                  );
                                },
                                childCount: _songs.length + (_isLoadingMore ? 1 : 0),
                              ),
                            ),
                          ),
                  ],
                ),
    );
  }
}