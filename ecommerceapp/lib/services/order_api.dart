import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

class OrderApiService {
  static String get baseUrl {
    final url = dotenv.env['BASE_URL']?.trim();
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
          'x-client-type': kIsWeb ? 'web' : 'mobile',
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
          'x-client-type': kIsWeb ? 'web' : 'mobile',
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
          'x-client-type': kIsWeb ? 'web' : 'mobile',
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
          'x-client-type': kIsWeb ? 'web' : 'mobile',
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
          'Content-Type': 'application/json',
          'x-client-type': kIsWeb ? 'web' : 'mobile',
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
          'x-client-type': kIsWeb ? 'web' : 'mobile',
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

  static Future<Map<String, dynamic>> initiatePartialReturn(String accessToken, String orderId, List<Map<String, dynamic>> itemsToReturn) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/orders/$orderId/partial-return'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'x-client-type': kIsWeb ? 'web' : 'mobile',
        },
        body: jsonEncode({'itemsToReturn': itemsToReturn}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': jsonDecode(response.body)['message'] ?? 'Partial return initiated',
        };
      } else {
        String msg = 'Failed to initiate partial return';
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
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/$orderId/invoice'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'x-client-type': kIsWeb ? 'web' : 'mobile',
        },
      );

      if (response.statusCode == 200) {
        final fileName = 'invoice_$orderId.pdf';

        if (kIsWeb) {
          // ==========================================
          // WEB EXECUTION (Chrome, Safari, Edge, etc.)
          // ==========================================
          
          // Convert the bytes into a Blob (Binary Large Object)
          final blob = html.Blob([response.bodyBytes], 'application/pdf');
          
          // Create a temporary object URL
          final url = html.Url.createObjectUrlFromBlob(blob);
          
          // Create an invisible HTML anchor tag <a> and simulate a click
          html.AnchorElement(href: url)
            ..setAttribute("download", fileName)
            ..click();
            
          // Clean up the URL to free memory
          html.Url.revokeObjectUrl(url);

        } else {
          // ==========================================
          // MOBILE EXECUTION (Android / iOS)
          // ==========================================
          final directory = await getApplicationDocumentsDirectory();
          final filePath = '${directory.path}/$fileName';
          final file = File(filePath);

          await file.writeAsBytes(response.bodyBytes);

          final result = await OpenFile.open(filePath);
          if (result.type != ResultType.done) {
            throw 'Could not open the invoice file';
          }
        }
      } else {
        String msg = 'Failed to download invoice';
        try {
          msg = jsonDecode(response.body)['message'] ?? msg;
        } catch (_) {}
        throw msg;
      }
    } catch (e) {
      throw 'Error downloading invoice: ${e.toString()}';
    }
  }
}