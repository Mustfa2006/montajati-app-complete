import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../models/product.dart';
import '../services/cart_service.dart';

class NewProductsPage extends StatefulWidget {
  const NewProductsPage({super.key});

  @override
  State<NewProductsPage> createState() => _NewProductsPageState();
}

class _NewProductsPageState extends State<NewProductsPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CartService _cartService = CartService();
  List<Product> _products = [];
  bool _isLoadingProducts = false;
  final Set<String> _likedProducts = <String>{}; // تتبع المنتجات المفضلة

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // دالة لتنسيق الأرقام بالفواصل
  String _formatPrice(double price) {
    final formatter = NumberFormat('#,###');
    return formatter.format(price.toInt());
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      final response = await _supabase
          .from('products')
          .select()
          .order('created_at', ascending: false);

      final products = (response as List)
          .map((json) => Product.fromJson(json))
          .toList();

      if (mounted) {
        setState(() {
          _products = products;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2125),
      body: SafeArea(
        child: Stack(
          children: [
            // المحتوى الرئيسي
            SingleChildScrollView(
              child: Column(
                children: [
                  // الشريط العلوي
                  _buildHeader(),
                  // البانر الرئيسي
                  _buildMainBanner(),
                  // عنوان Popular
                  _buildPopularTitle(),
                  // شبكة المنتجات
                  _buildProductsGrid(),
                  // مساحة إضافية للشريط السفلي
                  const SizedBox(height: 160),
                ],
              ),
            ),
            // شريط التنقل السفلي
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomNavigationBar(),
            ),
          ],
        ),
      ),
    );
  }

  // بناء الشريط العلوي
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'PixelsCo.',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
            ),
          ),
          GestureDetector(
            onTap: () {
              context.go('/cart');
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF6B7180),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // بناء البانر الرئيسي
  Widget _buildMainBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(25, 0, 25, 30),
      height: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B7180), Color(0xFF4A5058)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // النص
          Positioned(
            left: 30,
            top: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Vintage',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Collection',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    // التمرير إلى قسم المنتجات
                    Scrollable.ensureVisible(
                      context,
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Explore now',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // الصورة
          Positioned(
            right: 20,
            top: 20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  'https://images.unsplash.com/photo-1606983340126-99ab4feaa64a?w=300&h=300&fit=crop',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF6B7180),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 50,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // بناء عنوان Popular
  Widget _buildPopularTitle() {
    return Container(
      margin: const EdgeInsets.fromLTRB(25, 0, 25, 20),
      width: double.infinity,
      child: Text(
        'Popular',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.3,
        ),
      ),
    );
  }

  // بناء شبكة المنتجات
  Widget _buildProductsGrid() {
    if (_isLoadingProducts) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF6B7180),
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'لا توجد منتجات متاحة',
            style: GoogleFonts.cairo(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12), // تقليل المسافة الجانبية
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8, // تقليل المسافة بين البطاقات
          mainAxisSpacing: 16,
          childAspectRatio: 0.55, // تعديل النسبة للبطاقات الأطول
        ),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  // بناء بطاقة المنتج - تصميم ملفت ومبهر 🎨✨
  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        context.go('/products/details/${product.id}');
      },
      child: Container(
      width: MediaQuery.of(context).size.width * 0.47, // تكبير العرض
      height: 380, // تكبير الارتفاع
      margin: const EdgeInsets.only(right: 8, bottom: 16), // تقليل المسافة الجانبية
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF363940),
            Color(0xFF2D3748),
            Color(0x003D414B),
          ],
          stops: [0.0, 0.7, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF6B7180).withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          // تأثير الإضاءة المتحركة
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6B7180).withValues(alpha: 0.2),
                    const Color(0xFF4A5568).withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // تأثير إضاءة من الأسفل
          Positioned(
            left: -20,
            bottom: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.blue.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // زر القلب في الأعلى
          Positioned(
            right: 16,
            top: 16,
            child: _buildHeartButton(product),
          ),

          // عدد القطع في الأعلى اليسار - تصميم ملفت
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.withValues(alpha: 0.8),
                    Colors.green.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_2_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${product.availableFrom}-${product.availableTo}',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // منطقة الصورة الكبيرة مع تأثيرات
          Positioned(
            left: 12,
            top: 60,
            right: 12,
            child: Container(
              height: 220, // تكبير الصورة بشكل كبير
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // خلفية متدرجة خفيفة للصورة
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.05),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    // الصورة
                    product.images.isNotEmpty
                        ? Image.network(
                            product.images.first,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.white60,
                                  size: 50,
                                ),
                              );
                            },
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              color: Colors.white60,
                              size: 50,
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),

          // اسم المنتج تحت الصورة مباشرة
          Positioned(
            left: 12,
            right: 12,
            top: 290, // تحت الصورة مباشرة
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Text(
                product.name,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
                maxLines: 1, // سطر واحد فقط
                overflow: TextOverflow.ellipsis, // تحويل إلى ...
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // السعر وزر الإضافة في الأسفل
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // السعر مع تأثير هادئ
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.withValues(alpha: 0.6),
                          Colors.orange.withValues(alpha: 0.4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${_formatPrice(product.wholesalePrice)} د.ع',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  // زر الإضافة مع أنيميشن تحويل رائع
                  _buildAnimatedAddButton(product),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  // زر الإضافة المتحرك المحسن 🛒✨
  Widget _buildAnimatedAddButton(Product product) {
    // التحقق من وجود المنتج في السلة الحقيقية
    bool isInCart = _cartService.hasProduct(product.id);

    return GestureDetector(
      onTap: () async {
        if (!isInCart) {
          // تأثير اهتزاز خفيف
          HapticFeedback.lightImpact();

          // إضافة إلى السلة
          await _addToCart(product);

          // تحديث الحالة
          setState(() {});
        } else {
          // إزالة من السلة
          HapticFeedback.selectionClick();
          _cartService.removeItem(product.id);
          setState(() {});
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        width: isInCart ? 60 : 40,
        height: 36,
        decoration: BoxDecoration(
          gradient: isInCart
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4CAF50),
                    Color(0xFF45A049),
                    Color(0xFF388E3C),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6F757F),
                    Color(0xFF4A5568),
                    Color(0xFF2D3748),
                  ],
                ),
          borderRadius: BorderRadius.circular(isInCart ? 18 : 12),
          border: Border.all(
            color: isInCart
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isInCart
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.3),
              blurRadius: isInCart ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // أنيميشن مستمر للحالة المضافة
            if (isInCart)
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                ),
              ),

            // المحتوى الرئيسي
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: isInCart
                    ? Row(
                        key: const ValueKey('added'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'تم',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : const Icon(
                        key: ValueKey('add'),
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // زر القلب المتحرك الرهيب 💖
  Widget _buildHeartButton(Product product) {
    // تتبع حالة الإعجاب لكل منتج
    bool isLiked = _likedProducts.contains(product.id);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isLiked) {
            _likedProducts.remove(product.id);
          } else {
            _likedProducts.add(product.id);
          }
        });

        // تأثير اهتزاز
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: isLiked
              ? const LinearGradient(
                  colors: [
                    Color(0xFFFF6B6B),
                    Color(0xFFFF5252),
                    Color(0xFFE91E63),
                  ],
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isLiked
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isLiked
                  ? Colors.red.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.2),
              blurRadius: isLiked ? 15 : 8,
              offset: const Offset(0, 4),
            ),
            if (isLiked)
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.2),
                blurRadius: 25,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: AnimatedScale(
          scale: isLiked ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isLiked ? Colors.white : Colors.white70,
            size: isLiked ? 18 : 16,
          ),
        ),
      ),
    );
  }

  // بناء شريط التنقل السفلي
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D36),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: () {
              // الصفحة الحالية - لا حاجة للتنقل
            },
            child: _buildBottomNavIcon(Icons.home, true),
          ),
          GestureDetector(
            onTap: () {
              context.go('/favorites');
            },
            child: _buildBottomNavIcon(Icons.bookmark_border, false),
          ),
          GestureDetector(
            onTap: () {
              // الإشعارات - يمكن إضافة صفحة لاحقاً
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('صفحة الإشعارات قريباً')),
              );
            },
            child: _buildBottomNavIcon(Icons.notifications_none, false),
          ),
          GestureDetector(
            onTap: () {
              context.go('/account');
            },
            child: _buildBottomNavIcon(Icons.person_outline, false),
          ),
        ],
      ),
    );
  }

  // بناء أيقونة شريط التنقل السفلي
  Widget _buildBottomNavIcon(IconData icon, bool isActive) {
    return Container(
      width: isActive ? 50 : 30,
      height: isActive ? 50 : 30,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF6B7180) : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: isActive ? 25 : 20,
      ),
    );
  }

  // إضافة منتج إلى السلة
  Future<void> _addToCart(Product product) async {
    try {
      await _cartService.addItem(
        productId: product.id,
        name: product.name,
        image: product.images.isNotEmpty ? product.images.first : '',
        minPrice: product.minPrice.toInt(),
        maxPrice: product.maxPrice.toInt(),
        customerPrice: product.maxPrice.toInt(), // استخدام maxPrice كسعر العميل
        wholesalePrice: product.wholesalePrice.toInt(),
        quantity: 1,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم إضافة ${product.name} إلى السلة',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: const Color(0xFF28a745),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في إضافة المنتج: $e',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: const Color(0xFFdc3545),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}
