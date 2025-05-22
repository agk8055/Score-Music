import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../models/album.dart';

class SearchCacheService {
  static const String _cacheKey = 'search_cache';
  static const String _lastQueryKey = 'last_search_query';
  static const Duration _cacheDuration = Duration(minutes: 30);
  
  final SharedPreferences _prefs;
  Map<String, _CacheEntry> _cache = {};
  String _lastQuery = '';

  SearchCacheService(this._prefs) {
    _loadCache();
    _lastQuery = _prefs.getString(_lastQueryKey) ?? '';
  }

  String get lastQuery => _lastQuery;

  void _loadCache() {
    final cacheJson = _prefs.getString(_cacheKey);
    if (cacheJson != null) {
      try {
        final Map<String, dynamic> decoded = json.decode(cacheJson);
        _cache = decoded.map((key, value) {
          final entry = value as Map<String, dynamic>;
          return MapEntry(key, _CacheEntry.fromJson(entry));
        });
        _cleanExpiredCache();
      } catch (e) {
        print('Error loading search cache: $e');
        _cache = {};
      }
    }
  }

  void _cleanExpiredCache() {
    final now = DateTime.now();
    _cache.removeWhere((_, entry) => 
      now.difference(entry.timestamp) > _cacheDuration);
    _saveCache();
  }

  Future<void> _saveCache() async {
    final cacheJson = json.encode(_cache.map((key, entry) => 
      MapEntry(key, entry.toJson())));
    await _prefs.setString(_cacheKey, cacheJson);
  }

  Map<String, dynamic>? getCachedResults(String query) {
    _cleanExpiredCache();
    final entry = _cache[query];
    if (entry != null) {
      return {
        'songs': entry.songs,
        'albums': entry.albums,
      };
    }
    return null;
  }

  Future<void> cacheResults(String query, List<Song> songs, List<Album> albums) async {
    _cache[query] = _CacheEntry(
      songs: songs,
      albums: albums,
      timestamp: DateTime.now(),
    );
    _lastQuery = query;
    await _prefs.setString(_lastQueryKey, query);
    await _saveCache();
  }

  Future<void> clearCache() async {
    _cache.clear();
    _lastQuery = '';
    await _prefs.remove(_cacheKey);
    await _prefs.remove(_lastQueryKey);
  }
}

class _CacheEntry {
  final List<Song> songs;
  final List<Album> albums;
  final DateTime timestamp;

  _CacheEntry({
    required this.songs,
    required this.albums,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'songs': songs.map((s) => s.toJson()).toList(),
    'albums': albums.map((a) => a.toJson()).toList(),
    'timestamp': timestamp.toIso8601String(),
  };

  factory _CacheEntry.fromJson(Map<String, dynamic> json) {
    return _CacheEntry(
      songs: (json['songs'] as List)
          .map((s) => Song.fromJson(s))
          .toList(),
      albums: (json['albums'] as List)
          .map((a) => Album.fromJson(a))
          .toList(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
} 