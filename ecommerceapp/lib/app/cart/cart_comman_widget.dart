import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pet_shop/app/model/api_models.dart';

import '../../base/color_data.dart';
import '../../base/constant.dart';
import '../../base/get/bottom_selection_controller.dart';
import '../../base/get/cart_contr/cart_controller.dart';
import '../../base/get/login_data_controller.dart';
import '../../base/get/route_key.dart';
import '../../base/widget_utils.dart';

class CartCommonWidget extends StatefulWidget {

  const CartCommonWidget({Key? key}) : super(key: key);

  @override
  State<CartCommonWidget> createState() => _CartCommonWidgetState();
}

class _CartCommonWidgetState extends State<CartCommonWidget> {
  String inStock = 'instock';

  Widget emptyCard(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          getSvgImageWithSize(context, "empty_card.svg", 140.h, 140.h,
              fit: BoxFit.fill),
          5.h.verticalSpace,
          getCustomFont("Your cart is empty", 22, getFontColor(context), 1,
                  textAlign: TextAlign.center, fontWeight: FontWeight.w700)
              .marginSymmetric(vertical: 20.h),
          SizedBox(
            width: 174.h,
            child: getButtonFigma(context, Colors.transparent, true,
                "Explore Now", getAccentColor(context), () {
                  final controller = Get.find<BottomItemSelectionController>();
                  controller.changePos(0);
                      Constant.sendToNext(context, homeScreenRoute);

            }, EdgeInsets.zero,
                isBorder: true, borderColor: getAccentColor(context)),
          )
        ],
      ),
    );
  }

  TextEditingController couponController = TextEditingController();
  final cartController = Get.find<CartController>();
  final loginController = Get.find<LoginDataController>();
  final bottomController = Get.find<BottomItemSelectionController>();

  RxInt selectedIndex = 0.obs;

  @override
  void initState() {
    super.initState();
    // Refresh cart when opened
    cartController.fetchCart();
  }

  Widget _buildRealCartItem(BuildContext context, CartItemModel item) {
    String name = item.product?.title ?? "Unknown Product";
    String variantName = item.variant?.variantName ?? "";
    double price = item.variant?.discountPrice != null && item.variant!.discountPrice! > 0 
           ? item.variant!.discountPrice! 
           : (item.variant?.price ?? 0.0);
    String img = (item.variant?.images.isNotEmpty == true) ? item.variant!.images.first : (item.product?.imageUrl ?? "");

    return GestureDetector(
      onTap: () => Constant.sendToNext(context, productDetailScreenRoute),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
               borderRadius: BorderRadius.circular(8.w),
               image: img.isNotEmpty ? DecorationImage(image: NetworkImage(img), fit: BoxFit.cover) : null,
               color: Colors.grey.shade200,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 getCustomFont(name, 16, getFontColor(context), 2, fontWeight: FontWeight.w600),
                 SizedBox(height: 4.h),
                 getCustomFont(variantName, 12, getFontHint(context), 1),
                 SizedBox(height: 8.h),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     getCustomFont("₹${price.toStringAsFixed(0)}", 16, getAccentColor(context), 1, fontWeight: FontWeight.w700),
                     Row(
                       children: [
                         InkWell(
                           onTap: () => cartController.decreaseQuantity(item.productId, item.variantId),
                           child: Container(
                             padding: EdgeInsets.all(4.w),
                             child: Icon(Icons.remove_circle_outline, size: 24.w, color: getFontHint(context)),
                           )
                         ),
                         SizedBox(width: 8.w),
                         getCustomFont("${item.quantity}", 16, getFontColor(context), 1, fontWeight: FontWeight.bold),
                         SizedBox(width: 8.w),
                         InkWell(
                           onTap: () {
                             // Check for available stock before incrementing
                             if (item.variant != null && item.quantity >= item.variant!.availableStock) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(
                                   content: Text('Maximum available stock reached'),
                                   backgroundColor: Colors.orange,
                                   duration: Duration(seconds: 2),
                                 )
                               );
                               return;
                             }
                             cartController.increaseQuantity(item.productId, item.variantId);
                           },
                           child: Container(
                             padding: EdgeInsets.all(4.w),
                             child: Icon(Icons.add_circle_outline, size: 24.w, color: getAccentColor(context)),
                           )
                         ),
                       ],
                     )
                   ]
                 )
              ]
            )
          )
        ]
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: Obx(
          () {
            if (cartController.isLoading.value && cartController.cartModel.value == null) {
               return const Center(child: CircularProgressIndicator());
            }
            if (cartController.cartCount > 0) {
              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        Container(
                    padding: EdgeInsets.all(20.h),
                    margin: EdgeInsets.symmetric(vertical: 20.h),
                    color: getCardColor(context),
                    child: ListView.separated(
                      itemBuilder: (context, index) {
                        CartItemModel cartItem = cartController.cartModel.value!.items[index];
                        return _buildRealCartItem(context, cartItem);
                      },
                      itemCount: cartController.cartCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      separatorBuilder:
                          (BuildContext context, int index) {
                        return getDivider(setColor: Colors.grey.shade300).marginSymmetric(
                            vertical: 20.h);
                      },
                    ),
                  ),

                  Container(
                    color: getCardColor(context),
                    padding: EdgeInsets.all(20.h),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 18.h),
                            decoration: getButtonDecoration(
                                Colors.transparent,
                                withCorners: true,
                                corner: 12.h,
                                withBorder: true,
                              borderColor: black20
                            ),
                            height: 60.h,
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: TextField(
                                    onChanged: (value) {
                                    },
                                    controller: couponController,
                                    cursorColor:
                                    getFontColor(context),
                                    style: buildTextStyle(
                                        context,
                                        getFontColor(context),
                                        FontWeight.w400,
                                        16),
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.zero,
                                      isDense: true,
                                      isCollapsed: true,
                                      floatingLabelBehavior:
                                      FloatingLabelBehavior.never,
                                      border: InputBorder.none,
                                      hintText: "Coupon Code",
                                      hintMaxLines: 1,
                                      hintStyle: buildTextStyle(
                                          context,
                                          black40,
                                          FontWeight.w400,
                                          16),
                                    ),
                                  ),
                                ),
                                GetBuilder<CartController>(
                                  init: CartController(),
                                  builder: (controller) {
                                    return GestureDetector(
                                      onTap: () async {
                                        // Coupon logic implementation
                                      },
                                      child: getCustomFont(
                                        "Apply",
                                        16,
                                        getAccentColor(context),
                                        1,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  },
                                )
                              ],
                            ),
                          ),
                        ),
                        getHorSpace(24.h),
                        InkWell(
                          onTap: () {
                            Constant.sendToNext(
                                context, couponsScreenRoute);
                          },
                          child: getCustomFont(
                            "View all",
                            17,
                            black40,
                            1,
                            fontWeight: FontWeight.w400,
                            textAlign: TextAlign.start,
                          ),
                        )
                      ],
                    ),
                  ),

                  Container(
                    padding: EdgeInsets.all(20.h),
                    margin: EdgeInsets.symmetric(vertical: 20.h),
                    color: getCardColor(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildSubtotalRow(
                            context,
                            "Subtotal",
                            "₹${cartController.cartSubTotal.toStringAsFixed(0)}"),
                        getDivider(setColor: Colors.grey.shade300)
                            .marginSymmetric(vertical: 14.h),
                        buildSubtotalRow(
                            context,
                            "Discount",
                            "-₹${cartController.promoPrice.value.toStringAsFixed(0)}"),
                        getDivider(setColor: Colors.grey.shade300)
                            .marginSymmetric(vertical: 14.h),
                        buildTotalRow(
                          context,
                          "Total",
                          "₹${cartController.cartTotal.toStringAsFixed(0)}",
                        ),
                      ]
                    ),
                  ),
                  InkWell(
                     onTap: () async {
                        await cartController.clearCartAction();
                     },
                     child: Container(
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        child: getCustomFont("Clear Cart", 16, Colors.red, 1, fontWeight: FontWeight.w600)
                     )
                  ),
                  getVerSpace(20.h),
                      ],
                    ),
                  ),
                  Container(
                     color: getScaffoldColor(context),
                     padding: EdgeInsets.only(bottom: 30.h, top: 10.h),
                     child: getRowButtonFigma(
                        context,
                        getAccentColor(context),
                        true,
                        "${cartController.cartCount} item","₹${cartController.cartTotal.toStringAsFixed(0)}","Continue",
                        Colors.white,
                            () {
                               if (loginController.currentUser.value != null && loginController.currentUser.value!.id != null) {
                                  Constant.sendToNext(context, checkoutShippingScreenRoute);
                               } else {
                                  Constant.sendToNext(context, loginRoute);
                               }
                        },
                        EdgeInsets.symmetric(horizontal: 20.h)),
                  ),
                ],
              );
            } else {
              return emptyCard(context);
            }
          },
        )
    );
  }
}
