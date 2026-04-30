import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/tmdb_service.dart';
import '../data/favorites_store.dart';
import 'select_seats_screen_tmdb.dart';
import 'login_screen.dart';

class MovieDetailScreen extends StatefulWidget {
  final TmdbMovie? tmdbMovie;
  final int? movieId;

  const MovieDetailScreen._({this.tmdbMovie, this.movieId});

  factory MovieDetailScreen.fromTmdb({required TmdbMovie movie}) =>
      MovieDetailScreen._(tmdbMovie: movie, movieId: movie.id);

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  TmdbMovieDetail? _detail;
  bool _loading = true;
  bool _trailerPlaying = false;
  YoutubePlayerController? _ytController;
  final _favs = FavoritesStore.instance;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _ytController?.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    final id = widget.movieId ?? widget.tmdbMovie?.id;
    if (id == null) return;
    try {
      final detail = await TmdbService.getMovieDetail(id);
      setState(() { _detail = detail; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _playTrailer() {
    final key = _detail?.trailerKey;
    if (key == null) return;
    _ytController = YoutubePlayerController(
      initialVideoId: key,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false, enableCaption: false, useHybridComposition: true),
    );
    setState(() => _trailerPlaying = true);
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.tmdbMovie;
    return ListenableBuilder(
      listenable: _favs,
      builder: (context, _) {
        final movieId = widget.movieId?.toString() ?? movie?.id.toString() ?? '';
        print('Movie detail screen - movieId: $movieId');
        print('widget.movieId: ${widget.movieId}');
        print('movie?.id: ${movie?.id}');
        final isFav = _favs.isFavorite(movieId);
        return Scaffold(
          backgroundColor: const Color(0xFF0D0D0D),
          body: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5383B)))
              : Stack(children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 100), // Add padding for fixed button
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Trailer / Backdrop
                      SizedBox(
                        height: 260,
                        child: Stack(
                          fit: StackFit.expand,
                          clipBehavior: Clip.hardEdge, // Prevent overflow
                          children: [
                        if (_trailerPlaying && _ytController != null)
                          YoutubePlayerBuilder(
                            player: YoutubePlayer(controller: _ytController!, showVideoProgressIndicator: true, progressIndicatorColor: const Color(0xFFE5383B)),
                            builder: (_, player) => player,
                          )
                        else
                          GestureDetector(
                            onTap: _detail?.trailerKey != null ? _playTrailer : null,
                            child: Stack(fit: StackFit.expand, children: [
                              CachedNetworkImage(
                                imageUrl: _detail?.backdropUrl ?? movie?.backdropUrl ?? '',
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => CachedNetworkImage(imageUrl: movie?.posterUrl ?? '', fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(color: Colors.black)),
                              ),
                              Container(color: Colors.black.withOpacity(0.4)),
                              if (_detail?.trailerKey != null) Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                const Text('NEW TRAILER', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 3)),
                                const SizedBox(height: 14),
                                Container(width: 64, height: 64,
                                  decoration: BoxDecoration(color: const Color(0xFFE5383B), shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: const Color(0xFFE5383B).withOpacity(0.6), blurRadius: 20)]),
                                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 38)),
                                const SizedBox(height: 8),
                                const Text('Tap to play trailer', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ])),
                            ]),
                          ),
                        // Back & bookmark
                        Positioned(top: 0, left: 0, right: 0,
                          child: SafeArea(child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              _circleBtn(Icons.arrow_back, () { _ytController?.pause(); Navigator.pop(context); }),
                              GestureDetector(
                                onTap: () async {
                                  final isLoggedIn = _favs.userId != null;
                                  
                                  // Always toggle favorite (locally for guests, locally+backend for logged in)
                                  await _favs.toggle(movieId);
                                  
                                  // Use post-frame callback to show snackbar after rebuild
                                  SchedulerBinding.instance.addPostFrameCallback((_) {
                                    if (context.mounted) {
                                      final isNowFavorite = _favs.isFavorite(movieId);
                                      
                                      if (isLoggedIn) {
                                        // User is logged in
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                          content: Text(isNowFavorite ? 'Added to favorites' : 'Removed from favorites'),
                                          backgroundColor: const Color(0xFFE5383B), 
                                          duration: const Duration(seconds: 3), 
                                          behavior: SnackBarBehavior.floating,
                                          margin: const EdgeInsets.all(20),
                                        ));
                                      } else {
                                        // User is guest
                                        if (isNowFavorite) {
                                          // Added to local favorites
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                            content: const Text('Added to favorites (local)'),
                                            backgroundColor: const Color(0xFFE5383B), 
                                            duration: const Duration(seconds: 4), 
                                            behavior: SnackBarBehavior.floating,
                                            margin: const EdgeInsets.all(20),
                                            action: SnackBarAction(
                                              label: 'Login to sync',
                                              textColor: Colors.white,
                                              onPressed: () {
                                                Navigator.push(context, 
                                                  MaterialPageRoute(builder: (_) => const LoginScreen(returnToPrevious: true)));
                                              },
                                            ),
                                          ));
                                        } else {
                                          // Removed from local favorites
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                            content: const Text('Removed from favorites'),
                                            backgroundColor: const Color(0xFFE5383B), 
                                            duration: const Duration(seconds: 3), 
                                            behavior: SnackBarBehavior.floating,
                                            margin: const EdgeInsets.all(20),
                                          ));
                                        }
                                      }
                                    }
                                  });
                                },
                                child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                                  width: 38, height: 38,
                                  decoration: BoxDecoration(color: isFav ? const Color(0xFFE5383B) : Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                                  child: Icon(isFav ? Icons.bookmark : Icons.bookmark_border, color: Colors.white, size: 20)),
                              ),
                            ]),
                          ))),
                      ])),
                      Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        // Title + rating
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_detail?.title ?? movie?.title ?? '', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                            if ((_detail?.tagline ?? '').isNotEmpty)
                              Text(_detail!.tagline, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, fontStyle: FontStyle.italic)),
                          ])),
                          Row(children: [
                            const Icon(Icons.star, color: Color(0xFFFFC107), size: 18),
                            const SizedBox(width: 4),
                            Text((_detail?.voteAverage ?? movie?.voteAverage ?? 0).toStringAsFixed(1),
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ]),
                        ]),
                        const SizedBox(height: 8),
                        // Meta info
                        Row(children: [
                          if ((_detail?.durationFormatted ?? '').isNotEmpty) ...[
                            const Icon(Icons.access_time, color: Colors.white38, size: 14),
                            const SizedBox(width: 4),
                            Text(_detail!.durationFormatted, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                            const SizedBox(width: 16),
                          ],
                          if ((_detail?.releaseDate ?? movie?.releaseDate ?? '').isNotEmpty) ...[
                            const Icon(Icons.calendar_today_outlined, color: Colors.white38, size: 14),
                            const SizedBox(width: 4),
                            Text((_detail?.releaseDate ?? movie?.releaseDate ?? '').substring(0, 4),
                              style: const TextStyle(color: Colors.white38, fontSize: 12)),
                          ],
                        ]),
                        const SizedBox(height: 12),
                        // Genres
                        Wrap(spacing: 8, children: (_detail?.genres.map((g) => g.name).toList() ??
                            (movie?.genreIds.map((id) => tmdbGenreMap[id] ?? '').where((s) => s.isNotEmpty).toList() ?? []))
                            .map((g) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(20)),
                              child: Text(g, style: const TextStyle(color: Colors.white70, fontSize: 12)))).toList()),
                        const SizedBox(height: 20),
                        // Scores
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(border: Border(
                            top: BorderSide(color: Colors.white.withOpacity(0.1)),
                            bottom: BorderSide(color: Colors.white.withOpacity(0.1)))),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                            _scoreItem('${(_detail?.voteAverage ?? 0).toStringAsFixed(1)} / 10', 'TMDB'),
                            Container(width: 1, height: 30, color: Colors.white12),
                            _scoreItem('${_detail?.voteCount ?? 0}', 'Votes'),
                            Container(width: 1, height: 30, color: Colors.white12),
                            _scoreItem(_detail?.status ?? 'Released', 'Status'),
                          ]),
                        ),
                        const SizedBox(height: 20),
                        // Cast
                        if ((_detail?.cast ?? []).isNotEmpty) ...[
                          const Text('Cast', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 120, // Increased height to accommodate text
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _detail!.cast.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (_, i) {
                                final c = _detail!.cast[i];
                                return SizedBox(
                                  width: 64, // Fixed width for each cast item
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                          imageUrl: c.profileUrl,
                                          width: 56,
                                          height: 56,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) => Container(
                                            width: 56,
                                            height: 56,
                                            color: const Color(0xFF2A2A2A),
                                            child: const Icon(Icons.person, color: Colors.white30),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        c.name,
                                        style: const TextStyle(color: Colors.white60, fontSize: 10),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        c.character,
                                        style: const TextStyle(color: Colors.white30, fontSize: 9),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        // Directors
                        if ((_detail?.directors ?? '').isNotEmpty) ...[
                          const Text('Directors', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(_detail!.directors, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                          const SizedBox(height: 16),
                        ],
                        // Writers
                        if ((_detail?.writers ?? '').isNotEmpty) ...[
                          const Text('Writers', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(_detail!.writers, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                          const SizedBox(height: 16),
                        ],
                        // Storyline
                        const Text('Storyline', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_detail?.overview ?? movie?.overview ?? '', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.6)),
                        // Similar movies
                        if ((_detail?.similar ?? []).isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Text('More like this', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 160,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _detail!.similar.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 10),
                              itemBuilder: (_, i) {
                                final s = _detail!.similar[i];
                                return SizedBox(
                                  width: 110,
                                  child: GestureDetector(
                                    onTap: () => Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (_) => MovieDetailScreen.fromTmdb(movie: s)),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: CachedNetworkImage(
                                        imageUrl: s.posterUrl,
                                        width: 110,
                                        height: 160,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => Container(
                                          width: 110,
                                          height: 160,
                                          color: const Color(0xFF2A2A2A),
                                          child: const Icon(Icons.movie, color: Colors.white30),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 40), // Reduced from 100 to account for padding
                      ])),
                    ]),
                  ),
                  // Buy Tickets
                  Positioned(bottom: 0, left: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      decoration: BoxDecoration(gradient: LinearGradient(
                        begin: Alignment.bottomCenter, end: Alignment.topCenter,
                        colors: [const Color(0xFF0D0D0D), Colors.transparent])),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (_detail != null) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => SelectSeatsScreenTmdb(detail: _detail!)));
                          }
                        },
                        icon: const Icon(Icons.credit_card, size: 18),
                        label: const Text('Buy Tickets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5383B), foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                      ),
                    )),
                ]),
        );
      },
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(onTap: onTap,
      child: Container(width: 38, height: 38,
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 20)));
  }

  Widget _scoreItem(String value, String label) {
    return Column(children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
    ]);
  }
}
