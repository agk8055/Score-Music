import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/music_player_service.dart';
import '../services/play_history_service.dart';
import '../services/playlist_service.dart';
import '../widgets/base_scaffold.dart';
import '../widgets/play_history_section.dart';
import '../widgets/playlist_category_section.dart';

class HomeScreen extends StatefulWidget {
  final MusicPlayerService playerService;
  final PlayHistoryService historyService;
  final PlaylistService playlistService;

  const HomeScreen({
    Key? key,
    required this.playerService,
    required this.historyService,
    required this.playlistService,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<PlaylistSection> sections = [];

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    final savedConfig = prefs.getString('home_screen_config');
    
    if (savedConfig != null) {
      final List<dynamic> decoded = json.decode(savedConfig);
      setState(() {
        sections = decoded.map((item) => PlaylistSection.fromJson(item)).toList();
      });
    } else {
      // Load default configuration
      setState(() {
        sections = [
          PlaylistSection(
            title: 'Tamil',
            playlistUrls: [
              'https://www.jiosaavn.com/featured/top-kuthu-tamil/CNVzQf7lvT8wkg5tVhI3fw__',
              'https://www.jiosaavn.com/featured/trending-pop-tamil/5z8vKjNnhmIGSw2I1RxdhQ__',
              'https://www.jiosaavn.com/featured/lets-play-vijay/-KAZYpBulyM_',
            ],
          ),
          PlaylistSection(
            title: 'Malayalam',
            playlistUrls: [
              'https://www.jiosaavn.com/featured/chaya-friends-club/yO,WwRUN3CHfemJ68FuXsA__',
              'https://www.jiosaavn.com/featured/best-of-dance-malayalam/AJiiA8-w,u3ufxkxMEIbIw__',
              'https://www.jiosaavn.com/featured/best-of-romance-malayalam/CBJDUkJa-c-c1EngHtQQ2g__',
            ],
          ),
          PlaylistSection(
            title: 'Other',
            playlistUrls: [
              'https://www.jiosaavn.com/featured/trending-today/I3kvhipIy73uCJW60TJk1Q__',
              'https://www.jiosaavn.com/featured/most-streamed-love-songs-hindi/RQKZhDpGh8uAIonqf0gmcg__',
              'https://www.jiosaavn.com/featured/lets-play-lana-del-rey/tfSGFDM5b4eO0eMLZZxqsA__',
            ],
          ),
        ];
      });
    }
  }

  Future<void> _onRefresh() async {
    await _loadConfiguration();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        children: [
          PlayHistorySection(
            historyService: widget.historyService,
            playerService: widget.playerService,
            playlistService: widget.playlistService,
          ),
          ...sections.map((section) => PlaylistCategorySection(
            playerService: widget.playerService,
            playlistService: widget.playlistService,
            title: section.title,
            playlistUrls: section.playlistUrls,
          )).toList(),
        ],
      ),
    );
  }
}

class PlaylistSection {
  final String title;
  final List<String> playlistUrls;

  PlaylistSection({
    required this.title,
    required this.playlistUrls,
  });

  factory PlaylistSection.fromJson(Map<String, dynamic> json) {
    return PlaylistSection(
      title: json['title'] as String,
      playlistUrls: List<String>.from(json['playlistUrls']),
    );
  }
} 