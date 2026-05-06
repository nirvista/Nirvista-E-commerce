import 'package:get/get.dart';
import 'package:pet_shop/base/get/home_controller.dart';
import 'package:pet_shop/base/get/storage.dart';
import 'package:pet_shop/woocommerce/model/user.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class LoginDataController extends GetxController {
  var isDataLoading = false.obs;
  var currentUser = Rxn<User>();

  // WooCustomer? customer;
  HomeController storageController = Get.find<HomeController>();
  @override
  void onInit() {
    super.onInit();
    loadCurrentUser();
  }
  void loadCurrentUser() async {
    try {
      if (!getRememberMe()) {
        print("Remember me is false, logging out on app start.");
        logout();
        return;
      }
      Map<String, dynamic>? userData = getCurrentUserNew();
      if (userData != null) {
        currentUser.value = User.fromJson(userData);
        currentUser.refresh();
      }
      
      String? accessToken = getAccessToken();
      if (accessToken != null) {
        await dotenv.load(fileName: ".env");
        String? baseUrl = dotenv.env['BASE_URL']?.trim();
        
        if (baseUrl != null && baseUrl.isNotEmpty) {
          final response = await http.get(
            Uri.parse('$baseUrl/api/auth/me'),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          );
          
          if (response.statusCode == 200) {
            final Map<String, dynamic> responseData = jsonDecode(response.body);
            if (responseData['success'] == true && responseData['data'] != null) {
              final User apiUser = User.fromJson(responseData['data']);
              currentUser.value = apiUser;
              // Save the fresh data to local storage
              setCurrentUserNew(apiUser.toJson());
              currentUser.refresh();
            }
          } else if (response.statusCode == 401 || response.statusCode == 403) {
            print('Token expired or invalid: ${response.statusCode}. Logging out.');
            logout();
          } else {
            print('Failed to load user data: ${response.statusCode}');
          }
        } else {
          print('BASE_URL not found in .env file');
        }
      }
    } catch (e) {
      print("Error loading current user: $e");
      currentUser.value = null;
    }
  }
  void saveUser(User user,
      {String? accessToken, String? refreshToken, bool rememberMe = false}) {
    currentUser.value = user;
    setCurrentUserNew(user.toJson());
    if (accessToken != null) {
      setAccessToken(accessToken);
    }
    if (refreshToken != null) {
      setRefreshToken(refreshToken);
    }
    setLoggedIn(true);
    setRememberMe(rememberMe);
    update();
  }
  void logout() {
    currentUser.value = null;
    clearUserData();
    setLoggedIn(false);
    update();
  }
  bool get isLoggedIn => getBool(keyLoggedIn) ?? false;
  
  String? get accessToken => getAccessToken();
  
  String? get refreshToken => getRefreshToken();
  }



  // loginUser(WooCommerce wooCommerce, String userName, String password) async {
  //   isDataLoading.value = true;
  //   var result =
  //       await wooCommerce.loginCustomer(username: userName, password: password);
  //   print("getresult===${result.toString()}---${result is WooCustomer}");
  //   if (result is WooCustomer) {
  //     storageController.currentCustomer = result;
  //     setCurrentUser(storageController.currentCustomer);
  //     update();
  //     isDataLoading.value = false;
  //   } else {
  //     try {
  //       if (result["success"] == false) {
  //               showCustomToast(result["message"]);
  //             }
  //     } catch (e) {
  //       print(e);
  //     }
  //     isDataLoading.value = false;
  //   }
  //   // Future.delayed(Duration(seconds: 5),() {
  //   //   isDataLoading.value = false;
  //   // },);
  //   print("checkval===${result.toString()}");
  // }

