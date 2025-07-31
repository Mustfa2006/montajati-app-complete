import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/withdrawal_service.dart';
import '../widgets/common_header.dart';

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

  // جلب طلبات السحب للمستخدم الحالي فقط
  Future<void> _loadWithdrawalRequests() async {
    try {
      setState(() => _isLoading = true);

      // ✅ الحصول على معرف المستخدم من SharedPreferences (نفس النظام المستخدم في السحب)
      final prefs = await SharedPreferences.getInstance();
      String? currentUserId = prefs.getString('current_user_id');
      String? currentUserPhone = prefs.getString('current_user_phone');

      if (currentUserId == null || currentUserId.isEmpty) {
        debugPrint('❌ لا يوجد معرف مستخدم محفوظ');

        // محاولة البحث بالهاتف إذا لم يكن هناك معرف
        if (currentUserPhone != null && currentUserPhone.isNotEmpty) {
          debugPrint('🔍 البحث عن المستخدم برقم الهاتف: $currentUserPhone');

          final userResponse = await Supabase.instance.client
              .from('users')
              .select('id')
              .eq('phone', currentUserPhone)
              .maybeSingle();

          if (userResponse != null) {
            currentUserId = userResponse['id'];
            await prefs.setString('current_user_id', currentUserId!);
            debugPrint('✅ تم العثور على معرف المستخدم: $currentUserId');
          } else {
            debugPrint('❌ لم يتم العثور على المستخدم');
            setState(() => _isLoading = false);
            return;
          }
        } else {
          debugPrint('❌ لا يوجد مستخدم مسجل دخول');
          setState(() => _isLoading = false);
          return;
        }
      }

      debugPrint('👤 جلب طلبات السحب للمستخدم: $currentUserId');

      // جلب طلبات السحب للمستخدم الحالي فقط
      final requests = await WithdrawalService.getUserWithdrawalRequests(
        currentUserId,
      );

      debugPrint('📊 طلبات السحب المجلبة: $requests');
      debugPrint('📊 عدد طلبات السحب: ${requests.length}');

      if (requests.isNotEmpty) {
        debugPrint('📋 أول طلب سحب: ${requests.first}');
      }

      setState(() {
        withdrawalRequests = requests;
        _isLoading = false;
      });

      debugPrint('✅ تم جلب ${requests.length} طلب سحب للمستخدم');
    } catch (e) {
      debugPrint('❌ خطأ في جلب طلبات السحب: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في جلب طلبات السحب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  int get completedRequestsCount =>
      withdrawalRequests.where((req) => req['status'] == 'completed').length;

  int get pendingRequestsCount =>
      withdrawalRequests.where((req) => req['status'] == 'pending').length;

  // ترجمة حالات الطلبات من الإنجليزية إلى العربية
  String _getArabicStatus(String status) {
    switch (status) {
      case 'pending':
        return 'قيد المراجعة';
      case 'approved':
        return 'تمت الموافقة';
      case 'completed':
        return 'تم التحويل';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }

  double get totalRequestedAmount => withdrawalRequests.fold(
    0.0,
    (sum, req) => sum + (req['amount'] as num).toDouble(),
  );

  String get lastWithdrawalDate {
    final completedRequests = withdrawalRequests
        .where((req) => req['status'] == 'تم التحويل')
        .toList();

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
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      extendBody: true, // إزالة الخلفية السوداء خلف الشريط السفلي
      body: Column(
        children: [
          // الشريط العلوي الموحد
          CommonHeader(
            title: 'سجل السحب',
            rightActions: [
              // زر الرجوع على اليمين
              GestureDetector(
                onTap: () => context.pop(),
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

          // المحتوى القابل للتمرير (يحتوي على الإحصائيات والفلتر والقائمة)
          Expanded(child: _buildScrollableContent()),
        ],
      ),

      // شريط التنقل السفلي
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }



  // بناء المحتوى القابل للتمرير
  Widget _buildScrollableContent() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(0xFFffd700),
      backgroundColor: const Color(0xFF16213e),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // شريط الإحصائيات السريعة
          SliverToBoxAdapter(child: _buildQuickStats()),

          // شريط التصفية والبحث
          SliverToBoxAdapter(child: _buildFilterBar()),

          // قائمة طلبات السحب
          _buildWithdrawalSliverList(),
        ],
      ),
    );
  }

  // دالة تحديث البيانات
  Future<void> _refreshData() async {
    await _loadWithdrawalRequests();
  }

  // بناء شريط الإحصائيات السريعة
  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.all(15),
      height: 80,
      child: Row(
        children: [
          // إجمالي المسحوب
          Expanded(
            child: _buildStatCard(
              'إجمالي المسحوب',
              '${totalWithdrawn.toStringAsFixed(0)} د.ع',
              FontAwesomeIcons.circleCheck,
              const Color(0xFF28a745),
            ),
          ),
          const SizedBox(width: 8),

          // قيد المراجعة
          Expanded(
            child: _buildStatCard(
              'قيد المراجعة',
              '${pendingAmount.toStringAsFixed(0)} د.ع',
              FontAwesomeIcons.clock,
              const Color(0xFFffc107),
            ),
          ),
          const SizedBox(width: 8),

          // آخر سحب
          Expanded(
            child: _buildStatCard(
              'آخر سحب',
              lastWithdrawalDate,
              FontAwesomeIcons.calendar,
              const Color(0xFF6c757d),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF16213e), const Color(0xFF1a1a2e)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: color,
              shadows: [
                Shadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // بناء شريط التصفية والبحث
  Widget _buildFilterBar() {
    return Column(
      children: [
        // أزرار الفلتر
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 15),
          height: 45,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterButton('الكل', const Color(0xFF6c757d)),
                const SizedBox(width: 10),
                _buildFilterButton('قيد المراجعة', const Color(0xFFffc107)),
                const SizedBox(width: 10),
                _buildFilterButton('مرفوض', const Color(0xFFdc3545)),
                const SizedBox(width: 10),
                _buildFilterButton('تم التحويل', const Color(0xFF17a2b8)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // حقل البحث
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 15),
          height: 45,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF16213e), Color(0xFF1a1a2e)],
            ),
            borderRadius: BorderRadius.circular(25), // زيادة التقوس
            border: Border.all(
              color: const Color(0xFFffd700).withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFffd700).withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'بحث برقم الطلب، المبلغ، أو طريقة الدفع...',
              hintStyle: GoogleFonts.cairo(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.6),
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Container(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  FontAwesomeIcons.magnifyingGlass,
                  size: 16,
                  color: const Color(0xFFffd700).withValues(alpha: 0.8),
                ),
              ),
              suffixIcon: searchQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () => setState(() => searchQuery = ''),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          FontAwesomeIcons.xmark,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 20,
              ),
            ),
            onChanged: (value) => setState(() => searchQuery = value),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(String text, Color color) {
    bool isSelected = selectedFilter == text;
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withValues(alpha: 0.8)],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.6),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? (text == 'قيد المراجعة' ? Colors.black : Colors.white)
                : color,
            shadows: isSelected
                ? [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }

  // بناء قائمة طلبات السحب كـ Sliver
  Widget _buildWithdrawalSliverList() {
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
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    List<Map<String, dynamic>> filteredRequests = withdrawalRequests.where((
      req,
    ) {
      bool matchesFilter =
          selectedFilter == 'الكل' ||
          _getArabicStatus(req['status']) == selectedFilter;
      bool matchesSearch =
          searchQuery.isEmpty ||
          req['id'].toString().toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ||
          req['amount'].toString().contains(searchQuery) ||
          req['method'].toString().toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ||
          req['status'].toString().toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ||
          req['requestDate'].toString().contains(searchQuery) ||
          (req['processDate'] != null &&
              req['processDate'].toString().contains(searchQuery)) ||
          (req['note'] != null &&
              req['note'].toString().toLowerCase().contains(
                searchQuery.toLowerCase(),
              ));
      return matchesFilter && matchesSearch;
    }).toList();

    if (filteredRequests.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FontAwesomeIcons.inbox,
                size: 64,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد طلبات سحب',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.only(
        left: 15,
        right: 15,
        top: 10,
        bottom: 100, // مساحة للشريط السفلي
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return _buildWithdrawalCard(filteredRequests[index]);
        }, childCount: filteredRequests.length),
      ),
    );
  }

  // تم إزالة دالة _buildWithdrawalList غير المستخدمة

  // بناء بطاقة طلب السحب
  Widget _buildWithdrawalCard(Map<String, dynamic> request) {
    Color statusColor = _getStatusColor(request['status']);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFffd700), // إطار ذهبي
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: const Color(0xFFffd700).withValues(alpha: 0.2), // ظل ذهبي
            blurRadius: 20,
            offset: const Offset(0, 0),
          ),
          BoxShadow(
            color: statusColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // الصف الأول: الحالة
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(request['status']),
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _getStatusTextColor(request['status']),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // الصف الثاني: المبلغ وطريقة السحب
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    '${request['amount'].toStringAsFixed(0)} د.ع',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF007bff),
                      shadows: [
                        Shadow(
                          color: const Color(0xFF007bff).withValues(alpha: 0.3),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        (request['withdrawal_method'] ?? '') == 'mastercard'
                            ? FontAwesomeIcons.creditCard
                            : FontAwesomeIcons.mobileScreen,
                        color:
                            (request['withdrawal_method'] ?? '') == 'mastercard'
                            ? const Color(0xFF28a745)
                            : const Color(0xFF17a2b8),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _getMethodText(request['withdrawal_method']),
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                (request['withdrawal_method'] ?? '') ==
                                    'mastercard'
                                ? const Color(0xFF28a745)
                                : const Color(0xFF17a2b8),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // الصف الثاني والنصف: رقم البطاقة
            Row(
              children: [
                const Icon(
                  FontAwesomeIcons.creditCard,
                  color: Color(0xFF17a2b8),
                  size: 12,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'رقم البطاقة: ${request['account_details'] ?? 'غير محدد'}',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // الصف الثالث: تاريخ الطلب
            Row(
              children: [
                const Icon(
                  FontAwesomeIcons.calendarPlus,
                  color: Color(0xFF28a745),
                  size: 12,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'تاريخ الطلب: ${_formatDate(request['request_date'])}',
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // الصف الرابع: تاريخ المعالجة (إذا كان موجوداً)
            if (request['process_date'] != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    FontAwesomeIcons.calendarCheck,
                    color: Color(0xFF007bff),
                    size: 12,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'تاريخ المعالجة: ${_formatDate(request['process_date'])}',
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
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
    switch (status) {
      case 'pending':
        return const Color(0xFFffc107); // أصفر - قيد المراجعة
      case 'approved':
        return const Color(0xFF17a2b8); // أزرق - تمت الموافقة
      case 'completed':
        return const Color(0xFF28a745); // أخضر - تم التحويل
      case 'rejected':
        return const Color(0xFFdc3545); // أحمر - مرفوض
      default:
        return const Color(0xFF6c757d); // رمادي - غير محدد
    }
  }

  Color _getStatusTextColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.black; // نص أسود على خلفية صفراء
      default:
        return Colors.white; // نص أبيض على باقي الخلفيات
    }
  }

  // ترجمة حالة الطلب للعربية
  String _getStatusText(String? status) {
    switch (status) {
      case 'pending':
        return 'قيد المراجعة';
      case 'approved':
        return 'تمت الموافقة';
      case 'completed':
        return 'مكتمل';
      case 'rejected':
        return 'مرفوض';
      default:
        return 'غير محدد';
    }
  }

  // ترجمة طريقة السحب للعربية
  String _getMethodText(String? method) {
    switch (method) {
      case 'mastercard':
        return 'ماستر كارد';
      case 'zaincash':
        return 'زين كاش';
      default:
        return 'غير محدد';
    }
  }

  // تنسيق التاريخ بتوقيت العراق
  String _formatDate(String? dateString) {
    if (dateString == null) return 'غير محدد';

    try {
      // تحويل التاريخ من UTC إلى توقيت العراق (+3 ساعات)
      final utcDate = DateTime.parse(dateString);
      final iraqDate = utcDate.add(const Duration(hours: 3));

      // تنسيق التاريخ: السنة-الشهر-اليوم الساعة:الدقيقة
      final year = iraqDate.year;
      final month = iraqDate.month.toString().padLeft(2, '0');
      final day = iraqDate.day.toString().padLeft(2, '0');
      final hour = iraqDate.hour.toString().padLeft(2, '0');
      final minute = iraqDate.minute.toString().padLeft(2, '0');

      return '$year-$month-$day $hour:$minute';
    } catch (e) {
      return 'تاريخ غير صحيح';
    }
  }

  // بناء شريط التنقل السفلي
  Widget _buildBottomNavigationBar() {
    return Container(
      margin: const EdgeInsets.only(
        left: 15,
        right: 15,
        bottom: 8,
      ), // رفع للأعلى
      height: 55, // تصغير الارتفاع
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(FontAwesomeIcons.store, 'منتجاتي', 0, '/products'),
          _buildNavItem(FontAwesomeIcons.bagShopping, 'الطلبات', 1, '/orders'),
          _buildNavItem(FontAwesomeIcons.chartLine, 'الأرباح', 2, '/profits'),
          _buildNavItem(FontAwesomeIcons.user, 'الحساب', 3, '/account'),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, String route) {
    bool isSelected =
        index == 2; // الأرباح محددة (لأن سجل السحب جزء من الأرباح)
    return GestureDetector(
      onTap: () => context.go(route),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 6,
          horizontal: 10,
        ), // تصغير المساحة العمودية
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFFffd700)
                  : Colors.white.withValues(alpha: 0.6),
              size: 18, // تصغير الأيقونات
            ),
            const SizedBox(height: 2), // تقليل المسافة
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 10, // تصغير النص
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFFffd700)
                    : Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
