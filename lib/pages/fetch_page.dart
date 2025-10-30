import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/omdb_service.dart';
import '../services/clipboard_service.dart';
import '../services/movie_history_service.dart';
import '../models/movie.dart';

class FetchPage extends StatefulWidget {
  const FetchPage({super.key});

  @override
  State<FetchPage> createState() => _FetchPageState();
}

class _FetchPageState extends State<FetchPage> with AutomaticKeepAliveClientMixin {
  final _inputController = TextEditingController();
  final _settingsService = SettingsService();
  final _omdbService = OmdbService();
  final _clipboardService = ClipboardService();
  final _historyService = MovieHistoryService();
  
  bool _isLoading = false;
  Movie? _movie;
  String? _errorMessage;
  bool _hasCheckedClipboard = false;

  @override
  bool get wantKeepAlive => false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _checkAndPopulateClipboard() async {
    if (_hasCheckedClipboard) return;
    
    final text = await _clipboardService.getFromClipboard();
    if (text != null && text.isNotEmpty && _inputController.text.isEmpty) {
      setState(() {
        _inputController.text = text;
        _hasCheckedClipboard = true;
      });
    } else {
      setState(() {
        _hasCheckedClipboard = true;
      });
    }
  }

  Future<void> _fetchMovie() async {
    // Dismiss keyboard when fetch is triggered
    FocusScope.of(context).unfocus();
    
    final input = _inputController.text.trim();
    
    if (input.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an IMDB URL or movie ID';
        _movie = null;
      });
      return;
    }

    // Check if API key exists
    final apiKey = await _settingsService.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      setState(() {
        _errorMessage = 'Please set your OMDB API key in Settings first';
        _movie = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _movie = null;
    });

    try {
      final movie = await _omdbService.fetchMovieById(input, apiKey);
      final markdown = movie.toMarkdown();
      
      // Copy to clipboard
      await _clipboardService.copyToClipboard(markdown);
      
      // Save to history
      await _historyService.saveMovie(movie);
      
      setState(() {
        _isLoading = false;
        _movie = movie;
        _errorMessage = null;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Movie info copied to clipboard!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _movie = null;
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final text = await _clipboardService.getFromClipboard();
    if (text != null && text.isNotEmpty) {
      setState(() {
        _inputController.text = text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    // Check clipboard when widget is built
    if (!_hasCheckedClipboard) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndPopulateClipboard();
      });
    }
    
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside of text fields
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fetch Movie Info'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter IMDB URL or Movie ID',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _inputController,
              decoration: InputDecoration(
                hintText: 'e.g., tt0133093 or https://www.imdb.com/title/tt0133093/',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  onPressed: _pasteFromClipboard,
                  tooltip: 'Paste from clipboard',
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _fetchMovie,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Fetch Movie Info',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            
            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
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
            ],

            // Movie preview
            if (_movie != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Preview (Copied to Clipboard)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_movie!.poster != 'N/A')
                        Center(
                          child: Image.network(
                            _movie!.poster,
                            height: 300,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.movie, size: 100);
                            },
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        '${_movie!.title} (${_movie!.year})',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            _movie!.imdbRating,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            _movie!.genre,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _movie!.plot,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Director: ${_movie!.director}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Cast: ${_movie!.actors}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }
}
