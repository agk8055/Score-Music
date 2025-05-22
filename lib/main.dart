import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/search_screen.dart';
import 'screens/about_screen.dart';
import 'screens/home_screen.dart';
import 'services/music_player_service.dart';
import 'services/play_history_service.dart';
import 'widgets/music_controller.dart';
import 'widgets/base_scaffold.dart';
import 'models/song.dart';

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
          backgroundColor: Color(0xFF1A1A1A),
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
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final MusicPlayerService playerService;
  final PlayHistoryService historyService;
  
  const MyHomePage({
    super.key, 
    required this.playerService,
    required this.historyService,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  @override
  void dispose() {
    widget.playerService.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar() {
    switch (_selectedIndex) {
      case 0:
        return AppBar(
          title: const Text(
            'Home',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF5D505),
            ),
          ),
        );
      case 1:
        return AppBar(
          title: const Text(
            'Search',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF5D505),
            ),
          ),
        );
      default:
        return AppBar(
          title: const Text(
            'Score',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF5D505),
            ),
          ),
        );
    }
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return HomeScreen(
          playerService: widget.playerService,
          historyService: widget.historyService,
        );
      case 1:
        return SearchScreen(playerService: widget.playerService);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      playerService: widget.playerService,
      appBar: _buildAppBar(),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1A1A1A),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Score',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF5D505),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your Music Companion',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.library_music,
                color: Color(0xFFF5D505),
              ),
              title: const Text(
                'Library',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to library screen
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.settings,
                color: Color(0xFFF5D505),
              ),
              title: const Text(
                'Settings',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to settings screen
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.info,
                color: Color(0xFFF5D505),
              ),
              title: const Text(
                'About',
                style: TextStyle(color: Colors.white),
              ),
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
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
        ],
      ),
    );
  }
}
