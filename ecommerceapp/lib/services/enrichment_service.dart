import 'package:pet_shop/app/model/api_models.dart';
import 'package:pet_shop/services/category_api.dart';
import 'package:pet_shop/services/product_api.dart';

class EnrichmentService {
  /// Asynchronously fetches full details for products by "scraping" their 
  /// parent category. This is a workaround for the broken Product Detail/Search APIs.
  static Future<void> enrichProducts(List<ProductModel> products, {Function? onUpdate}) async {
    // 1. Group by categoryId (only those missing variants)
    final Map<String, List<ProductModel>> byCategory = {};
    final List<ProductModel> noCategoryProducts = [];
    
    for (var p in products) {
      if (p.variants.isEmpty) {
        if (p.categoryId.isNotEmpty) {
          byCategory.putIfAbsent(p.categoryId, () => []).add(p);
        } else {
          noCategoryProducts.add(p);
        }
      }
    }

    if (byCategory.isEmpty && noCategoryProducts.isEmpty) {
      print('[EnrichmentService] No enrichment needed (all items have data)');
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
              print('[EnrichmentService] WARNING: No detailed match found in category for ${p.title} (${p.id}). Fetching individually...');
              try {
                final variantsRes = await ProductApiService.getProductVariants(p.id);
                if (variantsRes['success'] && variantsRes['data'] != null) {
                  final variantsList = variantsRes['data'] as List;
                  if (variantsList.isNotEmpty) {
                    p.variants = variantsList.map((e) => VariantModel.fromJson(e)).toList();
                    print('[EnrichmentService] SUCCESS (Individual Variants): Enriched ${p.title}');
                    anyUpdated = true;
                  }
                }
              } catch (e) {
                print('[EnrichmentService] ERROR fetching individually ${p.title}: $e');
              }
            }
          }

          if (anyUpdated && onUpdate != null) {
            onUpdate();
          }
        } else {
          print('[EnrichmentService] ERROR: Category fetch failed for $catId: ${res['message']}');
          bool anyUpdated = false;
          for (var p in productsToEnrich) {
            try {
              final variantsRes = await ProductApiService.getProductVariants(p.id);
              if (variantsRes['success'] && variantsRes['data'] != null) {
                final variantsList = variantsRes['data'] as List;
                if (variantsList.isNotEmpty) {
                  p.variants = variantsList.map((e) => VariantModel.fromJson(e)).toList();
                  print('[EnrichmentService] SUCCESS (Individual Fallback): Enriched ${p.title}');
                  anyUpdated = true;
                }
              }
            } catch (e) {
              print('[EnrichmentService] ERROR fetching individually ${p.title}: $e');
            }
          }
          if (anyUpdated && onUpdate != null) {
            onUpdate();
          }
        }
      } catch (e) {
        print('[EnrichmentService] CRITICAL Error scraping category $catId: $e');
      }
    }
    
    // 3. Process products without category ID
    bool anyNoCatUpdated = false;
    for (var p in noCategoryProducts) {
      print('[EnrichmentService] Fetching category-less product individually: ${p.title} (${p.id})');
      try {
        final variantsRes = await ProductApiService.getProductVariants(p.id);
        if (variantsRes['success'] && variantsRes['data'] != null) {
          final variantsList = variantsRes['data'] as List;
          if (variantsList.isNotEmpty) {
            p.variants = variantsList.map((e) => VariantModel.fromJson(e)).toList();
            print('[EnrichmentService] SUCCESS (Individual no-cat): Enriched ${p.title}');
            anyNoCatUpdated = true;
          }
        }
      } catch (e) {
        print('[EnrichmentService] CRITICAL Error fetching product ${p.id}: $e');
      }
    }
    
    if (anyNoCatUpdated && onUpdate != null) {
      onUpdate();
    }
  }
}
