import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/search_screen.dart';
import 'screens/about_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/library_screen.dart';
import 'services/music_player_service.dart';
import 'services/play_history_service.dart';
import 'services/search_cache_service.dart';
import 'services/api_service.dart';
import 'services/playlist_service.dart';
import 'widgets/music_controller.dart';
import 'widgets/base_scaffold.dart';
import 'models/song.dart';
import 'models/album.dart';
import 'widgets/bottom_navigation.dart';

class SearchStateProvider extends ChangeNotifier {
  final SearchCacheService _cacheService;
  String _currentQuery = '';
  List<Song> _searchResults = [];
  List<Album> _albumResults = [];
  bool _isLoading = false;
  String? _error;

  SearchStateProvider(this._cacheService) {
    _currentQuery = _cacheService.lastQuery;
    if (_currentQuery.isNotEmpty) {
      _restoreLastSearch();
    }
  }

  String get currentQuery => _currentQuery;
  List<Song> get searchResults => _searchResults;
  List<Album> get albumResults => _albumResults;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _restoreLastSearch() {
    final cachedResults = _cacheService.getCachedResults(_currentQuery);
    if (cachedResults != null) {
      _searchResults = cachedResults['songs'] as List<Song>;
      _albumResults = cachedResults['albums'] as List<Album>;
      notifyListeners();
    }
  }

  Future<void> performSearch(String query) async {
    if (query.isEmpty) return;

    _currentQuery = query;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cachedResults = _cacheService.getCachedResults(query);
      if (cachedResults != null) {
        _searchResults = cachedResults['songs'] as List<Song>;
        _albumResults = cachedResults['albums'] as List<Album>;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final apiService = ApiService();
      final results = await apiService.search(query);
      final songs = results['songs'] as List<Song>;
      
      _searchResults = songs;
      _isLoading = false;
      notifyListeners();

      final albums = await apiService.loadAlbumsForSongs(_searchResults);
      await _cacheService.cacheResults(query, songs, albums);
      
      _albumResults = albums;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _currentQuery = '';
    _searchResults = [];
    _albumResults = [];
    _error = null;
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  
  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    final historyService = PlayHistoryService(prefs);
    final playerService = MusicPlayerService(historyService);
    final searchCacheService = SearchCacheService(prefs);
    final searchStateProvider = SearchStateProvider(searchCacheService);
    final playlistService = PlaylistService(prefs);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Score',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: const Color(0xFFF5D505),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF5D505),
          secondary: Color(0xFFF5D505),
          surface: Color(0xFF1A1A1A),
          background: Colors.black,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFFF5D505)),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFFF5D505),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: MyHomePage(
        playerService: playerService,
        historyService: historyService,
        searchCacheService: searchCacheService,
        searchStateProvider: searchStateProvider,
        playlistService: playlistService,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final MusicPlayerService playerService;
  final PlayHistoryService historyService;
  final SearchCacheService searchCacheService;
  final SearchStateProvider searchStateProvider;
  final PlaylistService playlistService;
  
  const MyHomePage({
    super.key, 
    required this.playerService,
    required this.historyService,
    required this.searchCacheService,
    required this.searchStateProvider,
    required this.playlistService,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;
    
    if (isFirstLaunch) {
      if (mounted) {
        _showNameDialog();
      }
      await prefs.setBool('is_first_launch', false);
    }
  }

  Future<void> _showNameDialog() async {
    final TextEditingController nameController = TextEditingController();
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Welcome to Score!',
            style: TextStyle(color: Color(0xFFF5D505)),
          ),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'Enter your name',
              hintStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFF5D505)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFF5D505)),
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              child: const Text(
                'Continue',
                style: TextStyle(color: Color(0xFFF5D505)),
              ),
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('user_name', nameController.text.trim());
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    widget.playerService.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar() {
    switch (_selectedIndex) {
      case 0:
        return AppBar(
          leadingWidth: 40,
          leading: Builder(
            builder: (context) => FutureBuilder<String?>(
              future: SharedPreferences.getInstance().then((prefs) => prefs.getString('user_name')),
              builder: (context, snapshot) {
                final userName = snapshot.data;
                final firstLetter = userName?.isNotEmpty == true ? userName![0].toUpperCase() : '?';
                return UserAvatar(
                  letter: firstLetter,
                  onTap: () => Scaffold.of(context).openDrawer(),
                );
              },
            ),
          ),
          title: const Text(
            'Score',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF5D505),
            ),
          ),
        );
      case 1:
        return AppBar(
          leadingWidth: 40,
          leading: Builder(
            builder: (context) => FutureBuilder<String?>(
              future: SharedPreferences.getInstance().then((prefs) => prefs.getString('user_name')),
              builder: (context, snapshot) {
                final userName = snapshot.data;
                final firstLetter = userName?.isNotEmpty == true ? userName![0].toUpperCase() : '?';
                return UserAvatar(
                  letter: firstLetter,
                  onTap: () => Scaffold.of(context).openDrawer(),
                );
              },
            ),
          ),
          title: const Text(
            'Search',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF5D505),
            ),
          ),
        );
      case 2:
        return AppBar(
          leadingWidth: 40,
          leading: Builder(
            builder: (context) => FutureBuilder<String?>(
              future: SharedPreferences.getInstance().then((prefs) => prefs.getString('user_name')),
              builder: (context, snapshot) {
                final userName = snapshot.data;
                final firstLetter = userName?.isNotEmpty == true ? userName![0].toUpperCase() : '?';
                return UserAvatar(
                  letter: firstLetter,
                  onTap: () => Scaffold.of(context).openDrawer(),
                );
              },
            ),
          ),
          title: const Text(
            'Library',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF5D505),
            ),
          ),
        );
      case 3:
        return AppBar(
          leadingWidth: 40,
          leading: Builder(
            builder: (context) => FutureBuilder<String?>(
              future: SharedPreferences.getInstance().then((prefs) => prefs.getString('user_name')),
              builder: (context, snapshot) {
                final userName = snapshot.data;
                final firstLetter = userName?.isNotEmpty == true ? userName![0].toUpperCase() : '?';
                return UserAvatar(
                  letter: firstLetter,
                  onTap: () => Scaffold.of(context).openDrawer(),
                );
              },
            ),
          ),
          title: const Text(
            'Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF5D505),
            ),
          ),
        );
      default:
        return AppBar();
    }
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return HomeScreen(
          playerService: widget.playerService,
          historyService: widget.historyService,
          playlistService: widget.playlistService,
        );
      case 1:
        return SearchScreen(
          playerService: widget.playerService,
          searchStateProvider: widget.searchStateProvider,
          searchCacheService: widget.searchCacheService,
          playlistService: widget.playlistService,
        );
      case 2:
        return LibraryScreen(
          playerService: widget.playerService,
        );
      case 3:
        return SettingsScreen(
          historyService: widget.historyService,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      playerService: widget.playerService,
      playlistService: widget.playlistService,
      appBar: _buildAppBar(),
      body: _buildBody(),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1A1A1A),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFFF5D505),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Score',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined, color: Colors.white),
              title: const Text('Home', style: TextStyle(color: Colors.white)),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.search_outlined, color: Colors.white),
              title: const Text('Search', style: TextStyle(color: Colors.white)),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.library_music_outlined, color: Colors.white),
              title: const Text('Library', style: TextStyle(color: Colors.white)),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
                Navigator.pop(context);
              },
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: Colors.white),
              title: const Text('Settings', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      historyService: widget.historyService,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white),
              title: const Text('About', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AboutScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  final String letter;
  final VoidCallback onTap;

  const UserAvatar({
    super.key,
    required this.letter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFFF5D505),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    letter,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
