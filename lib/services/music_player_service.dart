import 'package:just_audio/just_audio.dart';
import 'dart:async';
import '../models/song.dart';

class MusicPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Song? _currentSong;
  bool _isInitialized = false;
  final _currentSongController = StreamController<Song?>.broadcast();
  final List<Song> _queue = [];
  final _queueController = StreamController<List<Song>>.broadcast();

  Song? get currentSong => _currentSong;
  List<Song> get queue => List.unmodifiable(_queue);
  Stream<Song?> get currentSongStream => _currentSongController.stream;
  Stream<List<Song>> get queueStream => _queueController.stream;
  Stream<Duration?> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  bool get isPlaying => _audioPlayer.playing;

  Future<void> playSong(Song song) async {
    if (_currentSong?.id == song.id && _isInitialized) {
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
      return;
    }

    _currentSong = song;
    _currentSongController.add(song);
    try {
      await _audioPlayer.setUrl(song.mediaUrl);
      _isInitialized = true;
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing song: $e');
      _isInitialized = false;
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
    if (_currentSong != null && _queue.isNotEmpty) {
      // Add current song back to the front of the queue
      _queue.insert(0, _currentSong!);
      // Play the first song in the queue
      final previousSong = _queue.removeAt(0);
      _queueController.add(_queue);
      await playSong(previousSong);
    }
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