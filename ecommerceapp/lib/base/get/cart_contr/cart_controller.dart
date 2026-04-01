import 'package:get/get.dart';

import '../../../app/model/cart_other_info.dart';
import '../../../app/model/order_create_model.dart';

class CartController extends GetxController {
  var cartItems = <LineItems>[];
  List<ShippingLines> shippingLines = <ShippingLines>[];
  var coupon = <CouponLines>[];
  double promoPrice = 0;
  var cartOtherInfoList = <CartOtherInfo>[];
  RxBool inStock = true.obs;

  void clearPromoPrice() {
    promoPrice = 0;
  }

  void clearCart()
  {
    cartItems=[];
    shippingLines=[];
    coupon=[];
    promoPrice=0;
    cartOtherInfoList=[];
    inStock.value=true;
    update();
  }


  void addShippingLines(ShippingLines vals)
  {

    shippingLines=[];
    shippingLines.add(vals);

  }

  void createLineItems() {
    cartItems.clear();
    for (var element in cartOtherInfoList) {
      cartItems.add(LineItems(
        productId: element.productId,
        quantity: element.quantity,
        variationId: element.variationId,
      ));
    }
  }

  double updatePrice(double value) {
    promoPrice = value;
    update();
    return promoPrice;
  }

  void addCoupon(CouponLines couponLines) {
    coupon.add(couponLines);
    update();
  }

  void addItemInfo(CartOtherInfo cart) {
    cartOtherInfoList.add(cart);
    createLineItems();
    update();
  }

  void removeItemInfo(String name) {
    try {
      int? id;

      for (var element in cartOtherInfoList) {
        if (element.productName!.contains(name)) {
          id = element.productId;
        }
      }

      // Remove from cart other info list
      final itemToRemove = cartOtherInfoList
          .firstWhere((element) => element.productName == name, orElse: () => CartOtherInfo());
      if (itemToRemove.productName != null) {
        cartOtherInfoList.remove(itemToRemove);
      }

      // Remove from cart items
      if (id != null) {
        final lineItemToRemove = cartItems
            .firstWhere((element) => element.productId == id, orElse: () => LineItems());
        if (lineItemToRemove.productId != null) {
          cartItems.remove(lineItemToRemove);
        }
      }
      update();
    } catch (e) {
      print("Error removing item: $e");
    }
  }

  double cartTotalPriceF(quantity) {
    double cartTotalPrice = 0;
    for (var element in cartOtherInfoList) {
      cartTotalPrice = cartTotalPrice +
          (element.productPrice!.toDouble() * element.quantity!.toDouble());
    }
    return cartTotalPrice;
  }


  void increaseQuantity(int index) {
    if (index >= 0 && index < cartOtherInfoList.length) {
      cartOtherInfoList[index].quantity =
          cartOtherInfoList[index].quantity!.toInt() + 1;
      createLineItems();
      update();
    }
  }

  void decreaseQuantity(int index) {
    if (index >= 0 && index < cartOtherInfoList.length) {
      cartOtherInfoList[index].quantity =
          cartOtherInfoList[index].quantity!.toInt() - 1;
      createLineItems();
      update();
    }
  }

  @override
  void onInit() {
    super.onInit();
  }
}
