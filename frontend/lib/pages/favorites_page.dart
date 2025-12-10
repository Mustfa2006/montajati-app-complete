import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../core/design_system.dart';
import '../models/product.dart';
import '../providers/theme_provider.dart';
import '../services/favorites_service.dart';
import '../services/cart_service.dart';
import '../utils/font_helper.dart';
import '../utils/theme_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/pull_to_refresh_wrapper.dart';

// 🧠 كاش بسيط لصور المنتجات داخل جلسة التطبيق (نسخة محلية)
class _ProductImageCache {
  static final Map<String, ImageProvider> _cache = {};

  static ImageProvider get(String url) {
    if (_cache.containsKey(url)) {
      return _cache[url]!;
    }

    final provider = NetworkImage(url);
    _cache[url] = provider;
    return provider;
  }
}

// 🔁 ويدجت ذكية لعرض صورة المنتج مع إعادة المحاولة التلقائية + الكاش (نسخة محلية)
class _CachedAutoRetryProductImage extends StatefulWidget {
  final String imageUrl;
  final double height;
  final bool isDark;

  const _CachedAutoRetryProductImage({required this.imageUrl, required this.height, required this.isDark});

  @override
  State<_CachedAutoRetryProductImage> createState() => _CachedAutoRetryProductImageState();
}

class _CachedAutoRetryProductImageState extends State<_CachedAutoRetryProductImage> {
  int _retryKey = 0;
  Timer? _retryTimer;

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  void _scheduleRetry() {
    if (!mounted) return;
    if (_retryTimer != null && _retryTimer!.isActive) return;

    _retryTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() {
        _retryKey++;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _ProductImageCache.get(widget.imageUrl);

    return Image(
      key: ValueKey('${widget.imageUrl}#$_retryKey'),
      image: imageProvider,
      fit: BoxFit.contain,
      width: double.infinity,
      height: widget.height,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppDesignSystem.goldColor),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        _scheduleRetry();
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  color: widget.isDark ? Colors.white24 : Colors.grey.shade300,
                  size: 30,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final FavoritesService _favoritesService = FavoritesService.instance;
  final CartService _cartService = CartService(); // factory constructor
  List<Product> _displayedFavorites = [];
  String _searchQuery = '';
  String _sortBy = 'date_desc'; // date_desc, date_asc, price_high, price_low

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    await _favoritesService.loadFavorites();
    _updateDisplayedFavorites();
  }

  Future<void> _refreshData() async {
    await _loadFavorites();
  }

  void _updateDisplayedFavorites() {
    List<Product> favorites = _favoritesService.favorites;

    // تصفية حسب البحث
    if (_searchQuery.isNotEmpty) {
      favorites = favorites.where((product) {
        return product.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // ترتيب
    switch (_sortBy) {
      case 'date_desc':
        // الافتراضي، الأحدث أولاً (بافتراض أن القائمة مرتبة زمنياً)
        break;
      case 'date_asc':
        favorites = favorites.reversed.toList();
        break;
      case 'price_high':
        favorites.sort((a, b) => b.wholesalePrice.compareTo(a.wholesalePrice));
        break;
      case 'price_low':
        favorites.sort((a, b) => a.wholesalePrice.compareTo(b.wholesalePrice));
        break;
    }

    if (mounted) {
      setState(() {
        _displayedFavorites = favorites;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;

    // حساب عدد الأعمدة بناءً على عرض الشاشة (نفس منطق صفحة المنتجات)
    final int crossAxisCount = screenWidth > 600 ? 3 : 2;
    final horizontalMargin = screenWidth > 400 ? 16.0 : (screenWidth > 350 ? 14.0 : 12.0);
    final crossAxisSpacing = screenWidth > 400 ? 12.0 : (screenWidth > 350 ? 10.0 : 8.0);
    final mainAxisSpacing = screenWidth > 400 ? 20.0 : (screenWidth > 350 ? 18.0 : 16.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AppBackground(
        child: Stack(
          children: [
            // 🎨 الخلفية الموحدة للوضع النهاري
            if (!isDark)
              Container(
                color: const Color(0xFFF5F5F7), // خلفية نهارية موحدة
              ),

            // المحتوى الرئيسي
            PullToRefreshWrapper(
              onRefresh: _refreshData,
              refreshMessage: 'تم تحديث المفضلة',
              child: CustomScrollView(
                slivers: [
                  // مسافة للشريط العلوي
                  const SliverToBoxAdapter(child: SizedBox(height: 25)),

                  // العنوان
                  SliverToBoxAdapter(child: _buildHeader(isDark)),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // شريط البحث والفلترة المطور
                  SliverToBoxAdapter(child: _buildSearchAndFilterBar(isDark)),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // قائمة المفضلات
                  ListenableBuilder(
                    listenable: _favoritesService,
                    builder: (context, child) {
                      if (_displayedFavorites.isEmpty) {
                        return SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState(isDark));
                      }

                      return SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: 10),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: crossAxisSpacing,
                            mainAxisSpacing: mainAxisSpacing,
                            childAspectRatio: _calculateOptimalAspectRatio(context, crossAxisCount),
                          ),
                          delegate: SliverChildBuilderDelegate((context, index) {
                            final product = _displayedFavorites[index];
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              child: _buildProductCard(product, isDark),
                            );
                          }, childCount: _displayedFavorites.length),
                        ),
                      );
                    },
                  ),

                  // مسافة سفلية للشريط السفلي
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🧠 حساب النسبة المثالية للبطاقة (مطابق لصفحة المنتجات)
  double _calculateOptimalAspectRatio(BuildContext context, int columns) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    final horizontalMargin = screenWidth > 400 ? 16.0 : (screenWidth > 350 ? 14.0 : 12.0);
    final crossAxisSpacing = screenWidth > 400 ? 12.0 : (screenWidth > 350 ? 10.0 : 8.0);

    final availableWidth = screenWidth - (horizontalMargin * 2);
    final totalSpacing = crossAxisSpacing * (columns - 1);
    final cardWidth = (availableWidth - totalSpacing) / columns;

    final cardHeight = _calculateCardHeight(screenWidth, cardWidth);

    return cardWidth / cardHeight;
  }

  // ثوابت قياسات البطاقة
  static const double _cardTopPadding = 22.0;
  static const double _imageHeight = 200.0;
  static const double _imageBottomSpacing = -5.0;
  static const double _nameHeight = 27.0;
  static const double _nameBottomSpacing = 0.0;
  static const double _priceBarHeight = 40.0;
  static const double _cardBottomPadding = 15.0;

  double _calculateCardHeight(double screenWidth, double cardWidth) {
    final double imageHeight = _getImageHeightForCard(cardWidth, screenWidth);
    return _cardTopPadding +
        imageHeight +
        _imageBottomSpacing +
        _nameHeight +
        _nameBottomSpacing +
        _priceBarHeight +
        _cardBottomPadding;
  }

  double _getImageHeightForCard(double cardWidth, double screenWidth) {
    double factor;
    if (cardWidth < 160) {
      factor = 1.15;
    } else if (cardWidth < 190) {
      factor = 1.05;
    } else {
      factor = 0.95;
    }

    if (screenWidth < 360) {
      factor += 0.05;
    } else if (screenWidth > 600) {
      factor -= 0.05;
    }

    final double dynamicHeight = cardWidth * factor;
    const double minHeight = _imageHeight * 0.9;
    const double maxHeight = _imageHeight * 1.3;

    return dynamicHeight.clamp(minHeight, maxHeight).toDouble();
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'المفضلة',
                style: GoogleFonts.cairo(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_favoritesService.favorites.length} منتجات مميزة',
                style: GoogleFonts.cairo(color: isDark ? Colors.white70 : Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          if (_favoritesService.favorites.isNotEmpty)
            GestureDetector(
              onTap: () => _showClearConfirmation(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: const Icon(FontAwesomeIcons.trashCan, color: Colors.red, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // شريط البحث بتصميم مبهر
          Container(
            height: 55,
            decoration: BoxDecoration(
              color: isDark ? null : const Color(0xFFF3F4F6),
              gradient: isDark
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppDesignSystem.bottomNavColor.withValues(alpha: 0.85),
                        AppDesignSystem.activeButtonColor.withValues(alpha: 0.9),
                        AppDesignSystem.primaryBackground.withValues(alpha: 0.95),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    )
                  : null,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: isDark ? AppDesignSystem.goldColor.withValues(alpha: 0.4) : const Color(0xFFE5E7EB),
                width: isDark ? 1.2 : 1.0,
              ),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 0.5,
                      ),
                      BoxShadow(
                        color: AppDesignSystem.goldColor.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 0),
                        spreadRadius: 1,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _updateDisplayedFavorites();
              },
              style: GoogleFonts.cairo(
                color: isDark ? AppDesignSystem.primaryTextColor : const Color(0xFF111827),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'ابحث في مفضلتك...',
                hintStyle: GoogleFonts.cairo(
                  color: isDark ? AppDesignSystem.primaryTextColor.withValues(alpha: 0.6) : const Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(14),
                  child: Icon(
                    Icons.search_rounded,
                    color: isDark ? AppDesignSystem.goldColor.withValues(alpha: 0.9) : const Color(0xFFFFC727),
                    size: AppDesignSystem.largeIconSize,
                  ),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),

          const SizedBox(height: 15),

          // أزرار الفلترة
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSortButton('الأحدث', 'date_desc', isDark),
                const SizedBox(width: 8),
                _buildSortButton('الأقدم', 'date_asc', isDark),
                const SizedBox(width: 8),
                _buildSortButton('الأعلى سعراً', 'price_high', isDark),
                const SizedBox(width: 8),
                _buildSortButton('الأقل سعراً', 'price_low', isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortButton(String title, String sortType, bool isDark) {
    final isSelected = _sortBy == sortType;

    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = sortType;
        });
        _updateDisplayedFavorites();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFffd700).withValues(alpha: 0.2)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFffd700)
                : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2)),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFffd700).withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          title,
          style: GoogleFonts.cairo(
            color: isSelected
                ? const Color(0xFFffd700)
                : (isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7)),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // بطاقة المنتج - مطابقة تماماً لصفحة المنتجات 🎨✨
  Widget _buildProductCard(Product product, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () {
        context.push('/products/details/${product.id}');
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth;
            final double imageHeight = _getImageHeightForCard(cardWidth, screenWidth);

            return Container(
              margin: const EdgeInsets.only(right: 5, bottom: 0),
              clipBehavior: Clip.none,
              decoration: BoxDecoration(
                color: isDark ? null : Colors.white,
                gradient: isDark
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.06),
                          Colors.white.withValues(alpha: 0.03),
                          const Color(0xFF1A1F2E).withValues(alpha: 0.2),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      )
                    : null,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.04),
                  width: 1,
                ),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Stack(
                children: [
                  // شريط عدد القطع
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppDesignSystem.goldColor.withValues(alpha: 0.9),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inventory_2_rounded, color: Colors.black, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${product.availableFrom}-${product.availableTo}',
                            style: GoogleFonts.cairo(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // شريط التبليغات الذكي
                  if (product.notificationTags.isNotEmpty)
                    Positioned(right: 0, top: 0, child: _NotificationBarWidget(product: product)),

                  // منطقة الصورة
                  Positioned(
                    left: 8,
                    top: _cardTopPadding,
                    right: 8,
                    child: Container(
                      height: imageHeight - 8,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: imageHeight,
                              child: product.images.isNotEmpty
                                  ? Container(
                                      width: double.infinity,
                                      height: imageHeight,
                                      color: isDark ? Colors.transparent : Colors.white,
                                      child: _CachedAutoRetryProductImage(
                                        imageUrl: product.images.first,
                                        height: imageHeight,
                                        isDark: isDark,
                                      ),
                                    )
                                  : Container(
                                      height: imageHeight,
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        Icons.camera_alt_outlined,
                                        color: isDark ? Colors.white60 : Colors.grey,
                                        size: 50,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // اسم المنتج
                  Positioned(
                    left: 6,
                    right: 6,
                    top: _cardTopPadding + imageHeight + _imageBottomSpacing,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF1A1F2E).withValues(alpha: 0.7),
                                  const Color(0xFF0F1419).withValues(alpha: 0.4),
                                ]
                              : [Colors.white.withValues(alpha: 0.95), Colors.white.withValues(alpha: 0.9)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        product.name,
                        style: FontHelper.cairo(
                          color: ThemeColors.textColor(isDark),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  // السعر والأزرار
                  Positioned(
                    left: 5,
                    right: 5,
                    top: _cardTopPadding + imageHeight + _imageBottomSpacing + _nameHeight + _nameBottomSpacing,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? null : const Color(0xFFF3F4F6),
                        gradient: isDark
                            ? LinearGradient(
                                colors: [Colors.black.withValues(alpha: 0.4), Colors.black.withValues(alpha: 0.2)],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // السعر
                          Container(
                            constraints: const BoxConstraints(maxWidth: 80),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black.withValues(alpha: 0.6) : const Color(0xFFF1F1F1),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              _formatPrice(product.wholesalePrice),
                              style: FontHelper.cairo(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),

                          const Spacer(),

                          // الأزرار
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Transform.scale(scale: 0.85, child: _buildHeartButton(product, isDark)),
                              Transform.scale(scale: 0.75, child: _buildAnimatedAddButton(product)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeartButton(Product product, bool isDark) {
    // في صفحة المفضلات، المنتج دائماً مفضل، لذا الزر للحذف
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        await _favoritesService.toggleFavorite(product);
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم إزالة ${product.name} من المفضلة',
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFF5252), Color(0xFFE91E63)]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.red.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 4)),
            BoxShadow(color: Colors.red.withValues(alpha: 0.2), blurRadius: 25, offset: const Offset(0, 8)),
          ],
        ),
        child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildAnimatedAddButton(Product product) {
    bool isInCart = _cartService.hasProduct(product.id);

    return GestureDetector(
      onTap: () async {
        if (!isInCart) {
          HapticFeedback.lightImpact();
          await _cartService.addItem(
            productId: product.id,
            name: product.name,
            image: product.images.isNotEmpty ? product.images.first : '',
            minPrice: product.minPrice.toInt(),
            maxPrice: product.maxPrice.toInt(),
            customerPrice: 0,
            wholesalePrice: product.wholesalePrice.toInt(),
            quantity: 1,
          );
          setState(() {});
        } else {
          HapticFeedback.selectionClick();
          _cartService.removeItem(product.id);
          setState(() {});
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        width: 40,
        height: 36,
        decoration: BoxDecoration(
          gradient: isInCart
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4CAF50), Color(0xFF45A049), Color(0xFF388E3C)],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6F757F), Color(0xFF4A5568), Color(0xFF2D3748)],
                ),
          borderRadius: BorderRadius.circular(isInCart ? 18 : 12),
          border: Border.all(
            color: isInCart ? Colors.white.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isInCart ? Colors.green.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3),
              blurRadius: isInCart ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isInCart
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
              : const Icon(Icons.add_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1a1a2e).withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.3), width: 2),
            ),
            child: const Icon(FontAwesomeIcons.heartCrack, color: Color(0xFFffd700), size: 60),
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد منتجات مفضلة',
            style: GoogleFonts.cairo(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'اضغط على القلب لإضافة منتجات هنا',
            style: GoogleFonts.cairo(color: isDark ? Colors.white70 : Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => context.go('/products'),
            icon: const Icon(FontAwesomeIcons.store, color: Colors.black, size: 18),
            label: Text(
              'تصفح المنتجات',
              style: GoogleFonts.cairo(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFffd700),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'تأكيد الحذف',
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'هل أنت متأكد من حذف جميع المنتجات من المفضلة؟',
          style: GoogleFonts.cairo(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _favoritesService.clearFavorites();
              _updateDisplayedFavorites();
            },
            child: Text(
              'حذف الكل',
              style: GoogleFonts.cairo(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    return NumberFormat.currency(symbol: 'د.ع', decimalDigits: 0, locale: 'ar_IQ').format(price);
  }
}

class _NotificationBarWidget extends StatefulWidget {
  final Product product;

  const _NotificationBarWidget({required this.product});

  @override
  State<_NotificationBarWidget> createState() => _NotificationBarWidgetState();
}

class _NotificationBarWidgetState extends State<_NotificationBarWidget> {
  int currentIndex = 0;
  Timer? notificationTimer;

  @override
  void initState() {
    super.initState();
    final tags = widget.product.notificationTags;
    if (tags.length > 1) {
      notificationTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (mounted && tags.isNotEmpty) {
          setState(() {
            currentIndex = (currentIndex + 1) % tags.length;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    notificationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tags = widget.product.notificationTags;
    if (tags.isEmpty || currentIndex >= tags.length) {
      return const SizedBox.shrink();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Container(
        key: ValueKey(tags[currentIndex]),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF6B73FF).withValues(alpha: 0.9), const Color(0xFF9D4EDD).withValues(alpha: 0.8)],
          ),
          borderRadius: const BorderRadius.only(topRight: Radius.circular(24), bottomLeft: Radius.circular(16)),
          boxShadow: [
            BoxShadow(color: const Color(0xFF6B73FF).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.campaign_rounded, color: Colors.white, size: 12),
            const SizedBox(width: 4),
            Text(
              tags[currentIndex],
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
