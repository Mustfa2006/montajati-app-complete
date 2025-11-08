import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/theme_provider.dart';
import '../services/lazy_loading_service.dart';
import '../services/simple_orders_service.dart';
import '../utils/number_formatter.dart';
import '../utils/theme_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/curved_navigation_bar.dart';

class ProfitsPage extends StatefulWidget {
  const ProfitsPage({super.key});

  @override
  State<ProfitsPage> createState() => _ProfitsPageState();
}

class _ProfitsPageState extends State<ProfitsPage> with TickerProviderStateMixin {
  // متحكم الحركة للتحديث فقط
  late AnimationController _refreshAnimationController;

  // بيانات الأرباح
  double _realizedProfits = 0.0;
  double _pendingProfits = 0.0;
  int _completedOrders = 0;
  int _activeOrders = 0;
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
      _checkForRefreshParameter(); // التحقق من parameter التحديث
    });

    // تحميل فوري للأرباح كخطة احتياطية
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _realizedProfits == 0.0 && _pendingProfits == 0.0) {
        debugPrint('🔄 تحميل احتياطي للأرباح...');
        _loadProfitsFromDatabase();
      }
    }).catchError((error) {
      debugPrint('❌ خطأ في التحميل الاحتياطي: $error');
    });
  }

  /// التحقق من parameter التحديث وتحديث البيانات إذا لزم الأمر
  void _checkForRefreshParameter() {
    try {
      final uri = Uri.base;
      if (uri.queryParameters.containsKey('refresh')) {
        debugPrint('🔄 تم طلب تحديث صفحة الأرباح من parameter');
        // تحديث البيانات فوراً بدون تأخير
        if (mounted) {
          refreshProfits();
        }
        // تحديث إضافي للتأكد
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _loadProfitsFromDatabase();
          }
        });
      } else {
        // حتى لو لم يكن هناك parameter، قم بالتحديث للتأكد
        debugPrint('🔄 تحديث تلقائي للأرباح عند دخول الصفحة');
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _loadProfitsFromDatabase();
          }
        });
      }
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من parameter التحديث: $e');
      // في حالة الخطأ، قم بالتحديث على أي حال
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _loadProfitsFromDatabase();
        }
      });
    }
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

  void _initializeAnimations() {
    // حركة التحديث فقط
    _refreshAnimationController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
  }

  // تحميل وحساب الأرباح من الطلبات الفعلية
  Future<void> _loadAndCalculateProfits() async {
    try {
      // تحميل الطلبات من قاعدة البيانات
      await _ordersService.loadOrders();

      await _loadProfitsFromDatabase();
    } catch (e) {
      debugPrint('خطأ في تحميل الطلبات: $e');
    }
  }

  // 🛡️ جلب الأرباح مباشرة من قاعدة البيانات (مع حماية من التكرار)
  bool _isLoadingProfits = false;

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

      // جلب الأرباح من قاعدة البيانات
      final response = await Supabase.instance.client
          .from('users')
          .select('achieved_profits, expected_profits, name')
          .eq('phone', currentUserPhone)
          .maybeSingle();

      if (response != null) {
        final dbAchievedProfits = (response['achieved_profits'] as num?)?.toDouble() ?? 0.0;
        final dbExpectedProfits = (response['expected_profits'] as num?)?.toDouble() ?? 0.0;
        final userName = response['name'] ?? 'مستخدم';

        debugPrint('📊 الأرباح المحققة من قاعدة البيانات: $dbAchievedProfits د.ع');
        debugPrint('📊 الأرباح المنتظرة من قاعدة البيانات: $dbExpectedProfits د.ع');
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
        }
      } else {
        debugPrint('❌ لم يتم العثور على المستخدم في قاعدة البيانات');
        if (mounted) {
          setState(() {
            _realizedProfits = 0.0;
            _pendingProfits = 0.0;
          });
        }
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
      final totalOrdersResponse = await Supabase.instance.client.from('orders').select('id');

      debugPrint('📊 إجمالي الطلبات في قاعدة البيانات: ${totalOrdersResponse.length}');

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
          debugPrint('   ${order['primary_phone']} - ${order['customer_name']}');
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
    if (_isRefreshing || !mounted) return;

    setState(() {
      _isRefreshing = true;
    });

    _refreshAnimationController
        .forward()
        .then((_) {
          if (mounted) {
            _refreshAnimationController.reset();
          }
        })
        .catchError((error) {
          debugPrint('❌ خطأ في animation: $error');
        });

    // محاكاة تحديث البيانات
    await Future.delayed(const Duration(seconds: 1));

    // ✅ إعادة جلب الأرباح من قاعدة البيانات
    if (mounted) {
      await _loadProfitsFromDatabase();
    }

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  void dispose() {
    // إيقاف animation controller بأمان
    try {
      _refreshAnimationController.stop();
      _refreshAnimationController.dispose();
    } catch (e) {
      debugPrint('❌ خطأ في dispose refresh animation: $e');
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

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
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AppBackground(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // مساحة للشريط العلوي
              const SizedBox(height: 25),

              // ✨ شريط علوي بسيط (ضمن المحتوى)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // زر الرجوع
                    GestureDetector(
                      onTap: () => context.go('/'),
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.05)],
                          ),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Icon(Icons.arrow_back_ios_new, color: Colors.white.withValues(alpha: 0.9), size: 20),
                          ),
                        ),
                      ),
                    ),

                    // العنوان في المنتصف
                    Expanded(
                      child: Text(
                        'الأرباح',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFFD700),
                        ),
                      ),
                    ),

                    // مساحة فارغة للتوازن
                    const SizedBox(width: 45),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // بطاقة الأرباح المحققة
              buildRealizedProfitsCard(isDark),

              const SizedBox(height: 20),

              // بطاقة الأرباح المنتظرة
              buildPendingProfitsCard(isDark),

              const SizedBox(height: 30),

              // زر سحب الأرباح
              buildWithdrawButton(isDark),

              const SizedBox(height: 20),

              // أزرار سجل السحب والإحصائيات جنب بعض
              buildBottomButtonsRow(isDark),

              // مساحة إضافية للشريط السفلي
              const SizedBox(height: 160),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: 2, // الأرباح
        items: <Widget>[
          Icon(Icons.storefront_outlined, size: 28, color: Color(0xFFFFD700)),
          Icon(Icons.receipt_long_outlined, size: 28, color: Color(0xFFFFD700)),
          Icon(Icons.trending_up_outlined, size: 28, color: Color(0xFFFFD700)),
          Icon(Icons.person_outline, size: 28, color: Color(0xFFFFD700)),
        ],
        color: const Color(0xFF2D3748),
        buttonBackgroundColor: const Color(0xFF1A202C),
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOut,
        animationDuration: Duration(milliseconds: 600),
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

  // بناء بطاقة الأرباح المحققة
  Widget buildRealizedProfitsCard(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: ThemeColors.cardBackground(isDark),
        border: Border.all(color: const Color(0xFF06d6a0).withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Row(
          children: [
            // الأيقونة المتحركة للأرباح المحققة (مكبرة بدون مربع)
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Lottie.asset(
                  'assets/animations/wallet_animation.json',
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  repeat: true,
                  animate: true,
                ),
              ),
            ),

            const SizedBox(width: 20),

            // المحتوى النصي
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // العنوان
                  Text(
                    'الأرباح المحققة',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ThemeColors.textColor(isDark),
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // المبلغ
                  Text(
                    NumberFormatter.formatCurrency(_realizedProfits),
                    style: GoogleFonts.cairo(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF06d6a0),
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 5),

                  // الوصف
                  Text(
                    'من الطلبات المكتملة',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: ThemeColors.secondaryTextColor(isDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بناء بطاقة الأرباح المنتظرة
  Widget buildPendingProfitsCard(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: ThemeColors.cardBackground(isDark),
        border: Border.all(color: const Color(0xFFf72585).withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // الأيقونة المتحركة للأرباح المنتظرة (مكبرة)
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Lottie.asset(
                  'assets/animations/shipping_truck.json',
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  repeat: true,
                  animate: true,
                ),
              ),
            ),

            const SizedBox(width: 16),

            // المحتوى النصي
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // العنوان
                  Text(
                    'الأرباح المتوقعة',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ThemeColors.textColor(isDark),
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // المبلغ
                  Text(
                    NumberFormatter.formatCurrency(_pendingProfits),
                    style: GoogleFonts.cairo(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFf72585),
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 5),

                  // الوصف
                  Text(
                    'من الطلبات قيد التوصيل و النشط',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: ThemeColors.secondaryTextColor(isDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✨ زر سحب الأرباح المحدث
  Widget buildWithdrawButton(bool isDark) {
    bool canWithdraw = _realizedProfits >= 1000;

    return GestureDetector(
      onTap: canWithdraw ? () => context.push('/withdraw') : null,
      child: Container(
        width: double.infinity,
        height: 65,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: ThemeColors.cardBackground(isDark),
          border: Border.all(
            color: canWithdraw ? const Color(0xFF28a745).withValues(alpha: 0.4) : ThemeColors.cardBorder(isDark),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: canWithdraw
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [const Color(0xFFFFD700), const Color(0xFFFFA500), const Color(0xFFFF8C00)],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey.withValues(alpha: 0.6),
                          Colors.grey.withValues(alpha: 0.4),
                          Colors.grey.withValues(alpha: 0.3),
                        ],
                      ),
                boxShadow: canWithdraw
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: const Color(0xFFFFA500).withValues(alpha: 0.3),
                          blurRadius: 25,
                          offset: const Offset(0, 15),
                          spreadRadius: 5,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Icon(
                FontAwesomeIcons.wallet,
                color: canWithdraw
                    ? const Color(0xFF1a1a2e)
                    : (isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black54),
                size: 20,
              ),
            ),
            const SizedBox(width: 15),
            Flexible(
              child: Text(
                canWithdraw
                    ? 'سحب الأرباح (${NumberFormatter.formatCurrency(_realizedProfits)} )'
                    : 'الحد الأدنى للسحب ${NumberFormatter.formatCurrency(1000)}',
                style: GoogleFonts.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: canWithdraw ? const Color(0xFFFFD700) : ThemeColors.secondaryTextColor(isDark),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✨ صف الأزرار السفلية (سجل السحب والإحصائيات)
  Widget buildBottomButtonsRow(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // زر سجل السحب
          Expanded(child: buildCompactWithdrawalHistoryButton(isDark)),
          const SizedBox(width: 15),
          // زر الإحصائيات
          Expanded(child: buildCompactStatisticsButton(isDark)),
        ],
      ),
    );
  }

  // ✨ زر سجل السحب المدمج
  Widget buildCompactWithdrawalHistoryButton(bool isDark) {
    return GestureDetector(
      onTap: () {
        context.push('/profits/withdrawal-history');
      },
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: ThemeColors.cardBackground(isDark),
          border: Border.all(color: const Color(0xFF17a2b8).withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FontAwesomeIcons.clockRotateLeft, color: const Color(0xFF17a2b8), size: 18),
            const SizedBox(width: 10),
            Text(
              'سجل السحب',
              style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF17a2b8)),
            ),
          ],
        ),
      ),
    );
  }

  // ✨ زر الإحصائيات المدمج
  Widget buildCompactStatisticsButton(bool isDark) {
    return GestureDetector(
      onTap: () {
        context.go('/statistics');
      },
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: ThemeColors.cardBackground(isDark),
          border: Border.all(color: const Color(0xFF6f42c1).withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FontAwesomeIcons.chartLine, color: const Color(0xFF6f42c1), size: 18),
            const SizedBox(width: 10),
            Text(
              'الإحصائيات',
              style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF6f42c1)),
            ),
          ],
        ),
      ),
    );
  }
}
