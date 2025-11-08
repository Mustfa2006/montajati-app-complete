import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/order.dart';
import '../models/order_item.dart' as order_item_model;
import '../providers/theme_provider.dart';
import '../services/order_details_service.dart'; // ✅ استخدام Backend API
import '../utils/order_status_helper.dart';
import '../utils/theme_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/order_details_skeleton.dart';

class UserOrderDetailsPage extends StatefulWidget {
  final String orderId;

  const UserOrderDetailsPage({super.key, required this.orderId});

  @override
  State<UserOrderDetailsPage> createState() => _UserOrderDetailsPageState();
}

class _UserOrderDetailsPageState extends State<UserOrderDetailsPage> {
  Order? _order;
  bool _isLoading = true;
  String? _error;
  bool _isDeleting = false; // ✅ منع الحذف المزدوج

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  @override
  void dispose() {
    // ✅ تنظيف الموارد عند مغادرة الصفحة
    super.dispose();
  }

  Future<void> _loadOrderDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // ✅ استخدام Backend API بدلاً من Supabase مباشرة
      final order = await OrderDetailsService.fetchOrderDetails(widget.orderId);

      setState(() {
        _order = order;
        _isLoading = false;
      });

      debugPrint('✅ تم تحميل تفاصيل الطلب بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في جلب تفاصيل الطلب: $e');
      setState(() {
        _error = 'خطأ في جلب تفاصيل الطلب: $e';
        _isLoading = false;
      });
    }
  }

  // 🧮 حساب المجموع الفرعي من قاعدة البيانات
  double _calculateSubtotal() {
    if (_order == null) return 0.0;
    return _order!.subtotal.toDouble();
  }

  // 🧮 حساب المجموع الكلي من قاعدة البيانات
  double _calculateTotal() {
    if (_order == null) return 0.0;
    return _order!.total.toDouble();
  }

  // 🧮 حساب إجمالي الربح من قاعدة البيانات
  double _calculateTotalProfit() {
    if (_order == null) return 0.0;
    return _order!.totalProfit.toDouble();
  }

  // 🔍 التحقق من كون الطلب نشط (يمكن تعديله أو حذفه)
  bool _isOrderActive() {
    if (_order == null) return false;

    final rawStatus = _order!.rawStatus.toLowerCase().trim();

    // ✅ قائمة الحالات النشطة فقط
    const activeStatuses = ['نشط', 'active', 'pending', 'confirmed', 'جديد', 'new'];

    // ✅ قائمة الحالات غير النشطة
    const inactiveStatuses = [
      'تم التوصيل',
      'delivered',
      'ملغي',
      'cancelled',
      'قيد التوصيل',
      'in_delivery',
      'لا يرد',
      'no_answer',
      'مؤجل',
      'postponed',
    ];

    // ✅ فحص بسيط ومباشر
    if (rawStatus.isEmpty || rawStatus == 'null') return false;
    if (inactiveStatuses.any((status) => rawStatus.contains(status))) return false;
    return activeStatuses.contains(rawStatus);
  }

  // ✏️ تعديل الطلب
  void _editOrder() {
    if (_order == null) return;

    // التحقق من إمكانية التعديل
    bool isScheduledOrder = _order!.scheduledDate != null;

    // الطلبات المجدولة يمكن تعديلها دائماً
    // الطلبات العادية يجب أن تكون نشطة للتعديل
    if (!isScheduledOrder && !_isOrderActive()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا يمكن تعديل هذا الطلب. الحالة الحالية: ${_order!.rawStatus}', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    // الانتقال لصفحة التعديل الصحيحة حسب نوع الطلب
    if (isScheduledOrder) {
      // للطلبات المجدولة
      context.go('/scheduled-orders/edit/${_order!.id}');
    } else {
      // للطلبات العادية
      context.go('/orders/edit/${_order!.id}');
    }
  }

  // 🗑️ حذف الطلب
  void _deleteOrder() {
    if (_order == null) return;

    // التحقق من إمكانية الحذف
    bool isScheduledOrder = _order!.scheduledDate != null;

    // الطلبات المجدولة يمكن حذفها دائماً
    // الطلبات العادية يجب أن تكون نشطة للحذف
    if (!isScheduledOrder && !_isOrderActive()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا يمكن حذف هذا الطلب. الحالة الحالية: ${_order!.rawStatus}', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    // إظهار رسالة تأكيد بتصميم محسن
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: isDark ? 15 : 5, sigmaY: isDark ? 15 : 5),
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: isDark ? 0.3 : 0.5),
                    width: isDark ? 1 : 2,
                  ),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // أيقونة التحذير
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(FontAwesomeIcons.triangleExclamation, color: Colors.red, size: 30),
                    ),
                    const SizedBox(height: 20),
                    // العنوان
                    Text(
                      'حذف الطلب',
                      style: GoogleFonts.cairo(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    // المحتوى
                    Text(
                      'هل أنت متأكد من حذف هذا الطلب؟\nلا يمكن التراجع عن هذا الإجراء.',
                      style: GoogleFonts.cairo(
                        color: isDark ? Colors.white : Colors.black.withValues(alpha: 0.8),
                        fontSize: 16,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 25),
                    // الأزرار
                    Row(
                      children: [
                        // زر الإلغاء
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.grey.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.3)
                                      : Colors.grey.withValues(alpha: 0.4),
                                  width: isDark ? 1 : 2,
                                ),
                              ),
                              child: Text(
                                'إلغاء',
                                style: GoogleFonts.cairo(
                                  color: isDark ? Colors.white : Colors.black.withValues(alpha: 0.7),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        // زر الحذف
                        Expanded(
                          child: GestureDetector(
                            onTap: _isDeleting
                                ? null // ✅ تعطيل الزر أثناء الحذف
                                : () async {
                                    Navigator.pop(context);
                                    await _confirmDeleteOrder();
                                  },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1),
                              ),
                              child: Text(
                                'حذف',
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
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
          ),
        ),
      ),
    );
  }

  // 🗑️ تأكيد حذف الطلب
  Future<void> _confirmDeleteOrder() async {
    // ✅ منع الحذف المزدوج
    if (_isDeleting) return;

    try {
      setState(() => _isDeleting = true);
      debugPrint('🗑️ بدء حذف الطلب');

      // ✅ الحصول على رقم هاتف المستخدم من التخزين المحلي
      final prefs = await SharedPreferences.getInstance();
      final currentUserPhone = prefs.getString('current_user_phone');

      if (currentUserPhone == null || currentUserPhone.isEmpty) {
        throw Exception('رقم الهاتف غير متوفر');
      }

      // ✅ حذف الطلب عبر Backend API (آمن وموثوق)
      final success = await OrderDetailsService.deleteOrder(_order!.id, currentUserPhone);

      if (!success) {
        throw Exception('فشل في حذف الطلب');
      }

      // ✅ التحقق من mounted قبل أي عملية UI
      if (!mounted) return;

      // إظهار رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حذف الطلب بنجاح', style: GoogleFonts.cairo()),
          backgroundColor: Colors.green,
        ),
      );

      // العودة لصفحة الطلبات
      context.go('/orders');
    } catch (e) {
      debugPrint('❌ خطأ في حذف الطلب: $e');

      // ✅ التحقق من mounted قبل عرض الخطأ
      if (!mounted) return;

      // إظهار رسالة خطأ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في حذف الطلب: $e', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // ✅ إعادة تعيين الحالة
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Scaffold(
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 20, left: 10, right: 10, bottom: 20),
          child: Column(
            children: [
              // شريط علوي متحرك مع المحتوى
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  children: [
                    // زر الرجوع - تحريكه لليسار قليلاً
                    Padding(
                      padding: const EdgeInsets.only(right: 8), // ✅ إزاحة لليسار
                      child: GestureDetector(
                        onTap: () => context.go('/orders'),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFFffd700).withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.1), // ✅ خلفية سوداء في النهاري
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFFffd700).withValues(alpha: 0.3)
                                  : Colors.black.withValues(alpha: 0.2), // ✅ حدود سوداء في النهاري
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            FontAwesomeIcons.arrowLeft, // ✅ السهم يشير لليسار في الوضع العربي
                            color: isDark ? const Color(0xFFffd700) : Colors.black,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    // العنوان في الوسط بالضبط
                    Expanded(
                      child: Center(
                        child: Text(
                          'تفاصيل الطلب',
                          style: GoogleFonts.cairo(
                            color: ThemeColors.textColor(isDark),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // أزرار التعديل والحذف (للطلبات النشطة فقط)
                    if (_order != null && _isOrderActive()) ...[
                      // زر التعديل
                      GestureDetector(
                        onTap: _editOrder,
                        child: Container(
                          width: 35,
                          height: 35,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1),
                          ),
                          child: const Icon(FontAwesomeIcons.penToSquare, color: Colors.blue, size: 16),
                        ),
                      ),
                      // زر الحذف
                      GestureDetector(
                        onTap: _deleteOrder,
                        child: Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1),
                          ),
                          child: const Icon(FontAwesomeIcons.trash, color: Colors.red, size: 16),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // المحتوى
              if (_isLoading)
                _buildLoadingState()
              else if (_error != null)
                _buildErrorState()
              else
                _buildOrderContent(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return OrderDetailsSkeleton(isDark: isDark);
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const FaIcon(FontAwesomeIcons.triangleExclamation, color: Colors.red, size: 60),
          const SizedBox(height: 20),
          Text(
            _error!,
            style: GoogleFonts.cairo(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          // ✅ زر إعادة المحاولة
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _loadOrderDetails();
            },
            icon: const Icon(Icons.refresh),
            label: Text('إعادة المحاولة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFffd700),
              foregroundColor: const Color(0xFF1a1a2e),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
          ),
          const SizedBox(height: 15),
          // زر العودة
          TextButton(
            onPressed: () => context.go('/orders'),
            child: Text('العودة للطلبات', style: GoogleFonts.cairo(color: const Color(0xFFffd700))),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderContent(bool isDark) {
    if (_order == null) return const SizedBox();

    // ✅ بدون SingleChildScrollView - الـ Scaffold يتعامل مع التمرير
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderStatusCard(isDark),
          const SizedBox(height: 20),
          _buildScheduleInfoCard(isDark),
          _buildCustomerInfoCard(isDark),
          const SizedBox(height: 20),
          _buildOrderItemsCard(isDark),
          const SizedBox(height: 20),
          _buildOrderSummaryCard(isDark),
        ],
      ),
    );
  }

  Widget _buildOrderStatusCard(bool isDark) {
    // ✅ استخدام OrderStatusHelper للحصول على نفس النتائج المعروضة في بطاقة الطلب
    String actualStatus = _order!.rawStatus.isNotEmpty ? _order!.rawStatus : 'نشط';
    Color statusColor = OrderStatusHelper.getStatusColor(actualStatus);
    String statusText = OrderStatusHelper.getArabicStatus(actualStatus);
    IconData statusIcon = OrderStatusHelper.getStatusIcon(actualStatus);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // خلفية بيضاء في الوضع النهاري، شفافة في الوضع الليلي
        color: isDark ? Colors.transparent : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.6), width: 2),
        // توهج داخلي فقط في الوضع الليلي
        gradient: isDark
            ? RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [statusColor.withValues(alpha: 0.08), statusColor.withValues(alpha: 0.03), Colors.transparent],
                stops: const [0.0, 0.6, 1.0],
              )
            : null,
        // ظل مناسب للوضع
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ]
            : [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FaIcon(statusIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حالة الطلب',
                  style: GoogleFonts.cairo(color: ThemeColors.secondaryTextColor(isDark), fontSize: 14),
                ),
                Text(
                  statusText,
                  style: GoogleFonts.cairo(color: statusColor, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(_order!.createdAt),
            style: GoogleFonts.cairo(color: ThemeColors.secondaryTextColor(isDark), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleInfoCard(bool isDark) {
    if (_order?.scheduledDate == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.transparent : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF9c27b0).withValues(alpha: 0.6), width: 2),
        gradient: isDark
            ? RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  const Color(0xFF9c27b0).withValues(alpha: 0.08),
                  const Color(0xFF9c27b0).withValues(alpha: 0.03),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.6, 1.0],
              )
            : null,
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: const Color(0xFF9c27b0).withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ]
            : [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.calendar, color: Color(0xFF9c27b0), size: 20),
              const SizedBox(width: 10),
              Text(
                'طلب مجدول',
                style: GoogleFonts.cairo(color: const Color(0xFF9c27b0), fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildInfoRow('تاريخ الجدولة', DateFormat('yyyy/MM/dd', 'ar').format(_order!.scheduledDate!), isDark),
          if (_order!.scheduleNotes != null && _order!.scheduleNotes!.isNotEmpty)
            _buildInfoRow('ملاحظات الجدولة', _order!.scheduleNotes!, isDark),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeColors.cardBackground(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.3), width: 1),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.user, color: Color(0xFFffd700), size: 20),
              const SizedBox(width: 10),
              Text(
                'معلومات العميل',
                style: GoogleFonts.cairo(color: const Color(0xFFffd700), fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildInfoRow('اسم الزبون', _order!.customerName, isDark, showCopyButton: true),
          _buildInfoRow('رقم الزبون', _order!.primaryPhone, isDark, showCopyButton: true),
          // ✅ إخفاء الرقم البديل إذا كان فارغاً أو null
          if (_order!.secondaryPhone != null && _order!.secondaryPhone!.trim().isNotEmpty)
            _buildInfoRow('الرقم البديل', _order!.secondaryPhone!, isDark, showCopyButton: true),
          _buildInfoRow('المحافظة', _order!.province, isDark),
          _buildInfoRow('المدينة', _order!.city, isDark),
          _buildNotesRow(isDark),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark, {bool showCopyButton = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: GoogleFonts.cairo(color: ThemeColors.secondaryTextColor(isDark), fontSize: 14),
              softWrap: false,
              overflow: TextOverflow.visible,
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(value, style: GoogleFonts.cairo(color: ThemeColors.textColor(isDark), fontSize: 14)),
                ),
                if (showCopyButton) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _copyToClipboard(value),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFffd700).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.copy, color: Color(0xFFffd700), size: 16),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesRow(bool isDark) {
    String? rawNotes = _order?.notes;
    String displayNotes;
    bool hasNotes = false;

    if (rawNotes != null && rawNotes.trim().isNotEmpty) {
      displayNotes = rawNotes.trim();
      hasNotes = true;
    } else {
      displayNotes = 'لا توجد ملاحظات';
      hasNotes = false;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              'ملاحظات:',
              style: GoogleFonts.cairo(color: ThemeColors.secondaryTextColor(isDark), fontSize: 14),
              softWrap: false,
              overflow: TextOverflow.visible,
            ),
          ),
          Expanded(
            child: Text(
              displayNotes,
              style: GoogleFonts.cairo(
                color: hasNotes ? ThemeColors.textColor(isDark) : ThemeColors.secondaryTextColor(isDark),
                fontSize: 12,
                fontStyle: hasNotes ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFffd700).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.3), width: 1),
              ),
              child: Text(
                'تم نسخ: $text',
                style: GoogleFonts.cairo(color: const Color(0xFF1a1a2e), fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 50, left: 20, right: 20),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildOrderItemsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeColors.cardBackground(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.bagShopping, color: Colors.blue, size: 20),
              const SizedBox(width: 10),
              Text(
                'عناصر الطلب (${_order!.items.length})',
                style: GoogleFonts.cairo(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // ✅ رسالة عند عدم وجود عناصر
          if (_order!.items.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'لا توجد عناصر في هذا الطلب',
                  style: GoogleFonts.cairo(color: ThemeColors.textColor(isDark).withValues(alpha: 0.5), fontSize: 14),
                ),
              ),
            )
          else
            ...(_order!.items.map((item) => _buildOrderItem(item, isDark)).toList()),
        ],
      ),
    );
  }

  Widget _buildOrderItem(order_item_model.OrderItem item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // صورة المنتج
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.withValues(alpha: 0.2),
            ),
            child: _hasValidImage(item)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.image,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator(color: Color(0xFFffd700), strokeWidth: 2));
                      },
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('❌ خطأ في تحميل صورة المنتج: $error');
                        debugPrint('🔗 رابط الصورة: ${item.image}');
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported, color: Colors.grey, size: 20),
                              Text('لا توجد صورة', style: TextStyle(color: Colors.grey, fontSize: 8)),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, color: Colors.grey, size: 20),
                        Text('لا توجد صورة', style: TextStyle(color: Colors.grey, fontSize: 8)),
                      ],
                    ),
                  ),
          ),
          const SizedBox(width: 15),
          // تفاصيل المنتج
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.cairo(
                    color: ThemeColors.textColor(isDark),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'الكمية: ${item.quantity}',
                  style: GoogleFonts.cairo(color: ThemeColors.secondaryTextColor(isDark), fontSize: 12),
                ),
                Text(
                  'السعر: ${NumberFormat('#,###').format(_getItemPrice(item))} د.ع',
                  style: GoogleFonts.cairo(color: const Color(0xFFffd700), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // الربح الحقيقي للمنتج
          Text(
            'ربح: ${NumberFormat('#,###').format(_getItemProfit(item))} د.ع',
            style: GoogleFonts.cairo(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeColors.cardBackground(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.3), width: 1),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ملخص الطلب',
            style: GoogleFonts.cairo(color: const Color(0xFFffd700), fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          _buildSummaryRow('المجموع الفرعي', '${NumberFormat('#,###').format(_calculateSubtotal())} د.ع'),
          const Divider(color: Color(0xFF3a3a5c), thickness: 1),
          _buildSummaryRow('المجموع الكلي', '${NumberFormat('#,###').format(_calculateTotal())} د.ع', isTotal: true),
          const SizedBox(height: 10),
          _buildSummaryRow(
            'إجمالي الربح',
            '${NumberFormat('#,###').format(_calculateTotalProfit())} د.ع',
            isProfit: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    bool isDiscount = false,
    bool isProfit = false,
  }) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(
              color: ThemeColors.textColor(isDark),
              fontSize: isTotal || isProfit ? 16 : 14,
              fontWeight: isTotal || isProfit ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.cairo(
              color: isDiscount
                  ? Colors.red
                  : isProfit
                  ? Colors.green
                  : isTotal
                  ? const Color(0xFFffd700)
                  : ThemeColors.textColor(isDark),
              fontSize: isTotal || isProfit ? 16 : 14,
              fontWeight: isTotal || isProfit ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    // تحويل من UTC إلى توقيت بغداد (UTC+3)
    final baghdadDate = date.toUtc().add(const Duration(hours: 3));
    return '${baghdadDate.year}/${baghdadDate.month.toString().padLeft(2, '0')}/${baghdadDate.day.toString().padLeft(2, '0')}';
  }

  // 🧮 دوال مساعدة للحصول على أسعار العناصر
  double _getItemPrice(order_item_model.OrderItem item) {
    // إذا كان سعر العميل 0، استخدم سعر الجملة كبديل
    if (item.customerPrice > 0) {
      return item.customerPrice.toDouble();
    } else if (item.wholesalePrice > 0) {
      return item.wholesalePrice.toDouble();
    } else {
      return 0.0;
    }
  }

  // 💰 حساب ربح المنتج الواحد الحقيقي
  double _getItemProfit(order_item_model.OrderItem item) {
    // الربح = (سعر البيع - سعر الجملة) × الكمية
    double customerPrice = item.customerPrice.toDouble();
    double wholesalePrice = item.wholesalePrice.toDouble();

    // إذا لم يكن هناك سعر عميل، فلا يوجد ربح
    if (customerPrice <= 0) {
      return 0.0;
    }

    // حساب الربح للوحدة الواحدة
    double profitPerUnit = customerPrice - wholesalePrice;

    // الربح الإجمالي = ربح الوحدة × الكمية
    double totalProfit = profitPerUnit * item.quantity;

    debugPrint('🧮 ربح المنتج ${item.name}:');
    debugPrint('   سعر العميل: $customerPrice د.ع');
    debugPrint('   سعر الجملة: $wholesalePrice د.ع');
    debugPrint('   ربح الوحدة: $profitPerUnit د.ع');
    debugPrint('   الكمية: ${item.quantity}');
    debugPrint('   الربح الإجمالي: $totalProfit د.ع');

    return totalProfit;
  }

  bool _hasValidImage(order_item_model.OrderItem item) {
    return item.image.isNotEmpty && item.image != 'null' && item.image.startsWith('http');
  }
}
