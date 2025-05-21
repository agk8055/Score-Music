import 'package:flutter/material.dart';
import '../models/album.dart';
import '../models/song.dart';
import '../services/api_service.dart';
import '../services/music_player_service.dart';
import '../widgets/base_scaffold.dart';

class AlbumDetailsScreen extends StatefulWidget {
  final Album album;
  final MusicPlayerService playerService;

  const AlbumDetailsScreen({
    super.key,
    required this.album,
    required this.playerService,
  });

  @override
  State<AlbumDetailsScreen> createState() => _AlbumDetailsScreenState();
}

class _AlbumDetailsScreenState extends State<AlbumDetailsScreen> {
  final ApiService _apiService = ApiService();
  List<Song> _albumSongs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAlbumSongs();
  }

  Future<void> _loadAlbumSongs() async {
    try {
      final response = await _apiService.getAlbumDetails(widget.album.url);
      setState(() {
        _albumSongs = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      playerService: widget.playerService,
      appBar: AppBar(
        title: Text(
          widget.album.name,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : CustomScrollView(
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
                                Text(
                                  widget.album.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
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
                          const Divider(color: Colors.white24),
                        ],
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final song = _albumSongs[index];
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
                            onTap: () {
                              widget.playerService.playSong(song);
                            },
                          );
                        },
                        childCount: _albumSongs.length,
                      ),
                    ),
                  ],
                ),
    );
  }
} 