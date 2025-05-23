import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../models/song.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  static const String _downloadedSongsKey = 'downloaded_songs';

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${directory.path}/downloads');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    return downloadsDir.path;
  }

  Future<bool> isDownloaded(Song song) async {
    final localPath = await _localPath;
    final file = File('$localPath/${song.id}.mp3');
    return await file.exists();
  }

  Future<String?> getLocalPath(Song song) async {
    if (await isDownloaded(song)) {
      final localPath = await _localPath;
      return '$localPath/${song.id}.mp3';
    }
    return null;
  }

  Future<void> downloadSong(Song song, {Function(double)? onProgress, CancelToken? cancelToken}) async {
    try {
      // First save the song metadata
      await saveDownloadedSong(song);
      
      final localPath = await _localPath;
      final file = File('$localPath/${song.id}.mp3');
      
      if (await file.exists()) {
        return; // Already downloaded
      }

      final response = await http.Client().send(
        http.Request('GET', Uri.parse(song.mediaUrl))
      );

      final totalBytes = response.contentLength ?? 0;
      var receivedBytes = 0;

      final sink = file.openWrite();
      try {
        await response.stream.listen(
          (chunk) async {
            if (cancelToken != null && cancelToken.isCancelled) {
              await sink.close();
              await file.delete();
              throw Exception('Download cancelled');
            }
            sink.add(chunk);
            receivedBytes += chunk.length;
            if (onProgress != null && totalBytes > 0) {
              onProgress(receivedBytes / totalBytes);
            }
          },
          onDone: () async {
            await sink.close();
          },
        ).asFuture();
      } catch (e) {
        if (cancelToken != null && cancelToken.isCancelled) {
          // Already handled
        } else {
          rethrow;
        }
      }
    } catch (e) {
      print('Error downloading song: $e');
      rethrow;
    }
  }

  Future<void> deleteDownload(Song song) async {
    try {
      final localPath = await _localPath;
      final file = File('$localPath/${song.id}.mp3');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting downloaded song: $e');
      rethrow;
    }
  }

  Future<List<Song>> getDownloadedSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final songsJson = prefs.getStringList(_downloadedSongsKey) ?? [];
    final savedSongs = songsJson.map((json) => Song.fromJson(jsonDecode(json))).toList();
    final savedIds = savedSongs.map((s) => s.id).toSet();

    // Scan downloads directory for .mp3 files
    final localPath = await _localPath;
    final downloadsDir = Directory(localPath);
    final files = await downloadsDir.exists() ? await downloadsDir.list().toList() : <FileSystemEntity>[];
    final mp3Files = files.whereType<File>().where((f) => f.path.endsWith('.mp3')).toList();

    // For each file, extract ID and add placeholder Song if not already in savedSongs
    for (final file in mp3Files) {
      final filename = path.basename(file.path);
      final id = filename.replaceAll('.mp3', '');
      if (!savedIds.contains(id)) {
        // Try to find the song in the saved songs list by ID
        final existingSong = savedSongs.firstWhere(
          (s) => s.id == id,
          orElse: () => Song(
            id: id,
            title: 'Unknown Title',
            album: '',
            albumUrl: '',
            image: '',
            mediaUrl: '',
            mediaPreviewUrl: '',
            duration: '',
            language: '',
            artistMap: {},
            primaryArtists: 'Unknown Artist',
            singers: '',
            music: '',
            year: '',
            playCount: '',
            isDrm: false,
            hasLyrics: false,
            permaUrl: '',
            releaseDate: '',
            label: '',
            copyrightText: '',
            is320kbps: false,
            disabledText: '',
            isDisabled: false,
          ),
        );
        savedSongs.add(existingSong);
      }
    }
    return savedSongs;
  }

  Future<void> saveDownloadedSong(Song song) async {
    final prefs = await SharedPreferences.getInstance();
    final songs = await getDownloadedSongs();
    
    // Remove existing song with same ID if it exists
    songs.removeWhere((s) => s.id == song.id);
    
    // Add the new song
    songs.add(song);
    
    // Save to SharedPreferences
    await prefs.setStringList(
      _downloadedSongsKey,
      songs.map((s) => jsonEncode(s.toJson())).toList(),
    );
  }

  Future<void> updateSongMetadata(Song song) async {
    await saveDownloadedSong(song);
  }

  Future<void> deleteSong(Song song) async {
    final prefs = await SharedPreferences.getInstance();
    final songs = await getDownloadedSongs();
    
    songs.removeWhere((s) => s.id == song.id);
    await prefs.setStringList(
      _downloadedSongsKey,
      songs.map((s) => jsonEncode(s.toJson())).toList(),
    );

    // Delete the actual file if it exists
    try {
      final localPath = await _localPath;
      final file = File('$localPath/${song.id}.mp3');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting song file: $e');
    }
  }
} 