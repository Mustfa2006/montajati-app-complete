import 'dart:async';
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
import '../utils/number_formatter.dart';
import '../utils/theme_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/custom_notification.dart';
import '../widgets/error_animation_widget.dart';
import '../widgets/success_animation_widget.dart';

class WithdrawPage extends StatefulWidget {
  const WithdrawPage({super.key});

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> with WidgetsBindingObserver {
  // بيانات المستخدم
  double _availableBalance = 0.0;
  bool _isLoadingBalance = true;

  // متحكمات النموذج
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();

  // متغيرات النموذج
  String selectedMethod = 'ki_card'; // ki_card, zain_cash
  bool agreeToTerms = true;
  bool isLoading = false;

  // بيانات البطاقة
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // 🔒 حالة السحب
  bool _isWithdrawalEnabled = true;
  String _withdrawalMessage = 'عملية السحب متاحة حالياً';

  // 📦 SharedPreferences instance واحد
  SharedPreferences? _prefs;
  String? _currentUserPhone;

  // 💾 كاش الرصيد لتقليل الطلبات
  double? _cachedBalance;
  DateTime? _balanceCacheTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // ✅ التحقق من القفل أولاً قبل أي شيء
    _initializePage();
  }

  // 🔄 مراقبة حالة التطبيق (عند العودة للصفحة)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('🔄 التطبيق عاد للواجهة - التحقق من حالة السحب');
      _checkWithdrawalStatus();
    }
  }

  // 🚀 تهيئة الصفحة
  Future<void> _initializePage() async {
    try {
      // 1️⃣ تحميل SharedPreferences مرة واحدة
      _prefs = await SharedPreferences.getInstance();
      _currentUserPhone = _prefs?.getString('current_user_phone');

      // 2️⃣ التحقق من القفل أولاً (أسرع)
      await _checkWithdrawalStatus();

      // 3️⃣ ثم تحميل الرصيد
      if (mounted) {
        await _loadUserProfits();
      }
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة الصفحة: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _amountController.dispose();
    _accountController.dispose();
    _cardHolderController.dispose();
    _cardNumberController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // 🔒 التحقق من حالة السحب من الباك اند
  Future<void> _checkWithdrawalStatus() async {
    try {
      debugPrint('🔍 === التحقق من حالة السحب ===');

      final response = await http
          .get(Uri.parse('${ApiConfig.usersUrl}/withdrawal-status'), headers: ApiConfig.defaultHeaders)
          .timeout(ApiConfig.defaultTimeout);

      debugPrint('📡 استجابة الخادم: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        debugPrint('📊 البيانات المستلمة: $jsonData');

        if (jsonData['success'] == true && mounted) {
          setState(() {
            _isWithdrawalEnabled = jsonData['enabled'] ?? true;
            _withdrawalMessage = jsonData['message'] ?? 'عملية السحب متاحة حالياً';
          });

          debugPrint('✅ حالة السحب: ${_isWithdrawalEnabled ? "مفعل" : "معطل"}');
          debugPrint('📝 الرسالة: $_withdrawalMessage');
        }
      }
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من حالة السحب: $e');
      // في حالة الخطأ، نسمح بالسحب افتراضياً
      if (mounted) {
        setState(() {
          _isWithdrawalEnabled = true;
          _withdrawalMessage = 'عملية السحب متاحة حالياً';
        });
      }
    }
  }

  // 🔒 جلب رصيد المستخدم من الباك اند (آمن جداً - بدون إرسال رقم الهاتف)
  Future<void> _loadUserProfits() async {
    try {
      if (mounted) setState(() => _isLoadingBalance = true);

      debugPrint('💰 === جلب رصيد المستخدم من الـ API ===');

      // ✅ استخدام JWT فقط - السيرفر يحدد المستخدم من التوكن
      final response = await http
          .get(Uri.parse('${ApiConfig.usersUrl}/balance'), headers: ApiConfig.defaultHeaders)
          .timeout(ApiConfig.defaultTimeout);

      debugPrint('📡 استجابة الخادم: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        debugPrint('📊 البيانات المستلمة: $jsonData');

        if (jsonData['success'] == true) {
          final balance = (jsonData['balance'] as num?)?.toDouble() ?? 0.0;
          final userId = jsonData['user_id'] ?? '';
          final userName = jsonData['user_name'] ?? 'مستخدم';
          final userPhone = jsonData['phone'] ?? '';

          debugPrint('💰 الرصيد المستلم: $balance د.ع');
          debugPrint('👤 معرف المستخدم: $userId');
          debugPrint('📝 اسم المستخدم: $userName');

          // حفظ بيانات المستخدم
          if (_prefs != null) {
            await _prefs!.setString('current_user_id', userId);
            await _prefs!.setString('current_user_name', userName ?? 'مستخدم');
            await _prefs!.setString('current_user_phone', userPhone);
            _currentUserPhone = userPhone;
          }

          if (mounted) {
            setState(() {
              _availableBalance = balance;
              _isLoadingBalance = false;
            });
          }
        } else {
          debugPrint('❌ فشل في جلب الرصيد: ${jsonData['error']}');
          if (mounted) {
            setState(() {
              _availableBalance = 0.0;
              _isLoadingBalance = false;
            });
          }
        }
      } else {
        debugPrint('❌ خطأ في الخادم: ${response.statusCode}');
        if (mounted) {
          setState(() {
            _availableBalance = 0.0;
            _isLoadingBalance = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب الرصيد: $e');
      if (mounted) {
        setState(() {
          _availableBalance = 0.0;
          _isLoadingBalance = false;
        });
      }
    }
  }

  /// 🔒 التحقق من الرصيد من الباك اند قبل السحب (حماية من التلاعب + كاش ذكي)
  Future<bool> _verifyBalanceInDatabase(double requestedAmount) async {
    try {
      debugPrint('🔍 === التحقق من الرصيد ===');
      debugPrint('   المبلغ المطلوب: $requestedAmount د.ع');

      // ✅ استخدام الكاش إذا كان حديثاً (أقل من 10 ثواني)
      final now = DateTime.now();
      if (_cachedBalance != null && _balanceCacheTime != null) {
        final cacheAge = now.difference(_balanceCacheTime!);
        if (cacheAge.inSeconds < 10) {
          debugPrint('� استخدام الرصيد من الكاش: $_cachedBalance د.ع (عمر الكاش: ${cacheAge.inSeconds}ث)');

          if (requestedAmount > _cachedBalance!) {
            throw Exception('المبلغ المطلوب ($requestedAmount د.ع) أكبر من الرصيد المتاح ($_cachedBalance د.ع)');
          }

          return true;
        }
      }

      // 🌐 جلب الرصيد الحقيقي من الـ API (استخدام JWT فقط - بدون إرسال phone)
      debugPrint('🌐 جلب الرصيد من السيرفر...');
      final response = await http
          .get(Uri.parse('${ApiConfig.usersUrl}/balance'), headers: ApiConfig.defaultHeaders)
          .timeout(ApiConfig.defaultTimeout);

      if (response.statusCode != 200) {
        throw Exception('فشل في الاتصال بالخادم');
      }

      final jsonData = jsonDecode(response.body);

      if (jsonData['success'] != true) {
        throw Exception(jsonData['error'] ?? 'خطأ في جلب الرصيد');
      }

      final actualBalance = (jsonData['balance'] as num?)?.toDouble() ?? 0.0;

      debugPrint('   الرصيد الفعلي: $actualBalance د.ع');

      // ✅ تحديث الكاش
      _cachedBalance = actualBalance;
      _balanceCacheTime = now;

      // التحقق من كفاية الرصيد
      if (requestedAmount > actualBalance) {
        throw Exception('المبلغ المطلوب ($requestedAmount د.ع) أكبر من الرصيد المتاح ($actualBalance د.ع)');
      }

      // تحديث الرصيد المعروض إذا كان مختلف
      if (_availableBalance != actualBalance && mounted) {
        setState(() {
          _availableBalance = actualBalance;
        });
      }

      debugPrint('✅ التحقق من الرصيد نجح');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من الرصيد: $e');
      rethrow;
    }
  }

  // حساب المبلغ الصافي (بدون رسوم)
  double _getNetAmount(double amount) {
    return amount; // جميع طرق السحب مجانية
  }

  // ✨ إظهار أنيميشن النجاح
  void _showSuccessAnimation() {
    debugPrint('🎬 بدء عرض أنيميشن النجاح');

    if (!mounted) {
      debugPrint('⚠️ الصفحة لم تعد موجودة - لن يتم إظهار الأنيميشن');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => const SuccessAnimationWidget(),
    );

    Timer(const Duration(milliseconds: 2000), () {
      debugPrint('🎬 انتهاء أنيميشن النجاح - إغلاق الحوار');

      if (!mounted) {
        debugPrint('⚠️ الصفحة لم تعد موجودة');
        return;
      }

      try {
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
          debugPrint('✅ تم إغلاق حوار النجاح');
        }

        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            debugPrint('🎬 الانتقال إلى صفحة الأرباح');
            try {
              context.go('/profits?refresh=true');
              debugPrint('✅ تم الانتقال بنجاح إلى صفحة الأرباح');
            } catch (e) {
              debugPrint('❌ خطأ في الانتقال: $e');
            }
          }
        });
      } catch (e) {
        debugPrint('❌ خطأ في إغلاق الحوار أو الانتقال: $e');
      }
    });
  }

  // ❌ إظهار أنيميشن الخطأ
  void _showErrorAnimation() {
    debugPrint('🎬 بدء عرض أنيميشن الخطأ');

    if (!mounted) {
      debugPrint('⚠️ الصفحة لم تعد موجودة - لن يتم إظهار الأنيميشن');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => const ErrorAnimationWidget(),
    );

    Timer(const Duration(milliseconds: 2000), () {
      debugPrint('🎬 انتهاء أنيميشن الخطأ - إغلاق الحوار');

      if (!mounted) {
        debugPrint('⚠️ الصفحة لم تعد موجودة');
        return;
      }

      try {
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
          debugPrint('✅ تم إغلاق حوار الخطأ');
        }
      } catch (e) {
        debugPrint('❌ خطأ في إغلاق الحوار: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          AppBackground(
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
                        // زر الرجوع على اليمين - ذهبي
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: const Color(0xFFffd700).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.3), width: 1),
                            ),
                            child: const Icon(FontAwesomeIcons.arrowRight, color: Color(0xFFffd700), size: 18),
                          ),
                        ),

                        const SizedBox(width: 15),

                        // العنوان في المنتصف
                        Expanded(
                          child: Text(
                            'سحب الأرباح',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFFD700),
                            ),
                          ),
                        ),

                        // مساحة فارغة للتوازن
                        const SizedBox(width: 60),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // المحتوى
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // المبلغ المتاح للسحب
                        _buildAvailableBalance(isDark),

                        const SizedBox(height: 25),

                        // أزرار اختيار نوع البطاقة
                        _buildCardTypeButtons(isDark),

                        const SizedBox(height: 25),

                        // البطاقة البنكية أو حقل الهاتف
                        selectedMethod == 'ki_card' ? _buildMasterCard() : _buildPhoneInput(isDark),

                        const SizedBox(height: 25),

                        // إدخال مبلغ السحب
                        _buildWithdrawAmountInput(isDark),

                        const SizedBox(height: 25),

                        // ملخص السحب
                        _buildWithdrawSummary(isDark),

                        const SizedBox(height: 25),

                        // زر تأكيد السحب
                        _buildConfirmWithdrawButton(isDark),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 🔒 شاشة القفل المضببة الحمراء
          if (!_isWithdrawalEnabled) _buildLockOverlay(isDark),
        ],
      ),
    );
  }

  // 🔒 شاشة القفل المضببة الحمراء
  Widget _buildLockOverlay(bool isDark) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.red.withValues(alpha: 0.15), // تضبيب أحمر خفيف
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // تضبيب قوي
        child: Container(
          color: Colors.red.withValues(alpha: 0.2), // طبقة حمراء إضافية
          child: Stack(
            children: [
              // زر الرجوع في أعلى اليمين
              Positioned(
                top: 40,
                right: 20,
                child: GestureDetector(
                  onTap: () => context.go('/profits'),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFffd700),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFffd700).withValues(alpha: 0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(FontAwesomeIcons.arrowRight, color: Color(0xFF1a1a2e), size: 20),
                  ),
                ),
              ),
              // المحتوى في المنتصف
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1a1a1a) : Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.5), width: 2),
                    boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 5)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // أيقونة القفل
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(FontAwesomeIcons.lock, color: Colors.red, size: 40),
                      ),
                      const SizedBox(height: 25),
                      // الرسالة المخصصة من لوحة التحكم فقط
                      if (_withdrawalMessage.isNotEmpty)
                        Text(
                          _withdrawalMessage,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.red,
                            height: 1.8,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎨 أزرار اختيار نوع البطاقة المذهلة
  Widget _buildCardTypeButtons(bool isDark) {
    return Row(
      children: [
        // زر كي كارد
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => selectedMethod = 'ki_card'),
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: selectedMethod == 'ki_card' ? null : ThemeColors.cardBackground(isDark),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: selectedMethod == 'ki_card'
                      ? Colors.white.withValues(alpha: 0.6)
                      : ThemeColors.cardBorder(isDark),
                  width: selectedMethod == 'ki_card' ? 2 : 1,
                ),
              ),
              child: selectedMethod == 'ki_card'
                  ? Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFffd700), Color(0xFFe6b31e)]),
                        borderRadius: BorderRadius.circular(13), // ✅ تقليل الزاوية من 15 إلى 13
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(FontAwesomeIcons.creditCard, color: Colors.black, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'كي كارد',
                            style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black),
                          ),
                        ],
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(FontAwesomeIcons.creditCard, color: ThemeColors.secondaryIconColor(isDark), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'كي كارد',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: ThemeColors.secondaryTextColor(isDark),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),

        const SizedBox(width: 15),

        // زر زين كاش
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => selectedMethod = 'zain_cash'),
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: selectedMethod == 'zain_cash' ? null : ThemeColors.cardBackground(isDark),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: selectedMethod == 'zain_cash'
                      ? Colors.white.withValues(alpha: 0.6)
                      : ThemeColors.cardBorder(isDark),
                  width: selectedMethod == 'zain_cash' ? 2 : 1,
                ),
              ),
              child: selectedMethod == 'zain_cash'
                  ? Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFffd700), Color(0xFFe6b31e)]),
                        borderRadius: BorderRadius.circular(13), // ✅ تقليل الزاوية من 15 إلى 13
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(FontAwesomeIcons.mobileScreenButton, color: Colors.black, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'زين كاش',
                            style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black),
                          ),
                        ],
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FontAwesomeIcons.mobileScreenButton,
                          color: ThemeColors.secondaryIconColor(isDark),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'زين كاش',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: ThemeColors.secondaryTextColor(isDark),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // 🎨 بطاقة ماستر كارد السوداء
  Widget _buildMasterCard() {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a1a), Color(0xFF2d2d2d), Color(0xFF1a1a1a)],
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الصف الأول: علامة سوبر كي وشعار ماستر كارد
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // علامة سوبر كي العراقية - الصورة الحقيقية
                SizedBox(
                  width: 45,
                  height: 45,
                  child: Image.asset('assets/images/super_key_logo.png', width: 45, height: 45, fit: BoxFit.contain),
                ),

                // شعار ماستر كارد
                SizedBox(
                  width: 50,
                  height: 30,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(color: Color(0xFFEB001B), shape: BoxShape.circle),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(color: Color(0xFFF79E1B), shape: BoxShape.circle),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 35),

            // حقل رقم البطاقة - شريط مقوس بدون إطار
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: const Color(0xFF505050),
                child: TextFormField(
                  controller: _cardNumberController,
                  textAlign: TextAlign.left,
                  style: GoogleFonts.robotoMono(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                  decoration: InputDecoration(
                    hintText: 'XXXXXXXXXX',
                    hintStyle: GoogleFonts.robotoMono(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.4),
                      letterSpacing: 2,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                  onChanged: (value) => setState(() {}),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // حقل اسم حامل البطاقة - شريط مقوس بدون إطار
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: const Color(0xFF505050),
                child: TextFormField(
                  controller: _cardHolderController,
                  textAlign: TextAlign.left,
                  style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'اسم حامل البطاقة',
                    hintStyle: GoogleFonts.cairo(fontSize: 16, color: Colors.white.withValues(alpha: 0.4)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🎨 حقل إدخال رقم الهاتف لزين كاش - غير مفعل
  Widget _buildPhoneInput(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: ThemeColors.cardBackground(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withValues(alpha: 0.6), width: 2),
        boxShadow: isDark
            ? [BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 2)]
            : [BoxShadow(color: Colors.red.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // شريط أحمر "غير مفعل"
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(color: Colors.red.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Text(
              '🚫 غير مفعل في الوقت الحالي',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Icon(FontAwesomeIcons.mobileScreenButton, color: isDark ? const Color(0xFFFF9800) : Colors.black87, size: 40),
          const SizedBox(height: 15),
          Text(
            'رقم الهاتف',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _phoneController,
            enabled: false, // معطل
            style: GoogleFonts.robotoMono(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black54,
              letterSpacing: 1,
            ),
            decoration: InputDecoration(
              hintText: '07XXXXXXXX',
              hintStyle: GoogleFonts.robotoMono(
                fontSize: 18,
                color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black38,
                letterSpacing: 1,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black26),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black26),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
          ),
        ],
      ),
    );
  }

  // 🎨 عرض المبلغ المتاح للسحب
  Widget _buildAvailableBalance(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: ThemeColors.cardBackground(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.3), width: 1),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text(
            'الرصيد المتاح للسحب',
            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600, color: ThemeColors.textColor(isDark)),
          ),
          const SizedBox(height: 15),
          _isLoadingBalance
              ? const CircularProgressIndicator(color: Color(0xFFffd700), strokeWidth: 3)
              : Text(
                  NumberFormatter.formatCurrency(_availableBalance),
                  style: GoogleFonts.cairo(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFFffd700)),
                ),
        ],
      ),
    );
  }

  // 🎨 حقل إدخال مبلغ السحب
  Widget _buildWithdrawAmountInput(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: ThemeColors.cardBackground(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ThemeColors.cardBorder(isDark), width: 1),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المبلغ المطلوب سحبه',
            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600, color: ThemeColors.textColor(isDark)),
          ),
          const SizedBox(height: 20), // ✅ رفع الشريط قليلاً
          ClipRRect(
            borderRadius: BorderRadius.circular(25), // ✅ قص الحواف بشكل مثالي
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                // 🎨 تدرج لوني رهيب وجذاب
                gradient: isDark
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF2d2d2d), // رمادي داكن
                          Color(0xFF1a1a1a), // أسود خفيف
                        ],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFFFFFF), // أبيض نقي
                          Color(0xFFF8F8F8), // أبيض مائل للرمادي
                        ],
                      ),
                // ✅ ظل خفيف وأنيق
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                // ✅ إطار رفيع ومتناسق
                border: Border.all(
                  color: isDark
                      ? const Color(0xFFffd700).withValues(alpha: 0.25) // ذهبي خفيف
                      : const Color(0xFFE0E0E0), // رمادي فاتح
                  width: 1.5,
                ),
              ),
              child: TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: ThemeColors.textColor(isDark),
                  letterSpacing: 0.5,
                ),
                decoration: InputDecoration(
                  hintText: 'أدخل المبلغ',
                  hintStyle: GoogleFonts.cairo(
                    color: ThemeColors.secondaryTextColor(isDark),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Icon(
                      FontAwesomeIcons.coins,
                      color: isDark ? const Color(0xFFffd700) : const Color(0xFF757575),
                      size: 20,
                    ),
                  ),
                  suffixText: 'د.ع',
                  suffixStyle: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFffd700) : const Color(0xFF424242),
                  ),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🎨 ملخص السحب المذهل
  Widget _buildWithdrawSummary(bool isDark) {
    double amount = double.tryParse(_amountController.text) ?? 0;
    double fees = 0.0; // جميع طرق السحب مجانية
    double netAmount = _getNetAmount(amount);

    if (amount == 0) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: ThemeColors.cardBackground(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF28a745).withValues(alpha: 0.3), width: 1),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FontAwesomeIcons.fileInvoiceDollar, color: const Color(0xFF28a745), size: 24),
              const SizedBox(width: 12),
              Text(
                'ملخص السحب',
                style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF28a745)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSummaryRow('المبلغ المطلوب', NumberFormatter.formatCurrency(amount), isDark),
          _buildSummaryRow('رسوم التحويل', NumberFormatter.formatCurrency(fees), isDark),
          Divider(color: isDark ? Colors.white24 : Colors.grey.withValues(alpha: 0.3), height: 30),
          _buildSummaryRow('المبلغ الصافي', NumberFormatter.formatCurrency(netAmount), isDark, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
              color: isTotal ? const Color(0xFF28a745) : ThemeColors.textColor(isDark),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: isTotal ? 20 : 16,
              fontWeight: FontWeight.w800,
              color: isTotal ? const Color(0xFF28a745) : const Color(0xFFffd700),
            ),
          ),
        ],
      ),
    );
  }

  // 🎨 زر تأكيد السحب المذهل
  Widget _buildConfirmWithdrawButton(bool isDark) {
    double amount = double.tryParse(_amountController.text) ?? 0;

    // التحقق من صحة البيانات حسب نوع الطريقة المختارة
    bool hasValidAccount = selectedMethod == 'ki_card'
        ? (_cardNumberController.text.length == 10 && _cardHolderController.text.trim().isNotEmpty)
        : _phoneController.text.length == 11;

    bool canSubmit = amount >= 1000 && amount <= _availableBalance && agreeToTerms && hasValidAccount;

    // 📝 رسالة الخطأ التفاعلية
    String getErrorMessage() {
      if (amount < 1000) return 'المبلغ أقل من الحد الأدنى (1,000 د.ع)';
      if (amount > _availableBalance) return 'المبلغ أكبر من الرصيد المتاح';
      if (selectedMethod == 'ki_card') {
        if (_cardHolderController.text.trim().isEmpty) return 'اسم حامل البطاقة مطلوب';
        if (_cardNumberController.text.length != 10) return 'رقم البطاقة غير صحيح (10 أرقام)';
      }
      if (!agreeToTerms) return 'يجب الموافقة على الشروط والأحكام';
      return 'تأكيد طلب السحب';
    }

    return GestureDetector(
      onTap: canSubmit && !isLoading ? _submitWithdrawRequest : null,
      child: Container(
        width: double.infinity,
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: canSubmit
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFffd700), Color(0xFFe6b31e), Color(0xFFd4af37)],
                )
              : null,
          color: canSubmit ? null : ThemeColors.cardBackground(isDark),
          // ✅ حذف التوهج العالي
          boxShadow: canSubmit
              ? [
                  BoxShadow(
                    color: const Color(0xFFffd700).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(color: Color(0xFF1a1a2e), strokeWidth: 3),
              ),
              const SizedBox(width: 15),
            ] else ...[
              Icon(
                FontAwesomeIcons.paperPlane,
                color: canSubmit ? const Color(0xFF1a1a2e) : ThemeColors.secondaryIconColor(isDark),
                size: 24,
              ),
              const SizedBox(width: 15),
            ],
            // ✅ نص متفاعل حسب الخطأ
            Flexible(
              child: Text(
                isLoading ? 'جاري المعالجة...' : getErrorMessage(),
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: canSubmit ? 18 : 15,
                  fontWeight: FontWeight.w800,
                  color: canSubmit ? const Color(0xFF1a1a2e) : ThemeColors.secondaryTextColor(isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔒 نظام السحب الآمن المتقدم
  void _submitWithdrawRequest() async {
    setState(() => isLoading = true);

    // الحصول على معرف المستخدم من SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('current_user_id');

    // معرف فريد للمعاملة
    final String transactionId = 'WD_${DateTime.now().millisecondsSinceEpoch}_${userId ?? 'unknown'}';

    try {
      // 1. التحقق من صحة البيانات
      final validationResult = await _validateWithdrawData();
      if (!validationResult['isValid']) {
        throw Exception(validationResult['message']);
      }

      double amount = double.tryParse(_amountController.text) ?? 0;
      double netAmount = _getNetAmount(amount);
      String accountNumber = selectedMethod == 'ki_card' ? _cardNumberController.text : _phoneController.text;

      // 2. التحقق من الرصيد في قاعدة البيانات (حماية من التلاعب)
      await _verifyBalanceInDatabase(amount);

      // 3. بدء معاملة قاعدة البيانات الآمنة
      final result = await _executeSecureWithdrawTransaction(
        transactionId: transactionId,
        amount: amount,
        netAmount: netAmount,
        accountNumber: accountNumber,
        currentBalance: _availableBalance,
      );

      if (result['success']) {
        if (mounted) {
          debugPrint('✅ نجح طلب السحب - التحقق من قاعدة البيانات...');

          // 🔍 التحقق من أن الطلب تم إضافته فعلاً في قاعدة البيانات
          try {
            final verifyResponse = await http
                .post(
                  Uri.parse('${ApiConfig.usersUrl}/verify-withdrawal'),
                  headers: ApiConfig.defaultHeaders,
                  body: jsonEncode({
                    'phone': (await SharedPreferences.getInstance()).getString('current_user_phone'),
                    'transaction_id': result['transaction_id'],
                  }),
                )
                .timeout(ApiConfig.defaultTimeout);

            final verifyData = jsonDecode(verifyResponse.body);

            if (verifyData['success'] == true && verifyData['exists'] == true) {
              debugPrint('✅ تم التحقق: الطلب موجود في قاعدة البيانات');
              // ✨ إظهار أنيميشن النجاح
              _showSuccessAnimation();
            } else {
              debugPrint('❌ الطلب غير موجود في قاعدة البيانات');
              // ✨ إظهار أنيميشن الخطأ
              _showErrorAnimation();
            }
          } catch (verifyError) {
            debugPrint('⚠️ خطأ في التحقق من قاعدة البيانات: $verifyError');
            // في حالة فشل التحقق، نعرض أنيميشن النجاح لأن الـ API أرجع نجاح
            _showSuccessAnimation();
          }
        }
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      if (mounted) {
        debugPrint('❌ خطأ في عملية السحب: $e');

        String errorMessage = 'حدث خطأ في السحب، يرجى المحاولة لاحقاً';

        // رسائل خطأ واضحة للمستخدم
        if (e.toString().contains('الرصيد غير كافي')) {
          errorMessage = 'الرصيد غير كافي لإجراء هذه العملية';
        } else if (e.toString().contains('المبلغ المطلوب أكبر من الرصيد المتاح')) {
          errorMessage = 'المبلغ المطلوب أكبر من الرصيد المتاح';
        } else if (e.toString().contains('لا يوجد مستخدم مسجل دخول')) {
          errorMessage = 'يرجى تسجيل الدخول أولاً';
        } else if (e.toString().contains('المستخدم غير موجود')) {
          errorMessage = 'حسابك غير موجود، يرجى التواصل مع الإدارة';
        } else if (e.toString().contains('الاتصال')) {
          errorMessage = 'مشكلة في الاتصال، تحقق من الإنترنت';
        }

        // ✨ إظهار أنيميشن الخطأ
        _showErrorAnimation();

        // عرض رسالة الخطأ بعد الأنيميشن
        Future.delayed(const Duration(milliseconds: 2200), () {
          if (mounted) {
            CustomNotification.showError(context, errorMessage);
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // 🔍 التحقق من صحة البيانات
  Future<Map<String, dynamic>> _validateWithdrawData() async {
    double amount = double.tryParse(_amountController.text) ?? 0;

    // التحقق من المبلغ
    if (amount < 1000) {
      return {'isValid': false, 'message': 'الحد الأدنى للسحب هو ${NumberFormatter.formatCurrency(1000)}'};
    }

    if (amount > _availableBalance) {
      return {'isValid': false, 'message': 'المبلغ أكبر من الرصيد المتاح'};
    }

    // التحقق من رقم الحساب/البطاقة
    if (selectedMethod == 'ki_card') {
      if (_cardNumberController.text.length != 10) {
        return {'isValid': false, 'message': 'رقم البطاقة يجب أن يكون 10 أرقام'};
      }
      if (_cardHolderController.text.trim().isEmpty) {
        return {'isValid': false, 'message': 'اسم حامل البطاقة مطلوب'};
      }
    } else {
      if (_phoneController.text.length != 11) {
        return {'isValid': false, 'message': 'رقم الهاتف يجب أن يكون 11 رقم'};
      }
    }

    return {'isValid': true, 'message': 'البيانات صحيحة'};
  }

  //  تنفيذ معاملة السحب الآمنة عبر الباك اند
  Future<Map<String, dynamic>> _executeSecureWithdrawTransaction({
    required String transactionId,
    required double amount,
    required double netAmount,
    required String accountNumber,
    required double currentBalance,
  }) async {
    try {
      debugPrint('💸 === إرسال طلب السحب إلى الـ API ===');
      debugPrint(' المبلغ: $amount د.ع');
      debugPrint('🏦 الطريقة: $selectedMethod');

      // ✅ إعداد البيانات بدون إرسال رقم الهاتف (السيرفر يحدده من JWT)
      final Map<String, dynamic> requestData = {'amount': amount, 'method': selectedMethod};

      if (selectedMethod == 'ki_card') {
        requestData['card_holder'] = _cardHolderController.text.trim();
        requestData['card_number'] = _cardNumberController.text.trim();
        debugPrint('💳 حامل البطاقة: ${requestData['card_holder']}');
        debugPrint('💳 رقم البطاقة: ${requestData['card_number']}');
      } else {
        requestData['phone_number'] = _phoneController.text.trim();
        debugPrint('📞 رقم الهاتف: ${requestData['phone_number']}');
      }

      // 🌐 إرسال الطلب إلى الـ API (JWT فقط - بدون phone في body)
      final response = await http
          .post(
            Uri.parse('${ApiConfig.usersUrl}/withdraw'),
            headers: ApiConfig.defaultHeaders,
            body: jsonEncode(requestData),
          )
          .timeout(ApiConfig.defaultTimeout);

      debugPrint('📡 استجابة الخادم: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode != 200) {
        final jsonData = jsonDecode(response.body);
        throw Exception(jsonData['error'] ?? 'فشل في إرسال طلب السحب');
      }

      final jsonData = jsonDecode(response.body);

      if (jsonData['success'] != true) {
        throw Exception(jsonData['error'] ?? 'فشل في إرسال طلب السحب');
      }

      debugPrint('✅ تم إرسال طلب السحب بنجاح');
      debugPrint('🆔 معرف المعاملة: ${jsonData['transaction_id']}');
      debugPrint('💰 الرصيد الجديد: ${jsonData['new_balance']} د.ع');

      // تحديث الرصيد المحلي
      if (mounted) {
        setState(() {
          _availableBalance = (jsonData['new_balance'] as num?)?.toDouble() ?? 0.0;
        });
      }

      return {
        'success': true,
        'message': jsonData['message'] ?? 'تم إرسال طلب السحب بنجاح',
        'transaction_id': jsonData['transaction_id'],
        'new_balance': jsonData['new_balance'],
      };
    } catch (e) {
      debugPrint('❌ خطأ في تنفيذ معاملة السحب: $e');
      return {'success': false, 'message': 'فشل في تنفيذ المعاملة: $e'};
    }
  }
}
