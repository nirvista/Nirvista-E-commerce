import 'package:get/get.dart';
import '../../app/model/api_models.dart';
import '../../services/order_api.dart';
import 'login_data_controller.dart';

class GlobalOrderController extends GetxController {
  var userOrders = <OrderModel>[].obs;
  var isLoading = false.obs;
  var errorMessage = "".obs;

  Future<void> fetchOrders() async {
    isLoading.value = true;
    errorMessage.value = "";
    try {
      final loginController = Get.find<LoginDataController>();
      final token = loginController.accessToken;
      if (token == null || token.isEmpty) {
        isLoading.value = false;
        errorMessage.value = "Please login to view orders";
        return;
      }
      final res = await OrderApiService.getUserOrders(token);
      if (res['success'] && res['data'] != null) {
        final list = (res['data'] as List).map((e) => OrderModel.fromJson(e)).toList();
        userOrders.value = list;
      } else {
        errorMessage.value = res['message'] ?? "Failed to fetch orders";
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void updateOrderStatusLocally(String orderId, String newStatus) {
    int index = userOrders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      userOrders[index].orderStatus = newStatus;
      userOrders.refresh();
    }
  }
}
