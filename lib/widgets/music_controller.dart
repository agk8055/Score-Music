import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../services/music_player_service.dart';
import '../models/song.dart';

class MusicController extends StatelessWidget {
  final MusicPlayerService playerService;

  const MusicController({
    super.key,
    required this.playerService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Song?>(
      stream: Stream.value(playerService.currentSong),
      builder: (context, snapshot) {
        final song = snapshot.data;
        if (song == null) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<Duration?>(
                stream: playerService.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  return StreamBuilder<Duration?>(
                    stream: playerService.durationStream,
                    builder: (context, snapshot) {
                      final duration = snapshot.data ?? Duration.zero;
                      return SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 12,
                          ),
                          activeTrackColor: const Color(0xFFF5D505),
                          inactiveTrackColor: Colors.grey[800],
                          thumbColor: const Color(0xFFF5D505),
                          overlayColor: const Color(0xFFF5D505).withOpacity(0.2),
                        ),
                        child: Slider(
                          value: position.inMilliseconds.toDouble(),
                          max: duration.inMilliseconds.toDouble(),
                          onChanged: (value) {
                            playerService.seekTo(
                              Duration(milliseconds: value.toInt()),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        song.image,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 40,
                            height: 40,
                            color: Colors.grey[800],
                            child: const Icon(Icons.music_note),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            song.primaryArtists,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    StreamBuilder<PlayerState>(
                      stream: playerService.playerStateStream,
                      builder: (context, snapshot) {
                        final isPlaying = snapshot.data?.playing ?? false;
                        return IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: const Color(0xFFF5D505),
                            size: 28,
                          ),
                          onPressed: () {
                            if (isPlaying) {
                              playerService.pause();
                            } else {
                              playerService.resume();
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 