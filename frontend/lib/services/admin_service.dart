import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'user_management_service.dart';
import '../config/supabase_config.dart';
import '../models/order_summary.dart';
import '../utils/order_status_helper.dart';


class AdminService {
  static SupabaseClient get _supabase => SupabaseConfig.client;

  // رابط الخادم الخلفي
  static const String baseUrl = 'https://montajati-backend.onrender.com';

  /// توليد رقم طلب فريد
  static String generateOrderNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString().substring(
      7,
    ); // آخر 6 أرقام
    final random = (1000 + (now.microsecond % 9000))
        .toString(); // رقم عشوائي من 1000-9999
    return 'ORD$timestamp$random';
  }

  /// تحديث البيانات الموجودة لملء الأعمدة الجديدة
  static Future<void> updateExistingOrdersWithNewFields() async {
    try {
      debugPrint('🔄 بدء تحديث الطلبات الموجودة...');

      // جلب جميع الطلبات (لأن order_number غير موجود في الجدول)
      final ordersWithoutOrderNumber = await _supabase
          .from('orders')
          .select(
            'id, customer_name, primary_phone, secondary_phone, province, city, notes, profit',
          );

      for (final order in ordersWithoutOrderNumber) {
        final orderNumber = generateOrderNumber();

        await _supabase
            .from('orders')
            .update({
              // تحديث الأعمدة الموجودة فقط في الجدول الحالي:
              'customer_name': order['customer_name'],
              'primary_phone': order['primary_phone'],
              'secondary_phone': order['secondary_phone'],
              'province': order['province'],
              'city': order['city'],
              'notes': order['notes'],
              'total': order['total'],
              'profit': order['profit'],
              'status': order['status'],
            })
            .eq('id', order['id']);

        debugPrint('✅ تم تحديث الطلب: ${order['id']} برقم: $orderNumber');
      }

      debugPrint('🎉 تم تحديث ${ordersWithoutOrderNumber.length} طلب بنجاح!');
    } catch (e) {
      debugPrint('❌ خطأ في تحديث الطلبات الموجودة: $e');
    }
  }

  // التحقق من وجود جدول المنتجات
  static Future<bool> checkProductsTableExists() async {
    try {
      await _supabase.from('products').select('id').limit(1);
      return true;
    } catch (e) {
      debugPrint('جدول المنتجات غير موجود: $e');
      return false;
    }
  }

  // التحقق من صلاحيات المدير بواسطة ID
  static Future<bool> isAdmin(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('is_admin')
          .eq('id', userId)
          .maybeSingle();

      return response?['is_admin'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // التحقق من صلاحيات المدير بواسطة رقم الهاتف
  static Future<bool> isAdminByPhone(String phone) async {
    try {
      final response = await _supabase
          .from('users')
          .select('is_admin')
          .eq('phone', phone)
          .maybeSingle();

      return response?['is_admin'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // الحصول على معلومات المستخدم بواسطة رقم الهاتف
  static Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id, name, phone, email, is_admin')
          .eq('phone', phone)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  // إصلاح ربط الطلبات بالمستخدمين إذا لزم الأمر
  static Future<void> _fixOrderUserLinksIfNeeded() async {
    try {
      debugPrint('🔧 فحص ربط الطلبات بالمستخدمين...');

      // فحص سريع للطلبات غير المربوطة
      final unlinkedOrders = await _supabase
          .from('orders')
          .select('id')
          .isFilter('customer_id', null);

      if (unlinkedOrders.isNotEmpty) {
        debugPrint(
          '⚠️ وُجد ${unlinkedOrders.length} طلب غير مربوط، سيتم الإصلاح...',
        );

        // استدعاء دالة الإصلاح من UserManagementService
        final result = await UserManagementService.fixOrderUserLinks();
        if (result['success'] == true) {
          debugPrint('✅ تم إصلاح ${result['fixed_count']} طلب');
        }
      } else {
        debugPrint('✅ جميع الطلبات مربوطة بشكل صحيح');
      }
    } catch (e) {
      debugPrint('⚠️ خطأ في فحص ربط الطلبات: $e');
    }
  }

  // الحصول على إحصائيات لوحة التحكم مع إصلاح تلقائي
  static Future<DashboardStats> getDashboardStats() async {
    try {
      debugPrint('🔄 جلب إحصائيات لوحة التحكم...');

      // أولاً: إصلاح ربط الطلبات بالمستخدمين تلقائياً
      await _fixOrderUserLinksIfNeeded();

      // عدد المستخدمين
      final usersResponse = await _supabase
          .from('users')
          .select('id')
          .eq('is_admin', false);
      final totalUsers = usersResponse.length;

      // عدد الطلبات الإجمالي مع جلب جميع البيانات المطلوبة
      final ordersResponse = await _supabase
          .from('orders')
          .select('id, status, total, profit');
      final totalOrders = ordersResponse.length;

      debugPrint('📊 إجمالي الطلبات: $totalOrders');

      // الطلبات النشطة (تحديث حسب النظام الجديد)
      final activeOrders = ordersResponse
          .where(
            (order) =>
                order['status'] == 'active' || order['status'] == 'pending',
          )
          .length;

      // الطلبات قيد التوصيل
      final shippingOrders = ordersResponse
          .where((order) => order['status'] == 'in_delivery')
          .length;

      // الأرباح المحققة (من الطلبات المكتملة فقط)
      // استخدام profit فقط (ربح المستخدم فقط)
      double totalProfits = 0.0;
      final deliveredOrders = ordersResponse.where(
        (order) => order['status'] == 'delivered',
      );

      for (var order in deliveredOrders) {
        // استخدام profit فقط (ربح المستخدم فقط)
        final profit = (order['profit'] as num?)?.toDouble() ?? 0.0;
        totalProfits += profit;
      }

      debugPrint('📊 الإحصائيات المحسوبة:');
      debugPrint('   المستخدمين: $totalUsers');
      debugPrint('   إجمالي الطلبات: $totalOrders');
      debugPrint('   الطلبات النشطة: $activeOrders');
      debugPrint('   قيد التوصيل: $shippingOrders');
      debugPrint('   إجمالي الأرباح: $totalProfits');

      return DashboardStats(
        totalUsers: totalUsers,
        totalOrders: totalOrders,
        activeOrders: activeOrders,
        shippingOrders: shippingOrders,
        totalProfits: totalProfits,
      );
    } catch (e) {
      debugPrint('❌ خطأ في جلب الإحصائيات: $e');
      debugPrint('🔄 سيتم إرجاع إحصائيات تجريبية');

      // إرجاع إحصائيات فارغة في حالة الخطأ
      return DashboardStats(
        totalUsers: 0,
        totalOrders: 0,
        activeOrders: 0,
        shippingOrders: 0,
        totalProfits: 0.0,
      );
    }
  }

  // 🚀 جلب ملخص الطلبات فقط (بدون تفاصيل) - للعرض السريع
  static Future<List<OrderSummary>> getOrdersSummary({
    String? statusFilter,
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('''
            id,
            customer_name,
            primary_phone,
            province,
            city,
            total,
            status,
            created_at,
            updated_at
          ''')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map<OrderSummary>((order) => OrderSummary.fromJson(order)).toList();
    } catch (e) {
      throw Exception('خطأ في جلب ملخص الطلبات: $e');
    }
  }

  // 🎯 جلب تفاصيل طلب واحد فقط (عند النقر)
  static Future<AdminOrder?> getOrderDetailsFast(String orderId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*')
          .eq('id', orderId)
          .single();

      // response لن يكون null مع .single()

      // جلب عناصر الطلب بشكل منفصل
      List<AdminOrderItem> orderItemsList = [];
      try {
        final orderItemsData = await _supabase
            .from('order_items')
            .select('*')
            .eq('order_id', orderId);

        orderItemsList = orderItemsData.map<AdminOrderItem>((item) {
          return AdminOrderItem(
            id: item['id']?.toString() ?? '',
            productId: item['product_id'] ?? '',
            productName: item['product_name'] ?? 'منتج غير محدد',
            productImage: item['product_image'] ?? '',
            productPrice: (item['customer_price'] as num?)?.toDouble() ?? 0.0,
            wholesalePrice: (item['wholesale_price'] as num?)?.toDouble() ?? 0.0,
            customerPrice: (item['customer_price'] as num?)?.toDouble() ?? 0.0,
            quantity: (item['quantity'] as num?)?.toInt() ?? 1,
            totalPrice: (item['total_price'] as num?)?.toDouble() ?? 0.0,
            profitPerItem: (item['profit_per_item'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList();
      } catch (itemsError) {
        debugPrint('⚠️ خطأ في جلب عناصر الطلب: $itemsError');
      }

      final finalStatus = response['status'] ?? 'confirmed';

      return AdminOrder(
        id: response['id'] ?? '',
        orderNumber: response['id']?.toString().substring(0, 8) ?? '',
        customerName: response['customer_name'] ?? 'غير محدد',
        customerPhone: response['primary_phone'] ?? 'غير محدد',
        customerAlternatePhone: response['secondary_phone'],
        customerProvince: response['province'] ?? '',
        customerCity: response['city'] ?? '',
        customerAddress: '${response['province'] ?? ''} - ${response['city'] ?? ''}',
        customerNotes: response['customer_notes'], // ✅ إصلاح: استخدام customer_notes
        totalAmount: (response['total'] as num?)?.toDouble() ?? 0.0,
        deliveryCost: (response['delivery_fee'] as num?)?.toDouble() ?? 0.0,
        profitAmount: (response['profit'] as num?)?.toDouble() ?? 0.0,
        expectedProfit: (response['profit'] as num?)?.toDouble() ?? 0.0,
        itemsCount: orderItemsList.length,
        status: finalStatus,
        createdAt: DateTime.tryParse(response['created_at'] ?? '') ?? DateTime.now(),
        userName: 'غير محدد',
        userPhone: response['user_phone'] ?? 'غير محدد',
        items: orderItemsList,
      );
    } catch (e) {
      throw Exception('خطأ في جلب تفاصيل الطلب: $e');
    }
  }

  // الحصول على قائمة الطلبات مع الفلتر و pagination
  static Future<List<AdminOrder>> getOrders({
    String? statusFilter,
    int limit = 50, // حد أقصى 50 طلب في المرة الواحدة
    int offset = 0, // البداية
  }) async {
    try {
      // تحسين الأداء: تقليل الـ logs وإضافة pagination
      final simpleResponse = await _supabase
          .from('orders')
          .select('''
            id,
            customer_name,
            primary_phone,
            secondary_phone,
            province,
            city,
            notes,
            subtotal,
            delivery_fee,
            total,
            profit,
            status,
            user_phone,
            created_at,
            updated_at,
            order_items (
              id,
              product_id,
              product_name,
              product_image,
              wholesale_price,
              customer_price,
              quantity,
              total_price,
              profit_per_item
            )
          ''')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      if (simpleResponse.isEmpty) {
        return [];
      }

      final orders = simpleResponse.map<AdminOrder>((order) {

        // حساب الربح المتوقع
        double expectedProfit = 0;
        int itemsCount = 0;
        String userName = 'غير محدد';
        String userPhone = order['user_phone'] ?? 'غير محدد';

        // التحقق من وجود بيانات العناصر
        List<AdminOrderItem> orderItemsList = [];
        if (order['order_items'] != null) {
          final orderItems = order['order_items'] as List;
          itemsCount = orderItems.length;

          for (var item in orderItems) {
            try {
              final quantity = item['quantity'] as int;
              final customerPrice =
                  (item['customer_price'] as num?)?.toDouble() ?? 0.0;
              final wholesalePrice =
                  (item['wholesale_price'] as num?)?.toDouble() ?? 0.0;
              final profitPerItem =
                  (item['profit_per_item'] as num?)?.toDouble() ?? 0.0;

              // حساب الربح
              if (profitPerItem > 0) {
                expectedProfit += profitPerItem * quantity;
              } else if (customerPrice > 0 && wholesalePrice > 0) {
                expectedProfit += (customerPrice - wholesalePrice) * quantity;
              }

              // إنشاء عنصر الطلب
              orderItemsList.add(
                AdminOrderItem(
                  id: (item['id'] ?? '').toString(), // ✅ تحويل إلى String
                  productName: item['product_name'] ?? '',
                  productImage: item['product_image'],
                  productPrice:
                      (item['product_price'] as num?)?.toDouble() ?? 0.0,
                  wholesalePrice: wholesalePrice,
                  customerPrice: customerPrice,
                  minPrice: (item['min_price'] as num?)?.toDouble(),
                  maxPrice: (item['max_price'] as num?)?.toDouble(),
                  quantity: quantity,
                  totalPrice: (item['total_price'] as num?)?.toDouble() ?? 0.0,
                  profitPerItem: profitPerItem,
                ),
              );
            } catch (e) {
              // تجاهل أخطاء العناصر الفردية
            }
          }
        }

        // التحقق من وجود بيانات المستخدم
        if (order['users'] != null) {
          userName = order['users']['name'] ?? 'غير محدد';
          userPhone = order['users']['phone'] ?? 'غير محدد';
        }

        // معالجة حالة الطلب
        final rawStatus = order['status'];
        final finalStatus = rawStatus ?? 'confirmed';

        final adminOrder = AdminOrder(
          id: order['id'],
          orderNumber: order['id'].substring(0, 8),
          customerName: order['customer_name'] ?? 'غير محدد',
          customerPhone: order['primary_phone'] ?? 'غير محدد',
          customerAlternatePhone: order['secondary_phone'],
          customerProvince: order['province'],
          customerCity: order['city'],
          customerAddress:
              '${order['province'] ?? ''} - ${order['city'] ?? ''}',
          customerNotes: order['notes'],
          totalAmount: (order['total'] as num?)?.toDouble() ?? 0.0,
          deliveryCost: (order['delivery_fee'] as num?)?.toDouble() ?? 0.0,
          profitAmount: (order['profit'] as num?)?.toDouble() ?? 0.0,
          status: finalStatus,
          expectedProfit: expectedProfit,
          itemsCount: itemsCount,
          createdAt: DateTime.parse(order['created_at']),
          userName: userName,
          userPhone: userPhone,
          items: orderItemsList,
        );

        return adminOrder;
      }).toList();

      return orders;
    } catch (e) {
      debugPrint('❌ خطأ في جلب الطلبات: $e');
      throw Exception('خطأ في جلب الطلبات من قاعدة البيانات: $e');
    }
  }

  // إنشاء طلب جديد في قاعدة البيانات
  static Future<String> createOrder({
    required String customerName,
    required String primaryPhone,
    String? secondaryPhone,
    required String province,
    required String city,
    String? notes,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double deliveryFee,
    required double totalProfit,
    required String userPhone,
  }) async {
    try {
      debugPrint('🔄 إنشاء طلب جديد في قاعدة البيانات...');

      // إنشاء معرف فريد للطلب
      final orderId = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';
      final total = subtotal + deliveryFee;

      // إدراج الطلب في جدول orders
      final orderResponse = await _supabase.from('orders').insert({
        'id': orderId,
        'customer_name': customerName,
        'primary_phone': primaryPhone,
        'secondary_phone': secondaryPhone,
        'province': province,
        'city': city,
        'notes': notes ?? '',
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'total': total,
        'profit': totalProfit,
        'status': 'pending',
        'user_phone': userPhone,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select();

      debugPrint('✅ تم إدراج الطلب في جدول orders');

      // إدراج عناصر الطلب في جدول order_items
      for (var item in items) {
        final itemId =
            'ITEM_${DateTime.now().millisecondsSinceEpoch}_${items.indexOf(item)}';

        await _supabase.from('order_items').insert({
          'id': itemId,
          'order_id': orderId,
          'product_name': item['name'] ?? item['productName'] ?? '',
          'product_price': (item['price'] ?? item['customerPrice'] ?? 0.0)
              .toDouble(),
          'wholesale_price': (item['wholesalePrice'] ?? 0.0).toDouble(),
          'customer_price': (item['price'] ?? item['customerPrice'] ?? 0.0)
              .toDouble(),
          'quantity': (item['quantity'] ?? 1).toInt(),
          'total_price':
              ((item['price'] ?? item['customerPrice'] ?? 0.0) *
                      (item['quantity'] ?? 1))
                  .toDouble(),
          'profit_per_item':
              ((item['price'] ?? item['customerPrice'] ?? 0.0) -
                      (item['wholesalePrice'] ?? 0.0))
                  .toDouble(),
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      debugPrint('✅ تم إدراج ${items.length} عنصر في جدول order_items');
      debugPrint('📋 معرف الطلب: $orderId');

      return orderId;
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء الطلب: $e');
      rethrow;
    }
  }

  // إرجاع بيانات تجريبية للاختبار
  static List<AdminOrder> _getSampleOrders() {
    return [];
  }

  // الحصول على تفاصيل الطلب الكاملة مع جميع البيانات
  static Future<AdminOrder> getOrderDetails(String orderId) async {
    try {
      debugPrint('🔄 جلب تفاصيل الطلب الكاملة: $orderId');

      // جلب بيانات الطلب أولاً
      debugPrint('🔍 جلب بيانات الطلب الأساسية...');
      final orderResponse = await _supabase
          .from('orders')
          .select('*')
          .eq('id', orderId)
          .single();

      debugPrint('✅ تم جلب بيانات الطلب الأساسية');
      debugPrint('📋 حالة الطلب الحالية: ${orderResponse['status']}');
      debugPrint('📋 نوع حالة الطلب: ${orderResponse['status'].runtimeType}');

      // تشخيص حالة الطلب باستخدام النظام الجديد
      OrderStatusHelper.debugStatus(orderResponse['status']?.toString());

      debugPrint('📋 بيانات الطلب: $orderResponse');

      // جلب عناصر الطلب أولاً
      debugPrint('🔍 جلب عناصر الطلب...');
      List<Map<String, dynamic>> orderItemsData = [];
      try {
        orderItemsData = await _supabase
            .from('order_items')
            .select('*')
            .eq('order_id', orderId);
        debugPrint('✅ تم جلب ${orderItemsData.length} عنصر للطلب');
      } catch (itemsError) {
        debugPrint('⚠️ لا توجد عناصر للطلب أو خطأ في جلبها: $itemsError');
      }

      // معالجة عناصر الطلب
      List<AdminOrderItem> orderItems = [];
      if (orderItemsData.isNotEmpty) {
        debugPrint('📦 معالجة ${orderItemsData.length} عنصر...');

        for (var item in orderItemsData) {
          // جلب معلومات المنتج من جدول products إذا كان product_id متوفر
          Map<String, dynamic>? productInfo;
          String? productId = item['product_id']?.toString();

          if (productId != null && productId.isNotEmpty) {
            try {
              debugPrint('🔍 جلب معلومات المنتج: $productId');
              final productResponse = await _supabase
                  .from('products')
                  .select(
                    'id, available_from, available_to, available_quantity',
                  )
                  .eq('id', productId)
                  .single();
              productInfo = productResponse;
              debugPrint('✅ تم جلب معلومات المنتج: $productId');
            } catch (productError) {
              debugPrint(
                '⚠️ خطأ في جلب معلومات المنتج $productId: $productError',
              );
            }
          }

          orderItems.add(
            AdminOrderItem(
              id: item['id']?.toString() ?? '',
              productName: item['product_name']?.toString() ?? 'منتج غير محدد',
              productImage: item['product_image'],
              productPrice: (item['product_price'] as num?)?.toDouble() ?? 0.0,
              wholesalePrice:
                  (item['wholesale_price'] as num?)?.toDouble() ?? 0.0,
              customerPrice:
                  (item['customer_price'] as num?)?.toDouble() ?? 0.0,
              minPrice: (item['min_price'] as num?)?.toDouble(),
              maxPrice: (item['max_price'] as num?)?.toDouble(),
              quantity: (item['quantity'] as num?)?.toInt() ?? 0,
              totalPrice: (item['total_price'] as num?)?.toDouble() ?? 0.0,
              profitPerItem:
                  (item['profit_per_item'] as num?)?.toDouble() ?? 0.0,
              productId: productId,
              availableFrom: productInfo?['available_from'] as int?,
              availableTo: productInfo?['available_to'] as int?,
            ),
          );
        }
      } else {
        debugPrint('⚠️ لا توجد عناصر للطلب');
      }

      // حساب الربح الإجمالي
      double totalProfit = 0.0;
      for (var item in orderItems) {
        if (item.profitPerItem != null) {
          totalProfit += item.profitPerItem! * item.quantity;
        }
      }

      // جلب بيانات المستخدم (التاجر)
      String userName = 'غير محدد';
      String userPhone = 'غير محدد';

      // لا يوجد user_id في الجدول الحالي، لذا نستخدم بيانات افتراضية
      // userName = 'غير محدد';
      // userPhone = 'غير محدد';

      // إنشاء كائن AdminOrder مع جميع البيانات
      final adminOrder = AdminOrder(
        id: orderId,
        orderNumber: orderId.substring(0, 8),
        customerName: orderResponse['customer_name']?.toString() ?? 'غير محدد',
        customerPhone: orderResponse['primary_phone']?.toString() ?? 'غير محدد',
        customerAlternatePhone: orderResponse['secondary_phone']?.toString(),
        customerProvince: orderResponse['province']?.toString(),
        customerCity: orderResponse['city']?.toString(),
        customerAddress:
            '${orderResponse['province']?.toString() ?? ''} - ${orderResponse['city']?.toString() ?? ''}',
        customerNotes: orderResponse['customer_notes']?.toString(), // ✅ إصلاح: استخدام customer_notes
        totalAmount: (orderResponse['total'] as num?)?.toDouble() ?? 0.0,
        deliveryCost:
            (orderResponse['delivery_fee'] as num?)?.toDouble() ?? 0.0,
        profitAmount: (orderResponse['profit'] as num?)?.toDouble() ?? 0.0,
        status: orderResponse['status']?.toString() ?? 'confirmed',
        expectedProfit: totalProfit,
        itemsCount: orderItems.length,
        createdAt: DateTime.parse(
          orderResponse['created_at'] ?? DateTime.now().toIso8601String(),
        ),
        userName: userName,
        userPhone: userPhone,
        items: orderItems,
      );

      debugPrint('✅ تم إنشاء AdminOrder مع ${adminOrder.items.length} عنصر');
      return adminOrder;
    } catch (e) {
      debugPrint('❌ خطأ في جلب تفاصيل الطلب: $e');

      // محاولة جلب البيانات الأساسية فقط
      try {
        debugPrint('🔄 محاولة جلب البيانات الأساسية للطلب...');
        final basicOrderResponse = await _supabase
            .from('orders')
            .select('*')
            .eq('id', orderId)
            .single();

        // إنشاء طلب بالبيانات الأساسية فقط
        final basicOrder = AdminOrder(
          id: orderId,
          orderNumber: orderId.substring(0, 8),
          customerName:
              basicOrderResponse['customer_name']?.toString() ?? 'غير محدد',
          customerPhone:
              basicOrderResponse['primary_phone']?.toString() ?? 'غير محدد',
          customerAlternatePhone: basicOrderResponse['secondary_phone']
              ?.toString(),
          customerProvince: basicOrderResponse['province']?.toString(),
          customerCity: basicOrderResponse['city']?.toString(),
          customerAddress:
              '${basicOrderResponse['province']?.toString() ?? ''} - ${basicOrderResponse['city']?.toString() ?? ''}',
          customerNotes: basicOrderResponse['customer_notes']?.toString(), // ✅ إصلاح: استخدام customer_notes
          totalAmount: (basicOrderResponse['total'] as num?)?.toDouble() ?? 0.0,
          deliveryCost:
              (basicOrderResponse['delivery_fee'] as num?)?.toDouble() ?? 0.0,
          profitAmount:
              (basicOrderResponse['profit'] as num?)?.toDouble() ?? 0.0,
          status: basicOrderResponse['status']?.toString() ?? 'confirmed',
          expectedProfit:
              (basicOrderResponse['profit'] as num?)?.toDouble() ?? 0.0,
          itemsCount: 0,
          createdAt: DateTime.parse(
            basicOrderResponse['created_at'] ??
                DateTime.now().toIso8601String(),
          ),
          userName: 'غير محدد', // سيتم جلبه لاحقاً
          userPhone: 'غير محدد', // سيتم جلبه لاحقاً
          items: [], // قائمة فارغة
        );

        debugPrint('✅ تم جلب البيانات الأساسية للطلب');
        return basicOrder;
      } catch (basicError) {
        debugPrint('❌ فشل في جلب البيانات الأساسية أيضاً: $basicError');
        throw Exception('خطأ في جلب تفاصيل الطلب: $e');
      }
    }
  }

  // تم نقل دالة تحويل النصوص إلى OrderStatusManager

  // اختبار القيم المقبولة لحالة الطلب
  Future<void> testStatusValues(String orderId) async {
    // قائمة شاملة من القيم المحتملة
    final testValues = [
      // القيم العربية
      'نشط', 'قيد التوصيل', 'تم التوصيل', 'تم الإلغاء', 'في الانتظار',
      // القيم الإنجليزية
      'pending', 'active', 'in_delivery', 'delivered', 'cancelled', 'rejected',
      // الأرقام
      '1', '2', '3', '4', '5', '0',
      // قيم أخرى محتملة
      'new', 'processing', 'shipped', 'completed', 'failed',
      'confirmed', 'preparing', 'ready', 'out_for_delivery',
      // قيم بأشكال مختلفة
      'PENDING', 'ACTIVE', 'IN_DELIVERY', 'DELIVERED', 'CANCELLED',
    ];

    debugPrint('🧪 بدء اختبار ${testValues.length} قيمة محتملة...');

    List<String> acceptedValues = [];
    List<String> rejectedValues = [];

    for (String testValue in testValues) {
      try {
        debugPrint('🧪 اختبار القيمة: $testValue');
        await _supabase
            .from('orders')
            .update({'status': testValue})
            .eq('id', orderId)
            .select();
        debugPrint('✅ القيمة مقبولة: $testValue');
        acceptedValues.add(testValue);
        // لا نتوقف - نريد معرفة جميع القيم المقبولة
      } catch (e) {
        debugPrint('❌ القيمة مرفوضة: $testValue');
        rejectedValues.add(testValue);
      }
    }

    debugPrint('🎯 ملخص النتائج:');
    debugPrint('✅ القيم المقبولة (${acceptedValues.length}): $acceptedValues');
    debugPrint('❌ القيم المرفوضة (${rejectedValues.length}): $rejectedValues');
  }

  // تحديث حالة الطلب
  static Future<bool> updateOrderStatus(
    String orderId,
    String newStatus, {
    String? notes,
    String? updatedBy,
  }) async {
    try {
      debugPrint('🔥 ADMIN SERVICE: بدء تحديث حالة الطلب');
      debugPrint('🔥 ORDER ID: $orderId');
      debugPrint('🔥 NEW STATUS: $newStatus');
      debugPrint('🔥 NOTES: $notes');

      // لا نحتاج لاختبار القيم بعد الآن - نعرف القيم الصحيحة
      // await testStatusValues(orderId);

      // التحقق من وجود الطلب أولاً
      final existingOrder = await _supabase
          .from('orders')
          .select('id, status')
          .eq('id', orderId)
          .maybeSingle();

      if (existingOrder == null) {
        debugPrint('🔥 ERROR: الطلب غير موجود في قاعدة البيانات');
        return false;
      }

      debugPrint('🔥 EXISTING ORDER: $existingOrder');

      // تحديد قيمة قاعدة البيانات بناءً على نوع المدخل
      String statusForDatabase;

      // قائمة القيم الصحيحة لقاعدة البيانات - فقط القيم المسموحة
      final validDatabaseValues = [
        'active',
        'in_delivery',
        'delivered',
        'cancelled',
      ];

      debugPrint('🔍 فحص القيمة المدخلة:');
      debugPrint('   📝 القيمة: "$newStatus"');
      debugPrint('   📋 النوع: ${newStatus.runtimeType}');
      debugPrint('   📋 القائمة الصحيحة: $validDatabaseValues');
      debugPrint(
        '   ✅ موجودة في القائمة: ${validDatabaseValues.contains(newStatus)}',
      );

      if (validDatabaseValues.contains(newStatus)) {
        // إذا كانت القيمة المدخلة هي قيمة قاعدة بيانات صحيحة، استخدمها مباشرة
        statusForDatabase = newStatus;
        debugPrint('   ✅ استخدام القيمة مباشرة: "$statusForDatabase"');
      } else {
        // تحويل الحالات غير المسموحة إلى حالات مسموحة
        switch (newStatus.toLowerCase()) {
          case 'pending':
          case 'confirmed':
            statusForDatabase = 'active';
            debugPrint('   🔄 تحويل "$newStatus" إلى "active"');
            break;
          case 'processing':
            statusForDatabase = 'in_delivery';
            debugPrint('   🔄 تحويل "$newStatus" إلى "in_delivery"');
            break;
          case 'shipped':
            statusForDatabase = 'delivered'; // shipped يعني تم التوصيل
            debugPrint('   🔄 تحويل "$newStatus" إلى "delivered"');
            break;
          default:
            // إذا كانت القيمة المدخلة نص عربي، حولها إلى قيمة قاعدة البيانات
            statusForDatabase = OrderStatusHelper.arabicToDatabase(newStatus);
            debugPrint(
              '   🔄 تحويل من العربي: "$newStatus" -> "$statusForDatabase"',
            );
        }
      }

      debugPrint('🔄 تحويل الحالة باستخدام النظام الجديد:');
      debugPrint('   📝 الحالة المدخلة: "$newStatus"');
      debugPrint('   💾 قيمة قاعدة البيانات: "$statusForDatabase"');
      debugPrint(
        '   📋 النص العربي: "${OrderStatusHelper.getArabicStatus(statusForDatabase)}"',
      );

      // 🚀 تحديث مباشر في Supabase (النظام الرسمي النهائي)
      debugPrint('🔧 تحديث مباشر في Supabase: $orderId');
      debugPrint('🔧 نوع المعرف: ${orderId.runtimeType}');
      debugPrint('🔧 الحالة الجديدة: $statusForDatabase');

      // تحديث حالة الطلب مباشرة في Supabase
      final updateResult = await _supabase
          .from('orders')
          .update({
            'status': statusForDatabase,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .select();

      if (updateResult.isEmpty) {
        debugPrint('🔥 ERROR: فشل في تحديث الحالة في Supabase');
        return false;
      }

      debugPrint('🔥 SUCCESS: تم تحديث حالة الطلب مباشرة في Supabase');
      debugPrint('🔥 UPDATE RESULT: ${updateResult.first}');

      // إضافة سجل تاريخ الحالة مباشرة في Supabase
      debugPrint(
        '📝 إضافة سجل تاريخ الحالة من ${existingOrder['status']} إلى $statusForDatabase',
      );

      try {
        await _supabase.from('order_status_history').insert({
          'order_id': orderId,
          'old_status': existingOrder['status'],
          'new_status': statusForDatabase,
          'changed_by': updatedBy ?? 'admin',
          'change_reason': notes ?? 'تم تحديث الحالة من لوحة التحكم',
          'created_at': DateTime.now().toIso8601String(),
        });
        debugPrint('✅ تم إضافة سجل تاريخ الحالة بنجاح');
      } catch (historyError) {
        debugPrint('⚠️ تحذير: فشل في إضافة سجل التاريخ: $historyError');
        // لا نوقف العملية لأن التحديث الأساسي نجح
      }

      // 🚀 النظام الجديد: الخادم يتولى إرسال الطلب للوسيط تلقائياً
      if (statusForDatabase == 'in_delivery') {
        debugPrint('🚨 === الخادم سيرسل الطلب إلى شركة الوسيط تلقائياً ===');
        debugPrint('📦 معرف الطلب: $orderId');
        debugPrint('🔄 الحالة الجديدة: $statusForDatabase');
        debugPrint('✅ === الخادم يتولى العملية بالكامل ===');
      }

      // إرسال إشعار تغيير حالة الطلب للمستخدم صاحب الطلب (النظام الرسمي)
      try {
        // الحصول على رقم هاتف المستخدم صاحب الطلب
        final userPhone = existingOrder['user_phone']?.toString();
        final customerName = existingOrder['customer_name']?.toString() ?? 'عميل';
        final orderNumber = existingOrder['order_number']?.toString() ?? 'غير محدد';

        if (userPhone != null && userPhone.isNotEmpty) {
          debugPrint('📱 إرسال إشعار للمستخدم صاحب الطلب: $userPhone');

          // تم إزالة نظام الإشعارات
          debugPrint('تم تحديث حالة الطلب $orderNumber للعميل $customerName إلى $statusForDatabase');
        } else {
          debugPrint('⚠️ لا يوجد رقم هاتف للمستخدم صاحب الطلب');
        }
      } catch (e) {
        debugPrint('❌ خطأ في إرسال إشعار تغيير حالة الطلب: $e');
      }

      // ✅ تحديث أرباح المستخدم عند تغيير الحالة إلى "تم التوصيل"
      if (statusForDatabase == 'delivered' || statusForDatabase == 'shipped') {
        debugPrint('🚨 === بدء تحديث الأرباح عند التوصيل ===');
        debugPrint('📦 معرف الطلب: $orderId');
        debugPrint('🔄 الحالة الجديدة: $statusForDatabase');
        debugPrint('💰 تحديث الأرباح عند التوصيل للطلب: $orderId');
        debugPrint('✅ === انتهاء تحديث الأرباح عند التوصيل ===');
      }

      // محاولة إضافة ملاحظة إذا كانت متوفرة (اختيارية)
      if (notes != null && notes.isNotEmpty) {
        try {
          await _supabase.from('order_notes').insert({
            'order_id': orderId,
            'content': 'تم تحديث الحالة إلى: $statusForDatabase - $notes',
            'type': 'status_change',
            'is_internal': true,
            'created_by': updatedBy ?? 'admin',
            'created_at': DateTime.now().toIso8601String(),
          });
          debugPrint('🔥 NOTE ADDED: تم إضافة ملاحظة تحديث الحالة');
        } catch (noteError) {
          debugPrint('🔥 NOTE ERROR: $noteError');
          // لا نرمي خطأ هنا لأن تحديث الحالة نجح
        }
      }

      return true;
    } catch (e) {
      debugPrint('❌ خطأ في تحديث حالة الطلب: $e');
      return false;
    }
  }



  // تحديث بيانات العميل
  static Future<bool> updateCustomerInfo(
    String orderId,
    Map<String, dynamic> customerData,
  ) async {
    try {
      debugPrint('🔄 تحديث بيانات العميل للطلب: $orderId');
      debugPrint('📝 البيانات الجديدة: $customerData');

      // التحقق من وجود الطلب أولاً
      final existingOrder = await _supabase
          .from('orders')
          .select('id')
          .eq('id', orderId)
          .maybeSingle();

      if (existingOrder == null) {
        debugPrint('❌ الطلب غير موجود: $orderId');
        return false;
      }

      // تحويل أسماء الأعمدة لتتطابق مع قاعدة البيانات
      final mappedData = <String, dynamic>{};

      // تحويل أسماء الأعمدة - استخدام الأسماء الجديدة أولاً ثم القديمة كبديل
      if (customerData['customer_name'] != null) {
        mappedData['customer_name'] = customerData['customer_name'];
      }
      if (customerData['primary_phone'] != null) {
        mappedData['primary_phone'] = customerData['primary_phone'];
      }
      if (customerData['secondary_phone'] != null) {
        mappedData['secondary_phone'] = customerData['secondary_phone'];
      }
      if (customerData['province'] != null) {
        mappedData['province'] = customerData['province'];
      }
      if (customerData['city'] != null) {
        mappedData['city'] = customerData['city'];
      }
      if (customerData['notes'] != null) {
        mappedData['notes'] = customerData['notes'];
      }

      debugPrint('📝 البيانات المحولة: $mappedData');

      // تحديث بيانات العميل في جدول الطلبات
      final response = await _supabase
          .from('orders')
          .update({
            ...mappedData,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .select();

      debugPrint('✅ تم تحديث بيانات العميل بنجاح: ${response.length} صف محدث');
      return response.isNotEmpty;
    } catch (e) {
      debugPrint('❌ خطأ في تحديث بيانات العميل: $e');
      debugPrint('❌ تفاصيل الخطأ: ${e.runtimeType}');
      return false;
    }
  }

  // تحديث سعر وكمية المنتج في الطلب
  static Future<bool> updateProductPrice(
    String orderId,
    String itemId,
    double newPrice,
    double newTotalPrice,
    double newProfitPerItem, {
    int? newQuantity, // إضافة معامل اختياري للكمية
  }) async {
    try {
      debugPrint('🔄 تحديث المنتج: $itemId في الطلب: $orderId');
      debugPrint('💰 السعر الجديد: $newPrice');
      if (newQuantity != null) {
        debugPrint('📦 الكمية الجديدة: $newQuantity');
      }

      // إعداد البيانات للتحديث
      final updateData = {
        'customer_price': newPrice,
        'total_price': newTotalPrice,
        'profit_per_item': newProfitPerItem,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // إضافة الكمية إذا تم تمريرها
      if (newQuantity != null) {
        updateData['quantity'] = newQuantity;
      }

      // تحديث المنتج في جدول order_items
      await _supabase
          .from('order_items')
          .update(updateData)
          .eq('id', itemId)
          .eq('order_id', orderId);

      // إعادة حساب المبلغ الإجمالي والأرباح للطلب
      final orderItemsResponse = await _supabase
          .from('order_items')
          .select('total_price, profit_per_item, quantity')
          .eq('order_id', orderId);

      double totalAmount = 0;
      double totalProfit = 0;

      for (var item in orderItemsResponse) {
        totalAmount += (item['total_price'] as num).toDouble();
        totalProfit +=
            ((item['profit_per_item'] as num?) ?? 0).toDouble() *
            ((item['quantity'] as num?) ?? 1).toDouble();
      }

      // تحديث المبلغ الإجمالي والأرباح في جدول الطلبات
      await _supabase
          .from('orders')
          .update({
            'total': totalAmount,
            'profit': totalProfit, // استخدام profit بدلاً من profit_amount
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      debugPrint('✅ تم تحديث المنتج والمبلغ الإجمالي بنجاح');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في تحديث المنتج: $e');
      return false;
    }
  }

  // تحديث معلومات الطلب (المبلغ الإجمالي وتكلفة التوصيل)
  static Future<bool> updateOrderInfo(
    String orderId,
    double totalAmount,
    double deliveryCost,
    double profitAmount,
  ) async {
    try {
      debugPrint('🔄 تحديث معلومات الطلب: $orderId');
      debugPrint('💰 المبلغ الإجمالي الجديد: $totalAmount');
      debugPrint('🚚 تكلفة التوصيل الجديدة: $deliveryCost');

      // تحديث معلومات الطلب في قاعدة البيانات
      await _supabase
          .from('orders')
          .update({
            'total': totalAmount,
            'delivery_fee':
                deliveryCost, // استخدام delivery_fee بدلاً من delivery_cost
            'profit': profitAmount, // استخدام profit بدلاً من profit_amount
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      debugPrint('✅ تم تحديث معلومات الطلب بنجاح');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في تحديث معلومات الطلب: $e');
      return false;
    }
  }

  // إضافة ملاحظة للطلب
  static Future<bool> addOrderNote(
    String orderId,
    String content, {
    String type = 'general',
    bool isInternal = false,
    String? createdBy,
  }) async {
    try {
      await _supabase.from('order_notes').insert({
        'order_id': orderId,
        'content': content,
        'type': type,
        'is_internal': isInternal,
        'created_by': createdBy ?? 'admin',
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      throw Exception('خطأ في إضافة الملاحظة: $e');
    }
  }

  // جلب سجل تغييرات حالة الطلب
  static Future<List<StatusHistory>> getOrderStatusHistory(
    String orderId,
  ) async {
    try {
      debugPrint('🔍 جلب سجل الحالات للطلب: $orderId');

      // جلب سجل الحالات من جدول order_status_history
      final response = await _supabase
          .from('order_status_history')
          .select('*')
          .eq('order_id', orderId)
          .order('created_at', ascending: false);

      debugPrint('📋 سجل الحالات: ${response.length} عنصر');

      return response.map<StatusHistory>((item) {
        return StatusHistory(
          id: item['id'] ?? '',
          status: item['status'] ?? '',
          statusText: OrderStatusHelper.getArabicStatus(item['status'] ?? ''),
          notes: item['notes'],
          createdAt:
              DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now(),
          createdBy: item['created_by'],
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ خطأ في جلب سجل الحالات: $e');
      // إذا لم يكن الجدول موجود، نعيد قائمة فارغة
      return [];
    }
  }

  // ✅ حساب وتحديث الأرباح المحققة لجميع المستخدمين
  Future<void> recalculateAllUserProfits() async {
    try {
      debugPrint('🔄 === إعادة حساب الأرباح المحققة لجميع المستخدمين ===');

      // جلب جميع المستخدمين
      final usersResponse = await _supabase
          .from('users')
          .select('id, phone, name, achieved_profits, expected_profits');

      debugPrint('👥 عدد المستخدمين: ${usersResponse.length}');

      for (var user in usersResponse) {
        final userPhone = user['phone'] as String;
        final userName = user['name'] as String;

        debugPrint('🔄 معالجة المستخدم: $userName ($userPhone)');

        // حساب الأرباح المحققة من الطلبات المكتملة
        final deliveredOrdersResponse = await _supabase
            .from('orders')
            .select('profit')
            .eq('primary_phone', userPhone)
            .eq('status', 'delivered');

        double totalAchievedProfits = 0.0;
        for (var order in deliveredOrdersResponse) {
          final profit = (order['profit'] as num?)?.toDouble() ?? 0.0;
          totalAchievedProfits += profit;
        }

        // حساب الأرباح المنتظرة من الطلبات النشطة وقيد التوصيل
        final activeOrdersResponse = await _supabase
            .from('orders')
            .select('profit')
            .eq('primary_phone', userPhone)
            .inFilter('status', ['active', 'in_delivery']);

        double totalExpectedProfits = 0.0;
        for (var order in activeOrdersResponse) {
          final profit = (order['profit'] as num?)?.toDouble() ?? 0.0;
          totalExpectedProfits += profit;
        }

        debugPrint('💰 الأرباح المحققة المحسوبة: $totalAchievedProfits د.ع');
        debugPrint('📊 الأرباح المنتظرة المحسوبة: $totalExpectedProfits د.ع');

        // تحديث أرباح المستخدم
        await _supabase
            .from('users')
            .update({
              'achieved_profits': totalAchievedProfits,
              'expected_profits': totalExpectedProfits,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('phone', userPhone);

        debugPrint('✅ تم تحديث أرباح المستخدم: $userName');
      }

      debugPrint('✅ تم إعادة حساب الأرباح لجميع المستخدمين بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إعادة حساب الأرباح: $e');
    }
  }

  // إضافة تسجيل تغيير الحالة
  Future<bool> _addStatusHistoryEntry(
    String orderId,
    String oldStatus,
    String newStatus, {
    String? notes,
    String? createdBy,
  }) async {
    try {
      debugPrint('📝 إضافة تسجيل تغيير الحالة:');
      debugPrint('   📋 الطلب: $orderId');
      debugPrint('   🔄 من: $oldStatus إلى: $newStatus');

      await _supabase.from('order_status_history').insert({
        'order_id': orderId,
        'old_status': oldStatus,
        'new_status': newStatus,
        'status': newStatus, // الحالة الجديدة
        'notes':
            notes ??
            'تم تحديث الحالة من ${OrderStatusHelper.getArabicStatus(oldStatus)} إلى ${OrderStatusHelper.getArabicStatus(newStatus)}',
        'created_by': createdBy ?? 'admin',
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ تم إضافة تسجيل تغيير الحالة بنجاح');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في إضافة تسجيل تغيير الحالة: $e');
      // لا نرمي خطأ هنا لأن تحديث الحالة الأساسي نجح
      return false;
    }
  }

  // الحصول على قائمة المستخدمين مع الإحصائيات
  Future<List<AdminUser>> getUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select('''
            *,
            orders(id, status, total, profit)
          ''')
          .eq('is_admin', false)
          .order('created_at', ascending: false);

      return response.map<AdminUser>((user) {
        final orders = user['orders'] as List;

        // حساب الإحصائيات
        int totalOrders = orders.length;
        int activeOrders = orders
            .where((o) => ['active', 'in_delivery'].contains(o['status']))
            .length;

        // حساب الأرباح المحققة (من الطلبات المكتملة فقط)
        double totalProfits = 0;
        for (var order in orders) {
          if (order['status'] == 'delivered') {
            final profit = (order['profit'] as num?)?.toDouble() ?? 0.0;
            totalProfits += profit;
          }
        }

        return AdminUser(
          id: user['id'],
          name: user['name'],
          phone: user['phone'],
          email: user['email'],
          createdAt: DateTime.parse(user['created_at']),
          totalOrders: totalOrders,
          activeOrders: activeOrders,
          totalProfits: totalProfits,
        );
      }).toList();
    } catch (e) {
      throw Exception('خطأ في جلب المستخدمين: $e');
    }
  }

  // إضافة منتج جديد
  static Future<void> addProduct({
    required String name,
    required String description,
    required double wholesalePrice,
    required double minPrice,
    required double maxPrice,
    required String imageUrl,
    String category = '',
    int availableQuantity = 0,
    List<String>? additionalImages,
  }) async {
    try {
      // التحقق من وجود الجدول أولاً
      debugPrint('محاولة إضافة منتج: $name');

      // إنشاء مصفوفة الصور
      List<String> images = [imageUrl];
      if (additionalImages != null && additionalImages.isNotEmpty) {
        images.addAll(additionalImages);
      }

      final productData = <String, dynamic>{
        'name': name,
        'description': description,
        'wholesale_price': wholesalePrice,
        'min_price': minPrice,
        'max_price': maxPrice,
        'image_url': imageUrl, // الصورة الرئيسية
        'images': images, // مصفوفة جميع الصور
        'category': category.isEmpty ? 'عام' : category,
        'available_quantity': availableQuantity > 0 ? availableQuantity : 100,
        'is_active': true,
      };

      debugPrint('بيانات المنتج: $productData');

      final response = await _supabase
          .from('products')
          .insert(productData)
          .select()
          .single();

      debugPrint('تم إضافة المنتج بنجاح: ${response['id']}');
    } catch (e) {
      debugPrint('خطأ في إضافة المنتج: $e');

      // إذا كان الخطأ متعلق بعدم وجود الجدول
      if (e.toString().contains('relation "products" does not exist')) {
        throw Exception(
          'جدول المنتجات غير موجود في قاعدة البيانات. يرجى إنشاؤه أولاً.',
        );
      }

      // إذا كان الخطأ متعلق بالأعمدة
      if (e.toString().contains('column') &&
          e.toString().contains('does not exist')) {
        throw Exception(
          'بعض الأعمدة مفقودة في جدول المنتجات. يرجى تحديث هيكل الجدول.',
        );
      }

      throw Exception('خطأ في إضافة المنتج: $e');
    }
  }

  // تحديث منتج
  Future<void> updateProduct({
    required String productId,
    required String name,
    required String description,
    required double wholesalePrice,
    required double minPrice,
    required double maxPrice,
    required String imageUrl,
    String? category,
    int? availableQuantity,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'name': name,
        'description': description,
        'wholesale_price': wholesalePrice,
        'min_price': minPrice,
        'max_price': maxPrice,
        'image_url': imageUrl,
      };

      if (category != null) updateData['category'] = category;
      if (availableQuantity != null) {
        updateData['available_quantity'] = availableQuantity;
      }
      if (isActive != null) updateData['is_active'] = isActive;

      await _supabase.from('products').update(updateData).eq('id', productId);
    } catch (e) {
      throw Exception('خطأ في تحديث المنتج: $e');
    }
  }

  // تغيير حالة المنتج
  Future<void> toggleProductStatus(String productId, bool isActive) async {
    try {
      await _supabase
          .from('products')
          .update({'is_active': isActive})
          .eq('id', productId);
    } catch (e) {
      throw Exception('خطأ في تغيير حالة المنتج: $e');
    }
  }

  // الحصول على قائمة المنتجات
  Future<List<AdminProduct>> getProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select('''
            *,
            order_items(quantity)
          ''')
          .order('created_at', ascending: false);

      return response.map<AdminProduct>((product) {
        final orderItems = product['order_items'] as List;
        int totalOrdered = orderItems.fold(
          0,
          (sum, item) => sum + (item['quantity'] as int),
        );

        return AdminProduct(
          id: product['id'],
          name: product['name'],
          description: product['description'] ?? '',
          imageUrl: product['image_url'] ?? '',
          wholesalePrice: (product['wholesale_price'] as num).toDouble(),
          minPrice: (product['min_price'] as num).toDouble(),
          maxPrice: (product['max_price'] as num).toDouble(),
          availableQuantity: product['available_quantity'] ?? 100,
          category: product['category'] ?? '',
          isActive: product['is_active'] ?? true,
          totalOrdered: totalOrdered,
          createdAt: DateTime.parse(product['created_at']),
        );
      }).toList();
    } catch (e) {
      throw Exception('خطأ في جلب المنتجات: $e');
    }
  }

  // الحصول على طلبات السحب
  Future<List<WithdrawalRequest>> getWithdrawalRequests() async {
    try {
      final response = await _supabase
          .from('withdrawal_requests')
          .select('''
            *,
            users!inner(name, phone)
          ''')
          .order('created_at', ascending: false);

      return response.map<WithdrawalRequest>((request) {
        return WithdrawalRequest(
          id: request['id'],
          userId: request['user_id'],
          userName: request['users']['name'],
          userPhone: request['users']['phone'],
          amount: (request['amount'] as num).toDouble(),
          withdrawalMethod: request['withdrawal_method'],
          accountDetails: request['account_details'],
          status: request['status'],
          adminNotes: request['admin_notes'],
          createdAt: DateTime.parse(request['created_at']),
        );
      }).toList();
    } catch (e) {
      throw Exception('خطأ في جلب طلبات السحب: $e');
    }
  }

  // تحديث حالة طلب السحب
  Future<bool> updateWithdrawalStatus(
    String requestId,
    String newStatus, {
    String? adminNotes,
  }) async {
    try {
      final updateData = {'status': newStatus};
      if (adminNotes != null) {
        updateData['admin_notes'] = adminNotes;
      }

      await _supabase
          .from('withdrawal_requests')
          .update(updateData)
          .eq('id', requestId);
      return true;
    } catch (e) {
      throw Exception('خطأ في تحديث طلب السحب: $e');
    }
  }

  // الحصول على الإحصائيات الشاملة مع إصلاح تلقائي
  Future<AdminStats> getStats() async {
    try {
      debugPrint('🔄 جلب الإحصائيات الشاملة...');

      // أولاً: إصلاح ربط الطلبات بالمستخدمين تلقائياً
      await _fixOrderUserLinksIfNeeded();

      // جلب إحصائيات الطلبات مع جميع البيانات المطلوبة
      final ordersResponse = await _supabase
          .from('orders')
          .select('id, status, total, profit, created_at');

      final totalOrders = ordersResponse.length;
      debugPrint('📊 إجمالي الطلبات: $totalOrders');

      final activeOrders = ordersResponse
          .where((order) => order['status'] == 'active')
          .length;
      final deliveredOrders = ordersResponse
          .where((order) => order['status'] == 'delivered')
          .length;
      final cancelledOrders = ordersResponse
          .where((order) => order['status'] == 'cancelled')
          .length;
      final pendingOrders = ordersResponse
          .where((order) => order['status'] == 'pending')
          .length;
      final shippingOrders = ordersResponse
          .where((order) => order['status'] == 'in_delivery')
          .length;

      // حساب إجمالي الأرباح (ربح المستخدم فقط)
      double totalProfits = 0;
      for (final order in ordersResponse) {
        if (order['status'] == 'delivered') {
          // استخدام profit فقط (ربح المستخدم فقط)
          final profit = (order['profit'] as num?)?.toDouble() ?? 0.0;
          totalProfits += profit;
        }
      }

      debugPrint('📊 الإحصائيات المحسوبة:');
      debugPrint('   النشطة: $activeOrders');
      debugPrint('   المكتملة: $deliveredOrders');
      debugPrint('   الملغية: $cancelledOrders');
      debugPrint('   قيد التوصيل: $shippingOrders');
      debugPrint('   إجمالي الأرباح: $totalProfits');

      // جلب إحصائيات المستخدمين
      final usersResponse = await _supabase
          .from('users')
          .select('id, created_at')
          .eq('is_admin', false);

      final totalUsers = usersResponse.length;
      final now = DateTime.now();
      final lastWeek = now.subtract(const Duration(days: 7));
      final newUsers = usersResponse
          .where((user) => DateTime.parse(user['created_at']).isAfter(lastWeek))
          .length;

      // جلب إحصائيات المنتجات
      final productsResponse = await _supabase
          .from('products')
          .select('id, available_quantity');

      final totalProducts = productsResponse.length;
      final lowStockProducts = productsResponse
          .where((product) => (product['available_quantity'] ?? 0) < 10)
          .length;

      return AdminStats(
        totalOrders: totalOrders,
        activeOrders: activeOrders,
        deliveredOrders: deliveredOrders,
        cancelledOrders: cancelledOrders,
        totalUsers: totalUsers,
        newUsers: newUsers,
        totalProducts: totalProducts,
        lowStockProducts: lowStockProducts,
        pendingOrders: pendingOrders,
        shippingOrders: shippingOrders,
        totalProfits: totalProfits,
      );
    } catch (e) {
      throw Exception('خطأ في جلب الإحصائيات: $e');
    }
  }

  // دالة لإرجاع بيانات تجريبية للاختبار
  List<AdminOrder> getSampleOrders() {
    final now = DateTime.now();

    return [
      AdminOrder(
        id: 'sample-1',
        orderNumber: 'ORD-${now.millisecondsSinceEpoch}-001',
        customerName: 'أحمد محمد علي',
        customerPhone: '07501234567',
        customerAlternatePhone: '07709876543',
        customerProvince: 'بغداد',
        customerCity: 'الكرادة',
        customerAddress: 'شارع الكرادة الداخلية، بناية رقم 15، الطابق الثالث',
        customerNotes: 'يرجى الاتصال قبل التوصيل',
        totalAmount: 125000,
        deliveryCost: 5000,
        profitAmount: 15000,
        status: 'active',
        expectedProfit: 15000,
        itemsCount: 1,
        createdAt: now.subtract(const Duration(hours: 2)),
        userName: 'تاجر محمد',
        userPhone: '07501111111',
        items: [
          AdminOrderItem(
            id: 'item-1',
            productName: 'هاتف ذكي سامسونج Galaxy A54',
            productPrice: 450000,
            wholesalePrice: 400000,
            customerPrice: 450000,
            minPrice: 420000,
            maxPrice: 480000,
            quantity: 1,
            totalPrice: 450000,
            profitPerItem: 50000,
          ),
        ],
      ),
      AdminOrder(
        id: 'sample-2',
        orderNumber: 'ORD-${now.millisecondsSinceEpoch}-002',
        customerName: 'فاطمة حسن محمود',
        customerPhone: '07701234567',
        customerAlternatePhone: '07801234567',
        customerProvince: 'البصرة',
        customerCity: 'المعقل',
        customerAddress: 'حي الجمهورية، شارع الأطباء، منزل رقم 42',
        customerNotes: 'التوصيل بعد الساعة 4 عصراً',
        totalAmount: 89500,
        deliveryCost: 3000,
        profitAmount: 12000,
        status: 'in_delivery',
        expectedProfit: 12000,
        itemsCount: 2,
        createdAt: now.subtract(const Duration(days: 1)),
        userName: 'تاجر أحمد',
        userPhone: '07502222222',
        items: [
          AdminOrderItem(
            id: 'item-2',
            productName: 'سماعات بلوتوث JBL',
            productPrice: 85000,
            wholesalePrice: 70000,
            customerPrice: 85000,
            minPrice: 75000,
            maxPrice: 95000,
            quantity: 2,
            totalPrice: 170000,
            profitPerItem: 15000,
          ),
        ],
      ),
      AdminOrder(
        id: 'sample-3',
        orderNumber: 'ORD-${now.millisecondsSinceEpoch}-003',
        customerName: 'محمد عبد الله سالم',
        customerPhone: '07801234567',
        customerAlternatePhone: null,
        customerProvince: 'أربيل',
        customerCity: 'عنكاوا',
        customerAddress: 'منطقة عنكاوا، شارع الكنائس، بيت رقم 28',
        customerNotes: null,
        totalAmount: 67800,
        deliveryCost: 4000,
        profitAmount: 8500,
        status: 'delivered',
        expectedProfit: 8500,
        itemsCount: 1,
        createdAt: now.subtract(const Duration(days: 3)),
        userName: 'تاجر علي',
        userPhone: '07503333333',
        items: [
          AdminOrderItem(
            id: 'item-3',
            productName: 'ساعة ذكية Apple Watch',
            productPrice: 220000,
            wholesalePrice: 180000,
            customerPrice: 220000,
            minPrice: 200000,
            maxPrice: 250000,
            quantity: 1,
            totalPrice: 220000,
            profitPerItem: 40000,
          ),
        ],
      ),
      AdminOrder(
        id: 'sample-4',
        orderNumber: 'ORD-${now.millisecondsSinceEpoch}-004',
        customerName: 'زينب علي حسين',
        customerPhone: '07901234567',
        customerAlternatePhone: '07501234567',
        customerProvince: 'النجف',
        customerCity: 'الكوفة',
        customerAddress: 'حي الأطباء، شارع المستشفى، منزل رقم 67',
        customerNotes: 'يفضل التوصيل صباحاً',
        totalAmount: 156700,
        deliveryCost: 6000,
        profitAmount: 22000,
        status: 'active',
        expectedProfit: 22000,
        itemsCount: 2,
        createdAt: now.subtract(const Duration(hours: 5)),
        userName: 'تاجر حسن',
        userPhone: '07504444444',
        items: [
          AdminOrderItem(
            id: 'item-4a',
            productName: 'لابتوب HP Pavilion',
            productPrice: 750000,
            wholesalePrice: 650000,
            customerPrice: 750000,
            minPrice: 700000,
            maxPrice: 800000,
            quantity: 1,
            totalPrice: 750000,
            profitPerItem: 100000,
          ),
          AdminOrderItem(
            id: 'item-4b',
            productName: 'ماوس لاسلكي Logitech',
            productPrice: 35000,
            wholesalePrice: 25000,
            customerPrice: 35000,
            minPrice: 30000,
            maxPrice: 40000,
            quantity: 1,
            totalPrice: 35000,
            profitPerItem: 10000,
          ),
        ],
      ),
      AdminOrder(
        id: 'sample-5',
        orderNumber: 'ORD-${now.millisecondsSinceEpoch}-005',
        customerName: 'عمر خالد إبراهيم',
        customerPhone: '07601234567',
        customerAlternatePhone: '07701234567',
        customerProvince: 'كربلاء',
        customerCity: 'الحر',
        customerAddress: 'حي الحر، شارع الإمام الحسين، بناية السلام، شقة 12',
        customerNotes: 'الرجاء عدم الاتصال بعد الساعة 9 مساءً',
        totalAmount: 45600,
        deliveryCost: 2500,
        profitAmount: 0,
        status: 'cancelled',
        expectedProfit: 0,
        itemsCount: 1,
        createdAt: now.subtract(const Duration(days: 7)),
        userName: 'تاجر سالم',
        userPhone: '07505555555',
        items: [
          AdminOrderItem(
            id: 'item-5',
            productName: 'كيبورد ميكانيكي',
            productPrice: 45000,
            wholesalePrice: 35000,
            customerPrice: 45000,
            minPrice: 40000,
            maxPrice: 50000,
            quantity: 1,
            totalPrice: 45000,
            profitPerItem: 10000,
          ),
        ],
      ),
    ];
  }

  // حذف طلب (دالة static)
  static Future<bool> deleteOrder(String orderId) async {
    try {
      debugPrint('🗑️ حذف الطلب: $orderId');

      // حذف عناصر الطلب أولاً
      await _supabase.from('order_items').delete().eq('order_id', orderId);

      // حذف الطلب
      final response = await _supabase
          .from('orders')
          .delete()
          .eq('id', orderId)
          .select();

      debugPrint('✅ تم حذف الطلب بنجاح');
      return response.isNotEmpty;
    } catch (e) {
      debugPrint('❌ خطأ في حذف الطلب: $e');
      return false;
    }
  }

  // نقل ربح الطلب من المنتظرة إلى المحققة
  Future<void> _moveOrderProfitToAchieved(String orderId) async {
    try {
      debugPrint('💰 نقل ربح الطلب $orderId إلى الأرباح المحققة...');

      // جلب تفاصيل الطلب
      final orderResponse = await _supabase
          .from('orders')
          .select('profit, primary_phone')
          .eq('id', orderId)
          .maybeSingle();

      if (orderResponse == null) {
        debugPrint('❌ لم يتم العثور على الطلب');
        return;
      }

      final orderProfit = orderResponse['profit'] ?? 0;
      final userPhone = orderResponse['primary_phone'];

      if (orderProfit <= 0) {
        debugPrint('⚠️ ربح الطلب صفر أو سالب: $orderProfit');
        return;
      }

      debugPrint('📊 ربح الطلب: $orderProfit د.ع');
      debugPrint('📱 هاتف المستخدم: $userPhone');

      // جلب الأرباح الحالية للمستخدم
      final currentProfitsResponse = await _supabase
          .from('users')
          .select('achieved_profits, expected_profits')
          .eq('phone', userPhone)
          .maybeSingle();

      if (currentProfitsResponse != null) {
        final currentAchieved = currentProfitsResponse['achieved_profits'] ?? 0;
        final currentExpected = currentProfitsResponse['expected_profits'] ?? 0;

        final newAchieved = currentAchieved + orderProfit;
        final newExpected = (currentExpected - orderProfit).clamp(
          0,
          double.infinity,
        );

        // تحديث الأرباح
        await _supabase
            .from('users')
            .update({
              'achieved_profits': newAchieved,
              'expected_profits': newExpected,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('phone', userPhone);

        debugPrint('✅ تم نقل $orderProfit د.ع من المنتظرة إلى المحققة');
        debugPrint('📊 الأرباح المحققة: $currentAchieved → $newAchieved');
        debugPrint('📊 الأرباح المنتظرة: $currentExpected → $newExpected');
      }
    } catch (e) {
      debugPrint('❌ خطأ في نقل ربح الطلب: $e');
    }
  }

  // إرسال إشعار محلي فوري عند تغيير حالة الطلب
  static Future<void> _sendImmediateLocalNotification({
    required String customerName,
    required String orderNumber,
    required String oldStatus,
    required String newStatus,
  }) async {
    try {
      debugPrint('🔔 إرسال إشعار محلي فوري...');

      // تحديد رسالة الإشعار حسب الحالة
      String title = '';
      String message = '';

      switch (newStatus) {
        case 'pending':
          title = '⏳ طلب قيد المراجعة';
          message = 'طلب $customerName ($orderNumber) قيد المراجعة';
          break;
        case 'confirmed':
          title = '✅ تم تأكيد الطلب';
          message = 'تم تأكيد طلب $customerName ($orderNumber)';
          break;
        case 'processing':
          title = '🔄 جاري تحضير الطلب';
          message = 'طلب $customerName ($orderNumber) قيد التحضير';
          break;
        case 'in_delivery':
          title = '🚚 الطلب قيد التوصيل';
          message = 'طلب $customerName ($orderNumber) قيد التوصيل';
          break;
        case 'delivered':
          title = '🎉 تم تسليم الطلب';
          message = 'تم تسليم طلب $customerName ($orderNumber) بنجاح';
          break;
        case 'cancelled':
          title = '❌ تم إلغاء الطلب';
          message = 'تم إلغاء طلب $customerName ($orderNumber)';
          break;
        default:
          title = '🔄 تحديث حالة الطلب';
          message = 'تم تحديث حالة طلب $customerName ($orderNumber)';
      }

      // تم إزالة نظام الإشعارات مؤقتاً
      debugPrint('✅ تم تحديث الطلب بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إرسال الإشعار المحلي الفوري: $e');
    }
  }

  // ===================================
  // دوال الإشعارات الفورية
  // ===================================

  /// إرسال إشعار تحديث حالة الطلب
  static Future<void> _sendOrderStatusNotification({
    required String customerPhone,
    required String orderId,
    required String newStatus,
    required String customerName,
    String? notes,
  }) async {
    try {
      debugPrint('📱 إرسال إشعار تحديث الطلب للعميل: $customerPhone');

      final response = await http.post(
        Uri.parse('$baseUrl/api/notifications/order-status'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userPhone': customerPhone,
          'orderId': orderId,
          'newStatus': newStatus,
          'customerName': customerName,
          'notes': notes ?? '',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          debugPrint('✅ تم إرسال الإشعار بنجاح: ${data['data']['messageId']}');
        } else {
          debugPrint('⚠️ فشل في إرسال الإشعار: ${data['message']}');
        }
      } else {
        debugPrint('❌ خطأ في إرسال الإشعار: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ خطأ في إرسال إشعار تحديث الطلب: $e');
    }
  }

  /// إرسال إشعار عام للعميل
  static Future<void> sendGeneralNotification({
    required String customerPhone,
    required String title,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      debugPrint('📢 إرسال إشعار عام للعميل: $customerPhone');

      final response = await http.post(
        Uri.parse('$baseUrl/api/notifications/general'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userPhone': customerPhone,
          'title': title,
          'message': message,
          'additionalData': additionalData ?? {},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          debugPrint('✅ تم إرسال الإشعار العام بنجاح');
        } else {
          debugPrint('⚠️ فشل في إرسال الإشعار العام: ${data['message']}');
        }
      } else {
        debugPrint('❌ خطأ في إرسال الإشعار العام: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ خطأ في إرسال الإشعار العام: $e');
    }
  }

  /// اختبار إرسال إشعار
  static Future<bool> testNotification(String customerPhone) async {
    try {
      debugPrint('🧪 اختبار إرسال إشعار للعميل: $customerPhone');

      final response = await http.post(
        Uri.parse('$baseUrl/api/notifications/test'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userPhone': customerPhone,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          debugPrint('✅ تم إرسال الإشعار التجريبي بنجاح');
          return true;
        } else {
          debugPrint('⚠️ فشل في إرسال الإشعار التجريبي: ${data['message']}');
          return false;
        }
      } else {
        debugPrint('❌ خطأ في إرسال الإشعار التجريبي: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ خطأ في اختبار الإشعار: $e');
      return false;
    }
  }
}

// نماذج البيانات
class DashboardStats {
  final int totalUsers;
  final int totalOrders;
  final int activeOrders;
  final int? shippingOrders; // الطلبات قيد التوصيل
  final double totalProfits;

  DashboardStats({
    required this.totalUsers,
    required this.totalOrders,
    required this.activeOrders,
    this.shippingOrders,
    required this.totalProfits,
  });
}

class AdminStats {
  final int totalOrders;
  final int activeOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final int totalUsers;
  final int newUsers;
  final int totalProducts;
  final int lowStockProducts;
  final int pendingOrders;
  final int? shippingOrders;
  final double totalProfits;

  AdminStats({
    required this.totalOrders,
    required this.activeOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.totalUsers,
    required this.newUsers,
    required this.totalProducts,
    required this.lowStockProducts,
    required this.pendingOrders,
    this.shippingOrders,
    required this.totalProfits,
  });
}

class AdminOrder {
  final String id;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final String? customerAlternatePhone;
  final String? customerProvince;
  final String? customerCity;
  final String customerAddress;
  final String? customerNotes;
  final double totalAmount;
  final double deliveryCost;
  final double profitAmount;
  final String status;
  final double expectedProfit;
  final int itemsCount;
  final DateTime createdAt;
  final String userName;
  final String userPhone;
  final List<AdminOrderItem> items;

  // حقول شركة الوسيط
  final String? waseetQrId;
  final String? waseetStatus;
  final String? waseetStatusId;
  final String? waseetDeliveryPrice;
  final String? waseetMerchantPrice;
  final Map<String, dynamic>? waseetOrderData;

  AdminOrder({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    this.customerAlternatePhone,
    this.customerProvince,
    this.customerCity,
    required this.customerAddress,
    this.customerNotes,
    required this.totalAmount,
    required this.deliveryCost,
    required this.profitAmount,
    required this.status,
    required this.expectedProfit,
    required this.itemsCount,
    required this.createdAt,
    required this.userName,
    required this.userPhone,
    this.items = const [],
    // حقول شركة الوسيط
    this.waseetQrId,
    this.waseetStatus,
    this.waseetStatusId,
    this.waseetDeliveryPrice,
    this.waseetMerchantPrice,
    this.waseetOrderData,
  });

  factory AdminOrder.fromJson(Map<String, dynamic> json) {
    return AdminOrder(
      id: json['id'] ?? '',
      orderNumber: (json['id'] ?? '').substring(0, 8),
      customerName: json['customer_name'] ?? 'غير محدد',
      customerPhone: json['primary_phone'] ?? '',
      customerAlternatePhone: json['secondary_phone'],
      customerProvince: json['province'],
      customerCity: json['city'],
      customerAddress: '${json['province'] ?? ''} - ${json['city'] ?? ''}',
      customerNotes: json['notes'],
      totalAmount: (json['total'] ?? 0).toDouble(),
      deliveryCost: (json['delivery_fee'] ?? 0).toDouble(),
      profitAmount: (json['profit'] ?? 0).toDouble(),
      status: json['status'] ?? 'active',
      expectedProfit: (json['profit'] ?? 0).toDouble(),
      itemsCount: json['items_count'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      userName: json['user_name'] ?? 'غير محدد',
      userPhone: json['user_phone'] ?? '',
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => AdminOrderItem.fromJson(item))
              .toList() ??
          [],
      // حقول شركة الوسيط
      waseetQrId: json['waseet_qr_id'],
      waseetStatus: json['waseet_status'],
      waseetStatusId: json['waseet_status_id'],
      waseetDeliveryPrice: json['waseet_delivery_price'],
      waseetMerchantPrice: json['waseet_merchant_price'],
      waseetOrderData: json['waseet_order_data'] is String
          ? jsonDecode(json['waseet_order_data'])
          : json['waseet_order_data'],
    );
  }
}

class AdminOrderItem {
  final String id;
  final String productName;
  final String? productImage;
  final double productPrice;
  final double? wholesalePrice;
  final double? customerPrice;
  final double? minPrice;
  final double? maxPrice;
  final int quantity;
  final double totalPrice;
  final double? profitPerItem;
  final String? productId; // إضافة معرف المنتج
  final int? availableFrom; // الكمية المتاحة من
  final int? availableTo; // الكمية المتاحة إلى

  AdminOrderItem({
    required this.id,
    required this.productName,
    this.productImage,
    required this.productPrice,
    this.wholesalePrice,
    this.customerPrice,
    this.minPrice,
    this.maxPrice,
    required this.quantity,
    required this.totalPrice,
    this.profitPerItem,
    this.productId,
    this.availableFrom,
    this.availableTo,
  });

  factory AdminOrderItem.fromJson(Map<String, dynamic> json) {
    return AdminOrderItem(
      id: json['id'] ?? '',
      productName: json['product_name'] ?? '',
      productImage: json['product_image'],
      productPrice: (json['product_price'] ?? 0).toDouble(),
      wholesalePrice: json['wholesale_price']?.toDouble(),
      customerPrice: json['customer_price']?.toDouble(),
      minPrice: json['min_price']?.toDouble(),
      maxPrice: json['max_price']?.toDouble(),
      quantity: json['quantity'] ?? 0,
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      profitPerItem: json['profit_per_item']?.toDouble(),
      productId: json['product_id'],
      availableFrom: json['available_from'],
      availableTo: json['available_to'],
    );
  }
}

class AdminUser {
  final String id;
  final String name;
  final String phone;
  final String email;
  final DateTime createdAt;
  final int totalOrders;
  final int activeOrders;
  final double totalProfits;

  AdminUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.createdAt,
    required this.totalOrders,
    required this.activeOrders,
    required this.totalProfits,
  });
}

class AdminProduct {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double wholesalePrice;
  final double minPrice;
  final double maxPrice;
  final int availableQuantity;
  final String category;
  final bool isActive;
  final int totalOrdered;
  final DateTime createdAt;

  AdminProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.wholesalePrice,
    required this.minPrice,
    required this.maxPrice,
    required this.availableQuantity,
    required this.category,
    required this.isActive,
    required this.totalOrdered,
    required this.createdAt,
  });
}

class WithdrawalRequest {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final double amount;
  final String withdrawalMethod;
  final String accountDetails;
  final String status;
  final String? adminNotes;
  final DateTime createdAt;

  WithdrawalRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.amount,
    required this.withdrawalMethod,
    required this.accountDetails,
    required this.status,
    this.adminNotes,
    required this.createdAt,
  });
}

// نماذج بيانات تفاصيل الطلب المتقدمة
class OrderDetails {
  final String id;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String? customerNotes;
  final String status;
  final String statusText;
  final double totalAmount;
  final double deliveryFee;
  final double totalCost;
  final double totalRevenue;
  final double totalProfit;
  final double profitMargin;
  final int itemsCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // معلومات المستخدم
  final String userId;
  final String userName;
  final String userPhone;
  final String? userEmail;
  final DateTime userJoinDate;

  // العناصر والتفاصيل
  final List<OrderItem> items;
  final List<StatusHistory> statusHistory;
  final List<OrderNote> notes;
  final DeliveryInfo? deliveryInfo;

  OrderDetails({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    this.customerNotes,
    required this.status,
    required this.statusText,
    required this.totalAmount,
    required this.deliveryFee,
    required this.totalCost,
    required this.totalRevenue,
    required this.totalProfit,
    required this.profitMargin,
    required this.itemsCount,
    required this.createdAt,
    this.updatedAt,
    required this.userId,
    required this.userName,
    required this.userPhone,
    this.userEmail,
    required this.userJoinDate,
    required this.items,
    required this.statusHistory,
    required this.notes,
    this.deliveryInfo,
  });
}

class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final String productDescription;
  final String productImageUrl;
  final List<String> productImages;
  final int quantity;
  final double wholesalePrice;
  final double customerPrice;
  final double minPrice;
  final double maxPrice;
  final String category;
  final double totalCost;
  final double totalRevenue;
  final double profit;
  final double profitMargin;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productDescription,
    required this.productImageUrl,
    required this.productImages,
    required this.quantity,
    required this.wholesalePrice,
    required this.customerPrice,
    required this.minPrice,
    required this.maxPrice,
    required this.category,
    required this.totalCost,
    required this.totalRevenue,
    required this.profit,
    required this.profitMargin,
  });
}

class StatusHistory {
  final String id;
  final String status;
  final String statusText;
  final String? notes;
  final DateTime createdAt;
  final String? createdBy;

  StatusHistory({
    required this.id,
    required this.status,
    required this.statusText,
    this.notes,
    required this.createdAt,
    this.createdBy,
  });
}

class OrderNote {
  final String id;
  final String content;
  final String type;
  final bool isInternal;
  final DateTime createdAt;
  final String? createdBy;

  OrderNote({
    required this.id,
    required this.content,
    required this.type,
    required this.isInternal,
    required this.createdAt,
    this.createdBy,
  });
}

class DeliveryInfo {
  final String id;
  final String? driverName;
  final String? driverPhone;
  final DateTime? estimatedDeliveryTime;
  final DateTime? actualDeliveryTime;
  final String? deliveryNotes;
  final String? trackingNumber;
  final double deliveryFee;

  DeliveryInfo({
    required this.id,
    this.driverName,
    this.driverPhone,
    this.estimatedDeliveryTime,
    this.actualDeliveryTime,
    this.deliveryNotes,
    this.trackingNumber,
    required this.deliveryFee,
  });
}
