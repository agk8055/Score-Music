import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
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
            if (cancelToken != null && cancelToken.cancelled) {
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
        if (cancelToken != null && cancelToken.cancelled) {
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
    
    return songsJson.map((json) => Song.fromJson(jsonDecode(json))).toList();
  }

  Future<void> saveDownloadedSong(Song song) async {
    final prefs = await SharedPreferences.getInstance();
    final songs = await getDownloadedSongs();
    
    if (!songs.any((s) => s.id == song.id)) {
      songs.add(song);
      await prefs.setStringList(
        _downloadedSongsKey,
        songs.map((s) => jsonEncode(s.toJson())).toList(),
      );
    }
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

class CancelToken {
  bool cancelled = false;
  void cancel() {
    cancelled = true;
  }
} 