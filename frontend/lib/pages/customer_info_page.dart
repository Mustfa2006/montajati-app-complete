import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/cart_service.dart';


import '../services/location_validation_service.dart';
import '../utils/error_handler.dart';
import '../widgets/pull_to_refresh_wrapper.dart';
import '../widgets/common_header.dart';

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

class _CustomerInfoPageState extends State<CustomerInfoPage>
    with TickerProviderStateMixin {
  // Controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _primaryPhoneController = TextEditingController();
  final TextEditingController _secondaryPhoneController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Animation Controllers
  late AnimationController _glowController;
  late AnimationController _titleController;
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

  // خدمات
  final CartService _cartService = CartService();

  // بيانات شركة الوسيط
  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _cities = [];

  // قوائم البحث المفلترة
  List<Map<String, dynamic>> _filteredProvinces = [];
  List<Map<String, dynamic>> _filteredCities = [];

  // متحكمات البحث
  final TextEditingController _provinceSearchController =
      TextEditingController();
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

  // جلب المحافظات والمدن مباشرة من قاعدة البيانات
  Future<void> _loadCitiesFromWaseet() async {
    try {
      setState(() {
        _isLoadingCities = true;
      });

      debugPrint('🏛️ جلب المحافظات مباشرة من قاعدة البيانات...');

      // جلب المحافظات مباشرة من قاعدة البيانات
      final response = await Supabase.instance.client
          .from('provinces')
          .select('id, name, external_id, provider_name')
          .eq('provider_name', 'alwaseet')
          .order('name');

      final provinces = response.map((province) => {
        'id': province['id']?.toString() ?? '',
        'name': province['name']?.toString() ?? '',
        'external_id': province['external_id']?.toString() ?? '',
      }).toList();

      setState(() {
        _provinces = provinces;
        _filteredProvinces = provinces; // تحديث القائمة المفلترة
        _isLoadingCities = false;
      });

      debugPrint('✅ تم جلب ${provinces.length} محافظة مباشرة من قاعدة البيانات');
    } catch (e) {
      setState(() {
        _isLoadingCities = false;
        _provinces = [];
      });
      debugPrint('❌ خطأ في جلب المحافظات من شركة الوسيط: $e');

      // إظهار رسالة خطأ مناسبة للمستخدم
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          e,
          customMessage: ErrorHandler.isNetworkError(e)
              ? 'لا يوجد اتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مرة أخرى.'
              : 'حدث خطأ في تحميل المحافظات. يرجى المحاولة مرة أخرى.',
          onRetry: () => _loadCitiesFromWaseet(),
        );
      }
    }
  }

  // جلب المدن لمحافظة محددة مباشرة من قاعدة البيانات
  Future<void> _loadCitiesForProvince(String provinceId) async {
    try {
      // إظهار التحميل فوراً
      setState(() {
        _isLoadingCities = true;
        _cities = []; // مسح المدن السابقة فوراً
      });

      debugPrint('🏙️ جلب المدن للمحافظة $provinceId مباشرة من قاعدة البيانات...');

      // جلب المدن مباشرة من قاعدة البيانات
      final response = await Supabase.instance.client
          .from('cities')
          .select('id, name, external_id, province_id, provider_name')
          .eq('province_id', provinceId)
          .eq('provider_name', 'alwaseet')
          .order('name');

      final cities = response.map((city) => {
        'id': city['id']?.toString() ?? '',
        'name': city['name']?.toString() ?? '',
        'external_id': city['external_id']?.toString() ?? '',
        'province_id': city['province_id']?.toString() ?? '',
      }).toList();

      // تحديث البيانات فوراً
      if (mounted) {
        setState(() {
          _cities = cities;
          _filteredCities = cities; // تحديث القائمة المفلترة أيضاً
          _isLoadingCities = false;
        });
      }

      debugPrint('✅ تم جلب ${cities.length} مدينة للمحافظة $provinceId مباشرة من قاعدة البيانات');
    } catch (e) {
      debugPrint('❌ خطأ في جلب المدن: $e');
      if (mounted) {
        setState(() {
          _isLoadingCities = false;
          _cities = [];
          _filteredCities = [];
        });
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
          final provinceName1 =
              province['city_name']?.toString().toLowerCase() ?? '';
          final provinceName2 =
              province['name']?.toString().toLowerCase() ?? '';
          final provinceName3 =
              province['province_name']?.toString().toLowerCase() ?? '';
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

          return cityName1.contains(searchQuery) ||
              cityName2.contains(searchQuery) ||
              cityName3.contains(searchQuery);
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
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _titleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // تم إزالة تعيين _glowAnimation غير المستخدم

    // تم إزالة تعيين _titleAnimation غير المستخدم

    _titleController.forward();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _titleController.dispose();
    _nameController.dispose();
    _primaryPhoneController.dispose();
    _secondaryPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color.fromRGBO(26, 26, 46, 0.95),
              Color.fromRGBO(22, 33, 62, 0.9),
              Color.fromRGBO(15, 15, 35, 0.95),
            ],
          ),
        ),
        child: PullToRefreshWrapper(
          onRefresh: _refreshData,
          refreshMessage: 'تم تحديث بيانات المحافظات',
          child: Column(
            children: [
              // الشريط العلوي الموحد
              CommonHeader(
                title: 'معلومات الزبون',
                rightActions: [
                  // زر الرجوع على اليمين
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFffd700).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFffd700).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        FontAwesomeIcons.arrowRight,
                        color: Color(0xFFffd700),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(child: _buildForm()),
            ],
          ),
        ),
      ),
    );
  }

  // 📝 نموذج المعلومات
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: 100, // مساحة للشريط السفلي
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomerNameField(),
            const SizedBox(height: 20),
            _buildPhoneFields(),
            const SizedBox(height: 20),
            _buildLocationFields(),
            const SizedBox(height: 20),
            _buildNotesField(),
            const SizedBox(height: 30),
            _buildSubmitButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 👤 حقل اسم الزبون
  Widget _buildCustomerNameField() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(
          color: const Color(0xFFe6b31e).withValues(alpha: 0.1),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFffd700),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'اسم الزبون',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFffd700),
                ),
              ),
              const SizedBox(width: 5),
              const Icon(Icons.diamond, color: Color(0xFFffd700), size: 12),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            textAlign: TextAlign.right, // محاذاة النص لليمين لدعم العربية
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFf0f0f0),
            ),
            onChanged: (value) {
              setState(() {}); // ✅ تحديث الواجهة عند تغيير النص
            },
            decoration: InputDecoration(
              hintText: 'أدخل اسم الزبون',
              hintStyle: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              prefixIcon: const Icon(
                Icons.person,
                color: Color(0xFFffd700),
                size: 20,
              ),
              // ✅ علامة الصح عند كتابة اسم صحيح
              suffixIcon: _nameController.text.trim().isNotEmpty
                  ? const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    )
                  : null,
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  // ✅ تغيير لون الإطار حسب وجود النص
                  color: _nameController.text.trim().isNotEmpty
                      ? Colors.green
                      : const Color(0xFFffd700).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  // ✅ تغيير لون الإطار حسب وجود النص
                  color: _nameController.text.trim().isNotEmpty
                      ? Colors.green
                      : const Color(0xFFffd700).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  // ✅ تغيير لون الإطار حسب وجود النص
                  color: _nameController.text.trim().isNotEmpty
                      ? Colors.green
                      : const Color(0xFFffd700),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 18,
              ),
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
    );
  }

  // 📱 حقول أرقام الهواتف
  Widget _buildPhoneFields() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(
          color: const Color(0xFFe6b31e).withValues(alpha: 0.1),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رقم الهاتف الأساسي
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'رقم الهاتف *',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _primaryPhoneController,
                keyboardType: TextInputType.phone,
                maxLength: 11, // ✅ حد أقصى 11 رقم
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFf0f0f0),
                ),
                onChanged: (value) {
                  // ✨ تحويل الأرقام العربية إلى إنجليزية تلقائياً
                  final convertedValue = _convertArabicToEnglishNumbers(value);
                  if (convertedValue != value) {
                    _primaryPhoneController.value = TextEditingValue(
                      text: convertedValue,
                      selection: TextSelection.collapsed(
                        offset: convertedValue.length,
                      ),
                    );
                  }
                  setState(() {}); // ✅ تحديث الواجهة عند تغيير النص
                },
                decoration: InputDecoration(
                  hintText: '07xxxxxxxxx',
                  hintStyle: GoogleFonts.cairo(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  prefixIcon: const Icon(
                    Icons.phone,
                    color: Color(0xFFffd700),
                    size: 20,
                  ),
                  // ✅ علامة الصح عند كتابة 11 رقم صحيح
                  suffixIcon:
                      _primaryPhoneController.text.length == 11 &&
                          _primaryPhoneController.text.startsWith('07')
                      ? const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      // ✅ تغيير لون الإطار حسب صحة الرقم
                      color:
                          _primaryPhoneController.text.length == 11 &&
                              _primaryPhoneController.text.startsWith('07')
                          ? Colors.green
                          : const Color(0xFFffd700).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      // ✅ تغيير لون الإطار حسب صحة الرقم
                      color:
                          _primaryPhoneController.text.length == 11 &&
                              _primaryPhoneController.text.startsWith('07')
                          ? Colors.green
                          : const Color(0xFFffd700).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      // ✅ تغيير لون الإطار حسب صحة الرقم
                      color:
                          _primaryPhoneController.text.length == 11 &&
                              _primaryPhoneController.text.startsWith('07')
                          ? Colors.green
                          : const Color(0xFFffd700),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 18,
                  ),
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
              Text(
                'رقم بديل',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _secondaryPhoneController,
                keyboardType: TextInputType.phone,
                maxLength: 11, // ✅ حد أقصى 11 رقم
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFf0f0f0),
                ),
                onChanged: (value) {
                  // ✨ تحويل الأرقام العربية إلى إنجليزية تلقائياً
                  final convertedValue = _convertArabicToEnglishNumbers(value);
                  if (convertedValue != value) {
                    _secondaryPhoneController.value = TextEditingValue(
                      text: convertedValue,
                      selection: TextSelection.collapsed(
                        offset: convertedValue.length,
                      ),
                    );
                  }
                  setState(() {}); // ✅ تحديث الواجهة عند تغيير النص
                },
                decoration: InputDecoration(
                  hintText: '07xxxxxxxxx (اختياري)',
                  hintStyle: GoogleFonts.cairo(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  prefixIcon: const Icon(
                    Icons.phone,
                    color: Color(0xFFffd700),
                    size: 20,
                  ),
                  // ✅ علامة الصح عند كتابة 11 رقم صحيح (اختياري)
                  suffixIcon:
                      _secondaryPhoneController.text.isNotEmpty &&
                          _secondaryPhoneController.text.length == 11 &&
                          _secondaryPhoneController.text.startsWith('07')
                      ? const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      // ✅ تغيير لون الإطار حسب صحة الرقم
                      color:
                          _secondaryPhoneController.text.isNotEmpty &&
                              _secondaryPhoneController.text.length == 11 &&
                              _secondaryPhoneController.text.startsWith('07')
                          ? Colors.green
                          : const Color(0xFFffd700).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      // ✅ تغيير لون الإطار حسب صحة الرقم
                      color:
                          _secondaryPhoneController.text.isNotEmpty &&
                              _secondaryPhoneController.text.length == 11 &&
                              _secondaryPhoneController.text.startsWith('07')
                          ? Colors.green
                          : const Color(0xFFffd700).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      // ✅ تغيير لون الإطار حسب صحة الرقم
                      color:
                          _secondaryPhoneController.text.isNotEmpty &&
                              _secondaryPhoneController.text.length == 11 &&
                              _secondaryPhoneController.text.startsWith('07')
                          ? Colors.green
                          : const Color(0xFFffd700),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 18,
                  ),
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
    );
  }

  // 🌍 حقول الموقع
  Widget _buildLocationFields() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(
          color: const Color(0xFFe6b31e).withValues(alpha: 0.1),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(15),
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
    );
  }

  // 🏛️ حقل المحافظة
  Widget _buildProvinceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFffd700),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'المحافظة',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFffd700),
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
              color: Colors.black.withValues(alpha: 0.2),
              border: Border.all(
                color: const Color(0xFFffd700).withValues(alpha: 0.3),
                width: 1,
              ),
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
                          ? const Color(0xFFf0f0f0)
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const Icon(
                  FontAwesomeIcons.chevronDown,
                  color: Color(0xFFffd700),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 🏙️ حقل المدينة
  Widget _buildCityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFffd700),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'المدينة',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFffd700),
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
              color: Colors.black.withValues(alpha: 0.2),
              border: Border.all(
                color: const Color(0xFFffd700).withValues(alpha: 0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedCity ??
                        (_selectedProvince != null
                            ? 'اختر المدينة أولاً'
                            : 'اختر المحافظة أولاً'),
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _selectedCity != null
                          ? const Color(0xFFf0f0f0)
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                Icon(
                  FontAwesomeIcons.chevronDown,
                  color: _selectedProvince != null
                      ? const Color(0xFFffd700)
                      : Colors.white.withValues(alpha: 0.3),
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
    // تهيئة القائمة المفلترة
    _filteredProvinces = _provinces;
    _provinceSearchController.clear();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // العنوان
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFffd700),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'المحافظة',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFffd700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // شريط البحث
                  TextField(
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFf0f0f0),
                    ),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن المحافظة...',
                      hintStyle: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      prefixIcon: const Icon(
                        FontAwesomeIcons.magnifyingGlass,
                        color: Color(0xFFffd700),
                        size: 16,
                      ),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(
                          color: const Color(0xFFffd700).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(
                          color: const Color(0xFFffd700).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(
                          color: Color(0xFFffd700),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                    controller: _provinceSearchController,
                    onChanged: (value) {
                      _filterProvinces(value, setModalState);
                    },
                  ),

                  const SizedBox(height: 20),

                  // قائمة المحافظات من شركة الوسيط
                  if (_isLoadingCities)
                    const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFffd700),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredProvinces.length,
                        itemBuilder: (context, index) {
                          final province = _filteredProvinces[index];
                          final provinceName =
                              province['city_name'] ?? province['name'] ?? '';
                          final provinceId = province['id'] ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                provinceName,
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFf0f0f0),
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedProvince = provinceName;
                                  _selectedProvinceId =
                                      provinceId; // ✅ حفظ معرف المحافظة
                                  _selectedCity = null; // إعادة تعيين المدينة
                                  _selectedCityId = null;
                                  _selectedRegionId = null;
                                });
                                Navigator.pop(context);
                                // جلب المدن للمحافظة المختارة فقط (بدون فتح قائمة المدن)
                                _loadCitiesForProvince(provinceId);
                              },
                              tileColor: _selectedProvince == provinceName
                                  ? const Color(
                                      0xFFffd700,
                                    ).withValues(alpha: 0.1)
                                  : null,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: _selectedProvince == provinceName
                                      ? const Color(0xFFffd700)
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
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
    if (_selectedProvince == null) return;

    // تهيئة القائمة المفلترة
    _filteredCities = _cities;
    _citySearchController.clear();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // العنوان
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFffd700),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'المدينة',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFffd700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // شريط البحث
                  TextField(
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFf0f0f0),
                    ),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن المدينة...',
                      hintStyle: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      prefixIcon: const Icon(
                        FontAwesomeIcons.magnifyingGlass,
                        color: Color(0xFFffd700),
                        size: 16,
                      ),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(
                          color: const Color(0xFFffd700).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(
                          color: const Color(0xFFffd700).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(
                          color: Color(0xFFffd700),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                    controller: _citySearchController,
                    onChanged: (value) {
                      _filterCities(value, setModalState);
                    },
                  ),

                  const SizedBox(height: 20),

                  // قائمة المدن من شركة الوسيط
                  if (_isLoadingCities)
                    const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFffd700),
                      ),
                    )
                  else if (_cities.isEmpty)
                    Center(
                      child: Text(
                        'يرجى اختيار المحافظة أولاً',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredCities.length,
                        itemBuilder: (context, index) {
                          final city = _filteredCities[index];
                          final cityName =
                              city['region_name'] ?? city['name'] ?? '';
                          final cityId = city['id'] ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                cityName,
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFf0f0f0),
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedCity = cityName;
                                  _selectedCityId = cityId;
                                });
                                Navigator.pop(context);
                              },
                              tileColor: _selectedCity == cityName
                                  ? const Color(
                                      0xFFffd700,
                                    ).withValues(alpha: 0.1)
                                  : null,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: _selectedCity == cityName
                                      ? const Color(0xFFffd700)
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(
          color: const Color(0xFFe6b31e).withValues(alpha: 0.1),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFffd700),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'الملاحظات',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFffd700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            textAlign: TextAlign.right, // محاذاة النص لليمين لدعم العربية
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFf0f0f0),
            ),
            decoration: InputDecoration(
              hintText:
                  'لون المنتج، تفاصيل الموقع، نوع الهدية، أو أي ملاحظات أخرى...',
              hintStyle: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: const Color(0xFFffd700).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: const Color(0xFFffd700).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFFffd700),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 20,
              ),
            ),
            readOnly: false,
          ),
        ],
      ),
    );
  }

  // ✅ زر الإرسال
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFffd700),
          foregroundColor: Colors.black,
          elevation: 8,
          shadowColor: const Color(0xFFffd700).withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: _isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'جاري الإرسال...',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(FontAwesomeIcons.paperPlane, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'ملخص الطلب',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
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
        content: Text(
          message,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // التمرير للحقل المطلوب
    if (targetWidget != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
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
    if (_selectedProvince == null ||
        _selectedCityId == null ||
        _selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يرجى اختيار المحافظة والمدينة',
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
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFFdc3545),
            duration: const Duration(seconds: 5),
            action: locationValidation.suggestion != null
                ? SnackBarAction(
                    label: 'تحديث البيانات',
                    textColor: const Color(0xFFffd700),
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
      debugPrint('   المحافظة: "${locationValidation.provinceName}" (external_id: ${locationValidation.provinceExternalId})');
      debugPrint('   المدينة: "${locationValidation.cityName}" (external_id: ${locationValidation.cityExternalId})');

    } catch (e) {
      debugPrint('❌ خطأ في التحقق من صحة بيانات الموقع: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ في التحقق من بيانات الموقع. يرجى المحاولة مرة أخرى.',
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

        if (item is CartItem) {
          // إذا كان العنصر من نوع CartItem (للطلبات المجدولة)
          customerPrice = item.customerPrice.toDouble();
          wholesalePrice = item.wholesalePrice.toDouble();
          quantity = item.quantity;
          name = item.name;
          image = item.image;
          id = item.id;
          productId = item.productId;
        } else {
          // إذا كان العنصر من نوع Map (للطلبات العادية)
          customerPrice = (item['customerPrice'] ?? 0.0).toDouble();
          wholesalePrice = (item['wholesalePrice'] ?? 0.0).toDouble();
          quantity = (item['quantity'] ?? 1).toInt();
          name = item['name'] ?? 'منتج';
          image = item['image'] ?? '';
          id =
              item['id']?.toString() ??
              'PRODUCT_${DateTime.now().millisecondsSinceEpoch}';
          productId = item['productId']?.toString() ?? '';
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
        'primaryPhone': _primaryPhoneController.text
            .trim(), // ✅ رقم العميل الذي كتبه المستخدم
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
        // مسح السلة
        _cartService.clearCart();

        // الانتقال إلى صفحة ملخص الطلب
        context.go('/order-summary', extra: orderData);
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
