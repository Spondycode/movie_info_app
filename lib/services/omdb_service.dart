import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';

class OmdbService {
  static const String _baseUrl = 'https://www.omdbapi.com/';

  /// Fetch movie data from OMDB API by IMDB ID
  Future<Movie> fetchMovieById(String imdbId, String apiKey) async {
    // Clean up the IMDB ID (remove any URL parts)
    final cleanId = _extractImdbId(imdbId);
    
    final url = Uri.parse('$_baseUrl?i=$cleanId&apikey=$apiKey');
    
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      
      // Check if the API returned an error
      if (jsonData['Response'] == 'False') {
        throw Exception(jsonData['Error'] ?? 'Movie not found');
      }
      
      return Movie.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch movie data: ${response.statusCode}');
    }
  }

  /// Validate if the API key works by making a test request
  Future<bool> validateApiKey(String apiKey) async {
    try {
      // Test with a known movie ID (The Matrix)
      final url = Uri.parse('$_baseUrl?i=tt0133093&apikey=$apiKey');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['Response'] != 'False';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Extract IMDB ID from various input formats
  /// Supports: tt1234567, https://www.imdb.com/title/tt1234567/, etc.
  String _extractImdbId(String input) {
    final trimmed = input.trim();
    
    // If it's already just the ID
    if (RegExp(r'^tt\d{7,8}$').hasMatch(trimmed)) {
      return trimmed;
    }
    
    // Extract from URL
    final match = RegExp(r'tt\d{7,8}').firstMatch(trimmed);
    if (match != null) {
      return match.group(0)!;
    }
    
    // If nothing matches, return as-is and let the API handle the error
    return trimmed;
  }
}
