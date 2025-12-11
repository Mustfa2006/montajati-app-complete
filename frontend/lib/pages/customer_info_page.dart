import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ✅ استبدال Supabase بـ LocationApiService
import '../services/location_api_service.dart';

import '../providers/theme_provider.dart';
import '../services/cart_service.dart';
import '../services/location_validation_service.dart';
import '../utils/error_handler.dart';
import '../widgets/app_background.dart';
import '../widgets/pull_to_refresh_wrapper.dart';

class CustomerInfoPage extends StatefulWidget {
  final Map<String, int> orderTotals;
  final List<dynamic> cartItems;
  final DateTime? scheduledDate; // ✅ تاريخ الجدولة
  final String? scheduleNotes; // ✅ ملاحظات الجدولة

  const CustomerInfoPage({
    super.key,
    required this.orderTotals,
    required this.cartItems,
    this.scheduledDate, // اختياري
    this.scheduleNotes, // اختياري
  });

  @override
  State<CustomerInfoPage> createState() => _CustomerInfoPageState();
}

class _CustomerInfoPageState extends State<CustomerInfoPage> with TickerProviderStateMixin {
  // Controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _primaryPhoneController = TextEditingController();
  final TextEditingController _secondaryPhoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Animation Controllers
  late AnimationController _glowController;
  late AnimationController _titleController;
  late AnimationController _shimmerController; // ✨ لتأثير Skeleton Loading
  // تم إزالة _glowAnimation غير المستخدم
  // تم إزالة _titleAnimation غير المستخدم

  // Form Data
  String? _selectedProvince;
  String? _selectedProvinceId; // ✅ إضافة معرف المحافظة
  String? _selectedCity;
  String? _selectedCityId;
  String? _selectedRegionId;
  bool _isSubmitting = false;
  bool _isLoadingCities = false;

  // 🔄 نظام التحميل الذكي - Smart Loading System
  bool _isLoadingProvinces = false;
  bool _hasProvincesError = false;
  bool _hasCitiesError = false;
  int _provincesRetryCount = 0;
  int _citiesRetryCount = 0;
  final int _maxRetries = 5;

  // بيانات شركة الوسيط
  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _cities = [];

  // قوائم البحث المفلترة
  List<Map<String, dynamic>> _filteredProvinces = [];
  List<Map<String, dynamic>> _filteredCities = [];

  // متحكمات البحث
  final TextEditingController _provinceSearchController = TextEditingController();
  final TextEditingController _citySearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    // _fillProductColors(); // معطل مؤقتًا لحل مشكلة الألوان
    _loadCitiesFromWaseet();
    // المستخدم يكتب رقم العميل بحرية
  }

  /// تحديث البيانات عند السحب للأسفل
  Future<void> _refreshData() async {
    debugPrint('🔄 تحديث بيانات صفحة معلومات الزبون...');

    // إعادة تحميل المحافظات
    await _loadCitiesFromWaseet();

    debugPrint('✅ تم تحديث بيانات صفحة معلومات الزبون');
  }

  // 🔄 جلب المحافظات مع نظام Retry ذكي - عبر API
  Future<void> _loadCitiesFromWaseet({bool isRetry = false}) async {
    if (!mounted) return;

    // إعادة تعيين عداد المحاولات إذا لم يكن retry
    if (!isRetry) {
      _provincesRetryCount = 0;
    }

    setState(() {
      _isLoadingProvinces = true;
      _isLoadingCities = true;
      _hasProvincesError = false;
    });

    debugPrint('🏛️ جلب المحافظات عبر API... المحاولة ${_provincesRetryCount + 1}/$_maxRetries');

    try {
      // ✅ استخدام LocationApiService بدلاً من Supabase مباشرة
      final provincesData = await LocationApiService.getProvinces();

      final provinces = provincesData.map((province) => province.toMap()).toList();

      if (mounted) {
        setState(() {
          _provinces = provinces;
          _filteredProvinces = provinces;
          _isLoadingProvinces = false;
          _isLoadingCities = false;
          _hasProvincesError = false;
          _provincesRetryCount = 0;
        });
      }

      debugPrint('✅ تم جلب ${provinces.length} محافظة عبر API');
    } catch (e) {
      debugPrint('❌ خطأ في جلب المحافظات: $e (المحاولة ${_provincesRetryCount + 1})');

      if (mounted) {
        _provincesRetryCount++;

        if (_provincesRetryCount < _maxRetries) {
          setState(() {
            _hasProvincesError = false;
          });

          final delay = Duration(seconds: _provincesRetryCount * 2);
          debugPrint('🔄 إعادة المحاولة بعد ${delay.inSeconds} ثواني...');

          await Future.delayed(delay);
          if (mounted) {
            _loadCitiesFromWaseet(isRetry: true);
          }
        } else {
          setState(() {
            _isLoadingProvinces = false;
            _isLoadingCities = false;
            _hasProvincesError = true;
            _provinces = [];
          });
        }
      }
    }
  }

  // 🔄 جلب المدن لمحافظة محددة مع نظام Retry ذكي - عبر API
  Future<void> _loadCitiesForProvince(String provinceId, {bool isRetry = false}) async {
    if (!mounted) return;

    if (!isRetry) {
      _citiesRetryCount = 0;
    }

    setState(() {
      _isLoadingCities = true;
      _hasCitiesError = false;
      if (!isRetry) {
        _cities = [];
        _filteredCities = [];
      }
    });

    debugPrint('🏙️ جلب المدن للمحافظة $provinceId عبر API... المحاولة ${_citiesRetryCount + 1}/$_maxRetries');

    try {
      // ✅ استخدام LocationApiService بدلاً من Supabase مباشرة
      final citiesData = await LocationApiService.getCities(provinceId);

      final cities = citiesData.map((city) => city.toMap()).toList();

      if (mounted) {
        setState(() {
          _cities = cities;
          _filteredCities = cities;
          _isLoadingCities = false;
          _hasCitiesError = false;
          _citiesRetryCount = 0;
        });
      }

      debugPrint('✅ تم جلب ${cities.length} مدينة عبر API');
    } catch (e) {
      debugPrint('❌ خطأ في جلب المدن: $e (المحاولة ${_citiesRetryCount + 1})');

      if (mounted) {
        _citiesRetryCount++;

        if (_citiesRetryCount < _maxRetries) {
          setState(() {
            _hasCitiesError = false;
          });

          final delay = Duration(seconds: _citiesRetryCount * 2);
          debugPrint('🔄 إعادة محاولة جلب المدن بعد ${delay.inSeconds} ثواني...');

          await Future.delayed(delay);
          if (mounted) {
            _loadCitiesForProvince(provinceId, isRetry: true);
          }
        } else {
          setState(() {
            _isLoadingCities = false;
            _hasCitiesError = true;
            _cities = [];
            _filteredCities = [];
          });
        }
      }
    }
  }

  // دالة البحث في المحافظات
  void _filterProvinces(String query, [Function? setModalState]) {
    final updateState = setModalState ?? setState;
    updateState(() {
      if (query.isEmpty) {
        _filteredProvinces = _provinces;
      } else {
        _filteredProvinces = _provinces.where((province) {
          // ✅ البحث فقط في بداية اسم المحافظة (exact prefix matching)
          final provinceName1 = province['city_name']?.toString().toLowerCase() ?? '';
          final provinceName2 = province['name']?.toString().toLowerCase() ?? '';
          final provinceName3 = province['province_name']?.toString().toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();

          return provinceName1.startsWith(searchQuery) ||
              provinceName2.startsWith(searchQuery) ||
              provinceName3.startsWith(searchQuery);
        }).toList();
      }
    });
  }

  // دالة البحث في المدن
  void _filterCities(String query, [Function? setModalState]) {
    final updateState = setModalState ?? setState;
    updateState(() {
      if (query.isEmpty) {
        _filteredCities = _cities;
      } else {
        _filteredCities = _cities.where((city) {
          // ✅ البحث في جميع الحقول المحتملة
          final cityName1 = city['region_name']?.toString().toLowerCase() ?? '';
          final cityName2 = city['name']?.toString().toLowerCase() ?? '';
          final cityName3 = city['city_name']?.toString().toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();

          return cityName1.contains(searchQuery) || cityName2.contains(searchQuery) || cityName3.contains(searchQuery);
        }).toList();
      }
    });
  }

  // ✨ دالة تحويل الأرقام العربية إلى إنجليزية
  String _convertArabicToEnglishNumbers(String input) {
    const arabicNumbers = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const englishNumbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

    String result = input;
    for (int i = 0; i < arabicNumbers.length; i++) {
      result = result.replaceAll(arabicNumbers[i], englishNumbers[i]);
    }
    return result;
  }

  void _initAnimations() {
    _glowController = AnimationController(duration: const Duration(seconds: 3), vsync: this)..repeat(reverse: true);

    _titleController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);

    // ✨ Shimmer Controller لتأثير Skeleton Loading
    _shimmerController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)..repeat();

    // تم إزالة تعيين _glowAnimation غير المستخدم

    // تم إزالة تعيين _titleAnimation غير المستخدم

    _titleController.forward();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _titleController.dispose();
    _shimmerController.dispose(); // ✨ تنظيف shimmer controller
    _nameController.dispose();
    _primaryPhoneController.dispose();
    _secondaryPhoneController.dispose();
    _notesController.dispose();
    _provinceSearchController.dispose();
    _citySearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AppBackground(
        child: PullToRefreshWrapper(
          onRefresh: _refreshData,
          refreshMessage: 'تم تحديث بيانات المحافظات',
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 25, left: 20, right: 20, bottom: 100),
            child: Column(
              children: [
                // الشريط العلوي يتحرك مع المحتوى
                _buildHeader(isDark),
                const SizedBox(height: 20),

                // المحتوى
                _buildFormContent(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🎨 الشريط العلوي
  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8), // تقليل الـ padding لسحب الزر لليمين
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // زر الرجوع
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1), // خلفية رمادية فاتحة
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.3), // حد رمادي
                  width: 1.5,
                ),
              ),
              child: Icon(FontAwesomeIcons.arrowRight, color: isDark ? Colors.white : Colors.black87, size: 18),
            ),
          ),

          // العنوان - تصغير الخط
          Text(
            'معلومات الزبون',
            style: GoogleFonts.cairo(
              fontSize: 18, // تصغير من 24 إلى 18
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: 0.3,
            ),
          ),

          // مساحة فارغة للتوازن
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // 📝 محتوى النموذج
  Widget _buildFormContent(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCustomerNameField(),
          const SizedBox(height: 12), // تقريب المسافة
          _buildPhoneFields(),
          const SizedBox(height: 12), // تقريب المسافة
          _buildLocationFields(),
          const SizedBox(height: 12), // تقريب المسافة
          _buildNotesField(),
          const SizedBox(height: 20),
          _buildSubmitButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 👤 حقل اسم الزبون
  Widget _buildCustomerNameField() {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            // ✨ تصميم نظيف واحترافي مع تضبيب
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.85),
            border: Border.all(
              color: isDark
                  ? const Color(0xFFe6b31e).withValues(alpha: 0.2)
                  : const Color(0xFFffd700).withValues(alpha: 0.25), // إطار ذهبي خفيف
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: isDark
                ? []
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                textAlign: TextAlign.right,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFf0f0f0) : const Color(0xFF2C2C2C),
                ),
                onChanged: (value) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  labelText: null,
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  hintText: 'أدخل اسم الزبون',
                  hintStyle: GoogleFonts.cairo(
                    fontSize: 15,
                    color: (isDark ? Colors.white : Colors.grey).withValues(alpha: 0.5),
                  ),
                  prefixIcon: Icon(Icons.person, color: isDark ? Colors.white54 : Colors.grey[600], size: 22),
                  suffixIcon: _nameController.text.trim().isNotEmpty
                      ? const Icon(Icons.check_circle, color: Colors.green, size: 22)
                      : null,
                  filled: true,
                  fillColor: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFFFFF8E7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _nameController.text.trim().isNotEmpty
                          ? Colors.green
                          : const Color(0xFFffd700).withValues(alpha: 0.4),
                      width: _nameController.text.trim().isNotEmpty ? 2 : 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _nameController.text.trim().isNotEmpty
                          ? Colors.green
                          : const Color(0xFFffd700).withValues(alpha: 0.4),
                      width: _nameController.text.trim().isNotEmpty ? 2 : 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _nameController.text.trim().isNotEmpty ? Colors.green : const Color(0xFFffd700),
                      width: 2,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.red, width: 2.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال اسم الزبون';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 📱 حقول أرقام الهواتف
  Widget _buildPhoneFields() {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            // ✨ تصميم نظيف واحترافي مع تضبيب
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.85), // خلفية بيضاء نظيفة
            border: Border.all(
              color: isDark
                  ? const Color(0xFFe6b31e).withValues(alpha: 0.2)
                  : const Color(0xFFffd700).withValues(alpha: 0.25), // حد رمادي فاتح
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: isDark
                ? []
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // رقم الهاتف الأساسي
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _primaryPhoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 11, // ✅ حد أقصى 11 رقم
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFf0f0f0) : const Color(0xFF2C2C2C),
                    ),
                    onChanged: (value) {
                      // ✨ تحويل الأرقام العربية إلى إنجليزية تلقائياً
                      final convertedValue = _convertArabicToEnglishNumbers(value);
                      if (convertedValue != value) {
                        _primaryPhoneController.value = TextEditingValue(
                          text: convertedValue,
                          selection: TextSelection.collapsed(offset: convertedValue.length),
                        );
                      }
                      setState(() {}); // ✅ تحديث الواجهة عند تغيير النص
                    },
                    decoration: InputDecoration(
                      labelText: null, // ✅ إزالة أي label
                      floatingLabelBehavior: FloatingLabelBehavior.never, // ✅ منع floating
                      hintText: '07xxxxxxxxx',
                      hintStyle: GoogleFonts.cairo(
                        fontSize: 15,
                        color: (isDark ? Colors.white : Colors.grey).withValues(alpha: 0.5),
                      ),
                      prefixIcon: const Icon(Icons.phone, color: Colors.grey, size: 22),
                      // ✅ علامة الصح عند كتابة 11 رقم صحيح
                      suffixIcon:
                          _primaryPhoneController.text.length == 11 && _primaryPhoneController.text.startsWith('07')
                          ? const Icon(Icons.check_circle, color: Colors.green, size: 22)
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? Colors.black.withValues(alpha: 0.2)
                          : const Color(0xFFFFF8E7), // خلفية فاتحة جداً
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color:
                              _primaryPhoneController.text.length == 11 && _primaryPhoneController.text.startsWith('07')
                              ? Colors.green
                              : const Color(0xFFffd700).withValues(alpha: 0.4),
                          width:
                              _primaryPhoneController.text.length == 11 && _primaryPhoneController.text.startsWith('07')
                              ? 2
                              : 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color:
                              _primaryPhoneController.text.length == 11 && _primaryPhoneController.text.startsWith('07')
                              ? Colors.green
                              : const Color(0xFFffd700).withValues(alpha: 0.4),
                          width:
                              _primaryPhoneController.text.length == 11 && _primaryPhoneController.text.startsWith('07')
                              ? 1.5
                              : 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color:
                              _primaryPhoneController.text.length == 11 && _primaryPhoneController.text.startsWith('07')
                              ? Colors.green
                              : const Color(0xFFffd700),
                          width:
                              _primaryPhoneController.text.length == 11 && _primaryPhoneController.text.startsWith('07')
                              ? 1.5
                              : 2,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Colors.red, width: 1),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
                      counterText: '', // ✅ إخفاء عداد الأحرف
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'رقم الهاتف مطلوب';
                      }
                      if (value.length != 11) {
                        return 'يجب أن يكون رقم الهاتف من 11 رقم';
                      }
                      if (!value.startsWith('07')) {
                        return 'رقم الهاتف يجب أن يبدأ بـ 07';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20), // مساحة بين الحقلين
              // رقم الهاتف البديل
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _secondaryPhoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 11, // ✅ حد أقصى 11 رقم
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFf0f0f0) : Colors.black,
                    ),
                    onChanged: (value) {
                      // ✨ تحويل الأرقام العربية إلى إنجليزية تلقائياً
                      final convertedValue = _convertArabicToEnglishNumbers(value);
                      if (convertedValue != value) {
                        _secondaryPhoneController.value = TextEditingValue(
                          text: convertedValue,
                          selection: TextSelection.collapsed(offset: convertedValue.length),
                        );
                      }
                      setState(() {}); // ✅ تحديث الواجهة عند تغيير النص
                    },
                    decoration: InputDecoration(
                      labelText: null, // ✅ إزالة أي label
                      floatingLabelBehavior: FloatingLabelBehavior.never, // ✅ منع floating
                      hintText: '07xxxxxxxxx (اختياري)',
                      hintStyle: GoogleFonts.cairo(
                        fontSize: 14,
                        color: (isDark ? Colors.white : Colors.grey).withValues(alpha: 0.5),
                      ),
                      prefixIcon: const Icon(Icons.phone, color: Colors.grey, size: 20),
                      // ✅ علامة الصح عند كتابة 11 رقم صحيح (اختياري)
                      suffixIcon:
                          _secondaryPhoneController.text.isNotEmpty &&
                              _secondaryPhoneController.text.length == 11 &&
                              _secondaryPhoneController.text.startsWith('07')
                          ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                          : null,
                      filled: true,
                      fillColor: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color:
                              _secondaryPhoneController.text.isNotEmpty &&
                                  _secondaryPhoneController.text.length == 11 &&
                                  _secondaryPhoneController.text.startsWith('07')
                              ? Colors.green
                              : const Color(0xFFffd700).withValues(alpha: 0.4),
                          width:
                              _secondaryPhoneController.text.isNotEmpty &&
                                  _secondaryPhoneController.text.length == 11 &&
                                  _secondaryPhoneController.text.startsWith('07')
                              ? 1.5
                              : 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color:
                              _secondaryPhoneController.text.isNotEmpty &&
                                  _secondaryPhoneController.text.length == 11 &&
                                  _secondaryPhoneController.text.startsWith('07')
                              ? Colors.green
                              : const Color(0xFFffd700).withValues(alpha: 0.4),
                          width:
                              _secondaryPhoneController.text.isNotEmpty &&
                                  _secondaryPhoneController.text.length == 11 &&
                                  _secondaryPhoneController.text.startsWith('07')
                              ? 1.5
                              : 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color:
                              _secondaryPhoneController.text.isNotEmpty &&
                                  _secondaryPhoneController.text.length == 11 &&
                                  _secondaryPhoneController.text.startsWith('07')
                              ? Colors.green
                              : const Color(0xFFffd700),
                          width:
                              _secondaryPhoneController.text.isNotEmpty &&
                                  _secondaryPhoneController.text.length == 11 &&
                                  _secondaryPhoneController.text.startsWith('07')
                              ? 1.5
                              : 2,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Colors.red, width: 1),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
                      counterText: '', // ✅ إخفاء عداد الأحرف
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (value.length != 11) {
                          return 'يجب أن يكون من 11 رقم';
                        }
                        if (!value.startsWith('07')) {
                          return 'يجب أن يبدأ بـ 07';
                        }
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🌍 حقول الموقع
  Widget _buildLocationFields() {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            // ✨ تصميم نظيف واحترافي مع تضبيب
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.85),
            border: Border.all(
              color: isDark
                  ? const Color(0xFFe6b31e).withValues(alpha: 0.2)
                  : const Color(0xFFffd700).withValues(alpha: 0.25),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: isDark
                ? []
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // المحافظة
              _buildProvinceField(),
              const SizedBox(height: 20),
              // المدينة
              _buildCityField(),
            ],
          ),
        ),
      ),
    );
  }

  // 🏛️ حقل المحافظة
  Widget _buildProvinceField() {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFffd700).withValues(alpha: 0.3 + (_glowController.value * 0.4)),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFffd700).withValues(alpha: 0.3 * _glowController.value),
                        blurRadius: 4 + (_glowController.value * 4),
                        spreadRadius: _glowController.value * 2,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            Text(
              'المحافظة',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFffd700).withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            // تحويل إلى وضع البحث أو فتح القائمة
            _showProvinceSelector();
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
              border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.25), width: 1.5),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedProvince ?? 'اختر المحافظة',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _selectedProvince != null
                          ? (isDark ? const Color(0xFFf0f0f0) : Colors.black)
                          : (isDark ? Colors.white : Colors.grey).withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const Icon(FontAwesomeIcons.chevronDown, color: Colors.grey, size: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 🏙️ حقل المدينة
  Widget _buildCityField() {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFffd700).withValues(alpha: 0.3 + (_glowController.value * 0.4)),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFffd700).withValues(alpha: 0.3 * _glowController.value),
                        blurRadius: 4 + (_glowController.value * 4),
                        spreadRadius: _glowController.value * 2,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            Text(
              'المدينة',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFffd700).withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _selectedProvince != null
              ? () {
                  _showCitySelector();
                }
              : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
              border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.25), width: 1.5),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedCity ?? (_selectedProvince != null ? 'اختر المدينة أولاً' : 'اختر المحافظة أولاً'),
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _selectedCity != null
                          ? (isDark ? const Color(0xFFf0f0f0) : Colors.black)
                          : (isDark ? Colors.white : Colors.grey).withValues(alpha: 0.5),
                    ),
                  ),
                ),
                Icon(
                  FontAwesomeIcons.chevronDown,
                  color: _selectedProvince != null ? Colors.grey : Colors.white.withValues(alpha: 0.3),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 📋 عرض قائمة المحافظات
  void _showProvinceSelector() {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    // تهيئة القائمة المفلترة
    _filteredProvinces = _provinces;
    _provinceSearchController.clear();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                // ✨ خلفية سوداء متناسقة مع الوضع الليلي
                color: isDark ? const Color(0xFF121212) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFFffd700).withValues(alpha: 0.15)
                      : const Color(0xFFffd700).withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // ✨ المقبض العلوي
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFFffd700).withValues(alpha: 0.3)
                          : Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // ✨ العنوان مع تأثير التوهج
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFFffd700).withValues(alpha: 0.1)
                                    : const Color(0xFFffd700).withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(FontAwesomeIcons.locationDot, color: const Color(0xFFffd700), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'اختر المحافظة',
                              style: GoogleFonts.cairo(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ✨ شريط البحث المحسن
                        Container(
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
                          child: TextField(
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: 'ابحث عن المحافظة...',
                              hintStyle: GoogleFonts.cairo(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.4)
                                    : Colors.grey.withValues(alpha: 0.6),
                              ),
                              prefixIcon: Icon(
                                FontAwesomeIcons.magnifyingGlass,
                                color: isDark ? const Color(0xFFffd700).withValues(alpha: 0.7) : Colors.grey,
                                size: 16,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.grey.withValues(alpha: 0.08),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFFffd700).withValues(alpha: 0.3)
                                      : Colors.grey.withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFFffd700).withValues(alpha: 0.3)
                                      : Colors.grey.withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: const Color(0xFFffd700), width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            ),
                            controller: _provinceSearchController,
                            onChanged: (value) {
                              _filterProvinces(value, setModalState);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ✨ قائمة المحافظات مع Skeleton Loading
                  if (_isLoadingProvinces || _isLoadingCities)
                    Expanded(
                      child: _hasProvincesError
                          ? // حالة الخطأ مع زر إعادة المحاولة
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    FontAwesomeIcons.triangleExclamation,
                                    color: Colors.orange.withValues(alpha: 0.8),
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'فشل تحميل المحافظات',
                                    style: GoogleFonts.cairo(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'تحقق من اتصالك بالإنترنت',
                                    style: GoogleFonts.cairo(
                                      fontSize: 14,
                                      color: isDark ? Colors.white38 : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  GestureDetector(
                                    onTap: () {
                                      _loadCitiesFromWaseet();
                                      setModalState(() {});
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFffd700).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.4)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(FontAwesomeIcons.arrowsRotate, color: const Color(0xFFffd700), size: 16),
                                          const SizedBox(width: 8),
                                          Text(
                                            'إعادة المحاولة',
                                            style: GoogleFonts.cairo(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFFffd700),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : // Skeleton Loading
                            ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: 8, // عدد العناصر الوهمية
                              itemBuilder: (context, index) {
                                return AnimatedBuilder(
                                  animation: _shimmerController,
                                  builder: (context, child) {
                                    final shimmerValue = _shimmerController.value;
                                    final opacity = 0.3 + (0.3 * (1 + math.cos(shimmerValue * 3.14159 * 2)) / 2);

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: opacity * 0.1)
                                            : Colors.grey.withValues(alpha: opacity * 0.15),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.05)
                                              : Colors.grey.withValues(alpha: 0.1),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            // دائرة skeleton
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? Colors.white.withValues(alpha: opacity * 0.1)
                                                    : Colors.grey.withValues(alpha: opacity * 0.2),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            // شريط نص skeleton
                                            Expanded(
                                              child: Container(
                                                height: 16,
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? Colors.white.withValues(alpha: opacity * 0.1)
                                                      : Colors.grey.withValues(alpha: opacity * 0.2),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 50 + (index * 20 % 80).toDouble()), // تفاوت في العرض
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredProvinces.length,
                        itemBuilder: (context, index) {
                          final province = _filteredProvinces[index];
                          final provinceName = province['city_name'] ?? province['name'] ?? '';
                          final provinceId = province['id'] ?? '';
                          final isSelected = _selectedProvince == provinceName;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: isDark
                                          ? [
                                              const Color(0xFFffd700).withValues(alpha: 0.2),
                                              const Color(0xFFffd700).withValues(alpha: 0.1),
                                            ]
                                          : [
                                              const Color(0xFFffd700).withValues(alpha: 0.15),
                                              const Color(0xFFffd700).withValues(alpha: 0.05),
                                            ],
                                    )
                                  : null,
                              color: isSelected
                                  ? null
                                  : (isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.grey.withValues(alpha: 0.05)),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFffd700)
                                    : (isDark
                                          ? Colors.white.withValues(alpha: 0.1)
                                          : Colors.grey.withValues(alpha: 0.1)),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFffd700).withValues(alpha: 0.2)
                                      : (isDark
                                            ? Colors.white.withValues(alpha: 0.08)
                                            : Colors.grey.withValues(alpha: 0.1)),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isSelected ? FontAwesomeIcons.circleCheck : FontAwesomeIcons.city,
                                  color: isSelected ? const Color(0xFFffd700) : (isDark ? Colors.white54 : Colors.grey),
                                  size: 16,
                                ),
                              ),
                              title: Text(
                                provinceName,
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  color: isSelected
                                      ? const Color(0xFFffd700)
                                      : (isDark ? Colors.white : Colors.black87),
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(FontAwesomeIcons.check, color: const Color(0xFFffd700), size: 16)
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedProvince = provinceName;
                                  _selectedProvinceId = provinceId;
                                  _selectedCity = null;
                                  _selectedCityId = null;
                                  _selectedRegionId = null;
                                });
                                Navigator.pop(context);
                                _loadCitiesForProvince(provinceId);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 🏙️ عرض قائمة المدن
  void _showCitySelector() {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    if (_selectedProvince == null) return;

    // تهيئة القائمة المفلترة
    _filteredCities = _cities;
    _citySearchController.clear();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                // ✨ خلفية سوداء متناسقة مع الوضع الليلي
                color: isDark ? const Color(0xFF121212) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFFffd700).withValues(alpha: 0.15)
                      : const Color(0xFFffd700).withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // ✨ المقبض العلوي
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFFffd700).withValues(alpha: 0.3)
                          : Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // ✨ العنوان
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFFffd700).withValues(alpha: 0.1)
                                    : const Color(0xFFffd700).withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(FontAwesomeIcons.building, color: const Color(0xFFffd700), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'اختر المدينة',
                              style: GoogleFonts.cairo(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ✨ شريط البحث
                        Container(
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
                          child: TextField(
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: 'ابحث عن المدينة...',
                              hintStyle: GoogleFonts.cairo(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.4)
                                    : Colors.grey.withValues(alpha: 0.6),
                              ),
                              prefixIcon: Icon(
                                FontAwesomeIcons.magnifyingGlass,
                                color: isDark ? const Color(0xFFffd700).withValues(alpha: 0.7) : Colors.grey,
                                size: 16,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.grey.withValues(alpha: 0.08),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFFffd700).withValues(alpha: 0.3)
                                      : Colors.grey.withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFFffd700).withValues(alpha: 0.3)
                                      : Colors.grey.withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: const Color(0xFFffd700), width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            ),
                            controller: _citySearchController,
                            onChanged: (value) {
                              _filterCities(value, setModalState);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ✨ قائمة المدن مع Skeleton Loading
                  if (_isLoadingCities)
                    Expanded(
                      child: _hasCitiesError
                          ? // حالة الخطأ مع زر إعادة المحاولة
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    FontAwesomeIcons.triangleExclamation,
                                    color: Colors.orange.withValues(alpha: 0.8),
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'فشل تحميل المدن',
                                    style: GoogleFonts.cairo(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'تحقق من اتصالك بالإنترنت',
                                    style: GoogleFonts.cairo(
                                      fontSize: 14,
                                      color: isDark ? Colors.white38 : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  GestureDetector(
                                    onTap: () {
                                      if (_selectedProvinceId != null) {
                                        _loadCitiesForProvince(_selectedProvinceId!);
                                        setModalState(() {});
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFffd700).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.4)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(FontAwesomeIcons.arrowsRotate, color: const Color(0xFFffd700), size: 16),
                                          const SizedBox(width: 8),
                                          Text(
                                            'إعادة المحاولة',
                                            style: GoogleFonts.cairo(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFFffd700),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : // Skeleton Loading
                            ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: 8,
                              itemBuilder: (context, index) {
                                return AnimatedBuilder(
                                  animation: _shimmerController,
                                  builder: (context, child) {
                                    final shimmerValue = _shimmerController.value;
                                    final opacity = 0.3 + (0.3 * (1 + math.cos(shimmerValue * 3.14159 * 2)) / 2);

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: opacity * 0.1)
                                            : Colors.grey.withValues(alpha: opacity * 0.15),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.05)
                                              : Colors.grey.withValues(alpha: 0.1),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            // دائرة skeleton
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? Colors.white.withValues(alpha: opacity * 0.1)
                                                    : Colors.grey.withValues(alpha: opacity * 0.2),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            // شريط نص skeleton
                                            Expanded(
                                              child: Container(
                                                height: 16,
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? Colors.white.withValues(alpha: opacity * 0.1)
                                                      : Colors.grey.withValues(alpha: opacity * 0.2),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 50 + (index * 20 % 80).toDouble()),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    )
                  else if (_cities.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              FontAwesomeIcons.circleExclamation,
                              color: isDark ? Colors.white38 : Colors.grey,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد مدن متاحة',
                              style: GoogleFonts.cairo(fontSize: 16, color: isDark ? Colors.white54 : Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredCities.length,
                        itemBuilder: (context, index) {
                          final city = _filteredCities[index];
                          final cityName = city['region_name'] ?? city['name'] ?? '';
                          final cityId = city['id'] ?? '';
                          final isSelected = _selectedCity == cityName;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: isDark
                                          ? [
                                              const Color(0xFFffd700).withValues(alpha: 0.2),
                                              const Color(0xFFffd700).withValues(alpha: 0.1),
                                            ]
                                          : [
                                              const Color(0xFFffd700).withValues(alpha: 0.15),
                                              const Color(0xFFffd700).withValues(alpha: 0.05),
                                            ],
                                    )
                                  : null,
                              color: isSelected
                                  ? null
                                  : (isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.grey.withValues(alpha: 0.05)),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFffd700)
                                    : (isDark
                                          ? Colors.white.withValues(alpha: 0.1)
                                          : Colors.grey.withValues(alpha: 0.1)),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFffd700).withValues(alpha: 0.2)
                                      : (isDark
                                            ? Colors.white.withValues(alpha: 0.08)
                                            : Colors.grey.withValues(alpha: 0.1)),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isSelected ? FontAwesomeIcons.circleCheck : FontAwesomeIcons.building,
                                  color: isSelected ? const Color(0xFFffd700) : (isDark ? Colors.white54 : Colors.grey),
                                  size: 16,
                                ),
                              ),
                              title: Text(
                                cityName,
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  color: isSelected
                                      ? const Color(0xFFffd700)
                                      : (isDark ? Colors.white : Colors.black87),
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(FontAwesomeIcons.check, color: const Color(0xFFffd700), size: 16)
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedCity = cityName;
                                  _selectedCityId = cityId;
                                });
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 📝 حقل الملاحظات
  Widget _buildNotesField() {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            // ✨ تصميم نظيف واحترافي مع تضبيب
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.85),
            border: Border.all(
              color: isDark
                  ? const Color(0xFFe6b31e).withValues(alpha: 0.2)
                  : const Color(0xFFffd700).withValues(alpha: 0.25),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: isDark
                ? []
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _notesController,
                maxLines: null,
                minLines: 3,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                textAlign: TextAlign.right,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFf0f0f0) : const Color(0xFF2C2C2C),
                ),
                onChanged: (value) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  labelText: null,
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  hintText: 'لون المنتج، تفاصيل الموقع، أو أي ملاحظات أخرى...',
                  hintStyle: GoogleFonts.cairo(
                    fontSize: 15,
                    color: (isDark ? Colors.white : Colors.grey).withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFFFFF8E7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _notesController.text.trim().isNotEmpty
                          ? Colors.green
                          : const Color(0xFFffd700).withValues(alpha: 0.25),
                      width: _notesController.text.trim().isNotEmpty ? 2 : 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _notesController.text.trim().isNotEmpty
                          ? Colors.green
                          : const Color(0xFFffd700).withValues(alpha: 0.25),
                      width: _notesController.text.trim().isNotEmpty ? 2 : 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _notesController.text.trim().isNotEmpty ? Colors.green : Colors.blue,
                      width: 2,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.red, width: 1),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                ),
                readOnly: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ زر الإرسال
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey,
          foregroundColor: Colors.black,
          elevation: 8,
          shadowColor: Colors.grey.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'جاري الإرسال...',
                    style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(FontAwesomeIcons.paperPlane, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'ملخص الطلب',
                    style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                  ),
                ],
              ),
      ),
    );
  }

  // ✅ التحقق من الحقول المطلوبة
  String? _validateRequiredFields() {
    if (_nameController.text.trim().isEmpty) {
      return 'name';
    }
    if (_primaryPhoneController.text.trim().isEmpty) {
      return 'phone';
    }
    if (_selectedProvince == null) {
      return 'province';
    }
    if (_selectedCityId == null) {
      return 'city';
    }
    return null; // جميع الحقول مملوءة
  }

  // ✅ إظهار تنبيه وانتقال للحقل المطلوب
  void _showFieldError(String? fieldType) {
    if (fieldType == null) return;

    String message = '';
    Widget? targetWidget;

    switch (fieldType) {
      case 'name':
        message = 'يرجى إدخال اسم الزبون';
        targetWidget = _buildCustomerNameField();
        break;
      case 'phone':
        message = 'يرجى إدخال رقم الهاتف الأساسي';
        targetWidget = _buildPhoneFields();
        break;
      case 'province':
        message = 'يرجى اختيار المحافظة';
        targetWidget = _buildLocationFields();
        break;
      case 'city':
        message = 'يرجى اختيار المدينة';
        targetWidget = _buildLocationFields();
        break;
    }

    // إظهار رسالة تنبيه
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // التمرير للحقل المطلوب
    if (targetWidget != null) {
      Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    }
  }

  // 📤 إرسال الطلب
  void _submitOrder() async {
    debugPrint('🚀 تم الضغط على زر إرسال الطلب في صفحة معلومات العميل');

    // ✅ التحقق من الحقول المطلوبة وإظهار تنبيهات مخصصة
    String? missingField = _validateRequiredFields();
    if (missingField != null) {
      _showFieldError(missingField);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ فشل في التحقق من صحة النموذج');
      return;
    }

    // التحقق من اختيار المحافظة والمدينة فقط
    if (_selectedProvince == null || _selectedCityId == null || _selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يرجى اختيار المحافظة والمدينة',
            style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          backgroundColor: const Color(0xFFdc3545),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // ✅ التحقق من صحة بيانات الموقع قبل الإرسال
    debugPrint('🔍 التحقق من صحة بيانات الموقع قبل إرسال الطلب...');
    debugPrint('🔍 معرف المحافظة المرسل: $_selectedProvinceId');
    debugPrint('🔍 معرف المدينة المرسل: $_selectedCityId');
    debugPrint('🔍 اسم المحافظة: $_selectedProvince');
    debugPrint('🔍 اسم المدينة: $_selectedCity');

    try {
      final locationValidation = await LocationValidationService.validateOrderLocation(
        provinceId: _selectedProvinceId!,
        cityId: _selectedCityId!,
      );

      if (!locationValidation.isValid) {
        debugPrint('❌ فشل التحقق من صحة بيانات الموقع: ${locationValidation.error}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'خطأ في بيانات الموقع: ${locationValidation.error}',
                style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              backgroundColor: const Color(0xFFdc3545),
              duration: const Duration(seconds: 5),
              action: locationValidation.suggestion != null
                  ? SnackBarAction(
                      label: 'تحديث البيانات',
                      textColor: Colors.grey,
                      onPressed: () {
                        // يمكن إضافة وظيفة لتحديث البيانات هنا
                      },
                    )
                  : null,
            ),
          );
        }
        return;
      }

      debugPrint('✅ تم التحقق من صحة بيانات الموقع بنجاح');
      debugPrint(
        '   المحافظة: "${locationValidation.provinceName}" (external_id: ${locationValidation.provinceExternalId})',
      );
      debugPrint('   المدينة: "${locationValidation.cityName}" (external_id: ${locationValidation.cityExternalId})');
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من صحة بيانات الموقع: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في التحقق من بيانات الموقع. يرجى المحاولة مرة أخرى.',
              style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            backgroundColor: const Color(0xFFdc3545),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // استخدام المدينة كمنطقة افتراضية إذا لم يتم اختيار منطقة محددة
    String regionIdToUse = _selectedRegionId ?? _selectedCityId!;

    debugPrint(
      '🗺️ استخدام المنطقة: $regionIdToUse (${_selectedRegionId != null ? "منطقة محددة" : "المدينة كمنطقة افتراضية"})',
    );

    // إزالة التحقق من المنطقة المطلوبة - لأننا نستخدم المدينة كمنطقة افتراضية
    /*
    if (_selectedCity == null || _selectedRegionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يرجى اختيار المنطقة',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFFdc3545),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    */

    setState(() {
      _isSubmitting = true;
    });

    try {
      // حساب إجمالي السعر وعدد القطع
      int itemsCount = widget.cartItems.length;

      // إعداد قائمة المنتجات للنظام الرسمي وحساب الربح والمجموع الفرعي
      final List<Map<String, dynamic>> orderItems = [];
      double totalProfit = 0.0;
      double subtotalAmount = 0.0; // ✅ حساب المجموع الفرعي الصحيح

      for (var item in widget.cartItems) {
        // ✅ إصلاح: التعامل مع كلا من CartItem و Map
        double customerPrice;
        double wholesalePrice;
        int quantity;
        String name;
        String image;
        String id;
        String productId;
        String? colorId; // 🎨 معرف اللون
        String? colorName; // 🎨 اسم اللون
        String? colorCode; // 🎨 كود اللون

        if (item is CartItem) {
          // إذا كان العنصر من نوع CartItem (للطلبات المجدولة)
          customerPrice = item.customerPrice.toDouble();
          wholesalePrice = item.wholesalePrice.toDouble();
          quantity = item.quantity;
          name = item.name;
          image = item.image;
          id = item.id;
          productId = item.productId;
          colorId = item.colorId; // 🎨 اللون
          colorName = item.colorName; // 🎨 اسم اللون
          colorCode = item.colorHex; // 🎨 كود اللون
        } else {
          // إذا كان العنصر من نوع Map (للطلبات العادية)
          customerPrice = (item['customerPrice'] ?? 0.0).toDouble();
          wholesalePrice = (item['wholesalePrice'] ?? 0.0).toDouble();
          quantity = (item['quantity'] ?? 1).toInt();
          name = item['name'] ?? 'منتج';
          image = item['image'] ?? '';
          id = item['id']?.toString() ?? 'PRODUCT_${DateTime.now().millisecondsSinceEpoch}';
          productId = item['productId']?.toString() ?? '';
          colorId = item['colorId']?.toString(); // 🎨 اللون
          colorName = item['colorName']?.toString(); // 🎨 اسم اللون
          colorCode = item['colorHex']?.toString(); // 🎨 كود اللون
        }

        final itemProfit = (customerPrice - wholesalePrice) * quantity;
        final itemSubtotal = customerPrice * quantity;

        totalProfit += itemProfit > 0 ? itemProfit : 0;
        subtotalAmount += itemSubtotal; // ✅ جمع المجموع الفرعي

        orderItems.add({
          'name': name,
          'quantity': quantity,
          'price': customerPrice,
          'customerPrice': customerPrice, // ✅ إضافة customerPrice
          'wholesalePrice': wholesalePrice,
          'image': image, // ✅ إضافة صورة المنتج
          'productId': productId, // ✅ إضافة معرف المنتج الصحيح
          'sku': id,
          'colorId': colorId, // 🎨 معرف اللون
          'colorName': colorName, // 🎨 اسم اللون
          'colorCode': colorCode, // 🎨 كود اللون
        });
      }

      // إنشاء الطلب في قاعدة البيانات بحالة "نشط"
      debugPrint('📦 تحضير بيانات الطلب...');
      debugPrint('🏙️ المدينة: $_selectedCityId');
      debugPrint('🗺️ المنطقة المستخدمة: $regionIdToUse');
      debugPrint('💰 المجموع الفرعي: ${subtotalAmount.toInt()} د.ع');
      debugPrint('💎 الربح الإجمالي: ${totalProfit.toInt()} د.ع');
      debugPrint('📦 عدد القطع: $itemsCount');

      // ✅ حفظ الطلب في قاعدة البيانات العادية بحالة "نشط"
      debugPrint('💾 إنشاء طلب جديد في قاعدة البيانات بحالة "نشط"');

      // استخدام النظام الرسمي والمعتمد لحفظ الطلبات
      // سيتم حفظ الطلب في قاعدة البيانات الرسمية بحالة "نشط"

      debugPrint('💎 الربح الإجمالي المحسوب: $totalProfit د.ع');

      // تجهيز بيانات الطلب لإرسالها إلى صفحة ملخص الطلب
      debugPrint('📋 تجهيز بيانات الطلب لصفحة ملخص الطلب...');

      // ✅ الحصول على رقم الهاتف المحفوظ من SharedPreferences (النظام الرسمي)
      final prefs = await SharedPreferences.getInstance();
      final currentUserPhone = prefs.getString('current_user_phone');

      if (currentUserPhone == null || currentUserPhone.isEmpty) {
        throw Exception('لا يوجد رقم هاتف محفوظ للمستخدم الحالي');
      }

      debugPrint('📱 استخدام رقم الهاتف المحفوظ: $currentUserPhone');

      final orderData = {
        'customerName': _nameController.text.trim(),
        'primaryPhone': _primaryPhoneController.text.trim(), // ✅ رقم العميل الذي كتبه المستخدم
        'secondaryPhone': _secondaryPhoneController.text.trim().isNotEmpty
            ? _secondaryPhoneController.text.trim()
            : null,
        'province': _selectedProvince,
        'city': _selectedCity,
        'provinceId': _selectedProvinceId, // ✅ إضافة معرف المحافظة
        'cityId': _selectedCityId!,
        'regionId': regionIdToUse,
        'deliveryAddress': '$_selectedProvince - $_selectedCity', // ✅ العنوان الفعلي
        'customerNotes': _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null, // ✅ ملاحظات العميل الفعلية أو null
        'items': orderItems,
        'totals': {
          'subtotal': subtotalAmount.toInt(),
          'profit': widget.orderTotals['profit'] ?? 0, // ✅ استخدام الربح من السلة
        }, // ✅ استخدام المجموع الفرعي الصحيح
        // ✅ إضافة بيانات الجدولة إذا كانت موجودة
        'scheduledDate': widget.scheduledDate,
        'scheduleNotes': widget.scheduleNotes,
      };

      debugPrint('✅ تم تجهيز بيانات الطلب بنجاح');
      debugPrint('📊 المجموع الفرعي: ${subtotalAmount.toInt()} د.ع');
      debugPrint('💎 الربح الإجمالي: ${totalProfit.toInt()} د.ع');

      if (mounted) {
        // ⚠️ لا نمسح السلة هنا! سيتم مسحها فقط بعد تأكيد الطلب بنجاح في صفحة ملخص الطلب
        // هذا يسمح للمستخدم بالرجوع وتعديل البيانات دون فقدان السلة

        // الانتقال إلى صفحة ملخص الطلب باستخدام push للحفاظ على تاريخ التنقل
        // هذا يسمح للمستخدم بالرجوع لصفحة بيانات العميل عند الضغط على زر الرجوع
        context.push('/order-summary', extra: orderData);
      }
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء الطلب: $e');

      // إظهار رسالة خطأ مناسبة للمستخدم
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          e,
          customMessage: ErrorHandler.isNetworkError(e)
              ? 'لا يوجد اتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مرة أخرى.'
              : 'حدث خطأ في إنشاء الطلب. يرجى المحاولة مرة أخرى.',
          onRetry: () => _submitOrder(),
          duration: const Duration(seconds: 5),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
