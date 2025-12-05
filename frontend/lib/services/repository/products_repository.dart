import '../../models/product.dart';
import '../api/products_api.dart';
import '../local/products_cache_service.dart';

/// مستودع المنتجات - يدمج بين API والكاش
/// يطبق استراتيجية Cache-First
/// 🎯 الترتيب يأتي من السيرفر حسب display_order - لا نرتب يدوياً!
class ProductsRepository {
  final ProductsApi _api;

  ProductsRepository({ProductsApi? api}) : _api = api ?? ProductsApi();

  /// جلب المنتجات مع استراتيجية Cache-First
  /// للصفحة الأولى: يحاول الكاش أولاً، ثم يحدث من السيرفر في الخلفية
  /// للصفحات التالية: يجلب مباشرة من السيرفر (مرتبة من السيرفر)
  Future<ProductsResult> getProducts({int page = 1, int limit = 10, bool forceRefresh = false}) async {
    // الصفحة الأولى: جرب الكاش أولاً
    if (page == 1 && !forceRefresh) {
      final cached = await ProductsCacheService.getCachedProducts();
      if (cached != null && cached.isNotEmpty) {
        // إرجاع الكاش فوراً (الكاش محفوظ بالترتيب الصحيح)
        final available = cached.where((p) => p.availableQuantity > 0).toList();
        return ProductsResult(
          products: available,
          hasMore: true, // نفترض وجود المزيد
          fromCache: true,
        );
      }
    }

    // جلب من السيرفر (المنتجات تأتي مرتبة حسب display_order)
    final products = await _api.fetchProducts(page: page, limit: limit);
    final available = products.where((p) => p.availableQuantity > 0).toList();

    // حفظ في الكاش (للصفحة الأولى فقط)
    if (page == 1) {
      await ProductsCacheService.cacheProducts(products);
    }

    return ProductsResult(products: available, hasMore: products.length >= limit, fromCache: false);
  }

  /// تحديث المنتجات في الخلفية (للتحديث الصامت)
  Future<ProductsResult?> refreshInBackground({int limit = 10}) async {
    try {
      final products = await _api.fetchProducts(page: 1, limit: limit);
      final available = products.where((p) => p.availableQuantity > 0).toList();

      await ProductsCacheService.cacheProducts(products);

      return ProductsResult(products: available, hasMore: products.length >= limit, fromCache: false);
    } catch (_) {
      return null; // فشل التحديث الصامت، لا مشكلة
    }
  }

  /// جلب منتج واحد بالـ ID
  Future<Product> getProductById(String productId) async {
    return await _api.fetchProductById(productId);
  }

  /// البحث في المنتجات (محلياً من الكاش)
  Future<List<Product>> searchProducts(String query) async {
    if (query.trim().isEmpty) {
      final cached = await ProductsCacheService.getCachedProducts();
      return cached?.where((p) => p.availableQuantity > 0).toList() ?? [];
    }

    final cached = await ProductsCacheService.getCachedProducts();
    if (cached == null) return [];

    final lowerQuery = query.toLowerCase().trim();
    return cached.where((p) => p.availableQuantity > 0 && p.name.toLowerCase().contains(lowerQuery)).toList();
  }

  /// مسح الكاش
  Future<void> clearCache() async {
    await ProductsCacheService.clearCache();
  }

  /// هل يوجد كاش؟
  Future<bool> hasCachedData() async {
    return await ProductsCacheService.hasCachedProducts();
  }
}

/// نتيجة جلب المنتجات
class ProductsResult {
  final List<Product> products;
  final bool hasMore;
  final bool fromCache;

  ProductsResult({required this.products, required this.hasMore, required this.fromCache});
}
