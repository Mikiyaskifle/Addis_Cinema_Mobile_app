import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings.dart';
import '../services/tmdb_service.dart';
import 'movie_detail_screen.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});
  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  int _tabIndex = 0;
  int _currentIndex = 0;
  String? _selectedGenre;
  late PageController _pageController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  List<TmdbMovie> _nowPlaying = [];
  List<TmdbMovie> _upcoming = [];
  List<TmdbMovie> _popular = [];
  List<TmdbMovie> _topRated = [];
  List<TmdbMovie> _trending = [];
  List<TmdbMovie> _searchResults = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  
  // Pagination
  int _nowPlayingPage = 1;
  int _upcomingPage = 1;
  int _popularPage = 1;
  int _topRatedPage = 1;
  int _trendingPage = 1;
  bool _hasMoreNowPlaying = true;
  bool _hasMoreUpcoming = true;
  bool _hasMorePopular = true;
  bool _hasMoreTopRated = true;
  bool _hasMoreTrending = true;

  List<TmdbMovie> get _allMovies {
    if (_isSearching) return _searchResults;
    switch (_tabIndex) {
      case 0: return _nowPlaying;
      case 1: return _upcoming;
      case 2: return _popular;
      case 3: return _topRated;
      case 4: return _trending;
      default: return _nowPlaying;
    }
  }

  List<TmdbMovie> get _movies {
    if (_selectedGenre == null) return _allMovies;
    return _allMovies.where((m) {
      final names = m.genreIds.map((id) => tmdbGenreMap[id] ?? '').toList();
      return names.contains(_selectedGenre);
    }).toList();
  }

  List<String> get _allGenres {
    final genres = <String>{};
    for (final m in _allMovies) {
      for (final id in m.genreIds) {
        final name = tmdbGenreMap[id];
        if (name != null) genres.add(name);
      }
    }
    return genres.toList()..sort();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.72);
    _loadMovies();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMovies() async {
    setState(() { _loading = true; _error = null; });
    try {
      final now = await TmdbService.getNowPlaying();
      final up = await TmdbService.getUpcoming();
      final pop = await TmdbService.getPopular();
      final top = await TmdbService.getTopRated();
      final trend = await TmdbService.getTrending();
      setState(() { 
        _nowPlaying = now; 
        _upcoming = up; 
        _popular = pop;
        _topRated = top;
        _trending = trend;
        _loading = false; 
      });
    } catch (e) {
      setState(() { _error = 'Failed to load movies'; _loading = false; });
    }
  }

  Future<void> _loadMoreMovies() async {
    if (_loadingMore || _isSearching) return;
    
    setState(() => _loadingMore = true);
    try {
      switch (_tabIndex) {
        case 0: // Now Playing
          if (_hasMoreNowPlaying) {
            final nextPage = _nowPlayingPage + 1;
            final more = await TmdbService.getNowPlaying(page: nextPage);
            if (more.isEmpty) {
              _hasMoreNowPlaying = false;
            } else {
              setState(() {
                _nowPlaying.addAll(more);
                _nowPlayingPage = nextPage;
              });
            }
          }
          break;
        case 1: // Upcoming
          if (_hasMoreUpcoming) {
            final nextPage = _upcomingPage + 1;
            final more = await TmdbService.getUpcoming(page: nextPage);
            if (more.isEmpty) {
              _hasMoreUpcoming = false;
            } else {
              setState(() {
                _upcoming.addAll(more);
                _upcomingPage = nextPage;
              });
            }
          }
          break;
        case 2: // Popular
          if (_hasMorePopular) {
            final nextPage = _popularPage + 1;
            final more = await TmdbService.getPopular(page: nextPage);
            if (more.isEmpty) {
              _hasMorePopular = false;
            } else {
              setState(() {
                _popular.addAll(more);
                _popularPage = nextPage;
              });
            }
          }
          break;
        case 3: // Top Rated
          if (_hasMoreTopRated) {
            final nextPage = _topRatedPage + 1;
            final more = await TmdbService.getTopRated(page: nextPage);
            if (more.isEmpty) {
              _hasMoreTopRated = false;
            } else {
              setState(() {
                _topRated.addAll(more);
                _topRatedPage = nextPage;
              });
            }
          }
          break;
        case 4: // Trending
          if (_hasMoreTrending) {
            final nextPage = _trendingPage + 1;
            final more = await TmdbService.getTrending(page: nextPage);
            if (more.isEmpty) {
              _hasMoreTrending = false;
            } else {
              setState(() {
                _trending.addAll(more);
                _trendingPage = nextPage;
              });
            }
          }
          break;
      }
    } catch (e) {
      // Silently fail for pagination
    }
    setState(() => _loadingMore = false);
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchQuery = '';
        _searchResults.clear();
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
      _searchQuery = query;
      _loading = true;
    });
    
    try {
      final results = await TmdbService.searchMovies(query);
      setState(() {
        _searchResults = results;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to search movies';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    final movie = _movies.isNotEmpty ? _movies[_currentIndex.clamp(0, _movies.length - 1)] : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF1A0A0A), const Color(0xFF0D0D0D)],
          stops: const [0.0, 0.55],
        ),
      ),
      child: SafeArea(
        child: Column(children: [
          const SizedBox(height: 8),
          _buildSearchBar(s),
          const SizedBox(height: 8),
          _buildTabBar(s),
          const SizedBox(height: 8),
          if (!_isSearching) _buildDateHeader(s),
          const SizedBox(height: 8),
          if (movie != null && !_isSearching) _buildMovieTitle(movie),
          const SizedBox(height: 8),
          if (!_loading && _error == null && !_isSearching) _buildGenreFilter(),
          const SizedBox(height: 8),
          Expanded(child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5383B)))
              : _error != null
                  ? _buildError()
                  : _movies.isEmpty
                      ? _buildEmpty()
                      : _buildMovieGrid()),
        ]),
      ),
    );
  }

  Widget _buildSearchBar(AppSettings s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.search, color: Colors.white54, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          _performSearch(value);
                        } else {
                          setState(() {
                            _isSearching = false;
                            _searchQuery = '';
                            _searchResults.clear();
                          });
                        }
                      },
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search movies...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _isSearching = false;
                          _searchQuery = '';
                          _searchResults.clear();
                        });
                      },
                      icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                      padding: const EdgeInsets.only(right: 8),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppSettings s) {
    final tabLabels = ['Now Playing', 'Upcoming', 'Popular', 'Top Rated', 'Trending'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(tabLabels.length, (index) {
          return _tabBtn(tabLabels[index], index, s);
        }),
      ),
    );
  }

  Widget _tabBtn(String label, int index, AppSettings s) {
    final sel = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() { 
        _tabIndex = index; 
        _selectedGenre = null; 
        _isSearching = false;
        _searchController.clear();
        _searchResults.clear();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFE5383B) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? const Color(0xFFE5383B) : Colors.white24),
        ),
        child: Text(label, 
          style: TextStyle(
            color: sel ? Colors.white : Colors.white70, 
            fontWeight: sel ? FontWeight.bold : FontWeight.normal,
            fontSize: 13
          )),
      ),
    );
  }

  Widget _buildDateHeader(AppSettings s) {
    return Column(children: [
      Text(s.t('Today'), style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
      const Text('Jun 5th, 2025', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Container(width: 30, height: 2, color: Colors.white.withOpacity(0.4)),
    ]);
  }

  Widget _buildMovieTitle(TmdbMovie movie) {
    return Text(movie.title,
      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1),
      textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis);
  }

  Widget _buildGenreFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        _genreChip('All', null),
        ..._allGenres.map((g) => _genreChip(g, g)),
      ]),
    );
  }

  Widget _genreChip(String label, String? genre) {
    final sel = _selectedGenre == genre;
    return GestureDetector(
      onTap: () => setState(() { _selectedGenre = genre; }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFE5383B) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? const Color(0xFFE5383B) : Colors.white24),
        ),
        child: Text(label, style: TextStyle(color: sel ? Colors.white : Colors.white70, fontSize: 12, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _buildError() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, color: Colors.white24, size: 60),
      const SizedBox(height: 12),
      Text(_error!, style: const TextStyle(color: Colors.white38)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: _loadMovies,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5383B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        child: const Text('Retry', style: TextStyle(color: Colors.white))),
    ]));
  }

  Widget _buildEmpty() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(
        _isSearching ? Icons.search_off : Icons.movie_filter_outlined, 
        color: Colors.white24, 
        size: 60
      ),
      const SizedBox(height: 12),
      Text(
        _isSearching 
          ? 'No results for "$_searchQuery"' 
          : 'No movies in "$_selectedGenre"', 
        style: const TextStyle(color: Colors.white38)
      ),
    ]));
  }

  Widget _buildMovieGrid() {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification && 
            notification.metrics.extentAfter < 500 && 
            !_loadingMore && 
            !_isSearching) {
          _loadMoreMovies();
        }
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.6,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _movies.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _movies.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CircularProgressIndicator(color: const Color(0xFFE5383B)),
              ),
            );
          }
          
          final m = _movies[index];
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MovieDetailScreen.fromTmdb(movie: m))),
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
                      imageUrl: m.posterUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: const Color(0xFF1A1A1A)),
                      errorWidget: (_, __, ___) => Container(color: const Color(0xFF1A1A1A), child: const Icon(Icons.movie, color: Colors.white30, size: 40)),
                    ),
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
                            Text(m.title,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.star, color: Color(0xFFFFC107), size: 11),
                              const SizedBox(width: 3),
                              Text(m.voteAverage.toStringAsFixed(1),
                                style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              const Spacer(),
                              Text(m.releaseDate.isNotEmpty ? m.releaseDate.substring(0, 4) : '',
                                style: const TextStyle(color: Colors.white38, fontSize: 10)),
                            ]),
                          ],
                        ),
                      ),
                    ),
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
                          Text(m.voteAverage.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
