import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../providers/theme_provider.dart';
import '../utils/number_formatter.dart';
import '../widgets/app_background.dart';

class ProfitsPage extends StatefulWidget {
  const ProfitsPage({super.key});

  @override
  State<ProfitsPage> createState() => _ProfitsPageState();
}

class _ProfitsPageState extends State<ProfitsPage> with SingleTickerProviderStateMixin {
  final _secureStorage = const FlutterSecureStorage();

  double _realizedProfits = 0.0;
  double _pendingProfits = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfits();
  }

  Future<void> _loadProfits() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('current_user_phone') ?? '';
      String? token = await _secureStorage.read(key: 'auth_token') ?? 'temp_token_$phone';

      if (phone.isNotEmpty) {
        final response = await http
            .post(
              Uri.parse('${ApiConfig.usersUrl}/profits'),
              headers: {...ApiConfig.defaultHeaders, 'Authorization': 'Bearer $token'},
              body: jsonEncode({'phone': phone}),
            )
            .timeout(ApiConfig.defaultTimeout);

        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body);
          if (jsonData['success'] == true && jsonData['data'] != null) {
            final data = jsonData['data'];
            if (mounted) {
              setState(() {
                _realizedProfits = (data['achieved_profits'] as num?)?.toDouble() ?? 0.0;
                _pendingProfits = (data['expected_profits'] as num?)?.toDouble() ?? 0.0;
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading profits: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    // ألوان متكيفة مع الوضع
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A202C);
    final Color secondaryTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final Color accentGold = const Color(0xFFFFD700);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AppBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // تأثيرات خلفية خفيفة (Ambient Light)
              if (isDark)
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentGold.withValues(alpha: 0.05),
                      boxShadow: [BoxShadow(color: accentGold.withValues(alpha: 0.1), blurRadius: 100)],
                    ),
                  ),
                ),

              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // 1. Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'محفظتي',
                                style: GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
                              ),
                              Text(
                                'نظرة عامة على أرباحك',
                                style: GoogleFonts.cairo(fontSize: 14, color: secondaryTextColor),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200],
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(Icons.notifications_outlined, color: textColor),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // 2. HERO SECTION: Realized Profits
                      Column(
                        children: [
                          Text(
                            'الرصيد المتاح للسحب',
                            style: GoogleFonts.cairo(fontSize: 16, color: secondaryTextColor, letterSpacing: 1.0),
                          ),
                          const SizedBox(height: 10),
                          _isLoading
                              ? CircularProgressIndicator(color: accentGold)
                              : ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: isDark
                                        ? [const Color(0xFFFFD700), const Color(0xFFFDB931)]
                                        : [const Color(0xFF1A202C), const Color(0xFF2D3748)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds),
                                  child: Text(
                                    NumberFormatter.formatCurrency(_realizedProfits).replaceAll('د.ع', ''),
                                    style: GoogleFonts.cairo(
                                      fontSize: 52,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white, // Masked color
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                          Text(
                            'دينار عراقي',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              color: isDark ? accentGold : const Color(0xFF1A202C),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // 3. Pending Profits Capsule
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.orange, blurRadius: 6)],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text('قيد المعالجة: ', style: GoogleFonts.cairo(color: secondaryTextColor, fontSize: 14)),
                            Text(
                              NumberFormatter.formatCurrency(_pendingProfits),
                              style: GoogleFonts.cairo(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 50),

                      // 4. ✨ THE UNIFIED CONTROL PANEL ✨
                      _buildActionHub(context, isDark),

                      const SizedBox(height: 120),
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

  Widget _buildActionHub(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. زر السحب (Withdraw) - الجوهرة
          Expanded(
            child: _buildDeepSquare(
              context,
              title: 'سحب الأرباح',
              icon: FontAwesomeIcons.moneyBillTransfer,
              // لون برونزي/ذهبي هادئ جداً ومتناغم
              accentColor: const Color(0xFFC5A059),
              onTap: () => context.push('/withdraw'),
              isDark: isDark,
              isPrimary: true,
            ),
          ),
          const SizedBox(width: 15),

          // 2. زر السجل (History)
          Expanded(
            child: _buildDeepSquare(
              context,
              title: 'السجل',
              icon: FontAwesomeIcons.clockRotateLeft,
              // لون أزرق رمادي متناغم مع الخلفية
              accentColor: const Color(0xFF64748B),
              onTap: () => context.push('/profits/withdrawal-history'),
              isDark: isDark,
              isPrimary: false,
            ),
          ),
          const SizedBox(width: 15),

          // 3. زر الإحصائيات (Stats)
          Expanded(
            child: _buildDeepSquare(
              context,
              title: 'التحليل',
              icon: FontAwesomeIcons.chartPie,
              // لون بنفسجي رمادي هادئ
              accentColor: const Color(0xFF94A3B8),
              onTap: () => context.go('/statistics'),
              isDark: isDark,
              isPrimary: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeepSquare(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
    required bool isDark,
    required bool isPrimary,
  }) {
    // ألوان الخلفية المتناغمة "جداً" مع الصفحة
    final baseColor = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.6) // لون داكن شفاف قليلاً
        : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110, // مربع مثالي
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(24),
          // حدود متدرجة لتعطي عمقاً (Sculpted Look)
          border: Border.all(
            color: isPrimary
                ? accentColor.withValues(alpha: 0.3)
                : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100]!),
            width: 1,
          ),
          boxShadow: [
            // ظل ناعم جداً للعمق
            BoxShadow(
              color: isPrimary
                  ? accentColor.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            // توهج داخلي خفيف (Inner Light)
            if (isDark)
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.03),
                blurRadius: 0,
                spreadRadius: 0,
                offset: const Offset(0, 0),
              ),
          ],
          gradient: isPrimary && !isDark
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    const Color(0xFFFFFDF5), // لمسة ذهبية خفيفة جداً في الخلفية
                  ],
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // الأيقونة مع خلفية ناعمة
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(height: 12),
            // النص
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
