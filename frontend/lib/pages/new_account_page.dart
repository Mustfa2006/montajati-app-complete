import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // ✅ SVG Support
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart'; // ✅ Lottie Animation
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../utils/theme_colors.dart';
import '../widgets/app_background.dart';

class NewAccountPage extends StatefulWidget {
  const NewAccountPage({super.key});

  @override
  State<NewAccountPage> createState() => _NewAccountPageState();
}

class _NewAccountPageState extends State<NewAccountPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  final int _currentNavIndex = 4; // الحساب (الخانة الخامسة بعد إضافة المسابقات)

  // بيانات المستخدم
  String _userName = '';
  String _userPhone = '';
  String _joinDate = '';
  int _totalOrders = 0;
  double _totalProfits = 0.0;

  // 📋 السياسات من قاعدة البيانات
  List<Map<String, dynamic>> _policies = [];
  bool _isPoliciesLoading = true;

  // ✅ Animation Controller للوضع الليلي/النهاري
  late AnimationController _themeAnimationController;

  @override
  void initState() {
    super.initState();
    _themeAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _loadUserData();
    _loadPolicies(); // ✅ تحميل السياسات
  }

  @override
  void dispose() {
    _themeAnimationController.dispose();
    super.dispose();
  }

  // 📥 تحميل السياسات من قاعدة البيانات
  Future<void> _loadPolicies() async {
    try {
      setState(() => _isPoliciesLoading = true);

      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('app_policies')
          .select('*')
          .eq('is_active', true)
          .order('display_order', ascending: true);

      if (mounted) {
        setState(() {
          _policies = List<Map<String, dynamic>>.from(response);
          _isPoliciesLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل السياسات: $e');
      if (mounted) {
        setState(() => _isPoliciesLoading = false);
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userPhone = prefs.getString('current_user_phone');

      if (userPhone == null) {
        setState(() => _isLoading = false);
        return;
      }

      // جلب بيانات المستخدم
      final userResponse = await Supabase.instance.client
          .from('users')
          .select('name, phone, email, created_at')
          .eq('phone', userPhone)
          .maybeSingle();

      if (userResponse != null) {
        _userName = userResponse['name'] ?? '';
        _userPhone = userResponse['phone'] ?? '';

        // تنسيق تاريخ الانضمام
        if (userResponse['created_at'] != null) {
          final createdAt = DateTime.parse(userResponse['created_at']);
          final baghdadDate = createdAt.toUtc().add(const Duration(hours: 3));
          _joinDate = DateFormat('yyyy/MM/dd').format(baghdadDate);
        }
      }

      // ✅ جلب عدد الطلبات المسلمة فقط
      final ordersResponse = await Supabase.instance.client
          .from('orders')
          .select('id')
          .eq('user_phone', userPhone)
          .eq('status', 'تم التسليم'); // ✅ فقط الطلبات المسلمة
      _totalOrders = ordersResponse.length;

      // ✅ جلب الأرباح من الطلبات المسلمة فقط
      final profitsResponse = await Supabase.instance.client
          .from('orders')
          .select('profit')
          .eq('user_phone', userPhone)
          .eq('status', 'تم التسليم'); // ✅ فقط الطلبات المسلمة

      _totalProfits = 0.0;
      for (var order in profitsResponse) {
        _totalProfits += (order['profit'] ?? 0).toDouble();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('❌ خطأ في تحميل بيانات المستخدم: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout(AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1f2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.logoutConfirm, style: GoogleFonts.cairo(color: Colors.white)),
        content: Text(l10n.logoutMessage, style: GoogleFonts.cairo(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: GoogleFonts.cairo(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.logout, style: GoogleFonts.cairo(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) context.go('/login');
    }
  }

  Widget _buildThemeToggle(ThemeProvider themeProvider, bool isDark) {
    // ✅ تحديث حالة الأنيميشن حسب الوضع الحالي
    if (isDark && _themeAnimationController.value < 0.5) {
      _themeAnimationController.forward();
    } else if (!isDark && _themeAnimationController.value > 0.5) {
      _themeAnimationController.reverse();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: ThemeColors.cardBackground(isDark),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ThemeColors.cardBorder(isDark)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  themeProvider.getThemeName(),
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: ThemeColors.textColor(isDark),
                  ),
                ),
              ),
              // ✅ Lottie Animation للتبديل - على اليمين مثل زر الإطفاء/التشغيل
              GestureDetector(
                onTap: () {
                  // ✅ تبديل الوضع
                  themeProvider.toggleTheme();
                  // ✅ تشغيل الأنيميشن
                  if (isDark) {
                    _themeAnimationController.reverse();
                  } else {
                    _themeAnimationController.forward();
                  }
                },
                child: SizedBox(
                  width: 70,
                  height: 70,
                  child: Lottie.asset(
                    'assets/animations/dark_mode_toggle.json',
                    fit: BoxFit.contain,
                    repeat: false,
                    controller: _themeAnimationController,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      extendBody: true, // ✅ لحل مشكلة الشريط السفلي
      body: AppBackground(
        child: SafeArea(
          bottom: false, // ✅ عدم إضافة SafeArea في الأسفل
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFffd700)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: 100, // ✅ مساحة للشريط السفلي
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Header مع المحتوى
                      Row(
                        children: [
                          // زر الرجوع على اليمين
                          GestureDetector(
                            onTap: () => context.go('/products'),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFFffd700).withValues(alpha: 0.15)
                                    : Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFFffd700).withValues(alpha: 0.5)
                                      : Colors.black.withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                FontAwesomeIcons.arrowRight,
                                color: isDark ? const Color(0xFFffd700) : Colors.black,
                                size: 20,
                              ),
                            ),
                          ),
                          // كلمة "حسابي" في الوسط
                          Expanded(
                            child: Text(
                              l10n.myAccount,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: ThemeColors.textColor(isDark),
                              ),
                            ),
                          ),
                          // مساحة فارغة للتوازن
                          const SizedBox(width: 44),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Content
                      _buildUserCard(l10n, isDark),
                      const SizedBox(height: 20),
                      _buildThemeToggle(themeProvider, isDark),
                      const SizedBox(height: 20),
                      _buildMenuItems(l10n, isDark),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildUserCard(AppLocalizations l10n, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26), // ✅ تحسين الحشو
          decoration: BoxDecoration(
            color: ThemeColors.cardBackground(isDark),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: ThemeColors.cardBorder(isDark)),
          ),
          child: Column(
            children: [
              // Name
              Text(
                _userName.isNotEmpty ? _userName : l10n.user,
                style: GoogleFonts.cairo(
                  fontSize: 24, // ✅ تصغير قليلاً
                  fontWeight: FontWeight.bold,
                  color: ThemeColors.textColor(isDark),
                ),
              ),
              const SizedBox(height: 10),

              // Phone
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.phone,
                    size: 13,
                    color: isDark ? const Color(0xFFffd700) : Colors.black.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _userPhone,
                    style: GoogleFonts.cairo(fontSize: 15, color: ThemeColors.secondaryTextColor(isDark)),
                  ),
                ],
              ),

              if (_joinDate.isNotEmpty) ...[
                const SizedBox(height: 7),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.calendar,
                      size: 13,
                      color: isDark ? const Color(0xFFffd700) : Colors.black.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${l10n.joinedOn} $_joinDate',
                      style: GoogleFonts.cairo(fontSize: 13, color: ThemeColors.secondaryTextColor(isDark)),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 22),

              // Stats - ✅ أيقونات 3D ملونة
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      l10n.orders,
                      _totalOrders.toString(),
                      FontAwesomeIcons.boxOpen,
                      isDark,
                      emoji: '📦', // ✅ أيقونة 3D ملونة
                    ),
                  ),
                  Container(width: 1, height: 70, color: ThemeColors.dividerColor(isDark)),
                  Expanded(
                    child: _buildStatItem(
                      l10n.profits,
                      '${NumberFormat('#,###').format(_totalProfits)} د.ع',
                      FontAwesomeIcons.coins,
                      isDark,
                      emoji: '💰', // ✅ أيقونة 3D ملونة
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, bool isDark, {String? emoji}) {
    return Column(
      children: [
        // ✅ الأيقونة فقط بدون خلفية
        SizedBox(
          width: 60,
          height: 60,
          child: Center(
            child: emoji != null
                ? Text(emoji, style: const TextStyle(fontSize: 36))
                : FaIcon(icon, color: isDark ? const Color(0xFFffd700) : Colors.black.withValues(alpha: 0.7), size: 28),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: ThemeColors.textColor(isDark)),
        ),
        const SizedBox(height: 3),
        Text(label, style: GoogleFonts.cairo(fontSize: 13, color: ThemeColors.secondaryTextColor(isDark))),
      ],
    );
  }

  Widget _buildMenuItems(AppLocalizations l10n, bool isDark) {
    return Column(
      children: [
        _buildMenuItem(
          icon: FontAwesomeIcons.userPen,
          title: l10n.editProfile,
          emoji: '👤', // ✅ أيقونة ملونة
          color: Colors.blue,
          isDark: isDark,
          onTap: () {
            // TODO: Navigate to edit profile
          },
        ),
        const SizedBox(height: 8),
        _buildMenuItem(
          icon: FontAwesomeIcons.circleInfo,
          title: l10n.aboutApp,
          svgIcon: 'assets/images/about_app_icon.svg', // ✅ أيقونة SVG ملونة
          color: Colors.purple,
          isDark: isDark,
          onTap: () => _showAboutDialog(isDark),
        ),
        const SizedBox(height: 8),
        _buildMenuItem(
          icon: FontAwesomeIcons.rightFromBracket,
          title: l10n.logout,
          emoji: '�', // ✅ أيقونة ملونة
          color: Colors.red,
          isDark: isDark,
          onTap: () => _logout(l10n),
        ),
      ],
    );
  }

  // 📱 عرض صفحة "حول التطبيق"
  void _showAboutDialog(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAboutSheet(isDark),
    );
  }

  // 🎨 صفحة "حول التطبيق" الكاملة
  Widget _buildAboutSheet(bool isDark) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            // ✅ نفس خلفية الصفحة الرئيسية تماماً
            gradient: isDark
                ? const RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.5,
                    colors: [
                      Color(0xFF0F1419), // أسود مزرق عميق
                      Color(0xFF1A1F2E), // أزرق داكن
                      Color(0xFF0D1117), // أسود عميق
                      Colors.black, // أسود خالص
                    ],
                    stops: [0.0, 0.3, 0.7, 1.0],
                  )
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFE8EAF6), // بنفسجي فاتح جداً
                      Color(0xFFF3E5F5), // وردي فاتح جداً
                      Color(0xFFE1F5FE), // أزرق فاتح جداً
                    ],
                  ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ThemeColors.dividerColor(isDark),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Icon(FontAwesomeIcons.arrowRight, color: isDark ? Colors.white : Colors.black, size: 18),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'منتجاتي',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: ThemeColors.textColor(isDark),
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // صورة توضيحية - أيقونة 3D ملونة
                      Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    const Color(0xFFffd700).withValues(alpha: 0.15),
                                    const Color(0xFFffa500).withValues(alpha: 0.1),
                                  ]
                                : [Colors.blue.withValues(alpha: 0.08), Colors.purple.withValues(alpha: 0.05)],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFFffd700).withValues(alpha: 0.3)
                                : Colors.blue.withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          '🛡️',
                          style: TextStyle(
                            fontSize: 90,
                            shadows: [
                              Shadow(
                                color: isDark
                                    ? const Color(0xFFffd700).withValues(alpha: 0.5)
                                    : Colors.blue.withValues(alpha: 0.3),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      // العنوان الرئيسي
                      Text(
                        'سياسات و اتفاقيات التطبيق',
                        style: GoogleFonts.cairo(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: ThemeColors.textColor(isDark),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'لاستخدام تطبيق "منتجاتي"، يجب الموافقة على السياسات والشروط الخاصة بنا.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          color: ThemeColors.secondaryTextColor(isDark),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 30),
                      // الأقسام - من قاعدة البيانات ✅
                      if (_isPoliciesLoading)
                        const Center(child: CircularProgressIndicator(color: Color(0xFFffd700)))
                      else if (_policies.isEmpty)
                        Text(
                          'لا توجد سياسات متاحة حالياً',
                          style: GoogleFonts.cairo(fontSize: 16, color: ThemeColors.secondaryTextColor(isDark)),
                        )
                      else
                        ..._policies.map((policy) {
                          final items = (policy['items'] as List<dynamic>).map((e) => e.toString()).toList();
                          return Column(
                            children: [
                              _buildPolicySection(
                                title: policy['title'] ?? '',
                                icon: policy['icon'] ?? '📋',
                                items: items,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 20),
                            ],
                          );
                        }),
                      const SizedBox(height: 25),
                      // تحذير
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(FontAwesomeIcons.triangleExclamation, color: Colors.orange, size: 24),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                'عند موافقتك على هذه السياسات ستتحمل المسؤولية القانونية عن أي استخدام خاطئ للتطبيق. يُرجى قراءة هذه البنود بعناية.',
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  color: Colors.orange,
                                  height: 1.6,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 📋 قسم السياسة
  Widget _buildPolicySection({
    required String title,
    required String icon,
    required List<String> items,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.textColor(isDark),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // العناصر
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFFffd700) : Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: ThemeColors.secondaryTextColor(isDark),
                        height: 1.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required bool isDark,
    String? trailing,
    Color? color,
    String? emoji, // ✅ إضافة emoji
    String? svgIcon, // ✅ إضافة SVG
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: ThemeColors.cardBackground(isDark),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ThemeColors.cardBorder(isDark)),
            ),
            child: Row(
              children: [
                // ✅ الأيقونة فقط بدون خلفية
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: svgIcon != null
                        ? SvgPicture.asset(svgIcon, width: 40, height: 40, fit: BoxFit.contain)
                        : emoji != null
                        ? Text(emoji, style: const TextStyle(fontSize: 32))
                        : FaIcon(icon, color: color ?? (isDark ? const Color(0xFFffd700) : Colors.black), size: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: ThemeColors.textColor(isDark),
                    ),
                  ),
                ),
                if (trailing != null)
                  Text(trailing, style: GoogleFonts.cairo(fontSize: 13, color: ThemeColors.secondaryTextColor(isDark)))
                else
                  FaIcon(
                    FontAwesomeIcons.chevronLeft,
                    color: isDark ? ThemeColors.secondaryIconColor(isDark) : Colors.black.withValues(alpha: 0.4),
                    size: 13,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
