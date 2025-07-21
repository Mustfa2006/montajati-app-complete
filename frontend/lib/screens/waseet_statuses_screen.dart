// ===================================
// شاشة إدارة حالات الوسيط
// Waseet Statuses Management Screen
// ===================================

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WaseetStatusesScreen extends StatefulWidget {
  const WaseetStatusesScreen({Key? key}) : super(key: key);

  @override
  State<WaseetStatusesScreen> createState() => _WaseetStatusesScreenState();
}

class _WaseetStatusesScreenState extends State<WaseetStatusesScreen> {
  List<dynamic> statuses = [];
  Map<String, List<dynamic>> categorizedStatuses = {};
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadStatuses();
  }

  Future<void> loadStatuses() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://montajati-backend.onrender.com/api/waseet-statuses/approved'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            statuses = data['data']['statuses'];
            categorizedStatuses = {};
            
            // تجميع الحالات حسب الفئة
            for (var category in data['data']['categories']) {
              categorizedStatuses[category['name']] = category['statuses'];
            }
            
            isLoading = false;
          });
        } else {
          throw Exception(data['message'] ?? 'فشل في جلب البيانات');
        }
      } else {
        throw Exception('خطأ في الخادم: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حالات الوسيط'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadStatuses,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red[400]),
                      const SizedBox(height: 16),
                      Text(
                        'خطأ في تحميل البيانات',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: loadStatuses,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : buildStatusesList(),
    );
  }

  Widget buildStatusesList() {
    return RefreshIndicator(
      onRefresh: loadStatuses,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // إحصائيات عامة
            buildStatisticsCard(),
            const SizedBox(height: 16),
            
            // الحالات مجمعة حسب الفئة
            ...categorizedStatuses.entries.map((entry) => 
              buildCategorySection(entry.key, entry.value)
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget buildStatisticsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'إحصائيات الحالات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                buildStatItem('إجمالي الحالات', statuses.length.toString(), Colors.blue),
                buildStatItem('الفئات', categorizedStatuses.length.toString(), Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget buildCategorySection(String categoryName, List<dynamic> categoryStatuses) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          getCategoryDisplayName(categoryName),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text('${categoryStatuses.length} حالة'),
        leading: Icon(
          getCategoryIcon(categoryName),
          color: getCategoryColor(categoryName),
        ),
        children: categoryStatuses.map((status) => 
          buildStatusItem(status)
        ).toList(),
      ),
    );
  }

  Widget buildStatusItem(dynamic status) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: getStatusColor(status['appStatus']),
        child: Text(
          status['id'].toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      title: Text(
        status['text'],
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        'حالة التطبيق: ${getAppStatusDisplayName(status['appStatus'])}',
        style: TextStyle(
          color: getStatusColor(status['appStatus']),
          fontSize: 12,
        ),
      ),
      trailing: Chip(
        label: Text(
          'ID: ${status['id']}',
          style: const TextStyle(fontSize: 10),
        ),
        backgroundColor: Colors.grey[200],
      ),
    );
  }

  String getCategoryDisplayName(String category) {
    const categoryNames = {
      'delivered': '🚚 تم التوصيل',
      'modified': '🔄 تعديلات',
      'contact_issue': '📞 مشاكل التواصل',
      'in_delivery': '🚛 قيد التوصيل',
      'postponed': '⏰ مؤجل',
      'cancelled': '❌ ملغي',
      'address_issue': '📍 مشاكل العنوان',
    };
    return categoryNames[category] ?? category;
  }

  IconData getCategoryIcon(String category) {
    const categoryIcons = {
      'delivered': Icons.check_circle,
      'modified': Icons.edit,
      'contact_issue': Icons.phone_disabled,
      'in_delivery': Icons.local_shipping,
      'postponed': Icons.schedule,
      'cancelled': Icons.cancel,
      'address_issue': Icons.location_off,
    };
    return categoryIcons[category] ?? Icons.category;
  }

  Color getCategoryColor(String category) {
    const categoryColors = {
      'delivered': Colors.green,
      'modified': Colors.blue,
      'contact_issue': Colors.orange,
      'in_delivery': Colors.purple,
      'postponed': Colors.amber,
      'cancelled': Colors.red,
      'address_issue': Colors.brown,
    };
    return categoryColors[category] ?? Colors.grey;
  }

  Color getStatusColor(String appStatus) {
    const statusColors = {
      'delivered': Colors.green,
      'in_delivery': Colors.blue,
      'cancelled': Colors.red,
      'active': Colors.orange,
    };
    return statusColors[appStatus] ?? Colors.grey;
  }

  String getAppStatusDisplayName(String appStatus) {
    const statusNames = {
      'delivered': 'تم التوصيل',
      'in_delivery': 'قيد التوصيل',
      'cancelled': 'ملغي',
      'active': 'نشط',
    };
    return statusNames[appStatus] ?? appStatus;
  }
}
