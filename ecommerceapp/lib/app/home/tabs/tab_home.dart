import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pet_shop/app/home/tabs/tab_search.dart';
import 'package:pet_shop/base/color_data.dart';
import 'package:pet_shop/base/constant.dart';
import 'package:pet_shop/base/fetch_pixels.dart';
import 'package:pet_shop/base/get/route_key.dart';
import 'package:pet_shop/base/get/storage_controller.dart';
import 'package:pet_shop/base/widget_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pet_shop/services/product_api.dart';
import 'package:pet_shop/services/brand_api.dart';
import 'package:pet_shop/services/category_api.dart';
import 'package:pet_shop/services/enrichment_service.dart';

import '../../../base/get/bottom_selection_controller.dart';
import '../../../base/get/home_controller.dart';
import '../../../base/get/product_data.dart';
import '../../model/api_models.dart';
import '../../../base/get/cart_contr/shipping_add_controller.dart';
import '../../../base/get/login_data_controller.dart';
import '../../../base/get/wishlist_controller.dart';

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

  final shippingController = Get.isRegistered<ShippingAddressController>()
      ? Get.find<ShippingAddressController>()
      : Get.put(ShippingAddressController());

  final wishlistController = Get.isRegistered<WishlistController>()
      ? Get.find<WishlistController>()
      : Get.put(WishlistController());
  
  // Reactive product lists
  RxList<ProductModel> bestSellingList = <ProductModel>[].obs;
  RxList<ProductModel> topDealsList = <ProductModel>[].obs;
  RxList<ProductModel> popularPicksList = <ProductModel>[].obs;
  // Master pool to keep track of all unique products discovered (including Deep Fetch)
  RxList<ProductModel> masterProductPool = <ProductModel>[].obs;

  Future<List<BrandModel>>? brandsFuture;
  Future<List<CategoryModel>>? categoriesFuture;

  RxString selectedCategory = "for_you".obs;
  RxString selectedBrand = "".obs;
  RxInt sliderPos = 0.obs;
  RxBool isSectionLoading = false.obs;

  @override
  void initState() {
    super.initState();
    // Added a small delay for the initial load to resolve race conditions 
    // during page transitions (especially on emulators).
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _refreshAllSections();
        setState(() {
          brandsFuture = _fetchBrands();
          categoriesFuture = _fetchCategories();
        });
      }
    });
  }

  Future<void> _refreshAllSections() async {
    isSectionLoading.value = true;
    try {
      // 1. Fetch products from specialized APIs AND categories (Deep Fetch)
      // This matches the "View All" logic to ensure we catch all products even if 
      // the specialized APIs have strict variant filters.
      final catRes = await CategoryApiService.getAllCategories();
      final List<String> catIdsToScrape = [];
      if (catRes['success'] && catRes['data'] != null) {
        catIdsToScrape.addAll(
          (catRes['data'] as List).take(4).map((e) => e['id'].toString()).toList()
        );
      }

      final results = await Future.wait([
        _fetchProducts(ProductApiService.getAllProducts()),
        _fetchProducts(ProductApiService.getTopRatedProducts()),
        _fetchProducts(ProductApiService.getNewArrivals()),
        // Scrape products from the first few categories
        ...catIdsToScrape.map((id) => _fetchProducts(CategoryApiService.getProductsByCategory(id))),
      ]);

      // 2. Assign to reactive lists
      bestSellingList.value = results[0];
      popularPicksList.value = results[2];
      
      // Combine EVERYTHING into a master pool
      final List<ProductModel> masterPool = [];
      for (var r in results) {
        masterPool.addAll(r);
      }
      
      final Map<String, ProductModel> uniqueMap = {for (var p in masterPool) p.id: p};
      masterProductPool.value = uniqueMap.values.toList();

      // DERIVE subsections from the master pool with ROBUST sorting
      // This ensures we show newest items first if ratings are tied, 
      // and we aren't limited by the backend's "limit: 12" on specific endpoints.
      List<ProductModel> sortedForDeals = List.from(masterProductPool);
      sortedForDeals.sort((a, b) {
        // Primary: Rating
        int cmp = b.rating.compareTo(a.rating);
        if (cmp != 0) return cmp;
        // Secondary: Newest first
        return b.id.compareTo(a.id); // Assuming ID or date is chronological
      });
      
      topDealsList.value = sortedForDeals;

      // 3. Proactively fetch user address if missing
      shippingController.fetchAddresses();

      // 4. Apply background enrichment to fix potential lightweight API data (images/prices)
      await _enrichHomeSections();

    } catch (e) {
      print("Error refreshing sections: $e");
    } finally {
      isSectionLoading.value = false;
    }
  }

  Future<void> _enrichHomeSections() async {
    // Enrich the lists we already have, PLUS the master pool to catch undiscovered deals
    await Future.wait([
      EnrichmentService.enrichProducts(bestSellingList),
      EnrichmentService.enrichProducts(topDealsList),
      EnrichmentService.enrichProducts(popularPicksList),
      EnrichmentService.enrichProducts(masterProductPool),
    ]);

    // Relaxed cleanup: Only hide if the product is BOTH missing variants/price AND missing images.
    void cleanup(RxList<ProductModel> list) {
      list.removeWhere((p) => (p.variants.isEmpty && p.originalPrice <= 0) && p.imageUrl.isEmpty);
      list.refresh();
    }
    
    cleanup(bestSellingList);
    cleanup(topDealsList);
    cleanup(popularPicksList);
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
        bestSellingList.value = products.where((p) => p.variants.isNotEmpty || p.originalPrice > 0 || p.imageUrl.isNotEmpty).toList();
        topDealsList.value = List.from(bestSellingList.value)..shuffle();
        popularPicksList.value = bestSellingList.value;
      }
    } catch (e) {
      print("Error updating category products: $e");
    } finally {
      isSectionLoading.value = false;
    }
  }

  // Removed _fetchUserLocation as it is now handled by ShippingAddressController

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

  // ─────────────────────────────────────────────
  // ONLY THIS METHOD WAS CHANGED
  // Wrapped the search bar in a GestureDetector + AbsorbPointer
  // so that tapping anywhere on it navigates to SearchPage.
  // ─────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, double margin) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF14B8A6), Color(0xFF0D9488), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Color(0x1A0D9488), blurRadius: 12, offset: Offset(0, 4))
        ],
      ),
      padding: EdgeInsets.fromLTRB(margin, 14.h, margin, 14.h),
      child: Column(
        children: [
          // — Top row: brand + location + bell —
          Row(
            children: [
              // Brand Text
              getAssetImage(
                context,
                "nirvista_logo.png",
                60.w,
                24.h,
                boxFit: BoxFit.contain,
              ),
              const Spacer(),
              // Location chip
              InkWell(
                onTap: () => showAddressSelectorBottomSheet(context),
                borderRadius: BorderRadius.circular(20.w),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20.w),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, color: Colors.white, size: 13.w),
                      SizedBox(width: 4.w),
                      Obx(() => Text(
                        shippingController.selectedAddress.value?.city.toUpperCase() ?? "SET LOCATION",
                        style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w700),
                      )),
                      SizedBox(width: 4.w),
                      Icon(Icons.expand_more, color: Colors.white, size: 14.w),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              // Notification bell
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.notifications_outlined, color: Colors.white, size: 20.w),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          // — Search bar —
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TabSearch()),
            ),
            child: AbsorbPointer(
              child: Container(
                height: 52.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30.w),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.search, color: accentColor, size: 22.w),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: TextField(
                        style: TextStyle(color: getFontColor(context), fontSize: 14.sp),
                        decoration: InputDecoration(
                          hintText: "Search products, brands...",
                          hintStyle: TextStyle(color: getFontGreyColor(context).withOpacity(0.7), fontSize: 13.sp),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        textAlignVertical: TextAlignVertical.center,
                      ),
                    ),
                    Icon(Icons.tune, color: accentColor, size: 20.w),
                  ],
                ),
              ),
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
            return const SizedBox();
          }
          List<CategoryModel> apiCategories = snapshot.data!;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(
              () => Row(
                children: [
                  _buildSingleCategoryTab(context, 'for_you', 'For You'),
                  ...List.generate(
                    apiCategories.length,
                    (index) => _buildSingleCategoryTab(
                        context, apiCategories[index].id, apiCategories[index].name),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSingleCategoryTab(
      BuildContext context, String catId, String catName) {
    bool isSelected = selectedCategory.value == catId;
    return GestureDetector(
      onTap: () {
        if (selectedCategory.value == catId) return;
        selectedCategory.value = catId;
        storeController.setSelectedCategory(catId);
        storeController.setSelectedCategoryName(catName);
        _updateCategoryProducts(catId);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : getGreyCardColor(context),
          borderRadius: BorderRadius.circular(20.w),
          boxShadow: isSelected
              ? [BoxShadow(color: accentColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Text(
          catName,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : getFontGreyColor(context),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerCarousel(BuildContext context, double margin) {
    final List<Map<String, dynamic>> banners = [
      {"title": "Big Season Sale", "subtitle": "Up to 80% Off — Shop Now", "icon": Icons.local_offer_rounded, "gradient": [const Color(0xFF14B8A6), const Color(0xFF0D9488)]},
      {"title": "Electronics Week", "subtitle": "Top Brands · Best Prices", "icon": Icons.devices_rounded, "gradient": [const Color(0xFF0D9488), const Color(0xFF0F766E)]},
      {"title": "New Arrivals", "subtitle": "Fresh Picks Just for You", "icon": Icons.auto_awesome_rounded, "gradient": [const Color(0xFF0F766E), const Color(0xFF134E4A)]},
    ];

    return Column(
      children: [
        SizedBox(
          height: 160.h,
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: margin),
            child: CarouselSlider(
              items: List.generate(banners.length, (index) {
                final b = banners[index];
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: b["gradient"] as List<Color>,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18.w),
                    boxShadow: [
                      BoxShadow(color: accentColor.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6.w),
                              ),
                              child: Text("LIMITED OFFER", style: TextStyle(color: Colors.white70, fontSize: 9.sp, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                            ),
                            SizedBox(height: 8.h),
                            Text(b["title"]!, style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w800)),
                            SizedBox(height: 4.h),
                            Text(b["subtitle"]!, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12.sp, fontWeight: FontWeight.w500)),
                            SizedBox(height: 12.h),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20.w),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("SHOP NOW", style: TextStyle(color: accentColor, fontSize: 10.sp, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                                  SizedBox(width: 4.w),
                                  Icon(Icons.arrow_forward, color: accentColor, size: 11.w),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(b["icon"] as IconData, color: Colors.white.withOpacity(0.25), size: 80.w),
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
                onPageChanged: (index, reason) { sliderPos.value = index; },
              ),
            ),
          ),
        ),
        SizedBox(height: 10.h),
        // Dot indicators
        Obx(() => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: EdgeInsets.only(right: 5.w),
            width: sliderPos.value == i ? 18.w : 6.w,
            height: 6.h,
            decoration: BoxDecoration(
              color: sliderPos.value == i ? accentColor : accentColor.withOpacity(0.25),
              borderRadius: BorderRadius.circular(4.w),
            ),
          )),
        )),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, double margin, String title, VoidCallback onViewAll) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: margin),
      child: Row(
        children: [
          Container(width: 4.w, height: 20.h, decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(2.w))),
          SizedBox(width: 10.w),
          Expanded(child: Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: getFontColor(context)))),
          GestureDetector(
            onTap: onViewAll,
            child: Row(
              children: [
                Text("View All", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: accentColor)),
                SizedBox(width: 2.w),
                Icon(Icons.arrow_forward_ios, color: accentColor, size: 11.w),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestSellingSection(BuildContext context, double margin) {
    return Container(
      color: getCardColor(context),
      padding: EdgeInsets.symmetric(vertical: margin),
      child: Column(
        children: [
          _buildSectionHeader(context, margin, "Best Selling", () {
            storeController.setSelectedCategory("best_selling");
            storeController.setSelectedCategoryName("Best Selling");
            Constant.sendToNext(context, categoryProductsPageRoute);
          }),
          SizedBox(height: 16.h),
          SizedBox(
            height: 240.w,
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
                itemBuilder: (context, index) =>
                    _buildProductCard(context, bestSellingList[index], width: 155.w),
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
          _buildSectionHeader(context, margin, "Top Deals For You", () {
            storeController.setSelectedCategory("top_deals");
            storeController.setSelectedCategoryName("Top Deals For You");
            Constant.sendToNext(context, categoryProductsPageRoute);
          }),
          SizedBox(height: 16.h),
          SizedBox(
            height: 240.w,
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
                itemBuilder: (context, index) =>
                    _buildProductCard(context, topDealsList[index], width: 155.w),
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
                      return SizedBox();
                    }
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data!.isEmpty) {
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
                          bool isSelected =
                              selectedBrand.value == brands[index].id;
                          return InkWell(
                            onTap: () {
                              selectedBrand.value = brands[index].id;
                            },
                            child: Container(
                              margin: EdgeInsets.only(right: 10.w),
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? accentColor
                                    : getGreyCardColor(context),
                                borderRadius: BorderRadius.circular(20.w),
                                border: Border.all(
                                    color:
                                        isSelected ? accentColor : dividerColor,
                                    width: isSelected ? 1 : 0.5),
                              ),
                              child: Center(
                                child: getCustomFont(
                                    brands[index].name,
                                    13,
                                    isSelected
                                        ? Colors.white
                                        : getFontColor(context),
                                    1,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600),
                              ),
                            ),
                          );
                        });
                      },
                    );
                  })),
          SizedBox(height: 16.h),
          // Products for Selected Brand
          Obx(() {
            if (selectedBrand.value.isEmpty) return SizedBox();
            return SizedBox(
              height: 240.w,
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
                   
                   // Relaxed cleanup: Only hide if the product is BOTH missing variants/price AND missing images.
                   products.removeWhere((p) => (p.variants.isEmpty && p.originalPrice <= 0) && p.imageUrl.isEmpty);
                   
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
      padding: EdgeInsets.fromLTRB(margin, margin, margin, margin),
      child: Column(
        children: [
          _buildSectionHeader(context, 0, "New Arrivals", () {
            storeController.setSelectedCategory("new_arrivals");
            storeController.setSelectedCategoryName("New Arrivals");
            Constant.sendToNext(context, categoryProductsPageRoute);
          }),
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
                childAspectRatio: 0.65,
              ),
              itemCount: popularPicksList.take(4).length,
              itemBuilder: (context, index) =>
                  _buildProductCard(context, popularPicksList[index], width: double.infinity),
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
    if (basePrice <= 0) basePrice = currentPrice;
    if (currentPrice <= 0) currentPrice = basePrice;
    if (basePrice > 0 && currentPrice > 0 && basePrice > currentPrice) {
      discountPercent = (((basePrice - currentPrice) / basePrice) * 100);
    } else {
      basePrice = currentPrice;
    }

    return GestureDetector(
      onTap: () {
        storeController.setSelectedProductModel(product);
        Constant.sendToNext(context, productDetailScreenRoute);
      },
      child: Container(
        width: width,
        margin: EdgeInsets.only(right: width == double.infinity ? 0 : 12.w),
        decoration: BoxDecoration(
          color: getCardColor(context),
          borderRadius: BorderRadius.circular(14.w),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D9488).withOpacity(0.07),
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
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14.w)),
                  child: Container(
                    height: 110.w,
                    width: double.infinity,
                    color: getGreyCardColor(context),
                    child: (product.imageUrl.isNotEmpty && !product.imageUrl.contains("example.com"))
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => Center(
                              child: CircularProgressIndicator(color: accentColor, strokeWidth: 2),
                            ),
                            errorWidget: (_, __, ___) =>
                                Icon(Icons.shopping_bag_outlined, color: getFontGreyColor(context), size: 32.w),
                          )
                        : Icon(Icons.shopping_bag_outlined, color: getFontGreyColor(context), size: 32.w),
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
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6)],
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
            ),
            // ── Info ──
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(product.brandName,
                      style: TextStyle(fontSize: 10.sp, color: getFontGreyColor(context), fontWeight: FontWeight.w500)),
                  SizedBox(height: 3.h),
                  Text(product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.sp, color: getFontColor(context), fontWeight: FontWeight.w600, height: 1.3)),
                  SizedBox(height: 5.h),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, color: ratedColor, size: 12.w),
                      SizedBox(width: 3.w),
                      Text(product.rating.toStringAsFixed(1),
                          style: TextStyle(fontSize: 10.sp, color: getFontColor(context), fontWeight: FontWeight.w500)),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  // Price row with inline discount badge
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 5.w,
                    runSpacing: 3.h,
                    children: [
                      Text("₹${currentPrice.toStringAsFixed(0)}",
                          style: TextStyle(fontSize: 14.sp, color: accentColor, fontWeight: FontWeight.w800)),
                      if (discountPercent > 0) ...[
                        Text("\u20b9${basePrice.toStringAsFixed(0)}",
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
                          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4.w),
                          ),
                          child: Text(
                            "${discountPercent.toStringAsFixed(0)}% off",
                            style: TextStyle(fontSize: 9.sp, color: accentColor, fontWeight: FontWeight.w700),
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
