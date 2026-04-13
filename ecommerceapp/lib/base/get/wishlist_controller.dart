import 'package:get/get.dart';
import 'package:pet_shop/services/wishlist_api.dart';
import 'package:pet_shop/base/color_data.dart';
import 'package:pet_shop/base/get/login_data_controller.dart';
import 'package:pet_shop/woocommerce/model/user.dart';
import 'package:flutter/material.dart';

/// A single source of truth for wishlist state, shared by
/// ProductDetailScreen (heart button) and TabFavourite (list view).
///
/// Register in your AppBinding or main.dart:
///   Get.put(WishlistController(), permanent: true);
class WishlistController extends GetxController {
  final RxList<WishlistItem> items = <WishlistItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;

  /// Set of product IDs currently in the wishlist — used by the heart button.
  final RxSet<String> wishedProductIds = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _setupWishlistListeners();
  }

  void _setupWishlistListeners() {
    // Listen for changes to the current user in the LoginDataController
    final loginController = Get.find<LoginDataController>();
    ever(loginController.currentUser, (User? user) {
      if (user != null && user.id != null && user.id!.isNotEmpty) {
        // User just logged in — fetch their wishlist
        fetchWishlist();
      } else {
        // User logged out — clear wishlist
        items.clear();
        wishedProductIds.clear();
        hasError.value = false;
      }
    });

    // If user is already logged in at startup, fetch immediately
    if (loginController.currentUser.value?.id != null) {
      fetchWishlist();
    }
  }

  String? get currentUserId {
    final loginController = Get.find<LoginDataController>();
    return loginController.currentUser.value?.id;
  }

  bool get hasValidUserId => currentUserId != null && currentUserId!.isNotEmpty;

  // ═══════════════════════════════════════════════════════
  // FETCH
  // ═══════════════════════════════════════════════════════

  Future<void> fetchWishlist() async {
    isLoading.value = true;
    hasError.value = false;
    final userId = currentUserId;
    if (userId == null || userId.isEmpty) {
      print('[WishlistController] fetchWishlist skipped: no userId available');
      // Don't set hasError — just keep empty list while waiting for login
      items.clear();
      wishedProductIds.clear();
      isLoading.value = false;
      return;
    }

    try {
      final response = await WishlistService.getWishlist(userId);
      items.assignAll(response.data.items);
      _rebuildIdSet();
    } catch (e) {
      print('[WishlistController] fetchWishlist error: $e');
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════
  // TOGGLE
  // ═══════════════════════════════════════════════════════

  Future<void> toggleWishlist(String productId, {String? variantId}) async {
    if (wishedProductIds.contains(productId)) {
      await _removeByProductId(productId);
    } else {
      await _addToWishlist(productId, variantId: variantId);
    }
  }

  bool isWishlisted(String productId) => wishedProductIds.contains(productId);

  // ═══════════════════════════════════════════════════════
  // REMOVE
  // ═══════════════════════════════════════════════════════

  Future<bool> removeItem(WishlistItem item, int index) async {
    // FIX: capture the item by id, not index, to survive list shifts
    final itemId = item.id;
    final safeIndex = items.indexWhere((i) => i.id == itemId);
    if (safeIndex == -1) return false;

    // Optimistic removal
    items.removeAt(safeIndex);
    _rebuildIdSet();

    try {
      final success = await WishlistService.removeFromWishlist(itemId);
      if (!success) {
        // Rollback
        items.insert(safeIndex.clamp(0, items.length), item);
        _rebuildIdSet();
        _snack("Failed to remove item", isError: true);
        return false;
      }
      _snack("Removed from wishlist");
      return true;
    } catch (e) {
      print('[WishlistController] removeItem error: $e');
      items.insert(safeIndex.clamp(0, items.length), item);
      _rebuildIdSet();
      _snack("Failed to remove item", isError: true);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════
  // MOVE TO CART
  // ═══════════════════════════════════════════════════════

  Future<bool> moveToCart(WishlistItem item, int index) async {
    // Validate user is logged in
    final currentUserId = this.currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) {
      _snack('Please log in to move items to cart', isError: true);
      return false;
    }

    // FIX: find by id to handle any list shifts
    final safeIndex = items.indexWhere((i) => i.id == item.id);
    if (safeIndex == -1) return false;

    // Optimistic removal
    items.removeAt(safeIndex);
    _rebuildIdSet();

    try {
      final success = await WishlistService.moveToCart(
        itemId: item.id,
        userId: currentUserId,
      );
      if (success) {
        _snack("Moved to cart successfully");
        return true;
      } else {
        // Rollback
        items.insert(safeIndex.clamp(0, items.length), item);
        _rebuildIdSet();
        _snack("Failed to move to cart", isError: true);
        return false;
      }
    } catch (e) {
      print('[WishlistController] moveToCart error: $e');
      items.insert(safeIndex.clamp(0, items.length), item);
      _rebuildIdSet();
      _snack("Failed to move to cart", isError: true);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════
  // CLEAR ALL
  // ═══════════════════════════════════════════════════════

  Future<bool> clearWishlist() async {
    // Validate user is logged in
    final currentUserId = this.currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) {
      _snack('Please log in to clear your wishlist', isError: true);
      return false;
    }

    final previous = List<WishlistItem>.from(items);
    items.clear();
    wishedProductIds.clear();
    try {
      final success = await WishlistService.clearWishlist(currentUserId);
      if (!success) {
        items.assignAll(previous);
        _rebuildIdSet();
        _snack("Failed to clear wishlist", isError: true);
        return false;
      }
      _snack("Wishlist cleared");
      return true;
    } catch (e) {
      print('[WishlistController] clearWishlist error: $e');
      items.assignAll(previous);
      _rebuildIdSet();
      _snack("Failed to clear wishlist", isError: true);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════

  void _rebuildIdSet() {
    wishedProductIds.assignAll(
      items.map((i) => i.product.id).toSet(),
    );
  }

  Future<void> _removeByProductId(String productId) async {
    final index = items.indexWhere((i) => i.product.id == productId);
    if (index == -1) return;
    final item = items[index];
    await removeItem(item, index);
  }

  Future<void> _addToWishlist(String productId, {String? variantId}) async {
    // Validate user is logged in
    final currentUserId = this.currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) {
      _snack('Please log in to add items to your wishlist', isError: true);
      return;
    }

    // Validate variant was selected
    if (variantId == null || variantId.isEmpty) {
      _snack('Please select a product variant before adding to wishlist', isError: true);
      return;
    }

    // Optimistic: mark as wished immediately so UI snaps to filled heart
    wishedProductIds.add(productId);
    try {
      final success = await WishlistService.addToWishlist(
        userId: currentUserId,
        productId: productId,
        variantId: variantId,
      );
      if (success) {
        _snack("Added to wishlist");
        // Refresh to get the full WishlistItem object (with id, variant, etc.)
        await fetchWishlist();
      } else {
        wishedProductIds.remove(productId);
        _snack("Failed to add to wishlist", isError: true);
      }
    } catch (e) {
      print('[WishlistController] _addToWishlist error: $e');
      wishedProductIds.remove(productId);
      _snack("Failed to add to wishlist", isError: true);
    }
  }

  // FIX: Use Get.snackbar instead of ScaffoldMessenger to avoid
  //      null context crashes when called outside a visible scaffold.
  void _snack(String message, {bool isError = false}) {
    Get.snackbar(
      isError ? "Error" : "Success",
      message,
      backgroundColor: isError ? Colors.redAccent : accentColor,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 10,
      duration: const Duration(seconds: 2),
      isDismissible: true,
    );
  }
}