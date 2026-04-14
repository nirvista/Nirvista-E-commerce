class DummyProduct {
  final int id;
  final String name;
  final String brand;
  final String category; // "fashion", "mobiles", "beauty", "electronics", "home_decor"
  final String subCategory; // e.g. "kurta", "smartphone", "lipstick"
  final double price;
  final double originalPrice;
  final double rating;
  final int reviewCount;
  final String imageUrl; // CachedNetworkImage URL
  final List<String> colors;
  final List<String> sizes;
  final String description;
  final bool isBestSelling;
  final bool isTopDeal;

  DummyProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.subCategory,
    required this.price,
    required this.originalPrice,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.colors,
    required this.sizes,
    required this.description,
    this.isBestSelling = false,
    this.isTopDeal = false,
  });

  double get discountPercentage {
    if (originalPrice <= 0) return 0;
    double discount = ((originalPrice - price) / originalPrice * 100);
    return double.tryParse(discount.toStringAsFixed(0)) ?? 0.0;
  }
}
