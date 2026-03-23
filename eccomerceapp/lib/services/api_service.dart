import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api/auth';

//SIGN UP

  static Future<Map<String,dynamic>>userSignup({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String userType,
  })async{
    try{
      final response = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: {'Content-Type':'application/json'},
        body: jsonEncode({
          'name':name,
          'email':email,
          'password':password,
          'phone':phone,
          'userType':userType,
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
    }catch(e){
      return{
        'success':false,
        'message':'Error:$e'
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
        Uri.parse('$baseUrl/login'),
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
