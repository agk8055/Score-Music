import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HomeCustomizationScreen extends StatefulWidget {
  const HomeCustomizationScreen({Key? key}) : super(key: key);

  @override
  State<HomeCustomizationScreen> createState() => _HomeCustomizationScreenState();
}

class _HomeCustomizationScreenState extends State<HomeCustomizationScreen> {
  final List<PlaylistSection> sections = [];
  final _formKey = GlobalKey<FormState>();
  bool hasCustomConfig = false;

  // Default configuration
  final List<PlaylistSection> defaultSections = [
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

  @override
  void initState() {
    super.initState();
    _loadSavedConfiguration();
  }

  Future<void> _loadSavedConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    final savedConfig = prefs.getString('home_screen_config');
    
    if (savedConfig != null) {
      final List<dynamic> decoded = json.decode(savedConfig);
      setState(() {
        sections.clear();
        sections.addAll(
          decoded.map((item) => PlaylistSection.fromJson(item)).toList(),
        );
        hasCustomConfig = true;
      });
    } else {
      setState(() {
        sections.clear();
        sections.addAll(defaultSections);
        hasCustomConfig = false;
      });
    }
  }

  Future<void> _saveConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    final config = json.encode(sections.map((s) => s.toJson()).toList());
    await prefs.setString('home_screen_config', config);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Home screen configuration saved'),
          backgroundColor: Color(0xFF1A1A1A),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _resetToDefault() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Reset to Default',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to reset to default configuration? This will remove all your customizations.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Reset',
              style: TextStyle(color: Color(0xFFF5D505)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('home_screen_config');
      setState(() {
        sections.clear();
        sections.addAll(defaultSections);
        hasCustomConfig = false;
      });
    }
  }

  void _addNewSection() {
    setState(() {
      sections.add(PlaylistSection(title: '', playlistUrls: ['']));
      hasCustomConfig = true;
    });
  }

  void _removeSection(int index) {
    setState(() {
      sections.removeAt(index);
      hasCustomConfig = true;
    });
  }

  void _addUrlToSection(int sectionIndex) {
    setState(() {
      sections[sectionIndex].playlistUrls.add('');
      hasCustomConfig = true;
    });
  }

  void _removeUrlFromSection(int sectionIndex, int urlIndex) {
    setState(() {
      sections[sectionIndex].playlistUrls.removeAt(urlIndex);
      hasCustomConfig = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Customize Home Screen',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF5D505),
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFF5D505)),
        actions: [
          if (hasCustomConfig)
            IconButton(
              icon: const Icon(Icons.restore),
              onPressed: _resetToDefault,
              tooltip: 'Reset to Default',
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveConfiguration,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: Column(
        children: [
          if (!hasCustomConfig)
            Container(
              padding: const EdgeInsets.all(16.0),
              color: const Color(0xFF1A1A1A),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFF5D505)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'These are the default sections. Make changes to customize your home screen.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: sections.length + 1,
                itemBuilder: (context, index) {
                  if (index == sections.length) {
                    return ElevatedButton.icon(
                      onPressed: _addNewSection,
                      icon: const Icon(Icons.add),
                      label: const Text('Add New Section'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5D505),
                        foregroundColor: Colors.black,
                      ),
                    );
                  }

                  final section = sections[index];
                  return Card(
                    color: const Color(0xFF1A1A1A),
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: section.title,
                                  decoration: const InputDecoration(
                                    labelText: 'Section Title',
                                    labelStyle: TextStyle(color: Colors.grey),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Color(0xFFF5D505)),
                                    ),
                                  ),
                                  style: const TextStyle(color: Colors.white),
                                  onChanged: (value) {
                                    section.title = value;
                                    hasCustomConfig = true;
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeSection(index),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...section.playlistUrls.asMap().entries.map((entry) {
                            final urlIndex = entry.key;
                            final url = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: url,
                                      decoration: InputDecoration(
                                        labelText: 'Playlist URL ${urlIndex + 1}',
                                        labelStyle: const TextStyle(color: Colors.grey),
                                        enabledBorder: const UnderlineInputBorder(
                                          borderSide: BorderSide(color: Colors.grey),
                                        ),
                                        focusedBorder: const UnderlineInputBorder(
                                          borderSide: BorderSide(color: Color(0xFFF5D505)),
                                        ),
                                      ),
                                      style: const TextStyle(color: Colors.white),
                                      onChanged: (value) {
                                        section.playlistUrls[urlIndex] = value;
                                        hasCustomConfig = true;
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                                    onPressed: () => _removeUrlFromSection(index, urlIndex),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          TextButton.icon(
                            onPressed: () => _addUrlToSection(index),
                            icon: const Icon(Icons.add, color: Color(0xFFF5D505)),
                            label: const Text(
                              'Add URL',
                              style: TextStyle(color: Color(0xFFF5D505)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PlaylistSection {
  String title;
  List<String> playlistUrls;

  PlaylistSection({
    required this.title,
    required this.playlistUrls,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'playlistUrls': playlistUrls,
    };
  }

  factory PlaylistSection.fromJson(Map<String, dynamic> json) {
    return PlaylistSection(
      title: json['title'] as String,
      playlistUrls: List<String>.from(json['playlistUrls']),
    );
  }
} 