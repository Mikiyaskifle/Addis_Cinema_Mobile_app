class CastMember {
  final String name;
  final String imageUrl;
  const CastMember({required this.name, required this.imageUrl});
}

class Movie {
  final String id;
  final String title;
  final String subtitle;
  final String posterUrl;
  final String youtubeTrailerId;
  final List<String> genres;
  final double imdb;
  final int rottenTomatoes;
  final double ign;
  final String duration;
  final double rating;
  final String description;
  final String directors;
  final String writers;
  final List<CastMember> cast;
  final int bgColor;

  const Movie({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.posterUrl,
    required this.youtubeTrailerId,
    required this.genres,
    required this.imdb,
    required this.rottenTomatoes,
    required this.ign,
    required this.duration,
    required this.rating,
    required this.description,
    required this.directors,
    required this.writers,
    required this.cast,
    required this.bgColor,
  });
}
