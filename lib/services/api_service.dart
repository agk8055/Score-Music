import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song.dart';
import '../models/album.dart';
import '../models/playlist.dart';

class ApiService {
  static const String baseUrl = 'https://jiosaavnapi-bok7.onrender.com';

  Future<Map<String, dynamic>> search(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/song/?query=$query'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final songs = data.map((json) => Song.fromJson(json)).toList();
        
        // Return songs immediately
        return {
          'songs': songs.take(5).toList(), // Limit to 5 songs
          'albums': [], // Return empty albums list initially
        };
      } else {
        throw Exception('Failed to load search results');
      }
    } catch (e) {
      throw Exception('Error searching: $e');
    }
  }

  Future<List<Album>> loadAlbumsForSongs(List<Song> songs) async {
    try {
      // Get unique album URLs from songs
      final albumUrls = songs
          .map((song) => song.albumUrl)
          .where((url) => url.isNotEmpty)
          .toSet()
          .toList();

      // Fetch album details for each unique album URL
      final albums = <Album>[];
      for (final url in albumUrls) {
        try {
          final albumResponse = await http.get(
            Uri.parse('$baseUrl/album/?query=$url'),
          );
          if (albumResponse.statusCode == 200) {
            final albumData = json.decode(albumResponse.body);
            if (albumData is Map<String, dynamic>) {
              albums.add(Album.fromJson(albumData));
            }
          }
        } catch (e) {
          print('Error fetching album details: $e');
        }
      }
      return albums;
    } catch (e) {
      print('Error loading albums: $e');
      return [];
    }
  }

  Future<List<Song>> getAlbumDetails(String albumUrl) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/album/?query=$albumUrl'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['songs'] != null && data['songs'] is List) {
          final List<dynamic> songsData = data['songs'];
          return songsData.map((json) => Song.fromJson(json)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load album details');
      }
    } catch (e) {
      print('Error loading album details: $e');
      throw Exception('Error loading album details: $e');
    }
  }

  Future<Playlist> getPlaylistDetails(String playlistUrl) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/playlist/?query=$playlistUrl'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Playlist.fromJson(data);
      } else {
        throw Exception('Failed to load playlist details');
      }
    } catch (e) {
      throw Exception('Error loading playlist details: $e');
    }
  }

  Future<List<Song>> getPlaylistSongs(List<String> songIds) async {
    try {
      final songs = <Song>[];
      for (final id in songIds) {
        try {
          final response = await http.get(
            Uri.parse('$baseUrl/song/get/?id=$id'),
          );
          if (response.statusCode == 200) {
            final Map<String, dynamic> data = json.decode(response.body);
            songs.add(Song.fromJson(data));
          }
        } catch (e) {
          print('Error fetching song $id: $e');
        }
      }
      return songs;
    } catch (e) {
      throw Exception('Error loading playlist songs: $e');
    }
  }
} 