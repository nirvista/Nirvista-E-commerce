import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static String get baseUrl{
    final url = dotenv.env['BASE_URL'];
    if(url == null){
      throw Exception("BASE_URL not found in .env file");
    }
    return url;
  }

//SIGN UP

  static Future<Map<String,dynamic>>userSignup({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String phone,
    required String userRole,
  })async{
    try{
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type':'application/json'},
        body: jsonEncode({
          'name':name,
          'email':email,
          'password':password,
          'confirmPassword':confirmPassword,
          'phone':phone,
          'userRole':userRole,
        })
      );
      if (response.statusCode == 201 || response.statusCode == 200){
        return{
          'success':true,
          'data':jsonDecode(response.body),
        };
      }else{
        return{
          'success':false,
          'message':jsonDecode(response.body)['message'] ?? 'Signup failed',
        };
      }
    }catch (e, stackTrace) {
        print("Error: $e");
        print("StackTrace: $stackTrace");

    return {
      'success': false,
      'message': e.toString(),
    };
  }
  }
  //login

  static Future<Map<String,dynamic>>userLogin({
    required String email,
    required String password,
  })async{
    try{
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email':email,
          'password':password,
        })
      );
      if (response.statusCode == 200){
        return {
          'success':true,
          'data':jsonDecode(response.body),
        };
      }else{
        return {
          'success':false,
          'message':jsonDecode(response.body)['message'] ?? 'Login failed',
        };
      }
    }catch(e){
      return{
        'success':false,
        'message':'Error:$e',
      };
    }
  }
}
