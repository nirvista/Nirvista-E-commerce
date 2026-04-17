import 'package:get/get.dart';
import 'package:pet_shop/services/cart_api.dart';
import 'package:pet_shop/app/model/api_models.dart';
import 'package:pet_shop/base/get/login_data_controller.dart';

class CartController extends GetxController {
  Rx<CartModel?> cartModel = Rx<CartModel?>(null);
  RxBool isLoading = false.obs;
  RxDouble promoPrice = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _setupUserListener();
  }

  void _setupUserListener() {
    final loginController = Get.find<LoginDataController>();
    ever(loginController.currentUser, (user) {
      if (user != null) {
        // Fresh login or user update - fetch new cart
        fetchCart();
      } else {
        // Logout - clear cart
        cartModel.value = null;
        update();
      }
    });

    // Initial fetch if already logged in
    if (loginController.currentUser.value != null) {
      fetchCart();
    }
  }

  Future<void> fetchCart() async {
    final loginController = Get.find<LoginDataController>();
    final user = loginController.currentUser.value;
    if (user == null || user.id == null) {
      cartModel.value = null;
      update();
      return;
    }

    isLoading.value = true;
    final res = await CartApiService.getCartByUserId(loginController.accessToken ?? '', user.id!);
    isLoading.value = false;

    if (res['success'] && res['data'] != null) {
      cartModel.value = CartModel.fromJson(res['data']);
    } else {
      cartModel.value = null;
    }
    update();
  }

  Future<bool> addToCart(String productId, String variantId) async {
    final loginController = Get.find<LoginDataController>();
    final user = loginController.currentUser.value;
    if (user == null || user.id == null) return false;

    final res = await CartApiService.addToCart(
      accessToken: loginController.accessToken ?? '',
      userId: user.id!,
      productId: productId,
      variantId: variantId,
    );
    if (res['success']) {
      await fetchCart();
      return true;
    }
    return false;
  }

  Future<void> increaseQuantity(String productId, String variantId) async {
    final loginController = Get.find<LoginDataController>();
    final user = loginController.currentUser.value;
    if (user == null || user.id == null) return;

    final res = await CartApiService.increaseItemQuantity(
      accessToken: loginController.accessToken ?? '',
      userId: user.id!,
      productId: productId,
      variantId: variantId,
    );
    if (res['success']) {
      await fetchCart();
    }
  }

  Future<void> decreaseQuantity(String productId, String variantId) async {
    final loginController = Get.find<LoginDataController>();
    final user = loginController.currentUser.value;
    if (user == null || user.id == null) return;

    final res = await CartApiService.reduceItemQuantity(
      accessToken: loginController.accessToken ?? '',
      userId: user.id!,
      productId: productId,
      variantId: variantId,
    );
    if (res['success']) {
      await fetchCart();
    }
  }

  Future<void> clearCartAction() async {
    final loginController = Get.find<LoginDataController>();
    final user = loginController.currentUser.value;
    if (user == null || user.id == null) return;

    final res = await CartApiService.deleteCart(loginController.accessToken ?? '', user.id!);
    if (res['success']) {
      cartModel.value = null;
      update();
    }
  }

  double get cartSubTotal {
    if (cartModel.value == null) return 0.0;
    double total = 0.0;
    for (var item in cartModel.value!.items) {
      double price = item.variant?.discountPrice != null && item.variant!.discountPrice! > 0
          ? item.variant!.discountPrice!
          : (item.variant?.price ?? 0.0);
      total += (price * item.quantity);
    }
    return total;
  }

  double get cartTotal {
    // Add logic for tax, shipping, promo if needed
    // Simplified:
    return cartSubTotal - promoPrice.value;
  }

  int get cartCount {
    if (cartModel.value == null) return 0;
    return cartModel.value!.items.length;
  }
}
