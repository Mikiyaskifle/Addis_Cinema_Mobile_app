class ConcessionItem {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final String category;
  int quantity;

  ConcessionItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.category,
    this.quantity = 0,
  });
}
