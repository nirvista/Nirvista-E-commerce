import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CartApiService {
  static String get baseUrl {
    final url = dotenv.env['BASE_URL'];
    if (url == null) {
      throw Exception("BASE_URL not found in .env file");
    }
    return url;
  }

  static Future<Map<String, dynamic>> getCartByUserId(String accessToken, String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/cart/$userId'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch cart',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> addToCart({
    required String accessToken,
    required String userId,
    required String productId,
    required String variantId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/cart/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken'
        },
        body: jsonEncode({
          'userId': userId,
          'productId': productId,
          'variantId': variantId,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': jsonDecode(response.body)['message']};
      } else {
        return {
          'success': false,
          'message': 'Failed to add to cart',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> reduceItemQuantity({
    required String accessToken,
    required String userId,
    required String productId,
    required String variantId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/cart/reduce'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken'
        },
        body: jsonEncode({
          'userId': userId,
          'productId': productId,
          'variantId': variantId,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': jsonDecode(response.body)['message']};
      } else {
        return {
          'success': false,
          'message': 'Failed to reduce quantity',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> increaseItemQuantity({
    required String accessToken,
    required String userId,
    required String productId,
    required String variantId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/cart/increase'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken'
        },
        body: jsonEncode({
          'userId': userId,
          'productId': productId,
          'variantId': variantId,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': jsonDecode(response.body)['message']};
      } else {
        return {
          'success': false,
          'message': 'Failed to increase quantity',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateCartItemQuantity({
    required String accessToken,
    required String userId,
    required String productId,
    required String variantId,
    required int quantity,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/cart/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken'
        },
        body: jsonEncode({
          'userId': userId,
          'productId': productId,
          'variantId': variantId,
          'quantity': quantity,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': jsonDecode(response.body)['message']};
      } else {
        return {
          'success': false,
          'message': 'Failed to update quantity',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteCart(String accessToken, String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/cart?userId=$userId'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': jsonDecode(response.body)['message']};
      } else {
        return {
          'success': false,
          'message': 'Failed to delete cart',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
