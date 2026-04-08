import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BrandApiService {
  static String get baseUrl {
    final url = dotenv.env['BASE_URL'];
    if (url == null) {
      throw Exception("BASE_URL not found in .env file");
    }
    return url;
  }

  // Get All Brands
  static Future<Map<String, dynamic>> getAllBrands() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/brands'));
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
          'message': jsonDecode(response.body)['message'] ?? 'Failed to fetch brands',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get Brand By ID
  static Future<Map<String, dynamic>> getBrandById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/brands/$id'));
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
          'message': jsonDecode(response.body)['message'] ?? 'Failed to fetch brand details',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get Products By Brand ID
  static Future<Map<String, dynamic>> getProductsByBrand(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/brands/$id/products'));
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
          'message': jsonDecode(response.body)['message'] ?? 'Failed to fetch products for brand',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
