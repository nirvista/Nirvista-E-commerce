import 'package:pet_shop/app/model/api_models.dart';
import 'package:pet_shop/services/category_api.dart';

class EnrichmentService {
  /// Asynchronously fetches full details for products by "scraping" their 
  /// parent category. This is a workaround for the broken Product Detail/Search APIs.
  static Future<void> enrichProducts(List<ProductModel> products, {Function? onUpdate}) async {
    // 1. Group by categoryId (only those missing variants)
    final Map<String, List<ProductModel>> byCategory = {};
    for (var p in products) {
      if (p.categoryId.isNotEmpty && p.variants.isEmpty) {
        byCategory.putIfAbsent(p.categoryId, () => []).add(p);
      }
    }

    if (byCategory.isEmpty) {
      print('[EnrichmentService] No enrichment needed (all items have data or no categoryId)');
      return;
    }

    // 2. For each unique category, fetch its full product list (which contains variants)
    for (var entry in byCategory.entries) {
      final catId = entry.key;
      final productsToEnrich = entry.value;

      try {
        print('[EnrichmentService] SCRAPING category $catId for full data...');
        final res = await CategoryApiService.getProductsByCategory(catId);
        
        if (res['success'] && res['data'] != null) {
          final List<dynamic> catProductsJson = res['data'];
          
          // Create a lookup map of full product data from the category response
          final Map<String, ProductModel> fullDetailsMap = {};
          for (var json in catProductsJson) {
            if (json['id'] != null) {
              fullDetailsMap[json['id'].toString()] = ProductModel.fromJson(json);
            }
          }

          bool anyUpdated = false;
          for (var p in productsToEnrich) {
            final fullDetail = fullDetailsMap[p.id];
            if (fullDetail != null && fullDetail.variants.isNotEmpty) {
              p.copyFrom(fullDetail);
              print('[EnrichmentService] SUCCESS: Enriched ${p.title} (Price: ${p.currentPrice})');
              anyUpdated = true;
            } else {
              print('[EnrichmentService] WARNING: No detailed match found in category for ${p.title} (${p.id})');
            }
          }

          if (anyUpdated && onUpdate != null) {
            onUpdate();
          }
        } else {
          print('[EnrichmentService] ERROR: Category fetch failed for $catId: ${res['message']}');
        }
      } catch (e) {
        print('[EnrichmentService] CRITICAL Error scraping category $catId: $e');
      }
    }
  }
}
