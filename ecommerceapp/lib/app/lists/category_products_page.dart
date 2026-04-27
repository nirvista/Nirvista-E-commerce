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
import '../../../services/enrichment_service.dart';

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
    _loadInitialProducts();
  }

  Future<void> _loadInitialProducts() async {
    String category = storageController.selectedCategory.value;
    
    if (category == "best_selling") {
      productsFuture = _fetchProducts(ProductApiService.getAllProducts());
    } else if (category == "new_arrivals") {
      productsFuture = _fetchAndSortProducts(ProductApiService.getAllProducts(), "new_arrivals");
    } else if (category == "top_deals") {
      productsFuture = _fetchAndSortProducts(ProductApiService.getAllProducts(), "top_deals");
    } else if (category == "all" || category == "for_you" || category.isEmpty) {
      // Scrape from top categories (matches home screen fix)
      productsFuture = _scrapeAllProducts();
    } else if (category.startsWith("brand_")) {
      String brandId = category.replaceFirst("brand_", "");
      productsFuture = _fetchProducts(BrandApiService.getProductsByBrand(brandId));
    } else {
      productsFuture = _fetchProducts(CategoryApiService.getProductsByCategory(category));
    }
  }

  Future<List<ProductModel>> _scrapeAllProducts() async {
    String category = storageController.selectedCategory.value;
    final catRes = await CategoryApiService.getAllCategories();
    if (!catRes['success']) return [];
    List<CategoryModel> cats = (catRes['data'] as List).take(3).map((e) => CategoryModel.fromJson(e)).toList();
    
    final results = await Future.wait(cats.map((c) => CategoryApiService.getProductsByCategory(c.id)));
    List<ProductModel> allProds = [];
    for (var r in results) {
       if (r['success']) {
         List<dynamic> data = r['data'];
         allProds.addAll(data.map((e) => ProductModel.fromJson(e)).toList());
       }
    }
    final Map<String, ProductModel> unique = {for (var p in allProds) p.id: p};
    List<ProductModel> merged = unique.values.toList();

    if (category == "top_deals") {
      merged = merged.where((p) => p.variants.any((v) => v.discountPrice != null && v.discountPrice! > 0)).toList();
    }
    
    // Relaxed cleanup: Only hide if the product is BOTH missing variants/price AND missing images.
    merged.removeWhere((p) => (p.variants.isEmpty && p.originalPrice <= 0) && p.imageUrl.isEmpty);
    
    loadedProducts = merged;
    return loadedProducts;
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
      
      // Enrich with missing variants using the background enrichment service
      await EnrichmentService.enrichProducts(prods);

      // Cleanup broken products
      prods.removeWhere((p) => p.variants.isEmpty && p.originalPrice <= 0 && p.imageUrl.isEmpty);
      
      loadedProducts = prods;
      return prods;
    }
    loadedProducts = [];
    return [];
  }

  Future<List<ProductModel>> _fetchAndSortProducts(Future<Map<String, dynamic>> apiCall, String sortType) async {
    final prods = await _fetchProducts(apiCall);
    
    if (sortType == "top_deals") {
       prods.sort((a, b) {
         int cmp = b.rating.compareTo(a.rating);
         if (cmp != 0) return cmp;
         return b.id.compareTo(a.id);
       });
    } else if (sortType == "new_arrivals") {
       prods.sort((a, b) => b.id.compareTo(a.id));
    }
    
    loadedProducts = prods;
    return prods;
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
                            childAspectRatio: 0.65,
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
          SizedBox(width: 24.w), // Replaced search icon with spacer for alignment
        ],
      ),
    );
  }

  Widget _buildProductCard(
      BuildContext context, ProductModel product) {
    double basePrice = product.originalPrice;
    double currentPrice = product.currentPrice;
    double discountPercent = 0.0;
    
    // Add safety check for zero or negative prices
    if (basePrice <= 0) basePrice = currentPrice;
    if (currentPrice <= 0) currentPrice = basePrice;
    
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
                  child: (product.imageUrl.isNotEmpty && !product.imageUrl.contains("example.com")) 
                    ? CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          color: accentColor,
                          strokeWidth: 2,
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          Icon(Icons.image_not_supported,
                              color: getFontGreyColor(context)),
                    )
                    : Container(
                        color: getGreyCardColor(context),
                        child: Icon(Icons.shopping_bag_outlined, color: getFontGreyColor(context), size: 40.w),
                      ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            // Brand
            getCustomFont(product.brandName, 11, getFontGreyColor(context), 1,
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
                      14,
                      const Color(0xFF4B5563),
                      1,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: const Color(0xFF4B5563),
                      decorationThickness: 1.2,
                      txtHeight: 1.4),
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