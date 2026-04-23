import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../app/model/api_models.dart';

class ReviewApiService {
  static String get baseUrl {
    final url = dotenv.env['BASE_URL']?.trim();
    if (url == null) {
      throw Exception("BASE_URL not found in .env file");
    }
    return url;
  }

  static Future<Map<String, dynamic>> createReview({
    required String accessToken,
    required String productId,
    required String userId,
    required String headline,
    required String comment,
    required int rating,
    List<String> media = const [],
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/products/$productId/reviews'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'x-client-type': 'mobile',
        },
        body: jsonEncode({
          'productId': productId,
          'userId': userId,
          'headline': headline,
          'comment': comment,
          'rating': rating,
          'media': media,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        String msg = 'Failed to submit review';
        try {
          msg = jsonDecode(response.body)['message'] ?? msg;
        } catch (_) {}
        return {
          'success': false,
          'message': msg,
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getProductReviews(String productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/products/$productId/reviews'),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch reviews',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getUserReviews(String accessToken, String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/reviews/user/$userId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch user reviews',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
