import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/theme_provider.dart';
import '../utils/number_formatter.dart';
import '../utils/theme_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/custom_notification.dart';

class WithdrawPage extends StatefulWidget {
  const WithdrawPage({super.key});

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
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

  @override
  void initState() {
    super.initState();
    _loadUserProfits();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    _cardHolderController.dispose();
    _cardNumberController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfits() async {
    try {
      setState(() => _isLoadingBalance = true);

      final prefs = await SharedPreferences.getInstance();
      String? currentUserPhone = prefs.getString('current_user_phone');

      if (currentUserPhone == null || currentUserPhone.isEmpty) {
        setState(() {
          _availableBalance = 0.0;
          _isLoadingBalance = false;
        });
        return;
      }

      final response = await Supabase.instance.client
          .from('users')
          .select('achieved_profits, name, id')
          .eq('phone', currentUserPhone)
          .maybeSingle();

      if (response != null) {
        final achievedProfits = (response['achieved_profits'] as num?)?.toDouble() ?? 0.0;

        await prefs.setString('current_user_id', response['id']);
        await prefs.setString('current_user_name', response['name'] ?? 'مستخدم');

        setState(() {
          _availableBalance = achievedProfits;
          _isLoadingBalance = false;
        });
      } else {
        // المستخدم غير موجود - لا ننشئ حساب جديد
        setState(() {
          _availableBalance = 0.0;
          _isLoadingBalance = false;
        });
      }
    } catch (e) {
      setState(() {
        _availableBalance = 0.0;
        _isLoadingBalance = false;
      });
    }
  }

  /// التحقق من الرصيد في قاعدة البيانات قبل السحب (حماية من التلاعب)
  Future<bool> _verifyBalanceInDatabase(double requestedAmount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? currentUserPhone = prefs.getString('current_user_phone');

      if (currentUserPhone == null || currentUserPhone.isEmpty) {
        throw Exception('لا يوجد مستخدم مسجل دخول');
      }

      // جلب الرصيد الحقيقي من قاعدة البيانات
      final response = await Supabase.instance.client
          .from('users')
          .select('achieved_profits')
          .eq('phone', currentUserPhone)
          .maybeSingle();

      if (response == null) {
        throw Exception('المستخدم غير موجود في النظام');
      }

      final actualBalance = (response['achieved_profits'] as num?)?.toDouble() ?? 0.0;

      debugPrint('🔍 التحقق من الرصيد:');
      debugPrint('   المبلغ المطلوب: $requestedAmount د.ع');
      debugPrint('   الرصيد الفعلي: $actualBalance د.ع');

      // التحقق من كفاية الرصيد
      if (requestedAmount > actualBalance) {
        throw Exception('المبلغ المطلوب ($requestedAmount د.ع) أكبر من الرصيد المتاح ($actualBalance د.ع)');
      }

      // تحديث الرصيد المعروض إذا كان مختلف
      if (_availableBalance != actualBalance) {
        setState(() {
          _availableBalance = actualBalance;
        });
      }

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

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Scaffold(
      backgroundColor: Colors.transparent,
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
                        borderRadius: BorderRadius.circular(15),
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
                        borderRadius: BorderRadius.circular(15),
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
          Icon(FontAwesomeIcons.mobileScreenButton, color: const Color(0xFFFF9800), size: 40),
          const SizedBox(height: 15),
          Text(
            'رقم الهاتف',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _phoneController,
            enabled: false, // معطل
            style: GoogleFonts.robotoMono(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.4),
              letterSpacing: 1,
            ),
            decoration: InputDecoration(
              hintText: '07XXXXXXXX',
              hintStyle: GoogleFonts.robotoMono(
                fontSize: 18,
                color: Colors.white.withValues(alpha: 0.3),
                letterSpacing: 1,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
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
          const SizedBox(height: 12),
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.5), width: 1),
            ),
            child: TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w700, color: ThemeColors.textColor(isDark)),
              decoration: InputDecoration(
                hintText: 'أدخل المبلغ (الحد الأدنى ${NumberFormatter.formatCurrency(1000)})',
                hintStyle: GoogleFonts.cairo(color: ThemeColors.secondaryTextColor(isDark), fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                prefixIcon: const Icon(FontAwesomeIcons.coins, color: Color(0xFFffd700), size: 18),
                suffixText: 'د.ع',
                suffixStyle: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFffd700),
                ),
              ),
              onChanged: (value) => setState(() {}),
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
          boxShadow: canSubmit
              ? [BoxShadow(color: const Color(0x60ffd700), blurRadius: 30, offset: const Offset(0, 15))]
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
            Text(
              isLoading ? 'جاري المعالجة...' : 'تأكيد طلب السحب',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: canSubmit ? const Color(0xFF1a1a2e) : ThemeColors.secondaryTextColor(isDark),
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

      // 3. التحقق المزدوج من الرصيد
      final currentBalance = await _getCurrentBalance();
      if (currentBalance < amount) {
        throw Exception('الرصيد غير كافي. الرصيد الحالي: ${NumberFormatter.formatCurrency(currentBalance)}');
      }

      // 4. بدء معاملة قاعدة البيانات الآمنة
      final result = await _executeSecureWithdrawTransaction(
        transactionId: transactionId,
        amount: amount,
        netAmount: netAmount,
        accountNumber: accountNumber,
        currentBalance: currentBalance,
      );

      if (result['success']) {
        if (mounted) {
          // عرض إشعار النجاح المخصص
          CustomNotification.showSuccess(context, 'تم اجراء عملية السحب بنجاح');

          // الانتظار قليلاً ثم الانتقال مع تحديث صفحة الأرباح
          await Future.delayed(const Duration(milliseconds: 2000));
          if (mounted) {
            // العودة لصفحة الأرباح مع إجبار التحديث
            context.go('/profits?refresh=true');
          }
        }
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      if (mounted) {
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

        CustomNotification.showError(context, errorMessage);
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

  // 💰 الحصول على الرصيد الحالي
  Future<double> _getCurrentBalance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? currentUserPhone = prefs.getString('current_user_phone');

      if (currentUserPhone == null || currentUserPhone.isEmpty) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      final response = await Supabase.instance.client
          .from('users')
          .select('achieved_profits')
          .eq('phone', currentUserPhone)
          .single();

      return (response['achieved_profits'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      throw Exception('فشل في الحصول على الرصيد الحالي: $e');
    }
  }

  // 🔐 تنفيذ معاملة السحب الآمنة
  Future<Map<String, dynamic>> _executeSecureWithdrawTransaction({
    required String transactionId,
    required double amount,
    required double netAmount,
    required String accountNumber,
    required double currentBalance,
  }) async {
    try {
      // الحصول على معرف المستخدم من SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String? currentUserPhone = prefs.getString('current_user_phone');
      String? userId = prefs.getString('current_user_id');

      if (currentUserPhone == null || userId == null) {
        throw Exception('معرف المستخدم غير صحيح');
      }

      // 1. إنشاء طلب السحب
      String accountDetails = selectedMethod == 'ki_card'
          ? 'بطاقة كي كارد - ${_cardHolderController.text} - $accountNumber'
          : 'زين كاش - $accountNumber';

      await Supabase.instance.client.from('withdrawal_requests').insert({
        'user_id': userId,
        'amount': amount,
        'withdrawal_method': selectedMethod == 'ki_card' ? 'بطاقة كي كارد' : 'زين كاش',
        'account_details': accountDetails,
        'status': 'pending',
      });

      // 2. سحب المبلغ من الأرباح باستخدام الدالة الآمنة
      final withdrawResult = await Supabase.instance.client.rpc(
        'safe_withdraw_profits',
        params: {'p_user_phone': currentUserPhone, 'p_amount': amount, 'p_authorized_by': 'USER_WITHDRAWAL'},
      );

      if (withdrawResult == null || withdrawResult['success'] != true) {
        throw Exception('فشل في خصم المبلغ من الأرباح: ${withdrawResult?['error'] ?? 'خطأ غير معروف'}');
      }

      return {'success': true, 'message': 'تم إنجاز المعاملة بنجاح'};
    } catch (e) {
      return {'success': false, 'message': 'فشل في تنفيذ المعاملة: $e'};
    }
  }
}
