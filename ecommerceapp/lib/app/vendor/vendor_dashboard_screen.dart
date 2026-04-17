import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_shop/base/get/login_data_controller.dart';
import 'package:pet_shop/services/vendor_api.dart';
import 'package:pet_shop/services/product_api.dart';
import 'package:pet_shop/services/brand_api.dart';
import 'package:pet_shop/services/category_api.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
const _kTeal            = Color(0xFF0D9488);
const _kTealLight       = Color(0xFFCCFBF1);
const _kTealMid         = Color(0xFF14B8A6);
const _kTealDark        = Color(0xFF0F766E);
const _kTealDeep        = Color(0xFF134E4A);
const _kRed             = Color(0xFFEF4444);
const _kGreen           = Color(0xFF22C55E);
const _kSidebar         = Color(0xFF0F4C45);
const _kSidebarActive   = Color(0xFF1A6B61);
const _kSidebarText     = Color(0xFFB2DFDB);
const _kBg              = Color(0xFFF0F4F3);

// ─────────────────────────────────────────────────────────────────────────────
//  MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
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
    Icons.insights_rounded,
  ];

  bool _isBusy = false;

  // Raw data
  List<dynamic> _products    = [];
  List<dynamic> _inventory   = [];
  List<dynamic> _orders      = [];
  List<dynamic> _brands      = [];
  List<dynamic> _categories  = [];
  Map<String, dynamic> _salesAnalytics       = {};
  Map<String, dynamic> _performanceAnalytics = {};
  List<dynamic> _topProducts = [];

  // Product search & filter state
  final TextEditingController _productSearchC = TextEditingController();
  String _productFilterStatus = 'All';

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
                .toString()
                .toLowerCase()
            : (p['sku'] ?? '').toString().toLowerCase();
        return name.contains(q) || sku.contains(q);
      }).toList();
    }
    if (_productFilterStatus != 'All') {
      list = list.where((p) => p['listingStatus'] == _productFilterStatus).toList();
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _productSearchC.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  @override
  void dispose() {
    _productSearchC.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    if (_token.isEmpty) { _snack('Missing token. Please login.', true); return; }
    await Future.wait([
      _fetchProducts(loader: true),
      _fetchInventory(loader: true),
      _fetchOrders(loader: true),
      _fetchAnalytics(loader: true),
      _fetchBrands(),
      _fetchCategories(),
    ]);
  }

  Future<void> _run(Future<void> Function() fn, {bool loader = true}) async {
    if (loader) setState(() => _isBusy = true);
    try { await fn(); } finally { if (loader && mounted) setState(() => _isBusy = false); }
  }

  // ── API wrappers ─────────────────────────────────────────────────────────

  // ------------------------------------------------------------------
  //  PRODUCTS — now backed by ProductApiService
  // ------------------------------------------------------------------

  /// Fetches all products from the public product catalogue and stores them.
  /// Uses [ProductApiService.getAllProducts] which hits GET /api/products.
  Future<void> _fetchProducts({bool loader = false}) => _run(() async {
    final r = await ProductApiService.getAllProducts();
    if (r['success'] == true) {
      final d = r['data'];
      if (d is Map && d['products'] is List) {
        setState(() => _products = List<dynamic>.from(d['products']));
      } else if (d is List) {
        setState(() => _products = d);
      } else {
        setState(() => _products = []);
      }
    } else {
      _snack(r['message'] ?? 'Cannot fetch products', true);
    }
  }, loader: loader);

  Future<void> _fetchBrands() => _run(() async {
    final r = await BrandApiService.getAllBrands();
    if (r['success'] == true) {
      final d = r['data'];
      setState(() => _brands = d is List ? d : []);
    }
  }, loader: false);

  Future<void> _fetchCategories() => _run(() async {
    final r = await CategoryApiService.getAllCategories();
    if (r['success'] == true) {
      final d = r['data'];
      setState(() => _categories = d is List ? d : []);
    }
  }, loader: false);

  List<dynamic> get _flatCategories {
    final result = <dynamic>[];
    void walk(List<dynamic> entries) {
      for (final entry in entries) {
        result.add(entry);
        if (entry['children'] is List) {
          walk(List<dynamic>.from(entry['children']));
        }
      }
    }
    walk(_categories);
    return result;
  }

  String _slugify(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9\s-]"), '')
        .replaceAll(RegExp(r"\s+"), '-')
        .replaceAll(RegExp(r"-+"), '-');
  }

  String? _brandIdForName(String name) {
    final lower = name.trim().toLowerCase();
    final match = _brands.firstWhere(
      (b) => (b['name']?.toString().toLowerCase() ?? '') == lower,
      orElse: () => null,
    );
    return match == null ? null : match['id']?.toString();
  }

  String? _categoryIdForName(String name) {
    final lower = name.trim().toLowerCase();
    final match = _flatCategories.firstWhere(
      (c) => (c['name']?.toString().toLowerCase() ?? '') == lower,
      orElse: () => null,
    );
    return match == null ? null : match['id']?.toString();
  }

  Future<String?> _createBrandIfMissing(String name) async {
    final existing = _brandIdForName(name);
    if (existing != null) return existing;

    final r = await BrandApiService.createBrand(_token, {
      'name': name.trim(),
      'description': 'Created from vendor dashboard',
    });
    if (r['success'] == true) {
      await _fetchBrands();
      return r['data']?['id']?.toString();
    }
    _snack(r['message'] ?? 'Failed to create brand', true);
    return null;
  }

  Future<String?> _createCategoryIfMissing(String name) async {
    final existing = _categoryIdForName(name);
    if (existing != null) return existing;

    final r = await CategoryApiService.createCategory(_token, {
      'name': name.trim(),
      'slug': _slugify(name),
      'description': 'Created from vendor dashboard',
    });
    if (r['success'] == true) {
      await _fetchCategories();
      return r['data']?['id']?.toString();
    }
    _snack(r['message'] ?? 'Failed to create category', true);
    return null;
  }

  /// Creates a new product via POST /api/products.
  /// After a successful create the list is refreshed with [_fetchProducts]
  /// so the newly saved product (with its server-assigned id) appears immediately.
  Future<void> _createProduct(Map<String, dynamic> body) => _run(() async {
    final r = await VendorApiService.createVendorProduct(_token, body);
    _snack(r['message'] ?? 'Done', r['success'] != true);
    if (r['success'] == true) {
      // Refresh the full list so the new product shows with its real id/data
      await _fetchProducts();
      setState(() => _selectedSection = 1);
    }
  });

  /// Attaches image URLs to a product or one of its variants.
  /// Deletes a product from the backend (hard delete).
  /// Falls back to marking INACTIVE if the server returns 405/404.
  Future<void> _deleteProduct(String id) => _run(() async {
    final r = await VendorApiService.deleteVendorProduct(_token, id);
    if (r['success'] == true) {
      _snack('Product deleted', false);
      await _fetchProducts();
    } else {
      // Hard delete not supported → cannot fallback since no status update
      _snack('Failed to delete product', true);
    }
  });

  // --- New variant management APIs ---

  /// Adds a new variant to an existing product.
  Future<void> _addVariant(String productId, Map<String, dynamic> payload) => _run(() async {
    final r = await VendorApiService.addVariant(_token, productId, payload);
    _snack(r['message'] ?? 'Variant added', r['success'] != true);
    if (r['success'] == true) await _fetchProducts(); // Refresh to show new variant
  });

  /// Updates an existing variant.
  Future<void> _updateVariant(String productId, String variantId, Map<String, dynamic> payload) => _run(() async {
    final r = await VendorApiService.updateVariant(_token, productId, variantId, payload);
    _snack(r['message'] ?? 'Variant updated', r['success'] != true);
    if (r['success'] == true) await _fetchProducts(); // Refresh to show changes
  });

  /// Deletes a variant from a product.
  Future<void> _deleteVariant(String productId, String variantId) => _run(() async {
    final r = await VendorApiService.deleteVariant(_token, productId, variantId);
    _snack(r['message'] ?? 'Variant deleted', r['success'] != true);
    if (r['success'] == true) await _fetchProducts(); // Refresh to remove variant
  });

  // ------------------------------------------------------------------
  //  SEARCH — uses ProductApiService.searchProducts
  // ------------------------------------------------------------------

  /// Searches via GET /api/products/search with keyword + optional filters.
  /// Results replace the local _products list; clearing the search field
  /// triggers a full [_fetchProducts] to restore the complete catalogue.
  Future<void> _searchProducts(String keyword) async {
    if (keyword.trim().isEmpty) {
      await _fetchProducts(loader: true);
      return;
    }
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

  // ------------------------------------------------------------------
  //  INVENTORY
  // ------------------------------------------------------------------
  Future<void> _fetchInventory({bool loader = false}) => _run(() async {
    final r = await VendorApiService.getVendorInventory(_token);
    if (r['success'] == true) {
      final d = r['data']; setState(() => _inventory = d is List ? d : []);
    } else { _snack(r['message'] ?? 'Cannot fetch inventory', true); }
  }, loader: loader);

  Future<void> _adjustInventory(String sku, Map<String, dynamic> payload) =>
      _run(() async {
    final r = await VendorApiService.adjustVendorInventory(_token, sku, payload);
    _snack(r['message'] ?? 'Adjusted', r['success'] != true);
    if (r['success'] == true) await _fetchInventory();
  });

  // ------------------------------------------------------------------
  //  ORDERS
  // ------------------------------------------------------------------
  Future<void> _fetchOrders({bool loader = false}) => _run(() async {
    final r = await VendorApiService.getVendorOrders(_token);
    if (r['success'] == true) {
      final d = r['data']; setState(() => _orders = d is List ? d : []);
    } else { _snack(r['message'] ?? 'Cannot fetch orders', true); }
  }, loader: loader);

  Future<void> _fetchOrderById(String orderId) => _run(() async {
    final r = await VendorApiService.getVendorOrderById(_token, orderId);
    if (r['success'] == true) {
      _showOrderDetailDialog(r['data'] as Map<String, dynamic>? ?? {});
    } else { _snack(r['message'] ?? 'Cannot fetch order', true); }
  });

  Future<void> _updateFulfillment(
      String orderId, Map<String, dynamic> payload) =>
      _run(() async {
    final r = await VendorApiService.updateFulfillment(_token, orderId, payload);
    _snack(r['message'] ?? 'Updated', r['success'] != true);
    if (r['success'] == true) await _fetchOrders();
  });

  // ------------------------------------------------------------------
  //  ANALYTICS
  // ------------------------------------------------------------------
  Future<void> _fetchAnalytics({bool loader = false}) => _run(() async {
    final sales = await VendorApiService.getVendorSalesAnalytics(_token);
    final perf  = await VendorApiService.getVendorPerformanceAnalytics(_token);
    final top   = await VendorApiService.getVendorTopProducts(_token);
    if (sales['success'] == true)
      _salesAnalytics = Map<String, dynamic>.from(sales['data'] ?? {});
    if (perf['success'] == true)
      _performanceAnalytics = Map<String, dynamic>.from(perf['data'] ?? {});
    if (top['success'] == true) {
      final d = top['data']; _topProducts = d is List ? d : [];
    }
    if (mounted) setState(() {});
  }, loader: loader);

  // ─────────────────────────────────────────────────────────────────────────
  //  SNACKBAR
  // ─────────────────────────────────────────────────────────────────────────
  void _snack(String msg, bool isError) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      backgroundColor: isError ? _kRed : _kTeal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  DIALOGS
  // ─────────────────────────────────────────────────────────────────────────

  void _showAddProductDialog() {
    final nameC     = TextEditingController();
    final descC     = TextEditingController();
    final priceC    = TextEditingController();
    final categoryC = TextEditingController();
    final brandC    = TextEditingController();
    final skuC      = TextEditingController();
    final stockC    = TextEditingController();
    String status   = 'ACTIVE';

    final List<Map<String, dynamic>> variants = [];
    final List<XFile> productPickedFiles      = [];
    final List<String> productImageUrls       = [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => _NirvistaDialog(
          title: 'Add Product',
          onConfirm: () async {
            final categoryName = categoryC.text.trim();
            final brandName = brandC.text.trim();
            if (nameC.text.trim().isEmpty) {
              _snack('Product title is required', true);
              return;
            }
            if (categoryName.isEmpty || brandName.isEmpty) {
              _snack('Brand and category are required', true);
              return;
            }
            final categoryId = await _createCategoryIfMissing(categoryName);
            if (categoryId == null) return;
            final brandId = await _createBrandIfMissing(brandName);
            if (brandId == null) return;

            final defaultVariant = {
              'variantName': skuC.text.trim().isEmpty ? 'Default' : skuC.text.trim(),
              'price': double.tryParse(priceC.text.trim()) ?? 0,
              'stock': int.tryParse(stockC.text.trim()) ?? 0,
              'images': productImageUrls,
              'color': '',
              'size': '',
              'approvalStatus': 'PENDING',
            };
            final allVariants = [defaultVariant, ...variants];
            final body = {
              'title': nameC.text.trim(),
              'description': descC.text.trim(),
              'categoryId': categoryId,
              'brandId': brandId,
              'material': '',
              'rating': 0,
              'approvalStatus': 'PENDING',
              'imageUrls': productImageUrls,
              'variants': allVariants,
            };
            Navigator.pop(ctx);
            await _createProduct(body);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Basic Info'),
              _dInput(nameC, 'Product Name', Icons.label_outline),
              _dInput(descC, 'Description', Icons.description_outlined, maxLines: 3),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _dInput(categoryC, 'Category (existing or new)', Icons.category_outlined),
                const SizedBox(height: 8),
                if (_flatCategories.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _flatCategories
                        .take(8)
                        .map((c) => ActionChip(
                              backgroundColor: _kTealLight,
                              label: Text(c['name']?.toString() ?? '',
                                  style: const TextStyle(fontSize: 12)),
                              onPressed: () => setD(() => categoryC.text = c['name']?.toString() ?? ''),
                            ))
                        .toList(),
                  ),
                const SizedBox(height: 12),
                _dInput(brandC, 'Brand (existing or new)', Icons.branding_watermark),
                const SizedBox(height: 8),
                if (_brands.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _brands
                        .take(8)
                        .map((b) => ActionChip(
                              backgroundColor: _kTealLight,
                              label: Text(b['name']?.toString() ?? '',
                                  style: const TextStyle(fontSize: 12)),
                              onPressed: () => setD(() => brandC.text = b['name']?.toString() ?? ''),
                            ))
                        .toList(),
                  ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _dInput(priceC, 'Base Price (₹)', Icons.currency_rupee, numeric: true)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: status,
                    decoration: _dDeco('Status', Icons.toggle_on),
                    items: ['ACTIVE', 'DRAFT', 'INACTIVE']
                        .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) => setD(() => status = v ?? 'ACTIVE'),
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              _sectionLabel('Default Variant'),
              Row(children: [
                Expanded(child: _dInput(skuC, 'SKU', Icons.qr_code_2)),
                const SizedBox(width: 12),
                Expanded(child: _dInput(stockC, 'Opening Stock',
                    Icons.inventory_outlined, numeric: true)),
              ]),
              const SizedBox(height: 4),
              _sectionLabel('Product Images'),
              _ImagePickerAdder(
                pickedFiles: productPickedFiles,
                imageUrls: productImageUrls,
                onChanged: () => setD(() {}),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionLabel('Additional Variants', margin: false),
                  TextButton.icon(
                    onPressed: () => setD(() => variants.add({
                          'sku': '',
                          'stock': 0,
                          'price': 0,
                          'attributes': {},
                          'imageUrls': [],
                          '_pickedFiles': <XFile>[],
                        })),
                    icon: const Icon(Icons.add_circle_outline,
                        size: 16, color: _kTeal),
                    label: const Text('Add Variant',
                        style: TextStyle(
                            color: _kTeal,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact),
                  ),
                ],
              ),
              if (variants.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('No additional variants added.',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ),
              ...variants.asMap().entries.map((entry) {
                final i = entry.key;
                final v = entry.value;
                return _VariantFormCard(
                  index: i,
                  data: v,
                  onRemove: () => setD(() => variants.removeAt(i)),
                  onChanged: () => setD(() {}),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showVariantsDialog(Map<String, dynamic> product) {
    final variants = product['variants'] as List? ?? [];
    final skuC = TextEditingController();
    final variantNameC = TextEditingController();
    final priceC = TextEditingController();
    final sizeC = TextEditingController();
    final colorC = TextEditingController();
    final stockC = TextEditingController();
    final List<XFile> variantPickedFiles = [];
    final List<String> variantImageUrls = [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: 520,
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogHeader('Variants — ${product['title'] ?? product['name'] ?? 'Product'}', ctx),
                Flexible(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (variants.isEmpty)
                        _emptyState(Icons.layers_outlined, 'No variants yet')
                      else
                        ...variants.map((v) => _VariantTile(
                          variant: v,
                          onEdit: () => _showEditVariantDialog(product['id'], v, setD),
                          onDelete: () => _showDeleteVariantDialog(product['id'], v['id'], setD),
                        )),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      _sectionLabel('Add New Variant'),
                      _dInput(skuC, 'Variant SKU', Icons.qr_code_2),
                      _dInput(variantNameC, 'Variant Name', Icons.label_outline),
                      _dInput(priceC, 'Price (₹)', Icons.currency_rupee, numeric: true),
                      _dInput(sizeC, 'Size', Icons.straighten),
                      _dInput(colorC, 'Color', Icons.color_lens),
                      _dInput(stockC, 'Stock', Icons.inventory_outlined, numeric: true),
                      _ImagePickerAdder(
                        pickedFiles: variantPickedFiles,
                        imageUrls: variantImageUrls,
                        onChanged: () => setD(() {}),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kTeal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            if (skuC.text.trim().isEmpty) {
                              _snack('SKU is required', true);
                              return;
                            }
                            Navigator.pop(ctx);
                            _addVariant(product['id'], {
                              'sku': skuC.text.trim(),
                              'variantName': variantNameC.text.trim(),
                              'price': double.tryParse(priceC.text.trim()) ?? 0,
                              'size': sizeC.text.trim(),
                              'color': colorC.text.trim(),
                              'stock': int.tryParse(stockC.text.trim()) ?? 0,
                              'images': variantImageUrls,
                            });
                          },
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Add Variant',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Confirmation dialog before hard-deleting a product.
  void _showDeleteProductDialog(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete Product'),
        content: Text(
            'Permanently delete "${product['title'] ?? product['name']}"?\n\nIf your backend doesn\'t support hard delete this will mark it as INACTIVE instead.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // → DELETE /api/vendor/products/:id
              _deleteProduct(product['id']?.toString() ?? '');
            },
            child: const Text('Delete', style: TextStyle(color: _kRed)),
          ),
        ],
      ),
    );
  }

  // New helper dialogs for variant management
  void _showEditVariantDialog(String productId, Map<String, dynamic> variant, StateSetter setD) {
    final skuC = TextEditingController(text: variant['sku']);
    final variantNameC = TextEditingController(text: variant['variantName']);
    final priceC = TextEditingController(text: variant['price']?.toString());
    final sizeC = TextEditingController(text: variant['size']);
    final colorC = TextEditingController(text: variant['color']);
    final stockC = TextEditingController(text: variant['stock']?.toString());
    final List<String> imageUrls = List<String>.from(variant['images'] ?? []);

    showDialog(
      context: context,
      builder: (ctx) => _NirvistaDialog(
        title: 'Edit Variant',
        onConfirm: () {
          Navigator.pop(ctx);
          _updateVariant(productId, variant['id'], {
            'sku': skuC.text.trim(),
            'variantName': variantNameC.text.trim(),
            'price': double.tryParse(priceC.text.trim()) ?? 0,
            'size': sizeC.text.trim(),
            'color': colorC.text.trim(),
            'stock': int.tryParse(stockC.text.trim()) ?? 0,
            'images': imageUrls,
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dInput(skuC, 'SKU', Icons.qr_code_2),
            _dInput(variantNameC, 'Variant Name', Icons.label_outline),
            _dInput(priceC, 'Price (₹)', Icons.currency_rupee, numeric: true),
            _dInput(sizeC, 'Size', Icons.straighten),
            _dInput(colorC, 'Color', Icons.color_lens),
            _dInput(stockC, 'Stock', Icons.inventory_outlined, numeric: true),
            _sectionLabel('Images'),
            _ImagePickerAdder(
              pickedFiles: [], // Assume no new picks for simplicity; extend if needed
              imageUrls: imageUrls,
              onChanged: () => setD(() {}),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteVariantDialog(String productId, String variantId, StateSetter setD) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Variant'),
        content: const Text('Permanently delete this variant?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteVariant(productId, variantId);
            },
            child: const Text('Delete', style: TextStyle(color: _kRed)),
          ),
        ],
      ),
    );
  }

  void _showAdjustInventoryDialog(dynamic item) {
    final deltaC  = TextEditingController();
    final reasonC = TextEditingController();
    final sku     = item['sku']?.toString() ?? '';
    showDialog(
      context: context,
      builder: (ctx) => _NirvistaDialog(
        title: 'Adjust Inventory',
        onConfirm: () {
          Navigator.pop(ctx);
          _adjustInventory(sku, {
            'delta': int.tryParse(deltaC.text.trim()) ?? 0,
            'reason': reasonC.text.trim(),
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: _kTealLight,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.qr_code_2, color: _kTeal, size: 18),
                const SizedBox(width: 8),
                Text('SKU: $sku',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: _kTealDark)),
              ]),
            ),
            const SizedBox(height: 12),
            _dInput(deltaC,  'Delta (+/−)', Icons.add_circle_outline, numeric: true),
            _dInput(reasonC, 'Reason',      Icons.edit_note),
          ],
        ),
      ),
    );
  }

  void _showFulfillmentDialog(dynamic order) {
    String status   = 'PACKED';
    final trackingC = TextEditingController();
    final orderId   = order['id']?.toString() ?? '';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => _NirvistaDialog(
          title: 'Update Fulfillment',
          onConfirm: () {
            Navigator.pop(ctx);
            _updateFulfillment(
                orderId, {'status': status, 'trackingId': trackingC.text.trim()});
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: status,
                decoration: _dDeco(
                    'Fulfillment Status', Icons.local_shipping_outlined),
                items: ['PACKED', 'SHIPPED', 'DELIVERED', 'CANCELLED']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setD(() => status = v ?? 'PACKED'),
              ),
              const SizedBox(height: 12),
              _dInput(trackingC, 'Tracking ID (optional)', Icons.pin_drop_outlined),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetailDialog(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          width: 500,
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogHeader('Order Detail', ctx),
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: order.entries
                      .map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 130,
                                  child: Text(e.key,
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ),
                                Expanded(
                                  child: Text(e.value?.toString() ?? '—',
                                      style: const TextStyle(fontSize: 13)),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showFulfillmentDialog(order);
                    },
                    child: const Text('Update Fulfillment',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user      = _loginController.currentUser.value;
    final isCompact = MediaQuery.of(context).size.width < 860;
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
              title: Text(_sectionTitles[_selectedSection],
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              actions: [
                IconButton(
                  onPressed: _isBusy ? null : _loadInitial,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                )
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
              color: Colors.black12,
              child:
                  const Center(child: CircularProgressIndicator(color: _kTeal)),
            ),
        ],
      ),
    );
  }

  // ── Side Panel ────────────────────────────────────────────────────────────
  Widget _buildSidePanel(dynamic user, bool isCompact) {
    return Container(
      decoration: const BoxDecoration(color: _kSidebar),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: _kTeal,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.storefront_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('VendorHub',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 0.3)),
                  Text(user?.displayName ?? 'Vendor',
                      style: const TextStyle(
                          color: _kSidebarText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ]),
              ]),
            ),
            Container(height: 1, color: Colors.white.withOpacity(0.08)),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('MAIN MENU',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2)),
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
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: active ? _kSidebarActive : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: active
                            ? Border.all(
                                color: _kTeal.withOpacity(0.6), width: 1)
                            : null,
                      ),
                      child: Row(children: [
                        Icon(_sectionIcons[i],
                            size: 18,
                            color: active ? Colors.white : _kSidebarText),
                        const SizedBox(width: 12),
                        Text(_sectionTitles[i],
                            style: TextStyle(
                              color: active ? Colors.white : _kSidebarText,
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 14,
                            )),
                        if (active) ...[
                          const Spacer(),
                          Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                  color: _kTeal, shape: BoxShape.circle)),
                        ],
                      ]),
                    ),
                  );
                },
              ),
            ),
            Container(height: 1, color: Colors.white.withOpacity(0.08)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: _kTeal, borderRadius: BorderRadius.circular(10)),
                  child: Center(
                    child: Text(
                      (user?.displayName ?? 'V').substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.displayName ?? 'Vendor',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                            overflow: TextOverflow.ellipsis),
                        const Text('Active session',
                            style: TextStyle(
                                color: _kSidebarText, fontSize: 11)),
                      ]),
                ),
                IconButton(
                  onPressed: _isBusy ? null : _loadInitial,
                  icon:
                      const Icon(Icons.refresh, color: _kSidebarText, size: 18),
                  tooltip: 'Refresh all',
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  PAGES
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildDashboardTab() {
    final user = _loginController.currentUser.value;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Welcome back, ${user?.displayName ?? 'Vendor'}',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A2B26))),
              const SizedBox(height: 4),
              Text(
                  'Manage catalog, inventory, orders and fulfillment in one place.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ]),
          ),
          _TealButton(
              label: 'Refresh',
              icon: Icons.sync_rounded,
              onPressed: _isBusy ? null : _loadInitial),
        ]),
        const SizedBox(height: 24),
        LayoutBuilder(builder: (ctx, c) {
          return GridView.count(
            crossAxisCount: c.maxWidth < 500 ? 2 : 4,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.3,
            children: [
              _DashStatCard(
                  label: 'Products',
                  value: '${_products.length}',
                  icon: Icons.inventory_2_rounded,
                  color: _kTeal),
              _DashStatCard(
                  label: 'SKUs',
                  value: '${_inventory.length}',
                  icon: Icons.warehouse_rounded,
                  color: _kTealMid),
              _DashStatCard(
                  label: 'Orders',
                  value: '${_orders.length}',
                  icon: Icons.receipt_long_rounded,
                  color: _kTealDark),
              _DashStatCard(
                  label: 'Top Products',
                  value: '${_topProducts.length}',
                  icon: Icons.leaderboard_rounded,
                  color: _kTealDeep),
            ],
          );
        }),
        const SizedBox(height: 24),
        const Text('Quick Actions',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF1A2B26))),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: [
          _QuickActionChip(
              icon: Icons.add_box_outlined,
              label: 'Add Product',
              onTap: () {
                setState(() => _selectedSection = 1);
                Future.delayed(
                    const Duration(milliseconds: 100), _showAddProductDialog);
              }),
          _QuickActionChip(
              icon: Icons.inventory_outlined,
              label: 'Adjust Stock',
              onTap: () => setState(() => _selectedSection = 2)),
          _QuickActionChip(
              icon: Icons.local_shipping_outlined,
              label: 'Update Orders',
              onTap: () => setState(() => _selectedSection = 3)),
          _QuickActionChip(
              icon: Icons.insights_outlined,
              label: 'View Analytics',
              onTap: () => setState(() => _selectedSection = 4)),
        ]),
        const SizedBox(height: 24),
        if (_orders.isNotEmpty) ...[
          const Text('Recent Orders',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF1A2B26))),
          const SizedBox(height: 12),
          ..._orders.take(3).map((o) => _OrderRowCard(
                order: o,
                onFulfillment: () => _showFulfillmentDialog(o),
                onViewDetail: () =>
                    _fetchOrderById(o['id']?.toString() ?? ''),
              )),
        ],
      ]),
    );
  }

  // ── Products Tab ──────────────────────────────────────────────────────────
  // Search bar now has two behaviours:
  //   • Typing  → calls ProductApiService.searchProducts (GET /api/products/search)
  //   • Cleared → calls ProductApiService.getAllProducts (GET /api/products)
  // Filter pills operate locally on the already-fetched list.
  Widget _buildProductsTab() {
    final filtered      = _filteredProducts;
    final activeCount   = _products.where((p) => p['listingStatus'] == 'ACTIVE').length;
    final draftCount    = _products.where((p) => p['listingStatus'] == 'DRAFT').length;
    final inactiveCount = _products.where((p) => p['listingStatus'] == 'INACTIVE').length;

    return Column(children: [
      // ── Header ─────────────────────────────────────────────────────────
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Products',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A2B26))),
              Text('${_products.length} products total',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ])),
            // Sync = GET /api/products (full refresh)
            _OutlineBtn(
                label: 'Sync',
                icon: Icons.sync,
                onPressed: () => _fetchProducts(loader: true)),
            const SizedBox(width: 10),
            // Add Product = POST /api/vendor/products
            _TealButton(
                label: '+ Add Product', onPressed: _showAddProductDialog),
          ]),
          const SizedBox(height: 12),
          // ── Search bar — API-driven ────────────────────────────────────
          TextField(
            controller: _productSearchC,
            onSubmitted: _searchProducts, // hits /api/products/search on submit
            decoration: InputDecoration(
              hintText: 'Search by name or SKU…',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: _kTeal, size: 20),
              suffixIcon: _productSearchC.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: _kTeal),
                      // Clearing re-fetches the full catalogue
                      onPressed: () {
                        _productSearchC.clear();
                        _fetchProducts(loader: true);
                      },
                    )
                  : IconButton(
                      icon:
                          const Icon(Icons.search, size: 18, color: _kTeal),
                      tooltip: 'Search',
                      onPressed: () =>
                          _searchProducts(_productSearchC.text),
                    ),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _kTeal, width: 1.5)),
              filled: true,
              fillColor: _kBg,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          // ── Filter pills (local, on fetched list) ─────────────────────
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
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _productFilterStatus = entry.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: _productFilterStatus == entry.key
                            ? _kTeal
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${entry.key} (${entry.value})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _productFilterStatus == entry.key
                              ? Colors.white
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ]),
      ),
      // ── Product List ────────────────────────────────────────────────────
      Expanded(
        child: filtered.isEmpty
            ? _emptyState(
                _productSearchC.text.isNotEmpty
                    ? Icons.search_off
                    : Icons.inventory_2_outlined,
                _productSearchC.text.isNotEmpty
                    ? 'No products match your search'
                    : 'No products yet',
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final p = filtered[i] as Map<String, dynamic>? ?? {};
                  return _ProductCard(
                    product: p,
                    // Variants / images
                    onVariants: () => _showVariantsDialog(p),
                    // Delete → DELETE /api/vendor/products/:id
                    onDelete: () => _showDeleteProductDialog(p),
                  );
                },
              ),
      ),
    ]);
  }

  Widget _buildInventoryTab() {
    return Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Row(children: [
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Inventory',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A2B26))),
            Text('${_inventory.length} SKUs tracked',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ])),
          _OutlineBtn(
              label: 'Sync',
              icon: Icons.sync,
              onPressed: () => _fetchInventory(loader: true)),
        ]),
      ),
      Expanded(
        child: _inventory.isEmpty
            ? _emptyState(Icons.warehouse_outlined, 'No inventory data')
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _inventory.length,
                itemBuilder: (ctx, i) {
                  final item = _inventory[i] as Map<String, dynamic>? ?? {};
                  return _InventoryCard(
                      item: item,
                      onAdjust: () => _showAdjustInventoryDialog(item));
                },
              ),
      ),
    ]);
  }

  Widget _buildOrdersTab() {
    return Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Row(children: [
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Orders',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A2B26))),
            Text('${_orders.length} orders total',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ])),
          _OutlineBtn(
              label: 'Sync',
              icon: Icons.sync,
              onPressed: () => _fetchOrders(loader: true)),
        ]),
      ),
      Expanded(
        child: _orders.isEmpty
            ? _emptyState(Icons.receipt_long_outlined, 'No orders yet')
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _orders.length,
                itemBuilder: (ctx, i) {
                  final order = _orders[i] as Map<String, dynamic>? ?? {};
                  return _OrderRowCard(
                    order: order,
                    onFulfillment: () => _showFulfillmentDialog(order),
                    onViewDetail: () =>
                        _fetchOrderById(order['id']?.toString() ?? ''),
                  );
                },
              ),
      ),
    ]);
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
              child: Text('Analytics',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A2B26)))),
          _OutlineBtn(
              label: 'Refresh',
              icon: Icons.sync,
              onPressed: () => _fetchAnalytics(loader: true)),
        ]),
        const SizedBox(height: 16),
        _AnalyticsSection(title: 'Sales',       data: _salesAnalytics),
        const SizedBox(height: 14),
        _AnalyticsSection(title: 'Performance', data: _performanceAnalytics),
        if (_topProducts.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text('Top Products',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          ..._topProducts.map((p) => _TopProductTile(product: p)),
        ],
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _emptyState(IconData icon, String label) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 52, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        ]),
      );

  Widget _dialogHeader(String title, BuildContext ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
        decoration: const BoxDecoration(
          color: _kTeal,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Row(children: [
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15))),
          IconButton(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close, color: Colors.white),
              visualDensity: VisualDensity.compact),
        ]),
      );

  Widget _dInput(
    TextEditingController c,
    String label,
    IconData icon, {
    bool numeric = false,
    int maxLines = 1,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          maxLines: maxLines,
          keyboardType: numeric ? TextInputType.number : TextInputType.text,
          decoration: _dDeco(label, icon),
        ),
      );

  InputDecoration _dDeco(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: _kTeal),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kTeal, width: 1.8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        labelStyle: const TextStyle(fontSize: 13),
      );

  Widget _sectionLabel(String text, {bool margin = true}) => Padding(
        padding: EdgeInsets.only(bottom: 8, top: margin ? 4 : 0),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: _kTealDark)),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  IMAGE PICKER ADDER
// ─────────────────────────────────────────────────────────────────────────────
class _ImagePickerAdder extends StatefulWidget {
  const _ImagePickerAdder({
    required this.pickedFiles,
    required this.imageUrls,
    required this.onChanged,
  });
  final List<XFile> pickedFiles;
  final List<String> imageUrls;
  final VoidCallback onChanged;

  @override
  State<_ImagePickerAdder> createState() => _ImagePickerAdderState();
}

class _ImagePickerAdderState extends State<_ImagePickerAdder> {
  final _picker = ImagePicker();
  final _urlC = TextEditingController();
  bool _picking = false;

  @override
  void dispose() {
    _urlC.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 85);
      if (picked.isNotEmpty) {
        for (final xf in picked) {
          widget.pickedFiles.add(xf);
          widget.imageUrls.add(xf.path);
        }
        widget.onChanged();
        setState(() {});
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _addImageUrl() {
    final url = _urlC.text.trim();
    if (url.isEmpty) return;
    widget.imageUrls.add(url);
    _urlC.clear();
    widget.onChanged();
    setState(() {});
  }

  void _remove(int index) {
    final removedUrl = widget.imageUrls.removeAt(index);
    widget.pickedFiles.removeWhere((xf) => xf.path == removedUrl);
    widget.onChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kTealLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _kTeal.withOpacity(0.5),
              width: 1.4,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _urlC,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 12),
                        hintText: 'Add image URL',
                        hintStyle: TextStyle(color: _kTeal.withOpacity(0.7)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _kTeal.withOpacity(0.4)),
                        ),
                        suffixIcon: IconButton(
                          onPressed: _addImageUrl,
                          icon: const Icon(Icons.link),
                          color: _kTeal,
                        ),
                      ),
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addImageUrl(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _picking ? null : _pickImages,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _picking ? _kTeal.withOpacity(0.2) : _kTeal,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _picking ? Icons.hourglass_top_rounded : Icons.add,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Tap plus to add from device, or paste an image URL and press the link icon.',
                style: TextStyle(color: _kTeal.withOpacity(0.8), fontSize: 11),
              ),
            ],
          ),
        ),
        if (widget.imageUrls.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: widget.imageUrls.asMap().entries.map((entry) {
              final index = entry.key;
              final url = entry.value;
              final isNetwork = url.startsWith('http://') || url.startsWith('https://');
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 86,
                      height: 86,
                      color: _kTealLight,
                      child: isNetwork
                          ? Image.network(url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: _kTeal))
                          : Image.file(File(url),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: _kTeal)),
                    ),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: GestureDetector(
                      onTap: () => _remove(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: _kRed,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.imageUrls.length} image(s) added',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kTealDark),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  VARIANT FORM CARD
// ─────────────────────────────────────────────────────────────────────────────
class _VariantFormCard extends StatefulWidget {
  const _VariantFormCard(
      {required this.index,
      required this.data,
      required this.onRemove,
      required this.onChanged});
  final int index;
  final Map<String, dynamic> data;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  State<_VariantFormCard> createState() => _VariantFormCardState();
}

class _VariantFormCardState extends State<_VariantFormCard> {
  late final TextEditingController _skuC;
  late final TextEditingController _stockC;
  late final TextEditingController _priceC;
  late final TextEditingController _colorC;
  late final TextEditingController _sizeC;

  final List<XFile> _pickedFiles = [];
  final List<String> _imageUrls  = [];

  @override
  void initState() {
    super.initState();
    _skuC   = TextEditingController(text: widget.data['sku']?.toString() ?? '');
    _stockC = TextEditingController(text: widget.data['stock']?.toString() ?? '');
    _priceC = TextEditingController(text: widget.data['price']?.toString() ?? '');
    _colorC = TextEditingController(
        text: (widget.data['attributes'] as Map?)?['color']?.toString() ?? '');
    _sizeC  = TextEditingController(
        text: (widget.data['attributes'] as Map?)?['size']?.toString() ?? '');
    if (widget.data['imageUrls'] is List) {
      _imageUrls
          .addAll((widget.data['imageUrls'] as List).map((e) => e.toString()));
    }
    for (final c in [_skuC, _stockC, _priceC, _colorC, _sizeC]) {
      c.addListener(_sync);
    }
  }

  void _sync() {
    widget.data['sku']        = _skuC.text.trim();
    widget.data['stock']      = int.tryParse(_stockC.text.trim()) ?? 0;
    widget.data['price']      = double.tryParse(_priceC.text.trim()) ?? 0;
    widget.data['attributes'] = {
      'color': _colorC.text.trim(),
      'size': _sizeC.text.trim()
    };
    widget.data['imageUrls']  = List<String>.from(_imageUrls);
    widget.onChanged();
  }

  @override
  void dispose() {
    for (final c in [_skuC, _stockC, _priceC, _colorC, _sizeC]) c.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 16, color: _kTeal),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _kTeal, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        labelStyle: const TextStyle(fontSize: 12),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: _kTealLight, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF0FDFB),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
                color: _kTealLight,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(10))),
            child: Row(children: [
              const Icon(Icons.layers_rounded, size: 15, color: _kTeal),
              const SizedBox(width: 6),
              Text('Variant ${widget.index + 1}',
                  style: const TextStyle(
                      color: _kTealDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              const Spacer(),
              GestureDetector(
                onTap: widget.onRemove,
                child: const Icon(Icons.remove_circle_outline,
                    size: 18, color: _kRed),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TextField(
                            controller: _skuC,
                            decoration: _dec('SKU *', Icons.qr_code_2)))),
                const SizedBox(width: 10),
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TextField(
                            controller: _priceC,
                            keyboardType: TextInputType.number,
                            decoration:
                                _dec('Price (₹)', Icons.currency_rupee)))),
                const SizedBox(width: 10),
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TextField(
                            controller: _stockC,
                            keyboardType: TextInputType.number,
                            decoration: _dec(
                                'Stock', Icons.inventory_outlined)))),
              ]),
              Row(children: [
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TextField(
                            controller: _colorC,
                            decoration:
                                _dec('Color', Icons.palette_outlined)))),
                const SizedBox(width: 10),
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TextField(
                            controller: _sizeC,
                            decoration: _dec(
                                'Size', Icons.straighten_outlined)))),
              ]),
              Text('Variant Images',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[700])),
              const SizedBox(height: 6),
              _ImagePickerAdder(
                pickedFiles: _pickedFiles,
                imageUrls: _imageUrls,
                onChanged: _sync,
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PRODUCT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onVariants,
    required this.onDelete,
  });
  final Map<String, dynamic> product;
  final VoidCallback onVariants;
  final VoidCallback onDelete;

  Color _statusColor(String? s) {
    switch (s) {
      case 'ACTIVE':   return _kGreen;
      case 'DRAFT':    return Colors.orange;
      case 'INACTIVE': return _kRed;
      default:         return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final variants = product['variants'] as List? ?? [];
    final firstVariant = variants.isNotEmpty ? variants.first as Map<String, dynamic> : null;
    final images = <String>[];
    if (product['imageUrls'] is List) {
      images.addAll((product['imageUrls'] as List).map((e) => e.toString()));
    }
    if (images.isEmpty && firstVariant != null && firstVariant['images'] is List) {
      images.addAll((firstVariant['images'] as List).map((e) => e.toString()));
    }
    final status = product['listingStatus']?.toString();
    final sku = firstVariant?['sku'] ?? firstVariant?['variantName'] ?? '—';
    final stock = firstVariant?['stock'] ?? 0;
    final price = firstVariant?['price'] ?? product['basePrice'] ?? product['price'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: images.isNotEmpty
                  ? Image.network(images.first,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product['title']?.toString() ?? product['name']?.toString() ?? 'Unnamed',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF1A2B26))),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.qr_code_2, size: 13, color: _kTeal),
                      const SizedBox(width: 4),
                      Text(sku.toString(),
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(width: 12),
                      const Icon(Icons.inventory_outlined,
                          size: 13, color: _kTeal),
                      const SizedBox(width: 4),
                      Text('$stock units',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 12)),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.currency_rupee,
                          size: 13, color: _kTeal),
                      Text(price.toString(),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: _kTealDark)),
                      const SizedBox(width: 10),
                      if (variants.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: _kTealLight,
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(
                              '${variants.length} variant${variants.length > 1 ? 's' : ''}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: _kTealDark,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ]),
                  ]),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(status).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(status ?? '—',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(status))),
            ),
          ]),
        ),
        Container(
          decoration: BoxDecoration(
            color: _kBg,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(14)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(children: [
            _ActionBtn(
                icon: Icons.layers_outlined,
                label: 'Variants',
                onTap: onVariants),
            const Spacer(),
            _ActionBtn(
                icon: Icons.delete_outline,
                label: 'Delete',
                onTap: onDelete,
                color: _kRed),
          ]),
        ),
      ]),
    );
  }

  Widget _placeholder() => Container(
        width: 56,
        height: 56,
        color: _kTealLight,
        child: const Icon(Icons.image_outlined, color: _kTeal, size: 24),
      );
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
    final stock = item['stock'] ?? item['quantity'] ?? 0;
    final isLow = (stock is num) && stock < 5;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isLow
            ? Border.all(color: _kRed.withOpacity(0.4), width: 1.2)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 1))
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: isLow ? _kRed.withOpacity(0.1) : _kTealLight,
              borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.warehouse_rounded,
              color: isLow ? _kRed : _kTeal, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item['sku']?.toString() ?? '—',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13)),
          if (item['productName'] != null)
            Text(item['productName'].toString(),
                style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$stock units',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isLow ? _kRed : _kTealDark)),
          if (isLow)
            const Text('Low stock',
                style: TextStyle(fontSize: 10, color: _kRed)),
        ]),
        const SizedBox(width: 10),
        _OutlineBtn(
            label: 'Adjust',
            icon: Icons.edit,
            onPressed: onAdjust,
            compact: true),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ORDER ROW CARD
// ─────────────────────────────────────────────────────────────────────────────
class _OrderRowCard extends StatelessWidget {
  const _OrderRowCard(
      {required this.order,
      required this.onFulfillment,
      required this.onViewDetail});
  final Map<String, dynamic> order;
  final VoidCallback onFulfillment;
  final VoidCallback onViewDetail;

  @override
  Widget build(BuildContext context) {
    final statusText = order['fulfillmentStatus']?.toString() ??
        order['status']?.toString() ??
        '—';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 1))
        ],
      ),
      child: Row(children: [
        const Icon(Icons.receipt_long_rounded, color: _kTeal, size: 20),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('#${order['id'] ?? order['orderId'] ?? '—'}',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13)),
          Text(statusText,
              style: const TextStyle(fontSize: 12, color: _kTealDark)),
        ])),
        if (order['total'] != null)
          Text('₹${order['total']}',
              style:
                  const TextStyle(fontWeight: FontWeight.w700, color: _kTeal)),
        const SizedBox(width: 8),
        _OutlineBtn(
            label: 'Detail', onPressed: onViewDetail, compact: true),
        const SizedBox(width: 6),
        _OutlineBtn(
            label: 'Fulfill', onPressed: onFulfillment, compact: true),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ANALYTICS SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _AnalyticsSection extends StatelessWidget {
  const _AnalyticsSection({required this.title, required this.data});
  final String title;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Text('$title — no data yet',
            style: TextStyle(color: Colors.grey[400], fontSize: 13)),
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04), blurRadius: 6)
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Color(0xFF1A2B26))),
        const SizedBox(height: 10),
        Wrap(
            spacing: 12,
            runSpacing: 10,
            children: data.entries
                .map((e) => _StatChip(
                    label: e.key, value: e.value?.toString() ?? '—'))
                .toList()),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: _kTealLight, borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: _kTealDark)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: _kTeal)),
      ]),
    );
  }
}

class _TopProductTile extends StatelessWidget {
  const _TopProductTile({required this.product});
  final dynamic product;

  @override
  Widget build(BuildContext context) {
    final p = product as Map<String, dynamic>? ?? {};
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03), blurRadius: 4)
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
              color: _kTealLight, shape: BoxShape.circle),
          child: const Icon(Icons.star_outline_rounded,
              color: _kTeal, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
            child: Text(p['name']?.toString() ?? 'Product',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13))),
        if (p['revenue'] != null)
          Text('₹${p['revenue']}',
              style: const TextStyle(
                  color: _kTeal,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
      ]),
    );
  }
}

class _VariantTile extends StatelessWidget {
  const _VariantTile({required this.variant, this.onEdit, this.onDelete});
  final dynamic variant;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final v      = variant as Map<String, dynamic>? ?? {};
    final images = v['images'] as List? ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.qr_code_2, size: 16, color: _kTeal),
          const SizedBox(width: 8),
          Expanded(
              child: Text(v['sku']?.toString() ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13))),
          Text('${v['stock'] ?? 0} units',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          if (onEdit != null) IconButton(icon: const Icon(Icons.edit, size: 16), onPressed: onEdit),
          if (onDelete != null) IconButton(icon: const Icon(Icons.delete, size: 16, color: _kRed), onPressed: onDelete),
        ]),
        if ((v['attributes'] as Map?)?.isNotEmpty == true) ...[
          const SizedBox(height: 4),
          Wrap(
              spacing: 6,
              children: (v['attributes'] as Map)
                  .entries
                  .where((e) => e.value?.toString().isNotEmpty == true)
                  .map((e) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: _kTealLight,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text('${e.key}: ${e.value}',
                            style: const TextStyle(
                                fontSize: 11, color: _kTealDark)),
                      ))
                  .toList()),
        ],
        if (images.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
              spacing: 6,
              children: images
                  .take(4)
                  .map((img) => ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(img.toString(),
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                width: 44,
                                height: 44,
                                color: _kTealLight,
                                child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 16,
                                    color: _kTeal))),
                      ))
                  .toList()),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SMALL REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _NirvistaDialog extends StatelessWidget {
  const _NirvistaDialog(
      {required this.title,
      required this.child,
      required this.onConfirm});
  final String title;
  final Widget child;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Container(
        width: 520,
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              decoration: const BoxDecoration(
                color: _kTeal,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(children: [
                Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15))),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                  visualDensity: VisualDensity.compact,
                ),
              ]),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kTeal,
                        side: const BorderSide(color: _kTeal),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      child: const Text('Confirm',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _TealButton extends StatelessWidget {
  const _TealButton(
      {required this.label, this.icon, required this.onPressed});
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _kTeal,
        foregroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: onPressed,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 16),
          const SizedBox(width: 6)
        ],
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13)),
      ]),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn(
      {required this.label,
      this.icon,
      required this.onPressed,
      this.compact = false});
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: _kTeal,
        side: const BorderSide(color: _kTeal),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        visualDensity:
            compact ? VisualDensity.compact : VisualDensity.standard,
        textStyle: TextStyle(
            fontSize: compact ? 12 : 13, fontWeight: FontWeight.w600),
      ),
      child: icon != null
          ? Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 16),
              const SizedBox(width: 6),
              Text(label)
            ])
          : Text(label),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color = _kTeal});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        visualDensity: VisualDensity.compact,
      ),
      icon: Icon(icon, size: 15),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 1))
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: _kTeal),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2B26))),
        ]),
      ),
    );
  }
}

class _DashStatCard extends StatelessWidget {
  const _DashStatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18),
        ),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        Text(label,
            style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}