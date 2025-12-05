import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/api/products_api.dart';
import '../services/local/products_cache_service.dart';

/// مزود المنتجات - مطابق 100% لمنطق الصفحة القديمة
/// 🎯 الترتيب يأتي من السيرفر حسب display_order (1 = أول منتج، 2 = ثاني، ...)
/// 🎯 لا نرتب يدوياً أبداً - فقط addAll() للمنتجات الجديدة
class ProductsProvider extends ChangeNotifier {
  final ProductsApi _api;

  // الحالة - مطابقة تماماً للملف القديم
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentPage = 1;
  bool _hasMore = true;
  String _searchQuery = '';

  static const int _itemsPerPage = 10;

  ProductsProvider({ProductsApi? api}) : _api = api ?? ProductsApi();

  // Getters
  List<Product> get products => _filteredProducts;
  List<Product> get allProducts => _products;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  bool get isEmpty => _products.isEmpty && !_isLoading;
  String get searchQuery => _searchQuery;

  /// تحميل المنتجات (الصفحة الأولى) - مطابق لـ _loadProducts() في الملف القديم
  Future<void> loadProducts({bool forceRefresh = false}) async {
    if (_isLoading) return;

    // إعادة تعيين حالة الخطأ
    _hasError = false;
    _errorMessage = '';

    // إذا طلب التحديث الإجباري، امسح الكاش أولاً
    if (forceRefresh) {
      await ProductsCacheService.clearCache();
    }

    // محاولة تحميل من الكاش فوراً (Cache-First Strategy)
    final cachedProducts = await ProductsCacheService.getCachedProducts();
    if (cachedProducts != null && cachedProducts.isNotEmpty && !forceRefresh) {
      final availableProducts = cachedProducts.where((p) => p.availableQuantity > 0).toList();
      _products = availableProducts;
      _filteredProducts = List.from(availableProducts);
      _isLoading = false;
      _hasMore = true;
      _currentPage = 1;
      notifyListeners();

      // تحديث في الخلفية
      _refreshInBackground();
      return;
    }

    // إذا لا يوجد كاش، تحميل من السيرفر مع loading
    _isLoading = true;
    _currentPage = 1;
    _products = [];
    _filteredProducts = [];
    _hasMore = true;
    notifyListeners();

    await _fetchFromServer();
  }

  /// تحميل من السيرفر - مطابق لـ _fetchProductsFromServer() في الملف القديم
  Future<void> _fetchFromServer() async {
    try {
      debugPrint('📦 جلب المنتجات من السيرفر - صفحة $_currentPage');
      final products = await _api.fetchProducts(page: _currentPage, limit: _itemsPerPage);

      // طباعة ترتيب المنتجات للتأكد
      debugPrint('📋 ترتيب المنتجات من السيرفر:');
      for (int i = 0; i < products.length && i < 5; i++) {
        debugPrint('  ${i + 1}. ${products[i].name} - displayOrder: ${products[i].displayOrder}');
      }

      final availableProducts = products.where((p) => p.availableQuantity > 0).toList();

      // حفظ في الكاش
      await ProductsCacheService.cacheProducts(products);

      _products = availableProducts;
      _filteredProducts = List.from(availableProducts);
      _isLoading = false;
      _hasMore = products.length >= _itemsPerPage;
      _applySearch();

      debugPrint('✅ تم تحميل ${availableProducts.length} منتج متاح');
    } catch (e) {
      _isLoading = false;
      _hasMore = false;
      _hasError = true;
      _errorMessage = e.toString();
      debugPrint('❌ خطأ في تحميل المنتجات: $e');
    }

    notifyListeners();
  }

  /// تحميل المزيد من المنتجات - مطابق لـ _loadMoreProducts() في الملف القديم
  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      debugPrint('📦 تحميل المزيد - صفحة $_currentPage');
      final products = await _api.fetchProducts(page: _currentPage, limit: _itemsPerPage);

      // طباعة ترتيب المنتجات الجديدة
      debugPrint('📋 المنتجات الجديدة من صفحة $_currentPage:');
      for (int i = 0; i < products.length && i < 5; i++) {
        debugPrint('  ${i + 1}. ${products[i].name} - displayOrder: ${products[i].displayOrder}');
      }

      final availableProducts = products.where((p) => p.availableQuantity > 0).toList();

      // ✅ إضافة المنتجات الجديدة بالترتيب كما تأتي من السيرفر
      // لا نرتب يدوياً - فقط نضيف للنهاية مثل الملف القديم
      _products.addAll(availableProducts);

      _isLoadingMore = false;
      _hasMore = products.length >= _itemsPerPage;

      // إعادة تطبيق البحث الحالي
      _applySearch();

      // حفظ كل المنتجات في الكاش (مثل الملف القديم سطر 549)
      await ProductsCacheService.cacheProducts(_products);

      debugPrint('✅ تم إضافة ${availableProducts.length} منتج - المجموع: ${_products.length}');
    } catch (e) {
      _currentPage--; // التراجع عن الصفحة
      _isLoadingMore = false;
      _hasMore = false;
      debugPrint('❌ خطأ في تحميل المزيد: $e');
    }

    notifyListeners();
  }

  /// البحث في المنتجات - مطابق لـ _searchProducts() في الملف القديم
  void search(String query) {
    _searchQuery = query;
    _applySearch();
    notifyListeners();
  }

  /// تطبيق البحث على المنتجات (بدون تغيير الترتيب)
  void _applySearch() {
    if (_searchQuery.trim().isEmpty) {
      _filteredProducts = List.from(_products);
    } else {
      final lowerQuery = _searchQuery.toLowerCase().trim();
      _filteredProducts = _products.where((p) => p.name.toLowerCase().contains(lowerQuery)).toList();
    }
    // ✅ لا نرتب - الترتيب يأتي من السيرفر
  }

  /// تحديث في الخلفية - مطابق لـ _refreshProductsInBackground() في الملف القديم
  Future<void> _refreshInBackground() async {
    try {
      final products = await _api.fetchProducts(page: 1, limit: _itemsPerPage);
      final availableProducts = products.where((p) => p.availableQuantity > 0).toList();

      // حفظ في الكاش
      await ProductsCacheService.cacheProducts(products);

      // تحديث فقط إذا تغيرت البيانات
      if (_hasDataChanged(availableProducts)) {
        _products = availableProducts;
        _filteredProducts = List.from(availableProducts);
        _hasMore = products.length >= _itemsPerPage;
        notifyListeners();
      }
    } catch (_) {
      // فشل التحديث الصامت - لا مشكلة
    }
  }

  /// فحص هل تغيرت البيانات - مطابق لـ _hasDataChanged() في الملف القديم
  bool _hasDataChanged(List<Product> newProducts) {
    if (_products.length != newProducts.length) return true;
    for (int i = 0; i < _products.length; i++) {
      final oldP = _products[i];
      final newP = newProducts[i];
      if (oldP.id != newP.id ||
          oldP.availableQuantity != newP.availableQuantity ||
          oldP.wholesalePrice != newP.wholesalePrice ||
          oldP.minPrice != newP.minPrice ||
          oldP.maxPrice != newP.maxPrice ||
          oldP.name != newP.name ||
          oldP.images.length != newP.images.length ||
          (oldP.images.isNotEmpty && newP.images.isNotEmpty && oldP.images.first != newP.images.first)) {
        return true;
      }
    }
    return false;
  }

  /// إعادة المحاولة
  Future<void> retry() async {
    await loadProducts(forceRefresh: true);
  }

  /// مسح البحث
  void clearSearch() {
    _searchQuery = '';
    _filteredProducts = List.from(_products);
    notifyListeners();
  }
}
