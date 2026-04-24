import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';

class FavoritesStore extends ChangeNotifier {
  static final FavoritesStore _instance = FavoritesStore._();
  static FavoritesStore get instance => _instance;
  FavoritesStore._();

  final Set<String> _favoriteIds = {};
  String? _userId; // track which user's favorites are loaded

  String _key(String? uid) => uid != null ? 'favorites_$uid' : 'favorites_guest';

  // Load favorites for a specific user (call after login)
  Future<void> loadForUser(String? userId) async {
    _userId = userId;
    _favoriteIds.clear();
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key(userId)) ?? [];
    _favoriteIds.addAll(saved);
    notifyListeners();
  }

  // Load on app start (guest or last logged-in user)
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('current_user_id');
    await loadForUser(uid);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key(_userId), _favoriteIds.toList());
  }

  // Clear favorites on logout
  Future<void> clear() async {
    _userId = null;
    _favoriteIds.clear();
    notifyListeners();
  }

  bool isFavorite(String movieId) => _favoriteIds.contains(movieId);

  void toggle(String movieId) {
    if (_favoriteIds.contains(movieId)) {
      _favoriteIds.remove(movieId);
    } else {
      _favoriteIds.add(movieId);
    }
    notifyListeners();
    _save();
  }

  List<Movie> getFavorites(List<Movie> allMovies) {
    return allMovies.where((m) => _favoriteIds.contains(m.id)).toList();
  }

  int get count => _favoriteIds.length;
}
