import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';
import '../services/api_service.dart';

class FavoritesStore extends ChangeNotifier {
  static final FavoritesStore _instance = FavoritesStore._();
  static FavoritesStore get instance => _instance;
  FavoritesStore._();

  final Set<String> _favoriteIds = {};
  String? _userId; // track which user's favorites are loaded
  bool _isLoading = false;
  
  // Getter for userId (for UI to check if user is logged in)
  String? get userId => _userId;

  // Load favorites for a specific user (call after login)
  Future<void> loadForUser(String? userId) async {
    print('=== FavoritesStore.loadForUser() called with userId: $userId ===');
    
    // Handle case where userId might be the string "null"
    if (userId == 'null') {
      _userId = null;
    } else {
      _userId = userId;
    }
    
    print('User ID set to: $_userId');
    print('Local storage key will be: ${_getLocalStorageKey()}');
    print('Current _favoriteIds before clear: $_favoriteIds');
    
    _favoriteIds.clear();
    
    if (_userId != null) {
      // User is logged in - FIRST try to load from backend (database)
      // This ensures favorites persist across devices
      try {
        print('Loading favorites from backend for user: $_userId');
        final serverFavorites = await ApiService.getFavorites();
        print('Loaded ${serverFavorites.length} favorites from backend: $serverFavorites');
        
        // Start with server favorites (database)
        _favoriteIds.addAll(serverFavorites);
        
        // Also check local storage for any favorites added while offline
        final localFavorites = <String>{};
        try {
          final prefs = await SharedPreferences.getInstance();
          final key = _getLocalStorageKey();
          final saved = prefs.getStringList(key) ?? [];
          localFavorites.addAll(saved);
          print('Found ${localFavorites.length} favorites in local storage');
        } catch (e) {
          print('Error reading local storage: $e');
        }
        
        // Merge local favorites with server favorites
        // Local favorites might have been added while offline
        final beforeMerge = _favoriteIds.length;
        _favoriteIds.addAll(localFavorites);
        final afterMerge = _favoriteIds.length;
        
        if (afterMerge > beforeMerge) {
          print('Added ${afterMerge - beforeMerge} local favorites not on server');
          
          // Save merged list to local storage
          await _saveToLocalStorage();
          
          // Sync any new local favorites to server
          for (final movieId in localFavorites) {
            if (!serverFavorites.contains(movieId)) {
              await ApiService.addFavorite(movieId);
            }
          }
        } else {
          // Save server favorites to local storage (overwrites local)
          await _saveToLocalStorage();
        }
        
        print('Total favorites after merge: ${_favoriteIds.length}');
      } catch (e) {
        print('Error loading favorites from backend: $e');
        // If backend fails, fall back to local storage
        await _loadFromLocalStorage();
        print('Loaded ${_favoriteIds.length} favorites from local storage (fallback)');
      }
    } else {
      // User is guest - load from local storage only
      await _loadFromLocalStorage();
      print('Loaded ${_favoriteIds.length} favorites from local storage');
    }
    
    notifyListeners();
  }
  
  // Sync with backend (called in background after loading from local storage)
  Future<void> _syncWithBackend() async {
    if (_userId == null) return;
    
    try {
      print('Syncing favorites with backend for user: $_userId');
      final serverFavorites = await ApiService.getFavorites();
      print('Server has ${serverFavorites.length} favorites: $serverFavorites');
      print('Local has ${_favoriteIds.length} favorites: $_favoriteIds');
      
      // Merge server and local favorites (union)
      final merged = {..._favoriteIds, ...serverFavorites};
      if (merged.length != _favoriteIds.length) {
        print('Merging ${merged.length - _favoriteIds.length} favorites from server');
        _favoriteIds.clear();
        _favoriteIds.addAll(merged);
        
        // Save merged list to local storage
        await _saveToLocalStorage();
        
        // Save merged list to backend (update server)
        for (final movieId in merged) {
          if (!serverFavorites.contains(movieId)) {
            await ApiService.addFavorite(movieId);
          }
        }
        
        notifyListeners();
      }
    } catch (e) {
      print('Error syncing with backend: $e');
      // Backend sync failed, but we already have local favorites
    }
  }

  // Load from backend API
  Future<void> _loadFromBackend() async {
    if (_isLoading) return;
    _isLoading = true;
    
    try {
      print('Loading favorites from backend for user: $_userId');
      final favorites = await ApiService.getFavorites();
      _favoriteIds.clear();
      _favoriteIds.addAll(favorites);
      print('Loaded ${favorites.length} favorites from backend: $favorites');
      
      // Also save to local storage for offline access
      await _saveToLocalStorage();
    } catch (e) {
      print('Error loading favorites from backend: $e');
      // Fall back to local storage if backend fails
      try {
        await _loadFromLocalStorage();
      } catch (e2) {
        print('Error loading from local storage: $e2');
        // Just continue with empty favorites
      }
    } finally {
      _isLoading = false;
    }
  }

  // Load from local storage (SharedPreferences)
  Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getLocalStorageKey();
      print('Attempting to load from local storage with key: $key');
      final saved = prefs.getStringList(key) ?? [];
      _favoriteIds.clear();
      _favoriteIds.addAll(saved);
      print('Loaded ${saved.length} favorites from local storage (key: $key): $saved');
    } catch (e) {
      print('Error loading favorites from local storage: $e');
    }
  }

  // Save to local storage (SharedPreferences)
  Future<void> _saveToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getLocalStorageKey();
      final list = _favoriteIds.toList();
      print('Saving ${list.length} favorites to local storage with key: $key');
      await prefs.setStringList(key, list);
      print('Saved ${list.length} favorites to local storage (key: $key): $list');
    } catch (e) {
      print('Error saving favorites to local storage: $e');
    }
  }

  // Get the key for local storage
  String _getLocalStorageKey() {
    if (_userId == null) {
      return 'favorites_guest';
    }
    return 'favorites_$_userId';
  }

  // Load on app start (guest or last logged-in user)
  Future<void> load() async {
    try {
      print('=== FavoritesStore.load() called on app start ===');
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('current_user_id');
      print('Current user ID: $uid');
      
      // Simply call loadForUser with the user ID (or null for guest)
      // This handles both guest and logged-in users with proper backend sync
      await loadForUser(uid);
    } catch (e) {
      print('Error loading favorites in main: $e');
      // Don't rethrow - just continue with empty favorites
      _favoriteIds.clear();
    }
  }

  // Clear favorites on logout
  Future<void> clear() async {
    print('Clearing favorites on logout');
    
    // Save current user favorites before clearing (in case they log back in)
    if (_userId != null) {
      await _saveToLocalStorage();
    }
    
    _userId = null;
    _favoriteIds.clear();
    
    // Load guest favorites after logout
    await _loadFromLocalStorage();
    
    notifyListeners();
  }

  bool isFavorite(String movieId) {
    final isFav = _favoriteIds.contains(movieId);
    print('Checking if movieId $movieId is favorite: $isFav');
    return isFav;
  }

  Future<void> toggle(String movieId) async {
    print('Toggling favorite for movieId: $movieId');
    
    final wasFavorite = _favoriteIds.contains(movieId);
    
    if (wasFavorite) {
      // Remove favorite
      _favoriteIds.remove(movieId);
      print('Removed from favorites');
    } else {
      // Add favorite
      _favoriteIds.add(movieId);
      print('Added to favorites');
    }
    
    // Save to local storage first (for offline access)
    await _saveToLocalStorage();
    
    // If user is logged in, try to sync with backend
    if (_userId != null) {
      try {
        if (wasFavorite) {
          await ApiService.removeFavorite(movieId);
          print('Removed favorite from backend');
        } else {
          await ApiService.addFavorite(movieId);
          print('Added favorite to backend');
        }
      } catch (e) {
        print('Error syncing favorite with backend: $e');
        // Don't revert the change - keep it locally
        // We'll try to sync again later (e.g., on next app start, or with a manual sync)
        // For now, just log the error
      }
    }
    
    print('Current favorites: $_favoriteIds');
    
    notifyListeners();
  }

  List<Movie> getFavorites(List<Movie> allMovies) {
    print('Getting favorites from ${allMovies.length} movies');
    print('Favorite IDs: $_favoriteIds');
    final favs = allMovies.where((m) => _favoriteIds.contains(m.id)).toList();
    print('Found ${favs.length} favorites');
    return favs;
  }

  int get count => _favoriteIds.length;
  
  // Sync local favorites to backend (called after login)
  Future<void> syncToBackend() async {
    if (_userId == null) return;
    
    try {
      print('Syncing ${_favoriteIds.length} favorites to backend');
      await ApiService.syncFavorites(_favoriteIds.toList());
      print('Sync completed');
    } catch (e) {
      print('Error syncing favorites to backend: $e');
    }
  }
  
  // Manual sync with backend (public method for UI)
  Future<void> syncWithBackend() async {
    await _syncWithBackend();
  }
}
