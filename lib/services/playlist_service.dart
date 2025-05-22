import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_playlist.dart';

class PlaylistService {
  static const String _userPlaylistsKey = 'user_playlists';
  final SharedPreferences _prefs;

  PlaylistService(this._prefs);

  // Get user-created playlists from local storage
  List<UserPlaylist> getUserPlaylists() {
    final String? playlistsJson = _prefs.getString(_userPlaylistsKey);
    if (playlistsJson == null) return [];

    final List<dynamic> decoded = jsonDecode(playlistsJson);
    return decoded.map((json) => UserPlaylist.fromJson(json)).toList();
  }

  // Create a new user playlist
  Future<void> createUserPlaylist(String name) async {
    final playlists = getUserPlaylists();
    final newPlaylist = UserPlaylist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
    );
    
    playlists.add(newPlaylist);
    await _saveUserPlaylists(playlists);
  }

  // Delete a user playlist
  Future<void> deleteUserPlaylist(String id) async {
    final playlists = getUserPlaylists();
    playlists.removeWhere((playlist) => playlist.id == id);
    await _saveUserPlaylists(playlists);
  }

  // Add a song to a user playlist
  Future<void> addSongToUserPlaylist(String playlistId, String songId) async {
    final playlists = getUserPlaylists();
    final playlistIndex = playlists.indexWhere((p) => p.id == playlistId);
    
    if (playlistIndex != -1) {
      final playlist = playlists[playlistIndex];
      final updatedSongIds = List<String>.from(playlist.songIds)..add(songId);
      
      playlists[playlistIndex] = playlist.copyWith(
        songIds: updatedSongIds,
        lastUpdated: DateTime.now(),
      );
      
      await _saveUserPlaylists(playlists);
    }
  }

  // Remove a song from a user playlist
  Future<void> removeSongFromUserPlaylist(String playlistId, String songId) async {
    final playlists = getUserPlaylists();
    final playlistIndex = playlists.indexWhere((p) => p.id == playlistId);
    
    if (playlistIndex != -1) {
      final playlist = playlists[playlistIndex];
      final updatedSongIds = List<String>.from(playlist.songIds)..remove(songId);
      
      playlists[playlistIndex] = playlist.copyWith(
        songIds: updatedSongIds,
        lastUpdated: DateTime.now(),
      );
      
      await _saveUserPlaylists(playlists);
    }
  }

  // Save user playlists to local storage
  Future<void> _saveUserPlaylists(List<UserPlaylist> playlists) async {
    final String encoded = jsonEncode(playlists.map((p) => p.toJson()).toList());
    await _prefs.setString(_userPlaylistsKey, encoded);
  }
} 