import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TagApiService {
  static String get baseUrl {
    final url = dotenv.env['BASE_URL'];
    if (url == null) {
      throw Exception("BASE_URL not found in .env file");
    }
    return url;
  }

  // Get All Tags
  static Future<Map<String, dynamic>> getAllTags() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/tags'));
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
          'message': jsonDecode(response.body)['message'] ?? 'Failed to fetch tags',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get Products By Tag ID
  static Future<Map<String, dynamic>> getProductsByTag(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/tags/$id/products'));
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
          'message': jsonDecode(response.body)['message'] ?? 'Failed to fetch products for tag',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
