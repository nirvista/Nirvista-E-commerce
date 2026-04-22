import 'package:get/get.dart';
import 'package:collection/collection.dart';
import '../../app/model/api_models.dart';
import '../../services/order_api.dart';
import 'login_data_controller.dart';
import '../../services/product_api.dart';

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
      if (res['success']) {
        final data = res['data'];
        if (data is List) {
          final List<OrderModel> list = data.map((e) => OrderModel.fromJson(e)).toList();
          userOrders.value = list;
        } else {
          errorMessage.value = "Format error: Expected a list of orders.";
          userOrders.clear();
        }
      } else {
        errorMessage.value = res['message'] ?? "Failed to fetch orders";
        userOrders.clear();
      }
    } catch (e) {
      errorMessage.value = "System error: ${e.toString()}";
      userOrders.clear();
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
