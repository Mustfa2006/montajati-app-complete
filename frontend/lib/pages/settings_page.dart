import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/app_background.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = true;

  // بيانات المستخدم
  String _userName = '';
  String _userPhone = '';
  String _userEmail = '';
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
          .select('name, phone, email')
          .eq('phone', userPhone)
          .maybeSingle();

      if (userResponse != null) {
        _userName = userResponse['name'] ?? '';
        _userPhone = userResponse['phone'] ?? '';
        _userEmail = userResponse['email'] ?? '';
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

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1f2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('تسجيل الخروج', style: GoogleFonts.cairo(color: Colors.white)),
        content: Text('هل أنت متأكد من تسجيل الخروج؟', style: GoogleFonts.cairo(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('تسجيل الخروج', style: GoogleFonts.cairo(color: Colors.red)),
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

  @override
  Widget build(BuildContext context) {
    return AppBackground(
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
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const FaIcon(FontAwesomeIcons.arrowRight, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'حسابي',
                          style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
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
                          _buildUserCard(),
                          const SizedBox(height: 20),
                          _buildMenuItems(),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildUserCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFffd700), Color(0xFFffa500)],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: const Color(0xFFffd700).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 5)),
              ],
            ),
            child: const Center(child: FaIcon(FontAwesomeIcons.user, size: 45, color: Color(0xFFffd700))),
          ),
          const SizedBox(height: 20),

          // Name
          Text(
            _userName.isNotEmpty ? _userName : 'مستخدم',
            style: GoogleFonts.cairo(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),

          // Phone
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(FontAwesomeIcons.phone, size: 14, color: Colors.white70),
              const SizedBox(width: 8),
              Text(_userPhone, style: GoogleFonts.cairo(fontSize: 16, color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 25),

          // Stats
          Row(
            children: [
              Expanded(child: _buildStatItem('الطلبات', _totalOrders.toString(), FontAwesomeIcons.boxOpen)),
              Container(width: 1, height: 50, color: Colors.white.withValues(alpha: 0.3)),
              Expanded(
                child: _buildStatItem('الأرباح', '${_totalProfits.toStringAsFixed(0)} د.ع', FontAwesomeIcons.coins),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        FaIcon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.cairo(fontSize: 14, color: Colors.white70)),
      ],
    );
  }

  Widget _buildMenuItems() {
    return Column(
      children: [
        _buildMenuItem(
          icon: FontAwesomeIcons.userPen,
          title: 'تعديل الملف الشخصي',
          onTap: () {
            // TODO: Navigate to edit profile
          },
        ),
        const SizedBox(height: 12),
        _buildMenuItem(
          icon: FontAwesomeIcons.language,
          title: 'اللغة',
          trailing: 'العربية',
          onTap: () {
            // TODO: Show language selector
          },
        ),
        const SizedBox(height: 12),
        _buildMenuItem(
          icon: FontAwesomeIcons.circleInfo,
          title: 'حول التطبيق',
          onTap: () {
            // TODO: Show about dialog
          },
        ),
        const SizedBox(height: 12),
        _buildMenuItem(
          icon: FontAwesomeIcons.rightFromBracket,
          title: 'تسجيل الخروج',
          color: Colors.red,
          onTap: _logout,
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? trailing,
    Color? color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (color ?? const Color(0xFFffd700)).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: FaIcon(icon, color: color ?? const Color(0xFFffd700), size: 20),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
            if (trailing != null)
              Text(trailing, style: GoogleFonts.cairo(fontSize: 14, color: Colors.white54))
            else
              FaIcon(FontAwesomeIcons.chevronLeft, color: Colors.white.withValues(alpha: 0.3), size: 14),
          ],
        ),
      ),
    );
  }
}
