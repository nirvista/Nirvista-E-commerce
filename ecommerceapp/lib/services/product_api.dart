import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProductApiService {
  static String get baseUrl {
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
          'message': jsonDecode(response.body)['message'] ??
              'Failed to fetch products',
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
          'message':
              jsonDecode(response.body)['message'] ?? 'Failed to fetch product',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get New Arrivals
  static Future<Map<String, dynamic>> getNewArrivals() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/products/new-arrivals'));
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
              'Failed to fetch new arrivals',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get Top Rated Products
  static Future<Map<String, dynamic>> getTopRatedProducts() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/products/top-rated'));
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
              'Failed to fetch top rated products',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get Related Products
  static Future<Map<String, dynamic>> getRelatedProducts(String id) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/products/$id/related'));
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
              'Failed to fetch related products',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get Product Variants
  static Future<Map<String, dynamic>> getProductVariants(String id) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/products/$id/variants'));
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
              'Failed to fetch product variants',
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
      final Map<String, dynamic> flatParams = {};
      queryParams.forEach((key, value) {
        if (value is List) {
          flatParams[key] = value.map((v) => v.toString()).toList();
        } else {
          flatParams[key] = value.toString();
        }
      });

      // Try the primary search endpoint first
      var uri = Uri.parse('$baseUrl/api/products/search')
          .replace(queryParameters: flatParams);
      
      print('=== SEARCH ATTEMPT 1 (/search) ===');
      print('URL: $uri');
      
      var response = await http.get(uri);
      
      // DEBUG: Log focused first-result data
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final results = decoded['data'] ?? decoded['products'] ?? decoded['results'];
        if (results is List && results.isNotEmpty) {
          print('=== SEARCH RESULT PREVIEW (FIRST ITEM) ===');
          print(jsonEncode(results.first));
        } else {
          print('=== SEARCH RESPONSE BODY ===');
          print(response.body);
        }
      }
      // as many backends use the same endpoint for listing and filtering.
      bool useFallback = false;
      if (response.statusCode != 200) {
        useFallback = true;
      } else {
        final data = jsonDecode(response.body);
        final results = data['data'] ?? data['products'] ?? data['results'];
        if (results == null || (results is List && results.isEmpty)) {
            useFallback = true;
        }
      }

      if (useFallback) {
        print('=== SEARCH ATTEMPT 2 (/products fallback) ===');
        uri = Uri.parse('$baseUrl/api/products').replace(queryParameters: flatParams);
        print('URL: $uri');
        response = await http.get(uri);
      }

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        
        dynamic results;
        if (decodedResponse is List) {
          results = decodedResponse;
        } else if (decodedResponse is Map) {
          results = decodedResponse['data'] ?? decodedResponse['products'] ?? decodedResponse['results'] ?? decodedResponse;
        }

        return {
          'success': true,
          'data': results,
          'message': decodedResponse is Map ? decodedResponse['message'] : null,
        };
      } else {
        return {
          'success': false,
          'message': jsonDecode(response.body)['message'] ??
              'Failed to search products',
        };
      }
    } catch (e) {
      print('=== SEARCH API CRASH ===');
      print(e);
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
