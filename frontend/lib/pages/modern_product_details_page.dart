// 🎨 صفحة تفاصيل المنتج الأنيقة والمرتبة
// Elegant Product Details Page with Beautiful Design

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

import '../core/design_system.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/favorites_service.dart';
import '../utils/number_formatter.dart';
import '../widgets/common_header.dart';

class ModernProductDetailsPage extends StatefulWidget {
  final String productId;

  const ModernProductDetailsPage({
    super.key,
    required this.productId,
  });

  @override
  State<ModernProductDetailsPage> createState() => _ModernProductDetailsPageState();
}

class _ModernProductDetailsPageState extends State<ModernProductDetailsPage>
    with TickerProviderStateMixin {

  // Controllers & Animation
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  // Page Controllers
  final PageController _imagePageController = PageController();
  final TextEditingController _priceController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Services
  final FavoritesService _favoritesService = FavoritesService.instance;

  // State Variables
  Map<String, dynamic>? _productData;
  bool _isLoading = true;
  int _currentImageIndex = 0;
  double _customerPrice = 0;
  bool _isPriceValid = false;
  String? _selectedColor;
  int _selectedQuantity = 1;
  bool _isFavorite = false;
  bool _isDescriptionExpanded = false;
  bool _showActionButtons = false; // حالة إظهار أزرار الإجراءات
  bool _showActionBalls = false; // حالة إظهار الكرات المنبثقة
  final List<double> _pinnedPrices = []; // قائمة الأسعار المثبتة

  // Colors for product variants
  final List<Map<String, dynamic>> _productColors = [
    {'name': 'أسود', 'color': Colors.black, 'code': '#000000'},
    {'name': 'برتقالي', 'color': Colors.orange, 'code': '#FF9500'},
    {'name': 'أبيض', 'color': Colors.white, 'code': '#FFFFFF'},
    {'name': 'أزرق فيروزي', 'color': Colors.teal, 'code': '#009688'},
    {'name': 'أحمر', 'color': Colors.red, 'code': '#F44336'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadProductData();
    _loadFavorites();
    _selectedColor = _productColors.first['name'];
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
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _floatAnimation = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadProductData() async {
    try {
      final response = await Supabase.instance.client
          .from('products')
          .select()
          .eq('id', widget.productId)
          .single();

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
          'images': [
            '',
            '',
            '',
            '',
          ],
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

    // Add to cart logic here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم إضافة المنتج للسلة بنجاح!',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _copyDescription() {
    if (_productData != null && _productData!['description'] != null) {
      Clipboard.setData(ClipboardData(text: _productData!['description']));
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم نسخ الوصف بنجاح!',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppDesignSystem.goldColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _floatController.dispose();
    _imagePageController.dispose();
    _priceController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppDesignSystem.primaryBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppDesignSystem.goldColor),
              const SizedBox(height: 20),
              Text(
                'جاري تحميل المنتج...',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // خلفية هادئة
      floatingActionButton: _buildFloatingCartButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      extendBody: true, // إزالة الشريط الأسود
      body: SafeArea(
        bottom: false, // إزالة SafeArea من الأسفل
        child: Column(
          children: [
            // Header أنيق وبسيط
            _buildCleanHeader(),

            // المحتوى الرئيسي
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      const SizedBox(height: 10), // تقليل المسافة العلوية

                      // منطقة الصورة الأنيقة
                      _buildElegantImageSection(),

                      const SizedBox(height: 5), // تقليل المسافة بين الصورة والإطار

                      // تفاصيل المنتج في container أنيق
                      _buildProductDetailsCard(),

                      const SizedBox(height: 20), // تقليل المسافة من 100 إلى 20
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🎨 Header أنيق وبسيط
  Widget _buildCleanHeader() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // زر الرجوع أنيق
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),

          // زر المشاركة فقط
          GestureDetector(
            onTap: () => HapticFeedback.lightImpact(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.share_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🎨 منطقة الصورة النظيفة والمرتبة
  Widget _buildElegantImageSection() {
    final images = _getImagesList();

    return Container(
      height: 280, // تقليل الارتفاع
      color: Colors.transparent,
      child: Stack(
        children: [
          // الصورة الرئيسية - نظيفة وبسيطة
          Center(
            child: Container(
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
                  return Container(
                    child: Stack(
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
                          child: Container(
                            width: 280,
                            height: 280,
                            child: CachedNetworkImage(
                              imageUrl: images[index],
                              fit: BoxFit.contain,
                              placeholder: (context, url) => Center(
                                child: CircularProgressIndicator(
                                  color: const Color(0xFFD4AF37),
                                  strokeWidth: 2,
                                ),
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
                    ),
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
        ],
      ),
    );
  }

  // 🎯 الكرة العائمة - استجابة كاملة 100% بدون تداخل
  Widget _buildFloatingBall() {
    return GestureDetector(
      onTap: () {
        // تفعيل/إخفاء الكرات المنبثقة
        if (!mounted) return;

        HapticFeedback.lightImpact();
        setState(() {
          _showActionBalls = !_showActionBalls;
        });
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF363940),
              Color(0xFF2D3748),
              Color(0xFF1A202C),
            ],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: _isFavorite ? Colors.red : const Color(0xFFFFD700),
            width: _isFavorite ? 4.0 : 3.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: (_isFavorite ? Colors.red : const Color(0xFFFFD700)).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 0),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            _isFavorite ? Icons.favorite : Icons.apps,
            color: _isFavorite ? Colors.red : const Color(0xFFFFD700),
            size: _isFavorite ? 32 : 28,
          ),
        ),
      ),
    );
  }

  // 🎯 كرة الإجراءات المنبثقة - ذكية ومميزة حسب الحالة
  Widget _buildActionBall({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    // تحديد خصائص كرة القلب حسب حالة المفضلة
    bool isHeartBall = icon == Icons.favorite;
    bool isActive = isHeartBall ? _isFavorite : false;

    // ألوان مخصصة لكل كرة
    Color ballColor;
    Color iconColor;
    Color borderColor;

    if (isHeartBall) {
      // كرة القلب - تمييز واضح حسب الحالة
      ballColor = isActive ? Colors.red.withValues(alpha: 0.9) : const Color(0xFF2A2A2A);
      iconColor = isActive ? Colors.white : Colors.red;
      borderColor = isActive ? Colors.red : Colors.red.withValues(alpha: 0.5);
    } else if (icon == Icons.photo_camera) {
      // كرة الكاميرا
      ballColor = const Color(0xFF2A2A2A);
      iconColor = Colors.blue;
      borderColor = const Color(0xFFFFD700);
    } else {
      // كرة المعرض
      ballColor = const Color(0xFF2A2A2A);
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
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
              // إخفاء الكرات بعد النقر
              setState(() {
                _showActionBalls = false;
              });
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ballColor,
                    ballColor.withValues(alpha: 0.8),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor,
                  width: isActive ? 3.0 : 2.0, // حدود أكثر سمكاً للحالة النشطة
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
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
              child: Icon(
                isHeartBall && isActive ? Icons.favorite : icon,
                color: iconColor,
                size: isActive ? 28 : 24, // حجم أكبر للحالة النشطة
              ),
            ),
          ),
        );
      },
    );
  }

  // 🎨 تحديد لون الأيقونة حسب النوع
  Color _getIconColor(IconData icon) {
    if (icon == Icons.favorite) {
      return Colors.red;
    } else if (icon == Icons.photo_camera) {
      return Colors.blue;
    } else {
      return Colors.green;
    }
  }

  // 🎯 نفس تصميم CurvedNavigationBar بالضبط!
  Widget _buildCurvedBallSection() {
    return SizedBox(
      width: 80,
      height: 70,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // القوس المقطوع بنفس كود CurvedNavigationBar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomPaint(
              painter: _NavCustomPainter(0.5, 1, const Color(0xFFD4AF37), TextDirection.ltr),
              child: Container(
                height: 70.0,
                color: Colors.transparent,
              ),
            ),
          ),

          // الكرة بنفس تصميم CurvedNavigationBar بالضبط!
          Positioned(
            bottom: -45,
            left: 0,
            width: 80,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  // تفعيل الكرة
                  HapticFeedback.lightImpact();
                },
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  tween: Tween(begin: 0.8, end: 1.0),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeInOutCubic,
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFF363940),
                                  Color(0xFF2D3748),
                                  Color(0xFF1A202C),
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFFD700),
                                width: 3.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                  spreadRadius: 2,
                                ),
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 0),
                                  spreadRadius: 1,
                                ),
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                                  blurRadius: 30,
                                  offset: const Offset(0, 0),
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          const Color(0xFFFFD700).withValues(alpha: 0.1),
                                          Colors.transparent,
                                        ],
                                        stops: const [0.3, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                                Center(
                                  child: AnimatedScale(
                                    duration: const Duration(milliseconds: 400),
                                    scale: 1.0,
                                    child: AnimatedRotation(
                                      duration: const Duration(milliseconds: 800),
                                      turns: 0.0,
                                      child: IconTheme(
                                        data: const IconThemeData(
                                          color: Color(0xFFFFD700),
                                          size: 28,
                                        ),
                                        child: const Icon(Icons.apps), // أيقونة المربعات
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // أزرار الإجراءات المنبثقة
          if (_showActionButtons)
            Positioned(
              left: 85,
              top: -10,
              child: _buildActionButtons(),
            ),
        ],
      ),
    );
  }

  // 🎬 أزرار الإجراءات المنبثقة
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // زر القلب
          _buildActionButton(
            icon: Icons.favorite_border,
            onTap: () => _toggleFavorite(),
            tooltip: 'إضافة للمفضلة',
          ),

          const SizedBox(width: 8),

          // زر حفظ صورة واحدة
          _buildActionButton(
            icon: Icons.photo_camera,
            onTap: () => _saveCurrentImage(),
            tooltip: 'حفظ الصورة الحالية',
          ),

          const SizedBox(width: 8),

          // زر حفظ كل الصور
          _buildActionButton(
            icon: Icons.photo_library,
            onTap: () => _saveAllImages(),
            tooltip: 'حفظ كل الصور',
          ),
        ],
      ),
    );
  }

  // 🎯 زر إجراء واحد
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return GestureDetector(
      onTap: () {
        onTap();
        // تم النقر على الزر
        HapticFeedback.lightImpact();
      },
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFD4AF37),
            size: 16,
          ),
        ),
      ),
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

      final wasLiked = _isFavorite;
      final success = await _favoritesService.toggleFavorite(product);

      if (success && mounted) {
        setState(() {
          _isFavorite = _favoritesService.isFavorite(widget.productId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorite ? 'تم إضافة المنتج للمفضلة ❤️' : 'تم إزالة المنتج من المفضلة 💔',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
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
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
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
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حفظ $savedCount من ${images.length} صور في الاستوديو ✅',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل في حفظ الصور: $e',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
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
      // طلب الصلاحيات
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('لا توجد صلاحية للوصول للتخزين');
      }

      // تحميل الصورة
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('فشل في تحميل الصورة');
      }

      // حفظ الصورة في الاستوديو
      final result = await ImageGallerySaver.saveImage(
        response.bodyBytes,
        name: fileName,
        quality: 100,
      );

      if (result['isSuccess'] != true) {
        throw Exception('فشل في حفظ الصورة في الاستوديو');
      }

      debugPrint('✅ تم حفظ الصورة: $fileName');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ الصورة: $e');
      rethrow;
    }
  }

  // 📋 كارت تفاصيل المنتج الأنيق مع قوس عميق
  Widget _buildProductDetailsCard() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // الجزء الرصاصي الأساسي
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 0),
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 0), // زيادة المسافة العلوية
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(50), // قوس عميق
              topRight: Radius.circular(50), // قوس عميق
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // اسم المنتج فقط (بدون مجسم)
              Text(
                _productData?['name'] ?? 'اسم المنتج',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 16),

              const SizedBox(height: 24),

              // شريط الألوان والكمية المدمج
              _buildColorAndQuantityBar(),

              const SizedBox(height: 28),

              // السعر
              _buildPriceDisplay(),

              const SizedBox(height: 24),

              // الوصف
              _buildDescription(),

              // مساحة إضافية لتجنب تداخل الزر العائم
              const SizedBox(height: 30), // تقليل المسافة من 100 إلى 30
            ],
          ),
        ),

        // الكرة في الأعلى بين الجزء الرصاصي والأسود (الجهة اليسرى)
        Positioned(
          top: -30, // في الأعلى بين الجزأين
          left: 40, // سحب الكرة إلى اليمين قليلاً
          child: _buildFloatingBall(),
        ),

        // الكرات المنبثقة عند النقر - نفس مواقع الكرات البيضاء في الصورة المرجعية
        if (_showActionBalls) ...[
          // كرة حفظ المنتج (قلب) - أعلى يمين الكرة الأصلية
          Positioned(
            top: -60, // مسافة موحدة 80 بكسل من الكرة الرئيسية
            left: 110, // مسافة موحدة 120 بكسل من الكرة الرئيسية
            child: _buildActionBall(
              icon: Icons.favorite,
              color: const Color(0xFF2A2A2A), // سيتم تجاهله واستخدام اللون الذكي
              onTap: _toggleFavorite,
            ),
          ),

          // كرة حفظ الصورة الحالية - فوق الكرة الأصلية مائلة لليمين
          Positioned(
            top: -90, // مسافة موحدة 120 بكسل أعلى (فرق 40 بكسل من القلب)
            left: 60, // مسافة موحدة 80 بكسل يمين (فرق 40 بكسل من القلب)
            child: _buildActionBall(
              icon: Icons.photo_camera,
              color: const Color(0xFF2A2A2A),
              onTap: _saveCurrentImage,
            ),
          ),

          // كرة حفظ كل الصور - أسفل يمين الكرة الأصلية
          Positioned(
            top: -0, // مسافة موحدة 40 بكسل أعلى (فرق 40 بكسل من القلب)
            left: 115, // مسافة موحدة 120 بكسل يمين (نفس القلب)
            child: _buildActionBall(
              icon: Icons.photo_library,
              color: const Color(0xFF2A2A2A),
              onTap: _saveAllImages,
            ),
          ),
        ],

      ],
    );
  }

  // 🖼️ عارض الصور الأنيق مثل Nike
  Widget _buildProductImageViewer() {
    final images = _getImagesList();

    return Container(
      height: 450,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Stack(
        children: [
          // الصورة الرئيسية تطفو فوق قوس بيضوي
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
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: CachedNetworkImage(
                        imageUrl: images[index],
                        fit: BoxFit.contain,
                      ),
                    );
                  },
                ),
              ),
            ),

          // قوس بيضوي يحيط بالمنتج مع مؤشر صغير
          Positioned(
            bottom: 72,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 320,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // القوس المرسوم
                    CustomPaint(
                      size: const Size(320, 120),
                      painter: _ArcRingPainter(color: AppDesignSystem.goldColor),
                    ),
                    // مؤشر صغير في منتصف القوس
                    Container(
                      width: 34,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppDesignSystem.goldColor.withValues(alpha: 0.6),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppDesignSystem.goldColor.withValues(alpha: 0.25),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (_currentImageIndex > 0) {
                                _imagePageController.previousPage(
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            child: Icon(Icons.chevron_left, size: 12, color: AppDesignSystem.goldColor),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (_currentImageIndex < images.length - 1) {
                                _imagePageController.nextPage(
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            child: Icon(Icons.chevron_right, size: 12, color: AppDesignSystem.goldColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // النقاط الملونة تحت المنصة مثل Nike
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildColorDot(Colors.orange, true),
                const SizedBox(width: 8),
                _buildColorDot(Colors.blue, false),
                const SizedBox(width: 8),
                _buildColorDot(Colors.grey, false),
                const SizedBox(width: 8),
                _buildColorDot(Colors.green, false),
                const SizedBox(width: 8),
                _buildColorDot(Colors.red, false),
              ],
            ),
          ),

          // مؤشر الصور الأنيق في الأسفل
          if (images.length > 1)
            Positioned(
              bottom: -15,
              left: 0,
              right: 0,
              child: Container(
                height: 50,
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
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentImageIndex == index ? 12 : 8,
                        height: _currentImageIndex == index ? 12 : 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentImageIndex == index
                              ? AppDesignSystem.goldColor
                              : AppDesignSystem.goldColor.withValues(alpha: 0.3),
                          boxShadow: _currentImageIndex == index
                              ? [
                                  BoxShadow(
                                    color: AppDesignSystem.goldColor.withValues(alpha: 0.6),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // عداد الصور الأنيق في الزاوية
          if (images.length > 1)
            Positioned(
              top: 25,
              right: 25,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: AppDesignSystem.goldColor.withValues(alpha: 0.4),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${_currentImageIndex + 1} / ${images.length}',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // أزرار التنقل الجانبية
          if (images.length > 1) ...[
            // زر السابق
            Positioned(
              left: 15,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_currentImageIndex > 0) {
                      _imagePageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.6),
                      border: Border.all(
                        color: AppDesignSystem.goldColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_back_ios,
                      color: _currentImageIndex > 0
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),

            // زر التالي
            Positioned(
              right: 15,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_currentImageIndex < images.length - 1) {
                      _imagePageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.6),
                      border: Border.all(
                        color: AppDesignSystem.goldColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: _currentImageIndex < images.length - 1
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),


    );
  }

  // 🏆 عنوان المنتج المبهر في الوسط
  Widget _buildProductTitle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        children: [
          // اسم المنتج مع تأثير متدرج
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppDesignSystem.goldColor.withValues(alpha: 0.15),
                  AppDesignSystem.goldColor.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppDesignSystem.goldColor.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppDesignSystem.goldColor.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // اسم المنتج
                Text(
                  _productData!['name'] ?? 'منتج بدون اسم',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.3,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 12),

                // خط فاصل ذهبي
                Container(
                  width: 60,
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppDesignSystem.goldColor,
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                const SizedBox(height: 12),

                // الفئة
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppDesignSystem.goldColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: AppDesignSystem.goldColor.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _productData!['category'] ?? 'عام',
                    style: GoogleFonts.cairo(
                      color: AppDesignSystem.goldColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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


  // 🎨🔢 شريط الألوان والكمية المدمج
  Widget _buildColorAndQuantityBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
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
                    Icon(
                      Icons.palette,
                      color: const Color(0xFFD4AF37),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'اللون',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 32,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _productColors.length,
                    itemBuilder: (context, index) {
                      final colorData = _productColors[index];
                      final isSelected = _selectedColor == colorData['name'];
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedColor = colorData['name']);
                          HapticFeedback.selectionClick();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: colorData['color'],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFD4AF37)
                                  : Colors.white.withValues(alpha: 0.2),
                              width: isSelected ? 2.5 : 1,
                            ),
                          ),
                          child: isSelected ? Icon(
                            Icons.check,
                            color: colorData['color'] == Colors.white ? Colors.black : Colors.white,
                            size: 16,
                          ) : null,
                        ),
                      );
                    },
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
                    Icon(
                      Icons.inventory_2,
                      color: const Color(0xFFD4AF37),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'الكمية',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_selectedQuantity > 1) {
                          setState(() => _selectedQuantity--);
                          HapticFeedback.selectionClick();
                        }
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _selectedQuantity > 1
                              ? const Color(0xFF3A3A3A)
                              : const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.remove,
                          color: _selectedQuantity > 1
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.3),
                          size: 16,
                        ),
                      ),
                    ),
                    Container(
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
                    GestureDetector(
                      onTap: () {
                        setState(() => _selectedQuantity++);
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3A3A3A),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 16,
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

  // 🛒 زر السلة العائم الطويل
  Widget _buildFloatingCartButton() {
    final isEnabled = _isPriceValid && _customerPrice > 0;

    return Container(
      width: 200,
      height: 55,
      decoration: BoxDecoration(
        color: isEnabled
            ? const Color(0xFFD4AF37)
            : Colors.grey.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: isEnabled
                ? const Color(0xFFD4AF37).withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.2),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: isEnabled ? _addToCart : null,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  color: isEnabled ? Colors.black : Colors.white.withValues(alpha: 0.5),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'إضافة للسلة',
                  style: GoogleFonts.cairo(
                    color: isEnabled ? Colors.black : Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🎨 اختيار الألوان الأنيق
  Widget _buildColorSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اللون',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _productColors.take(5).map((colorData) {
            final isSelected = _selectedColor == colorData['name'];
            return GestureDetector(
              onTap: () {
                setState(() => _selectedColor = colorData['name']);
                HapticFeedback.selectionClick();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorData['color'],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFD4AF37)
                        : Colors.white.withValues(alpha: 0.2),
                    width: isSelected ? 2.5 : 1,
                  ),
                ),
                child: isSelected ? Icon(
                  Icons.check,
                  color: colorData['color'] == Colors.white ? Colors.black : Colors.white,
                  size: 18,
                ) : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 💳 بطاقة سعر مدمجة
  Widget _buildCompactPriceCard(String label, dynamic price, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            NumberFormatter.formatCurrency(price ?? 0),
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppDesignSystem.goldColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppDesignSystem.goldColor.withValues(alpha: 0.5),
          ),
        ),
        child: Icon(
          icon,
          color: AppDesignSystem.goldColor,
          size: 16,
        ),
      ),
    );
  }

  // 💰 قسم الأسعار المحسن والمنظم
  Widget _buildPriceSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          // قسم عرض الأسعار المرجعية
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppDesignSystem.bottomNavColor.withValues(alpha: 0.8),
                  AppDesignSystem.bottomNavColor.withValues(alpha: 0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppDesignSystem.goldColor.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.chartLine,
                      color: AppDesignSystem.goldColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'الأسعار المرجعية',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppDesignSystem.goldColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildCompactPriceCard('جملة', _productData!['wholesale_price'], Colors.blue)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildCompactPriceCard('أدنى', _productData!['min_price'], Colors.green)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildCompactPriceCard('أقصى', _productData!['max_price'], Colors.red)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // قسم تحديد السعر
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppDesignSystem.goldColor.withValues(alpha: 0.15),
                  AppDesignSystem.goldColor.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppDesignSystem.goldColor.withValues(alpha: 0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppDesignSystem.goldColor.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // عنوان القسم
                Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.dollarSign,
                      color: AppDesignSystem.goldColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'تحديد سعر البيع',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppDesignSystem.goldColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: _isPriceValid
                    ? Colors.green
                    : AppDesignSystem.goldColor.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'أدخل السعر للعميل',
                hintStyle: GoogleFonts.cairo(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                prefixIcon: Icon(
                  FontAwesomeIcons.dollarSign,
                  color: AppDesignSystem.goldColor,
                  size: 18,
                ),
                suffixText: 'د.ع',
                suffixStyle: GoogleFonts.cairo(
                  color: AppDesignSystem.goldColor,
                  fontWeight: FontWeight.bold,
                ),
                border: InputBorder.none,
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

          // مؤشر صحة السعر
          if (!_isPriceValid && _customerPrice > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'السعر يجب أن يكون بين ${NumberFormatter.formatCurrency(_productData!['min_price'])} و ${NumberFormatter.formatCurrency(_productData!['max_price'])}',
                style: GoogleFonts.cairo(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),

          // حساب الربح
          if (_isPriceValid)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الربح المتوقع:',
                      style: GoogleFonts.cairo(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      NumberFormatter.formatCurrency(
                        (_customerPrice - (_productData!['wholesale_price'] ?? 0)) * _selectedQuantity,
                      ),
                      style: GoogleFonts.cairo(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, dynamic price, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: GoogleFonts.cairo(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
        Text(
          NumberFormatter.formatCurrency(price),
          style: GoogleFonts.cairo(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }



  // 📝 قسم الوصف القابل للطي مع زر النسخ
  Widget _buildProductDescription() {
    final description = _productData!['description'] ?? 'وصف المنتج غير متوفر';
    final shortDescription = description.length > 100
        ? '${description.substring(0, 100)}...'
        : description;

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppDesignSystem.bottomNavColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس القسم مع زر النسخ
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppDesignSystem.goldColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(
                  color: AppDesignSystem.goldColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.fileText,
                      color: AppDesignSystem.goldColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'وصف المنتج',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                // زر النسخ
                GestureDetector(
                  onTap: _copyDescription,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppDesignSystem.goldColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppDesignSystem.goldColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Icon(
                      FontAwesomeIcons.copy,
                      color: AppDesignSystem.goldColor,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // محتوى الوصف
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isDescriptionExpanded ? description : shortDescription,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.6,
                  ),
                ),

                if (description.length > 100) ...[
                  const SizedBox(height: 16),

                  // زر التوسيع/الطي
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isDescriptionExpanded = !_isDescriptionExpanded;
                      });
                      HapticFeedback.lightImpact();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppDesignSystem.goldColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppDesignSystem.goldColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isDescriptionExpanded ? 'إخفاء التفاصيل' : 'عرض المزيد',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: AppDesignSystem.goldColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          AnimatedRotation(
                            turns: _isDescriptionExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              color: AppDesignSystem.goldColor,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🎨 بناء النقطة الملونة مثل Nike
  Widget _buildColorDot(Color color, bool isSelected) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        // يمكن إضافة منطق تغيير اللون هنا
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isSelected ? 16 : 12,
        height: isSelected ? 16 : 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ] : null,
        ),
      ),
    );
  }

  // 🎨 السعر والأزرار العصرية
  Widget _buildModernPriceAndActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // السعر مع تأثيرات
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppDesignSystem.goldColor.withValues(alpha: 0.1),
                AppDesignSystem.goldColor.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppDesignSystem.goldColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'السعر المقترح',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${NumberFormatter.formatCurrency(_customerPrice)}',
                    style: GoogleFonts.cairo(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppDesignSystem.goldColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ربح ${NumberFormatter.formatCurrency(_customerPrice - (_productData?['wholesale_price']?.toDouble() ?? 0))}',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // زر إضافة للسلة خرافي
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppDesignSystem.goldColor,
                AppDesignSystem.goldColor.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppDesignSystem.goldColor.withValues(alpha: 0.4),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () {
                HapticFeedback.heavyImpact();
                // إضافة للسلة
              },
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      color: Colors.black,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'إضافة للسلة',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 🔢 اختيار الكمية الأنيق
  Widget _buildQuantitySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الكمية',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                if (_selectedQuantity > 1) {
                  setState(() => _selectedQuantity--);
                  HapticFeedback.selectionClick();
                }
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _selectedQuantity > 1
                      ? const Color(0xFF3A3A3A)
                      : const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.remove,
                  color: _selectedQuantity > 1
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.3),
                  size: 18,
                ),
              ),
            ),
            Container(
              width: 60,
              child: Text(
                '$_selectedQuantity',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() => _selectedQuantity++);
                HapticFeedback.selectionClick();
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 💰 عرض السعر الأنيق مع إمكانية التعديل
  Widget _buildPriceDisplay() {
    final minPrice = _productData?['min_price']?.toDouble() ?? 0;
    final maxPrice = _productData?['max_price']?.toDouble() ?? 0;
    final wholesalePrice = _productData?['wholesale_price']?.toDouble() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [


        // نطاق الأسعار المسموح
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // سعر الجملة في الأعلى
              Row(
                children: [
                  Icon(
                    Icons.inventory_2,
                    color: const Color(0xFF4CAF50),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'سعر الجملة: ',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    NumberFormatter.formatCurrency((_productData?['wholesale_price'] ?? 0).toDouble()),
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4CAF50),
                    ),
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
                        color: const Color(0xFF3A3A3A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_downward,
                                color: Colors.orange,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'الحد الأدنى',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: Colors.orange,
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
                              color: Colors.white,
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
                        color: const Color(0xFF3A3A3A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_upward,
                                color: Colors.blue,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'الحد الأعلى',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: Colors.blue,
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
                              color: Colors.white,
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
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),

        // حقل إدخال السعر مع زر التثبيت
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _customerPrice == 0
                        ? const Color(0xFFD4AF37)
                        : _isPriceValid
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFE53E3E),
                    width: 2.5,
                  ),
                ),
                child: TextField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: false),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'أدخل سعر البيع',
                    hintStyle: GoogleFonts.cairo(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(
                      Icons.attach_money,
                      color: const Color(0xFFD4AF37),
                      size: 20,
                    ),
                    suffixText: 'د.ع',
                    suffixStyle: GoogleFonts.cairo(
                      color: Colors.white.withValues(alpha: 0.7),
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
                    ? const Color(0xFFD4AF37)
                    : const Color(0xFF3A3A3A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isPriceValid
                      ? const Color(0xFFD4AF37)
                      : Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
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
                          : Colors.white.withValues(alpha: 0.3),
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
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
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
                      content: Text(
                        '🗑️ تم حذف السعر المثبت',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
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
                        ? const Color(0xFFD4AF37).withValues(alpha: 0.3)
                        : const Color(0xFF3A3A3A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _customerPrice == price
                          ? const Color(0xFFD4AF37)
                          : Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.push_pin,
                        color: _customerPrice == price
                            ? const Color(0xFFD4AF37)
                            : Colors.white.withValues(alpha: 0.7),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        NumberFormatter.formatCurrency(price),
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _customerPrice == price
                              ? const Color(0xFFD4AF37)
                              : Colors.white,
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
              border: Border.all(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up,
                  color: const Color(0xFF4CAF50),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'ربح: ${NumberFormatter.formatCurrency((_customerPrice - (_productData!['wholesale_price'] ?? 0)) * _selectedQuantity)}',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // 🛒 زر إضافة للسلة الأنيق
  Widget _buildAddToCartButton() {
    final isEnabled = _isPriceValid && _customerPrice > 0;

    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: isEnabled
            ? const Color(0xFFD4AF37)
            : Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isEnabled ? () {
            HapticFeedback.heavyImpact();
            _addToCart();
          } : null,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  color: isEnabled ? Colors.black : Colors.white.withValues(alpha: 0.5),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isEnabled ? 'إضافة للسلة' : 'أدخل سعر صحيح',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isEnabled ? Colors.black : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 📝 الوصف المنعزل مع انيميشن
  Widget _buildDescription() {
    final description = _productData?['description'] ?? 'وصف المنتج هنا...';
    final shortDescription = description.length > 80
        ? '${description.substring(0, 80)}...'
        : description;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
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
                  Icon(
                    Icons.description,
                    color: const Color(0xFFD4AF37),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'الوصف',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // زر النسخ
                  GestureDetector(
                    onTap: () => _copyDescription(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A3A3A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.copy,
                        color: const Color(0xFFD4AF37),
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // زر التوسيع
                  AnimatedRotation(
                    turns: _isDescriptionExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 24,
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
                child: Text(
                  description,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ),

          // معاينة الوصف عندما يكون مطوياً
          if (!_isDescriptionExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                shortDescription,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }



}



// رسام قوس بيضوي أنيق يحيط بالمنتج
class _ArcRingPainter extends CustomPainter {
  final Color color;
  _ArcRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // مركز وبيضاوي القوس
    final center = Offset(size.width / 2, size.height * 0.62);
    final oval = Rect.fromCenter(
      center: center,
      width: size.width * 0.95,
      height: size.height * 1.05,
    );

    // زوايا القوس (يشبه Nike)
    final startAngle = math.pi + 0.25; // يبدأ من اليسار لأعلى قليلًا
    final sweepAngle = math.pi - 0.5;  // حتى اليمين مع تقليل بسيط للطرفين

    // ظل ناعم أسفل القوس
    final shadowPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawArc(oval, startAngle, sweepAngle, false, shadowPaint);

    // القوس الرئيسي
    final mainPaint = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(oval, startAngle, sweepAngle, false, mainPaint);

    // لمسة لمعان داخلية
    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final innerOval = oval.deflate(4);
    canvas.drawArc(innerOval, startAngle, sweepAngle, false, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _ArcRingPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

// 🎨 رسام القوس بنفس كود CurvedNavigationBar
class _NavCustomPainter extends CustomPainter {
  final double loc;
  final double s;
  final Color color;
  final TextDirection textDirection;

  _NavCustomPainter(this.loc, this.s, this.color, [this.textDirection = TextDirection.ltr]);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;
    final x = w * loc;

    // قوس مقلوب (مقطوع للأعلى) مثل الصورة
    path.moveTo(0, h);
    path.lineTo(x - 40, h);
    path.quadraticBezierTo(x - 20, h, x - 20, h - 20);
    path.quadraticBezierTo(x - 20, 0, x, 0);
    path.quadraticBezierTo(x + 20, 0, x + 20, h - 20);
    path.quadraticBezierTo(x + 20, h, x + 40, h);
    path.lineTo(w, h);
    path.lineTo(w, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}


