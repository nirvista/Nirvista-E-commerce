import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pet_shop/app/model/api_models.dart';

import 'package:dotted_line/dotted_line.dart';
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
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shopping_cart_outlined, size: 56.w, color: accentColor.withOpacity(0.5)),
          ),
          24.h.verticalSpace,
          getCustomFont("Your Cart is Empty", 20, getFontColor(context), 1,
              fontWeight: FontWeight.w800, textAlign: TextAlign.center),
          10.h.verticalSpace,
          getCustomFont("Looks like you haven't added\nanything to your cart yet.",
              13, getFontGreyColor(context), 3,
              fontWeight: FontWeight.w400, textAlign: TextAlign.center),
          28.h.verticalSpace,
          GestureDetector(
            onTap: () {
              final controller = Get.find<BottomItemSelectionController>();
              controller.changePos(0);
              Constant.sendToNext(context, homeScreenRoute);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 14.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF14B8A6), Color(0xFF0D9488), Color(0xFF0F766E)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12.w),
                boxShadow: [
                  BoxShadow(color: accentColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: getCustomFont("Start Shopping", 14, Colors.white, 1, fontWeight: FontWeight.w700),
            ),
          ),
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
    String img = item.displayImage;

    return GestureDetector(
      onTap: () {
        if (item.product != null) {
          Constant.sendToNext(context, productDetailScreenRoute, arguments: item.product);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: getCardColor(context),
          borderRadius: BorderRadius.circular(16.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(12.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(12.w),
              child: Container(
                width: 100.w,
                height: 100.w,
                color: getGreyCardColor(context),
                child: img.isNotEmpty
                    ? Image.network(
                        img,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported_outlined, size: 28.w, color: getFontGreyColor(context)),
                      )
                    : Icon(Icons.shopping_bag_outlined, size: 28.w, color: getFontGreyColor(context)),
              ),
            ),
            SizedBox(width: 14.w),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: getCustomFont(name, 14, getFontColor(context), 2, fontWeight: FontWeight.w700),
                      ),
                      GestureDetector(
                        onTap: () => _confirmDeleteItem(context, item),
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.delete_outline, size: 18.w, color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  if (variantName.isNotEmpty)
                    Wrap(
                      spacing: 6.w,
                      children: variantName.split(",").map((v) => Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: getGreyCardColor(context),
                          borderRadius: BorderRadius.circular(20.w),
                        ),
                        child: getCustomFont(v.trim(), 10, getFontGreyColor(context), 1, fontWeight: FontWeight.w600),
                      )).toList(),
                    ),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      getCustomFont("₹${price.toStringAsFixed(0)}", 18, getAccentColor(context), 1, fontWeight: FontWeight.w800),
                      // Quantity controls
                      Container(
                        height: 34.h,
                        decoration: BoxDecoration(
                          color: getGreyCardColor(context),
                          borderRadius: BorderRadius.circular(25.w),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => cartController.decreaseQuantity(item.productId, item.variantId),
                              child: Container(
                                width: 34.w,
                                height: 34.h,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: dividerColor.withOpacity(0.5)),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                                ),
                                child: Icon(Icons.remove, size: 14.w, color: getFontColor(context)),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12.w),
                              child: getCustomFont("${item.quantity}", 14, getFontColor(context), 1, fontWeight: FontWeight.w800),
                            ),
                            GestureDetector(
                              onTap: () {
                                // If availableStock is 0 but item is already in cart, it likely means the stock data is missing or not fetched yet.
                                // We only restrict if availableStock is clearly greater than 0 and the limit is actually reached.
                                if (item.variant != null && item.variant!.availableStock > 0 && item.quantity >= item.variant!.availableStock) {
                                  showCustomToast("Maximum available stock reached");
                                  return;
                                }
                                cartController.increaseQuantity(item.productId, item.variantId);
                              },
                              child: Container(
                                width: 34.w,
                                height: 34.h,
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: accentColor.withOpacity(0.2), blurRadius: 4)],
                                ),
                                child: Icon(Icons.add, size: 14.w, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteItem(BuildContext context, CartItemModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.w)),
        title: Text("Remove Item", style: TextStyle(color: getFontColor(context), fontWeight: FontWeight.w700, fontSize: 16.sp)),
        content: Text("Are you sure you want to remove this item from your cart?", style: TextStyle(color: getFontGreyColor(context), fontSize: 13.sp)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("Cancel", style: TextStyle(color: getFontGreyColor(context)))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Remove", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirmed == true) {
      await cartController.removeItem(item.productId, item.variantId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: Obx(() {
        if (cartController.isLoading.value && cartController.cartModel.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (cartController.cartCount > 0) {
          return Column(
            children: [
              // ── Scrollable cart content ──
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                  children: [
                    // Cart items
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: cartController.cartCount,
                      separatorBuilder: (_, __) => SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        CartItemModel cartItem = cartController.cartModel.value!.items[index];
                        return _buildRealCartItem(context, cartItem);
                      },
                    ),

                    SizedBox(height: 16.h),

                    // ── Coupon row ──
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: getCardColor(context),
                        borderRadius: BorderRadius.circular(12.w),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF0D9488).withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w),
                              decoration: getButtonDecoration(Colors.transparent, withCorners: true, corner: 10.h, withBorder: true, borderColor: black20),
                              height: 46.h,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      onChanged: (value) {},
                                      controller: couponController,
                                      cursorColor: getFontColor(context),
                                      style: buildTextStyle(context, getFontColor(context), FontWeight.w400, 14),
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.zero,
                                        isDense: true,
                                        isCollapsed: true,
                                        floatingLabelBehavior: FloatingLabelBehavior.never,
                                        border: InputBorder.none,
                                        hintText: "Coupon Code",
                                        hintMaxLines: 1,
                                        hintStyle: buildTextStyle(context, black40, FontWeight.w400, 14),
                                      ),
                                    ),
                                  ),
                                  GetBuilder<CartController>(
                                    init: CartController(),
                                    builder: (controller) {
                                      return GestureDetector(
                                        onTap: () async {},
                                        child: getCustomFont("Apply", 14, getAccentColor(context), 1, fontWeight: FontWeight.w600),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          getHorSpace(12.w),
                          InkWell(
                            onTap: () => Constant.sendToNext(context, couponsScreenRoute),
                            child: getCustomFont("View all", 13, black40, 1, fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 12.h),

                    // ── Order Summary ──
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: getCardColor(context),
                        borderRadius: BorderRadius.circular(14.w),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Price Details", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: getFontColor(context))),
                          SizedBox(height: 16.h),
                          _buildSummaryRow(context, "Listing price", "₹${cartController.originalSubTotal.toStringAsFixed(0)}", isStrikethrough: true),
                          SizedBox(height: 12.h),
                          _buildSummaryRow(context, "Special price", "₹${cartController.cartSubTotal.toStringAsFixed(0)}", isAccent: true),
                          SizedBox(height: 12.h),
                          _buildSummaryRow(context, "Item discount", "-₹${cartController.itemSavings.toStringAsFixed(0)}", isAccent: true),
                          SizedBox(height: 12.h),
                          _buildSummaryRow(context, "Total fees", "₹0"),
                          if (cartController.promoPrice.value > 0) ...[
                            SizedBox(height: 12.h),
                            _buildSummaryRow(context, "Other discount", "-₹${cartController.promoPrice.value.toStringAsFixed(0)}", isAccent: true),
                          ],
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            child: DottedLine(dashColor: dividerColor, dashLength: 4, lineThickness: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Total amount", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: getFontColor(context))),
                              Text("₹${cartController.cartTotal.toStringAsFixed(0)}",
                                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900, color: getFontColor(context))),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 8.h),

                    // SizedBox(height: 8.h),
                  ],
                ),
              ),

              // ── Checkout Button ──
              Container(
                padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h),
                color: getScaffoldColor(context),
                child: GestureDetector(
                  onTap: () {
                    if (loginController.currentUser.value != null && loginController.currentUser.value!.id != null) {
                      Constant.sendToNext(context, checkoutShippingScreenRoute);
                    } else {
                      Constant.sendToNext(context, loginRoute);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF14B8A6), Color(0xFF0D9488), Color(0xFF0F766E)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14.w),
                      boxShadow: [
                        BoxShadow(color: accentColor.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("${cartController.cartCount} item${cartController.cartCount > 1 ? 's' : ''}  •  ₹${cartController.cartTotal.toStringAsFixed(0)}",
                            style: TextStyle(color: Colors.white70, fontSize: 16.sp, fontWeight: FontWeight.w500)),
                        SizedBox(width: 12.w),
                        Container(width: 1, height: 16.h, color: Colors.white30),
                        SizedBox(width: 12.w),
                        Text("Checkout", style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w800)),
                        SizedBox(width: 6.w),
                        Icon(Icons.arrow_forward_ios, color: Colors.white, size: 13.w),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        } else {
          return emptyCard(context);
        }
      }),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String title, String value, {bool isAccent = false, bool isGreen = false, bool isStrikethrough = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        getCustomFont(title, 13, getFontGreyColor(context), 1, fontWeight: FontWeight.w500),
        getCustomFont(value, 14, isGreen ? Colors.green : (isAccent ? getAccentColor(context) : getFontColor(context)), 1, 
            fontWeight: (isAccent || isGreen) ? FontWeight.w700 : FontWeight.w600,
            decoration: isStrikethrough ? TextDecoration.lineThrough : TextDecoration.none),
      ],
    );
  }
}

