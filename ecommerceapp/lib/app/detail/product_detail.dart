import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pet_shop/base/color_data.dart';
import 'package:pet_shop/base/constant.dart';
import 'package:pet_shop/base/fetch_pixels.dart';
import 'package:pet_shop/base/get/storage_controller.dart';
import 'package:pet_shop/base/widget_utils.dart';
import 'package:pet_shop/base/pref_data.dart';
import 'package:pet_shop/app/model_ui/model_dummy_product.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ProductDetailScreen();
}

class _ProductDetailScreen extends State<ProductDetailScreen>
    with TickerProviderStateMixin {
  StorageController storageController = Get.find<StorageController>();
  RxString selectedColor = "".obs;
  RxString selectedSize = "".obs;
  RxInt quantity = 1.obs;
  RxBool isWishlisted = false.obs;
  PrefData prefData = PrefData();

  @override
  void initState() {
    super.initState();
    DummyProduct? product = storageController.selectedDummyProduct;
    if (product != null) {
      selectedColor.value =
          product.colors.isNotEmpty ? product.colors[0] : "";
      selectedSize.value = product.sizes.isNotEmpty ? product.sizes[0] : "";
      _loadWishlistStatus(product.id);
    }
  }

  void _loadWishlistStatus(int productId) async {
    List<String> favList = await prefData.getFavouriteList();
    isWishlisted.value = favList.contains(productId.toString());
  }

  void _toggleWishlist(int productId) async {
    List<String> favList = await prefData.getFavouriteList();
    String productIdStr = productId.toString();

    if (favList.contains(productIdStr)) {
      favList.remove(productIdStr);
    } else {
      favList.add(productIdStr);
    }

    await prefData.setFavouriteList(favList);
    isWishlisted.value = !isWishlisted.value;
  }

  @override
  Widget build(BuildContext context) {
    Constant.setupSize(context);
    DummyProduct? product = storageController.selectedDummyProduct;

    if (product == null) {
      return Scaffold(
        body: Center(
          child: getCustomFont("Product not found", 16, getFontColor(context), 1),
        ),
      );
    }

    double discountPercent =
        (((product.originalPrice - product.price) / product.originalPrice) * 100);
    double margin = FetchPixels.getDefaultHorSpaceFigma(context);

    return Scaffold(
      backgroundColor: getScaffoldColor(context),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(context, margin),
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Product Image
                    _buildProductImage(context, product, margin),
                    SizedBox(height: 16.h),
                    // Rating Pill
                    _buildRatingPill(context, product, margin),
                    SizedBox(height: 16.h),
                    // Colors Section
                    if (product.colors.isNotEmpty)
                      _buildColorsSection(context, product, margin),
                    // Sizes Section
                    if (product.sizes.isNotEmpty)
                      _buildSizesSection(context, product, margin),
                    // Brand and Price Info
                    _buildBrandAndPriceSection(context, product, margin),
                    SizedBox(height: 16.h),
                    // Delivery Details
                    _buildDeliveryDetails(context, product, margin),
                    SizedBox(height: 16.h),
                    // Trust Badges
                    _buildTrustBadges(context, margin),
                    SizedBox(height: 16.h),
                    // Similar Products
                    if (product.colors.isNotEmpty || product.sizes.isNotEmpty)
                      _buildSimilarProductsSection(context, product, margin),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
            // Bottom Buttons
            _buildBottomButtons(context, product),
          ],
        ),
      ),
    );
  }

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
                        hintStyle:
                            TextStyle(color: getFontGreyColor(context)),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 8.h),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Icon(Icons.shopping_cart_outlined,
              color: getFontColor(context), size: 24.w),
        ],
      ),
    );
  }

  Widget _buildProductImage(
      BuildContext context, DummyProduct product, double margin) {
    return Stack(
      children: [
        // Product Image
        Container(
          width: double.infinity,
          height: 300.h,
          color: getGreyCardColor(context),
          child: ClipRRect(
            child: CachedNetworkImage(
              imageUrl: product.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Center(
                child: CircularProgressIndicator(color: accentColor),
              ),
              errorWidget: (context, url, error) =>
                  Icon(Icons.image_not_supported, size: 50.w),
            ),
          ),
        ),
        // Wishlist Heart Button
        Positioned(
          top: 12.h,
          right: 12.w,
          child: Obx(
            () => GestureDetector(
              onTap: () => _toggleWishlist(product.id),
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
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isWishlisted.value ? Icons.favorite : Icons.favorite_border,
                    color: isWishlisted.value ? accentColor : getFontGreyColor(context),
                    size: 24.w,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingPill(
      BuildContext context, DummyProduct product, double margin) {
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
          getCustomFont(product.rating.toStringAsFixed(1),
              13, getFontColor(context), 1,
              fontWeight: FontWeight.w700),
          SizedBox(width: 8.w),
          Container(
            width: 1.w,
            height: 14.h,
            color: dividerColor,
          ),
          SizedBox(width: 8.w),
          getCustomFont("${product.reviewCount}+ Ratings", 12,
              getFontGreyColor(context), 1,
              fontWeight: FontWeight.w500),
        ],
      ),
    );
  }

  Widget _buildColorsSection(
      BuildContext context, DummyProduct product, double margin) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: margin, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => getCustomFont(
                "Selected Color: ${selectedColor.value}", 14, getFontColor(context), 1,
                fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 60.w,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: product.colors.length,
              itemBuilder: (context, index) {
                String color = product.colors[index];
                return Obx(
                  () => GestureDetector(
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
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(
                            "https://picsum.photos/seed/${product.id}${color}/200/200",
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Center(
                        child: getCustomFont(color, 10, Colors.white, 1,
                            fontWeight: FontWeight.w600,
                            textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizesSection(
      BuildContext context, DummyProduct product, double margin) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: margin, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              getCustomFont(
                  "Select Size", 14, getFontColor(context), 1,
                  fontWeight: FontWeight.w600),
              GestureDetector(
                onTap: () {
                  // Size chart action
                },
                child: getCustomFont(
                    "Size Chart", 12, accentColor, 1,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Obx(
            () => Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              children: product.sizes.map((size) {
                bool isSelected = selectedSize.value == size;
                return GestureDetector(
                  onTap: () {
                    selectedSize.value = size;
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
                    child: getCustomFont(
                        size,
                        12,
                        isSelected ? Colors.white : getFontColor(context),
                        1,
                        fontWeight: FontWeight.w600),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandAndPriceSection(
      BuildContext context, DummyProduct product, double margin) {
    double discountPercent =
        (((product.originalPrice - product.price) / product.originalPrice) * 100);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: margin, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              getCustomFont(product.brand, 14, getFontGreyColor(context), 1,
                  fontWeight: FontWeight.w700),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: () {},
                child: getCustomFont(
                    "Visit Store", 12, accentColor, 1,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          getCustomFont(product.name, 16, getFontColor(context), 2,
              fontWeight: FontWeight.w700),
          SizedBox(height: 12.h),
          Row(
            children: [
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
                  "₹${product.originalPrice.toStringAsFixed(0)}", 12,
                  getFontGreyColor(context), 1,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.lineThrough),
            ],
          ),
          SizedBox(height: 8.h),
          getCustomFont(
              "₹${product.price.toStringAsFixed(0)}", 20, accentColor, 1,
              fontWeight: FontWeight.w800),
        ],
      ),
    );
  }

  Widget _buildDeliveryDetails(
      BuildContext context, DummyProduct product, double margin) {
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
              Expanded(
                child: getCustomFont("No.23, Sri Krishna St, Santhi Naga...",
                    12, getFontColor(context), 1,
                    fontWeight: FontWeight.w500),
              ),
              Icon(Icons.arrow_forward, color: getFontGreyColor(context), size: 16.w),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Icon(Icons.local_shipping, color: getFontColor(context), size: 16.w),
              SizedBox(width: 8.w),
              getCustomFont(
                  "Delivery by 8 Apr, Wed", 12, getFontColor(context), 1,
                  fontWeight: FontWeight.w500),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Icon(Icons.store, color: getFontColor(context), size: 16.w),
              SizedBox(width: 8.w),
              getCustomFont(
                  "Fulfilled by ${product.brand}", 12, getFontColor(context), 1,
                  fontWeight: FontWeight.w500),
            ],
          ),
          SizedBox(height: 12.h),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {},
              child: getCustomFont(
                  "See other sellers", 11, accentColor, 1,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadges(BuildContext context, double margin) {
    List<Map<String, dynamic>> badges = [
      {"icon": Icons.schedule, "title": "10-Day Return", "desc": "Change of mind"},
      {
        "icon": Icons.money,
        "title": "Cash on Delivery",
        "desc": "Pay on delivery"
      },
      {"icon": Icons.verified, "title": "Brand Assured", "desc": "Official product"},
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: margin),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          badges.length,
          (index) => Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 6.w),
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                border: Border.all(color: dividerColor),
                borderRadius: BorderRadius.circular(8.w),
              ),
              child: Column(
                children: [
                  Icon(badges[index]["icon"] as IconData,
                      color: accentColor, size: 20.w),
                  SizedBox(height: 8.h),
                  getCustomFont(badges[index]["title"], 10,
                      getFontColor(context), 1,
                      fontWeight: FontWeight.w600,
                      textAlign: TextAlign.center),
                  SizedBox(height: 4.h),
                  getCustomFont(badges[index]["desc"], 8,
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

  Widget _buildSimilarProductsSection(
      BuildContext context, DummyProduct product, double margin) {
    // Get similar products from same category
    List<DummyProduct> similarProducts = [];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: margin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              getCustomFont("Similar Products", 16, getFontColor(context), 1,
                  fontWeight: FontWeight.w700),
              Icon(Icons.arrow_forward,
                  color: getFontColor(context), size: 18.w),
            ],
          ),
          SizedBox(height: 12.h),
          // Similar products carousel would go here
          getCustomFont("More products available in category",
              12, getFontGreyColor(context), 1,
              fontWeight: FontWeight.w500),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context, DummyProduct product) {
    return Container(
      color: getCardColor(context),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Add to cart logic
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
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Buy now logic
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color: ratedColor,
                    borderRadius: BorderRadius.circular(8.w),
                  ),
                  child: Center(
                    child: getCustomFont(
                        "Buy at ₹${product.price.toStringAsFixed(0)}", 14,
                        Colors.black, 1,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
