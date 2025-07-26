// ===================================
// مكون معالجة الطلبات
// Order Processing Widget
// ===================================

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

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
    print('🔍 === بدء عملية إرسال طلب الدعم ===');

    setState(() {
      _isLoading = true;
    });

    try {
      print('📋 Step 1: جلب معلومات الطلب...');
      final statusId = widget.order['status_id'];
      final statusName = statusesNeedProcessing[statusId] ?? 'غير محدد';
      print('📋 معرف الحالة: $statusId');
      print('📋 اسم الحالة: $statusName');
      print('📋 معلومات الطلب: ${widget.order}');

      print('📝 Step 2: تحضير رسالة التلغرام...');
      final message = _prepareTelegramMessage(statusName);
      print('📝 طول الرسالة: ${message.length} حرف');
      print('📝 أول 100 حرف من الرسالة: ${message.substring(0, message.length > 100 ? 100 : message.length)}...');

      print('📱 Step 3: محاولة فتح التلغرام...');
      await _sendToTelegramFromUser(message);
      print('✅ تم فتح التلغرام بنجاح');

      print('💾 Step 4: تحديث حالة الطلب في قاعدة البيانات...');
      await _updateOrderSupportStatus();
      print('✅ تم تحديث حالة الطلب بنجاح');

      // التحقق من أن الويدجت لا يزال مُحمّل
      if (!mounted) {
        print('⚠️ الويدجت لم يعد محمل - إيقاف العملية');
        return;
      }

      print('🚪 Step 5: إغلاق النافذة وإظهار رسالة النجاح...');
      // إغلاق النافذة
      Navigator.of(context).pop();

      // إظهار رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.telegram, color: Colors.white),
              const SizedBox(width: 8),
              const Text('تم فتح التلغرام لإرسال الرسالة للدعم'),
            ],
          ),
          backgroundColor: Colors.blue.shade600,
          duration: const Duration(seconds: 3),
        ),
      );

      // تحديث حالة الطلب
      widget.onProcessed();
      print('🎉 === تمت عملية إرسال طلب الدعم بنجاح ===');

    } catch (error, stackTrace) {
      print('❌ === خطأ في عملية إرسال طلب الدعم ===');
      print('❌ نوع الخطأ: ${error.runtimeType}');
      print('❌ رسالة الخطأ: ${error.toString()}');
      print('❌ Stack Trace: $stackTrace');

      if (!mounted) {
        print('⚠️ الويدجت لم يعد محمل - لا يمكن إظهار رسالة الخطأ');
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('خطأ: ${error.toString()}')),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      print('🔄 تنظيف الحالة...');
      setState(() {
        _isLoading = false;
      });
      print('✅ تم تنظيف الحالة');
    }
  }

  String _prepareTelegramMessage(String statusName) {
    print('📝 === تحضير رسالة التلغرام ===');

    try {
      print('📅 معالجة تاريخ الطلب...');
      final orderDate = widget.order['created_at'] != null
          ? DateTime.parse(widget.order['created_at']).toLocal().toString().split(' ')[0]
          : 'غير محدد';
      print('📅 تاريخ الطلب: $orderDate');

      print('📝 بناء الرسالة...');
      final message = '''🚨 طلب دعم جديد - منتجاتي 🚨

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

👤 معلومات الزبون:
📝 الاسم: ${widget.order['customer_name'] ?? 'غير محدد'}
📞 الهاتف الأساسي: ${widget.order['customer_phone'] ?? 'غير محدد'}
📱 الهاتف البديل: ${widget.order['alternative_phone'] ?? 'غير متوفر'}

📍 معلومات العنوان:
🏛️ المحافظة: ${widget.order['governorate'] ?? 'غير محدد'}
🏠 العنوان: ${widget.order['customer_address'] ?? 'غير محدد'}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 معلومات الطلب:
🆔 رقم الطلب: ${widget.order['order_number'] ?? widget.order['id']}
📅 تاريخ الطلب: $orderDate
⚠️ حالة الطلب: $statusName

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💬 ملاحظات المستخدم:
${_notesController.text.trim().isNotEmpty ? _notesController.text.trim() : 'لا توجد ملاحظات إضافية'}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚡ يرجى المتابعة مع الزبون في أقرب وقت ممكن ⚡''';

      print('✅ تم بناء الرسالة بنجاح - الطول: ${message.length} حرف');
      return message;

    } catch (error, stackTrace) {
      print('❌ خطأ في تحضير رسالة التلغرام: $error');
      print('❌ Stack Trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _sendToTelegramFromUser(String message) async {
    print('📱 === محاولة فتح التلغرام ===');

    try {
      // رقم أو معرف الدعم في التلغرام
      const supportUsername = 'montajati_support'; // ضع معرف قناة الدعم هنا
      print('📱 معرف الدعم: $supportUsername');

      print('🔗 ترميز الرسالة للـ URL...');
      final encodedMessage = Uri.encodeComponent(message);
      print('🔗 طول الرسالة المرمزة: ${encodedMessage.length} حرف');

      // إنشاء رابط التلغرام
      final telegramUrl = 'https://t.me/$supportUsername?text=$encodedMessage';
      print('🔗 رابط التلغرام: ${telegramUrl.substring(0, telegramUrl.length > 200 ? 200 : telegramUrl.length)}...');

      print('🔍 فحص إمكانية فتح الرابط...');
      final canLaunch = await canLaunchUrl(Uri.parse(telegramUrl));
      print('🔍 هل يمكن فتح الرابط؟ $canLaunch');

      if (canLaunch) {
        print('🚀 محاولة فتح التلغرام...');
        await launchUrl(
          Uri.parse(telegramUrl),
          mode: LaunchMode.externalApplication,
        );
        print('✅ تم فتح التلغرام بنجاح');
      } else {
        print('❌ لا يمكن فتح التلغرام');
        throw Exception('لا يمكن فتح التلغرام. تأكد من تثبيت التطبيق.');
      }
    } catch (e, stackTrace) {
      print('❌ خطأ في فتح التلغرام: $e');
      print('❌ Stack Trace: $stackTrace');
      throw Exception('فشل في فتح التلغرام: $e');
    }
  }

  Future<void> _updateOrderSupportStatus() async {
    print('💾 === تحديث حالة الدعم في قاعدة البيانات ===');

    try {
      final baseUrl = _getBaseUrl();
      final orderId = widget.order['id'];
      final notes = _notesController.text.trim();

      print('💾 الخادم: $baseUrl');
      print('💾 معرف الطلب: $orderId');
      print('💾 الملاحظات: $notes');

      final url = Uri.parse('$baseUrl/api/support/mark-support-sent');
      print('💾 الرابط: $url');

      final requestBody = json.encode({
        'orderId': orderId,
        'notes': notes,
      });
      print('💾 محتوى الطلب: $requestBody');

      print('📡 إرسال الطلب...');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      print('📡 رمز الاستجابة: ${response.statusCode}');
      print('📡 محتوى الاستجابة: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ تم تحديث حالة الدعم بنجاح');
      } else {
        print('⚠️ تحذير: فشل في تحديث حالة الدعم - رمز: ${response.statusCode}');
        print('⚠️ رسالة الخطأ: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('❌ خطأ في تحديث حالة الدعم: $e');
      print('❌ Stack Trace: $stackTrace');
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
