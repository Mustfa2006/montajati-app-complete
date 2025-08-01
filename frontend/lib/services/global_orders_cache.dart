import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../models/scheduled_order.dart';
import 'simple_orders_service.dart';
import 'scheduled_orders_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🚀 Global Orders Cache - Singleton للاحتفاظ بالطلبات في الذاكرة
/// يضمن العرض الفوري للطلبات بدون أي تأخير
class GlobalOrdersCache extends ChangeNotifier {
  static final GlobalOrdersCache _instance = GlobalOrdersCache._internal();
  factory GlobalOrdersCache() => _instance;
  GlobalOrdersCache._internal();

  // 📊 البيانات المخزنة في الذاكرة
  List<Order> _orders = [];
  List<ScheduledOrder> _scheduledOrders = [];
  DateTime? _lastUpdate;
  bool _isInitialized = false;
  bool _isUpdating = false;

  // 🔄 Stream للتحديثات الفورية
  final StreamController<List<Order>> _ordersStreamController = 
      StreamController<List<Order>>.broadcast();
  final StreamController<List<ScheduledOrder>> _scheduledOrdersStreamController = 
      StreamController<List<ScheduledOrder>>.broadcast();

  // ⚡ Getters للوصول الفوري للبيانات
  List<Order> get orders => List.unmodifiable(_orders);
  List<ScheduledOrder> get scheduledOrders => List.unmodifiable(_scheduledOrders);
  DateTime? get lastUpdate => _lastUpdate;
  bool get isInitialized => _isInitialized;
  bool get isUpdating => _isUpdating;

  // 📡 Streams للاستماع للتحديثات
  Stream<List<Order>> get ordersStream => _ordersStreamController.stream;
  Stream<List<ScheduledOrder>> get scheduledOrdersStream => _scheduledOrdersStreamController.stream;

  /// 🚀 تهيئة الكاش - يتم استدعاؤها مرة واحدة عند بدء التطبيق
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('⚡ GlobalOrdersCache مهيأ بالفعل - عرض فوري');
      return;
    }

    debugPrint('🚀 تهيئة GlobalOrdersCache...');
    
    try {
      // تحميل البيانات مرة واحدة فقط
      await _loadAllData();
      
      _isInitialized = true;
      debugPrint('✅ تم تهيئة GlobalOrdersCache بنجاح');
      debugPrint('📊 الطلبات العادية: ${_orders.length}');
      debugPrint('📅 الطلبات المجدولة: ${_scheduledOrders.length}');
      
      // إشعار المستمعين
      notifyListeners();
      _ordersStreamController.add(_orders);
      _scheduledOrdersStreamController.add(_scheduledOrders);
      
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة GlobalOrdersCache: $e');
    }
  }

  /// 🔄 تحديث البيانات في الخلفية
  Future<void> updateInBackground() async {
    if (_isUpdating) {
      debugPrint('⚠️ التحديث جاري بالفعل - تجاهل الطلب');
      return;
    }

    _isUpdating = true;
    debugPrint('🔄 تحديث البيانات في الخلفية...');
    
    try {
      await _loadAllData();
      
      _lastUpdate = DateTime.now();
      debugPrint('✅ تم تحديث البيانات في الخلفية');
      
      // إشعار المستمعين بالتحديث
      notifyListeners();
      _ordersStreamController.add(_orders);
      _scheduledOrdersStreamController.add(_scheduledOrders);
      
    } catch (e) {
      debugPrint('❌ خطأ في تحديث البيانات: $e');
    } finally {
      _isUpdating = false;
    }
  }

  /// 📊 تحميل جميع البيانات
  Future<void> _loadAllData() async {
    // تحميل الطلبات العادية
    final ordersService = SimpleOrdersService();
    await ordersService.loadOrders(forceRefresh: true);
    _orders = List.from(ordersService.orders);
    
    // تحميل الطلبات المجدولة
    final scheduledService = ScheduledOrdersService();
    final prefs = await SharedPreferences.getInstance();
    final currentUserPhone = prefs.getString('current_user_phone');
    
    await scheduledService.loadScheduledOrders(userPhone: currentUserPhone);
    _scheduledOrders = List.from(scheduledService.scheduledOrders);
  }

  /// ⚡ الحصول على الطلبات المفلترة فوراً
  List<Order> getFilteredOrders(String? statusFilter) {
    if (statusFilter == null || statusFilter == 'all') {
      return _orders;
    }
    
    return _orders.where((order) {
      final statusString = order.status.toString().split('.').last;
      return statusString == statusFilter;
    }).toList();
  }

  /// 📅 الحصول على الطلبات المجدولة كـ Orders
  List<Order> getScheduledOrdersAsOrders() {
    return _scheduledOrders.map((scheduledOrder) {
      return Order(
        id: scheduledOrder.id,
        customerName: scheduledOrder.customerName,
        primaryPhone: scheduledOrder.customerPhone,
        secondaryPhone: scheduledOrder.customerAlternatePhone,
        province: scheduledOrder.customerProvince ?? 'غير محدد',
        city: scheduledOrder.customerCity ?? 'غير محدد',
        notes: scheduledOrder.customerNotes ?? scheduledOrder.notes,
        totalCost: scheduledOrder.totalAmount.toInt(),
        totalProfit: 0,
        subtotal: scheduledOrder.totalAmount.toInt(),
        total: scheduledOrder.totalAmount.toInt(),
        status: OrderStatus.pending,
        createdAt: scheduledOrder.createdAt,
        items: [],
        scheduledDate: scheduledOrder.scheduledDate,
        scheduleNotes: scheduledOrder.notes,
      );
    }).toList();
  }

  /// 🔄 فرض التحديث
  Future<void> forceRefresh() async {
    debugPrint('🔄 فرض تحديث GlobalOrdersCache...');
    _isInitialized = false;
    await initialize();
  }

  /// 🧹 تنظيف الموارد
  @override
  void dispose() {
    _ordersStreamController.close();
    _scheduledOrdersStreamController.close();
    super.dispose();
  }
}
