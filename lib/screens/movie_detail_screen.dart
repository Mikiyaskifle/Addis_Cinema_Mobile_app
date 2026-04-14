import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie.dart';
import 'select_seats_screen.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;
  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  late YoutubePlayerController _ytController;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _ytController = YoutubePlayerController(
      initialVideoId: widget.movie.youtubeTrailerId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: false,
      ),
    );
  }

  @override
  void dispose() {
    _ytController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.movie;
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _ytController,
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xFFE5383B),
      ),
      builder: (context, player) {
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
                        children: [
                          SizedBox(width: double.infinity, height: 240, child: player),
                          Positioned(
                            top: 0, left: 0, right: 0,
                            child: SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _circleBtn(Icons.arrow_back, () => Navigator.pop(context)),
                                    _circleBtn(
                                      _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                      () => setState(() => _isBookmarked = !_isBookmarked),
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                    if (m.subtitle.isNotEmpty)
                                      Text(m.subtitle, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
                                  ],
                                ),
                              ),
                              Row(children: [
                                const Icon(Icons.star, color: Color(0xFFFFC107), size: 18),
                                const SizedBox(width: 4),
                                Text(m.rating.toString(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              ]),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: m.genres.map((g) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(20)),
                              child: Text(g, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            )).toList(),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.white.withOpacity(0.1)),
                                bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                              ),
                            ),
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
                                      imageUrl: c.imageUrl,
                                      width: 56, height: 56, fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Container(
                                        width: 56, height: 56,
                                        color: const Color(0xFF2A2A2A),
                                        child: const Icon(Icons.person, color: Colors.white30),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 60,
                                    child: Text(c.name,
                                      style: const TextStyle(color: Colors.white60, fontSize: 10),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ]);
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text('Description', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(m.description, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.6)),
                          const SizedBox(height: 16),
                          const Text('Directors', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(m.directors, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                          const SizedBox(height: 16),
                          const Text('Writers', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(m.writers, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
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
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
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
