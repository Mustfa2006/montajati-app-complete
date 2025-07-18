// صفحة المنتجات المتقدمة - Advanced Products Page
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../services/cart_service.dart';
import '../services/real_auth_service.dart';
import '../widgets/pull_to_refresh_wrapper.dart';
import '../utils/error_handler.dart';
import '../services/favorites_service.dart';
import '../services/scheduled_orders_service.dart';
import '../models/product.dart';
import '../utils/number_formatter.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../widgets/common_header.dart';

// تعداد أوضاع التطبيق
enum AppMode { day, night }

// نموذج البانر الإعلاني
class AdvertisementBanner {
  final String id;
  final String title;
  final String imageUrl;
  final bool isActive;

  AdvertisementBanner({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.isActive = true,
  });
}

class NewProductsPage extends StatefulWidget {
  const NewProductsPage({super.key});

  @override
  State<NewProductsPage> createState() => _NewProductsPageState();
}

class _NewProductsPageState extends State<NewProductsPage>
    with TickerProviderStateMixin {
  // حالة التطبيق
  AppMode currentMode = AppMode.day;
  int currentPageIndex = 0;
  bool isAdmin = false; // صلاحيات المدير
  final FavoritesService _favoritesService = FavoritesService.instance;
  final CartService _cartService = CartService();

  // متغيرات شريط الصور الإعلانية
  final PageController _bannerPageController = PageController();
  int currentBannerIndex = 0;
  Timer? _bannerTimer;

  // البانرات الإعلانية المتعددة (سيتم تحميلها من قاعدة البيانات)
  List<Map<String, dynamic>> banners = [];
  bool _isLoadingBanners = false;

  // بيانات المنتجات من قاعدة البيانات
  List<Product> products = [];
  List<Product> filteredProducts = [];
  bool _isLoadingProducts = false;

  // متغيرات البحث
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    // التحقق من صلاحيات المدير
    _checkAdminPermissions();

    // جلب المنتجات من قاعدة البيانات
    _loadProducts();

    // تحميل الصور الإعلانية
    _loadBanners();

    // تحميل المفضلة
    _favoritesService.loadFavorites();

    // بدء التقليب التلقائي للبانرات
    _startBannerAutoSlide();

    // إعداد البحث المستمر
    _searchController.addListener(_onSearchChanged);

    // تشغيل التحويل التلقائي للطلبات المجدولة عند فتح الصفحة
    _runAutoConversion();
  }

  // دالة تحديث البيانات عند السحب
  Future<void> _refreshData() async {
    setState(() {
      _isLoadingProducts = true;
    });

    await Future.wait([
      _loadProducts(),
      _loadBanners(),
      _favoritesService.loadFavorites()
    ]);

    setState(() {
      _isLoadingProducts = false;
    });
  }

  // تشغيل التحويل التلقائي للطلبات المجدولة
  Future<void> _runAutoConversion() async {
    try {
      debugPrint('🔄 تشغيل التحويل التلقائي للطلبات المجدولة...');
      final scheduledOrdersService = ScheduledOrdersService();
      final convertedCount = await scheduledOrdersService
          .convertScheduledOrdersToActive();
      if (convertedCount > 0) {
        debugPrint('✅ تم تحويل $convertedCount طلب مجدول إلى نشط');
      }
    } catch (e) {
      debugPrint('⚠️ خطأ في التحويل التلقائي: $e');
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerPageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // دالة البحث المستمر
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterProducts();
    });
  }

  // تصفية المنتجات حسب البحث - البحث في بداية اسم المنتج فقط
  void _filterProducts() {
    if (_searchQuery.isEmpty) {
      filteredProducts = List.from(products);
    } else {
      filteredProducts = products.where((product) {
        // البحث فقط في بداية اسم المنتج
        return product.name.toLowerCase().startsWith(
          _searchQuery.toLowerCase(),
        );
      }).toList();
    }
  }

  // بدء التقليب التلقائي للبانرات
  void _startBannerAutoSlide() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_bannerPageController.hasClients && banners.isNotEmpty) {
        setState(() {
          currentBannerIndex = (currentBannerIndex + 1) % banners.length;
        });
        _bannerPageController.animateToPage(
          currentBannerIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // تغيير البانر يدوياً
  void _onBannerPageChanged(int index) {
    setState(() {
      currentBannerIndex = index;
    });
  }

  // تحميل الصور الإعلانية من قاعدة البيانات
  Future<void> _loadBanners() async {
    setState(() => _isLoadingBanners = true);

    try {
      final response = await Supabase.instance.client
          .from('advertisement_banners')
          .select('*')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      setState(() {
        banners = List<Map<String, dynamic>>.from(response);
        _isLoadingBanners = false;
      });

      debugPrint('✅ تم جلب ${banners.length} صورة إعلانية من قاعدة البيانات');
    } catch (e) {
      debugPrint('❌ خطأ في جلب الصور الإعلانية: $e');
      setState(() {
        _isLoadingBanners = false;
        // في حالة الخطأ، استخدم قائمة فارغة
        banners = [];
      });
    }
  }

  // جلب المنتجات من قاعدة البيانات
  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      // جلب المنتجات من Supabase (فقط المنتجات المتاحة في المخزون)
      final response = await Supabase.instance.client
          .from('products')
          .select('*, available_from, available_to, available_quantity')
          .eq('is_active', true)
          .gt('available_quantity', 0) // فقط المنتجات التي لديها كمية متاحة
          .order('created_at', ascending: false);

      final List<Product> loadedProducts = [];

      for (final item in response) {
        final double wholesalePrice = (item['wholesale_price'] ?? 0).toDouble();
        final double minPrice = (item['min_price'] ?? 0).toDouble();
        final double maxPrice = (item['max_price'] ?? 0).toDouble();
        final double price = (item['price'] ?? wholesalePrice).toDouble();

        loadedProducts.add(
          Product(
            id: item['id'] ?? '',
            name: item['name'] ?? 'منتج بدون اسم',
            description: item['description'] ?? 'لا يوجد وصف',
            images: item['images'] != null
                ? List<String>.from(item['images'])
                : [
                    item['image_url'] ??
                        'https://picsum.photos/400/400?random=${DateTime.now().millisecondsSinceEpoch}',
                  ],
            wholesalePrice: wholesalePrice,
            minPrice: minPrice,
            maxPrice: maxPrice,
            category: item['category'] ?? 'عام',
            minQuantity: 1,
            maxQuantity: 0,
            availableFrom: item['available_from'] ?? 90,
            availableTo: item['available_to'] ?? 80,
            availableQuantity: item['available_quantity'] ?? 100,
            createdAt: item['created_at'] != null
                ? DateTime.parse(item['created_at'])
                : DateTime.now(),
            updatedAt: item['updated_at'] != null
                ? DateTime.parse(item['updated_at'])
                : DateTime.now(),
          ),
        );
      }

      setState(() {
        products = loadedProducts;
        filteredProducts = List.from(loadedProducts);
        _isLoadingProducts = false;
      });

      print('✅ تم جلب ${products.length} منتج من قاعدة البيانات');
    } catch (e) {
      print('❌ خطأ في جلب المنتجات: $e');
      setState(() {
        _isLoadingProducts = false;
        // في حالة الخطأ، استخدم قائمة فارغة
        products = [];
        filteredProducts = List.from(products);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // لا نحتاج للتحقق من صلاحيات المدير هنا لتجنب التكرار المفرط
    // التحقق يتم في initState() فقط
  }

  // التحقق من صلاحيات المدير
  Future<void> _checkAdminPermissions() async {
    try {
      // التحقق من صلاحيات المدير للمستخدم الحالي
      final isCurrentUserAdmin = await AuthService.isCurrentUserAdmin();

      // تحديث الحالة فقط إذا تغيرت
      if (isAdmin != isCurrentUserAdmin) {
        setState(() {
          isAdmin = isCurrentUserAdmin;
        });

        // طباعة فقط عند التغيير
        debugPrint('🔍 تحديث صلاحيات المدير: $isCurrentUserAdmin');
        if (isCurrentUserAdmin) {
          debugPrint('👑 المستخدم الحالي هو مدير - سيظهر زر لوحة التحكم');
        }
      }
    } catch (e) {
      // في حالة الخطأ، لا نعطي صلاحيات المدير
      debugPrint('❌ خطأ في التحقق من صلاحيات المدير: $e');
      if (isAdmin != false) {
        setState(() {
          isAdmin = false;
        });
      }
    }
  }

  // تبديل المفضلة
  Future<void> _toggleFavorite(Product product) async {
    final success = await _favoritesService.toggleFavorite(product);
    if (success && mounted) {
      // عرض رسالة تأكيد
      final isFavorite = _favoritesService.isFavorite(product.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFavorite
                ? '❤️ تم إضافة ${product.name} للمفضلة'
                : '💔 تم إزالة ${product.name} من المفضلة',
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 12, // تصغير النص
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: isFavorite
              ? const Color(0xFF00ff88)
              : const Color(0xFFff2d55),
          duration: const Duration(seconds: 1), // تقليل المدة
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ), // تصغير الهامش
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // لا نحتاج للتحقق من صلاحيات المدير في كل build
    // التحقق يتم مرة واحدة في initState()

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e), // خلفية داكنة ثابتة
      extendBody: true, // السماح للمحتوى بالظهور خلف الشريط السفلي
      body: Column(
        children: [
          // منطقة المحتوى القابل للتمرير
          Expanded(
            child: PullToRefreshWrapper(
              onRefresh: _refreshData,
              refreshMessage: 'تم تحديث المنتجات والمفضلة',
              indicatorColor: const Color(0xFFffd700),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: 100,
                  ), // مساحة للشريط السفلي
                  child: Column(
                    children: [
                      // الشريط العلوي الموحد
                      CommonHeader(
                        title: 'منتجاتي',
                        leftActions: [
                          _buildCartIcon(),
                          if (isAdmin) ...[
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => context.go('/admin'),
                              child: _buildHeaderIcon(
                                FontAwesomeIcons.userShield,
                                const Color(0xFF6f42c1),
                              ),
                            ),
                          ],
                        ],
                        rightActions: [
                          GestureDetector(
                            onTap: () => context.go('/favorites'),
                            child: _buildHeaderIcon(
                              FontAwesomeIcons.heart,
                              const Color(0xFFff2d55),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildHeaderIcon(
                            FontAwesomeIcons.moon,
                            const Color(0xFF6f42c1),
                          ),
                        ],
                      ),
                      // البانر الإعلاني الرئيسي
                      _buildMainAdvertisementBanner(),

                      // شريط البحث المتقدم
                      _buildAdvancedSearchBar(),

                      // شبكة المنتجات
                      _buildAdvancedProductsGrid(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // شريط التنقل السفلي المعاد ترتيبه
      bottomNavigationBar: const CustomBottomNavigationBar(
        currentRoute: '/products',
      ),
    );
  }



  // بناء أيقونة الشريط العلوي
  Widget _buildHeaderIcon(IconData icon, Color color) {
    return Container(
      width: 32, // الحجم الأصلي
      height: 32, // الحجم الأصلي
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle, // تغيير إلى دائرة
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 6, // تقليل الظل قليلاً
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 14,
      ), // تصغير الأيقونة من 16 إلى 14
    );
  }

  // بناء أيقونة السلة
  Widget _buildCartIcon() {
    return GestureDetector(
      onTap: () => context.go('/cart'),
      child: ListenableBuilder(
        listenable: _cartService,
        builder: (context, child) {
          return Stack(
            children: [
              Container(
                width: 32, // تصغير من 35 إلى 32
                height: 32, // تصغير من 35 إلى 32
                decoration: BoxDecoration(
                  color: const Color(0xFFffd700),
                  shape: BoxShape.circle, // تغيير إلى دائرة
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFffd700).withValues(alpha: 0.3),
                      blurRadius: 6, // تقليل الظل قليلاً
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  FontAwesomeIcons.bagShopping,
                  color: Color(0xFF1a1a2e),
                  size: 14, // تصغير الأيقونة من 16 إلى 14
                ),
              ),
              if (_cartService.itemCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3), // تصغير الحشو قليلاً
                    decoration: const BoxDecoration(
                      color: Color(0xFFff2d55),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _cartService.itemCount.toString(),
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 9, // تصغير الخط قليلاً
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // بناء شريط البانرات التفاعلي
  Widget _buildMainAdvertisementBanner() {
    // إذا كانت قائمة البانرات فارغة، عرض بانر افتراضي
    if (banners.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(15),
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [
              const Color(0xFFffd700).withValues(alpha: 0.8),
              const Color(0xFF1a1a2e).withValues(alpha: 0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FontAwesomeIcons.image,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'مرحباً بك في منتجاتي',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'أفضل المنتجات بأفضل الأسعار',
                  style: GoogleFonts.cairo(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(15),
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // شريط تمرير الصور
            PageView.builder(
              controller: _bannerPageController,
              onPageChanged: _onBannerPageChanged,
              itemCount: banners.length,
              itemBuilder: (context, index) {
                final banner = banners[index];
                return _buildBannerSlide(banner);
              },
            ),

            // مؤشرات النقاط (فقط إذا كان هناك أكثر من بانر واحد)
            if (banners.length > 1)
              Positioned(
                bottom: 15,
                right: 20,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    banners.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == currentBannerIndex
                            ? const Color(0xFFffd700)
                            : Colors.white.withValues(alpha: 0.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
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
    );
  }

  // بناء شريحة البانر الواحدة - صورة فقط بجودة كاملة
  Widget _buildBannerSlide(Map<String, dynamic> banner) {
    return Stack(
      children: [
        // صورة الخلفية بجودة كاملة
        SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Image.network(
            banner['image_url'] ?? '',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: const Color(0xFF1a1a2e),
                child: Center(
                  child: CircularProgressIndicator(
                    color: const Color(0xFFffd700),
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFF1a1a2e),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        FontAwesomeIcons.image,
                        color: const Color(0xFFffd700),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'لا يمكن تحميل الصورة',
                        style: GoogleFonts.cairo(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // طبقة تدرج خفيفة جداً للحفاظ على وضوح الصورة
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.1),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // لا يوجد نص أو أيقونات - فقط الصورة بجودة كاملة
      ],
    );
  }

  // بناء شريط البحث الأنيق والموحد
  Widget _buildAdvancedSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(15, 20, 15, 12),
      height: 50,
      decoration: BoxDecoration(
        // ✅ لون موحد بدلاً من التدرج لتجنب المشاكل
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.4),
          width: 1.5,
        ),
        // ✅ ظل خفيف وأنيق
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          // أيقونة البحث الأنيقة
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFffd700).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              FontAwesomeIcons.magnifyingGlass,
              color: Color(0xFFffd700),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              // ✅ حاوية شفافة لضمان عدم وجود خلفية
              decoration: const BoxDecoration(color: Colors.transparent),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                cursorColor: const Color(0xFFffd700),
                decoration: InputDecoration(
                  hintText: 'ابحث عن منتجك المفضل...',
                  hintStyle: GoogleFonts.cairo(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  // ✅ إزالة جميع الخلفيات الافتراضية
                  fillColor: Colors.transparent,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          // زر مسح البحث (يظهر عند وجود نص)
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                _onSearchChanged();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  FontAwesomeIcons.xmark,
                  color: Colors.white70,
                  size: 12,
                ),
              ),
            ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  // بناء شبكة المنتجات المتقدمة
  Widget _buildAdvancedProductsGrid() {
    if (_isLoadingProducts) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFFffd700)),
              SizedBox(height: 16),
              Text(
                'جاري تحميل المنتجات...',
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredProducts.isEmpty && _searchQuery.isNotEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FontAwesomeIcons.magnifyingGlass,
                color: Color(0xFFffd700),
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'لا توجد نتائج للبحث',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'جرب البحث بكلمات مختلفة',
                style: GoogleFonts.cairo(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (products.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FontAwesomeIcons.boxOpen,
                color: Color(0xFFffd700),
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'لا توجد منتجات متاحة',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'سيتم عرض المنتجات هنا عند إضافتها',
                style: GoogleFonts.cairo(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // حساب عدد الأعمدة بناءً على عرض الشاشة
          double screenWidth = constraints.maxWidth;
          int crossAxisCount;
          double childAspectRatio;

          if (screenWidth > 600) {
            // للأجهزة اللوحية - نسبة أطول لتتسع للنص
            crossAxisCount = 3;
            childAspectRatio = 0.65;
          } else if (screenWidth > 400) {
            // للهواتف الكبيرة - نسبة أطول لتتسع للنص
            crossAxisCount = 2;
            childAspectRatio = 0.60;
          } else {
            // للهواتف الصغيرة والمتوسطة - نسبة أطول لتتسع للنص
            crossAxisCount = 2;
            childAspectRatio = 0.58;
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 12,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              return _buildSmartProductCard(filteredProducts[index]);
            },
          );
        },
      ),
    );
  }

  // بناء بطاقة المنتج الذكية والمتجاوبة
  Widget _buildSmartProductCard(Product product) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // حساب الأحجام بناءً على عرض البطاقة
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
                      Flexible(
                        child: Text(
                          product.name,
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            height: 1.2, // زيادة المسافة بين الأسطر
                          ),
                          maxLines: 2, // السماح بسطرين
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                        ),
                      ),

                      SizedBox(
                        height: padding * 0.6,
                      ), // مسافة مقللة بين الاسم والسعر
                      // سعر الجملة
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFffd700,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(
                              0xFFffd700,
                            ).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'جملة: ${NumberFormatter.formatCurrency(product.wholesalePrice)}',
                          style: GoogleFonts.cairo(
                            color: const Color(0xFFffd700),
                            fontSize: priceFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const Spacer(), // يدفع الأزرار إلى أسفل البطاقة

                      // الأزرار السفلية - القلب وإضافة للسلة
                      Row(
                        children: [
                          // زر القلب على اليمين
                          ListenableBuilder(
                            listenable: _favoritesService,
                            builder: (context, child) {
                              return GestureDetector(
                                onTap: () => _toggleFavorite(product),
                                child: Container(
                                  width: cardWidth > 200 ? 30 : cardWidth > 160 ? 28 : cardWidth > 140 ? 26 : 24,
                                  height: cardWidth > 200 ? 30 : cardWidth > 160 ? 28 : cardWidth > 140 ? 26 : 24,
                                  decoration: BoxDecoration(
                                    color:
                                        _favoritesService.isFavorite(product.id)
                                        ? const Color(
                                            0xFFff2d55,
                                          ).withValues(alpha: 0.2)
                                        : const Color(0xFF1a1a2e),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          _favoritesService.isFavorite(
                                            product.id,
                                          )
                                          ? const Color(0xFFff2d55)
                                          : const Color(
                                              0xFFffd700,
                                            ).withValues(alpha: 0.4),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _favoritesService.isFavorite(product.id)
                                        ? FontAwesomeIcons.solidHeart
                                        : FontAwesomeIcons.heart,
                                    color:
                                        _favoritesService.isFavorite(product.id)
                                        ? const Color(0xFFff2d55)
                                        : const Color(
                                            0xFFff2d55,
                                          ).withValues(alpha: 0.6),
                                    size: cardWidth > 200 ? 16 : cardWidth > 160 ? 14 : cardWidth > 140 ? 12 : 10,
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(width: 8),

                          // زر إضافة للسلة على اليسار
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _addToCart(product),
                              child: Container(
                                height: cardWidth > 200 ? 30 : cardWidth > 160 ? 28 : cardWidth > 140 ? 26 : 24,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFffd700),
                                      Color(0xFFe6b31e),
                                    ],
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
                                      size: cardWidth > 200 ? 14 : cardWidth > 160 ? 12 : cardWidth > 140 ? 10 : 9,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'إضافة للسلة',
                                      style: GoogleFonts.cairo(
                                        color: const Color(0xFF1a1a2e),
                                        fontSize: cardWidth > 200 ? 12 : cardWidth > 160 ? 11 : cardWidth > 140 ? 10 : 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
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
                      _getAvailableFromTo(product),
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

  // دالة لإرجاع الكمية المتاحة بصيغة "من - إلى"
  String _getAvailableFromTo(Product product) {
    return '${product.availableFrom} - ${product.availableTo}';
  }

  // إضافة منتج للسلة
  Future<void> _addToCart(Product product) async {
    try {
      // إضافة المنتج للسلة بدون سعر عميل (يجب على المستخدم تحديده في السلة)
      final result = await _cartService.addItem(
        productId: product.id,
        name: product.name,
        image: product.images.isNotEmpty ? product.images.first : '',
        wholesalePrice: product.wholesalePrice.toInt(),
        minPrice: product.minPrice.toInt(),
        maxPrice: product.maxPrice.toInt(),
        customerPrice: 0, // بدون سعر عميل - يجب تحديده في السلة
        quantity: 1,
      );

      if (result['success']) {
        // عرض رسالة نجاح
        _showSnackBar(
          '✅ تم إضافة ${product.name} للسلة بنجاح!',
          isError: false,
        );
      } else {
        // عرض رسالة خطأ
        _showSnackBar('❌ ${result['message']}', isError: true);
      }
    } catch (e) {
      _showSnackBar('❌ حدث خطأ أثناء إضافة المنتج للسلة', isError: true);
    }
  }

  // عرض رسالة
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isError
            ? const Color(0xFFff2d55)
            : const Color(0xFF00ff88),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
