import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../core/design_system.dart';
import '../models/product.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../services/cart_service.dart';
import '../services/favorites_service.dart';
import '../services/products_cache_service.dart';
import '../services/user_service.dart';
import '../utils/font_helper.dart';
import '../utils/theme_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/drawer_menu.dart';
import '../widgets/sliding_drawer.dart';

// نقاط تقفز للتحميل
class _BouncingDotsLoader extends StatefulWidget {
  final bool isDark;
  final double size;

  const _BouncingDotsLoader({required this.isDark, this.size = 8});

  @override
  State<_BouncingDotsLoader> createState() => _BouncingDotsLoaderState();
}

class _BouncingDotsLoaderState extends State<_BouncingDotsLoader> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    });
    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0, end: -10).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();
    _startAnimation();
  }

  void _startAnimation() async {
    while (mounted) {
      for (int i = 0; i < 3; i++) {
        if (!mounted) return;
        _controllers[i].forward();
        await Future.delayed(const Duration(milliseconds: 120));
      }
      await Future.delayed(const Duration(milliseconds: 100));
      for (int i = 0; i < 3; i++) {
        if (!mounted) return;
        _controllers[i].reverse();
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.isDark ? AppDesignSystem.goldColor.withValues(alpha: 0.8) : AppDesignSystem.goldColor;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animations[index].value),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: widget.size * 0.4),
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: dotColor.withValues(alpha: 0.4), blurRadius: 4, spreadRadius: 1)],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

// ويدجت صورة المنتج مع إعادة المحاولة
class _SmartProductImage extends StatefulWidget {
  final String imageUrl;
  final double height;
  final bool isDark;

  const _SmartProductImage({required this.imageUrl, required this.height, required this.isDark});

  @override
  State<_SmartProductImage> createState() => _SmartProductImageState();
}

class _SmartProductImageState extends State<_SmartProductImage> {
  static const int _maxRetries = 3;
  int _retryCount = 0;
  bool _hasFailed = false;

  void _retry() {
    if (!mounted || _retryCount >= _maxRetries) {
      if (mounted) setState(() => _hasFailed = true);
      return;
    }
    setState(() => _retryCount++);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasFailed) {
      return Container(
        height: widget.height,
        color: widget.isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.withValues(alpha: 0.05),
        child: Center(
          child: GestureDetector(
            onTap: () => setState(() {
              _retryCount = 0;
              _hasFailed = false;
            }),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_rounded, color: widget.isDark ? Colors.white38 : Colors.grey[400], size: 24),
                const SizedBox(height: 4),
                Text(
                  'اضغط للتحديث',
                  style: TextStyle(fontSize: 9, color: widget.isDark ? Colors.white38 : Colors.grey[400]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      cacheKey: widget.imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: widget.height,
      httpHeaders: const {'Connection': 'keep-alive'},
      placeholder: (context, url) => Container(
        height: widget.height,
        color: widget.isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.withValues(alpha: 0.05),
        child: Center(child: _BouncingDotsLoader(isDark: widget.isDark)),
      ),
      errorWidget: (context, url, error) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _retry();
        });
        return Container(
          height: widget.height,
          color: widget.isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.withValues(alpha: 0.05),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _BouncingDotsLoader(isDark: widget.isDark, size: 6),
              const SizedBox(height: 6),
              Text(
                'جاري المحاولة ${_retryCount + 1}/$_maxRetries',
                style: TextStyle(fontSize: 8, color: widget.isDark ? Colors.white30 : Colors.grey[400]),
              ),
            ],
          ),
        );
      },
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
    );
  }
}

class NewProductsPage extends StatefulWidget {
  const NewProductsPage({super.key});

  @override
  State<NewProductsPage> createState() => _NewProductsPageState();
}

class _NewProductsPageState extends State<NewProductsPage> {
  final SlidingDrawerController _drawerController = SlidingDrawerController();
  List<Product> _products = [];
  bool _isLoadingProducts = false;
  bool _hasError = false;

  // بيانات البانرات الإعلانية
  List<Map<String, dynamic>> _banners = [];
  bool _isLoadingBanners = false;
  final PageController _bannerPageController = PageController();
  Timer? _bannerTimer;
  int _currentBannerIndex = 0;

  // شريط البحث
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // البحث
  List<Product> _filteredProducts = [];
  Timer? _searchDebounceTimer;

  // نظام Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  bool _isLoadingMore = false;
  bool _hasMoreProducts = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadBanners();
    _setupScrollListener();
    _loadFavorites();
  }

  // إعداد listener للـ scroll لتحميل المزيد من المنتجات
  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (!mounted) return;
      try {
        if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 500) {
          if (!_isLoadingProducts && !_isLoadingMore && _hasMoreProducts) {
            _loadMoreProducts();
          }
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    try {
      _bannerTimer?.cancel();
      _searchDebounceTimer?.cancel();
      _bannerPageController.dispose();
      _searchController.dispose();
      _scrollController.dispose();
    } catch (_) {}
    super.dispose();
  }

  // تحميل المفضلة
  Future<void> _loadFavorites() async {
    try {
      // استخدام Provider - لا حاجة لـ setState لأن FavoritesService هو ChangeNotifier
      await context.read<FavoritesService>().loadFavorites();
    } catch (_) {}
  }

  // تحميل البانرات الإعلانية
  Future<void> _loadBanners() async {
    if (!mounted) return;
    setState(() => _isLoadingBanners = true);

    try {
      final uri = Uri.parse('${ApiConfig.productsUrl}/banners');
      final response = await http.get(uri, headers: ApiConfig.defaultHeaders).timeout(ApiConfig.defaultTimeout);

      if (response.statusCode != 200) {
        if (mounted) {
          setState(() {
            _isLoadingBanners = false;
            _banners = [];
          });
        }
        return;
      }

      final jsonData = jsonDecode(response.body);
      if (jsonData['success'] != true) {
        if (mounted) {
          setState(() {
            _isLoadingBanners = false;
            _banners = [];
          });
        }
        return;
      }

      final List<dynamic> data = jsonData['data'] ?? [];
      final List<Map<String, dynamic>> banners = List<Map<String, dynamic>>.from(data);

      if (mounted) {
        setState(() {
          _banners = banners;
          _isLoadingBanners = false;
        });
        if (_banners.length > 1) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) _startAutoSlide();
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingBanners = false;
          _banners = [];
        });
      }
    }
  }

  // بدء التقليب التلقائي للبانرات
  void _startAutoSlide() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || _banners.isEmpty) {
        timer.cancel();
        return;
      }
      if (!_bannerPageController.hasClients) return;
      if (_bannerPageController.positions.isEmpty) return;

      final currentPage = _bannerPageController.page?.round() ?? 0;
      final nextPage = (currentPage + 1) % _banners.length;
      _bannerPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  // إيقاف التقليب التلقائي مؤقتاً
  void _pauseAutoSlide() {
    _bannerTimer?.cancel();
    Timer(const Duration(seconds: 3), () {
      if (mounted && _banners.length > 1) _startAutoSlide();
    });
  }

  // تنسيق الأرقام بالفواصل
  String _formatPrice(double price) {
    final formatter = NumberFormat('#,###');
    return formatter.format(price.toInt());
  }

  // تحميل المنتجات مع نظام الكاش الذكي (Cache-First Strategy)
  Future<void> _loadProducts() async {
    if (!mounted) return;

    // إعادة تعيين حالة الخطأ
    setState(() => _hasError = false);

    // محاولة تحميل من الكاش فوراً
    final cachedProducts = await ProductsCacheService.getCachedProducts();

    if (cachedProducts != null && cachedProducts.isNotEmpty) {
      final availableProducts = cachedProducts.where((p) => p.availableQuantity > 0).toList();
      if (mounted) {
        setState(() {
          _products = availableProducts;
          _filteredProducts = List.from(availableProducts);
          _isLoadingProducts = false;
          _hasMoreProducts = true;
          _currentPage = 1;
        });
      }
      _refreshProductsInBackground();
      return;
    }

    // إذا لا يوجد كاش، تحميل من السيرفر مع loading
    setState(() {
      _isLoadingProducts = true;
      _currentPage = 1;
      _products = [];
      _filteredProducts = [];
      _hasMoreProducts = true;
    });

    await _fetchProductsFromServer();
  }

  // تحديث المنتجات في الخلفية
  Future<void> _refreshProductsInBackground() async {
    try {
      final uri = Uri.parse(ApiConfig.productsUrl).replace(queryParameters: {'page': '1', 'limit': '$_itemsPerPage'});
      final response = await http.get(uri, headers: ApiConfig.defaultHeaders).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true) {
          final List<dynamic> data = jsonData['data']?['products'] ?? [];
          final products = data.map<Product>((json) => Product.fromJson(json)).toList();
          final availableProducts = products.where((p) => p.availableQuantity > 0).toList();
          await ProductsCacheService.cacheProducts(products);

          if (mounted && _hasDataChanged(availableProducts)) {
            setState(() {
              _products = availableProducts;
              _filteredProducts = List.from(availableProducts);
              _hasMoreProducts = products.length >= _itemsPerPage;
            });
          }
        }
      }
    } catch (_) {}
  }

  // فحص هل تغيرت البيانات
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

  // تحميل المنتجات من السيرفر
  Future<void> _fetchProductsFromServer() async {
    try {
      final uri = Uri.parse(
        ApiConfig.productsUrl,
      ).replace(queryParameters: {'page': '$_currentPage', 'limit': '$_itemsPerPage'});
      final response = await http.get(uri, headers: ApiConfig.defaultHeaders).timeout(ApiConfig.defaultTimeout);

      if (response.statusCode != 200) {
        if (mounted) {
          setState(() {
            _isLoadingProducts = false;
            _hasMoreProducts = false;
            _hasError = true;
          });
        }
        return;
      }

      final jsonData = jsonDecode(response.body);
      if (jsonData['success'] != true) {
        if (mounted) {
          setState(() {
            _isLoadingProducts = false;
            _hasMoreProducts = false;
            _hasError = true;
          });
        }
        return;
      }

      final List<dynamic> data = jsonData['data']?['products'] ?? [];
      final products = data.map<Product>((json) => Product.fromJson(json)).toList();
      final availableProducts = products.where((p) => p.availableQuantity > 0).toList();
      await ProductsCacheService.cacheProducts(products);

      if (mounted) {
        setState(() {
          _products = availableProducts;
          _filteredProducts = List.from(availableProducts);
          _isLoadingProducts = false;
          _hasMoreProducts = products.length >= _itemsPerPage;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
          _hasMoreProducts = false;
          _hasError = true;
        });
      }
    }
  }

  // تحميل المزيد من المنتجات
  Future<void> _loadMoreProducts() async {
    if (!mounted || _isLoadingProducts || _isLoadingMore || !_hasMoreProducts) return;
    setState(() => _isLoadingMore = true);

    try {
      _currentPage++;
      final uri = Uri.parse(
        ApiConfig.productsUrl,
      ).replace(queryParameters: {'page': '$_currentPage', 'limit': '$_itemsPerPage'});
      final response = await http.get(uri, headers: ApiConfig.defaultHeaders).timeout(ApiConfig.defaultTimeout);

      if (response.statusCode != 200) {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
            _hasMoreProducts = false;
          });
        }
        return;
      }

      final jsonData = jsonDecode(response.body);
      if (jsonData['success'] != true) {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
            _hasMoreProducts = false;
          });
        }
        return;
      }

      final List<dynamic> data = jsonData['data']?['products'] ?? [];
      final newProducts = data.map<Product>((json) => Product.fromJson(json)).toList();
      final availableProducts = newProducts.where((product) => product.availableQuantity > 0).toList();

      if (mounted) {
        setState(() {
          _products.addAll(availableProducts);
          _isLoadingMore = false;
          _hasMoreProducts = newProducts.length >= _itemsPerPage;
        });
        // إعادة تطبيق البحث الحالي
        _searchProducts(_searchController.text);
        ProductsCacheService.cacheProducts(_products);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _hasMoreProducts = false;
        });
      }
    }
  }

  // البحث في المنتجات
  void _searchProducts(String query) {
    if (!mounted) return;
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      List<Product> filtered = query.isEmpty
          ? List.from(_products)
          : _products.where((p) => p.name.toLowerCase().contains(query.toLowerCase().trim())).toList();
      if (mounted) setState(() => _filteredProducts = filtered);
    });
  }

  // زر الـ Header
  Widget _buildHeaderButton({required IconData icon, required VoidCallback onTap, required bool isDark, int? badge}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                icon,
                color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.7),
                size: 21,
              ),
            ),
            if (badge != null && badge > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.4), blurRadius: 4, spreadRadius: 0),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      badge > 9 ? '9+' : badge.toString(),
                      style: GoogleFonts.cairo(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<ThemeProvider, bool>(
      selector: (_, provider) => provider.isDarkMode,
      builder: (context, isDark, _) {
        return SlidingDrawer(
          controller: _drawerController,
          menuWidthFactor: 0.68,
          endScale: 0.85,
          rotationDegrees: -3,
          backgroundColor: isDark ? const Color(0xFF1a1a2e) : const Color(0xFF2c3e50),
          shadowColor: const Color(0xFFffd700),
          menu: DrawerMenu(onClose: () => _drawerController.toggle()),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            extendBody: true,
            body: AppBackground(
              child: Stack(
                children: [
                  if (!isDark) Container(color: const Color(0xFFF5F5F7)),
                  RefreshIndicator(
                    onRefresh: _loadProducts,
                    color: const Color(0xFFffd700),
                    backgroundColor: isDark ? const Color(0xFF1a1a2e) : Colors.white,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      slivers: [
                        const SliverToBoxAdapter(child: SizedBox(height: 25)),
                        SliverToBoxAdapter(child: _buildHeader(isDark)),
                        SliverToBoxAdapter(child: _buildMainBanner(isDark)),
                        SliverToBoxAdapter(child: _buildSearchBar(isDark)),
                        ..._buildProductsSlivers(context, isDark),
                        const SliverToBoxAdapter(child: SizedBox(height: 160)),
                      ],
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

  // بناء الشريط العلوي
  Widget _buildHeader(bool isDark) {
    final greetingData = UserService.getGreeting();
    final greeting = greetingData['greeting']!;
    final emoji = greetingData['emoji']!;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Consumer<UserProvider>(
                      builder: (context, userProvider, _) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RichText(
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$greeting ${userProvider.firstName} ',
                                  style: GoogleFonts.cairo(
                                    color: ThemeColors.textColor(isDark),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(text: emoji, style: const TextStyle(fontSize: 12, fontFamily: null)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userProvider.phoneNumber,
                            style: GoogleFonts.cairo(
                              color: ThemeColors.secondaryTextColor(isDark),
                              fontSize: 9,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Consumer<CartService>(
                        builder: (context, cart, _) => _buildHeaderButton(
                          icon: Icons.shopping_bag_outlined,
                          onTap: () => context.go('/cart'),
                          isDark: isDark,
                          badge: cart.itemCount > 0 ? cart.itemCount : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildHeaderButton(
                        icon: Icons.menu_rounded,
                        onTap: () => _drawerController.toggle(),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
              Positioned.fill(
                child: Center(
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFB8860B), Color(0xFFDAA520)],
                      stops: [0.0, 0.3, 0.7, 1.0],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'منتجاتي',
                      style: GoogleFonts.amiri(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // بناء البانر الرئيسي
  Widget _buildMainBanner(bool isDark) {
    if (_isLoadingBanners) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        height: 180,
        decoration: BoxDecoration(
          color: isDark ? null : Colors.white,
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppDesignSystem.primaryBackground,
                    const Color(0xFF2D3748).withValues(alpha: 0.8),
                    const Color(0xFF1A202C).withValues(alpha: 0.9),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFffd700).withValues(alpha: isDark ? 0.4 : 0.5),
            width: isDark ? 1.5 : 2,
          ),
          boxShadow: isDark
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))]
              : [BoxShadow(color: Colors.grey.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFffd700).withValues(alpha: 0.3)),
                    ),
                  ),
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffd700)),
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFFffd700),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFffd700).withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.image, color: Colors.white, size: 12),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'جاري تحميل ...',
                style: GoogleFonts.cairo(
                  color: const Color(0xFFffd700).withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_banners.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        height: 180,
        decoration: BoxDecoration(
          color: isDark ? null : Colors.white,
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppDesignSystem.primaryBackground,
                    const Color(0xFF2D3748).withValues(alpha: 0.8),
                    const Color(0xFF1A202C).withValues(alpha: 0.9),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFF8F8F8)],
                  stops: [0.0, 1.0],
                ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFffd700).withValues(alpha: isDark ? 0.4 : 0.3), width: 1.5),
          boxShadow: isDark
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))]
              : [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                    spreadRadius: 2,
                  ),
                ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFffd700).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.image_outlined, color: Color(0xFFffd700), size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد إعلانات متاحة',
                style: GoogleFonts.cairo(
                  color: const Color(0xFFffd700).withValues(alpha: 0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // عرض البانرات الحقيقية
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          height: 180,
          child: PageView.builder(
            controller: _bannerPageController,
            itemCount: _banners.length,
            physics: const BouncingScrollPhysics(),
            pageSnapping: true,
            onPageChanged: (index) {
              setState(() => _currentBannerIndex = index);
              _pauseAutoSlide();
            },
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFffd700).withValues(alpha: isDark ? 0.4 : 0.3), width: 1.5),
                  boxShadow: isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                            spreadRadius: 2,
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CachedNetworkImage(
                          imageUrl: banner['image_url'] ?? '',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            decoration: BoxDecoration(
                              color: isDark ? null : Colors.white,
                              gradient: isDark
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppDesignSystem.primaryBackground,
                                        const Color(0xFF2D3748).withValues(alpha: 0.8),
                                        const Color(0xFF1A202C).withValues(alpha: 0.9),
                                      ],
                                    )
                                  : null,
                            ),
                            child: Center(child: _BouncingDotsLoader(isDark: isDark)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            decoration: BoxDecoration(
                              color: isDark ? null : Colors.white,
                              gradient: isDark
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppDesignSystem.primaryBackground,
                                        const Color(0xFF2D3748).withValues(alpha: 0.8),
                                        const Color(0xFF1A202C).withValues(alpha: 0.9),
                                      ],
                                    )
                                  : null,
                            ),
                            child: Center(child: _BouncingDotsLoader(isDark: isDark)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_banners.length > 1)
          Container(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _banners.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentBannerIndex == index ? 12 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentBannerIndex == index
                        ? const Color(0xFFffd700)
                        : const Color(0xFFffd700).withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // شريط البحث
  Widget _buildSearchBar(bool isDark) {
    final Color bgColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);
    final Color iconColor = const Color(0xFF8E8E93);
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color hintColor = isDark ? const Color(0xFF636366) : const Color(0xFFA0A0A5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        height: 44,
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.search_rounded, color: iconColor, size: 20),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.cairo(color: textColor, fontSize: 15, fontWeight: FontWeight.w500),
                textAlign: TextAlign.right,
                cursorColor: const Color(0xFFD4A853),
                cursorWidth: 1.5,
                onTap: () {
                  _searchController.selection = TextSelection.collapsed(offset: _searchController.text.length);
                },
                onChanged: (value) {
                  if (mounted) {
                    setState(() {});
                    _searchProducts(value);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'ابحث عن منتج...',
                  hintStyle: GoogleFonts.cairo(color: hintColor, fontSize: 15, fontWeight: FontWeight.w400),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  isDense: true,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  _searchProducts('');
                  setState(() {});
                },
                child: Container(
                  margin: const EdgeInsets.only(left: 8, right: 12),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF48484A) : const Color(0xFFD1D1D6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : const Color(0xFF636366), size: 14),
                ),
              )
            else
              const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  // حساب عدد الأعمدة الذكي
  int _getSmartColumnCount(double screenWidth) {
    if (screenWidth <= 400) return 2;
    if (screenWidth <= 600) return 2;
    if (screenWidth <= 900) return 3;
    if (screenWidth <= 1200) return 4;
    if (screenWidth <= 1600) return 5;
    return 6;
  }

  // بناء شبكة المنتجات
  List<Widget> _buildProductsSlivers(BuildContext context, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;

    final horizontalMargin = screenWidth > 600 ? 16.0 : (screenWidth > 400 ? 12.0 : 8.0);
    final crossAxisSpacing = screenWidth > 600 ? 14.0 : (screenWidth > 400 ? 10.0 : 6.0);
    final mainAxisSpacing = screenWidth > 600 ? 18.0 : (screenWidth > 400 ? 16.0 : 12.0);
    final int crossAxisCount = _getSmartColumnCount(screenWidth);

    if (_isLoadingProducts && _filteredProducts.isEmpty) {
      return [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: crossAxisSpacing,
              mainAxisSpacing: mainAxisSpacing,
              childAspectRatio: _calculateOptimalAspectRatio(context, crossAxisCount),
            ),
            delegate: SliverChildBuilderDelegate((context, index) => _buildSkeletonLoader(isDark), childCount: 10),
          ),
        ),
      ];
    }

    // عرض رسالة الخطأ مع زر إعادة المحاولة
    if (_hasError && _filteredProducts.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 300,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.red.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.wifi_off_rounded, size: 48, color: isDark ? Colors.red[300] : Colors.red[400]),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'فشل الاتصال بالخادم',
                    style: GoogleFonts.cairo(
                      color: isDark ? Colors.white70 : Colors.grey[700],
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'تحقق من اتصالك بالإنترنت وحاول مرة أخرى',
                      style: GoogleFonts.cairo(color: isDark ? Colors.white38 : Colors.grey[500], fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadProducts,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text('إعادة المحاولة', style: GoogleFonts.cairo(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFffd700),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    if (_filteredProducts.isEmpty) {
      final isSearching = _searchController.text.isNotEmpty;
      return [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 280,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSearching ? Icons.search_off_rounded : Icons.inventory_2_outlined,
                    size: 56,
                    color: isDark ? Colors.white30 : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isSearching ? 'لا توجد نتائج للبحث' : 'لا توجد منتجات متاحة',
                    style: GoogleFonts.cairo(
                      color: isDark ? Colors.white70 : Colors.grey[600],
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      isSearching ? 'جرب البحث بكلمات أخرى أو تصفح جميع المنتجات' : 'سيتم إضافة منتجات جديدة قريباً',
                      style: GoogleFonts.cairo(color: isDark ? Colors.white38 : Colors.grey[500], fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isSearching)
                    TextButton.icon(
                      onPressed: () {
                        _searchController.clear();
                        _searchProducts('');
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear, size: 18),
                      label: Text('مسح البحث', style: GoogleFonts.cairo(fontSize: 14)),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFFffd700)),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _loadProducts,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text('تحديث', style: GoogleFonts.cairo(fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFffd700),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
            childAspectRatio: _calculateOptimalAspectRatio(context, crossAxisCount),
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            if (index >= _filteredProducts.length) return null;
            final product = _filteredProducts[index];
            return AnimatedContainer(
              key: ValueKey(product.id),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: _buildProductCard(product, isDark),
            );
          }, childCount: _filteredProducts.length),
        ),
      ),
      if (_isLoadingMore)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator(color: Color(0xFFffd700), strokeWidth: 2)),
          ),
        ),
    ];
  }

  // بناء skeleton loader
  Widget _buildSkeletonLoader(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.04),
          width: 1,
        ),
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF5F5F7),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(17), topRight: Radius.circular(17)),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  color: const Color(0xFFffd700).withValues(alpha: 0.3),
                  strokeWidth: 1.5,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              color: isDark ? Colors.transparent : Colors.white,
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  Container(
                    height: 10,
                    width: 100,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // القياسات الثابتة للبطاقة
  static const double _cardTopPadding = 0.0;
  static const double _imageBottomSpacing = 3.0;
  static const double _nameHeight = 24.0;
  static const double _nameBottomSpacing = 2.0;
  static const double _priceBarHeight = 38.0;
  static const double _cardBottomPadding = 10.0;
  static const double _fixedElementsHeight =
      _imageBottomSpacing + _nameHeight + _nameBottomSpacing + _priceBarHeight + _cardBottomPadding;

  // حساب ارتفاع الصورة الذكي
  double _getSmartImageHeight(double cardWidth, double screenWidth) {
    double heightToWidthRatio;
    if (screenWidth <= 400) {
      heightToWidthRatio = 1.15;
    } else if (screenWidth <= 600) {
      heightToWidthRatio = 1.10;
    } else if (screenWidth <= 900) {
      heightToWidthRatio = 1.05;
    } else if (screenWidth <= 1200) {
      heightToWidthRatio = 1.0;
    } else {
      heightToWidthRatio = 0.95;
    }
    final imageHeight = cardWidth * heightToWidthRatio;
    return imageHeight.clamp(130.0, 300.0);
  }

  // حساب الارتفاع الكلي للبطاقة
  double _calculateCardHeight(double screenWidth, double cardWidth) {
    final imageHeight = _getSmartImageHeight(cardWidth, screenWidth);
    return _cardTopPadding + imageHeight + _fixedElementsHeight;
  }

  // حساب النسبة المثالية للبطاقة
  double _calculateOptimalAspectRatio(BuildContext context, [int? columns]) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    final horizontalMargin = screenWidth > 600 ? 16.0 : (screenWidth > 400 ? 12.0 : 8.0);
    final crossAxisSpacing = screenWidth > 600 ? 14.0 : (screenWidth > 400 ? 10.0 : 6.0);
    int actualColumns = columns ?? _getSmartColumnCount(screenWidth);

    final availableWidth = screenWidth - (horizontalMargin * 2);
    final totalSpacing = crossAxisSpacing * (actualColumns - 1);
    final cardWidth = (availableWidth - totalSpacing) / actualColumns;
    final cardHeight = _calculateCardHeight(screenWidth, cardWidth);

    return cardWidth / cardHeight;
  }

  // بناء شريط التبليغات الذكي
  Widget _buildSmartNotificationBar(Product product) {
    if (product.notificationTags.isEmpty) return const SizedBox.shrink();
    return _NotificationBarWidget(product: product);
  }

  // بناء بطاقة المنتج
  Widget _buildProductCard(Product product, bool isDark) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animationValue, child) {
        final screenWidth = MediaQuery.of(context).size.width;

        return Transform.translate(
          offset: Offset(0, 20 * (1 - animationValue)),
          child: Transform.scale(
            scale: 0.8 + (0.2 * animationValue),
            child: Opacity(
              opacity: animationValue,
              child: GestureDetector(
                onTap: () => context.push('/products/details/${product.id}'),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = constraints.maxWidth;
                      final double imageHeight = _getSmartImageHeight(cardWidth, screenWidth);

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
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
                            // منطقة الصورة
                            Positioned(
                              left: 0,
                              top: 0,
                              right: 0,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(18),
                                  topRight: Radius.circular(18),
                                ),
                                child: SizedBox(
                                  height: imageHeight,
                                  width: double.infinity,
                                  child: product.images.isNotEmpty
                                      ? Container(
                                          color: isDark ? Colors.transparent : Colors.white,
                                          child: _SmartProductImage(
                                            imageUrl: product.images.first,
                                            height: imageHeight,
                                            isDark: isDark,
                                          ),
                                        )
                                      : Container(
                                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                                          child: Icon(
                                            Icons.camera_alt_outlined,
                                            color: isDark ? Colors.white60 : Colors.grey,
                                            size: 50,
                                          ),
                                        ),
                                ),
                              ),
                            ),

                            // شريط عدد القطع
                            Positioned(
                              left: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppDesignSystem.goldColor.withValues(alpha: 0.9),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(17),
                                    bottomRight: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.inventory_2_rounded, color: Colors.black, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${product.availableFrom}-${product.availableTo}',
                                      style: GoogleFonts.cairo(
                                        color: Colors.black,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // شريط التبليغات
                            if (product.notificationTags.isNotEmpty)
                              Positioned(right: 0, top: 0, child: _buildSmartNotificationBar(product)),

                            // اسم المنتج
                            Positioned(
                              left: 6,
                              right: 6,
                              top: imageHeight + _imageBottomSpacing,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.12)
                                        : Colors.black.withValues(alpha: 0.04),
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

                            // شريط السعر والأزرار
                            Positioned(
                              left: 5,
                              right: 5,
                              top: imageHeight + _imageBottomSpacing + _nameHeight + _nameBottomSpacing,
                              child: Container(
                                padding: const EdgeInsets.only(left: 8, right: 8, top: 2, bottom: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF5F5F7),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.12)
                                        : Colors.black.withValues(alpha: 0.04),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // السعر
                                    Container(
                                      constraints: const BoxConstraints(maxWidth: 80),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.12)
                                              : Colors.black.withValues(alpha: 0.04),
                                          width: 1,
                                        ),
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
                                        Transform.scale(scale: 0.75, child: _buildAnimatedAddButton(product, isDark)),
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
              ),
            ),
          ),
        );
      },
    );
  }

  // زر الإضافة للسلة
  Widget _buildAnimatedAddButton(Product product, bool isDark) {
    final cart = context.watch<CartService>();
    bool isInCart = cart.hasProduct(product.id);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (!isInCart) {
          cart.addItemSync(
            productId: product.id,
            name: product.name,
            image: product.images.isNotEmpty ? product.images.first : '',
            minPrice: product.minPrice.toInt(),
            maxPrice: product.maxPrice.toInt(),
            customerPrice: 0,
            wholesalePrice: product.wholesalePrice.toInt(),
            quantity: 1,
          );
        } else {
          cart.removeByProductId(product.id);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isInCart
              ? const Color(0xFF22C55E)
              : (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.06)),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isInCart ? Icons.check_rounded : Icons.add_rounded,
          color: isInCart ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
          size: 20,
        ),
      ),
    );
  }

  // زر القلب - يستخدم Consumer لتجنب إعادة بناء الصفحة كاملة
  Widget _buildHeartButton(Product product, bool isDark) {
    return Consumer<FavoritesService>(
      builder: (context, favoritesService, _) {
        bool isLiked = favoritesService.isFavorite(product.id);

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            favoritesService.toggleFavoriteSync(product);
            // لا حاجة لـ setState - Consumer يعيد البناء تلقائياً
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isLiked
                  ? const Color(0xFFEF4444)
                  : (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.06)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isLiked ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
              size: 17,
            ),
          ),
        );
      },
    );
  }
}

// ويدجت شريط التبليغات - بدون Timer
class _NotificationBarWidget extends StatelessWidget {
  final Product product;

  const _NotificationBarWidget({required this.product});

  @override
  Widget build(BuildContext context) {
    final tags = product.notificationTags;
    if (tags.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF6B73FF).withValues(alpha: 0.9), const Color(0xFF9D4EDD).withValues(alpha: 0.8)],
        ),
        borderRadius: const BorderRadius.only(topRight: Radius.circular(17), bottomLeft: Radius.circular(12)),
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
            tags.first,
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
