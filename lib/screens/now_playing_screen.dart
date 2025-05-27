import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../services/music_player_service.dart';
import '../services/download_service.dart';
import '../services/playlist_service.dart';
import '../models/song.dart';
import '../widgets/playlist_selection_dialog.dart';
import '../screens/queue_screen.dart';

class NowPlayingScreen extends StatelessWidget {
  final MusicPlayerService playerService;
  final PlaylistService playlistService;

  const NowPlayingScreen({
    super.key,
    required this.playerService,
    required this.playlistService,
  });

  void _showAddToPlaylistDialog(BuildContext context, Song song) {
    showDialog(
      context: context,
      builder: (context) => PlaylistSelectionDialog(
        playlistService: playlistService,
        songId: song.id,
      ),
    );
  }

  void _showQueueScreen(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.3,
        minChildSize: 0.2,
        maxChildSize: 0.8,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: QueueScreen(playerService: playerService),
        ),
      ),
    );
  }

  IconData _getRepeatIcon(LoopMode loopMode) {
    switch (loopMode) {
      case LoopMode.off:
        return Icons.repeat;
      case LoopMode.one:
        return Icons.repeat_one;
      case LoopMode.all:
        return Icons.repeat;
    }
  }

  Color _getRepeatColor(LoopMode loopMode) {
    return loopMode == LoopMode.off ? Colors.white : const Color(0xFFF5D505);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: StreamBuilder<Song?>(
          stream: playerService.currentSongStream,
          builder: (context, snapshot) {
            final song = snapshot.data;
            if (song == null) return const SizedBox.shrink();

            return Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_downward, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      const Text(
                        'Now Playing',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.grey[900],
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            builder: (context) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                StreamBuilder<bool>(
                                  stream: Stream.fromFuture(DownloadService().isDownloaded(song)),
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
                                                  song,
                                                  onProgress: (progress) {
                                                    // TODO: Show download progress
                                                  },
                                                );
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Song downloaded successfully'),
                                                  ),
                                                );
                                              } catch (e) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Error downloading song: $e'),
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
                                            _showAddToPlaylistDialog(context, song);
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                // Album Art
                Expanded(
                  child: Center(
                    child: Hero(
                      tag: 'album_art_${song.id}',
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.width * 0.8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            song.image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[800],
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
                    ),
                  ),
                ),

                // Song Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      Text(
                        song.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        song.primaryArtists,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: StreamBuilder<Duration?>(
                    stream: playerService.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      return StreamBuilder<Duration?>(
                        stream: playerService.durationStream,
                        builder: (context, snapshot) {
                          final duration = snapshot.data ?? Duration.zero;
                          final positionMs = position.inMilliseconds.toDouble();
                          final durationMs = duration.inMilliseconds.toDouble();
                          // Ensure position doesn't exceed duration
                          final boundedPosition = positionMs.clamp(0.0, durationMs);
                          return Column(
                            children: [
                              SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 8,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 16,
                                  ),
                                  activeTrackColor: const Color(0xFFF5D505),
                                  inactiveTrackColor: Colors.grey[800],
                                  thumbColor: const Color(0xFFF5D505),
                                  overlayColor: const Color(0xFFF5D505).withOpacity(0.2),
                                ),
                                child: Slider(
                                  value: boundedPosition,
                                  max: durationMs,
                                  onChanged: (value) {
                                    playerService.seekTo(
                                      Duration(milliseconds: value.toInt()),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(position),
                                      style: TextStyle(color: Colors.grey[400]),
                                    ),
                                    Text(
                                      _formatDuration(duration),
                                      style: TextStyle(color: Colors.grey[400]),
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
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          StreamBuilder<bool>(
                            stream: playerService.shuffleStream,
                            builder: (context, snapshot) {
                              final isShuffleOn = snapshot.data ?? false;
                              return IconButton(
                                icon: Icon(
                                  Icons.shuffle,
                                  color: isShuffleOn ? const Color(0xFFF5D505) : Colors.white,
                                  size: 28,
                                ),
                                onPressed: () {
                                  playerService.toggleShuffle();
                                },
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.skip_previous,
                              color: Color(0xFFF5D505),
                              size: 36,
                            ),
                            onPressed: () {
                              playerService.playPrevious();
                            },
                          ),
                          StreamBuilder<PlayerState>(
                            stream: playerService.playerStateStream,
                            builder: (context, snapshot) {
                              final isPlaying = snapshot.data?.playing ?? false;
                              return Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFF5D505),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.black,
                                    size: 36,
                                  ),
                                  onPressed: () {
                                    if (isPlaying) {
                                      playerService.pause();
                                    } else {
                                      playerService.resume();
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.skip_next,
                              color: Color(0xFFF5D505),
                              size: 36,
                            ),
                            onPressed: () {
                              playerService.playNext();
                            },
                          ),
                          StreamBuilder<LoopMode>(
                            stream: playerService.loopModeStream,
                            builder: (context, snapshot) {
                              final loopMode = snapshot.data ?? LoopMode.off;
                              return IconButton(
                                icon: Icon(
                                  _getRepeatIcon(loopMode),
                                  color: _getRepeatColor(loopMode),
                                  size: 28,
                                ),
                                onPressed: () {
                                  switch (loopMode) {
                                    case LoopMode.off:
                                      playerService.setLoopMode(LoopMode.all);
                                      break;
                                    case LoopMode.all:
                                      playerService.setLoopMode(LoopMode.one);
                                      break;
                                    case LoopMode.one:
                                      playerService.setLoopMode(LoopMode.off);
                                      break;
                                  }
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: StreamBuilder<List<Song>>(
                          stream: playerService.queueStream,
                          builder: (context, snapshot) {
                            final queue = snapshot.data ?? [];
                            return Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.queue_music,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  onPressed: () => _showQueueScreen(context),
                                ),
                                if (queue.isNotEmpty)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        queue.length.toString(),
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
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