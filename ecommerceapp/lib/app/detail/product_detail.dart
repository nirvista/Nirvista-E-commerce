import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pet_shop/base/color_data.dart';
import 'package:pet_shop/base/constant.dart';
import 'package:pet_shop/base/fetch_pixels.dart';
import 'package:pet_shop/base/get/storage_controller.dart';
import 'package:pet_shop/base/widget_utils.dart';
import '../../app/model/api_models.dart';
import '../../base/get/login_data_controller.dart';
import '../../base/get/route_key.dart';
import '../../base/get/cart_contr/cart_controller.dart';
import '../../base/get/cart_contr/shipping_add_controller.dart';
import '../../services/brand_api.dart';
import 'package:pet_shop/base/get/wishlist_controller.dart';
import 'package:pet_shop/base/pref_data.dart';
import '../../services/product_api.dart';
import 'package:pet_shop/app/detail/product_images_carousel.dart';
import 'package:pet_shop/app/detail/rating_widget.dart';

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
  RxString selectedVariantId = "".obs;
  RxBool isWishlisted = false.obs;
  RxString brandName = ''.obs;
  PrefData prefData = PrefData();
  ProductModel? product;

  @override
  void initState() {
    super.initState();
    product = storageController.selectedProductModel;
    if (product != null) {
      _initializeSelection(product!);
      _loadWishlistStatus(product!.id);
      _fetchBrandName(product!);
      _enrichProductDetail(product!.id);
    }
  }

  void _initializeSelection(ProductModel product) {
    if (product.variants.isEmpty) return;

    // Pick first available color IF nothing selected
    if (selectedColor.value.isEmpty) {
      var vWithColor = product.variants.firstWhereOrNull(
          (v) => v.color != null && v.color!.trim().isNotEmpty);
      if (vWithColor != null) {
        selectedColor.value = vWithColor.color!.trim();
        storageController.setSelectedColor(selectedColor.value);
      }
    }

    // Pick first available size IF nothing selected
    if (selectedSize.value.isEmpty) {
      var vWithSize = product.variants.firstWhereOrNull(
          (v) => v.size != null && v.size!.trim().isNotEmpty);
      if (vWithSize != null) {
        selectedSize.value = vWithSize.size!.trim();
        storageController.setSelectedSize(selectedSize.value);
      }
    }

    // After setting defaults, try to find a variant matching the selection
    final match = _getSelectedVariant(product);
    if (match != null) {
      selectedVariantId.value = match.id;
    } else {
      selectedVariantId.value = product.variants.first.id;
    }
  }

  // --- Background enrichment (optional, non-blocking) ---
  void _enrichProductDetail(String productId) async {
    try {
      final res = await ProductApiService.getProductById(productId);
      if (res['success'] && res['data'] != null) {
        final fullProduct = ProductModel.fromJson(res['data']);
        setState(() {
          product = product!.merge(fullProduct);
          _initializeSelection(product!); // Re-initialize selection with new data
        });
      }
    } catch (_) {}
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



  @override
  Widget build(BuildContext context) {
    Constant.setupSize(context);
    double margin = FetchPixels.getDefaultHorSpaceFigma(context);

    if (product == null) {
      return Scaffold(
        backgroundColor: getScaffoldColor(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: getScaffoldColor(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, margin),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductImage(context, product!, margin),
                    SizedBox(height: 16.h),
                    _buildRatingPill(context, product!, margin),
                    SizedBox(height: 16.h),
                    _buildBrandAndPriceSection(context, product!, margin),
                    _buildOptionsSection(context, product!, margin),
                    _buildDeliveryDetails(context, product!, margin),
                    SizedBox(height: 16.h),
                    _buildTrustBadges(context, margin),
                    SizedBox(height: 16.h),
                    if (product!.description != null && product!.description!.isNotEmpty)
                      _buildDescriptionSection(context, product!, margin),
                    SizedBox(height: 16.h),
                    _buildProductRatingSection(context, product!, margin),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
            _buildBottomButtons(context, product!),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsSection(BuildContext context, ProductModel product, double margin) {
    List<String> uniqueColors = product.variants
        .where((v) => v.color != null && v.color!.isNotEmpty)
        .map((v) => v.color!.trim())
        .toSet()
        .toList();
    List<String> uniqueSizes = product.variants
        .where((v) => v.size != null && v.size!.isNotEmpty)
        .map((v) => v.size!.trim())
        .toSet()
        .toList();

    return Column(
      children: [
        if (uniqueColors.isNotEmpty)
          _buildColorsSection(context, product, uniqueColors, margin),
        if (uniqueSizes.isNotEmpty)
          _buildSizesSection(context, product, uniqueSizes, margin),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // TOP BAR
  // ═══════════════════════════════════════════════════════

  Widget _buildTopBar(BuildContext context, double margin) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF14B8A6), Color(0xFF0D9488), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      padding: EdgeInsets.symmetric(horizontal: margin, vertical: 12.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Constant.backToPrev(context),
            child: Icon(Icons.arrow_back,
                color: Colors.white, size: 24.w),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: getCustomFont(
              product!.title,
              16,
              Colors.white,
              1,
              fontWeight: FontWeight.w700,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 12.w),
          GestureDetector(
            onTap: () {
              Constant.sendToNext(context, myCartScreenRoute);
            },
            child: Icon(Icons.shopping_cart_outlined,
                color: Colors.white, size: 24.w),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // PRODUCT IMAGE CAROUSEL with multiple images and zoom
  // ═══════════════════════════════════════════════════════

  Widget _buildProductImage(
      BuildContext context, ProductModel product, double margin) {
    // The first variant id (if available) tells the API which variant to save.
    final String? firstVariantId =
        product.variants.isNotEmpty ? product.variants.first.id : null;

    return Obx(() {
      // Fix: Ensure Obx always has a listener even if variants are empty
      selectedVariantId.value;

      // ── Reactive: collects all images from the currently selected variant ──
      final variant = _getSelectedVariant(product);
      
      // Get all images for the carousel
      List<String> carouselImages = [];
      
      // Add variant images if available
      if (variant != null && variant.images.isNotEmpty) {
        carouselImages.addAll(variant.images);
      }
      
      // Add product-level images
      if (product.images.isNotEmpty) {
        carouselImages.addAll(product.images);
      }
      
      // Add main image if available
      if (product.imageUrl.isNotEmpty && !carouselImages.contains(product.imageUrl)) {
        carouselImages.insert(0, product.imageUrl);
      }
      
      // Ensure we have at least one image
      if (carouselImages.isEmpty) {
        carouselImages.add("https://placehold.co/400");
      }

      return ProductImagesCarousel(
        images: carouselImages,
        containerHeight: 300,
        isWishlisted: wishlistController.isWishlisted(product.id),
        onHeartTap: () => wishlistController.toggleWishlist(
          product.id,
          variantId: firstVariantId,
        ),
      );
    });
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
          getCustomFont(product.rating.toStringAsFixed(1), 13,
              getFontColor(context), 1,
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
    if (colors.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: margin, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => getCustomFont(
              "Selected Color: ${selectedColor.value}", 14,
              getFontColor(context), 1,
              fontWeight: FontWeight.w600)),
          SizedBox(height: 12.h),
          Obx(() {
            // Ensure Obx has a variable to watch even if list is empty
            selectedColor.value;
            
            return SizedBox(
              height: 60.w,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: colors.length,
                itemBuilder: (context, index) {
                  final color = colors[index];
                  final isSelected =
                      selectedColor.value.trim().toLowerCase() ==
                          color.trim().toLowerCase();

                  return GestureDetector(
                    onTap: () {
                      selectedColor.value = color;
                      selectedVariantId.value =
                          ""; // Reset to allow best-match search
                      storageController.setSelectedColor(color);
                    },
                    child: Container(
                      width: 60.w,
                      height: 60.w,
                      margin: EdgeInsets.only(right: 12.w),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? accentColor : dividerColor,
                          width: isSelected ? 3 : 1,
                        ),
                        borderRadius: BorderRadius.circular(10.w),
                        color: getGreyCardColor(context),
                      ),
                      child: Center(
                        child: getCustomFont(color, 12, getFontColor(context), 1,
                            fontWeight: FontWeight.w600,
                            textAlign: TextAlign.center),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // SIZES
  // ═══════════════════════════════════════════════════════

  Widget _buildSizesSection(BuildContext context, ProductModel product,
      List<String> sizes, double margin) {
    if (sizes.isEmpty) return const SizedBox.shrink();

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
          Obx(() {
            // Ensure Obx has a variable to watch
            selectedSize.value;

            return Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              children: sizes.map((size) {
                final isSelected = selectedSize.value.trim().toLowerCase() ==
                    size.trim().toLowerCase();
                return GestureDetector(
                  onTap: () {
                    selectedSize.value = size;
                    selectedVariantId.value =
                        ""; // Reset to allow best-match search
                    storageController.setSelectedSize(size);
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
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
            );
          }),
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
    
    // Add safety check for zero or negative prices
    if (basePrice <= 0) basePrice = currentPrice;
    if (currentPrice <= 0) currentPrice = basePrice;
    
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
                  brandName.value, 
                  14, getFontGreyColor(context), 1,
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
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
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
                getCustomFont(
                    "₹${basePrice.toStringAsFixed(0)}",
                    14,
                    const Color(0xFF4B5563),
                    1,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: const Color(0xFF4B5563),
                    decorationThickness: 1.2,
                    txtHeight: 1.4),
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
    return GestureDetector(
      onTap: () {
        showAddressSelectorBottomSheet(context);
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: margin),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: getCardColor(context),
          border: Border.all(color: dividerColor),
          borderRadius: BorderRadius.circular(8.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: accentColor, size: 18.w),
                SizedBox(width: 8.w),
                Obx(() {
                  final shippingController = Get.find<ShippingAddressController>();
                  final selectedAddr = shippingController.selectedAddress.value;
                  return Expanded(
                    child: getCustomFont(
                      selectedAddr != null ? selectedAddr.fullAddress : "Select a shipping address",
                      12, getFontColor(context), 1,
                      fontWeight: FontWeight.w600,
                      overflow: TextOverflow.ellipsis
                    ),
                  );
                }),
                Icon(Icons.keyboard_arrow_right, color: getFontGreyColor(context), size: 18.w),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(Icons.local_shipping_outlined,
                    color: getFontGreyColor(context), size: 16.w),
                SizedBox(width: 8.w),
                getCustomFont(
                    "Standard Delivery: 3-5 Days", 12, getFontGreyColor(context), 1,
                    fontWeight: FontWeight.w400),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // TRUST BADGES
  // ═══════════════════════════════════════════════════════

  Widget _buildTrustBadges(BuildContext context, double margin) {
    final badges = [
      {"icon": Icons.schedule, "title": "10-Day Return", "desc": "Change of mind"},
      {"icon": Icons.money, "title": "Cash on Delivery", "desc": "Pay on delivery"},
      {"icon": Icons.verified, "title": "Brand Assured", "desc": "Official product"},
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
                      fontWeight: FontWeight.w600,
                      textAlign: TextAlign.center),
                  SizedBox(height: 4.h),
                  getCustomFont(badges[i]["desc"] as String, 8,
                      getFontGreyColor(context), 1,
                      fontWeight: FontWeight.w400,
                      textAlign: TextAlign.center),
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
          getCustomFont(product.description ?? "", 14,
              getFontGreyColor(context), 50,
              fontWeight: FontWeight.w500),
        ],
      ),
    );
  }

  VariantModel? _getSelectedVariant(ProductModel product) {
    if (product.variants.isEmpty) return null;

    final sColor = selectedColor.value.trim().toLowerCase();
    final sSize = selectedSize.value.trim().toLowerCase();

    // 1. EXACT MATCH: Both color and size match
    final exactMatch = product.variants.firstWhereOrNull((v) {
      final vColor = v.color?.trim().toLowerCase() ?? "";
      final vSize = v.size?.trim().toLowerCase() ?? "";
      return vColor == sColor && vSize == sSize;
    });
    if (exactMatch != null) return exactMatch;

    // 2. PARTIAL MATCH: Color match (often color is the primary selection)
    if (sColor.isNotEmpty) {
      final colorMatch = product.variants.firstWhereOrNull((v) {
        final vColor = v.color?.trim().toLowerCase() ?? "";
        return vColor == sColor;
      });
      if (colorMatch != null) return colorMatch;
    }

    // 3. PARTIAL MATCH: Size match
    if (sSize.isNotEmpty) {
      final sizeMatch = product.variants.firstWhereOrNull((v) {
        final vSize = v.size?.trim().toLowerCase() ?? "";
        return vSize == sSize;
      });
      if (sizeMatch != null) return sizeMatch;
    }

    // 4. FALLBACK: First variant
    return product.variants.first;
  }

  int _getCartQuantity(ProductModel product) {
    final cartController = Get.find<CartController>();
    final cartItems = cartController.cartModel.value?.items ?? [];
    int qty = 0;
    for (var item in cartItems) {
      if (item.productId == product.id) {
        qty += item.quantity;
      }
    }
    return qty;
  }

  // ═══════════════════════════════════════════════════════
  // PRODUCT RATING SECTION - Let user rate the product
  // ═══════════════════════════════════════════════════════

  Widget _buildProductRatingSection(
      BuildContext context, ProductModel product, double margin) {
    return Column(
      children: [
        getCustomFont("Rate This Product", 16, getFontColor(context), 1,
            fontWeight: FontWeight.w700, textAlign: TextAlign.center),
        SizedBox(height: 8.h),
        StarRatingWidget(
          initialRating: 0.0,
          isReadOnly: false,
          starSize: 32.0,
          alignment: MainAxisAlignment.center,
          showLabel: false,
          onRatingChanged: (rating) {
            // Handle rating submission
            print("User rated product: $rating stars");
          },
        ),
      ],
    );
  }

  Widget _buildBottomButtons(BuildContext context, ProductModel product) {
    return Container(
      color: getCardColor(context),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: SafeArea(
        top: false,
        child: Obx(() {
          final cartController = Get.find<CartController>();
          int cartQty = _getCartQuantity(product);
          bool isInCart = cartQty > 0;
          
          VariantModel? variant = _getSelectedVariant(product);
          bool hasReachedMaxStock = variant != null && cartQty >= variant.availableStock;

          return Row(
            children: [
              // Left: "Add to Cart" OR quantity +/- selector
              Expanded(
                child: isInCart
                        ? Container(
                            padding: EdgeInsets.symmetric(vertical: 6.h),
                            decoration: BoxDecoration(
                              border: Border.all(color: getFontColor(context), width: 1.5),
                              borderRadius: BorderRadius.circular(8.w),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (variant == null) return;
                                    cartController.decreaseQuantity(product.id, variant.id);
                                  },
                                  child: SizedBox(
                                    width: 36.w,
                                    height: 36.w,
                                    child: Center(
                                      child: Icon(Icons.remove, size: 20.w, color: getFontColor(context)),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 40.w,
                                  alignment: Alignment.center,
                                  child: getCustomFont("$cartQty", 16, getFontColor(context), 1, fontWeight: FontWeight.w700),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    if (variant == null) return;
                                    if (hasReachedMaxStock) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Maximum stock reached'), backgroundColor: Colors.orange)
                                      );
                                      return;
                                    }
                                    cartController.increaseQuantity(product.id, variant.id);
                                  },
                                  child: SizedBox(
                                    width: 36.w,
                                    height: 36.w,
                                    child: Center(
                                      child: Icon(Icons.add, size: 20.w, color: accentColor),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GestureDetector(
                            onTap: () async {
                              if (variant == null) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select valid options'), backgroundColor: Colors.orange));
                                return;
                              }
                              // if (variant.availableStock <= 0) {
                              //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected variant is out of stock'), backgroundColor: Colors.red));
                              //   return;
                              // }
                              try {
                                final loginController = Get.find<LoginDataController>();
                                if (loginController.currentUser.value == null || loginController.currentUser.value!.id == null) {
                                  Constant.sendToNext(context, loginRoute);
                                  return;
                                }
                                bool success = await cartController.addToCart(product.id, variant.id);
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart!'), backgroundColor: Colors.green));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add to cart'), backgroundColor: Colors.red));
                                }
                              } catch (e) {
                                Constant.sendToNext(context, loginRoute);
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              decoration: BoxDecoration(
                                border: Border.all(color: getFontColor(context), width: 1.5),
                                borderRadius: BorderRadius.circular(8.w),
                              ),
                              child: Center(
                                child: getCustomFont("Add to Cart", 14,
                                    getFontColor(context), 1,
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
                    if (variant == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select valid options'), backgroundColor: Colors.orange));
                      return;
                    }
                    try {
                      final loginController = Get.find<LoginDataController>();
                      if (loginController.currentUser.value == null || loginController.currentUser.value!.id == null) {
                        Constant.sendToNext(context, loginRoute);
                        return;
                      }
                      if (!isInCart) {
                        bool success = await cartController.addToCart(product.id, variant.id);
                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to prepare checkout'), backgroundColor: Colors.red));
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
                      color: accentColor,
                      borderRadius: BorderRadius.circular(8.w),
                    ),
                    child: Center(
                      child: getCustomFont(
                          "Buy at \u20B9${product.currentPrice.toStringAsFixed(0)}", 14,
                          Colors.white, 1,
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
