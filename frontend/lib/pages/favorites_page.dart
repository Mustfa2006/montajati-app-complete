// صفحة المفضلة - Favorites Page
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/product.dart';
import '../services/favorites_service.dart';
// تم إزالة import cart_service غير المستخدم
import '../widgets/pull_to_refresh_wrapper.dart';

import '../widgets/custom_app_bar.dart';

import 'package:go_router/go_router.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with TickerProviderStateMixin {
  final FavoritesService _favoritesService = FavoritesService.instance;
  // تم إزالة _cartService غير المستخدم

  List<Product> _displayedFavorites = [];
  String _searchQuery = '';
  String _sortBy = 'name'; // name, price, recent
  bool _isAscending = true;

  late AnimationController _animationController;
  late AnimationController _statsAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  // تم إزالة _statsAnimation غير المستخدم

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadFavorites();
  }

  /// تحديث البيانات عند السحب للأسفل
  Future<void> _refreshData() async {
    debugPrint('🔄 تحديث بيانات صفحة المفضلة...');

    // إعادة تحميل المفضلة
    await _loadFavorites();

    debugPrint('✅ تم تحديث بيانات صفحة المفضلة');
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _statsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    // تم إزالة تعيين _statsAnimation غير المستخدم
  }

  Future<void> _loadFavorites() async {
    await _favoritesService.loadFavorites();
    _updateDisplayedFavorites();
    _animationController.forward();
    _statsAnimationController.forward();
  }

  void _updateDisplayedFavorites() {
    setState(() {
      List<Product> favorites = _favoritesService.favorites;

      // فلترة المنتجات المتاحة فقط (الكمية > 0)
      favorites = favorites.where((product) {
        return product.availableQuantity > 0;
      }).toList();

      // تطبيق البحث
      if (_searchQuery.isNotEmpty) {
        favorites = favorites.where((product) {
          return product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              product.description.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
      }

      // تطبيق الترتيب
      switch (_sortBy) {
        case 'name':
          favorites = _favoritesService.getFavoritesSortedByName(
            ascending: _isAscending,
          );
          break;
        case 'price':
          favorites = _favoritesService.getFavoritesSortedByPrice(
            ascending: _isAscending,
          );
          break;
        case 'recent':
          favorites = _isAscending ? favorites.reversed.toList() : favorites;
          break;
      }

      _displayedFavorites = favorites;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _statsAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: CustomAppBar(
        title: 'مفضلتي',
        leading: IconButton(
          onPressed: () => context.go('/products'),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFFffd700),
            size: 20,
          ),
        ),
        actions: [
          // زر الإحصائيات
          IconButton(
            onPressed: _showStatsDialog,
            icon: const Icon(
              FontAwesomeIcons.chartLine,
              color: Color(0xFFffd700),
              size: 20,
            ),
          ),
          // زر مسح الكل
          if (_displayedFavorites.isNotEmpty)
            IconButton(
              onPressed: _showClearAllDialog,
              icon: const Icon(
                FontAwesomeIcons.trash,
                color: Color(0xFFff2d55),
                size: 18,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث والفلترة
          _buildSearchAndFilterBar(),

          // المحتوى الرئيسي
          Expanded(
            child: ListenableBuilder(
              listenable: _favoritesService,
              builder: (context, child) {
                return _displayedFavorites.isEmpty
                    ? _buildEmptyState()
                    : _buildFavoritesList(isTablet);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildReorganizedBottomNavigationBar(),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF16213e).withValues(alpha: 0.8),
            const Color(0xFF1a1a2e).withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // شريط البحث
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _updateDisplayedFavorites();
            },
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'ابحث في مفضلتك...',
              hintStyle: GoogleFonts.cairo(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                FontAwesomeIcons.magnifyingGlass,
                color: Color(0xFFffd700),
                size: 16,
              ),
              filled: true,
              fillColor: const Color(0xFF1a1a2e).withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // أزرار الترتيب
          Row(
            children: [
              _buildSortButton('الاسم', 'name'),
              const SizedBox(width: 8),
              _buildSortButton('السعر', 'price'),
              const SizedBox(width: 8),
              _buildSortButton('الأحدث', 'recent'),
              const Spacer(),
              // زر تغيير اتجاه الترتيب
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isAscending = !_isAscending;
                  });
                  _updateDisplayedFavorites();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFffd700).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFffd700).withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    _isAscending
                        ? FontAwesomeIcons.arrowUpAZ
                        : FontAwesomeIcons.arrowDownZA,
                    color: const Color(0xFFffd700),
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortButton(String title, String sortType) {
    final isSelected = _sortBy == sortType;

    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = sortType;
        });
        _updateDisplayedFavorites();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFffd700).withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFffd700)
                : const Color(0xFFffd700).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.cairo(
            color: isSelected
                ? const Color(0xFFffd700)
                : Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // أيقونة القلب المكسور
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFff2d55).withValues(alpha: 0.2),
                          const Color(0xFFffd700).withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFffd700).withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      FontAwesomeIcons.heartCrack,
                      color: Color(0xFFff2d55),
                      size: 50,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // النص الرئيسي
                  Text(
                    'مفضلتك فارغة!',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // النص الفرعي
                  Text(
                    'ابدأ بإضافة المنتجات التي تعجبك\nلتجدها هنا بسهولة',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFavoritesList(bool isTablet) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: PullToRefreshWrapper(
              onRefresh: _refreshData,
              refreshMessage: 'تم تحديث المفضلة',
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isTablet ? 3 : 2,
                  childAspectRatio: isTablet ? 0.75 : 0.7,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _displayedFavorites.length,
                itemBuilder: (context, index) {
                  final product = _displayedFavorites[index];
                  return _buildFavoriteCard(product, index);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFavoriteCard(Product product, int index) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // حساب الأحجام بناءً على عرض البطاقة (نفس نظام صفحة المنتجات)
        double cardWidth = constraints.maxWidth;
        double cardHeight = constraints.maxHeight;

        // نسبة الصورة تتكيف مع حجم البطاقة
        double imageHeight = cardHeight * 0.58; // 58% من ارتفاع البطاقة للصورة

        // أحجام النصوص والعناصر بناءً على عرض البطاقة
        double titleFontSize;
        double priceFontSize;
        double padding;

        if (cardWidth > 200) {
          titleFontSize = 15;
          priceFontSize = 14;
          padding = 14;
        } else if (cardWidth > 160) {
          titleFontSize = 14;
          priceFontSize = 13;
          padding = 12;
        } else if (cardWidth > 140) {
          titleFontSize = 13;
          priceFontSize = 12;
          padding = 10;
        } else {
          titleFontSize = 12;
          priceFontSize = 11;
          padding = 8;
        }

        return GestureDetector(
          onTap: () => context.go('/products/details/${product.id}'),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF16213e),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFffd700).withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // صورة المنتج الكبيرة - تملأ معظم البطاقة
                _buildLargeProductImage(product, imageHeight),

                // معلومات المنتج المضغوطة
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      padding,
                      padding * 0.6,
                      padding,
                      padding * 0.3,
                    ), // تقليل الحشو أكثر
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // اسم المنتج - متعدد الأسطر ومتجاوب
                        Expanded(
                          flex: 2,
                          child: Text(
                            product.name,
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                              height: 1.3, // زيادة المسافة بين الأسطر
                            ),
                            maxLines: 3, // السماح بثلاثة أسطر
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                          ),
                        ),

                        SizedBox(
                          height: padding * 1.2,
                        ), // مسافة أكبر بين الاسم والسعر
                        // سعر الجملة
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFffd700).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFffd700).withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'جملة: ${product.wholesalePrice.toStringAsFixed(0)} د.ع',
                            style: GoogleFonts.cairo(
                              color: const Color(0xFFffd700),
                              fontSize: priceFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        SizedBox(height: padding * 0.5),

                        // الأزرار السفلية - حذف من المفضلة وإضافة للسلة
                        Row(
                    children: [
                      // زر حذف من المفضلة على اليمين
                      GestureDetector(
                        onTap: () => _removeFromFavorites(product),
                        child: Container(
                          width: cardWidth > 180 ? 32 : 28,
                          height: cardWidth > 180 ? 32 : 28,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFff2d55,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFff2d55),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            FontAwesomeIcons.solidHeart,
                            color: const Color(0xFFff2d55),
                            size: cardWidth > 180 ? 14 : 12,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // زر إضافة للسلة على اليسار
                      Expanded(
                        child: Container(
                          height: cardWidth > 180 ? 32 : 28,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFffd700), Color(0xFFe6b31e)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFffd700,
                                ).withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                FontAwesomeIcons.cartPlus,
                                color: const Color(0xFF1a1a2e),
                                size: cardWidth > 180 ? 12 : 10,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'إضافة للسلة',
                                style: GoogleFonts.cairo(
                                  color: const Color(0xFF1a1a2e),
                                  fontSize: cardWidth > 180 ? 11 : 9,
                                  fontWeight: FontWeight.bold,
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // بناء صورة المنتج الكبيرة التي تملأ الإطار
  Widget _buildLargeProductImage(Product product, double imageHeight) {
    return Container(
      width: double.infinity,
      height: imageHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
        child: Stack(
          children: [
            // صورة المنتج - تملأ الإطار بالكامل
            Image.network(
              product.images.isNotEmpty
                  ? product.images.first
                  : 'https://picsum.photos/400/400?random=1',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover, // تملأ الإطار مع الحفاظ على النسبة
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1a2e),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        FontAwesomeIcons.image,
                        color: Color(0xFFffd700),
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'لا توجد صورة',
                        style: GoogleFonts.cairo(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1a2e),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFffd700),
                      strokeWidth: 3,
                    ),
                  ),
                );
              },
            ),

            // الكمية المتاحة في الزاوية العلوية اليسرى - مكبرة
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF28a745),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFffd700),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      FontAwesomeIcons.boxesStacked,
                      color: Colors.white,
                      size: 9,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${product.availableFrom} - ${product.availableTo}',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // إزالة منتج من المفضلة
  Future<void> _removeFromFavorites(Product product) async {
    final success = await _favoritesService.removeFromFavorites(product.id);
    if (success) {
      // تحديث القائمة المعروضة فوراً
      setState(() {
        _displayedFavorites.removeWhere((p) => p.id == product.id);
      });
      _showSnackBar('تم إزالة ${product.name} من المفضلة', isError: false);
    }
  }

  // تم حذف _addToCart غير المستخدم

  // عرض رسالة
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontSize: 12, // تصغير حجم الخط
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isError
            ? const Color(0xFFff2d55)
            : const Color(0xFF00ff88),
        duration: const Duration(milliseconds: 1500), // تقليل مدة العرض
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ), // تصغير الهوامش
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ), // تصغير الحشو
      ),
    );
  }

  // عرض حوار الإحصائيات
  void _showStatsDialog() {
    final stats = _favoritesService.getFavoritesStats();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFFffd700).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        title: Row(
          children: [
            const Icon(
              FontAwesomeIcons.chartLine,
              color: Color(0xFFffd700),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'إحصائيات المفضلة',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatItem('عدد المنتجات', '${stats['totalProducts']}'),
            _buildStatItem(
              'متوسط السعر',
              '${stats['averagePrice'].toStringAsFixed(0)} د.ع',
            ),
            _buildStatItem(
              'أقل سعر',
              '${stats['minPrice'].toStringAsFixed(0)} د.ع',
            ),
            _buildStatItem(
              'أعلى سعر',
              '${stats['maxPrice'].toStringAsFixed(0)} د.ع',
            ),
            _buildStatItem(
              'القيمة الإجمالية',
              '${stats['totalValue'].toStringAsFixed(0)} د.ع',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إغلاق',
              style: GoogleFonts.cairo(
                color: const Color(0xFFffd700),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.cairo(
              color: const Color(0xFFffd700),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // عرض حوار مسح الكل
  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFFff2d55).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        title: Row(
          children: [
            const Icon(
              FontAwesomeIcons.triangleExclamation,
              color: Color(0xFFff2d55),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'تأكيد المسح',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من مسح جميع المنتجات من المفضلة؟\nلا يمكن التراجع عن هذا الإجراء.',
          style: GoogleFonts.cairo(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _favoritesService.clearFavorites();
              _updateDisplayedFavorites();
              _showSnackBar('تم مسح جميع المفضلة', isError: false);
            },
            child: Text(
              'مسح الكل',
              style: GoogleFonts.cairo(
                color: const Color(0xFFff2d55),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // متغيرات الشريط السفلي
  int currentPageIndex = -1; // المفضلة ليست في الشريط السفلي
  bool isAdmin = false;

  // بناء شريط التنقل السفلي المعاد ترتيبه
  Widget _buildReorganizedBottomNavigationBar() {
    return Container(
      margin: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
      height: 60, // تصغير الارتفاع
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // منتجاتي على اليمين
          _buildAdvancedNavButton(
            icon: FontAwesomeIcons.store,
            label: 'منتجاتي',
            index: 0,
            isActive: currentPageIndex == 0,
          ),
          // الطلبات
          _buildAdvancedNavButton(
            icon: FontAwesomeIcons.bagShopping,
            label: 'الطلبات',
            index: 1,
            isActive: currentPageIndex == 1,
          ),
          // الأرباح
          _buildAdvancedNavButton(
            icon: FontAwesomeIcons.chartLine,
            label: 'الأرباح',
            index: 2,
            isActive: currentPageIndex == 2,
          ),
          // الحساب
          _buildAdvancedNavButton(
            icon: FontAwesomeIcons.user,
            label: 'الحساب',
            index: 3,
            isActive: currentPageIndex == 3,
          ),
          // لوحة التحكم (تظهر فقط للمدير)
          if (isAdmin)
            _buildAdvancedNavButton(
              icon: FontAwesomeIcons.userShield,
              label: 'الإدارة',
              index: 4,
              isActive: currentPageIndex == 4,
            ),
        ],
      ),
    );
  }

  // بناء زر التنقل المتقدم
  Widget _buildAdvancedNavButton({
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 12,
        ), // تصغير الحشو
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive
                  ? const Color(0xFFffd700)
                  : Colors.white.withValues(alpha: 0.6),
              size: 20, // تصغير الأيقونة
            ),
            const SizedBox(height: 3), // تقليل المسافة
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 11, // تصغير النص
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? const Color(0xFFffd700)
                    : Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // معالج النقر على أزرار التنقل
  void _onNavTap(int index) {
    setState(() {
      currentPageIndex = index;
    });

    switch (index) {
      case 0:
        // منتجاتي
        context.go('/products');
        break;
      case 1:
        // الطلبات
        context.go('/orders');
        break;
      case 2:
        // الأرباح
        context.go('/profits');
        break;
      case 3:
        // الحساب
        context.go('/account');
        break;
      case 4:
        // لوحة التحكم الإدارية
        if (isAdmin) {
          context.go('/admin');
        }
        break;
    }
  }
}
