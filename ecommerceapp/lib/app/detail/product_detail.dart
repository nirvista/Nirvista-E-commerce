import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pet_shop/base/color_data.dart';
import 'package:pet_shop/base/constant.dart';
import 'package:pet_shop/base/fetch_pixels.dart';
import 'package:pet_shop/base/get/storage_controller.dart';
import 'package:pet_shop/base/pref_data.dart';
import 'package:pet_shop/base/widget_utils.dart';
import '../../app/model/api_models.dart';
import '../../base/get/login_data_controller.dart';
import '../../base/get/route_key.dart';
import '../../base/get/cart_contr/cart_controller.dart';
import '../../base/get/cart_contr/shipping_add_controller.dart';
import '../../services/brand_api.dart';
import 'package:pet_shop/base/get/wishlist_controller.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ProductDetailScreen();
}

class _ProductDetailScreen extends State<ProductDetailScreen>
    with TickerProviderStateMixin {
  StorageController storageController = Get.find<StorageController>();

  // ── NEW: single shared controller ────────────────────────────────────
  WishlistController wishlistController = Get.find<WishlistController>();
  // ─────────────────────────────────────────────────────────────────────

  RxString selectedColor = "".obs;
  RxString selectedSize = "".obs;
  RxBool isWishlisted = false.obs;
  RxString brandName = ''.obs;
  PrefData prefData = PrefData();

  @override
  void initState() {
    super.initState();
    ProductModel? product = storageController.selectedProductModel;
    if (product != null) {
      if (product.variants.isNotEmpty) {
        var v = product.variants.first;
        if (v.color != null) selectedColor.value = v.color!;
        if (v.size != null) selectedSize.value = v.size!;
      }
      _loadWishlistStatus(product.id);
      _fetchBrandName(product);
    }
  }

  void _loadWishlistStatus(String productId) async {
    List<String> favList = await prefData.getFavouriteList();
    isWishlisted.value = favList.contains(productId);
  }

  void _fetchBrandName(ProductModel product) async {
    if (product.brandName.isNotEmpty) {
      brandName.value = product.brandName;
      return;
    }
    if (product.brandId.isEmpty) return;
    try {
      final res = await BrandApiService.getBrandById(product.brandId);
      if (res['success'] && res['data'] != null) {
        brandName.value = res['data']['name'] ?? '';
      }
    } catch (_) {}
  }

  void _toggleWishlist(String productId) async {
    List<String> favList = await prefData.getFavouriteList();

    if (favList.contains(productId)) {
      favList.remove(productId);
    } else {
      favList.add(productId);
    }

    await prefData.setFavouriteList(favList);
    isWishlisted.value = !isWishlisted.value;
  }

  @override
  Widget build(BuildContext context) {
    Constant.setupSize(context);
    ProductModel? product = storageController.selectedProductModel;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: Center(
          child: getCustomFont(
              "Product not found or not mapped", 16, getFontColor(context), 1),
        ),
      );
    }

    double margin = FetchPixels.getDefaultHorSpaceFigma(context);

    List<String> uniqueColors = product.variants
        .where((v) => v.color != null && v.color!.isNotEmpty)
        .map((v) => v.color!)
        .toSet()
        .toList();

    List<String> uniqueSizes = product.variants
        .where((v) => v.size != null && v.size!.isNotEmpty)
        .map((v) => v.size!)
        .toSet()
        .toList();

    return Scaffold(
      backgroundColor: getScaffoldColor(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, margin),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildProductImage(context, product, margin),
                    SizedBox(height: 16.h),
                    _buildRatingPill(context, product, margin),
                    SizedBox(height: 16.h),
                    if (uniqueColors.isNotEmpty)
                      _buildColorsSection(
                          context, product, uniqueColors, margin),
                    if (uniqueSizes.isNotEmpty)
                      _buildSizesSection(context, product, uniqueSizes, margin),
                    _buildBrandAndPriceSection(context, product, margin),
                    SizedBox(height: 16.h),
                    _buildDeliveryDetails(context, product, margin),
                    SizedBox(height: 16.h),
                    _buildTrustBadges(context, margin),
                    SizedBox(height: 16.h),
                    if (product.description != null &&
                        product.description!.isNotEmpty)
                      _buildDescriptionSection(context, product, margin),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
            _buildBottomButtons(context, product),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // TOP BAR
  // ═══════════════════════════════════════════════════════

  Widget _buildTopBar(BuildContext context, double margin) {
    return Container(
      color: getCardColor(context),
      padding: EdgeInsets.symmetric(horizontal: margin, vertical: 12.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Constant.backToPrev(context),
            child: Icon(Icons.arrow_back,
                color: getFontColor(context), size: 24.w),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: getGreyCardColor(context),
                borderRadius: BorderRadius.circular(10.w),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                children: [
                  Icon(Icons.search,
                      color: getFontGreyColor(context), size: 18.w),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: TextField(
                      style: TextStyle(color: getFontColor(context)),
                      decoration: InputDecoration(
                        hintText: "Search for products",
                        hintStyle: TextStyle(color: getFontGreyColor(context)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12.w),
          GestureDetector(
            onTap: () {
              Constant.sendToNext(context, myCartScreenRoute);
            },
            child: Icon(Icons.shopping_cart_outlined,
                color: getFontColor(context), size: 24.w),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // PRODUCT IMAGE — heart button wired to WishlistController
  // ═══════════════════════════════════════════════════════

  Widget _buildProductImage(
      BuildContext context, ProductModel product, double margin) {
    // The first variant id (if available) tells the API which variant to save.
    final String? firstVariantId =
        product.variants.isNotEmpty ? product.variants.first.id : null;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 300.h,
          color: getGreyCardColor(context),
          child: ClipRRect(
            child: CachedNetworkImage(
              imageUrl: product.imageUrl.isNotEmpty
                  ? product.imageUrl
                  : "https://placehold.co/400",
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  Center(child: CircularProgressIndicator(color: accentColor)),
              errorWidget: (context, url, error) =>
                  Icon(Icons.image_not_supported, size: 50.w),
            ),
          ),
        ),

        // ── Heart button — observes WishlistController ──
        Positioned(
          top: 12.h,
          right: 12.w,
          child: Obx(
            () {
              final wished = wishlistController.isWishlisted(product.id);
              return GestureDetector(
                onTap: () => wishlistController.toggleWishlist(
                  product.id,
                  variantId: firstVariantId,
                ),
                child: Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8.w,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                      child: Icon(
                        wished ? Icons.favorite : Icons.favorite_border,
                        key: ValueKey(wished),
                        color: wished ? accentColor : getFontGreyColor(context),
                        size: 24.w,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // RATING PILL
  // ═══════════════════════════════════════════════════════

  Widget _buildRatingPill(
      BuildContext context, ProductModel product, double margin) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: margin),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: getGreyCardColor(context),
        borderRadius: BorderRadius.circular(20.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: ratedColor, size: 14.w),
          SizedBox(width: 4.w),
          getCustomFont(
              product.rating.toStringAsFixed(1), 13, getFontColor(context), 1,
              fontWeight: FontWeight.w700),
          SizedBox(width: 8.w),
          Container(width: 1.w, height: 14.h, color: dividerColor),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // COLORS
  // ═══════════════════════════════════════════════════════

  Widget _buildColorsSection(BuildContext context, ProductModel product,
      List<String> colors, double margin) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: margin, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => getCustomFont("Selected Color: ${selectedColor.value}", 14,
              getFontColor(context), 1,
              fontWeight: FontWeight.w600)),
          SizedBox(height: 12.h),
          SizedBox(
            height: 60.w,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: colors.length,
              itemBuilder: (context, index) {
                final color = colors[index];
                return Obx(() => GestureDetector(
                      onTap: () {
                        selectedColor.value = color;
                        storageController.setSelectedColor(color);
                      },
                      child: Container(
                        width: 60.w,
                        height: 60.w,
                        margin: EdgeInsets.only(right: 12.w),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selectedColor.value == color
                                ? accentColor
                                : dividerColor,
                            width: selectedColor.value == color ? 3 : 1,
                          ),
                          borderRadius: BorderRadius.circular(10.w),
                          color: getGreyCardColor(context),
                        ),
                        child: Center(
                          child: getCustomFont(
                              color, 12, getFontColor(context), 1,
                              fontWeight: FontWeight.w600,
                              textAlign: TextAlign.center),
                        ),
                      ),
                    ));
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // SIZES
  // ═══════════════════════════════════════════════════════

  Widget _buildSizesSection(BuildContext context, ProductModel product,
      List<String> sizes, double margin) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: margin, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              getCustomFont("Select Size", 14, getFontColor(context), 1,
                  fontWeight: FontWeight.w600),
              GestureDetector(
                onTap: () {},
                child: getCustomFont("Size Chart", 12, accentColor, 1,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Obx(() => Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: sizes.map((size) {
                  final isSelected = selectedSize.value == size;
                  return GestureDetector(
                    onTap: () {
                      selectedSize.value = size;
                      storageController.setSelectedSize(size);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: isSelected ? accentColor : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? accentColor : dividerColor,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(8.w),
                      ),
                      child: getCustomFont(size, 12,
                          isSelected ? Colors.white : getFontColor(context), 1,
                          fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
              )),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // BRAND & PRICE
  // ═══════════════════════════════════════════════════════

  Widget _buildBrandAndPriceSection(
      BuildContext context, ProductModel product, double margin) {
    double basePrice = product.originalPrice;
    double currentPrice = product.currentPrice;
    double discountPercent = 0.0;

    if (basePrice > 0 && currentPrice > 0 && basePrice > currentPrice) {
      discountPercent =
          (((basePrice - currentPrice) / basePrice) * 100).toDouble();
    } else {
      basePrice = currentPrice;
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: margin, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Obx(() => getCustomFont(
                  brandName.value, 14, getFontGreyColor(context), 1,
                  fontWeight: FontWeight.w700)),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: () {},
                child: getCustomFont("Visit Store", 12, accentColor, 1,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          getCustomFont(product.title, 16, getFontColor(context), 2,
              fontWeight: FontWeight.w700),
          SizedBox(height: 12.h),
          Row(
            children: [
              if (discountPercent > 0) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: greenColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4.w),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_drop_down,
                          color: greenColor, size: 14.w),
                      getCustomFont(
                          "${discountPercent.toStringAsFixed(0)}% OFF",
                          11,
                          greenColor,
                          1,
                          fontWeight: FontWeight.w700),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                getCustomFont("₹${basePrice.toStringAsFixed(0)}", 12,
                    getFontGreyColor(context), 1,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.lineThrough),
              ],
            ],
          ),
          SizedBox(height: 8.h),
          getCustomFont(
              "₹${currentPrice.toStringAsFixed(0)}", 20, accentColor, 1,
              fontWeight: FontWeight.w800),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // DELIVERY DETAILS
  // ═══════════════════════════════════════════════════════

  Widget _buildDeliveryDetails(
      BuildContext context, ProductModel product, double margin) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: margin),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        border: Border.all(color: dividerColor),
        borderRadius: BorderRadius.circular(8.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.home, color: getFontColor(context), size: 16.w),
              SizedBox(width: 8.w),
              Obx(() {
                final shippingController =
                    Get.find<ShippingAddressController>();
                final selectedAddr = shippingController.selectedAddress.value;
                return Expanded(
                  child: getCustomFont(
                      selectedAddr != null
                          ? selectedAddr.fullAddress
                          : "Select a shipping address",
                      12,
                      getFontColor(context),
                      1,
                      fontWeight: FontWeight.w500,
                      overflow: TextOverflow.ellipsis),
                );
              }),
              Icon(Icons.arrow_forward,
                  color: getFontGreyColor(context), size: 16.w),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Icon(Icons.local_shipping,
                  color: getFontColor(context), size: 16.w),
              SizedBox(width: 8.w),
              getCustomFont(
                  "Delivery by 8 Apr, Wed", 12, getFontColor(context), 1,
                  fontWeight: FontWeight.w500),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // TRUST BADGES
  // ═══════════════════════════════════════════════════════

  Widget _buildTrustBadges(BuildContext context, double margin) {
    final badges = [
      {
        "icon": Icons.schedule,
        "title": "10-Day Return",
        "desc": "Change of mind"
      },
      {
        "icon": Icons.money,
        "title": "Cash on Delivery",
        "desc": "Pay on delivery"
      },
      {
        "icon": Icons.verified,
        "title": "Brand Assured",
        "desc": "Official product"
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: margin),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          badges.length,
          (i) => Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 6.w),
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                border: Border.all(color: dividerColor),
                borderRadius: BorderRadius.circular(8.w),
              ),
              child: Column(
                children: [
                  Icon(badges[i]["icon"] as IconData,
                      color: accentColor, size: 20.w),
                  SizedBox(height: 8.h),
                  getCustomFont(badges[i]["title"] as String, 10,
                      getFontColor(context), 1,
                      fontWeight: FontWeight.w600, textAlign: TextAlign.center),
                  SizedBox(height: 4.h),
                  getCustomFont(badges[i]["desc"] as String, 8,
                      getFontGreyColor(context), 1,
                      fontWeight: FontWeight.w400, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // DESCRIPTION
  // ═══════════════════════════════════════════════════════

  Widget _buildDescriptionSection(
      BuildContext context, ProductModel product, double margin) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: margin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          getCustomFont("Description", 16, getFontColor(context), 1,
              fontWeight: FontWeight.w700),
          SizedBox(height: 12.h),
          getCustomFont(
              product.description ?? "", 14, getFontGreyColor(context), 50,
              fontWeight: FontWeight.w500),
        ],
      ),
    );
  }

  VariantModel? _getSelectedVariant(ProductModel product) {
    if (product.variants.isEmpty) return null;
    try {
      return product.variants.firstWhere((v) =>
          (v.color == selectedColor.value ||
              v.color == null ||
              v.color!.isEmpty) &&
          (v.size == selectedSize.value || v.size == null || v.size!.isEmpty));
    } catch (_) {
      return product.variants.first;
    }
  }

  int _getCartQuantity(ProductModel product) {
    try {
      final cartController = Get.find<CartController>();
      final cart = cartController.cartModel.value;
      if (cart == null) return 0;
      final variant = _getSelectedVariant(product);
      if (variant == null) return 0;
      final items = cart.items
          .where((i) => i.productId == product.id && i.variantId == variant.id)
          .toList();
      if (items.isNotEmpty) return items.first.quantity;
    } catch (_) {}
    return 0;
  }

  Widget _buildBottomButtons(BuildContext context, ProductModel product) {
    return Container(
      color: getCardColor(context),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: SafeArea(
        top: false,
        child: Obx(() {
          final cartController = Get.find<CartController>();
          // Read cartModel to trigger reactivity
          final _cart = cartController.cartModel.value;
          int cartQty = _getCartQuantity(product);
          bool isInCart = cartQty > 0;

          return Row(
            children: [
              // Left: "Add to Cart" OR quantity +/- selector
              Expanded(
                child: isInCart
                    ? Container(
                        padding: EdgeInsets.symmetric(vertical: 6.h),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: getFontColor(context), width: 1.5),
                          borderRadius: BorderRadius.circular(8.w),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                VariantModel? variant =
                                    _getSelectedVariant(product);
                                if (variant == null) return;
                                cartController.decreaseQuantity(
                                    product.id, variant.id);
                              },
                              child: SizedBox(
                                width: 36.w,
                                height: 36.w,
                                child: Center(
                                  child: Icon(Icons.remove,
                                      size: 20.w, color: getFontColor(context)),
                                ),
                              ),
                            ),
                            Container(
                              width: 40.w,
                              alignment: Alignment.center,
                              child: getCustomFont(
                                  "$cartQty", 16, getFontColor(context), 1,
                                  fontWeight: FontWeight.w700),
                            ),
                            GestureDetector(
                              onTap: () {
                                VariantModel? variant =
                                    _getSelectedVariant(product);
                                if (variant == null) return;
                                cartController.increaseQuantity(
                                    product.id, variant.id);
                              },
                              child: SizedBox(
                                width: 36.w,
                                height: 36.w,
                                child: Center(
                                  child: Icon(Icons.add,
                                      size: 20.w, color: accentColor),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : GestureDetector(
                        onTap: () async {
                          VariantModel? variant = _getSelectedVariant(product);
                          if (variant == null) return;
                          try {
                            final loginController =
                                Get.find<LoginDataController>();
                            if (loginController.currentUser.value == null ||
                                loginController.currentUser.value!.id == null) {
                              Constant.sendToNext(context, loginRoute);
                              return;
                            }
                            bool success = await cartController.addToCart(
                                product.id, variant.id);
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Added to cart!'),
                                      backgroundColor: Colors.green));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Failed to add to cart'),
                                      backgroundColor: Colors.red));
                            }
                          } catch (e) {
                            Constant.sendToNext(context, loginRoute);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: getFontColor(context), width: 1.5),
                            borderRadius: BorderRadius.circular(8.w),
                          ),
                          child: Center(
                            child: getCustomFont(
                                "Add to Cart", 14, getFontColor(context), 1,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
              ),
              SizedBox(width: 12.w),
              // Right: Buy Now
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    VariantModel? variant = _getSelectedVariant(product);
                    if (variant == null) return;
                    try {
                      final loginController = Get.find<LoginDataController>();
                      if (loginController.currentUser.value == null ||
                          loginController.currentUser.value!.id == null) {
                        Constant.sendToNext(context, loginRoute);
                        return;
                      }
                      if (!isInCart) {
                        bool success = await cartController.addToCart(
                            product.id, variant.id);
                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Failed to prepare checkout'),
                                  backgroundColor: Colors.red));
                          return;
                        }
                      }
                      Constant.sendToNext(context, checkoutShippingScreenRoute);
                    } catch (e) {
                      Constant.sendToNext(context, loginRoute);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: ratedColor,
                      borderRadius: BorderRadius.circular(8.w),
                    ),
                    child: Center(
                      child: getCustomFont(
                          "Buy at \u20B9${product.currentPrice.toStringAsFixed(0)}",
                          14,
                          Colors.black,
                          1,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
