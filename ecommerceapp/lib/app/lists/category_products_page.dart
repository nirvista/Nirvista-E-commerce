import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:pet_shop/app/model_ui/model_dummy_product.dart';

class CategoryProductsPage extends StatefulWidget {
  const CategoryProductsPage({Key? key}) : super(key: key);

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  StorageController storageController = Get.find<StorageController>();
  RxString selectedSubCategory = "all".obs;
  List<DummyProduct> categoryProducts = [];
  List<DummyProduct> filteredProducts = [];
  Map<String, List<String>> subCategoriesMap = {
    "fashion": ["All", "Kurta", "Shirts", "Dresses", "Jeans", "Sarees"],
    "mobiles": ["All", "Smartphones", "Earphones", "Chargers", "Cases"],
    "beauty": ["All", "Lipstick", "Foundation", "Eye Makeup", "Face Wash", "Moisturizer"],
    "electronics": ["All", "Earbuds", "Hair Appliances", "Smart Watches", "Power Banks"],
    "home_decor": ["All", "Clocks", "Candles", "Frames", "Lamps"],
  };

  @override
  void initState() {
    super.initState();
    String category = storageController.selectedCategory.value;
    if (category == "best_selling") {
      categoryProducts = DataFile.getAllDummyProducts()
          .where((p) => p.isBestSelling)
          .toList();
    } else if (category == "top_deals") {
      categoryProducts = DataFile.getAllDummyProducts()
          .where((p) => p.isTopDeal)
          .toList();
    } else if (category == "all") {
      categoryProducts = DataFile.getAllDummyProducts();
    } else if (category.isNotEmpty && category != "for_you") {
      categoryProducts = DataFile.getProductsByCategory(category);
    }
    filteredProducts = categoryProducts;
  }

  void _filterBySubCategory(String subCategory) {
    if (subCategory.toLowerCase() == "all") {
      filteredProducts = categoryProducts;
    } else {
      filteredProducts = categoryProducts
          .where((p) => p.subCategory.toLowerCase().contains(subCategory.toLowerCase()))
          .toList();
    }
    selectedSubCategory.value = subCategory;
  }

  @override
  Widget build(BuildContext context) {
    Constant.setupSize(context);
    double margin = FetchPixels.getDefaultHorSpaceFigma(context);
    String category = storageController.selectedCategory.value.isEmpty
        ? "fashion"
        : storageController.selectedCategory.value;
    String categoryTitle;
    if (category == "best_selling") {
      categoryTitle = "BEST SELLING PRODUCTS";
    } else if (category == "top_deals") {
      categoryTitle = "TOP DEALS FOR YOU";
    } else if (category == "all") {
      categoryTitle = "ALL PRODUCTS";
    } else {
      categoryTitle = category.replaceAll("_", " ").toUpperCase();
    }

    List<String> subCategories = subCategoriesMap[category] ?? ["All"];
    List<String> brands = _getBrandsForCategory(category);

    return Scaffold(
      backgroundColor: getScaffoldColor(context),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(context, categoryTitle, margin),
            // Sub-categories horizontal scroll
            _buildSubCategoriesTabs(context, subCategories, margin),
            SizedBox(height: 8.h),
            // Brand filter pills
            _buildBrandFilterSection(context, brands, margin),
            SizedBox(height: 12.h),
            // Products Grid
            Expanded(
              child: Obx(
                () => filteredProducts.isEmpty
                    ? Center(
                        child: getCustomFont(
                            "No products found",
                            16,
                            getFontColor(context),
                            1,
                            fontWeight: FontWeight.w500),
                      )
                    : GridView.builder(
                        padding:
                            EdgeInsets.symmetric(horizontal: margin, vertical: 8.h),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12.w,
                          mainAxisSpacing: 12.w,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          return _buildProductCard(
                            context,
                            filteredProducts[index],
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(
      BuildContext context, String categoryTitle, double margin) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor, lightAccentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: margin, vertical: 16.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Constant.backToPrev(context),
            child: Icon(Icons.arrow_back,
                color: Colors.white, size: 24.w),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: getCustomFont(categoryTitle, 16, Colors.white, 1,
                fontWeight: FontWeight.w700),
          ),
          Icon(Icons.search, color: Colors.white, size: 24.w),
        ],
      ),
    );
  }

  Widget _buildSubCategoriesTabs(BuildContext context, List<String> subCategories,
      double margin) {
    return Container(
      color: getCardColor(context),
      padding: EdgeInsets.symmetric(horizontal: margin, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          getCustomFont("Filter by Category", 12, getFontGreyColor(context), 1,
              fontWeight: FontWeight.w600),
          SizedBox(height: 10.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(
              () => Row(
                children: List.generate(
                  subCategories.length,
                  (index) {
                    String subCategory = subCategories[index];
                    bool isSelected = selectedSubCategory.value == subCategory;
                    return GestureDetector(
                      onTap: () {
                        _filterBySubCategory(subCategory);
                      },
                      child: Container(
                        margin: EdgeInsets.only(right: 10.w),
                        padding:
                            EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accentColor
                              : lightAccentColor,
                          borderRadius: BorderRadius.circular(20.w),
                          border: Border.all(
                            color: isSelected ? accentColor : dividerColor,
                            width: 1,
                          ),
                        ),
                        child: getCustomFont(
                            subCategory,
                            12,
                            isSelected ? Colors.white : accentColor,
                            1,
                            fontWeight: FontWeight.w600),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandFilterSection(
      BuildContext context, List<String> brands, double margin) {
    return Container(
      color: getCardColor(context),
      padding: EdgeInsets.symmetric(horizontal: margin, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          getCustomFont("Featured Brands", 12, getFontColor(context), 1,
              fontWeight: FontWeight.w600),
          SizedBox(height: 10.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                brands.length,
                (index) {
                  return Container(
                    margin: EdgeInsets.only(right: 10.w),
                    padding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: lightAccentColor,
                      borderRadius: BorderRadius.circular(20.w),
                      border: Border.all(color: accentColor, width: 1),
                    ),
                    child: getCustomFont(brands[index], 11,
                        accentColor, 1,
                        fontWeight: FontWeight.w600),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
      BuildContext context, DummyProduct product) {
    double discountPercent =
        (((product.originalPrice - product.price) / product.originalPrice) * 100);

    return InkWell(
      onTap: () {
        storageController.setSelectedDummyProduct(product);
        Constant.sendToNext(context, productDetailScreenRoute);
      },
      child: Container(
        decoration: BoxDecoration(
          color: getCardColor(context),
          borderRadius: BorderRadius.circular(12.w),
          border: Border.all(color: dividerColor, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.15),
              blurRadius: 8.w,
              offset: Offset(0, 4),
            ),
          ],
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
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
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
    );
  }

  List<String> _getBrandsForCategory(String category) {
    List<DummyProduct> products = DataFile.getProductsByCategory(category);
    Set<String> uniqueBrands = {};
    for (var product in products) {
      uniqueBrands.add(product.brand);
    }
    return uniqueBrands.toList();
  }
}
