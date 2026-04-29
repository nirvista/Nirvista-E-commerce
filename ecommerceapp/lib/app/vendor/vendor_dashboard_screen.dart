import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:pet_shop/base/get/login_data_controller.dart';
import '../../services/vendor_api.dart';
import '../../services/vendor_order_api.dart';
import 'package:pet_shop/services/product_api.dart';
import 'package:pet_shop/services/brand_api.dart';
import 'package:pet_shop/services/category_api.dart';
import 'package:pet_shop/app/model/api_models.dart';
import 'package:pet_shop/services/enrichment_service.dart';
import 'package:pet_shop/base/get/route_key.dart';
import 'package:pet_shop/base/constant.dart';
import 'package:pet_shop/base/get/bottom_selection_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS — teal theme, strengthened
// ─────────────────────────────────────────────────────────────────────────────
const _kTeal           = Color(0xFF0D9488);
const _kTealLight      = Color(0xFFCCFBF1);
const _kTealMid        = Color(0xFF14B8A6);
const _kTealDark       = Color(0xFF0F766E);
const _kTealDeep       = Color(0xFF134E4A);
const _kRed            = Color(0xFFEF4444);
const _kRedLight       = Color(0xFFFEE2E2);
const _kGreen          = Color(0xFF22C55E);
const _kGreenLight     = Color(0xFFDCFCE7);
const _kAmber          = Color(0xFFF59E0B);
const _kAmberLight     = Color(0xFFFEF3C7);
const _kSidebar        = Color(0xFF0A3631);
const _kSidebarHover   = Color(0xFF0F4C43);
const _kSidebarActive  = Color(0xFF0D9488);
const _kSidebarText    = Color(0xFF99D6CF);
const _kBg             = Color(0xFFF4F7F6);
const _kCard           = Colors.white;
const _kBorder         = Color(0xFFE2EAE8);
const _kText           = Color(0xFF0F2622);
const _kTextMuted      = Color(0xFF6B8680);

// ─────────────────────────────────────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────────────────────────────────────
String _getVendorStatus(List<dynamic> items) {
  if (items.isEmpty) return 'pending';
  if (items.any((i) => i['fulfillmentStatus'] == 'cancelled')) return 'cancelled';
  if (items.every((i) => i['fulfillmentStatus'] == 'delivered')) return 'delivered';
  if (items.any((i) => i['fulfillmentStatus'] == 'shipped')) return 'shipped';
  if (items.any((i) => i['fulfillmentStatus'] == 'processing')) return 'processing';
  return 'pending';
}

/// Safely extract a string ID from a value that might be a String, int, or Map.
String _extractId(dynamic value) {
  if (value == null) return '';
  if (value is String) return value.trim();
  if (value is int) return value.toString();
  if (value is Map) {
    final id = value['id'] ?? value['_id'] ?? value['categoryId'];
    return _extractId(id);
  }
  return value.toString().trim();
}

// ─────────────────────────────────────────────────────────────────────────────
//  MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen>
    with TickerProviderStateMixin {
  final LoginDataController _loginController = Get.find<LoginDataController>();
  int _selectedSection = 0;

  static const List<String> _sectionTitles = [
    'Dashboard', 'Products', 'Inventory', 'Orders', 'Analytics',
  ];
  static const List<IconData> _sectionIcons = [
    Icons.space_dashboard_rounded,
    Icons.inventory_2_rounded,
    Icons.warehouse_rounded,
    Icons.receipt_long_rounded,
    Icons.bar_chart_rounded,
  ];

  bool _isBusy = false;

  // Raw data
  List<dynamic> _products    = [];
  List<dynamic> _inventory   = [];
  Map<String, dynamic> _inventorySummary = {};
  List<dynamic> _orders      = [];
  List<dynamic> _brands      = [];
  List<dynamic> _categories  = [];
  Map<String, dynamic> _salesAnalytics       = {};
  Map<String, dynamic> _performanceAnalytics = {};
  List<dynamic> _topProducts = [];

  // Product search & filter
  final TextEditingController _productSearchC = TextEditingController();
  String _productFilterStatus = 'All';

  // Analytics timeframe
  String _analyticsTimeframe = 'last_30_days';

  // Inventory filter
  bool _inventoryLowStockOnly = false;

  // Orders search
  final TextEditingController _orderSearchC = TextEditingController();

  String get _token => _loginController.accessToken ?? '';

  List<dynamic> get _filteredProducts {
    var list = List<dynamic>.from(_products);
    final q = _productSearchC.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((p) {
        final name = (p['title'] ?? p['name'] ?? '').toString().toLowerCase();
        final variants = p['variants'] as List? ?? [];
        final sku = variants.isNotEmpty
            ? (variants.first['variantName'] ?? variants.first['sku'] ?? '')
                .toString().toLowerCase()
            : (p['sku'] ?? '').toString().toLowerCase();
        return name.contains(q) || sku.contains(q);
      }).toList();
    }
    if (_productFilterStatus != 'All') {
      list = list.where((p) =>
        (p['listingStatus'] ?? '').toString().toUpperCase() == _productFilterStatus.toUpperCase()
      ).toList();
    }
    return list;
  }

  List<dynamic> get _filteredOrders {
    final q = _orderSearchC.text.trim().toLowerCase();
    if (q.isEmpty) return _orders;
    return _orders.where((o) {
      final items = o['items'] as List? ?? [];
      final id = (o['id'] ?? '').toString().toLowerCase();
      final status = _getVendorStatus(items).toLowerCase();
      final productTitles = items.map((i) => i['product']?['title']?.toString().toLowerCase() ?? '').join(' ');
      return id.contains(q) || status.contains(q) || productTitles.contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _productSearchC.addListener(() => setState(() {}));
    _orderSearchC.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  @override
  void dispose() {
    _productSearchC.dispose();
    _orderSearchC.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    if (_token.isEmpty) {
      _snack('Missing token. Please login again.', true);
      return;
    }
    setState(() => _isBusy = true);
    try {
      await Future.wait([_fetchBrands(), _fetchCategories()]);
      await Future.wait([
        _fetchProducts(loader: false),
        _fetchInventory(loader: false),
        _fetchOrders(loader: false),
        _fetchAnalytics(loader: false),
      ]);
    } catch (e) {
      _snack('Connection error: $e', true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _run(Future<void> Function() fn, {bool loader = true}) async {
    if (loader) setState(() => _isBusy = true);
    try { await fn(); } finally { if (loader && mounted) setState(() => _isBusy = false); }
  }

  // ── API wrappers ─────────────────────────────────────────────────────────

  Future<void> _fetchProducts({bool loader = false}) => _run(() async {
    final r = await VendorApiService.getVendorProducts(_token);
    if (r['success'] == true) {
      final d = r['data'];
      if (d is Map && d['products'] is List) {
        final List<Map<String, dynamic>> rawList = List<Map<String, dynamic>>.from(d['products']);
        final models = rawList.map((m) => ProductModel.fromJson(m)).toList();
        await EnrichmentService.enrichProducts(models);
        for (int i = 0; i < models.length; i++) {
          rawList[i]['imageUrls'] = models[i].images;
          rawList[i]['thumbnail'] = models[i].thumbnail;
          rawList[i]['basePrice'] = models[i].basePrice;
          rawList[i]['salePrice'] = models[i].salePrice;
          if (models[i].variants.isNotEmpty && (rawList[i]['variants'] == null || (rawList[i]['variants'] as List).isEmpty)) {
            rawList[i]['variants'] = models[i].variants.map((v) => <String, dynamic>{
              'id': v.id,
              'variantName': v.variantName,
              'sku': v.id,
              'price': v.price,
              'discountPrice': v.discountPrice,
              'stock': v.stock,
              'images': v.images,
            }).toList();
          }
        }
        setState(() => _products = rawList);
      } else if (d is List) {
        setState(() => _products = d);
      } else {
        setState(() => _products = []);
      }
    } else {
      _snack(r['message'] ?? 'Cannot fetch products', true);
    }
  }, loader: loader);

  Future<void> _fetchBrands() async {
    try {
      final r = await BrandApiService.getAllBrands();
      if (r['success'] == true) {
        final d = r['data'];
        if (mounted) setState(() => _brands = d is List ? d : []);
      } else {
        debugPrint('Brands fetch failed: ${r['message']}');
      }
    } catch (e) {
      debugPrint('_fetchBrands error: $e');
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final r = await CategoryApiService.getAllCategories();
      if (r['success'] == true) {
        final d = r['data'];
        if (mounted) {
          final raw = d is List ? d : [];
          for (final c in raw) {
            debugPrint('[Category] id=${_extractId(c['id'] ?? c['_id'])} '
                'name=${c['name']} parentId=${c['parentId']} '
                'parentIdType=${c['parentId']?.runtimeType}');
          }
          setState(() => _categories = raw);
        }
      } else {
        debugPrint('Categories fetch failed: ${r['message']}');
      }
    } catch (e) {
      debugPrint('_fetchCategories error: $e');
    }
  }

  List<dynamic> get _rootCategories {
    return _categories.where((c) {
      final rawParentId = c['parentId'];
      final parentId = _extractId(rawParentId);
      return rawParentId == null ||
          parentId.isEmpty ||
          parentId == 'null' ||
          parentId == '0';
    }).toList();
  }

  List<dynamic> _getSubCategories(String parentId) {
    if (parentId.isEmpty) return [];
    return _flatCategories.where((c) {
      final rawParentId = c['parentId'];
      if (rawParentId == null) return false;
      final pid = _extractId(rawParentId);
      return pid == parentId;
    }).toList();
  }

  String _categoryId(dynamic c) {
    return _extractId(c['id'] ?? c['_id'] ?? c['categoryId']);
  }

  List<dynamic> get _flatCategories {
    final result = <dynamic>[];
    void walk(List<dynamic> entries) {
      for (final entry in entries) {
        result.add(entry);
        if (entry['children'] is List) walk(List<dynamic>.from(entry['children']));
      }
    }
    walk(_categories);
    return result;
  }

  Future<void> _createProduct(Map<String, dynamic> body) => _run(() async {
    debugPrint('[VendorDashboard] Creating product: $body');
    final r = await VendorApiService.createVendorProduct(_token, body);
    debugPrint('[VendorDashboard] Create product response: $r');
    if (r['success'] == true) {
      if (r['data'] != null && r['data'] is Map<String, dynamic>) {
        final newProduct = r['data'] as Map<String, dynamic>;
        setState(() {
          _products = [newProduct, ..._products];
          _selectedSection = 1;
        });
      }
      _snack('Product Created Successfully!', false);
      _fetchProducts(loader: false);
    } else {
      _snack('Failed to create product: ${r['message'] ?? 'Server error'}', true);
    }
  });

  Future<void> _addVariant(String productId, Map<String, dynamic> payload) => _run(() async {
    final r = await VendorApiService.addVariant(_token, productId, payload);
    _snack(r['message'] ?? 'Variant added', r['success'] != true);
    if (r['success'] == true) await _fetchProducts();
  });

  Future<void> _updateVariant(String productId, String variantId, Map<String, dynamic> payload) => _run(() async {
    final r = await VendorApiService.updateVendorProduct(_token, productId, {
      'variants': [{...payload, 'id': variantId}]
    });
    _snack(r['message'] ?? 'Variant updated', r['success'] != true);
    if (r['success'] == true) await _fetchProducts();
  });

  Future<void> _searchProducts(String keyword) async {
    if (keyword.trim().isEmpty) { await _fetchProducts(loader: true); return; }
    await _run(() async {
      final r = await ProductApiService.searchProducts({'keyword': keyword.trim()});
      if (r['success'] == true) {
        final d = r['data'];
        setState(() => _products = d is List ? d : []);
      } else {
        _snack(r['message'] ?? 'Search failed', true);
      }
    }, loader: true);
  }

  Future<void> _fetchInventory({bool loader = false}) => _run(() async {
    final r = await VendorApiService.getVendorInventory(
      _token, lowStockOnly: _inventoryLowStockOnly,
    );
    if (r['success'] == true) {
      final d = r['data'];
      if (d is Map) {
        setState(() {
          _inventory = d['inventory'] as List? ?? [];
          _inventorySummary = d['summary'] as Map<String, dynamic>? ?? {};
        });
      } else {
        setState(() => _inventory = d is List ? d : []);
      }
    } else {
      debugPrint('Inventory fetch failed: ${r['message']}');
    }
  }, loader: loader);

  Future<void> _adjustInventory(String sku, Map<String, dynamic> payload) => _run(() async {
    final r = await VendorApiService.adjustVendorInventory(_token, sku, payload);
    _snack(r['message'] ?? 'Adjusted', r['success'] != true);
    if (r['success'] == true) await _fetchInventory();
  });

  Future<void> _fetchOrders({bool loader = false}) => _run(() async {
    final r = await VendorOrderApiService.getVendorOrders(_token);
    if (r['success'] == true) {
      final d = r['data'];
      if (d is Map && d['orders'] is List) {
        setState(() => _orders = d['orders'] as List);
      } else {
        setState(() => _orders = d is List ? d : []);
      }
    } else {
      _snack(r['message'] ?? 'Cannot fetch orders', true);
    }
  }, loader: loader);

  Future<void> _fetchOrderById(String orderId) => _run(() async {
    final r = await VendorOrderApiService.getVendorOrderById(_token, orderId);
    if (r['success'] == true) {
      _showOrderDetailDialog(r['data'] as Map<String, dynamic>? ?? {});
    } else {
      _snack(r['message'] ?? 'Cannot fetch order', true);
    }
  });

  Future<void> _updateFulfillment(String orderId, Map<String, dynamic> payload) => _run(() async {
    final r = await VendorOrderApiService.updateFulfillment(_token, orderId, payload);
    _snack(r['message'] ?? 'Updated', r['success'] != true);
    if (r['success'] == true) await _fetchOrders();
  });

  Future<void> _initiateRefund(String orderId, String orderItemId, int qty, String reason) => _run(() async {
    final r = await VendorOrderApiService.initiateVendorRefund(_token, orderId, {
      'orderItemId': orderItemId,
      'refundQuantity': qty,
      'reason': reason,
    });
    _snack(r['message'] ?? 'Refund processed', r['success'] != true);
    if (r['success'] == true) await _fetchOrders();
  });

  Future<void> _fetchAnalytics({bool loader = false}) => _run(() async {
    final sales = await VendorApiService.getVendorSalesAnalytics(_token, timeframe: _analyticsTimeframe);
    final perf  = await VendorApiService.getVendorPerformanceAnalytics(_token, timeframe: _analyticsTimeframe);
    final top   = await VendorApiService.getVendorTopProducts(_token, timeframe: _analyticsTimeframe);
    if (sales['success'] == true) _salesAnalytics = Map<String, dynamic>.from(sales['data'] ?? {});
    if (perf['success'] == true) _performanceAnalytics = Map<String, dynamic>.from(perf['data'] ?? {});
    if (top['success'] == true) {
      final d = top['data'];
      if (d is Map && d['topProducts'] is List) {
        _topProducts = d['topProducts'] as List;
      } else {
        _topProducts = d is List ? d : [];
      }
    }
    if (mounted) setState(() {});
  }, loader: loader);

  void _logout() {
    _loginController.logout();
    try {
      if (Get.isRegistered<BottomItemSelectionController>()) {
        Get.find<BottomItemSelectionController>().changePos(0);
      }
    } catch (e) {
      debugPrint('BottomItemSelectionController not found: $e');
    }
    Constant.sendToNext(context, loginRoute);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  SNACKBAR
  // ─────────────────────────────────────────────────────────────────────────
  void _snack(String msg, bool isError) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
      ]),
      backgroundColor: isError ? _kRed : _kTeal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user      = _loginController.currentUser.value;
    final w         = MediaQuery.of(context).size.width;
    final isCompact = w < 880;
    final sidePanel = _buildSidePanel(user, isCompact);

    final pages = [
      _buildDashboardTab(),
      _buildProductsTab(),
      _buildInventoryTab(),
      _buildOrdersTab(),
      _buildAnalyticsTab(),
    ];

    return Scaffold(
      backgroundColor: _kBg,
      drawer: isCompact ? Drawer(child: sidePanel) : null,
      appBar: isCompact
          ? AppBar(
              backgroundColor: _kSidebar,
              foregroundColor: Colors.white,
              elevation: 0,
              title: Text(_sectionTitles[_selectedSection],
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              actions: [
                IconButton(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  tooltip: 'Logout',
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: Stack(
        children: [
          Row(
            children: [
              if (!isCompact) SizedBox(width: 260, child: sidePanel),
              Expanded(child: pages[_selectedSection]),
            ],
          ),
          if (_isBusy)
            Container(
              color: Colors.black.withOpacity(0.15),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: _kTeal, strokeWidth: 2.5),
                      SizedBox(height: 12),
                      Text('Loading…', style: TextStyle(color: _kTextMuted, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Side Panel ────────────────────────────────────────────────────────────
  Widget _buildSidePanel(dynamic user, bool isCompact) {
    return Container(
      decoration: const BoxDecoration(
        color: _kSidebar,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kTealMid, _kTeal],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('VendorHub',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: 0.2)),
                  Text(user?.displayName ?? 'My Store',
                      style: const TextStyle(color: _kSidebarText, fontSize: 12, fontWeight: FontWeight.w500)),
                ]),
              ]),
            ),
            Container(height: 1, color: Colors.white.withOpacity(0.07)),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('NAVIGATION',
                  style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _sectionTitles.length,
                itemBuilder: (ctx, i) {
                  final active = _selectedSection == i;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedSection = i);
                      if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.only(bottom: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: active ? _kSidebarActive : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: active ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(_sectionIcons[i], size: 16, color: active ? Colors.white : _kSidebarText),
                        ),
                        const SizedBox(width: 12),
                        Text(_sectionTitles[i],
                            style: TextStyle(
                              color: active ? Colors.white : _kSidebarText,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 14,
                            )),
                        if (active) ...[
                          const Spacer(),
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                        ],
                      ]),
                    ),
                  );
                },
              ),
            ),
            Container(height: 1, color: Colors.white.withOpacity(0.07)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_kTealMid, _kTealDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      (user?.displayName ?? 'V').substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(user?.displayName ?? 'Vendor',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                    const Text('Active session', style: TextStyle(color: _kSidebarText, fontSize: 11)),
                  ]),
                ),
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle)),
              ]),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: InkWell(
                onTap: _logout,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.logout_rounded, color: _kRed, size: 18),
                      SizedBox(width: 12),
                      Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  DASHBOARD TAB
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDashboardTab() {
    final totalProducts = _products.length;
    final totalOrders = _orders.length;
    final lowStock  = _inventorySummary['lowStockCount'] ?? 0;
    final revenue   = _salesAnalytics['summary']?['totalRevenue'] ?? '0.00';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Dashboard', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _kText)),
              Text('Welcome back! Here\'s your store overview.', style: TextStyle(color: _kTextMuted, fontSize: 13)),
            ]),
          ),
        ]),
        const SizedBox(height: 24),
        LayoutBuilder(builder: (ctx, constraints) {
          final cols = constraints.maxWidth > 700 ? 4 : 2;
          final gap  = 14.0;
          final w    = (constraints.maxWidth - gap * (cols - 1)) / cols;
          final cards = [
            _KpiData('Total Revenue', '₹$revenue', Icons.currency_rupee_rounded, _kTeal, _kTealLight),
            _KpiData('Total Orders',  '$totalOrders', Icons.receipt_long_rounded, const Color(0xFF6366F1), const Color(0xFFEEF2FF)),
            _KpiData('Products',      '$totalProducts', Icons.inventory_2_rounded, _kAmber, _kAmberLight),
            _KpiData('Low Stock',     '$lowStock SKUs', Icons.warning_amber_rounded, _kRed, _kRedLight),
          ];
          return Wrap(spacing: gap, runSpacing: gap, children: [
            for (final c in cards) SizedBox(width: w, child: _KpiCard(data: c)),
          ]);
        }),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Quick Actions'),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: [
          _QuickActionChip(icon: Icons.add_box_rounded,    label: 'Add Product',    onTap: () { setState(() => _selectedSection = 1); _showAddProductDialog(); }),
          _QuickActionChip(icon: Icons.bar_chart_rounded,  label: 'Sales Report',   onTap: () => setState(() => _selectedSection = 4)),
          _QuickActionChip(icon: Icons.warehouse_rounded,  label: 'View Inventory', onTap: () => setState(() => _selectedSection = 3)),
        ]),
        const SizedBox(height: 24),
        if (_orders.isNotEmpty) ...[
          _SectionHeader(
            title: 'Recent Orders',
            action: TextButton(
              onPressed: () => setState(() => _selectedSection = 3),
              child: const Text('View All', style: TextStyle(color: _kTeal, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          ..._orders.take(3).map((o) => _OrderRowCard(
                order: o,
                statusText: _getVendorStatus(o['items'] as List? ?? []),
                onFulfillment: () => _showFulfillmentDialog(o),
                onViewDetail: () => _fetchOrderById(o['id']?.toString() ?? ''),
              )),
        ],
        if (_topProducts.isNotEmpty) ...[
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Top Products',
            action: TextButton(
              onPressed: () => setState(() => _selectedSection = 4),
              child: const Text('Analytics', style: TextStyle(color: _kTeal, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          ..._topProducts.take(5).map((p) => _TopProductRow(product: p)),
        ],
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  PRODUCTS TAB
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildProductsTab() {
    final filtered      = _filteredProducts;
    final activeCount   = _products.where((p) => (p['listingStatus'] ?? '').toString().toUpperCase() == 'ACTIVE').length;
    final draftCount    = _products.where((p) => (p['listingStatus'] ?? '').toString().toUpperCase() == 'DRAFT').length;
    final inactiveCount = _products.where((p) => (p['listingStatus'] ?? '').toString().toUpperCase() == 'INACTIVE').length;

    return Column(children: [
      Container(
        color: _kCard,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Products', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _kText)),
                Text('${_products.length} products in catalogue', style: const TextStyle(color: _kTextMuted, fontSize: 12)),
              ]),
            ),
            _TealButton(label: '+ Add Product', onPressed: _showAddProductDialog),
          ]),
          const SizedBox(height: 16),
          _SearchBar(
            controller: _productSearchC,
            hint: 'Search by name or SKU…',
            onSubmit: _searchProducts,
            onClear: () { _productSearchC.clear(); _fetchProducts(loader: true); },
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final entry in {
                'All': _products.length,
                'ACTIVE': activeCount,
                'DRAFT': draftCount,
                'INACTIVE': inactiveCount,
              }.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterPill(
                    label: entry.key,
                    count: entry.value,
                    active: _productFilterStatus == entry.key,
                    onTap: () => setState(() => _productFilterStatus = entry.key),
                  ),
                ),
            ]),
          ),
        ]),
      ),
      Container(height: 1, color: _kBorder),
      Expanded(
        child: filtered.isEmpty
            ? _EmptyState(
                icon: _productSearchC.text.isNotEmpty ? Icons.search_off_rounded : Icons.inventory_2_outlined,
                label: _productSearchC.text.isNotEmpty ? 'No products match your search' : 'No products yet. Add your first product.',
                action: _productSearchC.text.isEmpty
                    ? _TealButton(label: '+ Add Product', onPressed: _showAddProductDialog)
                    : null,
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final p = filtered[i] as Map<String, dynamic>? ?? {};
                  return _ProductCard(
                    product: p,
                    onVariants: () => _showVariantsDialog(p),
                  );
                },
              ),
      ),
    ]);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  INVENTORY TAB
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildInventoryTab() {
    final totalSKUs     = _inventorySummary['totalSKUs'] ?? _inventory.length;
    final lowStockCount = _inventorySummary['lowStockCount'] ?? 0;
    final outOfStock    = _inventorySummary['outOfStockCount'] ?? 0;

    return Column(children: [
      Container(
        color: _kCard,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Inventory', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _kText)),
                Text('$totalSKUs SKUs tracked', style: const TextStyle(color: _kTextMuted, fontSize: 12)),
              ]),
            ),
            _OutlineBtn(label: 'Sync', icon: Icons.sync_rounded, onPressed: () => _fetchInventory(loader: true)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _MiniStatCard(label: 'Total SKUs', value: '$totalSKUs', color: _kTeal)),
            const SizedBox(width: 10),
            Expanded(child: _MiniStatCard(label: 'Low Stock', value: '$lowStockCount', color: _kAmber)),
            const SizedBox(width: 10),
            Expanded(child: _MiniStatCard(label: 'Out of Stock', value: '$outOfStock', color: _kRed)),
          ]),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              setState(() => _inventoryLowStockOnly = !_inventoryLowStockOnly);
              _fetchInventory(loader: true);
            },
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 40, height: 22,
                decoration: BoxDecoration(
                  color: _inventoryLowStockOnly ? _kTeal : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 180),
                  alignment: _inventoryLowStockOnly ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 18, height: 18,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Show low stock only', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kText)),
            ]),
          ),
        ]),
      ),
      Container(height: 1, color: _kBorder),
      Expanded(
        child: _inventory.isEmpty
            ? const _EmptyState(icon: Icons.warehouse_outlined, label: 'No inventory data')
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _inventory.length,
                itemBuilder: (ctx, i) {
                  final item = _inventory[i] as Map<String, dynamic>? ?? {};
                  return _InventoryCard(item: item, onAdjust: () => _showAdjustInventoryDialog(item));
                },
              ),
      ),
    ]);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  ORDERS TAB
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildOrdersTab() {
    final filtered  = _filteredOrders;
    int pending = 0, processing = 0, shipped = 0, delivered = 0;
    for (final o in _orders) {
      final s = _getVendorStatus(o['items'] as List? ?? []);
      if (s == 'pending') pending++;
      else if (s == 'processing') processing++;
      else if (s == 'shipped') shipped++;
      else if (s == 'delivered') delivered++;
    }

    return Column(children: [
      Container(
        color: _kCard,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Orders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _kText)),
                Text('${_orders.length} total orders', style: const TextStyle(color: _kTextMuted, fontSize: 12)),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _MiniStatCard(label: 'Pending',    value: '$pending',    color: _kAmber)),
            const SizedBox(width: 10),
            Expanded(child: _MiniStatCard(label: 'Processing', value: '$processing', color: _kTeal)),
            const SizedBox(width: 10),
            Expanded(child: _MiniStatCard(label: 'Shipped',    value: '$shipped',    color: const Color(0xFF6366F1))),
            const SizedBox(width: 10),
            Expanded(child: _MiniStatCard(label: 'Delivered',  value: '$delivered',  color: _kGreen)),
          ]),
          const SizedBox(height: 12),
          _SearchBar(
            controller: _orderSearchC,
            hint: 'Search by Order ID or status…',
            onSubmit: (_) => setState(() {}),
            onClear: () { _orderSearchC.clear(); setState(() {}); },
          ),
        ]),
      ),
      Container(height: 1, color: _kBorder),
      Expanded(
        child: filtered.isEmpty
            ? const _EmptyState(icon: Icons.receipt_long_outlined, label: 'No orders yet')
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final order = filtered[i] as Map<String, dynamic>? ?? {};
                  final items = order['items'] as List? ?? [];
                  return _OrderRowCard(
                    order: order,
                    statusText: _getVendorStatus(items),
                    onFulfillment: () => _showFulfillmentDialog(order),
                    onViewDetail: () => _fetchOrderById(order['id']?.toString() ?? ''),
                  );
                },
              ),
      ),
    ]);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  ANALYTICS TAB
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAnalyticsTab() {
    final summary     = _salesAnalytics['summary'] as Map<String, dynamic>? ?? {};
    final fulfillment = _performanceAnalytics['fulfillment'] as Map<String, dynamic>? ?? {};
    final returns     = _performanceAnalytics['returns'] as Map<String, dynamic>? ?? {};

    const timeframes = {
      'last_7_days': 'Last 7 Days', 'last_30_days': 'Last 30 Days',
      'last_90_days': 'Last 90 Days', 'this_month': 'This Month',
      'this_year': 'This Year', 'last_12_months': 'Last 12 Months',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _kText)),
              Text('Sales & performance insights', style: TextStyle(color: _kTextMuted, fontSize: 13)),
            ]),
          ),
          Container(
            decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: _kBorder)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _analyticsTimeframe,
                style: const TextStyle(fontSize: 13, color: _kText, fontWeight: FontWeight.w600),
                items: timeframes.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _analyticsTimeframe = v);
                  _fetchAnalytics(loader: true);
                },
              ),
            ),
          ),
        ]),
        const SizedBox(height: 22),
        _SectionHeader(title: 'Sales Summary'),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (ctx, constraints) {
          final cols = constraints.maxWidth > 600 ? 4 : 2;
          final gap  = 12.0;
          final w    = (constraints.maxWidth - gap * (cols - 1)) / cols;
          final cards = [
            _KpiData('Total Revenue',   '₹${summary['totalRevenue'] ?? '0.00'}',  Icons.currency_rupee_rounded, _kTeal,                 _kTealLight),
            _KpiData('Orders',          '${summary['orderCount'] ?? 0}',           Icons.receipt_long_rounded,   const Color(0xFF6366F1), const Color(0xFFEEF2FF)),
            _KpiData('Units Sold',      '${summary['unitsSold'] ?? 0}',            Icons.shopping_bag_rounded,   _kAmber,                _kAmberLight),
            _KpiData('Avg Order Value', '₹${summary['avgOrderValue'] ?? '0.00'}', Icons.trending_up_rounded,    _kGreen,                _kGreenLight),
          ];
          return Wrap(spacing: gap, runSpacing: gap, children: [
            for (final c in cards) SizedBox(width: w, child: _KpiCard(data: c, compact: true)),
          ]);
        }),
        const SizedBox(height: 22),
        _SectionHeader(title: 'Fulfillment Performance'),
        const SizedBox(height: 12),
        _AnalyticsGrid(items: [
          _AnalyticsTile(label: 'Avg Hours to Ship', value: '${fulfillment['avgHoursToShip'] ?? '—'}h'),
          _AnalyticsTile(label: 'Cancellation Rate', value: '${fulfillment['cancellationRate'] ?? '—'}'),
          _AnalyticsTile(label: 'Shipped Count',     value: '${fulfillment['shippedCount'] ?? 0}'),
          _AnalyticsTile(label: 'Delivered Count',   value: '${fulfillment['deliveredCount'] ?? 0}'),
        ]),
        const SizedBox(height: 22),
        _SectionHeader(title: 'Returns & Refunds'),
        const SizedBox(height: 12),
        _AnalyticsGrid(items: [
          _AnalyticsTile(label: 'Return Rate',       value: '${returns['returnRate'] ?? '—'}'),
          _AnalyticsTile(label: 'Return Requests',   value: '${returns['returnRequests'] ?? 0}'),
          _AnalyticsTile(label: 'Completed Returns', value: '${returns['completedReturns'] ?? 0}'),
          _AnalyticsTile(label: 'Total Refunded',    value: '₹${returns['totalRefunded'] ?? '0.00'}'),
        ]),
        if (_topProducts.isNotEmpty) ...[
          const SizedBox(height: 22),
          _SectionHeader(title: 'Top Products by Revenue'),
          const SizedBox(height: 12),
          ..._topProducts.map((p) => _TopProductRow(product: p, showRank: true)),
        ],
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  DIALOGS
  // ─────────────────────────────────────────────────────────────────────────
  void _showAddProductDialog() {
    final nameC     = TextEditingController();
    final descC     = TextEditingController();
    final priceC    = TextEditingController();
    final discountC = TextEditingController();
    final stockC    = TextEditingController();
    final urlC      = TextEditingController();
    final materialC = TextEditingController();

    String? selectedBrandId;
    String? selectedCategoryId;
    String? selectedSubCategoryId;

    final List<Map<String, dynamic>> variants  = [];
    final List<String>               imageUrls = [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          final List<dynamic> subCategories = selectedCategoryId != null
              ? _getSubCategories(selectedCategoryId!)
              : [];

          if (selectedSubCategoryId != null &&
              !subCategories.any((s) => _categoryId(s) == selectedSubCategoryId)) {
            selectedSubCategoryId = null;
          }

          return _NirvistaDialog(
            title: 'Add New Product',
            onConfirm: () async {
              final title     = nameC.text.trim();
              final priceText = priceC.text.trim();
              final discText  = discountC.text.trim();
              final stockText = stockC.text.trim();

              final autoUrl = urlC.text.trim();
              if (autoUrl.isNotEmpty && !imageUrls.contains(autoUrl)) imageUrls.add(autoUrl);

              if (title.isEmpty) { _snack('Product title is required', true); return; }
              if (selectedBrandId == null || selectedBrandId!.isEmpty) { _snack('Please select a brand', true); return; }
              if (selectedCategoryId == null || selectedCategoryId!.isEmpty) { _snack('Please select a category', true); return; }

              final price = priceText.isEmpty ? 0.0 : double.tryParse(priceText);
              if (price == null) { _snack('Enter a valid price (e.g. 299.99)', true); return; }

              final discountPrice = discText.isEmpty ? null : double.tryParse(discText);
              final autoSku = '${title.replaceAll(RegExp(r"\s+"), "-").toLowerCase()}-${DateTime.now().millisecondsSinceEpoch}';
              final defaultVariant = <String, dynamic>{
                'sku'           : autoSku,
                'variantName'   : 'Default',
                'price'         : price,
                'discountPrice' : discountPrice,
                'stock'         : int.tryParse(stockText) ?? 0,
                'images'        : List<String>.from(imageUrls),
                'color'         : '',
                'size'          : '',
                'approvalStatus': 'pending',
              };

              final effectiveCategoryId =
                  (selectedSubCategoryId != null && selectedSubCategoryId!.isNotEmpty)
                      ? selectedSubCategoryId
                      : selectedCategoryId;

              // FIX APPLIED HERE: Changed 'listingStatus' from 'pending' to 'active'
              final body = <String, dynamic>{
                'title'         : title,
                'description'   : descC.text.trim(),
                'categoryId'    : effectiveCategoryId,
                'brandId'       : selectedBrandId,
                'material'      : materialC.text.trim(),
                'listingStatus' : 'active', 
                'approvalStatus': 'pending',
                'variants'      : [defaultVariant, ...variants],
              };

              Navigator.pop(ctx);
              await _createProduct(body);
            },
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _dInput(nameC, 'Product Title *', Icons.label_rounded),
              _dInput(descC, 'Description', Icons.description_rounded, maxLines: 3),
              // ── Brand Dropdown ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  value: selectedBrandId,
                  decoration: _dDeco('Select Brand *', Icons.business_rounded),
                  hint: const Text('Choose a brand'),
                  items: _brands.map((b) => DropdownMenuItem(
                    value: _extractId(b['id'] ?? b['_id']),
                    child: Text(b['name']?.toString() ?? 'Unknown'),
                  )).toList(),
                  onChanged: (v) => setD(() => selectedBrandId = v),
                ),
              ),
              // ── Parent / Root Category Dropdown ────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  value: selectedCategoryId,
                  decoration: _dDeco('Select Category *', Icons.category_rounded),
                  hint: const Text('Choose a category'),
                  items: _rootCategories.map((c) {
                    final id = _categoryId(c);
                    return DropdownMenuItem(
                      value: id,
                      child: Text(c['name']?.toString() ?? 'Unknown'),
                    );
                  }).toList(),
                  onChanged: (v) => setD(() {
                    selectedCategoryId    = v;
                    selectedSubCategoryId = null;
                  }),
                ),
              ),
              // ── Sub-Category section ────────────────────────────────────
              if (selectedCategoryId != null) ...[
                if (subCategories.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(children: [
                            const Icon(Icons.subdirectory_arrow_right_rounded, size: 14, color: _kTeal),
                            const SizedBox(width: 6),
                            const Text('Sub-Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kTealDark)),
                            const Spacer(),
                            if (selectedSubCategoryId != null)
                              GestureDetector(
                                onTap: () => setD(() => selectedSubCategoryId = null),
                                child: const Text('Clear', style: TextStyle(fontSize: 11, color: _kTextMuted, decoration: TextDecoration.underline)),
                              ),
                          ]),
                        ),
                        SizedBox(
                          height: 38,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: subCategories.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (ctx, i) {
                              final sub    = subCategories[i];
                              final subId  = _categoryId(sub);
                              final subName= sub['name']?.toString() ?? 'Unknown';
                              final active = selectedSubCategoryId == subId;
                              return GestureDetector(
                                onTap: () => setD(() => selectedSubCategoryId = subId),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color  : active ? _kTeal : _kBg,
                                    borderRadius: BorderRadius.circular(20),
                                    border : Border.all(color: active ? _kTeal : _kBorder),
                                  ),
                                  child: Text(subName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : _kTextMuted)),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          selectedSubCategoryId != null
                              ? 'Sub-category selected. Product will be listed under the selected sub-category.'
                              : 'Optional — select a sub-category to narrow the listing.',
                          style: TextStyle(fontSize: 10, color: selectedSubCategoryId != null ? _kTealDark : _kTextMuted),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(children: [
                      const Icon(Icons.info_outline_rounded, size: 13, color: _kTextMuted),
                      const SizedBox(width: 6),
                      const Text('This category has no sub-categories.', style: TextStyle(fontSize: 11, color: _kTextMuted)),
                    ]),
                  ),
                ],
              ],
              _dInput(priceC,    'Base Price (₹) *',               Icons.currency_rupee_rounded, numeric: true),
              _dInput(discountC, 'Discount Price (₹)',              Icons.tag_rounded,            numeric: true),
              _dInput(materialC, 'Material (e.g. cotton, leather)', Icons.texture_rounded),
              _dInput(stockC,    'Initial Stock',                   Icons.inventory_2_rounded,    numeric: true),
              const SizedBox(height: 8),
              _sectionLabel('Additional Variants'),
              ...variants.asMap().entries.map((e) => _VariantFormCard(
                index: e.key,
                data: e.value,
                onRemove: () => setD(() => variants.removeAt(e.key)),
                onChanged: () => setD(() {}),
              )),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => setD(() => variants.add({})),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Variant'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kTeal,
                  side: const BorderSide(color: _kTeal),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  void _showVariantsDialog(Map<String, dynamic> product) {
    final variants  = product['variants'] as List? ?? [];
    final productId = product['id']?.toString() ?? '';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Container(
            width: 560,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _dialogHeader('Manage Variants — ${product['title'] ?? 'Product'}', ctx),
              Flexible(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: variants.length,
                  itemBuilder: (ctx, i) {
                    final v = variants[i] as Map<String, dynamic>;
                    final variantId      = v['id']?.toString() ?? '';
                    final approvalStatus = v['approvalStatus']?.toString() ?? 'pending';
                    Color approvalColor  = approvalStatus == 'approved' ? _kGreen : approvalStatus == 'rejected' ? _kRed : _kAmber;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: _kBorder)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(v['variantName']?.toString() ?? v['sku']?.toString() ?? 'Variant ${i+1}',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _kText))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: approvalColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                              child: Text(approvalStatus.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: approvalColor)),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          Wrap(spacing: 16, runSpacing: 4, children: [
                            _InfoChip(Icons.qr_code_2_rounded, v['sku']?.toString() ?? '—'),
                            _InfoChip(Icons.currency_rupee_rounded, '${v['price'] ?? '—'}'),
                            _InfoChip(Icons.inventory_2_rounded, '${v['stock'] ?? 0} units'),
                            if (v['color'] != null && v['color'].toString().isNotEmpty)
                              _InfoChip(Icons.circle_rounded, v['color'].toString()),
                            if (v['size'] != null && v['size'].toString().isNotEmpty)
                              _InfoChip(Icons.straighten_rounded, v['size'].toString()),
                          ]),
                          const SizedBox(height: 10),
                          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                            _OutlineBtn(label: 'Edit', icon: Icons.edit_rounded, onPressed: () => _showEditVariantDialog(productId, v, setD), compact: true),
                          ]),
                        ]),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _OutlineBtn(label: 'Add Variant', icon: Icons.add_rounded, onPressed: () => _showAddVariantDialog(productId)),
                  _TealButton(label: 'Done', onPressed: () => Navigator.pop(ctx)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _showAddVariantDialog(String productId) {
    final skuC         = TextEditingController();
    final variantNameC = TextEditingController();
    final priceC       = TextEditingController();
    final discountC    = TextEditingController();
    final sizeC        = TextEditingController();
    final colorC       = TextEditingController();
    final stockC       = TextEditingController();
    final urlC         = TextEditingController();
    final List<String> imageUrls = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => _NirvistaDialog(
          title: 'Add Variant',
          onConfirm: () {
            final autoUrl = urlC.text.trim();
            if (autoUrl.isNotEmpty && !imageUrls.contains(autoUrl)) imageUrls.add(autoUrl);
            String sku = skuC.text.trim();
            if (sku.isEmpty) {
              sku = '${variantNameC.text.trim().isNotEmpty ? variantNameC.text.trim() : 'variant'}-${DateTime.now().millisecondsSinceEpoch}';
            }
            Navigator.pop(ctx);
            _addVariant(productId, {
              'sku': sku,
              'variantName': variantNameC.text.trim(),
              'price': double.tryParse(priceC.text.trim()) ?? 0,
              'discountPrice': double.tryParse(discountC.text.trim()),
              'size': sizeC.text.trim(),
              'color': colorC.text.trim(),
              'stock': int.tryParse(stockC.text.trim()) ?? 0,
              'images': imageUrls,
            });
          },
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _dInput(skuC,         'SKU (optional)',     Icons.qr_code_2_rounded),
            _dInput(variantNameC, 'Variant Name',       Icons.label_rounded),
            _dInput(priceC,       'Price (₹)',          Icons.currency_rupee_rounded, numeric: true),
            _dInput(discountC,    'Discount Price (₹)', Icons.tag_rounded,            numeric: true),
            _dInput(sizeC,        'Size',               Icons.straighten_rounded),
            _dInput(colorC,       'Color',              Icons.palette_rounded),
            _dInput(stockC,       'Stock',              Icons.inventory_2_rounded,    numeric: true),
            _sectionLabel('Images'),
            _UrlOnlyImageAdder(urlController: urlC, imageUrls: imageUrls, onChanged: () => setD(() {})),
          ]),
        ),
      ),
    );
  }

  void _showEditVariantDialog(String productId, Map<String, dynamic> variant, StateSetter setD) {
    final skuC         = TextEditingController(text: variant['sku']?.toString() ?? '');
    final variantNameC = TextEditingController(text: variant['variantName']?.toString() ?? '');
    final priceC       = TextEditingController(text: variant['price']?.toString() ?? '');
    final discountC    = TextEditingController(text: variant['discountPrice']?.toString() ?? '');
    final sizeC        = TextEditingController(text: variant['size']?.toString() ?? '');
    final colorC       = TextEditingController(text: variant['color']?.toString() ?? '');
    final stockC       = TextEditingController(text: variant['stock']?.toString() ?? '');
    final urlC         = TextEditingController();
    final imageUrls    = List<String>.from((variant['images'] as List? ?? []).map((e) => e.toString()));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD2) => _NirvistaDialog(
          title: 'Edit Variant',
          onConfirm: () {
            final autoUrl = urlC.text.trim();
            if (autoUrl.isNotEmpty && !imageUrls.contains(autoUrl)) imageUrls.add(autoUrl);
            Navigator.pop(ctx);
            _updateVariant(productId, variant['id'], {
              'sku': skuC.text.trim(),
              'variantName': variantNameC.text.trim(),
              'price': double.tryParse(priceC.text.trim()) ?? 0,
              'discountPrice': double.tryParse(discountC.text.trim()),
              'size': sizeC.text.trim(),
              'color': colorC.text.trim(),
              'stock': int.tryParse(stockC.text.trim()) ?? 0,
              'images': imageUrls,
            });
          },
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _dInput(skuC,         'SKU',                Icons.qr_code_2_rounded),
            _dInput(variantNameC, 'Variant Name',       Icons.label_rounded),
            _dInput(priceC,       'Price (₹)',          Icons.currency_rupee_rounded, numeric: true),
            _dInput(discountC,    'Discount Price (₹)', Icons.tag_rounded,            numeric: true),
            _dInput(sizeC,        'Size',               Icons.straighten_rounded),
            _dInput(colorC,       'Color',              Icons.palette_rounded),
            _dInput(stockC,       'Stock',              Icons.inventory_2_rounded,    numeric: true),
            _sectionLabel('Images'),
            _UrlOnlyImageAdder(urlController: urlC, imageUrls: imageUrls, onChanged: () => setD2(() {})),
          ]),
        ),
      ),
    );
  }

  void _showAdjustInventoryDialog(dynamic item) {
    final quantityC = TextEditingController();
    final sku       = item['sku']?.toString() ?? '';
    String operation = 'increment';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => _NirvistaDialog(
          title: 'Adjust Stock',
          onConfirm: () {
            final qty = int.tryParse(quantityC.text.trim());
            if (qty == null || qty < 0) { _snack('Enter a valid non-negative quantity', true); return; }
            Navigator.pop(ctx);
            _adjustInventory(sku, {'quantity': qty, 'operation': operation});
          },
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: _kTealLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kTeal.withOpacity(0.3))),
              child: Row(children: [
                const Icon(Icons.qr_code_2_rounded, color: _kTeal, size: 18),
                const SizedBox(width: 8),
                Text('SKU: $sku', style: const TextStyle(fontWeight: FontWeight.w700, color: _kTealDark)),
                const SizedBox(width: 12),
                Text('Current: ${item['stock'] ?? item['availableStock'] ?? '—'} units', style: const TextStyle(color: _kTextMuted, fontSize: 12)),
              ]),
            ),
            const SizedBox(height: 14),
            Row(children: [
              for (final op in ['set', 'increment', 'decrement'])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () => setD(() => operation = op),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: operation == op ? _kTeal : _kBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: operation == op ? _kTeal : _kBorder),
                        ),
                        child: Text(op[0].toUpperCase() + op.substring(1),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: operation == op ? Colors.white : _kTextMuted)),
                      ),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 14),
            _dInput(quantityC, 'Quantity', Icons.numbers_rounded, numeric: true),
          ]),
        ),
      ),
    );
  }

  void _showFulfillmentDialog(dynamic order) {
    String status   = 'processing';
    final trackingC = TextEditingController();
    final carrierC  = TextEditingController();
    final orderId   = order['id']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => _NirvistaDialog(
          title: 'Update Fulfillment',
          onConfirm: () {
            Navigator.pop(ctx);
            _updateFulfillment(orderId, {
              'fulfillmentStatus': status,
              'trackingNumber': trackingC.text.trim(),
              'carrierName': carrierC.text.trim(),
            });
          },
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBorder)),
              child: Row(children: [
                const Icon(Icons.receipt_long_rounded, color: _kTeal, size: 18),
                const SizedBox(width: 8),
                Text('Order #${orderId.length > 8 ? orderId.substring(0, 8) : orderId}…',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _kText)),
              ]),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: status,
              decoration: _dDeco('Fulfillment Status', Icons.local_shipping_rounded),
              items: ['processing', 'shipped', 'delivered', 'cancelled']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
                  .toList(),
              onChanged: (v) => setD(() => status = v ?? 'processing'),
            ),
            const SizedBox(height: 12),
            _dInput(carrierC,  'Carrier (e.g. BlueDart, Delivery)', Icons.business_rounded),
            _dInput(trackingC, 'Tracking Number (optional)',        Icons.pin_drop_rounded),
          ]),
        ),
      ),
    );
  }

  void _showOrderDetailDialog(Map<String, dynamic> order) {
    final addr    = order['shippingAddress'] as Map<String, dynamic>? ?? {};
    final items   = order['items'] as List? ?? [];
    final orderId = order['id']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          width: 580,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _dialogHeader('Order Detail', ctx),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text('SHIPPING ADDRESS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _kTextMuted, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBorder)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(addr['recipientName'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.w700, color: _kText)),
                      const SizedBox(height: 4),
                      Text('${addr['addressLine1'] ?? ''}, ${addr['addressLine2'] ?? ''}', style: const TextStyle(fontSize: 13, color: _kText)),
                      Text('${addr['city'] ?? ''}, ${addr['state'] ?? ''} - ${addr['postal_code'] ?? ''}', style: const TextStyle(fontSize: 13, color: _kText)),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  const Text('ORDER ITEMS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _kTextMuted, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  ...items.map((item) {
                    final variant  = item['variant'] as Map<String, dynamic>? ?? {};
                    final product  = item['product'] as Map<String, dynamic>? ?? {};
                    final status   = item['fulfillmentStatus']?.toString() ?? 'pending';
                    final canRefund = status == 'delivered' && (item['returnStatus'] == null);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBorder)),
                      child: Row(children: [
                        Container(width: 44, height: 44, decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.shopping_bag_outlined, color: _kTeal, size: 20)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(product['title'] ?? 'Product', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          Text('SKU: ${variant['sku'] ?? 'N/A'} · Qty: ${item['quantity']}', style: const TextStyle(fontSize: 11, color: _kTextMuted)),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('₹${item['priceAtPurchase']}', style: const TextStyle(fontWeight: FontWeight.w700, color: _kTeal)),
                          const SizedBox(height: 4),
                          Row(children: [
                            if (canRefund) _ActionBtn(icon: Icons.assignment_return_rounded, label: 'Refund', color: _kAmber, onTap: () {
                              Navigator.pop(ctx);
                              _showRefundDialog(orderId, item);
                            }),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(4)),
                              child: Text(status.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _kTextMuted)),
                            ),
                          ]),
                        ]),
                      ]),
                    );
                  }).toList(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                Expanded(child: _OutlineBtn(label: 'Close', onPressed: () => Navigator.pop(ctx))),
                const SizedBox(width: 10),
                Expanded(child: _TealButton(label: 'Fulfill Order', icon: Icons.local_shipping_rounded, onPressed: () { Navigator.pop(ctx); _showFulfillmentDialog(order); })),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  void _showRefundDialog(String orderId, dynamic item) {
    final qtyC    = TextEditingController(text: '1');
    final reasonC = TextEditingController();
    final maxQty  = (item['quantity'] as int? ?? 1);

    showDialog(
      context: context,
      builder: (ctx) => _NirvistaDialog(
        title: 'Process Refund',
        onConfirm: () {
          final qty = int.tryParse(qtyC.text) ?? 0;
          if (qty < 1 || qty > maxQty) { _snack('Invalid quantity', true); return; }
          Navigator.pop(ctx);
          _initiateRefund(orderId, item['id'].toString(), qty, reasonC.text.trim());
        },
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Initiate a refund for this item. This will reverse the payment for the selected quantity.',
              style: TextStyle(fontSize: 12, color: _kTextMuted)),
          const SizedBox(height: 16),
          _dInput(qtyC,    'Refund Quantity (Max $maxQty)', Icons.numbers_rounded, numeric: true),
          _dInput(reasonC, 'Reason for Refund',             Icons.message_rounded, maxLines: 2),
        ]),
      ),
    );
  }

  // ── Dialog Helpers ──────────────────────────────────────────────────────
  Widget _dialogHeader(String title, BuildContext ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [_kTealDark, _kTeal], begin: Alignment.centerLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(children: [
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))),
          IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20), visualDensity: VisualDensity.compact),
        ]),
      );

  Widget _dInput(TextEditingController c, String label, IconData icon, {bool numeric = false, int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(controller: c, maxLines: maxLines, keyboardType: numeric ? TextInputType.number : TextInputType.text, decoration: _dDeco(label, icon)),
      );

  InputDecoration _dDeco(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: _kTeal),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kTeal, width: 2)),
        filled: true, fillColor: _kBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        labelStyle: const TextStyle(fontSize: 13, color: _kTextMuted),
      );

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _kTealDark)),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────
class _KpiData {
  final String label, value;
  final IconData icon;
  final Color color, bgColor;
  const _KpiData(this.label, this.value, this.icon, this.color, this.bgColor);
}

class _AnalyticsTile {
  final String label, value;
  const _AnalyticsTile({required this.label, required this.value});
}

// ─────────────────────────────────────────────────────────────────────────────
//  REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});
  final String title;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Row(children: [
      Container(width: 4, height: 18, decoration: BoxDecoration(color: _kTeal, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _kText)),
    ])),
    if (action != null) action!,
  ]);
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data, this.compact = false});
  final _KpiData data;
  final bool compact;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(compact ? 14 : 18),
    decoration: BoxDecoration(
      color: _kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: _kBorder),
      boxShadow: [BoxShadow(color: data.color.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: Row(children: [
      Container(width: 48, height: 48, decoration: BoxDecoration(color: data.bgColor, borderRadius: BorderRadius.circular(14)), child: Icon(data.icon, color: data.color, size: 22)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(data.label, style: const TextStyle(color: _kTextMuted, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 3),
        Text(data.value, style: TextStyle(fontSize: compact ? 18 : 20, fontWeight: FontWeight.w800, color: _kText), overflow: TextOverflow.ellipsis),
      ])),
    ]),
  );
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _kTextMuted)),
    ]),
  );
}

class _AnalyticsGrid extends StatelessWidget {
  const _AnalyticsGrid({required this.items});
  final List<_AnalyticsTile> items;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (ctx, constraints) {
    final cols = constraints.maxWidth > 500 ? 4 : 2;
    final gap  = 10.0;
    final w    = (constraints.maxWidth - gap * (cols - 1)) / cols;
    return Wrap(spacing: gap, runSpacing: gap, children: [
      for (final item in items)
        SizedBox(width: w, child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: _kBorder),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.label, style: const TextStyle(color: _kTextMuted, fontSize: 11, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(item.value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _kText)),
          ]),
        )),
    ]);
  });
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.count, required this.active, required this.onTap});
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: active ? _kTeal : _kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: active ? _kTeal : _kBorder)),
      child: Text('$label ($count)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : _kTextMuted)),
    ),
  );
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.hint, required this.onSubmit, required this.onClear});
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onSubmit;
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onSubmitted: onSubmit,
    style: const TextStyle(fontSize: 13),
    decoration: InputDecoration(
      hintText: hint, hintStyle: const TextStyle(color: _kTextMuted, fontSize: 13),
      prefixIcon: const Icon(Icons.search_rounded, color: _kTeal, size: 20),
      suffixIcon: controller.text.isNotEmpty
          ? IconButton(icon: const Icon(Icons.clear_rounded, size: 18, color: _kTextMuted), onPressed: onClear)
          : IconButton(icon: const Icon(Icons.search_rounded, size: 18, color: _kTeal), onPressed: () => onSubmit(controller.text)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kTeal, width: 1.5)),
      filled: true, fillColor: _kBg, contentPadding: const EdgeInsets.symmetric(vertical: 12),
    ),
  );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 12, color: _kTeal), const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 12, color: _kTextMuted, fontWeight: FontWeight.w500)),
  ]);
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBorder),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))]),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 30, height: 30, decoration: BoxDecoration(color: _kTealLight, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: _kTeal)),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kText)),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  PRODUCT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onVariants});
  final Map<String, dynamic> product;
  final VoidCallback onVariants;

  Color _statusColor(String? s) { switch (s?.toUpperCase()) { case 'ACTIVE': return _kGreen; case 'DRAFT': return _kAmber; case 'INACTIVE': return _kRed; default: return Colors.grey; } }
  Color _statusBg(String? s) { switch (s?.toUpperCase()) { case 'ACTIVE': return _kGreenLight; case 'DRAFT': return _kAmberLight; case 'INACTIVE': return _kRedLight; default: return Colors.grey.shade100; } }

  @override
  Widget build(BuildContext context) {
    final variants     = product['variants'] as List? ?? [];
    final firstVariant = variants.isNotEmpty ? variants.first as Map<String, dynamic> : null;
    final images       = <String>[];
    if (product['imageUrls'] is List) images.addAll((product['imageUrls'] as List).map((e) => e.toString()));
    if (images.isEmpty && product['images'] is List) images.addAll((product['images'] as List).map((e) => e.toString()));
    if (images.isEmpty) {
      for (final v in variants) {
        if (v is Map<String, dynamic> && v['images'] is List) {
          final vImgs = (v['images'] as List).map((e) => e.toString()).where((s) => s.isNotEmpty);
          if (vImgs.isNotEmpty) { images.addAll(vImgs); break; }
        }
      }
    }
    final status        = product['listingStatus']?.toString();
    final sku           = firstVariant?['sku'] ?? firstVariant?['variantName'] ?? '—';
    final stock         = firstVariant?['stock'] ?? 0;
    final originalPrice = firstVariant?['price'] ?? product['basePrice'] ?? product['price'] ?? 0;
    final discountPrice = firstVariant?['discountPrice'];
    final displayPrice  = (discountPrice != null && (double.tryParse(discountPrice.toString()) ?? 0) > 0) ? discountPrice : originalPrice;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: _kBorder),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(borderRadius: BorderRadius.circular(12),
              child: images.isNotEmpty
                  ? Image.network(images.first, width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imagePlaceholder())
                  : _imagePlaceholder()),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product['title']?.toString() ?? product['name']?.toString() ?? 'Unnamed',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _kText)),
              const SizedBox(height: 6),
              Row(children: [_InfoChip(Icons.qr_code_2_rounded, sku.toString()), const SizedBox(width: 14), _InfoChip(Icons.inventory_2_rounded, '$stock units')]),
              const SizedBox(height: 6),
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: _kTealLight, borderRadius: BorderRadius.circular(6)),
                    child: Text('₹$displayPrice', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: _kTealDark))),
                if (discountPrice != null && (double.tryParse(discountPrice.toString()) ?? 0) > 0) ...[
                  const SizedBox(width: 6),
                  Text('₹$originalPrice', style: const TextStyle(fontSize: 11, color: Color(0xFF757575), decoration: TextDecoration.lineThrough, decorationColor: Color(0xFF555555), decorationThickness: 1.5)),
                ],
                const SizedBox(width: 8),
                if (variants.isNotEmpty)
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(6), border: Border.all(color: _kBorder)),
                      child: Text('${variants.length} variant${variants.length > 1 ? 's' : ''}', style: const TextStyle(fontSize: 11, color: _kTextMuted, fontWeight: FontWeight.w600))),
              ]),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: _statusBg(status), borderRadius: BorderRadius.circular(20)),
                child: Text(status?.toUpperCase() ?? '—', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _statusColor(status)))),
          ]),
        ),
        Container(
          decoration: BoxDecoration(color: _kBg, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)), border: Border(top: BorderSide(color: _kBorder))),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(children: [
            _ActionBtn(icon: Icons.layers_rounded, label: 'Variants', onTap: onVariants),
          ]),
        ),
      ]),
    );
  }

  Widget _imagePlaceholder() => Container(width: 64, height: 64, decoration: BoxDecoration(color: _kTealLight, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.image_rounded, color: _kTeal, size: 28));
}

// ─────────────────────────────────────────────────────────────────────────────
//  INVENTORY CARD
// ─────────────────────────────────────────────────────────────────────────────
class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.item, required this.onAdjust});
  final Map<String, dynamic> item;
  final VoidCallback onAdjust;
  @override
  Widget build(BuildContext context) {
    final alerts   = item['alerts'] as Map<String, dynamic>? ?? {};
    final isLow    = alerts['lowStock'] == true;
    final isOut    = alerts['outOfStock'] == true;
    final stock    = item['availableStock'] ?? item['stock'] ?? 0;
    final reserved = item['reservedStock'] ?? 0;
    Color statusColor = isOut ? _kRed : isLow ? _kAmber : _kGreen;
    Color statusBg    = isOut ? _kRedLight : isLow ? _kAmberLight : _kGreenLight;
    String statusText = isOut ? 'Out of Stock' : isLow ? 'Low Stock' : 'In Stock';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isOut ? _kRed.withOpacity(0.3) : isLow ? _kAmber.withOpacity(0.3) : _kBorder),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))]),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.warehouse_rounded, color: statusColor, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item['sku']?.toString() ?? '—', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _kText)),
            if (item['productTitle'] != null || item['variantName'] != null)
              Text('${item['productTitle'] ?? ''} ${item['variantName'] != null ? '· ${item['variantName']}' : ''}', style: const TextStyle(color: _kTextMuted, fontSize: 12)),
            const SizedBox(height: 4),
            Row(children: [
              _InfoChip(Icons.inventory_2_rounded, '$stock available'),
              if (reserved > 0) ...[const SizedBox(width: 10), _InfoChip(Icons.lock_outline_rounded, '$reserved reserved')],
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                child: Text(statusText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor))),
            const SizedBox(height: 8),
            _OutlineBtn(label: 'Adjust', icon: Icons.edit_rounded, onPressed: onAdjust, compact: true),
          ]),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ORDER ROW CARD
// ─────────────────────────────────────────────────────────────────────────────
class _OrderRowCard extends StatelessWidget {
  const _OrderRowCard({required this.order, required this.statusText, required this.onFulfillment, required this.onViewDetail});
  final Map<String, dynamic> order;
  final String statusText;
  final VoidCallback onFulfillment;
  final VoidCallback onViewDetail;
  Color _statusColor(String s) { switch (s.toLowerCase()) { case 'delivered': return _kGreen; case 'shipped': return const Color(0xFF6366F1); case 'processing': return _kTeal; case 'packed': return _kAmber; case 'cancelled': return _kRed; default: return _kTextMuted; } }
  Color _statusBg(String s) { switch (s.toLowerCase()) { case 'delivered': return _kGreenLight; case 'shipped': return const Color(0xFFEEF2FF); case 'processing': return _kTealLight; case 'packed': return _kAmberLight; case 'cancelled': return _kRedLight; default: return _kBg; } }
  @override
  Widget build(BuildContext context) {
    final orderId   = order['id']?.toString() ?? '—';
    final items     = order['items'] as List? ?? [];
    double total    = 0;
    for (final i in items) { total += (double.tryParse(i['priceAtPurchase']?.toString() ?? '0') ?? 0) * (i['quantity'] ?? 1); }
    final createdAt = order['createdAt']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: _kBorder),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))]),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: _kTealLight, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.receipt_long_rounded, color: _kTeal, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('#${orderId.length > 8 ? orderId.substring(0, 8) : orderId}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _kText)),
            const SizedBox(height: 3),
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: _statusBg(statusText), borderRadius: BorderRadius.circular(6)),
                  child: Text(statusText.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor(statusText)))),
              if (createdAt.isNotEmpty) ...[const SizedBox(width: 8), Text(createdAt.length > 10 ? createdAt.substring(0, 10).replaceAll('-', '/') : createdAt, style: const TextStyle(color: _kTextMuted, fontSize: 11))],
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _kTeal)),
            const SizedBox(height: 6),
            Row(children: [
              _OutlineBtn(label: 'Detail', onPressed: onViewDetail, compact: true),
              const SizedBox(width: 6),
              _TealButton(label: 'Fulfill', icon: Icons.local_shipping_rounded, onPressed: onFulfillment, compact: true),
            ]),
          ]),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TOP PRODUCT ROW
// ─────────────────────────────────────────────────────────────────────────────
class _TopProductRow extends StatelessWidget {
  const _TopProductRow({required this.product, this.showRank = false});
  final dynamic product;
  final bool showRank;
  @override
  Widget build(BuildContext context) {
    final p = product as Map<String, dynamic>? ?? {};
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBorder)),
      child: Row(children: [
        if (showRank) ...[
          Container(width: 28, height: 28, decoration: BoxDecoration(color: _kTealLight, borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text('${p['rank'] ?? '—'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _kTealDark)))),
          const SizedBox(width: 12),
        ],
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p['productTitle']?.toString() ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _kText)),
          Text(p['sku']?.toString() ?? p['variantName']?.toString() ?? '', style: const TextStyle(color: _kTextMuted, fontSize: 11)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('₹${p['revenue'] ?? '0.00'}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _kTeal)),
          Text('${p['unitsSold'] ?? 0} sold', style: const TextStyle(color: _kTextMuted, fontSize: 11)),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.label, this.action});
  final IconData icon;
  final String label;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 80, height: 80, decoration: BoxDecoration(color: _kTealLight, borderRadius: BorderRadius.circular(24)), child: Icon(icon, size: 38, color: _kTeal)),
      const SizedBox(height: 16),
      Text(label, textAlign: TextAlign.center, style: const TextStyle(color: _kTextMuted, fontSize: 14, fontWeight: FontWeight.w500)),
      if (action != null) ...[const SizedBox(height: 16), action!],
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  BUTTONS
// ─────────────────────────────────────────────────────────────────────────────
class _TealButton extends StatelessWidget {
  const _TealButton({required this.label, this.icon, required this.onPressed, this.compact = false});
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool compact;
  @override
  Widget build(BuildContext context) => ElevatedButton(
    style: ElevatedButton.styleFrom(backgroundColor: _kTeal, foregroundColor: Colors.white, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: compact ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8) : const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
    onPressed: onPressed,
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[Icon(icon, size: compact ? 14 : 16), SizedBox(width: compact ? 4 : 6)],
      Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: compact ? 12 : 13)),
    ]),
  );
}

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({required this.label, this.icon, required this.onPressed, this.compact = false});
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool compact;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(foregroundColor: _kTeal, side: const BorderSide(color: _kTeal),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: compact ? const EdgeInsets.symmetric(horizontal: 10, vertical: 7) : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
        textStyle: TextStyle(fontSize: compact ? 12 : 13, fontWeight: FontWeight.w600)),
    child: icon != null
        ? Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: compact ? 14 : 16), SizedBox(width: compact ? 4 : 6), Text(label)])
        : Text(label),
  );
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.icon, required this.label, required this.onTap, this.color = _kTeal});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onTap,
    style: TextButton.styleFrom(foregroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), visualDensity: VisualDensity.compact),
    icon: Icon(icon, size: 15),
    label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  NIRVISTA DIALOG
// ─────────────────────────────────────────────────────────────────────────────
class _NirvistaDialog extends StatelessWidget {
  const _NirvistaDialog({required this.title, required this.child, required this.onConfirm});
  final String title;
  final Widget child;
  final VoidCallback onConfirm;
  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 32),
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 540, maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [_kTealDark, _kTeal], begin: Alignment.centerLeft, end: Alignment.centerRight),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(children: [
            Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20), visualDensity: VisualDensity.compact),
          ]),
        ),
        Flexible(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: child)),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            _OutlineBtn(label: 'Cancel', onPressed: () => Navigator.pop(context)),
            const SizedBox(width: 10),
            _TealButton(label: 'Confirm', onPressed: onConfirm),
          ]),
        ),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  URL-ONLY IMAGE ADDER  (no device/gallery picker)
// ─────────────────────────────────────────────────────────────────────────────
class _UrlOnlyImageAdder extends StatefulWidget {
  const _UrlOnlyImageAdder({
    required this.urlController,
    required this.imageUrls,
    required this.onChanged,
  });
  final TextEditingController urlController;
  final List<String> imageUrls;
  final VoidCallback onChanged;

  @override
  State<_UrlOnlyImageAdder> createState() => _UrlOnlyImageAdderState();
}

class _UrlOnlyImageAdderState extends State<_UrlOnlyImageAdder> {
  void _addTypedUrl() {
    final url = widget.urlController.text.trim();
    if (url.isEmpty) return;
    if (!widget.imageUrls.contains(url)) {
      widget.imageUrls.add(url);
      widget.onChanged();
    }
    widget.urlController.clear();
    setState(() {});
  }

  void _remove(int index) {
    widget.imageUrls.removeAt(index);
    widget.onChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: TextField(
                controller: widget.urlController,
                style: const TextStyle(fontSize: 13),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _addTypedUrl(),
                decoration: InputDecoration(
                  hintText: 'Paste image URL…',
                  hintStyle: const TextStyle(color: _kTextMuted, fontSize: 12),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kTeal, width: 1.5)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  suffixIcon: widget.urlController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16, color: _kTextMuted),
                          visualDensity: VisualDensity.compact,
                          onPressed: () { widget.urlController.clear(); setState(() {}); },
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 6),
            // ── Link / Add URL button only ──────────────────────────────
            Tooltip(
              message: 'Add URL',
              child: InkWell(
                onTap: _addTypedUrl,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: _kTealLight, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.link_rounded, color: _kTeal, size: 20),
                ),
              ),
            ),
          ]),
          if (widget.imageUrls.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Paste an image URL and tap the link icon to add it.',
                style: TextStyle(color: _kTeal.withOpacity(0.7), fontSize: 11),
              ),
            ),
        ]),
      ),
      if (widget.imageUrls.isNotEmpty) ...[
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: widget.imageUrls.asMap().entries.map((entry) {
            final index = entry.key;
            final url   = entry.value;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: _kTealLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: _kTeal.withOpacity(0.25))),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _buildTileImage(url),
                  ),
                ),
                Positioned(
                  top: -6, right: -6,
                  child: GestureDetector(
                    onTap: () => _remove(index),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: _kRed, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        Text('${widget.imageUrls.length} image(s) added',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kTealDark)),
      ],
    ]);
  }

  Widget _buildTileImage(String url) {
    if (url.startsWith('http') || url.startsWith('https')) {
      return Image.network(
        url, width: 80, height: 80, fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Center(
            child: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                    : null,
                color: _kTeal,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _errorPlaceholder(),
      );
    }
    return _errorPlaceholder();
  }

  Widget _errorPlaceholder() => Container(
    color: _kRedLight.withOpacity(0.5),
    child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.broken_image_rounded, color: _kRed, size: 24),
      SizedBox(height: 4),
      Text('Load Error', style: TextStyle(fontSize: 9, color: _kRed, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  VARIANT FORM CARD
// ─────────────────────────────────────────────────────────────────────────────
class _VariantFormCard extends StatefulWidget {
  const _VariantFormCard({required this.index, required this.data, required this.onRemove, required this.onChanged});
  final int index;
  final Map<String, dynamic> data;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  @override
  State<_VariantFormCard> createState() => _VariantFormCardState();
}

class _VariantFormCardState extends State<_VariantFormCard> {
  late final TextEditingController _skuC, _stockC, _priceC, _discC, _colorC, _sizeC, _urlC;
  final List<String> _imageUrls = [];

  @override
  void initState() {
    super.initState();
    _skuC   = TextEditingController(text: widget.data['sku']?.toString() ?? '');
    _stockC = TextEditingController(text: widget.data['stock']?.toString() ?? '');
    _priceC = TextEditingController(text: widget.data['price']?.toString() ?? '');
    _discC  = TextEditingController(text: widget.data['discountPrice']?.toString() ?? '');
    _colorC = TextEditingController(text: widget.data['color']?.toString() ?? '');
    _sizeC  = TextEditingController(text: widget.data['size']?.toString() ?? '');
    _urlC   = TextEditingController();
    if (widget.data['images'] is List) _imageUrls.addAll((widget.data['images'] as List).map((e) => e.toString()));
    else if (widget.data['imageUrls'] is List) _imageUrls.addAll((widget.data['imageUrls'] as List).map((e) => e.toString()));
    for (final c in [_skuC, _stockC, _priceC, _discC, _colorC, _sizeC, _urlC]) { c.addListener(_sync); }
  }

  void _sync() {
    String sku = _skuC.text.trim();
    if (sku.isEmpty) sku = 'variant-${widget.index}-${DateTime.now().millisecondsSinceEpoch}';
    widget.data['sku']           = sku;
    widget.data['stock']         = int.tryParse(_stockC.text.trim()) ?? 0;
    widget.data['price']         = double.tryParse(_priceC.text.trim()) ?? 0;
    widget.data['discountPrice'] = double.tryParse(_discC.text.trim());
    widget.data['color']         = _colorC.text.trim();
    widget.data['size']          = _sizeC.text.trim();
    final autoUrl = _urlC.text.trim();
    final combinedImages = List<String>.from(_imageUrls);
    if (autoUrl.isNotEmpty && !combinedImages.contains(autoUrl)) combinedImages.add(autoUrl);
    widget.data['images'] = combinedImages;
    widget.onChanged();
  }

  @override
  void dispose() {
    for (final c in [_skuC, _stockC, _priceC, _discC, _colorC, _sizeC, _urlC]) c.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    labelText: label, prefixIcon: Icon(icon, size: 16, color: _kTeal),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kBorder)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kBorder)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kTeal, width: 1.5)),
    filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
    labelStyle: const TextStyle(fontSize: 12, color: _kTextMuted),
  );

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(color: const Color(0xFFF0FDFB), border: Border.all(color: _kTealLight, width: 1.5), borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(color: _kTealLight, borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
        child: Row(children: [
          const Icon(Icons.layers_rounded, size: 15, color: _kTeal), const SizedBox(width: 8),
          Text('Variant ${widget.index + 1}', style: const TextStyle(color: _kTealDark, fontWeight: FontWeight.w700, fontSize: 13)),
          const Spacer(),
          GestureDetector(onTap: widget.onRemove, child: const Icon(Icons.remove_circle_outline_rounded, size: 18, color: _kRed)),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _varInput(_skuC,   'SKU (optional)',      Icons.qr_code_2_rounded),
          _varInput(_priceC, 'Price (₹)',           Icons.currency_rupee_rounded, numeric: true),
          _varInput(_discC,  'Discount Price (₹)',  Icons.tag_rounded,            numeric: true),
          _varInput(_colorC, 'Color',               Icons.palette_rounded),
          _varInput(_sizeC,  'Size',                Icons.straighten_rounded),
          _varInput(_stockC, 'Stock',               Icons.inventory_2_rounded,    numeric: true),
          const Align(alignment: Alignment.centerLeft, child: Padding(
            padding: EdgeInsets.only(bottom: 8, top: 4),
            child: Text('Variant Images', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kTealDark)),
          )),
          _UrlOnlyImageAdder(urlController: _urlC, imageUrls: _imageUrls, onChanged: _sync),
        ]),
      ),
    ]),
  );

  Widget _varInput(TextEditingController c, String label, IconData icon, {bool numeric = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          keyboardType: numeric ? TextInputType.number : TextInputType.text,
          decoration: _dec(label, icon),
        ),
      );
}