import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/admin_service.dart';
import '../utils/order_status_helper.dart';

class SimpleOrderDetailsPage extends StatefulWidget {
  final String orderId;

  const SimpleOrderDetailsPage({super.key, required this.orderId});

  @override
  State<SimpleOrderDetailsPage> createState() => _SimpleOrderDetailsPageState();
}

class _SimpleOrderDetailsPageState extends State<SimpleOrderDetailsPage>
    with TickerProviderStateMixin {
  AdminOrder? _order;
  bool _isLoading = true;
  bool _isUpdating = false;
  final List<StatusHistory> _statusHistory = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrderDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderDetails() async {
    try {
      final order = await AdminService.getOrderDetails(widget.orderId);
      final statusHistory = await AdminService.getOrderStatusHistory(
        widget.orderId,
      );

      if (mounted) {
        setState(() {
          _order = order;
          _statusHistory.clear();
          _statusHistory.addAll(statusHistory);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('خطأ في جلب تفاصيل الطلب: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0e27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213e),
        title: Text(
          'تفاصيل الطلب',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_order != null)
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFFffd700)),
              onPressed: _showStatusUpdateDialog,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffd700)),
              ),
            )
          : _order == null
          ? const Center(
              child: Text(
                'لم يتم العثور على الطلب',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            )
          : _buildOrderDetailsWithTabs(),
    );
  }

  Widget _buildOrderDetailsWithTabs() {
    return Column(
      children: [
        // التبويبات
        Container(
          color: const Color(0xFF16213e),
          child: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFFffd700),
            labelColor: const Color(0xFFffd700),
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'تفاصيل الطلب', icon: Icon(Icons.info_outline)),
              Tab(text: 'سجل الحالات', icon: Icon(Icons.history)),
              Tab(text: 'الإجراءات', icon: Icon(Icons.settings)),
            ],
          ),
        ),
        // محتوى التبويبات
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOrderDetailsTab(),
              _buildStatusHistoryTab(),
              _buildActionsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildCustomerInfo(),
          const SizedBox(height: 16),
          _buildOrderSummary(),
          const SizedBox(height: 16),
          _buildItemsList(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final statusColor = OrderStatusHelper.getStatusColor(_order!.status);
    final statusText = OrderStatusHelper.getArabicStatus(_order!.status);
    final statusIcon = OrderStatusHelper.getStatusIcon(_order!.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'رقم الطلب: ${_order!.orderNumber}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _isUpdating ? null : _showStatusUpdateDialog,
            icon: _isUpdating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.edit),
            label: Text(_isUpdating ? 'جاري التحديث...' : 'تحديث الحالة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFffd700),
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'معلومات العميل',
                style: TextStyle(
                  color: Color(0xFFffd700),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
          _buildInfoRow('الاسم', _order!.customerName, Icons.person),
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
          const SizedBox(width: 10),
          SizedBox(
            width: 110, // ✅ عرض كافي لمنع الكسرة
            child: Text(
              '$label: ',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
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
                fontWeight: FontWeight.w500,
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

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ملخص الطلب',
                style: TextStyle(
                  color: Color(0xFFffd700),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showEditPricesDialog,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('تعديل الأسعار'),
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
          _buildSummaryRow(
            'المبلغ الإجمالي',
            '${_order!.totalAmount.toStringAsFixed(0)} د.ع',
          ),
          _buildSummaryRow(
            'تكلفة التوصيل',
            '${_order!.deliveryCost.toStringAsFixed(0)} د.ع',
          ),
          _buildSummaryRow(
            'الربح المتوقع',
            '${_order!.profitAmount.toStringAsFixed(0)} د.ع',
          ),
          _buildSummaryRow(
            'تاريخ الطلب',
            DateFormat('yyyy/MM/dd HH:mm').format(_order!.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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

  Widget _buildItemsList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'منتجات الطلب (${_order!.items.length})',
            style: const TextStyle(
              color: Color(0xFFffd700),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          ..._order!.items.map((item) => _buildItemCard(item)),
        ],
      ),
    );
  }

  Widget _buildItemCard(AdminOrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
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
              // تفاصيل المنتج
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFffd700,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'الكمية: ${item.quantity}',
                            style: const TextStyle(
                              color: Color(0xFFffd700),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // زر تعديل سعر المنتج
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
          const SizedBox(height: 12),
          // تفاصيل الأسعار
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF16213e).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildPriceRow(
                  'سعر الجملة',
                  '${(item.wholesalePrice ?? 0).toStringAsFixed(0)} د.ع',
                  Icons.store,
                ),
                _buildPriceRow(
                  'سعر العميل',
                  '${item.productPrice.toStringAsFixed(0)} د.ع',
                  Icons.person,
                ),
                _buildPriceRow(
                  'المجموع',
                  '${item.totalPrice.toStringAsFixed(0)} د.ع',
                  Icons.calculate,
                ),
                _buildPriceRow(
                  'الربح',
                  '${((item.profitPerItem ?? 0) * item.quantity).toStringAsFixed(0)} د.ع',
                  Icons.trending_up,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusUpdateDialog() {
    String selectedStatus = _order!.status;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: const Text(
          'تحديث حالة الطلب',
          style: TextStyle(color: Color(0xFFffd700)),
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'اختر الحالة الجديدة:',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),
                ..._getStatusOptions().map((status) {
                  final isSelected = selectedStatus == status['value'];
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
                          color: isSelected
                              ? const Color(0xFFffd700)
                              : Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        setDialogState(() {
                          selectedStatus = status['value'] as String;
                        });
                      },
                      selected: isSelected,
                      selectedTileColor: const Color(
                        0xFFffd700,
                      ).withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateOrderStatus(selectedStatus);
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

  List<Map<String, dynamic>> _getStatusOptions() {
    return [
      {'value': 'pending', 'text': 'في الانتظار', 'color': Colors.orange},
      {'value': 'confirmed', 'text': 'نشط', 'color': Colors.blue},
      {'value': 'processing', 'text': 'قيد التوصيل', 'color': Colors.purple},
      {'value': 'shipped', 'text': 'تم التوصيل', 'color': Colors.green},
      {'value': 'cancelled', 'text': 'ملغي', 'color': Colors.red},
    ];
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    if (newStatus == _order!.status) return;

    setState(() => _isUpdating = true);

    try {
      debugPrint('🔄 تحديث حالة الطلب:');
      debugPrint('   📝 القيمة الجديدة: "$newStatus"');
      debugPrint('   📋 الحالة الحالية: "${_order!.status}"');

      // استخدام القيمة مباشرة لأن AdminService.updateOrderStatus يتوقع قيمة قاعدة البيانات
      await AdminService.updateOrderStatus(_order!.id, newStatus);
      await _loadOrderDetails();
      _showSuccessSnackBar('تم تحديث حالة الطلب بنجاح');
    } catch (e) {
      _showErrorSnackBar('خطأ في تحديث حالة الطلب: $e');
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

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
    if (!_productPriceControllers.containsKey(item.id)) {
      _productPriceControllers[item.id] = TextEditingController(
        text: item.productPrice.toStringAsFixed(0),
      );
    }

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

  Future<void> _updateOrderPrices(
    double totalAmount,
    double deliveryCost,
  ) async {
    try {
      // حساب الربح الجديد
      double totalCost = 0;
      for (var item in _order!.items) {
        final newPrice =
            double.tryParse(_productPriceControllers[item.id]?.text ?? '0') ??
            item.productPrice;
        totalCost += (item.wholesalePrice ?? 0) * item.quantity;

        // تحديث سعر المنتج إذا تغير
        if (newPrice != item.productPrice) {
          final newTotalPrice = newPrice * item.quantity;
          final newProfitPerItem = newPrice - (item.wholesalePrice ?? 0);

          await AdminService.updateProductPrice(
            _order!.id,
            item.id,
            newPrice,
            newTotalPrice,
            newProfitPerItem,
          );
        }
      }

      final newProfit = totalAmount - totalCost - deliveryCost;

      // تحديث معلومات الطلب
      await AdminService.updateOrderInfo(
        _order!.id,
        totalAmount,
        deliveryCost,
        newProfit,
      );

      await _loadOrderDetails();
      _showSuccessSnackBar('تم تحديث الأسعار بنجاح');
    } catch (e) {
      _showErrorSnackBar('خطأ في تحديث الأسعار: $e');
    }
  }

  void _showEditProductPriceDialog(AdminOrderItem item) {
    final priceController = TextEditingController(
      text: item.productPrice.toStringAsFixed(0),
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

  Future<void> _updateSingleProductPrice(
    AdminOrderItem item,
    double newPrice,
    int newQuantity,
  ) async {
    try {
      final newTotalPrice = newPrice * newQuantity;
      final newProfitPerItem = newPrice - (item.wholesalePrice ?? 0);

      await AdminService.updateProductPrice(
        _order!.id,
        item.id,
        newPrice,
        newTotalPrice,
        newProfitPerItem,
        newQuantity: newQuantity, // تمرير الكمية الجديدة
      );

      await _loadOrderDetails();
      _showSuccessSnackBar('تم تحديث المنتج بنجاح');
    } catch (e) {
      _showErrorSnackBar('خطأ في تحديث المنتج: $e');
    }
  }

  Widget _buildStatusHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF16213e),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const Icon(Icons.history, color: Color(0xFFffd700), size: 24),
                const SizedBox(width: 12),
                const Text(
                  'سجل تغييرات الحالة',
                  style: TextStyle(
                    color: Color(0xFFffd700),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '(${_statusHistory.length})',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
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

  Widget _buildStatusHistoryItem(StatusHistory history) {
    final statusColor = OrderStatusHelper.getStatusColor(history.status);
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
                  history.statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (history.notes != null && history.notes!.isNotEmpty)
                  Text(
                    history.notes!,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('yyyy/MM/dd HH:mm').format(history.createdAt),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF16213e),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Row(
              children: [
                Icon(Icons.settings, color: Color(0xFFffd700), size: 24),
                SizedBox(width: 12),
                Text(
                  'الإجراءات السريعة',
                  style: TextStyle(
                    color: Color(0xFFffd700),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            'إرسال رسالة',
            Icons.message,
            Colors.green,
            _sendMessage,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'طباعة الطلب',
            Icons.print,
            Colors.blue,
            _printOrder,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'مشاركة الطلب',
            Icons.share,
            Colors.purple,
            _shareOrder,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'تصدير PDF',
            Icons.picture_as_pdf,
            Colors.red,
            _exportToPDF,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF16213e),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: Color(0xFFffd700),
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'إجراءات متقدمة',
                  style: TextStyle(
                    color: Color(0xFFffd700),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            'تعديل معلومات العميل',
            Icons.person_outline,
            const Color(0xFFffd700),
            _showEditCustomerDialog,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'تعديل الأسعار',
            Icons.attach_money,
            const Color(0xFFffd700),
            _showEditPricesDialog,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'تغيير حالة الطلب',
            Icons.swap_horiz,
            const Color(0xFFffd700),
            _showStatusUpdateDialog,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'إضافة ملاحظة',
            Icons.note_add,
            Colors.orange,
            _showAddNoteDialog,
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(title, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _sendMessage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: const Text(
          'إرسال رسالة',
          style: TextStyle(color: Color(0xFFffd700)),
        ),
        content: Text(
          'سيتم إرسال رسالة نصية إلى العميل على رقم ${_order?.customerPhone ?? "غير محدد"}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessSnackBar('تم إرسال الرسالة بنجاح');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('إرسال', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _printOrder() {
    _showSuccessSnackBar('تم إرسال الطلب للطباعة');
  }

  void _shareOrder() {
    final orderInfo =
        '''
طلب رقم: ${_order?.orderNumber ?? "غير محدد"}
العميل: ${_order?.customerName ?? "غير محدد"}
المبلغ الإجمالي: ${_order?.totalAmount.toStringAsFixed(0) ?? "0"} د.ع
الحالة: ${OrderStatusHelper.getArabicStatus(_order?.status ?? "")}
    ''';

    _showDialog(
      'مشاركة الطلب',
      'تفاصيل الطلب:\n$orderInfo',
      'مشاركة',
      () => _showSuccessSnackBar('تم نسخ تفاصيل الطلب'),
    );
  }

  void _exportToPDF() {
    _showDialog(
      'تصدير PDF',
      'سيتم تصدير تفاصيل الطلب كملف PDF',
      'تصدير',
      () => _showSuccessSnackBar('تم تصدير الطلب كملف PDF'),
    );
  }

  void _showAddNoteDialog() {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: const Text(
          'إضافة ملاحظة',
          style: TextStyle(color: Color(0xFFffd700)),
        ),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'اكتب ملاحظتك هنا...',
            hintStyle: const TextStyle(color: Colors.white54),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (noteController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                try {
                  await AdminService.addOrderNote(
                    _order!.id,
                    noteController.text.trim(),
                    type: 'admin_note',
                    isInternal: false,
                    createdBy: 'admin',
                  );
                  _showSuccessSnackBar('تم إضافة الملاحظة بنجاح');
                } catch (e) {
                  _showErrorSnackBar('خطأ في إضافة الملاحظة: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('إضافة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDialog(
    String title,
    String content,
    String actionText,
    VoidCallback onAction,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: Text(title, style: const TextStyle(color: Color(0xFFffd700))),
        content: Text(content, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onAction();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFffd700),
            ),
            child: Text(
              actionText,
              style: const TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
