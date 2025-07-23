// ===================================
// مكون معالجة الطلبات
// Order Processing Widget
// ===================================

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderProcessingWidget extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback onProcessed;

  const OrderProcessingWidget({
    Key? key,
    required this.order,
    required this.onProcessed,
  }) : super(key: key);

  @override
  _OrderProcessingWidgetState createState() => _OrderProcessingWidgetState();
}

class _OrderProcessingWidgetState extends State<OrderProcessingWidget> {
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  // الحالات التي تحتاج معالجة
  final Map<int, String> statusesNeedProcessing = {
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

  bool get needsProcessing {
    final statusId = widget.order['status_id'];
    return statusesNeedProcessing.containsKey(statusId) && 
           !(widget.order['support_requested'] ?? false);
  }

  @override
  Widget build(BuildContext context) {
    if (!needsProcessing) {
      return Container(); // لا يظهر شيء إذا لم يحتج معالجة
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade600,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'هذا الطلب يحتاج معالجة',
              style: TextStyle(
                color: Colors.orange.shade800,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _showProcessingDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'معالجة',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showProcessingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.support_agent,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'إرسال للدعم',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // معلومات الطلب
                    _buildOrderInfo(),
                    const SizedBox(height: 16),
                    
                    // حقل الملاحظات
                    const Text(
                      'ملاحظات إضافية:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'اكتب أي ملاحظات إضافية هنا...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendSupportRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('إرسال للدعم'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildOrderInfo() {
    final statusId = widget.order['status_id'];
    final statusName = statusesNeedProcessing[statusId] ?? 'غير محدد';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📋 معلومات الطلب:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('🆔', 'رقم الطلب', '#${widget.order['id']}'),
          _buildInfoRow('👤', 'اسم الزبون', widget.order['customer_name'] ?? ''),
          _buildInfoRow('📞', 'الهاتف الأساسي', widget.order['customer_phone'] ?? ''),
          if (widget.order['alternative_phone'] != null && widget.order['alternative_phone'].isNotEmpty)
            _buildInfoRow('📱', 'الهاتف البديل', widget.order['alternative_phone']),
          _buildInfoRow('🏛️', 'المحافظة', widget.order['governorate'] ?? ''),
          _buildInfoRow('🏠', 'العنوان', widget.order['customer_address'] ?? ''),
          _buildInfoRow('⚠️', 'حالة الطلب', statusName),
          _buildInfoRow('📅', 'تاريخ الطلب', _formatDate(widget.order['created_at'])),
        ],
      ),
    );
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

  Widget _buildInfoRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$emoji ',
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSupportRequest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final statusId = widget.order['status_id'];
      final statusName = statusesNeedProcessing[statusId] ?? 'غير محدد';

      final response = await http.post(
        Uri.parse('${_getBaseUrl()}/api/support/send-support-request'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'orderId': widget.order['id'],
          'customerName': widget.order['customer_name'],
          'primaryPhone': widget.order['customer_phone'],
          'alternativePhone': widget.order['alternative_phone'],
          'governorate': widget.order['governorate'],
          'address': widget.order['customer_address'],
          'orderStatus': statusName,
          'notes': _notesController.text.trim(),
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        // التحقق من أن الويدجت لا يزال مُحمّل
        if (!mounted) return;

        // إغلاق النافذة
        Navigator.of(context).pop();

        // إظهار رسالة نجاح
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('تم إرسال الطلب للدعم بنجاح'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 3),
          ),
        );

        // تحديث حالة الطلب
        widget.onProcessed();

      } else {
        throw Exception(responseData['message'] ?? 'فشل في إرسال الطلب');
      }

    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('خطأ: ${error.toString()}'),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getBaseUrl() {
    // يجب تحديث هذا الرابط ليطابق رابط الخادم الحقيقي
    return 'https://montajati-backend.onrender.com';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
