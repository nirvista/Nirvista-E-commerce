import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class SearchProduct {
  final String id, name, brand, category;
  final double price, originalPrice, rating;
  final int reviewCount;

  SearchProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.originalPrice,
    required this.rating,
    required this.reviewCount,
    required this.category,
  });

  factory SearchProduct.fromJson(Map<String, dynamic> json) => SearchProduct(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? '',
        brand: json['brand'] ?? '',
        price: (json['price'] ?? 0).toDouble(),
        originalPrice:
            (json['original_price'] ?? json['originalPrice'] ?? json['price'] ?? 0)
                .toDouble(),
        rating: (json['rating'] ?? 0).toDouble(),
        reviewCount: json['review_count'] ?? json['reviewCount'] ?? 0,
        category: json['category'] ?? '',
      );

  double get discountPercent =>
      originalPrice > 0 ? ((originalPrice - price) / originalPrice) * 100 : 0;
}

class PopularProduct {
  final String name, price;
  const PopularProduct({required this.name, required this.price});
}

class TrendingItem {
  final String name;
  const TrendingItem({required this.name});
}

class StoreCategory {
  final String name;
  final IconData icon;
  const StoreCategory({required this.name, required this.icon});
}

class RecentSearch {
  final String query;
  const RecentSearch({required this.query});
}

// ─────────────────────────────────────────────────────────────────────────────
// API SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class SearchApiService {
  static const String _baseUrl = 'https://yourapi.com/api';
  static const Duration _timeout = Duration(seconds: 12);
  static Map<String, String> get _headers =>
      {'Content-Type': 'application/json', 'Accept': 'application/json'};

  static Future<List<SearchProduct>> globalSearch(String query) async {
    try {
      final uri =
          Uri.parse('$_baseUrl/search').replace(queryParameters: {'q': query});
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['products'] ?? data['data'] ?? [];
        return (list as List).map((e) => SearchProduct.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<String>> getSuggestions(String query) async {
    try {
      final uri = Uri.parse('$_baseUrl/search/suggestions')
          .replace(queryParameters: {'q': query});
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['suggestions'] ?? data['data'] ?? [];
        return (list as List).map((e) => e.toString()).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveSearchHistory(String query) async {
    try {
      await http
          .post(Uri.parse('$_baseUrl/search/history'),
              headers: _headers, body: jsonEncode({'query': query}))
          .timeout(_timeout);
    } catch (_) {}
  }

  static Future<void> clearSearchHistory({String? query}) async {
    try {
      final uri = query != null
          ? Uri.parse('$_baseUrl/search/history')
              .replace(queryParameters: {'query': query})
          : Uri.parse('$_baseUrl/search/history');
      await http.delete(uri, headers: _headers).timeout(_timeout);
    } catch (_) {}
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTROLLER
// ─────────────────────────────────────────────────────────────────────────────

class SearchScreenController extends GetxController {
  final RxString query = ''.obs;
  final RxBool isSearching = false.obs;
  final RxBool hasSearched = false.obs;
  final RxList<SearchProduct> searchResults = <SearchProduct>[].obs;
  final RxList<String> suggestions = <String>[].obs;
  final RxList<RecentSearch> recentSearches = <RecentSearch>[].obs;
  final RxBool showSuggestions = false.obs;
  Timer? _debounce;

  final List<TrendingItem> trendingSearches = const [
    TrendingItem(name: 'Samsung S24 Ultra 5G'),
    TrendingItem(name: 'Redmi Note 15 SE'),
    TrendingItem(name: 'Old money perfume'),
    TrendingItem(name: 'Bla Bli Blu perfume'),
    TrendingItem(name: 'Kurta set women'),
    TrendingItem(name: 'TWS earbuds'),
  ];

  final List<StoreCategory> recommendedStores = const [
    StoreCategory(name: 'Tops', icon: Icons.checkroom_outlined),
    StoreCategory(name: 'Ethnic Sets', icon: Icons.dry_cleaning_outlined),
    StoreCategory(name: 'Dresses', icon: Icons.woman_outlined),
    StoreCategory(name: 'Footwear', icon: Icons.ice_skating_outlined),
    StoreCategory(name: 'Accessories', icon: Icons.watch_outlined),
    StoreCategory(name: 'Kids Fashion', icon: Icons.child_care_outlined),
  ];

  final List<PopularProduct> popularProducts = const [
    PopularProduct(name: 'iPhone 16 Pro 128GB', price: '₹1,19,900'),
    PopularProduct(name: 'Anarkali Salwar Suit', price: '₹1,499'),
    PopularProduct(name: 'Boult Z60 TWS Earbuds', price: '₹799'),
    PopularProduct(name: "Nike Air Max Men's", price: '₹5,995'),
    PopularProduct(name: 'Minimalist Niacinamide Serum', price: '₹399'),
    PopularProduct(name: 'Noise ColorFit Ultra 3', price: '₹2,499'),
  ];

  @override
  void onInit() {
    super.onInit();
    recentSearches.assignAll([
      const RecentSearch(query: 'smartphones'),
      const RecentSearch(query: 'running shoes'),
      const RecentSearch(query: 'headphones'),
      const RecentSearch(query: 'moisturizer'),
    ]);
  }

  void onQueryChanged(String value) {
    query.value = value;
    if (value.trim().isEmpty) {
      showSuggestions.value = false;
      suggestions.clear();
      if (hasSearched.value) {
        hasSearched.value = false;
        searchResults.clear();
      }
      return;
    }
    showSuggestions.value = true;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final s = await SearchApiService.getSuggestions(value.trim());
      suggestions.assignAll(s);
    });
  }

  Future<void> performSearch(String q) async {
    if (q.trim().isEmpty) return;
    query.value = q;
    showSuggestions.value = false;
    isSearching.value = true;
    hasSearched.value = true;
    final results = await SearchApiService.globalSearch(q.trim());
    searchResults.assignAll(results);
    isSearching.value = false;
    await SearchApiService.saveSearchHistory(q.trim());
    final exists = recentSearches.any((r) => r.query == q.trim());
    if (!exists) {
      recentSearches.insert(0, RecentSearch(query: q.trim()));
      if (recentSearches.length > 8) recentSearches.removeLast();
    }
  }

  void removeRecentItem(RecentSearch item) {
    recentSearches.remove(item);
    SearchApiService.clearSearchHistory(query: item.query);
  }

  void clearAllRecent() {
    recentSearches.clear();
    SearchApiService.clearSearchHistory();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAP SCALE WIDGET — Minimalist press animation
// ─────────────────────────────────────────────────────────────────────────────

class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;

  const TapScale({
    Key? key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.96,
  }) : super(key: key);

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.forward();
  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class TabSearch extends StatefulWidget {
  const TabSearch({Key? key}) : super(key: key);

  @override
  State<TabSearch> createState() => _TabSearchState();
}

class _TabSearchState extends State<TabSearch> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final SearchScreenController _ctrl;

  // ── Mint-green palette ────────────────────────────────────────────────────
  static const Color _mint = Color(0xFF4ECDC4);
  static const Color _mintLight = Color(0xFFE8FAF8);
  static const Color _mintDark = Color(0xFF3AB5AD);

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(SearchScreenController());
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 150), () {
          _ctrl.showSuggestions.value = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSubmit(String q) {
    _focusNode.unfocus();
    _ctrl.performSearch(q);
  }

  void _onTapTerm(String term) {
    _textController.text = term;
    _ctrl.onQueryChanged(term);
    _onSubmit(term);
  }

  // ── Colors ────────────────────────────────────────────────────────────────
  Color get _bg => const Color(0xFFF5F9F8);
  Color get _card => Colors.white;
  Color get _textPrimary => const Color(0xFF1A2E35);
  Color get _textSecondary => const Color(0xFF8E9FAA);
  Color get _divider => const Color(0xFFE8EDEF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(),
            Expanded(
              child: Stack(
                children: [
                  Obx(() {
                    if (_ctrl.isSearching.value) return _buildShimmerGrid();
                    if (_ctrl.hasSearched.value) return _buildResultsView();
                    return _buildDiscoveryView();
                  }),
                  Obx(() => _ctrl.showSuggestions.value
                      ? _buildSuggestionsOverlay()
                      : const SizedBox.shrink()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SEARCH HEADER ──────────────────────────────────────────────────────────

  Widget _buildSearchHeader() {
    return Container(
      color: _card,
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
      child: Row(
        children: [
          TapScale(
            onTap: () => Get.back(),
            child: Container(
              padding: EdgeInsets.all(8.w),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: _textPrimary, size: 20.w),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Container(
              height: 44.h,
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  SizedBox(width: 14.w),
                  Icon(Icons.search_rounded, color: _textSecondary, size: 18.w),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      style: TextStyle(
                          color: _textPrimary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400),
                      decoration: InputDecoration(
                        hintText: 'Search products, brands…',
                        hintStyle: TextStyle(
                            color: _textSecondary,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      textInputAction: TextInputAction.search,
                      onChanged: _ctrl.onQueryChanged,
                      onSubmitted: _onSubmit,
                    ),
                  ),
                  Obx(() => _ctrl.query.value.isNotEmpty
                      ? TapScale(
                          onTap: () {
                            _textController.clear();
                            _ctrl.onQueryChanged('');
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.w),
                            child: Icon(Icons.close_rounded,
                                color: _textSecondary, size: 16.w),
                          ),
                        )
                      : SizedBox(width: 10.w)),
                ],
              ),
            ),
          ),
          SizedBox(width: 10.w),
          TapScale(
            onTap: () => _showFilterSheet(context),
            child: Container(
              height: 44.h,
              width: 44.w,
              decoration: BoxDecoration(
                color: _mint,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.tune_rounded, color: Colors.white, size: 20.w),
            ),
          ),
        ],
      ),
    );
  }

  // ── FILTER SHEET ──────────────────────────────────────────────────────────

  void _showFilterSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 20.h),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: _divider,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            Text('Filters',
                style: TextStyle(
                    color: _textPrimary,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700)),
            SizedBox(height: 20.h),
            _filterSection('Sort By', ['Relevance', 'Price ↑', 'Price ↓', 'Rating']),
            SizedBox(height: 16.h),
            _filterSection('Price Range', ['Under ₹500', '₹500–₹2000', '₹2000–₹5000', 'Above ₹5000']),
            SizedBox(height: 16.h),
            _filterSection('Rating', ['4★ & above', '3★ & above', '2★ & above']),
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: TapScale(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      height: 48.h,
                      decoration: BoxDecoration(
                        border: Border.all(color: _divider),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      alignment: Alignment.center,
                      child: Text('Reset',
                          style: TextStyle(
                              color: _textSecondary,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: TapScale(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: _mint,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      alignment: Alignment.center,
                      child: Text('Apply',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _filterSection(String title, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                color: _textPrimary,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600)),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: options
              .map((o) => TapScale(
                    onTap: () {},
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: _bg,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(o,
                          style: TextStyle(
                              color: _textPrimary,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400)),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  // ── SUGGESTIONS OVERLAY ───────────────────────────────────────────────────

  Widget _buildSuggestionsOverlay() {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: Material(
        elevation: 4,
        shadowColor: Colors.black12,
        color: _card,
        borderRadius:
            BorderRadius.only(
              bottomLeft: Radius.circular(16.r),
              bottomRight: Radius.circular(16.r),
            ),
        child: Obx(() {
          final list = _ctrl.suggestions;
          if (list.isEmpty) return const SizedBox.shrink();
          return ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16.r),
              bottomRight: Radius.circular(16.r),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(vertical: 6.h),
              itemCount: list.length.clamp(0, 6),
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: _divider),
              itemBuilder: (ctx, i) {
                final s = list[i];
                return TapScale(
                  onTap: () {
                    _textController.text = s;
                    _onSubmit(s);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 16.w, vertical: 14.h),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded,
                            color: _textSecondary, size: 15.w),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(s,
                              style: TextStyle(
                                  color: _textPrimary,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w400)),
                        ),
                        Icon(Icons.north_west_rounded,
                            color: _textSecondary, size: 12.w),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }

  // ── DISCOVERY VIEW ────────────────────────────────────────────────────────

  Widget _buildDiscoveryView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Recent Searches ──
          Obx(() {
            if (_ctrl.recentSearches.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(
                  icon: Icons.history_rounded,
                  title: 'Recent Searches',
                  trailing: TapScale(
                    onTap: _ctrl.clearAllRecent,
                    child: Text('Clear All',
                        style: TextStyle(
                            color: _mint,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                SizedBox(height: 14.h),
                SizedBox(
                  height: 90.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: _ctrl.recentSearches.length,
                    separatorBuilder: (_, __) => SizedBox(width: 16.w),
                    itemBuilder: (_, i) =>
                        _buildRecentChip(_ctrl.recentSearches[i]),
                  ),
                ),
                SizedBox(height: 8.h),
                _sectionDivider(),
              ],
            );
          }),

          // ── Trending Searches ──
          _sectionHeader(
            icon: Icons.trending_up_rounded,
            title: 'Trending Searches',
          ),
          SizedBox(height: 8.h),
          ...List.generate(
            _ctrl.trendingSearches.length,
            (i) => _buildTrendingRow(_ctrl.trendingSearches[i], i),
          ),
          _sectionDivider(),

          // ── Search by Category ──
          _sectionHeader(
            icon: Icons.grid_view_rounded,
            title: 'Search by Category',
          ),
          SizedBox(height: 14.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
                childAspectRatio: 0.9,
              ),
              itemCount: _ctrl.recommendedStores.length,
              itemBuilder: (_, i) =>
                  _buildCategoryCard(_ctrl.recommendedStores[i]),
            ),
          ),
          _sectionDivider(),

          // ── Popular Products ──
          _sectionHeader(
            icon: Icons.local_fire_department_outlined,
            title: 'Popular Products',
          ),
          SizedBox(height: 14.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10.w,
                mainAxisSpacing: 10.h,
                childAspectRatio: 0.72,
              ),
              itemCount: _ctrl.popularProducts.length,
              itemBuilder: (_, i) =>
                  _buildPopularCard(_ctrl.popularProducts[i]),
            ),
          ),
        ],
      ),
    );
  }

  // ── SECTION HEADER ────────────────────────────────────────────────────────

  Widget _sectionHeader(
      {required IconData icon, required String title, Widget? trailing}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 0),
      child: Row(
        children: [
          Icon(icon, color: _mint, size: 18.w),
          SizedBox(width: 8.w),
          Text(title,
              style: TextStyle(
                  color: _textPrimary,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2)),
          const Spacer(),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _sectionDivider() => Container(
        height: 6.h,
        margin: EdgeInsets.only(top: 20.h),
        color: _divider.withOpacity(0.5),
      );

  // ── RECENT CHIP ───────────────────────────────────────────────────────────

  Widget _buildRecentChip(RecentSearch item) {
    return TapScale(
      onTap: () => _onTapTerm(item.query),
      child: SizedBox(
        width: 68.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: BoxDecoration(
                    color: _mintLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.shopping_bag_outlined,
                      color: _mint, size: 22.w),
                ),
                Positioned(
                  top: -2,
                  right: -2,
                  child: TapScale(
                    scaleDown: 0.85,
                    onTap: () => _ctrl.removeRecentItem(item),
                    child: Container(
                      width: 18.w,
                      height: 18.w,
                      decoration: BoxDecoration(
                        color: _textSecondary.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded,
                          color: Colors.white, size: 10.w),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(item.query,
                style: TextStyle(
                    color: _textSecondary,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w400),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // ── TRENDING ROW ──────────────────────────────────────────────────────────

  Widget _buildTrendingRow(TrendingItem item, int index) {
    return TapScale(
      onTap: () => _onTapTerm(item.name),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 1.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: _card,
          border: Border(bottom: BorderSide(color: _divider, width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(
                color: _mintLight,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.trending_up_rounded,
                  color: _mint, size: 14.w),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(item.name,
                  style: TextStyle(
                      color: _textPrimary,
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w400)),
            ),
            Icon(Icons.chevron_right_rounded,
                color: _textSecondary.withOpacity(0.5), size: 18.w),
          ],
        ),
      ),
    );
  }

  // ── CATEGORY CARD ─────────────────────────────────────────────────────────

  Widget _buildCategoryCard(StoreCategory store) {
    return TapScale(
      onTap: () => _onTapTerm(store.name),
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: _divider, width: 0.8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: _mintLight,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(store.icon, color: _mint, size: 24.w),
            ),
            SizedBox(height: 10.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Text(store.name,
                  style: TextStyle(
                      color: _textPrimary,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  // ── POPULAR PRODUCT CARD ──────────────────────────────────────────────────

  Widget _buildPopularCard(PopularProduct product) {
    return TapScale(
      onTap: () => _onTapTerm(product.name),
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: _divider, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _mintLight.withOpacity(0.5),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(14.r)),
                ),
                child: Icon(Icons.image_outlined,
                    color: _textSecondary.withOpacity(0.3), size: 28.w),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.all(8.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(product.name,
                        style: TextStyle(
                            color: _textPrimary,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w400,
                            height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    Text(product.price,
                        style: TextStyle(
                            color: _mint,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── RESULTS VIEW ──────────────────────────────────────────────────────────

  Widget _buildResultsView() {
    return Obx(() {
      final results = _ctrl.searchResults;
      if (results.isEmpty) return _buildEmptyState();
      return Column(
        children: [
          Container(
            color: _card,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${results.length} results for "${_ctrl.query.value}"',
                    style: TextStyle(
                        color: _textSecondary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: _divider),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(12.w),
              physics: const BouncingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10.w,
                mainAxisSpacing: 10.h,
                childAspectRatio: 0.65,
              ),
              itemCount: results.length,
              itemBuilder: (ctx, i) => _buildResultCard(results[i]),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildResultCard(SearchProduct product) {
    return TapScale(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: _divider, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: ClipRRect(
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(14.r)),
                child: Container(
                  width: double.infinity,
                  color: _mintLight.withOpacity(0.5),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.brand,
                            style: TextStyle(
                                color: _textSecondary,
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w400),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        SizedBox(height: 2.h),
                        Text(product.name,
                            style: TextStyle(
                                color: _textPrimary,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                height: 1.3),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                    Row(
                      children: [
                        Text('₹${product.price.toStringAsFixed(0)}',
                            style: TextStyle(
                                color: _mint,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w800)),
                        SizedBox(width: 4.w),
                        if (product.originalPrice > product.price)
                          Text('₹${product.originalPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 10.sp,
                                  decoration: TextDecoration.lineThrough)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── EMPTY STATE ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72.w,
              height: 72.w,
              decoration: BoxDecoration(
                color: _mintLight,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_off_rounded, size: 32.w, color: _mint),
            ),
            SizedBox(height: 16.h),
            Text('No results found',
                style: TextStyle(
                    color: _textPrimary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700)),
            SizedBox(height: 6.h),
            Text('Try different keywords or browse categories.',
                style: TextStyle(
                    color: _textSecondary,
                    fontSize: 12.sp,
                    height: 1.5),
                textAlign: TextAlign.center),
            SizedBox(height: 22.h),
            TapScale(
              onTap: () {
                _textController.clear();
                _ctrl.onQueryChanged('');
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: _mint,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text('Back to Search',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SHIMMER ───────────────────────────────────────────────────────────────

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(12.w),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10.w,
        mainAxisSpacing: 10.h,
        childAspectRatio: 0.65,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: _divider.withOpacity(0.3),
          borderRadius: BorderRadius.circular(14.r),
        ),
      ),
    );
  }
}
