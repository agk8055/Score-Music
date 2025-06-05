import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:just_audio_background/just_audio_background.dart';
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

  // Initialize just_audio_background with proper error handling
  bool audioServiceInitialized = false;
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.score.music',
      androidNotificationChannelName: 'Score Music',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'drawable/ic_notification',
      androidShowNotificationBadge: true,
      androidStopForegroundOnPause: true,
    );
    audioServiceInitialized = true;
    debugPrint('Audio service initialized successfully');
  } catch (e, stack) {
    debugPrint('Audio service initialization failed: $e');
    debugPrint('Stack trace: $stack');
    // Show error UI for audio service failure
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Failed to initialize audio service',
                  style: TextStyle(color: Colors.red, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'This may affect music playback functionality.\nPlease try reinstalling the app.',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    // Try to reinitialize audio service
                    try {
                      await JustAudioBackground.init(
                        androidNotificationChannelId: 'com.score.music',
                        androidNotificationChannelName: 'Score Music',
                        androidNotificationOngoing: true,
                        androidNotificationIcon: 'drawable/ic_notification',
                        androidShowNotificationBadge: true,
                        androidStopForegroundOnPause: true,
                      );
                      audioServiceInitialized = true;
                      // Restart the app
                      runApp(await _initializeApp());
                    } catch (e) {
                      debugPrint('Audio service reinitialization failed: $e');
                    }
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return;
  }

  // Continue with app initialization
  runApp(await _initializeApp());
}

// Separate app initialization into a function for better organization
Future<Widget> _initializeApp() async {
  // Enable verbose logging
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };
  
  // Handle async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Async Error: $error');
    debugPrint('Stack trace: $stack');
    return true;
  };

  // Initialize API service first
  try {
    await ApiService.initialize();
    debugPrint('API Service initialized successfully');
  } catch (e) {
    debugPrint('API Service initialization failed: $e');
    // Continue anyway, as the app can work offline
  }
  
  // Initialize SharedPreferences with error handling
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
    debugPrint('SharedPreferences initialized successfully');
  } catch (e) {
    debugPrint('SharedPreferences initialization failed: $e');
    // Show error UI if SharedPreferences fails
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Failed to initialize app storage',
                style: TextStyle(color: Colors.red, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Error: $e\n\nPlease try reinstalling the app.',
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  // Try to reinitialize SharedPreferences
                  try {
                    prefs = await SharedPreferences.getInstance();
                    // Restart the app
                    runApp(await _initializeApp());
                  } catch (e) {
                    debugPrint('SharedPreferences reinitialization failed: $e');
                  }
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  if (prefs == null) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'Failed to initialize app storage\n\nPlease try reinstalling the app.',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // Initialize services with error handling
  try {
    final historyService = PlayHistoryService(prefs);
    final playerService = MusicPlayerService(historyService);
    final searchCacheService = SearchCacheService(prefs);
    final searchStateProvider = SearchStateProvider(searchCacheService);
    final playlistService = PlaylistService(prefs);
    
    debugPrint('All services initialized successfully');
    return MyApp(
      prefs: prefs,
      playerService: playerService,
      historyService: historyService,
      searchCacheService: searchCacheService,
      searchStateProvider: searchStateProvider,
      playlistService: playlistService,
    );
  } catch (e, stack) {
    debugPrint('Service initialization failed: $e');
    debugPrint('Stack trace: $stack');
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Failed to initialize app services',
                style: TextStyle(color: Colors.red, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Error: $e\n\nPlease try reinstalling the app.',
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  // Try to reinitialize services
                  runApp(await _initializeApp());
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  final MusicPlayerService playerService;
  final PlayHistoryService historyService;
  final SearchCacheService searchCacheService;
  final SearchStateProvider searchStateProvider;
  final PlaylistService playlistService;
  
  const MyApp({
    super.key,
    required this.prefs,
    required this.playerService,
    required this.historyService,
    required this.searchCacheService,
    required this.searchStateProvider,
    required this.playlistService,
  });

  @override
  Widget build(BuildContext context) {
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
  final int initialIndex;
  
  const MyHomePage({
    super.key, 
    required this.playerService,
    required this.historyService,
    required this.searchCacheService,
    required this.searchStateProvider,
    required this.playlistService,
    this.initialIndex = 0,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late int _selectedIndex;
  late ConnectivityResult _connectivityResult;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _checkFirstLaunch();
    _initConnectivity();
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

  Future<void> _initConnectivity() async {
    _connectivityResult = await Connectivity().checkConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (_connectivityResult != result) {
        _connectivityResult = result;
        if (result == ConnectivityResult.none) {
          _showOfflineNotification();
        } else {
          _showOnlineNotification();
          if (_selectedIndex == 0) {
            // Reload home page when coming back online
            setState(() {});
          }
        }
      }
    });
  }

  void _showOfflineNotification() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You are offline'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(8),
      ),
    );
  }

  void _showOnlineNotification() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You are back online'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(8),
      ),
    );
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
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
