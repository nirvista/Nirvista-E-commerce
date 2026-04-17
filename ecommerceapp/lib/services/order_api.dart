import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderApiService {
  static String get baseUrl {
    final rawUrl = dotenv.env['BASE_URL']?.trim();
    if (rawUrl == null || rawUrl.isEmpty) {
      throw Exception("BASE_URL not found in .env file");
    }
    final withoutTrailingSlash = rawUrl.replaceAll(RegExp(r'/+$'), '');
    if (withoutTrailingSlash.endsWith('/api')) {
      return withoutTrailingSlash.substring(0, withoutTrailingSlash.length - 4);
    }
    return withoutTrailingSlash;
  }

  static Future<Map<String, dynamic>> createOrder({
    required String accessToken,
    String? addressId,
    required String paymentMethod,
  }) async {
    try {
      final bodyData = {
        'paymentMethod': paymentMethod,
      };
      if (addressId != null && addressId.isNotEmpty) {
        bodyData['addressId'] = addressId;
      }
      final response = await http.post(
        Uri.parse('$baseUrl/api/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(bodyData),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': jsonDecode(response.body)['data'],
          'message': jsonDecode(response.body)['message']
        };
      } else {
        return {
          'success': false,
          'message':
              jsonDecode(response.body)['message'] ?? 'Failed to create order',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getUserOrders(String accessToken,
      {String? status}) async {
    try {
      String url = '$baseUrl/api/orders';
      if (status != null && status.isNotEmpty) {
        url += '?status=$status';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': jsonDecode(response.body)['data'],
        };
      } else {
        return {
          'success': false,
          'message':
              jsonDecode(response.body)['message'] ?? 'Failed to fetch orders',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getOrderById(
      String accessToken, String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/$orderId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': jsonDecode(response.body)['data'],
        };
      } else {
        return {
          'success': false,
          'message':
              jsonDecode(response.body)['message'] ?? 'Failed to fetch order',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> cancelOrder(
      String accessToken, String orderId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/orders/$orderId/cancel'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': jsonDecode(response.body)['message'] ?? 'Order cancelled',
        };
      } else {
        return {
          'success': false,
          'message':
              jsonDecode(response.body)['message'] ?? 'Failed to cancel order',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getOrderStatus(
      String accessToken, String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/$orderId/status'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': jsonDecode(response.body)['data'],
        };
      } else {
        return {
          'success': false,
          'message': jsonDecode(response.body)['message'] ??
              'Failed to get order status',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> initiateReturn(
      String accessToken, String orderId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/orders/$orderId/return'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': jsonDecode(response.body)['message'] ?? 'Return initiated',
        };
      } else {
        return {
          'success': false,
          'message': jsonDecode(response.body)['message'] ??
              'Failed to initiate return',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<void> downloadInvoice(
      String accessToken, String orderId) async {
    final url =
        Uri.parse('$baseUrl/api/orders/$orderId/invoice?token=$accessToken');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }
}
