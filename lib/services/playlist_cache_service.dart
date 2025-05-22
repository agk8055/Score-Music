import '../models/playlist.dart';

class PlaylistCacheService {
  static final PlaylistCacheService _instance = PlaylistCacheService._internal();
  factory PlaylistCacheService() => _instance;
  PlaylistCacheService._internal();

  final Map<String, Playlist> _playlistCache = {};

  void cachePlaylist(Playlist playlist) {
    _playlistCache[playlist.url] = playlist;
  }

  Playlist? getCachedPlaylist(String url) {
    return _playlistCache[url];
  }

  bool hasCachedPlaylist(String url) {
    return _playlistCache.containsKey(url);
  }

  void clearCache() {
    _playlistCache.clear();
  }
} 