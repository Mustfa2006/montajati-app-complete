import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../services/admin_service.dart';
import '../utils/order_status_helper.dart';

class AdvancedOrderDetailsPage extends StatefulWidget {
  final String orderId;

  const AdvancedOrderDetailsPage({super.key, required this.orderId});

  @override
  State<AdvancedOrderDetailsPage> createState() =>
      _AdvancedOrderDetailsPageState();
}

class _AdvancedOrderDetailsPageState extends State<AdvancedOrderDetailsPage>
    with TickerProviderStateMixin {
  // بيانات الطلب
  AdminOrder? _order;
  bool _isLoading = true;
  bool _isUpdatingStatus = false;
  final List<StatusHistory> _statusHistory = [];

  // تحكم في الرسوم المتحركة
  late AnimationController _statusAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _statusAnimation;
  late Animation<double> _cardAnimation;

  // نظام تحديث الحالات المبسط
  final bool _showStatusDialog = false;

  // تحكم في التبويبات
  final int _selectedTabIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _tabController = TabController(length: 4, vsync: this);
    _loadOrderDetails();
  }

  void _initializeAnimations() {
    _statusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _statusAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _statusAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: Curves.easeOutBack,
      ),
    );
  }

  Future<void> _loadOrderDetails() async {
    try {
      setState(() => _isLoading = true);

      final order = await AdminService.getOrderDetails(widget.orderId);
      final statusHistory = await AdminService.getOrderStatusHistory(
        widget.orderId,
      );

      setState(() {
        _order = order;
        _statusHistory.clear();
        _statusHistory.addAll(statusHistory);
        _isLoading = false;
      });

      // تشغيل الرسوم المتحركة
      _cardAnimationController.forward();
      _statusAnimationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('خطأ في تحميل تفاصيل الطلب: $e');
    }
  }

  @override
  void dispose() {
    _statusAnimationController.dispose();
    _cardAnimationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0e27),
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingWidget() : _buildContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF16213e),
      elevation: 0,
      title: Text(
        _order != null ? 'طلب #${_order!.orderNumber}' : 'تفاصيل الطلب',
        style: const TextStyle(
          color: Color(0xFFffd700),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFFffd700)),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (_order != null) ...[
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFffd700)),
            onPressed: _loadOrderDetails,
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFFffd700)),
            onPressed: _showStatusUpdateDialog,
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffd700)),
          ),
          SizedBox(height: 20),
          Text(
            'جاري تحميل تفاصيل الطلب...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_order == null) {
      return const Center(
        child: Text(
          'لم يتم العثور على الطلب',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    return Column(
      children: [
        // مساحة فارغة للتخطيط
        const SizedBox(height: 10),

        // التبويبات
        _buildTabBar(),

        // محتوى التبويبات
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildItemsTab(),
              _buildStatusHistoryTab(),
              _buildActionsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF16213e),
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFFffd700),
        labelColor: const Color(0xFFffd700),
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(text: 'نظرة عامة', icon: Icon(Icons.info_outline)),
          Tab(text: 'المنتجات', icon: Icon(Icons.inventory)),
          Tab(text: 'سجل الحالات', icon: Icon(Icons.history)),
          Tab(text: 'الإجراءات', icon: Icon(Icons.settings)),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildCustomerInfoCard(),
          const SizedBox(height: 16),
          _buildOrderSummaryCard(),
          const SizedBox(height: 16),
          _buildFinancialCard(),
        ],
      ),
    );
  }

  Widget _buildItemsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildItemsHeader(),
          const SizedBox(height: 16),
          ..._order!.items.map((item) => _buildItemCard(item)),
        ],
      ),
    );
  }

  Widget _buildStatusHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatusHistoryHeader(),
          const SizedBox(height: 16),
          if (_statusHistory.isEmpty)
            const Center(
              child: Text(
                'لا يوجد سجل للحالات حتى الآن',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            )
          else
            ..._statusHistory.map(
              (history) => _buildStatusHistoryItem(history),
            ),
        ],
      ),
    );
  }

  Widget _buildActionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildQuickActionsCard(),
          const SizedBox(height: 16),
          _buildAdvancedActionsCard(),
          const SizedBox(height: 16),
          _buildDangerZoneCard(),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  // نظام تحديث الحالات الجديد - حوار منبثق بسيط
  void _showStatusUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: const Text(
          'تحديث حالة الطلب',
          style: TextStyle(color: Color(0xFFffd700)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'اختر الحالة الجديدة للطلب:',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            _buildSimpleStatusSelector(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateOrderStatusSimple();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFffd700),
            ),
            child: const Text('تحديث', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  String _selectedStatus = '';

  Widget _buildSimpleStatusSelector() {
    final statuses = [
      {'value': 'active', 'text': 'نشط', 'color': Colors.blue},
      {'value': 'in_delivery', 'text': 'قيد التوصيل', 'color': Colors.orange},
      {'value': 'delivered', 'text': 'تم التوصيل', 'color': Colors.green},
      {'value': 'cancelled', 'text': 'ملغي', 'color': Colors.red},
    ];

    return Column(
      children: statuses.map((status) {
        final isSelected = _selectedStatus == status['value'];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              Icons.circle,
              color: status['color'] as Color,
              size: 16,
            ),
            title: Text(
              status['text'] as String,
              style: TextStyle(
                color: isSelected ? const Color(0xFFffd700) : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            onTap: () {
              setState(() {
                _selectedStatus = status['value'] as String;
              });
            },
            selected: isSelected,
            selectedTileColor: const Color(0xFFffd700).withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _updateOrderStatusSimple() async {
    if (_selectedStatus.isEmpty) return;

    setState(() => _isUpdatingStatus = true);

    try {
      await AdminService.updateOrderStatus(_order!.id, _selectedStatus);

      await _loadOrderDetails();
      _showSuccessSnackBar('تم تحديث حالة الطلب بنجاح');
    } catch (e) {
      _showErrorSnackBar('خطأ في تحديث حالة الطلب: $e');
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
    }
  }

  // تم حذف النظام القديم - استخدم النظام الجديد المبسط

  // بطاقة حالة الطلب المتحركة
  Widget _buildStatusCard() {
    final statusColor = OrderStatusHelper.getStatusColor(_order!.status);
    final statusText = OrderStatusHelper.getArabicStatus(_order!.status);
    final statusIcon = OrderStatusHelper.getStatusIcon(_order!.status);

    return AnimatedBuilder(
      animation: _statusAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _statusAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withValues(alpha: 0.2),
                  statusColor.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: statusColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(statusIcon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'حالة الطلب',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            statusText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _showStatusUpdateDialog,
                      icon: const Icon(Icons.edit, color: Color(0xFFffd700)),
                      tooltip: 'تحديث الحالة',
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusInfoItem(
                        'آخر تحديث',
                        DateFormat(
                          'yyyy/MM/dd HH:mm',
                        ).format(_order!.createdAt),
                        Icons.access_time,
                      ),
                    ),
                    Expanded(
                      child: _buildStatusInfoItem(
                        'تاريخ الإنشاء',
                        DateFormat(
                          'yyyy/MM/dd HH:mm',
                        ).format(_order!.createdAt),
                        Icons.calendar_today,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusInfoItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFffd700), size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // بطاقة معلومات العميل
  Widget _buildCustomerInfoCard() {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _cardAnimation.value)),
          child: Opacity(
            opacity: _cardAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF16213e),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: const Color(0xFFffd700).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            color: Color(0xFFffd700),
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'معلومات العميل',
                            style: TextStyle(
                              color: Color(0xFFffd700),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _showEditCustomerDialog,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('تعديل'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFffd700),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildInfoRow(
                    'الاسم',
                    _order!.customerName,
                    Icons.person_outline,
                  ),
                  _buildInfoRow(
                    'الهاتف',
                    _order!.customerPhone.isNotEmpty
                        ? _order!.customerPhone
                        : 'غير محدد',
                    Icons.phone,
                  ),
                  _buildInfoRow(
                    'الرقم البديل',
                    _order!.customerAlternatePhone ?? 'غير محدد',
                    Icons.phone_android,
                  ),
                  _buildInfoRow(
                    'المحافظة',
                    _order!.customerProvince ?? 'غير محدد',
                    Icons.location_on,
                  ),
                  _buildInfoRow(
                    'المدينة',
                    _order!.customerCity ?? 'غير محدد',
                    Icons.location_city,
                  ),
                  _buildInfoRow(
                    'الملاحظات',
                    _order!.customerNotes != null && _order!.customerNotes!.isNotEmpty
                        ? _order!.customerNotes!
                        : 'لا توجد ملاحظات',
                    Icons.note,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          SizedBox(
            width: 110, // ✅ زيادة العرض لمنع الكسرة
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              softWrap: false, // ✅ منع الكسرة
              overflow: TextOverflow.visible, // ✅ إظهار النص كاملاً
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // تحديد لون الكمية المتاحة حسب الحالة
  Color _getAvailabilityColor(AdminOrderItem item) {
    if (item.availableFrom == null || item.availableTo == null) {
      return Colors.grey;
    }

    final currentQuantity = item.quantity;
    final availableTo = item.availableTo!;

    if (currentQuantity > availableTo) {
      return Colors.red; // الكمية المطلوبة أكبر من المتاح
    } else if (availableTo < 5) {
      return Colors.orange; // كمية قليلة
    } else {
      return Colors.green; // كمية جيدة
    }
  }

  // بطاقة ملخص الطلب
  Widget _buildOrderSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
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
              const Icon(Icons.receipt, color: Color(0xFFffd700), size: 24),
              const SizedBox(width: 10),
              const Text(
                'ملخص الطلب',
                style: TextStyle(
                  color: Color(0xFFffd700),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildSummaryRow('رقم الطلب', _order!.orderNumber),
          _buildSummaryRow('عدد المنتجات', '${_order!.itemsCount} منتج'),
          _buildSummaryRow('طريقة الدفع', 'نقداً'),
          _buildSummaryRow('التاجر', _order!.userName),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // بطاقة المعلومات المالية
  Widget _buildFinancialCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1a4d3a), Color(0xFF16213e)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.attach_money, color: Colors.green, size: 24),
                  const SizedBox(width: 10),
                  const Text(
                    'المعلومات المالية',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showEditPricesDialog,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('تعديل الأسعار'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildFinancialItem(
                  'المبلغ الإجمالي',
                  '${_order!.totalAmount.toStringAsFixed(0)} د.ع',
                  Colors.blue,
                  Icons.account_balance_wallet,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFinancialItem(
                  'رسوم التوصيل',
                  '${_order!.deliveryCost.toStringAsFixed(0)} د.ع',
                  Colors.orange,
                  Icons.local_shipping,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildFinancialItem(
                  'الربح المحقق',
                  '${_order!.expectedProfit.toStringAsFixed(0)} د.ع',
                  Colors.green,
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildEditableFinancialItem(
                  'الربح المستهدف',
                  _order!.profitAmount,
                  Colors.purple,
                  Icons.star,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialItem(
    String label,
    String value,
    Color color,
    IconData icon,
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
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
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

  Widget _buildEditableFinancialItem(
    String label,
    double value,
    Color color,
    IconData icon,
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
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _showEditProfitDialog(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${value.toStringAsFixed(0)} د.ع',
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.edit,
                    color: color,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // تبويب المنتجات
  Widget _buildItemsHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory, color: Color(0xFFffd700), size: 24),
          const SizedBox(width: 10),
          Text(
            'منتجات الطلب (${_order!.items.length})',
            style: const TextStyle(
              color: Color(0xFFffd700),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFffd700).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'إجمالي: ${_order!.totalAmount.toStringAsFixed(0)} د.ع',
              style: const TextStyle(
                color: Color(0xFFffd700),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(AdminOrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // صورة المنتج
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF16213e),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFffd700).withValues(alpha: 0.3),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const Icon(
                Icons.shopping_bag,
                color: Color(0xFFffd700),
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // معلومات المنتج
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
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'الكمية: ${item.quantity}',
                            style: const TextStyle(
                              color: Color(0xFFffd700),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'سعر الوحدة: ${item.productPrice.toStringAsFixed(0)} د.ع',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'سعر الجملة: ${(item.wholesalePrice ?? 0).toStringAsFixed(0)} د.ع',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'الربح: ${((item.profitPerItem ?? 0) * item.quantity).toStringAsFixed(0)} د.ع',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // إجمالي المنتج وزر التعديل
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFffd700).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${item.totalPrice.toStringAsFixed(0)} د.ع',
                  style: const TextStyle(
                    color: Color(0xFFffd700),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              IconButton(
                onPressed: () => _showEditProductPriceDialog(item),
                icon: const Icon(
                  Icons.edit,
                  color: Color(0xFFffd700),
                  size: 20,
                ),
                tooltip: 'تعديل السعر',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // تبويب سجل الحالات
  Widget _buildStatusHistoryHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, color: Color(0xFFffd700), size: 24),
          const SizedBox(width: 10),
          Text(
            'سجل تحديثات الحالة (${_statusHistory.length})',
            style: const TextStyle(
              color: Color(0xFFffd700),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // تبويب الإجراءات
  Widget _buildQuickActionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
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
              const Icon(Icons.flash_on, color: Color(0xFFffd700), size: 24),
              const SizedBox(width: 10),
              const Text(
                'الإجراءات السريعة',
                style: TextStyle(
                  color: Color(0xFFffd700),
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
                child: _buildActionButton(
                  'طباعة الطلب',
                  Icons.print,
                  Colors.blue,
                  () => _printOrder(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  'إرسال رسالة',
                  Icons.message,
                  Colors.green,
                  () => _sendMessage(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'تصدير PDF',
                  Icons.picture_as_pdf,
                  Colors.red,
                  () => _exportToPDF(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  'مشاركة الطلب',
                  Icons.share,
                  Colors.purple,
                  () => _shareOrder(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedActionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings, color: Colors.orange, size: 24),
              const SizedBox(width: 10),
              const Text(
                'الإجراءات المتقدمة',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildAdvancedActionItem(
            'تعديل معلومات العميل',
            'تحديث اسم العميل، الهاتف، والعنوان',
            Icons.edit,
            Colors.blue,
            () => _editCustomerInfo(),
          ),
          _buildAdvancedActionItem(
            'إضافة ملاحظة',
            'إضافة ملاحظة خاصة للطلب',
            Icons.note_add,
            Colors.green,
            () => _addNote(),
          ),
          _buildAdvancedActionItem(
            'تغيير التاجر',
            'نقل الطلب إلى تاجر آخر',
            Icons.swap_horiz,
            Colors.orange,
            () => _changeTrader(),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZoneCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: Colors.red, size: 24),
              const SizedBox(width: 10),
              const Text(
                'المنطقة الخطرة',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildDangerActionItem(
            'إلغاء الطلب',
            'إلغاء الطلب نهائياً (لا يمكن التراجع)',
            Icons.cancel,
            () => _cancelOrder(),
          ),
          _buildDangerActionItem(
            'حذف الطلب',
            'حذف الطلب من النظام (لا يمكن التراجع)',
            Icons.delete_forever,
            () => _deleteOrder(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildAdvancedActionItem(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white54,
          size: 16,
        ),
        onTap: onPressed,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor: Colors.black.withValues(alpha: 0.2),
      ),
    );
  }

  Widget _buildDangerActionItem(
    String title,
    String description,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.red, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.red,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.red,
          size: 16,
        ),
        onTap: onPressed,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor: Colors.red.withValues(alpha: 0.1),
      ),
    );
  }

  // دوال الإجراءات
  void _printOrder() {
    _showInfoSnackBar('سيتم إضافة ميزة الطباعة قريباً');
  }

  void _sendMessage() {
    _showInfoSnackBar('سيتم إضافة ميزة إرسال الرسائل قريباً');
  }

  void _exportToPDF() {
    _showInfoSnackBar('سيتم إضافة ميزة تصدير PDF قريباً');
  }

  void _shareOrder() {
    _showInfoSnackBar('سيتم إضافة ميزة المشاركة قريباً');
  }

  void _editCustomerInfo() {
    _showInfoSnackBar('سيتم إضافة ميزة تعديل معلومات العميل قريباً');
  }

  void _addNote() {
    _showInfoSnackBar('سيتم إضافة ميزة إضافة الملاحظات قريباً');
  }

  void _changeTrader() {
    _showInfoSnackBar('سيتم إضافة ميزة تغيير التاجر قريباً');
  }

  void _cancelOrder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: const Text(
          'تأكيد إلغاء الطلب',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          'هل أنت متأكد من إلغاء هذا الطلب؟ لا يمكن التراجع عن هذا الإجراء.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showErrorSnackBar('تم إلغاء الطلب');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('تأكيد الإلغاء'),
          ),
        ],
      ),
    );
  }

  void _deleteOrder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: const Text(
          'تأكيد حذف الطلب',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          'هل أنت متأكد من حذف هذا الطلب نهائياً؟ لا يمكن التراجع عن هذا الإجراء.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AdminService.deleteOrder(_order!.id);
                if (mounted) {
                  Navigator.pop(context);
                  _showSuccessSnackBar('تم حذف الطلب بنجاح');
                }
              } catch (e) {
                if (mounted) {
                  _showErrorSnackBar('خطأ في حذف الطلب: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('تأكيد الحذف'),
          ),
        ],
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.blue),
      );
    }
  }

  // دوال التعديل المطلوبة
  void _showEditCustomerDialog() {
    final nameController = TextEditingController(text: _order!.customerName);
    final phoneController = TextEditingController(text: _order!.customerPhone);
    final alternatePhoneController = TextEditingController(
      text: _order!.customerAlternatePhone ?? '',
    );
    final provinceController = TextEditingController(
      text: _order!.customerProvince ?? '',
    );
    final cityController = TextEditingController(
      text: _order!.customerCity ?? '',
    );
    final addressController = TextEditingController(
      text: _order!.customerAddress,
    );
    final notesController = TextEditingController(
      text: _order!.customerNotes ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: const Text(
          'تعديل معلومات العميل',
          style: TextStyle(color: Color(0xFFffd700)),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEditField('الاسم', nameController, Icons.person),
              const SizedBox(height: 12),
              _buildEditField('رقم الهاتف', phoneController, Icons.phone),
              const SizedBox(height: 12),
              _buildEditField(
                'الرقم البديل',
                alternatePhoneController,
                Icons.phone_android,
              ),
              const SizedBox(height: 12),
              _buildEditField(
                'المحافظة',
                provinceController,
                Icons.location_on,
              ),
              const SizedBox(height: 12),
              _buildEditField('المدينة', cityController, Icons.location_city),
              const SizedBox(height: 12),
              _buildEditField('العنوان', addressController, Icons.home),
              const SizedBox(height: 12),
              _buildEditField(
                'الملاحظات',
                notesController,
                Icons.note,
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateCustomerInfo(
                nameController.text,
                phoneController.text,
                alternatePhoneController.text,
                provinceController.text,
                cityController.text,
                addressController.text,
                notesController.text,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFffd700),
            ),
            child: const Text('حفظ', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white30),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFffd700)),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _updateCustomerInfo(
    String name,
    String phone,
    String alternatePhone,
    String province,
    String city,
    String address,
    String notes,
  ) async {
    try {
      await AdminService.updateCustomerInfo(_order!.id, {
        'customer_name': name,
        'customer_phone': phone,
        'customer_alternate_phone': alternatePhone,
        'customer_province': province,
        'customer_city': city,
        'customer_address': address,
        'customer_notes': notes,
      });
      await _loadOrderDetails();
      _showSuccessSnackBar('تم تحديث معلومات العميل بنجاح');
    } catch (e) {
      _showErrorSnackBar('خطأ في تحديث معلومات العميل: $e');
    }
  }

  void _showEditProfitDialog() {
    final profitController = TextEditingController(
      text: _order!.profitAmount.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: const Text(
          'تعديل الربح المستهدف',
          style: TextStyle(color: Color(0xFFffd700)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEditField(
              'الربح المستهدف',
              profitController,
              Icons.star,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    'الربح المحقق حالياً: ${_order!.expectedProfit.toStringAsFixed(0)} د.ع',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'يمكنك تعديل الربح المستهدف لتتبع أهدافك',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateOrderProfit(
                double.tryParse(profitController.text) ?? _order!.profitAmount,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFffd700),
            ),
            child: const Text('حفظ', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showEditPricesDialog() {
    final totalAmountController = TextEditingController(
      text: _order!.totalAmount.toStringAsFixed(0),
    );
    final deliveryCostController = TextEditingController(
      text: _order!.deliveryCost.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: const Text(
          'تعديل الأسعار',
          style: TextStyle(color: Color(0xFFffd700)),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEditField(
                'المبلغ الإجمالي',
                totalAmountController,
                Icons.attach_money,
              ),
              const SizedBox(height: 12),
              _buildEditField(
                'تكلفة التوصيل',
                deliveryCostController,
                Icons.local_shipping,
              ),
              const SizedBox(height: 20),
              const Text(
                'تعديل أسعار المنتجات:',
                style: TextStyle(
                  color: Color(0xFFffd700),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ..._order!.items.map((item) => _buildProductPriceEditor(item)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateOrderPrices(
                double.tryParse(totalAmountController.text) ??
                    _order!.totalAmount,
                double.tryParse(deliveryCostController.text) ??
                    _order!.deliveryCost,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFffd700),
            ),
            child: const Text('حفظ', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  final Map<String, TextEditingController> _productPriceControllers = {};

  Widget _buildProductPriceEditor(AdminOrderItem item) {
    // تحديث الـ controller بالسعر الحالي في كل مرة
    _productPriceControllers[item.id] = TextEditingController(
      text: (item.customerPrice ?? item.productPrice).toStringAsFixed(0),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.productName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _productPriceControllers[item.id],
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'السعر',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(
                      Icons.attach_money,
                      color: Colors.white70,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFFffd700)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'الكمية: ${item.quantity}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderProfit(double newProfitAmount) async {
    try {
      // تحديث الربح المستهدف في قاعدة البيانات
      await AdminService.updateOrderInfo(
        _order!.id,
        _order!.totalAmount,
        _order!.deliveryCost,
        newProfitAmount,
      );

      await _loadOrderDetails();
      _showSuccessSnackBar('تم تحديث الربح المستهدف بنجاح');
    } catch (e) {
      _showErrorSnackBar('خطأ في تحديث الربح: $e');
    }
  }

  Future<void> _updateOrderPrices(
    double newTotalAmount,
    double newDeliveryCost,
  ) async {
    try {
      // 🧠 نظام حسابات ذكي
      await _smartCalculationSystem(newTotalAmount, newDeliveryCost);

      await _loadOrderDetails();
      _showSuccessSnackBar('تم تحديث الأسعار بذكاء');
    } catch (e) {
      _showErrorSnackBar('خطأ في تحديث الأسعار: $e');
    }
  }

  Future<void> _smartCalculationSystem(
    double newTotalAmount,
    double newDeliveryCost,
  ) async {
    // 📊 حساب القيم الحالية
    double currentProductsTotal = 0;
    double currentTotalCost = 0;
    List<Map<String, dynamic>> itemsData = [];

    for (var item in _order!.items) {
      final currentPrice = double.tryParse(_productPriceControllers[item.id]?.text ?? '0') ??
          (item.customerPrice ?? item.productPrice);
      final wholesalePrice = item.wholesalePrice ?? 0;
      final quantity = item.quantity;

      currentProductsTotal += currentPrice * quantity;
      currentTotalCost += wholesalePrice * quantity;

      itemsData.add({
        'item': item,
        'currentPrice': currentPrice,
        'wholesalePrice': wholesalePrice,
        'quantity': quantity,
        'currentTotal': currentPrice * quantity,
        'currentProfit': (currentPrice - wholesalePrice) * quantity,
      });
    }

    // 📈 حساب التغيير المطلوب
    final targetProductsTotal = newTotalAmount - newDeliveryCost;
    final totalChange = targetProductsTotal - currentProductsTotal;

    debugPrint('🧮 نظام الحسابات الذكي:');
    debugPrint('   المجموع الحالي للمنتجات: ${currentProductsTotal.toStringAsFixed(0)} د.ع');
    debugPrint('   المجموع المستهدف للمنتجات: ${targetProductsTotal.toStringAsFixed(0)} د.ع');
    debugPrint('   التغيير المطلوب: ${totalChange.toStringAsFixed(0)} د.ع');

    if (totalChange.abs() > 1) { // إذا كان التغيير أكبر من 1 دينار
      await _distributeChangeIntelligently(itemsData, totalChange);
    }

    // تحديث معلومات الطلب
    final newProfit = targetProductsTotal - currentTotalCost;
    await AdminService.updateOrderInfo(
      _order!.id,
      newTotalAmount,
      newDeliveryCost,
      newProfit,
    );
  }

  Future<void> _distributeChangeIntelligently(
    List<Map<String, dynamic>> itemsData,
    double totalChange,
  ) async {
    if (itemsData.isEmpty) return;

    // 🎯 استراتيجية التوزيع الذكي
    if (totalChange > 0) {
      // زيادة: توزع بناءً على القيمة النسبية لكل منتج
      await _distributeIncrease(itemsData, totalChange);
    } else {
      // نقصان: توزع بناءً على هامش الربح المتاح
      await _distributeDecrease(itemsData, totalChange.abs());
    }
  }

  Future<void> _distributeIncrease(
    List<Map<String, dynamic>> itemsData,
    double increaseAmount,
  ) async {
    final totalCurrentValue = itemsData.fold<double>(
      0, (sum, item) => sum + item['currentTotal']
    );

    for (var itemData in itemsData) {
      final item = itemData['item'] as AdminOrderItem;
      final currentPrice = itemData['currentPrice'] as double;
      final quantity = itemData['quantity'] as int;
      final currentTotal = itemData['currentTotal'] as double;

      // حساب النسبة من الزيادة لهذا المنتج
      final proportion = totalCurrentValue > 0 ? currentTotal / totalCurrentValue : 1.0 / itemsData.length;
      final itemIncrease = increaseAmount * proportion;
      final priceIncrease = itemIncrease / quantity;

      final newPrice = currentPrice + priceIncrease;
      final newTotalPrice = newPrice * quantity;
      final newProfitPerItem = newPrice - (itemData['wholesalePrice'] as double);

      debugPrint('📈 زيادة ${item.productName}:');
      debugPrint('   السعر: ${currentPrice.toStringAsFixed(0)} → ${newPrice.toStringAsFixed(0)} د.ع');
      debugPrint('   الزيادة: +${priceIncrease.toStringAsFixed(0)} د.ع');

      // تحديث المنتج
      await AdminService.updateProductPrice(
        _order!.id,
        item.id,
        newPrice,
        newTotalPrice,
        newProfitPerItem,
      );

      // تحديث الـ controller
      _productPriceControllers[item.id]?.text = newPrice.toStringAsFixed(0);
    }
  }

  Future<void> _distributeDecrease(
    List<Map<String, dynamic>> itemsData,
    double decreaseAmount,
  ) async {
    // ترتيب المنتجات حسب هامش الربح (الأعلى ربحاً أولاً)
    itemsData.sort((a, b) {
      final profitA = a['currentProfit'] as double;
      final profitB = b['currentProfit'] as double;
      return profitB.compareTo(profitA);
    });

    double remainingDecrease = decreaseAmount;

    for (var itemData in itemsData) {
      if (remainingDecrease <= 0) break;

      final item = itemData['item'] as AdminOrderItem;
      final currentPrice = itemData['currentPrice'] as double;
      final wholesalePrice = itemData['wholesalePrice'] as double;
      final quantity = itemData['quantity'] as int;

      // حساب أقصى نقصان ممكن (بحيث لا يقل السعر عن سعر الجملة + هامش أمان)
      final minPrice = wholesalePrice + 1000; // هامش أمان 1000 دينار
      final maxDecrease = (currentPrice - minPrice) * quantity;

      if (maxDecrease > 0) {
        final actualDecrease = math.min(remainingDecrease, maxDecrease);
        final priceDecrease = actualDecrease / quantity;
        final newPrice = currentPrice - priceDecrease;
        final newTotalPrice = newPrice * quantity;
        final newProfitPerItem = newPrice - wholesalePrice;

        debugPrint('📉 تقليل ${item.productName}:');
        debugPrint('   السعر: ${currentPrice.toStringAsFixed(0)} → ${newPrice.toStringAsFixed(0)} د.ع');
        debugPrint('   التقليل: -${priceDecrease.toStringAsFixed(0)} د.ع');

        // تحديث المنتج
        await AdminService.updateProductPrice(
          _order!.id,
          item.id,
          newPrice,
          newTotalPrice,
          newProfitPerItem,
        );

        // تحديث الـ controller
        _productPriceControllers[item.id]?.text = newPrice.toStringAsFixed(0);

        remainingDecrease -= actualDecrease;
      }
    }

    if (remainingDecrease > 0) {
      debugPrint('⚠️ لم يتم توزيع ${remainingDecrease.toStringAsFixed(0)} د.ع (محدود بأسعار الجملة)');
    }
  }

  Future<void> _updateSingleProductPrice(
    AdminOrderItem item,
    double newPrice,
    int newQuantity,
  ) async {
    try {
      debugPrint('🔧 تحديث منتج واحد: ${item.productName}');
      debugPrint('   السعر: ${item.customerPrice ?? item.productPrice} → $newPrice د.ع');
      debugPrint('   الكمية: ${item.quantity} → $newQuantity');

      // حساب القيم الجديدة للمنتج
      final newTotalPrice = newPrice * newQuantity;
      final newProfitPerItem = newPrice - (item.wholesalePrice ?? 0);

      // تحديث المنتج في قاعدة البيانات
      await AdminService.updateProductPrice(
        _order!.id,
        item.id,
        newPrice,
        newTotalPrice,
        newProfitPerItem,
        newQuantity: newQuantity,
      );

      // 🧠 إعادة حساب إجمالي الطلب بذكاء
      await _recalculateOrderTotals();

      await _loadOrderDetails();
      _showSuccessSnackBar('تم تحديث المنتج بذكاء');
    } catch (e) {
      _showErrorSnackBar('خطأ في تحديث المنتج: $e');
    }
  }

  Future<void> _recalculateOrderTotals() async {
    try {
      // 🧮 إعادة حساب الإجماليات بناءً على المنتجات المحدثة
      double totalAmount = 0;
      double totalProfit = 0;

      // حساب الإجماليات من المنتجات الحالية
      for (var item in _order!.items) {
        // استخدام السعر المحدث من الـ controller إذا كان متاحاً
        final currentPrice = double.tryParse(_productPriceControllers[item.id]?.text ?? '0') ??
            (item.customerPrice ?? item.productPrice);
        final quantity = item.quantity;
        final wholesalePrice = item.wholesalePrice ?? 0;

        final itemTotal = currentPrice * quantity;
        final itemProfit = (currentPrice - wholesalePrice) * quantity;

        totalAmount += itemTotal;
        totalProfit += itemProfit;
      }

      // تحديث إجمالي الطلب (مع رسوم التوصيل)
      final newOrderTotal = totalAmount + _order!.deliveryCost;

      // تحديث قاعدة البيانات
      await AdminService.updateOrderInfo(
        _order!.id,
        newOrderTotal,
        _order!.deliveryCost,
        totalProfit,
      );

      debugPrint('✅ تم إعادة حساب إجماليات الطلب:');
      debugPrint('   المبلغ الإجمالي: $newOrderTotal د.ع');
      debugPrint('   الربح الإجمالي: $totalProfit د.ع');

    } catch (e) {
      debugPrint('❌ خطأ في إعادة حساب الإجماليات: $e');
    }
  }

  void _showEditProductPriceDialog(AdminOrderItem item) {
    final priceController = TextEditingController(
      text: (item.customerPrice ?? item.productPrice).toStringAsFixed(0),
    );
    final quantityController = TextEditingController(
      text: item.quantity.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: Text(
          'تعديل ${item.productName}',
          style: const TextStyle(color: Color(0xFFffd700)),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEditField(
                'سعر الوحدة',
                priceController,
                Icons.attach_money,
              ),
              const SizedBox(height: 12),
              _buildEditField('الكمية', quantityController, Icons.numbers),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      'سعر الجملة',
                      '${(item.wholesalePrice ?? 0).toStringAsFixed(0)} د.ع',
                      Icons.store,
                    ),
                    _buildInfoRow(
                      'السعر الحالي',
                      '${item.productPrice.toStringAsFixed(0)} د.ع',
                      Icons.person,
                    ),
                    _buildInfoRow(
                      'المجموع الحالي',
                      '${item.totalPrice.toStringAsFixed(0)} د.ع',
                      Icons.calculate,
                    ),
                    // عرض الكمية المتاحة إذا كانت متوفرة
                    if (item.availableFrom != null && item.availableTo != null)
                      _buildInfoRow(
                        'الكمية المتاحة',
                        'من ${item.availableFrom} إلى ${item.availableTo}',
                        Icons.inventory,
                        color: _getAvailabilityColor(item),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateSingleProductPrice(
                item,
                double.tryParse(priceController.text) ?? item.productPrice,
                int.tryParse(quantityController.text) ?? item.quantity,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFffd700),
            ),
            child: const Text('حفظ', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }



  Widget _buildStatusHistoryItem(StatusHistory history) {
    final statusColor = OrderStatusHelper.getStatusColor(history.status);
    final statusText = OrderStatusHelper.getArabicStatus(history.status);
    final statusIcon = OrderStatusHelper.getStatusIcon(history.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('yyyy/MM/dd HH:mm').format(history.createdAt),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (history.notes != null && history.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      history.notes!,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
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
}
