import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/playlist.dart';
import '../models/play_history_item.dart';

class PlayHistoryService {
  static const String _historyKey = 'play_history';
  static const int _maxHistoryItems = 20;
  
  final SharedPreferences _prefs;
  List<PlayHistoryItem> _history = [];

  PlayHistoryService(this._prefs) {
    _loadHistory();
  }

  List<PlayHistoryItem> get history => List.unmodifiable(_history);

  void _loadHistory() {
    try {
      final historyJson = _prefs.getStringList(_historyKey) ?? [];
      _history = historyJson
          .map((json) {
            try {
              final Map<String, dynamic> decoded = jsonDecode(json);
              return PlayHistoryItem.fromJson(decoded);
            } catch (e) {
              print('Error decoding history item: $e');
              return null;
            }
          })
          .whereType<PlayHistoryItem>()
          .toList();
    } catch (e) {
      print('Error loading history: $e');
      _history = [];
    }
  }

  Future<void> addToHistory(Song song, {Album? album, Playlist? playlist}) async {
    PlayHistoryItem? itemToAdd;

    // If the song is from an album or playlist, add that instead
    if (album != null) {
      itemToAdd = PlayHistoryItem.fromAlbum(album);
    } else if (playlist != null) {
      itemToAdd = PlayHistoryItem.fromPlaylist(playlist);
    } else {
      itemToAdd = PlayHistoryItem.fromSong(song);
    }

    // Remove if already exists to avoid duplicates
    _history.removeWhere((item) => item.id == itemToAdd!.id);
    
    // Add to beginning of list
    _history.insert(0, itemToAdd);
    
    // Keep only the most recent items
    if (_history.length > _maxHistoryItems) {
      _history = _history.sublist(0, _maxHistoryItems);
    }
    
    await _saveHistory();
  }

  Future<void> _saveHistory() async {
    try {
      final historyJson = _history
          .map((item) => jsonEncode(item.toJson()))
          .toList();
      await _prefs.setStringList(_historyKey, historyJson);
    } catch (e) {
      print('Error saving history: $e');
    }
  }

  Future<void> clearHistory() async {
    _history.clear();
    await _prefs.remove(_historyKey);
  }
} 