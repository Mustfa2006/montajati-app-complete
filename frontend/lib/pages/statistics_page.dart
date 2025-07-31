import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../widgets/common_header.dart';
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
  List<double> _monthlyProfits = [];
  List<String> _monthNames = [];

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
        // جلب الطلبات باستخدام user_id
        ordersResponse = await Supabase.instance.client
            .from('orders')
            .select('*')
            .eq('user_id', currentUserId);

        debugPrint('📊 تم جلب ${ordersResponse.length} طلب باستخدام user_id');
      }

      // إذا لم نجد طلبات بـ user_id، جرب primary_phone
      if (ordersResponse.isEmpty &&
          currentUserPhone != null &&
          currentUserPhone.isNotEmpty) {
        ordersResponse = await Supabase.instance.client
            .from('orders')
            .select('*')
            .eq('primary_phone', currentUserPhone);

        debugPrint(
          '📊 تم جلب ${ordersResponse.length} طلب باستخدام primary_phone',
        );
      }

      debugPrint('📊 إجمالي الطلبات المجلبة: ${ordersResponse.length}');

      if (ordersResponse.isNotEmpty) {
        await _calculateStatistics(ordersResponse);
        await _loadTopProducts(ordersResponse);
      } else {
        debugPrint('لا توجد طلبات للمستخدم');
        _resetStatistics();
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
    _monthlyProfits = List.filled(12, 0.0); // 12 شهر
    _monthNames = List.generate(
      12,
      (index) => (index + 1).toString().padLeft(2, '0'),
    ); // أرقام الشهور
  }

  // حساب الإحصائيات من الطلبات
  Future<void> _calculateStatistics(List<dynamic> orders) async {
    _totalOrders = orders.length;
    _totalProfits = 0.0;
    _realizedProfits = 0.0;
    // تم إزالة تعيين المتغيرات غير المستخدمة
    _activeOrders = 0;
    _deliveredOrders = 0;

    // إعادة تعيين الطلبات الأسبوعية
    _dailyProfits = List.filled(7, 0.0);

    for (var order in orders) {
      final status = order['status'] ?? '';

      // حساب الربح من البيانات المتاحة
      double profit = 0.0;

      // محاولة الحصول على الربح من عدة مصادر
      if (order['profit_amount'] != null) {
        profit = (order['profit_amount']).toDouble();
      } else if (order['profit'] != null) {
        profit = (order['profit']).toDouble();
      } else {
        // حساب الربح من السعر والكمية إذا لم يكن محفوظاً
        final price = (order['price'] ?? 0).toDouble();
        final quantity = (order['quantity'] ?? 1).toDouble();
        final costPrice = (order['cost_price'] ?? 0).toDouble();

        if (price > 0 && costPrice > 0) {
          profit = (price - costPrice) * quantity;
        } else if (price > 0) {
          // افتراض هامش ربح 30% إذا لم يكن سعر التكلفة متوفراً
          profit = price * quantity * 0.3;
        }
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

    debugPrint('إجمالي الطلبات: $_totalOrders');
    debugPrint('الطلبات المكتملة: $_deliveredOrders');
    debugPrint('الطلبات النشطة: $_activeOrders');
    debugPrint('إجمالي الأرباح: $_totalProfits');

    // حساب الطلبات الشهرية
    _calculateMonthlyOrders(orders);
  }

  // إضافة الطلب إلى اليوم المناسب في الأسبوع
  void _addToWeeklyOrders(String? createdAt) {
    if (createdAt == null) return;

    try {
      final date = DateTime.parse(createdAt);
      // تحويل يوم الأسبوع إلى فهرس صحيح
      // DateTime.weekday: الاثنين=1, الثلاثاء=2, الأربعاء=3, الخميس=4, الجمعة=5, السبت=6, الأحد=7
      // _dayNames الجديد: الأحد=0, الاثنين=1, الثلاثاء=2, الأربعاء=3, الخميس=4, الجمعة=5, السبت=6
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
        _dailyProfits[dayIndex] += 1; // إضافة طلب واحد

        debugPrint(
          '📅 إضافة طلب لليوم ${_dayNames[dayIndex]} (فهرس $dayIndex)',
        );
        debugPrint('📊 الطلبات الأسبوعية الحالية: $_dailyProfits');
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

  // جلب أفضل المنتجات
  Future<void> _loadTopProducts(List<dynamic> orders) async {
    try {
      debugPrint('🏆 بدء جلب أفضل المنتجات من ${orders.length} طلب');

      // جلب عناصر الطلبات للطلبات المكتملة
      List<String> deliveredOrderIds = orders
          .where((order) => order['status'] == 'delivered')
          .map((order) => order['id'] as String)
          .toList();

      debugPrint('📦 عدد الطلبات المكتملة: ${deliveredOrderIds.length}');

      if (deliveredOrderIds.isEmpty) {
        debugPrint('❌ لا توجد طلبات مكتملة');
        _topProducts = [];
        return;
      }

      // محاولة جلب عناصر الطلبات من جدول order_items
      try {
        final orderItemsResponse = await Supabase.instance.client
            .from('order_items')
            .select('product_name, quantity, profit_per_item')
            .inFilter('order_id', deliveredOrderIds);

        debugPrint(
          '📋 تم جلب ${orderItemsResponse.length} عنصر من order_items',
        );

        if (orderItemsResponse.isNotEmpty) {
          Map<String, Map<String, dynamic>> productData = {};

          for (var item in orderItemsResponse) {
            final productName = item['product_name'] ?? 'منتج غير محدد';
            final quantity = (item['quantity'] ?? 1).toInt();
            final profitPerItem = (item['profit_per_item'] ?? 0).toDouble();
            final totalProfit = profitPerItem * quantity;

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

          // ترتيب المنتجات حسب المبيعات
          _topProducts = productData.values.toList()
            ..sort((a, b) => b['sales'].compareTo(a['sales']));

          // أخذ أفضل 5 منتجات فقط
          if (_topProducts.length > 5) {
            _topProducts = _topProducts.take(5).toList();
          }
        } else {
          debugPrint('❌ لا توجد عناصر في order_items للطلبات المكتملة');
          _topProducts = [];
        }
      } catch (e) {
        debugPrint('❌ خطأ في جلب order_items: $e');
        _topProducts = [];
      }

      debugPrint('✅ تم جلب ${_topProducts.length} من أفضل المنتجات');
      for (var product in _topProducts) {
        debugPrint(
          '🏆 ${product['name']}: ${product['sales']} مبيعة، ربح: ${product['profit']}',
        );
      }
    } catch (e) {
      debugPrint('خطأ في جلب أفضل المنتجات: $e');
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
      backgroundColor: const Color(0xFF1a1a2e),
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

      // مؤشر التحميل مع التضبيب
      bottomNavigationBar: const CustomBottomNavigationBar(
        currentRoute: '/statistics',
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
              Text(
                'الطلبات الأسبوعية',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
    double maxProfit = _dailyProfits.reduce((a, b) => a > b ? a : b);
    if (maxProfit == 0) maxProfit = 1;

    return SizedBox(
      height: 150, // زيادة الارتفاع
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _dailyProfits.asMap().entries.map((entry) {
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
              // المبيعات
              Expanded(
                child: Text(
                  '${product['sales']} مبيعة',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: const Color(0xFF28a745),
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
