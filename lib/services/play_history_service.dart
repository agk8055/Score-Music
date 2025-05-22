import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

class PlayHistoryService {
  static const String _historyKey = 'play_history';
  static const int _maxHistoryItems = 20;
  
  final SharedPreferences _prefs;
  List<Song> _history = [];

  PlayHistoryService(this._prefs) {
    _loadHistory();
  }

  List<Song> get history => List.unmodifiable(_history);

  void _loadHistory() {
    final historyJson = _prefs.getStringList(_historyKey) ?? [];
    _history = historyJson
        .map((json) => Song.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> addToHistory(Song song) async {
    // Remove if already exists to avoid duplicates
    _history.removeWhere((s) => s.id == song.id);
    
    // Add to beginning of list
    _history.insert(0, song);
    
    // Keep only the most recent items
    if (_history.length > _maxHistoryItems) {
      _history = _history.sublist(0, _maxHistoryItems);
    }
    
    await _saveHistory();
  }

  Future<void> _saveHistory() async {
    final historyJson = _history
        .map((song) => jsonEncode(song.toJson()))
        .toList();
    await _prefs.setStringList(_historyKey, historyJson);
  }

  Future<void> clearHistory() async {
    _history.clear();
    await _prefs.remove(_historyKey);
  }
} 