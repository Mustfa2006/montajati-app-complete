import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import '../models/order_item.dart' as OrderItemModel;
import '../widgets/common_header.dart';
// تم إزالة جميع imports الإدارة - المستخدم لا يحتاج لها

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
  // تم إزالة _isAdmin - المستخدم لا يحتاج لصلاحيات الإدارة
  // تم إزالة _isUpdatingStatus - المستخدم لا يمكنه تحديث الحالة

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
    // تم إزالة فحص صلاحيات الإدارة - المستخدم لا يحتاج لها
  }

  Future<void> _loadOrderDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      debugPrint('📥 جلب تفاصيل الطلب: ${widget.orderId}');

      // محاولة جلب من جدول الطلبات العادية أولاً
      dynamic orderResponse;
      bool isScheduledOrder = false;

      try {
        orderResponse = await Supabase.instance.client
            .from('orders')
            .select('*, order_items(*)')
            .eq('id', widget.orderId)
            .single();
      } catch (e) {
        // إذا لم يوجد في الطلبات العادية، جرب الطلبات المجدولة
        debugPrint('🔄 لم يوجد في الطلبات العادية، جرب الطلبات المجدولة...');
        try {
          orderResponse = await Supabase.instance.client
              .from('scheduled_orders')
              .select('*, scheduled_order_items(*)')
              .eq('id', widget.orderId)
              .single();
          isScheduledOrder = true;
        } catch (scheduledError) {
          throw Exception('الطلب غير موجود في الطلبات العادية أو المجدولة');
        }
      }

      debugPrint('✅ تم جلب تفاصيل الطلب: ${orderResponse['id']}');

      // تحويل عناصر الطلب (حسب نوع الطلب)
      final itemsKey = isScheduledOrder
          ? 'scheduled_order_items'
          : 'order_items';
      final orderItems =
          (orderResponse[itemsKey] as List?)?.map((item) {
            if (isScheduledOrder) {
              // للطلبات المجدولة - استخدام أسماء الأعمدة الصحيحة
              return OrderItemModel.OrderItem(
                id: item['id']?.toString() ?? '',
                productId:
                    item['product_id']?.toString() ??
                    item['id']?.toString() ??
                    '',
                name: item['product_name'] ?? '',
                image:
                    item['product_image'] ??
                    '', // ✅ استخدام صورة المنتج من قاعدة البيانات
                wholesalePrice: double.tryParse(item['price']?.toString() ?? '0') ?? 0.0,
                customerPrice: double.tryParse(item['price']?.toString() ?? '0') ?? 0.0,
                quantity: item['quantity'] ?? 1,
              );
            } else {
              // للطلبات العادية
              return OrderItemModel.OrderItem(
                id: item['id']?.toString() ?? '',
                productId: item['product_id'] ?? '',
                name: item['product_name'] ?? '',
                image: item['product_image'] ?? '',
                wholesalePrice: double.tryParse(item['wholesale_price']?.toString() ?? '0') ?? 0.0,
                customerPrice: double.tryParse(item['customer_price']?.toString() ?? '0') ?? 0.0,
                quantity: item['quantity'] ?? 1,
              );
            }
          }).toList() ??
          <OrderItemModel.OrderItem>[];

      // إنشاء كائن الطلب مع أسماء الأعمدة الصحيحة
      final order = Order(
        id: orderResponse['id'],
        customerName: orderResponse['customer_name'] ?? '',
        primaryPhone: isScheduledOrder
            ? (orderResponse['customer_phone'] ?? '')
            : (orderResponse['primary_phone'] ?? ''),
        secondaryPhone: isScheduledOrder
            ? (orderResponse['customer_alternate_phone'])
            : (orderResponse['secondary_phone']),
        province: isScheduledOrder
            ? (orderResponse['customer_province'] ?? 'غير محدد')
            : (orderResponse['province'] ?? 'غير محدد'),
        city: isScheduledOrder
            ? (orderResponse['customer_city'] ?? 'غير محدد')
            : (orderResponse['city'] ?? 'غير محدد'),
        notes: orderResponse['notes'],
        totalCost: isScheduledOrder
            ? (double.tryParse(
                    orderResponse['total_amount']?.toString() ?? '0',
                  ) ??
                  0).toInt()
            : (orderResponse['total'] ?? 0),
        subtotal: isScheduledOrder
            ? (double.tryParse(
                    orderResponse['total_amount']?.toString() ?? '0',
                  ) ??
                  0).toInt()
            : (orderResponse['subtotal'] ?? 0),
        total: isScheduledOrder
            ? (double.tryParse(
                    orderResponse['total_amount']?.toString() ?? '0',
                  ) ??
                  0).toInt()
            : (orderResponse['total'] ?? 0),
        totalProfit: isScheduledOrder
            ? (double.tryParse(
                    orderResponse['profit_amount']?.toString() ?? '0',
                  ) ??
                  0).toInt()
            : (orderResponse['profit'] ?? 0),
        status: _parseOrderStatus(orderResponse['status'] ?? 'pending'),
        createdAt: DateTime.parse(orderResponse['created_at']),
        items: orderItems,
        // إضافة معلومات الجدولة إذا كان طلب مجدول
        scheduledDate: isScheduledOrder
            ? DateTime.tryParse(orderResponse['scheduled_date'] ?? '')
            : null,
        scheduleNotes: isScheduledOrder ? orderResponse['notes'] : null,
      );

      setState(() {
        _order = order;
        _isLoading = false;
      });

      debugPrint('✅ تم تحميل تفاصيل الطلب بنجاح: ${order.id}');
      debugPrint('📋 اسم العميل: ${order.customerName}');
      debugPrint('📞 رقم الهاتف: ${order.primaryPhone}');
      debugPrint('💰 المجموع: ${order.total}');
      debugPrint('🧮 المجموع الفرعي من قاعدة البيانات: ${order.subtotal} د.ع');
      debugPrint('🧮 المجموع الكلي من قاعدة البيانات: ${order.total} د.ع');
      debugPrint('🧮 إجمالي الربح من قاعدة البيانات: ${order.totalProfit} د.ع');
    } catch (e) {
      debugPrint('❌ خطأ في جلب تفاصيل الطلب: $e');
      setState(() {
        _error = 'خطأ في جلب تفاصيل الطلب: $e';
        _isLoading = false;
      });
    }
  }

  OrderStatus _parseOrderStatus(String? status) {
    switch (status) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'in_delivery':
        return OrderStatus.inDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  // 🧮 حساب المجموع الفرعي من قاعدة البيانات
  double _calculateSubtotal() {
    if (_order == null) return 0.0;

    // استخدام القيمة المحفوظة في قاعدة البيانات
    double subtotal = _order!.subtotal.toDouble();

    debugPrint('🧮 المجموع الفرعي من قاعدة البيانات: $subtotal د.ع');
    return subtotal;
  }

  // 🧮 حساب المجموع الكلي من قاعدة البيانات
  double _calculateTotal() {
    if (_order == null) return 0.0;

    // استخدام القيمة المحفوظة في قاعدة البيانات
    double total = _order!.total.toDouble();

    debugPrint('🧮 المجموع الكلي من قاعدة البيانات: $total د.ع');
    return total;
  }

  // 🧮 حساب إجمالي الربح من قاعدة البيانات
  double _calculateTotalProfit() {
    if (_order == null) return 0.0;

    // استخدام القيمة المحفوظة في قاعدة البيانات
    double totalProfit = _order!.totalProfit.toDouble();

    debugPrint('🧮 إجمالي الربح من قاعدة البيانات: $totalProfit د.ع');
    return totalProfit;
  }

  // 🔍 التحقق من كون الطلب نشط
  bool _isOrderActive() {
    return _order?.status == OrderStatus.pending ||
        _order?.status == OrderStatus.confirmed;
  }

  // ✏️ تعديل الطلب
  void _editOrder() {
    if (_order == null) return;

    // التحقق من إمكانية التعديل
    if (!_isOrderActive()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا يمكن تعديل الطلبات غير النشطة',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // التحقق من الوقت المتبقي (24 ساعة)
    final now = DateTime.now();
    final deadline = _order!.createdAt.add(const Duration(hours: 24));
    if (now.isAfter(deadline)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'انتهت فترة التعديل المسموحة (24 ساعة)',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // الانتقال لصفحة التعديل
    context.go('/orders/edit/${_order!.id}');
  }

  // 🗑️ حذف الطلب
  void _deleteOrder() {
    if (_order == null) return;

    // إظهار رسالة تأكيد
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Text('حذف الطلب', style: GoogleFonts.cairo(color: Colors.red)),
        content: Text(
          'هل أنت متأكد من حذف هذا الطلب؟\nلا يمكن التراجع عن هذا الإجراء.',
          style: GoogleFonts.cairo(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirmDeleteOrder();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('حذف', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 🗑️ تأكيد حذف الطلب
  Future<void> _confirmDeleteOrder() async {
    try {
      // حذف الطلب من قاعدة البيانات
      await Supabase.instance.client
          .from('orders')
          .delete()
          .eq('id', _order!.id);

      // إظهار رسالة نجاح
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف الطلب بنجاح', style: GoogleFonts.cairo()),
            backgroundColor: Colors.green,
          ),
        );

        // العودة لصفحة الطلبات
        context.go('/orders');
      }
    } catch (e) {
      // إظهار رسالة خطأ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حذف الطلب: $e', style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                onTap: () => context.go('/orders'),
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
            leftActions: [
              // أزرار التعديل والحذف (فقط للطلبات النشطة)
              if (_order != null && _isOrderActive()) ...[
                // زر التعديل
                GestureDetector(
                  onTap: _editOrder,
                  child: Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(left: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      FontAwesomeIcons.penToSquare,
                      color: Colors.blue,
                      size: 16,
                    ),
                  ),
                ),
                // زر الحذف
                GestureDetector(
                  onTap: _deleteOrder,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      FontAwesomeIcons.trash,
                      color: Colors.red,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _error != null
                ? _buildErrorState()
                : _buildOrderContent(),
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
          CircularProgressIndicator(color: Color(0xFFffd700)),
          SizedBox(height: 20),
          Text(
            'جاري تحميل تفاصيل الطلب...',
            style: TextStyle(color: Colors.white),
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
          const FaIcon(
            FontAwesomeIcons.triangleExclamation,
            color: Colors.red,
            size: 60,
          ),
          const SizedBox(height: 20),
          Text(
            _error!,
            style: GoogleFonts.cairo(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go('/orders'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFffd700),
              foregroundColor: const Color(0xFF1a1a2e),
            ),
            child: Text(
              'العودة للطلبات',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderContent() {
    if (_order == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: 100, // مساحة للشريط السفلي
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderStatusCard(),
          const SizedBox(height: 20),
          _buildScheduleInfoCard(),
          _buildCustomerInfoCard(),
          const SizedBox(height: 20),
          _buildOrderItemsCard(),
          const SizedBox(height: 20),
          _buildOrderSummaryCard(),
        ],
      ),
    );
  }

  Widget _buildOrderStatusCard() {
    // ✅ استخدام rawStatus للحصول على الحالة الصحيحة من قاعدة البيانات
    String actualStatus = _order!.rawStatus.isNotEmpty ? _order!.rawStatus : 'نشط';
    Color statusColor = _getStatusColorFromRaw(actualStatus);
    String statusText = _getStatusTextFromRaw(actualStatus);
    IconData statusIcon = _getStatusIconFromRaw(actualStatus);

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
            child: FaIcon(statusIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حالة الطلب',
                  style: GoogleFonts.cairo(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                Text(
                  statusText,
                  style: GoogleFonts.cairo(
                    color: statusColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(_order!.createdAt),
            style: GoogleFonts.cairo(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          // تم إزالة زر تحديث الحالة - المستخدم لا يمكنه تغيير حالة الطلب
        ],
      ),
    );
  }

  Widget _buildScheduleInfoCard() {
    if (_order?.scheduledDate == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFF9c27b0).withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9c27b0).withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.calendar,
                color: Color(0xFF9c27b0),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'طلب مجدول',
                style: GoogleFonts.cairo(
                  color: const Color(0xFF9c27b0),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildInfoRow(
            'تاريخ الجدولة',
            DateFormat('yyyy/MM/dd', 'ar').format(_order!.scheduledDate!),
          ),
          if (_order!.scheduleNotes != null &&
              _order!.scheduleNotes!.isNotEmpty)
            _buildInfoRow('ملاحظات الجدولة', _order!.scheduleNotes!),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
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
              const FaIcon(
                FontAwesomeIcons.user,
                color: Color(0xFFffd700),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'معلومات العميل',
                style: GoogleFonts.cairo(
                  color: const Color(0xFFffd700),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildInfoRow('الاسم', _order!.customerName),
          _buildInfoRow('الهاتف الأساسي', _order!.primaryPhone),
          if (_order!.secondaryPhone != null)
            _buildInfoRow('الهاتف الثانوي', _order!.secondaryPhone!),
          _buildInfoRow('المحافظة', _order!.province),
          _buildInfoRow('المدينة', _order!.city),
          if (_order!.notes != null && _order!.notes!.isNotEmpty)
            _buildInfoRow('ملاحظات', _order!.notes!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110, // ✅ زيادة العرض لمنع الكسرة
            child: Text(
              '$label:',
              style: GoogleFonts.cairo(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
              softWrap: false, // ✅ منع الكسرة
              overflow: TextOverflow.visible, // ✅ إظهار النص كاملاً
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.bagShopping,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'عناصر الطلب (${_order!.items.length})',
                style: GoogleFonts.cairo(
                  color: Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ...(_order!.items.map((item) => _buildOrderItem(item)).toList()),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItemModel.OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
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
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFffd700),
                            strokeWidth: 2,
                          ),
                        );
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
                              Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                                size: 20,
                              ),
                              Text(
                                'لا توجد صورة',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 8,
                                ),
                              ),
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
                        Text(
                          'لا توجد صورة',
                          style: TextStyle(color: Colors.grey, fontSize: 8),
                        ),
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
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'الكمية: ${item.quantity}',
                  style: GoogleFonts.cairo(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                Text(
                  'السعر: ${_getItemPrice(item).toStringAsFixed(0)} د.ع',
                  style: GoogleFonts.cairo(
                    color: const Color(0xFFffd700),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // المجموع
          Text(
            '${_getItemTotal(item).toStringAsFixed(0)} د.ع',
            style: GoogleFonts.cairo(
              color: Colors.green,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e), // خلفية داكنة
        border: Border.all(
          color: const Color(0xFFffd700), // إطار ذهبي فقط
          width: 2,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFffd700).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ملخص الطلب',
            style: GoogleFonts.cairo(
              color: const Color(0xFFffd700), // لون ذهبي للنص
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          _buildSummaryRow(
            'المجموع الفرعي',
            '${_calculateSubtotal().toStringAsFixed(0)} د.ع',
          ),
          const Divider(color: Color(0xFF3a3a5c), thickness: 1),
          _buildSummaryRow(
            'المجموع الكلي',
            '${_calculateTotal().toStringAsFixed(0)} د.ع',
            isTotal: true,
          ),
          const SizedBox(height: 10),
          _buildSummaryRow(
            'إجمالي الربح',
            '${_calculateTotalProfit().toStringAsFixed(0)} د.ع',
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(
              color: Colors.white, // تغيير لون النص للخلفية الداكنة
              fontSize: isTotal || isProfit ? 16 : 14,
              fontWeight: isTotal || isProfit
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.cairo(
              color: isDiscount
                  ? Colors.red
                  : isProfit
                  ? Colors
                        .green // لون أخضر للربح
                  : isTotal
                  ? const Color(0xFFffd700) // لون ذهبي للمجموع الكلي
                  : Colors.white, // لون أبيض للباقي
              fontSize: isTotal || isProfit ? 16 : 14,
              fontWeight: isTotal || isProfit
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ دوال جديدة للتعامل مع الحالة الخام من قاعدة البيانات
  Color _getStatusColorFromRaw(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'confirmed':
      case 'نشط':
      case 'مؤكد':
      case 'فعال':
        return const Color(0xFFffd700); // أصفر ذهبي
      case 'in_delivery':
      case 'processing':
      case 'قيد التوصيل':
      case 'في الطريق':
      case 'قيد التوصيل الى الزبون (في عهدة المندوب)':
        return const Color(0xFF17a2b8); // سماوي
      case 'delivered':
      case 'shipped':
      case 'تم التسليم للزبون':
      case 'تم التسليم':
      case 'مكتمل':
        return const Color(0xFF28a745); // أخضر
      case 'cancelled':
      case 'rejected':
      case 'الغاء الطلب':
      case 'ملغي':
      case 'رفض الطلب':
      case 'الرقم غير معرف':
      case 'لا يرد':
      case 'مؤجل':
        return const Color(0xFFdc3545); // أحمر
      case 'pending':
      case 'في الانتظار':
        return const Color(0xFF6c757d); // رمادي
      default:
        return const Color(0xFFffd700); // أصفر ذهبي كافتراضي
    }
  }

  String _getStatusTextFromRaw(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'confirmed':
      case 'نشط':
      case 'مؤكد':
      case 'فعال':
        return 'نشط';
      case 'in_delivery':
      case 'processing':
      case 'قيد التوصيل':
      case 'في الطريق':
        return 'قيد التوصيل';
      case 'قيد التوصيل الى الزبون (في عهدة المندوب)':
        return 'قيد التوصيل للزبون';
      case 'delivered':
      case 'shipped':
      case 'تم التسليم للزبون':
      case 'تم التسليم':
      case 'مكتمل':
        return 'مكتمل';
      case 'cancelled':
      case 'rejected':
      case 'الغاء الطلب':
      case 'ملغي':
      case 'رفض الطلب':
      case 'الرقم غير معرف':
      case 'لا يرد':
      case 'مؤجل':
        return 'ملغي';
      case 'pending':
      case 'في الانتظار':
        return 'في الانتظار';
      default:
        return status.isNotEmpty ? status : 'غير محدد';
    }
  }

  IconData _getStatusIconFromRaw(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'confirmed':
      case 'نشط':
      case 'مؤكد':
      case 'فعال':
        return Icons.check_circle;
      case 'in_delivery':
      case 'processing':
      case 'قيد التوصيل':
      case 'في الطريق':
      case 'قيد التوصيل الى الزبون (في عهدة المندوب)':
        return Icons.local_shipping;
      case 'delivered':
      case 'shipped':
      case 'تم التسليم للزبون':
      case 'تم التسليم':
      case 'مكتمل':
        return Icons.done_all;
      case 'cancelled':
      case 'rejected':
      case 'الغاء الطلب':
      case 'ملغي':
      case 'رفض الطلب':
      case 'الرقم غير معرف':
      case 'لا يرد':
      case 'مؤجل':
        return Icons.cancel;
      case 'pending':
      case 'في الانتظار':
        return Icons.hourglass_empty;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFFffd700); // أصفر ذهبي
      case OrderStatus.confirmed:
        return const Color(0xFFffd700); // أصفر ذهبي
      case OrderStatus.inDelivery:
        return const Color(0xFF17a2b8); // سماوي
      case OrderStatus.delivered:
        return const Color(0xFF28a745); // أخضر
      case OrderStatus.cancelled:
        return const Color(0xFFdc3545); // أحمر
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'نشط';
      case OrderStatus.confirmed:
        return 'نشط';
      case OrderStatus.inDelivery:
        return 'قيد التوصيل';
      case OrderStatus.delivered:
        return 'تم التسليم';
      case OrderStatus.cancelled:
        return 'ملغي';
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return FontAwesomeIcons.clock;
      case OrderStatus.confirmed:
        return FontAwesomeIcons.circleCheck;
      case OrderStatus.inDelivery:
        return FontAwesomeIcons.truck;
      case OrderStatus.delivered:
        return FontAwesomeIcons.checkDouble;
      case OrderStatus.cancelled:
        return FontAwesomeIcons.xmark;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  // 🧮 دوال مساعدة للحصول على أسعار العناصر
  double _getItemPrice(OrderItemModel.OrderItem item) {
    // إذا كان سعر العميل 0، استخدم سعر الجملة كبديل
    if (item.customerPrice > 0) {
      return item.customerPrice.toDouble();
    } else if (item.wholesalePrice > 0) {
      return item.wholesalePrice.toDouble();
    } else {
      return 0.0;
    }
  }

  double _getItemTotal(OrderItemModel.OrderItem item) {
    // إذا كان total_price محفوظ في قاعدة البيانات، استخدمه
    // وإلا احسب من السعر والكمية
    double price = _getItemPrice(item);
    return price * item.quantity;
  }

  bool _hasValidImage(OrderItemModel.OrderItem item) {
    return item.image.isNotEmpty &&
        item.image != 'null' &&
        item.image.startsWith('http');
  }

  // تم إزالة جميع دوال تحديث الحالة والدوال المساعدة
  // المستخدم لا يمكنه تغيير حالة الطلب - فقط الإدارة من لوحة التحكم
}
