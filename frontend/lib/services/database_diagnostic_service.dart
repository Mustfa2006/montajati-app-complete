import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseDiagnosticService {
  static final _supabase = Supabase.instance.client;

  /// تشخيص شامل لقاعدة البيانات
  static Future<Map<String, dynamic>> runFullDiagnostic() async {
    final results = <String, dynamic>{};

    try {
      debugPrint('🔍 بدء التشخيص الشامل لقاعدة البيانات...');

      // 1. فحص جدول المستخدمين
      results['users'] = await _diagnoseUsersTable();

      // 2. فحص جدول الطلبات
      results['orders'] = await _diagnoseOrdersTable();

      // 3. فحص الربط بين الجداول
      results['relationships'] = await _diagnoseRelationships();

      // 4. حساب الإحصائيات الفعلية
      results['statistics'] = await _calculateRealStatistics();

      debugPrint('✅ تم إكمال التشخيص الشامل');
      return results;
    } catch (e) {
      debugPrint('❌ خطأ في التشخيص: $e');
      results['error'] = e.toString();
      return results;
    }
  }

  /// فحص جدول المستخدمين
  static Future<Map<String, dynamic>> _diagnoseUsersTable() async {
    try {
      debugPrint('🔍 فحص جدول المستخدمين...');

      // جلب عينة من المستخدمين
      final users = await _supabase.from('users').select('*').limit(3);

      final totalUsers = await _supabase.from('users').select('id');

      return {
        'total_count': totalUsers.length,
        'sample_data': users,
        'columns': users.isNotEmpty ? users.first.keys.toList() : [],
        'status': 'success',
      };
    } catch (e) {
      return {'error': e.toString(), 'status': 'error'};
    }
  }

  /// فحص جدول الطلبات
  static Future<Map<String, dynamic>> _diagnoseOrdersTable() async {
    try {
      debugPrint('🔍 فحص جدول الطلبات...');

      // جلب عينة من الطلبات
      final orders = await _supabase.from('orders').select('*').limit(3);

      final totalOrders = await _supabase.from('orders').select('id');

      // فحص الحالات المختلفة
      final statusCounts = <String, int>{};
      if (totalOrders.isNotEmpty) {
        final allOrders = await _supabase.from('orders').select('status');

        for (var order in allOrders) {
          final status = order['status'] ?? 'unknown';
          statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        }
      }

      return {
        'total_count': totalOrders.length,
        'sample_data': orders,
        'columns': orders.isNotEmpty ? orders.first.keys.toList() : [],
        'status_distribution': statusCounts,
        'status': 'success',
      };
    } catch (e) {
      return {'error': e.toString(), 'status': 'error'};
    }
  }

  /// فحص العلاقات بين الجداول
  static Future<Map<String, dynamic>> _diagnoseRelationships() async {
    try {
      debugPrint('🔍 فحص العلاقات بين الجداول...');

      final results = <String, dynamic>{};

      // فحص إذا كان هناك عمود customer_id في جدول الطلبات
      final ordersWithCustomerId = await _supabase
          .from('orders')
          .select('customer_id')
          .limit(1);

      results['has_customer_id'] =
          ordersWithCustomerId.isNotEmpty &&
          ordersWithCustomerId.first.containsKey('customer_id');

      // فحص إذا كان هناك عمود user_id في جدول الطلبات
      try {
        final ordersWithUserId = await _supabase
            .from('orders')
            .select('user_id')
            .limit(1);
        results['has_user_id'] =
            ordersWithUserId.isNotEmpty &&
            ordersWithUserId.first.containsKey('user_id');
      } catch (e) {
        results['has_user_id'] = false;
      }

      // فحص الطلبات المرتبطة بمستخدمين
      if (results['has_customer_id'] == true) {
        final linkedOrders = await _supabase
            .from('orders')
            .select('customer_id')
            .not('customer_id', 'is', null);
        results['orders_with_customer_id'] = linkedOrders.length;
      }

      return results;
    } catch (e) {
      return {'error': e.toString(), 'status': 'error'};
    }
  }

  /// حساب الإحصائيات الحقيقية
  static Future<Map<String, dynamic>> _calculateRealStatistics() async {
    try {
      debugPrint('🔍 حساب الإحصائيات الحقيقية...');

      // إحصائيات المستخدمين
      final allUsers = await _supabase
          .from('users')
          .select('is_admin, is_active');
      final totalUsers = allUsers.length;
      final adminUsers = allUsers.where((u) => u['is_admin'] == true).length;
      final activeUsers = allUsers.where((u) => u['is_active'] == true).length;

      // إحصائيات الطلبات
      final allOrders = await _supabase.from('orders').select('status, total');
      final totalOrders = allOrders.length;

      final deliveredOrders = allOrders
          .where((o) => o['status'] == 'delivered')
          .length;
      final activeOrdersCount = allOrders
          .where((o) => o['status'] == 'active')
          .length;
      final cancelledOrders = allOrders
          .where((o) => o['status'] == 'cancelled')
          .length;

      // حساب إجمالي المبيعات
      final totalSales = allOrders
          .where((o) => o['status'] == 'delivered')
          .fold<double>(0.0, (sum, o) => sum + (o['total']?.toDouble() ?? 0.0));

      return {
        'users': {
          'total': totalUsers,
          'admin': adminUsers,
          'active': activeUsers,
          'regular': totalUsers - adminUsers,
        },
        'orders': {
          'total': totalOrders,
          'delivered': deliveredOrders,
          'active': activeOrdersCount,
          'cancelled': cancelledOrders,
        },
        'sales': {
          'total': totalSales,
          'average_order': deliveredOrders > 0
              ? totalSales / deliveredOrders
              : 0.0,
        },
        'status': 'success',
      };
    } catch (e) {
      return {'error': e.toString(), 'status': 'error'};
    }
  }

  /// إنشاء بيانات تجريبية للاختبار
  static Future<bool> createTestData() async {
    try {
      debugPrint('🔄 إنشاء بيانات تجريبية...');

      // حذف البيانات التجريبية السابقة أولاً
      await cleanupTestData();

      // التحقق من اتصال قاعدة البيانات أولاً
      try {
        final testConnection = await _supabase
            .from('users')
            .select('count')
            .count();
        debugPrint(
          '✅ اتصال قاعدة البيانات سليم - عدد المستخدمين: $testConnection',
        );
      } catch (e) {
        debugPrint('❌ خطأ في اتصال قاعدة البيانات: $e');
        return false;
      }

      // إنشاء مستخدمين تجريبيين بشكل منفصل لتجنب الأخطاء
      List<dynamic> createdUsers = [];

      final testUsers = [
        {
          'name': 'أحمد محمد التجريبي',
          'email': 'ahmed.test@example.com',
          'phone': '07701234567',
          'password_hash': 'test123hash',
          'is_admin': false,
          'is_active': true,
          'province': 'بغداد',
          'city': 'الكرادة',
          'address': 'شارع الكرادة الداخلية',
        },
        {
          'name': 'فاطمة علي التجريبية',
          'email': 'fatima.test@example.com',
          'phone': '07707654321',
          'password_hash': 'test123hash',
          'is_admin': false,
          'is_active': true,
          'province': 'البصرة',
          'city': 'المعقل',
          'address': 'شارع المعقل الرئيسي',
        },
        {
          'name': 'سارة أحمد التجريبية',
          'email': 'sara.test@example.com',
          'phone': '07709876543',
          'password_hash': 'test123hash',
          'is_admin': false,
          'is_active': true,
          'province': 'أربيل',
          'city': 'المركز',
          'address': 'شارع الجامعة',
        },
      ];

      // إنشاء المستخدمين واحد تلو الآخر
      for (int i = 0; i < testUsers.length; i++) {
        try {
          // التحقق من وجود المستخدم أولاً
          final existingUser = await _supabase
              .from('users')
              .select()
              .eq('email', testUsers[i]['email']!)
              .maybeSingle();

          if (existingUser != null) {
            createdUsers.add(existingUser);
            debugPrint(
              '✅ المستخدم ${i + 1} موجود مسبقاً: ${testUsers[i]['name']}',
            );
          } else {
            final user = await _supabase
                .from('users')
                .insert(testUsers[i])
                .select()
                .single();
            createdUsers.add(user);
            debugPrint('✅ تم إنشاء المستخدم ${i + 1}: ${testUsers[i]['name']}');
          }
        } catch (e) {
          debugPrint('❌ خطأ في إنشاء المستخدم ${i + 1}: $e');
        }
      }

      debugPrint('✅ تم إنشاء ${createdUsers.length} مستخدم تجريبي');

      // إنشاء طلبات تجريبية مع ربط صحيح
      if (createdUsers.isNotEmpty) {
        final testOrders = [
          // طلبات للمستخدم الأول
          {
            'order_number': 'TEST-${DateTime.now().millisecondsSinceEpoch}-1',
            'customer_name': 'أحمد محمد التجريبي',
            'customer_phone': '07701234567',
            'customer_address': 'بغداد - الكرادة - شارع الكرادة الداخلية',
            'total': 50000,
            'status': 'delivered',
            'customer_id': createdUsers[0]['id'],
            'created_at': DateTime.now()
                .subtract(const Duration(days: 5))
                .toIso8601String(),
          },
          {
            'order_number': 'TEST-${DateTime.now().millisecondsSinceEpoch}-2',
            'customer_name': 'أحمد محمد التجريبي',
            'customer_phone': '07701234567',
            'customer_address': 'بغداد - الكرادة - شارع الكرادة الداخلية',
            'total': 75000,
            'status': 'delivered',
            'customer_id': createdUsers[0]['id'],
            'created_at': DateTime.now()
                .subtract(const Duration(days: 3))
                .toIso8601String(),
          },
          {
            'order_number': 'TEST-${DateTime.now().millisecondsSinceEpoch}-3',
            'customer_name': 'أحمد محمد التجريبي',
            'customer_phone': '07701234567',
            'customer_address': 'بغداد - الكرادة - شارع الكرادة الداخلية',
            'total': 30000,
            'status': 'active',
            'customer_id': createdUsers[0]['id'],
            'created_at': DateTime.now()
                .subtract(const Duration(days: 1))
                .toIso8601String(),
          },

          // طلبات للمستخدم الثاني
          {
            'order_number': 'TEST-${DateTime.now().millisecondsSinceEpoch}-4',
            'customer_name': 'فاطمة علي التجريبية',
            'customer_phone': '07707654321',
            'customer_address': 'البصرة - المعقل - شارع المعقل الرئيسي',
            'total': 90000,
            'status': 'delivered',
            'customer_id': createdUsers[1]['id'],
            'created_at': DateTime.now()
                .subtract(const Duration(days: 7))
                .toIso8601String(),
          },
          {
            'order_number': 'TEST-${DateTime.now().millisecondsSinceEpoch}-5',
            'customer_name': 'فاطمة علي التجريبية',
            'customer_phone': '07707654321',
            'customer_address': 'البصرة - المعقل - شارع المعقل الرئيسي',
            'total': 45000,
            'status': 'in_delivery',
            'customer_id': createdUsers[1]['id'],
            'created_at': DateTime.now()
                .subtract(const Duration(hours: 12))
                .toIso8601String(),
          },

          // طلبات للمستخدم الثالث
          {
            'order_number': 'TEST-${DateTime.now().millisecondsSinceEpoch}-6',
            'customer_name': 'سارة أحمد التجريبية',
            'customer_phone': '07709876543',
            'customer_address': 'أربيل - المركز - شارع الجامعة',
            'total': 120000,
            'status': 'delivered',
            'customer_id': createdUsers[2]['id'],
            'created_at': DateTime.now()
                .subtract(const Duration(days: 2))
                .toIso8601String(),
          },
          {
            'order_number': 'TEST-${DateTime.now().millisecondsSinceEpoch}-7',
            'customer_name': 'سارة أحمد التجريبية',
            'customer_phone': '07709876543',
            'customer_address': 'أربيل - المركز - شارع الجامعة',
            'total': 25000,
            'status': 'cancelled',
            'customer_id': createdUsers[2]['id'],
            'created_at': DateTime.now()
                .subtract(const Duration(days: 4))
                .toIso8601String(),
          },
        ];

        // إنشاء الطلبات واحد تلو الآخر لتجنب الأخطاء
        List<dynamic> createdOrders = [];
        for (int i = 0; i < testOrders.length; i++) {
          try {
            final order = await _supabase
                .from('orders')
                .insert(testOrders[i])
                .select()
                .single();
            createdOrders.add(order);
            debugPrint('✅ تم إنشاء الطلب ${i + 1}');
          } catch (e) {
            debugPrint('❌ خطأ في إنشاء الطلب ${i + 1}: $e');
          }
        }

        debugPrint('✅ تم إنشاء ${createdOrders.length} طلب تجريبي');

        // طباعة تفاصيل الربط
        for (int i = 0; i < createdUsers.length; i++) {
          final userId = createdUsers[i]['id'];
          final userName = createdUsers[i]['name'];
          final userOrders = createdOrders
              .where((o) => o['customer_id'] == userId)
              .length;
          debugPrint(
            '👤 المستخدم: $userName (ID: $userId) - عدد الطلبات: $userOrders',
          );
        }
      } else {
        debugPrint('⚠️ لم يتم إنشاء أي مستخدم، لذلك لن يتم إنشاء طلبات');
      }

      return true;
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء البيانات التجريبية: $e');
      return false;
    }
  }

  /// حذف البيانات التجريبية
  static Future<bool> cleanupTestData() async {
    try {
      debugPrint('🔄 حذف البيانات التجريبية...');

      // حذف الطلبات التجريبية
      try {
        await _supabase.from('orders').delete().inFilter('customer_name', [
          'أحمد محمد التجريبي',
          'فاطمة علي التجريبية',
          'سارة أحمد التجريبية',
          'مستخدم تجريبي',
        ]);
        debugPrint('✅ تم حذف الطلبات التجريبية');
      } catch (e) {
        debugPrint('⚠️ خطأ في حذف الطلبات التجريبية: $e');
      }

      // حذف المستخدمين التجريبيين
      try {
        await _supabase.from('users').delete().inFilter('email', [
          'ahmed.test@example.com',
          'fatima.test@example.com',
          'sara.test@example.com',
          'test@example.com',
        ]);
        debugPrint('✅ تم حذف المستخدمين التجريبيين');
      } catch (e) {
        debugPrint('⚠️ خطأ في حذف المستخدمين التجريبيين: $e');
      }

      debugPrint('✅ تم حذف البيانات التجريبية');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في حذف البيانات التجريبية: $e');
      return false;
    }
  }
}
