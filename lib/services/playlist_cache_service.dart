import '../models/playlist.dart';
import '../models/song.dart';

class PlaylistCacheService {
  static final PlaylistCacheService _instance = PlaylistCacheService._internal();
  factory PlaylistCacheService() => _instance;
  PlaylistCacheService._internal();

  final Map<String, _PlaylistCacheEntry> _playlistCache = {};
  final Map<String, _SongCacheEntry> _songCache = {};
  static const Duration _cacheDuration = Duration(minutes: 10);

  void cachePlaylist(Playlist playlist) {
    _playlistCache[playlist.url] = _PlaylistCacheEntry(
      playlist: playlist,
      timestamp: DateTime.now(),
    );
  }

  void cacheSongs(List<Song> songs) {
    for (var song in songs) {
      _songCache[song.id] = _SongCacheEntry(
        song: song,
        timestamp: DateTime.now(),
      );
    }
  }

  Playlist? getCachedPlaylist(String url) {
    final entry = _playlistCache[url];
    if (entry != null) {
      // Check if cache is still valid
      if (DateTime.now().difference(entry.timestamp) <= _cacheDuration) {
        return entry.playlist;
      } else {
        // Remove expired cache
        _playlistCache.remove(url);
      }
    }
    return null;
  }

  List<Song> getCachedSongs(List<String> songIds) {
    final now = DateTime.now();
    final songs = <Song>[];
    final missingIds = <String>[];

    for (var id in songIds) {
      final entry = _songCache[id];
      if (entry != null && now.difference(entry.timestamp) <= _cacheDuration) {
        songs.add(entry.song);
      } else {
        if (entry != null) {
          _songCache.remove(id); // Remove expired cache
        }
        missingIds.add(id);
      }
    }

    return songs;
  }

  bool hasCachedPlaylist(String url) {
    final entry = _playlistCache[url];
    if (entry != null) {
      // Check if cache is still valid
      if (DateTime.now().difference(entry.timestamp) <= _cacheDuration) {
        return true;
      } else {
        // Remove expired cache
        _playlistCache.remove(url);
      }
    }
    return false;
  }

  void clearCache() {
    _playlistCache.clear();
    _songCache.clear();
  }
}

class _PlaylistCacheEntry {
  final Playlist playlist;
  final DateTime timestamp;

  _PlaylistCacheEntry({
    required this.playlist,
    required this.timestamp,
  });
}

class _SongCacheEntry {
  final Song song;
  final DateTime timestamp;

  _SongCacheEntry({
    required this.song,
    required this.timestamp,
  });
} 