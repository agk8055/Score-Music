import 'package:just_audio/just_audio.dart';
import 'dart:async';
import '../models/song.dart';

class MusicPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Song? _currentSong;
  bool _isInitialized = false;
  final _currentSongController = StreamController<Song?>.broadcast();

  Song? get currentSong => _currentSong;
  Stream<Song?> get currentSongStream => _currentSongController.stream;
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
    await _audioPlayer.dispose();
  }
} 