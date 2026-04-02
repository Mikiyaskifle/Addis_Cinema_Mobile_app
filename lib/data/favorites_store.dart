import 'package:flutter/material.dart';
import '../models/movie.dart';

class FavoritesStore extends ChangeNotifier {
  static final FavoritesStore _instance = FavoritesStore._();
  static FavoritesStore get instance => _instance;
  FavoritesStore._();

  final Set<String> _favoriteIds = {};

  bool isFavorite(String movieId) => _favoriteIds.contains(movieId);

  void toggle(String movieId) {
    if (_favoriteIds.contains(movieId)) {
      _favoriteIds.remove(movieId);
    } else {
      _favoriteIds.add(movieId);
    }
    notifyListeners();
  }

  List<Movie> getFavorites(List<Movie> allMovies) {
    return allMovies.where((m) => _favoriteIds.contains(m.id)).toList();
  }

  int get count => _favoriteIds.length;
}
