// 🧪 صفحة اختبار النظام الجديد - اختبار شامل للمزايا المحدثة
// تتضمن اختبار التوصيل المرن والإشعارات وإنشاء الطلبات

import 'package:flutter/material.dart';
import '../services/new_flexible_delivery_service.dart';


class NewSystemTestPage extends StatefulWidget {
  const NewSystemTestPage({Key? key}) : super(key: key);

  @override
  State<NewSystemTestPage> createState() => _NewSystemTestPageState();
}

class _NewSystemTestPageState extends State<NewSystemTestPage> {
  bool _isLoading = false;
  List<String> _testResults = [];
  Map<String, dynamic> _systemStatus = {};
  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _cities = [];
  String? _selectedProvinceId;

  @override
  void initState() {
    super.initState();
    _runInitialTests();
  }

  // تشغيل الاختبارات الأولية
  Future<void> _runInitialTests() async {
    setState(() {
      _isLoading = true;
      _testResults.clear();
    });

    await _testSystemHealth();
    await _testNotificationService();
    await _loadProvinces();

    setState(() {
      _isLoading = false;
    });
  }

  // اختبار صحة النظام
  Future<void> _testSystemHealth() async {
    try {
      _addTestResult('🏥 اختبار صحة النظام...');
      
      final isHealthy = await NewFlexibleDeliveryService.checkSystemHealth();
      final systemInfo = await NewFlexibleDeliveryService.getSystemInfo();
      
      setState(() {
        _systemStatus = NewFlexibleDeliveryService.getSystemStatus();
      });

      if (isHealthy) {
        _addTestResult('✅ النظام يعمل بشكل صحيح');
        _addTestResult('📊 المزود الحالي: ${_systemStatus['currentProvider'] ?? 'غير محدد'}');
      } else {
        _addTestResult('❌ النظام لا يعمل بشكل صحيح');
      }
    } catch (e) {
      _addTestResult('❌ خطأ في اختبار النظام: $e');
    }
  }

  // تم إزالة نظام الإشعارات
  Future<void> _testNotificationService() async {
    _addTestResult('⚠️ تم إزالة نظام الإشعارات من التطبيق');
  }

  // تحميل المحافظات
  Future<void> _loadProvinces() async {
    try {
      _addTestResult('🌍 تحميل المحافظات...');
      
      final provinces = await NewFlexibleDeliveryService.getProvinces();
      
      setState(() {
        _provinces = provinces;
      });

      if (provinces.isNotEmpty) {
        _addTestResult('✅ تم تحميل ${provinces.length} محافظة');
      } else {
        _addTestResult('⚠️ لم يتم العثور على محافظات');
      }
    } catch (e) {
      _addTestResult('❌ خطأ في تحميل المحافظات: $e');
    }
  }

  // تحميل المدن
  Future<void> _loadCities(String provinceId) async {
    try {
      _addTestResult('🏙️ تحميل المدن للمحافظة: $provinceId');
      
      final cities = await NewFlexibleDeliveryService.getCities(provinceId);
      
      setState(() {
        _cities = cities;
      });

      if (cities.isNotEmpty) {
        _addTestResult('✅ تم تحميل ${cities.length} مدينة');
      } else {
        _addTestResult('⚠️ لم يتم العثور على مدن');
      }
    } catch (e) {
      _addTestResult('❌ خطأ في تحميل المدن: $e');
    }
  }

  // اختبار إنشاء طلب تجريبي
  Future<void> _testCreateOrder() async {
    if (_selectedProvinceId == null || _cities.isEmpty) {
      _addTestResult('⚠️ يرجى اختيار محافظة ومدينة أولاً');
      return;
    }

    try {
      _addTestResult('📦 اختبار إنشاء طلب تجريبي...');
      
      final result = await NewFlexibleDeliveryService.createOrder(
        userId: 1,
        customerName: 'أحمد محمد',
        customerPhone: '07501234567',
        customerAddress: 'شارع الحبيبية، بناية رقم 10',
        provinceId: _selectedProvinceId!,
        cityId: _cities.first['id'].toString(),
        items: [
          {
            'productId': 1,
            'productName': 'منتج تجريبي',
            'quantity': 2,
            'price': 25000,
          }
        ],
        notes: 'طلب تجريبي من التطبيق',
      );

      if (result['success'] == true) {
        _addTestResult('✅ تم إنشاء الطلب بنجاح');
        _addTestResult('📋 رقم الطلب: ${result['orderId']}');
        _addTestResult('🔍 رقم التتبع: ${result['trackingNumber']}');
      } else {
        _addTestResult('❌ فشل في إنشاء الطلب: ${result['error']}');
      }
    } catch (e) {
      _addTestResult('❌ خطأ في إنشاء الطلب: $e');
    }
  }

  // إضافة نتيجة اختبار
  void _addTestResult(String result) {
    setState(() {
      _testResults.add('${DateTime.now().toString().substring(11, 19)} - $result');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار النظام الجديد'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runInitialTests,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // معلومات النظام
                  _buildSystemStatusCard(),
                  const SizedBox(height: 16),
                  
                  // اختبار المحافظات والمدن
                  _buildLocationTestCard(),
                  const SizedBox(height: 16),
                  
                  // اختبار إنشاء الطلبات
                  _buildOrderTestCard(),
                  const SizedBox(height: 16),
                  
                  // نتائج الاختبارات
                  _buildTestResultsCard(),
                ],
              ),
            ),
    );
  }

  // بطاقة حالة النظام
  Widget _buildSystemStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 حالة النظام',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('الصحة: ${_systemStatus['isHealthy'] == true ? '✅ سليم' : '❌ غير سليم'}'),
            Text('المزود: ${_systemStatus['currentProvider'] ?? 'غير محدد'}'),
            Text('المحافظات المخزنة: ${_systemStatus['hasCachedProvinces'] == true ? '✅ نعم' : '❌ لا'}'),
            Text('المدن المخزنة: ${_systemStatus['hasCachedCities'] == true ? '✅ نعم' : '❌ لا'}'),
          ],
        ),
      ),
    );
  }

  // بطاقة اختبار المواقع
  Widget _buildLocationTestCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🌍 اختبار المحافظات والمدن',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            // قائمة المحافظات
            if (_provinces.isNotEmpty) ...[
              const Text('المحافظات:'),
              DropdownButton<String>(
                value: _selectedProvinceId,
                hint: const Text('اختر محافظة'),
                isExpanded: true,
                items: _provinces.map((province) {
                  return DropdownMenuItem<String>(
                    value: province['id'].toString(),
                    child: Text(province['name'] ?? 'غير محدد'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProvinceId = value;
                    _cities.clear();
                  });
                  if (value != null) {
                    _loadCities(value);
                  }
                },
              ),
            ],
            
            // قائمة المدن
            if (_cities.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('المدن:'),
              Container(
                height: 100,
                child: ListView.builder(
                  itemCount: _cities.length,
                  itemBuilder: (context, index) {
                    final city = _cities[index];
                    return ListTile(
                      dense: true,
                      title: Text(city['name'] ?? 'غير محدد'),
                      subtitle: Text('ID: ${city['id']}'),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // بطاقة اختبار الطلبات
  Widget _buildOrderTestCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📦 اختبار إنشاء الطلبات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _testCreateOrder,
              child: const Text('إنشاء طلب تجريبي'),
            ),
          ],
        ),
      ),
    );
  }

  // بطاقة نتائج الاختبارات
  Widget _buildTestResultsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 نتائج الاختبارات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _testResults.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      _testResults[index],
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
