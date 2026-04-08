import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pet_shop/base/color_data.dart';
import 'package:pet_shop/base/constant.dart';
import 'package:pet_shop/base/fetch_pixels.dart';
import 'package:pet_shop/base/get/route_key.dart';
import 'package:pet_shop/base/get/storage_controller.dart';
import 'package:pet_shop/base/widget_utils.dart';
import '../../app/model/api_models.dart';
import '../../../services/product_api.dart';
import '../../../services/category_api.dart';
import '../../../services/brand_api.dart';

class CategoryProductsPage extends StatefulWidget {
  const CategoryProductsPage({Key? key}) : super(key: key);

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  StorageController storageController = Get.find<StorageController>();
  RxString selectedSubCategory = "all".obs;
  
  Future<List<ProductModel>>? productsFuture;
  List<ProductModel> loadedProducts = [];


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
      productsFuture = _fetchProducts(ProductApiService.getAllProducts());
    } else if (category == "top_deals") {
      productsFuture = _fetchProducts(ProductApiService.getTopRatedProducts());
    } else if (category == "new_arrivals") {
      productsFuture = _fetchProducts(ProductApiService.getNewArrivals());
    } else if (category == "all" || category == "for_you" || category.isEmpty) {
      productsFuture = _fetchProducts(ProductApiService.getAllProducts());
    } else if (category.startsWith("brand_")) {
      String brandId = category.replaceFirst("brand_", "");
      productsFuture = _fetchProducts(BrandApiService.getProductsByBrand(brandId));
    } else {
      productsFuture = _fetchProducts(CategoryApiService.getProductsByCategory(category));
    }
  }

  Future<List<ProductModel>> _fetchProducts(Future<Map<String, dynamic>> apiCall) async {
    final res = await apiCall;
    if (res['success']) {
      dynamic data = res['data'];
      List<dynamic> productsList = [];
      if (data is List) {
        productsList = data;
      } else if (data is Map && data['products'] is List) {
        productsList = data['products'];
      }
      var prods = productsList.map((e) => ProductModel.fromJson(e)).toList();
      loadedProducts = prods;
      return prods;
    }
    loadedProducts = [];
    return [];
  }

  List<ProductModel> _getFilteredProducts() {
    if (selectedSubCategory.value.toLowerCase() == "all") {
      return loadedProducts;
    }
    // Filter logic using description or tags if subCategory is not explicitly modeled
    return loadedProducts.where((p) {
       var matchesDesc = p.description?.toLowerCase().contains(selectedSubCategory.value.toLowerCase()) ?? false;
       var matchesTitle = p.title.toLowerCase().contains(selectedSubCategory.value.toLowerCase());
       return matchesDesc || matchesTitle;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    Constant.setupSize(context);
    double margin = FetchPixels.getDefaultHorSpaceFigma(context);
    String category = storageController.selectedCategory.value.isEmpty
        ? "fashion"
        : storageController.selectedCategory.value;
        
    String categoryTitle = storageController.selectedCategoryName.value;
    if (categoryTitle.isEmpty) {
      if (category == "best_selling") {
        categoryTitle = "BEST SELLING PRODUCTS";
      } else if (category == "top_deals") {
        categoryTitle = "TOP DEALS FOR YOU";
      } else if (category == "new_arrivals") {
        categoryTitle = "NEW ARRIVALS";
      } else if (category == "all" || category == "for_you") {
        categoryTitle = "ALL PRODUCTS";
      } else {
        categoryTitle = category.replaceAll("_", " ").toUpperCase();
      }
    } else {
      categoryTitle = categoryTitle.toUpperCase();
    }

    List<String> subCategories = subCategoriesMap[category] ?? ["All"];
    
    // Extracted Unique Brands
    List<String> brands = loadedProducts.map((e) => e.brandId).toSet().toList();
    if (brands.isEmpty) {
       brands = ["Nike", "Adidas", "Puma"]; // Fallback if empty in UI rendering
    }

    return Scaffold(
      backgroundColor: getScaffoldColor(context),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(context, categoryTitle, margin),
            SizedBox(height: 12.h),
            // Products Grid
            Expanded(
              child: FutureBuilder<List<ProductModel>>(
                future: productsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: accentColor));
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: getCustomFont(
                          "No products found",
                          16,
                          getFontColor(context),
                          1,
                          fontWeight: FontWeight.w500),
                    );
                  }

                  return Obx(() {
                    var filtered = _getFilteredProducts();
                    if (filtered.isEmpty) {
                      return Center(child: Text("No items match filter."));
                    }
                    return GridView.builder(
                          padding:
                              EdgeInsets.symmetric(horizontal: margin, vertical: 8.h),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12.w,
                            mainAxisSpacing: 12.w,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            return _buildProductCard(
                              context,
                              filtered[index],
                            );
                          },
                        );
                  });
                }
              )
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

  Widget _buildProductCard(
      BuildContext context, ProductModel product) {
    double basePrice = product.originalPrice;
    double currentPrice = product.currentPrice;
    double discountPercent = 0.0;
    
    if (basePrice > 0 && currentPrice > 0 && basePrice > currentPrice) {
      discountPercent = (((basePrice - currentPrice) / basePrice) * 100).toDouble();
    } else {
      basePrice = currentPrice;
    }

    return InkWell(
      onTap: () {
        storageController.setSelectedProductModel(product);
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
                    imageUrl: product.imageUrl.isNotEmpty ? product.imageUrl : 'https://placehold.co/400',
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
            getCustomFont(product.brandId, 11, getFontGreyColor(context), 1,
                fontWeight: FontWeight.w500),
            SizedBox(height: 4.h),
            // Product Name
            getCustomFont(product.title, 12, getFontColor(context), 2,
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
              ],
            ),
            SizedBox(height: 8.h),
            // Price Row
            Row(
              children: [
                getCustomFont(
                    "₹${currentPrice.toStringAsFixed(0)}",
                    13,
                    accentColor,
                    1,
                    fontWeight: FontWeight.w700),
                SizedBox(width: 6.w),
                if (discountPercent > 0)
                  getCustomFont(
                      "₹${basePrice.toStringAsFixed(0)}",
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
}
