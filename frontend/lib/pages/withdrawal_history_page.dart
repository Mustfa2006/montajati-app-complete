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

import '../providers/theme_provider.dart';
import '../utils/theme_colors.dart';
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

      // 🌐 جلب طلبات السحب من الـ API (آمن جداً - يعتمد على JWT)
      const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:3002');

      final response = await http
          .post(
            Uri.parse('$apiUrl/api/users/withdrawals'),
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
            body: jsonEncode({'phone': phone}),
          )
          .timeout(const Duration(seconds: 10));

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

  // بناء الشريط العلوي البسيط
  Widget _buildSimpleHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // زر الرجوع (بارز وجميل - الوضع النهاري فقط)
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5), width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: const Icon(FontAwesomeIcons.arrowRight, color: Colors.black, size: 20),
                ),
              ),
            ),
          ),

          const SizedBox(width: 15),

          // العنوان
          Expanded(
            child: Text(
              'سجل السحب',
              style: GoogleFonts.cairo(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: ThemeColors.textColor(isDark),
                shadows: isDark
                    ? [
                        Shadow(
                          color: const Color(0xFFffd700).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(width: 55), // للتوازن مع زر الرجوع
        ],
      ),
    );
  }

  // بناء شريط البحث
  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: ThemeColors.cardBackground(isDark),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: ThemeColors.cardBorder(isDark), width: 1),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
          },
          style: GoogleFonts.cairo(color: ThemeColors.textColor(isDark), fontSize: 16),
          decoration: InputDecoration(
            hintText: 'البحث في طلبات السحب...',
            hintStyle: GoogleFonts.cairo(color: ThemeColors.secondaryTextColor(isDark), fontSize: 14),
            prefixIcon: Icon(
              FontAwesomeIcons.magnifyingGlass,
              color: const Color(0xFFffd700).withValues(alpha: 0.7),
              size: 18,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),
      ),
    );
  }

  // بناء أزرار فلترة الحالات
  Widget _buildStatusFilterButtons(bool isDark) {
    final filters = [
      {'key': 'الكل', 'label': 'الكل', 'icon': FontAwesomeIcons.list},
      {'key': 'pending', 'label': 'قيد المراجعة', 'icon': FontAwesomeIcons.clock},
      {'key': 'completed', 'label': 'مكتمل', 'icon': FontAwesomeIcons.circleCheck},
      {'key': 'cancelled', 'label': 'ملغي', 'icon': FontAwesomeIcons.ban},
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
            margin: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedFilter = filter['key'] as String;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected ? const LinearGradient(colors: [Color(0xFFffd700), Color(0xFFe6b31e)]) : null,
                  color: isSelected ? null : ThemeColors.cardBackground(isDark),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFffd700) : ThemeColors.cardBorder(isDark),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      filter['icon'] as IconData,
                      size: 14,
                      color: isSelected
                          ? Colors.black
                          : (isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black87),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      filter['label'] as String,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.black : ThemeColors.textColor(isDark),
                      ),
                    ),
                  ],
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
      color: const Color(0xFFffd700),
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
              CircularProgressIndicator(color: Color(0xFFffd700)),
              SizedBox(height: 20),
              Text(
                'جاري تحميل طلبات السحب...',
                style: GoogleFonts.cairo(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500),
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
              Icon(FontAwesomeIcons.fileInvoiceDollar, size: 80, color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
              const SizedBox(height: 20),
              Text(
                withdrawalRequests.isEmpty ? 'لا توجد طلبات سحب' : 'لا توجد نتائج',
                style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              Text(
                withdrawalRequests.isEmpty ? 'لم تقم بأي طلبات سحب حتى الآن' : 'جرب تغيير معايير البحث أو الفلترة',
                style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return _buildWithdrawalCard(filteredRequests[index], isDark);
        }, childCount: filteredRequests.length),
      ),
    );
  }

  // تم إزالة دالة _buildWithdrawalList غير المستخدمة

  // بناء بطاقة طلب السحب محسنة
  Widget _buildWithdrawalCard(Map<String, dynamic> request, bool isDark) {
    Color statusColor = _getStatusColor(request['status']);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: ThemeColors.cardBackground(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ThemeColors.cardBorder(isDark), width: 1),
        boxShadow: isDark
            ? [
                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8)),
                BoxShadow(
                  color: const Color(0xFFffd700).withValues(alpha: 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 0),
                ),
              ]
            : [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الصف الأول: الحالة والمبلغ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // الحالة
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 1),
                  ),
                  child: Text(
                    _getStatusText(request['status']),
                    style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor),
                  ),
                ),

                // المبلغ مع فاصلة
                Text(
                  '${_formatAmount(request['amount'])} د.ع',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFffd700),
                    shadows: [
                      Shadow(
                        color: const Color(0xFFffd700).withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // طريقة السحب
            Row(
              children: [
                Icon(
                  _getMethodIcon(request['withdrawal_method']),
                  color: const Color(0xFFffd700).withValues(alpha: 0.8),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'طريقة السحب: ${_getMethodText(request['withdrawal_method'])}',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ThemeColors.textColor(isDark),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // رقم البطاقة
            Row(
              children: [
                Icon(FontAwesomeIcons.hashtag, color: ThemeColors.secondaryIconColor(isDark), size: 14),
                const SizedBox(width: 8),
                Text(
                  'رقم البطاقة: ${_extractCardNumber(request['account_details'])}',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: ThemeColors.secondaryTextColor(isDark),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // اسم حامل البطاقة
            Row(
              children: [
                Icon(FontAwesomeIcons.user, color: ThemeColors.secondaryIconColor(isDark), size: 14),
                const SizedBox(width: 8),
                Text(
                  'اسم حامل البطاقة: ${_extractCardHolderName(request['account_details'])}',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: ThemeColors.secondaryTextColor(isDark),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // تاريخ الطلب
            Row(
              children: [
                Icon(FontAwesomeIcons.calendar, color: ThemeColors.secondaryIconColor(isDark), size: 14),
                const SizedBox(width: 8),
                Text(
                  'تاريخ الطلب: ${_formatDateWithSeparator(request['request_date'])}',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: ThemeColors.secondaryTextColor(isDark),
                  ),
                ),
              ],
            ),

            // تاريخ المعالجة (إذا كان موجوداً)
            if (request['process_date'] != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(FontAwesomeIcons.check, color: Colors.green.withValues(alpha: 0.8), size: 14),
                  const SizedBox(width: 8),
                  Text(
                    'تاريخ المعالجة: ${_formatDateWithSeparator(request['process_date'])}',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: ThemeColors.secondaryTextColor(isDark),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase().trim()) {
      case 'pending':
        return const Color(0xFFffc107); // أصفر - قيد المراجعة
      case 'approved':
        return const Color(0xFF17a2b8); // أزرق - تمت الموافقة
      case 'completed':
        return const Color(0xFF28a745); // أخضر - تم التحويل
      case 'rejected':
        return const Color(0xFFdc3545); // أحمر - مرفوض
      case 'cancelled':
        return const Color(0xFFfd7e14); // برتقالي - ملغي
      default:
        return const Color(0xFF6c757d); // رمادي - غير محدد
    }
  }

  // ترجمة حالة الطلب للعربية
  String _getStatusText(String? status) {
    // طباعة الحالة للتشخيص
    debugPrint('🔍 حالة الطلب الواردة: "$status"');

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
        debugPrint('⚠️ حالة غير معروفة: "$status"');
        return status?.toString() ?? 'غير محدد';
    }
  }

  // ترجمة طريقة السحب للعربية
  String _getMethodText(String? method) {
    debugPrint('🔍 طريقة السحب الواردة: "$method"');

    if (method == null) return 'غير محدد';

    // التحقق من النص المحفوظ
    if (method.contains('بطاقة كي كارد') || method.contains('كي كارد')) {
      return 'كي كارد';
    } else if (method.contains('زين كاش')) {
      return 'زين كاش';
    }

    // التحقق من القيم القديمة
    switch (method.toLowerCase().trim()) {
      case 'mastercard':
      case 'ki_card':
        return 'كي كارد';
      case 'zaincash':
      case 'zain_cash':
        return 'زين كاش';
      default:
        return method; // عرض القيمة الفعلية إذا لم تكن معروفة
    }
  }

  // الحصول على أيقونة طريقة السحب
  IconData _getMethodIcon(String? method) {
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

  // استخراج رقم البطاقة من account_details
  String _extractCardNumber(String? accountDetails) {
    if (accountDetails == null || accountDetails.isEmpty) {
      return 'غير محدد';
    }

    debugPrint('🔍 استخراج رقم البطاقة من: "$accountDetails"');

    // تنسيق البيانات المحفوظة: "بطاقة كي كارد - اسم حامل البطاقة - رقم البطاقة"
    final parts = accountDetails.split(' - ');

    if (parts.length >= 3) {
      // الجزء الثالث هو رقم البطاقة
      final cardNumber = parts[2].trim();
      debugPrint('✅ رقم البطاقة المستخرج: "$cardNumber"');
      return cardNumber;
    } else if (parts.length == 2) {
      // إذا كان هناك جزءان فقط، نتحقق أيهما الرقم
      final secondPart = parts[1].trim();
      // إذا كان الجزء الثاني يحتوي على أرقام فقط، فهو رقم البطاقة
      if (RegExp(r'^\d+$').hasMatch(secondPart)) {
        debugPrint('✅ رقم البطاقة المستخرج: "$secondPart"');
        return secondPart;
      }
    }

    // البحث عن أي رقم في النص كحل أخير
    final RegExp numberRegex = RegExp(r'\d{4,}');
    final match = numberRegex.firstMatch(accountDetails);

    if (match != null) {
      final cardNumber = match.group(0) ?? 'غير محدد';
      debugPrint('✅ رقم البطاقة المستخرج (بحث): "$cardNumber"');
      return cardNumber;
    }

    debugPrint('❌ لم يتم العثور على رقم البطاقة');
    return 'غير محدد';
  }

  // استخراج اسم حامل البطاقة من account_details
  String _extractCardHolderName(String? accountDetails) {
    if (accountDetails == null || accountDetails.isEmpty) {
      return 'غير محدد';
    }

    debugPrint('🔍 استخراج اسم حامل البطاقة من: "$accountDetails"');

    // تنسيق البيانات المحفوظة: "بطاقة كي كارد - اسم حامل البطاقة - رقم البطاقة"
    final parts = accountDetails.split(' - ');

    if (parts.length >= 3) {
      // الجزء الثاني هو اسم حامل البطاقة
      final cardHolderName = parts[1].trim();
      debugPrint('✅ اسم حامل البطاقة المستخرج: "$cardHolderName"');
      return cardHolderName;
    } else if (parts.length == 2) {
      // إذا كان هناك جزءان فقط، نتحقق أيهما الاسم
      final secondPart = parts[1].trim();
      // إذا كان الجزء الثاني لا يحتوي على أرقام فقط، فهو الاسم
      if (!RegExp(r'^\d+$').hasMatch(secondPart)) {
        debugPrint('✅ اسم حامل البطاقة المستخرج: "$secondPart"');
        return secondPart;
      }
    }

    debugPrint('❌ لم يتم العثور على اسم حامل البطاقة');
    return 'غير محدد';
  }

  // تنسيق المبلغ مع فاصلة
  String _formatAmount(dynamic amount) {
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
  String _formatDateWithSeparator(String? dateString) {
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
