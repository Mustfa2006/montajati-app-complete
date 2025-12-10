// 🎯 Provider لتفاصيل المنتج
// يدير كل حالة صفحة تفاصيل المنتج

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/product.dart';
import '../models/product_color.dart';
import '../repositories/product_details_repository.dart';
import '../services/cart_service.dart';
import '../services/favorites_service.dart';
import '../services/image_download_service.dart';

/// حالات تحميل المنتج
enum ProductLoadState { initial, loading, loaded, error }

/// مزود تفاصيل المنتج
class ProductDetailsProvider extends ChangeNotifier {
  final ProductDetailsRepository _repository;
  final FavoritesService _favoritesService;
  final CartService _cartService;
  final ImageDownloadService _imageService;

  // 🎯 معرف المنتج
  String _productId = '';
  String get productId => _productId;

  // 📦 بيانات المنتج
  Map<String, dynamic>? _productData;
  Map<String, dynamic>? get productData => _productData;

  // 🔄 حالة التحميل
  ProductLoadState _loadState = ProductLoadState.initial;
  ProductLoadState get loadState => _loadState;
  bool get isLoading => _loadState == ProductLoadState.loading;
  bool get hasError => _loadState == ProductLoadState.error;

  // 🖼️ فهرس الصورة الحالية
  int _currentImageIndex = 0;
  int get currentImageIndex => _currentImageIndex;

  // 💰 سعر الزبون
  double _customerPrice = 0;
  double get customerPrice => _customerPrice;

  // ✅ صحة السعر
  bool _isPriceValid = false;
  bool get isPriceValid => _isPriceValid;

  // 🎨 اللون المختار
  String? _selectedColorId = 'none';
  String? get selectedColorId => _selectedColorId;

  // 📊 الكمية المختارة
  int _selectedQuantity = 1;
  int get selectedQuantity => _selectedQuantity;
  static const int maxQuantity = 10;
  static const int minQuantity = 1;

  // ❤️ المفضلة
  bool _isFavorite = false;
  bool get isFavorite => _isFavorite;

  // 📝 توسيع الوصف
  bool _isDescriptionExpanded = false;
  bool get isDescriptionExpanded => _isDescriptionExpanded;

  // 📌 الأسعار المثبتة
  List<double> _pinnedPrices = [];
  List<double> get pinnedPrices => List.unmodifiable(_pinnedPrices);

  // 🎨 ألوان المنتج
  List<ProductColor> _productColors = [];
  List<ProductColor> get productColors => List.unmodifiable(_productColors);

  ProductDetailsProvider({
    ProductDetailsRepository? repository,
    FavoritesService? favoritesService,
    CartService? cartService,
    ImageDownloadService? imageService,
  }) : _repository = repository ?? ProductDetailsRepository(),
       _favoritesService = favoritesService ?? FavoritesService.instance,
       _cartService = cartService ?? CartService(),
       _imageService = imageService ?? ImageDownloadService();

  // 🔧 تهيئة المنتج
  Future<void> initialize(String productId) async {
    if (_productId == productId && _productData != null) return;

    _productId = productId;
    _selectedColorId = 'none';
    _selectedQuantity = 1;
    _customerPrice = 0;
    _isPriceValid = false;
    _currentImageIndex = 0;
    _isDescriptionExpanded = false;

    await Future.wait([_loadProductData(), _loadProductColors(), _loadFavorites(), _loadPinnedPrices()]);
  }

  // 📦 تحميل بيانات المنتج
  Future<void> _loadProductData() async {
    _loadState = ProductLoadState.loading;
    notifyListeners();

    final data = await _repository.fetchProduct(_productId);

    if (data != null) {
      _productData = data;
      _loadState = ProductLoadState.loaded;
      _isFavorite = _favoritesService.isFavorite(_productId);
    } else {
      _productData = _getErrorProductData();
      _loadState = ProductLoadState.error;
    }

    _validatePrice();
    notifyListeners();
  }

  // 🎨 تحميل ألوان المنتج
  Future<void> _loadProductColors() async {
    _productColors = await _repository.fetchProductColors(_productId);
    notifyListeners();
  }

  // ❤️ تحميل المفضلة
  Future<void> _loadFavorites() async {
    try {
      await _favoritesService.loadFavorites();
      _isFavorite = _favoritesService.isFavorite(_productId);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ خطأ في تحميل المفضلة: $e');
    }
  }

  // 📌 تحميل الأسعار المثبتة
  Future<void> _loadPinnedPrices() async {
    _pinnedPrices = await _repository.loadPinnedPrices(_productId);
    notifyListeners();
  }

  // ✅ التحقق من صحة السعر
  void _validatePrice() {
    if (_productData == null) {
      _isPriceValid = false;
      return;
    }
    final minPrice = (_productData!['min_price'] ?? 0).toDouble();
    final maxPrice = (_productData!['max_price'] ?? 0).toDouble();
    _isPriceValid = _customerPrice >= minPrice && _customerPrice <= maxPrice;
  }

  // 💰 تعيين سعر الزبون
  void setCustomerPrice(double price) {
    _customerPrice = price;
    _validatePrice();
    notifyListeners();
  }

  // 📌 تثبيت السعر الحالي
  Future<bool> pinCurrentPrice() async {
    if (!_isPriceValid || _customerPrice <= 0) return false;
    if (_pinnedPrices.contains(_customerPrice)) return false;
    if (_pinnedPrices.length >= 5) return false;

    _pinnedPrices.add(_customerPrice);
    notifyListeners();

    HapticFeedback.mediumImpact();
    return await _repository.savePinnedPrices(_productId, _pinnedPrices);
  }

  // 📌 استخدام سعر مثبت
  void usePinnedPrice(double price) {
    _customerPrice = price;
    _validatePrice();
    HapticFeedback.lightImpact();
    notifyListeners();
  }

  // 📌 حذف سعر مثبت
  Future<void> removePinnedPrice(double price) async {
    _pinnedPrices.remove(price);
    notifyListeners();
    await _repository.savePinnedPrices(_productId, _pinnedPrices);
    HapticFeedback.lightImpact();
  }

  // 🖼️ تغيير الصورة الحالية
  void setCurrentImageIndex(int index) {
    _currentImageIndex = index;
    notifyListeners();
  }

  // 🎨 تغيير اللون المختار
  void setSelectedColor(String? colorId) {
    _selectedColorId = colorId;
    notifyListeners();
  }

  // 📊 زيادة الكمية
  void incrementQuantity() {
    if (_selectedQuantity < maxQuantity) {
      _selectedQuantity++;
      HapticFeedback.selectionClick();
      notifyListeners();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  // 📊 إنقاص الكمية
  void decrementQuantity() {
    if (_selectedQuantity > minQuantity) {
      _selectedQuantity--;
      HapticFeedback.selectionClick();
      notifyListeners();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  // 📊 تعيين الكمية
  void setQuantity(int quantity) {
    _selectedQuantity = quantity.clamp(minQuantity, maxQuantity);
    notifyListeners();
  }

  // 📝 تبديل توسيع الوصف
  void toggleDescriptionExpanded() {
    _isDescriptionExpanded = !_isDescriptionExpanded;
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  // ❤️ تبديل المفضلة
  Future<bool> toggleFavorite() async {
    if (_productData == null) return false;

    try {
      HapticFeedback.mediumImpact();

      final product = Product(
        id: _productId,
        name: _productData!['name'] ?? '',
        description: _productData!['description'] ?? '',
        wholesalePrice: (_productData!['wholesale_price'] ?? 0).toDouble(),
        minPrice: (_productData!['min_price'] ?? 0).toDouble(),
        maxPrice: (_productData!['max_price'] ?? 0).toDouble(),
        images: _getImagesList(),
        minQuantity: _productData!['min_quantity'] ?? 1,
        maxQuantity: _productData!['max_quantity'] ?? 100,
        availableFrom: _productData!['available_from'] ?? DateTime.now().millisecondsSinceEpoch,
        availableTo:
            _productData!['available_to'] ?? DateTime.now().add(const Duration(days: 365)).millisecondsSinceEpoch,
        availableQuantity: _productData!['available_quantity'] ?? 100,
        category: _productData!['category'] ?? '',
        displayOrder: _productData!['display_order'] ?? 999,
        notificationTags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isFavorite) {
        await _favoritesService.removeFromFavorites(_productId);
        _isFavorite = false;
      } else {
        await _favoritesService.addToFavorites(product);
        _isFavorite = true;
      }

      notifyListeners();
      return _isFavorite;
    } catch (e) {
      debugPrint('❌ خطأ في تبديل المفضلة: $e');
      return _isFavorite;
    }
  }

  // 🛒 إضافة للسلة
  Future<Map<String, dynamic>> addToCart() async {
    if (!_isPriceValid || _productData == null) {
      return {'success': false, 'message': 'السعر غير صحيح'};
    }

    String? colorName;
    String? colorHex;

    if (_selectedColorId != null && _selectedColorId != 'none') {
      try {
        final selectedColor = _productColors.firstWhere((color) => color.id == _selectedColorId);
        colorName = selectedColor.colorArabicName;
        colorHex = selectedColor.colorCode;
      } catch (e) {
        debugPrint('⚠️ لم يتم العثور على اللون المختار');
      }
    }

    HapticFeedback.mediumImpact();

    return await _cartService.addItem(
      productId: _productId,
      name: _productData!['name'] ?? '',
      image: _getImagesList().isNotEmpty ? _getImagesList().first : '',
      wholesalePrice: (_productData!['wholesale_price'] ?? 0).toInt(),
      minPrice: (_productData!['min_price'] ?? 0).toInt(),
      maxPrice: (_productData!['max_price'] ?? 0).toInt(),
      customerPrice: _customerPrice.toInt(),
      quantity: _selectedQuantity,
      colorId: _selectedColorId != 'none' ? _selectedColorId : null,
      colorName: colorName,
      colorHex: colorHex,
    );
  }

  // 🖼️ حفظ الصورة الحالية
  Future<bool> saveCurrentImage() async {
    final images = _getImagesList();
    if (images.isEmpty || _currentImageIndex >= images.length) return false;

    final url = images[_currentImageIndex];
    final fileName = 'product_${_productId}_${_currentImageIndex + 1}';

    HapticFeedback.mediumImpact();
    return await _imageService.saveSingleImage(imageUrl: url, fileName: fileName);
  }

  // 🖼️ حفظ كل الصور
  Future<ImagesSaveResult> saveAllImages() async {
    HapticFeedback.mediumImpact();
    return await _imageService.saveAllImages(_getImagesList());
  }

  // 🖼️ الحصول على قائمة الصور
  List<String> _getImagesList() {
    if (_productData == null) return [];
    final images = _productData!['images'];
    if (images == null) return [];
    if (images is List) {
      return images.map((e) => e.toString()).toList();
    }
    return [];
  }

  // 🖼️ Getter عام للصور
  List<String> get imagesList => _getImagesList();

  // 📦 بيانات المنتج في حالة الخطأ
  Map<String, dynamic> _getErrorProductData() {
    return {
      'name': 'خطأ في التحميل',
      'description': 'حدث خطأ أثناء تحميل بيانات المنتج',
      'wholesale_price': 0,
      'min_price': 0,
      'max_price': 0,
      'images': <String>[],
    };
  }

  // 🔗 استخراج الروابط من النص
  List<Map<String, String>> extractLinks(String text) {
    final List<Map<String, String>> links = [];
    final RegExp urlPattern = RegExp(r'(https?://[^\s]+)', caseSensitive: false);
    final matches = urlPattern.allMatches(text);
    int linkCounter = 1;

    for (final match in matches) {
      final url = match.group(0)!;
      String label;
      if (linkCounter == 1) {
        label = 'رابط الفيديو الأول';
      } else if (linkCounter == 2) {
        label = 'رابط الفيديو الثاني';
      } else if (linkCounter == 3) {
        label = 'رابط الفيديو الثالث';
      } else if (linkCounter == 4) {
        label = 'رابط الفيديو الرابع';
      } else if (linkCounter == 5) {
        label = 'رابط الفيديو الخامس';
      } else {
        label = 'رابط الفيديو $linkCounter';
      }
      links.add({'url': url, 'label': label});
      linkCounter++;
    }
    return links;
  }

  // 🔗 إزالة الروابط من النص
  String removeLinksFromText(String text) {
    final RegExp urlPattern = RegExp(r'(https?://[^\s]+)', caseSensitive: false);
    final lines = text.split('\n');
    final cleanLines = <String>[];

    for (final line in lines) {
      if (!urlPattern.hasMatch(line)) {
        cleanLines.add(line);
      }
    }

    return cleanLines.join('\n').trim();
  }

  // 📋 نسخ الوصف
  void copyDescription() {
    if (_productData == null) return;
    final desc = _productData!['description'] ?? '';
    final cleanDesc = removeLinksFromText(desc);
    Clipboard.setData(ClipboardData(text: cleanDesc));
    HapticFeedback.lightImpact();
  }
}
