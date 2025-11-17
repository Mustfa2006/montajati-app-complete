import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../providers/theme_provider.dart';
import '../services/real_auth_service.dart';
import '../services/user_service.dart';

class DrawerMenu extends StatefulWidget {
  const DrawerMenu({super.key, this.onClose});

  final void Function()? onClose;

  @override
  State<DrawerMenu> createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<DrawerMenu> with SingleTickerProviderStateMixin {
  String _userName = 'المستخدم';
  String _userPhone = '';
  double _achievedProfits = 0.0;
  double _expectedProfits = 0.0;
  bool _isLoading = true;
  final _secureStorage = const FlutterSecureStorage();

  late AnimationController _themeToggleController;

  @override
  void initState() {
    super.initState();
    _themeToggleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    // مزامنة قيمة الأنميشن مع وضع التطبيق الحالي بعد بناء الـ context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
      // نعتمد أن إطار 0.0 يمثل النهار، وإطار 0.5 يمثل الحالة الليلية في ملف الأنميشن
      _themeToggleController.value = isDark ? 0.5 : 0.0;
    });

    _loadUserData();
  }

  @override
  void dispose() {
    _themeToggleController.dispose();
    super.dispose();
  }

  static const String _dayModeSvg =
      '''<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" fill="none" viewBox="0 0 32 32" id="sun"><path fill="#FCD53F" d="M29.999 15.9656C29.999 23.6973 23.7312 29.9651 15.9995 29.9651C8.2678 29.9651 2 23.6973 2 15.9656C2 8.23386 8.2678 1.96606 15.9995 1.96606C23.7312 1.96606 29.999 8.23386 29.999 15.9656Z"></path><path fill="#F9C23C" d="M2.02193 15.1753C2.37516 15.0615 2.7519 15 3.14301 15C5.1595 15 6.79419 16.6347 6.79419 18.6512C6.79419 20.5459 5.35102 22.1035 3.50396 22.2848C2.54205 20.3864 2 18.2393 2 15.9656C2 15.7004 2.00737 15.4369 2.02193 15.1753ZM26.1571 25.5994C24.4773 27.37 22.3394 28.7017 19.9333 29.4048C19.6477 28.8844 19.4854 28.2867 19.4854 27.6512C19.4854 25.6347 21.12 24 23.1365 24C24.3923 24 25.5001 24.634 26.1571 25.5994ZM29.9545 17.0909C29.8181 18.8057 29.3727 20.4335 28.6739 21.9186C27.5901 21.6461 26.7877 20.6652 26.7877 19.4969C26.7877 18.1179 27.9056 17 29.2846 17C29.5166 17 29.7413 17.0317 29.9545 17.0909ZM15.4925 8C16.8715 8 17.9894 6.88211 17.9894 5.50311C17.9894 4.12412 16.8715 3.00623 15.4925 3.00623C14.1135 3.00623 12.9956 4.12412 12.9956 5.50311C12.9956 6.88211 14.1135 8 15.4925 8ZM14.7894 22.6149C15.8399 23.4374 16.1262 24.8261 15.429 25.7167C14.7317 26.6072 13.3149 26.6624 12.2644 25.8399C11.2139 25.0175 10.9276 23.6288 11.6248 22.7382C12.3221 21.8476 13.739 21.7924 14.7894 22.6149Z"></path><path fill="#321B41" d="M10.6699 8.04004C9.30499 8.04004 8.18994 9.14727 8.18994 10.52 8.18994 10.7962 7.96608 11.02 7.68994 11.02 7.4138 11.02 7.18994 10.7962 7.18994 10.52 7.18994 8.59281 8.75489 7.04004 10.6699 7.04004 10.9461 7.04004 11.1699 7.2639 11.1699 7.54004 11.1699 7.81618 10.9461 8.04004 10.6699 8.04004ZM20.55 7.54004C20.55 7.2639 20.7739 7.04004 21.05 7.04004 22.9651 7.04004 24.5301 8.59281 24.5301 10.52 24.5301 10.7962 24.3062 11.02 24.0301 11.02 23.7539 11.02 23.5301 10.7962 23.5301 10.52 23.5301 9.14727 22.415 8.04004 21.05 8.04004 20.7739 8.04004 20.55 7.81618 20.55 7.54004ZM10.3081 12.384C10.5071 11.877 11.0029 11.52 11.5899 11.52 12.1976 11.52 12.7162 11.9141 12.8976 12.4647 13.0272 12.8581 13.4512 13.072 13.8446 12.9424 14.238 12.8128 14.4519 12.3888 14.3223 11.9954 13.9437 10.846 12.8622 10.02 11.5899 10.02 10.377 10.02 9.33281 10.7631 8.91177 11.8361 8.76046 12.2216 8.95039 12.6569 9.33598 12.8082 9.72157 12.9595 10.1568 12.7696 10.3081 12.384ZM20.2099 11.52C19.6229 11.52 19.1271 11.877 18.9281 12.384 18.7768 12.7696 18.3416 12.9595 17.956 12.8082 17.5704 12.6569 17.3805 12.2216 17.5318 11.8361 17.9528 10.7631 18.997 10.02 20.2099 10.02 21.4822 10.02 22.5637 10.846 22.9423 11.9954 23.0719 12.3888 22.858 12.8128 22.4646 12.9424 22.0712 13.072 21.6472 12.8581 21.5176 12.4647 21.3362 11.9141 20.8176 11.52 20.2099 11.52ZM11.9703 16.5797C11.6774 16.2868 11.2025 16.2868 10.9096 16.5797 10.6167 16.8725 10.6167 17.3474 10.9096 17.6403 13.6525 20.3832 18.0974 20.3832 20.8403 17.6403 21.1332 17.3474 21.1332 16.8725 20.8403 16.5797 20.5474 16.2868 20.0725 16.2868 19.7796 16.5797 17.6225 18.7368 14.1274 18.7368 11.9703 16.5797Z"></path></svg>''';

  static const String _nightModeSvg =
      '''<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" fill="none" viewBox="0 0 32 32" id="moon"><path fill="#FCD53F" d="M29.999 15.9656C29.999 23.6973 23.7312 29.9651 15.9995 29.9651C8.2678 29.9651 2 23.6973 2 15.9656C2 8.23386 8.2678 1.96606 15.9995 1.96606C23.7312 1.96606 29.999 8.23386 29.999 15.9656Z"></path><path fill="#F9C23C" d="M2.02193 15.1753C2.37516 15.0615 2.7519 15 3.14301 15C5.1595 15 6.79419 16.6347 6.79419 18.6512C6.79419 20.5459 5.35102 22.1035 3.50396 22.2848C2.54205 20.3864 2 18.2393 2 15.9656C2 15.7004 2.00737 15.4369 2.02193 15.1753ZM26.1571 25.5994C24.4773 27.37 22.3394 28.7017 19.9333 29.4048C19.6477 28.8844 19.4854 28.2867 19.4854 27.6512C19.4854 25.6347 21.12 24 23.1365 24C24.3923 24 25.5001 24.634 26.1571 25.5994ZM29.9545 17.0909C29.8181 18.8057 29.3727 20.4335 28.6739 21.9186C27.5901 21.6461 26.7877 20.6652 26.7877 19.4969C26.7877 18.1179 27.9056 17 29.2846 17C29.5166 17 29.7413 17.0317 29.9545 17.0909ZM15.4925 8C16.8715 8 17.9894 6.88211 17.9894 5.50311C17.9894 4.12412 16.8715 3.00623 15.4925 3.00623C14.1135 3.00623 12.9956 4.12412 12.9956 5.50311C12.9956 6.88211 14.1135 8 15.4925 8ZM14.7894 22.6149C15.8399 23.4374 16.1262 24.8261 15.429 25.7167C14.7317 26.6072 13.3149 26.6624 12.2644 25.8399C11.2139 25.0175 10.9276 23.6288 11.6248 22.7382C12.3221 21.8476 13.739 21.7924 14.7894 22.6149Z"></path><path fill="#321B41" d="M10.6699 8.04004C9.30499 8.04004 8.18994 9.14727 8.18994 10.52 8.18994 10.7962 7.96608 11.02 7.68994 11.02 7.4138 11.02 7.18994 10.7962 7.18994 10.52 7.18994 8.59281 8.75489 7.04004 10.6699 7.04004 10.9461 7.04004 11.1699 7.2639 11.1699 7.54004 11.1699 7.81618 10.9461 8.04004 10.6699 8.04004ZM20.55 7.54004C20.55 7.2639 20.7739 7.04004 21.05 7.04004 22.9651 7.04004 24.5301 8.59281 24.5301 10.52 24.5301 10.7962 24.3062 11.02 24.0301 11.02 23.7539 11.02 23.5301 10.7962 23.5301 10.52 23.5301 9.14727 22.415 8.04004 21.05 8.04004 20.7739 8.04004 20.55 7.81618 20.55 7.54004ZM10.3081 12.384C10.5071 11.877 11.0029 11.52 11.5899 11.52 12.1976 11.52 12.7162 11.9141 12.8976 12.4647 13.0272 12.8581 13.4512 13.072 13.8446 12.9424 14.238 12.8128 14.4519 12.3888 14.3223 11.9954 13.9437 10.846 12.8622 10.02 11.5899 10.02 10.377 10.02 9.33281 10.7631 8.91177 11.8361 8.76046 12.2216 8.95039 12.6569 9.33598 12.8082 9.72157 12.9595 10.1568 12.7696 10.3081 12.384ZM20.2099 11.52C19.6229 11.52 19.1271 11.877 18.9281 12.384 18.7768 12.7696 18.3416 12.9595 17.956 12.8082 17.5704 12.6569 17.3805 12.2216 17.5318 11.8361 17.9528 10.7631 18.997 10.02 20.2099 10.02 21.4822 10.02 22.5637 10.846 22.9423 11.9954 23.0719 12.3888 22.858 12.8128 22.4646 12.9424 22.0712 13.072 21.6472 12.8581 21.5176 12.4647 21.3362 11.9141 20.8176 11.52 20.2099 11.52ZM11.9703 16.5797C11.6774 16.2868 11.2025 16.2868 10.9096 16.5797 10.6167 16.8725 10.6167 17.3474 10.9096 17.6403 13.6525 20.3832 18.0974 20.3832 20.8403 17.6403 21.1332 17.3474 21.1332 16.8725 20.8403 16.5797 20.5474 16.2868 20.0725 16.2868 19.7796 16.5797 17.6225 18.7368 14.1274 18.7368 11.9703 16.5797Z"></path></svg>''';

  Future<void> _loadUserData() async {
    try {
      debugPrint('📥 [DrawerMenu] تحميل بيانات المستخدم والأرباح...');

      // 1) جلب رقم الهاتف من SharedPreferences (نفس منطق صفحة الأرباح)
      final prefs = await SharedPreferences.getInstance();
      String phone = prefs.getString('current_user_phone') ?? '';

      // 2) إذا لم يوجد رقم هاتف في التخزين المحلي نحاول جلبه من خدمة المستخدمين، بدون إيقاف تحميل الأرباح عند الفشل
      if (phone.isEmpty) {
        try {
          phone = await UserService.getPhoneNumber();
          debugPrint('📱 [DrawerMenu] رقم الهاتف من UserService: $phone');
        } catch (e) {
          debugPrint('⚠️ [DrawerMenu] فشل جلب رقم الهاتف من UserService: $e');
        }
      }

      // 3) جلب اسم المستخدم، لكن أي خطأ هنا لا يمنع جلب الأرباح
      String name = _userName;
      try {
        final fetchedName = await UserService.getFirstName();
        if (fetchedName.isNotEmpty) {
          name = fetchedName;
        }
      } catch (e) {
        debugPrint('⚠️ [DrawerMenu] فشل جلب اسم المستخدم من UserService: $e');
      }

      Map<String, double>? profits;
      if (phone.isNotEmpty) {
        // 4) جلب الأرباح من الـ API باستخدام نفس الـ engine الخاص بصفحة الأرباح
        profits = await _fetchUserProfitsFromApi(phone);
      } else {
        debugPrint('❌ [DrawerMenu] لا يوجد رقم هاتف نهائياً - لن يتم جلب الأرباح');
      }

      if (mounted) {
        setState(() {
          _userName = name;
          _userPhone = phone;
          _achievedProfits = profits?['achieved_profits'] ?? 0.0;
          _expectedProfits = profits?['expected_profits'] ?? 0.0;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ خطأ غير متوقع في تحميل بيانات المستخدم داخل القائمة الجانبية: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<Map<String, double>?> _fetchUserProfitsFromApi(String phone) async {
    if (phone.isEmpty) {
      debugPrint('❌ [DrawerMenu] لا يوجد رقم هاتف محفوظ للأرباح');
      return null;
    }

    try {
      debugPrint('📊 [DrawerMenu] جلب الأرباح من الـ API للمستخدم: $phone');

      // 🔒 نفس منطق صفحة الأرباح: استخدام التوكن الآمن إن وجد، وإلا توكن مؤقت مبني على رقم الهاتف
      String? token = await _secureStorage.read(key: 'auth_token');
      if (token == null || token.isEmpty) {
        debugPrint('⚠️ [DrawerMenu] لا يوجد توكن آمن - استخدام التوكن الافتراضي');
        token = 'temp_token_$phone';
      }

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
          final achieved = (data['achieved_profits'] as num?)?.toDouble() ?? 0.0;
          final expected = (data['expected_profits'] as num?)?.toDouble() ?? 0.0;

          debugPrint('📊 [DrawerMenu] الأرباح المحققة: $achieved د.ع');
          debugPrint('📊 [DrawerMenu] الأرباح المنتظرة: $expected د.ع');

          return {'achieved_profits': achieved, 'expected_profits': expected};
        }
      } else if (response.statusCode == 401) {
        debugPrint('❌ [DrawerMenu] خطأ في المصادقة عند جلب الأرباح (401)');
      } else if (response.statusCode == 404) {
        debugPrint('❌ [DrawerMenu] المستخدم غير موجود في نظام الأرباح (404)');
      } else {
        debugPrint('❌ [DrawerMenu] خطأ في الـ API عند جلب الأرباح: ${response.statusCode}');
      }
    } on TimeoutException {
      debugPrint('❌ [DrawerMenu] انتهت مهلة الاتصال عند جلب الأرباح');
    } catch (e) {
      debugPrint('❌ [DrawerMenu] استثناء غير متوقع عند جلب الأرباح: $e');
    }

    return null;
  }

  // 📱 عرض صفحة "حول التطبيق" بنفس تجربة صفحة الحساب
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
            gradient: isDark
                ? const RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.5,
                    colors: [Color(0xFF0F1419), Color(0xFF1A1F2E), Color(0xFF0D1117), Colors.black],
                    stops: [0.0, 0.3, 0.7, 1.0],
                  )
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE8EAF6), Color(0xFFF3E5F5), Color(0xFFE1F5FE)],
                  ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              // مقبض السحب
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // الهيدر
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
                        child: Icon(Icons.arrow_right, color: isDark ? Colors.white : Colors.black, size: 20),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'منتجاتي',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              // المحتوى
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        'حول تطبيق منتجاتي',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'تطبيق منتجاتي يساعدك على إدارة وبيع منتجاتك بسهولة وأمان، مع نظام أرباح وسحب مبسط وواضح.',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          height: 1.6,
                          color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'مزايا التطبيق:',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildAboutBullet('نظام أرباح واضح يعرض الأرباح المحققة والمنتظرة للمستخدم.', isDark),
                      _buildAboutBullet('واجهة سهلة الاستخدام تدعم اللغة العربية بالكامل.', isDark),
                      _buildAboutBullet('إدارة طلبات وسجلات سحب الأرباح بشكل منظم.', isDark),
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

  Widget _buildAboutBullet(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFFffd700) : Colors.black.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.cairo(
                fontSize: 14,
                height: 1.6,
                color: isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
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
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // الشعار في الوسط
              Center(
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    'منتجاتي',
                    style: GoogleFonts.amiri(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildProfitsSection(),
              const SizedBox(height: 16),
              _buildThemeModeSection(),
              const SizedBox(height: 16),

              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildMenuItem(context, "💰", "سحب الأرباح", () {
                                widget.onClose?.call();
                                context.push('/withdraw');
                              }),
                              const SizedBox(height: 6),
                              _buildMenuItem(context, "📜", "سجل السحب", () {
                                widget.onClose?.call();
                                context.push('/profits/withdrawal-history');
                              }),
                              const SizedBox(height: 6),
                              _buildMenuItem(context, "📊", "الإحصائيات", () {
                                widget.onClose?.call();
                                context.go('/statistics');
                              }),
                              const SizedBox(height: 6),
                              _buildMenuItem(context, "ℹ️", "حول التطبيق", () {
                                final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
                                widget.onClose?.call();
                                _showAboutDialog(isDark);
                              }),
                              const Spacer(),
                              const SizedBox(height: 16),
                              _buildMenuItem(context, "🚪", "تسجيل الخروج", () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (dialogContext) {
                                    final isDarkDialog = Provider.of<ThemeProvider>(
                                      dialogContext,
                                      listen: false,
                                    ).isDarkMode;
                                    final bgColor = isDarkDialog ? const Color(0xFF0F172A) : Colors.white;
                                    final titleColor = isDarkDialog ? Colors.white : Colors.black87;
                                    final textColor = isDarkDialog
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : Colors.black.withValues(alpha: 0.7);

                                    return Directionality(
                                      textDirection: TextDirection.rtl,
                                      child: AlertDialog(
                                        backgroundColor: bgColor,
                                        elevation: 12,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                                        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                                        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                        title: Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: LinearGradient(
                                                  colors: [Color(0xFFE74C3C), Color(0xFFFFA726)],
                                                  begin: Alignment.topRight,
                                                  end: Alignment.bottomLeft,
                                                ),
                                              ),
                                              child: const Icon(Icons.logout, color: Colors.white),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'تأكيد تسجيل الخروج',
                                                style: GoogleFonts.cairo(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: titleColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        content: Text(
                                          'هل أنت متأكد أنك تريد تسجيل الخروج من حسابك؟',
                                          style: GoogleFonts.cairo(fontSize: 14, height: 1.6, color: textColor),
                                        ),
                                        actions: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextButton(
                                                  onPressed: () => Navigator.of(dialogContext).pop(false),
                                                  child: Text(
                                                    'إلغاء',
                                                    style: GoogleFonts.cairo(
                                                      fontWeight: FontWeight.w600,
                                                      color: isDarkDialog ? Colors.white : Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFFE74C3C),
                                                    foregroundColor: Colors.white,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    elevation: 0,
                                                  ),
                                                  onPressed: () => Navigator.of(dialogContext).pop(true),
                                                  child: Text(
                                                    'تسجيل الخروج',
                                                    style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );

                                if (confirmed == true) {
                                  widget.onClose?.call();
                                  await AuthService.logout();
                                  if (context.mounted) {
                                    context.go('/login');
                                  }
                                }
                              }, color: const Color(0xFFE74C3C)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // زر الإغلاق على اليسار
        GestureDetector(
          onTap: () {
            widget.onClose?.call();
            context.go('/');
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1),
            ),
            child: Icon(Icons.close, color: isDark ? Colors.white : Colors.black87, size: 18),
          ),
        ),
        const SizedBox(width: 12),
        // الاسم ورقم الهاتف
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _userName.isNotEmpty ? _userName : 'مستخدم',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _userPhone.isNotEmpty ? _userPhone : '---',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // صورة المستخدم على اليمين
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFffd700), Color(0xFFffa500)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              _userName.isNotEmpty ? _userName[0].toUpperCase() : 'م',
              style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeModeSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final modeLabel = isDark ? 'ليلي' : 'نهاري';

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          textDirection: TextDirection.rtl,
          children: [
            // 1) زر التبديل: يكون على أقصى اليمين، ويتفاعل مع كل وضع (نهاري / ليلي)
            GestureDetector(
              onTap: () {
                final provider = Provider.of<ThemeProvider>(context, listen: false);
                final currentlyDark = provider.isDarkMode;

                // نحرك الأنميشن حسب الاتجاه
                if (currentlyDark) {
                  // من ليلي → نهاري: نتحرك من منتصف التايم لاين (0.5) إلى النهاية (1.0)، ثم نرجعه لبداية التايم لاين (0.0)
                  _themeToggleController
                      .animateTo(1.0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut)
                      .then((_) {
                        if (!mounted) return;
                        // نعيد القيمة إلى 0.0 لأنها تمثل نفس شكل النهار في بداية الأنميشن
                        _themeToggleController.value = 0.0;
                      });
                } else {
                  // من نهاري → ليلي: نتحرك من 0.0 إلى المنتصف (0.5) حيث شكل الليل
                  _themeToggleController.animateTo(
                    0.5,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                  );
                }

                // ثم نبدّل وضع التطبيق فعليًا
                provider.toggleTheme();
              },
              child: SizedBox(
                width: 56,
                height: 56,
                child: Lottie.asset(
                  'assets/animations/dark_mode_toggle.json',
                  controller: _themeToggleController,
                  repeat: false,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 2) نص الوضع فقط (ليلي / نهاري)
            Text(
              modeLabel,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 10),
            // 3) الأيقونة تكون الآن في موقع الزر القديم (على اليسار)
            SizedBox(width: 28, height: 28, child: SvgPicture.string(isDark ? _nightModeSvg : _dayModeSvg)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitsSection() {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final screenWidth = MediaQuery.sizeOf(context).width;

    // نجعل البطاقة أصغر وعلى أقصى اليسار بعيداً عن طبقات الشاشة المنسدلة
    double cardMaxWidth = screenWidth * 0.45;
    if (cardMaxWidth > 260) {
      cardMaxWidth = 260;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: cardMaxWidth),
        child: Container(
          margin: const EdgeInsets.only(left: 4),
          padding: EdgeInsets.symmetric(horizontal: screenWidth < 360 ? 10 : 12, vertical: screenWidth < 360 ? 8 : 10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // الأرباح المحققة
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الأرباح المحققة',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.right,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _achievedProfits.toStringAsFixed(0),
                        style: GoogleFonts.cairo(
                          fontSize: screenWidth < 360 ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('IQD', style: GoogleFonts.cairo(fontSize: 10, color: const Color(0xFF4CAF50))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // خط فاصل
              Container(
                height: 1,
                color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 8),
              // الأرباح المنتظرة
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الأرباح المنتظرة',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.right,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _expectedProfits.toStringAsFixed(0),
                        style: GoogleFonts.cairo(
                          fontSize: screenWidth < 360 ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD700),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('IQD', style: GoogleFonts.cairo(fontSize: 10, color: const Color(0xFFFFD700))),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String emoji, String title, VoidCallback onTap, {Color? color}) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textColor = color ?? (isDark ? Colors.white : Colors.black87);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 10),
            Text(emoji, style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
