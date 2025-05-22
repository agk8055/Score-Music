import 'package:flutter/material.dart';
import '../services/music_player_service.dart';
import '../services/play_history_service.dart';
import '../widgets/base_scaffold.dart';
import '../widgets/play_history_section.dart';
import '../widgets/playlist_category_section.dart';

class HomeScreen extends StatelessWidget {
  final MusicPlayerService playerService;
  final PlayHistoryService historyService;

  const HomeScreen({
    Key? key,
    required this.playerService,
    required this.historyService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        PlayHistorySection(
          historyService: historyService,
          playerService: playerService,
        ),
        PlaylistCategorySection(
          playerService: playerService,
          title: 'Tamil ',
          playlistUrls: [
            'https://www.jiosaavn.com/featured/top-kuthu-tamil/CNVzQf7lvT8wkg5tVhI3fw__',
            'https://www.jiosaavn.com/featured/trending-pop-tamil/5z8vKjNnhmIGSw2I1RxdhQ__',
            'https://www.jiosaavn.com/featured/lets-play-vijay/-KAZYpBulyM_',
          ],
        ),
        PlaylistCategorySection(
          playerService: playerService,
          title: 'Malayalam ',
          playlistUrls: [
            'https://www.jiosaavn.com/featured/chaya-friends-club/yO,WwRUN3CHfemJ68FuXsA__',
            'https://www.jiosaavn.com/featured/best-of-dance-malayalam/AJiiA8-w,u3ufxkxMEIbIw__',
            'https://www.jiosaavn.com/featured/best-of-romance-malayalam/CBJDUkJa-c-c1EngHtQQ2g__',
          ],
        ),
        PlaylistCategorySection(
          playerService: playerService,
          title: 'Other ',
          playlistUrls: [
            'https://www.jiosaavn.com/featured/trending-today/I3kvhipIy73uCJW60TJk1Q__',
            'https://www.jiosaavn.com/featured/most-streamed-love-songs-hindi/RQKZhDpGh8uAIonqf0gmcg__',
            'https://www.jiosaavn.com/featured/lets-play-lana-del-rey/tfSGFDM5b4eO0eMLZZxqsA__',
          ],
        ),
      ],
    );
  }
} 