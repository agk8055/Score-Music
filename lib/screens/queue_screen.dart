import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/music_player_service.dart';

class QueueScreen extends StatelessWidget {
  final MusicPlayerService playerService;

  const QueueScreen({
    super.key,
    required this.playerService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[800]!,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Text(
                    'Queue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear_all, color: Colors.white70),
                  onPressed: () {
                    playerService.clearQueue();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Queue cleared'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          StreamBuilder<List<Song>>(
            stream: playerService.queueStream,
            initialData: playerService.queue,
            builder: (context, snapshot) {
              print('Queue screen builder called. Queue size: ${snapshot.data?.length ?? 0}');
              final queue = snapshot.data ?? [];
              if (queue.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'Queue is empty',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              }

              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: queue.length,
                  onReorder: (oldIndex, newIndex) {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final song = queue.removeAt(oldIndex);
                    queue.insert(newIndex, song);
                    playerService.reorderQueue(queue);
                  },
                  itemBuilder: (context, index) {
                    final song = queue[index];
                    return ListTile(
                      key: ValueKey(song.id),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          song.image,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 48,
                              height: 48,
                              color: Colors.grey[800],
                              child: const Icon(Icons.music_note),
                            );
                          },
                        ),
                      ),
                      title: Text(
                        song.title,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        song.primaryArtists,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.white70),
                            onPressed: () {
                              playerService.removeFromQueue(song);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Removed from queue'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          const Icon(
                            Icons.drag_handle,
                            color: Colors.white54,
                          ),
                        ],
                      ),
                      onTap: () {
                        playerService.playSong(song);
                        playerService.removeFromQueue(song);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
} 