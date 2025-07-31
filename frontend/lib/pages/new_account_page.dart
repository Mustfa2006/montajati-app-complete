// صفحة الحساب الشخصي - تصميم مفصل ودقيق حسب المواصفات
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../widgets/common_header.dart';
import '../services/real_auth_service.dart';

class NewAccountPage extends StatefulWidget {
  const NewAccountPage({super.key});

  @override
  State<NewAccountPage> createState() => _NewAccountPageState();
}

class _NewAccountPageState extends State<NewAccountPage>
    with TickerProviderStateMixin {
  // متحكمات الحركة
  late AnimationController _animationController;
  late AnimationController _headerAnimationController;
  late AnimationController _particleAnimationController;
  late AnimationController _settingsAnimationController;

  // الحركات
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideDownAnimation;
  late Animation<Offset> _slideUpAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  // تم إزالة _pulseAnimation غير المستخدم

  // متغيرات الإعدادات
  bool _ordersNotifications = true;
  bool _profitsNotifications = true;
  // تم إزالة _offersNotifications غير المستخدم
  bool _darkMode = true; // الوضع الليلي دائماً
  // تم إزالة _twoFactorAuth و _hideAccount غير المستخدمين
  double _fontSize = 100.0;
  double get _fontScale => _fontSize / 100; // معامل تكبير الخط

  // بيانات المستخدم الحقيقية من قاعدة البيانات
  Map<String, dynamic> _userData = {
    'name': 'جاري التحميل...',
    'email': 'جاري التحميل...',
    'phone': 'جاري التحميل...',
    'joinDate': 'جاري التحميل...',
    'totalOrders': 0,
    'totalProfits': 0.0,
    'rating': 0.0,
    'successRate': 0,
    'monthlyProfit': 0.0,
  };

  // متغيرات التحكم في التحميل
  bool _isLoadingUserData = true;
  String? _currentUserPhone;
  // تم إزالة _currentUserId غير المستخدم

  // متغير لإظهار نافذة التعديل
  bool _showEditModal = false;

  @override
  void initState() {
    super.initState();

    // تهيئة المتحكمات
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _headerAnimationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _particleAnimationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _settingsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // تهيئة الحركات
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideDownAnimation =
        Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.elasticOut,
          ),
        );

    _slideUpAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _particleAnimationController,
        curve: Curves.linear,
      ),
    );

    // تم إزالة تعيين _pulseAnimation غير المستخدم

    // بدء الحركات
    _animationController.forward();
    _headerAnimationController.repeat(reverse: true);
    _particleAnimationController.repeat();

    // جلب بيانات المستخدم
    _loadUserData();
  }

  /// جلب بيانات المستخدم من قاعدة البيانات
  Future<void> _loadUserData() async {
    try {
      debugPrint('🔄 بدء تحميل بيانات المستخدم...');

      // الحصول على المستخدم الحالي
      final prefs = await SharedPreferences.getInstance();
      _currentUserPhone = prefs.getString('current_user_phone');
      // تم إزالة تعيين _currentUserId غير المستخدم

      if (_currentUserPhone == null || _currentUserPhone!.isEmpty) {
        debugPrint('❌ لا يوجد مستخدم مسجل دخول');
        setState(() => _isLoadingUserData = false);
        return;
      }

      debugPrint('📱 رقم هاتف المستخدم: $_currentUserPhone');

      // جلب بيانات المستخدم من قاعدة البيانات
      final response = await Supabase.instance.client
          .from('users')
          .select(
            'id, name, phone, email, created_at, achieved_profits, expected_profits, is_admin',
          )
          .eq('phone', _currentUserPhone!)
          .maybeSingle();

      if (response != null) {
        debugPrint('✅ تم جلب بيانات المستخدم: $response');

        // تنسيق تاريخ التسجيل
        String formattedDate = 'غير محدد';
        if (response['created_at'] != null) {
          try {
            final createdAt = DateTime.parse(response['created_at']);
            formattedDate = DateFormat('dd MMMM yyyy', 'ar').format(createdAt);
          } catch (e) {
            debugPrint('خطأ في تنسيق التاريخ: $e');
          }
        }

        // حساب عدد الطلبات الحقيقي
        int totalOrders = 0;
        try {
          final ordersResponse = await Supabase.instance.client
              .from('orders')
              .select('id')
              .eq('user_id', response['id']);
          totalOrders = ordersResponse.length;
          debugPrint('📊 عدد الطلبات: $totalOrders');
        } catch (e) {
          debugPrint('خطأ في حساب عدد الطلبات: $e');
        }

        // حساب إحصائيات المستخدم
        final totalProfits =
            (response['achieved_profits'] ?? 0.0) +
            (response['expected_profits'] ?? 0.0);

        setState(() {
          _userData = {
            'name': response['name'] ?? 'غير محدد',
            'email': response['email'] ?? '$_currentUserPhone@montajati.com',
            'phone': response['phone'] ?? _currentUserPhone,
            'joinDate': formattedDate,
            'totalOrders': totalOrders,
            'totalProfits': totalProfits,
            'rating': 4.8, // قيمة افتراضية
            'successRate': 95, // قيمة افتراضية
            'monthlyProfit': response['achieved_profits'] ?? 0.0,
          };
          _isLoadingUserData = false;
        });

        debugPrint('✅ تم تحديث بيانات المستخدم في الواجهة');
      } else {
        debugPrint('❌ لم يتم العثور على المستخدم في قاعدة البيانات');
        setState(() => _isLoadingUserData = false);
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب بيانات المستخدم: $e');
      setState(() => _isLoadingUserData = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _headerAnimationController.dispose();
    _particleAnimationController.dispose();
    _settingsAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e), // خلفية ليلية دائماً
      extendBody: true, // إزالة الخلفية السوداء خلف الشريط السفلي
      body: Stack(
        children: [
          // خلفية متحركة مع جزيئات
          _buildAnimatedBackground(),

          // المحتوى الرئيسي
          Column(
            children: [
              // الشريط العلوي الموحد
              CommonHeader(
                title: 'حسابي',
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

              // محتوى الصفحة مع حركات
              Expanded(
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(
                          left: 12.5,
                          right: 12.5,
                          top: 25,
                          bottom: 100, // مساحة للشريط السفلي
                        ),
                        child: Column(
                          children: [
                            // بطاقة المعلومات الشخصية المفصلة
                            SlideTransition(
                              position: _slideDownAnimation,
                              child: ScaleTransition(
                                scale: _scaleAnimation,
                                child: _buildDetailedUserInfoCard(),
                              ),
                            ),

                            const SizedBox(height: 25),

                            // قسم الإعدادات السريعة
                            SlideTransition(
                              position: _slideUpAnimation,
                              child: _buildQuickSettingsSection(),
                            ),

                            const SizedBox(height: 25),

                            // قسم الإجراءات والروابط
                            SlideTransition(
                              position: _slideUpAnimation,
                              child: _buildActionsSection(),
                            ),

                            const SizedBox(height: 30),

                            // زر تسجيل الخروج
                            SlideTransition(
                              position: _slideUpAnimation,
                              child: _buildLogoutButton(),
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // نافذة تعديل المعلومات
          if (_showEditModal) _buildEditModal(),
        ],
      ),

      // شريط التنقل السفلي
      bottomNavigationBar: const CustomBottomNavigationBar(
        currentRoute: '/account',
      ),
    );
  }

  // تم حذف _buildNavButton غير المستخدم

  // بناء الخلفية المتحركة مع جزيئات
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _particleAnimationController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1a1a2e), Color(0xFF16213e)], // وضع ليلي دائماً
            ),
          ),
          child: Stack(
            children: List.generate(20, (index) {
              return Positioned(
                left: (index * 50.0) % MediaQuery.of(context).size.width,
                top: (index * 80.0) % MediaQuery.of(context).size.height,
                child: Transform.rotate(
                  angle: _rotationAnimation.value * 2 * 3.14159,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFffd700).withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFffd700).withValues(alpha: 0.2),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }



  // بناء بطاقة المعلومات الشخصية المفصلة
  Widget _buildDetailedUserInfoCard() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.95,
      height: 140, // ✅ تصغير من 200 إلى 140
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667eea).withValues(alpha: 0.1),
            const Color(0xFFf093fb).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF667eea).withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15), // ✅ تصغير من 20 إلى 15
        child: Row(
          children: [
            // صورة الملف الشخصي (يسار البطاقة)
            _buildProfileImage(),

            const SizedBox(width: 15), // ✅ تصغير من 20 إلى 15
            // المعلومات الأساسية (وسط البطاقة)
            Expanded(child: _buildUserBasicInfo()),
          ],
        ),
      ),
    );
  }

  // بناء صورة الملف الشخصي
  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: _changeProfileImage,
      child: Container(
        width: 45, // ✅ تصغير أكثر من 50 إلى 45
        height: 45, // ✅ تصغير أكثر من 50 إلى 45
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2), // تصغير الحدود
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFffd700), Color(0xFFe6b31e)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          FontAwesomeIcons.user,
          color: Color(0xFF1a1a2e),
          size: 28, // ✅ تصغير من 35 إلى 28
        ),
      ),
    );
  }

  // بناء المعلومات الأساسية للمستخدم
  Widget _buildUserBasicInfo() {
    if (_isLoadingUserData) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFffd700), strokeWidth: 2),
            SizedBox(height: 8),
            Text(
              'جاري تحميل البيانات...',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // اسم المستخدم
        Text(
          _userData['name'],
          style: GoogleFonts.cairo(
            fontSize: 18, // تصغير من 22.4 إلى 18
            fontWeight: FontWeight.w700,
            color: _darkMode ? Colors.white : const Color(0xFF1a1a2e),
            letterSpacing: 0.5,
          ),
        ),

        const SizedBox(height: 8),

        // ✅ تم إخفاء البريد الإلكتروني حسب الطلب
        const SizedBox(height: 6),

        // رقم الهاتف
        Row(
          children: [
            const Icon(
              FontAwesomeIcons.phone,
              color: Color(0xFF28a745),
              size: 14,
            ),
            const SizedBox(width: 8),
            Text(
              _userData['phone'],
              style: GoogleFonts.cairo(
                fontSize: 13, // تصغير من 16 إلى 13
                fontWeight: FontWeight.w500,
                color: Colors.white70, // أبيض في الوضع الليلي
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // تاريخ التسجيل
        Row(
          children: [
            const Icon(
              FontAwesomeIcons.calendarDays,
              color: Color(0xFFffc107),
              size: 14,
            ),
            const SizedBox(width: 8),
            Text(
              'عضو منذ: ${_userData['joinDate']}',
              style: GoogleFonts.cairo(
                fontSize: 12, // تصغير من 14.4 إلى 12
                fontWeight: FontWeight.w400,
                color: Colors.white70, // أبيض في الوضع الليلي
              ),
            ),
          ],
        ),
      ],
    );
  }

  // بناء قسم الإعدادات السريعة
  Widget _buildQuickSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان القسم
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.5),
          child: Row(
            children: [
              const Icon(
                FontAwesomeIcons.sliders,
                color: Color(0xFF667eea),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'الإعدادات السريعة',
                style: GoogleFonts.cairo(
                  fontSize: 20.8, // 1.3rem
                  fontWeight: FontWeight.w700,
                  color: _darkMode ? Colors.white : const Color(0xFF1a1a2e),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 15),

        // شبكة البطاقات
        Row(
          children: [
            // بطاقة إعدادات الإشعارات
            Expanded(child: _buildNotificationsCard()),
            const SizedBox(width: 15),
            // بطاقة الأمان والخصوصية
            Expanded(child: _buildSecurityCard()),
          ],
        ),

        const SizedBox(height: 15),

        // الصف الثاني من البطاقات
        Row(
          children: [
            // بطاقة إعدادات المظهر
            Expanded(child: _buildAppearanceCard()),
            const SizedBox(width: 15),
            // بطاقة الإحصائيات الشخصية
            Expanded(child: _buildPersonalStatsCard()),
          ],
        ),
      ],
    );
  }

  // بطاقة إعدادات الإشعارات
  Widget _buildNotificationsCard() {
    return Container(
      height: 120, // تكبير المربعات قليلاً
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05), // خلفية شفافة للوضع الليلي
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFF17a2b8),
          width: 1,
        ), // تقليل سمك الحدود
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17a2b8).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10), // تقليل padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // تقليل المساحة المطلوبة
          children: [
            // العنوان
            Row(
              children: [
                const Icon(
                  FontAwesomeIcons.bell,
                  color: Color(0xFF17a2b8),
                  size: 14, // تقليل حجم الأيقونة
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'الإشعارات',
                    style: GoogleFonts.cairo(
                      fontSize: 13 * _fontScale, // تطبيق معامل تكبير الخط
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4), // تقليل المسافة أكثر
            // المفاتيح مع فراغ بسيط
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCompactToggleSwitch(
                    'إشعارات الطلبات',
                    _ordersNotifications,
                  ),
                  const SizedBox(height: 12), // فراغ أكبر بين الإشعارات
                  _buildCompactToggleSwitch(
                    'إشعارات الأرباح',
                    _profitsNotifications,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بطاقة الأمان والخصوصية
  Widget _buildSecurityCard() {
    return Container(
      height: 120, // تكبير المربعات قليلاً
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05), // خلفية شفافة للوضع الليلي
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFdc3545),
          width: 1,
        ), // تقليل سمك الحدود
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFdc3545).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان
            Row(
              children: [
                const Icon(
                  FontAwesomeIcons.shieldHalved,
                  color: Color(0xFFdc3545),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الأمان والخصوصية',
                    style: GoogleFonts.cairo(
                      fontSize: 13 * _fontScale, // تطبيق معامل تكبير الخط
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4), // تقليل المسافة
            // زر الدعم - في الوسط بالضبط
            Expanded(
              child: Center(
                child: _buildSmallButton(
                  'تغيير كلمة المرور',
                  const Color(0xFFffc107),
                  FontAwesomeIcons.key,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بطاقة إعدادات المظهر
  Widget _buildAppearanceCard() {
    return Container(
      height: 120, // تكبير المربعات قليلاً
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05), // خلفية شفافة للوضع الليلي
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFF6f42c1),
          width: 1,
        ), // تقليل سمك الحدود
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6f42c1).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان
            Row(
              children: [
                const Icon(
                  FontAwesomeIcons.palette,
                  color: Color(0xFF6f42c1),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'المظهر',
                  style: GoogleFonts.cairo(
                    fontSize: 13, // تصغير أكثر
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4), // تقليل المسافة
            // خيارات المظهر - شريط حجم الخط فقط
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [_buildCompactFontSizeSlider()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بطاقة الإحصائيات الشخصية
  Widget _buildPersonalStatsCard() {
    return Container(
      height: 120, // تكبير المربعات قليلاً
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05), // خلفية شفافة للوضع الليلي
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFF28a745),
          width: 1,
        ), // تقليل سمك الحدود
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF28a745).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان
            Row(
              children: [
                const Icon(
                  FontAwesomeIcons.chartBar,
                  color: Color(0xFF28a745),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'إحصائياتي',
                  style: GoogleFonts.cairo(
                    fontSize: 17.6, // 1.1rem
                    fontWeight: FontWeight.w600,
                    color: _darkMode ? Colors.white : const Color(0xFF1a1a2e),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // الإحصائيات
            Row(
              children: [
                const Icon(
                  FontAwesomeIcons.circleCheck,
                  color: Color(0xFF28a745),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_userData['successRate']}% معدل نجاح',
                  style: GoogleFonts.cairo(
                    fontSize: 14.4,
                    color: const Color(0xFF28a745),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  FontAwesomeIcons.coins,
                  color: Color(0xFFffc107),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  '${(_userData['monthlyProfit'] / 1000).toStringAsFixed(0)}K د.ع/شهر',
                  style: GoogleFonts.cairo(
                    fontSize: 14.4,
                    color: const Color(0xFFffc107),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // تم حذف _buildToggleSwitch غير المستخدم

  // بناء مفتاح تبديل مضغوط للبطاقات الصغيرة
  Widget _buildCompactToggleSwitch(String title, bool value) {
    return Container(
      height: 18, // ارتفاع أصغر
      margin: EdgeInsets.zero, // إزالة أي هوامش
      padding: EdgeInsets.zero, // إزالة أي حشو
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 11, // خط أصغر أكثر
                fontWeight: FontWeight.w500,
                color: Colors.white70,
                height: 1.0, // تقليل ارتفاع السطر
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Transform.scale(
            scale: 0.6, // مفتاح أصغر أكثر
            child: Switch(
              value: value,
              onChanged: (newValue) {
                setState(() {
                  if (title == 'إشعارات الطلبات') {
                    _ordersNotifications = newValue;
                  } else if (title == 'إشعارات الأرباح') {
                    _profitsNotifications = newValue;
                  } else if (title == 'الوضع الليلي') {
                    _darkMode = newValue;
                  }
                });
              },
              activeColor: const Color(0xFF28a745),
              inactiveThumbColor: const Color(0xFF6c757d),
              materialTapTargetSize:
                  MaterialTapTargetSize.shrinkWrap, // تقليل منطقة اللمس
            ),
          ),
        ],
      ),
    );
  }

  // بناء زر صغير
  Widget _buildSmallButton(String title, Color color, IconData icon) {
    return GestureDetector(
      onTap: () {
        if (title == 'تغيير كلمة المرور') {
          _openTelegramSupport();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 12),
            const SizedBox(width: 4),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 11.2,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // تم حذف _buildFontSizeSlider غير المستخدم

  // بناء شريط تمرير حجم الخط مضغوط
  Widget _buildCompactFontSizeSlider() {
    return Row(
      children: [
        Text(
          'حجم الخط',
          style: GoogleFonts.cairo(
            fontSize: 10, // خط أصغر
            color: Colors.white70,
          ),
        ),
        Expanded(
          child: Transform.scale(
            scale: 0.8, // تصغير الشريط
            child: Slider(
              value: _fontSize,
              min: 80,
              max: 120,
              divisions: 4,
              onChanged: (value) {
                setState(() {
                  _fontSize = value;
                });
              },
              activeColor: const Color(0xFF6f42c1),
              inactiveColor: const Color(0xFF6f42c1).withValues(alpha: 0.3),
            ),
          ),
        ),
      ],
    );
  }

  // بناء قسم الإجراءات والروابط
  Widget _buildActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان القسم
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.5),
          child: Text(
            'الإجراءات والروابط',
            style: GoogleFonts.cairo(
              fontSize: 20.8, // 1.3rem
              fontWeight: FontWeight.w700,
              color: _darkMode ? Colors.white : const Color(0xFF1a1a2e),
            ),
          ),
        ),

        const SizedBox(height: 15),

        // الأزرار
        _buildActionButton(
          title: 'تعديل المعلومات الشخصية',
          icon: FontAwesomeIcons.penToSquare,
          gradient: const LinearGradient(
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ], // ألوان متناسقة مع الشريط العلوي
          ),
          onTap: _editPersonalInfo,
        ),

        const SizedBox(height: 15),

        _buildActionButton(
          title: 'عرض الأرباح التفصيلية',
          icon: FontAwesomeIcons.chartLine,
          gradient: const LinearGradient(
            colors: [Color(0xFFffd700), Color(0xFFe6b31e)], // ألوان ذهبية
          ),
          textColor: const Color(0xFF1a1a2e), // نص داكن على خلفية ذهبية
          onTap: _viewDetailedProfits,
        ),

        const SizedBox(height: 15),

        _buildActionButton(
          title: 'الدعم والمساعدة',
          icon: FontAwesomeIcons.headset,
          gradient: const LinearGradient(
            colors: [Color(0xFF6f42c1), Color(0xFF5a2d91)], // بنفسجي
          ),
          onTap: _openSupport,
        ),

        // ✅ تم حذف زر اختبار النظام حسب الطلب
      ],
    );
  }

  // بناء زر إجراء
  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required LinearGradient gradient,
    Color textColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 50,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 16, // 1rem
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بناء زر تسجيل الخروج
  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _showLogoutDialog,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 45,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFdc3545), Color(0xFFc82333)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFdc3545).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              FontAwesomeIcons.rightFromBracket,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 12),
            Text(
              'تسجيل الخروج',
              style: GoogleFonts.cairo(
                fontSize: 16, // 1rem
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بناء نافذة تعديل المعلومات - محسنة ومنظمة
  Widget _buildEditModal() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withValues(alpha: 0.8), // خلفية أغمق
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.92,
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a2e),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: const Color(0xFFffd700).withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 50,
                offset: const Offset(0, 25),
              ),
              BoxShadow(
                color: const Color(0xFFffd700).withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // شريط العنوان المحسن
              Container(
                height: 65,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF007bff), Color(0xFF0056b3)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // أيقونة التعديل
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          FontAwesomeIcons.userPen,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 15),
                      // العنوان
                      Expanded(
                        child: Text(
                          'تعديل المعلومات الشخصية',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // زر الإغلاق
                      GestureDetector(
                        onTap: _closeEditModal,
                        child: Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            FontAwesomeIcons.xmark,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // محتوى النافذة المحسن
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    children: [
                      // حقول التعديل مع تباعد أفضل
                      _buildEditField(
                        'الاسم الكامل',
                        _userData['name'],
                        FontAwesomeIcons.user,
                      ),
                      const SizedBox(height: 20),
                      // ✅ تم إخفاء حقل البريد الإلكتروني حسب الطلب
                      _buildEditField(
                        'رقم الهاتف',
                        _userData['phone'],
                        FontAwesomeIcons.phone,
                      ),
                      const SizedBox(height: 40),

                      // أزرار الإجراء المحسنة
                      Row(
                        children: [
                          // زر الإلغاء
                          Expanded(
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6c757d),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF6c757d,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _closeEditModal,
                                  borderRadius: BorderRadius.circular(25),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          FontAwesomeIcons.xmark,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'إلغاء',
                                          style: GoogleFonts.cairo(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          // زر الحفظ
                          Expanded(
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF28a745),
                                    Color(0xFF20c997),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF28a745,
                                    ).withValues(alpha: 0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _saveChanges,
                                  borderRadius: BorderRadius.circular(25),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          FontAwesomeIcons.floppyDisk,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'حفظ التغييرات',
                                          style: GoogleFonts.cairo(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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

  // بناء حقل تعديل محسن
  Widget _buildEditField(
    String label,
    String value,
    IconData icon, {
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // تسمية الحقل
        Padding(
          padding: const EdgeInsets.only(right: 5),
          child: Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFffd700),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // حقل الإدخال
        Container(
          height: 55,
          decoration: BoxDecoration(
            color: const Color(0xFF16213e),
            border: Border.all(
              color: const Color(0xFFffd700).withValues(alpha: 0.4),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFffd700).withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 18),
              // أيقونة الحقل
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: const Color(0xFFffd700).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFFffd700), size: 18),
              ),
              const SizedBox(width: 15),
              // حقل النص
              Expanded(
                child: TextFormField(
                  initialValue: value,
                  obscureText: isPassword,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: isPassword
                        ? 'أدخل كلمة المرور الجديدة'
                        : 'أدخل القيمة الجديدة',
                    hintStyle: GoogleFonts.cairo(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
            ],
          ),
        ),
      ],
    );
  }

  // الدوال المطلوبة للوظائف

  // تغيير صورة الملف الشخصي
  void _changeProfileImage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // عنوان
              Text(
                'تغيير الصورة الشخصية',
                style: GoogleFonts.cairo(
                  fontSize: 18 * _fontScale,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              // خيارات تغيير الصورة
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // الكاميرا
                  _buildImageOption(
                    icon: FontAwesomeIcons.camera,
                    label: 'الكاميرا',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromCamera();
                    },
                  ),
                  // المعرض
                  _buildImageOption(
                    icon: FontAwesomeIcons.image,
                    label: 'المعرض',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                  ),
                  // حذف الصورة
                  _buildImageOption(
                    icon: FontAwesomeIcons.trash,
                    label: 'حذف',
                    color: const Color(0xFFdc3545),
                    onTap: () {
                      Navigator.pop(context);
                      _removeProfileImage();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // بناء خيار الصورة
  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: (color ?? const Color(0xFF667eea)).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color ?? const Color(0xFF667eea), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color ?? const Color(0xFF667eea), size: 24),
            const SizedBox(height: 5),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12 * _fontScale,
                fontWeight: FontWeight.w600,
                color: color ?? const Color(0xFF667eea),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // التقاط صورة من الكاميرا
  void _pickImageFromCamera() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'فتح الكاميرا لالتقاط صورة جديدة',
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: const Color(0xFF28a745),
      ),
    );
  }

  // اختيار صورة من المعرض
  void _pickImageFromGallery() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'فتح معرض الصور لاختيار صورة',
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: const Color(0xFF007bff),
      ),
    );
  }

  // حذف الصورة الشخصية
  void _removeProfileImage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حذف الصورة الشخصية', style: GoogleFonts.cairo()),
        backgroundColor: const Color(0xFFdc3545),
      ),
    );
  }

  // ✅ تم حذف الدوال غير المستخدمة

  // تعديل المعلومات الشخصية
  void _editPersonalInfo() {
    setState(() {
      _showEditModal = true;
    });
  }

  // عرض الأرباح التفصيلية
  void _viewDetailedProfits() {
    context.push('/profits');
  }

  // فتح الدعم والمساعدة - التلغرام
  void _openSupport() async {
    const telegramUrl = 'https://t.me/montajati_support';

    try {
      final Uri url = Uri.parse(telegramUrl);

      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication, // فتح في تطبيق التلغرام
        );
      } else {
        // إذا لم يتمكن من فتح التلغرام، اعرض رسالة مع الرابط
        if (mounted) {
          _showTelegramDialog();
        }
      }
    } catch (e) {
      // في حالة حدوث خطأ، اعرض رسالة مع الرابط
      if (mounted) {
        _showTelegramDialog();
      }
    }
  }

  // عرض نافذة معلومات التلغرام
  void _showTelegramDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1a1a2e),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0088cc), Color(0xFF006bb3)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  FontAwesomeIcons.telegram,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  'الدعم والمساعدة',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'للحصول على الدعم والمساعدة، تواصل معنا عبر التلغرام:',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 15),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213e),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF0088cc), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      FontAwesomeIcons.at,
                      color: Color(0xFF0088cc),
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'montajati_support',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0088cc),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'إغلاق',
                style: GoogleFonts.cairo(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // محاولة فتح التلغرام مرة أخرى
                const telegramUrl = 'https://t.me/montajati_support';
                final Uri url = Uri.parse(telegramUrl);
                await launchUrl(url, mode: LaunchMode.externalApplication);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0088cc),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(FontAwesomeIcons.telegram, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'فتح التلغرام',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // إظهار نافذة تسجيل الخروج
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'تسجيل الخروج',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'هل أنت متأكد من رغبتك في تسجيل الخروج؟',
            style: GoogleFonts.cairo(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'إلغاء',
                style: GoogleFonts.cairo(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // حفظ BuildContext قبل العملية غير المتزامنة
                final navigator = Navigator.of(context);
                final router = GoRouter.of(context);

                navigator.pop();

                // تسجيل الخروج باستخدام خدمة المصادقة
                await AuthService.logout();

                // التوجه لصفحة الترحيب
                if (mounted) {
                  router.go('/welcome');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFdc3545),
                foregroundColor: Colors.white,
              ),
              child: Text(
                'تسجيل الخروج',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  // إغلاق نافذة التعديل
  void _closeEditModal() {
    setState(() {
      _showEditModal = false;
    });
  }

  // حفظ التغييرات
  void _saveChanges() {
    // منطق حفظ التغييرات
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حفظ التغييرات بنجاح', style: GoogleFonts.cairo()),
        backgroundColor: const Color(0xFF28a745),
      ),
    );
    _closeEditModal();
  }

  // فتح دعم التلغرام مع رسالة تغيير كلمة المرور
  Future<void> _openTelegramSupport() async {
    try {
      // إعداد الرسالة مع بيانات المستخدم الحقيقية
      final userName = _userData['name'] ?? 'غير محدد';
      final userPhone = _userData['phone'] ?? _currentUserPhone ?? 'غير محدد';

      final message =
          '''مرحباً، أريد تغيير كلمة المرور في تطبيق منتجاتي

اسم المستخدم: $userName
رقم الهاتف: $userPhone''';

      // ترميز الرسالة للـ URL
      final encodedMessage = Uri.encodeComponent(message);

      // إنشاء رابط التلغرام مع الرسالة
      final telegramUrl = 'https://t.me/montajati_support?text=$encodedMessage';

      debugPrint('📱 فتح التلغرام مع الرسالة: $message');

      final Uri url = Uri.parse(telegramUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        debugPrint('✅ تم فتح رابط التلغرام بنجاح');

        // عرض رسالة تأكيد للمستخدم
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم فتح التلغرام. سيتم التواصل معك قريباً لتغيير كلمة المرور.',
                style: GoogleFonts.cairo(),
              ),
              backgroundColor: const Color(0xFF28a745),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        throw Exception('لا يمكن فتح تطبيق التلغرام');
      }
    } catch (e) {
      debugPrint('❌ خطأ في فتح رابط التلغرام: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في فتح التلغرام. تأكد من تثبيت التطبيق أو جرب مرة أخرى.',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
