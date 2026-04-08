import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CategoryApiService {
  static String get baseUrl {
    final url = dotenv.env['BASE_URL'];
    if (url == null) {
      throw Exception("BASE_URL not found in .env file");
    }
    return url;
  }

  // Get All Categories
  static Future<Map<String, dynamic>> getAllCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/categories'));
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
          'message': jsonDecode(response.body)['message'] ?? 'Failed to fetch categories',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get Category By ID
  static Future<Map<String, dynamic>> getCategoryById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/categories/$id'));
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
          'message': jsonDecode(response.body)['message'] ?? 'Failed to fetch category details',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get Products By Category ID
  static Future<Map<String, dynamic>> getProductsByCategory(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/categories/$id/products'));
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
          'message': jsonDecode(response.body)['message'] ?? 'Failed to fetch products for category',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
