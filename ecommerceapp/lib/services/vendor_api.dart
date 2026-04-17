import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class VendorApiService {
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

  static String get baseUrl {
    return '$_baseUrl/api/vendor';
  }

  static String get productsBaseUrl {
    return '$_baseUrl/api/products';
  }

  static Map<String, String> _headers(String accessToken) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
  }

  static Map<String, dynamic> _success(http.Response response) {
    final decoded = jsonDecode(response.body);
    return {
      'success': true,
      'data': decoded['data'],
      'message': decoded['message'],
    };
  }

  static Map<String, dynamic> _failure(
      http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      return {
        'success': false,
        'message': decoded['message'] ?? fallback,
      };
    } catch (_) {
      return {
        'success': false,
        'message': fallback,
      };
    }
  }

  static bool _isOk(http.Response response) {
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  static Future<Map<String, dynamic>> getVendorProducts(
      String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('$productsBaseUrl'),
        headers: _headers(accessToken),
      );
      if (_isOk(response)) return _success(response);
      return _failure(response, 'Failed to fetch vendor products');
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> createVendorProduct(
    String accessToken,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$productsBaseUrl'),
        headers: _headers(accessToken),
        body: jsonEncode(payload),
      );
      if (_isOk(response)) return _success(response);
      return _failure(response, 'Failed to create product');
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getVendorInventory(
      String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/inventory'),
        headers: _headers(accessToken),
      );
      if (_isOk(response)) return _success(response);
      return _failure(response, 'Failed to fetch inventory');
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

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

  static Future<Map<String, dynamic>> getVendorOrders(
      String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders'),
        headers: _headers(accessToken),
      );
      if (_isOk(response)) return _success(response);
      return _failure(response, 'Failed to fetch orders');
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getVendorOrderById(
    String accessToken,
    String orderId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: _headers(accessToken),
      );
      if (_isOk(response)) return _success(response);
      return _failure(response, 'Failed to fetch order');
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateFulfillment(
    String accessToken,
    String orderId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/orders/$orderId/fulfillment'),
        headers: _headers(accessToken),
        body: jsonEncode(payload),
      );
      if (_isOk(response)) return _success(response);
      return _failure(response, 'Failed to update fulfillment');
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> initiateVendorRefund(
    String accessToken,
    String orderId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/refunds'),
        headers: _headers(accessToken),
        body: jsonEncode(payload),
      );
      if (_isOk(response)) return _success(response);
      return _failure(response, 'Failed to initiate refund');
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getVendorSalesAnalytics(
      String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/sales'),
        headers: _headers(accessToken),
      );
      if (_isOk(response)) return _success(response);
      return _failure(response, 'Failed to fetch sales analytics');
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getVendorPerformanceAnalytics(
    String accessToken,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/performance'),
        headers: _headers(accessToken),
      );
      if (_isOk(response)) return _success(response);
      return _failure(response, 'Failed to fetch performance analytics');
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getVendorTopProducts(
      String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/top-products'),
        headers: _headers(accessToken),
      );
      if (_isOk(response)) return _success(response);
      return _failure(response, 'Failed to fetch top products');
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // --- New vendor-specific methods from backend ---

  /// Adds a new variant to an existing product.
  /// Endpoint: POST /api/products/:id/variants
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

  /// Updates an existing variant for a product.
  /// Endpoint: PUT /api/products/:id/variants/:variantId
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

  /// Fetches all variants for a specific product.
  /// Endpoint: GET /api/products/:id/variants
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

  /// Deletes a specific variant from a product.
  /// Endpoint: DELETE /api/products/:id/variants/:variantId
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

  /// Deletes a product (hard delete).
  /// Endpoint: DELETE /api/products/:id
  static Future<Map<String, dynamic>> deleteVendorProduct(
    String accessToken,
    String productId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/products/$productId'),
        headers: _headers(accessToken),
      );
      if (_isOk(response)) return _success(response);
      return _failure(response, 'Failed to delete product');
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
