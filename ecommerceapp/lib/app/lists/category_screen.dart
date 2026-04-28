import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pet_shop/base/color_data.dart';
import 'package:pet_shop/base/constant.dart';
import 'package:pet_shop/base/fetch_pixels.dart';
import 'package:pet_shop/base/get/route_key.dart';
import 'package:pet_shop/base/widget_utils.dart';
import '../../app/model/api_models.dart';
import '../../../services/category_api.dart';
import 'package:pet_shop/base/get/storage_controller.dart';
import 'package:pet_shop/base/get/wishlist_controller.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({Key? key}) : super(key: key);

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen>
    with TickerProviderStateMixin {
  StorageController storageController = Get.find<StorageController>();

  final wishlistController = Get.isRegistered<WishlistController>()
      ? Get.find<WishlistController>()
      : Get.put(WishlistController());

  RxInt selectedId = 0.obs;
  Future<List<CategoryModel>>? categoriesFuture;

  @override
  void initState() {
    super.initState();
    categoriesFuture = _fetchCategories();
  }

  Future<List<CategoryModel>> _fetchCategories() async {
    final result = await CategoryApiService.getAllCategories();
    if (result['success']) {
      return (result['data'] as List)
          .map((c) => CategoryModel.fromJson(c))
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    Constant.setupSize(context);
    double margin = FetchPixels.getDefaultHorSpaceFigma(context);

    return Scaffold(
      backgroundColor: getScaffoldColor(context),
      body: Column(
        children: [
          // ── Teal gradient header — matches home tab exactly ──────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF14B8A6), Color(0xFF0D9488), Color(0xFF0F766E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A0D9488),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(margin, 48.h, margin, 16.h),
            child: Row(
              children: [
                Text(
                  'Categories',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20.sp,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          Expanded(
            child: FutureBuilder<List<CategoryModel>>(
              future: categoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                            color: accentColor, strokeWidth: 2.5),
                        SizedBox(height: 12.h),
                        Text('Loading…',
                            style: TextStyle(
                                color: getFontGreyColor(context),
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                }
                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.category_outlined,
                            color: getFontGreyColor(context), size: 48.h),
                        SizedBox(height: 12.h),
                        Text('No categories found',
                            style: TextStyle(
                                color: getFontGreyColor(context),
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                }

                final allCategory = snapshot.data!;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── LEFT SIDEBAR ────────────────────────────────────
                    Container(
                      width: 90.w,
                      height: double.infinity,
                      color: getCardColor(context),
                      child: ListView.builder(
                        padding: EdgeInsets.only(top: 8.h, bottom: 8.h),
                        itemCount: allCategory.length,
                        itemBuilder: (context, index) {
                          final category = allCategory[index];
                          return Obx(() {
                            final active = selectedId.value == index;
                            return GestureDetector(
                              onTap: () => selectedId.value = index,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                                margin: EdgeInsets.symmetric(
                                    horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: active
                                      ? accentColor.withOpacity(0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8.w),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Active indicator bar
                                    Container(
                                      width: 3.w,
                                      height: 40.h,
                                      decoration: BoxDecoration(
                                        color: active
                                            ? accentColor
                                            : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(2.w),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    // Label — always visible
                                    Expanded(
                                      child: Text(
                                        category.name,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.start,
                                        style: TextStyle(
                                          color: active
                                              ? accentColor
                                              : getFontColor(context),
                                          fontWeight: active
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          fontSize: 11.sp,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 6.w),
                                  ],
                                ),
                              ),
                            );
                          });
                        },
                      ),
                    ),

                    // Thin divider
                    Container(
                        width: 1,
                        color: dividerColor),

                    // ── RIGHT CONTENT AREA ──────────────────────────────
                    Expanded(
                      child: Obx(() {
                        if (allCategory.isEmpty) return const SizedBox();
                        final selectedCat = allCategory[selectedId.value];
                        final subCategory = selectedCat.children;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section header — same style as home tab
                            Container(
                              color: getCardColor(context),
                              padding: EdgeInsets.fromLTRB(
                                  margin, 14.h, margin, 14.h),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4.w,
                                    height: 20.h,
                                    decoration: BoxDecoration(
                                      color: accentColor,
                                      borderRadius:
                                          BorderRadius.circular(2.w),
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Text(
                                      selectedCat.name,
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w800,
                                        color: getFontColor(context),
                                      ),
                                    ),
                                  ),
                                  if (subCategory.isNotEmpty)
                                    Text(
                                      '${subCategory.length} sub',
                                      style: TextStyle(
                                          fontSize: 11.sp,
                                          color: getFontGreyColor(context),
                                          fontWeight: FontWeight.w500),
                                    ),
                                ],
                              ),
                            ),

                            Expanded(
                              child: subCategory.isEmpty
                                  ? _buildDirectProductsView(
                                      selectedCat, margin)
                                  : _buildSubcategoryGrid(
                                      subCategory, margin),
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Sub-category grid — same card style as home popular picks ─────────────
  Widget _buildSubcategoryGrid(List<CategoryModel> subs, double margin) {
    return GridView.builder(
      padding: EdgeInsets.all(margin),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10.w,
        mainAxisSpacing: 10.h,
        childAspectRatio: 2.2,
      ),
      itemCount: subs.length,
      itemBuilder: (context, index) {
        final sub = subs[index];
        return GestureDetector(
          onTap: () {
            storageController.setSelectedCategory(sub.id);
            storageController.setSelectedCategoryName(sub.name);
            Constant.sendToNext(context, categoryProductsPageRoute);
          },
          child: Container(
            decoration: BoxDecoration(
              color: getCardColor(context),
              borderRadius: BorderRadius.circular(14.w),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  child: Text(
                    sub.name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: getFontColor(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 12.sp,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Direct products view — same card as home _buildProductCard ─────────────
  Widget _buildDirectProductsView(CategoryModel cat, double margin) {
    return FutureBuilder<Map<String, dynamic>>(
      future: CategoryApiService.getProductsByCategory(cat.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(
                  color: accentColor, strokeWidth: 2.5));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
              child: Text('No products found',
                  style: TextStyle(
                      color: getFontGreyColor(context), fontSize: 14.sp)));
        }
        final res = snapshot.data!;
        if (!res['success']) {
          return Center(
              child: Text('No products found',
                  style: TextStyle(
                      color: getFontGreyColor(context), fontSize: 14.sp)));
        }
        List<dynamic> productsList = [];
        if (res['data'] is List) {
          productsList = res['data'];
        } else if (res['data'] is Map && res['data']['products'] is List) {
          productsList = res['data']['products'];
        }
        final products =
            productsList.map((e) => ProductModel.fromJson(e)).toList()
                ..removeWhere((p) =>
                    p.variants.isEmpty &&
                    p.originalPrice <= 0 &&
                    p.imageUrl.isEmpty);

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shopping_bag_outlined,
                    color: getFontGreyColor(context), size: 48.h),
                SizedBox(height: 12.h),
                Text('No products in this category',
                    style: TextStyle(
                        color: getFontGreyColor(context), fontSize: 14.sp)),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.all(margin),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10.w,
            mainAxisSpacing: 10.h,
            childAspectRatio: 0.65,
          ),
          itemCount: products.length,
          itemBuilder: (context, idx) =>
              _buildProductCard(context, products[idx]),
        );
      },
    );
  }

  // ── Product card — exact same design as home tab ───────────────────────────
  Widget _buildProductCard(BuildContext context, ProductModel product) {
    double basePrice = product.originalPrice;
    double currentPrice = product.currentPrice;
    double discountPercent = 0.0;
    if (basePrice <= 0) basePrice = currentPrice;
    if (currentPrice <= 0) currentPrice = basePrice;
    if (basePrice > 0 && currentPrice > 0 && basePrice > currentPrice) {
      discountPercent = ((basePrice - currentPrice) / basePrice) * 100;
    } else {
      basePrice = currentPrice;
    }

    return GestureDetector(
      onTap: () {
        storageController.setSelectedProductModel(product);
        Constant.sendToNext(context, productDetailScreenRoute);
      },
      child: Container(
        decoration: BoxDecoration(
          color: getCardColor(context),
          borderRadius: BorderRadius.circular(14.w),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Image with heart overlay ──
            LayoutBuilder(
              builder: (context, constraints) {
                final imgH = (constraints.maxWidth * 0.75).clamp(80.0, 130.0);
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(14.w)),
                      child: Container(
                        height: imgH,
                        width: double.infinity,
                        color: getGreyCardColor(context),
                        child: (product.imageUrl.isNotEmpty &&
                                !product.imageUrl.contains('example.com'))
                            ? CachedNetworkImage(
                                imageUrl: product.imageUrl,
                                fit: BoxFit.contain,
                                placeholder: (_, __) => Center(
                                  child: CircularProgressIndicator(
                                      color: accentColor, strokeWidth: 2),
                                ),
                                errorWidget: (_, __, ___) => Icon(
                                    Icons.shopping_bag_outlined,
                                    color: getFontGreyColor(context),
                                    size: 32.w),
                              )
                            : Icon(Icons.shopping_bag_outlined,
                                color: getFontGreyColor(context), size: 32.w),
                      ),
                    ),
                    // Heart icon — top right
                    Positioned(
                      top: 6.h,
                      right: 6.w,
                      child: GestureDetector(
                        onTap: () {
                          if (product.variants.isNotEmpty) {
                            wishlistController.toggleWishlist(product.id, variantId: product.variants[0].id);
                          } else {
                            Get.snackbar("Error", "No variants available for this product", 
                              backgroundColor: Colors.redAccent, colorText: Colors.white);
                          }
                        },
                        child: Obx(() {
                          bool isWished = wishlistController.isWishlisted(product.id);
                          return Container(
                            width: 28.w,
                            height: 28.w,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 6)
                              ],
                            ),
                            child: Icon(
                              isWished ? Icons.favorite : Icons.favorite_border,
                              color: accentColor, 
                              size: 15.w
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                );
              },
            ),
            // ── Info ──
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (product.brandName.isNotEmpty)
                    Text(product.brandName,
                        style: TextStyle(
                            fontSize: 10.sp,
                            color: getFontGreyColor(context),
                            fontWeight: FontWeight.w500)),
                  SizedBox(height: 3.h),
                  Text(product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12.sp,
                          color: getFontColor(context),
                          fontWeight: FontWeight.w600,
                          height: 1.3)),
                  SizedBox(height: 5.h),
                  Row(
                    children: [
                      Icon(Icons.star_rounded,
                          color: ratedColor, size: 12.w),
                      SizedBox(width: 3.w),
                      Text(product.rating.toStringAsFixed(1),
                          style: TextStyle(
                              fontSize: 10.sp,
                              color: getFontColor(context),
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 5.w,
                    runSpacing: 3.h,
                    children: [
                      Text('₹${currentPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                              fontSize: 14.sp,
                              color: accentColor,
                              fontWeight: FontWeight.w800)),
                      if (discountPercent > 0) ...[
                        Text('₹${basePrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: const Color(0xFF4B5563),
                              decoration: TextDecoration.lineThrough,
                              decorationColor: const Color(0xFF4B5563),
                              decorationThickness: 2.0,
                              fontWeight: FontWeight.w500,
                              height: 1.0,
                            )),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 5.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4.w),
                          ),
                          child: Text(
                            '${discountPercent.toStringAsFixed(0)}% off',
                            style: TextStyle(
                                fontSize: 9.sp,
                                color: accentColor,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
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
}