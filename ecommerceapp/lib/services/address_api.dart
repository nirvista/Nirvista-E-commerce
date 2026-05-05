import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AddressApiService {
  static String get baseUrl {
    final url = dotenv.env['BASE_URL']?.trim();
    if (url == null) {
      throw Exception("BASE_URL not found in .env file");
    }
    return url;
  }

  /// GET /api/address — Fetch all addresses for the logged-in user
  static Future<Map<String, dynamic>> getUserAddresses(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/address'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'x-client-type': 'mobile',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        return {
          'success': true,
          'data': decoded['data'],
          'message': decoded['message'],
        };
      } else {
        String msg = 'Failed to fetch addresses';
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

  /// POST /api/address — Add a new address
  static Future<Map<String, dynamic>> addAddress({
    required String accessToken,
    required String addressLabel,
    required String recipientName,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String postalCode,
    required String country,
    bool isDefaultShipping = false,
  }) async {
    try {
      final body = {
        'addressLabel': addressLabel,
        'recipientName': recipientName,
        'addressLine1': addressLine1,
        'city': city,
        'state': state,
        'postal_code': postalCode,
        'country': country,
        'isDefaultShipping': isDefaultShipping,
      };
      if (addressLine2 != null && addressLine2.isNotEmpty) {
        body['addressLine2'] = addressLine2;
      }
      final response = await http.post(
        Uri.parse('$baseUrl/api/address'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'x-client-type': 'mobile',
        },
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        return {
          'success': true,
          'data': decoded['data'],
          'message': decoded['message'],
        };
      } else {
        String msg = 'Failed to add address';
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

  /// PUT /api/address/:addressId — Update address
  static Future<Map<String, dynamic>> updateAddress({
    required String accessToken,
    required String addressId,
    String? addressLabel,
    String? recipientName,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    bool? isDefaultShipping,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (addressLabel != null) body['addressLabel'] = addressLabel;
      if (recipientName != null) body['recipientName'] = recipientName;
      if (addressLine1 != null) body['addressLine1'] = addressLine1;
      if (addressLine2 != null) body['addressLine2'] = addressLine2;
      if (city != null) body['city'] = city;
      if (state != null) body['state'] = state;
      if (postalCode != null) body['postal_code'] = postalCode;
      if (country != null) body['country'] = country;
      if (isDefaultShipping != null) body['isDefaultShipping'] = isDefaultShipping;

      final response = await http.put(
        Uri.parse('$baseUrl/api/address/$addressId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'x-client-type': 'mobile',
        },
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        return {'success': true, 'data': decoded['data'], 'message': decoded['message']};
      } else {
        String msg = 'Failed to update address';
        try {
          msg = jsonDecode(response.body)['message'] ?? msg;
        } catch (_) {}
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {'success': false, 'message': "Connection error: ${e.toString()}"};
    }
  }

  /// DELETE /api/address/:addressId — Delete address
  static Future<Map<String, dynamic>> deleteAddress(String accessToken, String addressId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/address/$addressId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'x-client-type': 'mobile',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': jsonDecode(response.body)['message']};
      } else {
        String msg = 'Failed to delete address';
        try {
          msg = jsonDecode(response.body)['message'] ?? msg;
        } catch (_) {}
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {'success': false, 'message': "Connection error: ${e.toString()}"};
    }
  }

  /// POST /api/address/:addressId/default — Set default address
  static Future<Map<String, dynamic>> setDefaultAddress(String accessToken, String addressId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/address/$addressId/default'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'x-client-type': 'mobile',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        return {'success': true, 'data': decoded['data'], 'message': decoded['message']};
      } else {
        String msg = 'Failed to set default address';
        try {
          msg = jsonDecode(response.body)['message'] ?? msg;
        } catch (_) {}
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {'success': false, 'message': "Connection error: ${e.toString()}"};
    }
  }
}
