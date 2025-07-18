// أداة تشخيص نظام حالات الطلبات
// Order Status System Diagnostics Tool

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_status_provider.dart';
import '../utils/order_status_helper.dart';
import '../services/admin_service.dart';

class OrderStatusDiagnostics extends StatefulWidget {
  const OrderStatusDiagnostics({super.key});

  @override
  State<OrderStatusDiagnostics> createState() => _OrderStatusDiagnosticsState();
}

class _OrderStatusDiagnosticsState extends State<OrderStatusDiagnostics> {
  String _diagnosticsOutput = '';
  bool _isRunning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: const Text('تشخيص نظام حالات الطلبات'),
        backgroundColor: const Color(0xFF16213e),
        foregroundColor: Colors.white,
      ),
      body: Consumer<OrderStatusProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // معلومات النظام
                _buildSystemInfo(provider),
                const SizedBox(height: 20),

                // أزرار التشخيص
                _buildDiagnosticButtons(),
                const SizedBox(height: 20),

                // نتائج التشخيص
                Expanded(child: _buildDiagnosticsOutput()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSystemInfo(OrderStatusProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFffd700).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'معلومات النظام',
            style: TextStyle(
              color: Color(0xFFffd700),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'حالة التحميل',
            provider.isLoading ? 'جاري التحميل...' : 'مكتمل',
          ),
          _buildInfoRow('عدد الطلبات', provider.orders.length.toString()),
          _buildInfoRow(
            'الفلتر المحدد',
            provider.selectedFilter?.toString() ?? 'لا يوجد',
          ),
          _buildInfoRow('الأخطاء', provider.error ?? 'لا توجد أخطاء'),

          const SizedBox(height: 12),
          const Text(
            'إحصائيات الحالات:',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          StreamBuilder<Map<String, int>>(
            stream: provider.statusCountsStream,
            builder: (context, snapshot) {
              final counts = snapshot.data ?? {};
              return Column(
                children: OrderStatusHelper.getAvailableStatuses().map((
                  status,
                ) {
                  final count = counts[status] ?? 0;
                  return _buildInfoRow(status, count.toString());
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildDiagnosticButton('اختبار الاتصال', Icons.wifi, _testConnection),
        _buildDiagnosticButton(
          'اختبار قاعدة البيانات',
          Icons.storage,
          _testDatabase,
        ),
        _buildDiagnosticButton(
          'اختبار التحديث الفوري',
          Icons.sync,
          _testRealtimeUpdates,
        ),
        _buildDiagnosticButton(
          'اختبار تحويل الحالات',
          Icons.transform,
          _testStatusConversion,
        ),
        _buildDiagnosticButton(
          'إعادة تحميل البيانات',
          Icons.refresh,
          _reloadData,
        ),
        _buildDiagnosticButton('مسح السجل', Icons.clear, _clearLog),
      ],
    );
  }

  Widget _buildDiagnosticButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: _isRunning ? null : onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFffd700),
        foregroundColor: const Color(0xFF1a1a2e),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildDiagnosticsOutput() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0d1117),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFffd700).withOpacity(0.3)),
      ),
      child: SingleChildScrollView(
        child: Text(
          _diagnosticsOutput.isEmpty
              ? 'اضغط على أحد الأزرار لبدء التشخيص...'
              : _diagnosticsOutput,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  void _addLog(String message) {
    setState(() {
      final timestamp = DateTime.now().toString().substring(11, 19);
      _diagnosticsOutput += '[$timestamp] $message\n';
    });
  }

  Future<void> _testConnection() async {
    setState(() => _isRunning = true);
    _addLog('🔄 بدء اختبار الاتصال...');

    try {
      final provider = context.read<OrderStatusProvider>();
      await provider.loadOrders();
      _addLog('✅ تم الاتصال بنجاح');
      _addLog('📊 تم تحميل ${provider.orders.length} طلب');
    } catch (e) {
      _addLog('❌ فشل الاتصال: $e');
    }

    setState(() => _isRunning = false);
  }

  Future<void> _testDatabase() async {
    setState(() => _isRunning = true);
    _addLog('🔄 بدء اختبار قاعدة البيانات...');

    try {
      final orders = await AdminService.getOrders();
      _addLog('✅ تم الاتصال بقاعدة البيانات بنجاح');
      _addLog('📊 عدد الطلبات في قاعدة البيانات: ${orders.length}');

      if (orders.isNotEmpty) {
        final firstOrder = orders.first;
        _addLog('📋 أول طلب: ${firstOrder.id}');
        _addLog('📋 حالة الطلب: ${firstOrder.status}');
        OrderStatusHelper.debugStatus(firstOrder.status);
      }
    } catch (e) {
      _addLog('❌ فشل في الاتصال بقاعدة البيانات: $e');
    }

    setState(() => _isRunning = false);
  }

  Future<void> _testRealtimeUpdates() async {
    setState(() => _isRunning = true);
    _addLog('🔄 بدء اختبار التحديث الفوري...');

    try {
      final provider = context.read<OrderStatusProvider>();

      // إعادة تهيئة الاشتراك
      await provider.initialize();
      _addLog('✅ تم تهيئة التحديث الفوري');

      // مراقبة التحديثات لمدة 10 ثوان
      _addLog('⏱️ مراقبة التحديثات لمدة 10 ثوان...');

      int updateCount = 0;
      final subscription = provider.ordersStream.listen((orders) {
        updateCount++;
        _addLog('📡 تحديث رقم $updateCount: ${orders.length} طلب');
      });

      await Future.delayed(const Duration(seconds: 10));
      subscription.cancel();

      _addLog('✅ انتهى اختبار التحديث الفوري');
      _addLog('📊 عدد التحديثات المستلمة: $updateCount');
    } catch (e) {
      _addLog('❌ فشل في اختبار التحديث الفوري: $e');
    }

    setState(() => _isRunning = false);
  }

  void _testStatusConversion() {
    setState(() => _isRunning = true);
    _addLog('🔄 بدء اختبار تحويل الحالات...');

    final testValues = [
      'confirmed',
      'processing',
      'shipped',
      'active',
      'in_delivery',
      'delivered',
      '1',
      '2',
      '3',
      '4',
      'نشط',
      'قيد التوصيل',
      'تم التوصيل',
    ];

    for (final value in testValues) {
      final arabicText = OrderStatusHelper.getArabicStatus(value);
      final dbValue = OrderStatusHelper.arabicToDatabase(arabicText);

      _addLog('🔄 "$value" -> "$arabicText" -> "$dbValue"');
    }

    _addLog('✅ انتهى اختبار تحويل الحالات');
    setState(() => _isRunning = false);
  }

  Future<void> _reloadData() async {
    setState(() => _isRunning = true);
    _addLog('🔄 إعادة تحميل البيانات...');

    try {
      final provider = context.read<OrderStatusProvider>();
      await provider.loadOrders();
      _addLog('✅ تم إعادة تحميل البيانات بنجاح');
    } catch (e) {
      _addLog('❌ فشل في إعادة تحميل البيانات: $e');
    }

    setState(() => _isRunning = false);
  }

  void _clearLog() {
    setState(() {
      _diagnosticsOutput = '';
    });
  }
}
