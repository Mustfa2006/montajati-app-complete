// ===================================
// خدمة حالات الوسيط في التطبيق
// Waseet Status Service for App
// ===================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WaseetStatusService {
  static const String baseUrl = 'https://montajati-backend.onrender.com/api/waseet-statuses';
  
  // الحالات المحلية المخزنة
  static List<WaseetStatus> _cachedStatuses = [];
  static Map<String, List<WaseetStatus>> _categorizedStatuses = {};
  static DateTime? _lastFetch;

  // جلب الحالات بتنسيق مناسب للحوار
  Future<List<Map<String, dynamic>>> getStatuses() async {
    try {
      final statuses = await getApprovedStatuses();
      return statuses.map((status) => {
        'id': status.id,
        'text': status.text,
        'color': _getColorForCategory(status.category),
        'icon': _getIconForCategory(status.category),
        'category': status.category,
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting statuses: $e');
      }
      return [];
    }
  }

  // دالة مساعدة لتحديد لون الفئة
  Color _getColorForCategory(String category) {
    switch (category) {
      case 'delivered':
        return Colors.green;
      case 'in_delivery':
        return Colors.blue;
      case 'contact_issue':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'postponed':
        return Colors.amber;
      case 'address_issue':
        return Colors.brown;
      case 'returned':
        return Colors.purple;
      case 'active':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // دالة مساعدة لتحديد أيقونة الفئة
  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'delivered':
        return Icons.check_circle;
      case 'in_delivery':
        return Icons.local_shipping;
      case 'contact_issue':
        return Icons.phone_disabled;
      case 'cancelled':
        return Icons.cancel;
      case 'postponed':
        return Icons.schedule;
      case 'address_issue':
        return Icons.location_off;
      case 'returned':
        return Icons.keyboard_return;
      case 'active':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  // جلب جميع الحالات المعتمدة
  static Future<List<WaseetStatus>> getApprovedStatuses({bool forceRefresh = false}) async {
    try {
      // استخدام الكاش إذا كان حديث (أقل من ساعة)
      if (!forceRefresh && 
          _cachedStatuses.isNotEmpty && 
          _lastFetch != null && 
          DateTime.now().difference(_lastFetch!).inHours < 1) {
        return _cachedStatuses;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/approved'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _cachedStatuses = (data['data']['statuses'] as List)
              .map((status) => WaseetStatus.fromJson(status))
              .toList();
          
          // تجميع الحالات حسب الفئة
          _categorizedStatuses.clear();
          for (var category in data['data']['categories']) {
            _categorizedStatuses[category['name']] = (category['statuses'] as List)
                .map((status) => WaseetStatus.fromJson(status))
                .toList();
          }
          
          _lastFetch = DateTime.now();
          return _cachedStatuses;
        } else {
          throw Exception(data['message'] ?? 'فشل في جلب الحالات');
        }
      } else {
        throw Exception('خطأ في الخادم: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('خطأ في جلب حالات الوسيط: $e');
      return _cachedStatuses; // إرجاع الكاش في حالة الخطأ
    }
  }

  // جلب الحالات حسب الفئة
  static Future<List<WaseetStatus>> getStatusesByCategory(String category) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/category/$category'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return (data['data']['statuses'] as List)
              .map((status) => WaseetStatus.fromJson(status))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'فشل في جلب حالات الفئة');
        }
      } else {
        throw Exception('خطأ في الخادم: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('خطأ في جلب حالات الفئة $category: $e');
      return _categorizedStatuses[category] ?? [];
    }
  }

  // تحديث حالة طلب واحد
  static Future<bool> updateOrderStatus(String orderId, int waseetStatusId, {String? waseetStatusText}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update-order-status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'orderId': orderId,
          'waseetStatusId': waseetStatusId,
          'waseetStatusText': waseetStatusText,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      } else {
        debugPrint('خطأ في تحديث حالة الطلب: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('خطأ في تحديث حالة الطلب: $e');
      return false;
    }
  }

  // تحديث حالات متعددة
  static Future<Map<String, dynamic>> updateMultipleOrderStatuses(List<Map<String, dynamic>> updates) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update-multiple-orders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'updates': updates}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('خطأ في الخادم: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('خطأ في تحديث الحالات المتعددة: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // الحصول على إحصائيات الحالات
  static Future<List<Map<String, dynamic>>> getStatusStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/statistics'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return List<Map<String, dynamic>>.from(data['data']['statistics']);
        } else {
          throw Exception(data['message'] ?? 'فشل في جلب الإحصائيات');
        }
      } else {
        throw Exception('خطأ في الخادم: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('خطأ في جلب إحصائيات الحالات: $e');
      return [];
    }
  }

  // التحقق من صحة حالة
  static Future<bool> validateStatus(int waseetStatusId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/validate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'waseetStatusId': waseetStatusId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['isValid'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('خطأ في التحقق من الحالة: $e');
      return false;
    }
  }

  // الحصول على معلومات حالة محددة
  static Future<WaseetStatus?> getStatusInfo(int statusId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/status/$statusId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return WaseetStatus.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('خطأ في جلب معلومات الحالة: $e');
      return null;
    }
  }

  // مزامنة الحالات مع قاعدة البيانات
  static Future<bool> syncStatuses() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sync'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          // إعادة تحميل الحالات بعد المزامنة
          await getApprovedStatuses(forceRefresh: true);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('خطأ في مزامنة الحالات: $e');
      return false;
    }
  }

  // الحصول على الحالات المخزنة محلياً
  static List<WaseetStatus> getCachedStatuses() => _cachedStatuses;

  // الحصول على الحالات المجمعة حسب الفئة
  static Map<String, List<WaseetStatus>> getCategorizedStatuses() => _categorizedStatuses;

  // البحث في الحالات
  static List<WaseetStatus> searchStatuses(String query) {
    if (query.isEmpty) return _cachedStatuses;
    
    return _cachedStatuses.where((status) =>
      status.text.toLowerCase().contains(query.toLowerCase()) ||
      status.id.toString().contains(query)
    ).toList();
  }

  // تنظيف الكاش
  static void clearCache() {
    _cachedStatuses.clear();
    _categorizedStatuses.clear();
    _lastFetch = null;
  }
}

// نموذج حالة الوسيط
class WaseetStatus {
  final int id;
  final String text;
  final String category;
  final String appStatus;

  WaseetStatus({
    required this.id,
    required this.text,
    required this.category,
    required this.appStatus,
  });

  factory WaseetStatus.fromJson(Map<String, dynamic> json) {
    return WaseetStatus(
      id: json['id'] ?? 0,
      text: json['text'] ?? '',
      category: json['category'] ?? '',
      appStatus: json['appStatus'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'category': category,
      'appStatus': appStatus,
    };
  }

  @override
  String toString() => 'WaseetStatus(id: $id, text: $text, category: $category, appStatus: $appStatus)';
}
