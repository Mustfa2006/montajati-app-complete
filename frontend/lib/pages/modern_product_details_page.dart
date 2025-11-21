// 🎨 صفحة تفاصيل المنتج الأنيقة والمرتبة
// Elegant Product Details Page with Beautiful Design

import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart'; // 🎯 إضافة Provider
import 'package:saver_gallery/saver_gallery.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart'; // 🎯 إضافة url_launcher

import '../core/design_system.dart';
import '../models/product.dart';
import '../models/product_color.dart'; // 🎯 إضافة ProductColor
import '../providers/theme_provider.dart'; // 🎯 إضافة ThemeProvider
import '../services/cart_service.dart'; // 🎯 إضافة CartService
import '../services/favorites_service.dart';
import '../services/smart_colors_service.dart'; // 🎯 إضافة SmartColorsService
import '../utils/number_formatter.dart';
import 'cart_page.dart'; // 🎯 إضافة صفحة السلة

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
  bool _isFavorite = false;
  bool _isDescriptionExpanded = false;

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
    _selectedColorId = 'none'; // 🎯 اختيار "لا شيء" افتراضياً
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

  // 📌 تثبيت السعر
  void _pinPrice() {
    if (_isPriceValid && !_pinnedPrices.contains(_customerPrice)) {
      setState(() {
        _pinnedPrices.add(_customerPrice);
      });

      HapticFeedback.mediumImpact();
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

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppDesignSystem.primaryBackground : Colors.white, // 🎯 خلفية متكيفة
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppDesignSystem.goldColor),
              const SizedBox(height: 20),
              Text(
                'جاري تحميل المنتج...',
                style: GoogleFonts.cairo(
                  color: isDark ? Colors.white : Colors.black, // 🎯 لون متكيف
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white, // 🎯 خلفية بيضاء في الوضع النهاري
      extendBody: true, // إزالة الشريط الأسود
      body: Stack(
        children: [
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
                    // منطقة الصورة الأنيقة
                    _buildElegantImageSection(),

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

          // 🛒 زر إضافة للسلة الثابت في الأسفل - خارج المحتوى
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      (isDark ? Colors.black : Colors.white).withValues(alpha: 0.0),
                      (isDark ? Colors.black : Colors.white).withValues(alpha: 0.95),
                      (isDark ? Colors.black : Colors.white),
                    ],
                  ),
                ),
                child: _buildAddToCartButton(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🎨 منطقة الصورة النظيفة بدون مربع
  Widget _buildElegantImageSection() {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode; // 🎯 تحديد الوضع
    final images = _getImagesList();

    return Container(
      height: 320, // تكبير الصورة قليلاً
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // الصورة الرئيسية - نظيفة وبسيطة
          Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: PageView.builder(
                controller: _imagePageController,
                onPageChanged: (index) {
                  setState(() => _currentImageIndex = index);
                  HapticFeedback.selectionClick();
                },
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      // ظل بسيط أسفل المنتج
                      Positioned(
                        bottom: 60,
                        left: 60,
                        right: 60,
                        child: Container(
                          height: 20,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.3),
                                Colors.black.withValues(alpha: 0.1),
                                Colors.transparent,
                              ],
                              stops: [0.0, 0.6, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),

                      // الصورة النظيفة
                      Center(
                        child: SizedBox(
                          width: 500,
                          height: 500,
                          child: CachedNetworkImage(
                            imageUrl: images[index],
                            fit: BoxFit.contain,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(color: const Color(0xFFD4AF37), strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.white.withValues(alpha: 0.3),
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // مؤشر الصور البسيط
          if (images.length > 1)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (index) => GestureDetector(
                    onTap: () {
                      _imagePageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentImageIndex == index ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _currentImageIndex == index
                            ? const Color(0xFFD4AF37)
                            : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // زر الرجوع في الأعلى على اليمين
          Positioned(
            top: 10,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withValues(alpha: 0.6) : Colors.white, // 🎯 خلفية بيضاء في الوضع النهاري
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.3), // 🎯 حدود ذهبية خفيفة
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: isDark ? Colors.white : Colors.black, // 🎯 لون متكيف
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 الكرة العائمة - استجابة كاملة 100% بدون تداخل

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

                  // شريط الألوان والكمية المدمج
                  _buildColorAndQuantityBar(),

                  const SizedBox(height: 28),

                  // السعر
                  _buildPriceDisplay(),

                  const SizedBox(height: 24),

                  // الوصف
                  _buildDescription(),

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

  // 🎨🔢 شريط الألوان والكمية المدمج - متناسق مع الخلفية الخرافية
  Widget _buildColorAndQuantityBar() {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode; // 🎯 تحديد الوضع
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white, // 🎯 خلفية بيضاء في الوضع النهاري
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.3), // 🎯 حدود ذهبية خفيفة
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.2), // 🎯 ظل أوضح في الوضع النهاري
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // قسم الألوان
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.palette, color: const Color(0xFFD4AF37), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'اللون',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black, // 🎯 لون متكيف
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // 🎯 خيار "لا شيء" كأول خيار
                      GestureDetector(
                        onTap: () {
                          setState(() => _selectedColorId = 'none');
                          HapticFeedback.selectionClick();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedColorId == 'none'
                                  ? const Color(0xFFD4AF37)
                                  : Colors.grey.withValues(alpha: 0.5),
                              width: _selectedColorId == 'none' ? 2.5 : 1.5,
                            ),
                            boxShadow: !isDark
                                ? [BoxShadow(color: Colors.grey.withValues(alpha: 0.3), blurRadius: 4, spreadRadius: 0)]
                                : null,
                          ),
                          child: Stack(
                            children: [
                              // دائرة حمراء في الوسط
                              Center(
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.red, width: 2),
                                  ),
                                ),
                              ),
                              // خط أحمر قطري
                              Center(
                                child: Transform.rotate(
                                  angle: -0.785398, // -45 degrees
                                  child: Container(width: 20, height: 2, color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 🎨 الألوان من قاعدة البيانات
                      ..._productColors.map((colorData) {
                        final isSelected = _selectedColorId == colorData.id;
                        final color = colorData.flutterColor;

                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedColorId = colorData.id);
                            HapticFeedback.selectionClick();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFD4AF37)
                                    : (color == Colors.white
                                          ? Colors.grey.withValues(alpha: 0.5)
                                          : Colors.white.withValues(alpha: 0.2)),
                                width: isSelected ? 2.5 : 1.5,
                              ),
                              boxShadow: color == Colors.white && !isDark
                                  ? [
                                      BoxShadow(
                                        color: Colors.grey.withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        spreadRadius: 0,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isSelected ? Icon(Icons.check, color: colorData.textColor, size: 16) : null,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // خط فاصل رفيع
          Container(
            width: 1,
            height: 60,
            color: Colors.white.withValues(alpha: 0.2),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),

          // قسم الكمية
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2, color: const Color(0xFFD4AF37), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'الكمية',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black, // 🎯 لون متكيف
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 🎯 زر النقصان - سريع الاستجابة
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (_selectedQuantity > 1) {
                            setState(() => _selectedQuantity--);
                            HapticFeedback.selectionClick();
                          }
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _selectedQuantity > 1
                                ? const Color(0xFFFFD700).withValues(alpha: 0.15)
                                : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3), width: 1),
                          ),
                          child: Icon(
                            Icons.remove,
                            color: _selectedQuantity > 1
                                ? (isDark ? Colors.white : Colors.black)
                                : (isDark ? Colors.white.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.5)),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '$_selectedQuantity',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD4AF37),
                        ),
                      ),
                    ),
                    // 🎯 زر الزيادة - سريع الاستجابة
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (_selectedQuantity < 10) {
                            setState(() => _selectedQuantity++);
                            HapticFeedback.selectionClick();
                          }
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _selectedQuantity < 10
                                ? const Color(0xFFFFD700).withValues(alpha: 0.15)
                                : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3), width: 1),
                          ),
                          child: Icon(
                            Icons.add,
                            color: _selectedQuantity < 10
                                ? (isDark ? Colors.white : Colors.black)
                                : (isDark ? Colors.white.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.5)),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 💰 عرض السعر الأنيق مع إمكانية التعديل
  Widget _buildPriceDisplay() {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode; // 🎯 تحديد الوضع
    final minPrice = _productData?['min_price']?.toDouble() ?? 0;
    final maxPrice = _productData?['max_price']?.toDouble() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // نطاق الأسعار المسموح - متناسق مع الخلفية الخرافية
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white, // 🎯 خلفية بيضاء في الوضع النهاري
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFFD700).withValues(alpha: 0.3), // 🎯 حدود ذهبية خفيفة
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.2), // 🎯 ظل أوضح في الوضع النهاري
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // سعر الجملة في الأعلى
              Row(
                children: [
                  Icon(Icons.inventory_2, color: const Color(0xFF4CAF50), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'سعر الجملة: ',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.black.withValues(alpha: 0.7), // 🎯 لون متكيف
                    ),
                  ),
                  Text(
                    NumberFormatter.formatCurrency((_productData?['wholesale_price'] ?? 0).toDouble()),
                    style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF4CAF50)),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  // الحد الأدنى
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3), width: 1),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_downward, color: const Color(0xFFFFD700), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'الحد الأدنى',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: const Color(0xFFFFD700),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            NumberFormatter.formatCurrency(minPrice),
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black, // 🎯 لون متكيف
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // الحد الأعلى
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90E2).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF4A90E2).withValues(alpha: 0.3), width: 1),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_upward, color: const Color(0xFF4A90E2), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'الحد الأعلى',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: const Color(0xFF4A90E2),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            NumberFormatter.formatCurrency(maxPrice),
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black, // 🎯 لون متكيف
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Text(
          'سعر البيع للزبون',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black, // 🎯 لون متكيف
          ),
        ),
        const SizedBox(height: 12),

        // حقل إدخال السعر مع زر التثبيت
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white, // 🎯 خلفية بيضاء في الوضع النهاري
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _customerPrice == 0
                        ? const Color(0xFFFFD700).withValues(alpha: 0.3) // 🎯 ذهبي خفيف
                        : _isPriceValid
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFE53E3E),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.2), // 🎯 ظل أوضح في الوضع النهاري
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: false),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.cairo(
                    color: isDark ? Colors.white : Colors.black, // 🎯 لون متكيف
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'أدخل سعر البيع',
                    hintStyle: GoogleFonts.cairo(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.grey.withValues(alpha: 0.6), // 🎯 لون متكيف
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(Icons.attach_money, color: const Color(0xFFD4AF37), size: 20),
                    suffixText: 'د.ع',
                    suffixStyle: GoogleFonts.cairo(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.black.withValues(alpha: 0.7), // 🎯 لون متكيف
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  onChanged: (value) {
                    final price = double.tryParse(value) ?? 0;
                    setState(() {
                      _customerPrice = price;
                      _validatePrice();
                    });
                  },
                ),
              ),
            ),

            const SizedBox(width: 12),

            // زر تثبيت السعر
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _isPriceValid
                    ? const Color(0xFFFFD700)
                    : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white), // 🎯 خلفية بيضاء في الوضع النهاري
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.3), // 🎯 حدود ذهبية خفيفة
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2), // 🎯 ظل أوضح في الوضع النهاري
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _isPriceValid ? _pinPrice : null,
                  child: Center(
                    child: Icon(
                      Icons.push_pin,
                      color: _isPriceValid
                          ? Colors.black
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.3)
                                : Colors.grey.withValues(alpha: 0.5)), // 🎯 لون متكيف
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // مؤشر صحة السعر
        if (!_isPriceValid && _customerPrice > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'السعر يجب أن يكون بين ${NumberFormatter.formatCurrency(_productData!['min_price'])} و ${NumberFormatter.formatCurrency(_productData!['max_price'])}',
              style: GoogleFonts.cairo(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w500),
            ),
          ),

        const SizedBox(height: 16),

        // عرض الأسعار المثبتة
        if (_pinnedPrices.isNotEmpty) ...[
          Text(
            'الأسعار المثبتة',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _pinnedPrices.map((price) {
              return GestureDetector(
                onTap: () {
                  // استخدام السعر المثبت
                  setState(() {
                    _customerPrice = price;
                    _priceController.text = price.toStringAsFixed(0);
                    _validatePrice();
                  });
                  HapticFeedback.selectionClick();
                },
                onLongPress: () {
                  // حذف السعر المثبت
                  setState(() {
                    _pinnedPrices.remove(price);
                  });
                  HapticFeedback.heavyImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🗑️ تم حذف السعر المثبت', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _customerPrice == price
                        ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                        : const Color(0xFF4A90E2).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _customerPrice == price
                          ? const Color(0xFFFFD700)
                          : const Color(0xFF4A90E2).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.push_pin,
                        color: _customerPrice == price ? const Color(0xFFD4AF37) : Colors.white.withValues(alpha: 0.7),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        NumberFormatter.formatCurrency(price),
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _customerPrice == price ? const Color(0xFFD4AF37) : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // الربح المتوقع - مربع صغير
        if (_isPriceValid && _customerPrice > 0)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E7B3A).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.trending_up, color: const Color(0xFF4CAF50), size: 14),
                const SizedBox(width: 6),
                Text(
                  'ربح: ${NumberFormatter.formatCurrency((_customerPrice - (_productData!['wholesale_price'] ?? 0)) * _selectedQuantity)}',
                  style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF4CAF50)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // 🛒 زر إضافة للسلة الأنيق
  Widget _buildAddToCartButton() {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode; // 🎯 تحديد الوضع
    final isEnabled = _isPriceValid && _customerPrice > 0;

    return Container(
      width: double.infinity,
      height: 48, // 🎯 حجم أصغر
      decoration: BoxDecoration(
        color: isEnabled
            ? const Color(0xFFFFD700)
            : (isDark
                  ? const Color(0xFF4A90E2).withValues(alpha: 0.3)
                  : Colors.white), // 🎯 خلفية بيضاء في الوضع النهاري
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.3), // 🎯 حدود ذهبية خفيفة
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.2), // 🎯 ظل أوضح في الوضع النهاري
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isEnabled
              ? () {
                  HapticFeedback.heavyImpact();
                  _addToCart();
                }
              : null,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  color: isEnabled
                      ? Colors.black
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.grey.withValues(alpha: 0.6)), // 🎯 لون متكيف
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isEnabled ? 'إضافة للسلة' : 'أدخل سعر صحيح',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isEnabled
                        ? Colors.black
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.grey.withValues(alpha: 0.6)), // 🎯 لون متكيف
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔗 استخراج الروابط من النص مع تسمية تلقائية ذكية
  List<Map<String, String>> _extractLinks(String text) {
    final List<Map<String, String>> links = [];
    final RegExp urlPattern = RegExp(r'(https?://[^\s]+)', caseSensitive: false);

    final matches = urlPattern.allMatches(text);
    int linkCounter = 1;

    for (final match in matches) {
      final url = match.group(0)!;

      // تسمية تلقائية: "رابط الفيديو الأول"، "رابط الفيديو الثاني"، إلخ
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

  // 🔗 إزالة الروابط من النص لإظهار الوصف نظيفاً
  String _removeLinksFromText(String text) {
    final RegExp urlPattern = RegExp(r'(https?://[^\s]+)', caseSensitive: false);

    // إزالة الروابط والسطر الذي يحتوي عليها
    String cleanText = text;
    final lines = text.split('\n');
    final cleanLines = <String>[];

    for (final line in lines) {
      // إذا كان السطر يحتوي على رابط، نتجاهله
      if (!urlPattern.hasMatch(line)) {
        cleanLines.add(line);
      }
    }

    cleanText = cleanLines.join('\n').trim();

    return cleanText;
  }

  // 🔗 فتح الرابط
  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('لا يمكن فتح الرابط', style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 📝 الوصف المنعزل مع انيميشن
  Widget _buildDescription() {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode; // 🎯 تحديد الوضع
    final originalDescription = _productData?['description'] ?? 'وصف المنتج هنا...';
    final links = _extractLinks(originalDescription); // 🎯 استخراج الروابط
    final description = _removeLinksFromText(originalDescription); // 🎯 إزالة الروابط من النص
    final shortDescription = description.length > 80 ? '${description.substring(0, 80)}...' : description;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white, // 🎯 خلفية بيضاء في الوضع النهاري
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.3), // 🎯 حدود رمادية في الوضع النهاري
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // رأس الوصف مع زر التوسيع وزر النسخ
          GestureDetector(
            onTap: () {
              setState(() {
                _isDescriptionExpanded = !_isDescriptionExpanded;
              });
              HapticFeedback.selectionClick();
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.description, color: const Color(0xFFD4AF37), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'الوصف',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black, // 🎯 لون متكيف
                      ),
                    ),
                  ),
                  // زر النسخ
                  GestureDetector(
                    onTap: () => _copyDescription(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white, // 🎯 خلفية بيضاء في الوضع النهاري
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.3), // 🎯 حدود ذهبية خفيفة
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.2)
                                : Colors.grey.withValues(alpha: 0.2), // 🎯 ظل أوضح في الوضع النهاري
                            blurRadius: 8,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.copy, color: const Color(0xFFD4AF37), size: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // زر التوسيع
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.withValues(alpha: 0.1), // 🎯 خلفية خفيفة
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.grey.withValues(alpha: 0.3), // 🎯 حدود واضحة
                        width: 1,
                      ),
                    ),
                    child: AnimatedRotation(
                      turns: _isDescriptionExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.black.withValues(alpha: 0.7), // 🎯 لون متكيف
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // محتوى الوصف مع انيميشن
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isDescriptionExpanded ? null : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isDescriptionExpanded ? 1.0 : 0.0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الروابط في الأعلى
                    if (links.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : const Color(0xFFFFF9E6), // 🎯 خلفية صفراء خفيفة
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.link, color: const Color(0xFFD4AF37), size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'الروابط',
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...links.map(
                              (link) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: GestureDetector(
                                  onTap: () => _openUrl(link['url']!),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.open_in_new, color: const Color(0xFFD4AF37), size: 14),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            link['label']!,
                                            style: GoogleFonts.cairo(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: isDark ? Colors.white : Colors.black,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // نص الوصف
                    Text(
                      description,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.8)
                            : Colors.black.withValues(alpha: 0.8), // 🎯 لون متكيف
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // معاينة الروابط فقط عندما يكون مطوياً - قابل للنقر
          if (!_isDescriptionExpanded && links.isNotEmpty)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isDescriptionExpanded = true;
                });
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFFFF9E6), // 🎯 خلفية صفراء خفيفة
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.link, color: const Color(0xFFD4AF37), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'الروابط',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${links.length} ${links.length == 1 ? 'رابط' : 'روابط'}',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...links
                          .take(2)
                          .map(
                            (link) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GestureDetector(
                                onTap: () => _openUrl(link['url']!),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4), width: 1),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.open_in_new, color: const Color(0xFFD4AF37), size: 14),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          link['label']!,
                                          style: GoogleFonts.cairo(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: isDark ? Colors.white : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      if (links.length > 2)
                        Text(
                          '... و ${links.length - 2} ${links.length - 2 == 1 ? 'رابط آخر' : 'روابط أخرى'}',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // معاينة الوصف عندما يكون مطوياً ولا توجد روابط
          if (!_isDescriptionExpanded && links.isEmpty)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isDescriptionExpanded = true;
                });
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  shortDescription,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.6), // 🎯 لون متكيف
                    height: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
