import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie.dart';
import '../data/movies_data.dart';
import '../data/favorites_store.dart';
import 'select_seats_screen.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;
  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final _favs = FavoritesStore.instance;
  YoutubePlayerController? _ytController;
  bool _trailerTapped = false;
  bool _playerReady = false;

  List<Movie> get _moreLikeThis {
    final all = [...nowShowingMovies, ...comingSoonMovies];
    return all.where((m) => m.id != widget.movie.id).take(3).toList();
  }

  void _initPlayer() {
    _ytController = YoutubePlayerController(
      initialVideoId: widget.movie.youtubeTrailerId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
        forceHD: false,
        useHybridComposition: true,
      ),
    );
    setState(() => _trailerTapped = true);
  }

  @override
  void dispose() {
    _ytController?.dispose();
    super.dispose();
  }

  Widget _buildTrailerSection(Movie m) {
    if (!_trailerTapped || _ytController == null) {
      // Show thumbnail with play button — no WebView loaded yet
      return GestureDetector(
        onTap: _initPlayer,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: 'https://img.youtube.com/vi/${m.youtubeTrailerId}/maxresdefault.jpg',
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: Colors.black),
              errorWidget: (_, __, ___) => CachedNetworkImage(
                imageUrl: 'https://img.youtube.com/vi/${m.youtubeTrailerId}/hqdefault.jpg',
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(color: Colors.black),
              ),
            ),
            Container(color: Colors.black.withOpacity(0.3)),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('NEW TRAILER',
                    style: TextStyle(color: Colors.white, fontSize: 18,
                      fontWeight: FontWeight.w900, letterSpacing: 3)),
                  const SizedBox(height: 14),
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5383B),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(
                        color: const Color(0xFFE5383B).withOpacity(0.6),
                        blurRadius: 20, spreadRadius: 3)],
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 38),
                  ),
                  const SizedBox(height: 8),
                  const Text('Tap to play trailer',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Player initialized — wrap with YoutubePlayerBuilder
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _ytController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xFFE5383B),
        progressColors: const ProgressBarColors(
          playedColor: Color(0xFFE5383B),
          handleColor: Color(0xFFE5383B),
        ),
        onReady: () => setState(() => _playerReady = true),
      ),
      builder: (_, player) => player,
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.movie;
    return ListenableBuilder(
      listenable: _favs,
      builder: (context, _) {
        final isFav = _favs.isFavorite(m.id);
        return Scaffold(
          backgroundColor: const Color(0xFF0D0D0D),
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 240,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildTrailerSection(m),
                          // Back & bookmark always on top
                          Positioned(
                            top: 0, left: 0, right: 0,
                            child: SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _circleBtn(Icons.arrow_back, () {
                                      _ytController?.pause();
                                      Navigator.pop(context);
                                    }),
                                    GestureDetector(
                                      onTap: () {
                                        _favs.toggle(m.id);
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                          content: Text(_favs.isFavorite(m.id)
                                            ? 'Added to favorites' : 'Removed from favorites'),
                                          backgroundColor: const Color(0xFF1C1C1E),
                                          duration: const Duration(seconds: 1),
                                          behavior: SnackBarBehavior.floating,
                                        ));
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 38, height: 38,
                                        decoration: BoxDecoration(
                                          color: isFav ? const Color(0xFFE5383B) : Colors.black.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(isFav ? Icons.bookmark : Icons.bookmark_border,
                                          color: Colors.white, size: 20),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                  if (m.subtitle.isNotEmpty)
                                    Text(m.subtitle, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
                                ],
                              )),
                              Row(children: [
                                const Icon(Icons.star, color: Color(0xFFFFC107), size: 18),
                                const SizedBox(width: 4),
                                Text(m.rating.toString(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              ]),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(spacing: 8, children: m.genres.map((g) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(20)),
                            child: Text(g, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          )).toList()),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(border: Border(
                              top: BorderSide(color: Colors.white.withOpacity(0.1)),
                              bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                            )),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _scoreItem('${m.imdb} / 10', 'IMDB'),
                                Container(width: 1, height: 30, color: Colors.white12),
                                _scoreItem('${m.rottenTomatoes}%', 'Rotten Tomatoes'),
                                Container(width: 1, height: 30, color: Colors.white12),
                                _scoreItem('${m.ign} / 10', 'IGN'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 90,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: m.cast.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (_, i) {
                                final c = m.cast[i];
                                return Column(children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: c.imageUrl, width: 56, height: 56, fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Container(
                                        width: 56, height: 56, color: const Color(0xFF2A2A2A),
                                        child: const Icon(Icons.person, color: Colors.white30)),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(width: 60, child: Text(c.name,
                                    style: const TextStyle(color: Colors.white60, fontSize: 10),
                                    textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis)),
                                ]);
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text('Writers', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(m.writers, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                          const SizedBox(height: 16),
                          const Text('Directors', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(m.directors, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                          const SizedBox(height: 16),
                          const Text('Storyline', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(m.description, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.6)),
                          const SizedBox(height: 24),
                          const Text('More like this', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 160,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _moreLikeThis.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 10),
                              itemBuilder: (_, i) {
                                final related = _moreLikeThis[i];
                                return GestureDetector(
                                  onTap: () => Navigator.pushReplacement(context,
                                    MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: related))),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: related.posterUrl, width: 110, height: 160, fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Container(width: 110, height: 160,
                                        color: const Color(0xFF2A2A2A),
                                        child: const Icon(Icons.movie, color: Colors.white30)),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: [const Color(0xFF0D0D0D), Colors.transparent],
                    ),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => SelectSeatsScreen(movie: m))),
                    icon: const Icon(Icons.credit_card, size: 18),
                    label: const Text('Buy Tickets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5383B),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _scoreItem(String value, String label) {
    return Column(children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
    ]);
  }
}
