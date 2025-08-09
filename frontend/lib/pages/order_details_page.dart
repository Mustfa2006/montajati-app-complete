import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/admin_service.dart';
import '../services/order_sync_service.dart';
import '../widgets/common_header.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage>
    with TickerProviderStateMixin {
  AdminOrder? _orderDetails;
  bool _isLoading = true;
  String? _error;

  late TabController _tabController;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadOrderDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final details = await AdminService.getOrderDetails(widget.orderId);

      setState(() {
        _orderDetails = details;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // تحديث حالة الطلب من شركة الوسيط
  Future<void> _refreshOrderStatusFromWaseet() async {
    if (_orderDetails?.waseetQrId != null) {
      try {
        // إظهار مؤشر التحميل
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'جاري تحديث حالة الطلب من شركة الوسيط...',
                  style: GoogleFonts.cairo(fontSize: 14),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF17a2b8),
            duration: const Duration(seconds: 3),
          ),
        );

        // فحص حالة الطلب في شركة الوسيط
        await OrderSyncService.checkOrderStatus(_orderDetails!.waseetQrId!);

        // إعادة تحميل تفاصيل الطلب
        await _loadOrderDetails();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم تحديث حالة الطلب بنجاح',
                style: GoogleFonts.cairo(fontSize: 14),
              ),
              backgroundColor: const Color(0xFF28a745),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'فشل في تحديث حالة الطلب: $e',
                style: GoogleFonts.cairo(fontSize: 14),
              ),
              backgroundColor: const Color(0xFFdc3545),
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'هذا الطلب غير مربوط بشركة الوسيط',
            style: GoogleFonts.cairo(fontSize: 14),
          ),
          backgroundColor: const Color(0xFFffc107),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: Column(
        children: [
          // الشريط العلوي الموحد
          CommonHeader(
            title: 'تفاصيل الطلب',
            rightActions: [
              // زر الرجوع على اليمين
              GestureDetector(
                onTap: () => Navigator.pop(context),
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
                    FontAwesomeIcons.arrowLeft,
                    color: Color(0xFFffd700),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          // المحتوى
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _error != null
                ? _buildErrorState()
                : _buildOrderDetailsContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFffd700), strokeWidth: 3),
          SizedBox(height: 20),
          Text(
            'جاري تحميل تفاصيل الطلب...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            FontAwesomeIcons.triangleExclamation,
            color: Color(0xFFdc3545),
            size: 60,
          ),
          const SizedBox(height: 20),
          Text(
            'خطأ في تحميل تفاصيل الطلب',
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _error ?? 'حدث خطأ غير متوقع',
            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _loadOrderDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFffd700),
              foregroundColor: const Color(0xFF1a1a2e),
            ),
            icon: const Icon(FontAwesomeIcons.arrowsRotate),
            label: Text(
              'إعادة المحاولة',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsContent() {
    if (_orderDetails == null) return const SizedBox();

    return Column(
      children: [
        _buildHeader(),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildItemsTab(),
              _buildCustomerTab(),
              _buildHistoryTab(),
              _buildNotesTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final order = _orderDetails!;
    final statusColor = _getStatusColor(order.waseetStatus ?? order.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF16213e), const Color(0xFF1a1a2e)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // معلومات الطلب
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الطلب #${order.orderNumber}',
                  style: GoogleFonts.cairo(
                    color: const Color(0xFFffd700),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                          Text(
                            'تم إنشاؤه في ${_formatDate(order.createdAt)}',
                            style: GoogleFonts.cairo(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          if (order.waseetQrId != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF28a745,
                                ).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(
                                    0xFF28a745,
                                  ).withValues(alpha: 0.5),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'مربوط بالوسيط',
                                style: GoogleFonts.cairo(
                                  color: const Color(0xFF28a745),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                  ],
                ),
                // زر تحديث حالة الوسيط
                if (order.waseetQrId != null)
                  IconButton(
                    onPressed: _refreshOrderStatusFromWaseet,
                    icon: const Icon(
                      FontAwesomeIcons.truck,
                      color: Color(0xFF28a745),
                      size: 18,
                    ),
                    tooltip: 'تحديث من الوسيط',
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // معلومات سريعة
            Row(
              children: [
                Expanded(
                  child: _buildQuickInfo(
                    'الحالة',
                    _getStatusText(order.status),
                    FontAwesomeIcons.circleInfo,
                    statusColor,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildQuickInfo(
                    'المبلغ الإجمالي',
                    '${order.totalAmount.toStringAsFixed(0)} د.ع',
                    FontAwesomeIcons.coins,
                    const Color(0xFFffd700),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildQuickInfo(
                    'الربح',
                    '${order.profitAmount.toStringAsFixed(0)} د.ع',
                    FontAwesomeIcons.chartLine,
                    const Color(0xFF28a745),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildQuickInfo(
                    'العناصر',
                    order.itemsCount.toString(),
                    FontAwesomeIcons.boxOpen,
                    const Color(0xFF17a2b8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInfo(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 5),
          Text(
            title,
            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.cairo(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateStatusButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFffd700), const Color(0xFFe6b31e)],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFffd700).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          debugPrint('🔥 تم الضغط على زر تحديث الحالة الكبير!');
          _showUpdateStatusDialog();
        },
        borderRadius: BorderRadius.circular(15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              FontAwesomeIcons.penToSquare,
              color: Color(0xFF1a1a2e),
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              'تحديث حالة الطلب',
              style: TextStyle(
                color: Color(0xFF1a1a2e),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFffd700), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إجراءات أخرى',
            style: TextStyle(
              color: Color(0xFFffd700),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildActionButton(
                  FontAwesomeIcons.print,
                  'طباعة',
                  () => _printOrder(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  FontAwesomeIcons.download,
                  'تصدير',
                  () => _exportOrder(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          debugPrint('🔘 تم الضغط على زر: $tooltip');
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16), // زيادة الحجم
          decoration: BoxDecoration(
            color: const Color(
              0xFFffd700,
            ).withValues(alpha: 0.2), // لون أكثر وضوحاً
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFffd700), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: const Color(0xFFffd700),
                size: 20,
              ), // أيقونة أكبر
              const SizedBox(height: 4),
              Text(
                tooltip,
                style: const TextStyle(
                  color: Color(0xFFffd700),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF16213e),
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFFffd700),
        labelColor: const Color(0xFFffd700),
        unselectedLabelColor: Colors.white60,
        labelStyle: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: GoogleFonts.cairo(fontSize: 12),
        tabs: const [
          Tab(text: 'نظرة عامة'),
          Tab(text: 'المنتجات'),
          Tab(text: 'العميل'),
          Tab(text: 'السجل'),
          Tab(text: 'الملاحظات'),
        ],
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
      case 'confirmed':
      case '1':
      case 'فعال':
        return const Color(0xFFffd700); // أصفر ذهبي
      case 'in_delivery':
      case 'processing':
      case '2':
      case 'قيد التوصيل الى الزبون (في عهدة المندوب)':
        return const Color(0xFF17a2b8); // سماوي
      case 'delivered':
      case 'shipped':
      case '3':
      case 'تم التسليم':
        return const Color(0xFF28a745); // أخضر
      case 'rejected':
      case 'cancelled':
      case '4':
      case 'الغاء الطلب':
        return const Color(0xFFdc3545); // أحمر
      case 'pending':
        return const Color(0xFF6c757d); // رمادي
      default:
        return const Color(0xFF6c757d); // رمادي
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
      case 'confirmed':
      case '1':
        return 'نشط';
      case 'in_delivery':
      case 'processing':
      case '2':
        return 'قيد التوصيل';
      case 'delivered':
      case 'shipped':
      case '3':
        return 'مكتمل';
      case 'rejected':
      case 'cancelled':
      case '4':
        return 'ملغي';
      case 'pending':
        return 'في الانتظار';
      case 'قيد التوصيل الى الزبون (في عهدة المندوب)':
        return 'قيد التوصيل للزبون';
      case 'فعال':
        return 'نشط';
      case 'الغاء الطلب':
        return 'ملغي';
      case 'تم التسليم':
        return 'مكتمل';
      default:
        return status.isNotEmpty ? status : 'غير محدد';
    }
  }

  void _printOrder() {
    // ignore: todo
    // TODO: تنفيذ طباعة الطلب
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('ميزة الطباعة قيد التطوير')));
  }

  void _exportOrder() {
    // ignore: todo
    // TODO: تنفيذ تصدير الطلب
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('ميزة التصدير قيد التطوير')));
  }

  void _showUpdateStatusDialog() {
    debugPrint('🔄 فتح حوار تحديث حالة الطلب');
    final currentStatus = _orderDetails?.status ?? 'pending';
    String selectedStatus = currentStatus;
    debugPrint('📋 الحالة الحالية: $currentStatus');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1a1a2e),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Color(0xFFffd700), width: 1),
          ),
          title: const Row(
            children: [
              Icon(Icons.edit, color: Color(0xFFffd700)),
              SizedBox(width: 10),
              Text(
                'تحديث حالة الطلب',
                style: TextStyle(color: Color(0xFFffd700), fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'اختر الحالة الجديدة للطلب:',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213e),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFffd700).withValues(alpha: 0.3),
                  ),
                ),
                child: DropdownButton<String>(
                  value: selectedStatus,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1a1a2e),
                  style: const TextStyle(color: Colors.white),
                  underline: const SizedBox(),
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFFffd700),
                  ),
                  items:
                      [
                        {
                          'value': 'pending',
                          'label': 'في الانتظار',
                          'color': const Color(0xFFffd700),
                        },
                        {
                          'value': 'active',
                          'label': 'نشط',
                          'color': const Color(0xFF2196F3),
                        },
                        {
                          'value': 'in_delivery',
                          'label': 'قيد التوصيل',
                          'color': const Color(0xFFFF9800),
                        },
                        {
                          'value': 'delivered',
                          'label': 'تم التوصيل',
                          'color': const Color(0xFF4CAF50),
                        },
                        {
                          'value': 'cancelled',
                          'label': 'ملغي',
                          'color': const Color(0xFFF44336),
                        },
                        {
                          'value': 'rejected',
                          'label': 'مرفوض',
                          'color': const Color(0xFFF44336),
                        },
                      ].map((status) {
                        return DropdownMenuItem<String>(
                          value: status['value'] as String,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: status['color'] as Color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(status['label'] as String),
                            ],
                          ),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: selectedStatus == currentStatus
                  ? null
                  : () {
                      debugPrint(
                        '🔄 بدء تحديث حالة الطلب من $currentStatus إلى $selectedStatus',
                      );
                      _updateOrderStatus(selectedStatus);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFffd700),
                foregroundColor: const Color(0xFF1a1a2e),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('تحديث'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    try {
      debugPrint('🔄 تحديث حالة الطلب: ${widget.orderId} إلى $newStatus');

      // إغلاق الحوار أولاً
      Navigator.pop(context);

      // عرض مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFffd700)),
        ),
      );

      // تحديث حالة الطلب في قاعدة البيانات
      final success = await AdminService.updateOrderStatus(
        widget.orderId,
        newStatus,
        notes: 'تم تحديث الحالة من لوحة التحكم',
        updatedBy: 'admin',
      );

      // إغلاق مؤشر التحميل
      if (mounted) Navigator.pop(context);

      if (success) {
        // إعادة جلب تفاصيل الطلب المحدثة
        await _loadOrderDetails();

        // عرض رسالة نجاح
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  'تم تحديث حالة الطلب إلى "${_getStatusText(newStatus)}" بنجاح',
                ),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 3),
          ),
        );
        }
      } else {
        // عرض رسالة خطأ
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 10),
                Text('فشل في تحديث حالة الطلب. يرجى المحاولة مرة أخرى'),
              ],
            ),
            backgroundColor: Color(0xFFF44336),
            duration: Duration(seconds: 3),
          ),
        );
        }
      }
    } catch (e) {
      // إغلاق مؤشر التحميل في حالة الخطأ
      if (mounted) Navigator.pop(context);

      // عرض رسالة خطأ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 10),
              Text('خطأ في تحديث حالة الطلب: ${e.toString()}'),
            ],
          ),
          backgroundColor: const Color(0xFFF44336),
          duration: const Duration(seconds: 3),
        ),
      );
      }
    }
  }

  // تبويب نظرة عامة
  Widget _buildOverviewTab() {
    // تم إزالة order غير المستخدم

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // زر تحديث الحالة المميز
          _buildUpdateStatusButton(),
          const SizedBox(height: 20),

          // أزرار الإجراءات الأخرى
          _buildActionButtons(),
          const SizedBox(height: 20),

          // الإحصائيات المالية
          _buildFinancialSummary(),
          const SizedBox(height: 20),

          // معلومات الطلب الأساسية
          _buildBasicInfo(),
          const SizedBox(height: 20),

          // معلومات التوصيل
          _buildDeliveryInfo(),
          const SizedBox(height: 20),

          // الخط الزمني للطلب
          _buildOrderTimeline(),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    final order = _orderDetails!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFffd700).withValues(alpha: 0.1),
            const Color(0xFFe6b31e).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                FontAwesomeIcons.chartPie,
                color: Color(0xFFffd700),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'الملخص المالي',
                style: GoogleFonts.cairo(
                  color: const Color(0xFFffd700),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: _buildFinancialCard(
                  'تكلفة التوصيل',
                  '${order.deliveryCost.toStringAsFixed(0)} د.ع',
                  FontAwesomeIcons.receipt,
                  const Color(0xFFdc3545),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFinancialCard(
                  'المبلغ الإجمالي',
                  '${order.totalAmount.toStringAsFixed(0)} د.ع',
                  FontAwesomeIcons.coins,
                  const Color(0xFF17a2b8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _buildFinancialCard(
                  'صافي الربح',
                  '${order.profitAmount.toStringAsFixed(0)} د.ع',
                  FontAwesomeIcons.chartLine,
                  const Color(0xFF28a745),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFinancialCard(
                  'الربح المتوقع',
                  '${order.expectedProfit.toStringAsFixed(0)} د.ع',
                  FontAwesomeIcons.percent,
                  const Color(0xFFffd700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.cairo(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    final order = _orderDetails!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معلومات الطلب',
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),

          _buildInfoRow('رقم الطلب', order.orderNumber),
          _buildInfoRow('تاريخ الإنشاء', _formatDate(order.createdAt)),
          _buildInfoRow('الحالة الحالية', _getStatusText(order.status)),
          _buildInfoRow('عدد المنتجات', order.itemsCount.toString()),

          // عرض معرف الوسيط إذا كان موجوداً
          if (order.waseetQrId != null && order.waseetQrId!.isNotEmpty)
            _buildWaseetInfoRow('معرف الوسيط (QR ID)', order.waseetQrId!),

          if (order.deliveryCost > 0)
            _buildInfoRow(
              'رسوم التوصيل',
              '${order.deliveryCost.toStringAsFixed(0)} د.ع',
            ),
          if (order.customerNotes != null && order.customerNotes!.isNotEmpty)
            _buildInfoRow('ملاحظات العميل', order.customerNotes!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140, // ✅ زيادة العرض لمنع الكسرة
            child: Text(
              label,
              style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14),
              softWrap: false, // ✅ منع الكسرة
              overflow: TextOverflow.visible, // ✅ إظهار النص كاملاً
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // دالة خاصة لعرض معرف الوسيط مع تنسيق مميز
  Widget _buildWaseetInfoRow(String label, String qrId) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14),
              softWrap: false,
              overflow: TextOverflow.visible,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF28a745).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF28a745).withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    FontAwesomeIcons.qrcode,
                    color: Color(0xFF28a745),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      qrId,
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF28a745),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openWaseetLink(qrId),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF28a745).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        FontAwesomeIcons.upRightFromSquare,
                        color: Color(0xFF28a745),
                        size: 12,
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

  // فتح رابط الوسيط
  void _openWaseetLink(String qrId) async {
    final url = 'https://alwaseet-iq.net/merchant/print-single-tcpdf?id=$qrId';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('لا يمكن فتح الرابط: $url'),
              backgroundColor: const Color(0xFFF44336),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في فتح الرابط: $e'),
            backgroundColor: const Color(0xFFF44336),
          ),
        );
      }
    }
  }

  Widget _buildDeliveryInfo() {
    final order = _orderDetails!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF17a2b8).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFF17a2b8).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                FontAwesomeIcons.truck,
                color: Color(0xFF17a2b8),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'معلومات التوصيل',
                style: GoogleFonts.cairo(
                  color: const Color(0xFF17a2b8),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          _buildInfoRow('العنوان', order.customerAddress),
          if (order.customerProvince != null)
            _buildInfoRow('المحافظة', order.customerProvince!),
          if (order.customerCity != null)
            _buildInfoRow('المدينة', order.customerCity!),
          if (order.deliveryCost > 0)
            _buildInfoRow(
              'تكلفة التوصيل',
              '${order.deliveryCost.toStringAsFixed(0)} د.ع',
            ),
        ],
      ),
    );
  }

  Widget _buildOrderTimeline() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الخط الزمني للطلب',
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),

          // سيتم إضافة الخط الزمني هنا
          const Center(
            child: Text(
              'سيتم إضافة الخط الزمني قريباً',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  // تبويب المنتجات
  Widget _buildItemsTab() {
    final order = _orderDetails!;

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: order.items.length,
      itemBuilder: (context, index) {
        final item = order.items[index];
        return _buildAdminProductCard(item);
      },
    );
  }

  Widget _buildAdminProductCard(AdminOrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF16213e),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFffd700).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.inventory_2,
                  color: Color(0xFFffd700),
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'الكمية: ${item.quantity}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${item.totalPrice.toStringAsFixed(0)} د.ع',
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // تم حذف _buildProductCard غير المستخدم

  // تم حذف _buildItemInfo و _buildItemFinancial غير المستخدمين

  // تبويب العميل
  Widget _buildCustomerTab() {
    // تم إزالة order غير المستخدم

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildCustomerInfo(),
          const SizedBox(height: 20),
          _buildMerchantInfo(),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo() {
    final order = _orderDetails!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                FontAwesomeIcons.noteSticky,
                color: Color(0xFFffd700),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'الملاحظات',
                style: GoogleFonts.cairo(
                  color: const Color(0xFFffd700),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // عرض ملاحظات العميل
          if (order.customerNotes != null && order.customerNotes!.isNotEmpty)
            _buildInfoRow('ملاحظات العميل', order.customerNotes!)
          else
            _buildInfoRow('ملاحظات العميل', 'لا توجد ملاحظات'),
        ],
      ),
    );
  }

  Widget _buildMerchantInfo() {
    final order = _orderDetails!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                FontAwesomeIcons.store,
                color: Color(0xFF17a2b8),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'معلومات التاجر',
                style: GoogleFonts.cairo(
                  color: const Color(0xFF17a2b8),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          _buildInfoRow('الاسم', order.userName),
          _buildInfoRow('رقم الهاتف', order.userPhone),
        ],
      ),
    );
  }

  // تبويب السجل
  Widget _buildHistoryTab() {
    final order = _orderDetails!;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF16213e),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFFffd700).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.history, color: Color(0xFFffd700), size: 48),
                const SizedBox(height: 15),
                const Text(
                  'سجل الطلب',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'تاريخ الإنشاء: ${_formatDate(order.createdAt)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'الحالة الحالية: ${_getStatusText(order.status)}',
                  style: const TextStyle(
                    color: Color(0xFFffd700),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // تم حذف _buildHistoryCard غير المستخدم

  // تم حذف _getStatusIcon غير المستخدم

  // تبويب الملاحظات
  Widget _buildNotesTab() {
    final order = _orderDetails!;

    return Column(
      children: [
        // إضافة ملاحظة جديدة
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إضافة ملاحظة جديدة',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _noteController,
                style: GoogleFonts.cairo(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'اكتب ملاحظتك هنا...',
                  hintStyle: GoogleFonts.cairo(color: Colors.white60),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _addNote(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFffd700),
                        foregroundColor: const Color(0xFF1a1a2e),
                      ),
                      icon: const Icon(FontAwesomeIcons.plus, size: 16),
                      label: Text(
                        'إضافة ملاحظة عامة',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _addNote(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF17a2b8),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(FontAwesomeIcons.lock, size: 16),
                      label: Text(
                        'ملاحظة داخلية',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // قائمة الملاحظات
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF16213e),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: const Color(0xFFffd700).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.note_alt,
                    color: Color(0xFFffd700),
                    size: 48,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'ملاحظات الطلب',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (order.customerNotes != null &&
                      order.customerNotes!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1a1a2e),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ملاحظات العميل:',
                            style: TextStyle(
                              color: Color(0xFFffd700),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            order.customerNotes!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      'لا توجد ملاحظات لهذا الطلب',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // تم حذف _buildNoteCard غير المستخدم

  Future<void> _addNote(bool isInternal) async {
    if (_noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة الملاحظة أولاً')),
      );
      return;
    }

    try {
      await AdminService.addOrderNote(
        widget.orderId,
        _noteController.text.trim(),
        type: isInternal ? 'internal' : 'general',
        isInternal: isInternal,
        createdBy: 'admin',
      );

      _noteController.clear();
      await _loadOrderDetails(); // إعادة تحميل التفاصيل

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة الملاحظة بنجاح'),
            backgroundColor: Color(0xFF28a745),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إضافة الملاحظة: $e'),
            backgroundColor: const Color(0xFFdc3545),
          ),
        );
      }
    }
  }
}
