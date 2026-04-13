class ProductModel {
  final String id;
  final String title;
  final String? description;
  final String categoryId;
  final String brandId;
  final String brandName;
  final String? material;
  final double rating;
  final List<VariantModel> variants;

  ProductModel({
    required this.id,
    required this.title,
    this.description,
    required this.categoryId,
    required this.brandId,
    this.brandName = '',
    this.material,
    required this.rating,
    this.variants = const [],
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Try to get brand name from nested 'brand' object if available
    String parsedBrandName = '';
    if (json['brand'] != null && json['brand'] is Map) {
      parsedBrandName = json['brand']['name'] ?? '';
    }
    return ProductModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      categoryId: json['categoryId'] ?? '',
      brandId: json['brandId'] ?? '',
      brandName: parsedBrandName,
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

class CartItemModel {
  final String productId;
  final String variantId;
  final int quantity;
  final ProductModel? product;
  final VariantModel? variant;

  CartItemModel({
    required this.productId,
    required this.variantId,
    required this.quantity,
    this.product,
    this.variant,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      productId: json['productId'] ?? '',
      variantId: json['variant'] != null ? (json['variant']['id'] ?? '') : (json['variantId'] ?? ''),
      quantity: json['quantity'] ?? 0,
      product: json['product'] != null ? ProductModel.fromJson(json['product']) : null,
      variant: json['variant'] != null ? VariantModel.fromJson(json['variant']) : null,
    );
  }
}

class CartModel {
  final String cartId;
  final String userId;
  final List<CartItemModel> items;

  CartModel({
    required this.cartId,
    required this.userId,
    this.items = const [],
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      cartId: json['cartId'] ?? '',
      userId: json['userId'] ?? '',
      items: json['items'] != null
          ? (json['items'] as List).map((i) => CartItemModel.fromJson(i)).toList()
          : [],
    );
  }
}

class OrderItemModel {
  final String productId;
  final String variantId;
  final int quantity;
  final double priceAtPurchase;
  final ProductModel? product;
  final VariantModel? variant;

  OrderItemModel({
    required this.productId,
    required this.variantId,
    required this.quantity,
    required this.priceAtPurchase,
    this.product,
    this.variant,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json['productId'] ?? '',
      variantId: json['variantId'] ?? '',
      quantity: json['quantity'] ?? 0,
      priceAtPurchase: json['priceAtPurchase'] != null ? (json['priceAtPurchase'] as num).toDouble() : 0.0,
      product: json['product'] != null ? ProductModel.fromJson(json['product']) : null,
      variant: json['variant'] != null ? VariantModel.fromJson(json['variant']) : null,
    );
  }
}

class OrderModel {
  final String id;
  final String userId;
  final String addressId;
  final double totalAmount;
  String orderStatus;
  final String paymentMethod;
  final String paymentStatus;
  final String createdAt;
  final String? shippingAddress;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.userId,
    required this.addressId,
    required this.totalAmount,
    required this.orderStatus,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
    this.shippingAddress,
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    String? derivedAddr;
    if (json['address'] != null && json['address'] is Map) {
      final a = json['address'];
      derivedAddr = "${a['addressLine1'] ?? ''}${a['addressLine2'] != null ? ', ' + a['addressLine2'] : ''}, ${a['city'] ?? ''}, ${a['state'] ?? ''} - ${a['postal_code'] ?? ''}, ${a['country'] ?? ''}";
    }
    return OrderModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      addressId: json['addressId'] ?? '',
      totalAmount: json['totalAmount'] != null ? (json['totalAmount'] as num).toDouble() : 0.0,
      orderStatus: json['orderStatus'] ?? 'pending',
      paymentMethod: json['paymentMethod'] ?? 'COD',
      paymentStatus: json['paymentStatus'] ?? 'pending',
      createdAt: json['createdAt'] ?? '',
      shippingAddress: derivedAddr,
      items: json['items'] != null
          ? (json['items'] as List).map((i) => OrderItemModel.fromJson(i)).toList()
          : [],
    );
  }
}

class AddressModel {
  final String id;
  final String userId;
  final String addressLabel;
  final String recipientName;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final bool isDefaultBilling;
  final bool isDefaultShipping;

  AddressModel({
    required this.id,
    required this.userId,
    required this.addressLabel,
    required this.recipientName,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.isDefaultBilling = false,
    this.isDefaultShipping = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      addressLabel: json['addressLabel'] ?? 'Home',
      recipientName: json['recipientName'] ?? '',
      addressLine1: json['addressLine1'] ?? '',
      addressLine2: json['addressLine2'],
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postalCode: json['postal_code'] ?? '',
      country: json['country'] ?? '',
      isDefaultBilling: json['isDefaultBilling'] ?? false,
      isDefaultShipping: json['isDefaultShipping'] ?? false,
    );
  }

  String get fullAddress {
    String addr = addressLine1;
    if (addressLine2 != null && addressLine2!.isNotEmpty) {
      addr += ', $addressLine2';
    }
    addr += ', $city, $state - $postalCode, $country';
    return addr;
  }
}
