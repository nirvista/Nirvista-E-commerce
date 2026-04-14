import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pet_shop/base/color_data.dart';
import 'package:pet_shop/base/constant.dart';
import 'package:pet_shop/base/get/bottom_selection_controller.dart';
import 'package:pet_shop/base/widget_utils.dart';
import '../../../base/fetch_pixels.dart';
import 'package:pet_shop/services/wishlist_api.dart';
import 'package:pet_shop/base/get/wishlist_controller.dart';

class TabFavourite extends StatelessWidget {
  const TabFavourite({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Constant.setupSize(context);
    final double margin = FetchPixels.getDefaultHorSpaceFigma(context);

    // FIX: Use Get.find with a fallback put() so the page never crashes
    // even if the controller wasn't pre-registered in a binding.
    final wishlistController = Get.isRegistered<WishlistController>()
        ? Get.find<WishlistController>()
        : Get.put(WishlistController());

    final bottomController = Get.isRegistered<BottomItemSelectionController>()
        ? Get.find<BottomItemSelectionController>()
        : Get.put(BottomItemSelectionController());

    return Scaffold(
      backgroundColor: getScaffoldColor(context),
      body: SafeArea(
        child: Obx(() {
          final isLoading = wishlistController.isLoading.value;
          final hasError = wishlistController.hasError.value;
          final items = wishlistController.items;

          return Column(
            children: [
              _buildHeader(context, margin, wishlistController, items),
              Expanded(
                child: isLoading
                    ? _buildShimmerLoader(context, margin)
                    : hasError
                        ? _buildErrorState(context, wishlistController)
                        : items.isEmpty
                            ? _buildEmptyState(context, bottomController)
                            : _buildWishlistContent(
                                context, margin, wishlistController, items),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════

  Widget _buildHeader(
    BuildContext context,
    double margin,
    WishlistController ctrl,
    List<WishlistItem> items,
  ) {
    return Container(
      color: getCardColor(context),
      padding: EdgeInsets.symmetric(horizontal: margin, vertical: 14.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                getCustomFont("My Wishlist", 20, getFontColor(context), 1,
                    fontWeight: FontWeight.w800),
                if (items.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: getCustomFont(
                      "${items.length} item${items.length > 1 ? 's' : ''}",
                      12,
                      getFontGreyColor(context),
                      1,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          if (items.isNotEmpty)
            GestureDetector(
              onTap: () => _confirmClearWishlist(context, ctrl),
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: Colors.redAccent.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(20.w),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_outline,
                        color: Colors.redAccent, size: 16.w),
                    SizedBox(width: 4.w),
                    getCustomFont("Clear All", 11, Colors.redAccent, 1,
                        fontWeight: FontWeight.w600),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // LIST
  // ═══════════════════════════════════════════════════════

  Widget _buildWishlistContent(
    BuildContext context,
    double margin,
    WishlistController ctrl,
    List<WishlistItem> items,
  ) {
    return RefreshIndicator(
      onRefresh: ctrl.fetchWishlist,
      color: accentColor,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: margin, vertical: 16.h),
        // FIX: use items.length from the passed list, not ctrl.items directly,
        // to avoid stale reads inside the builder.
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          // FIX: guard against index out of range if list shrinks mid-scroll
          if (index >= items.length) return const SizedBox.shrink();
          final item = items[index];
          return _buildWishlistCard(context, item, index, ctrl);
        },
      ),
    );
  }

  Widget _buildWishlistCard(
    BuildContext context,
    WishlistItem item,
    int index,
    WishlistController ctrl,
  ) {
    final imageUrl =
        item.variant.images.isNotEmpty ? item.variant.images[0] : '';
    final isInStock = item.variant.status == 'in-stock';

    return Dismissible(
      key: ValueKey(item.id), // FIX: ValueKey is more robust than Key()
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16.w),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 28.w),
            SizedBox(height: 4.h),
            getCustomFont("Remove", 11, Colors.white, 1,
                fontWeight: FontWeight.w600),
          ],
        ),
      ),
      confirmDismiss: (_) async =>
          await _confirmRemoveDialog(context, item.product.title),
      onDismissed: (_) => ctrl.removeItem(item, index),
      child: Container(
        decoration: BoxDecoration(
          color: getCardColor(context),
          borderRadius: BorderRadius.circular(16.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12.w,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Product row ──
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.w),
                    child: Container(
                      width: 100.w,
                      height: 100.w,
                      color: getGreyCardColor(context),
                      child: imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Center(
                                child: CircularProgressIndicator(
                                    color: accentColor, strokeWidth: 2),
                              ),
                              errorWidget: (_, __, ___) => Icon(
                                  Icons.image_not_supported,
                                  size: 30.w,
                                  color: getFontGreyColor(context)),
                            )
                          : Icon(Icons.image_not_supported,
                              size: 30.w,
                              color: getFontGreyColor(context)),
                    ),
                  ),
                  SizedBox(width: 14.w),

                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        getCustomFont(item.product.title, 14,
                            getFontColor(context), 2,
                            fontWeight: FontWeight.w700),
                        SizedBox(height: 6.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: getGreyCardColor(context),
                            borderRadius: BorderRadius.circular(6.w),
                          ),
                          child: getCustomFont(item.variant.variantName, 11,
                              getFontGreyColor(context), 1,
                              fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 8.h),
                        getCustomFont(
                          "₹${item.variant.price.toStringAsFixed(0)}",
                          18,
                          accentColor,
                          1,
                          fontWeight: FontWeight.w800,
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            Container(
                              width: 8.w,
                              height: 8.w,
                              decoration: BoxDecoration(
                                color: isInStock
                                    ? greenColor
                                    : Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            getCustomFont(
                              isInStock ? "In Stock" : "Out of Stock",
                              11,
                              isInStock ? greenColor : Colors.redAccent,
                              1,
                              fontWeight: FontWeight.w600,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // X button
                  GestureDetector(
                    onTap: () => ctrl.removeItem(item, index),
                    child: Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        color: getGreyCardColor(context),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close,
                          size: 16.w,
                          color: getFontGreyColor(context)),
                    ),
                  ),
                ],
              ),
            ),

            // ── Divider ──
            Container(
              height: 1,
              color: dividerColor.withOpacity(0.5),
            ),

            // ── Action buttons ──
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              child: Row(
                children: [
                  // Remove
                  Expanded(
                    child: GestureDetector(
                      onTap: () => ctrl.removeItem(item, index),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.redAccent.withOpacity(0.4),
                              width: 1.2),
                          borderRadius: BorderRadius.circular(10.w),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.favorite_border,
                                color: Colors.redAccent, size: 16.w),
                            SizedBox(width: 6.w),
                            getCustomFont(
                                "Remove", 12, Colors.redAccent, 1,
                                fontWeight: FontWeight.w600),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),

                  // Move to Cart
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: isInStock
                          ? () => ctrl.moveToCart(item, index)
                          : null,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        decoration: BoxDecoration(
                          color: isInStock
                              ? accentColor
                              : getFontGreyColor(context).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10.w),
                          boxShadow: isInStock
                              ? [
                                  BoxShadow(
                                    color: accentColor.withOpacity(0.3),
                                    blurRadius: 8.w,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_outlined,
                                color: Colors.white, size: 16.w),
                            SizedBox(width: 6.w),
                            getCustomFont(
                              isInStock ? "Move to Cart" : "Out of Stock",
                              13,
                              Colors.white,
                              1,
                              fontWeight: FontWeight.w700,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // DIALOGS
  // ═══════════════════════════════════════════════════════

  Future<bool?> _confirmRemoveDialog(
      BuildContext context, String productTitle) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: getCardColor(context),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.w)),
        title: Text("Remove Item",
            style: TextStyle(
                color: getFontColor(context),
                fontWeight: FontWeight.w700,
                fontSize: 15.sp)),
        content: Text(
          'Remove "$productTitle" from wishlist?',
          style: TextStyle(
              color: getFontGreyColor(context), fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Cancel",
                style: TextStyle(color: getFontGreyColor(context))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Remove",
                style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearWishlist(
      BuildContext context, WishlistController ctrl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: getCardColor(context),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.w)),
        title: Text("Clear Wishlist",
            style: TextStyle(
                color: getFontColor(context),
                fontWeight: FontWeight.w700,
                fontSize: 16.sp)),
        content: Text(
          "Are you sure you want to remove all items from your wishlist?",
          style: TextStyle(
              color: getFontGreyColor(context), fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Cancel",
                style: TextStyle(color: getFontGreyColor(context))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Clear All",
                style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) await ctrl.clearWishlist();
  }

  // ═══════════════════════════════════════════════════════
  // SHIMMER LOADER
  // ═══════════════════════════════════════════════════════

  Widget _buildShimmerLoader(BuildContext context, double margin) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: margin, vertical: 16.h),
      itemCount: 4,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (_, __) => Container(
        height: 140.h,
        decoration: BoxDecoration(
          color: getCardColor(context),
          borderRadius: BorderRadius.circular(16.w),
        ),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              Container(
                width: 100.w,
                height: 100.w,
                decoration: BoxDecoration(
                  color: getGreyCardColor(context),
                  borderRadius: BorderRadius.circular(12.w),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                        height: 14.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: getGreyCardColor(context),
                          borderRadius: BorderRadius.circular(4.w),
                        )),
                    SizedBox(height: 8.h),
                    Container(
                        height: 12.h,
                        width: 80.w,
                        decoration: BoxDecoration(
                          color: getGreyCardColor(context),
                          borderRadius: BorderRadius.circular(4.w),
                        )),
                    SizedBox(height: 8.h),
                    Container(
                        height: 16.h,
                        width: 60.w,
                        decoration: BoxDecoration(
                          color: getGreyCardColor(context),
                          borderRadius: BorderRadius.circular(4.w),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // ERROR STATE
  // ═══════════════════════════════════════════════════════

  Widget _buildErrorState(
      BuildContext context, WishlistController ctrl) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 64.w,
                color: getFontGreyColor(context).withOpacity(0.4)),
            SizedBox(height: 16.h),
            getCustomFont(
                "Something went wrong", 16, getFontColor(context), 1,
                fontWeight: FontWeight.w700),
            SizedBox(height: 8.h),
            getCustomFont(
                "Please check your connection and try again.",
                13,
                getFontGreyColor(context),
                2,
                fontWeight: FontWeight.w400,
                textAlign: TextAlign.center),
            SizedBox(height: 24.h),
            GestureDetector(
              onTap: ctrl.fetchWishlist,
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(10.w),
                ),
                child: getCustomFont("Retry", 14, Colors.white, 1,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════════════════════

  Widget _buildEmptyState(BuildContext context,
      BottomItemSelectionController bottomController) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.favorite_outline_rounded,
                  size: 56.w, color: accentColor.withOpacity(0.5)),
            ),
            SizedBox(height: 24.h),
            getCustomFont(
                "Your Wishlist is Empty", 18, getFontColor(context), 1,
                fontWeight: FontWeight.w800),
            SizedBox(height: 10.h),
            getCustomFont(
              "Save items you love to your wishlist.\nReview them anytime and move to cart.",
              13,
              getFontGreyColor(context),
              3,
              fontWeight: FontWeight.w400,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 28.h),
            GestureDetector(
              onTap: () => bottomController.changePos(0),
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 40.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12.w),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.3),
                      blurRadius: 12.w,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: getCustomFont(
                    "Start Shopping", 14, Colors.white, 1,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}