import 'dart:async';
import 'dart:convert';

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
import '../services/cart_service.dart';
import '../services/favorites_service.dart';
import '../services/user_service.dart';
import '../utils/font_helper.dart';
import '../utils/theme_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/drawer_menu.dart';
import '../widgets/sliding_drawer.dart';

// 🧠 كاش بسيط لصور المنتجات داخل جلسة التطبيق
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

// 🔁 ويدجت ذكية لعرض صورة المنتج مع إعادة المحاولة التلقائية + الكاش
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
          child: Icon(Icons.camera_alt_outlined, color: widget.isDark ? Colors.white60 : Colors.grey, size: 50),
        );
      },
    );
  }
}

class NewProductsPage extends StatefulWidget {
  const NewProductsPage({super.key});

  @override
  State<NewProductsPage> createState() => _NewProductsPageState();
}

class _NewProductsPageState extends State<NewProductsPage> with SingleTickerProviderStateMixin {
  final CartService _cartService = CartService();
  final FavoritesService _favoritesService = FavoritesService.instance;
  final SlidingDrawerController _drawerController = SlidingDrawerController();
  List<Product> _products = [];
  bool _isLoadingProducts = false;

  // بيانات المستخدم
  String _firstName = 'صديقي';
  String _phoneNumber = '+964 770 123 4567';

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

  // 📄 نظام Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  bool _isLoadingMore = false;
  bool _hasMoreProducts = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _initializeUserData();
    _loadBanners();
    _setupScrollListener();
    _loadFavorites();
  }

  // 📄 إعداد listener للـ scroll لتحميل المزيد من المنتجات
  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (!mounted) return;

      try {
        // التحقق من الوصول للنهاية
        if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 500) {
          if (!_isLoadingProducts && !_isLoadingMore && _hasMoreProducts) {
            _loadMoreProducts();
          }
        }
      } catch (e) {
        debugPrint('❌ خطأ في scroll listener: $e');
      }
    });
  }

  @override
  void dispose() {
    try {
      // إلغاء جميع المؤقتات
      _bannerTimer?.cancel();
      _searchDebounceTimer?.cancel();

      // تنظيف الـ controllers
      _bannerPageController.dispose();
      _searchController.dispose();
      _scrollController.dispose();
    } catch (e) {
      debugPrint('❌ خطأ في تنظيف الموارد: $e');
    }
    super.dispose();
  }

  // تحميل المفضلة
  Future<void> _loadFavorites() async {
    try {
      await _favoritesService.loadFavorites();
      if (mounted) {
        setState(() {}); // تحديث الواجهة لإظهار حالة المفضلة
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل المفضلة: $e');
    }
  }

  // تهيئة بيانات المستخدم (تحميل من قاعدة البيانات مرة واحدة فقط)
  Future<void> _initializeUserData() async {
    try {
      // التحقق من وجود بيانات محفوظة
      final isDataSaved = await UserService.isUserDataSaved();

      if (!isDataSaved) {
        debugPrint('🔄 تحميل بيانات المستخدم من قاعدة البيانات...');
        await UserService.loadAndSaveUserData();
      } else {
        debugPrint('✅ استخدام البيانات المحفوظة محلياً');
      }

      // جلب البيانات من التخزين المحلي
      await _loadLocalUserData();
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة بيانات المستخدم: $e');
    }
  }

  // جلب البيانات من التخزين المحلي
  Future<void> _loadLocalUserData() async {
    try {
      final firstName = await UserService.getFirstName();
      final phoneNumber = await UserService.getPhoneNumber();

      if (mounted) {
        setState(() {
          _firstName = firstName;
          _phoneNumber = phoneNumber;
        });
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب البيانات المحلية: $e');
    }
  }

  // تحميل البانرات الإعلانية عبر الباك إند
  Future<void> _loadBanners() async {
    if (!mounted) return;

    setState(() {
      _isLoadingBanners = true;
    });

    try {
      final uri = Uri.parse('${ApiConfig.productsUrl}/banners');
      final response = await http.get(uri, headers: ApiConfig.defaultHeaders).timeout(ApiConfig.defaultTimeout);

      if (response.statusCode != 200) {
        debugPrint('❌ فشل في تحميل البانرات: ${response.statusCode}');
        debugPrint('📥 Response body: ${response.body}');
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
        debugPrint('❌ فشل في تحميل البانرات: ${jsonData['error'] ?? 'خطأ غير معروف'}');
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

        // بدء التقليب التلقائي إذا كان هناك أكثر من بانر واحد
        // تأخير قصير للتأكد من أن PageView تم بناؤه
        if (_banners.length > 1) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _startAutoSlide();
            }
          });
        }
      }

      debugPrint('✅ تم تحميل ${_banners.length} بانر إعلاني');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل البانرات: $e');
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

      // التأكد من أن PageController متصل بـ PageView قبل محاولة التحريك
      if (!_bannerPageController.hasClients) {
        return;
      }

      final currentPage = _bannerPageController.page?.round() ?? 0;
      final nextPage = (currentPage + 1) % _banners.length;

      _bannerPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  // إيقاف التقليب التلقائي مؤقتاً عند التفاعل اليدوي
  void _pauseAutoSlide() {
    _bannerTimer?.cancel();
    // إعادة تشغيل التقليب بعد 3 ثواني من التوقف
    Timer(const Duration(seconds: 3), () {
      if (mounted && _banners.length > 1) {
        _startAutoSlide();
      }
    });
  }

  // دالة لتنسيق الأرقام بالفواصل
  String _formatPrice(double price) {
    final formatter = NumberFormat('#,###');
    return formatter.format(price.toInt());
  }

  // 📄 تحميل المنتجات الأولى (10 منتجات فقط)
  Future<void> _loadProducts() async {
    if (!mounted) return;

    setState(() {
      _isLoadingProducts = true;
      _currentPage = 1;
      _products = [];
      _filteredProducts = [];
      _hasMoreProducts = true;
    });

    try {
      final uri = Uri.parse(
        ApiConfig.productsUrl,
      ).replace(queryParameters: {'page': '$_currentPage', 'limit': '$_itemsPerPage'});

      final response = await http.get(uri, headers: ApiConfig.defaultHeaders).timeout(ApiConfig.defaultTimeout);

      if (response.statusCode != 200) {
        debugPrint('❌ فشل في تحميل المنتجات: ${response.statusCode}');
        debugPrint('📥 Response body: ${response.body}');
        if (mounted) {
          setState(() {
            _isLoadingProducts = false;
            _hasMoreProducts = false;
          });
        }
        return;
      }

      final jsonData = jsonDecode(response.body);
      if (jsonData['success'] != true) {
        debugPrint('❌ فشل في تحميل المنتجات: ${jsonData['error'] ?? 'خطأ غير معروف'}');
        if (mounted) {
          setState(() {
            _isLoadingProducts = false;
            _hasMoreProducts = false;
          });
        }
        return;
      }

      final List<dynamic> data = jsonData['data']?['products'] ?? [];
      final products = data.map<Product>((json) => Product.fromJson(json)).toList();
      final availableProducts = products.where((product) => product.availableQuantity > 0).toList();

      if (mounted) {
        setState(() {
          _products = availableProducts;
          _filteredProducts = List.from(availableProducts);
          _isLoadingProducts = false;
          _hasMoreProducts = products.length >= _itemsPerPage;
        });
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل المنتجات: $e');
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
          _hasMoreProducts = false;
        });
      }
    }
  }

  // 📄 تحميل المزيد من المنتجات
  Future<void> _loadMoreProducts() async {
    if (!mounted || _isLoadingProducts || _isLoadingMore || !_hasMoreProducts) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      _currentPage++;
      final uri = Uri.parse(
        ApiConfig.productsUrl,
      ).replace(queryParameters: {'page': '$_currentPage', 'limit': '$_itemsPerPage'});

      final response = await http.get(uri, headers: ApiConfig.defaultHeaders).timeout(ApiConfig.defaultTimeout);

      if (response.statusCode != 200) {
        debugPrint('❌ فشل في تحميل المزيد من المنتجات: ${response.statusCode}');
        debugPrint('📥 Response body: ${response.body}');
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
        debugPrint('❌ فشل في تحميل المزيد من المنتجات: ${jsonData['error'] ?? 'خطأ غير معروف'}');
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
          _filteredProducts = List.from(_products);
          _isLoadingMore = false;
          _hasMoreProducts = newProducts.length >= _itemsPerPage;
        });
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل المزيد من المنتجات: $e');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _hasMoreProducts = false;
        });
      }
    }
  }

  // 🔍 البحث البسيط في المنتجات
  void _searchProducts(String query) {
    if (!mounted) return;

    try {
      _searchDebounceTimer?.cancel();
      _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (!mounted) return;

        List<Product> filtered;
        if (query.isEmpty) {
          filtered = List.from(_products);
        } else {
          final searchQuery = query.toLowerCase().trim();
          filtered = _products.where((product) => product.name.toLowerCase().contains(searchQuery)).toList();
        }

        if (mounted) {
          setState(() {
            _filteredProducts = filtered;
          });
        }
      });
    } catch (e) {
      debugPrint('❌ خطأ في البحث: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    return SlidingDrawer(
      controller: _drawerController,
      menuWidthFactor: 0.68,
      endScale: 0.85,
      rotationDegrees: -3,
      backgroundColor: isDark ? const Color(0xFF1a1a2e) : const Color(0xFF2c3e50),
      shadowColor: const Color(0xFFffd700),
      menu: DrawerMenu(
        onClose: () {
          _drawerController.toggle();
        },
      ),
      child: Scaffold(
        // 🎨 خلفية شفافة تماماً للوضع النهاري - لإظهار البطاقات بوضوح
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: AppBackground(
          child: Stack(
            children: [
              // 🎨 الخلفية الموحدة للوضع النهاري (backgroundPage = #F5F5F7)
              if (!isDark)
                Container(
                  color: const Color(0xFFF5F5F7), // خلفية نهارية موحدة ناعمة جداً
                ),
              // المحتوى الرئيسي باستخدام CustomScrollView + Slivers لأداء أفضل
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 25)),
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildMainBanner()),
                  SliverToBoxAdapter(child: _buildSearchBar()),
                  ..._buildProductsSlivers(context),
                  const SliverToBoxAdapter(child: SizedBox(height: 160)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // بناء الشريط العلوي
  Widget _buildHeader() {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    // الحصول على التحية المناسبة
    final greetingData = UserService.getGreeting();
    final greeting = greetingData['greeting']!;
    final emoji = greetingData['emoji']!;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12), // تقليل padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الصف العلوي - التحية، العنوان، والأزرار
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // التحية (اليسار)
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$greeting $_firstName ',
                            style: GoogleFonts.cairo(
                              color: ThemeColors.textColor(isDark),
                              fontSize: 9, // تصغير من 11 إلى 9
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: emoji,
                            style: const TextStyle(
                              fontSize: 11, // تصغير من 14 إلى 11
                              fontFamily: null, // استخدام الخط الافتراضي للإيموجي
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2), // تقليل من 4 إلى 2
                    // رقم الهاتف
                    Text(
                      _phoneNumber,
                      style: GoogleFonts.cairo(
                        color: ThemeColors.secondaryTextColor(isDark),
                        fontSize: 7, // تصغير من 9 إلى 7
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // عنوان "منتجاتي" (الوسط)
              Expanded(
                flex: 3,
                child: Center(
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        const Color(0xFFFFD700), // ذهبي فاتح
                        const Color(0xFFFFA500), // برتقالي ذهبي
                        const Color(0xFFB8860B), // ذهبي داكن
                        const Color(0xFFDAA520), // ذهبي متوسط
                      ],
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
              // زر القائمة (اليمين)
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // زر القائمة الجانبية
                    GestureDetector(
                      onTap: () {
                        _drawerController.toggle();
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFffd700).withValues(alpha: 0.9),
                              const Color(0xFFffa500).withValues(alpha: 0.8),
                              const Color(0xFFff8c00).withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.6), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFffd700).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                              spreadRadius: 1,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // بناء البانر الرئيسي
  Widget _buildMainBanner() {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

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
              // مؤشر تحميل مخصص جميل
              Stack(
                alignment: Alignment.center,
                children: [
                  // الدائرة الخارجية
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFffd700).withValues(alpha: 0.3)),
                    ),
                  ),
                  // الدائرة الداخلية
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFffd700)),
                    ),
                  ),
                  // أيقونة في المنتصف
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
              // نص التحميل
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
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, const Color(0xFFF8F8F8)],
                  stops: const [0.0, 1.0],
                ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFffd700).withValues(alpha: isDark ? 0.4 : 0.3), // إطار ذهبي أقوى
            width: isDark ? 1.5 : 1.5,
          ),
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
              setState(() {
                _currentBannerIndex = index;
              });
              // إيقاف التقليب التلقائي مؤقتاً عند السحب اليدوي
              _pauseAutoSlide();
            },
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFffd700).withValues(alpha: isDark ? 0.4 : 0.3), // إطار ذهبي أقوى
                    width: isDark ? 1.5 : 1.5,
                  ),
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
                      // صورة البانر بأفضل جودة مع كاش داخلي
                      Positioned.fill(
                        child: Image(
                          image: _ProductImageCache.get(banner['image_url'] ?? ''),
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
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
                              child: Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 50,
                                      height: 50,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                            : null,
                                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFffd700)),
                                        backgroundColor: const Color(0xFFffd700).withValues(alpha: 0.2),
                                      ),
                                    ),
                                    const Icon(Icons.image, color: Color(0xFFffd700), size: 20),
                                  ],
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
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
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.red.withValues(alpha: 0.3), width: 2),
                                      ),
                                      child: const Icon(Icons.error_outline, color: Colors.red, size: 30),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'خطأ في تحميل الصورة',
                                      style: GoogleFonts.cairo(
                                        color: Colors.red.withValues(alpha: 0.8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // مؤشرات النقاط إذا كان هناك أكثر من بانر واحد
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

  // بناء شريط البحث الأصلي
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: _buildOriginalSearchBar(),
    );
  }

  // شريط البحث الأصلي - التصميم الكامل
  Widget _buildOriginalSearchBar() {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    return Container(
      height: 55,
      decoration: BoxDecoration(
        // 🎨 في الوضع الليلي يبقى التصميم الغني كما هو، في النهاري نستخدم سطح حيادي ناعم
        color: isDark ? null : const Color(0xFFF3F4F6), // surfaceSubtle للبحث والفلاتر
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
          color: isDark
              ? AppDesignSystem.goldColor.withValues(alpha: 0.4)
              : const Color(0xFFE5E7EB), // borderSubtle في النهار
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
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.cairo(
            color: isDark ? AppDesignSystem.primaryTextColor : const Color(0xFF111827), // textPrimary
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.right,
          onTap: () {
            // وضع المؤشر في النهاية عند النقر لتجنب تحديد النص
            final text = _searchController.text;
            _searchController.selection = TextSelection.collapsed(offset: text.length);
          },
          onChanged: (value) {
            if (mounted) {
              try {
                _searchProducts(value);
              } catch (e) {
                debugPrint('❌ خطأ في البحث من الشريط الأصلي: $e');
              }
            }
          },
          decoration: InputDecoration(
            hintText: 'ابحث عن المنتجات...',
            hintStyle: GoogleFonts.cairo(
              color: isDark
                  ? AppDesignSystem.primaryTextColor.withValues(alpha: 0.6)
                  : const Color(0xFF9CA3AF), // textMuted
              fontSize: 14,
            ),
            prefixIcon: Container(
              padding: const EdgeInsets.all(14),
              child: Icon(
                Icons.search_rounded,
                color: isDark
                    ? AppDesignSystem.goldColor.withValues(alpha: 0.9)
                    : const Color(0xFFFFC727), // brandPrimary
                size: AppDesignSystem.largeIconSize,
              ),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      _searchProducts('');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      child: Icon(
                        Icons.clear_rounded,
                        color: isDark ? AppDesignSystem.secondaryTextColor : const Color(0xFF6B7280), // textSecondary
                        size: AppDesignSystem.mediumIconSize,
                      ),
                    ),
                  )
                : null,
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ),
    );
  }

  // بناء شبكة المنتجات باستخدام Slivers لأداء أفضل
  List<Widget> _buildProductsSlivers(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalMargin = screenWidth > 400 ? 16.0 : (screenWidth > 350 ? 14.0 : 12.0);
    final crossAxisSpacing = screenWidth > 400 ? 12.0 : (screenWidth > 350 ? 10.0 : 8.0);
    final mainAxisSpacing = screenWidth > 400 ? 20.0 : (screenWidth > 350 ? 18.0 : 16.0);
    final int crossAxisCount = screenWidth > 600 ? 3 : 2;

    // 📦 عند التحميل الأول - عرض skeleton loaders داخل SliverGrid
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

    if (_filteredProducts.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 200,
            child: Center(
              child: Text(
                _searchController.text.isNotEmpty
                    ? 'لا توجد نتائج للبحث "${_searchController.text}"'
                    : 'لا توجد منتجات متاحة',
                style: GoogleFonts.cairo(color: isDark ? Colors.white70 : Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
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
              child: _buildProductCard(product),
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

  // 📦 بناء skeleton loader
  Widget _buildSkeletonLoader(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE5E7EB), // borderSubtle
          width: 1,
        ),
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        gradient: isDark ? null : null,
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
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.08), // لون أفتح قليلاً
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
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
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.withValues(alpha: 0.12), // لون أفتح قليلاً
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  Container(
                    height: 10,
                    width: 100,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.withValues(alpha: 0.12), // لون أفتح قليلاً
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

  // 🧠 النظام الذكي القوي لحساب النسبة المثالية للبطاقة
  // ✨ القياسات الثابتة للعناصر داخل البطاقة - لا تتغير أبداً
  static const double _cardTopPadding = 22.0; // المسافة من الأعلى
  static const double _imageHeight = 200.0; // ارتفاع الصورة ثابت
  static const double _imageBottomSpacing = -5.0; // المسافة بين الصورة والاسم
  static const double _nameHeight = 27.0; // ارتفاع شريط الاسم (padding + text)
  static const double _nameBottomSpacing = 0.0; // المسافة بين الاسم والسعر
  static const double _priceBarHeight = 40.0; // ارتفاع شريط السعر (vertical padding 3×2 + content 32 + border 1×2 = 40)
  static const double _cardBottomPadding = 15.0; // المسافة من الأسفل (مسافة أكبر لمنع القطع)

  // 🎯 حساب الارتفاع الكلي للبطاقة بذكاء - مجموع كل العناصر
  //    باستخدام ارتفاع صورة يعتمد على عرض البطاقة نفسه (نظام مرن لكل الشاشات)
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

  // 🧠 دالة مساعدة ذكية لحساب ارتفاع الصورة حسب عرض البطاقة وحجم الشاشة
  //    - في الهواتف الصغيرة: نجعل الصورة أطول قليلاً لتملأ البطاقة بقوة
  //    - في الهواتف المتوسطة والكبيرة: نحافظ على توازن جميل بين الصورة والباقي
  double _getImageHeightForCard(double cardWidth, double screenWidth) {
    // النسبة الأساسية بين عرض البطاقة وارتفاع الصورة
    double factor;

    if (cardWidth < 160) {
      // بطاقات ضيقة جداً (هواتف صغيرة) ⇒ نكبر الصورة أكثر
      factor = 1.15; // الصورة أعلى من العرض بقليل
    } else if (cardWidth < 190) {
      // بطاقات متوسطة (أغلب الهواتف العادية)
      factor = 1.05;
    } else {
      // بطاقات عريضة (هواتف كبيرة / شاشات واسعة)
      factor = 0.95;
    }

    // تعديل بسيط جداً حسب عرض الشاشة بالكامل
    if (screenWidth < 360) {
      // هواتف أصغر من المعتاد ⇒ تكبير إضافي بسيط للصورة
      factor += 0.05;
    } else if (screenWidth > 600) {
      // شاشات كبيرة مع 3 أعمدة ⇒ نقلل الارتفاع قليلاً حتى لا تكون البطاقة طويلة جداً
      factor -= 0.05;
    }

    final double dynamicHeight = cardWidth * factor;

    // ضمان أن يبقى الارتفاع في مدى منطقي (قريب من القيمة الأساسية 200)
    const double minHeight = _imageHeight * 0.9; // 180
    const double maxHeight = _imageHeight * 1.3; // 260

    return dynamicHeight.clamp(minHeight, maxHeight).toDouble();
  }

  // 🧠 حساب النسبة المثالية للبطاقة بناءً على حجم الشاشة
  double _calculateOptimalAspectRatio(BuildContext context, [int? columns]) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    // 🎯 حساب المسافات والأعمدة
    final horizontalMargin = screenWidth > 400 ? 16.0 : (screenWidth > 350 ? 14.0 : 12.0);
    final crossAxisSpacing = screenWidth > 400 ? 12.0 : (screenWidth > 350 ? 10.0 : 8.0);

    // 🧠 تحديد عدد الأعمدة
    int actualColumns = columns ?? 2;

    // 🎯 حساب عرض البطاقة الواحدة
    final availableWidth = screenWidth - (horizontalMargin * 2);
    final totalSpacing = crossAxisSpacing * (actualColumns - 1);
    final cardWidth = (availableWidth - totalSpacing) / actualColumns;

    // 🎯 حساب ارتفاع البطاقة من النظام الذكي اعتماداً على عرض البطاقة الفعلي
    final cardHeight = _calculateCardHeight(screenWidth, cardWidth);

    // 🎯 النسبة = العرض / الارتفاع
    final aspectRatio = cardWidth / cardHeight;

    return aspectRatio;
  }

  // 🎯 بناء شريط التبليغات الذكي مع تأثير التقليب
  Widget _buildSmartNotificationBar(Product product) {
    // حماية إضافية من القيم الفارغة
    if (product.notificationTags.isEmpty) {
      return const SizedBox.shrink();
    }
    return _NotificationBarWidget(product: product);
  }

  // بناء بطاقة المنتج - تصميم ملفت ومبهر 🎨✨
  Widget _buildProductCard(Product product) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animationValue, child) {
        // 📱 قياس الشاشة (نستخدمها مع عرض البطاقة لحساب ارتفاع الصورة بدقة)
        final screenWidth = MediaQuery.of(context).size.width;

        return Transform.translate(
          offset: Offset(0, 20 * (1 - animationValue)), // 🌊 تأثير الانزلاق من الأسفل
          child: Transform.scale(
            scale: 0.8 + (0.2 * animationValue), // 🎭 تأثير التكبير التدريجي
            child: Opacity(
              opacity: animationValue, // ✨ تأثير الظهور التدريجي
              child: GestureDetector(
                onTap: () {
                  context.go('/products/details/${product.id}');
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = constraints.maxWidth;
                      final double imageHeight = _getImageHeightForCard(cardWidth, screenWidth);

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        // إزالة الأبعاد الثابتة لتتكيف مع النسبة الذكية
                        margin: const EdgeInsets.only(right: 5, bottom: 0), // تقليل المسافة الجانبية
                        clipBehavior: Clip.none, // عدم قطع المحتوى - لضمان ظهور شريط السعر كاملاً
                        decoration: BoxDecoration(
                          // 🎨 تصميم عالمي لبطاقة المنتج في الوضع النهاري
                          color: isDark ? null : Colors.white,
                          gradient: isDark
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.06), // شفاف أكثر
                                    Colors.white.withValues(alpha: 0.03), // شفاف جداً
                                    const Color(0xFF1A1F2E).withValues(alpha: 0.2), // يتناسق مع الخلفية
                                  ],
                                  stops: [0.0, 0.5, 1.0],
                                )
                              : null,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.black.withValues(alpha: 0.04), // 🧱 Hairline Border عالمي
                            width: 1,
                          ),
                          boxShadow: isDark
                              ? []
                              : [
                                  // 🫧 Shadow خفي جداً يبرز البطاقة مثل Shein/AliExpress
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                        ),
                        child: Stack(
                          children: [
                            // شريط عدد القطع - تصميم بسيط وجميل في الزاوية
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
                                    Icon(
                                      Icons.inventory_2_rounded,
                                      color: Colors.black,
                                      size: 12, // أصغر قليلاً
                                    ),
                                    const SizedBox(width: 4), // مسافة أصغر
                                    Text(
                                      '${product.availableFrom}-${product.availableTo}',
                                      style: GoogleFonts.cairo(
                                        color: Colors.black,
                                        fontSize: 10, // أصغر قليلاً
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // 🎯 شريط التبليغات الذكي - يظهر فقط إذا كان هناك تبليغات
                            if (product.notificationTags.isNotEmpty)
                              Positioned(right: 0, top: 0, child: _buildSmartNotificationBar(product)),

                            // منطقة الصورة - القياس الأصلي مع مسافة مناسبة من الحواف
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
                                      // منطقة الصورة موسعة لحد البطاقة
                                      Positioned(
                                        top: 0,
                                        left: 0,
                                        right: 0,
                                        height: imageHeight, // 🎯 من الثوابت (متغيرة حسب حجم الشاشة)
                                        child: product.images.isNotEmpty
                                            ? Container(
                                                width: double.infinity,
                                                height: imageHeight,
                                                color: isDark
                                                    ? Colors.transparent
                                                    : Colors.white, // 🎯 خلفية بيضاء للصور الشفافة في الوضع النهاري
                                                child: _CachedAutoRetryProductImage(
                                                  imageUrl: product.images.first,
                                                  height: imageHeight,
                                                  isDark: isDark,
                                                ),
                                              )
                                            : Container(
                                                height: imageHeight, // 🎯 من الثوابت (متغيّرة حسب حجم الشاشة)
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? Colors.white.withValues(alpha: 0.05)
                                                      : Colors.white, // 🎯 خلفية بيضاء في الوضع النهاري
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                child: Icon(
                                                  Icons.camera_alt_outlined,
                                                  color: isDark
                                                      ? Colors.white60
                                                      : Colors.grey, // 🎯 لون واضح في الوضع النهاري
                                                  size: 50,
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // اسم المنتج أسفل الصورة مباشرة مع مسافة قليلة جداً
                            Positioned(
                              left: 6,
                              right: 6,
                              top:
                                  _cardTopPadding +
                                  imageHeight +
                                  _imageBottomSpacing, // 🎯 حساب ذكي من الثوابت (تأخذ تكبير الصورة في الهواتف الصغيرة)
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ), // تقليل padding العمودي
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDark
                                        ? [
                                            const Color(0xFF1A1F2E).withValues(alpha: 0.7), // متناسق مع الخلفية الليلية
                                            const Color(0xFF0F1419).withValues(alpha: 0.4), // متناسق مع الخلفية الليلية
                                          ]
                                        : [
                                            Colors.white.withValues(alpha: 0.95), // خلفية بيضاء في الوضع النهاري
                                            Colors.white.withValues(alpha: 0.9), // خلفية بيضاء في الوضع النهاري
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.grey.withValues(alpha: 0.2), // حدود أوضح في الوضع النهاري
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  product.name,
                                  style: FontHelper.cairo(
                                    color: ThemeColors.textColor(isDark),
                                    fontSize: 12, // إرجاع الحجم الأصلي
                                    fontWeight: FontWeight.w700,
                                    height: 1.2, // إرجاع الارتفاع الأصلي
                                  ),
                                  maxLines: 1, // سطر واحد فقط مع النقاط
                                  overflow: TextOverflow.ellipsis, // تحويل إلى ...
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),

                            // السعر وزر القلب وزر الإضافة - أسفل اسم المنتج مباشرة
                            Positioned(
                              left: 5,
                              right: 5,
                              top:
                                  _cardTopPadding +
                                  imageHeight +
                                  _imageBottomSpacing +
                                  _nameHeight +
                                  _nameBottomSpacing, // 🎯 حساب ذكي من الثوابت (يتبع تكبير الصورة في الهواتف الصغيرة)
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ), // تقليل الـ padding العمودي لتقليل ارتفاع الشريط
                                decoration: BoxDecoration(
                                  // 🎨 شريط السعر كـ surfaceSubtle في النهار
                                  color: isDark ? null : const Color(0xFFF3F4F6),
                                  gradient: isDark
                                      ? LinearGradient(
                                          colors: [
                                            Colors.black.withValues(alpha: 0.4),
                                            Colors.black.withValues(alpha: 0.2),
                                          ],
                                        )
                                      : null,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : const Color(0xFFE5E7EB), // borderSubtle في النهار
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // السعر على اليسار - عرض محدد لمنع الدفع
                                    Container(
                                      constraints: const BoxConstraints(maxWidth: 80), // عرض محدد
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.black.withValues(alpha: 0.6)
                                            : const Color(0xFFF1F1F1), // بطاقة السعر في الوضع النهاري
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
                                          fontSize: 12, // أصغر قليلاً
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),

                                    // مساحة مرنة لدفع الأزرار لليمين
                                    const Spacer(),

                                    // الأزرار في أقصى اليمين ملاصقين تماماً
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // زر القلب - أكبر قليلاً
                                        Transform.scale(scale: 0.85, child: _buildHeartButton(product)),

                                        // زر الإضافة ملاصق للقلب تماماً - أكبر قليلاً
                                        Transform.scale(scale: 0.75, child: _buildAnimatedAddButton(product)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ), // إغلاق Stack
                      ); // إغلاق AnimatedContainer (return AnimatedContainer)
                    }, // إغلاق LayoutBuilder.builder
                  ), // إغلاق LayoutBuilder
                ), // إغلاق ClipRRect
              ), // إغلاق GestureDetector
            ), // إغلاق Opacity
          ), // إغلاق Transform.scale
        ); // إغلاق Transform.translate
      }, // إغلاق builder
    ); // إغلاق TweenAnimationBuilder
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
        width: 40, // عرض ثابت لا يتغير
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
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: isInCart
                    ? TweenAnimationBuilder<double>(
                        key: const ValueKey('added'),
                        duration: const Duration(milliseconds: 600),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
                          );
                        },
                      )
                    : const Icon(key: ValueKey('add'), Icons.add_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // زر القلب المتحرك الرهيب 💖 - محدث ليستخدم FavoritesService
  Widget _buildHeartButton(Product product) {
    // تتبع حالة الإعجاب من FavoritesService
    bool isLiked = _favoritesService.isFavorite(product.id);
    bool isDark = Provider.of<ThemeProvider>(context).isDarkMode; // 🎯 تحديد الوضع من ThemeProvider

    return GestureDetector(
      onTap: () async {
        try {
          // تأثير اهتزاز فوري
          HapticFeedback.lightImpact();

          // تبديل حالة المفضلة
          final success = await _favoritesService.toggleFavorite(product);

          if (success && mounted) {
            setState(() {}); // تحديث الواجهة

            // إظهار رسالة تأكيد
            final message = isLiked ? 'تم إزالة ${product.name} من المفضلة' : 'تم إضافة ${product.name} للمفضلة';

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  message,
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                backgroundColor: isLiked ? Colors.red : Colors.green,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          debugPrint('❌ خطأ في تبديل المفضلة: $e');
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: isLiked
              ? const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFF5252), Color(0xFFE91E63)])
              : (isDark
                    ? LinearGradient(
                        colors: [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.05)],
                      )
                    : LinearGradient(colors: [Colors.white, Colors.grey.shade50])), // 🎯 خلفية بيضاء في الوضع النهاري
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isLiked
                ? Colors.white.withValues(alpha: 0.3)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.4)), // 🎯 إطار رمادي واضح في الوضع النهاري
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isLiked
                  ? Colors.red.withValues(alpha: 0.4)
                  : (isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.3)), // 🎯 ظل رمادي في الوضع النهاري
              blurRadius: isLiked ? 15 : 8,
              offset: const Offset(0, 4),
            ),
            if (isLiked)
              BoxShadow(color: Colors.red.withValues(alpha: 0.2), blurRadius: 25, offset: const Offset(0, 8)),
          ],
        ),
        child: AnimatedScale(
          scale: isLiked ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isLiked
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.grey.shade600), // 🎯 لون رمادي واضح في الوضع النهاري
            size: isLiked ? 18 : 16,
          ),
        ),
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
        customerPrice: 0, // سعر فارغ عند الإضافة من بطاقة المنتج
        wholesalePrice: product.wholesalePrice.toInt(),
        quantity: 1,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم إضافة ${product.name} إلى السلة',
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
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
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
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
    // بدء التقليب التلقائي إذا كان هناك أكثر من تبليغ واحد
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
    // 🎯 حماية مضاعفة من القيم الفارغة
    final tags = widget.product.notificationTags;
    if (tags.isEmpty || currentIndex >= tags.length) {
      return const SizedBox.shrink();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Container(
        key: ValueKey(tags[currentIndex]), // مفتاح فريد لكل تبليغ
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6B73FF).withValues(alpha: 0.9), // بنفسجي متناسق
              const Color(0xFF9D4EDD).withValues(alpha: 0.8), // بنفسجي فاتح
            ],
          ),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(24), // يتبع زاوية البطاقة
            bottomLeft: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(color: const Color(0xFF6B73FF).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.campaign_rounded, // أيقونة التبليغ
              color: Colors.white,
              size: 12,
            ),
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
