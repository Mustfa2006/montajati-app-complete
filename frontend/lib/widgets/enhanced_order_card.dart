// ===================================
// بطاقة الطلب المحسنة مع نظام المعالجة
// Enhanced Order Card with Processing System
// ===================================

import 'package:flutter/material.dart';
import 'order_processing_widget.dart';

class EnhancedOrderCard extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback? onTap;
  final VoidCallback? onRefresh;

  const EnhancedOrderCard({
    Key? key,
    required this.order,
    this.onTap,
    this.onRefresh,
  }) : super(key: key);

  @override
  _EnhancedOrderCardState createState() => _EnhancedOrderCardState();
}

class _EnhancedOrderCardState extends State<EnhancedOrderCard> {
  late Map<String, dynamic> _order;

  @override
  void initState() {
    super.initState();
    _order = Map<String, dynamic>.from(widget.order);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // رأس البطاقة
              _buildCardHeader(),
              
              const SizedBox(height: 12),
              
              // معلومات الزبون
              _buildCustomerInfo(),
              
              const SizedBox(height: 12),
              
              // شريط السعر والتاريخ مع زر المعالجة
              _buildPriceAndDateBar(),
              
              // مكون المعالجة (يظهر فقط للطلبات التي تحتاج معالجة)
              OrderProcessingWidget(
                order: _order,
                onProcessed: _onOrderProcessed,
              ),
              
              const SizedBox(height: 8),
              
              // معلومات إضافية
              _buildAdditionalInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader() {
    return Row(
      children: [
        // رقم الطلب
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'طلب #${_order['id']}',
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        
        const Spacer(),
        
        // حالة الطلب
        _buildStatusChip(),
      ],
    );
  }

  Widget _buildStatusChip() {
    final statusName = _getStatusName();
    final isProcessed = _order['support_requested'] ?? false;
    
    Color backgroundColor;
    Color textColor;
    IconData icon;
    
    if (isProcessed) {
      backgroundColor = Colors.green.shade100;
      textColor = Colors.green.shade800;
      icon = Icons.check_circle;
    } else if (_needsProcessing()) {
      backgroundColor = Colors.orange.shade100;
      textColor = Colors.orange.shade800;
      icon = Icons.warning_amber;
    } else {
      backgroundColor = Colors.grey.shade100;
      textColor = Colors.grey.shade800;
      icon = Icons.info;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            isProcessed ? 'تم المعالجة' : statusName,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // اسم الزبون
        Row(
          children: [
            Icon(Icons.person, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _order['customer_name'] ?? 'غير محدد',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 4),
        
        // رقم الهاتف
        Row(
          children: [
            Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              _order['customer_phone'] ?? 'غير محدد',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 4),
        
        // العنوان
        Row(
          children: [
            Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${_order['governorate'] ?? ''} - ${_order['customer_address'] ?? ''}',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceAndDateBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // السعر
          Icon(Icons.attach_money, size: 16, color: Colors.green.shade600),
          const SizedBox(width: 4),
          Text(
            '${_order['total_price'] ?? 0} د.ع',
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          
          const Spacer(),
          
          // التاريخ
          Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            _formatDate(_order['created_at']),
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return Row(
      children: [
        // عدد المنتجات
        if (_order['products_count'] != null) ...[
          Icon(Icons.inventory, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            '${_order['products_count']} منتج',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 16),
        ],
        
        // وقت الإنشاء
        Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          _formatTime(_order['created_at']),
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11,
          ),
        ),
        
        const Spacer(),
        
        // مؤشر المعالجة
        if (_order['support_requested'] ?? false)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'تم المعالجة',
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  String _getStatusName() {
    final statusId = _order['status_id'];
    
    // قائمة الحالات
    final statusMap = {
      25: "لا يرد",
      26: "لا يرد بعد الاتفاق",
      27: "مغلق",
      28: "مغلق بعد الاتفاق",
      36: "الرقم غير معرف",
      37: "الرقم غير داخل في الخدمة",
      41: "لا يمكن الاتصال بالرقم",
      29: "مؤجل",
      30: "مؤجل لحين اعادة الطلب لاحقا",
      33: "مفصول عن الخدمة",
      34: "طلب مكرر",
      35: "مستلم مسبقا",
      38: "العنوان غير دقيق",
      39: "لم يطلب",
      40: "حظر المندوب",
    };
    
    return statusMap[statusId] ?? _order['status_name'] ?? 'غير محدد';
  }

  bool _needsProcessing() {
    final statusId = _order['status_id'];
    final statusesNeedProcessing = [25, 26, 27, 28, 36, 37, 41, 29, 30, 33, 34, 35, 38, 39, 40];
    return statusesNeedProcessing.contains(statusId) && !(_order['support_requested'] ?? false);
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'غير محدد';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'غير محدد';
    }
  }

  String _formatTime(String? dateString) {
    if (dateString == null) return 'غير محدد';
    try {
      final date = DateTime.parse(dateString);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'غير محدد';
    }
  }

  void _onOrderProcessed() {
    setState(() {
      _order['support_requested'] = true;
      _order['support_requested_at'] = DateTime.now().toIso8601String();
    });
    
    // إشعار الصفحة الأب بالتحديث
    if (widget.onRefresh != null) {
      widget.onRefresh!();
    }
  }
}
