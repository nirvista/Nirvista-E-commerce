import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProductModel {
  final String id;
  final String title;
  final String? description;
  final String categoryId;
  final String brandId;
  final String brandName;
  final String? material;
  final double rating;
  List<VariantModel> variants;
  List<String> images;
  String? thumbnail;
  double? basePrice;
  double? salePrice;


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
    this.images = const [],
    this.thumbnail,
    this.basePrice,
    this.salePrice,
  });



  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Try to get brand name from nested 'brand' object or root-level 'brandName'
    String parsedBrandName = json['brandName']?.toString() ?? '';
    if (parsedBrandName.isEmpty && json['brand'] != null && json['brand'] is Map) {
      parsedBrandName = json['brand']['name']?.toString() ?? '';
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
          ? (json['rating'] is num ? (json['rating'] as num).toDouble() : double.tryParse(json['rating'].toString().replaceAll(',', '')) ?? 0.0)
          : 0.0,
      variants: (json['variants'] != null && json['variants'] is List)
          ? (json['variants'] as List).map((i) => VariantModel.fromJson(i)).toList()
          : [],
      images: json['images'] != null
          ? (json['images'] is List 
              ? (json['images'] as List).map((i) => _parseImage(i) ?? '').where((s) => s.isNotEmpty).toList()
              : [_parseImage(json['images']) ?? ''].where((s) => s.isNotEmpty).toList())
          : [],
      thumbnail: _parseImage(json['image'] ?? json['thumbnail'] ?? json['productImage'] ?? json['imageUrl'] ?? json['mainImage'] ?? json['featuredImage'] ?? json['image_url'] ?? json['img_url']),
      basePrice: _parseNum(json['price'] ?? json['originalPrice'] ?? json['basePrice'] ?? json['mrp'] ?? json['actual_price']),
      salePrice: _parseNum(json['discountPrice'] ?? json['salePrice'] ?? json['discount_price'] ?? json['sale_price'] ?? json['selling_price']),
    );
  }

  static double? _parseNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is Map) {
      // Handle cases like {"amount": 100, "original_price": 120}
      final nested = v['amount'] ?? v['price'] ?? v['value'] ?? v['mrp'] ?? v['current'];
      if (nested != null) return _parseNum(nested);
    }
    String s = v.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(s);
  }

  static String? _parseImage(dynamic e) {
    if (e == null) return null;
    final String baseUrl = dotenv.env['BASE_URL'] ?? '';
    
    String? path;
    if (e is Map) {
      // Handle image objects common in Express/Node backends
      path = (e['url'] ?? e['src'] ?? e['image'] ?? e['path'] ?? e['file'] ?? e['imageUrl'] ?? e['image_url'] ?? e['img_url'] ?? e['thumb'] ?? e['thumbnail'])?.toString();
      
      // Deep fallback: if still null, look for ANY string that looks like an image path
      if (path == null) {
        for (var val in e.values) {
          if (val is String && (val.endsWith('.jpg') || val.endsWith('.png') || val.endsWith('.jpeg') || val.endsWith('.webp') || val.contains('/uploads/'))) {
             path = val;
             break;
          }
        }
      }
    } else {
      path = e.toString();
    }

    if (path == null || path.trim().isEmpty) return null;
    
    String cleanPath = path.trim().replaceAll('\\', '/');
    if (cleanPath.isNotEmpty && !cleanPath.startsWith('http')) {
      return "$baseUrl${cleanPath.startsWith('/') ? '' : '/'}$cleanPath";
    }
    return cleanPath;
  }



  // Helpers for UI
  double get currentPrice {
    if (variants.isNotEmpty) {
      var v = variants.first;
      return v.discountPrice != null && v.discountPrice! > 0 ? v.discountPrice! : v.price;
    }
    return salePrice ?? basePrice ?? 0.0;
  }

  double get originalPrice {
    if (variants.isNotEmpty) {
      return variants.first.price;
    }
    return basePrice ?? 0.0;
  }

  String get imageUrl {
    if (thumbnail != null && thumbnail!.isNotEmpty) return thumbnail!;
    if (images.isNotEmpty) return images.first;
    for (var v in variants) {
      if (v.images.isNotEmpty) return v.images.first;
    }
    return '';
  }

  ProductModel merge(ProductModel other) {
    return ProductModel(
      id: id,
      title: other.title.isNotEmpty ? other.title : title,
      description: (other.description?.isNotEmpty ?? false) ? other.description : description,
      categoryId: other.categoryId.isNotEmpty ? other.categoryId : categoryId,
      brandId: other.brandId.isNotEmpty ? other.brandId : brandId,
      brandName: other.brandName.isNotEmpty ? other.brandName : brandName,
      material: (other.material?.isNotEmpty ?? false) ? other.material : material,
      rating: other.rating > 0 ? other.rating : rating,
      variants: other.variants.isNotEmpty ? other.variants : variants,
      images: other.images.isNotEmpty ? other.images : images,
      thumbnail: (other.thumbnail?.isNotEmpty ?? false) ? other.thumbnail : thumbnail,
      basePrice: (other.basePrice ?? 0) > 0 ? other.basePrice : basePrice,
      salePrice: (other.salePrice ?? 0) > 0 ? other.salePrice : salePrice,
    );
  }

  void copyFrom(ProductModel other) {
    variants = other.variants;
    // Copy top-level fields too so enrichment actually "heals" the product for the UI
    if (other.thumbnail != null) thumbnail = other.thumbnail;
    if (other.images.isNotEmpty) images.clear(); images.addAll(other.images);
    if (other.basePrice != null && other.basePrice! > 0) basePrice = other.basePrice;
    if (other.salePrice != null && other.salePrice! > 0) salePrice = other.salePrice;
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
    // Clean price strings (remove commas, currency symbols etc)
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      String s = value.toString().replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(s) ?? 0.0;
    }

    // Helper for stock parsing
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    // Parse images list directly — uses toString() so full URLs from the backend
    // are preserved without modification (fixes cart images not showing).
    double price = parseDouble(json['price'] ?? json['originalPrice'] ?? json['basePrice'] ?? json['mrp'] ?? json['actual_price']);
    double? discountPrice = (json['discountPrice'] ?? json['salePrice'] ?? json['discount_price'] ?? json['sale_price'] ?? json['selling_price']) != null 
        ? parseDouble(json['discountPrice'] ?? json['salePrice'] ?? json['discount_price'] ?? json['sale_price'] ?? json['selling_price']) 
        : null;
    
    // Parse images list using _parseImage for each item
    final List<String> parsedImages = [];
    dynamic imagesRaw = json['images'];
    if (imagesRaw is String && imagesRaw.isNotEmpty) {
      try {
        imagesRaw = jsonDecode(imagesRaw);
      } catch (e) {
        // Not a JSON string, handle as single image or ignore
      }
    }

    if (imagesRaw != null && imagesRaw is List) {
      for (var item in imagesRaw) {
        final img = ProductModel._parseImage(item);
        if (img != null) parsedImages.add(img);
      }
    }
    
    // Fallback: if no images list, try single-image fields
    if (parsedImages.isEmpty) {
      final String? img = ProductModel._parseImage(
          json['image'] ?? json['thumbnail'] ?? json['variantImage'] ?? json['imageUrl'] ?? json['src'] ?? json['image_url'] ?? json['img_url'] ?? json['path']);
      if (img != null && img.isNotEmpty) parsedImages.add(img);
    }
    
    int stock = parseInt(json['stock']);
    int reserved = parseInt(json['reservedStock'] ?? json['reservedstock']);
    int avail = json['availableStock'] != null ? parseInt(json['availableStock']) : (stock - reserved);

    return VariantModel(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      variantName: json['variantName']?.toString(),
      price: price,
      discountPrice: discountPrice,
      images: parsedImages,
      color: json['color']?.toString(),
      size: json['size']?.toString(),
      status: json['status']?.toString() ?? 'in-stock',
      stock: stock,
      reservedstock: reserved,
      availableStock: avail,
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
  final String? image;


  CartItemModel({
    this.id,
    required this.cartId,
    required this.productId,
    required this.variantId,
    required this.quantity,
    this.product,
    this.variant,
    this.image,
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
      image: ProductModel._parseImage(
          json['image'] ?? 
          json['thumbnail'] ?? 
          json['productImage'] ?? 
          json['imageUrl'] ?? 
          json['mainImage'] ?? 
          json['variantImage'] ?? 
          json['src'] ??
          (json['variant'] != null && json['variant']['images'] != null && (json['variant']['images'] is List) && (json['variant']['images'] as List).isNotEmpty 
              ? (json['variant']['images'] as List).first 
              : null)
      ),
    );
  }


  String get displayImage {
    if (variant != null && variant!.images.isNotEmpty) {
      return variant!.images.first;
    }
    if (product != null && product!.imageUrl.isNotEmpty) {
      return product!.imageUrl;
    }
    if (image != null && image!.isNotEmpty) {
      return image!;
    }
    return '';
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
  final String? image;


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
    this.image,
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
      image: ProductModel._parseImage(json['image'] ?? json['thumbnail'] ?? json['productImage'] ?? json['imageUrl'] ?? json['mainImage'] ?? json['variantImage'] ?? json['src']),
    );
  }


  String get displayImage {
    if (variant != null && variant!.images.isNotEmpty) {
      return variant!.images.first;
    }
    if (product != null && product!.imageUrl.isNotEmpty) {
      return product!.imageUrl;
    }
    if (image != null && image!.isNotEmpty) {
      return image!;
    }
    return '';
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
    final addressData = json['shippingAddress'] ?? json['address'];
    if (addressData != null && addressData is Map) {
      final a = addressData;
      derivedAddr = "${a['addressLine1'] ?? ''}${a['addressLine2'] != null && a['addressLine2'].toString().isNotEmpty ? ', ' + a['addressLine2'].toString() : ''}, ${a['city'] ?? ''}, ${a['state'] ?? ''} - ${a['postal_code'] ?? a['postalCode'] ?? ''}, ${a['country'] ?? ''}";
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
      addressLabel: json['addressLabel']?.toString() ?? json['label']?.toString() ?? 'Home',
      recipientName: json['recipientName']?.toString() ?? json['name']?.toString() ?? '',
      addressLine1: json['addressLine1']?.toString() ?? json['address']?.toString() ?? '',
      addressLine2: json['addressLine2']?.toString(),
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      postalCode: (json['postal_code'] ?? json['postalCode'] ?? json['zip'] ?? json['zipCode'])?.toString() ?? '',
      country: json["country"]?.toString() ?? '',
      isDefaultBilling: json['isDefaultBilling'] == true || json['isDefaultBilling'] == 1 || json['is_default_billing'] == true,
      isDefaultShipping: json['isDefaultShipping'] == true || json['isDefaultShipping'] == 1 || json['is_default_shipping'] == true,
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

  String get displayImage {
    if (variant != null && variant!.images.isNotEmpty) {
      return variant!.images.first;
    }
    if (product != null && product!.imageUrl.isNotEmpty) {
      return product!.imageUrl;
    }
    return '';
  }
}