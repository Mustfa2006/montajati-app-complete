// 🚀 خدمة الطلبات المبسطة والموثوقة
// تطبيق منتجاتي - نظام إدارة الدروب شيبنگ

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import '../models/order_item.dart' as order_models;
import 'inventory_service.dart';
import 'admin_service.dart';
import 'support_status_cache.dart';

class SimpleOrdersService extends ChangeNotifier {
  static final SimpleOrdersService _instance = SimpleOrdersService._internal();
  factory SimpleOrdersService() => _instance;
  SimpleOrdersService._internal();

  List<Order> _orders = [];
  bool _isLoading = false;
  DateTime? _lastUpdate;

  // ✅ منع التحميل المتكرر - تحميل مرة واحدة كل 30 ثانية
  static const Duration _cacheTimeout = Duration(seconds: 30);

  // Getters
  List<Order> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  DateTime? get lastUpdate => _lastUpdate;

  /// جلب الطلبات من قاعدة البيانات مباشرة
  Future<void> loadOrders({bool forceRefresh = false}) async {
    if (_isLoading) return;

    // ✅ فحص الـ cache - تجنب التحميل المتكرر
    if (!forceRefresh && _lastUpdate != null) {
      final timeSinceLastUpdate = DateTime.now().difference(_lastUpdate!);
      if (timeSinceLastUpdate < _cacheTimeout) {
        debugPrint('📋 استخدام البيانات المحفوظة (${_orders.length} طلب)');
        return;
      }
    }

    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      String? currentUserPhone = prefs.getString('current_user_phone');

      if (currentUserPhone == null || currentUserPhone.isEmpty) {
        currentUserPhone = '07503597589';
        await prefs.setString('current_user_phone', currentUserPhone);
        debugPrint(
          '⚠️ لم يتم العثور على رقم المستخدم، استخدام الافتراضي: $currentUserPhone',
        );
      } else {
        debugPrint('✅ تم العثور على رقم المستخدم: $currentUserPhone');
      }

      debugPrint('🚀 جلب الطلبات للمستخدم: $currentUserPhone');

      // ✅ جلب الطلبات مباشرة للمستخدم من قاعدة البيانات (أسرع)
      List<AdminOrder> userOrders;
      try {
        userOrders = await _getUserOrdersDirectly(currentUserPhone);
        debugPrint(
          '✅ تم جلب ${userOrders.length} طلب للمستخدم من قاعدة البيانات مباشرة',
        );
      } catch (e) {
        debugPrint('❌ فشل الجلب المباشر، استخدام الطريقة الاحتياطية: $e');
        // في حالة الفشل، استخدم AdminService كطريقة احتياطية
        final allOrders = await AdminService.getOrders();
        userOrders = allOrders.where((order) {
          return order.userPhone == currentUserPhone ||
              order.customerPhone == currentUserPhone;
        }).toList();
        debugPrint(
          '✅ تم جلب ${userOrders.length} طلب للمستخدم من الطريقة الاحتياطية',
        );
      }

      // تحويل AdminOrder إلى Order مع معالجة الأخطاء
      _orders = [];
      for (final adminOrder in userOrders) {
        try {
          // ✅ استخدام حالة الدعم من AdminOrder مباشرة (تم جلبها من قاعدة البيانات)
          final supportRequested = adminOrder.supportRequested ?? false;
          final order = Order(
            id: adminOrder.id,
            customerName: adminOrder.customerName,
            primaryPhone: adminOrder.customerPhone,
            secondaryPhone: adminOrder.customerAlternatePhone,
            province: adminOrder.customerProvince ?? '',
            city: adminOrder.customerCity ?? '',
            notes: adminOrder.customerNotes ?? '',
            totalCost: adminOrder.totalAmount.toInt(),
            totalProfit: adminOrder.profitAmount.toInt(),
            subtotal: (adminOrder.totalAmount - adminOrder.deliveryCost)
                .toInt(),
            total: adminOrder.totalAmount.toInt(),
            status: _convertAdminStatusToOrderStatus(adminOrder.status),
            rawStatus: adminOrder.status, // الاحتفاظ بالنص الأصلي
            createdAt: adminOrder.createdAt,
            items: adminOrder.items
                .map(
                  (adminItem) => order_models.OrderItem(
                    id: adminItem.id,
                    productId: adminItem.id,
                    name: adminItem.productName,
                    image: adminItem.productImage ?? '',
                    quantity: adminItem.quantity,
                    customerPrice: adminItem.customerPrice ?? 0.0,
                    wholesalePrice: adminItem.wholesalePrice ?? 0.0,
                  ),
                )
                .toList(),
            scheduledDate: null,
            scheduleNotes: null,
            waseetOrderId: adminOrder.waseetQrId, // ✅ إضافة رقم الطلب في الوسيط
            supportRequested: supportRequested, // ✅ إضافة حالة الدعم من قاعدة البيانات
          );
          _orders.add(order);
        } catch (e) {
          debugPrint('❌ خطأ في تحويل الطلب ${adminOrder.id}: $e');
          // إنشاء طلب بدون عناصر في حالة الخطأ
          final order = Order(
            id: adminOrder.id,
            customerName: adminOrder.customerName,
            primaryPhone: adminOrder.customerPhone,
            secondaryPhone: adminOrder.customerAlternatePhone,
            province: adminOrder.customerProvince ?? '',
            city: adminOrder.customerCity ?? '',
            notes: adminOrder.customerNotes ?? '',
            totalCost: adminOrder.totalAmount.toInt(),
            totalProfit: adminOrder.profitAmount.toInt(),
            subtotal: (adminOrder.totalAmount - adminOrder.deliveryCost)
                .toInt(),
            total: adminOrder.totalAmount.toInt(),
            status: _convertAdminStatusToOrderStatus(adminOrder.status),
            rawStatus: adminOrder.status, // الاحتفاظ بالنص الأصلي
            createdAt: adminOrder.createdAt,
            items: [], // قائمة فارغة في حالة الخطأ
            scheduledDate: null,
            scheduleNotes: null,
            waseetOrderId: adminOrder.waseetQrId, // ✅ إضافة رقم الطلب في الوسيط
            supportRequested: adminOrder.supportRequested ?? false, // ✅ استخدام حالة الدعم من AdminOrder
          );
          _orders.add(order);
        }
      }

      // ✅ طباعة تفاصيل أول 3 طلبات بعد التحويل النهائي إلى Order
      debugPrint('📊 تم تحويل ${_orders.length} طلب إلى تنسيق Order النهائي');
      if (_orders.isNotEmpty) {
        debugPrint('📋 أول 3 طلبات بعد التحويل النهائي:');
        for (int i = 0; i < _orders.length && i < 3; i++) {
          final order = _orders[i];
          debugPrint(
            '   ${i + 1}. ${order.customerName} - ${order.id} - ${order.createdAt}',
          );
        }
      }

      _lastUpdate = DateTime.now();
    } catch (e) {
      debugPrint('❌ خطأ في جلب الطلبات: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// دالة تحويل حالة الطلب من AdminOrder إلى OrderStatus
  OrderStatus _convertAdminStatusToOrderStatus(String adminStatus) {
    // التحقق من النص العربي أولاً
    if (adminStatus == 'قيد التوصيل الى الزبون (في عهدة المندوب)' ||
        adminStatus == 'قيد التوصيل') {
      return OrderStatus.inDelivery;
    }

    switch (adminStatus.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
      case 'active': // ✅ إضافة حالة active لتحويلها إلى confirmed
        return OrderStatus.confirmed;
      case 'shipping':
      case 'shipped':
        return OrderStatus.inDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  /// إحصائيات سريعة
  Map<String, int> get orderCounts {
    return {
      'all': _orders.length,
      'active': _orders
          .where((order) => order.status == OrderStatus.confirmed)
          .length,
      'in_delivery': _orders
          .where((order) => order.status == OrderStatus.inDelivery)
          .length,
      'delivered': _orders
          .where((order) => order.status == OrderStatus.delivered)
          .length,
      'cancelled': _orders
          .where((order) => order.status == OrderStatus.cancelled)
          .length,
    };
  }

  /// مسح البيانات
  void clearOrders() {
    _orders.clear();
    _lastUpdate = null;
    notifyListeners();
  }

  /// تحديث طلب واحد
  void updateOrder(Order updatedOrder) {
    final index = _orders.indexWhere((order) => order.id == updatedOrder.id);
    if (index != -1) {
      _orders[index] = updatedOrder;
      notifyListeners();
    }
  }

  /// تحديث حالة الدعم للطلب مع الحفظ الذكي
  void updateOrderSupportStatus(String orderId, bool supportRequested) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index != -1) {
      final order = _orders[index];
      final updatedOrder = Order(
        id: order.id,
        customerName: order.customerName,
        primaryPhone: order.primaryPhone,
        secondaryPhone: order.secondaryPhone,
        province: order.province,
        city: order.city,
        notes: order.notes,
        totalCost: order.totalCost,
        totalProfit: order.totalProfit,
        subtotal: order.subtotal,
        total: order.total,
        status: order.status,
        rawStatus: order.rawStatus,
        createdAt: order.createdAt,
        items: order.items,
        scheduledDate: order.scheduledDate,
        scheduleNotes: order.scheduleNotes,
        supportRequested: supportRequested, // ✅ تحديث حالة الدعم
        waseetOrderId: order.waseetOrderId, // ✅ الاحتفاظ برقم الطلب في الوسيط
      );
      _orders[index] = updatedOrder;

      // ✅ حفظ الحالة محلياً كطبقة حماية إضافية
      await SupportStatusCache.setSupportRequested(orderId, supportRequested);

      notifyListeners();
    }
  }

  /// مسح الـ cache لإجبار إعادة التحميل
  void clearCache() {
    _lastUpdate = null;
    debugPrint('🗑️ تم مسح cache الطلبات');
  }

  /// إضافة طلب جديد
  void addOrder(Order newOrder) {
    _orders.insert(0, newOrder);
    notifyListeners();
  }

  /// حذف طلب
  void removeOrder(String orderId) {
    _orders.removeWhere((order) => order.id == orderId);
    notifyListeners();
  }

  /// البحث في الطلبات
  List<Order> searchOrders(String query) {
    if (query.isEmpty) return _orders;

    return _orders
        .where(
          (order) =>
              order.customerName.toLowerCase().contains(query.toLowerCase()) ||
              order.primaryPhone.contains(query) ||
              order.id.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  /// فلترة الطلبات حسب الحالة
  List<Order> getOrdersByStatus(OrderStatus status) {
    return _orders.where((order) => order.status == status).toList();
  }

  /// فلترة الطلبات حسب التاريخ
  List<Order> getOrdersByDate(DateTime date) {
    return _orders.where((order) {
      final orderDate = DateTime(
        order.createdAt.year,
        order.createdAt.month,
        order.createdAt.day,
      );
      final targetDate = DateTime(date.year, date.month, date.day);
      return orderDate.isAtSameMomentAs(targetDate);
    }).toList();
  }

  /// الحصول على إجمالي الأرباح
  double get totalProfit {
    return _orders.fold(0.0, (sum, order) => sum + order.totalProfit);
  }

  /// الحصول على إجمالي المبيعات
  double get totalSales {
    return _orders.fold(0.0, (sum, order) => sum + order.total);
  }

  /// الحصول على عدد الطلبات اليوم
  int get todayOrdersCount {
    final today = DateTime.now();
    return getOrdersByDate(today).length;
  }

  /// الحصول على أرباح اليوم
  double get todayProfit {
    final todayOrders = getOrdersByDate(DateTime.now());
    return todayOrders.fold(0.0, (sum, order) => sum + order.totalProfit);
  }

  /// إنشاء طلب جديد
  Future<Map<String, dynamic>> createOrder({
    required String customerName,
    required String primaryPhone,
    String? secondaryPhone,
    required String province,
    required String city,
    String? notes,
    required List<order_models.OrderItem> items,
    required double totalCost,
    required double totalProfit,
    required double deliveryCost,
    DateTime? scheduledDate,
    String? scheduleNotes,
  }) async {
    try {
      debugPrint('🚀 إنشاء طلب جديد...');

      // إنشاء طلب محلي
      final newOrder = Order(
        id: 'order_${DateTime.now().millisecondsSinceEpoch}',
        customerName: customerName,
        primaryPhone: primaryPhone,
        secondaryPhone: secondaryPhone,
        province: province,
        city: city,
        notes: notes ?? '',
        totalCost: totalCost.toInt(),
        totalProfit: totalProfit.toInt(),
        subtotal: (totalCost - deliveryCost).toInt(),
        total: totalCost.toInt(),
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
        items: items,
        scheduledDate: scheduledDate,
        scheduleNotes: scheduleNotes,
      );

      // إضافة الطلب محلياً
      addOrder(newOrder);

      // 🔔 تقليل كمية المنتجات ومراقبة المخزون
      for (final item in items) {
        try {
          // تقليل الكمية المتاحة
          await InventoryService.reserveProduct(
            productId: item.productId,
            reservedQuantity: item.quantity,
          );

          debugPrint(
            '✅ تم تقليل كمية المنتج ${item.productId} بمقدار ${item.quantity}',
          );
        } catch (e) {
          debugPrint('⚠️ خطأ في تقليل كمية المنتج ${item.productId}: $e');
        }
      }

      debugPrint('✅ تم إنشاء الطلب بنجاح: ${newOrder.id}');

      return {
        'success': true,
        'orderId': newOrder.id,
        'message': 'تم إنشاء الطلب بنجاح',
      };
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء الطلب: $e');
      return {'success': false, 'error': 'فشل في إنشاء الطلب: $e'};
    }
  }

  /// حذف طلب
  Future<bool> deleteOrder(String orderId) async {
    try {
      debugPrint('🗑️ حذف الطلب من قاعدة البيانات: $orderId');

      // ✅ حذف عناصر الطلب أولاً من قاعدة البيانات
      await Supabase.instance.client
          .from('order_items')
          .delete()
          .eq('order_id', orderId);

      // ✅ حذف الطلب من قاعدة البيانات
      await Supabase.instance.client.from('orders').delete().eq('id', orderId);

      // ✅ حذف من الذاكرة المحلية أيضاً
      removeOrder(orderId);

      debugPrint('✅ تم حذف الطلب بنجاح من قاعدة البيانات والذاكرة المحلية');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في حذف الطلب: $e');
      return false;
    }
  }

  /// تحديث حالة الطلب
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      debugPrint('🔄 تحديث حالة الطلب $orderId إلى $newStatus');

      final orderIndex = _orders.indexWhere((order) => order.id == orderId);
      if (orderIndex == -1) {
        debugPrint('❌ لم يتم العثور على الطلب');
        return false;
      }

      final order = _orders[orderIndex];
      final updatedOrder = Order(
        id: order.id,
        customerName: order.customerName,
        primaryPhone: order.primaryPhone,
        secondaryPhone: order.secondaryPhone,
        province: order.province,
        city: order.city,
        notes: order.notes,
        totalCost: order.totalCost,
        totalProfit: order.totalProfit,
        subtotal: order.subtotal,
        total: order.total,
        status: _convertStringToOrderStatus(newStatus),
        createdAt: order.createdAt,
        items: order.items,
        scheduledDate: order.scheduledDate,
        scheduleNotes: order.scheduleNotes,
      );

      updateOrder(updatedOrder);

      debugPrint('✅ تم تحديث حالة الطلب بنجاح');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في تحديث حالة الطلب: $e');
      return false;
    }
  }

  /// تحويل String إلى OrderStatus
  OrderStatus _convertStringToOrderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
      case 'active': // ✅ إضافة حالة active لتحويلها إلى confirmed
        return OrderStatus.confirmed;
      case 'in_delivery':
      case 'indelivery':
        return OrderStatus.inDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  /// ✅ جلب الطلبات مباشرة للمستخدم من قاعدة البيانات (محسّن للأداء)
  Future<List<AdminOrder>> _getUserOrdersDirectly(String userPhone) async {
    try {
      debugPrint('📊 جلب الطلبات مباشرة للمستخدم: $userPhone');

      // ✅ استعلام مباشر من قاعدة البيانات للمستخدم فقط
      final supabase = Supabase.instance.client;
      debugPrint('📡 تنفيذ استعلام قاعدة البيانات للمستخدم: $userPhone');

      final response = await supabase
          .from('orders')
          .select('''
            *,
            support_requested,
            support_requested_at,
            support_status,
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
          .eq('user_phone', userPhone)
          .order('created_at', ascending: false);

      debugPrint('📡 استجابة قاعدة البيانات: ${response.length} سجل');

      debugPrint('📊 تم جلب ${response.length} طلب مباشرة من قاعدة البيانات');

      // ✅ طباعة تفاصيل أول 3 طلبات من قاعدة البيانات
      if (response.isNotEmpty) {
        debugPrint('📋 أول 3 طلبات من قاعدة البيانات:');
        for (int i = 0; i < response.length && i < 3; i++) {
          final orderData = response[i];
          debugPrint(
            '   ${i + 1}. ${orderData['customer_name']} - ${orderData['id']} - ${orderData['created_at']}',
          );
        }
      }

      // تحويل البيانات إلى تنسيق AdminOrder
      final adminOrders = response.map((orderData) {
        final orderItems =
            (orderData['order_items'] as List?)?.map((item) {
              return AdminOrderItem(
                id: (item['id'] ?? '').toString(), // ✅ تحويل إلى String
                productName: item['product_name'] ?? '',
                productImage: item['product_image'],
                productPrice:
                    (item['customer_price'] as num?)?.toDouble() ?? 0.0,
                wholesalePrice:
                    (item['wholesale_price'] as num?)?.toDouble() ?? 0.0,
                customerPrice:
                    (item['customer_price'] as num?)?.toDouble() ?? 0.0,
                quantity: item['quantity'] ?? 1,
                totalPrice: (item['total_price'] as num?)?.toDouble() ?? 0.0,
                profitPerItem:
                    (item['profit_per_item'] as num?)?.toDouble() ?? 0.0,
              );
            }).toList() ??
            [];

        // ✅ استخراج رقم الطلب من waseet_data
        String? waseetQrId;
        try {
          final waseetDataStr = orderData['waseet_data'];
          if (waseetDataStr != null && waseetDataStr.toString().isNotEmpty) {
            final waseetData = json.decode(waseetDataStr.toString());
            waseetQrId = waseetData['qrId']?.toString();
            debugPrint('🔍 استخراج رقم الوسيط للطلب ${orderData['id']}: $waseetQrId');
          }
        } catch (e) {
          debugPrint('⚠️ خطأ في استخراج رقم الوسيط للطلب ${orderData['id']}: $e');
        }

        return AdminOrder(
          id: orderData['id'] ?? '',
          orderNumber: orderData['order_number'] ?? orderData['id'] ?? '',
          customerName: orderData['customer_name'] ?? '',
          customerPhone: orderData['primary_phone'] ?? '',
          customerAlternatePhone: orderData['secondary_phone'],
          customerProvince: orderData['province'],
          customerCity: orderData['city'],
          customerAddress:
              '${orderData['province'] ?? 'غير محدد'} - ${orderData['city'] ?? 'غير محدد'}',
          customerNotes: orderData['notes'],
          totalAmount: (orderData['total'] as num?)?.toDouble() ?? 0.0,
          deliveryCost: (orderData['delivery_fee'] as num?)?.toDouble() ?? 0.0,
          profitAmount: (orderData['profit'] as num?)?.toDouble() ?? 0.0,
          status: orderData['status'] ?? 'active',
          expectedProfit: (orderData['profit'] as num?)?.toDouble() ?? 0.0,
          itemsCount: orderItems.length,
          createdAt: DateTime.parse(orderData['created_at']),
          userName: 'المستخدم', // يمكن تحسينه لاحقاً
          userPhone: orderData['user_phone'] ?? '',
          items: orderItems,
          waseetQrId: waseetQrId, // ✅ إضافة رقم الطلب في الوسيط
          supportRequested: orderData['support_requested'], // ✅ إضافة حالة الدعم
        );
      }).toList();

      debugPrint('📊 تم تحويل ${adminOrders.length} طلب إلى تنسيق AdminOrder');

      // ✅ طباعة تفاصيل أول 3 طلبات بعد التحويل
      if (adminOrders.isNotEmpty) {
        debugPrint('📋 أول 3 طلبات بعد التحويل إلى AdminOrder:');
        for (int i = 0; i < adminOrders.length && i < 3; i++) {
          final order = adminOrders[i];
          debugPrint(
            '   ${i + 1}. ${order.customerName} - ${order.id} - ${order.createdAt}',
          );
        }
      }

      // ✅ مزامنة البيانات المحلية مع قاعدة البيانات
      final supportStatusMap = <String, bool>{};
      for (final order in adminOrders) {
        supportStatusMap[order.id] = order.supportRequested ?? false;
      }
      await SupportStatusCache.syncWithDatabase(supportStatusMap);

      return adminOrders;
    } catch (e) {
      debugPrint('❌ خطأ في جلب الطلبات مباشرة: $e');

      // إعادة رمي الخطأ ليتم التعامل معه في loadOrders
      rethrow;
    }
  }
}
