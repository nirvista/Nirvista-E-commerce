import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static String get baseUrl {
    final rawUrl = dotenv.env['BASE_URL']?.trim();
    if (rawUrl == null || rawUrl.isEmpty) {
      throw Exception("BASE_URL not found in .env file");
    }
    final withoutTrailingSlash = rawUrl.replaceAll(RegExp(r'/+$'), '');
    if (withoutTrailingSlash.endsWith('/api')) {
      return withoutTrailingSlash.substring(0, withoutTrailingSlash.length - 4);
    }
    return withoutTrailingSlash;
  }

  static const String consumerKey = 'your_consumer_key_here';
  static const String consumerSecret = 'your_consumer_secret_here';

  static String get fallbackBaseUrl => 'http://127.0.0.1:5000';

  static bool _isFetchFailure(Object e) {
    final message = e.toString().toLowerCase();
    return message.contains('failed to fetch') ||
        message.contains('clientexception');
  }

  static Future<http.Response> _postWithFallback(
    String endpointPath,
    Map<String, String> headers,
    Map<String, dynamic> body,
  ) async {
    final primaryUri = Uri.parse('$baseUrl$endpointPath');
    try {
      return await http.post(
        primaryUri,
        headers: headers,
        body: jsonEncode(body),
      );
    } catch (e) {
      if (!_isFetchFailure(e)) rethrow;
      final fallbackUri = Uri.parse('$fallbackBaseUrl$endpointPath');
      return await http.post(
        fallbackUri,
        headers: headers,
        body: jsonEncode(body),
      );
    }
  }

//SIGN UP

  static Future<Map<String, dynamic>> userSignup({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String phone,
    required String userRole,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'x-client-type': 'mobile',
      };
      final payload = {
        'name': name,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
        'phone': phone,
        'userRole': userRole,
      };

      final response =
          await _postWithFallback('/api/auth/signup', headers, payload);
      if (response.statusCode == 201 || response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        return {
          'success': true,
          'data': decodedResponse['data'],
          'message': decodedResponse['message'],
        };
      } else {
        return {
          'success': false,
          'message': jsonDecode(response.body)['message'] ?? 'Signup failed',
        };
      }
    } catch (e, stackTrace) {
      print("Error: $e");
      print("StackTrace: $stackTrace");

      return {
        'success': false,
        'message':
            'Unable to reach server. Verify backend is running on BASE_URL or localhost:5000.',
      };
    }
  }
  //login

  static Future<Map<String, dynamic>> userLogin({
    required String email,
    required String password,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'x-client-type': 'mobile',
      };
      final payload = {
        'email': email,
        'password': password,
      };

      final response =
          await _postWithFallback('/api/auth/login', headers, payload);
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
          'message': jsonDecode(response.body)['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message':
            'Unable to reach server. Verify backend is running on BASE_URL or localhost:5000.',
      };
    }
  }
  static Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'x-client-type': 'mobile',
      };
      final payload = {'email': email};

      final response = await _postWithFallback('/api/auth/forgot-password', headers, payload);
      final decodedResponse = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'message': decodedResponse['message'] ?? 'Action failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to reach server. Please check your connection.',
      };
    }
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String password,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'x-client-type': 'mobile',
      };
      final payload = {'password': password};

      final response = await _postWithFallback('/api/auth/reset-password/$token', headers, payload);
      final decodedResponse = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'message': decodedResponse['message'] ?? 'Reset failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to reach server. Please check your connection.',
      };
    }
  }
}
