import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../widgets/curved_navigation_bar.dart';
import '../widgets/common_header.dart';
import '../core/design_system.dart';
import 'dart:math' as math;

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage>
    with TickerProviderStateMixin {
  // متحكمات الحركة
  late AnimationController _pulseAnimationController;
  // تم إزالة _pulseScale غير المستخدم

  // تم إزالة _isLoading غير المستخدم

  // البيانات الحقيقية من قاعدة البيانات
  int _totalOrders = 0;
  double _totalProfits = 0.0;
  double _realizedProfits = 0.0;
  // تم إزالة _expectedProfits غير المستخدم
  int _activeOrders = 0;
  int _deliveredOrders = 0;
  // تم إزالة _inDeliveryOrders غير المستخدم
  // تم إزالة _cancelledOrders غير المستخدم

  // بيانات أفضل المنتجات
  List<Map<String, dynamic>> _topProducts = [];

  // بيانات الأرباح حسب الفترة
  List<double> _dailyProfits = List.filled(7, 0.0); // الأحد إلى السبت
  List<double> _lastWeekProfits = List.filled(7, 0.0); // الأسبوع الماضي
  List<double> _monthlyProfits = [];
  List<String> _monthNames = [];

  // متغير لتتبع عرض الأسبوع الحالي أم الماضي
  bool _showCurrentWeek = true;

  // أسماء أيام الأسبوع (من الأحد إلى السبت)
  final List<String> _dayNames = [
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadRealData();
  }

  void _initializeAnimations() {
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // تم إزالة إعداد _pulseScale غير المستخدم

    _pulseAnimationController.repeat(reverse: true);
  }

  // جلب البيانات الحقيقية من قاعدة البيانات
  Future<void> _loadRealData() async {
    if (!mounted) return;

    // تم إزالة تعيين _isLoading غير المستخدم

    try {
      // الحصول على معرف المستخدم الحالي من SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String? currentUserId = prefs.getString('current_user_id');
      String? currentUserPhone = prefs.getString('current_user_phone');

      debugPrint('🔍 معرف المستخدم الحالي: $currentUserId');
      debugPrint('📱 رقم هاتف المستخدم الحالي: $currentUserPhone');

      if (currentUserId == null && currentUserPhone == null) {
        debugPrint('❌ لا يوجد مستخدم مسجل دخول');
        return;
      }

      // جلب جميع الطلبات للمستخدم الحالي
      // استخدام user_id أولاً، وإذا لم يكن متوفراً استخدم primary_phone
      List<dynamic> ordersResponse = [];

      if (currentUserId != null && currentUserId.isNotEmpty) {
        // جلب الطلبات باستخدام user_id مع ترتيب محسن
        ordersResponse = await Supabase.instance.client
            .from('orders')
            .select('*')
            .eq('user_id', currentUserId)
            .order('created_at', ascending: false); // استخدام الفهرس على created_at

        debugPrint('📊 تم جلب ${ordersResponse.length} طلب باستخدام user_id');
      }

      // إذا لم نجد طلبات بـ user_id، جرب primary_phone
      if (ordersResponse.isEmpty &&
          currentUserPhone != null &&
          currentUserPhone.isNotEmpty) {
        ordersResponse = await Supabase.instance.client
            .from('orders')
            .select('*')
            .eq('primary_phone', currentUserPhone) // استخدام الفهرس على primary_phone
            .order('created_at', ascending: false); // استخدام الفهرس على created_at

        debugPrint(
          '📊 تم جلب ${ordersResponse.length} طلب باستخدام primary_phone',
        );
      }

      // طباعة عينة من البيانات للتشخيص
      if (ordersResponse.isNotEmpty) {
        debugPrint('📋 عينة من الطلبات:');
        for (int i = 0; i < (ordersResponse.length > 3 ? 3 : ordersResponse.length); i++) {
          final order = ordersResponse[i];
          debugPrint('   طلب ${i + 1}: حالة=${order['status']}, ربح=${order['profit']}, تاريخ=${order['created_at']}');
        }
      } else {
        debugPrint('⚠️ لم يتم العثور على أي طلبات للمستخدم');
      }

      debugPrint('📊 إجمالي الطلبات المجلبة: ${ordersResponse.length}');

      if (ordersResponse.isNotEmpty) {
        await _calculateStatistics(ordersResponse);
        await _loadTopProducts(ordersResponse);

        // تحديث الواجهة بالبيانات الجديدة
        if (mounted) {
          setState(() {
            // البيانات تم تحديثها في _calculateStatistics
          });
        }
      } else {
        debugPrint('لا توجد طلبات للمستخدم');
        _resetStatistics();

        // تحديث الواجهة بالقيم الصفرية
        if (mounted) {
          setState(() {
            // البيانات تم إعادة تعيينها في _resetStatistics
          });
        }
      }
    } catch (e) {
      debugPrint('خطأ في جلب الإحصائيات: $e');
      _resetStatistics();
    } finally {
      // تم إزالة تعيين _isLoading غير المستخدم
    }
  }

  // إعادة تعيين الإحصائيات إلى الصفر
  void _resetStatistics() {
    _totalOrders = 0;
    _totalProfits = 0.0;
    _realizedProfits = 0.0;
    // تم إزالة تعيين المتغيرات غير المستخدمة
    _activeOrders = 0;
    _deliveredOrders = 0;
    _topProducts = [];
    _dailyProfits = List.filled(7, 0.0);
    _lastWeekProfits = List.filled(7, 0.0);
    _monthlyProfits = List.filled(12, 0.0); // 12 شهر
    _monthNames = List.generate(
      12,
      (index) => (index + 1).toString().padLeft(2, '0'),
    ); // أرقام الشهور
  }

  // حساب الإحصائيات من الطلبات
  Future<void> _calculateStatistics(List<dynamic> orders) async {
    debugPrint('🧮 === بدء حساب الإحصائيات ===');
    debugPrint('📊 عدد الطلبات المستلمة: ${orders.length}');

    _totalOrders = orders.length;
    _totalProfits = 0.0;
    _realizedProfits = 0.0;
    // تم إزالة تعيين المتغيرات غير المستخدمة
    _activeOrders = 0;
    _deliveredOrders = 0;

    // إعادة تعيين الطلبات الأسبوعية
    _dailyProfits = List.filled(7, 0.0);
    _lastWeekProfits = List.filled(7, 0.0);

    for (var order in orders) {
      final status = order['status'] ?? '';

      // حساب الربح من البيانات المتاحة
      double profit = 0.0;

      // الحصول على الربح من حقل profit مباشرة
      if (order['profit'] != null) {
        profit = (order['profit'] as num).toDouble();
      }

      debugPrint('طلب: ${order['id']}, الحالة: $status, الربح: $profit');

      // إضافة جميع الطلبات للإحصائيات الأسبوعية
      _addToWeeklyOrders(order['created_at']);

      // حساب الأرباح حسب الحالة (حسب الحالات الموجودة فعلياً في قاعدة البيانات)
      switch (status) {
        case 'delivered':
          _deliveredOrders++;
          _realizedProfits += profit;
          _totalProfits += profit;
          break;
        case 'active':
        case 'confirmed':
          _activeOrders++;
          // تم إزالة تعيين _expectedProfits غير المستخدم
          break;
        case 'shipped':
        case 'in_delivery':
        case 'pending':
          // تم إزالة تعيين _inDeliveryOrders غير المستخدم
          // تم إزالة تعيين _expectedProfits غير المستخدم
          break;
        case 'cancelled':
          // تم إزالة تعيين _cancelledOrders غير المستخدم
          break;
      }
    }

    debugPrint('📊 === نتائج حساب الإحصائيات ===');
    debugPrint('📈 إجمالي الطلبات: $_totalOrders');
    debugPrint('✅ الطلبات المكتملة: $_deliveredOrders');
    debugPrint('🔄 الطلبات النشطة: $_activeOrders');
    debugPrint('💰 إجمالي الأرباح: $_totalProfits د.ع');
    debugPrint('💵 الأرباح المحققة: $_realizedProfits د.ع');

    // حساب الطلبات الشهرية
    _calculateMonthlyOrders(orders);

    debugPrint('✅ تم الانتهاء من حساب الإحصائيات');
  }

  // إضافة الطلب إلى اليوم المناسب في الأسبوع
  void _addToWeeklyOrders(String? createdAt) {
    if (createdAt == null) return;

    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();

      // حساب بداية الأسبوع الحالي (الأحد)
      final currentWeekStart = now.subtract(Duration(days: now.weekday % 7));
      final currentWeekStartDate = DateTime(currentWeekStart.year, currentWeekStart.month, currentWeekStart.day);

      // حساب بداية الأسبوع الماضي
      final lastWeekStart = currentWeekStartDate.subtract(Duration(days: 7));
      final lastWeekEnd = currentWeekStartDate.subtract(Duration(days: 1));

      // تحويل يوم الأسبوع إلى فهرس صحيح
      int dayIndex;
      if (date.weekday == 7) {
        // الأحد
        dayIndex = 0;
      } else {
        // الاثنين إلى السبت
        dayIndex = date.weekday; // الاثنين=1, الثلاثاء=2, ..., السبت=6
      }

      // التأكد من أن الفهرس صحيح
      if (dayIndex >= 0 && dayIndex < _dailyProfits.length) {
        // تحديد إذا كان الطلب في الأسبوع الحالي أم الماضي
        if (date.isAfter(currentWeekStartDate.subtract(Duration(days: 1))) && date.isBefore(now.add(Duration(days: 1)))) {
          // الأسبوع الحالي
          _dailyProfits[dayIndex] += 1;
          debugPrint('📅 إضافة طلب للأسبوع الحالي - ${_dayNames[dayIndex]} (فهرس $dayIndex)');
        } else if (date.isAfter(lastWeekStart.subtract(Duration(days: 1))) && date.isBefore(lastWeekEnd.add(Duration(days: 1)))) {
          // الأسبوع الماضي
          _lastWeekProfits[dayIndex] += 1;
          debugPrint('� إضافة طلب للأسبوع الماضي - ${_dayNames[dayIndex]} (فهرس $dayIndex)');
        }
      }
    } catch (e) {
      debugPrint('خطأ في تحليل التاريخ: $e');
    }
  }

  // حساب الطلبات الشهرية (12 شهر)
  void _calculateMonthlyOrders(List<dynamic> orders) {
    // إنشاء خريطة لآخر 12 شهر
    Map<String, int> monthlyData = {};
    final now = DateTime.now();

    // إنشاء آخر 12 شهر
    for (int i = 11; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      monthlyData[monthKey] = 0;
    }

    debugPrint('🗓️ حساب الطلبات الشهرية من ${orders.length} طلب');

    for (var order in orders) {
      try {
        final date = DateTime.parse(order['created_at'] ?? '');
        final monthKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}';

        // إضافة الطلب إذا كان ضمن آخر 12 شهر
        if (monthlyData.containsKey(monthKey)) {
          monthlyData[monthKey] = monthlyData[monthKey]! + 1;
        }

        debugPrint(
          '📅 شهر $monthKey: إضافة طلب، المجموع: ${monthlyData[monthKey]}',
        );
      } catch (e) {
        debugPrint('خطأ في تحليل التاريخ: $e');
      }
    }

    // إنشاء قائمة مرتبة لـ 12 شهر (من 1 إلى 12)
    List<int> orderedMonthlyData = List.filled(12, 0);
    List<String> orderedMonthNames = List.generate(
      12,
      (index) => (index + 1).toString().padLeft(2, '0'),
    );

    // نسخ البيانات إلى القائمة المرتبة
    for (var entry in monthlyData.entries) {
      final monthNumber = int.tryParse(entry.key.split('-')[1]) ?? 1;
      if (monthNumber >= 1 && monthNumber <= 12) {
        orderedMonthlyData[monthNumber - 1] = entry.value;
      }
    }

    _monthlyProfits = orderedMonthlyData.map((e) => e.toDouble()).toList();
    _monthNames = orderedMonthNames;

    debugPrint('📊 الطلبات الشهرية النهائية: $_monthlyProfits');
    debugPrint('📊 أرقام الشهور: $_monthNames');
  }

  // جلب أفضل المنتجات للمستخدم الحالي
  Future<void> _loadTopProducts(List<dynamic> orders) async {
    try {
      debugPrint('🏆 === بدء جلب أفضل المنتجات للمستخدم الحالي ===');

      // فلترة الطلبات المكتملة فقط
      List<dynamic> deliveredOrders = orders
          .where((order) => order['status'] == 'delivered')
          .toList();

      debugPrint('📦 عدد الطلبات المكتملة: ${deliveredOrders.length}');

      if (deliveredOrders.isEmpty) {
        debugPrint('❌ لا توجد طلبات مكتملة للمستخدم');
        _topProducts = [];
        return;
      }

      // طباعة عينة من الطلبات المكتملة للتشخيص
      debugPrint('📋 عينة من الطلبات المكتملة:');
      for (int i = 0; i < (deliveredOrders.length > 3 ? 3 : deliveredOrders.length); i++) {
        final order = deliveredOrders[i];
        debugPrint('   طلب مكتمل: ${order['id']} - هاتف: ${order['primary_phone']}');
      }

      // استخراج معرفات الطلبات المكتملة
      List<String> deliveredOrderIds = deliveredOrders
          .map((order) => order['id'] as String)
          .toList();

      // جلب عناصر الطلبات من جدول order_items للطلبات المكتملة
      // استخدام الفهرس على order_id لتحسين الأداء
      debugPrint('🔍 جلب عناصر الطلبات من order_items...');

      final orderItemsResponse = await Supabase.instance.client
          .from('order_items')
          .select('product_name, quantity, profit_per_item, order_id')
          .inFilter('order_id', deliveredOrderIds) // استخدام الفهرس على order_id
          .order('product_name'); // ترتيب حسب اسم المنتج للتجميع الأفضل

      debugPrint('📋 تم جلب ${orderItemsResponse.length} عنصر من order_items');

      if (orderItemsResponse.isEmpty) {
        debugPrint('❌ لا توجد عناصر في order_items للطلبات المكتملة');
        _topProducts = [];
        return;
      }

      // حساب إحصائيات المنتجات
      Map<String, Map<String, dynamic>> productData = {};

      for (var item in orderItemsResponse) {
        final productName = item['product_name'] ?? 'منتج غير محدد';
        final quantity = (item['quantity'] ?? 1).toInt();
        final profitPerItem = (item['profit_per_item'] != null)
            ? double.tryParse(item['profit_per_item'].toString()) ?? 0.0
            : 0.0;
        final totalProfit = profitPerItem * quantity;

        debugPrint('📦 منتج: $productName، كمية: $quantity، ربح للقطعة: $profitPerItem');

        if (productData.containsKey(productName)) {
          productData[productName]!['sales'] += quantity;
          productData[productName]!['profit'] += totalProfit;
        } else {
          productData[productName] = {
            'name': productName,
            'sales': quantity,
            'profit': totalProfit,
          };
        }
      }

      // ترتيب المنتجات حسب عدد المبيعات (الكمية)
      _topProducts = productData.values.toList()
        ..sort((a, b) => b['sales'].compareTo(a['sales']));

      // أخذ أفضل 5 منتجات فقط
      if (_topProducts.length > 5) {
        _topProducts = _topProducts.take(5).toList();
      }

      debugPrint('🎯 === نتائج أفضل المنتجات للمستخدم ===');
      debugPrint('📊 عدد المنتجات المختلفة: ${_topProducts.length}');

      for (int i = 0; i < _topProducts.length; i++) {
        var product = _topProducts[i];
        debugPrint(
          '🏆 ${i + 1}. ${product['name']}: ${product['sales']} قطعة مباعة، ربح: ${product['profit'].toStringAsFixed(0)} د.ع',
        );
      }

      if (_topProducts.isEmpty) {
        debugPrint('⚠️ لا توجد منتجات مباعة للمستخدم الحالي');
      }

    } catch (e) {
      debugPrint('❌ خطأ في جلب أفضل المنتجات: $e');
      _topProducts = [];
    }
  }

  @override
  void dispose() {
    _pulseAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.primaryBackground,
      extendBody: true,
      body: Column(
        children: [
          // الشريط العلوي الموحد
          CommonHeader(
            title: 'الإحصائيات',
            rightActions: [
              // زر الرجوع على اليمين
              GestureDetector(
                onTap: () => context.go('/products'),
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

          // المحتوى القابل للتمرير مع Pull-to-refresh
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadRealData,
              color: const Color(0xFF28a745),
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  top: 20,
                  left: 15,
                  right: 15,
                  bottom: 100, // مساحة للشريط السفلي
                ),
                child: Column(
                  children: [
                    // البطاقات الإحصائية الرئيسية
                    _buildMainStatisticsCards(),

                    const SizedBox(height: 30),

                    // الرسوم البيانية
                    _buildChartsSection(),

                    const SizedBox(height: 30),

                    // جدول أفضل المنتجات
                    _buildTopProductsTable(),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // الشريط السفلي المنحني
      bottomNavigationBar: CurvedNavigationBar(
        index: 2, // الإحصائيات
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
          switch (index) {
            case 0:
              context.go('/products');
              break;
            case 1:
              context.go('/orders');
              break;
            case 2:
              // الصفحة الحالية
              break;
            case 3:
              context.go('/account');
              break;
          }
        },
        letIndexChange: (index) => true,
      ),
    );
  }



  // البطاقات الإحصائية الرئيسية
  Widget _buildMainStatisticsCards() {
    return Column(
      children: [
        // الصف الأول
        Row(
          children: [
            Expanded(child: _buildOrdersStatCard()),
            const SizedBox(width: 15),
            Expanded(child: _buildProfitsStatCard()),
          ],
        ),
        const SizedBox(height: 20),
        // الصف الثاني
        Row(
          children: [
            Expanded(child: _buildDeliveredOrdersCard()),
            const SizedBox(width: 15),
            Expanded(child: _buildActiveOrdersCard()),
          ],
        ),
      ],
    );
  }

  // بطاقة إجمالي الطلبات
  Widget _buildOrdersStatCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8FA7F7), Color(0xFF9B7BC4)], // ألوان أفتح
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.cartShopping,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              Text(
                _totalOrders.toString(),
                style: GoogleFonts.cairo(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            'إجمالي الطلبات',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'جميع الطلبات',
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // بطاقة إجمالي الأرباح
  Widget _buildProfitsStatCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5CB85C), Color(0xFF5BCCCB)], // ألوان أفتح
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF28a745).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.dollarSign,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              Text(
                _realizedProfits.toStringAsFixed(
                  0,
                ), // استخدام الأرباح المحققة فقط
                style: GoogleFonts.cairo(
                  fontSize: 20, // تصغير حجم الخط
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            'الأرباح المحققة',
            style: GoogleFonts.cairo(
              fontSize: 14, // تصغير حجم الخط
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'دينار عراقي',
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // بطاقة الطلبات المكتملة
  Widget _buildDeliveredOrdersCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5BC0DE), Color(0xFF5CB3CC)], // ألوان أفتح
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17a2b8).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.check,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              Text(
                _deliveredOrders.toString(),
                style: GoogleFonts.cairo(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            'تم التوصيل',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'طلبات مكتملة',
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // بطاقة الطلبات النشطة
  Widget _buildActiveOrdersCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0AD4E), Color(0xFFEEA236)], // ألوان أفتح
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFffc107).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.clock,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              Text(
                _activeOrders.toString(),
                style: GoogleFonts.cairo(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            'طلبات نشطة',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'قيد المعالجة',
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // قسم الرسوم البيانية
  Widget _buildChartsSection() {
    return Column(
      children: [
        // الأرباح الشهرية
        _buildMonthlyProfitsChart(),
        const SizedBox(height: 30),
        // الطلبات الأسبوعية
        _buildDailyProfitsChart(),
      ],
    );
  }

  // رسم بياني للأرباح الشهرية
  Widget _buildMonthlyProfitsChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF28a745).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF28a745).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.chartColumn,
                  color: Color(0xFF28a745),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'الطلبات الشهرية (12 شهر)',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildMonthlyProfitsChartContent(),
        ],
      ),
    );
  }

  // محتوى الرسم البياني للأرباح الشهرية
  Widget _buildMonthlyProfitsChartContent() {
    if (_monthlyProfits.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: Text(
          'لا توجد بيانات للأرباح الشهرية',
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    double maxProfit = _monthlyProfits.reduce((a, b) => a > b ? a : b);
    if (maxProfit == 0) maxProfit = 1;

    return SizedBox(
      height: 150, // زيادة الارتفاع
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: math.max(300, _monthlyProfits.length * 60.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _monthlyProfits.asMap().entries.map((entry) {
              int index = entry.key;
              double profit = entry.value;
              double height = (profit / maxProfit) * 80; // تقليل ارتفاع العمود
              if (height < 8) height = 8;

              return Flexible(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min, // تقليل المساحة المستخدمة
                    children: [
                      // القيمة
                      Text(
                        profit.toStringAsFixed(0),
                        style: GoogleFonts.cairo(
                          fontSize: 9,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // العمود
                      Container(
                        width: 25, // تقليل عرض العمود
                        height: height,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              const Color(0xFF28a745),
                              const Color(0xFF20c997),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // اسم الشهر
                      Text(
                        index < _monthNames.length ? _monthNames[index] : '',
                        style: GoogleFonts.cairo(
                          fontSize: 9,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // رسم بياني للأرباح اليومية
  Widget _buildDailyProfitsChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF17a2b8).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF17a2b8).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.chartLine,
                  color: Color(0xFF17a2b8),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _showCurrentWeek ? 'الطلبات الأسبوعية - الأسبوع الحالي' : 'الطلبات الأسبوعية - الأسبوع الماضي',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              // زر التبديل
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showCurrentWeek = !_showCurrentWeek;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF28a745).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF28a745).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FontAwesomeIcons.arrowsRotate,
                        color: const Color(0xFF28a745),
                        size: 12,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _showCurrentWeek ? 'الماضي' : 'الحالي',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF28a745),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDailyProfitsChartContent(),
        ],
      ),
    );
  }

  // محتوى الرسم البياني للأرباح اليومية
  Widget _buildDailyProfitsChartContent() {
    // اختيار البيانات حسب الأسبوع المختار
    List<double> currentData = _showCurrentWeek ? _dailyProfits : _lastWeekProfits;
    double maxProfit = currentData.reduce((a, b) => a > b ? a : b);
    if (maxProfit == 0) maxProfit = 1;

    return SizedBox(
      height: 150, // زيادة الارتفاع
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: currentData.asMap().entries.map((entry) {
          int index = entry.key;
          double profit = entry.value;
          double height = (profit / maxProfit) * 80; // تقليل ارتفاع العمود
          if (height < 8) height = 8;

          return Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min, // تقليل المساحة المستخدمة
              children: [
                // القيمة
                Text(
                  profit.toStringAsFixed(0),
                  style: GoogleFonts.cairo(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                // العمود
                Container(
                  width: 22, // تقليل عرض العمود
                  height: height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        const Color(0xFF17a2b8),
                        const Color(0xFF138496),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                // اسم اليوم
                Text(
                  _dayNames[index],
                  style: GoogleFonts.cairo(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // جدول أفضل المنتجات
  Widget _buildTopProductsTable() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFffc107).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFffc107).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.trophy,
                  color: Color(0xFFffc107),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'أفضل 5 منتجات مبيعاً',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTopProductsContent(),
        ],
      ),
    );
  }

  // محتوى أفضل المنتجات
  Widget _buildTopProductsContent() {
    if (_topProducts.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: Text(
          'لا توجد مبيعات حتى الآن',
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    return Column(
      children: _topProducts.asMap().entries.map((entry) {
        int index = entry.key;
        var product = entry.value;

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a2e),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFffc107).withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // الترتيب
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFffc107),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              // اسم المنتج
              Expanded(
                flex: 3,
                child: Text(
                  product['name'] as String,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              // المبيعات (عدد القطع المباعة)
              Expanded(
                child: Text(
                  '${product['sales']} قطعة',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: const Color(0xFF28a745),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // الربح
              Expanded(
                child: Text(
                  '${(product['profit'] as double).toStringAsFixed(0)} د.ع',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: const Color(0xFFffc107),
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
