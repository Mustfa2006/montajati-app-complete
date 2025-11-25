import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_user.dart';
import '../models/user_statistics.dart';
import '../config/supabase_config.dart';

class UserManagementService {
  static final SupabaseClient _supabase = SupabaseConfig.client;

  // ===== جلب البيانات =====

  // جلب جميع المستخدمين مع الإحصائيات
  static Future<List<AdminUser>> getAllUsers({
    int? limit,
    int? offset,
    String? searchQuery,
    String? statusFilter,
    String? roleFilter,
    String? sortBy,
    bool ascending = true,
  }) async {
    try {
      debugPrint('🔄 جلب قائمة المستخدمين...');

      // إنشاء استعلام بسيط
      List<Map<String, dynamic>> response;

      if (searchQuery != null && searchQuery.isNotEmpty) {
        response = await _supabase
            .from('users')
            .select('*')
            .or('name.ilike.%$searchQuery%,phone.ilike.%$searchQuery%,email.ilike.%$searchQuery%')
            .order('created_at', ascending: false)
            .limit(limit ?? 20); // تقليل العدد لتحسين الأداء
      } else {
        response = await _supabase
            .from('users')
            .select('*')
            .order('created_at', ascending: false)
            .limit(limit ?? 20); // تقليل العدد لتحسين الأداء
      }

      debugPrint('✅ تم جلب ${response.length} مستخدم');

      // تحويل البيانات بدون حساب الإحصائيات (لتحسين الأداء)
      List<AdminUser> users = [];
      for (var userData in response) {
        // إضافة إحصائيات افتراضية سريعة
        final quickStats = {
          'total_orders': 0,
          'total_sales': 0.0,
          'achieved_profits': userData['achieved_profits'] ?? 0.0,
          'expected_profits': userData['expected_profits'] ?? 0.0,
          'last_login': userData['last_login'],
          'login_count': userData['login_count'] ?? 0,
        };

        users.add(AdminUser.fromJson({...userData, ...quickStats}));
      }

      return users;
    } catch (e) {
      debugPrint('❌ خطأ في جلب المستخدمين: $e');
      return [];
    }
  }

  // تم حذف _getUserProfitsStats غير المستخدم

  // دالة مساعدة لحساب إحصائيات طلبات المستخدم
  static Future<Map<String, dynamic>> _getUserOrdersStats(String userId) async {
    try {
      debugPrint('🔄 حساب إحصائيات المستخدم: $userId');

      // جلب بيانات المستخدم أولاً
      final userData = await _supabase.from('users').select('name, phone, email').eq('id', userId).single();

      debugPrint('👤 بيانات المستخدم: ${userData['name']} - ${userData['phone']}');

      // محاولة جلب الطلبات بطرق مختلفة
      List<dynamic> orders = [];

      // الطريقة 1: البحث بـ customer_id
      try {
        orders = await _supabase
            .from('orders')
            .select('status, total, profit, customer_id, customer_name, customer_phone')
            .eq('customer_id', userId);
        debugPrint('✅ تم العثور على ${orders.length} طلب باستخدام customer_id');
      } catch (e) {
        debugPrint('⚠️ فشل البحث بـ customer_id: $e');
      }

      // إذا لم نجد طلبات، جرب البحث بالاسم
      if (orders.isEmpty) {
        try {
          // البحث بالاسم والهاتف
          final ordersByName = await _supabase
              .from('orders')
              .select('status, total, profit, customer_name, customer_phone')
              .eq('customer_name', userData['name']);

          orders = ordersByName;
          debugPrint('✅ تم العثور على ${orders.length} طلب باستخدام الاسم');

          // إذا وجدنا طلبات بالاسم، قم بتحديث customer_id
          if (orders.isNotEmpty) {
            try {
              await _supabase
                  .from('orders')
                  .update({'customer_id': userId})
                  .eq('customer_name', userData['name'])
                  .eq('customer_phone', userData['phone']);
              debugPrint('✅ تم تحديث customer_id للطلبات');
            } catch (e) {
              debugPrint('⚠️ فشل في تحديث customer_id: $e');
            }
          }
        } catch (e) {
          debugPrint('⚠️ فشل البحث بالاسم: $e');
        }
      }

      // الطريقة 2: إذا لم نجد طلبات، جرب user_id
      if (orders.isEmpty) {
        try {
          orders = await _supabase.from('orders').select('status, total, profit, user_id').eq('user_id', userId);
          debugPrint('✅ تم العثور على ${orders.length} طلب باستخدام user_id');
        } catch (e) {
          debugPrint('⚠️ فشل البحث بـ user_id: $e');
        }
      }

      // الطريقة 3: البحث بالهاتف
      if (orders.isEmpty && userData['phone'] != null) {
        try {
          orders = await _supabase
              .from('orders')
              .select('status, total, profit, customer_phone')
              .eq('customer_phone', userData['phone']);
          debugPrint('✅ تم العثور على ${orders.length} طلب باستخدام رقم الهاتف');

          // إذا وجدنا طلبات بالهاتف، قم بتحديث customer_id
          if (orders.isNotEmpty) {
            try {
              await _supabase.from('orders').update({'customer_id': userId}).eq('customer_phone', userData['phone']);
              debugPrint('✅ تم تحديث customer_id للطلبات (بالهاتف)');
            } catch (e) {
              debugPrint('⚠️ فشل في تحديث customer_id (بالهاتف): $e');
            }
          }
        } catch (e) {
          debugPrint('⚠️ فشل البحث بالهاتف: $e');
        }
      }

      // حساب الإحصائيات
      final totalOrders = orders.length;
      final completedOrders = orders.where((o) => o['status'] == 'delivered').length;
      final cancelledOrders = orders.where((o) => o['status'] == 'cancelled').length;
      final pendingOrders = orders.where((o) => o['status'] == 'active' || o['status'] == 'in_delivery').length;

      final totalProfits = orders
          .where((o) => o['status'] == 'delivered')
          .fold<double>(0.0, (sum, o) => sum + (o['profit']?.toDouble() ?? 0.0));

      debugPrint('📊 إحصائيات المستخدم $userId:');
      debugPrint('   إجمالي الطلبات: $totalOrders');
      debugPrint('   الطلبات المكتملة: $completedOrders');
      debugPrint('   الطلبات الملغية: $cancelledOrders');
      debugPrint('   الطلبات المعلقة: $pendingOrders');
      debugPrint('   إجمالي الأرباح المحققة: $totalProfits');

      return {
        'total_orders': totalOrders,
        'completed_orders': completedOrders,
        'cancelled_orders': cancelledOrders,
        'pending_orders': pendingOrders,
        'total_profits': totalProfits,
      };
    } catch (e) {
      debugPrint('❌ خطأ في حساب إحصائيات المستخدم: $e');
      return {'total_orders': 0, 'completed_orders': 0, 'cancelled_orders': 0, 'pending_orders': 0, 'total_sales': 0.0};
    }
  }

  // جلب مستخدم واحد بالتفصيل
  static Future<AdminUser?> getUserById(String userId) async {
    try {
      debugPrint('🔄 جلب تفاصيل المستخدم: $userId');

      final response = await _supabase.from('users').select('*').eq('id', userId).single();

      // حساب الإحصائيات الحقيقية للمستخدم
      final ordersStats = await _getUserOrdersStats(userId);

      debugPrint('✅ تم جلب تفاصيل المستخدم');
      debugPrint('📊 البيانات الخام: ${response.toString()}');
      debugPrint('🔐 كلمة المرور في البيانات: ${response['password']}');
      debugPrint('📈 الإحصائيات: ${ordersStats.toString()}');

      final combinedData = {...response, ...ordersStats};
      debugPrint('📋 البيانات المدمجة: ${combinedData.toString()}');

      final user = AdminUser.fromJson(combinedData);
      debugPrint('👤 المستخدم النهائي - كلمة المرور: ${user.password}');

      return user;
    } catch (e) {
      debugPrint('❌ خطأ في جلب تفاصيل المستخدم: $e');
      return null;
    }
  }

  // جلب إحصائيات المستخدمين العامة
  static Future<UserStatistics> getUserStatistics() async {
    try {
      debugPrint('🔄 جلب إحصائيات المستخدمين...');

      // جلب إحصائيات المستخدمين (استخدام الأعمدة الموجودة فقط)
      final usersResponse = await _supabase.from('users').select('id, is_active, is_admin, created_at, last_login');

      // جلب إحصائيات الطلبات (جلب جميع الطلبات)
      final ordersResponse = await _supabase.from('orders').select('status, total, created_at');

      debugPrint('📊 تم جلب ${ordersResponse.length} طلب من قاعدة البيانات');

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekAgo = today.subtract(const Duration(days: 7));
      final monthAgo = DateTime(now.year, now.month - 1, now.day);

      // حساب إحصائيات المستخدمين
      final totalUsers = usersResponse.length;
      final activeUsers = usersResponse.where((u) => u['is_active'] == true).length;
      final inactiveUsers = totalUsers - activeUsers;
      final adminUsers = usersResponse.where((u) => u['is_admin'] == true).length;
      final regularUsers = totalUsers - adminUsers;
      // تعيين قيم افتراضية للمستخدمين المعتمدين (لأن العمود قد لا يكون موجود)
      final verifiedUsers = totalUsers; // افتراض أن جميع المستخدمين معتمدين
      final unverifiedUsers = 0;

      // حساب التسجيلات
      final todayRegistrations = usersResponse.where((u) {
        final createdAt = DateTime.parse(u['created_at']);
        return createdAt.isAfter(today);
      }).length;

      final weekRegistrations = usersResponse.where((u) {
        final createdAt = DateTime.parse(u['created_at']);
        return createdAt.isAfter(weekAgo);
      }).length;

      final monthRegistrations = usersResponse.where((u) {
        final createdAt = DateTime.parse(u['created_at']);
        return createdAt.isAfter(monthAgo);
      }).length;

      // حساب المستخدمين المتصلين (آخر دخول خلال ساعة)
      final onlineUsers = usersResponse.where((u) {
        if (u['last_login'] == null) return false;
        final lastLogin = DateTime.parse(u['last_login']);
        return now.difference(lastLogin).inHours < 1;
      }).length;

      // حساب إحصائيات الطلبات
      final totalOrders = ordersResponse.length;
      final completedOrders = ordersResponse.where((o) => o['status'] == 'delivered').length;
      final cancelledOrders = ordersResponse.where((o) => o['status'] == 'cancelled').length;
      final pendingOrders = ordersResponse.where((o) => o['status'] == 'active' || o['status'] == 'in_delivery').length;

      final totalProfits = ordersResponse
          .where((o) => o['status'] == 'delivered')
          .fold<double>(0.0, (sum, o) => sum + (o['profit'] ?? 0.0));

      final averageProfitPerOrder = completedOrders > 0 ? totalProfits / completedOrders : 0.0;

      debugPrint('📊 إحصائيات الطلبات:');
      debugPrint('   إجمالي الطلبات: $totalOrders');
      debugPrint('   الطلبات المكتملة: $completedOrders');
      debugPrint('   الطلبات الملغية: $cancelledOrders');
      debugPrint('   الطلبات المعلقة: $pendingOrders');
      debugPrint('   إجمالي الأرباح المحققة: $totalProfits');
      debugPrint('   متوسط الربح لكل طلب: $averageProfitPerOrder');

      debugPrint('✅ تم حساب الإحصائيات');

      return UserStatistics(
        totalUsers: totalUsers,
        activeUsers: activeUsers,
        inactiveUsers: inactiveUsers,
        adminUsers: adminUsers,
        regularUsers: regularUsers,
        verifiedUsers: verifiedUsers,
        unverifiedUsers: unverifiedUsers,
        onlineUsers: onlineUsers,
        todayRegistrations: todayRegistrations,
        weekRegistrations: weekRegistrations,
        monthRegistrations: monthRegistrations,
        totalSales: totalProfits,
        averageOrderValue: averageProfitPerOrder,
        totalOrders: totalOrders,
        completedOrders: completedOrders,
        cancelledOrders: cancelledOrders,
        pendingOrders: pendingOrders,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ خطأ في جلب الإحصائيات: $e');
      throw Exception('فشل في جلب إحصائيات المستخدمين: $e');
    }
  }

  // إعادة حساب الإحصائيات لجميع المستخدمين
  static Future<void> recalculateAllUserStats() async {
    try {
      debugPrint('🔄 إعادة حساب إحصائيات جميع المستخدمين...');

      // أولاً: إصلاح ربط الطلبات بالمستخدمين
      await _fixOrderUserLinks();

      // جلب جميع المستخدمين
      final users = await _supabase.from('users').select('id, name');

      int updatedCount = 0;
      for (final user in users) {
        try {
          final stats = await _getUserOrdersStats(user['id']);
          debugPrint('📊 المستخدم ${user['name']}: ${stats['total_orders']} طلب');
          updatedCount++;
        } catch (e) {
          debugPrint('❌ خطأ في حساب إحصائيات ${user['name']}: $e');
        }
      }

      debugPrint('✅ تم إعادة حساب إحصائيات $updatedCount مستخدم');
    } catch (e) {
      debugPrint('❌ خطأ في إعادة حساب الإحصائيات: $e');
    }
  }

  // إصلاح ربط الطلبات بالمستخدمين
  static Future<void> _fixOrderUserLinks() async {
    try {
      debugPrint('🔧 إصلاح ربط الطلبات بالمستخدمين...');

      // جلب جميع المستخدمين
      final users = await _supabase.from('users').select('id, name, phone');

      // جلب جميع الطلبات
      final allOrders = await _supabase.from('orders').select('id, customer_name, customer_phone, customer_id');

      // فلترة الطلبات التي لا تحتوي على customer_id
      final ordersWithoutCustomerId = allOrders.where((order) => order['customer_id'] == null).toList();

      debugPrint('🔍 وُجد ${ordersWithoutCustomerId.length} طلب بدون customer_id');

      int fixedCount = 0;
      for (final order in ordersWithoutCustomerId) {
        // البحث عن المستخدم المطابق
        Map<String, dynamic>? matchingUser;
        try {
          matchingUser = users.firstWhere(
            (user) => user['name'] == order['customer_name'] || user['phone'] == order['customer_phone'],
          );
        } catch (e) {
          matchingUser = null;
        }

        if (matchingUser != null) {
          try {
            await _supabase.from('orders').update({'customer_id': matchingUser['id']}).eq('id', order['id']);
            fixedCount++;
          } catch (e) {
            debugPrint('⚠️ فشل في تحديث الطلب ${order['id']}: $e');
          }
        }
      }

      debugPrint('✅ تم إصلاح $fixedCount طلب');
    } catch (e) {
      debugPrint('❌ خطأ في إصلاح ربط الطلبات: $e');
    }
  }

  // دالة عامة لإصلاح ربط الطلبات (يمكن استدعاؤها من صفحة التشخيص)
  static Future<Map<String, dynamic>> fixOrderUserLinks() async {
    try {
      debugPrint('🔧 بدء إصلاح ربط الطلبات بالمستخدمين...');

      // جلب جميع المستخدمين
      final users = await _supabase.from('users').select('id, name, phone');

      // جلب جميع الطلبات
      final allOrders = await _supabase.from('orders').select('id, customer_name, customer_phone, customer_id');

      debugPrint('📊 إجمالي الطلبات: ${allOrders.length}');
      debugPrint('📊 إجمالي المستخدمين: ${users.length}');

      int fixedCount = 0;
      int alreadyLinkedCount = 0;
      int notFoundCount = 0;

      for (final order in allOrders) {
        if (order['customer_id'] != null) {
          alreadyLinkedCount++;
          continue;
        }

        // البحث عن المستخدم المطابق
        Map<String, dynamic>? matchingUser;
        try {
          matchingUser = users.firstWhere(
            (user) =>
                (user['name'] != null && user['name'] == order['customer_name']) ||
                (user['phone'] != null && user['phone'] == order['customer_phone']),
          );
        } catch (e) {
          matchingUser = null;
        }

        if (matchingUser != null) {
          try {
            await _supabase.from('orders').update({'customer_id': matchingUser['id']}).eq('id', order['id']);
            fixedCount++;
            debugPrint('✅ ربط الطلب ${order['id']} بالمستخدم ${matchingUser['name']}');
          } catch (e) {
            debugPrint('⚠️ فشل في تحديث الطلب ${order['id']}: $e');
          }
        } else {
          notFoundCount++;
          debugPrint('⚠️ لم يتم العثور على مستخدم للطلب: ${order['customer_name']} - ${order['customer_phone']}');
        }
      }

      final result = {
        'total_orders': allOrders.length,
        'already_linked': alreadyLinkedCount,
        'fixed_count': fixedCount,
        'not_found_count': notFoundCount,
        'success': true,
      };

      debugPrint('✅ تم إصلاح ربط الطلبات:');
      debugPrint('   إجمالي الطلبات: ${result['total_orders']}');
      debugPrint('   مربوطة مسبقاً: ${result['already_linked']}');
      debugPrint('   تم إصلاحها: ${result['fixed_count']}');
      debugPrint('   لم يتم العثور على مستخدم: ${result['not_found_count']}');

      return result;
    } catch (e) {
      debugPrint('❌ خطأ في إصلاح ربط الطلبات: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ===== إدارة المستخدمين =====

  // إضافة مستخدم جديد
  static Future<AdminUser?> createUser({
    required String name,
    required String phone,
    required String email,
    required String password,
    bool isAdmin = false,
    String? province,
    String? city,
    String? address,
    String? notes,
  }) async {
    try {
      debugPrint('🔄 إنشاء مستخدم جديد: $name');

      // تشفير كلمة المرور (يجب استخدام bcrypt في الإنتاج)
      final passwordHash = _hashPassword(password);

      // إنشاء البيانات الأساسية فقط (الأعمدة الموجودة في الجدول)
      final userData = {
        'name': name,
        'phone': phone,
        'email': email,
        'password_hash': passwordHash,
        'is_admin': isAdmin,
      };

      // إضافة الحقول الاختيارية فقط إذا كانت موجودة في الجدول
      // سنحاول إضافتها ولكن لن نفشل إذا لم تكن موجودة
      if (province != null && province.isNotEmpty) {
        userData['province'] = province;
      }
      if (city != null && city.isNotEmpty) {
        userData['city'] = city;
      }
      if (address != null && address.isNotEmpty) {
        userData['address'] = address;
      }
      if (notes != null && notes.isNotEmpty) {
        userData['notes'] = notes;
      }

      final response = await _supabase.from('users').insert(userData).select().single();

      debugPrint('✅ تم إنشاء المستخدم بنجاح');
      return AdminUser.fromJson({
        ...response,
        'total_orders': 0,
        'completed_orders': 0,
        'cancelled_orders': 0,
        'pending_orders': 0,
        'total_sales': 0.0,
        // إضافة القيم الافتراضية للحقول المفقودة
        'province': response['province'] ?? province ?? '',
        'city': response['city'] ?? city ?? '',
        'address': response['address'] ?? address ?? '',
        'notes': response['notes'] ?? notes ?? '',
      });
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء المستخدم: $e');

      // إذا فشل، جرب بالحقول الأساسية فقط
      try {
        debugPrint('🔄 محاولة إنشاء المستخدم بالحقول الأساسية فقط...');

        final basicUserData = {
          'name': name,
          'phone': phone,
          'email': email,
          'password_hash': _hashPassword(password),
          'is_admin': isAdmin,
        };

        final response = await _supabase.from('users').insert(basicUserData).select().single();

        debugPrint('✅ تم إنشاء المستخدم بالحقول الأساسية');
        return AdminUser.fromJson({
          ...response,
          'total_orders': 0,
          'completed_orders': 0,
          'cancelled_orders': 0,
          'pending_orders': 0,
          'total_sales': 0.0,
          'province': province ?? '',
          'city': city ?? '',
          'address': address ?? '',
          'notes': notes ?? '',
        });
      } catch (e2) {
        debugPrint('❌ فشل في إنشاء المستخدم حتى بالحقول الأساسية: $e2');
        throw Exception('فشل في إنشاء المستخدم: $e2');
      }
    }
  }

  // تحديث بيانات المستخدم
  static Future<AdminUser?> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      debugPrint('🔄 تحديث بيانات المستخدم: $userId');

      // تشفير كلمة المرور إذا تم تحديثها
      if (updates.containsKey('password') && updates['password'] != null) {
        String password = updates['password'].toString();
        if (password.isNotEmpty) {
          // تشفير كلمة المرور بـ SHA256
          String hashedPassword = _hashPassword(password);
          updates['password_hash'] = hashedPassword;
          debugPrint('🔐 تم تشفير كلمة المرور الجديدة');
        }
      }

      // إضافة تاريخ التحديث
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase.from('users').update(updates).eq('id', userId).select().single();

      debugPrint('✅ تم تحديث بيانات المستخدم');

      // حساب الإحصائيات للمستخدم المحدث
      final ordersStats = await _getUserOrdersStats(userId);

      return AdminUser.fromJson({...response, ...ordersStats});
    } catch (e) {
      debugPrint('❌ خطأ في تحديث المستخدم: $e');
      throw Exception('فشل في تحديث بيانات المستخدم: $e');
    }
  }

  // دالة تشفير كلمة المرور
  static String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // تعطيل/تفعيل المستخدم
  static Future<bool> toggleUserStatus(String userId, bool isActive) async {
    try {
      debugPrint('🔄 ${isActive ? 'تفعيل' : 'تعطيل'} المستخدم: $userId');

      await _supabase
          .from('users')
          .update({'is_active': isActive, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', userId);

      debugPrint('✅ تم ${isActive ? 'تفعيل' : 'تعطيل'} المستخدم');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في تغيير حالة المستخدم: $e');
      return false;
    }
  }

  // حذف المستخدم
  static Future<bool> deleteUser(String userId) async {
    try {
      debugPrint('🔄 حذف المستخدم: $userId');

      await _supabase.from('users').delete().eq('id', userId);

      debugPrint('✅ تم حذف المستخدم');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في حذف المستخدم: $e');
      return false;
    }
  }

  // تغيير كلمة المرور
  static Future<bool> changeUserPassword(String userId, String newPassword) async {
    try {
      debugPrint('🔄 تغيير كلمة مرور المستخدم: $userId');

      final passwordHash = _hashPassword(newPassword);

      await _supabase
          .from('users')
          .update({
            'password_hash': passwordHash,
            'password_changed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      debugPrint('✅ تم تغيير كلمة المرور');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في تغيير كلمة المرور: $e');
      return false;
    }
  }

  // ===== دوال مساعدة =====

  // البحث في المستخدمين
  static Future<List<AdminUser>> searchUsers(String query) async {
    try {
      debugPrint('🔍 البحث في المستخدمين: $query');

      final response = await _supabase
          .from('users')
          .select('*')
          .or('name.ilike.%$query%,phone.ilike.%$query%,email.ilike.%$query%')
          .limit(20);

      debugPrint('✅ تم العثور على ${response.length} نتيجة');

      // إضافة الإحصائيات لكل مستخدم
      List<AdminUser> users = [];
      for (var userData in response) {
        final ordersStats = await _getUserOrdersStats(userData['id'].toString());
        users.add(AdminUser.fromJson({...userData, ...ordersStats}));
      }

      return users;
    } catch (e) {
      debugPrint('❌ خطأ في البحث: $e');
      return [];
    }
  }

  // جلب المستخدمين المتصلين حالياً
  static Future<List<AdminUser>> getOnlineUsers() async {
    try {
      debugPrint('🔄 جلب المستخدمين المتصلين...');

      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));

      final response = await _supabase
          .from('users')
          .select('*')
          .gte('last_login', oneHourAgo.toIso8601String())
          .order('last_login', ascending: false);

      debugPrint('✅ تم جلب ${response.length} مستخدم متصل');

      // إضافة الإحصائيات لكل مستخدم
      List<AdminUser> users = [];
      for (var userData in response) {
        final ordersStats = await _getUserOrdersStats(userData['id'].toString());
        users.add(AdminUser.fromJson({...userData, ...ordersStats}));
      }

      return users;
    } catch (e) {
      debugPrint('❌ خطأ في جلب المستخدمين المتصلين: $e');
      return [];
    }
  }

  // تحديث أرباح المستخدم عبر دالة قاعدة البيانات الآمنة
  static Future<bool> updateUserProfits(
    String userId,
    double achievedProfits,
    double expectedProfits, {
    String? reason,
  }) async {
    try {
      debugPrint('🔄 تحديث أرباح المستخدم عبر admin_update_user_profits: $userId');

      final result = await _supabase.rpc(
        'admin_update_user_profits',
        params: {
          'p_user_id': userId,
          'p_new_expected': expectedProfits,
          'p_new_achieved': achievedProfits,
          'p_reason': reason ?? 'Manual adjustment from admin panel',
        },
      );

      if (result is Map && result['success'] == true) {
        debugPrint('✅ تم تحديث الأرباح بنجاح (RPC)');
        return true;
      } else {
        debugPrint('❌ فشل في تحديث الأرباح عبر RPC: $result');
        return false;
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحديث الأرباح عبر RPC: $e');
      return false;
    }
  }

  // جلب المستخدمين الجدد
  static Future<List<AdminUser>> getNewUsers({int days = 7}) async {
    try {
      debugPrint('🔄 جلب المستخدمين الجدد...');

      final daysAgo = DateTime.now().subtract(Duration(days: days));

      final response = await _supabase
          .from('users')
          .select('*')
          .gte('created_at', daysAgo.toIso8601String())
          .order('created_at', ascending: false);

      debugPrint('✅ تم جلب ${response.length} مستخدم جديد');

      // إضافة الإحصائيات لكل مستخدم
      List<AdminUser> users = [];
      for (var userData in response) {
        final ordersStats = await _getUserOrdersStats(userData['id'].toString());
        users.add(AdminUser.fromJson({...userData, ...ordersStats}));
      }

      return users;
    } catch (e) {
      debugPrint('❌ خطأ في جلب المستخدمين الجدد: $e');
      return [];
    }
  }
}
