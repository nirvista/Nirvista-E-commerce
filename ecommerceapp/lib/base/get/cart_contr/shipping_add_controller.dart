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
    final token = loginController.accessToken;
    if (token == null || token.isEmpty) return;

    isLoading.value = true;
    try {
      final res = await AddressApiService.getUserAddresses(token);
      if (res['success'] && res['data'] != null) {
        final list = (res['data'] as List).map((e) => AddressModel.fromJson(e)).toList();
        addresses.assignAll(list);
        
        // Auto-select default if none selected
        if (selectedAddress.value == null) {
          final def = list.where((a) => a.isDefaultShipping == true).toList();
          if (def.isNotEmpty) {
            selectedAddress.value = def.first;
          } else if (list.isNotEmpty) {
            selectedAddress.value = list.first;
          }
        }
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
