import 'package:flutter/material.dart';
import '../models/album.dart';
import '../models/song.dart';
import '../services/api_service.dart';
import '../services/music_player_service.dart';
import '../services/playlist_service.dart';
import '../widgets/base_scaffold.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/skeleton_loader.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/play_history_service.dart';
import '../services/search_cache_service.dart';
import '../main.dart';  // This contains SearchStateProvider and MyHomePage

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

    setState(() {
      _isLoadingMore = true;
      _error = null;
    });

    try {
      final allSongs = await _apiService.getAlbumDetails(widget.album.url);
      final startIndex = _currentPage * _songsPerPage;
      
      if (startIndex >= allSongs.length) {
        setState(() {
          _isLoadingMore = false;
        });
        return;
      }

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
        _error = e.toString();
      });
      
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load more songs: ${e.toString()}'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadMoreSongs,
            ),
          ),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      playerService: widget.playerService,
      playlistService: widget.playlistService,
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadAlbumSongs,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5D505),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Retry',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _isLoading
              ? _buildSkeletonLoader()
              : CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      expandedHeight: MediaQuery.of(context).size.width * 0.8,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.network(
                                widget.album.image,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[900],
                                    child: const Center(
                                      child: Icon(
                                        Icons.album,
                                        size: 100,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.8),
                                    Colors.black.withOpacity(0.2),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
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
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                GestureDetector(
                                  onTap: () {
                                    if (_albumSongs.isNotEmpty) {
                                      widget.playerService.playSong(_albumSongs[0], album: widget.album);
                                      for (var i = 1; i < _albumSongs.length; i++) {
                                        widget.playerService.addToQueue(_albumSongs[i]);
                                      }
                                    }
                                  },
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5D505),
                                      borderRadius: BorderRadius.circular(28),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFF5D505).withOpacity(0.4),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow,
                                      size: 32,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.album.primaryArtists,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  widget.album.year,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[400],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                Text(
                                  widget.album.language,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: Colors.white24),
                          ],
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= _albumSongs.length) {
                            return _isLoadingMore
                                ? Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFF5D505)),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink();
                          }
                          
                          final song = _albumSongs[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[900]!.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              leading: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[800],
                                ),
                                child: ClipRRect(
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
                                            color: Colors.grey[800],
                                            child: const Icon(
                                              Icons.music_note,
                                              color: Colors.white54,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
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
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.more_vert, color: Colors.white70),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Colors.grey[900],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                    ),
                                    builder: (context) {
                                      return SafeArea(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListTile(
                                              leading: const Icon(Icons.play_arrow, color: Colors.white),
                                              title: const Text('Play Now', style: TextStyle(color: Colors.white)),
                                              onTap: () {
                                                Navigator.pop(context);
                                                widget.playerService.playSong(song);
                                              },
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.queue_music, color: Colors.white),
                                              title: const Text('Add to Queue', style: TextStyle(color: Colors.white)),
                                              onTap: () {
                                                Navigator.pop(context);
                                                widget.playerService.addToQueue(song);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: const Text('Added to queue'),
                                                    backgroundColor: const Color(0xFFF5D505),
                                                    duration: const Duration(seconds: 2),
                                                    behavior: SnackBarBehavior.floating,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.download, color: Colors.white),
                                              title: const Text('Download in Browser', style: TextStyle(color: Colors.white)),
                                              onTap: () async {
                                                Navigator.pop(context);
                                                await _downloadInBrowser(song);
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              onTap: () {
                                widget.playerService.playSong(song, album: widget.album);
                                final currentIndex = _albumSongs.indexOf(song);
                                for (var i = currentIndex + 1; i < _albumSongs.length; i++) {
                                  widget.playerService.addToQueue(_albumSongs[i]);
                                }
                              },
                            ),
                          );
                        },
                        childCount: _albumSongs.length + (_isLoadingMore ? 1 : 0),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 150),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSkeletonLoader() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: MediaQuery.of(context).size.width * 0.8,
          flexibleSpace: const SkeletonLoader(
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoader(width: 200, height: 32),
                const SizedBox(height: 16),
                const SkeletonLoader(width: 150, height: 24),
                const SizedBox(height: 16),
                const SkeletonLoader(width: 100, height: 20),
                const SizedBox(height: 24),
                const Divider(color: Colors.white24),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            SongSkeletonLoader(),
            SongSkeletonLoader(),
            SongSkeletonLoader(),
            SongSkeletonLoader(),
            SongSkeletonLoader(),
            SongSkeletonLoader(),
            SongSkeletonLoader(),
            SongSkeletonLoader(),
            SongSkeletonLoader(),
            SongSkeletonLoader(),
          ]),
        ),
      ],
    );
  }
}