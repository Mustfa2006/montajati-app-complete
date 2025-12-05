import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/repository/products_repository.dart';

/// مزود المنتجات - يدير حالة المنتجات بالكامل
class ProductsProvider extends ChangeNotifier {
  final ProductsRepository _repository;

  // الحالة
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

  ProductsProvider({ProductsRepository? repository}) : _repository = repository ?? ProductsRepository();

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

  /// تحميل المنتجات (الصفحة الأولى)
  Future<void> loadProducts({bool forceRefresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    _currentPage = 1;
    notifyListeners();

    try {
      final result = await _repository.getProducts(page: 1, limit: _itemsPerPage, forceRefresh: forceRefresh);

      _products = result.products;
      // ✅ ترتيب المنتجات حسب displayOrder
      _products.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

      _hasMore = result.hasMore;
      _applySearch();

      // إذا جاء من الكاش، حدث في الخلفية
      if (result.fromCache && !forceRefresh) {
        _refreshInBackground();
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = e.toString();
      debugPrint('❌ خطأ في تحميل المنتجات: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// تحميل المزيد من المنتجات
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      final result = await _repository.getProducts(page: _currentPage, limit: _itemsPerPage);

      // إضافة المنتجات الجديدة فقط (تجنب التكرار)
      for (final product in result.products) {
        if (!_products.any((p) => p.id == product.id)) {
          _products.add(product);
        }
      }

      // ✅ إعادة ترتيب كل المنتجات حسب displayOrder
      _products.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

      _hasMore = result.hasMore;
      _applySearch(); // إعادة تطبيق البحث على المنتجات الجديدة
    } catch (e) {
      _currentPage--; // التراجع عن الصفحة
      debugPrint('❌ خطأ في تحميل المزيد: $e');
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  /// البحث في المنتجات
  void search(String query) {
    _searchQuery = query;
    _applySearch();
    notifyListeners();
  }

  /// تطبيق البحث على المنتجات مع الحفاظ على الترتيب
  void _applySearch() {
    if (_searchQuery.trim().isEmpty) {
      _filteredProducts = List.from(_products);
    } else {
      final lowerQuery = _searchQuery.toLowerCase().trim();
      _filteredProducts = _products.where((p) => p.name.toLowerCase().contains(lowerQuery)).toList();
    }
    // ✅ الحفاظ على الترتيب حسب displayOrder
    _filteredProducts.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  /// تحديث في الخلفية
  Future<void> _refreshInBackground() async {
    final result = await _repository.refreshInBackground(limit: _itemsPerPage);
    if (result != null && _hasDataChanged(result.products)) {
      _products = result.products;
      _hasMore = result.hasMore;
      _applySearch();
      notifyListeners();
    }
  }

  /// فحص هل تغيرت البيانات
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
          oldP.name != newP.name) {
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
