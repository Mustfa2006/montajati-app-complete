// مزود حالة الطلبات مع التحديث الفوري والذكي
// Smart Order Status Provider with Real-time Updates

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../utils/order_status_helper.dart';
import '../services/admin_service.dart';

class OrderStatusProvider extends ChangeNotifier {
  static final OrderStatusProvider _instance = OrderStatusProvider._internal();
  factory OrderStatusProvider() => _instance;
  OrderStatusProvider._internal();

  final SupabaseClient _supabase = SupabaseConfig.client;

  // قائمة الطلبات مع حالاتها
  List<AdminOrder> _orders = [];
  List<AdminOrder> get orders => _orders;

  // الحالة المختارة للفلترة
  String? _selectedFilter;
  String? get selectedFilter => _selectedFilter;

  // حالة التحميل
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // خطأ إن وجد
  String? _error;
  String? get error => _error;

  // اشتراك في التحديثات الفورية
  RealtimeChannel? _ordersSubscription;

  // Stream للطلبات
  final StreamController<List<AdminOrder>> _ordersStreamController =
      StreamController<List<AdminOrder>>.broadcast();
  Stream<List<AdminOrder>> get ordersStream => _ordersStreamController.stream;

  // Stream للحالات المفلترة
  final StreamController<List<AdminOrder>> _filteredOrdersStreamController =
      StreamController<List<AdminOrder>>.broadcast();
  Stream<List<AdminOrder>> get filteredOrdersStream =>
      _filteredOrdersStreamController.stream;

  /// تهيئة المزود وبدء الاستماع للتحديثات الفورية
  Future<void> initialize() async {
    debugPrint('🔄 تهيئة مزود حالة الطلبات الذكي...');

    try {
      // تحميل الطلبات الأولي
      await loadOrders();

      // بدء الاستماع للتحديثات الفورية
      _startRealtimeSubscription();

      debugPrint('✅ تم تهيئة مزود حالة الطلبات بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة مزود حالة الطلبات: $e');
      _error = e.toString();
      _updateStreams();
    }
  }

  /// تحميل جميع الطلبات
  Future<void> loadOrders() async {
    _isLoading = true;
    _error = null;
    _updateStreams();

    try {
      debugPrint('🔄 تحميل الطلبات من قاعدة البيانات...');

      final loadedOrders = await AdminService.getOrders();

      _orders = loadedOrders;
      _isLoading = false;

      debugPrint('✅ تم تحميل ${_orders.length} طلب بنجاح');
      _updateStreams();
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الطلبات: $e');
      _error = e.toString();
      _isLoading = false;
      _updateStreams();
    }
  }

  /// بدء الاستماع للتحديثات الفورية
  void _startRealtimeSubscription() {
    debugPrint('🔄 بدء الاستماع للتحديثات الفورية...');

    _ordersSubscription = _supabase
        .channel('orders_realtime_${DateTime.now().millisecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: _handleRealtimeUpdate,
        )
        .subscribe();

    debugPrint('✅ تم بدء الاستماع للتحديثات الفورية');
  }

  /// معالجة التحديثات الفورية
  void _handleRealtimeUpdate(PostgresChangePayload payload) {
    debugPrint('🔄 تحديث فوري مستلم: ${payload.eventType}');
    debugPrint('📋 البيانات: ${payload.newRecord}');

    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        _handleOrderInsert(payload.newRecord);
        break;
      case PostgresChangeEvent.update:
        _handleOrderUpdate(payload.newRecord);
        break;
      case PostgresChangeEvent.delete:
        _handleOrderDelete(payload.oldRecord);
        break;
      case PostgresChangeEvent.all:
        // لا نحتاج لمعالجة خاصة لـ all
        break;
    }
  }

  /// معالجة إدراج طلب جديد
  void _handleOrderInsert(Map<String, dynamic> newRecord) {
    debugPrint('➕ طلب جديد مضاف: ${newRecord['id']}');
    // إعادة تحميل الطلبات للحصول على البيانات الكاملة
    loadOrders();
  }

  /// معالجة تحديث طلب موجود
  void _handleOrderUpdate(Map<String, dynamic> updatedRecord) {
    final orderId = updatedRecord['id']?.toString();
    if (orderId == null) return;

    debugPrint('🔄 تحديث طلب: $orderId');
    debugPrint('📋 الحالة الجديدة: ${updatedRecord['status']}');

    // البحث عن الطلب في القائمة المحلية
    final orderIndex = _orders.indexWhere((order) => order.id == orderId);

    if (orderIndex != -1) {
      // تحديث الطلب المحلي
      final existingOrder = _orders[orderIndex];
      final updatedOrder = AdminOrder(
        id: existingOrder.id,
        orderNumber: existingOrder.orderNumber,
        customerName: existingOrder.customerName,
        customerPhone: existingOrder.customerPhone,
        customerAlternatePhone: existingOrder.customerAlternatePhone,
        customerProvince: existingOrder.customerProvince,
        customerCity: existingOrder.customerCity,
        customerAddress: existingOrder.customerAddress,
        customerNotes: existingOrder.customerNotes,
        totalAmount: existingOrder.totalAmount,
        deliveryCost: existingOrder.deliveryCost,
        profitAmount: existingOrder.profitAmount,
        status: updatedRecord['status']?.toString() ?? existingOrder.status,
        expectedProfit: existingOrder.expectedProfit,
        itemsCount: existingOrder.itemsCount,
        createdAt: existingOrder.createdAt,
        userName: existingOrder.userName,
        userPhone: existingOrder.userPhone,
        items: existingOrder.items,
      );

      _orders[orderIndex] = updatedOrder;

      debugPrint('✅ تم تحديث الطلب محلياً');
      _updateStreams();
    } else {
      debugPrint('⚠️ الطلب غير موجود محلياً، إعادة تحميل...');
      loadOrders();
    }
  }

  /// معالجة حذف طلب
  void _handleOrderDelete(Map<String, dynamic>? deletedRecord) {
    if (deletedRecord == null) return;

    final orderId = deletedRecord['id']?.toString();
    if (orderId == null) return;

    debugPrint('🗑️ حذف طلب: $orderId');

    _orders.removeWhere((order) => order.id == orderId);
    _updateStreams();
  }

  /// تحديث حالة طلب محدد
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    debugPrint('🔄 تحديث حالة الطلب: $orderId إلى $newStatus');

    try {
      final success = await AdminService.updateOrderStatus(orderId, newStatus);

      if (success) {
        debugPrint('✅ تم تحديث حالة الطلب بنجاح');
        // التحديث الفوري سيتم عبر الاشتراك
        return true;
      } else {
        debugPrint('❌ فشل في تحديث حالة الطلب');
        return false;
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحديث حالة الطلب: $e');
      return false;
    }
  }

  /// تحديث جميع الـ Streams
  void _updateStreams() {
    _ordersStreamController.add(_orders);
    _filteredOrdersStreamController.add(filteredOrders);
    notifyListeners();
  }

  /// تطبيق فلتر الحالة
  void setStatusFilter(String? filter) {
    _selectedFilter = filter;
    debugPrint('🔍 تطبيق فلتر الحالة: $filter');
    _updateStreams();
  }

  /// الحصول على الطلبات المفلترة
  List<AdminOrder> get filteredOrders {
    if (_selectedFilter == null) {
      return _orders;
    }

    debugPrint('🔍 فلترة الطلبات: الفلتر المختار = $_selectedFilter');
    debugPrint('📊 عدد الطلبات الكلي: ${_orders.length}');

    // طباعة حالات الطلبات الموجودة
    final statusCounts = <String, int>{};
    for (final order in _orders) {
      statusCounts[order.status] = (statusCounts[order.status] ?? 0) + 1;
    }
    debugPrint('📊 إحصائيات الحالات: $statusCounts');

    final filtered = _orders.where((order) {
      // فلترة مباشرة بدون تحويل
      bool matches = false;

      switch (_selectedFilter) {
        case 'نشط':
          matches = order.status == 'active' || order.status == 'confirmed';
          break;
        case 'قيد التوصيل':
          matches =
              order.status == 'in_delivery' ||
              order.status == 'processing' ||
              order.status == 'shipped';
          break;
        case 'تم التوصيل':
          matches = order.status == 'delivered';
          break;
        case 'ملغي':
          matches = order.status == 'cancelled';
          break;
        default:
          // استخدام OrderStatusHelper كما هو
          final arabicStatus = OrderStatusHelper.getArabicStatus(order.status);
          matches = arabicStatus == _selectedFilter;
      }

      if (matches) {
        debugPrint(
          '✅ طلب ${order.orderNumber} يطابق الفلتر (حالة: ${order.status})',
        );
      }

      return matches;
    }).toList();

    debugPrint('🎯 عدد الطلبات المفلترة: ${filtered.length}');
    return filtered;
  }

  /// الحصول على عدد الطلبات لكل حالة
  Map<String, int> get statusCounts {
    final counts = <String, int>{};
    final availableStatuses = OrderStatusHelper.getAvailableStatuses();

    for (final status in availableStatuses) {
      counts[status] = 0;
    }

    for (final order in _orders) {
      final arabicStatus = OrderStatusHelper.getArabicStatus(order.status);
      counts[arabicStatus] = (counts[arabicStatus] ?? 0) + 1;
    }

    return counts;
  }

  /// Stream للإحصائيات
  Stream<Map<String, int>> get statusCountsStream {
    return ordersStream.map((_) => statusCounts);
  }

  /// إنهاء المزود وإلغاء الاشتراكات
  @override
  void dispose() {
    debugPrint('🔄 إنهاء مزود حالة الطلبات...');

    _ordersSubscription?.unsubscribe();
    _ordersSubscription = null;

    _ordersStreamController.close();
    _filteredOrdersStreamController.close();

    super.dispose();
    debugPrint('✅ تم إنهاء مزود حالة الطلبات');
  }
}
