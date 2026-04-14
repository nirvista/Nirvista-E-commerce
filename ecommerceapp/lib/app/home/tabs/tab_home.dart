import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pet_shop/base/color_data.dart';
import 'package:pet_shop/base/constant.dart';
import 'package:pet_shop/base/fetch_pixels.dart';
import 'package:pet_shop/base/get/route_key.dart';
import 'package:pet_shop/base/get/storage_controller.dart';
import 'package:pet_shop/base/widget_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../base/get/bottom_selection_controller.dart';
import '../../../base/get/home_controller.dart';
import '../../../base/get/product_data.dart';
import '../../model/api_models.dart';
import '../../../services/product_api.dart';
import '../../../services/brand_api.dart';
import '../../../services/category_api.dart';
import '../../../services/address_api.dart';
import '../../../base/get/login_data_controller.dart';

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
  final loginController = Get.find<LoginDataController>();

  RxString userCity = "Set Location".obs;
  
  // Reactive product lists
  RxList<ProductModel> bestSellingList = <ProductModel>[].obs;
  RxList<ProductModel> topDealsList = <ProductModel>[].obs;
  RxList<ProductModel> popularPicksList = <ProductModel>[].obs;

  Future<List<BrandModel>>? brandsFuture;
  Future<List<CategoryModel>>? categoriesFuture;

  RxString selectedCategory = "for_you".obs;
  RxString selectedBrand = "".obs;
  RxInt sliderPos = 0.obs;
  RxBool isSectionLoading = false.obs;

  @override
  void initState() {
    super.initState();
    _refreshAllSections();
    brandsFuture = _fetchBrands();
    categoriesFuture = _fetchCategories();
    _fetchUserLocation();
  }

  Future<void> _refreshAllSections() async {
    isSectionLoading.value = true;
    try {
      // Step 1: Fetch categories first to use them for scraping 'For You' products
      final catRes = await CategoryApiService.getAllCategories();
      List<CategoryModel> cats = [];
      if (catRes['success']) {
        cats = (catRes['data'] as List).map((e) => CategoryModel.fromJson(e)).toList();
      }

      if (cats.isEmpty) {
        // Fallback to restricted API if categories are empty
        final results = await Future.wait([
          _fetchProducts(ProductApiService.getAllProducts()),
          _fetchProducts(ProductApiService.getTopRatedProducts()),
          _fetchProducts(ProductApiService.getNewArrivals()),
        ]);
        bestSellingList.value = results[0];
        topDealsList.value = results[1];
        popularPicksList.value = results[2];
        return;
      }

      // Step 2: Scrape products from the first 3 categories (bypass restricted Product API)
      final scrapeResults = await Future.wait(
        cats.take(3).map((c) => CategoryApiService.getProductsByCategory(c.id))
      );

      List<ProductModel> allScraped = [];
      for (var res in scrapeResults) {
        if (res['success']) {
          List<dynamic> data = res['data'];
          allScraped.addAll(data.map((e) => ProductModel.fromJson(e)).toList());
        }
      }

      // Deduplicate by ID
      final Map<String, ProductModel> uniqueProds = {for (var p in allScraped) p.id: p};
      final mergedProducts = uniqueProds.values.toList();

      if (mergedProducts.isEmpty) {
        // Ultimate fallback
        bestSellingList.clear();
        topDealsList.clear();
        popularPicksList.clear();
      } else {
        bestSellingList.value = mergedProducts;
        topDealsList.value = mergedProducts.where((p) => p.variants.any((v) => v.discountPrice != null && v.discountPrice! > 0)).toList();
        popularPicksList.value = mergedProducts;
      }

    } catch (e) {
      print("Error refreshing sections: $e");
    } finally {
      isSectionLoading.value = false;
    }
  }

  Future<void> _updateCategoryProducts(String catId) async {
    if (catId == "for_you") {
      _refreshAllSections();
      return;
    }

    isSectionLoading.value = true;
    try {
      final res = await CategoryApiService.getProductsByCategory(catId);
      if (res['success']) {
        List<dynamic> data = res['data'];
        final products = data.map((e) => ProductModel.fromJson(e)).toList();
        
        // Populate all sections with category products
        // In a real app, you might have category-specific best sellers, 
        // but here we'll show the category products in these sections.
        bestSellingList.value = products;
        topDealsList.value = products.where((p) => p.variants.any((v) => v.discountPrice != null && v.discountPrice! > 0)).toList();
        popularPicksList.value = products;
      }
    } catch (e) {
      print("Error updating category products: $e");
    } finally {
      isSectionLoading.value = false;
    }
  }

  Future<void> _fetchUserLocation() async {
    final token = loginController.accessToken;
    if (token != null && token.isNotEmpty) {
      try {
        final res = await AddressApiService.getUserAddresses(token);
        if (res['success'] && res['data'] != null && (res['data'] as List).isNotEmpty) {
          final addresses = (res['data'] as List).map((e) => AddressModel.fromJson(e)).toList();
          final defaultAddr = addresses.where((a) => a.isDefaultShipping).toList();
          if (defaultAddr.isNotEmpty) {
            userCity.value = defaultAddr.first.city;
          } else {
            userCity.value = addresses.first.city;
          }
        }
      } catch (_) {}
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
      return productsList.map((e) => ProductModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<CategoryModel>> _fetchCategories() async {
    final res = await CategoryApiService.getAllCategories();
    if (res['success']) {
      List<dynamic> data = res['data'];
      return data.map((e) => CategoryModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<BrandModel>> _fetchBrands() async {
    final res = await BrandApiService.getAllBrands();
    if (res['success']) {
      List<dynamic> data = res['data'];
      var b = data.map((e) => BrandModel.fromJson(e)).toList();
      if (selectedBrand.value.isEmpty) {
        selectedBrand.value = 'all';
      }
      return b;
    }
    return [];
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
                  // Popular Picks
                  _buildPopularPicksSection(context, margin),
                  SizedBox(height: 20.h),
                  // Featured Brands
                  _buildFeaturedBrandsSection(context, margin),
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
          InkWell(
            onTap: () {
              showAddressSelectorBottomSheet(context);
            },
            child: Row(
              children: [
                Icon(Icons.location_on, color: accentColor, size: 20.w),
                SizedBox(width: 8.w),
                Obx(() => getCustomFont(userCity.value.toUpperCase(), 14, getFontColor(context), 1,
                    fontWeight: FontWeight.w700)),
                Spacer(),
                Icon(Icons.expand_more, color: getFontGreyColor(context), size: 20.w),
              ],
            ),
          ),
          SizedBox(height: 12.h),
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
      child: FutureBuilder<List<CategoryModel>>(
        future: categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: accentColor));
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return SizedBox(); // fallback if no categories
          }

          List<CategoryModel> apiCategories = snapshot.data!;
          
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(
              () => Row(
                children: [
                  // Default 'For You' option
                  _buildSingleCategoryTab(context, 'for_you', 'For You'),
                  ...List.generate(
                    apiCategories.length,
                    (index) {
                      return _buildSingleCategoryTab(context, apiCategories[index].id, apiCategories[index].name);
                    },
                  ),
                ]
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildSingleCategoryTab(BuildContext context, String catId, String catName) {
    bool isSelected = selectedCategory.value == catId;
    return InkWell(
      onTap: () {
        if (selectedCategory.value == catId) return;
        selectedCategory.value = catId;
        storeController.setSelectedCategory(catId);
        storeController.setSelectedCategoryName(catName);
        _updateCategoryProducts(catId);
      },
      child: Padding(
        padding: EdgeInsets.only(right: 20.w),
        child: Column(
          children: [
            getCustomFont(
              catName,
              14,
              isSelected ? accentColor : getFontGreyColor(context),
              1,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
                    storeController.setSelectedCategoryName("Best Selling");
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
            child: Obx(() {
              if (isSectionLoading.value) {
                return Center(child: CircularProgressIndicator(color: accentColor));
              }
              if (bestSellingList.isEmpty) {
                return Center(child: getCustomFont("No products available", 14, getFontGreyColor(context), 1));
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: margin),
                itemCount: bestSellingList.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(
                    context,
                    bestSellingList[index],
                    width: 150.w,
                  );
                },
              );
            }),
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
                    storeController.setSelectedCategoryName("Top Deals For You");
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
            child: Obx(() {
              if (isSectionLoading.value) {
                return Center(child: CircularProgressIndicator(color: accentColor));
              }
              if (topDealsList.isEmpty) {
                return Center(child: getCustomFont("No top deals available", 14, getFontGreyColor(context), 1));
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: margin),
                itemCount: topDealsList.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(
                    context,
                    topDealsList[index],
                    width: 150.w,
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedBrandsSection(BuildContext context, double margin) {
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
            child: FutureBuilder<List<BrandModel>>(
              future: brandsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(); // Don't show anything or show small loader
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return SizedBox();
                }
                var apiBrands = snapshot.data!;
                var brands = [
                  BrandModel(id: 'all', name: 'All', logoUrl: ''),
                  ...apiBrands
                ];
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: margin),
                  itemCount: brands.length,
                  itemBuilder: (context, index) {
                    return Obx(() {
                      bool isSelected = selectedBrand.value == brands[index].id;
                      return InkWell(
                        onTap: () {
                          selectedBrand.value = brands[index].id;
                        },
                        child: Container(
                          margin: EdgeInsets.only(right: 10.w),
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          decoration: BoxDecoration(
                            color: isSelected ? accentColor : getGreyCardColor(context),
                            borderRadius: BorderRadius.circular(20.w),
                            border: Border.all(color: isSelected ? accentColor : dividerColor, width: isSelected ? 1 : 0.5),
                          ),
                          child: Center(
                            child: getCustomFont(brands[index].name, 13, isSelected ? Colors.white : getFontColor(context),
                                1,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600),
                          ),
                        ),
                      );
                    });
                  },
                );
              }
            )
          ),
          SizedBox(height: 16.h),
          // Products for Selected Brand
          Obx(() {
            if (selectedBrand.value.isEmpty) return SizedBox();
            return SizedBox(
              height: 200.w,
              child: FutureBuilder<Map<String, dynamic>>(
                future: () async {
                  if (selectedBrand.value == 'all') {
                    // Scrape from top brands to bypass Product API restriction
                    final bRes = await BrandApiService.getAllBrands();
                    if (!bRes['success']) return {'success': false};
                    List<BrandModel> topBrands = (bRes['data'] as List).take(3).map((e) => BrandModel.fromJson(e)).toList();
                    
                    final brandScrape = await Future.wait(topBrands.map((b) => BrandApiService.getProductsByBrand(b.id)));
                    List<dynamic> allProds = [];
                    for (var r in brandScrape) {
                      if (r['success']) {
                        var d = r['data'];
                        if (d is List) allProds.addAll(d);
                        else if (d is Map && d['products'] is List) allProds.addAll(d['products']);
                      }
                    }
                    return {'success': true, 'data': allProds};
                  } else {
                    return BrandApiService.getProductsByBrand(selectedBrand.value);
                  }
                }(),
                builder: (context, prodSnapshot) {
                   if (prodSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: accentColor));
                   }
                   if (!prodSnapshot.hasData || prodSnapshot.data!['success'] == false) {
                     return Center(child: getCustomFont("No products available", 14, getFontGreyColor(context), 1));
                   }
                   
                   List<dynamic> productsList = [];
                   var resData = prodSnapshot.data!['data'];
                   if (resData is List) productsList = resData;
                   else if (resData is Map && resData['products'] is List) productsList = resData['products'];
                   
                   var products = productsList.map((e) => ProductModel.fromJson(e)).toList();
                   
                   if (products.isEmpty) {
                     return Center(child: getCustomFont("No products available", 14, getFontGreyColor(context), 1));
                   }
                   
                   return ListView.builder(
                     scrollDirection: Axis.horizontal,
                     padding: EdgeInsets.symmetric(horizontal: margin),
                     itemCount: products.length,
                     itemBuilder: (context, index) {
                       return _buildProductCard(context, products[index], width: 150.w);
                     }
                   );
                }
              )
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPopularPicksSection(BuildContext context, double margin) {
    return Container(
      color: getCardColor(context),
      padding: EdgeInsets.symmetric(vertical: margin, horizontal: margin),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              getCustomFont("New Arrivals", 18, getFontColor(context), 1,
                  fontWeight: FontWeight.w700),
              GestureDetector(
                onTap: () {
                  storeController.setSelectedCategory("new_arrivals");
                  storeController.setSelectedCategoryName("New Arrivals");
                  Constant.sendToNext(context, categoryProductsPageRoute);
                },
                child: getCustomFont("View All", 14, accentColor, 1,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Obx(() {
            if (isSectionLoading.value) {
              return Center(child: CircularProgressIndicator(color: accentColor));
            }
            if (popularPicksList.isEmpty) {
              return Center(child: getCustomFont("No picks available", 14, getFontGreyColor(context), 1));
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.w,
                childAspectRatio: 0.75,
              ),
              itemCount: popularPicksList.take(4).length,
              itemBuilder: (context, index) {
                return _buildProductCard(
                  context,
                  popularPicksList[index],
                  width: double.infinity,
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product,
      {required double width}) {
    double basePrice = product.originalPrice;
    double currentPrice = product.currentPrice;
    double discountPercent = 0.0;
    
    // Add safety check for zero or negative prices
    if (basePrice <= 0) basePrice = currentPrice;
    if (currentPrice <= 0) currentPrice = basePrice;
    
    if (basePrice > 0 && currentPrice > 0 && basePrice > currentPrice) {
      discountPercent = (((basePrice - currentPrice) / basePrice) * 100).toDouble();
    } else {
      basePrice = currentPrice; // If no discount, original = current
    }

    return InkWell(
      onTap: () {
        storeController.setSelectedProductModel(product);
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
