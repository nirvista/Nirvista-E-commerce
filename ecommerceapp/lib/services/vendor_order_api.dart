import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class VendorOrderApiService {
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

  static String get baseUrl => '$_baseUrl/api/vendor/orders';

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
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': '$fallback - Status ${response.statusCode}'};
    }
  }

  static bool _isOk(http.Response response) =>
      response.statusCode >= 200 && response.statusCode < 300;

  /// GET /api/vendor/orders
  static Future<Map<String, dynamic>> getVendorOrders(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: _headers(accessToken),
      );
      if (_isOk(response)) return _success(response);
      return _failure(response, 'Failed to fetch orders');
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// GET /api/vendor/orders/:orderId
  static Future<Map<String, dynamic>> getVendorOrderById(
    String accessToken,
    String orderId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$orderId'),
        headers: _headers(accessToken),
      );
      if (_isOk(response)) return _success(response);
      return _failure(response, 'Failed to fetch order');
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// PATCH /api/vendor/orders/:orderId/fulfillment
  static Future<Map<String, dynamic>> updateFulfillment(
    String accessToken,
    String orderId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$orderId/fulfillment'),
        headers: _headers(accessToken),
        body: jsonEncode(payload),
      );
      if (_isOk(response)) return _success(response);
      return _failure(response, 'Failed to update fulfillment');
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// POST /api/vendor/orders/:orderId/refunds
  static Future<Map<String, dynamic>> initiateVendorRefund(
    String accessToken,
    String orderId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$orderId/refunds'),
        headers: _headers(accessToken),
        body: jsonEncode(payload),
      );
      if (_isOk(response)) return _success(response);
      return _failure(response, 'Failed to initiate refund');
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
