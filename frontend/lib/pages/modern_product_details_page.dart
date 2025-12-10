// 🎨 صفحة تفاصيل المنتج الأنيقة والمرتبة
// Elegant Product Details Page with Beautiful Design

import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart'; // 🎯 إضافة Provider
import 'package:saver_gallery/saver_gallery.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🎯 إضافة SharedPreferences
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_html/html.dart' as html;

import '../core/design_system.dart';
import '../models/product.dart';
import '../models/product_color.dart'; // 🎯 إضافة ProductColor
import '../providers/theme_provider.dart'; // 🎯 إضافة ThemeProvider
import '../services/cart_service.dart'; // 🎯 إضافة CartService
import '../services/favorites_service.dart';
import '../services/smart_colors_service.dart'; // 🎯 إضافة SmartColorsService
import '../utils/number_formatter.dart';
import '../widgets/app_background.dart'; // 🎯 إضافة الخلفية الرئيسية
import '../widgets/product_details_skeleton.dart'; // 🎯 إضافة Skeleton Loading
import 'cart_page.dart'; // 🎯 إضافة صفحة السلة

// 🎯 Widgets المستخرجة للهيكل النظيف
import 'product_details/add_to_cart_button.dart';
import 'product_details/color_quantity_bar.dart';
import 'product_details/description_section.dart';
import 'product_details/price_section.dart';
import 'product_details/product_image_gallery.dart';

class ModernProductDetailsPage extends StatefulWidget {
  final String productId;

  const ModernProductDetailsPage({super.key, required this.productId});

  @override
  State<ModernProductDetailsPage> createState() => _ModernProductDetailsPageState();
}

class _ModernProductDetailsPageState extends State<ModernProductDetailsPage> with TickerProviderStateMixin {
  // Controllers & Animation
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;

  // Page Controllers
  final PageController _imagePageController = PageController();
  final TextEditingController _priceController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Services
  final FavoritesService _favoritesService = FavoritesService.instance;
  final CartService _cartService = CartService(); // 🎯 تهيئة CartService مباشرة

  // State Variables
  Map<String, dynamic>? _productData;
  bool _isLoading = true;
  int _currentImageIndex = 0;
  double _customerPrice = 0;
  bool _isPriceValid = false;
  String? _selectedColorId; // 🎯 تغيير من String إلى String? لتخزين معرف اللون
  int _selectedQuantity = 1;
  static const int _maxQuantity = 10; // 🔒 الحد الأقصى للكمية
  static const int _minQuantity = 1; // 🔒 الحد الأدنى للكمية
  bool _isFavorite = false;

  bool _showActionBalls = false; // حالة إظهار الكرات المنبثقة
  // مفاتيح قياس مواضع الكرات
  final GlobalKey _mainBallKey = GlobalKey();
  final GlobalKey _heartBallKey = GlobalKey();
  final GlobalKey _cameraBallKey = GlobalKey();
  final GlobalKey _galleryBallKey = GlobalKey();
  OverlayEntry? _actionsOverlay;
  final List<double> _pinnedPrices = []; // قائمة الأسعار المثبتة
  bool _isHandlingAction = false; // حارس لمنع تنفيذ مضاعف للنقرات

  // 🎨 ألوان المنتج من قاعدة البيانات
  List<ProductColor> _productColors = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadProductData();
    _loadFavorites();
    _loadProductColors(); // 🎯 جلب الألوان من قاعدة البيانات
    _loadPinnedPrices(); // 🎯 تحميل الأسعار المثبتة
    _selectedColorId = 'none'; // 🎯 اختيار "لا شيء" افتراضياً
  }

  // 📌 تحميل الأسعار المثبتة من التخزين المحلي
  Future<void> _loadPinnedPrices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'pinned_prices_${widget.productId}';
      final savedPrices = prefs.getStringList(key);

      if (savedPrices != null && mounted) {
        setState(() {
          _pinnedPrices.clear();
          _pinnedPrices.addAll(savedPrices.map((e) => double.tryParse(e) ?? 0).where((p) => p > 0));
        });
        debugPrint('✅ تم تحميل ${_pinnedPrices.length} سعر مثبت للمنتج ${widget.productId}');
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الأسعار المثبتة: $e');
    }
  }

  // 📌 حفظ الأسعار المثبتة في التخزين المحلي
  Future<void> _savePinnedPrices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'pinned_prices_${widget.productId}';
      final priceStrings = _pinnedPrices.map((p) => p.toString()).toList();
      await prefs.setStringList(key, priceStrings);
      debugPrint('✅ تم حفظ ${_pinnedPrices.length} سعر مثبت للمنتج ${widget.productId}');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ الأسعار المثبتة: $e');
    }
  }

  // 🎨 جلب ألوان المنتج من قاعدة البيانات
  Future<void> _loadProductColors() async {
    try {
      final colors = await SmartColorsService.getProductColors(
        productId: widget.productId,
        includeUnavailable: false, // فقط الألوان المتاحة
      );

      if (mounted) {
        setState(() {
          _productColors = colors;
        });
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب ألوان المنتج: $e');
    }
  }

  // تحميل المفضلة
  Future<void> _loadFavorites() async {
    try {
      await _favoritesService.loadFavorites();
      if (mounted) {
        setState(() {
          _isFavorite = _favoritesService.isFavorite(widget.productId);
        });
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل المفضلة: $e');
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);

    _slideController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadProductData() async {
    try {
      final response = await Supabase.instance.client.from('products').select().eq('id', widget.productId).single();

      setState(() {
        _productData = response;
        _isLoading = false;
        _customerPrice = 0;
        _priceController.text = '';
        _validatePrice();
        // تحديث حالة المفضلة من FavoritesService
        _isFavorite = _favoritesService.isFavorite(widget.productId);
      });
    } catch (e) {
      setState(() {
        _productData = {
          'id': widget.productId,
          'name': 'لاتوجد اتصال بالانترنيت',
          'description': '',
          'wholesale_price': 0,
          'min_price': 0,
          'max_price': 0,
          'images': ['', '', '', ''],
          'available_quantity': 0,
          'category': '',
        };
        _isLoading = false;
        _customerPrice = 0;
        _priceController.text = '';
        _validatePrice();
      });
    }
  }

  void _validatePrice() {
    if (_productData == null) return;

    final minPrice = _productData!['min_price']?.toDouble() ?? 0;
    final maxPrice = _productData!['max_price']?.toDouble() ?? 0;

    setState(() {
      _isPriceValid = _customerPrice >= minPrice && _customerPrice <= maxPrice;
    });
  }

  // 📌 تثبيت السعر وحفظه في التخزين المحلي
  Future<void> _pinPrice() async {
    if (_isPriceValid && !_pinnedPrices.contains(_customerPrice)) {
      setState(() {
        _pinnedPrices.add(_customerPrice);
      });

      // 🎯 حفظ الأسعار في التخزين المحلي - انتظار الحفظ
      await _savePinnedPrices();

      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '📌 تم تثبيت السعر: ${NumberFormatter.formatCurrency(_customerPrice)}',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFFD4AF37),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // 📌 حذف سعر مثبت
  void _removePinnedPrice(double price) {
    setState(() {
      _pinnedPrices.remove(price);
    });
    // 🎯 حفظ التغييرات في التخزين المحلي
    _savePinnedPrices();

    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🗑️ تم حذف السعر: ${NumberFormatter.formatCurrency(price)}',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 🔢 زيادة الكمية
  void _incrementQuantity() {
    if (_selectedQuantity < _maxQuantity) {
      setState(() => _selectedQuantity++);
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  // 🔢 إنقاص الكمية
  void _decrementQuantity() {
    if (_selectedQuantity > _minQuantity) {
      setState(() => _selectedQuantity--);
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  void _addToCart() async {
    if (!_isPriceValid || _productData == null) return;

    HapticFeedback.mediumImpact();

    try {
      // 🎨 الحصول على معلومات اللون المختار
      String? colorName;
      String? colorHex;

      if (_selectedColorId != null && _selectedColorId != 'none') {
        try {
          final selectedColor = _productColors.firstWhere((color) => color.id == _selectedColorId);
          colorName = selectedColor.colorArabicName; // 🎨 استخدام الاسم العربي
          colorHex = selectedColor.colorCode; // 🎨 استخدام colorCode
        } catch (e) {
          debugPrint('⚠️ لم يتم العثور على اللون المختار');
        }
      }

      // 🎯 إضافة المنتج للسلة
      final result = await _cartService.addItem(
        productId: widget.productId,
        name: _productData!['name'] ?? '',
        image: _getImagesList().isNotEmpty ? _getImagesList().first : '',
        wholesalePrice: (_productData!['wholesale_price'] ?? 0).toInt(),
        minPrice: (_productData!['min_price'] ?? 0).toInt(),
        maxPrice: (_productData!['max_price'] ?? 0).toInt(),
        customerPrice: _customerPrice.toInt(),
        quantity: _selectedQuantity,
        colorId: _selectedColorId != 'none' ? _selectedColorId : null, // 🎨 تمرير معرف اللون
        colorName: colorName, // 🎨 تمرير اسم اللون
        colorHex: colorHex, // 🎨 تمرير كود اللون
      );

      if (result['success']) {
        // 🎯 الانتقال إلى صفحة السلة مباشرة بدون رسالة
        if (mounted) {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CartPage()));
        }
      } else {
        // 🎯 إظهار رسالة خطأ
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'فشل في إضافة المنتج للسلة',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ خطأ في إضافة المنتج للسلة: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء إضافة المنتج للسلة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _copyDescription() {
    if (_productData != null && _productData!['description'] != null) {
      // 🎯 نسخ الوصف بدون الروابط
      final originalDescription = _productData!['description'];
      final cleanDescription = _removeLinksFromText(originalDescription);

      Clipboard.setData(ClipboardData(text: cleanDescription));
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم نسخ الوصف بنجاح!', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          backgroundColor: AppDesignSystem.goldColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _removeActionsOverlay();
    _fadeController.dispose();
    _slideController.dispose();
    _imagePageController.dispose();
    _priceController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode; // 🎯 تحديد الوضع من ThemeProvider

    // 🦴 عرض Skeleton Loading أثناء التحميل
    if (_isLoading) {
      return PopScope(
        canPop: true, // السماح بالرجوع أثناء التحميل
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: AppBackground(
            child: SafeArea(bottom: false, child: ProductDetailsSkeleton(isDark: isDark)),
          ),
        ),
      );
    }

    return PopScope(
      canPop: true, // السماح بالرجوع من صفحة التفاصيل
      child: Scaffold(
        backgroundColor: Colors.transparent, // 🎯 شفاف لإظهار الخلفية الرئيسية
        extendBody: true,
        body: AppBackground(
          child: Stack(
            children: [
              // 🎨 خلفية الوضع النهاري
              if (!isDark) Container(color: const Color(0xFFF5F5F7)),

              // المحتوى الرئيسي
              SafeArea(
                bottom: false, // إزالة SafeArea من الأسفل
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 80), // 🎯 مساحة للزر الثابت
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        const SizedBox(height: 10), // تقليل المسافة العلوية
                        // منطقة الصورة الأنيقة - استخدام Widget المستخرج
                        ProductImageGallery(
                          images: _getImagesList(),
                          currentIndex: _currentImageIndex,
                          pageController: _imagePageController,
                          onPageChanged: (index) {
                            setState(() => _currentImageIndex = index);
                          },
                        ),

                        // فاصل بسيط بدون كرة
                        const SizedBox(height: 10),

                        // تفاصيل المنتج في container أنيق (بدون مسافة)
                        _buildProductDetailsCard(),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),

              // 🛒 زر إضافة للسلة الثابت في الأسفل - بدون تدرج
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 12),
                    // 🎯 استخدام AddToCartButton Widget المستخرج
                    child: AddToCartButton(
                      isPriceValid: _isPriceValid,
                      customerPrice: _customerPrice,
                      selectedQuantity: _selectedQuantity,
                      onPressed: _addToCart,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //  الكرة العائمة - استجابة كاملة 100% بدون تداخل

  // 🎨 العرض البصري للكرة فقط (بدون منطق النقر)
  Widget _buildActionBallVisual(IconData icon, {Key? widgetKey}) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode; // 🎯 تحديد الوضع

    // تحديد خصائص كرة القلب حسب حالة المفضلة
    bool isHeartBall = icon == Icons.favorite;
    bool isActive = isHeartBall ? _isFavorite : false;

    // ألوان مخصصة لكل كرة
    Color ballColor;
    Color iconColor;
    Color borderColor;

    if (isHeartBall) {
      // كرة القلب - تمييز واضح حسب الحالة
      ballColor = isActive
          ? Colors.red.withValues(alpha: 0.9)
          : (isDark ? const Color(0xFF2A2A2A) : Colors.white); // 🎯 خلفية بيضاء في الوضع النهاري
      iconColor = isActive ? Colors.white : Colors.red;
      borderColor = isActive ? Colors.red : Colors.red.withValues(alpha: 0.5);
    } else if (icon == Icons.photo_camera) {
      // كرة الكاميرا
      ballColor = isDark ? const Color(0xFF2A2A2A) : Colors.white; // 🎯 خلفية بيضاء في الوضع النهاري
      iconColor = Colors.blue;
      borderColor = const Color(0xFFFFD700);
    } else {
      // كرة المعرض
      ballColor = isDark ? const Color(0xFF2A2A2A) : Colors.white; // 🎯 خلفية بيضاء في الوضع النهاري
      iconColor = Colors.green;
      borderColor = const Color(0xFFFFD700);
    }

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            key: widgetKey,
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: isDark ? null : ballColor, // 🎯 لون صلب في الوضع النهاري
              gradient: isDark
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [ballColor, ballColor.withValues(alpha: 0.8)],
                    )
                  : null, // 🎯 بدون تدرج في الوضع النهاري
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: isActive ? 3.0 : 2.0),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.3), // 🎯 ظل أخف في الوضع النهاري
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 0),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Center(
              child: Icon(isHeartBall && isActive ? Icons.favorite : icon, color: iconColor, size: isActive ? 24 : 20),
            ),
          ),
        );
      },
    );
  }

  // 🎯 كرة الإجراءات المنبثقة - مع النقر
  Widget _buildActionBall({required IconData icon, required Color color, required VoidCallback onTap, Key? widgetKey}) {
    return GestureDetector(
      onTap: () {
        debugPrint('🎯 تم النقر على كرة! الأيقونة: $icon');
        HapticFeedback.lightImpact();
        onTap();
        setState(() {
          _showActionBalls = false;
        });
      },
      child: _buildActionBallVisual(icon, widgetKey: widgetKey),
    );
  }

  // 💖 تبديل المفضلة - محدث ليستخدم FavoritesService
  Future<void> _toggleFavorite() async {
    if (_productData == null) return;

    try {
      // إنشاء كائن Product من البيانات
      final product = Product(
        id: widget.productId,
        name: _productData!['name'] ?? '',
        description: _productData!['description'] ?? '',
        wholesalePrice: (_productData!['wholesale_price'] ?? 0).toDouble(),
        minPrice: (_productData!['min_price'] ?? 0).toDouble(),
        maxPrice: (_productData!['max_price'] ?? 0).toDouble(),
        images: _getImagesList(),
        category: _productData!['category'] ?? '',
        availableQuantity: _productData!['available_quantity'] ?? 0,
        availableFrom: _productData!['available_from'] ?? 90,
        availableTo: _productData!['available_to'] ?? 80,
        minQuantity: _productData!['min_quantity'] ?? 10,
        maxQuantity: _productData!['max_quantity'] ?? 50,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await _favoritesService.toggleFavorite(product);

      if (success && mounted) {
        setState(() {
          _isFavorite = _favoritesService.isFavorite(widget.productId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorite ? 'تم إضافة المنتج للمفضلة ❤️' : 'تم إزالة المنتج من المفضلة 💔',
              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: _isFavorite ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ خطأ في تبديل المفضلة: $e');
    }
  }

  // 📷 حفظ الصورة الحالية
  Future<void> _saveCurrentImage() async {
    final images = _getImagesList();
    if (images.isEmpty) return;

    try {
      final currentImage = images[_currentImageIndex];
      await _saveImageToGallery(currentImage, 'صورة_المنتج_${DateTime.now().millisecondsSinceEpoch}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حفظ الصورة في الاستوديو ✅',
              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل في حفظ الصورة: $e',
              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // 🖼️ حفظ كل الصور
  Future<void> _saveAllImages() async {
    final images = _getImagesList();
    if (images.isEmpty) return;

    // فرع الويب: أطلق جميع التنزيلات فوراً دفعة واحدة بدون انتظار متسلسل
    if (kIsWeb) {
      // تنزيل صامت لكل الصور عبر Blob دون فتح تبويبات
      int downloaded = 0;
      int failed = 0;
      for (int i = 0; i < images.length; i++) {
        final url = images[i];
        try {
          final response = await http.get(Uri.parse(url));
          if (response.statusCode != 200) {
            failed++;
            continue;
          }
          // تخمين الامتداد والنوع
          final lower = url.toLowerCase();
          String ext = '.jpg';
          String mime = 'image/jpeg';
          if (lower.endsWith('.png')) {
            ext = '.png';
            mime = 'image/png';
          } else if (lower.endsWith('.webp')) {
            ext = '.webp';
            mime = 'image/webp';
          }

          final blob = html.Blob([response.bodyBytes], mime);
          final objUrl = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: objUrl)
            ..download = 'image_${i + 1}_${DateTime.now().millisecondsSinceEpoch}$ext'
            ..style.display = 'none';
          html.document.body?.append(anchor);
          anchor.click();
          anchor.remove();
          html.Url.revokeObjectUrl(objUrl);
          downloaded++;
        } catch (e) {
          failed++;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        final msg = failed == 0
            ? 'تم تنزيل $downloaded صورة ✅'
            : 'تم تنزيل $downloaded صورة، وفشل $failed (قيود المصدر)';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              msg,
              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: failed == 0 ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // الأجهزة: نحفظ تسلسلياً لكن برسالة واحدة في النهاية
    try {
      int savedCount = 0;
      for (int i = 0; i < images.length; i++) {
        try {
          await _saveImageToGallery(images[i], 'صورة_المنتج_${i + 1}_${DateTime.now().millisecondsSinceEpoch}');
          savedCount++;
        } catch (e) {
          debugPrint('❌ فشل في حفظ الصورة $i: $e');
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حفظ $savedCount من ${images.length} صور في الاستوديو ✅',
              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل في حفظ الصور: $e',
              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // 💾 حفظ صورة في الاستوديو
  Future<void> _saveImageToGallery(String imageUrl, String fileName) async {
    try {
      // دعم الويب: لا يمكن الحفظ في الاستوديو على المتصفح
      if (kIsWeb) {
        // تنزيل مباشر عبر المتصفح. نحاول أولاً عبر Blob، وإن فشل (مثل CORS) نسقط إلى رابط مباشر
        try {
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode != 200) {
            throw Exception('HTTP ${response.statusCode}');
          }
          // تحديد نوع/امتداد الملف بناءً على رابط الصورة
          final lower = imageUrl.toLowerCase();
          String ext = '.jpg';
          String mime = 'image/jpeg';
          if (lower.endsWith('.png')) {
            ext = '.png';
            mime = 'image/png';
          } else if (lower.endsWith('.webp')) {
            ext = '.webp';
            mime = 'image/webp';
          }
          final blob = html.Blob([response.bodyBytes], mime);
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..download = '$fileName$ext'
            ..style.display = 'none';
          html.document.body?.append(anchor);
          anchor.click();
          anchor.remove();
          html.Url.revokeObjectUrl(url);
        } catch (e) {
          // سقوط إلى رابط مباشر يُنزل أو يفتح الصورة في تبويب جديد
          try {
            final anchor = html.AnchorElement(href: imageUrl)
              ..download = fileName
              ..target = '_blank'
              ..rel = 'noopener'
              ..style.display = 'none';
            html.document.body?.append(anchor);
            anchor.click();
            anchor.remove();
          } catch (err) {
            debugPrint('❌ تعذّر تنزيل الصورة على الويب: $e / $err');
          }
        }
        return;
      }

      // طلب الصلاحيات (للأجهزة فقط)
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('لا توجد صلاحية للوصول للتخزين');
      }

      // تحميل الصورة
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('فشل في تحميل الصورة');
      }

      // حفظ الصورة في الاستوديو باستخدام saver_gallery
      final result = await SaverGallery.saveImage(
        response.bodyBytes,
        quality: 100,
        fileName: fileName,
        androidRelativePath: "Pictures/منتجاتي/images",
        skipIfExists: false,
      );

      if (result.isSuccess != true) {
        throw Exception('فشل في حفظ الصورة في الاستوديو');
      }

      debugPrint('✅ تم حفظ الصورة: $fileName');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ الصورة: $e');
      rethrow;
    }
  }

  // 📋 كارت تفاصيل المنتج الشفاف والمضبب
  Widget _buildProductDetailsCard() {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode; // 🎯 تحديد الوضع
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // الجزء الشفاف والمضبب
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(50), // قوس عميق
            topRight: Radius.circular(50), // قوس عميق
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 0),
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 0), // زيادة المسافة العلوية
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.01)
                    : Colors.white.withValues(alpha: 0.95), // 🎯 خلفية بيضاء في الوضع النهاري
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(50), // قوس عميق
                  topRight: Radius.circular(50), // قوس عميق
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.3), // 🎯 حدود رمادية في الوضع النهاري
                  width: 1,
                ),
                // إضافة ظل للتأثير ثلاثي الأبعاد
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // اسم المنتج فقط (بدون مجسم)
                  Text(
                    _productData?['name'] ?? 'اسم المنتج',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black, // 🎯 لون متكيف
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // شريط الألوان والكمية المدمج - 🎯 استخدام ColorQuantityBar Widget المستخرج
                  ColorQuantityBar(
                    colors: _productColors,
                    selectedColorId: _selectedColorId,
                    selectedQuantity: _selectedQuantity,
                    maxQuantity: _maxQuantity,
                    minQuantity: _minQuantity,
                    onColorSelected: (colorId) {
                      setState(() => _selectedColorId = colorId);
                    },
                    onIncrement: _incrementQuantity,
                    onDecrement: _decrementQuantity,
                  ),

                  const SizedBox(height: 28),

                  // السعر - 🎯 استخدام PriceSection Widget المستخرج
                  PriceSection(
                    minPrice: _productData?['min_price']?.toDouble() ?? 0,
                    maxPrice: _productData?['max_price']?.toDouble() ?? 0,
                    wholesalePrice: _productData?['wholesale_price']?.toDouble() ?? 0,
                    customerPrice: _customerPrice,
                    isPriceValid: _isPriceValid,
                    pinnedPrices: _pinnedPrices,
                    priceController: _priceController,
                    onPriceChanged: (value) {
                      setState(() {
                        _customerPrice = double.tryParse(value) ?? 0;
                        _validatePrice();
                      });
                    },
                    onPinPrice: _isPriceValid ? _pinPrice : null,
                    onPinnedPriceTap: (price) {
                      setState(() {
                        _customerPrice = price;
                        _priceController.text = price.toInt().toString();
                        _validatePrice();
                      });
                      HapticFeedback.selectionClick();
                    },
                    onPinnedPriceLongPress: (price) {
                      // للاستخدام المستقبلي - حذف السعر المثبت
                      _removePinnedPrice(price);
                    },
                  ),

                  const SizedBox(height: 24),

                  // الوصف - 🎯 استخدام DescriptionSection Widget المستخرج
                  DescriptionSection(
                    description: _productData?['description'] ?? 'وصف المنتج هنا...',
                    onCopy: _copyDescription,
                  ),

                  const SizedBox(height: 24),

                  // مساحة إضافية لتجنب تداخل الزر العائم
                  const SizedBox(height: 30), // تقليل المسافة من 100 إلى 30
                ],
              ),
            ),
          ),
        ),

        // 🎯 الكرة الرئيسية منفصلة في الجهة اليمنى
        _buildMainFloatingBall(),

        // طبقة شفافة عامة تلتقط النقرات وتحدد الهدف بناءً على مفاتيح القياس
        if (_showActionBalls)
          Positioned.fill(
            child: GestureDetector(behavior: HitTestBehavior.translucent, onTapDown: _handleActionBallsTap),
          ),

        // طبقة إضافية تغطي المنطقة أعلى البطاقة لضمان التقاط نقرات الكرات ذات الإزاحة السالبة
        if (_showActionBalls)
          Positioned(
            top: -180, // تغطية كافية فوق حد البطاقة لغاية 180px
            left: 0,
            right: 0,
            height: 220, // ارتفاع يغطي القلب والكاميرا
            child: GestureDetector(behavior: HitTestBehavior.translucent, onTapDown: _handleActionBallsTap),
          ),
      ],
    );
  }

  // 🎯 الكرة الرئيسية والكرات المنبثقة - قسم منفصل
  Widget _buildMainFloatingBall() {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode; // 🎯 تحديد الوضع

    return Positioned(
      top: -29,
      right: 50, // تصحيح الموضع ليظهر داخل الشاشة
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // الكرة الرئيسية
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _showActionBalls = !_showActionBalls;
              });
              if (_showActionBalls) {
                _showActionsOverlay();
              } else {
                _removeActionsOverlay();
              }
            },
            child: Container(
              key: _mainBallKey,
              width: 50,
              height: 60,
              decoration: BoxDecoration(
                color: isDark ? Colors.orange : Colors.white, // 🎯 خلفية بيضاء في الوضع النهاري
                gradient: isDark
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF363940), Color(0xFF2D3748), Color(0xFF1A202C)],
                      )
                    : null, // 🎯 بدون تدرج في الوضع النهاري
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFD700), width: 3.0),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.5)
                        : Colors.grey.withValues(alpha: 0.3), // 🎯 ظل أخف في الوضع النهاري
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                    blurRadius: 5,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  _isFavorite ? Icons.favorite : Icons.apps,
                  color: _isFavorite ? Colors.red : const Color(0xFFFFD700),
                  size: 25,
                ),
              ),
            ),
          ),

          // الكرات المنبثقة - نفس المواقع الأصلية بالضبط
          if (_showActionBalls) ...[
            // كرة المفضلة - يسار
            Positioned(
              top: -40,
              right: 60, // تصحيح الموضع ليظهر داخل الشاشة
              child: _buildActionBall(
                icon: Icons.favorite,
                color: isDark ? const Color(0xFF2A2A2A) : Colors.white, // 🎯 خلفية بيضاء في الوضع النهاري
                onTap: _toggleFavorite,
                widgetKey: _heartBallKey,
              ),
            ),

            // كرة حفظ الصورة الحالية - أعلى
            Positioned(
              top: -55, // أعلى الكرة الرئيسية
              right: 10,
              child: _buildActionBall(
                icon: Icons.photo_camera,
                color: isDark ? const Color(0xFF2A2A2A) : Colors.white, // 🎯 خلفية بيضاء في الوضع النهاري
                onTap: _saveCurrentImage,
                widgetKey: _cameraBallKey,
              ),
            ),

            // كرة حفظ كل الصور - أسفل
            Positioned(
              top: 13, // أسفل الكرة الرئيسية
              right: 65, // تصحيح الموضع ليظهر داخل الشاشة
              child: _buildActionBall(
                icon: Icons.photo_library,
                color: isDark ? const Color(0xFF2A2A2A) : Colors.white, // 🎯 خلفية بيضاء في الوضع النهاري
                onTap: _saveAllImages,
                widgetKey: _galleryBallKey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 🧠 معالج نقرات عام يعتمد على الإحداثيات العالمية للكرات (لا تغيير للمواقع إطلاقاً)
  void _handleActionBallsTap(TapDownDetails details) {
    if (_isHandlingAction) return; // منع تكرار التنفيذ
    _isHandlingAction = true;
    final pos = details.globalPosition;

    bool hit(GlobalKey key) {
      final ctx = key.currentContext;
      if (ctx == null) return false;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return false;
      final topLeft = box.localToGlobal(Offset.zero);
      final size = box.size;
      final center = topLeft + Offset(size.width / 2, size.height / 2);
      final radius = (size.shortestSide / 2) + 6; // سماحية بسيطة لتأثيرات التحجيم
      return (pos - center).distance <= radius;
    }

    if (hit(_heartBallKey)) {
      HapticFeedback.lightImpact();
      _toggleFavorite();
    } else if (hit(_cameraBallKey)) {
      HapticFeedback.lightImpact();
      _saveCurrentImage();
    } else if (hit(_galleryBallKey)) {
      HapticFeedback.lightImpact();
      _saveAllImages();
    }

    setState(() => _showActionBalls = false);
    _removeActionsOverlay();
    _isHandlingAction = false; // تحرير الحارس
  }

  // 🧠 إدارة طبقة Overlay على مستوى الشاشة لالتقاط النقرات فوق حدود البطاقة
  void _showActionsOverlay() {
    final overlay = Overlay.of(context);
    _actionsOverlay?.remove();
    _actionsOverlay = OverlayEntry(
      builder: (ctx) => Positioned.fill(
        child: GestureDetector(behavior: HitTestBehavior.translucent, onTapDown: _handleActionBallsTap),
      ),
    );
    overlay.insert(_actionsOverlay!);
  }

  void _removeActionsOverlay() {
    _actionsOverlay?.remove();
    _actionsOverlay = null;
  }

  // دالة مساعدة للحصول على قائمة الصور
  List<String> _getImagesList() {
    if (_productData == null) return [];
    final images = _productData!['images'];
    if (images is List) {
      return images.map((img) => img.toString()).toList();
    }
    return [];
  }

  // 🔗 إزالة الروابط من النص لإظهار الوصف نظيفاً
  String _removeLinksFromText(String text) {
    final RegExp urlPattern = RegExp(r'(https?://[^\s]+)', caseSensitive: false);

    // إزالة الروابط والسطر الذي يحتوي عليها
    final lines = text.split('\n');
    final cleanLines = <String>[];

    for (final line in lines) {
      // إذا كان السطر يحتوي على رابط، نتجاهله
      if (!urlPattern.hasMatch(line)) {
        cleanLines.add(line);
      }
    }

    return cleanLines.join('\n').trim();
  }
}
