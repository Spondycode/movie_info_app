import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';

class MovieHistoryService {
  static const String _historyKey = 'movie_history';
  static const int _maxHistorySize = 50;

  /// Save a movie to the search history
  Future<void> saveMovie(Movie movie) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey);
    
    List<Map<String, dynamic>> history = [];
    
    if (historyJson != null) {
      final decoded = jsonDecode(historyJson) as List;
      history = decoded.cast<Map<String, dynamic>>();
    }
    
    // Remove duplicate if exists (by imdbID)
    history.removeWhere((item) => item['imdbID'] == movie.imdbID);
    
    // Add new movie at the beginning
    history.insert(0, movie.toJson());
    
    // Limit history size
    if (history.length > _maxHistorySize) {
      history = history.sublist(0, _maxHistorySize);
    }
    
    // Save back to preferences
    await prefs.setString(_historyKey, jsonEncode(history));
  }

  /// Get all movies from search history
  Future<List<Movie>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey);
    
    if (historyJson == null) {
      return [];
    }
    
    try {
      final decoded = jsonDecode(historyJson) as List;
      final history = decoded.cast<Map<String, dynamic>>();
      return history.map((json) => Movie.fromJson(json)).toList();
    } catch (e) {
      // If there's an error parsing, return empty list
      return [];
    }
  }

  /// Clear all search history
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  /// Remove a specific movie from history by imdbID
  Future<void> removeMovie(String imdbID) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey);
    
    if (historyJson == null) return;
    
    try {
      final decoded = jsonDecode(historyJson) as List;
      final history = decoded.cast<Map<String, dynamic>>();
      
      // Remove the movie with matching imdbID
      history.removeWhere((item) => item['imdbID'] == imdbID);
      
      // Save back to preferences
      await prefs.setString(_historyKey, jsonEncode(history));
    } catch (e) {
      // If there's an error, do nothing
    }
  }
}
