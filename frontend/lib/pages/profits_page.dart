import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
// تم إزالة استيراد dart:math غير المستخدم
import '../services/simple_orders_service.dart';
import '../utils/number_formatter.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../widgets/common_header.dart';
// تم إزالة استيراد smart_profits_manager غير المستخدم
import '../services/lazy_loading_service.dart';

class ProfitsPage extends StatefulWidget {
  const ProfitsPage({super.key});

  @override
  State<ProfitsPage> createState() => _ProfitsPageState();
}

class _ProfitsPageState extends State<ProfitsPage>
    with TickerProviderStateMixin {
  // متحكمات الحركة
  late AnimationController _crownAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _refreshAnimationController;
  // تم إزالة _crownRotation غير المستخدم
  late Animation<double> _pulseAnimation;
  // تم إزالة _refreshRotation غير المستخدم

  // بيانات الأرباح
  double _realizedProfits = 0.0;
  double _pendingProfits = 0.0;
  int _completedOrders = 0;
  int _activeOrders = 0;
  int _deliveryOrders = 0;
  bool _isRefreshing = false;
  bool _isLoadingCounts = false;

  // خدمة الطلبات
  final SimpleOrdersService _ordersService = SimpleOrdersService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // تهيئة الصفحة بشكل صحيح
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProfitsPage();
    });

    // تحميل فوري للأرباح كخطة احتياطية
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _realizedProfits == 0.0 && _pendingProfits == 0.0) {
        debugPrint('🔄 تحميل احتياطي للأرباح...');
        _loadProfitsFromDatabase();
      }
    });

    // 🛡️ تم إزالة الاستماع لتغييرات الطلبات لمنع الحلقة اللا نهائية
    // الأرباح تُحدث فقط عند فتح الصفحة أو السحب للتحديث
    // _ordersService.addListener(_onOrdersChanged);
  }

  /// تهيئة صفحة الأرباح مع التحميل التدريجي
  Future<void> _initializeProfitsPage() async {
    try {
      debugPrint('🚀 === بدء تهيئة صفحة الأرباح ===');

      // تحميل الصفحة عند الحاجة فقط
      await LazyLoadingService.loadPageIfNeeded('profits');
      debugPrint('✅ تم تحميل خدمة التحميل التدريجي');

      // تحميل البيانات
      debugPrint('🔄 بدء تحميل بيانات الأرباح...');
      await _loadAndCalculateProfits();

      // إذا كانت الأرباح لا تزال صفر، حاول إعادة حساب الأرباح
      if (_realizedProfits == 0.0 && _pendingProfits == 0.0) {
        debugPrint('⚠️ الأرباح لا تزال صفر - محاولة إعادة الحساب الشامل...');
        await _forceRecalculateAllProfits();
      }

      debugPrint('✅ تم الانتهاء من تهيئة صفحة الأرباح');

    } catch (e) {
      debugPrint('❌ خطأ في تهيئة صفحة الأرباح: $e');
      // في حالة الخطأ، حاول تحميل البيانات مباشرة
      try {
        await _loadProfitsFromDatabase();
      } catch (e2) {
        debugPrint('❌ خطأ في التحميل المباشر: $e2');
      }
    }
  }

  // دالة تحديث البيانات
  Future<void> _refreshData() async {
    debugPrint('🔄 === تحديث بيانات الأرباح والعدادات ===');
    await _loadAndCalculateProfits();
  }

  // 🛡️ تم إزالة دالة _onOrdersChanged لمنع الحلقة اللا نهائية

  void _initializeAnimations() {
    // حركة التيجان
    _crownAnimationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    // تم إزالة تعريف _crownRotation غير المستخدم
    _crownAnimationController.repeat();

    // حركة النبض
    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _pulseAnimationController.repeat(reverse: true);

    // حركة التحديث
    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    // تم إزالة تعريف _refreshRotation غير المستخدم
  }

  // تحميل وحساب الأرباح من الطلبات الفعلية
  Future<void> _loadAndCalculateProfits() async {
    try {
      // تحميل الطلبات من قاعدة البيانات
      await _ordersService.loadOrders();

      // ✅ جلب الأرباح من قاعدة البيانات
      await _loadProfitsFromDatabase();
    } catch (e) {
      debugPrint('خطأ في تحميل الطلبات: $e');
    }
  }

  // إعادة حساب شاملة للأرباح
  Future<void> _forceRecalculateAllProfits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? currentUserPhone = prefs.getString('current_user_phone');

      if (currentUserPhone != null && currentUserPhone.isNotEmpty) {
        debugPrint('🔄 إعادة حساب شاملة للأرباح للمستخدم: $currentUserPhone');
        await _recalculateProfitsFromOrders(currentUserPhone);
      }
    } catch (e) {
      debugPrint('❌ خطأ في إعادة الحساب الشاملة: $e');
    }
  }

  // 🛡️ جلب الأرباح مباشرة من قاعدة البيانات (مع حماية من التكرار)
  bool _isLoadingProfits = false;

  // تم إزالة دالة _smartRecalculateProfits غير المستخدمة

  Future<void> _loadProfitsFromDatabase() async {
    // منع التحميل المتكرر
    if (_isLoadingProfits) {
      debugPrint('⏸️ تحميل الأرباح قيد التنفيذ - تجاهل الطلب');
      return;
    }

    _isLoadingProfits = true;

    try {
      debugPrint('📊 === جلب الأرباح من قاعدة البيانات ===');

      // الحصول على المستخدم الحالي
      final prefs = await SharedPreferences.getInstance();
      String? currentUserPhone = prefs.getString('current_user_phone');

      if (currentUserPhone == null || currentUserPhone.isEmpty) {
        debugPrint('❌ لا يوجد مستخدم مسجل دخول');
        if (mounted) {
          setState(() {
            _realizedProfits = 0.0;
            _pendingProfits = 0.0;
          });
        }
        return;
      }

      debugPrint('📱 رقم هاتف المستخدم: $currentUserPhone');

      // 🔍 أولاً: فحص جميع المستخدمين في قاعدة البيانات للتشخيص
      final allUsersResponse = await Supabase.instance.client
          .from('users')
          .select('phone, name, achieved_profits, expected_profits')
          .limit(5);

      debugPrint('📋 عينة من المستخدمين في قاعدة البيانات:');
      for (var user in allUsersResponse) {
        debugPrint('   ${user['phone']} - ${user['name']} - أرباح: ${user['achieved_profits']}');
      }

      // جلب الأرباح من قاعدة البيانات
      final response = await Supabase.instance.client
          .from('users')
          .select('achieved_profits, expected_profits, name')
          .eq('phone', currentUserPhone)
          .maybeSingle();

      debugPrint('🔍 استعلام البحث: phone = $currentUserPhone');
      debugPrint('📊 نتيجة الاستعلام: $response');

      if (response != null) {
        final dbAchievedProfits =
            (response['achieved_profits'] as num?)?.toDouble() ?? 0.0;
        final dbExpectedProfits =
            (response['expected_profits'] as num?)?.toDouble() ?? 0.0;
        final userName = response['name'] ?? 'مستخدم';

        debugPrint(
          '📊 الأرباح المحققة من قاعدة البيانات: $dbAchievedProfits د.ع',
        );
        debugPrint(
          '📊 الأرباح المنتظرة من قاعدة البيانات: $dbExpectedProfits د.ع',
        );
        debugPrint('👤 المستخدم: $userName');

        // حساب عدادات الطلبات
        await _calculateOrderCounts(currentUserPhone);

        if (mounted) {
          setState(() {
            _realizedProfits = dbAchievedProfits;
            _pendingProfits = dbExpectedProfits;
          });

          // 🔍 تأكيد إضافي من القيم المحدثة
          debugPrint('🎯 تم تحديث المتغيرات:');
          debugPrint('   _realizedProfits = $_realizedProfits');
          debugPrint('   _pendingProfits = $_pendingProfits');
          debugPrint('   _completedOrders = $_completedOrders');
          debugPrint('   _activeOrders = $_activeOrders');
          debugPrint('   _deliveryOrders = $_deliveryOrders');
        }
      } else {
        debugPrint('❌ لم يتم العثور على المستخدم في قاعدة البيانات');
        debugPrint('🔄 محاولة البحث بطرق مختلفة...');

        // محاولة البحث بطرق مختلفة
        await _tryAlternativeUserSearch(currentUserPhone);
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب الأرباح: $e');
      if (mounted) {
        setState(() {
          _realizedProfits = 0.0;
          _pendingProfits = 0.0;
        });
      }
    } finally {
      _isLoadingProfits = false;
    }
  }

  // محاولة البحث بطرق مختلفة
  Future<void> _tryAlternativeUserSearch(String userPhone) async {
    try {
      debugPrint('🔍 === البحث البديل عن المستخدم ===');

      // 1. البحث بدون مسافات
      final trimmedPhone = userPhone.trim();
      debugPrint('🔍 البحث برقم منظف: $trimmedPhone');

      var response = await Supabase.instance.client
          .from('users')
          .select('achieved_profits, expected_profits, name, phone')
          .eq('phone', trimmedPhone)
          .maybeSingle();

      if (response != null) {
        debugPrint('✅ تم العثور على المستخدم بالرقم المنظف');
        await _updateProfitsFromResponse(response);
        return;
      }

      // 2. البحث بـ LIKE للأرقام المشابهة
      debugPrint('🔍 البحث بـ LIKE للأرقام المشابهة...');
      final likeResponse = await Supabase.instance.client
          .from('users')
          .select('achieved_profits, expected_profits, name, phone')
          .like('phone', '%$trimmedPhone%')
          .limit(1);

      if (likeResponse.isNotEmpty) {
        debugPrint('✅ تم العثور على مستخدم مشابه: ${likeResponse.first['phone']}');
        await _updateProfitsFromResponse(likeResponse.first);
        return;
      }

      // 3. إذا لم نجد شيء، نضع قيم افتراضية
      debugPrint('❌ لم يتم العثور على المستخدم بأي طريقة');
      if (mounted) {
        setState(() {
          _realizedProfits = 0.0;
          _pendingProfits = 0.0;
        });
      }

    } catch (e) {
      debugPrint('❌ خطأ في البحث البديل: $e');
      if (mounted) {
        setState(() {
          _realizedProfits = 0.0;
          _pendingProfits = 0.0;
        });
      }
    }
  }

  // تحديث الأرباح من الاستجابة
  Future<void> _updateProfitsFromResponse(Map<String, dynamic> response) async {
    final dbAchievedProfits = (response['achieved_profits'] as num?)?.toDouble() ?? 0.0;
    final dbExpectedProfits = (response['expected_profits'] as num?)?.toDouble() ?? 0.0;
    final userName = response['name'] ?? 'مستخدم';
    final userPhone = response['phone'] ?? '';

    debugPrint('💰 الأرباح المحققة: $dbAchievedProfits د.ع');
    debugPrint('📊 الأرباح المنتظرة: $dbExpectedProfits د.ع');
    debugPrint('👤 المستخدم: $userName ($userPhone)');

    // حساب عدادات الطلبات
    await _calculateOrderCounts(userPhone);

    if (mounted) {
      setState(() {
        _realizedProfits = dbAchievedProfits;
        _pendingProfits = dbExpectedProfits;
      });

      debugPrint('✅ تم تحديث الأرباح بنجاح');
      debugPrint('   _realizedProfits = $_realizedProfits');
      debugPrint('   _pendingProfits = $_pendingProfits');

      // إذا كانت الأرباح صفر، حاول إعادة حسابها
      if (_realizedProfits == 0.0 && _pendingProfits == 0.0) {
        debugPrint('⚠️ الأرباح صفر - محاولة إعادة الحساب...');
        _recalculateProfitsFromOrders(userPhone);
      }
    }
  }

  // إعادة حساب الأرباح من الطلبات مباشرة
  Future<void> _recalculateProfitsFromOrders(String userPhone) async {
    try {
      debugPrint('🔄 === إعادة حساب الأرباح من الطلبات ===');

      // جلب جميع الطلبات للمستخدم
      final ordersResponse = await Supabase.instance.client
          .from('orders')
          .select('status, profit')
          .eq('primary_phone', userPhone);

      debugPrint('📊 تم جلب ${ordersResponse.length} طلب لإعادة الحساب');

      double realizedProfits = 0.0;
      double expectedProfits = 0.0;

      for (var order in ordersResponse) {
        final status = order['status'] ?? '';
        final profit = (order['profit'] as num?)?.toDouble() ?? 0.0;

        switch (status.toLowerCase()) {
          case 'delivered':
          case 'تم التسليم للزبون':
            realizedProfits += profit;
            break;
          case 'active':
          case 'in_delivery':
          case 'نشط':
          case 'في التوصيل':
            expectedProfits += profit;
            break;
        }
      }

      debugPrint('💰 الأرباح المحسوبة - محققة: $realizedProfits، منتظرة: $expectedProfits');

      if (mounted && (realizedProfits > 0 || expectedProfits > 0)) {
        setState(() {
          _realizedProfits = realizedProfits;
          _pendingProfits = expectedProfits;
        });

        debugPrint('✅ تم تحديث الأرباح من إعادة الحساب');
      }

    } catch (e) {
      debugPrint('❌ خطأ في إعادة حساب الأرباح: $e');
    }
  }

  // حساب عدادات الطلبات
  Future<void> _calculateOrderCounts(String userPhone) async {
    if (_isLoadingCounts) return;

    setState(() {
      _isLoadingCounts = true;
    });

    try {
      debugPrint('🔢 === حساب عدادات الطلبات ===');
      debugPrint('📱 المستخدم: $userPhone');

      // جلب جميع الطلبات للمستخدم مع تفاصيل أكثر
      debugPrint('🔍 البحث عن الطلبات برقم الهاتف: $userPhone');

      // أولاً: فحص إجمالي الطلبات في قاعدة البيانات
      final totalOrdersResponse = await Supabase.instance.client
          .from('orders')
          .select('id');

      debugPrint(
        '📊 إجمالي الطلبات في قاعدة البيانات: ${totalOrdersResponse.length}',
      );

      // ثانياً: فحص الطلبات لهذا الرقم
      final response = await Supabase.instance.client
          .from('orders')
          .select('id, status, customer_name, created_at, primary_phone')
          .eq('primary_phone', userPhone)
          .order('created_at', ascending: false);

      debugPrint('📊 تم جلب ${response.length} طلب لحساب العدادات');

      // إذا لم نجد طلبات، دعنا نتحقق من جميع الطلبات في قاعدة البيانات
      if (response.isEmpty) {
        debugPrint('⚠️ لم نجد طلبات لهذا الرقم، دعنا نتحقق من جميع الطلبات...');
        final allOrders = await Supabase.instance.client
            .from('orders')
            .select('primary_phone, customer_name')
            .limit(10);

        debugPrint('📋 عينة من أرقام الهواتف في قاعدة البيانات:');
        for (var order in allOrders) {
          debugPrint(
            '   ${order['primary_phone']} - ${order['customer_name']}',
          );
        }
      }

      int completed = 0;
      int active = 0;
      int delivery = 0;

      // إحصائيات مفصلة
      Map<String, int> statusCounts = {};

      for (var order in response) {
        String status = order['status'] ?? '';
        String customerName = order['customer_name'] ?? 'غير محدد';

        // عد الحالات
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;

        debugPrint('📋 ${order['id']}: $customerName - $status');

        // ✅ تصنيف صحيح حسب الحالات الفعلية في قاعدة البيانات
        switch (status.toLowerCase()) {
          case 'delivered':
            completed++;
            break;
          case 'active':
            active++;
            break;
          case 'in_delivery':
            delivery++;
            break;
          case 'cancelled':
            // لا نحسبها في أي من العدادات
            break;
          default:
            debugPrint('⚠️ حالة غير معروفة: $status');
        }
      }

      debugPrint('📊 === ملخص الحالات ===');
      statusCounts.forEach((status, count) {
        debugPrint('   $status: $count');
      });

      debugPrint('📊 === النتائج النهائية ===');
      debugPrint('   ✅ مكتمل: $completed');
      debugPrint('   🟡 نشط: $active');
      debugPrint('   🚚 قيد التوصيل: $delivery');

      if (mounted) {
        setState(() {
          _completedOrders = completed;
          _activeOrders = active;
          _deliveryOrders = delivery;
          _isLoadingCounts = false;
        });

        debugPrint('🎯 تم تحديث العدادات في الواجهة');
      }
    } catch (e) {
      debugPrint('❌ خطأ في حساب عدادات الطلبات: $e');
      if (mounted) {
        setState(() {
          _isLoadingCounts = false;
        });
      }
    }
  }

  void refreshProfits() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    _refreshAnimationController.forward().then((_) {
      _refreshAnimationController.reset();
    });

    // محاكاة تحديث البيانات
    await Future.delayed(const Duration(seconds: 1));

    // ✅ إعادة جلب الأرباح من قاعدة البيانات
    await _loadProfitsFromDatabase();

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  void dispose() {
    // ✅ إزالة المستمع عند إغلاق الصفحة
    _ordersService.removeListener(_onOrdersChanged);

    _crownAnimationController.dispose();
    _pulseAnimationController.dispose();
    _refreshAnimationController.dispose();
    super.dispose();
  }

  // ✅ دالة تحديث الأرباح عند تغيير الطلبات
  void _onOrdersChanged() {
    debugPrint('🔄 تم تغيير الطلبات - تحديث الأرباح...');
    // تأخير قصير للسماح لقاعدة البيانات بالتحديث
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _loadProfitsFromDatabase();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🔍 طباعة القيم المعروضة في الواجهة
    debugPrint('🖥️ === عرض الواجهة ===');
    debugPrint('   الأرباح المحققة المعروضة: $_realizedProfits');
    debugPrint('   الأرباح المنتظرة المعروضة: $_pendingProfits');

    // 🛡️ تم إزالة التحديث التلقائي لمنع الحلقة اللا نهائية
    // الأرباح تُحدث فقط عند:
    // 1. فتح الصفحة (initState)
    // 2. السحب للتحديث (refresh)
    // 3. تغيير الطلبات (listener)

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      extendBody: true, // السماح للمحتوى بالظهور خلف الشريط السفلي
      body: Column(
        children: [
          // الشريط العلوي الموحد
          CommonHeader(
            title: 'الأرباح',
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
              onRefresh: _refreshData,
              color: const Color(0xFFffd700),
              backgroundColor: const Color(0xFF16213e),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  top: 25,
                  left: 15,
                  right: 15,
                  bottom: 100,
                ),
                child: Column(
                  children: [
                    // بطاقة الأرباح المحققة
                    buildRealizedProfitsCard(),

                    const SizedBox(height: 20),

                    // بطاقة الأرباح
                    buildPendingProfitsCard(),

                    const SizedBox(height: 30),

                    // زر سحب الأرباح
                    buildWithdrawButton(),

                    const SizedBox(height: 15),

                    // زر سجل السحب
                    buildWithdrawalHistoryButton(),

                    const SizedBox(height: 15),

                    // زر الإحصائيات
                    buildStatisticsButton(),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // شريط التنقل السفلي
      bottomNavigationBar: const CustomBottomNavigationBar(
        currentRoute: '/profits',
      ),
    );
  }



  // بناء بطاقة الأرباح المحققة
  Widget buildRealizedProfitsCard() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.98 + (0.02 * _pulseAnimation.value),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: 140,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(color: const Color(0xFF06d6a0), width: 2),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF06d6a0).withValues(alpha: 0.2),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFF06d6a0).withValues(alpha: 0.1),
                  blurRadius: 50,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // الأيقونة
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF06d6a0), Color(0xFF05a57a)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF06d6a0).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      FontAwesomeIcons.circleCheck,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // المحتوى النصي
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // العنوان
                        Text(
                          'الأرباح المحققة',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // المبلغ
                        Text(
                          NumberFormatter.formatCurrency(_realizedProfits),
                          style: GoogleFonts.cairo(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF06d6a0),
                            shadows: [
                              Shadow(
                                color: const Color(
                                  0xFF06d6a0,
                                ).withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 3),

                        // الوصف
                        Row(
                          children: [
                            const Icon(
                              FontAwesomeIcons.circleInfo,
                              color: Color(0xFF17a2b8),
                              size: 12,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'من الطلبات المكتملة',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6c757d),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // بناء بطاقة الأرباح
  Widget buildPendingProfitsCard() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.98 + (0.02 * (1 - _pulseAnimation.value)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: 140,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(color: const Color(0xFFf72585), width: 2),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFf72585).withValues(alpha: 0.2),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFFf72585).withValues(alpha: 0.1),
                  blurRadius: 50,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // الأيقونة
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFf72585), Color(0xFFc9184a)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFf72585).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      FontAwesomeIcons.clock,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // المحتوى النصي
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // العنوان
                        Text(
                          'الأرباح المتوقعة',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // المبلغ
                        Text(
                          NumberFormatter.formatCurrency(_pendingProfits),
                          style: GoogleFonts.cairo(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFf72585),
                            shadows: [
                              Shadow(
                                color: const Color(
                                  0xFFf72585,
                                ).withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 3),
                      ],
                    ),
                  ),

                  // تفصيل الطلبات
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // الطلبات النشطة
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(
                              FontAwesomeIcons.clock,
                              color: Color(0xFFffc107),
                              size: 10,
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // قيد التوصيل
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(
                              FontAwesomeIcons.truck,
                              color: Color(0xFF007bff),
                              size: 10,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // بناء زر سحب الأرباح
  Widget buildWithdrawButton() {
    bool canWithdraw = _realizedProfits >= 1000;

    return GestureDetector(
      onTap: canWithdraw ? () => context.push('/withdraw') : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: MediaQuery.of(context).size.width * 0.9,
        height: 55,
        decoration: BoxDecoration(
          gradient: canWithdraw
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFe6b31e), Color(0xFFffd700)],
                )
              : const LinearGradient(
                  colors: [Color(0xFF6c757d), Color(0xFF6c757d)],
                ),
          borderRadius: BorderRadius.circular(27),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: canWithdraw
              ? [
                  BoxShadow(
                    color: const Color(0xFFe6b31e).withValues(alpha: 0.25),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.moneyBillWave,
              color: const Color(0xFF1a1a2e),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              canWithdraw
                  ? 'سحب الأرباح (${NumberFormatter.formatCurrency(_realizedProfits)} متاحة)'
                  : 'الحد الأدنى للسحب ${NumberFormatter.formatCurrency(1000)}',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1a1a2e),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بناء زر سجل السحب
  Widget buildWithdrawalHistoryButton() {
    return GestureDetector(
      onTap: () {
        // الانتقال لصفحة سجل السحب
        context.push('/profits/withdrawal-history');
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(color: const Color(0xFF17a2b8), width: 2),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              FontAwesomeIcons.clockRotateLeft,
              color: Color(0xFF17a2b8),
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              'سجل السحب',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF17a2b8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بناء زر الإحصائيات
  Widget buildStatisticsButton() {
    return GestureDetector(
      onTap: () {
        // الانتقال لصفحة الإحصائيات
        context.go('/statistics');
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 55,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6f42c1), Color(0xFF5a2d91)],
          ),
          borderRadius: BorderRadius.circular(27),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6f42c1).withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              FontAwesomeIcons.chartBar,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'الإحصائيات التفصيلية',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
