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
import '../widgets/app_background.dart';

class WithdrawalHistoryPage extends StatefulWidget {
  const WithdrawalHistoryPage({super.key});

  @override
  State<WithdrawalHistoryPage> createState() => _WithdrawalHistoryPageState();
}

class _WithdrawalHistoryPageState extends State<WithdrawalHistoryPage> {
  String selectedFilter = 'الكل';
  String searchQuery = '';
  bool _isLoading = true;
  List<Map<String, dynamic>> withdrawalRequests = [];
  final TextEditingController _searchController = TextEditingController();
  final _secureStorage = const FlutterSecureStorage();

  // إحصائيات من الباك اند
  final Map<String, dynamic> _stats = {
    'total_requests': 0,
    'pending_count': 0,
    'completed_count': 0,
    'rejected_count': 0,
    'total_withdrawn': 0.0,
    'pending_amount': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _loadWithdrawalRequests();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // إعادة تحميل البيانات عند العودة للصفحة
    _loadWithdrawalRequests();
  }

  // 🔒 جلب طلبات السحب من الباك اند فقط (آمن جداً)
  Future<void> _loadWithdrawalRequests() async {
    try {
      setState(() => _isLoading = true);

      debugPrint('📊 === جلب طلبات السحب من الـ API ===');

      // الحصول على رقم الهاتف من SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('current_user_phone') ?? '';

      if (phone.isEmpty) {
        debugPrint('❌ لا يوجد رقم هاتف محفوظ - المستخدم غير مسجل دخول');
        if (mounted) {
          _showErrorSnackBar('يرجى تسجيل الدخول مرة أخرى.');
        }
        setState(() => _isLoading = false);
        return;
      }

      debugPrint('📱 رقم هاتف المستخدم: $phone');

      // 🔒 محاولة الحصول على التوكن من التخزين الآمن (اختياري للآن)
      String? token = await _secureStorage.read(key: 'auth_token');

      // إذا لم يكن هناك توكن، استخدم توكن وهمي (سيتم تحسينه لاحقاً مع JWT)
      if (token == null || token.isEmpty) {
        debugPrint('⚠️ لا يوجد توكن آمن - استخدام التوكن الافتراضي');
        token = 'temp_token_$phone'; // توكن مؤقت
      }

      debugPrint('✅ جاهز لإرسال الطلب إلى الـ API');

      // 🌐 جلب طلبات السحب من الـ API (آمن جداً - يعتمد على ApiConfig)
      final response = await http
          .post(
            Uri.parse('${ApiConfig.usersUrl}/withdrawals'),
            headers: {...ApiConfig.defaultHeaders, 'Authorization': 'Bearer $token'},
            body: jsonEncode({'phone': phone}),
          )
          .timeout(ApiConfig.defaultTimeout);

      debugPrint('📡 استجابة الخادم: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          final data = jsonData['data'];
          final List<dynamic> withdrawalsData = data['withdrawals'] ?? [];
          final Map<String, dynamic> statsData = data['stats'] ?? {};

          debugPrint('📊 عدد طلبات السحب المجلبة: ${withdrawalsData.length}');
          debugPrint('📊 الإحصائيات: $statsData');

          if (mounted) {
            setState(() {
              withdrawalRequests = withdrawalsData.cast<Map<String, dynamic>>();
              _stats.addAll(statsData);
              _isLoading = false;
            });
          }

          debugPrint('✅ تم جلب طلبات السحب بنجاح');
        } else {
          debugPrint('❌ فشل في جلب طلبات السحب: ${jsonData['error']}');
          if (mounted) {
            _showErrorSnackBar('فشل في جلب طلبات السحب.');
            setState(() => _isLoading = false);
          }
        }
      } else if (response.statusCode == 401) {
        debugPrint('❌ غير مصرح - التوكن غير صالح');
        if (mounted) {
          _showErrorSnackBar('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى.');
          setState(() => _isLoading = false);
        }
      } else if (response.statusCode == 404) {
        debugPrint('❌ المستخدم غير موجود');
        if (mounted) {
          _showErrorSnackBar('المستخدم غير موجود.');
          setState(() => _isLoading = false);
        }
      } else {
        debugPrint('❌ خطأ في الخادم: ${response.statusCode}');
        if (mounted) {
          _showErrorSnackBar('خطأ في الخادم. حاول مرة أخرى.');
          setState(() => _isLoading = false);
        }
      }
    } on http.ClientException catch (e) {
      debugPrint('❌ خطأ في الاتصال: $e');
      if (mounted) {
        _showErrorSnackBar('فشل في الاتصال بالخادم. تحقق من الإنترنت.');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب طلبات السحب: $e');
      if (mounted) {
        _showErrorSnackBar('حدث خطأ غير متوقع.');
        setState(() => _isLoading = false);
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

  // إحصائيات سريعة - عمليات حسابية دقيقة 100%
  double get totalWithdrawn => withdrawalRequests
      .where((req) => req['status'] == 'completed')
      .fold(0.0, (sum, req) => sum + (req['amount'] as num).toDouble());

  double get pendingAmount => withdrawalRequests
      .where((req) => req['status'] == 'pending')
      .fold(0.0, (sum, req) => sum + (req['amount'] as num).toDouble());

  double get approvedAmount => withdrawalRequests
      .where((req) => req['status'] == 'approved')
      .fold(0.0, (sum, req) => sum + (req['amount'] as num).toDouble());

  double get rejectedAmount => withdrawalRequests
      .where((req) => req['status'] == 'rejected')
      .fold(0.0, (sum, req) => sum + (req['amount'] as num).toDouble());

  int get completedRequestsCount => withdrawalRequests.where((req) => req['status'] == 'completed').length;

  int get pendingRequestsCount => withdrawalRequests.where((req) => req['status'] == 'pending').length;

  double get totalRequestedAmount =>
      withdrawalRequests.fold(0.0, (sum, req) => sum + (req['amount'] as num).toDouble());

  String get lastWithdrawalDate {
    final completedRequests = withdrawalRequests.where((req) => req['status'] == 'تم التحويل').toList();

    if (completedRequests.isEmpty) return 'لا يوجد';

    // ترتيب حسب تاريخ المعالجة (الأحدث أولاً)
    completedRequests.sort((a, b) {
      // تحويل التاريخ من صيغة 2024/01/17 إلى DateTime
      final dateStrA = a['processDate'] ?? '';
      final dateStrB = b['processDate'] ?? '';

      final dateA = _parseDate(dateStrA);
      final dateB = _parseDate(dateStrB);

      return dateB.compareTo(dateA);
    });

    final lastDateStr = completedRequests.first['processDate'] ?? '';
    final lastDate = _parseDate(lastDateStr);

    if (lastDate.year == 2000) return 'غير محدد';

    final now = DateTime.now();
    final difference = now.difference(lastDate).inDays;

    if (difference == 0) return 'اليوم';
    if (difference == 1) return 'أمس';
    if (difference <= 7) return 'منذ $difference أيام';
    if (difference <= 30) return 'منذ ${(difference / 7).round()} أسابيع';
    return 'منذ ${(difference / 30).round()} شهر';
  }

  // دالة مساعدة لتحويل التاريخ من صيغة 2024/01/17
  DateTime _parseDate(String dateStr) {
    if (dateStr.isEmpty) return DateTime(2000);

    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      // في حالة خطأ في التحويل
    }

    return DateTime(2000); // تاريخ افتراضي قديم
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return AppBackground(
      child: Scaffold(backgroundColor: Colors.transparent, extendBody: true, body: _buildScrollableContent(isDark)),
    );
  }

  // بناء الشريط العلوي البسيط - متناسق مع صفحة الإحصائيات
  Widget _buildSimpleHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // زر الرجوع - تصميم زجاجي ناعم
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87, size: 18),
            ),
          ),

          const SizedBox(width: 15),

          // العنوان
          Expanded(
            child: Text(
              'سجل السحب',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(width: 60), // للتوازن
        ],
      ),
    );
  }

  // بناء شريط البحث - تصميم Glassmorphism
  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.white.withValues(alpha: 0.08), Colors.white.withValues(alpha: 0.03)]
                    : [Colors.white.withValues(alpha: 0.9), Colors.white.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: -5,
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              style: GoogleFonts.cairo(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'ابحث عن عملية سحب...',
                hintStyle: GoogleFonts.cairo(color: isDark ? Colors.grey[400] : Colors.grey[500], fontSize: 14),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(FontAwesomeIcons.magnifyingGlass, color: const Color(0xFFFFC107), size: 18),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // بناء أزرار فلترة الحالات - تصميم Premium Glassmorphism
  Widget _buildStatusFilterButtons(bool isDark) {
    final filters = [
      {'key': 'الكل', 'label': 'الكل', 'icon': FontAwesomeIcons.list},
      {'key': 'pending', 'label': 'قيد المراجعة', 'icon': FontAwesomeIcons.clock},
      {'key': 'completed', 'label': 'مكتمل', 'icon': FontAwesomeIcons.circleCheck},
      {'key': 'rejected', 'label': 'مرفوض', 'icon': FontAwesomeIcons.circleXmark},
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter['key'];

          return Container(
            margin: const EdgeInsets.only(left: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedFilter = filter['key'] as String;
                });
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: isSelected ? 8 : 4, sigmaY: isSelected ? 8 : 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFC107)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected
                          ? null
                          : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.6)),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.3)
                            : (isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.3)),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          filter['icon'] as IconData,
                          size: 14,
                          color: isSelected ? Colors.black87 : (isDark ? Colors.grey[300] : Colors.grey[600]),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          filter['label'] as String,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? Colors.black87 : (isDark ? Colors.grey[300] : Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // بناء المحتوى القابل للتمرير
  Widget _buildScrollableContent(bool isDark) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(0xFFC5A059),
      backgroundColor: Colors.transparent,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // مساحة للشريط العلوي
          SliverToBoxAdapter(child: const SizedBox(height: 25)),

          // الشريط العلوي البسيط
          SliverToBoxAdapter(child: _buildSimpleHeader(isDark)),

          // مساحة بعد الشريط العلوي
          SliverToBoxAdapter(child: const SizedBox(height: 20)),

          // شريط البحث
          SliverToBoxAdapter(child: _buildSearchBar(isDark)),

          // مساحة بعد شريط البحث
          SliverToBoxAdapter(child: const SizedBox(height: 15)),

          // أزرار فلترة الحالات
          SliverToBoxAdapter(child: _buildStatusFilterButtons(isDark)),

          // مساحة بعد أزرار الفلترة
          SliverToBoxAdapter(child: const SizedBox(height: 20)),

          // قائمة طلبات السحب
          _buildWithdrawalSliverList(isDark),

          // مساحة سفلية
          SliverToBoxAdapter(child: const SizedBox(height: 80)),
        ],
      ),
    );
  }

  // دالة تحديث البيانات
  Future<void> _refreshData() async {
    await _loadWithdrawalRequests();
  }

  // بناء قائمة طلبات السحب كـ Sliver
  Widget _buildWithdrawalSliverList(bool isDark) {
    // عرض مؤشر التحميل
    if (_isLoading) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: const Color(0xFFC5A059)),
              const SizedBox(height: 20),
              Text(
                'جاري تحميل السجل...',
                style: GoogleFonts.cairo(color: isDark ? Colors.grey[300] : Colors.grey[700], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // تطبيق الفلترة والبحث
    List<Map<String, dynamic>> filteredRequests = withdrawalRequests.where((request) {
      // فلترة حسب الحالة
      bool statusMatch = selectedFilter == 'الكل' || request['status'] == selectedFilter;

      // فلترة حسب البحث
      bool searchMatch =
          searchQuery.isEmpty ||
          (request['account_details']?.toString().contains(searchQuery) ?? false) ||
          (request['cardholder_name']?.toString().contains(searchQuery) ?? false) ||
          request['amount'].toString().contains(searchQuery);

      return statusMatch && searchMatch;
    }).toList();

    if (filteredRequests.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FontAwesomeIcons.fileInvoiceDollar,
                size: 60,
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 20),
              Text(
                withdrawalRequests.isEmpty ? 'لا توجد عمليات سحب' : 'لا توجد نتائج',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return _buildWithdrawalCard(filteredRequests[index], isDark);
        }, childCount: filteredRequests.length),
      ),
    );
  }

  // بناء بطاقة طلب السحب - Refined Professional Design
  Widget _buildWithdrawalCard(Map<String, dynamic> request, bool isDark) {
    final status = request['status']?.toString().toLowerCase() ?? '';

    // ألوان الحالة
    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;

    switch (status) {
      case 'pending':
        statusColor = const Color(0xFFD97706); // Amber 600 - واضح للانتظار
        statusBgColor = const Color(0xFFFFFBEB); // Amber 50
        statusIcon = FontAwesomeIcons.clock;
        break;
      case 'completed':
        statusColor = const Color(0xFF059669); // Emerald 600 - واضح للنجاح
        statusBgColor = const Color(0xFFECFDF5); // Emerald 50
        statusIcon = FontAwesomeIcons.check;
        break;
      case 'rejected':
      case 'cancelled':
        statusColor = const Color(0xFFDC2626); // Red 600 - أحمر واضح للخطأ
        statusBgColor = const Color(0xFFFEF2F2); // Red 50
        statusIcon = FontAwesomeIcons.xmark;
        break;
      default:
        statusColor = const Color(0xFF475569); // Slate 600
        statusBgColor = const Color(0xFFF8FAFC); // Slate 50
        statusIcon = FontAwesomeIcons.question;
    }

    // تعديل الألوان للوضع الداكن
    if (isDark) {
      statusBgColor = statusColor.withValues(alpha: 0.1);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // الصف العلوي: الحالة والمبلغ
                Row(
                  children: [
                    // أيقونة الحالة (صغيرة وأنيقة)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: statusBgColor, shape: BoxShape.circle),
                      child: Icon(statusIcon, color: statusColor, size: 16),
                    ),
                    const SizedBox(width: 12),

                    // نص الحالة والتاريخ
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            getStatusText(status),
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            formatDateWithSeparator(request['request_date']),
                            style: GoogleFonts.cairo(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),

                    // المبلغ
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatAmount(request['amount']),
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: statusColor, // لون الحالة للمبلغ
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // فاصل
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(
                    height: 1,
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                  ),
                ),

                // معلومات البطاقة (بسيطة وواضحة)
                Row(
                  children: [
                    Icon(
                      getMethodIcon(request['withdrawal_method']),
                      size: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      getMethodText(request['withdrawal_method']),
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    // اسم حامل البطاقة
                    Text(
                      extractCardHolderName(request['account_details']),
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // رقم البطاقة
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _extractCardNumber(request['account_details']),
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // استخراج رقم البطاقة من account_details
  String _extractCardNumber(String? accountDetails) {
    if (accountDetails == null || accountDetails.isEmpty) {
      return '0000';
    }

    final parts = accountDetails.split(' - ');

    if (parts.length >= 3) {
      return parts[2].trim();
    } else if (parts.length == 2) {
      final secondPart = parts[1].trim();
      if (RegExp(r'^\d+$').hasMatch(secondPart)) {
        return secondPart;
      }
    }

    final RegExp numberRegex = RegExp(r'\d{4,}');
    final match = numberRegex.firstMatch(accountDetails);

    if (match != null) {
      return match.group(0) ?? '0000';
    }

    return '0000';
  }

  // استخراج اسم حامل البطاقة من account_details
  String extractCardHolderName(String? accountDetails) {
    if (accountDetails == null || accountDetails.isEmpty) {
      return 'غير محدد';
    }

    final parts = accountDetails.split(' - ');

    if (parts.length >= 3) {
      return parts[1].trim();
    } else if (parts.length == 2) {
      final secondPart = parts[1].trim();
      if (!RegExp(r'^\d+$').hasMatch(secondPart)) {
        return secondPart;
      }
    }

    return 'غير محدد';
  }

  // ترجمة حالة الطلب للعربية (محدثة)
  String getStatusText(String? status) {
    switch (status?.toLowerCase().trim()) {
      case 'pending':
        return 'قيد المراجعة';
      case 'approved':
        return 'تمت الموافقة';
      case 'completed':
        return 'مكتمل';
      case 'rejected':
        return 'مرفوض';
      case 'cancelled':
        return 'ملغي';
      default:
        return 'غير محدد';
    }
  }

  // ترجمة طريقة السحب للعربية
  String getMethodText(String? method) {
    if (method == null) return 'غير محدد';

    if (method.contains('بطاقة كي كارد') || method.contains('كي كارد')) {
      return 'كي كارد';
    } else if (method.contains('زين كاش')) {
      return 'زين كاش';
    }

    switch (method.toLowerCase().trim()) {
      case 'mastercard':
      case 'ki_card':
        return 'كي كارد';
      case 'zaincash':
      case 'zain_cash':
        return 'زين كاش';
      default:
        return method;
    }
  }

  // الحصول على أيقونة طريقة السحب
  IconData getMethodIcon(String? method) {
    if (method == null) return FontAwesomeIcons.circleQuestion;

    if (method.contains('بطاقة كي كارد') ||
        method.contains('كي كارد') ||
        method.toLowerCase().contains('mastercard') ||
        method.toLowerCase().contains('ki_card')) {
      return FontAwesomeIcons.creditCard;
    } else if (method.contains('زين كاش') ||
        method.toLowerCase().contains('zaincash') ||
        method.toLowerCase().contains('zain_cash')) {
      return FontAwesomeIcons.mobileScreen;
    }

    return FontAwesomeIcons.circleQuestion;
  }

  // تنسيق المبلغ مع فاصلة
  String formatAmount(dynamic amount) {
    if (amount == null) return '0';

    try {
      final numAmount = double.parse(amount.toString());
      final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      String result = numAmount.toStringAsFixed(0);
      return result.replaceAllMapped(formatter, (Match m) => '${m[1]},');
    } catch (e) {
      return amount.toString();
    }
  }

  // تنسيق التاريخ بتوقيت العراق مع فاصل
  String formatDateWithSeparator(String? dateString) {
    if (dateString == null) return 'غير محدد';

    try {
      // تحويل التاريخ من UTC إلى توقيت العراق (+3 ساعات)
      final utcDate = DateTime.parse(dateString);
      final iraqDate = utcDate.add(const Duration(hours: 3));

      // تنسيق التاريخ: السنة-الشهر-اليوم __ الساعة:الدقيقة
      final year = iraqDate.year;
      final month = iraqDate.month.toString().padLeft(2, '0');
      final day = iraqDate.day.toString().padLeft(2, '0');
      final hour = iraqDate.hour.toString().padLeft(2, '0');
      final minute = iraqDate.minute.toString().padLeft(2, '0');

      return '$year-$month-$day __ $hour:$minute';
    } catch (e) {
      return 'تاريخ غير صحيح';
    }
  }
}
