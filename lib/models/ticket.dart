class Ticket {
  final String id;
  final String movieTitle;
  final String moviePosterUrl;
  final String date;
  final String time;
  final String screenType;
  final List<String> seats;
  final double totalPrice;

  const Ticket({
    required this.id,
    required this.movieTitle,
    required this.moviePosterUrl,
    required this.date,
    required this.time,
    required this.screenType,
    required this.seats,
    required this.totalPrice,
  });
}
