import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/favorites_store.dart';
import '../data/movies_data.dart';
import '../models/movie.dart';
import 'movie_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FavoritesStore.instance,
      builder: (context, _) {
        final all = [...nowShowingMovies, ...comingSoonMovies];
        final favs = FavoritesStore.instance.getFavorites(all);
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
            child: const Icon(Icons.bookmark_border_rounded, color: Colors.white24, size: 50),
          ),
          const SizedBox(height: 20),
          const Text('No favorites yet',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Tap the bookmark on any movie\nto save it here',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
            textAlign: TextAlign.center),
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
        MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie))),
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
                  onTap: () => FavoritesStore.instance.toggle(movie.id),
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
