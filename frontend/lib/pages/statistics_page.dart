import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/theme_provider.dart';
import '../widgets/app_background.dart';
import '../widgets/iraq_map_widget.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
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
    await _loadGeoJsonData();
    await _setDefaultDateRange();
    await _loadUserProfits();
    await _loadProvinceOrders();
    await _loadWeekdayOrders();
  }

  // تحميل بيانات GeoJSON
  Future<void> _loadGeoJsonData() async {
    try {
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
    // الحصول على الوقت الحالي بتوقيت بغداد
    final nowUtc = DateTime.now().toUtc();
    final nowBaghdad = nowUtc.add(const Duration(hours: 3));

    // آخر 7 أيام
    final sevenDaysAgo = nowBaghdad.subtract(const Duration(days: 7));

    if (mounted) {
      setState(() {
        // بداية اليوم (00:00:00) بتوقيت بغداد، ثم تحويل إلى UTC
        final fromBaghdad = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day, 0, 0, 0);
        _selectedFromDate = fromBaghdad.subtract(const Duration(hours: 3)); // تحويل إلى UTC

        // نهاية اليوم (23:59:59) بتوقيت بغداد، ثم تحويل إلى UTC
        final toBaghdad = DateTime(nowBaghdad.year, nowBaghdad.month, nowBaghdad.day, 23, 59, 59);
        _selectedToDate = toBaghdad.subtract(const Duration(hours: 3)); // تحويل إلى UTC
      });
    }
  }

  // جلب أرباح المستخدم - جمع الأرباح من الطلبات المسلمة فقط
  Future<void> _loadUserProfits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? currentUserPhone = prefs.getString('current_user_phone');

      if (currentUserPhone == null || currentUserPhone.isEmpty) {
        return;
      }

      // جلب الطلبات المسلمة فقط (status = 'تم التسليم للزبون')
      final response = await Supabase.instance.client
          .from('orders')
          .select('profit')
          .eq('user_phone', currentUserPhone)
          .eq('status', 'تم التسليم للزبون');

      if (mounted) {
        // جمع جميع الأرباح من الطلبات المسلمة
        double totalProfit = 0.0;
        for (var order in response) {
          final profit = (order['profit'] as num?)?.toDouble() ?? 0.0;
          totalProfit += profit;
        }

        setState(() {
          _realizedProfits = totalProfit;
        });

        debugPrint('✅ إجمالي الأرباح المحققة: $totalProfit د.ع من ${response.length} طلب مسلم');
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

      // جلب الطلبات للمستخدم الحالي فقط
      // استخدام user_phone لأنه رقم المستخدم الذي أنشأ الطلب
      debugPrint('🔎 البحث عن الطلبات بـ user_phone = $currentUserPhone');

      final response = await Supabase.instance.client
          .from('orders')
          .select('id, province, city, created_at, user_phone, status')
          .eq('user_phone', currentUserPhone)
          .gte('created_at', _selectedFromDate!.toIso8601String())
          .lte('created_at', _selectedToDate!.toIso8601String());

      debugPrint('📊 عدد الطلبات المسترجعة: ${response.length}');

      if (response.isEmpty) {
        debugPrint('⚠️ لا توجد طلبات في هذه الفترة للمستخدم $currentUserPhone');
      }

      // حساب عدد الطلبات لكل محافظة
      final Map<String, int> provinceCounts = {};

      for (var order in response) {
        final province = order['province'];
        final orderId = order['id'];
        final city = order['city'];
        final status = order['status'];

        debugPrint('� طلب $orderId:');
        debugPrint('   المحافظة الأصلية: $province');
        debugPrint('   المدينة: $city');
        debugPrint('   الحالة: $status');

        if (province != null && province.toString().trim().isNotEmpty) {
          final originalName = province.toString().trim();
          final normalizedName = _normalizeProvinceName(originalName);

          provinceCounts[normalizedName] = (provinceCounts[normalizedName] ?? 0) + 1;
          debugPrint('   ✅ تم إضافة للمحافظة: $normalizedName');
        } else {
          debugPrint('   ⚠️ المحافظة فارغة!');
        }
      }

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

      // استخدام RPC للحصول على البيانات
      final response = await Supabase.instance.client.rpc(
        'get_weekday_orders',
        params: {
          'p_user_phone': currentUserPhone,
          'p_week_start': weekStartUtc.toIso8601String(),
          'p_week_end': weekEndUtc.toIso8601String(),
        },
      );

      debugPrint('📦 عدد الأيام المسترجعة: ${response?.length ?? 0}');

      // إعادة تعيين العدادات
      _weekdayOrders.updateAll((key, value) => 0);

      if (response != null && response.isNotEmpty) {
        // معالجة النتائج
        for (var item in response) {
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
      await _loadProvinceOrders();
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
      await _loadProvinceOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: RefreshIndicator(
          onRefresh: () async {
            await _loadUserProfits();
            await _loadProvinceOrders();
          },
          color: const Color(0xFFffd700),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // الشريط العلوي
              SliverToBoxAdapter(child: const SizedBox(height: 25)),
              SliverToBoxAdapter(child: _buildHeader(isDark)),
              SliverToBoxAdapter(child: const SizedBox(height: 20)),

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

              // زر أكثر المنتجات مبيعاً
              SliverToBoxAdapter(child: _buildTopProductsButton()),
              SliverToBoxAdapter(child: const SizedBox(height: 50)),
            ],
          ),
        ),
      ),
    );
  }

  // بناء الشريط العلوي
  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // زر الرجوع - يرجع إلى صفحة الأرباح
          GestureDetector(
            onTap: () => context.go('/profits'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFffd700).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.3), width: 1),
              ),
              child: const Icon(FontAwesomeIcons.arrowRight, color: Color(0xFFffd700), size: 18),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              'الإحصائيات',
              style: GoogleFonts.cairo(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 55), // للتوازن
        ],
      ),
    );
  }

  // مربع الأرباح
  Widget _buildProfitsCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          // أيقونة الدولار
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFffd700).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const FaIcon(FontAwesomeIcons.dollarSign, color: Color(0xFFffd700), size: 24),
          ),
          const SizedBox(width: 20),
          // النص
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إجمالي الأرباح المحققة',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_realizedProfits.toStringAsFixed(0)} د.ع',
                  style: GoogleFonts.cairo(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFffd700),
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // واجهة اختيار التاريخ
  Widget _buildDateRangeSelector(bool isDark) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFffd700).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const FaIcon(FontAwesomeIcons.calendar, color: Color(0xFFffd700), size: 16),
              ),
              const SizedBox(width: 12),
              Text(
                'المدة',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildDateButton(label: 'من', date: _selectedFromDate, onTap: _selectFromDate, isDark: isDark),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildDateButton(label: 'إلى', date: _selectedToDate, onTap: _selectToDate, isDark: isDark),
              ),
            ],
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
    // تحويل التاريخ من UTC إلى توقيت بغداد للعرض
    final displayDate = date?.add(const Duration(hours: 3));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFFffd700).withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.cairo(fontSize: 12, color: const Color(0xFFffd700), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            Text(
              displayDate != null
                  ? '${displayDate.year}-${displayDate.month.toString().padLeft(2, '0')}-${displayDate.day.toString().padLeft(2, '0')}'
                  : 'اختر التاريخ',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // الخريطة التفاعلية
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

    return IraqMapWidget(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFffd700).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const FaIcon(FontAwesomeIcons.calendarWeek, color: Color(0xFFffd700), size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الطلبات حسب أيام الأسبوع',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weekTitle,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: const Color(0xFFffd700),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // زر الأسبوع الماضي
              if (_weekOffset > -4)
                GestureDetector(
                  onTap: () async {
                    setState(() {
                      _weekOffset--;
                    });
                    await _loadWeekdayOrders();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFffd700).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.3), width: 1),
                    ),
                    child: Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.arrowLeft, color: Color(0xFFffd700), size: 12),
                        const SizedBox(width: 6),
                        Text('السابق', style: GoogleFonts.cairo(fontSize: 12, color: const Color(0xFFffd700))),
                      ],
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              // زر الأسبوع التالي (إذا لم نكن في الأسبوع الحالي)
              if (_weekOffset < 0)
                GestureDetector(
                  onTap: () async {
                    setState(() {
                      _weekOffset++;
                    });
                    await _loadWeekdayOrders();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFffd700).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.3), width: 1),
                    ),
                    child: Row(
                      children: [
                        Text('التالي', style: GoogleFonts.cairo(fontSize: 12, color: const Color(0xFFffd700))),
                        const SizedBox(width: 6),
                        const FaIcon(FontAwesomeIcons.arrowRight, color: Color(0xFFffd700), size: 12),
                      ],
                    ),
                  ),
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
                      Text(
                        entry.key,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                        ),
                      ),
                      Text(
                        '${entry.value} طلب',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFffd700),
                        ),
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
    return GestureDetector(
      onTap: () {
        context.push('/top-products');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFffd700), Color(0xFFffa000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFffd700).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(FontAwesomeIcons.trophy, color: Color(0xFF1a1a2e), size: 24),
            const SizedBox(width: 15),
            Text(
              'أكثر المنتجات مبيعاً',
              style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1a1a2e)),
            ),
          ],
        ),
      ),
    );
  }
}
