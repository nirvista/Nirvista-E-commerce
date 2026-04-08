class ProductModel {
  final String id;
  final String title;
  final String? description;
  final String categoryId;
  final String brandId;
  final String? material;
  final double rating;
  final List<VariantModel> variants;

  ProductModel({
    required this.id,
    required this.title,
    this.description,
    required this.categoryId,
    required this.brandId,
    this.material,
    required this.rating,
    this.variants = const [],
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      categoryId: json['categoryId'] ?? '',
      brandId: json['brandId'] ?? '',
      material: json['material'],
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : 0.0,
      variants: json['variants'] != null
          ? (json['variants'] as List).map((i) => VariantModel.fromJson(i)).toList()
          : [],
    );
  }

  // Helpers for UI
  double get currentPrice {
    if (variants.isEmpty) return 0.0;
    var v = variants.first;
    return v.discountPrice != null && v.discountPrice! > 0 ? v.discountPrice! : v.price;
  }

  double get originalPrice {
    if (variants.isEmpty) return 0.0;
    return variants.first.price;
  }

  String get imageUrl {
    if (variants.isNotEmpty && variants.first.images.isNotEmpty) {
      return variants.first.images.first;
    }
    return '';
  }
}

class VariantModel {
  final String id;
  final String? variantName;
  final double price;
  final double? discountPrice;
  final List<String> images;
  final String? color;
  final String? size;
  final String status;
  final int stock;

  VariantModel({
    required this.id,
    this.variantName,
    required this.price,
    this.discountPrice,
    this.images = const [],
    this.color,
    this.size,
    this.status = 'in-stock',
    this.stock = 0,
  });

  factory VariantModel.fromJson(Map<String, dynamic> json) {
    return VariantModel(
      id: json['id'] ?? '',
      variantName: json['variantName'],
      price: json['price'] != null ? (json['price'] as num).toDouble() : 0.0,
      discountPrice: json['discountPrice'] != null ? (json['discountPrice'] as num).toDouble() : null,
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      color: json['color'],
      size: json['size'],
      status: json['status'] ?? 'in-stock',
      stock: json['stock'] ?? 0,
    );
  }
}

class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? parentId;
  final List<CategoryModel> children;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.parentId,
    this.children = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      parentId: json['parentId'],
      children: json['children'] != null
          ? (json['children'] as List).map((i) => CategoryModel.fromJson(i)).toList()
          : [],
    );
  }
}

class BrandModel {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;

  BrandModel({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      logoUrl: json['logoUrl'],
    );
  }
}
