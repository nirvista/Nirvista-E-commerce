import 'package:get/get.dart';
import '../../../app/model/api_models.dart';
import '../../../services/address_api.dart';
import '../login_data_controller.dart';

class ShippingAddressController extends GetxController {
  String countryValue = "";
  String stateValue = "";
  String cityValue = "";

  RxList<AddressModel> addresses = <AddressModel>[].obs;
  Rx<AddressModel?> selectedAddress = Rx<AddressModel?>(null);
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _setupUserListener();
  }

  void _setupUserListener() {
    final loginController = Get.find<LoginDataController>();
    ever(loginController.currentUser, (user) {
      if (user != null) {
        // Fresh login or user update - fetch new addresses
        fetchAddresses();
      } else {
        // Logout - clear everything
        addresses.clear();
        selectedAddress.value = null;
      }
    });

    // Initial fetch if already logged in
    if (loginController.isLoggedIn) {
      fetchAddresses();
    }
  }

  Future<void> fetchAddresses() async {
    final loginController = Get.find<LoginDataController>();
    
    // Fallback/Retry logic: if token is null, wait briefly as it might be initializing
    if (loginController.accessToken == null) {
      print("ShippingAddressController: Access token is null, waiting 500ms before retry...");
      await Future.delayed(const Duration(milliseconds: 500));
    }

    final token = loginController.accessToken;
    if (token == null || token.isEmpty) {
      print("ShippingAddressController: Skipping fetch - no access token available.");
      return;
    }

    isLoading.value = true;
    print("ShippingAddressController: Fetching addresses for user...");
    try {
      final res = await AddressApiService.getUserAddresses(token);
      if (res['success'] && res['data'] != null) {
        final list = (res['data'] as List).map((e) => AddressModel.fromJson(e)).toList();
        addresses.assignAll(list);
        print("ShippingAddressController: Successfully fetched ${list.length} addresses.");
        
        // Auto-select default if none selected
        if (selectedAddress.value == null) {
          final def = list.where((a) => a.isDefaultShipping == true).toList();
          if (def.isNotEmpty) {
            selectedAddress.value = def.first;
            print("ShippingAddressController: Auto-selected default address: ${def.first.id}");
          } else if (list.isNotEmpty) {
            selectedAddress.value = list.first;
            print("ShippingAddressController: No default found, selected first address: ${list.first.id}");
          }
        }
      } else {
        print("ShippingAddressController: API failed - ${res['message']}");
      }
    } catch (e) {
      print("Error fetching addresses in shipping controller: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void selectAddress(AddressModel addr) {
    selectedAddress.value = addr;
  }

  changeCountry(String con) {
    countryValue = con;
    update();
  }

  changeState(String con) {
    stateValue = con;
    update();
  }

  changeCity(String con) {
    cityValue = con;
    update();
  }

  bool validateSelection() {
    return selectedAddress.value != null;
  }
}
