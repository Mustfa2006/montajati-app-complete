import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/design_system.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../utils/theme_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/curved_navigation_bar.dart';

class NewAccountPage extends StatefulWidget {
  const NewAccountPage({super.key});

  @override
  State<NewAccountPage> createState() => _NewAccountPageState();
}

class _NewAccountPageState extends State<NewAccountPage> {
  bool _isLoading = true;
  int _currentNavIndex = 3; // الحساب

  // بيانات المستخدم
  String _userName = '';
  String _userPhone = '';
  String _userEmail = '';
  String _joinDate = '';
  int _totalOrders = 0;
  double _totalProfits = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
        _userEmail = userResponse['email'] ?? '';

        // تنسيق تاريخ الانضمام
        if (userResponse['created_at'] != null) {
          final createdAt = DateTime.parse(userResponse['created_at']);
          final baghdadDate = createdAt.toUtc().add(const Duration(hours: 3));
          _joinDate = DateFormat('yyyy/MM/dd').format(baghdadDate);
        }
      }

      // جلب عدد الطلبات
      final ordersResponse = await Supabase.instance.client.from('orders').select('id').eq('user_phone', userPhone);
      _totalOrders = ordersResponse.length;

      // جلب الأرباح
      final profitsResponse = await Supabase.instance.client
          .from('orders')
          .select('profit')
          .eq('user_phone', userPhone)
          .inFilter('status', ['delivered', 'واصل', 'تم التسليم للزبون']);

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
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ThemeColors.cardBackground(isDark),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ThemeColors.cardBorder(isDark)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFffd700).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(
                  themeProvider.isDarkMode ? FontAwesomeIcons.moon : FontAwesomeIcons.sun,
                  color: const Color(0xFFffd700),
                  size: 22,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  themeProvider.getThemeName(),
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ThemeColors.textColor(isDark),
                  ),
                ),
              ),
              Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) => themeProvider.setDarkMode(value),
                activeThumbColor: const Color(0xFFffd700),
                activeTrackColor: const Color(0xFFffd700).withValues(alpha: 0.5),
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
      body: AppBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFffd700)))
              : Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const SizedBox(width: 10),
                          Text(
                            l10n.myAccount,
                            style: GoogleFonts.cairo(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: ThemeColors.textColor(isDark),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
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
                  ],
                ),
        ),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _currentNavIndex,
        items: const <Widget>[
          Icon(Icons.storefront_outlined, size: 28, color: Color(0xFFFFD700)),
          Icon(Icons.receipt_long_outlined, size: 28, color: Color(0xFFFFD700)),
          Icon(Icons.trending_up_outlined, size: 28, color: Color(0xFFFFD700)),
          Icon(Icons.person_outline, size: 28, color: Color(0xFFFFD700)),
        ],
        color: AppDesignSystem.bottomNavColor,
        buttonBackgroundColor: AppDesignSystem.activeButtonColor,
        backgroundColor: Colors.transparent,
        animationCurve: Curves.elasticOut,
        animationDuration: const Duration(milliseconds: 1200),
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });
          switch (index) {
            case 0:
              context.go('/products');
              break;
            case 1:
              context.go('/orders');
              break;
            case 2:
              context.go('/profits');
              break;
            case 3:
              // الحساب - الصفحة الحالية
              break;
          }
        },
        letIndexChange: (index) => true,
      ),
    );
  }

  Widget _buildUserCard(AppLocalizations l10n, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: ThemeColors.cardBackground(isDark),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: ThemeColors.cardBorder(isDark)),
          ),
          child: Column(
            children: [
              // Name
              Text(
                _userName.isNotEmpty ? _userName : l10n.user,
                style: GoogleFonts.cairo(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: ThemeColors.textColor(isDark),
                ),
              ),
              const SizedBox(height: 12),

              // Phone
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(FontAwesomeIcons.phone, size: 14, color: ThemeColors.secondaryIconColor(isDark)),
                  const SizedBox(width: 8),
                  Text(
                    _userPhone,
                    style: GoogleFonts.cairo(fontSize: 16, color: ThemeColors.secondaryTextColor(isDark)),
                  ),
                ],
              ),

              if (_joinDate.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(FontAwesomeIcons.calendar, size: 14, color: ThemeColors.secondaryIconColor(isDark)),
                    const SizedBox(width: 8),
                    Text(
                      '${l10n.joinedOn} $_joinDate',
                      style: GoogleFonts.cairo(fontSize: 14, color: ThemeColors.secondaryTextColor(isDark)),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 25),

              // Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(l10n.orders, _totalOrders.toString(), FontAwesomeIcons.boxOpen, isDark),
                  ),
                  Container(width: 1, height: 50, color: ThemeColors.dividerColor(isDark)),
                  Expanded(
                    child: _buildStatItem(
                      l10n.profits,
                      '${NumberFormat('#,###').format(_totalProfits)} د.ع',
                      FontAwesomeIcons.coins,
                      isDark,
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

  Widget _buildStatItem(String label, String value, IconData icon, bool isDark) {
    return Column(
      children: [
        FaIcon(icon, color: const Color(0xFFffd700), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: ThemeColors.textColor(isDark)),
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.cairo(fontSize: 14, color: ThemeColors.secondaryTextColor(isDark))),
      ],
    );
  }

  Widget _buildMenuItems(AppLocalizations l10n, bool isDark) {
    return Column(
      children: [
        _buildMenuItem(
          icon: FontAwesomeIcons.userPen,
          title: l10n.editProfile,
          isDark: isDark,
          onTap: () {
            // TODO: Navigate to edit profile
          },
        ),
        const SizedBox(height: 12),
        _buildMenuItem(
          icon: FontAwesomeIcons.circleInfo,
          title: l10n.aboutApp,
          isDark: isDark,
          onTap: () {
            // TODO: Show about dialog
          },
        ),
        const SizedBox(height: 12),
        _buildMenuItem(
          icon: FontAwesomeIcons.rightFromBracket,
          title: l10n.logout,
          color: Colors.red,
          isDark: isDark,
          onTap: () => _logout(l10n),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required bool isDark,
    String? trailing,
    Color? color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: ThemeColors.cardBackground(isDark),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: ThemeColors.cardBorder(isDark)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (color ?? const Color(0xFFffd700)).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FaIcon(icon, color: color ?? const Color(0xFFffd700), size: 22),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ThemeColors.textColor(isDark),
                    ),
                  ),
                ),
                if (trailing != null)
                  Text(trailing, style: GoogleFonts.cairo(fontSize: 14, color: ThemeColors.secondaryTextColor(isDark)))
                else
                  FaIcon(FontAwesomeIcons.chevronLeft, color: ThemeColors.secondaryIconColor(isDark), size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
