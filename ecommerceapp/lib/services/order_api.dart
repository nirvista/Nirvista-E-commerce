import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderApiService {
  static String get baseUrl {
    final url = dotenv.env['BASE_URL'];
    if (url == null) {
      throw Exception("BASE_URL not found in .env file");
    }
    return url;
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
        final decoded = jsonDecode(response.body);
        return {
          'success': true,
          ...decoded,
        };
      } else {
        String msg = 'Failed to create order';
        try {
          msg = jsonDecode(response.body)['message'] ?? msg;
        } catch (_) {}
        return {
          'success': false,
          'message': msg,
        };
      }
    } catch (e) {
      return {'success': false, 'message': "Connection error: ${e.toString()}"};
    }
  }

  static Future<Map<String, dynamic>> getUserOrders(String accessToken, {String? status}) async {
    try {
      String url = '$baseUrl/api/orders';
      if (status != null && status.isNotEmpty) {
        url += '?status=$status';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': jsonDecode(response.body)['data'],
        };
      } else {
        String msg = 'Failed to fetch orders';
        try {
          msg = jsonDecode(response.body)['message'] ?? msg;
        } catch (_) {}
        return {
          'success': false,
          'message': msg,
        };
      }
    } catch (e) {
      return {'success': false, 'message': "Connection error: ${e.toString()}"};
    }
  }

  static Future<Map<String, dynamic>> getOrderById(String accessToken, String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/$orderId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': jsonDecode(response.body)['data'],
        };
      } else {
        String msg = 'Failed to fetch order';
        try {
          msg = jsonDecode(response.body)['message'] ?? msg;
        } catch (_) {}
        return {
          'success': false,
          'message': msg,
        };
      }
    } catch (e) {
      return {'success': false, 'message': "Connection error: ${e.toString()}"};
    }
  }

  static Future<Map<String, dynamic>> cancelOrder(String accessToken, String orderId) async {
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
        String msg = 'Failed to cancel order';
        try {
          msg = jsonDecode(response.body)['message'] ?? msg;
        } catch (_) {}
        return {
          'success': false,
          'message': msg,
        };
      }
    } catch (e) {
      return {'success': false, 'message': "Connection error: ${e.toString()}"};
    }
  }

  static Future<Map<String, dynamic>> getOrderStatus(String accessToken, String orderId) async {
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
        String msg = 'Failed to get order status';
        try {
          msg = jsonDecode(response.body)['message'] ?? msg;
        } catch (_) {}
        return {
          'success': false,
          'message': msg,
        };
      }
    } catch (e) {
      return {'success': false, 'message': "Connection error: ${e.toString()}"};
    }
  }

  static Future<Map<String, dynamic>> initiateReturn(String accessToken, String orderId) async {
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
        String msg = 'Failed to initiate return';
        try {
          msg = jsonDecode(response.body)['message'] ?? msg;
        } catch (_) {}
        return {
          'success': false,
          'message': msg,
        };
      }
    } catch (e) {
      return {'success': false, 'message': "Connection error: ${e.toString()}"};
    }
  }

  static Future<void> downloadInvoice(String accessToken, String orderId) async {
    final url = Uri.parse('$baseUrl/api/orders/$orderId/invoice?token=$accessToken');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }
}
