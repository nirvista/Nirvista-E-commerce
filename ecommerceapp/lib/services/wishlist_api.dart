import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WishlistService {
  static String get baseUrl {
    final url = dotenv.env['BASE_URL']?.trim();
    if (url == null || url.isEmpty) {
      throw Exception("BASE_URL not found in .env file");
    }
    return url;
  }

  /// GET /api/wishlist - Fetch user's wishlist
  /// Backend expects: userId (from req.user or req.body)
  /// Returns: { success, message, data: { items: [...] } }
  static Future<WishlistResponse> getWishlist(String userId) async {
    final uri = Uri.parse('$baseUrl/api/wishlist?userId=$userId');
    print('[Wishlist] GET $uri');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    print('[Wishlist] GET Status: ${response.statusCode}');
    print('[Wishlist] GET Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return WishlistResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch wishlist: ${response.body}');
    }
  }

  /// POST /api/wishlist - Add item to wishlist
  /// Backend expects: { userId, productId, variantId }
  /// Returns: { success, message, data: item }
  static Future<bool> addToWishlist({
    required String userId,
    required String productId,
    required String variantId,
  }) async {
    final body = {
      'userId': userId,
      'productId': productId,
      'variantId': variantId,
    };

    print('[Wishlist] POST /api/wishlist with body: $body');

    final response = await http.post(
      Uri.parse('$baseUrl/api/wishlist'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 10));

    print('[Wishlist] POST Status: ${response.statusCode} | Body: ${response.body}');
    return response.statusCode == 200 || response.statusCode == 201;
  }

  /// DELETE /api/wishlist/:itemId - Remove item from wishlist
  /// Backend expects: itemId in route params
  /// Returns: { success, message }
  static Future<bool> removeFromWishlist(String itemId) async {
    final uri = Uri.parse('$baseUrl/api/wishlist/$itemId');
    print('[Wishlist] DELETE $uri');

    final response = await http.delete(
      uri,
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    print('[Wishlist] DELETE Status: ${response.statusCode}');
    return response.statusCode == 200;
  }

  /// POST /api/wishlist/move-to-cart/:itemId - Move item from wishlist to cart
  /// Backend expects: itemId in route params, { userId } in body
  /// Returns: { success, message }
  static Future<bool> moveToCart({
    required String itemId,
    required String userId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/wishlist/move-to-cart/$itemId');
    print('[Wishlist] POST $uri with userId: $userId');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    ).timeout(const Duration(seconds: 10));

    print('[Wishlist] Move to cart Status: ${response.statusCode}');
    return response.statusCode == 200;
  }

  /// DELETE /api/wishlist - Clear entire wishlist for user
  /// Backend expects: userId (from req.user or req.body)
  /// Returns: { success, message }
  static Future<bool> clearWishlist(String userId) async {
    final body = {'userId': userId};
    print('[Wishlist] DELETE /api/wishlist with body: $body');

    final response = await http.delete(
      Uri.parse('$baseUrl/api/wishlist'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 10));

    print('[Wishlist] Clear Status: ${response.statusCode}');
    return response.statusCode == 200;
  }
}

// ─── Models ─────────────────────────────────────────────

class WishlistResponse {
  final bool success;
  final String message;
  final WishlistData data;

  WishlistResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory WishlistResponse.fromJson(Map<String, dynamic> json) {
    return WishlistResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: WishlistData.fromJson(json['data'] ?? {}),
    );
  }
}

class WishlistData {
  final String id;
  final String userId;
  final List<WishlistItem> items;

  WishlistData({
    this.id = '',
    this.userId = '',
    this.items = const [],
  });

  factory WishlistData.fromJson(Map<String, dynamic> json) {
    return WishlistData(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => WishlistItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class WishlistItem {
  final String id;
  final String wishlistId;
  final String productId;
  final String variantId;
  final WishlistProduct product;
  final WishlistVariant variant;

  WishlistItem({
    required this.id,
    required this.wishlistId,
    required this.productId,
    required this.variantId,
    required this.product,
    required this.variant,
  });

  /// NEW: Helper to convert back to ProductModel for UI reuse
  dynamic toProductModel() {
    return {
      'id': productId,
      'title': product.title,
      'originalPrice': variant.price,
      'salePrice': variant.price,
      'price': variant.price,
      'images': variant.images,
      'variants': [
        {
          'id': variantId,
          'originalPrice': variant.price,
          'salePrice': variant.price,
          'price': variant.price,
          'images': variant.images,
          'status': variant.status,
          'name': variant.variantName,
        }
      ]
    };
  }

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'] ?? '',
      wishlistId: json['wishlistId'] ?? '',
      productId: json['productId'] ?? '',
      variantId: json['variantId'] ?? '',
      product: WishlistProduct.fromJson(
          json['product'] as Map<String, dynamic>? ?? {}),
      variant: WishlistVariant.fromJson(
          json['variant'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class WishlistProduct {
  final String id;
  final String title;

  WishlistProduct({
    required this.id,
    required this.title,
  });

  factory WishlistProduct.fromJson(Map<String, dynamic> json) {
    return WishlistProduct(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
    );
  }
}

class WishlistVariant {
  final String id;
  final String variantName;
  final double price;
  final List<String> images;
  final String status;

  WishlistVariant({
    required this.id,
    required this.variantName,
    required this.price,
    required this.images,
    required this.status,
  });

  factory WishlistVariant.fromJson(Map<String, dynamic> json) {
    return WishlistVariant(
      id: json['id'] ?? '',
      variantName: json['variantName'] ?? '',
      price: json['price'] != null 
          ? (json['price'] is num ? (json['price'] as num).toDouble() : double.tryParse(json['price'].toString().replaceAll(',', '')) ?? 0.0)
          : 0.0,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      status: json['status'] ?? 'out-of-stock',
    );
  }
}
