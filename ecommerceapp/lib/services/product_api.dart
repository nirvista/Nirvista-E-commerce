import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProductApiService {
  static String get baseUrl {
    final url = dotenv.env['BASE_URL'];
    if (url == null) {
      throw Exception("BASE_URL not found in .env file");
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

}
