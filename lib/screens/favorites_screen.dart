import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/favorites_store.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import 'movie_detail_screen.dart';
import 'login_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Movie> _allMovies = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Load movies from all TMDB categories
      final nowPlaying = await TmdbService.getNowPlaying();
      final upcoming = await TmdbService.getUpcoming();
      final popular = await TmdbService.getPopular();
      final topRated = await TmdbService.getTopRated();
      final trending = await TmdbService.getTrending();
      
      // Combine all movies and remove duplicates by ID
      final allTmdbMovies = [...nowPlaying, ...upcoming, ...popular, ...topRated, ...trending];
      final uniqueMovies = <TmdbMovie>[];
      final seenIds = <int>{};
      
      for (final movie in allTmdbMovies) {
        if (!seenIds.contains(movie.id)) {
          seenIds.add(movie.id);
          uniqueMovies.add(movie);
        }
      }
      
      // Convert TmdbMovie to Movie for compatibility
      final allMovies = uniqueMovies.map((tmdbMovie) => Movie(
        id: tmdbMovie.id.toString(), // Convert int ID to string
        title: tmdbMovie.title,
        subtitle: '',
        posterUrl: tmdbMovie.posterUrl,
        youtubeTrailerId: '',
        genres: tmdbMovie.genreIds.map((id) => tmdbGenreMap[id] ?? '').where((g) => g.isNotEmpty).toList(),
        imdb: tmdbMovie.voteAverage,
        rottenTomatoes: (tmdbMovie.voteAverage * 10).toInt(),
        ign: tmdbMovie.voteAverage,
        duration: '2h 0m', // Default duration
        rating: tmdbMovie.voteAverage,
        description: tmdbMovie.overview,
        directors: '',
        writers: '',
        cast: const [],
        bgColor: 0xFF1A1A1A,
      )).toList();
      
      setState(() { 
        _allMovies = allMovies;
        _loading = false;
      });
    } catch (e) {
      setState(() { 
        _error = 'Failed to load movies';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FavoritesStore.instance,
      builder: (context, _) {
        if (_loading) {
          return Scaffold(
            backgroundColor: const Color(0xFF0D0D0D),
            body: const Center(child: CircularProgressIndicator(color: Color(0xFFE5383B))),
          );
        }
        
        if (_error != null) {
          return Scaffold(
            backgroundColor: const Color(0xFF0D0D0D),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.white38)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadMovies,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5383B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                    ),
                    child: const Text('Retry', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        }
        
        print('Favorites screen - Total movies: ${_allMovies.length}');
        final favs = FavoritesStore.instance.getFavorites(_allMovies);
        print('Favorites screen - Found ${favs.length} favorites');
        return Scaffold(
          backgroundColor: const Color(0xFF0D0D0D),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Row(
                    children: [
                      const Text('Favorites',
                        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      // Sync button for logged in users
                      if (FavoritesStore.instance.userId != null)
                        IconButton(
                          onPressed: () async {
                            // Manual sync with backend
                            await FavoritesStore.instance.syncWithBackend();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Favorites synced with server'),
                                backgroundColor: const Color(0xFF1C1C1E),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.sync, color: Colors.white70, size: 22),
                          tooltip: 'Sync with server',
                        ),
                      if (favs.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5383B),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${favs.length}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                    ],
                  ),
                ),
                if (favs.isEmpty)
                  Expanded(child: _buildEmpty())
                else
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.62,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: favs.length,
                      itemBuilder: (_, i) => _FavCard(movie: favs[i]),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    final isLoggedIn = FavoritesStore.instance.userId != null;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLoggedIn ? Icons.bookmark_border_rounded : Icons.login,
              color: Colors.white24, 
              size: 50
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isLoggedIn ? 'No favorites yet' : 'Login to save favorites',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 8),
          Text(
            isLoggedIn 
              ? 'Tap the bookmark on any movie\nto save it here'
              : 'Favorites are saved to your account\nand sync across devices',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          if (!isLoggedIn) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to login screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE5383B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Login',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FavCard extends StatelessWidget {
  final Movie movie;
  const _FavCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => MovieDetailScreen.fromTmdb(movie: TmdbMovie(
          id: int.tryParse(movie.id) ?? 0, 
          title: movie.title, 
          overview: movie.description, 
          posterPath: null, 
          backdropPath: null, 
          voteAverage: movie.rating, 
          releaseDate: '', 
          genreIds: movie.genres.map((g) {
            // Try to find genre ID from name (reverse lookup)
            for (final entry in tmdbGenreMap.entries) {
              if (entry.value == g) return entry.key;
            }
            return 0;
          }).where((id) => id != 0).toList(),
        )))),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: movie.posterUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  color: const Color(0xFF1A1A1A),
                  child: const Icon(Icons.movie, color: Colors.white30, size: 40)),
              ),
              // Gradient overlay
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.95), Colors.transparent],
                      stops: const [0.0, 0.7],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(movie.title,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.star, color: Color(0xFFFFC107), size: 11),
                        const SizedBox(width: 3),
                        Text(movie.rating.toString(),
                          style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        const Spacer(),
                        Text(movie.duration,
                          style: const TextStyle(color: Colors.white38, fontSize: 10)),
                      ]),
                    ],
                  ),
                ),
              ),
              // Remove bookmark button
              Positioned(
                top: 8, right: 8,
                child: GestureDetector(
                  onTap: () async {
                    final isLoggedIn = FavoritesStore.instance.userId != null;
                    await FavoritesStore.instance.toggle(movie.id);
                    
                    if (context.mounted) {
                      if (isLoggedIn) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Removed from favorites'),
                            backgroundColor: Color(0xFF1C1C1E),
                            duration: Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Removed from favorites (local)'),
                            backgroundColor: Color(0xFF1C1C1E),
                            duration: Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    width: 32, height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE5383B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bookmark, color: Colors.white, size: 16),
                  ),
                ),
              ),
              // Rating badge
              Positioned(
                top: 8, left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.star, color: Color(0xFFFFC107), size: 10),
                    const SizedBox(width: 3),
                    Text(movie.rating.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
