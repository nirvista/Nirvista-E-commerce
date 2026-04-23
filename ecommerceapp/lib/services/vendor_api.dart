import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class VendorApiService {
  // ─────────────────────────────────────────────────────────────────────────────
  //  BASE URL
  // ─────────────────────────────────────────────────────────────────────────────
  static String get _baseUrl {
    final rawUrl = dotenv.env['BASE_URL']?.trim();
    if (rawUrl == null || rawUrl.isEmpty) {
      throw Exception('BASE_URL not found in .env file');
    }
    final withoutTrailingSlash = rawUrl.replaceAll(RegExp(r'/+$'), '');
    if (withoutTrailingSlash.endsWith('/api')) {
      return withoutTrailingSlash.substring(0, withoutTrailingSlash.length - 4);
    }
    return withoutTrailingSlash;
  }

  static String get baseUrl => '$_baseUrl/api/vendor';
  static String get productsBaseUrl => '$_baseUrl/api/products';

  // ─────────────────────────────────────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────────────────────────────────────
  static Map<String, String> _headers(String accessToken) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

  static Map<String, dynamic> _success(http.Response response) {
    final decoded = jsonDecode(response.body);
    return {
      'success': true,
      'data': decoded['data'],
      'message': decoded['message'],
    };
  }

  static Map<String, dynamic> _failure(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      final message = decoded['message'] ?? decoded['error'] ?? fallback;
      print('[VendorApiService Error] Status: ${response.statusCode}, Message: $message, Body: ${response.body}');
      return {'success': false, 'message': message};
    } catch (e) {
      print('[VendorApiService Error] Status: ${response.statusCode}, Fallback: $fallback, Body: ${response.body}, Parse Error: $e');
      return {'success': false, 'message': '$fallback - Status ${response.statusCode}'};
    }
  }

  static bool _isOk(http.Response response) =>
      response.statusCode >= 200 && response.statusCode < 300;

  // ─────────────────────────────────────────────────────────────────────────────
  //  VENDOR PROFILE  &  CURRENT USER
  // ─────────────────────────────────────────────────────────────────────────────

  /// POST /api/vendor/profile
  /// Creates the vendor profile for the currently authenticated vendor.
  /// Backend returns 400 "Vendor profile already exists" if one is present.
  static Future<Map<String, dynamic>> createVendorProfile(
    String accessToken,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/profile'),
        headers: _headers(accessToken),
        body: jsonEncode(payload),
      );
      if (_isOk(response)) return _success(response);
      return _failure(response, 'Failed to create vendor profile');
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// GET /api/auth/me — returns the current user including userStatus.
  /// Used after login to decide where to route a vendor
  /// (pending → profile screen, active → dashboard, suspended → blocked).
  static Future<Map<String, dynamic>> getCurrentUser(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/auth/me'),
        headers: _headers(accessToken),
      );
      if (_isOk(response)) return _success(response);
      return _failure(response, 'Failed to fetch current user');
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  PRODUCTS
  // ─────────────────────────────────────────────────────────────────────────────

  /// GET /api/vendor/products
  /// Supports: listingStatus, categoryId, search, page, limit, sortBy, sortOrder
  static Future<Map<String, dynamic>> getVendorProducts(
    String accessToken, {
    String? listingStatus,
    String? categoryId,
    String? search,
    int page = 1,
    int limit = 20,
    String sortBy = 'createdAt',
    String sortOrder = 'DESC',
  }) async {
    try {
      final params = {
        'page': '$page',
        'limit': '$limit',
        'sortBy': sortBy,
        'sortOrder': sortOrder,
        if (listingStatus != null) 'listingStatus': listingStatus,
        if (categoryId != null) 'categoryId': categoryId,
        if (search != null && search.isNotEmpty) 'search': search,
      };
      final uri = Uri.parse('$baseUrl/products').replace(queryParameters: params);
      final response = await http.get(uri, headers: _headers(accessToken));
      if (_isOk(response)) return _success(response);
      return _failure(response, 'Failed to fetch vendor products');
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// POST /api/vendor/products
  static Future<Map<String, dynamic>> createVendorProduct(
    String accessToken,
    Map<String, dynamic> payload,
  ) async {
    try {
      print('[VendorApiService] Creating product with payload: $payload');
      print('[VendorApiService] URL: $baseUrl/products');
      print('[VendorApiService] Token: $accessToken');
      final response = await http.post(
        Uri.parse('$baseUrl/products'),
        headers: _headers(accessToken),
        body: jsonEncode(payload),
      );
      print('[VendorApiService] Response status: ${response.statusCode}');
      print('[VendorApiService] Response body: ${response.body}');
      if (_isOk(response)) return _success(response);
      return _failure(response, 'Failed to create product');
    } catch (e) {
      print('[VendorApiService] Exception: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// PUT /api/vendor/products/:productId
  static Future<Map<String, dynamic>> updateVendorProduct(
    String accessToken,
    String productId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/products/$productId'),
        headers: _headers(accessToken),
        body: jsonEncode(payload),
      );
      if (_isOk(response)) return _success(response);
      return _failure(response, 'Failed to update product');
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// PATCH /api/vendor/products/:productId/status
  static Future<Map<String, dynamic>> updateVendorProductStatus(
    String accessToken,
    String productId,
    String listingStatus,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/products/$productId/status'),
        headers: _headers(accessToken),
        body: jsonEncode({'listingStatus': listingStatus}),
      );
      if (_isOk(response)) return _success(response);
      return _failure(response, 'Failed to update product status');
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// POST /api/vendor/products/:productId/images
  static Future<Map<String, dynamic>> addVariantImageUrls(
    String accessToken,
    String productId, {
    required String variantId,
    required List<String> imageUrls,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products/$productId/images'),
        headers: _headers(accessToken),
        body: jsonEncode({'variantId': variantId, 'imageUrls': imageUrls}),
      );
      if (_isOk(response)) return _success(response);
      return _failure(response, 'Failed to add image URLs');
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// DELETE /api/vendor/products/:id
  static Future<Map<String, dynamic>> deleteVendorProduct(
    String accessToken,
    String id,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/products/$id'),
        headers: _headers(accessToken),
      );
      if (_isOk(response)) return _success(response);
      return _failure(response, 'Failed to delete product');
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  VARIANTS  (via /api/products — public product routes)
  // ─────────────────────────────────────────────────────────────────────────────

  /// POST /api/products/:id/variants
  static Future<Map<String, dynamic>> addVariant(
    String accessToken,
    String productId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$productsBaseUrl/$productId/variants'),
        headers: _headers(accessToken),
        body: jsonEncode(payload),
      );
      if (_isOk(response)) return _success(response);
      return _failure(response, 'Failed to add variant');
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// PUT /api/products/:id/variants/:variantId
  static Future<Map<String, dynamic>> updateVariant(
    String accessToken,
    String productId,
    String variantId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$productsBaseUrl/$productId/variants/$variantId'),
        headers: _headers(accessToken),
        body: jsonEncode(payload),
      );
      if (_isOk(response)) return _success(response);
      return _failure(response, 'Failed to update variant');
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// GET /api/products/:id/variants
  static Future<Map<String, dynamic>> getProductVariants(
    String accessToken,
    String productId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$productsBaseUrl/$productId/variants'),
        headers: _headers(accessToken),
      );
      if (_isOk(response)) return _success(response);
      return _failure(response, 'Failed to fetch product variants');
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// DELETE /api/products/:id/variants/:variantId
  static Future<Map<String, dynamic>> deleteVariant(
    String accessToken,
    String productId,
    String variantId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$productsBaseUrl/$productId/variants/$variantId'),
        headers: _headers(accessToken),
      );
      if (_isOk(response)) return _success(response);
      return _failure(response, 'Failed to delete variant');
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  INVENTORY
  // ─────────────────────────────────────────────────────────────────────────────

  /// GET /api/vendor/inventory
  /// Supports: lowStockOnly, status, search, page, limit
  static Future<Map<String, dynamic>> getVendorInventory(
    String accessToken, {
    bool lowStockOnly = false,
    String? status,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final params = {
        'page': '$page',
        'limit': '$limit',
        if (lowStockOnly) 'lowStockOnly': '1',
        if (status != null) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      };
      final uri = Uri.parse('$baseUrl/inventory').replace(queryParameters: params);
      final response = await http.get(uri, headers: _headers(accessToken));
      if (_isOk(response)) return _success(response);
      return _failure(response, 'Failed to fetch inventory');
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// PATCH /api/vendor/inventory/:sku
  /// Body: { quantity: int, operation: 'set'|'increment'|'decrement', lowStockThreshold?: int }
  static Future<Map<String, dynamic>> adjustVendorInventory(
    String accessToken,
    String sku,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/inventory/$sku'),
        headers: _headers(accessToken),
        body: jsonEncode(payload),
      );
      if (_isOk(response)) return _success(response);
      return _failure(response, 'Failed to adjust inventory');
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  ANALYTICS
  // ─────────────────────────────────────────────────────────────────────────────

  /// GET /api/vendor/analytics/sales
  /// timeframe: today | last_7_days | last_30_days | last_90_days |
  ///            last_12_months | this_month | this_year
  /// granularity: day | week | month
  static Future<Map<String, dynamic>> getVendorSalesAnalytics(
    String accessToken, {
    String timeframe = 'last_30_days',
    String granularity = 'day',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/analytics/sales').replace(
        queryParameters: {'timeframe': timeframe, 'granularity': granularity},
      );
      final response = await http.get(uri, headers: _headers(accessToken));
      if (_isOk(response)) return _success(response);
      return _failure(response, 'Failed to fetch sales analytics');
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// GET /api/vendor/analytics/performance
  static Future<Map<String, dynamic>> getVendorPerformanceAnalytics(
    String accessToken, {
    String timeframe = 'last_30_days',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/analytics/performance').replace(
        queryParameters: {'timeframe': timeframe},
      );
      final response = await http.get(uri, headers: _headers(accessToken));
      if (_isOk(response)) return _success(response);
      return _failure(response, 'Failed to fetch performance analytics');
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// GET /api/vendor/analytics/top-products
  /// metric: revenue | volume
  static Future<Map<String, dynamic>> getVendorTopProducts(
    String accessToken, {
    String timeframe = 'last_30_days',
    String metric = 'revenue',
    int limit = 10,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/analytics/top-products').replace(
        queryParameters: {
          'timeframe': timeframe,
          'metric': metric,
          'limit': '$limit',
        },
      );
      final response = await http.get(uri, headers: _headers(accessToken));
      if (_isOk(response)) return _success(response);
      return _failure(response, 'Failed to fetch top products');
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}