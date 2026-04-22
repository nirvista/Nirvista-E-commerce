import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pet_shop/app/cart/cart_comman_widget.dart';
import 'package:pet_shop/base/constant.dart';
import 'package:pet_shop/base/widget_utils.dart';
import 'package:pet_shop/base/get/cart_contr/cart_controller.dart';
import 'package:pet_shop/base/color_data.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _CartScreen();
  }
}

class _CartScreen extends State<CartScreen> {
  final cartController = Get.isRegistered<CartController>() ? Get.find<CartController>() : Get.put(CartController());

  backClick(BuildContext context) {
    Constant.backToPrev(context);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Constant.setupSize(context);

    return WillPopScope(
        child: Scaffold(
            backgroundColor: getScaffoldColor(context),
            body: Column(
              children: [
                // Identical header to TabCart
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF14B8A6), Color(0xFF0D9488), Color(0xFF0F766E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 12.h,
                    bottom: 16.h,
                    left: 20.w,
                    right: 20.w,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => backClick(context),
                        child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20.w),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          "Cart",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      Obx(() => cartController.cartCount > 0
                          ? GestureDetector(
                              onTap: () => _confirmClearCart(context, cartController),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white.withOpacity(0.6)),
                                  borderRadius: BorderRadius.circular(20.w),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.delete_outline, color: Colors.white, size: 15.w),
                                    SizedBox(width: 4.w),
                                    Text("Clear All",
                                        style: TextStyle(
                                            fontSize: 11.sp,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            )
                          : Container(
                              width: 36.w,
                              height: 36.w,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 18.w),
                            )),
                    ],
                  ),
                ),
                const Expanded(flex: 1, child: CartCommonWidget()),
              ],
            )),
        onWillPop: () async {
          backClick(context);
          return true;
        });
  }

  Future<void> _confirmClearCart(BuildContext context, CartController ctrl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.w)),
        title: Text("Clear Cart",
            style: TextStyle(color: getFontColor(context), fontWeight: FontWeight.w700, fontSize: 16.sp)),
        content: Text(
          "Are you sure you want to remove all items from your cart?",
          style: TextStyle(color: getFontGreyColor(context), fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Cancel", style: TextStyle(color: getFontGreyColor(context))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Clear All",
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) await ctrl.clearCartAction();
  }
}
