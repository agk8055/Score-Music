import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/playlist.dart';
import 'play_history_service.dart';

class MusicPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final PlayHistoryService _historyService;
  Song? _currentSong;
  Album? _currentAlbum;
  Playlist? _currentPlaylist;
  bool _isInitialized = false;
  final _currentSongController = StreamController<Song?>.broadcast();
  final List<Song> _queue = [];
  final List<Song> _previousSongs = [];
  final _queueController = StreamController<List<Song>>.broadcast();

  MusicPlayerService(this._historyService);

  Song? get currentSong => _currentSong;
  Album? get currentAlbum => _currentAlbum;
  Playlist? get currentPlaylist => _currentPlaylist;
  List<Song> get queue => List.unmodifiable(_queue);
  Stream<Song?> get currentSongStream => _currentSongController.stream.asBroadcastStream().startWith(_currentSong);
  Stream<List<Song>> get queueStream => _queueController.stream;
  Stream<Duration?> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  bool get isPlaying => _audioPlayer.playing;

  Future<void> playSong(Song song, {Album? album, Playlist? playlist}) async {
    if (_currentSong?.id == song.id && _isInitialized) {
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
      return;
    }

    // Stop current playback and reset
    await _audioPlayer.stop();
    _isInitialized = false;

    if (_currentSong != null) {
      _previousSongs.add(_currentSong!);
    }

    _currentSong = song;
    _currentAlbum = album;
    _currentPlaylist = playlist;
    _currentSongController.add(song);
    try {
      await _audioPlayer.setUrl(song.mediaUrl);
      _isInitialized = true;
      await _audioPlayer.play();
      await _historyService.addToHistory(song, album: album, playlist: playlist);
    } catch (e) {
      print('Error playing song: $e');
      _isInitialized = false;
      _currentSong = null;
      _currentSongController.add(null);
    }
  }

  void addToQueue(Song song) {
    print('Adding song to queue: ${song.title}');
    if (!_queue.any((s) => s.id == song.id)) {
      _queue.add(song);
      print('Queue size after adding: ${_queue.length}');
      _queueController.add(_queue);
    } else {
      print('Song already in queue');
    }
  }

  void removeFromQueue(Song song) {
    print('Removing song from queue: ${song.title}');
    _queue.removeWhere((s) => s.id == song.id);
    print('Queue size after removing: ${_queue.length}');
    _queueController.add(_queue);
  }

  void clearQueue() {
    print('Clearing queue');
    _queue.clear();
    _queueController.add(_queue);
  }

  void reorderQueue(List<Song> newQueue) {
    print('Reordering queue. New size: ${newQueue.length}');
    _queue.clear();
    _queue.addAll(newQueue);
    _queueController.add(_queue);
  }

  Future<void> playNext() async {
    if (_queue.isNotEmpty) {
      final nextSong = _queue.removeAt(0);
      _queueController.add(_queue);
      await playSong(nextSong);
    }
  }

  Future<void> playPrevious() async {
    if (_previousSongs.isNotEmpty) {
      final previousSong = _previousSongs.removeLast();
      await playSong(previousSong);
    }
  }

  void clearPreviousSongs() {
    _previousSongs.clear();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    await _audioPlayer.play();
  }

  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> dispose() async {
    await _currentSongController.close();
    await _queueController.close();
    await _audioPlayer.dispose();
  }
} 