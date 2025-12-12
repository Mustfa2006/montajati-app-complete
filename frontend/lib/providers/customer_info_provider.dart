/// 🧑‍💼 مزود بيانات صفحة معلومات العميل
/// CustomerInfoProvider - Single Source of Truth
///
/// يحتوي على كل:
/// - Controllers
/// - State
/// - Loading Logic
/// - Filter Logic
/// - Validation Logic
/// - Business Rules
///
/// ❌ لا UI logic (لا SnackBar, لا Dialog, لا Navigator)
library;

import 'package:flutter/material.dart';
import '../models/province.dart';
import '../models/city.dart';
import '../models/order_draft.dart';
import '../services/location_api_service.dart';

class CustomerInfoProvider extends ChangeNotifier {
  // ═══════════════════════════════════════════════════
  // 📝 TEXT CONTROLLERS
  // ═══════════════════════════════════════════════════
  final TextEditingController nameController = TextEditingController();
  final TextEditingController primaryPhoneController = TextEditingController();
  final TextEditingController secondaryPhoneController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController provinceSearchController = TextEditingController();
  final TextEditingController citySearchController = TextEditingController();

  // ═══════════════════════════════════════════════════
  // 📍 LOCATION STATE - Typed Lists
  // ═══════════════════════════════════════════════════
  List<Province> _provinces = [];
  List<Province> _filteredProvinces = [];
  List<City> _cities = [];
  List<City> _filteredCities = [];

  // ✅ Selected as Objects (not just IDs)
  Province? _selectedProvince;
  City? _selectedCity;
  String? _selectedRegionId;

  // ═══════════════════════════════════════════════════
  // 🔄 LOADING / ERROR STATE
  // ═══════════════════════════════════════════════════
  bool _isSubmitting = false;
  bool _isLoadingCities = false;
  bool _isLoadingProvinces = false;
  bool _hasProvincesError = false;
  bool _hasCitiesError = false;
  int _provincesRetryCount = 0;
  int _citiesRetryCount = 0;
  final int _maxRetries = 5;

  // ✅ متغير لتحديث الـ Modal عند جلب البيانات
  VoidCallback? cityModalUpdater;

  // ═══════════════════════════════════════════════════
  // 📖 GETTERS
  // ═══════════════════════════════════════════════════
  List<Province> get provinces => _provinces;
  List<Province> get filteredProvinces => _filteredProvinces;
  List<City> get cities => _cities;
  List<City> get filteredCities => _filteredCities;

  Province? get selectedProvince => _selectedProvince;
  City? get selectedCity => _selectedCity;
  String? get selectedRegionId => _selectedRegionId;

  // للتوافق مع الكود القديم
  String? get selectedProvinceName => _selectedProvince?.name;
  String? get selectedProvinceId => _selectedProvince?.id;
  String? get selectedCityName => _selectedCity?.name;
  String? get selectedCityId => _selectedCity?.id;

  bool get isSubmitting => _isSubmitting;
  bool get isLoadingCities => _isLoadingCities;
  bool get isLoadingProvinces => _isLoadingProvinces;
  bool get hasProvincesError => _hasProvincesError;
  bool get hasCitiesError => _hasCitiesError;
  int get provincesRetryCount => _provincesRetryCount;
  int get citiesRetryCount => _citiesRetryCount;
  int get maxRetries => _maxRetries;

  // ═══════════════════════════════════════════════════
  // ✅ VALIDATION GETTERS
  // ═══════════════════════════════════════════════════
  bool get isFormComplete =>
      nameController.text.trim().isNotEmpty &&
      primaryPhoneController.text.length == 11 &&
      primaryPhoneController.text.startsWith('07') &&
      _selectedProvince != null &&
      _selectedCity != null;

  // ═══════════════════════════════════════════════════
  // 🔧 SETTERS
  // ═══════════════════════════════════════════════════
  set isSubmitting(bool value) {
    _isSubmitting = value;
    notifyListeners();
  }

  /// ✅ دالة عامة للـ Widgets لتنبيه Provider بتغيير الحقول
  /// Widgets call this instead of notifyListeners() directly
  void notifyFieldChanged() {
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════
  // 🔄 LOADING METHODS - نقل حرفي من customer_info_page.dart
  // ═══════════════════════════════════════════════════

  /// تحديث البيانات عند السحب للأسفل
  Future<void> refreshData() async {
    debugPrint('🔄 تحديث بيانات صفحة معلومات الزبون...');
    await loadProvinces();
    debugPrint('✅ تم تحديث بيانات صفحة معلومات الزبون');
  }

  /// 🔄 جلب المحافظات مع نظام Retry ذكي - عبر API
  Future<void> loadProvinces({bool isRetry = false}) async {
    // إعادة تعيين عداد المحاولات إذا لم يكن retry
    if (!isRetry) {
      _provincesRetryCount = 0;
    }

    _isLoadingProvinces = true;
    _isLoadingCities = true;
    _hasProvincesError = false;
    notifyListeners();

    debugPrint('🏛️ جلب المحافظات عبر API... المحاولة ${_provincesRetryCount + 1}/$_maxRetries');

    try {
      // ✅ استخدام LocationApiService - يرجع List<Province> مباشرة
      final provincesData = await LocationApiService.getProvinces();

      _provinces = provincesData;
      _filteredProvinces = provincesData;
      _isLoadingProvinces = false;
      _isLoadingCities = false;
      _hasProvincesError = false;
      _provincesRetryCount = 0;
      notifyListeners();

      debugPrint('✅ تم جلب ${provincesData.length} محافظة عبر API');
    } catch (e) {
      debugPrint('❌ خطأ في جلب المحافظات: $e (المحاولة ${_provincesRetryCount + 1})');

      _provincesRetryCount++;

      if (_provincesRetryCount < _maxRetries) {
        _hasProvincesError = false;
        notifyListeners();

        final delay = Duration(seconds: _provincesRetryCount * 2);
        debugPrint('🔄 إعادة المحاولة بعد ${delay.inSeconds} ثواني...');

        await Future.delayed(delay);
        loadProvinces(isRetry: true);
      } else {
        _isLoadingProvinces = false;
        _isLoadingCities = false;
        _hasProvincesError = true;
        _provinces = [];
        notifyListeners();
      }
    }
  }

  /// 🔄 جلب المدن لمحافظة محددة مع نظام Retry ذكي - عبر API
  Future<void> loadCitiesForProvince(String provinceId, {bool isRetry = false, VoidCallback? onComplete}) async {
    if (!isRetry) {
      _citiesRetryCount = 0;
    }

    _isLoadingCities = true;
    _hasCitiesError = false;
    if (!isRetry) {
      _cities = [];
      _filteredCities = [];
    }
    notifyListeners();

    debugPrint('🏙️ جلب المدن للمحافظة $provinceId عبر API... المحاولة ${_citiesRetryCount + 1}/$_maxRetries');

    try {
      // ✅ استخدام LocationApiService - يرجع List<City> مباشرة
      final citiesData = await LocationApiService.getCities(provinceId);

      _cities = citiesData;
      _filteredCities = citiesData;
      _isLoadingCities = false;
      _hasCitiesError = false;
      _citiesRetryCount = 0;
      notifyListeners();

      // ✅ استدعاء callback لتحديث الـ Modal
      onComplete?.call();
      cityModalUpdater?.call();

      debugPrint('✅ تم جلب ${citiesData.length} مدينة عبر API');
    } catch (e) {
      debugPrint('❌ خطأ في جلب المدن: $e (المحاولة ${_citiesRetryCount + 1})');

      _citiesRetryCount++;

      if (_citiesRetryCount < _maxRetries) {
        _hasCitiesError = false;
        notifyListeners();

        final delay = Duration(seconds: _citiesRetryCount * 2);
        debugPrint('🔄 إعادة محاولة جلب المدن بعد ${delay.inSeconds} ثواني...');

        await Future.delayed(delay);
        loadCitiesForProvince(provinceId, isRetry: true, onComplete: onComplete);
      } else {
        _isLoadingCities = false;
        _hasCitiesError = true;
        _cities = [];
        _filteredCities = [];
        notifyListeners();
        onComplete?.call();
      }
    }
  }

  // ═══════════════════════════════════════════════════
  // 🔍 FILTER METHODS - نقل حرفي
  // ═══════════════════════════════════════════════════

  /// دالة البحث في المحافظات
  void filterProvinces(String query) {
    if (query.isEmpty) {
      _filteredProvinces = _provinces;
    } else {
      final searchQuery = query.toLowerCase();
      _filteredProvinces = _provinces.where((province) {
        // ✅ البحث في بداية اسم المحافظة (exact prefix matching)
        return province.name.toLowerCase().startsWith(searchQuery);
      }).toList();
    }
    notifyListeners();
  }

  /// دالة البحث في المدن
  void filterCities(String query) {
    if (query.isEmpty) {
      _filteredCities = _cities;
    } else {
      final searchQuery = query.toLowerCase();
      _filteredCities = _cities.where((city) {
        // ✅ البحث في اسم المدينة
        return city.name.toLowerCase().contains(searchQuery);
      }).toList();
    }
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════
  // 🎯 SELECTION METHODS
  // ═══════════════════════════════════════════════════

  void selectProvince(Province province) {
    _selectedProvince = province;
    // إعادة تعيين المدينة عند تغيير المحافظة
    _selectedCity = null;
    _selectedRegionId = null;
    _cities = [];
    _filteredCities = [];
    citySearchController.clear();
    notifyListeners();
  }

  void selectCity(City city, {String? regionId}) {
    _selectedCity = city;
    _selectedRegionId = regionId;
    notifyListeners();
  }

  void clearProvince() {
    _selectedProvince = null;
    _selectedCity = null;
    _selectedRegionId = null;
    _cities = [];
    _filteredCities = [];
    provinceSearchController.clear();
    citySearchController.clear();
    notifyListeners();
  }

  void clearCity() {
    _selectedCity = null;
    _selectedRegionId = null;
    citySearchController.clear();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════
  // ✅ VALIDATION METHODS - نقل حرفي
  // ═══════════════════════════════════════════════════

  /// التحقق من الحقول المطلوبة - يرجع نوع الحقل الناقص أو null
  String? validateRequiredFields() {
    if (nameController.text.trim().isEmpty) {
      return 'name';
    }
    if (primaryPhoneController.text.trim().isEmpty) {
      return 'phone';
    }
    if (_selectedProvince == null) {
      return 'province';
    }
    if (_selectedCity == null) {
      return 'city';
    }
    return null; // جميع الحقول مملوءة
  }

  /// الحصول على رسالة الخطأ بناءً على نوع الحقل
  String? getErrorMessage(String? fieldType) {
    if (fieldType == null) return null;

    switch (fieldType) {
      case 'name':
        return 'يرجى إدخال اسم الزبون';
      case 'phone':
        return 'يرجى إدخال رقم الهاتف الأساسي';
      case 'province':
        return 'يرجى اختيار المحافظة';
      case 'city':
        return 'يرجى اختيار المدينة';
      default:
        return null;
    }
  }

  // ═══════════════════════════════════════════════════
  // 🔢 UTILITY METHODS - نقل حرفي
  // ═══════════════════════════════════════════════════

  /// تحويل الأرقام العربية إلى إنجليزية
  String convertArabicToEnglishNumbers(String input) {
    const arabicNumbers = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const englishNumbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

    String result = input;
    for (int i = 0; i < arabicNumbers.length; i++) {
      result = result.replaceAll(arabicNumbers[i], englishNumbers[i]);
    }
    return result;
  }

  // ═══════════════════════════════════════════════════
  // 📦 ORDER DRAFT BUILDER
  // ═══════════════════════════════════════════════════

  /// بناء مسودة الطلب من البيانات الحالية
  OrderDraft? buildOrderDraft({DateTime? scheduledDate, String? scheduleNotes}) {
    if (_selectedProvince == null || _selectedCity == null) {
      return null;
    }

    return OrderDraft(
      customerName: nameController.text.trim(),
      primaryPhone: primaryPhoneController.text.trim(),
      secondaryPhone: secondaryPhoneController.text.trim().isEmpty ? null : secondaryPhoneController.text.trim(),
      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      province: _selectedProvince!,
      city: _selectedCity!,
      regionId: _selectedRegionId,
      scheduledDate: scheduledDate,
      scheduleNotes: scheduleNotes,
    );
  }

  // ═══════════════════════════════════════════════════
  // 🧹 CLEANUP
  // ═══════════════════════════════════════════════════

  void reset() {
    nameController.clear();
    primaryPhoneController.clear();
    secondaryPhoneController.clear();
    notesController.clear();
    provinceSearchController.clear();
    citySearchController.clear();

    _selectedProvince = null;
    _selectedCity = null;
    _selectedRegionId = null;

    _provinces = [];
    _cities = [];
    _filteredProvinces = [];
    _filteredCities = [];

    _isSubmitting = false;
    _isLoadingCities = false;
    _isLoadingProvinces = false;
    _hasProvincesError = false;
    _hasCitiesError = false;
    _provincesRetryCount = 0;
    _citiesRetryCount = 0;

    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    primaryPhoneController.dispose();
    secondaryPhoneController.dispose();
    notesController.dispose();
    provinceSearchController.dispose();
    citySearchController.dispose();
    super.dispose();
  }
}
