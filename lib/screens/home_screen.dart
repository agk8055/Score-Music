import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/music_player_service.dart';
import '../services/play_history_service.dart';
import '../services/playlist_service.dart';
import '../services/playlist_cache_service.dart';
import '../widgets/base_scaffold.dart';
import '../widgets/play_history_section.dart';
import '../widgets/playlist_category_section.dart';
import '../widgets/skeleton_loader.dart'; // Import skeleton loader

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
  bool _isLoading = true;

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
        _isLoading = false;
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
              'https://www.jiosaavn.com/featured/lets-play-anirudh-ravichander-tamil/ePUVUJs1h,E_',
              'https://www.jiosaavn.com/featured/lets-play-vijay/-KAZYpBulyM_',
            ],
          ),
          PlaylistSection(
            title: 'Malayalam',
            playlistUrls: [
              'https://www.jiosaavn.com/featured/chaya-friends-club/yO,WwRUN3CHfemJ68FuXsA__',
              'https://www.jiosaavn.com/featured/best-of-dance-malayalam/AJiiA8-w,u3ufxkxMEIbIw__',
              'https://www.jiosaavn.com/featured/lets-play-sushin-shyam-malayalam/QtJNHKsL92FFo9wdEAzFBA__',
              'https://www.jiosaavn.com/featured/best-of-romance-malayalam/CBJDUkJa-c-c1EngHtQQ2g__',
              'https://www.jiosaavn.com/featured/lets-play-jakes-bejoy-malayalam/-x5OEMrsb-bc1EngHtQQ2g__'
            ],
          ),
          PlaylistSection(
            title: 'Other',
            playlistUrls: [
              'https://www.jiosaavn.com/featured/trending-today/I3kvhipIy73uCJW60TJk1Q__',
              'https://www.jiosaavn.com/featured/most-streamed-love-songs-hindi/RQKZhDpGh8uAIonqf0gmcg__',
              'https://www.jiosaavn.com/featured/lets-play-lana-del-rey/tfSGFDM5b4eO0eMLZZxqsA__',
              'https://www.jiosaavn.com/featured/lets-play-billie-eilish/9FW8zUEIHh9ieSJqt9HmOQ__',
            ],
          ),
        ];
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _isLoading = true);
    PlaylistCacheService().clearCache();
    await _loadConfiguration();
  }

  Widget _buildSkeletonLoader() {
    return ListView(
      children: [
        // Skeleton for history section
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: SkeletonLoader(width: 180, height: 24, borderRadius: 4),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                itemCount: 4,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      children: [
                        const SkeletonLoader(width: 140, height: 140, borderRadius: 12),
                        const SizedBox(height: 8),
                        SkeletonLoader(
                          width: 140,
                          height: 16,
                          borderRadius: 4,
                        ),
                        const SizedBox(height: 4),
                        SkeletonLoader(
                          width: 100,
                          height: 14,
                          borderRadius: 4,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        // Skeleton for category sections
        for (int i = 0; i < 3; i++)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SkeletonLoader(width: 120, height: 24, borderRadius: 4),
              ),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SkeletonLoader(width: 160, height: 160, borderRadius: 12),
                          const SizedBox(height: 8),
                          SkeletonLoader(width: 140, height: 16, borderRadius: 4),
                          const SizedBox(height: 4),
                          SkeletonLoader(width: 80, height: 14, borderRadius: 4),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xFFF5D505),
      child: _isLoading
          ? _buildSkeletonLoader()
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: PlayHistorySection(
                    historyService: widget.historyService,
                    playerService: widget.playerService,
                    playlistService: widget.playlistService,
                  ),
                ),
                ...sections.map((section) => SliverToBoxAdapter(
                  child: PlaylistCategorySection(
                    playerService: widget.playerService,
                    playlistService: widget.playlistService,
                    title: section.title,
                    playlistUrls: section.playlistUrls,
                  ),
                )).toList(),
                const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
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