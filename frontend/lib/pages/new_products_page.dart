import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/design_system.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/favorites_service.dart';
import '../services/user_service.dart';
import '../utils/font_helper.dart';
import '../widgets/app_background.dart';
import '../widgets/curved_navigation_bar.dart';

// 🧠 حالات شريط البحث الذكي
enum SearchBarState {
  hidden, // مخفي تماماً
  buttonOnly, // زر البحث فقط
  expanded, // شريط البحث مفتوح
}

// كلاس مساعد لترتيب نتائج البحث
class ProductMatch {
  final Product product;
  final int score;

  ProductMatch(this.product, this.score);
}

class NewProductsPage extends StatefulWidget {
  const NewProductsPage({super.key});

  @override
  State<NewProductsPage> createState() => _NewProductsPageState();
}

class _NewProductsPageState extends State<NewProductsPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CartService _cartService = CartService();
  final FavoritesService _favoritesService = FavoritesService.instance;
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

  // 🧠 نظام ذكي موحد لإدارة شريط البحث
  SearchBarState _searchBarState = SearchBarState.hidden;
  final FocusNode _originalSearchFocus = FocusNode(); // للشريط الأصلي
  final FocusNode _expandedSearchFocus = FocusNode(); // للشريط المفتوح - منفصل

  // البحث والـ hints
  List<Product> _filteredProducts = [];
  Timer? _hintTimer;
  Timer? _searchDebounceTimer;
  int _currentHintIndex = 0;
  List<String> _productHints = [];
  int _currentNavIndex = 0; // للشريط السفلي المنحني

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _initializeUserData();
    _loadBanners();
    _setupScrollListener();
    _setupProductHints();
    _loadFavorites(); // تحميل المفضلة
  }

  // 🧠 نظام ذكي لإدارة شريط البحث حسب التمرير مع حماية من الـ crash
  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (!mounted) return; // حماية أساسية

      try {
        const double threshold = 150.0;
        final currentOffset = _scrollController.offset;

        // منطق ذكي لإدارة حالات الشريط
        if (currentOffset >= threshold) {
          // المستخدم مرر للأسفل - إظهار زر البحث فقط إذا لم يكن في حالة expanded
          if (_searchBarState == SearchBarState.hidden) {
            _updateSearchBarState(SearchBarState.buttonOnly);
          }
        } else {
          // المستخدم في أعلى الصفحة - إخفاء كل شيء مع انتقال ذكي
          if (_searchBarState != SearchBarState.hidden) {
            _smartTransitionToOriginal();
          }
        }
      } catch (e) {
        debugPrint('❌ خطأ في scroll listener: $e');
      }
    });
  }

  // 🎯 انتقال ذكي للشريط الأصلي مع حماية من الـ crash
  void _smartTransitionToOriginal() {
    if (!mounted) return; // حماية أساسية

    try {
      // حفظ النص الحالي
      final currentText = _searchController.text;
      final wasTyping = currentText.isNotEmpty;

      // إخفاء الشريط الثانوي فوراً
      setState(() {
        _searchBarState = SearchBarState.hidden;
      });

      // إزالة التركيز من أي حقل نشط
      if (mounted && context.mounted) {
        FocusScope.of(context).unfocus();
      }

      // إذا كان المستخدم يكتب - انتقال سلس للشريط الأصلي
      if (wasTyping) {
        // وضع النص فوراً
        _searchController.text = currentText;

        // استخدام Timer قصير لضمان وضع المؤشر بشكل صحيح
        Timer(const Duration(milliseconds: 10), () {
          if (mounted) {
            try {
              // وضع المؤشر في النهاية بدون تحديد النص
              _searchController.selection = TextSelection.collapsed(offset: currentText.length);

              // تحديث الواجهة لضمان ظهور التغييرات
              setState(() {});
            } catch (e) {
              debugPrint('❌ خطأ في وضع المؤشر: $e');
            }
          }
        });
      } else {
        // إذا لم يكن يكتب - تنظيف فقط
        _searchController.clear();
        _searchProducts('');
      }
    } catch (e) {
      debugPrint('❌ خطأ في الانتقال الذكي: $e');
    }
  }

  // 🔍 مراقبة الانتقال المفاجئ للبداية مع حماية من الـ crash
  void _checkForSuddenJumpToTop() {
    if (!mounted) return; // حماية أساسية

    try {
      // تأخير قصير للسماح للشاشة بالتحديث
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && _scrollController.hasClients) {
          try {
            final currentPosition = _scrollController.offset;

            // إذا كان المستخدم في البداية والشريط ظاهر
            if (currentPosition <= 100 && _searchBarState != SearchBarState.hidden) {
              debugPrint('🔍 انتقال مفاجئ للبداية - إخفاء الشريط الثانوي');
              _smartTransitionToOriginal();
            }
          } catch (e) {
            debugPrint('❌ خطأ في فحص موضع التمرير: $e');
          }
        }
      });
    } catch (e) {
      debugPrint('❌ خطأ في إعداد فحص الانتقال: $e');
    }
  }

  // 🎯 دالة ذكية لتحديث حالة الشريط مع حماية من الـ crash
  void _updateSearchBarState(SearchBarState newState) {
    if (!mounted) return; // حماية من الـ crash

    if (_searchBarState != newState) {
      try {
        // إزالة التركيز من أي FocusNode نشط قبل التغيير
        _originalSearchFocus.unfocus();
        _expandedSearchFocus.unfocus();

        setState(() {
          _searchBarState = newState;
        });

        // إضافة تأخير صغير قبل التركيز الجديد
        if (newState == SearchBarState.expanded) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && _expandedSearchFocus.canRequestFocus) {
              _expandedSearchFocus.requestFocus();
            }
          });
        }
      } catch (e) {
        debugPrint('❌ خطأ في تحديث حالة شريط البحث: $e');
      }
    }
  }

  @override
  void dispose() {
    try {
      // إلغاء جميع المؤقتات
      _bannerTimer?.cancel();
      _hintTimer?.cancel();
      _searchDebounceTimer?.cancel();

      // تنظيف الـ controllers
      _bannerPageController.dispose();
      _searchController.dispose();
      _scrollController.dispose();
      _originalSearchFocus.dispose(); // تنظيف FocusNode الأصلي
      _expandedSearchFocus.dispose(); // تنظيف FocusNode المفتوح
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

  // تحميل البانرات الإعلانية من قاعدة البيانات
  Future<void> _loadBanners() async {
    if (!mounted) return;

    setState(() {
      _isLoadingBanners = true;
    });

    try {
      final response = await _supabase
          .from('advertisement_banners')
          .select('*')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _banners = List<Map<String, dynamic>>.from(response);
          _isLoadingBanners = false;
        });

        // بدء التقليب التلقائي إذا كان هناك أكثر من بانر واحد
        if (_banners.length > 1) {
          _startAutoSlide();
        }
      }

      debugPrint('✅ تم تحميل ${_banners.length} بانر إعلاني');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل البانرات: $e');
      if (mounted) {
        setState(() {
          _isLoadingBanners = false;
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

      final currentPage = _bannerPageController.hasClients ? (_bannerPageController.page?.round() ?? 0) : 0;
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

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('is_active', true) // فقط المنتجات النشطة
          .order('created_at', ascending: false);

      final allProducts = (response as List).map((json) => Product.fromJson(json)).toList();

      // 🎯 فلترة المنتجات المتاحة فقط (عدد القطع > 0)
      final availableProducts = allProducts.where((product) => product.availableQuantity > 0).toList();

      if (mounted) {
        // تحديث تدريجي لتجنب التقطيع
        setState(() {
          _products = availableProducts; // فقط المنتجات المتاحة
          _isLoadingProducts = false;
        });

        // تأخير صغير لضمان السلاسة
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {
              _filteredProducts = List.from(availableProducts); // نسخة منفصلة
            });
            _updateProductHints(); // تحديث hints البحث
          }
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

  // إعداد hints المنتجات
  void _setupProductHints() {
    _updateProductHints();
    _startHintRotation();
  }

  // تحديث قائمة hints من أسماء المنتجات
  void _updateProductHints() {
    if (_products.isNotEmpty) {
      _productHints = _products.map((product) => product.name).take(10).toList();
      if (_productHints.isEmpty) {
        _productHints = ['ابحث عن المنتجات...'];
      }
    } else {
      _productHints = ['ابحث عن المنتجات...'];
    }
  }

  // بدء تقليب الـ hints
  void _startHintRotation() {
    _hintTimer?.cancel();
    _hintTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || _productHints.isEmpty) {
        timer.cancel();
        return;
      }

      setState(() {
        _currentHintIndex = (_currentHintIndex + 1) % _productHints.length;
      });
    });
  }

  // البحث في المنتجات مع debouncing وحماية من الـ crash
  void _searchProducts(String query) {
    if (!mounted) return; // حماية أساسية

    try {
      // إلغاء البحث السابق
      _searchDebounceTimer?.cancel();

      // تأخير البحث لتقليل الضغط
      _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          _performSearch(query);
        }
      });
    } catch (e) {
      debugPrint('❌ خطأ في إعداد البحث: $e');
    }
  }

  // تنفيذ البحث الفعلي مع خوارزمية محسنة وحماية من الـ crash
  void _performSearch(String query) {
    if (!mounted) return;

    try {
      // تأخير صغير لضمان السلاسة
      Future.delayed(const Duration(milliseconds: 50), () {
        if (!mounted) return;

        List<Product> filtered;

        try {
          if (query.isEmpty) {
            filtered = List.from(_products);
          } else {
            filtered = _smartSearch(query);
          }

          if (mounted) {
            setState(() {
              _filteredProducts = filtered;
            });

            // 🔍 مراقبة الانتقال المفاجئ للبداية
            _checkForSuddenJumpToTop();
          }
        } catch (e) {
          debugPrint('❌ خطأ في تنفيذ البحث: $e');
          // في حالة الخطأ، عرض جميع المنتجات
          if (mounted) {
            setState(() {
              _filteredProducts = List.from(_products);
            });
          }
        }
      });
    } catch (e) {
      debugPrint('❌ خطأ في إعداد البحث: $e');
    }
  }

  // بحث دقيق في اسم المنتج فقط
  List<Product> _smartSearch(String query) {
    final searchQuery = query.toLowerCase().trim();
    final searchWords = _expandSearchWords(searchQuery);

    List<ProductMatch> matches = [];

    for (final product in _products) {
      final productName = product.name.toLowerCase();

      int score = 0;
      bool hasMatch = false;

      // البحث في اسم المنتج فقط
      for (final word in searchWords) {
        if (productName.contains(word)) {
          hasMatch = true;

          // مطابقة كاملة للاسم
          if (productName == word) {
            score += 200;
          }
          // يبدأ بالكلمة
          else if (productName.startsWith(word)) {
            score += 150;
          }
          // كلمة في الاسم تبدأ بالكلمة المبحوث عنها
          else if (productName.split(' ').any((nameWord) => nameWord.startsWith(word))) {
            score += 120;
          }
          // يحتوي على الكلمة
          else {
            score += 80;
          }
        }
      }

      // البحث الجزئي فقط للكلمات الطويلة وإذا لم نجد مطابقة
      if (!hasMatch && searchQuery.length >= 3) {
        if (productName.contains(searchQuery)) {
          hasMatch = true;
          score += 15;
        }
      }

      if (hasMatch) {
        matches.add(ProductMatch(product, score));
      }
    }

    // ترتيب النتائج حسب النقاط (الأعلى أولاً)
    matches.sort((a, b) => b.score.compareTo(a.score));

    return matches.map((match) => match.product).toList();
  }

  // توسيع كلمات البحث بالمرادفات
  List<String> _expandSearchWords(String query) {
    final words = query.split(' ').where((word) => word.isNotEmpty).toList();
    final expandedWords = <String>[];

    // قاموس المرادفات للكلمات الشائعة
    final synonyms = {
      'ستائر': ['ستارة', 'ستار'],
      'ستارة': ['ستائر', 'ستار'],
      'ستار': ['ستائر', 'ستارة'],
      'خزانة': ['خزان', 'دولاب'],
      'خزان': ['خزانة', 'دولاب'],
      'دولاب': ['خزانة', 'خزان'],
      'طاولة': ['منضدة'],
      'منضدة': ['طاولة'],
      'كرسي': ['مقعد'],
      'مقعد': ['كرسي'],
    };

    for (final word in words) {
      expandedWords.add(word);
      if (synonyms.containsKey(word)) {
        expandedWords.addAll(synonyms[word]!);
      }
    }

    return expandedWords.toSet().toList(); // إزالة التكرار
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AppBackground(
        child: Stack(
          children: [
            // المحتوى الرئيسي
            SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  // مساحة للشريط العلوي (تقليل الفراغ)
                  const SizedBox(height: 25),
                  // الشريط العلوي
                  _buildHeader(),
                  // البانر الرئيسي
                  _buildMainBanner(),
                  // شريط البحث
                  _buildSearchBar(),
                  // شبكة المنتجات
                  _buildProductsGrid(),
                  // مساحة إضافية للشريط السفلي
                  const SizedBox(height: 160),
                ],
              ),
            ),

            // 🧠 شريط البحث الذكي - يظهر حسب الحالة
            if (_searchBarState != SearchBarState.hidden)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 40, 12, 10),
                  color: Colors.transparent, // بدون خلفية
                  child: _buildAnimatedSearchBar(),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _currentNavIndex,
        items: <Widget>[
          Icon(Icons.storefront_outlined, size: 28, color: Color(0xFFFFD700)), // ذهبي
          Icon(Icons.receipt_long_outlined, size: 28, color: Color(0xFFFFD700)), // ذهبي
          Icon(Icons.trending_up_outlined, size: 28, color: Color(0xFFFFD700)), // ذهبي
          Icon(Icons.person_outline, size: 28, color: Color(0xFFFFD700)), // ذهبي
        ],
        color: AppDesignSystem.bottomNavColor, // لون الشريط موحد
        buttonBackgroundColor: AppDesignSystem.activeButtonColor, // لون الكرة موحد
        backgroundColor: Colors.transparent, // خلفية شفافة
        animationCurve: Curves.elasticOut, // منحنى مبهر
        animationDuration: Duration(milliseconds: 1200), // انتقال مبهر
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });
          // التنقل السلس حسب العنصر المحدد
          switch (index) {
            case 0:
              // المنتجات الرئيسية - الصفحة الحالية
              break;
            case 1:
              context.go('/orders'); // الطلبات
              break;
            case 2:
              context.go('/profits'); // الأرباح
              break;
            case 3:
              context.go('/account'); // الحساب
              break;
          }
        },
        letIndexChange: (index) => true,
      ),
    );
  }

  // بناء الشريط العلوي
  Widget _buildHeader() {
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
                              color: Colors.white,
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
                        color: Colors.white.withValues(alpha: 0.7),
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
                  child: Stack(
                    children: [
                      // الظل الخلفي للنص
                      Text(
                        'منتجاتي',
                        style: GoogleFonts.amiri(
                          fontSize: 20, // تصغير من 25 إلى 20
                          fontWeight: FontWeight.bold,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth =
                                1.2 // تصغير من 1.5 إلى 1.2
                            ..color = Colors.black.withValues(alpha: 0.3),
                        ),
                      ),
                      // النص الذهبي الرئيسي
                      ShaderMask(
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
                            fontSize: 24, // تصغير من 30 إلى 24
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.8, // تصغير من 1.0 إلى 0.8
                            shadows: [
                              // ظل ذهبي مضيء
                              Shadow(
                                color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                                offset: const Offset(0, 0),
                                blurRadius: 6,
                              ),
                              // ظل أسود للعمق
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                offset: const Offset(1, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // الأزرار (اليمين)
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // زر المفضلة
                    GestureDetector(
                      onTap: () {
                        context.go('/favorites');
                      },
                      child: Container(
                        width: 36, // تكبير قليلاً من 32 إلى 36
                        height: 36, // تكبير قليلاً من 32 إلى 36
                        margin: const EdgeInsets.only(left: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.3), width: 1),
                        ),
                        child: const Icon(
                          Icons.favorite_outline,
                          color: Color(0xFFFF6B6B),
                          size: 18, // تكبير قليلاً من 16 إلى 18
                        ),
                      ),
                    ),
                    // زر السلة المحسن
                    GestureDetector(
                      onTap: () {
                        context.go('/cart');
                      },
                      child: Container(
                        width: 36, // تكبير قليلاً من 32 إلى 36
                        height: 36, // تكبير قليلاً من 32 إلى 36
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
                        child: const Icon(
                          Icons.shopping_cart_outlined,
                          color: Colors.white,
                          size: 18, // تكبير قليلاً من 16 إلى 18
                        ),
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
    if (_isLoadingBanners) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppDesignSystem.primaryBackground,
              const Color(0xFF2D3748).withValues(alpha: 0.8),
              const Color(0xFF1A202C).withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
          ],
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppDesignSystem.primaryBackground,
              const Color(0xFF2D3748).withValues(alpha: 0.8),
              const Color(0xFF1A202C).withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
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
                  border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    children: [
                      // صورة البانر بأفضل جودة
                      Positioned.fill(
                        child: Image.network(
                          banner['image_url'] ?? '',
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppDesignSystem.primaryBackground,
                                    const Color(0xFF2D3748).withValues(alpha: 0.8),
                                    const Color(0xFF1A202C).withValues(alpha: 0.9),
                                  ],
                                ),
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
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppDesignSystem.primaryBackground,
                                    const Color(0xFF2D3748).withValues(alpha: 0.8),
                                    const Color(0xFF1A202C).withValues(alpha: 0.9),
                                  ],
                                ),
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
    return Container(
      height: 55,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppDesignSystem.bottomNavColor.withValues(alpha: 0.85),
            AppDesignSystem.activeButtonColor.withValues(alpha: 0.9),
            AppDesignSystem.primaryBackground.withValues(alpha: 0.95),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppDesignSystem.goldColor.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
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
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: TextField(
          controller: _searchController,
          focusNode: _originalSearchFocus, // ربط FocusNode
          style: GoogleFonts.cairo(color: AppDesignSystem.primaryTextColor, fontSize: 16, fontWeight: FontWeight.w500),
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
            hintStyle: GoogleFonts.cairo(color: AppDesignSystem.primaryTextColor.withValues(alpha: 0.6), fontSize: 14),
            prefixIcon: Container(
              padding: const EdgeInsets.all(14),
              child: Icon(
                Icons.search_rounded,
                color: AppDesignSystem.goldColor.withValues(alpha: 0.9),
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
                        color: AppDesignSystem.secondaryTextColor,
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

  // بناء شبكة المنتجات
  Widget _buildProductsGrid() {
    if (_isLoadingProducts) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: Color(0xFF6B7180))),
      );
    }

    if (_filteredProducts.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            _searchController.text.isNotEmpty
                ? 'لا توجد نتائج للبحث "${_searchController.text}"'
                : 'لا توجد منتجات متاحة',
            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // 🎯 حساب المسافات والأعمدة الذكية بناءً على حجم الشاشة
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalMargin = screenWidth > 400 ? 16.0 : (screenWidth > 350 ? 14.0 : 12.0);
    final crossAxisSpacing = screenWidth > 400 ? 12.0 : (screenWidth > 350 ? 10.0 : 8.0);
    final mainAxisSpacing = screenWidth > 400 ? 20.0 : (screenWidth > 350 ? 18.0 : 16.0);

    // 🧠 تحديد عدد الأعمدة بناءً على عرض الشاشة
    int crossAxisCount;
    if (screenWidth > 600) {
      crossAxisCount = 3; // تابلت أو شاشات كبيرة
    } else if (screenWidth > 480) {
      crossAxisCount = 3; // شاشات كبيرة
    } else {
      crossAxisCount = 2; // هواتف عادية
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: GridView.builder(
          key: ValueKey(_filteredProducts.length), // مفتاح للتحكم في الانيميشن
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount, // 🧠 عدد أعمدة ذكي
            crossAxisSpacing: crossAxisSpacing, // 🎯 مسافة ذكية أفقية
            mainAxisSpacing: mainAxisSpacing, // 🎯 مسافة ذكية عمودية
            childAspectRatio: _calculateOptimalAspectRatio(context, crossAxisCount), // 🧠 نسبة ذكية متكيفة
          ),
          itemCount: _filteredProducts.length,
          itemBuilder: (context, index) {
            final product = _filteredProducts[index];
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: _buildProductCard(product),
            );
          },
        ),
      ),
    );
  }

  // 🧠 حساب النسبة المثلى للبطاقات بناءً على حجم الشاشة - نظام ذكي جداً
  double _calculateOptimalAspectRatio(BuildContext context, [int? columns]) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final devicePixelRatio = mediaQuery.devicePixelRatio;

    // حساب النسبة الأساسية للشاشة
    final screenAspectRatio = screenWidth / screenHeight;

    // تصنيف الشاشات بناءً على العرض والكثافة
    double baseRatio;

    if (screenWidth <= 320) {
      // شاشات صغيرة جداً (iPhone SE القديم) - نسبة أطول لإظهار كامل البطاقة
      baseRatio = 0.55;
    } else if (screenWidth <= 375) {
      // شاشات صغيرة (iPhone 8, iPhone SE الجديد)
      baseRatio = 0.58;
    } else if (screenWidth <= 414) {
      // شاشات متوسطة (iPhone 8 Plus, iPhone 11 Pro)
      baseRatio = 0.60;
    } else if (screenWidth <= 428) {
      // شاشات كبيرة (iPhone 12 Pro Max, iPhone 13 Pro Max)
      baseRatio = 0.62;
    } else if (screenWidth <= 480) {
      // شاشات كبيرة جداً أو تابلت صغير
      baseRatio = 0.65;
    } else {
      // تابلت أو شاشات عريضة
      baseRatio = 0.68;
    }

    // تعديل النسبة بناءً على نسبة العرض إلى الارتفاع للشاشة
    if (screenAspectRatio > 0.6) {
      // شاشات عريضة (مناظر طبيعية أو تابلت) - نحتاج بطاقات أطول
      baseRatio -= 0.05;
    } else if (screenAspectRatio < 0.45) {
      // شاشات طويلة جداً (هواتف حديثة) - نحتاج بطاقات أطول
      baseRatio -= 0.08;
    }

    // تعديل بناءً على كثافة البكسل
    if (devicePixelRatio > 3.0) {
      // شاشات عالية الدقة - نحتاج بطاقات أطول قليلاً
      baseRatio -= 0.05;
    } else if (devicePixelRatio < 2.0) {
      // شاشات منخفضة الدقة
      baseRatio -= 0.02;
    }

    // تعديل بناءً على عدد الأعمدة
    if (columns != null && columns > 2) {
      // إذا كان لدينا 3 أعمدة أو أكثر، نحتاج بطاقات أطول
      baseRatio -= 0.08;
    }

    // ضمان أن النسبة ضمن حدود معقولة لإظهار كامل البطاقة - أقصر للهواتف
    return baseRatio.clamp(0.64, 0.64); // تقليل الارتفاع لجميع الهواتف
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
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animationValue, child) {
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
                // 🎭 تأثير الطفو عند اللمس
                onTapDown: (_) => setState(() {}),
                onTapUp: (_) => setState(() {}),
                onTapCancel: () => setState(() {}),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    // إزالة الأبعاد الثابتة لتتكيف مع النسبة الذكية
                    margin: const EdgeInsets.only(right: 8, bottom: 16), // تقليل المسافة الجانبية
                    clipBehavior: Clip.antiAlias, // قطع التضبيب داخل الحدود
                    decoration: BoxDecoration(
                      // 🔮 خلفية متناسقة مع الخلفية الخرافية
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.06), // شفاف أكثر
                          Colors.white.withValues(alpha: 0.03), // شفاف جداً
                          const Color(0xFF1A1F2E).withValues(alpha: 0.2), // يتناسق مع الخلفية
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12), // حدود أخف
                        width: 1.2,
                      ),
                      // بدون ظل
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
                                colors: [Colors.blue.withValues(alpha: 0.15), Colors.transparent],
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),

                        // شريط عدد القطع - تصميم بسيط وجميل في الزاوية
                        Positioned(
                          left: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), // أصغر قليلاً
                            decoration: BoxDecoration(
                              color: AppDesignSystem.goldColor.withValues(alpha: 0.9), // إرجاع الأصفر لعدد القطع
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(24), // يتبع زاوية البطاقة
                                bottomRight: Radius.circular(16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
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

                        // منطقة الصورة - موسعة لحد البطاقة مع رفع قليل
                        Positioned(
                          left: 6, // توسيع للحد
                          top: 22, // رفع قليل للوصول لشريط عدد القطع بمسافة بسيطة
                          right: 6, // توسيع للحد
                          child: Container(
                            height: 160, // تقليل الارتفاع لتقليل طول البطاقة
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
                                  // 🖼️ خلفية شفافة تماماً لإظهار الخلفية الخرافية
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent, // شفاف تماماً
                                          Colors.transparent, // شفاف تماماً
                                        ],
                                      ),
                                    ),
                                  ),
                                  // منطقة الصورة موسعة لحد البطاقة
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    height: 160, // نفس الارتفاع الجديد
                                    child: product.images.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: Image.network(
                                              product.images.first,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: 140,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  height: 140,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withValues(alpha: 0.05),
                                                    borderRadius: BorderRadius.circular(16),
                                                  ),
                                                  child: const Icon(
                                                    Icons.camera_alt_outlined,
                                                    color: Colors.white60,
                                                    size: 50,
                                                  ),
                                                );
                                              },
                                            ),
                                          )
                                        : Container(
                                            height: 140,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.05),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: const Icon(
                                              Icons.camera_alt_outlined,
                                              color: Colors.white60,
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
                          top: 186, // أسفل الصورة مباشرة (22 + 160 + 4)
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // تقليل padding العمودي
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF1A1F2E).withValues(alpha: 0.7), // متناسق مع الخلفية
                                  const Color(0xFF0F1419).withValues(alpha: 0.4), // متناسق مع الخلفية
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08), // أخف
                                width: 1,
                              ),
                            ),
                            child: Text(
                              product.name,
                              style: FontHelper.cairo(
                                color: Colors.white,
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
                          top: 213, // تقليل المسافة لمنع القطع (186 + 24)
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.black.withValues(alpha: 0.4), Colors.black.withValues(alpha: 0.2)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                            ),
                            child: Row(
                              children: [
                                // السعر على اليسار - عرض محدد لمنع الدفع
                                Container(
                                  constraints: const BoxConstraints(maxWidth: 80), // عرض محدد
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    _formatPrice(product.wholesalePrice),
                                    style: FontHelper.cairo(
                                      color: Colors.white,
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
                  ), // إغلاق AnimatedContainer
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
              : LinearGradient(colors: [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.05)]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isLiked ? Colors.white.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isLiked ? Colors.red.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.2),
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
            color: isLiked ? Colors.white : Colors.white70,
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

  // 🧠 شريط البحث الذكي - يتكيف مع جميع الحالات
  Widget _buildAnimatedSearchBar() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeInBack,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack)),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: _buildSearchBarContent(),
    );
  }

  // 🎯 محتوى الشريط حسب الحالة
  Widget _buildSearchBarContent() {
    switch (_searchBarState) {
      case SearchBarState.hidden:
        return const SizedBox.shrink(); // اختفاء كامل

      case SearchBarState.buttonOnly:
        return _buildSearchButton();

      case SearchBarState.expanded:
        return _buildExpandedSearchBar();
    }
  }

  // 🔍 زر البحث الصغير
  Widget _buildSearchButton() {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('search_button'),
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.only(left: 0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFB8941F)]),
                borderRadius: const BorderRadius.only(topRight: Radius.circular(25), bottomRight: Radius.circular(25)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(2, 4)),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.search_rounded, color: Colors.white, size: 22),
                onPressed: () {
                  // حماية شاملة من النقرات المتعددة والحالات الخاطئة
                  if (!mounted || _searchBarState == SearchBarState.expanded || !context.mounted) return;

                  try {
                    // إزالة أي تركيز نشط
                    FocusScope.of(context).unfocus();

                    // تحديث الحالة مباشرة بدون async
                    _updateSearchBarState(SearchBarState.expanded);
                  } catch (e) {
                    debugPrint('❌ خطأ في فتح شريط البحث: $e');
                    // في حالة الخطأ، إعادة تعيين الحالة
                    if (mounted) {
                      setState(() {
                        _searchBarState = SearchBarState.buttonOnly;
                      });
                    }
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // 📝 شريط البحث المفتوح - نفس التصميم الأصلي بالضبط!
  Widget _buildExpandedSearchBar() {
    return Container(
      key: const ValueKey('expanded_search'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppDesignSystem.primaryBackground.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 55, // نفس ارتفاع الشريط الأصلي
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppDesignSystem.bottomNavColor.withValues(alpha: 0.85),
                    AppDesignSystem.activeButtonColor.withValues(alpha: 0.9),
                    AppDesignSystem.primaryBackground.withValues(alpha: 0.95),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(50), // نفس الشكل الأصلي
                border: Border.all(
                  color: AppDesignSystem.goldColor.withValues(alpha: 0.4), // نفس اللون
                  width: 1.2, // نفس السماكة
                ),
                boxShadow: [
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
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: TextField(
                  controller: _searchController,
                  // بدون autofocus لتجنب التداخل مع الانتقال الذكي
                  style: GoogleFonts.cairo(
                    color: AppDesignSystem.primaryTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                  onChanged: (value) {
                    if (mounted) {
                      try {
                        // البحث بدون تغيير الحالة
                        _searchProducts(value);
                      } catch (e) {
                        debugPrint('❌ خطأ في البحث من الشريط الموسع: $e');
                      }
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'ابحث عن المنتجات...',
                    hintStyle: GoogleFonts.cairo(
                      color: AppDesignSystem.primaryTextColor.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                    prefixIcon: Container(
                      padding: const EdgeInsets.all(14), // نفس الحشو الأصلي
                      child: Icon(
                        Icons.search_rounded,
                        color: AppDesignSystem.goldColor.withValues(alpha: 0.9),
                        size: AppDesignSystem.largeIconSize, // نفس الحجم الأصلي
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
                                color: AppDesignSystem.secondaryTextColor,
                                size: AppDesignSystem.mediumIconSize,
                              ),
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, // نفس الحشو الأصلي
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // زر X ذكي
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 3)),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                // حماية من النقرات المتعددة السريعة
                if (!mounted || _searchBarState != SearchBarState.expanded) return;

                try {
                  // إغلاق ذكي - العودة لزر البحث فقط
                  _searchController.clear();
                  _searchProducts('');
                  _updateSearchBarState(SearchBarState.buttonOnly);
                } catch (e) {
                  debugPrint('❌ خطأ في إغلاق شريط البحث: $e');
                }
              },
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
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
