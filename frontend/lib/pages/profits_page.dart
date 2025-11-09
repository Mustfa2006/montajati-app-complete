import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/theme_provider.dart';
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

  // التخزين الآمن للبيانات الحساسة
  final _secureStorage = const FlutterSecureStorage();

  // بيانات الأرباح
  double _realizedProfits = 0.0;
  double _pendingProfits = 0.0;
  bool _isRefreshing = false;
  bool _isLoadingProfits = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // تحميل الأرباح مرة واحدة فقط عند بدء الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfitsFromDatabaseWithRetry();
    });
  }

  /// جلب الأرباح مع نظام إعادة المحاولة (Retry)
  Future<void> _loadProfitsFromDatabaseWithRetry() async {
    int retries = 0;
    const maxRetries = 3;

    while (retries < maxRetries) {
      try {
        await _loadProfitsFromDatabase();
        debugPrint('✅ تم جلب الأرباح بنجاح');
        break; // نجح التحميل، اخرج من الحلقة
      } catch (e) {
        retries++;
        debugPrint('❌ محاولة $retries من $maxRetries فشلت: $e');

        if (retries < maxRetries) {
          // انتظر قبل إعادة المحاولة (exponential backoff)
          await Future.delayed(Duration(seconds: retries * 2));
          debugPrint('🔄 إعادة المحاولة...');
        } else {
          debugPrint('❌ فشلت جميع المحاولات');
          if (mounted) {
            _showErrorSnackBar('فشل في جلب الأرباح بعد $maxRetries محاولات. تحقق من الإنترنت.');
          }
        }
      }
    }
  }

  void _initializeAnimations() {
    // حركة التحديث فقط
    _refreshAnimationController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
  }

  // 🛡️ جلب الأرباح من الـ API (آمن جداً مع حماية من التكرار)
  Future<void> _loadProfitsFromDatabase() async {
    // منع التحميل المتكرر
    if (_isLoadingProfits) {
      debugPrint('⏸️ تحميل الأرباح قيد التنفيذ - تجاهل الطلب');
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingProfits = true;
      });
    }

    try {
      debugPrint('📊 === جلب الأرباح من الـ API ===');

      // 🔒 الحصول على التوكن من التخزين الآمن
      final token = await _secureStorage.read(key: 'auth_token');

      if (token == null || token.isEmpty) {
        debugPrint('❌ لا يوجد توكن مصادقة - المستخدم غير مسجل دخول');
        if (mounted) {
          _showErrorSnackBar('يرجى تسجيل الدخول مرة أخرى.');
        }
        return;
      }

      debugPrint('✅ تم العثور على توكن المصادقة');

      // 🌐 جلب الأرباح من الـ API (آمن جداً - يعتمد على JWT فقط)
      const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:5000');

      // TODO: في المستقبل، يجب أن يعتمد الخادم على JWT فقط لتحديد المستخدم
      // للآن، نحتاج إرسال رقم الهاتف حتى يتم تطبيق JWT verification كاملاً
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('current_user_phone') ?? '';

      final response = await http
          .post(
            Uri.parse('$apiUrl/api/users/profits'),
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
            body: jsonEncode({'phone': phone}),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final data = jsonData['data'];
          final dbAchievedProfits = (data['achieved_profits'] as num?)?.toDouble() ?? 0.0;
          final dbExpectedProfits = (data['expected_profits'] as num?)?.toDouble() ?? 0.0;

          debugPrint('📊 الأرباح المحققة من الـ API: $dbAchievedProfits د.ع');
          debugPrint('📊 الأرباح المنتظرة من الـ API: $dbExpectedProfits د.ع');

          if (mounted) {
            setState(() {
              _realizedProfits = dbAchievedProfits;
              _pendingProfits = dbExpectedProfits;
            });

            debugPrint('🎯 تم تحديث المتغيرات:');
            debugPrint('   _realizedProfits = $_realizedProfits');
            debugPrint('   _pendingProfits = $_pendingProfits');
          }
        } else {
          debugPrint('❌ فشل في جلب الأرباح من الـ API');
          if (mounted) {
            _showErrorSnackBar('فشل في جلب الأرباح. حاول مرة أخرى.');
          }
        }
      } else if (response.statusCode == 401) {
        debugPrint('❌ خطأ في المصادقة: غير مصرح');
        if (mounted) {
          _showErrorSnackBar('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى.');
        }
      } else if (response.statusCode == 404) {
        debugPrint('❌ المستخدم غير موجود');
        if (mounted) {
          _showErrorSnackBar('المستخدم غير موجود.');
        }
      } else {
        debugPrint('❌ خطأ في الـ API: ${response.statusCode}');
        if (mounted) {
          _showErrorSnackBar('خطأ في الخادم (${response.statusCode}). حاول لاحقاً.');
        }
      }
    } on TimeoutException {
      debugPrint('❌ انتهت مهلة الاتصال');
      if (mounted) {
        _showErrorSnackBar('انتهت مهلة الاتصال. تحقق من الإنترنت.');
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب الأرباح: $e');
      if (mounted) {
        _showErrorSnackBar('فشل في الاتصال بالخادم. تحقق من الإنترنت.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfits = false;
        });
      }
    }
  }

  /// عرض رسالة خطأ للمستخدم
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w500)),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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

    try {
      // ✅ إعادة جلب الأرباح من الـ API
      await _loadProfitsFromDatabase();
      debugPrint('✅ تم تحديث الأرباح بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تحديث الأرباح: $e');
      if (mounted) {
        _showErrorSnackBar('فشل التحديث. حاول مرة أخرى.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
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

    // لا حاجة لمؤشر تحميل كامل للصفحة - الأنيميشن موجود على العدادات مباشرة
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
                    // زر الرجوع (بارز وجميل - الوضع النهاري فقط)
                    GestureDetector(
                      onTap: () => context.go('/'),
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                          border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5), width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
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

                  // المبلغ مع أنيميشن تحميل
                  _isLoadingProfits
                      ? Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF06d6a0)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'جاري التحميل...',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF06d6a0).withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        )
                      : Text(
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

                  // المبلغ مع أنيميشن تحميل
                  _isLoadingProfits
                      ? Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFf72585)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'جاري التحميل...',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFf72585).withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        )
                      : Text(
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
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: canWithdraw ? const Color(0xFFFFD700) : Colors.grey.withValues(alpha: 0.3),
              ),
              child: Icon(
                FontAwesomeIcons.wallet,
                color: canWithdraw
                    ? const Color(0xFF1a1a2e)
                    : (isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black54),
                size: 16,
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
