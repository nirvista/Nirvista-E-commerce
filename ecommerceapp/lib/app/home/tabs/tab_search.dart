import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pet_shop/base/color_data.dart';
import 'package:pet_shop/base/constant.dart';
import 'package:pet_shop/base/fetch_pixels.dart';
import 'package:pet_shop/base/get/route_key.dart';
import 'package:pet_shop/base/get/storage_controller.dart';
import 'package:pet_shop/base/widget_utils.dart';
import 'package:pet_shop/services/product_api.dart';
import 'package:pet_shop/services/brand_api.dart';
import 'package:pet_shop/services/category_api.dart';
import 'package:pet_shop/app/model/api_models.dart';

// ─────────────────────────────────────────────
//  Filter Model
// ─────────────────────────────────────────────
class SearchFilters {
  List<String> categoryIds;
  List<String> brandIds;
  List<String> materials;
  List<String> colors;
  List<String> sizes;
  double? minPrice;
  double? maxPrice;
  double? minRating;
  String sort; // newest | price_asc | price_desc | rating_desc | discount_desc

  SearchFilters({
    this.categoryIds = const [],
    this.brandIds = const [],
    this.materials = const [],
    this.colors = const [],
    this.sizes = const [],
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.sort = 'newest',
  });

  SearchFilters copyWith({
    List<String>? categoryIds,
    List<String>? brandIds,
    List<String>? materials,
    List<String>? colors,
    List<String>? sizes,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? sort,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
    bool clearMinRating = false,
  }) {
    return SearchFilters(
      categoryIds: categoryIds ?? this.categoryIds,
      brandIds: brandIds ?? this.brandIds,
      materials: materials ?? this.materials,
      colors: colors ?? this.colors,
      sizes: sizes ?? this.sizes,
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      sort: sort ?? this.sort,
    );
  }

  Map<String, dynamic> toQueryParams(String keyword) {
    final params = <String, dynamic>{};
    if (keyword.isNotEmpty) {
      params['keyword'] = keyword;
    }
    if (categoryIds.isNotEmpty) params['categoryId'] = categoryIds;
    if (brandIds.isNotEmpty) params['brandId'] = brandIds;
    if (materials.isNotEmpty) params['material'] = materials;
    if (colors.isNotEmpty) params['color'] = colors;
    if (sizes.isNotEmpty) params['size'] = sizes;
    if (minPrice != null) params['minPrice'] = minPrice.toString();
    if (maxPrice != null) params['maxPrice'] = maxPrice.toString();
    if (minRating != null) params['minRating'] = minRating.toString();
    if (sort != 'newest') params['sort'] = sort;
    return params;
  }

  bool get hasActiveFilters =>
      categoryIds.isNotEmpty ||
      brandIds.isNotEmpty ||
      materials.isNotEmpty ||
      colors.isNotEmpty ||
      sizes.isNotEmpty ||
      minPrice != null ||
      maxPrice != null ||
      minRating != null ||
      sort != 'newest';
}

// ─────────────────────────────────────────────
//  Search Page
// ─────────────────────────────────────────────
class TabSearch extends StatefulWidget {
  final bool showBack;
  const TabSearch({Key? key, this.showBack = true}) : super(key: key);

  @override
  State<TabSearch> createState() => _TabSearchState();
}

class _TabSearchState extends State<TabSearch> {
  final StorageController storeController = Get.find<StorageController>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounce;
  String _currentKeyword = '';
  SearchFilters _filters = SearchFilters();

  List<ProductModel> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  // For filter bottom sheet
  List<CategoryModel> _categories = [];
  List<BrandModel> _brands = [];

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadFilterOptions() async {
    try {
      final catRes = await CategoryApiService.getAllCategories();
      final brandRes = await BrandApiService.getAllBrands();
      if (mounted) {
        setState(() {
          if (catRes['success'] == true) {
            _categories = (catRes['data'] as List)
                .map((e) => CategoryModel.fromJson(e))
                .toList();
          }
          if (brandRes['success'] == true) {
            _brands = (brandRes['data'] as List)
                .map((e) => BrandModel.fromJson(e))
                .toList();
          }
        });
      }
    } catch (_) {}
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _currentKeyword = value.trim();
      if (_currentKeyword.isNotEmpty) {
        _performSearch();
      } else {
        setState(() {
          _results = [];
          _hasSearched = false;
        });
      }
    });
  }

  Future<void> _performSearch() async {
    if (_currentKeyword.isEmpty) return;
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _errorMessage = null;
    });

    try {
      final queryParams = _filters.toQueryParams(_currentKeyword);
      final res = await ProductApiService.searchProducts(queryParams);
      if (!mounted) return;

      if (res['success'] == true) {
        dynamic rawData = res['data'];
        List<dynamic> productList = [];

        if (rawData is List) {
          productList = rawData;
        } else if (rawData is Map) {
          final nested = rawData['data'] ??
              rawData['products'] ??
              rawData['results'] ??
              rawData['items'];
          if (nested is List) {
            productList = nested;
          }
        }

        debugPrint('[TabSearch] Raw product count from API: ${productList.length}');

        // Only exclude products explicitly marked inactive or rejected.
        // Missing/null fields are treated as approved — the search API already
        // returns only visible listings on most backends.
        productList.removeWhere((e) {
          final status   = (e['listingStatus']  ?? '').toString().toLowerCase();
          final approval = (e['approvalStatus'] ?? '').toString().toLowerCase();
          final statusBad   = status.isNotEmpty   && status   != 'active';
          final approvalBad = approval.isNotEmpty && approval != 'approved';
          return statusBad || approvalBad;
        });

        debugPrint('[TabSearch] After status filter: ${productList.length}');

        final List<ProductModel> parsedResults =
            productList.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();

        // Only strip completely empty placeholder entries.
        parsedResults.removeWhere(
          (p) => p.title.isEmpty && p.originalPrice <= 0 && p.imageUrl.isEmpty,
        );

        // Client-side keyword filter — ensures only matching products are shown
        // even if the API returns a broader result set.
        if (_currentKeyword.isNotEmpty) {
          final kw = _currentKeyword.toLowerCase();
          parsedResults.removeWhere((p) {
            final title = p.title.toLowerCase();
            final brand = p.brandName.toLowerCase();
            return !title.contains(kw) && !brand.contains(kw);
          });
        }

        debugPrint('[TabSearch] Final results after enrichment: ${parsedResults.length}');

        if (mounted) {
          setState(() {
            _results = parsedResults;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _results = [];
          _isLoading = false;
          _errorMessage = res['message'] ?? 'Search failed';
        });
      }
    } catch (e, stack) {
      print('=== SEARCH PARSE ERROR ===');
      print(e);
      print(stack);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error parsing search results. Check logs.';
        });
      }
    }
  }

  void _openFilterSheet() async {
    final result = await showModalBottomSheet<SearchFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterBottomSheet(
        currentFilters: _filters,
        categories: _categories,
        brands: _brands,
      ),
    );
    if (result != null) {
      setState(() => _filters = result);
      if (_currentKeyword.isNotEmpty) _performSearch();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _currentKeyword = '';
      _results = [];
      _hasSearched = false;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double margin = FetchPixels.getDefaultHorSpaceFigma(context);

    return Scaffold(
      backgroundColor: getScaffoldColor(context),
      appBar: _buildAppBar(context, margin),
      body: Column(
        children: [
          // Filter + sort bar
          if (_hasSearched) _buildFilterBar(context, margin),
          // Results
          Expanded(
            child: _buildBody(context, margin),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, double margin) {
    return PreferredSize(
      preferredSize: Size.fromHeight(72.h),
      child: SafeArea(
        child: Container(
          color: getCardColor(context),
          padding: EdgeInsets.symmetric(horizontal: margin, vertical: 10.h),
          child: Row(
            children: [
              if (widget.showBack) ...[
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: getGreyCardColor(context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_back_ios_new,
                        color: getFontColor(context), size: 18.w),
                  ),
                ),
                SizedBox(width: 12.w),
              ],
              Expanded(
                child: Container(
                  height: 52.h,
                  decoration: BoxDecoration(
                    color: getGreyCardColor(context),
                    borderRadius: BorderRadius.circular(30.w),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.search,
                          color: accentColor, size: 20.w),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _focusNode,
                          style: TextStyle(
                              color: getFontColor(context), fontSize: 14.sp),
                          decoration: InputDecoration(
                            hintText: 'Search products...',
                            hintStyle:
                                TextStyle(color: getFontGreyColor(context).withOpacity(0.7), fontSize: 13.sp),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                          textAlignVertical: TextAlignVertical.center,
                          onChanged: _onSearchChanged,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (v) {
                            _currentKeyword = v.trim();
                            if (_currentKeyword.isNotEmpty) _performSearch();
                          },
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: _clearSearch,
                          child: Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(color: getFontGreyColor(context).withOpacity(0.2), shape: BoxShape.circle),
                            child: Icon(Icons.close,
                                color: getFontGreyColor(context), size: 14.w),
                          ),
                        ),
                      SizedBox(width: 8.w),
                      GestureDetector(
                        onTap: _openFilterSheet,
                        child: Icon(Icons.tune_rounded, color: accentColor, size: 20.w),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, double margin) {
    return Container(
      color: getCardColor(context),
      padding: EdgeInsets.symmetric(horizontal: margin, vertical: 10.h),
      child: Row(
        children: [
          // Result count
          Expanded(
            child: getCustomFont(
              _isLoading
                  ? 'Searching...'
                  : '${_results.length} result${_results.length == 1 ? '' : 's'}',
              13,
              getFontGreyColor(context),
              1,
              fontWeight: FontWeight.w500,
            ),
          ),
          // Filter button
          GestureDetector(
            onTap: _openFilterSheet,
            child: Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: _filters.hasActiveFilters
                    ? accentColor
                    : getGreyCardColor(context),
                borderRadius: BorderRadius.circular(20.w),
                border: Border.all(
                  color: _filters.hasActiveFilters
                      ? accentColor
                      : dividerColor,
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded,
                      color: _filters.hasActiveFilters
                          ? Colors.white
                          : getFontColor(context),
                      size: 16.w),
                  SizedBox(width: 6.w),
                  getCustomFont(
                    'Filter',
                    13,
                    _filters.hasActiveFilters
                        ? Colors.white
                        : getFontColor(context),
                    1,
                    fontWeight: FontWeight.w600,
                  ),
                  if (_filters.hasActiveFilters) ...[
                    SizedBox(width: 6.w),
                    Container(
                      width: 18.w,
                      height: 18.w,
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: Center(
                        child: getCustomFont(
                          _countActiveFilters().toString(),
                          10,
                          accentColor,
                          1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _countActiveFilters() {
    int count = 0;
    if (_filters.categoryIds.isNotEmpty) count++;
    if (_filters.brandIds.isNotEmpty) count++;
    if (_filters.materials.isNotEmpty) count++;
    if (_filters.colors.isNotEmpty) count++;
    if (_filters.sizes.isNotEmpty) count++;
    if (_filters.minPrice != null || _filters.maxPrice != null) count++;
    if (_filters.minRating != null) count++;
    if (_filters.sort != 'newest') count++;
    return count;
  }

  Widget _buildBody(BuildContext context, double margin) {
    if (!_hasSearched) {
      return _buildEmptyState(context);
    }
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: accentColor));
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                color: getFontGreyColor(context), size: 48.w),
            SizedBox(height: 12.h),
            getCustomFont(
                _errorMessage!, 14, getFontGreyColor(context), 2,
                textAlign: TextAlign.center),
          ],
        ),
      );
    }
    if (_results.isEmpty) {
      return _buildNoResults(context);
    }

    return GridView.builder(
      padding: EdgeInsets.all(margin),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.w,
        childAspectRatio: 0.65,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        return _buildProductCard(context, _results[index]);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, color: getFontGreyColor(context), size: 64.w),
          SizedBox(height: 16.h),
          getCustomFont(
              'Search for products', 16, getFontGreyColor(context), 1,
              fontWeight: FontWeight.w600),
          SizedBox(height: 8.h),
          getCustomFont(
              'Try keywords like "mobile", "galaxy", "shoes"',
              13,
              getFontGreyColor(context),
              2,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildNoResults(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, color: getFontGreyColor(context), size: 64.w),
          SizedBox(height: 16.h),
          getCustomFont(
              'No results for "$_currentKeyword"', 16, getFontColor(context), 1,
              fontWeight: FontWeight.w600),
          SizedBox(height: 8.h),
          getCustomFont(
              'Try different keywords or adjust filters',
              13,
              getFontGreyColor(context),
              2,
              textAlign: TextAlign.center),
          if (_filters.hasActiveFilters) ...[
            SizedBox(height: 16.h),
            GestureDetector(
              onTap: () {
                setState(() => _filters = SearchFilters());
                _performSearch();
              },
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                decoration: BoxDecoration(
                  border: Border.all(color: accentColor),
                  borderRadius: BorderRadius.circular(20.w),
                ),
                child: getCustomFont(
                    'Clear Filters', 13, accentColor, 1,
                    fontWeight: FontWeight.w600),
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    double basePrice = product.originalPrice;
    double currentPrice = product.currentPrice;
    double discountPercent = 0.0;

    if (basePrice > 0 && currentPrice > 0 && basePrice > currentPrice) {
      discountPercent =
          (((basePrice - currentPrice) / basePrice) * 100).toDouble();
    } else {
      basePrice = currentPrice;
    }

    return InkWell(
      onTap: () {
        storeController.setSelectedProductModel(product);
        Constant.sendToNext(context, productDetailScreenRoute);
      },
      borderRadius: BorderRadius.circular(12.w),
      child: Container(
        decoration: BoxDecoration(
          color: getCardColor(context),
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
                    imageUrl: product.imageUrl.isNotEmpty
                        ? product.imageUrl
                        : 'https://placehold.co/400',
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Center(
                      child:
                          CircularProgressIndicator(color: accentColor),
                    ),
                    errorWidget: (context, url, error) => Icon(
                        Icons.image_not_supported,
                        color: getFontGreyColor(context)),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            getCustomFont(product.brandName, 11, getFontGreyColor(context), 1,
                fontWeight: FontWeight.w500),
            SizedBox(height: 4.h),
            getCustomFont(product.title, 12, getFontColor(context), 2,
                fontWeight: FontWeight.w600,
                overflow: TextOverflow.ellipsis),
            SizedBox(height: 4.h),
            Row(
              children: [
                Icon(Icons.star, color: ratedColor, size: 12.w),
                SizedBox(width: 4.w),
                getCustomFont(product.rating.toStringAsFixed(1), 11,
                    getFontColor(context), 1,
                    fontWeight: FontWeight.w500),
              ],
            ),
            SizedBox(height: 6.h),
            Row(
              children: [
                getCustomFont('₹${currentPrice.toStringAsFixed(0)}', 13,
                    accentColor, 1,
                    fontWeight: FontWeight.w700),
                SizedBox(width: 6.w),
                if (discountPercent > 0)
                  Text('₹${basePrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: const Color(0xFF757575),
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: const Color(0xFF555555),
                        decorationThickness: 2.0,
                        height: 1.0,
                      )),
              ],
            ),
            if (discountPercent > 0)
              Container(
                margin: EdgeInsets.only(top: 4.h),
                padding:
                    EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(20.w),
                ),
                child: getCustomFont(
                    '${discountPercent.toStringAsFixed(0)}% OFF',
                    9,
                    const Color(0xFF004D40),
                    1,
                    fontWeight: FontWeight.w700),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Filter Bottom Sheet
// ─────────────────────────────────────────────
class _FilterBottomSheet extends StatefulWidget {
  final SearchFilters currentFilters;
  final List<CategoryModel> categories;
  final List<BrandModel> brands;

  const _FilterBottomSheet({
    required this.currentFilters,
    required this.categories,
    required this.brands,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late SearchFilters _tempFilters;

  // Static options (expand these from API if available)
  final List<String> _availableColors = [
    'Red', 'Blue', 'Green', 'Black', 'White', 'Yellow', 'Pink', 'Grey',
  ];
  final List<String> _availableSizes = [
    'XS', 'S', 'M', 'L', 'XL', 'XXL',
  ];
  final List<String> _availableMaterials = [
    'Cotton', 'Polyester', 'Leather', 'Wool', 'Silk', 'Denim',
  ];
  final List<Map<String, String>> _sortOptions = [
    {'key': 'newest', 'label': 'Newest First'},
    {'key': 'price_asc', 'label': 'Price: Low to High'},
    {'key': 'price_desc', 'label': 'Price: High to Low'},
    {'key': 'rating_desc', 'label': 'Highest Rated'},
    {'key': 'discount_desc', 'label': 'Best Discount'},
  ];

  final TextEditingController _minPriceCtrl = TextEditingController();
  final TextEditingController _maxPriceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tempFilters = widget.currentFilters.copyWith();
    if (_tempFilters.minPrice != null) {
      _minPriceCtrl.text = _tempFilters.minPrice!.toStringAsFixed(0);
    }
    if (_tempFilters.maxPrice != null) {
      _maxPriceCtrl.text = _tempFilters.maxPrice!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    super.dispose();
  }

  void _toggleList(List<String> current, String value, Function(List<String>) onUpdate) {
    final updated = List<String>.from(current);
    if (updated.contains(value)) {
      updated.remove(value);
    } else {
      updated.add(value);
    }
    setState(() => onUpdate(updated));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: getScaffoldColor(context),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.w)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: dividerColor,
                  borderRadius: BorderRadius.circular(2.h),
                ),
              ),
              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                child: Row(
                  children: [
                    getCustomFont('Filters & Sort', 18, getFontColor(context), 1,
                        fontWeight: FontWeight.w700),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _tempFilters = SearchFilters();
                          _minPriceCtrl.clear();
                          _maxPriceCtrl.clear();
                        });
                      },
                      child: getCustomFont(
                          'Clear All', 13, accentColor, 1,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Divider(color: dividerColor, height: 1),
              // Scrollable filters
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  children: [
                    // Sort
                    _sectionTitle(context, 'Sort By'),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 8.h,
                      children: _sortOptions.map((opt) {
                        final isSelected = _tempFilters.sort == opt['key'];
                        return _filterChip(
                          context,
                          opt['label']!,
                          isSelected,
                          () => setState(() =>
                              _tempFilters = _tempFilters.copyWith(sort: opt['key'])),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 20.h),

                    // Price Range
                    _sectionTitle(context, 'Price Range'),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Expanded(
                          child: _priceField(
                              context, _minPriceCtrl, 'Min Price (₹)'),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _priceField(
                              context, _maxPriceCtrl, 'Max Price (₹)'),
                        ),
                      ],
                    ),

                    SizedBox(height: 20.h),

                    // Minimum Rating
                    _sectionTitle(context, 'Minimum Rating'),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 8.h,
                      children: [1.0, 2.0, 3.0, 4.0, 4.5].map((r) {
                        final isSelected = _tempFilters.minRating == r;
                        return _filterChip(
                          context,
                          '${r.toStringAsFixed(r == r.toInt() ? 0 : 1)}★ & above',
                          isSelected,
                          () => setState(() {
                            _tempFilters = isSelected
                                ? _tempFilters.copyWith(clearMinRating: true)
                                : _tempFilters.copyWith(minRating: r);
                          }),
                        );
                      }).toList(),
                    ),

                    if (widget.categories.isNotEmpty) ...[
                      SizedBox(height: 20.h),
                      _sectionTitle(context, 'Category'),
                      SizedBox(height: 10.h),
                      Wrap(
                        spacing: 10.w,
                        runSpacing: 8.h,
                        children: widget.categories.map((cat) {
                          final isSelected =
                              _tempFilters.categoryIds.contains(cat.id);
                          return _filterChip(
                            context,
                            cat.name,
                            isSelected,
                            () => _toggleList(
                              _tempFilters.categoryIds,
                              cat.id,
                              (updated) => _tempFilters =
                                  _tempFilters.copyWith(categoryIds: updated),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    if (widget.brands.isNotEmpty) ...[
                      SizedBox(height: 20.h),
                      _sectionTitle(context, 'Brand'),
                      SizedBox(height: 10.h),
                      Wrap(
                        spacing: 10.w,
                        runSpacing: 8.h,
                        children: widget.brands.map((brand) {
                          final isSelected =
                              _tempFilters.brandIds.contains(brand.id);
                          return _filterChip(
                            context,
                            brand.name,
                            isSelected,
                            () => _toggleList(
                              _tempFilters.brandIds,
                              brand.id,
                              (updated) => _tempFilters =
                                  _tempFilters.copyWith(brandIds: updated),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    SizedBox(height: 20.h),
                    _sectionTitle(context, 'Color'),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 8.h,
                      children: _availableColors.map((color) {
                        final isSelected =
                            _tempFilters.colors.contains(color);
                        return _filterChip(
                          context,
                          color,
                          isSelected,
                          () => _toggleList(
                            _tempFilters.colors,
                            color,
                            (updated) => _tempFilters =
                                _tempFilters.copyWith(colors: updated),
                          ),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 20.h),
                    _sectionTitle(context, 'Size'),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 8.h,
                      children: _availableSizes.map((size) {
                        final isSelected =
                            _tempFilters.sizes.contains(size);
                        return _filterChip(
                          context,
                          size,
                          isSelected,
                          () => _toggleList(
                            _tempFilters.sizes,
                            size,
                            (updated) => _tempFilters =
                                _tempFilters.copyWith(sizes: updated),
                          ),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 20.h),
                    _sectionTitle(context, 'Material'),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 8.h,
                      children: _availableMaterials.map((mat) {
                        final isSelected =
                            _tempFilters.materials.contains(mat);
                        return _filterChip(
                          context,
                          mat,
                          isSelected,
                          () => _toggleList(
                            _tempFilters.materials,
                            mat,
                            (updated) => _tempFilters =
                                _tempFilters.copyWith(materials: updated),
                          ),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 30.h),
                  ],
                ),
              ),

              // Apply Button
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                decoration: BoxDecoration(
                  color: getCardColor(context),
                  border: Border(top: BorderSide(color: dividerColor)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed: () {
                      // Parse price inputs
                      final minP = double.tryParse(_minPriceCtrl.text);
                      final maxP = double.tryParse(_maxPriceCtrl.text);
                      SearchFilters finalFilters = _tempFilters.copyWith(
                        minPrice: minP,
                        maxPrice: maxP,
                        clearMinPrice: minP == null,
                        clearMaxPrice: maxP == null,
                      );
                      Navigator.of(context).pop(finalFilters);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.w),
                      ),
                    ),
                    child: getCustomFont('Apply Filters', 15, Colors.white, 1,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return getCustomFont(title, 15, getFontColor(context), 1,
        fontWeight: FontWeight.w700);
  }

  Widget _filterChip(BuildContext context, String label, bool isSelected,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : getGreyCardColor(context),
          borderRadius: BorderRadius.circular(20.w),
          border: Border.all(
            color: isSelected ? accentColor : dividerColor,
            width: isSelected ? 1 : 0.5,
          ),
        ),
        child: getCustomFont(
          label,
          13,
          isSelected ? Colors.white : getFontColor(context),
          1,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _priceField(
      BuildContext context, TextEditingController ctrl, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: getGreyCardColor(context),
        borderRadius: BorderRadius.circular(10.w),
        border: Border.all(color: dividerColor, width: 0.5),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        style: TextStyle(color: getFontColor(context), fontSize: 13.sp),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: getFontGreyColor(context), fontSize: 12.sp),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 10.h),
        ),
      ),
    );
  }
}