import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../services/music_player_service.dart';
import '../services/download_service.dart';
import '../services/playlist_service.dart';
import '../models/song.dart';
import '../widgets/playlist_selection_dialog.dart';
import '../widgets/custom_progress_indicator.dart';
import '../screens/queue_screen.dart';
import '../widgets/audio_visualizer.dart'; // Import the new visualizer

class NowPlayingScreen extends StatelessWidget {
  final MusicPlayerService audioPlayer;
  final PlaylistService playlistManager;

  const NowPlayingScreen({
    super.key,
    required this.audioPlayer,
    required this.playlistManager,
  });

  void _showPlaylistSelection(BuildContext context, Song currentTrack) {
    showDialog(
      context: context,
      builder: (context) => PlaylistSelectionDialog(
        playlistService: playlistManager,
        songId: currentTrack.id,
      ),
    );
  }

  void _showTrackQueue(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.25,
        maxChildSize: 0.85,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: QueueScreen(playerService: audioPlayer),
          ),
        ),
      ),
    );
  }

  IconData _getRepeatIcon(LoopMode repeatMode) {
    switch (repeatMode) {
      case LoopMode.off:
        return Icons.repeat;
      case LoopMode.one:
        return Icons.repeat_one;
      case LoopMode.all:
        return Icons.repeat_on_rounded;
    }
  }

  Color _getRepeatColor(LoopMode repeatMode) {
    return repeatMode == LoopMode.off ? Colors.white : const Color(0xFFF5D505);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: StreamBuilder<Song?>(
          stream: audioPlayer.currentSongStream,
          builder: (context, snapshot) {
            final currentTrack = snapshot.data;
            if (currentTrack == null) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFF5D505),
                ),
              );
            }

            return Column(
              children: [
                // Premium App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      const Text(
                        'NOW PLAYING',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onPressed: () => _showTrackOptions(context, currentTrack),
                      ),
                    ],
                  ),
                ),
                
                // Album Art (no visualizer background)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        StreamBuilder<Duration?>(
                          stream: audioPlayer.positionStream,
                          builder: (context, snapshot) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              width: MediaQuery.of(context).size.width * 0.75,
                              height: MediaQuery.of(context).size.width * 0.75,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF5D505).withOpacity(0.3),
                                    blurRadius: 30,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Hero(
                                  tag: 'album_art_${currentTrack.id}',
                                  child: Image.network(
                                    currentTrack.image,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[900],
                                        child: const Icon(
                                          Icons.music_note,
                                          size: 100,
                                          color: Colors.white54,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Track Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                  child: Column(
                    children: [
                      Text(
                        currentTrack.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentTrack.primaryArtists,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Progress Bar with Liquid Effect
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: StreamBuilder<Duration?>(
                    stream: audioPlayer.positionStream,
                    builder: (context, positionSnapshot) {
                      final position = positionSnapshot.data ?? Duration.zero;
                      return StreamBuilder<Duration?>(
                        stream: audioPlayer.durationStream,
                        builder: (context, durationSnapshot) {
                          final duration = durationSnapshot.data ?? Duration.zero;
                          final progress = duration.inMilliseconds > 0
                              ? position.inMilliseconds / duration.inMilliseconds
                              : 0.0;

                          return Column(
                            children: [
                              SizedBox(
                                height: 24,
                                child: Slider(
                                  value: position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble(),
                                  min: 0.0,
                                  max: duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0,
                                  activeColor: const Color(0xFFF5D505),
                                  inactiveColor: Colors.grey[800],
                                  onChanged: (value) {
                                    audioPlayer.seekTo(Duration(milliseconds: value.toInt()));
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(position),
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(duration),
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),

                // Playback Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  child: Column(
                    children: [
                      // Main Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Shuffle Button
                          StreamBuilder<bool>(
                            stream: audioPlayer.shuffleStream,
                            builder: (context, snapshot) {
                              final isShuffleOn = snapshot.data ?? false;
                              return IconButton(
                                icon: Icon(
                                  Icons.shuffle,
                                  color: isShuffleOn ? const Color(0xFFF5D505) : Colors.white,
                                  size: 26,
                                ),
                                onPressed: audioPlayer.toggleShuffle,
                              );
                            },
                          ),
                          
                          // Previous Track Button
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFF5D505), width: 2),
                              ),
                              child: const Icon(
                                Icons.skip_previous,
                                color: Color(0xFFF5D505),
                                size: 32,
                              ),
                            ),
                            onPressed: audioPlayer.playPrevious,
                          ),
                          
                          // Play/Pause Button
                          StreamBuilder<PlayerState>(
                            stream: audioPlayer.playerStateStream,
                            builder: (context, snapshot) {
                              final isPlaying = snapshot.data?.playing ?? false;
                              return Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFF5D505).withOpacity(0.8),
                                      const Color(0xFFF5D505),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFF5D505).withOpacity(0.4),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.black,
                                    size: 36,
                                  ),
                                  onPressed: isPlaying ? audioPlayer.pause : audioPlayer.resume,
                                ),
                              );
                            },
                          ),
                          
                          // Next Track Button
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFF5D505), width: 2),
                              ),
                              child: const Icon(
                                Icons.skip_next,
                                color: Color(0xFFF5D505),
                                size: 32,
                              ),
                            ),
                            onPressed: audioPlayer.playNext,
                          ),
                          
                          // Repeat Button
                          StreamBuilder<LoopMode>(
                            stream: audioPlayer.loopModeStream,
                            builder: (context, snapshot) {
                              final repeatMode = snapshot.data ?? LoopMode.off;
                              return IconButton(
                                icon: Icon(
                                  _getRepeatIcon(repeatMode),
                                  color: _getRepeatColor(repeatMode),
                                  size: 26,
                                ),
                                onPressed: () {
                                  switch (repeatMode) {
                                    case LoopMode.off:
                                      audioPlayer.setLoopMode(LoopMode.all);
                                      break;
                                    case LoopMode.all:
                                      audioPlayer.setLoopMode(LoopMode.one);
                                      break;
                                    case LoopMode.one:
                                      audioPlayer.setLoopMode(LoopMode.off);
                                      break;
                                  }
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      
                      // Queue Button
                      const SizedBox(height: 16),
                      StreamBuilder<List<Song>>(
                        stream: audioPlayer.queueStream,
                        builder: (context, snapshot) {
                          final trackQueue = snapshot.data ?? [];
                          return GestureDetector(
                            onTap: () => _showTrackQueue(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.queue_music,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Queue ${trackQueue.isNotEmpty ? '(${trackQueue.length})' : ''}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Audio Visualizer
                StreamBuilder<PlayerState>(
                  stream: audioPlayer.playerStateStream,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data?.playing ?? false;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: isPlaying ? 60 : 0,
                      width: double.infinity,
                      child: isPlaying ? const AudioVisualizer() : null,
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showTrackOptions(BuildContext context, Song currentTrack) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(currentTrack.image),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentTrack.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        currentTrack.primaryArtists,
                        style: TextStyle(color: Colors.grey[400]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.grey, height: 1),
          StreamBuilder<bool>(
            stream: Stream.fromFuture(DownloadService().isDownloaded(currentTrack)),
            builder: (context, snapshot) {
              final isDownloaded = snapshot.data ?? false;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(
                      isDownloaded ? Icons.download_done : Icons.download,
                      color: const Color(0xFFF5D505),
                    ),
                    title: Text(
                      isDownloaded ? 'Downloaded' : 'Download',
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      if (!isDownloaded) {
                        try {
                          await DownloadService().downloadSong(
                            currentTrack,
                            onProgress: (progress) {
                              // TODO: Show download progress
                            },
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Track downloaded successfully'),
                              backgroundColor: const Color(0xFFF5D505),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error downloading track: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.playlist_add,
                      color: Color(0xFFF5D505),
                    ),
                    title: const Text(
                      'Add to Playlist',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showPlaylistSelection(context, currentTrack);
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}