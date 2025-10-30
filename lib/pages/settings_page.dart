import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/settings_service.dart';
import '../services/omdb_service.dart';
import 'search_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _apiKeyController = TextEditingController();
  final _settingsService = SettingsService();
  final _omdbService = OmdbService();
  bool _isLoading = false;
  String? _validationMessage;
  bool? _isValid;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final apiKey = await _settingsService.getApiKey();
    if (apiKey != null) {
      setState(() {
        _apiKeyController.text = apiKey;
      });
    }
  }

  Future<void> _saveApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    
    if (apiKey.isEmpty) {
      setState(() {
        _validationMessage = 'Please enter an API key';
        _isValid = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _validationMessage = 'Validating API key...';
      _isValid = null;
    });

    // Validate the API key
    final isValid = await _omdbService.validateApiKey(apiKey);

    if (isValid) {
      await _settingsService.saveApiKey(apiKey);
      setState(() {
        _isLoading = false;
        _validationMessage = 'API key saved successfully!';
        _isValid = true;
      });
      
      // Navigate to Search Page after successful save
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const SearchPage(),
          ),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
        _validationMessage = 'Invalid API key. Please check and try again.';
        _isValid = false;
      });
    }
  }

  Future<void> _launchOmdbUrl() async {
    final url = Uri.parse('https://www.omdbapi.com/apikey.aspx');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // API Key Section
            const Text(
              'OMDB API Key',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                hintText: 'Enter your OMDB API key',
                border: const OutlineInputBorder(),
                suffixIcon: _isValid == true
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : _isValid == false
                        ? const Icon(Icons.error, color: Colors.red)
                        : null,
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            if (_validationMessage != null)
              Text(
                _validationMessage!,
                style: TextStyle(
                  color: _isValid == true ? Colors.green : Colors.red,
                  fontSize: 14,
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveApiKey,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save API Key'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _launchOmdbUrl,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Get API Key from OMDB'),
              ),
            ),
            const SizedBox(height: 32),

            // Instructions Section
            const Text(
              'How to Use',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1. Get Your API Key',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text('• Tap "Get API Key from OMDB" above'),
                    Text('• Sign up for a free account'),
                    Text('• Copy your API key'),
                    Text('• Paste it in the field above and save'),
                    SizedBox(height: 16),
                    Text(
                      '2. Search for Movies',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text('• Go to the "Search" tab'),
                    Text('• Browse IMDB for movies'),
                    Text('• Copy the movie URL or ID'),
                    SizedBox(height: 16),
                    Text(
                      '3. Fetch Movie Info',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text('• Go to the "Fetch" tab'),
                    Text('• Paste the IMDB URL or movie ID (e.g., tt0133093)'),
                    Text('• Tap "Fetch Movie Info"'),
                    Text('• The movie info will be copied to your clipboard'),
                    Text('• Paste it anywhere you want!'),
                    SizedBox(height: 16),
                    Text(
                      'About OMDB',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text('The Open Movie Database (OMDB) API provides movie information from IMDB.'),
                    Text('The free tier includes 1,000 requests per day.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
