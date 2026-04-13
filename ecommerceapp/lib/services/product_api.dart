import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProductApiService {
  static String get baseUrl {
    final url = dotenv.env['BASE_URL']?.trim();
    if (url == null || url.isEmpty) {
      throw Exception('BASE_URL not found in .env file');
    }
    return url;
  }


  // Get All Products
  static Future<Map<String, dynamic>> getAllProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/products'));
      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        return {
          'success': true,
          'data': decodedResponse['data'],
          'message': decodedResponse['message'],
        };
      } else {
        return {
          'success': false,
          'message': jsonDecode(response.body)['message'] ?? 'Failed to fetch products',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get Single Product by ID
  static Future<Map<String, dynamic>> getProductById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/products/$id'));
      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        return {
          'success': true,
          'data': decodedResponse['data'],
          'message': decodedResponse['message'],
        };
      } else {
        return {
          'success': false,
          'message': jsonDecode(response.body)['message'] ?? 'Failed to fetch product',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get New Arrivals
  static Future<Map<String, dynamic>> getNewArrivals() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/products/new-arrivals'));
      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        return {
          'success': true,
          'data': decodedResponse['data'],
          'message': decodedResponse['message'],
        };
      } else {
        return {
          'success': false,
          'message': jsonDecode(response.body)['message'] ?? 'Failed to fetch new arrivals',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get Top Rated Products
  static Future<Map<String, dynamic>> getTopRatedProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/products/top-rated'));
      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        return {
          'success': true,
          'data': decodedResponse['data'],
          'message': decodedResponse['message'],
        };
      } else {
        return {
          'success': false,
          'message': jsonDecode(response.body)['message'] ?? 'Failed to fetch top rated products',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get Related Products
  static Future<Map<String, dynamic>> getRelatedProducts(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/products/$id/related'));
      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        return {
          'success': true,
          'data': decodedResponse['data'],
          'message': decodedResponse['message'],
        };
      } else {
        return {
          'success': false,
          'message': jsonDecode(response.body)['message'] ?? 'Failed to fetch related products',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get Product Variants
  static Future<Map<String, dynamic>> getProductVariants(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/products/$id/variants'));
      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        return {
          'success': true,
          'data': decodedResponse['data'],
          'message': decodedResponse['message'],
        };
      } else {
        return {
          'success': false,
          'message': jsonDecode(response.body)['message'] ?? 'Failed to fetch product variants',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Search Products with filters
  // Hits: GET /api/products/search?keyword=&categoryId=&brandId=&minPrice=&maxPrice=&minRating=&color=&size=&material=&sort=
  static Future<Map<String, dynamic>> searchProducts(
      Map<String, dynamic> queryParams) async {
    try {
      // Build query parameters — handles both single values and lists (multi-select)
      final Map<String, dynamic> flatParams = {};
      queryParams.forEach((key, value) {
        if (value is List) {
          // Uri supports repeated keys for lists e.g. ?color=Red&color=Blue
          flatParams[key] = value.map((v) => v.toString()).toList();
        } else {
          flatParams[key] = value.toString();
        }
      });

      final uri = Uri.parse('$baseUrl/api/products/search')
          .replace(queryParameters: flatParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        return {
          'success': true,
          'data': decodedResponse['data'],
          'message': decodedResponse['message'],
        };
      } else {
        return {
          'success': false,
          'message': jsonDecode(response.body)['message'] ??
              'Failed to search products',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}