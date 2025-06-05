import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio/just_audio.dart' show AudioPlayer, LoopMode, ProcessingState, PlayerState, AudioSource;
import 'dart:async';
import 'dart:math';
import 'package:rxdart/rxdart.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/playlist.dart';
import 'play_history_service.dart';
import 'package:flutter/foundation.dart';

class MusicPlayerService {
  late final AudioPlayer _audioPlayer;
  final PlayHistoryService _historyService;
  Song? _currentSong;
  Album? _currentAlbum;
  Playlist? _currentPlaylist;
  bool _isInitialized = false;
  bool _isShuffleOn = false;
  final _currentSongController = StreamController<Song?>.broadcast();
  final List<Song> _queue = [];
  final List<Song> _historyStack = [];
  final _queueController = StreamController<List<Song>>.broadcast();
  final _shuffleController = StreamController<bool>.broadcast();
  final _errorController = StreamController<String?>.broadcast();
  bool _isDisposed = false;

  MusicPlayerService(this._historyService) {
    // Initialize the audio player with error handling
    try {
      _audioPlayer = AudioPlayer(
        androidApplyAudioAttributes: true,
      );

      // Listen for song completion
      _audioPlayer.playerStateStream.listen(
        (state) {
          if (state.processingState == ProcessingState.completed) {
            playNext();
          }
        },
        onError: (error) {
          debugPrint('Error in player state stream: $error');
          _errorController.add('Playback error: $error');
        },
      );

      // Listen for player errors
      _audioPlayer.playbackEventStream.listen(
        (event) {},
        onError: (error) {
          debugPrint('Error in playback event stream: $error');
          _errorController.add('Playback error: $error');
          _handlePlaybackError();
        },
      );
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
      _errorController.add('Failed to initialize audio player: $e');
      rethrow;
    }
  }

  Song? get currentSong => _currentSong;
  Album? get currentAlbum => _currentAlbum;
  Playlist? get currentPlaylist => _currentPlaylist;
  List<Song> get queue => List.unmodifiable(_queue);
  bool get isShuffleOn => _isShuffleOn;
  Stream<Song?> get currentSongStream => _currentSongController.stream.asBroadcastStream().startWith(_currentSong);
  Stream<List<Song>> get queueStream => _queueController.stream;
  Stream<Duration?> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<LoopMode> get loopModeStream => _audioPlayer.loopModeStream;
  Stream<bool> get shuffleStream => _shuffleController.stream.startWith(_isShuffleOn);
  bool get isPlaying => _audioPlayer.playing;
  Stream<String?> get errorStream => _errorController.stream;

  void toggleShuffle() {
    _isShuffleOn = !_isShuffleOn;
    _shuffleController.add(_isShuffleOn);
    if (_isShuffleOn) {
      _shuffleQueue();
    }
  }

  void _shuffleQueue() {
    if (_queue.isEmpty) return;
    
    final random = Random();
    for (var i = _queue.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = _queue[i];
      _queue[i] = _queue[j];
      _queue[j] = temp;
    }
    _queueController.add(_queue);
  }

  void _handlePlaybackError() async {
    if (_isDisposed) return;
    
    try {
      // Try to recover from the error
      if (_currentSong != null) {
        // Stop current playback
        await _audioPlayer.stop();
        _isInitialized = false;

        // Try to reload the current song
        await Future.delayed(const Duration(seconds: 1));
        if (!_isDisposed && _currentSong != null) {
          await playSong(_currentSong!);
        }
      }
    } catch (e) {
      debugPrint('Error recovering from playback error: $e');
      _errorController.add('Failed to recover from playback error: $e');
    }
  }

  Future<void> playSong(Song song, {Album? album, Playlist? playlist}) async {
    if (_isDisposed) return;

    if (_currentSong?.id == song.id && _isInitialized) {
      try {
        if (_audioPlayer.playing) {
          await _audioPlayer.pause();
        } else {
          await _audioPlayer.play();
        }
        return;
      } catch (e) {
        debugPrint('Error toggling playback: $e');
        _errorController.add('Failed to toggle playback: $e');
        return;
      }
    }

    try {
      // Stop current playback and reset
      await _audioPlayer.stop();
      _isInitialized = false;

      // Add current song to history stack if it exists
      if (_currentSong != null) {
        _historyStack.add(_currentSong!);
      }

      _currentSong = song;
      _currentAlbum = album;
      _currentPlaylist = playlist;
      _currentSongController.add(song);

      // Create media item for background playback
      final mediaItem = MediaItem(
        id: song.id,
        album: album?.title ?? 'Unknown Album',
        title: song.title,
        artist: song.artist,
        artUri: Uri.parse(song.image),
        displayTitle: song.title,
        displaySubtitle: song.artist,
        displayDescription: album?.title,
      );

      // Set the audio source with media item and timeout
      await _audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(song.mediaUrl),
          tag: mediaItem,
        ),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Failed to load audio source');
        },
      );
      
      _isInitialized = true;
      await _audioPlayer.play();
      await _historyService.addToHistory(song, album: album, playlist: playlist);
    } catch (e) {
      debugPrint('Error playing song: $e');
      _errorController.add('Failed to play song: $e');
      _isInitialized = false;
      _currentSong = null;
      _currentSongController.add(null);
      
      // Try to recover if it's a network error
      if (e is TimeoutException || e.toString().contains('SocketException')) {
        await Future.delayed(const Duration(seconds: 2));
        if (!_isDisposed && song.id == _currentSong?.id) {
          await playSong(song, album: album, playlist: playlist);
        }
      }
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
    if (_queue.isEmpty) {
      // If queue is empty and we're in loop mode, we should handle that
      if (_audioPlayer.loopMode == LoopMode.all && _currentSong != null) {
        // Add the current song back to the queue
        _queue.add(_currentSong!);
        _queueController.add(_queue);
      } else {
        return;
      }
    }

    // If we're playing the same song that's next in queue, remove it first
    if (_queue.isNotEmpty && _queue[0].id == _currentSong?.id) {
      _queue.removeAt(0);
      if (_queue.isEmpty) {
        _queueController.add(_queue);
        return;
      }
    }

    // Add current song to history stack before playing next
    if (_currentSong != null) {
      _historyStack.add(_currentSong!);
    }

    Song nextSong;
    if (_isShuffleOn) {
      final random = Random();
      final index = random.nextInt(_queue.length);
      nextSong = _queue.removeAt(index);
    } else {
      nextSong = _queue.removeAt(0);
    }
    
    _queueController.add(_queue);
    
    // Update current song before playing
    _currentSong = nextSong;
    _currentSongController.add(nextSong);
    
    try {
      // Create media item for background playback
      final mediaItem = MediaItem(
        id: nextSong.id,
        album: _currentAlbum?.title ?? 'Unknown Album',
        title: nextSong.title,
        artist: nextSong.artist,
        artUri: Uri.parse(nextSong.image),
        displayTitle: nextSong.title,
        displaySubtitle: nextSong.artist,
        displayDescription: _currentAlbum?.title,
      );

      // Set the audio source with media item
      await _audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(nextSong.mediaUrl),
          tag: mediaItem,
        ),
      );
      
      _isInitialized = true;
      await _audioPlayer.play();
      await _historyService.addToHistory(nextSong);
    } catch (e) {
      print('Error playing next song: $e');
      _isInitialized = false;
      _currentSong = null;
      _currentSongController.add(null);
    }
  }

  Future<void> playPrevious() async {
    if (_historyStack.isEmpty) {
      return;
    }

    // Get the previous song from history stack
    final previousSong = _historyStack.removeLast();
    
    // Add current song to front of queue if it exists
    if (_currentSong != null) {
      _queue.insert(0, _currentSong!);
      _queueController.add(_queue);
    }

    // Play the previous song
    await playSong(previousSong);
  }

  void clearHistory() {
    _historyStack.clear();
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

  Future<void> setLoopMode(LoopMode mode) async {
    await _audioPlayer.setLoopMode(mode);
  }

  @override
  Future<void> dispose() async {
    _isDisposed = true;
    try {
      await _currentSongController.close();
      await _queueController.close();
      await _shuffleController.close();
      await _errorController.close();
      await _audioPlayer.dispose();
    } catch (e) {
      debugPrint('Error disposing MusicPlayerService: $e');
    }
  }
} 