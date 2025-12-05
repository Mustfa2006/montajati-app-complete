import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_background.dart';
import '../widgets/iraq_map_widget.dart';

// ⏰ دوال ثابتة لتوحيد منطق التوقيت (بغداد = UTC+3)
class _TimeHelper {
  static const Duration baghdadOffset = Duration(hours: 3);

  /// تحويل من UTC إلى توقيت بغداد
  static DateTime toBaghdad(DateTime utc) => utc.add(baghdadOffset);

  /// تحويل من توقيت بغداد إلى UTC
  static DateTime toUtc(DateTime baghdad) => baghdad.subtract(baghdadOffset);

  /// الوقت الحالي بتوقيت بغداد
  static DateTime nowBaghdad() => toBaghdad(DateTime.now().toUtc());

  /// بداية اليوم (00:00:00) بتوقيت بغداد ثم تحويل إلى UTC
  static DateTime startOfDayUtc(DateTime baghdadDate) {
    final startBaghdad = DateTime(baghdadDate.year, baghdadDate.month, baghdadDate.day, 0, 0, 0);
    return toUtc(startBaghdad);
  }

  /// نهاية اليوم (23:59:59) بتوقيت بغداد ثم تحويل إلى UTC
  static DateTime endOfDayUtc(DateTime baghdadDate) {
    final endBaghdad = DateTime(baghdadDate.year, baghdadDate.month, baghdadDate.day, 23, 59, 59);
    return toUtc(endBaghdad);
  }

  /// حساب بداية الأسبوع (السبت) بتوقيت بغداد
  static DateTime startOfWeekBaghdad(DateTime baghdadDate, {int weekOffset = 0}) {
    final currentWeekday = baghdadDate.weekday;

    int daysToSubtract;
    if (currentWeekday == DateTime.saturday) {
      daysToSubtract = 0;
    } else if (currentWeekday == DateTime.sunday) {
      daysToSubtract = 1;
    } else {
      daysToSubtract = currentWeekday + 1;
    }

    return DateTime(
      baghdadDate.year,
      baghdadDate.month,
      baghdadDate.day,
      0,
      0,
      0,
      0,
      0,
    ).subtract(Duration(days: daysToSubtract)).add(Duration(days: weekOffset * 7));
  }

  /// حساب نهاية الأسبوع (الجمعة 23:59:59) بتوقيت بغداد
  static DateTime endOfWeekBaghdad(DateTime weekStartBaghdad) {
    return weekStartBaghdad.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
  }
}

class StatisticsPage extends StatefulWidget {
  final bool isInsideTabView;
  final int? currentTabIndex;
  final Function(int)? onTabChanged;

  const StatisticsPage({super.key, this.isInsideTabView = false, this.currentTabIndex, this.onTabChanged});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  // 💾 تخزين GeoJSON في متغير static لتحميله مرة واحدة فقط
  static Map<String, dynamic>? _cachedGeoJsonData;

  // بيانات الأرباح
  double _realizedProfits = 0.0;

  // متغيرات اختيار التاريخ
  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;

  // بيانات GeoJSON
  Map<String, dynamic>? _geoJsonData;
  bool _isLoadingMap = true;

  // بيانات الطلبات حسب المحافظة
  final Map<String, int> _provinceOrders = {};

  // المحافظة المختارة
  String? _selectedProvince;

  // بيانات الطلبات حسب أيام الأسبوع
  final Map<String, int> _weekdayOrders = {
    'السبت': 0,
    'الأحد': 0,
    'الاثنين': 0,
    'الثلاثاء': 0,
    'الأربعاء': 0,
    'الخميس': 0,
    'الجمعة': 0,
  };

  // متغير لتتبع الأسبوع الحالي (0 = هذا الأسبوع، -1 = الأسبوع الماضي، إلخ)
  int _weekOffset = 0;

  // 🚀 نظام Cache للبيانات (تحسين الأداء)
  Map<String, dynamic>? _cachedData;
  DateTime? _cacheTimestamp;
  static const Duration _cacheDuration = Duration(minutes: 5); // مدة صلاحية الكاش

  // 🚀 نظام Debounce للحماية من التكرار
  DateTime? _lastRequestTime;
  static const Duration _debounceDuration = Duration(milliseconds: 500);
  bool _isLoading = false; // لمنع الطلبات المتعددة
  bool _isLoadingProfits = false; // مؤشر تحميل منفصل للأرباح المحققة
  bool _profitsLoaded = false; // لتتبع ما إذا تم تحميل الأرباح مسبقاً

  // دالة مساعدة لتحويل رقم اليوم إلى اسم عربي
  String _getArabicDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'الاثنين';
      case DateTime.tuesday:
        return 'الثلاثاء';
      case DateTime.wednesday:
        return 'الأربعاء';
      case DateTime.thursday:
        return 'الخميس';
      case DateTime.friday:
        return 'الجمعة';
      case DateTime.saturday:
        return 'السبت';
      case DateTime.sunday:
        return 'الأحد';
      default:
        return 'غير معروف';
    }
  }

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    // 🚀 تفعيل مؤشر تحميل الأرباح
    setState(() => _isLoadingProfits = true);

    // 🚀 SWR Pattern: عرض البيانات المخزنة فوراً ثم تحديثها
    await _loadCachedStatistics(); // عرض فوري
    await _loadGeoJsonData();
    await _setDefaultDateRange();
    // 🚀 استخدام الدالة الموحدة الجديدة بدلاً من 3 دوال منفصلة
    await _loadAllStatistics(); // تحديث من الخادم
  }

  // � تحميل البيانات المخزنة محلياً (SWR Pattern)
  Future<void> _loadCachedStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedProfits = prefs.getDouble('cached_realized_profits');

      if (cachedProfits != null && mounted) {
        setState(() {
          _realizedProfits = cachedProfits;
        });
        debugPrint('✅ تم تحميل الأرباح من الكاش المحلي: $cachedProfits');
      }
    } catch (e) {
      debugPrint('⚠️ خطأ في تحميل الكاش المحلي: $e');
    }
  }

  // 💾 حفظ البيانات محلياً
  Future<void> _saveCachedStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('cached_realized_profits', _realizedProfits);
      debugPrint('💾 تم حفظ الأرباح في الكاش المحلي: $_realizedProfits');
    } catch (e) {
      debugPrint('⚠️ خطأ في حفظ الكاش المحلي: $e');
    }
  }

  // �💾 تحميل بيانات GeoJSON (مع تخزين مؤقت)
  Future<void> _loadGeoJsonData() async {
    try {
      // 🚀 استخدام الكاش إذا كان موجوداً
      if (_cachedGeoJsonData != null) {
        debugPrint('✅ استخدام GeoJSON من الكاش');
        if (mounted) {
          setState(() {
            _geoJsonData = _cachedGeoJsonData;
            _isLoadingMap = false;
          });
        }
        return;
      }

      // 📥 تحميل من الملف إذا لم يكن في الكاش
      debugPrint('📥 تحميل GeoJSON من الملف...');
      final String jsonString = await rootBundle.loadString('assets/data/iraq_Governorate_level_1.geojson');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      // طباعة أسماء المحافظات في GeoJSON للتحقق
      debugPrint('🗺️ === أسماء المحافظات في GeoJSON ===');
      final features = jsonData['features'] as List;
      for (var feature in features) {
        final properties = feature['properties'];
        final shapeName = properties['shapeName'] ?? properties['name'] ?? '';
        if (shapeName.isNotEmpty) {
          debugPrint('   - $shapeName');
        }
      }

      // 💾 حفظ في الكاش
      _cachedGeoJsonData = jsonData;

      if (mounted) {
        setState(() {
          _geoJsonData = jsonData;
          _isLoadingMap = false;
        });
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل بيانات الخريطة: $e');
      if (mounted) {
        setState(() {
          _isLoadingMap = false;
        });
      }
    }
  }

  // تعيين نطاق التاريخ الافتراضي (آخر 7 أيام حسب توقيت بغداد)
  Future<void> _setDefaultDateRange() async {
    // 🚀 استخدام _TimeHelper لتوحيد منطق التوقيت
    final nowBaghdad = _TimeHelper.nowBaghdad();
    final sevenDaysAgo = nowBaghdad.subtract(const Duration(days: 7));

    if (mounted) {
      setState(() {
        _selectedFromDate = _TimeHelper.startOfDayUtc(sevenDaysAgo);
        _selectedToDate = _TimeHelper.endOfDayUtc(nowBaghdad);
      });
    }
  }

  // 🚀 جلب جميع الإحصائيات في طلب واحد (محسّن + Cache + Debounce)
  Future<void> _loadAllStatistics({bool forceRefresh = false}) async {
    try {
      // 🛡️ Debounce: منع الطلبات المتكررة
      final now = DateTime.now();
      if (_lastRequestTime != null && !forceRefresh) {
        final timeSinceLastRequest = now.difference(_lastRequestTime!);
        if (timeSinceLastRequest < _debounceDuration) {
          debugPrint('⏸️ تم تجاهل الطلب (Debounce): ${timeSinceLastRequest.inMilliseconds}ms منذ آخر طلب');
          return;
        }
      }

      // 🛡️ منع الطلبات المتعددة في نفس الوقت
      if (_isLoading && !forceRefresh) {
        debugPrint('⏸️ تم تجاهل الطلب: يوجد طلب قيد التنفيذ');
        return;
      }

      // 💾 Cache: استخدام البيانات المخزنة إذا كانت صالحة
      if (_cachedData != null && _cacheTimestamp != null && !forceRefresh) {
        final cacheAge = now.difference(_cacheTimestamp!);
        if (cacheAge < _cacheDuration) {
          debugPrint('✅ استخدام البيانات من الكاش (عمر الكاش: ${cacheAge.inSeconds}s)');
          _applyDataFromCache();
          return;
        } else {
          debugPrint('⏰ الكاش منتهي الصلاحية (عمر الكاش: ${cacheAge.inMinutes}m)');
        }
      }

      setState(() => _isLoading = true);
      _lastRequestTime = now;

      final prefs = await SharedPreferences.getInstance();
      String? currentUserPhone = prefs.getString('current_user_phone');

      if (currentUserPhone == null || currentUserPhone.isEmpty) {
        debugPrint('❌ رقم الهاتف غير موجود');
        setState(() => _isLoading = false);
        return;
      }

      if (_selectedFromDate == null || _selectedToDate == null) {
        debugPrint('❌ التواريخ غير محددة');
        setState(() => _isLoading = false);
        return;
      }

      // 🚀 حساب بداية ونهاية الأسبوع باستخدام _TimeHelper
      final nowBaghdad = _TimeHelper.nowBaghdad();
      final weekStartBaghdad = _TimeHelper.startOfWeekBaghdad(nowBaghdad, weekOffset: _weekOffset);
      final weekEndBaghdad = _TimeHelper.endOfWeekBaghdad(weekStartBaghdad);
      final weekStartUtc = _TimeHelper.toUtc(weekStartBaghdad);
      final weekEndUtc = _TimeHelper.toUtc(weekEndBaghdad);

      debugPrint('📊 === جلب ملخص الإحصائيات الموحد ===');
      debugPrint('📱 رقم الهاتف: $currentUserPhone');
      debugPrint('📅 الفترة: ${_selectedFromDate!.toIso8601String()} إلى ${_selectedToDate!.toIso8601String()}');
      debugPrint('📅 الأسبوع: ${weekStartUtc.toIso8601String()} إلى ${weekEndUtc.toIso8601String()}');

      // 🚀 طلب واحد موحد بدلاً من 3 طلبات منفصلة
      // TODO: 🔒 استخدام JWT بدلاً من إرسال phone من الفرونت اند (تحسين أمني)
      // يجب تعديل الباك اند ليستخرج phone من التوكن بدلاً من الطلب
      final response = await http
          .post(
            Uri.parse('${ApiConfig.usersUrl}/statistics/summary'),
            headers: ApiConfig.defaultHeaders,
            body: jsonEncode({
              'phone': currentUserPhone, // ⚠️ سيتم إزالته لاحقاً واستخدام JWT
              'from_date': _selectedFromDate!.toIso8601String(),
              'to_date': _selectedToDate!.toIso8601String(),
              'week_start': weekStartUtc.toIso8601String(),
              'week_end': weekEndUtc.toIso8601String(),
            }),
          )
          .timeout(ApiConfig.defaultTimeout);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final data = jsonData['data'];

          // 💾 حفظ البيانات في الكاش
          _cachedData = data;
          _cacheTimestamp = DateTime.now();

          // تطبيق البيانات
          _applyDataFromResponse(data);

          // 💾 حفظ في الكاش المحلي (SharedPreferences)
          _saveCachedStatistics();

          debugPrint('✅ تم جلب جميع الإحصائيات بنجاح');
          debugPrint('   💰 الأرباح: $_realizedProfits د.ع');
          debugPrint('   🗺️ المحافظات: ${_provinceOrders.length}');
          debugPrint('   📅 أيام الأسبوع: ${_weekdayOrders.values.reduce((a, b) => a + b)} طلب');
        }
      } else {
        debugPrint('❌ خطأ في جلب الإحصائيات: ${response.statusCode}');
        // 🚨 عرض رسالة خطأ للمستخدم
        _showErrorSnackBar('فشل في جلب البيانات (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب الإحصائيات: $e');
      // 🚨 عرض رسالة خطأ للمستخدم مع إعادة محاولة تلقائية
      _showErrorSnackBarWithRetry('خطأ في الاتصال بالإنترنت');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // تطبيق البيانات من الاستجابة
  void _applyDataFromResponse(Map<String, dynamic> data) {
    if (!mounted) return;

    setState(() {
      // 1️⃣ الأرباح المحققة (تُحمل مرة واحدة فقط)
      if (!_profitsLoaded) {
        _realizedProfits = (data['realized_profits'] as num?)?.toDouble() ?? 0.0;
        _profitsLoaded = true;
        _isLoadingProfits = false;
      }

      // 2️⃣ طلبات المحافظات
      _provinceOrders.clear();
      final provinceData = data['province_orders'];
      if (provinceData != null) {
        final Map<String, dynamic> rawProvinceCounts = provinceData['province_counts'] ?? {};
        rawProvinceCounts.forEach((province, count) {
          if (province.toString().trim().isNotEmpty) {
            final normalizedName = _normalizeProvinceName(province.toString().trim());
            _provinceOrders[normalizedName] = (count as num).toInt();
          }
        });
      }

      // 3️⃣ طلبات أيام الأسبوع
      _weekdayOrders.updateAll((key, value) => 0);
      final List<dynamic> weekdayOrdersData = data['weekday_orders'] ?? [];
      for (var item in weekdayOrdersData) {
        final dayOfWeek = item['day_of_week'] as int;
        final orderCount = item['order_count'] as int;

        String dayName;
        switch (dayOfWeek) {
          case 0:
            dayName = 'الأحد';
            break;
          case 1:
            dayName = 'الاثنين';
            break;
          case 2:
            dayName = 'الثلاثاء';
            break;
          case 3:
            dayName = 'الأربعاء';
            break;
          case 4:
            dayName = 'الخميس';
            break;
          case 5:
            dayName = 'الجمعة';
            break;
          case 6:
            dayName = 'السبت';
            break;
          default:
            dayName = 'غير معروف';
        }

        _weekdayOrders[dayName] = orderCount;
      }
    });
  }

  // تطبيق البيانات من الكاش
  void _applyDataFromCache() {
    if (_cachedData != null) {
      _applyDataFromResponse(_cachedData!);
    }
  }

  // 🚨 عرض رسالة خطأ مع إعادة محاولة تلقائية عند توفر الإنترنت
  void _showErrorSnackBarWithRetry(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'إعادة المحاولة',
          textColor: Colors.white,
          onPressed: () => _loadAllStatistics(forceRefresh: true),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );

    // 🔄 إعادة محاولة تلقائية بعد 3 ثواني
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _loadAllStatistics(forceRefresh: true);
      }
    });
  }

  // 🚨 عرض رسالة خطأ مع زر "إعادة المحاولة"
  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'إعادة المحاولة',
          textColor: Colors.white,
          onPressed: () => _loadAllStatistics(forceRefresh: true),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // 🌐 جلب أرباح المستخدم من الباك اند (آمن جداً)
  Future<void> _loadUserProfits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? currentUserPhone = prefs.getString('current_user_phone');

      if (currentUserPhone == null || currentUserPhone.isEmpty) {
        return;
      }

      debugPrint('📊 جلب الأرباح المحققة من الباك اند للمستخدم: $currentUserPhone');

      // 🌐 جلب الأرباح من الباك اند
      final response = await http
          .post(
            Uri.parse('${ApiConfig.usersUrl}/statistics/realized-profits'),
            headers: ApiConfig.defaultHeaders,
            body: jsonEncode({'phone': currentUserPhone}),
          )
          .timeout(ApiConfig.defaultTimeout);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final data = jsonData['data'];
          final realizedProfits = (data['realized_profits'] as num?)?.toDouble() ?? 0.0;

          if (mounted) {
            setState(() {
              _realizedProfits = realizedProfits;
            });

            debugPrint('✅ إجمالي الأرباح المحققة: $realizedProfits د.ع');
          }
        }
      } else {
        debugPrint('❌ خطأ في جلب الأرباح: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب الأرباح: $e');
    }
  }

  // تحويل اسم المحافظة من قاعدة البيانات إلى الاسم الموحد
  String _normalizeProvinceName(String dbProvinceName) {
    // خريطة تحويل شاملة من أسماء قاعدة البيانات إلى الأسماء الموحدة
    final Map<String, String> provinceMapping = {
      // المحافظات التي تحتوي على اسم المدينة + المحافظة
      'الحلة - بابل': 'بابل',
      'الديوانية - القادسية': 'القادسية',
      'السماوة - المثنى': 'المثنى',
      'العمارة - ميسان': 'ميسان',
      'الكوت - واسط': 'واسط',
      'الناصرية - ذي قار': 'ذي قار',

      // المحافظات بأسماء مختلفة
      'اربيل': 'أربيل',
      'الانبار': 'الأنبار',
      'نينوى': 'نينوى',

      // المحافظات الصحيحة (نفس الاسم)
      'بغداد': 'بغداد',
      'البصرة': 'البصرة',
      'النجف': 'النجف',
      'كربلاء': 'كربلاء',
      'صلاح الدين': 'صلاح الدين',
      'ديالى': 'ديالى',
      'كركوك': 'كركوك',
      'دهوك': 'دهوك',
      'السليمانية': 'السليمانية',
      'بابل': 'بابل',
      'القادسية': 'القادسية',
      'المثنى': 'المثنى',
      'ميسان': 'ميسان',
      'واسط': 'واسط',
      'ذي قار': 'ذي قار',
      'أربيل': 'أربيل',
      'الأنبار': 'الأنبار',
    };

    final normalized = provinceMapping[dbProvinceName.trim()] ?? dbProvinceName.trim();
    debugPrint('🔄 تحويل: "$dbProvinceName" → "$normalized"');
    return normalized;
  }

  // جلب عدد الطلبات حسب المحافظة من قاعدة البيانات
  Future<void> _loadProvinceOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? currentUserPhone = prefs.getString('current_user_phone');

      debugPrint('🔍 === بدء جلب بيانات المحافظات ===');
      debugPrint('📱 رقم الهاتف من SharedPreferences: $currentUserPhone');

      if (currentUserPhone == null || currentUserPhone.isEmpty) {
        debugPrint('❌ رقم الهاتف غير موجود في SharedPreferences');
        return;
      }

      if (_selectedFromDate == null || _selectedToDate == null) {
        debugPrint('❌ التواريخ غير محددة');
        return;
      }

      debugPrint('� الفترة الزمنية:');
      debugPrint('   من: ${_selectedFromDate!.toIso8601String()}');
      debugPrint('   إلى: ${_selectedToDate!.toIso8601String()}');

      // 🌐 جلب الطلبات من الباك اند (آمن جداً)
      debugPrint('🔎 جلب طلبات المحافظات من الباك اند');

      final response = await http
          .post(
            Uri.parse('${ApiConfig.usersUrl}/statistics/province-orders'),
            headers: ApiConfig.defaultHeaders,
            body: jsonEncode({
              'phone': currentUserPhone,
              'from_date': _selectedFromDate!.toIso8601String(),
              'to_date': _selectedToDate!.toIso8601String(),
            }),
          )
          .timeout(ApiConfig.defaultTimeout);

      if (response.statusCode != 200) {
        debugPrint('❌ خطأ في جلب طلبات المحافظات: ${response.statusCode}');
        return;
      }

      final jsonData = jsonDecode(response.body);
      if (jsonData['success'] != true || jsonData['data'] == null) {
        debugPrint('❌ فشل في جلب طلبات المحافظات');
        return;
      }

      final data = jsonData['data'];
      final Map<String, dynamic> rawProvinceCounts = data['province_counts'] ?? {};
      final totalOrders = data['total_orders'] ?? 0;

      debugPrint('📊 عدد الطلبات المسترجعة: $totalOrders');

      if (totalOrders == 0) {
        debugPrint('⚠️ لا توجد طلبات في هذه الفترة للمستخدم $currentUserPhone');
      }

      // تحويل وتطبيع أسماء المحافظات
      final Map<String, int> provinceCounts = {};

      rawProvinceCounts.forEach((province, count) {
        if (province.toString().trim().isNotEmpty) {
          final originalName = province.toString().trim();
          final normalizedName = _normalizeProvinceName(originalName);
          provinceCounts[normalizedName] = (provinceCounts[normalizedName] ?? 0) + (count as int);
          debugPrint('   ✅ $normalizedName: $count طلب');
        }
      });

      debugPrint('🗺️ === النتيجة النهائية ===');
      debugPrint('عدد الطلبات حسب المحافظة:');
      provinceCounts.forEach((province, count) {
        debugPrint('   $province: $count طلب');
      });

      if (mounted) {
        setState(() {
          _provinceOrders.clear();
          _provinceOrders.addAll(provinceCounts);
        });
        debugPrint('✅ تم تحديث الخريطة بالبيانات');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ خطأ في جلب بيانات المحافظات: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  // جلب بيانات الطلبات حسب أيام الأسبوع (مستقل عن من/إلى)
  Future<void> _loadWeekdayOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserPhone = prefs.getString('current_user_phone');

      if (currentUserPhone == null) {
        debugPrint('⚠️ لا يوجد رقم مستخدم');
        return;
      }

      debugPrint('📱 رقم المستخدم الحالي: $currentUserPhone');

      // الحصول على الوقت الحالي بتوقيت UTC
      final nowUtc = DateTime.now().toUtc();

      // تحويل إلى توقيت العراق (UTC+3)
      final nowIraq = nowUtc.add(const Duration(hours: 3));

      debugPrint('🕐 الوقت الحالي UTC: ${nowUtc.toIso8601String()}');
      debugPrint('🕐 الوقت الحالي بتوقيت العراق: ${nowIraq.toString()}');

      // حساب بداية الأسبوع (السبت) بتوقيت العراق
      // في Dart: Monday=1, Tuesday=2, ..., Saturday=6, Sunday=7
      final currentWeekday = nowIraq.weekday;

      int daysToSubtract;
      if (currentWeekday == DateTime.saturday) {
        // 6
        daysToSubtract = 0; // اليوم هو السبت
      } else if (currentWeekday == DateTime.sunday) {
        // 7
        daysToSubtract = 1; // أمس كان السبت
      } else {
        // 1-5 (الاثنين-الجمعة)
        daysToSubtract = currentWeekday + 1; // عدد الأيام منذ السبت الماضي
      }

      debugPrint('📅 اليوم: ${_getArabicDayName(currentWeekday)}, الأيام منذ السبت: $daysToSubtract');

      // بداية الأسبوع (السبت 00:00:00) بتوقيت العراق
      final weekStartIraq = DateTime(
        nowIraq.year,
        nowIraq.month,
        nowIraq.day,
        0,
        0,
        0,
        0,
        0,
      ).subtract(Duration(days: daysToSubtract)).add(Duration(days: _weekOffset * 7));

      // نهاية الأسبوع (الجمعة 23:59:59) بتوقيت العراق
      final weekEndIraq = weekStartIraq.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

      // تحويل إلى UTC (طرح 3 ساعات)
      final weekStartUtc = weekStartIraq.subtract(const Duration(hours: 3));
      final weekEndUtc = weekEndIraq.subtract(const Duration(hours: 3));

      debugPrint('📅 الأسبوع بتوقيت العراق: من ${weekStartIraq.toString()} إلى ${weekEndIraq.toString()}');
      debugPrint('📅 الأسبوع بتوقيت UTC: من ${weekStartUtc.toIso8601String()} إلى ${weekEndUtc.toIso8601String()}');

      // 🌐 جلب طلبات الأسبوع من الباك اند (آمن جداً)
      final response = await http
          .post(
            Uri.parse('${ApiConfig.usersUrl}/statistics/weekday-orders'),
            headers: ApiConfig.defaultHeaders,
            body: jsonEncode({
              'phone': currentUserPhone,
              'week_start': weekStartUtc.toIso8601String(),
              'week_end': weekEndUtc.toIso8601String(),
            }),
          )
          .timeout(ApiConfig.defaultTimeout);

      if (response.statusCode != 200) {
        debugPrint('❌ خطأ في جلب طلبات الأسبوع: ${response.statusCode}');
        return;
      }

      final jsonData = jsonDecode(response.body);
      if (jsonData['success'] != true || jsonData['data'] == null) {
        debugPrint('❌ فشل في جلب طلبات الأسبوع');
        return;
      }

      final data = jsonData['data'];
      final List<dynamic> weekdayOrdersData = data['weekday_orders'] ?? [];

      debugPrint('📦 عدد الأيام المسترجعة: ${weekdayOrdersData.length}');

      // إعادة تعيين العدادات
      _weekdayOrders.updateAll((key, value) => 0);

      if (weekdayOrdersData.isNotEmpty) {
        // معالجة النتائج
        for (var item in weekdayOrdersData) {
          final dayOfWeek = item['day_of_week'] as int;
          final orderCount = item['order_count'] as int;

          // تحويل رقم اليوم من PostgreSQL (0=الأحد) إلى اسم اليوم بالعربي
          String dayName;
          switch (dayOfWeek) {
            case 0: // الأحد
              dayName = 'الأحد';
              break;
            case 1: // الاثنين
              dayName = 'الاثنين';
              break;
            case 2: // الثلاثاء
              dayName = 'الثلاثاء';
              break;
            case 3: // الأربعاء
              dayName = 'الأربعاء';
              break;
            case 4: // الخميس
              dayName = 'الخميس';
              break;
            case 5: // الجمعة
              dayName = 'الجمعة';
              break;
            case 6: // السبت
              dayName = 'السبت';
              break;
            default:
              dayName = 'غير معروف';
          }

          _weekdayOrders[dayName] = orderCount;
          debugPrint('   $dayName: $orderCount طلب');
        }
      }

      debugPrint('📊 نتائج الأسبوع: $_weekdayOrders');

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب بيانات أيام الأسبوع: $e');
    }
  }

  // اختيار تاريخ البداية
  Future<void> _selectFromDate() async {
    // تحويل التاريخ المحفوظ (UTC) إلى توقيت بغداد للعرض
    final currentFromBaghdad = _selectedFromDate != null
        ? _selectedFromDate!.add(const Duration(hours: 3))
        : DateTime.now().toUtc().add(const Duration(hours: 3)).subtract(const Duration(days: 7));

    final nowBaghdad = DateTime.now().toUtc().add(const Duration(hours: 3));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentFromBaghdad,
      firstDate: DateTime(2020),
      lastDate: nowBaghdad,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFffd700),
              onPrimary: Colors.black,
              surface: Color(0xFF1a1a2e),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        // تحويل التاريخ المختار من بغداد إلى UTC (بداية اليوم 00:00:00)
        final pickedBaghdad = DateTime(picked.year, picked.month, picked.day, 0, 0, 0);
        _selectedFromDate = pickedBaghdad.subtract(const Duration(hours: 3));

        // إذا كان التاريخ المختار بعد تاريخ النهاية، نعيد تعيين تاريخ النهاية
        if (_selectedToDate != null && _selectedFromDate!.isAfter(_selectedToDate!)) {
          _selectedToDate = null;
        }
      });
      // 🚀 استخدام الدالة الموحدة بدلاً من _loadProvinceOrders
      await _loadAllStatistics(forceRefresh: true);
    }
  }

  // اختيار تاريخ النهاية
  Future<void> _selectToDate() async {
    // تحويل التاريخ المحفوظ (UTC) إلى توقيت بغداد للعرض
    final currentToBaghdad = _selectedToDate != null
        ? _selectedToDate!.add(const Duration(hours: 3))
        : DateTime.now().toUtc().add(const Duration(hours: 3));

    final fromBaghdad = _selectedFromDate != null ? _selectedFromDate!.add(const Duration(hours: 3)) : DateTime(2020);

    final nowBaghdad = DateTime.now().toUtc().add(const Duration(hours: 3));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentToBaghdad,
      firstDate: fromBaghdad,
      lastDate: nowBaghdad,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFffd700),
              onPrimary: Colors.black,
              surface: Color(0xFF1a1a2e),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        // تحويل التاريخ المختار من بغداد إلى UTC (نهاية اليوم 23:59:59)
        final pickedBaghdad = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        _selectedToDate = pickedBaghdad.subtract(const Duration(hours: 3));
      });
      // 🚀 استخدام الدالة الموحدة بدلاً من _loadProvinceOrders
      await _loadAllStatistics(forceRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    final content = Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          // 🚀 استخدام الدالة الموحدة مع forceRefresh لتجاهل الكاش
          await _loadAllStatistics(forceRefresh: true);
        },
        color: const Color(0xFFffd700),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // العنوان والـ tabs - دائماً موجودة في البداية
            if (widget.isInsideTabView) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 25)),
              // زر الرجوع والعنوان
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // زر الرجوع
                      GestureDetector(
                        onTap: () => context.go('/profits'),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFFffd700).withValues(alpha: 0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFFffd700).withValues(alpha: 0.3) : Colors.black87,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            FontAwesomeIcons.arrowRight,
                            color: isDark ? const Color(0xFFffd700) : Colors.black87,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      // العنوان
                      Expanded(
                        child: Text(
                          'الإحصائيات',
                          style: GoogleFonts.cairo(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1a1a2e),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 55), // موازنة المساحة مع زر الرجوع
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 15)),
              // الـ tabs
              SliverToBoxAdapter(child: _buildInlineTabButtons(isDark)),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],

            // الشريط العلوي - فقط عندما لا تكون داخل TabView
            if (!widget.isInsideTabView) ...[
              SliverToBoxAdapter(child: const SizedBox(height: 25)),
              SliverToBoxAdapter(child: _buildHeader(isDark)),
              SliverToBoxAdapter(child: const SizedBox(height: 15)),
              SliverToBoxAdapter(child: _buildTabButtons(isDark)),
            ],

            // مربع الأرباح
            SliverToBoxAdapter(child: _buildProfitsCard(isDark)),
            SliverToBoxAdapter(child: const SizedBox(height: 20)),

            // اختيار التاريخ
            SliverToBoxAdapter(child: _buildDateRangeSelector(isDark)),
            SliverToBoxAdapter(child: const SizedBox(height: 20)),

            // الخريطة التفاعلية
            SliverToBoxAdapter(child: _buildInteractiveMap(isDark)),
            SliverToBoxAdapter(child: const SizedBox(height: 20)),

            // مربع الطلبات حسب أيام الأسبوع
            SliverToBoxAdapter(child: _buildWeekdayOrdersCard(isDark)),
            SliverToBoxAdapter(child: const SizedBox(height: 20)),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );

    // إذا كانت داخل TabView، لا تستخدم AppBackground
    if (widget.isInsideTabView) {
      return content;
    }

    // إذا لم تكن داخل TabView، استخدم AppBackground
    return AppBackground(child: content);
  }

  // بناء الشريط العلوي
  Widget _buildHeader(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          // زر رجوع ناعم وأنيق
          Material(
            color: isDark ? const Color(0xFF2d2d44) : Colors.white,
            elevation: 0,
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
              onTap: () => context.go('/profits'),
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(
                  FontAwesomeIcons.chevronRight,
                  color: isDark ? Colors.white : const Color(0xFF1a1a2e),
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // العنوان بسيط وواضح
          Expanded(
            child: Text(
              'الإحصائيات',
              style: GoogleFonts.cairo(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1a1a2e),
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 65), // موازنة المساحة مع زر الرجوع
        ],
      ),
    );
  }

  // أزرار التبويب
  Widget _buildTabButtons(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              label: 'الإحصائيات',
              icon: FontAwesomeIcons.chartLine,
              isActive: true,
              isDark: isDark,
              onTap: () {
                // already on this page
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTabButton(
              label: 'أكثر المنتجات',
              icon: FontAwesomeIcons.trophy,
              isActive: false,
              isDark: isDark,
              onTap: () {
                context.push('/top-products');
              },
            ),
          ),
        ],
      ),
    );
  }

  // أزرار التبويب للاستخدام داخل PageView
  Widget _buildInlineTabButtons(bool isDark) {
    final currentIndex = widget.currentTabIndex ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              label: 'الإحصائيات',
              icon: FontAwesomeIcons.chartLine,
              isActive: currentIndex == 0,
              isDark: isDark,
              onTap: () {
                widget.onTabChanged?.call(0);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTabButton(
              label: 'أكثر المنتجات',
              icon: FontAwesomeIcons.trophy,
              isActive: currentIndex == 1,
              isDark: isDark,
              onTap: () {
                widget.onTabChanged?.call(1);
              },
            ),
          ),
        ],
      ),
    );
  }

  // زر تبويب واحد
  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: isActive ? 12 : 8, sigmaY: isActive ? 12 : 8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: isActive
                  ? (isDark
                        ? const Color(0xFFFFD700).withValues(alpha: 0.15)
                        : const Color(0xFFFFD700).withValues(alpha: 0.2))
                  : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive
                    ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                    : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                width: isActive ? 1.5 : 1,
              ),
              boxShadow: [
                if (isActive)
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isActive ? const Color(0xFFFFA000) : (isDark ? Colors.white70 : Colors.grey[600]),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                      color: isActive
                          ? (isDark ? Colors.white : const Color(0xFF1a1a2e))
                          : (isDark ? Colors.white70 : Colors.grey[600]),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // مربع الأرباح
  Widget _buildProfitsCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Stack(
              children: [
                // خلفية زخرفية ناعمة - طبقة 1
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFFD700).withValues(alpha: isDark ? 0.08 : 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // المحتوى الرئيسي
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      // أيقونة مصغرة
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(FontAwesomeIcons.coins, color: Color(0xFFFFA000), size: 20),
                      ),
                      const SizedBox(width: 16),
                      // النصوص
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'إجمالي الأرباح',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.grey[700],
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _isLoadingProfits
                                ? SizedBox(
                                    height: 26,
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: isDark ? Colors.white : const Color(0xFF1a1a2e),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 800),
                                    tween: Tween(begin: 0, end: _realizedProfits),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, child) {
                                      return Text(
                                        '${value.toStringAsFixed(0)} د.ع',
                                        style: GoogleFonts.cairo(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : const Color(0xFF1a1a2e),
                                          height: 1.0,
                                        ),
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // واجهة اختيار التاريخ
  Widget _buildDateRangeSelector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _buildDateButton(label: 'من', date: _selectedFromDate, onTap: _selectFromDate, isDark: isDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDateButton(label: 'إلى', date: _selectedToDate, onTap: _selectToDate, isDark: isDark),
          ),
        ],
      ),
    );
  }

  // زر اختيار التاريخ
  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final displayDate = date?.add(const Duration(hours: 3));

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.calendar,
                      size: 12,
                      color: isDark ? const Color(0xFFFFD700) : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  displayDate != null
                      ? '${displayDate.year}-${displayDate.month.toString().padLeft(2, '0')}-${displayDate.day.toString().padLeft(2, '0')}'
                      : 'اختر التاريخ',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF1a1a2e),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // الخريطة التفاعلية (responsive + إخفاء مربع الملاحظة عند النقر خارجها)
  Widget _buildInteractiveMap(bool isDark) {
    if (_isLoadingMap) {
      return Container(
        height: 500,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: const Center(child: CircularProgressIndicator(color: Color(0xFFffd700))),
      );
    }

    if (_geoJsonData == null) {
      return Container(
        height: 500,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Center(
          child: Text('خطأ في تحميل الخريطة', style: GoogleFonts.cairo(color: isDark ? Colors.white : Colors.black87)),
        ),
      );
    }

    debugPrint('🗺️ Building map with province orders: $_provinceOrders');

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;

        // القياسات الحقيقية للخريطة العراقية (aspect ratio)
        final mapHeight = screenWidth * 1.2; // نسبة 1:1 تقريباً

        return GestureDetector(
          onTap: () {
            if (_selectedProvince != null && mounted) {
              setState(() {
                _selectedProvince = null;
              });
            }
          },
          child: Container(
            height: mapHeight, // حجم طبيعي 100%
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Transform.scale(
              scale: 1.2, // 100% - حجم طبيعي!
              child: Container(
                height: mapHeight,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: IraqMapWidget(
                  geoJsonData: _geoJsonData!,
                  provinceOrders: _provinceOrders,
                  selectedProvince: _selectedProvince,
                  onProvinceSelected: (provinceName, center) {
                    if (mounted) {
                      setState(() {
                        _selectedProvince = provinceName;
                      });
                    }
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // مربع الطلبات حسب أيام الأسبوع
  Widget _buildWeekdayOrdersCard(bool isDark) {
    // حساب عنوان الأسبوع
    String weekTitle;
    if (_weekOffset == 0) {
      weekTitle = 'هذا الأسبوع';
    } else if (_weekOffset == -1) {
      weekTitle = 'الأسبوع الماضي';
    } else {
      weekTitle = 'قبل ${-_weekOffset} أسابيع';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان مع الأزرار
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الصف الأول: الأيقونة والعنوان
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFFffd700).withValues(alpha: 0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isDark ? null : Border.all(color: Colors.black87, width: 1),
                    ),
                    child: FaIcon(
                      FontAwesomeIcons.calendarWeek,
                      color: isDark ? const Color(0xFFffd700) : Colors.black87,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الطلبات حسب أيام الأسبوع',
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        // 🚀 عرض كرات تحميل أو عنوان الأسبوع
                        _isLoading
                            ? SizedBox(
                                height: 12,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                    3,
                                    (index) => Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                                      child: _BouncingBall(
                                        delay: Duration(milliseconds: index * 150),
                                        color: const Color(0xFFffd700),
                                        size: 4,
                                        maxHeight: 10,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Text(
                                weekTitle,
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: const Color(0xFFffd700),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ],
                    ),
                  ),
                ],
              ),

              // الصف الثاني: أزرار التنقل
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // زر الأسبوع الماضي
                  if (_weekOffset > -4)
                    GestureDetector(
                      onTap: () async {
                        setState(() {
                          _weekOffset--;
                        });
                        await _loadAllStatistics(forceRefresh: true);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFFffd700).withValues(alpha: 0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? const Color(0xFFffd700).withValues(alpha: 0.3) : Colors.black87,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.arrowLeft,
                              color: isDark ? const Color(0xFFffd700) : Colors.black87,
                              size: 12,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'السابق',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: isDark ? const Color(0xFFffd700) : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  // زر الأسبوع التالي
                  if (_weekOffset < 0)
                    GestureDetector(
                      onTap: () async {
                        setState(() {
                          _weekOffset++;
                        });
                        await _loadAllStatistics(forceRefresh: true);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFFffd700).withValues(alpha: 0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? const Color(0xFFffd700).withValues(alpha: 0.3) : Colors.black87,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'التالي',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: isDark ? const Color(0xFFffd700) : Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 6),
                            FaIcon(
                              FontAwesomeIcons.arrowRight,
                              color: isDark ? const Color(0xFFffd700) : Colors.black87,
                              size: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._weekdayOrders.entries.map((entry) {
            final maxOrders = _weekdayOrders.values.reduce((a, b) => a > b ? a : b);
            final percentage = maxOrders > 0 ? entry.value / maxOrders : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          entry.key,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 🚀 عرض كرات تحميل أو العداد
                      _isLoading
                          ? SizedBox(
                              height: 12,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(
                                  3,
                                  (index) => Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                                    child: _BouncingBall(
                                      delay: Duration(milliseconds: index * 150),
                                      color: const Color(0xFFffd700),
                                      size: 4,
                                      maxHeight: 10,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              '${entry.value} طلب',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFffd700),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: percentage,
                      minHeight: 8,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFffd700)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // زر أكثر المنتجات مبيعاً
  Widget _buildTopProductsButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        context.push('/top-products');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2d2d44) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const FaIcon(FontAwesomeIcons.trophy, color: Color(0xFFFFA000), size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              'أكثر المنتجات مبيعاً',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1a1a2e),
              ),
            ),
            const Spacer(),
            Icon(FontAwesomeIcons.chevronLeft, color: isDark ? Colors.white54 : Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }
}

// 🎯 Widget للكرات القافزة (مؤشر تحميل مخصص)
class _BouncingBall extends StatefulWidget {
  final Duration delay;
  final Color color;
  final double size;
  final double maxHeight;

  const _BouncingBall({required this.delay, required this.color, this.size = 8, this.maxHeight = 20});

  @override
  State<_BouncingBall> createState() => _BouncingBallState();
}

class _BouncingBallState extends State<_BouncingBall> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);

    _animation = Tween<double>(
      begin: 0,
      end: -widget.maxHeight * 0.5, // تقليل الارتفاع إلى 50% فقط
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
          ),
        );
      },
    );
  }
}
