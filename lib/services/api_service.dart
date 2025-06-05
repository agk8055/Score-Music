import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/playlist.dart';
import 'dart:async';

class ApiService {
  static const String defaultBaseUrl = 'https://jiosaavnapi-tyye.onrender.com/';
  static String baseUrl = defaultBaseUrl;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('backend_url');
    if (savedUrl != null) {
      baseUrl = savedUrl;
    }
  }

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
      if (albumUrl.isEmpty) {
        throw Exception('Album URL cannot be empty');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/album/?query=$albumUrl'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timed out. Please check your internet connection.');
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['songs'] != null && data['songs'] is List) {
          final List<dynamic> songsData = data['songs'];
          return songsData.map((json) => Song.fromJson(json)).toList();
        }
        return [];
      } else if (response.statusCode == 404) {
        throw Exception('Album not found');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception('Failed to load album details (Status: ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
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
    final songs = <Song>[];
    final maxRetries = 3;
    final retryDelay = const Duration(seconds: 1);

    for (final id in songIds) {
      int retryCount = 0;
      while (retryCount < maxRetries) {
        try {
          final response = await http.get(
            Uri.parse('$baseUrl/song/get/?id=$id'),
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Request timed out');
            },
          );

          if (response.statusCode == 200) {
            final Map<String, dynamic> data = json.decode(response.body);
            songs.add(Song.fromJson(data));
            break; // Success, exit retry loop
          } else if (response.statusCode >= 500) {
            // Server error, retry
            retryCount++;
            if (retryCount < maxRetries) {
              await Future.delayed(retryDelay * retryCount);
              continue;
            }
          }
          // For other status codes, don't retry
          break;
        } catch (e) {
          retryCount++;
          if (retryCount < maxRetries) {
            await Future.delayed(retryDelay * retryCount);
            continue;
          }
          print('Error fetching song $id after $maxRetries retries: $e');
        }
      }
    }
    return songs;
  }
} 