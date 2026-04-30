import 'dart:convert';
import 'package:http/http.dart' as http;

class TmdbService {
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _imageBase = 'https://image.tmdb.org/t/p/w500';
  static const String _imageBaseOriginal = 'https://image.tmdb.org/t/p/original';

  // Replace with your TMDB API Read Access Token
  static const String _token = 'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJhNjVjMGQwOTNiZmY3OTdhN2U2NjcwZTcwMWNhYjEzMCIsIm5iZiI6MTc3NzQ1MzEzNS4zNTIsInN1YiI6IjY5ZjFjODRmZjI4MmI4MDJmOWQ1N2M2MiIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.ZKYEMfTjYqL0u8Ni2X64qrUKmisSrV5B9owtD69_qqE';

  static Map<String, String> get _headers => {
    'Authorization': 'Bearer $_token',
    'Content-Type': 'application/json',
  };

  static String posterUrl(String? path) =>
      path != null && path.isNotEmpty ? '$_imageBase$path' : '';

  static String backdropUrl(String? path) =>
      path != null && path.isNotEmpty ? '$_imageBaseOriginal$path' : '';

  static String profileUrl(String? path) =>
      path != null && path.isNotEmpty ? 'https://image.tmdb.org/t/p/w185$path' : '';

  // ── Now Playing (Now Showing) ─────────────────────────────────────────────
  static Future<List<TmdbMovie>> getNowPlaying({int page = 1}) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/movie/now_playing?language=en-US&page=$page'),
      headers: _headers,
    );
    final data = jsonDecode(res.body);
    return (data['results'] as List).map((m) => TmdbMovie.fromJson(m)).toList();
  }

  // ── Upcoming (Coming Soon) ────────────────────────────────────────────────
  static Future<List<TmdbMovie>> getUpcoming({int page = 1}) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/movie/upcoming?language=en-US&page=$page'),
      headers: _headers,
    );
    final data = jsonDecode(res.body);
    return (data['results'] as List).map((m) => TmdbMovie.fromJson(m)).toList();
  }

  // ── Movie Details ─────────────────────────────────────────────────────────
  static Future<TmdbMovieDetail> getMovieDetail(int movieId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/movie/$movieId?language=en-US&append_to_response=credits,videos,similar'),
      headers: _headers,
    );
    return TmdbMovieDetail.fromJson(jsonDecode(res.body));
  }

  // ── Search ────────────────────────────────────────────────────────────────
  static Future<List<TmdbMovie>> searchMovies(String query) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/search/movie?query=${Uri.encodeComponent(query)}&language=en-US'),
      headers: _headers,
    );
    final data = jsonDecode(res.body);
    return (data['results'] as List).map((m) => TmdbMovie.fromJson(m)).toList();
  }

  // ── Popular Movies ──────────────────────────────────────────────────────
  static Future<List<TmdbMovie>> getPopular({int page = 1}) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/movie/popular?language=en-US&page=$page'),
      headers: _headers,
    );
    final data = jsonDecode(res.body);
    return (data['results'] as List).map((m) => TmdbMovie.fromJson(m)).toList();
  }

  // ── Top Rated Movies ────────────────────────────────────────────────────
  static Future<List<TmdbMovie>> getTopRated({int page = 1}) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/movie/top_rated?language=en-US&page=$page'),
      headers: _headers,
    );
    final data = jsonDecode(res.body);
    return (data['results'] as List).map((m) => TmdbMovie.fromJson(m)).toList();
  }

  // ── Trending Movies (Day) ──────────────────────────────────────────────
  static Future<List<TmdbMovie>> getTrending({int page = 1}) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/trending/movie/day?language=en-US&page=$page'),
      headers: _headers,
    );
    final data = jsonDecode(res.body);
    return (data['results'] as List).map((m) => TmdbMovie.fromJson(m)).toList();
  }
}

// ── Models ────────────────────────────────────────────────────────────────────

class TmdbMovie {
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final String releaseDate;
  final List<int> genreIds;

  TmdbMovie({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    required this.releaseDate,
    required this.genreIds,
  });

  factory TmdbMovie.fromJson(Map<String, dynamic> j) => TmdbMovie(
    id: j['id'] ?? 0,
    title: j['title'] ?? '',
    overview: j['overview'] ?? '',
    posterPath: j['poster_path'],
    backdropPath: j['backdrop_path'],
    voteAverage: (j['vote_average'] ?? 0).toDouble(),
    releaseDate: j['release_date'] ?? '',
    genreIds: List<int>.from(j['genre_ids'] ?? []),
  );

  String get posterUrl => TmdbService.posterUrl(posterPath);
  String get backdropUrl => TmdbService.backdropUrl(backdropPath);
}

class TmdbMovieDetail {
  final int id;
  final String title;
  final String tagline;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final int voteCount;
  final String releaseDate;
  final int runtime;
  final List<TmdbGenre> genres;
  final List<TmdbCastMember> cast;
  final List<TmdbCrew> crew;
  final String? trailerKey; // YouTube video key
  final List<TmdbMovie> similar;
  final String status;

  TmdbMovieDetail({
    required this.id,
    required this.title,
    required this.tagline,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    required this.voteCount,
    required this.releaseDate,
    required this.runtime,
    required this.genres,
    required this.cast,
    required this.crew,
    this.trailerKey,
    required this.similar,
    required this.status,
  });

  factory TmdbMovieDetail.fromJson(Map<String, dynamic> j) {
    // Get cast
    final credits = j['credits'] as Map<String, dynamic>?;
    final castList = (credits?['cast'] as List? ?? [])
        .take(8)
        .map((c) => TmdbCastMember.fromJson(c))
        .toList();
    final crewList = (credits?['crew'] as List? ?? [])
        .map((c) => TmdbCrew.fromJson(c))
        .toList();

    // Get YouTube trailer
    final videos = j['videos'] as Map<String, dynamic>?;
    final videoResults = videos?['results'] as List? ?? [];
    final trailer = videoResults.firstWhere(
      (v) => v['type'] == 'Trailer' && v['site'] == 'YouTube',
      orElse: () => videoResults.isNotEmpty ? videoResults.first : null,
    );
    final trailerKey = trailer?['key'] as String?;

    // Similar movies
    final similarData = j['similar'] as Map<String, dynamic>?;
    final similarList = (similarData?['results'] as List? ?? [])
        .take(6)
        .map((m) => TmdbMovie.fromJson(m))
        .toList();

    return TmdbMovieDetail(
      id: j['id'] ?? 0,
      title: j['title'] ?? '',
      tagline: j['tagline'] ?? '',
      overview: j['overview'] ?? '',
      posterPath: j['poster_path'],
      backdropPath: j['backdrop_path'],
      voteAverage: (j['vote_average'] ?? 0).toDouble(),
      voteCount: j['vote_count'] ?? 0,
      releaseDate: j['release_date'] ?? '',
      runtime: j['runtime'] ?? 0,
      genres: (j['genres'] as List? ?? []).map((g) => TmdbGenre.fromJson(g)).toList(),
      cast: castList,
      crew: crewList,
      trailerKey: trailerKey,
      similar: similarList,
      status: j['status'] ?? '',
    );
  }

  String get posterUrl => TmdbService.posterUrl(posterPath);
  String get backdropUrl => TmdbService.backdropUrl(backdropPath);

  String get directors => crew
      .where((c) => c.job == 'Director')
      .map((c) => c.name)
      .join(', ');

  String get writers => crew
      .where((c) => c.job == 'Screenplay' || c.job == 'Writer' || c.job == 'Story')
      .map((c) => c.name)
      .take(3)
      .join(', ');

  String get durationFormatted {
    final h = runtime ~/ 60;
    final m = runtime % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }
}

class TmdbGenre {
  final int id;
  final String name;
  TmdbGenre({required this.id, required this.name});
  factory TmdbGenre.fromJson(Map<String, dynamic> j) =>
      TmdbGenre(id: j['id'] ?? 0, name: j['name'] ?? '');
}

class TmdbCastMember {
  final int id;
  final String name;
  final String character;
  final String? profilePath;
  TmdbCastMember({required this.id, required this.name, required this.character, this.profilePath});
  factory TmdbCastMember.fromJson(Map<String, dynamic> j) => TmdbCastMember(
    id: j['id'] ?? 0,
    name: j['name'] ?? '',
    character: j['character'] ?? '',
    profilePath: j['profile_path'],
  );
  String get profileUrl => TmdbService.profileUrl(profilePath);
}

class TmdbCrew {
  final String name;
  final String job;
  TmdbCrew({required this.name, required this.job});
  factory TmdbCrew.fromJson(Map<String, dynamic> j) =>
      TmdbCrew(name: j['name'] ?? '', job: j['job'] ?? '');
}

// Genre ID to name map
const Map<int, String> tmdbGenreMap = {
  28: 'Action', 12: 'Adventure', 16: 'Animation', 35: 'Comedy',
  80: 'Crime', 99: 'Documentary', 18: 'Drama', 10751: 'Family',
  14: 'Fantasy', 36: 'History', 27: 'Horror', 10402: 'Music',
  9648: 'Mystery', 10749: 'Romance', 878: 'Sci-Fi', 10770: 'TV Movie',
  53: 'Thriller', 10752: 'War', 37: 'Western',
};
