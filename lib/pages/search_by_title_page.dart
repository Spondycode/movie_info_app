import 'package:flutter/material.dart';
import '../models/search_result.dart';
import '../services/omdb_service.dart';
import '../services/settings_service.dart';
import '../services/clipboard_service.dart';
import '../services/movie_history_service.dart';

class SearchByTitlePage extends StatefulWidget {
  const SearchByTitlePage({super.key});

  @override
  State<SearchByTitlePage> createState() => _SearchByTitlePageState();
}

class _SearchByTitlePageState extends State<SearchByTitlePage> {
  final _searchController = TextEditingController();
  final _omdbService = OmdbService();
  final _settingsService = SettingsService();
  final _clipboardService = ClipboardService();
  final _historyService = MovieHistoryService();
  
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;
  String? _errorMessage;
  String? _apiKey;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final key = await _settingsService.getApiKey();
    setState(() {
      _apiKey = key;
    });
  }

  Future<void> _searchMovies() async {
    final query = _searchController.text.trim();
    
    if (query.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a movie title';
      });
      return;
    }

    if (_apiKey == null || _apiKey!.isEmpty) {
      setState(() {
        _errorMessage = 'Please set your API key in Settings';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _searchResults = [];
    });

    try {
      final results = await _omdbService.searchMovies(query, _apiKey!);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isSearching = false;
      });
    }
  }

  Future<void> _fetchMovieDetails(String imdbID) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      _showSnackBar('Please set your API key in Settings');
      return;
    }

    try {
      // Show loading indicator
      _showSnackBar('Fetching movie details...');

      final movie = await _omdbService.fetchMovieById(imdbID, _apiKey!);
      
      // Copy to clipboard
      final markdown = movie.toMarkdown();
      await _clipboardService.copyToClipboard(markdown);
      
      // Save to history
      await _historyService.saveMovie(movie);
      
      _showSnackBar('Movie details copied to clipboard!');
    } catch (e) {
      _showSnackBar('Error: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Movies'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Movie Title',
                hintText: 'Enter movie title to search',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchMovies,
                ),
              ),
              onSubmitted: (_) => _searchMovies(),
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                color: Colors.red[100],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_isSearching)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          if (!_isSearching && _searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: ListTile(
                      leading: result.poster != 'N/A'
                          ? Image.network(
                              result.poster,
                              width: 50,
                              height: 75,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.movie, size: 50),
                            )
                          : const Icon(Icons.movie, size: 50),
                      title: Text(
                        result.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Year: ${result.year}'),
                          Text('Type: ${result.type}'),
                          Text('IMDB ID: ${result.imdbID}'),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward),
                      isThreeLine: true,
                      onTap: () => _fetchMovieDetails(result.imdbID),
                    ),
                  );
                },
              ),
            ),
          if (!_isSearching && _searchResults.isEmpty && _errorMessage == null)
            const Expanded(
              child: Center(
                child: Text(
                  'Search for movies by title',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
