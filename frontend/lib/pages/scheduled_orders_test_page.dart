import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/scheduled_orders_service.dart';
import '../models/scheduled_order.dart';

class ScheduledOrdersTestPage extends StatefulWidget {
  const ScheduledOrdersTestPage({super.key});

  @override
  State<ScheduledOrdersTestPage> createState() => _ScheduledOrdersTestPageState();
}

class _ScheduledOrdersTestPageState extends State<ScheduledOrdersTestPage> {
  final ScheduledOrdersService _service = ScheduledOrdersService();
  bool _isLoading = false;
  String _testResults = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFffd700)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'اختبار نظام الطلبات المجدولة',
          style: TextStyle(
            color: Color(0xFFffd700),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // شرح النظام
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16213e),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFffd700).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔄 نظام التحويل التلقائي',
                    style: TextStyle(
                      color: Color(0xFFffd700),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'يقوم النظام بتحويل الطلبات المجدولة إلى طلبات نشطة تلقائياً قبل يوم واحد من التاريخ المجدول.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'مثال: طلب مجدول لتاريخ 20/6/2025 سيتم تحويله تلقائياً في 19/6/2025 منتصف الليل.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // أزرار الاختبار
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildTestButton(
                  'إنشاء طلب مجدول لغداً',
                  Icons.add_alarm,
                  () => _createTestOrderForTomorrow(),
                ),
                _buildTestButton(
                  'إنشاء طلب مجدول لاليوم',
                  Icons.today,
                  () => _createTestOrderForToday(),
                ),
                _buildTestButton(
                  'إنشاء طلب مجدول متأخر',
                  Icons.warning,
                  () => _createOverdueTestOrder(),
                ),
                _buildTestButton(
                  'تشغيل التحويل التلقائي',
                  Icons.autorenew,
                  () => _runAutoConversion(),
                ),
                _buildTestButton(
                  'عرض جميع الطلبات المجدولة',
                  Icons.list,
                  () => _loadAndDisplayOrders(),
                ),
                _buildTestButton(
                  'مسح جميع الطلبات التجريبية',
                  Icons.clear_all,
                  () => _clearTestOrders(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // نتائج الاختبار
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213e),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFffd700).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 نتائج الاختبار',
                      style: TextStyle(
                        color: Color(0xFFffd700),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFffd700),
                                  ),
                                ),
                              )
                            : Text(
                                _testResults.isEmpty
                                    ? 'اضغط على أحد الأزرار لبدء الاختبار...'
                                    : _testResults,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFffd700),
        foregroundColor: const Color(0xFF1a1a2e),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Future<void> _createTestOrderForTomorrow() async {
    setState(() {
      _isLoading = true;
      _testResults = '🔄 إنشاء طلب مجدول لغداً...\n';
    });

    try {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final result = await _service.addScheduledOrder(
        customerName: 'عميل تجريبي - غداً',
        customerPhone: '07701234567',
        customerAddress: 'بغداد - منطقة تجريبية',
        totalAmount: 50000.0,
        scheduledDate: tomorrow,
        items: [
          ScheduledOrderItem(
            name: 'منتج تجريبي',
            quantity: 1,
            price: 50000.0,
            notes: 'طلب تجريبي لاختبار التحويل التلقائي',
          ),
        ],
        notes: 'طلب تجريبي مجدول لغداً - سيتم تحويله تلقائياً اليوم',
        priority: 'عالية',
      );

      setState(() {
        _testResults += result['success']
            ? '✅ تم إنشاء الطلب بنجاح: ${result['orderNumber']}\n'
                '📅 مجدول لتاريخ: ${DateFormat('yyyy/MM/dd').format(tomorrow)}\n'
                '🔄 سيتم تحويله تلقائياً اليوم\n\n'
            : '❌ فشل في إنشاء الطلب: ${result['message']}\n\n';
      });
    } catch (e) {
      setState(() {
        _testResults += '❌ خطأ: $e\n\n';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createTestOrderForToday() async {
    setState(() {
      _isLoading = true;
      _testResults += '🔄 إنشاء طلب مجدول لاليوم...\n';
    });

    try {
      final today = DateTime.now();
      final result = await _service.addScheduledOrder(
        customerName: 'عميل تجريبي - اليوم',
        customerPhone: '07801234567',
        customerAddress: 'البصرة - منطقة تجريبية',
        totalAmount: 30000.0,
        scheduledDate: today,
        items: [
          ScheduledOrderItem(
            name: 'منتج عاجل',
            quantity: 2,
            price: 15000.0,
            notes: 'طلب عاجل لاليوم',
          ),
        ],
        notes: 'طلب تجريبي مجدول لاليوم - يجب تحويله فوراً',
        priority: 'عالية',
      );

      setState(() {
        _testResults += result['success']
            ? '✅ تم إنشاء الطلب بنجاح: ${result['orderNumber']}\n'
                '📅 مجدول لتاريخ: ${DateFormat('yyyy/MM/dd').format(today)}\n'
                '🔄 يجب تحويله فوراً\n\n'
            : '❌ فشل في إنشاء الطلب: ${result['message']}\n\n';
      });
    } catch (e) {
      setState(() {
        _testResults += '❌ خطأ: $e\n\n';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createOverdueTestOrder() async {
    setState(() {
      _isLoading = true;
      _testResults += '🔄 إنشاء طلب مجدول متأخر...\n';
    });

    try {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final result = await _service.addScheduledOrder(
        customerName: 'عميل تجريبي - متأخر',
        customerPhone: '07901234567',
        customerAddress: 'أربيل - منطقة تجريبية',
        totalAmount: 75000.0,
        scheduledDate: yesterday,
        items: [
          ScheduledOrderItem(
            name: 'منتج متأخر',
            quantity: 1,
            price: 75000.0,
            notes: 'طلب متأخر يحتاج معالجة فورية',
          ),
        ],
        notes: 'طلب تجريبي متأخر - يجب تحويله فوراً',
        priority: 'عالية',
      );

      setState(() {
        _testResults += result['success']
            ? '✅ تم إنشاء الطلب بنجاح: ${result['orderNumber']}\n'
                '📅 مجدول لتاريخ: ${DateFormat('yyyy/MM/dd').format(yesterday)}\n'
                '⚠️ طلب متأخر - يجب تحويله فوراً\n\n'
            : '❌ فشل في إنشاء الطلب: ${result['message']}\n\n';
      });
    } catch (e) {
      setState(() {
        _testResults += '❌ خطأ: $e\n\n';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runAutoConversion() async {
    setState(() {
      _isLoading = true;
      _testResults += '🔄 تشغيل التحويل التلقائي...\n';
    });

    try {
      final convertedCount = await _service.convertScheduledOrdersToActive();
      setState(() {
        _testResults += convertedCount > 0
            ? '✅ تم تحويل $convertedCount طلب مجدول إلى نشط\n\n'
            : 'ℹ️ لا توجد طلبات مجدولة تحتاج للتحويل\n\n';
      });
    } catch (e) {
      setState(() {
        _testResults += '❌ خطأ في التحويل التلقائي: $e\n\n';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAndDisplayOrders() async {
    setState(() {
      _isLoading = true;
      _testResults += '🔄 تحميل جميع الطلبات المجدولة...\n';
    });

    try {
      await _service.loadScheduledOrders();
      final orders = _service.scheduledOrders;
      
      setState(() {
        _testResults += '📋 تم العثور على ${orders.length} طلب مجدول:\n\n';
        
        for (final order in orders) {
          final daysUntil = order.scheduledDate.difference(DateTime.now()).inDays;
          final status = daysUntil < 0 
              ? '⚠️ متأخر ${-daysUntil} يوم'
              : daysUntil == 0 
                  ? '🔥 اليوم'
                  : daysUntil == 1
                      ? '📅 غداً'
                      : '📅 خلال $daysUntil أيام';
          
          _testResults += '• ${order.orderNumber}\n'
              '  العميل: ${order.customerName}\n'
              '  المبلغ: ${order.totalAmount.toStringAsFixed(0)} د.ع\n'
              '  التاريخ: ${DateFormat('yyyy/MM/dd').format(order.scheduledDate)}\n'
              '  الحالة: $status\n'
              '  الأولوية: ${order.priority}\n\n';
        }
      });
    } catch (e) {
      setState(() {
        _testResults += '❌ خطأ في تحميل الطلبات: $e\n\n';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearTestOrders() async {
    setState(() {
      _isLoading = true;
      _testResults += '🔄 مسح الطلبات التجريبية...\n';
    });

    try {
      await _service.loadScheduledOrders();
      final orders = _service.scheduledOrders;
      int deletedCount = 0;
      
      for (final order in orders) {
        if (order.customerName.contains('تجريبي')) {
          final success = await _service.deleteScheduledOrder(order.id);
          if (success) deletedCount++;
        }
      }
      
      setState(() {
        _testResults += '✅ تم مسح $deletedCount طلب تجريبي\n\n';
      });
    } catch (e) {
      setState(() {
        _testResults += '❌ خطأ في مسح الطلبات: $e\n\n';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
