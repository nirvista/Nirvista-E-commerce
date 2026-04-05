import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pet_shop/base/color_data.dart';
import 'package:pet_shop/base/constant.dart';
import 'package:pet_shop/base/data_file.dart';
import 'package:pet_shop/base/fetch_pixels.dart';
import 'package:pet_shop/base/get/route_key.dart';
import 'package:pet_shop/base/get/storage_controller.dart';
import 'package:pet_shop/base/widget_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../base/get/bottom_selection_controller.dart';
import '../../../base/get/home_controller.dart';
import '../../../base/get/product_data.dart';
import '../../model_ui/model_dummy_product.dart';

class TabHome extends StatefulWidget {
  const TabHome({Key? key}) : super(key: key);

  @override
  State<TabHome> createState() => _TabHomeState();
}

class _TabHomeState extends State<TabHome> with TickerProviderStateMixin {
  StorageController storeController = Get.find<StorageController>();
  ProductDataController productController = Get.find<ProductDataController>();
  HomeController homeController = Get.find<HomeController>();
  final controller = Get.find<BottomItemSelectionController>();

  List<DummyProduct> allProducts = DataFile.getAllDummyProducts();
  List<DummyProduct> bestSellingProducts = [];
  List<DummyProduct> topDealProducts = [];
  List<String> categories = [
    "for_you",
    "fashion",
    "mobiles",
    "beauty",
    "electronics",
    "home_decor"
  ];
  List<String> categoryLabels = [
    "For You",
    "Fashion",
    "Mobiles",
    "Beauty",
    "Electronics",
    "Home Decor"
  ];

  RxString selectedCategory = "for_you".obs;
  RxInt sliderPos = 0.obs;

  @override
  void initState() {
    super.initState();
    bestSellingProducts =
        allProducts.where((p) => p.isBestSelling).toList().take(6).toList();
    topDealProducts =
        allProducts.where((p) => p.isTopDeal).toList().take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    Constant.setupSize(context);
    double margin = FetchPixels.getDefaultHorSpaceFigma(context);

    return SafeArea(
      child: Column(
        children: [
          // Fixed Header
          _buildHeader(context, margin),
          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Category Tabs
                  _buildCategoryTabs(context, margin),
                  SizedBox(height: 20.h),
                  // Banner Carousel
                  _buildBannerCarousel(context, margin),
                  SizedBox(height: 20.h),
                  // Best Selling Products
                  _buildBestSellingSection(context, margin),
                  SizedBox(height: 20.h),
                  // Top Deals For You
                  _buildTopDealsSection(context, margin),
                  SizedBox(height: 20.h),
                  // Featured Brands
                  _buildFeaturedBrandsSection(context, margin),
                  SizedBox(height: 20.h),
                  // Popular Picks
                  _buildPopularPicksSection(context, margin),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double margin) {
    return Container(
      color: getCardColor(context),
      padding: EdgeInsets.symmetric(horizontal: margin, vertical: 12.h),
      child: Column(
        children: [
          // Row 1: Location only
          Row(
            children: [
              Icon(Icons.home, color: accentColor, size: 20.w),
              SizedBox(width: 8.w),
              getCustomFont("HOME", 14, getFontColor(context), 1,
                  fontWeight: FontWeight.w700),
              Spacer(),
              Icon(Icons.expand_more, color: getFontGreyColor(context), size: 20.w),
            ],
          ),
          SizedBox(height: 12.h),
          // Row 2: Search Bar
          Container(
            decoration: BoxDecoration(
              color: getGreyCardColor(context),
              borderRadius: BorderRadius.circular(12.w),
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
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
                    ),
                  ),
                ),
                Icon(Icons.camera_alt_outlined,
                    color: getFontGreyColor(context), size: 18.w),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(BuildContext context, double margin) {
    return Container(
      color: getCardColor(context),
      padding: EdgeInsets.symmetric(horizontal: margin, vertical: 12.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(
          () => Row(
            children: List.generate(
              categories.length,
              (index) {
                bool isSelected =
                    selectedCategory.value == categories[index];
                return InkWell(
                  onTap: () {
                    selectedCategory.value = categories[index];
                  },
                  child: Padding(
                    padding: EdgeInsets.only(right: 20.w),
                    child: Column(
                      children: [
                        getCustomFont(
                          categoryLabels[index],
                          14,
                          isSelected ? accentColor : getFontGreyColor(context),
                          1,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        if (isSelected)
                          Container(
                            height: 3.h,
                            width: 30.w,
                            margin: EdgeInsets.only(top: 4.h),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(2.h),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerCarousel(BuildContext context, double margin) {
    List<Map<String, String>> banners = [
      {
        "title": "Big Fashion Sale",
        "subtitle": "Up to 80% Off",
        "color": "#CDF5E7"
      },
      {
        "title": "Electronics Week",
        "subtitle": "Top Brands on Deals",
        "color": "#E8D5F2"
      },
      {
        "title": "Beauty Essentials",
        "subtitle": "Min 50% Off",
        "color": "#FFE5E5"
      },
    ];

    return SizedBox(
      height: 140.h,
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: margin),
        child: CarouselSlider(
          items: List.generate(banners.length, (index) {
            return Container(
              decoration: BoxDecoration(
                color: banners[index]["color"]!.toColor(),
                borderRadius: BorderRadius.circular(16.w),
              ),
              padding: EdgeInsets.all(16.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        getCustomFont(
                          banners[index]["title"]!,
                          16,
                          getFontColor(context),
                          1,
                          fontWeight: FontWeight.w600,
                        ),
                        SizedBox(height: 4.h),
                        getCustomFont(
                          banners[index]["subtitle"]!,
                          14,
                          getFontColor(context),
                          1,
                          fontWeight: FontWeight.w500,
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            getCustomFont(
                              "SHOP NOW",
                              12,
                              accentColor,
                              1,
                              fontWeight: FontWeight.w700,
                            ),
                            SizedBox(width: 6.w),
                            Icon(Icons.arrow_forward,
                                color: accentColor, size: 14.w),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.shopping_bag,
                      color: accentColor.withOpacity(0.3), size: 60.w),
                ],
              ),
            );
          }),
          options: CarouselOptions(
            viewportFraction: 1,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            onPageChanged: (index, reason) {
              sliderPos.value = index;
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBestSellingSection(BuildContext context, double margin) {
    return Container(
      color: getCardColor(context),
      padding: EdgeInsets.symmetric(vertical: margin),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: margin),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                getCustomFont("Best Selling", 18, getFontColor(context), 1,
                    fontWeight: FontWeight.w700),
                GestureDetector(
                  onTap: () {
                    storeController.setSelectedCategory("best_selling");
                    Constant.sendToNext(context, categoryProductsPageRoute);
                  },
                  child: getCustomFont("View All", 14, accentColor, 1,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 200.w,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: margin),
              itemCount: bestSellingProducts.length,
              itemBuilder: (context, index) {
                return _buildProductCard(
                  context,
                  bestSellingProducts[index],
                  width: 150.w,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopDealsSection(BuildContext context, double margin) {
    return Container(
      color: getCardColor(context),
      padding: EdgeInsets.symmetric(vertical: margin),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: margin),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                getCustomFont("Top Deals For You", 18, getFontColor(context), 1,
                    fontWeight: FontWeight.w700),
                GestureDetector(
                  onTap: () {
                    storeController.setSelectedCategory("top_deals");
                    Constant.sendToNext(context, categoryProductsPageRoute);
                  },
                  child: getCustomFont("View All", 14, accentColor, 1,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 200.w,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: margin),
              itemCount: topDealProducts.length,
              itemBuilder: (context, index) {
                return _buildProductCard(
                  context,
                  topDealProducts[index],
                  width: 150.w,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedBrandsSection(BuildContext context, double margin) {
    List<String> brands = DataFile.getFeaturedBrands();

    return Container(
      color: getCardColor(context),
      padding: EdgeInsets.symmetric(vertical: margin),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: margin),
            child: getCustomFont(
                "Featured Brands", 18, getFontColor(context), 1,
                fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 40.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: margin),
              itemCount: brands.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(right: 10.w),
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: getGreyCardColor(context),
                    borderRadius: BorderRadius.circular(20.w),
                    border: Border.all(color: dividerColor, width: 0.5),
                  ),
                  child: Center(
                    child: getCustomFont(brands[index], 13, getFontColor(context),
                        1,
                        fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularPicksSection(BuildContext context, double margin) {
    List<DummyProduct> popularProducts =
        allProducts.where((p) => p.isBestSelling || p.isTopDeal).toList();

    return Container(
      color: getCardColor(context),
      padding: EdgeInsets.symmetric(vertical: margin, horizontal: margin),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              getCustomFont("Popular Picks", 18, getFontColor(context), 1,
                  fontWeight: FontWeight.w700),
              Icon(Icons.arrow_forward,
                  color: getFontColor(context), size: 18.w),
            ],
          ),
          SizedBox(height: 16.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.w,
              childAspectRatio: 0.75,
            ),
            itemCount: popularProducts.take(4).length,
            itemBuilder: (context, index) {
              return _buildProductCard(
                context,
                popularProducts[index],
                width: double.infinity,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, DummyProduct product,
      {required double width}) {
    double discountPercent = (((product.originalPrice - product.price) /
                product.originalPrice) *
            100)
        .toDouble();

    return InkWell(
      onTap: () {
        storeController.setSelectedDummyProduct(product);
        Constant.sendToNext(context, productDetailScreenRoute);
      },
      child: SizedBox(
        width: width,
        child: Container(
          decoration: BoxDecoration(
            color: getScaffoldColor(context),
            borderRadius: BorderRadius.circular(12.w),
            border: Border.all(color: dividerColor, width: 0.5),
          ),
          padding: EdgeInsets.all(8.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.w),
                    color: getGreyCardColor(context),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.w),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          color: accentColor,
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          Icon(Icons.image_not_supported,
                              color: getFontGreyColor(context)),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              // Brand
              getCustomFont(product.brand, 11, getFontGreyColor(context), 1,
                  fontWeight: FontWeight.w500),
              SizedBox(height: 4.h),
              // Product Name
              getCustomFont(product.name, 12, getFontColor(context), 2,
                  fontWeight: FontWeight.w600,
                  overflow: TextOverflow.ellipsis),
              SizedBox(height: 4.h),
              // Rating
              Row(
                children: [
                  Icon(Icons.star, color: ratedColor, size: 12.w),
                  SizedBox(width: 4.w),
                  getCustomFont(
                      product.rating.toStringAsFixed(1),
                      11,
                      getFontColor(context),
                      1,
                      fontWeight: FontWeight.w500),
                  SizedBox(width: 4.w),
                  getCustomFont("(${product.reviewCount})", 10,
                      getFontGreyColor(context), 1,
                      fontWeight: FontWeight.w400),
                ],
              ),
              SizedBox(height: 8.h),
              // Price Row
              Row(
                children: [
                  getCustomFont(
                      "₹${product.price.toStringAsFixed(0)}",
                      13,
                      accentColor,
                      1,
                      fontWeight: FontWeight.w700),
                  SizedBox(width: 6.w),
                  getCustomFont(
                      "₹${product.originalPrice.toStringAsFixed(0)}",
                      11,
                      getFontGreyColor(context),
                      1,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.lineThrough),
                ],
              ),
              // Discount Badge
              if (discountPercent > 0)
                Container(
                  margin: EdgeInsets.only(top: 6.h),
                  padding:
                      EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: redColor,
                    borderRadius: BorderRadius.circular(4.w),
                  ),
                  child: getCustomFont(
                      "${discountPercent.toStringAsFixed(0)}% OFF",
                      9,
                      Colors.white,
                      1,
                      fontWeight: FontWeight.w700),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
