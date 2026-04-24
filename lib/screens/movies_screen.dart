import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings.dart';
import '../data/movies_data.dart';
import '../models/movie.dart';
import 'movie_detail_screen.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});
  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  int _tabIndex = 0;
  int _currentMovieIndex = 0;
  String? _selectedGenre;
  late PageController _pageController;

  List<Movie> get _allMovies => _tabIndex == 0 ? nowShowingMovies : comingSoonMovies;

  List<Movie> get _movies {
    if (_selectedGenre == null) return _allMovies;
    return _allMovies.where((m) => m.genres.contains(_selectedGenre)).toList();
  }

  List<String> get _allGenres {
    final genres = <String>{};
    for (final m in _allMovies) genres.addAll(m.genres);
    return genres.toList();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.72, initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final movie = _movies.isNotEmpty ? _movies[_currentMovieIndex] : _allMovies[0];
    final bgColor = Color(movie.bgColor);
    final s = context.watch<AppSettings>();
    final isDark = s.isDark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgColor, const Color(0xFF0D0D0D)],
          stops: const [0.0, 0.55],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildTabBar(),
            const SizedBox(height: 16),
            _buildDateHeader(),
            const SizedBox(height: 8),
            _buildMovieTitle(movie),
            const SizedBox(height: 12),
            _buildGenreFilter(),
            const SizedBox(height: 8),
            Expanded(child: _movies.isEmpty ? _buildEmpty() : _buildCarousel()),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(children: [_tabButton(context.read<AppSettings>().t('Now Showing'), 0), _tabButton(context.read<AppSettings>().t('Coming Soon'), 1)]),
    );
  }

  Widget _tabButton(String label, int index) {
    final selected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _tabIndex = index;
          _currentMovieIndex = 0;
          _selectedGenre = null;
          _pageController.jumpToPage(0);
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.black : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            )),
        ),
      ),
    );
  }

  Widget _buildDateHeader() {
    return Column(children: [
      Text('Today', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),      const Text('Jun 5th, 2023', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Container(width: 30, height: 2, color: Colors.white.withOpacity(0.4)),
    ]);
  }

  Widget _buildMovieTitle(Movie movie) {
    return Text(movie.title,
      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildGenreFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _genreChip('All', null),
          ..._allGenres.map((g) => _genreChip(g, g)),
        ],
      ),
    );
  }

  Widget _genreChip(String label, String? genre) {
    final selected = _selectedGenre == genre;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedGenre = genre;
        _currentMovieIndex = 0;
        if (_movies.isNotEmpty) _pageController.jumpToPage(0);
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE5383B) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? const Color(0xFFE5383B) : Colors.white24),
        ),
        child: Text(label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          )),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.movie_filter_outlined, color: Colors.white24, size: 60),
          const SizedBox(height: 12),
          Text('No movies in "$_selectedGenre"',
            style: const TextStyle(color: Colors.white38, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildCarousel() {
    return PageView.builder(
      controller: _pageController,
      itemCount: _movies.length,
      onPageChanged: (i) => setState(() => _currentMovieIndex = i),
      itemBuilder: (context, index) {
        final m = _movies[index];
        final isActive = index == _currentMovieIndex;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: m))),
          child: AnimatedScale(
            scale: isActive ? 1.0 : 0.88,
            duration: const Duration(milliseconds: 300),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))] : [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(fit: StackFit.expand, children: [
                  CachedNetworkImage(
                    imageUrl: m.posterUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: const Color(0xFF1A1A1A)),
                    errorWidget: (_, __, ___) => Container(
                      color: const Color(0xFF1A1A1A),
                      child: const Icon(Icons.movie, color: Colors.white30, size: 60),
                    ),
                  ),
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                        ),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Row(children: [
                            const Icon(Icons.access_time, color: Colors.white70, size: 13),
                            const SizedBox(width: 4),
                            Text(m.duration, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ]),
                          Row(children: [
                            const Icon(Icons.star, color: Color(0xFFFFC107), size: 13),
                            const SizedBox(width: 4),
                            Text(m.rating.toString(), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ]),
                        ]),
                        const SizedBox(height: 6),
                        Text(m.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        const SizedBox(height: 6),
                        Wrap(spacing: 6, children: m.genres.map((g) => GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedGenre = g;
                              _currentMovieIndex = 0;
                            });
                            _pageController.jumpToPage(0);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: _selectedGenre == g ? const Color(0xFFE5383B).withOpacity(0.4) : Colors.transparent,
                              border: Border.all(color: _selectedGenre == g ? const Color(0xFFE5383B) : Colors.white30),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(g, style: TextStyle(
                              color: _selectedGenre == g ? Colors.white : Colors.white70,
                              fontSize: 11,
                            )),
                          ),
                        )).toList()),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }
}
