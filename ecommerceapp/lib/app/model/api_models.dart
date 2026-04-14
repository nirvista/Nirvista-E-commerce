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
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      categoryId: json['categoryId']?.toString() ?? '',
      brandId: json['brandId']?.toString() ?? '',
      brandName: parsedBrandName,
      material: json['material']?.toString(),
      rating: json['rating'] != null 
          ? (json['rating'] is num ? (json['rating'] as num).toDouble() : double.tryParse(json['rating'].toString()) ?? 0.0)
          : 0.0,
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
  final String productId;
  final String? variantName;
  final double price;
  final double? discountPrice;
  final List<String> images;
  final String? color;
  final String? size;
  final String status;
  final int stock;
  final int reservedstock;
  final int availableStock;
  final String approvalStatus;

  VariantModel({
    required this.id,
    required this.productId,
    this.variantName,
    required this.price,
    this.discountPrice,
    this.images = const [],
    this.color,
    this.size,
    this.status = 'in-stock',
    this.stock = 0,
    this.reservedstock = 0,
    this.availableStock = 0,
    this.approvalStatus = 'pending',
  });

  factory VariantModel.fromJson(Map<String, dynamic> json) {
    return VariantModel(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      variantName: json['variantName']?.toString(),
      price: json['price'] != null 
    ? (json['price'] is num ? (json['price'] as num).toDouble() : double.tryParse(json['price'].toString()) ?? 0.0)
      : 0.0,
      discountPrice: json['discountPrice'] != null 
    ? (json['discountPrice'] is num ? (json['discountPrice'] as num).toDouble() : double.tryParse(json['discountPrice'].toString()))
    : null,

      images: json['images'] != null ? List<String>.from(json['images'].map((i) => i.toString())) : [],
      color: json['color']?.toString(),
      size: json['size']?.toString(),
      status: json['status']?.toString() ?? 'in-stock',
      stock: json['stock'] != null ? (json['stock'] is num ? (json['stock'] as num).toInt() : int.tryParse(json['stock'].toString()) ?? 0) : 0,
      reservedstock: json['reservedstock'] != null ? (json['reservedstock'] is num ? (json['reservedstock'] as num).toInt() : int.tryParse(json['reservedstock'].toString()) ?? 0) : (json['reservedStock'] != null ? (json['reservedStock'] is num ? (json['reservedStock'] as num).toInt() : int.tryParse(json['reservedStock'].toString()) ?? 0) : 0),
      availableStock: json['availableStock'] != null 
    ? (json['availableStock'] is num ? (json['availableStock'] as num).toInt() : int.tryParse(json['availableStock'].toString()) ?? 0)
    : (int.tryParse(json['stock']?.toString() ?? '0') ?? 0) - (int.tryParse(json['reservedstock']?.toString() ?? json['reservedStock']?.toString() ?? '0') ?? 0),
      approvalStatus: json['approvalStatus']?.toString() ?? 'pending',
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
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      parentId: json['parentId']?.toString(),
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
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      logoUrl: json['logoUrl']?.toString(),
    );
  }
}

class CartItemModel {
  final String? id;
  final String cartId;
  final String productId;
  final String variantId;
  final int quantity;
  final ProductModel? product;
  final VariantModel? variant;

  CartItemModel({
    this.id,
    required this.cartId,
    required this.productId,
    required this.variantId,
    required this.quantity,
    this.product,
    this.variant,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id']?.toString(),
      cartId: json['cartId']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      variantId: json['variant'] != null ? (json['variant']['id']?.toString() ?? '') : (json['variantId']?.toString() ?? ''),
      quantity: json['quantity'] != null ? (json['quantity'] is num ? (json['quantity'] as num).toInt() : int.tryParse(json['quantity'].toString()) ?? 0) : 0,
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
      cartId: json['id']?.toString() ?? json['cartId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      items: json['items'] != null
          ? (json['items'] as List).map((i) => CartItemModel.fromJson(i)).toList()
          : [],
    );
  }
}

class OrderItemModel {
  final String id;
  final String orderId;
  final String productId;
  final String variantId;
  final int quantity;
  final double priceAtPurchase;
  final String returnStatus;
  final int returnedQuantity;
  final ProductModel? product;
  final VariantModel? variant;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.variantId,
    required this.quantity,
    required this.priceAtPurchase,
    this.returnStatus = 'none',
    this.returnedQuantity = 0,
    this.product,
    this.variant,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      variantId: json['variantId']?.toString() ?? '',
      quantity: json['quantity'] != null ? (json['quantity'] is num ? (json['quantity'] as num).toInt() : int.tryParse(json['quantity'].toString()) ?? 0) : 0,
      priceAtPurchase: json['priceAtPurchase'] != null 
    ? (json['priceAtPurchase'] is num ? (json['priceAtPurchase'] as num).toDouble() : double.tryParse(json['priceAtPurchase'].toString()) ?? 0.0)
    : 0.0,
      returnStatus: json['returnStatus']?.toString() ?? 'none',
      returnedQuantity: json['returnedQuantity'] != null ? (json['returnedQuantity'] is num ? (json['returnedQuantity'] as num).toInt() : int.tryParse(json['returnedQuantity'].toString()) ?? 0) : 0,
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
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
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
    this.razorpayOrderId,
    this.razorpayPaymentId,
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
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      addressId: json['addressId']?.toString() ?? '',
     totalAmount: json['totalAmount'] != null 
      ? (json['totalAmount'] is num ? (json['totalAmount'] as num).toDouble() : double.tryParse(json['totalAmount'].toString()) ?? 0.0)
      : 0.0,
      orderStatus: json['orderStatus']?.toString() ?? 'processing',
      paymentMethod: json['paymentMethod']?.toString() ?? 'cod',
      paymentStatus: json['paymentStatus']?.toString() ?? 'pending',
      razorpayOrderId: json['razorpayOrderId']?.toString(),
      razorpayPaymentId: json['razorpayPaymentId']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
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
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      addressLabel: json['addressLabel']?.toString() ?? 'Home',
      recipientName: json['recipientName']?.toString() ?? '',
      addressLine1: json['addressLine1']?.toString() ?? '',
      addressLine2: json['addressLine2']?.toString(),
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      postalCode: json['postal_code']?.toString() ?? '',
      country: json["country"]?.toString() ?? '',
      isDefaultBilling: json['isDefaultBilling'] == true || json['isDefaultBilling'] == 1,
      isDefaultShipping: json['isDefaultShipping'] == true || json['isDefaultShipping'] == 1,
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

class WishlistItemModel {
  final String id;
  final String wishlistId;
  final String productId;
  final String variantId;
  final ProductModel? product;
  final VariantModel? variant;

  WishlistItemModel({
    required this.id,
    required this.wishlistId,
    required this.productId,
    required this.variantId,
    this.product,
    this.variant,
  });

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) {
    return WishlistItemModel(
      id: json['id'] ?? '',
      wishlistId: json['wishlistId'] ?? '',
      productId: json['productId'] ?? '',
      variantId: json['variantId'] ?? (json['variant'] != null ? json['variant']['id'] : ''),
      product: json['product'] != null ? ProductModel.fromJson(json['product']) : null,
      variant: json['variant'] != null ? VariantModel.fromJson(json['variant']) : null,
    );
  }
}