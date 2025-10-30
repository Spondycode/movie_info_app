import 'package:flutter/material.dart';
import 'pages/settings_page.dart';
import 'pages/search_page.dart';
import 'pages/fetch_page.dart';
import 'services/settings_service.dart';

void main() {
  runApp(const MovieInfoApp());
}

class MovieInfoApp extends StatelessWidget {
  const MovieInfoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie Info',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 1; // Start with Search page
  final _settingsService = SettingsService();
  bool _hasApiKey = false;

  final List<Widget> _pages = [
    const SettingsPage(),
    const SearchPage(),
    const FetchPage(),
  ];

  @override
  void initState() {
    super.initState();
    _checkApiKey();
  }

  Future<void> _checkApiKey() async {
    final hasKey = await _settingsService.hasApiKey();
    setState(() {
      _hasApiKey = hasKey;
    });

    // If no API key, navigate to settings
    if (!hasKey) {
      setState(() {
        _selectedIndex = 0;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.download),
            label: 'Fetch',
          ),
        ],
      ),
    );
  }
}
