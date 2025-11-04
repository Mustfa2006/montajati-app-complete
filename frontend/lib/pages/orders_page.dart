import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../core/design_system.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../providers/theme_provider.dart';
import '../utils/error_handler.dart';
import '../utils/order_status_helper.dart';
import '../utils/theme_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/curved_navigation_bar.dart';
import '../widgets/order_card_skeleton.dart';
import '../widgets/pull_to_refresh_wrapper.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  // ===================================
  // المتغيرات الأساسية
  // ===================================

  /// فلتر الطلبات المحدد حالياً
  String selectedFilter = 'all';

  /// نص البحث
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // ===================================
  // بيانات الطلبات
  // ===================================

  /// قائمة الطلبات الرئيسية (يتم جلبها من Backend API)
  List<Order> _orders = [];

  /// قائمة الطلبات المجدولة (يتم جلبها من Backend API)
  List<Order> _scheduledOrders = [];

  // ===================================
  // حالة التحميل والـ Pagination
  // ===================================

  /// حالة التحميل الأولي
  bool _isLoading = false;

  /// حالة تحميل المزيد من الطلبات
  bool _isLoadingMore = false;

  /// هل يوجد المزيد من البيانات للتحميل
  bool _hasMoreData = true;

  /// رقم الصفحة الحالية (يبدأ من 0)
  int _currentPage = 0;

  /// عدد الطلبات في كل صفحة
  final int _pageSize = 10;

  /// متحكم التمرير للـ Infinite Scroll و Scroll-to-Refresh
  final ScrollController _scrollController = ScrollController();

  /// مؤقت لـ Debouncing التمرير
  Timer? _scrollDebounceTimer;

  /// حالة التحديث (Pull-to-Refresh)
  bool _isRefreshing = false;

  /// موضع التمرير السابق لاكتشاف التمرير للأعلى
  double _previousScrollPosition = 0.0;

  // ===================================
  // عدادات الطلبات حسب الحالة
  // ===================================

  Map<String, int> _orderCounts = {
    'all': 0,
    'processing': 0,
    'active': 0,
    'in_delivery': 0,
    'delivered': 0,
    'cancelled': 0,
    'scheduled': 0,
  };

  // ===================================
  // دورة حياة الصفحة
  // ===================================

  @override
  void initState() {
    super.initState();

    // إعداد Infinite Scroll
    _scrollController.addListener(_onScroll);

    // تحميل البيانات الأولية
    _loadOrderCounts();
    _loadOrdersFromDatabase();
    _loadScheduledOrdersOnInit();

    // تعيين الفلتر الافتراضي
    selectedFilter = 'all';
  }

  /// مراقبة التمرير للتحميل التدريجي (Infinite Scroll) و Scroll-to-Refresh
  /// مع Debouncing لمنع الطلبات المتعددة المتزامنة
  void _onScroll() {
    final currentPosition = _scrollController.position.pixels;

    // اكتشاف التمرير للأعلى عند الوصول لأعلى الصفحة
    if (currentPosition <= 0 && _previousScrollPosition > 0 && !_isRefreshing) {
      // تفعيل التحديث عند السحب للأعلى
      _refreshData();
    }

    _previousScrollPosition = currentPosition;

    // إلغاء المؤقت السابق إن وجد
    _scrollDebounceTimer?.cancel();

    // إنشاء مؤقت جديد للتحميل التدريجي
    _scrollDebounceTimer = Timer(Duration(milliseconds: AppConfig.scrollDebounceDuration), () {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - AppConfig.scrollLoadThreshold) {
        _loadMoreOrders();
      }
    });
  }

  // دالة مساعدة للحصول على رقم هاتف المستخدم الحالي
  Future<String?> _getCurrentUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_user_phone');
  }

  // ===================================
  // دوال الطلبات المجدولة
  // ===================================

  /// جلب الطلبات المجدولة من Backend API
  /// ✅ يستخدم Backend API - آمن وسريع
  Future<List<Order>> _getScheduledOrders(String userPhone) async {
    try {
      debugPrint('� جلب الطلبات المجدولة من Backend API للمستخدم: $userPhone');

      // بناء URL للـ Backend API
      final url = Uri.parse(AppConfig.getScheduledOrdersUrl(userPhone, page: 0, limit: 100));

      // إرسال الطلب إلى Backend
      final response = await http
          .get(url)
          .timeout(
            Duration(seconds: AppConfig.requestTimeoutSeconds),
            onTimeout: () => throw TimeoutException('انتهت مهلة الانتظار'),
          );

      // معالجة الاستجابة
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['success'] == true) {
          final List<dynamic> ordersData = json['data'] ?? [];

          if (ordersData.isEmpty) {
            debugPrint('📋 لا توجد طلبات مجدولة للمستخدم');
            return [];
          }

          // تحويل الطلبات المجدولة إلى نموذج Order
          List<Order> scheduledOrders = [];
          for (var orderData in ordersData) {
            try {
              // تحويل عناصر الطلب المجدول
              List<OrderItem> items = [];
              if (orderData['scheduled_order_items'] != null) {
                for (var itemData in orderData['scheduled_order_items']) {
                  items.add(
                    OrderItem(
                      id: itemData['id'] ?? '',
                      productId: itemData['product_id'] ?? '',
                      name: itemData['product_name'] ?? '',
                      image: itemData['product_image'] ?? '',
                      wholesalePrice: 0.0,
                      customerPrice: (itemData['price'] ?? 0.0).toDouble(),
                      quantity: itemData['quantity'] ?? 1,
                    ),
                  );
                }
              }

              // إنشاء طلب من النوع Order
              final order = Order(
                id: orderData['id'] ?? '',
                customerName: orderData['customer_name'] ?? '',
                primaryPhone: orderData['customer_phone'] ?? '',
                secondaryPhone: orderData['customer_alternate_phone'],
                province: orderData['province'] ?? orderData['customer_province'] ?? '',
                city: orderData['city'] ?? orderData['customer_city'] ?? '',
                notes: orderData['notes'] ?? orderData['customer_notes'] ?? '',
                totalCost: (orderData['total_amount'] ?? 0.0).toInt(),
                totalProfit: 0,
                subtotal: (orderData['total_amount'] ?? 0.0).toInt(),
                total: (orderData['total_amount'] ?? 0.0).toInt(),
                status: OrderStatus.pending,
                rawStatus: 'مجدول',
                createdAt: DateTime.parse(orderData['created_at'] ?? DateTime.now().toIso8601String()),
                items: items,
                scheduledDate: DateTime.parse(orderData['scheduled_date']),
                scheduleNotes: orderData['notes'] ?? '',
                supportRequested: false,
                waseetOrderId: null,
              );

              scheduledOrders.add(order);
            } catch (e) {
              debugPrint('❌ خطأ في تحويل الطلب المجدول: $e');
            }
          }

          debugPrint('✅ تم جلب ${scheduledOrders.length} طلب مجدول');
          return scheduledOrders;
        } else {
          throw Exception(json['error'] ?? 'خطأ في جلب الطلبات المجدولة');
        }
      } else if (response.statusCode == 404) {
        debugPrint('⚠️ لا توجد طلبات مجدولة للمستخدم');
        return [];
      } else {
        throw Exception('خطأ في الخادم: ${response.statusCode}');
      }
    } on TimeoutException {
      debugPrint('❌ انتهت مهلة الانتظار في جلب الطلبات المجدولة');
      return [];
    } on http.ClientException {
      debugPrint('❌ فشل الاتصال بالخادم في جلب الطلبات المجدولة');
      return [];
    } catch (e) {
      debugPrint('❌ خطأ في جلب الطلبات المجدولة: $e');
      return [];
    }
  }

  // جلب الطلبات المجدولة وحفظها في المتغير المحلي
  Future<void> _loadScheduledOrdersFromDatabase(String userPhone) async {
    try {
      debugPrint('🔄 جلب الطلبات المجدولة للمستخدم: $userPhone');

      final scheduledOrders = await _getScheduledOrders(userPhone);

      setState(() {
        _scheduledOrders = scheduledOrders;
      });

      debugPrint('✅ تم تحديث ${scheduledOrders.length} طلب مجدول');
    } catch (e) {
      debugPrint('❌ خطأ في جلب الطلبات المجدولة: $e');
      setState(() {
        _scheduledOrders = [];
      });
    }
  }

  // جلب الطلبات المجدولة عند بدء التطبيق
  Future<void> _loadScheduledOrdersOnInit() async {
    try {
      final currentUserPhone = await _getCurrentUserPhone();
      if (currentUserPhone != null && currentUserPhone.isNotEmpty) {
        await _loadScheduledOrdersFromDatabase(currentUserPhone);
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب الطلبات المجدولة عند البدء: $e');
    }
  }

  /// تحديث البيانات عند السحب للأسفل (Pull-to-Refresh)
  /// ✅ مع animation جميل للبطاقات
  Future<void> _refreshData() async {
    if (_isRefreshing) return; // منع التحديث المتعدد

    setState(() {
      _isRefreshing = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      String? currentUserPhone = prefs.getString('current_user_phone');

      if (currentUserPhone != null && currentUserPhone.isNotEmpty) {
        // تحديث جميع البيانات بالتوازي
        await Future.wait([
          _loadOrderCounts(),
          _loadOrdersFromDatabase(),
          _loadScheduledOrdersFromDatabase(currentUserPhone),
        ]);

        // تأخير بسيط لإظهار animation
        await Future.delayed(const Duration(milliseconds: 300));
      }
    } catch (e) {
      debugPrint('❌ خطأ في التحديث: $e');
      if (mounted) {
        _showErrorMessage('فشل في تحديث البيانات');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // إلغاء المؤقت
    _scrollDebounceTimer?.cancel();

    // إلغاء المتحكمات
    _scrollController.dispose();
    _searchController.dispose();

    super.dispose();
  }

  /// جلب طلبات المستخدم من Backend API
  /// يدعم Pagination و Infinite Scroll
  Future<void> _loadOrdersFromDatabase({bool isLoadMore = false}) async {
    // منع الطلبات المتعددة المتزامنة
    if (_isLoading || (isLoadMore && _isLoadingMore) || (isLoadMore && !_hasMoreData)) {
      return;
    }

    // تحديث حالة التحميل
    setState(() {
      if (isLoadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _currentPage = 0;
        _hasMoreData = true;
        _orders.clear();
      }
    });

    try {
      // جلب رقم هاتف المستخدم من التخزين المحلي
      final prefs = await SharedPreferences.getInstance();
      final currentUserPhone = prefs.getString('current_user_phone');

      if (currentUserPhone == null || currentUserPhone.isEmpty) {
        debugPrint('❌ رقم هاتف المستخدم غير متوفر');
        _showErrorMessage('رقم الهاتف غير متوفر');
        return;
      }

      // تحديد الفلتر المطلوب (إذا لم يكن 'all' أو 'scheduled')
      String? statusFilter;
      if (selectedFilter != 'all' && selectedFilter != 'scheduled') {
        statusFilter = selectedFilter;
      }

      debugPrint('🔍 جلب طلبات المستخدم من Backend API - الصفحة: $_currentPage, الفلتر: ${statusFilter ?? 'الكل'}');

      // بناء URL للـ Backend API مع الفلتر
      final url = Uri.parse(
        AppConfig.getUserOrdersUrl(currentUserPhone, page: _currentPage, limit: _pageSize, statusFilter: statusFilter),
      );

      // إرسال الطلب إلى Backend
      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 10), onTimeout: () => throw TimeoutException('انتهت مهلة الانتظار'));

      // معالجة الاستجابة
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['success'] == true) {
          final List<dynamic> ordersData = json['data'] ?? [];
          final Map<String, dynamic> pagination = json['pagination'] ?? {};

          // تحويل البيانات إلى Order objects
          final List<Order> newOrders = [];
          for (final orderData in ordersData) {
            try {
              final order = Order.fromJson(orderData);
              newOrders.add(order);
            } catch (e) {
              debugPrint('❌ خطأ في تحويل طلب: $e');
            }
          }

          // تحديث القائمة
          if (mounted) {
            setState(() {
              if (isLoadMore) {
                _orders.addAll(newOrders);
              } else {
                _orders = newOrders;
              }

              _hasMoreData = pagination['hasMore'] ?? false;
              _currentPage++;
            });
          }

          debugPrint('✅ تم تحميل ${newOrders.length} طلب - المجموع: ${_orders.length}');
        } else {
          throw Exception(json['error'] ?? 'خطأ في جلب الطلبات');
        }
      } else if (response.statusCode == 404) {
        debugPrint('⚠️ لا توجد طلبات للمستخدم');
        if (mounted) {
          setState(() {
            _orders = [];
            _hasMoreData = false;
          });
        }
      } else {
        throw Exception('خطأ في الخادم: ${response.statusCode}');
      }
    } on TimeoutException {
      debugPrint('❌ انتهت مهلة الانتظار');
      _showErrorMessage('انتهت مهلة الانتظار. يرجى المحاولة مرة أخرى');
    } on http.ClientException {
      debugPrint('❌ فشل الاتصال بالخادم');
      _showErrorMessage('فشل الاتصال بالخادم. تحقق من الإنترنت');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الطلبات: $e');
      _showErrorMessage('حدث خطأ في تحميل الطلبات');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  /// عرض رسالة خطأ للمستخدم
  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red, duration: const Duration(seconds: 3)),
      );
    }
  }

  /// تحميل المزيد من الطلبات (Infinite Scroll)
  Future<void> _loadMoreOrders() async {
    await _loadOrdersFromDatabase(isLoadMore: true);
  }

  // ===================================
  // دوال العدادات والإحصائيات
  // ===================================

  /// جلب عدادات الطلبات حسب الحالة من Backend API
  /// ✅ يستخدم Backend API - آمن وسريع
  Future<void> _loadOrderCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserPhone = prefs.getString('current_user_phone');

      if (currentUserPhone == null || currentUserPhone.isEmpty) {
        debugPrint('❌ رقم هاتف المستخدم غير متوفر لجلب العدادات');
        return;
      }

      debugPrint('📊 جلب العدادات من Backend API للمستخدم: $currentUserPhone');

      // بناء URL للـ Backend API
      final url = Uri.parse(AppConfig.getOrderCountsUrl(currentUserPhone));

      // إرسال الطلب إلى Backend
      final response = await http
          .get(url)
          .timeout(
            Duration(seconds: AppConfig.requestTimeoutSeconds),
            onTimeout: () => throw TimeoutException('انتهت مهلة الانتظار'),
          );

      // معالجة الاستجابة
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['success'] == true) {
          final Map<String, dynamic> counts = json['data'] ?? {};

          if (mounted) {
            setState(() {
              _orderCounts = {
                'all': counts['all'] ?? 0,
                'processing': counts['processing'] ?? 0,
                'active': counts['active'] ?? 0,
                'in_delivery': counts['in_delivery'] ?? 0,
                'delivered': counts['delivered'] ?? 0,
                'cancelled': counts['cancelled'] ?? 0,
                'scheduled': counts['scheduled'] ?? 0,
              };
            });
          }

          debugPrint('✅ تم تحميل العدادات: $_orderCounts');
        } else {
          throw Exception(json['error'] ?? 'خطأ في جلب العدادات');
        }
      } else {
        throw Exception('خطأ في الخادم: ${response.statusCode}');
      }
    } on TimeoutException {
      debugPrint('❌ انتهت مهلة الانتظار في جلب العدادات');
      // لا نحسب العدادات محلياً - نبقي القيم الافتراضية (0)
    } on http.ClientException {
      debugPrint('❌ فشل الاتصال بالخادم في جلب العدادات');
      // لا نحسب العدادات محلياً - نبقي القيم الافتراضية (0)
    } catch (e) {
      debugPrint('❌ خطأ في جلب العدادات: $e');
      // لا نحسب العدادات محلياً - نبقي القيم الافتراضية (0)
    }
  }

  Map<String, int> get orderCounts {
    return _orderCounts;
  }

  // ===================================
  // مجموعات الحالات (Status Sets)
  // ===================================

  /// حالات المعالجة - طلبات تحتاج متابعة أو تدخل
  static const Set<String> _processingStatuses = {
    'تم تغيير محافظة الزبون',
    'تغيير المندوب',
    'لا يرد',
    'لا يرد بعد الاتفاق',
    'مغلق',
    'مغلق بعد الاتفاق',
    'الرقم غير معرف',
    'الرقم غير داخل في الخدمة',
    'لا يمكن الاتصال بالرقم',
    'مؤجل',
    'مؤجل لحين اعادة الطلب لاحقا',
    'مفصول عن الخدمة',
    'طلب مكرر',
    'مستلم مسبقا',
    'العنوان غير دقيق',
    'لم يطلب',
    'حظر المندوب',
  };

  /// حالات النشطة - طلبات جديدة قيد الانتظار
  static const Set<String> _activeStatuses = {'active'};

  /// حالات قيد التوصيل - طلبات مع المندوب
  static const Set<String> _inDeliveryStatuses = {'قيد التوصيل الى الزبون (في عهدة المندوب)', 'in_delivery'};

  /// حالات المسلّمة - طلبات تم تسليمها بنجاح
  static const Set<String> _deliveredStatuses = {'تم التسليم للزبون', 'delivered'};

  /// حالات الملغاة - طلبات ملغاة أو مرفوضة
  static const Set<String> _cancelledStatuses = {'الغاء الطلب', 'رفض الطلب', 'تم الارجاع الى التاجر', 'cancelled'};

  // ===================================
  // دوال فحص الحالات (Status Checkers)
  // ===================================

  /// فحص إذا كان الطلب في حالة معالجة
  bool _isProcessingStatus(String status) => _processingStatuses.contains(status);

  /// فحص إذا كان الطلب نشط
  bool _isActiveStatus(String status) => _activeStatuses.contains(status);

  /// فحص إذا كان الطلب قيد التوصيل
  bool _isInDeliveryStatus(String status) => _inDeliveryStatuses.contains(status);

  /// فحص إذا كان الطلب مسلّم
  bool _isDeliveredStatus(String status) => _deliveredStatuses.contains(status);

  /// فحص إذا كان الطلب ملغى
  bool _isCancelledStatus(String status) => _cancelledStatuses.contains(status);

  // ===================================
  // ألوان الحالات (Status Colors)
  // ===================================

  /// خريطة ألوان الحالات - لتحسين الأداء وتقليل التكرار
  static final Map<String, Map<String, dynamic>> _statusColorMap = {
    // 🟡 حالة نشطة (أصفر ذهبي)
    'active': {
      'borderColor': const Color(0xFFffc107),
      'shadowColor': const Color(0xFFffc107),
      'gradientColors': [const Color(0xFF2e2a1a), const Color(0xFF2e2616), const Color(0xFF3f3a1e)],
    },
    'نشط': {
      'borderColor': const Color(0xFFffc107),
      'shadowColor': const Color(0xFFffc107),
      'gradientColors': [const Color(0xFF2e2a1a), const Color(0xFF2e2616), const Color(0xFF3f3a1e)],
    },

    // 🟢 حالات مسلّمة (أخضر)
    'delivered': {
      'borderColor': const Color(0xFF28a745),
      'shadowColor': const Color(0xFF28a745),
      'gradientColors': [const Color(0xFF1a2e1a), const Color(0xFF162e16), const Color(0xFF1e3f1e)],
    },
    'تم التسليم للزبون': {
      'borderColor': const Color(0xFF28a745),
      'shadowColor': const Color(0xFF28a745),
      'gradientColors': [const Color(0xFF1a2e1a), const Color(0xFF162e16), const Color(0xFF1e3f1e)],
    },

    // 🔵 حالات قيد التوصيل (أزرق)
    'in_delivery': {
      'borderColor': const Color(0xFF007bff),
      'shadowColor': const Color(0xFF007bff),
      'gradientColors': [const Color(0xFF1a2332), const Color(0xFF162838), const Color(0xFF1e3a5f)],
    },
    'قيد التوصيل الى الزبون (في عهدة المندوب)': {
      'borderColor': const Color(0xFF007bff),
      'shadowColor': const Color(0xFF007bff),
      'gradientColors': [const Color(0xFF1a2332), const Color(0xFF162838), const Color(0xFF1e3a5f)],
    },

    // 🔴 حالات ملغاة (أحمر)
    'cancelled': {
      'borderColor': const Color(0xFFdc3545),
      'shadowColor': const Color(0xFFdc3545),
      'gradientColors': [const Color(0xFF2e1a1a), const Color(0xFF2e1616), const Color(0xFF3f1e1e)],
    },
    'الغاء الطلب': {
      'borderColor': const Color(0xFFdc3545),
      'shadowColor': const Color(0xFFdc3545),
      'gradientColors': [const Color(0xFF2e1a1a), const Color(0xFF2e1616), const Color(0xFF3f1e1e)],
    },
    'رفض الطلب': {
      'borderColor': const Color(0xFFdc3545),
      'shadowColor': const Color(0xFFdc3545),
      'gradientColors': [const Color(0xFF2e1a1a), const Color(0xFF2e1616), const Color(0xFF3f1e1e)],
    },
    'تم الارجاع الى التاجر': {
      'borderColor': const Color(0xFFdc3545),
      'shadowColor': const Color(0xFFdc3545),
      'gradientColors': [const Color(0xFF2e1a1a), const Color(0xFF2e1616), const Color(0xFF3f1e1e)],
    },
  };

  /// اللون الافتراضي للحالات غير المعروفة (رمادي)
  static final Map<String, dynamic> _defaultStatusColor = {
    'borderColor': const Color(0xFF6c757d),
    'shadowColor': const Color(0xFF6c757d),
    'gradientColors': [const Color(0xFF2a2a2a), const Color(0xFF262626), const Color(0xFF3a3a3a)],
  };

  List<Order> get filteredOrders {
    // ✅ Backend الآن يقوم بالفلترة حسب الحالة
    // لذلك نستخدم الطلبات المجلوبة مباشرة بدون فلترة محلية
    List<Order> statusFiltered;

    if (selectedFilter == 'scheduled') {
      // الطلبات المجدولة تُجلب من endpoint منفصل
      statusFiltered = _scheduledOrders;
    } else {
      // جميع الطلبات الأخرى تأتي مفلترة من Backend
      statusFiltered = _orders;
    }

    // فلترة البحث فقط (محلياً)
    if (searchQuery.isNotEmpty) {
      statusFiltered = statusFiltered.where((order) {
        final customerName = order.customerName.toLowerCase();
        final primaryPhone = order.primaryPhone.toLowerCase();
        final secondaryPhone = order.secondaryPhone?.toLowerCase() ?? '';
        final query = searchQuery.toLowerCase();

        return customerName.contains(query) || primaryPhone.contains(query) || secondaryPhone.contains(query);
      }).toList();
    }

    return statusFiltered;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: _buildScrollableContent(isDark), // المحتوى دائماً (مع skeleton عند التحميل)
        bottomNavigationBar: CurvedNavigationBar(
          index: 1, // الطلبات
          items: <Widget>[
            Icon(Icons.storefront_outlined, size: 28, color: Color(0xFFFFD700)), // ذهبي
            Icon(Icons.receipt_long_outlined, size: 28, color: Color(0xFFFFD700)), // ذهبي
            Icon(Icons.trending_up_outlined, size: 28, color: Color(0xFFFFD700)), // ذهبي
            Icon(Icons.person_outline, size: 28, color: Color(0xFFFFD700)), // ذهبي
          ],
          color: AppDesignSystem.bottomNavColor, // لون الشريط موحد
          buttonBackgroundColor: AppDesignSystem.activeButtonColor, // لون الكرة موحد
          backgroundColor: Colors.transparent, // خلفية شفافة
          animationCurve: Curves.elasticOut, // منحنى مبهر
          animationDuration: Duration(milliseconds: 1200), // انتقال مبهر
          onTap: (index) {
            switch (index) {
              case 0:
                context.go('/products');
                break;
              case 1:
                // الصفحة الحالية
                break;
              case 2:
                context.go('/profits');
                break;
              case 3:
                context.go('/account');
                break;
            }
          },
          letIndexChange: (index) => true,
        ),
      ),
    );
  }

  // بناء المحتوى القابل للتمرير
  Widget _buildScrollableContent(bool isDark) {
    List<Order> displayedOrders = filteredOrders;

    return PullToRefreshWrapper(
      onRefresh: _refreshData,
      refreshMessage: 'تم تحديث الطلبات',
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // الشريط العلوي مع العنوان وزر الرجوع (ضمن المحتوى القابل للتمرير)
          SliverToBoxAdapter(child: _buildHeader(isDark)),

          // شريط البحث
          SliverToBoxAdapter(child: _buildSearchBar(isDark)),

          // شريط فلتر الحالة المحسن
          SliverToBoxAdapter(child: _buildEnhancedFilterBar(isDark)),

          // قائمة الطلبات مع Skeleton Loading
          _isLoading
              ? SliverPadding(
                  padding: const EdgeInsets.only(left: 8, right: 8, top: 15, bottom: 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => OrderCardSkeleton(isDark: isDark),
                      childCount: 5, // عرض 5 skeleton cards
                    ),
                  ),
                )
              : displayedOrders.isEmpty
              ? SliverFillRemaining(child: _buildEmptyState())
              : SliverPadding(
                  padding: const EdgeInsets.only(left: 8, right: 8, top: 15, bottom: 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      // إذا كان هذا آخر عنصر وهناك المزيد من البيانات، أظهر مؤشر التحميل
                      if (index == displayedOrders.length) {
                        return _isLoadingMore
                            ? Container(
                                padding: const EdgeInsets.all(20),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffd700)),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink();
                      }
                      return _buildOrderCard(displayedOrders[index], isDark);
                    }, childCount: displayedOrders.length + (_isLoadingMore ? 1 : 0)),
                  ),
                ),
        ],
      ),
    );
  }

  // بناء الشريط العلوي (ضمن المحتوى القابل للتمرير)
  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 35, 16, 20),
      child: Row(
        children: [
          const SizedBox(width: 16),
          // العنوان
          Expanded(
            child: Text(
              'الطلبات',
              style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: ThemeColors.textColor(isDark)),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // بناء شريط البحث
  Widget _buildSearchBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: ThemeColors.cardBackground(isDark),
        borderRadius: BorderRadius.circular(25), // أطراف مقوصة بالكامل
        border: Border.all(color: ThemeColors.cardBorder(isDark), width: 1),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25), // قص الزوايا بالكامل
        child: TextField(
          controller: _searchController,
          style: TextStyle(color: ThemeColors.textColor(isDark), fontSize: 16),
          textAlign: TextAlign.right,
          onChanged: (value) {
            setState(() {
              searchQuery = value.toLowerCase();
            });
          },
          decoration: InputDecoration(
            hintText: 'البحث برقم الهاتف أو اسم العميل...',
            hintStyle: TextStyle(color: ThemeColors.secondaryTextColor(isDark), fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: Color(0xFFFFD700), size: 22),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        searchQuery = '';
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),
      ),
    );
  }

  // بناء شريط فلتر الحالة الأفقي مع تصميم شفاف مضبب رهيب
  Widget _buildEnhancedFilterBar(bool isDark) {
    return Container(
      height: 85,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Row(
          children: [
            _buildGlassFilterButton('all', 'الكل', FontAwesomeIcons.list, const Color(0xFF6c757d)),
            const SizedBox(width: 10),
            _buildGlassFilterButton('processing', 'معالجة', FontAwesomeIcons.wrench, const Color(0xFFff6b35)),
            const SizedBox(width: 10),
            _buildGlassFilterButton('active', 'نشط', FontAwesomeIcons.clock, const Color(0xFFffc107)),
            const SizedBox(width: 10),
            _buildGlassFilterButton('in_delivery', 'قيد التوصيل', FontAwesomeIcons.truck, const Color(0xFF007bff)),
            const SizedBox(width: 10),
            _buildGlassFilterButton('delivered', 'تم التسليم', FontAwesomeIcons.circleCheck, const Color(0xFF28a745)),
            const SizedBox(width: 10),
            _buildGlassFilterButton('cancelled', 'ملغي', FontAwesomeIcons.circleXmark, const Color(0xFFdc3545)),
            const SizedBox(width: 10),
            _buildGlassFilterButton('scheduled', 'مجدول', FontAwesomeIcons.calendar, const Color(0xFF8b5cf6)),
            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }

  // بناء زر فلتر شفاف مضبب بتصميم رهيب
  Widget _buildGlassFilterButton(String status, String label, IconData icon, Color color) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    bool isSelected = selectedFilter == status;
    int count = orderCounts[status] ?? 0;
    double width = _isInDeliveryStatus(status) || _isDeliveredStatus(status) || status == 'processing' ? 130 : 100;

    return GestureDetector(
      onTap: () async {
        setState(() {
          selectedFilter = status;
        });
        await _loadOrdersFromDatabase();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: width,
        height: 60,
        decoration: BoxDecoration(
          // خلفية بيضاء في الوضع النهاري، شفافة في الوضع الليلي
          color: isDark ? Colors.transparent : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : color.withValues(alpha: 0.4), width: isSelected ? 3 : 1.5),
          // ظلال في الوضع النهاري
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: 1,
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: isDark ? 10 : 0, sigmaY: isDark ? 10 : 0),
            child: Container(
              decoration: BoxDecoration(
                gradient: isDark
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isSelected
                            ? [color.withValues(alpha: 0.15), color.withValues(alpha: 0.08), Colors.transparent]
                            : [Colors.white.withValues(alpha: 0.05), Colors.transparent],
                      )
                    : null, // لا تدرج في الوضع النهاري
              ),
              child: Padding(
                padding: const EdgeInsets.all(6), // تقليل الـ padding لتجنب overflow
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // الأيقونة والنص
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          color: isSelected
                              ? (isDark ? Colors.white : color)
                              : isDark
                              ? color.withValues(alpha: 0.9)
                              : (status == 'all' ? Colors.black.withValues(alpha: 0.7) : color),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            label,
                            style: GoogleFonts.cairo(
                              fontSize: status == 'processing' || status == 'in_delivery' || status == 'delivered'
                                  ? 9
                                  : 10,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? (isDark ? Colors.white : color)
                                  : isDark
                                  ? color.withValues(alpha: 0.9)
                                  : (status == 'all' ? Colors.black.withValues(alpha: 0.7) : color),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // العداد مع تصميم شفاف
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
                      ),
                      child: Text(
                        count.toString(),
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? (isDark ? Colors.white : color)
                              : isDark
                              ? color
                              : (status == 'all' ? Colors.black.withValues(alpha: 0.8) : color),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // بناء حالة عدم وجود طلبات
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FontAwesomeIcons.bagShopping, size: 64, color: const Color(0xFF6c757d)),
          const SizedBox(height: 20),
          Text(
            'لا توجد طلبات حالياً',
            style: GoogleFonts.cairo(fontSize: 19.2, color: const Color(0xFF6c757d), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// بناء بطاقة الطلب الواحدة
  /// ✅ مع Fade-in Animation
  Widget _buildOrderCard(Order order, bool isDark) {
    // تحديد إذا كان الطلب مجدول
    final bool isScheduled = order.scheduledDate != null;

    // الحصول على ألوان البطاقة حسب حالة الطلب
    final cardColors = _getOrderCardColors(order.rawStatus, isScheduled);

    // Fade-in Animation للبطاقة مع تأثير إضافي عند التحديث
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: TweenAnimationBuilder<double>(
        key: ValueKey('${order.id}_${_isRefreshing ? 'refreshing' : 'normal'}'),
        tween: Tween(begin: _isRefreshing ? 0.0 : 0.0, end: 1.0),
        duration: Duration(milliseconds: _isRefreshing ? 500 : 400),
        curve: Curves.easeOut,
        builder: (context, opacity, child) {
          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - opacity)),
              child: Transform.scale(scale: 0.95 + (0.05 * opacity), child: child),
            ),
          );
        },
        child: GestureDetector(
          onTap: () => _showOrderDetails(order),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            width: MediaQuery.of(context).size.width * 0.95,
            height: isScheduled ? 145 : 145,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              // خلفية بيضاء في الوضع النهاري، شفافة في الوضع الليلي
              color: isDark ? Colors.transparent : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? cardColors['borderColor'].withValues(alpha: 0.6)
                    : cardColors['borderColor'].withValues(alpha: 0.4),
                width: isDark ? 2.5 : 2.7, // ✅ تثخين الإطار لإظهار اللون بوضوح
              ),
              // ظلال محسّنة
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: cardColors['shadowColor'].withValues(alpha: 0.15),
                        blurRadius: 0,
                        offset: const Offset(0, 2),
                        spreadRadius: 0,
                      ),
                    ]
                  : [
                      // ظل رمادي ناعم في الوضع النهاري
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                        spreadRadius: 1,
                      ),
                    ],
            ),
            child: Container(
              // بدون توهج في الوضع النهاري
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.transparent),
              padding: const EdgeInsets.all(2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // الصف الأول - معلومات الزبون
                  _buildCustomerInfoWithStatus(order, isDark),

                  // الصف الثالث - حالة الطلب
                  Container(
                    height: 32, // ارتفاع كافي لعرض النص كاملاً
                    margin: const EdgeInsets.symmetric(vertical: 2), // مساحة مناسبة
                    child: isScheduled
                        ? Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8b5cf6),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF8b5cf6).withValues(alpha: 0.3),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                'مجدول',
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : Center(child: _buildStatusBadge(order)), // عرض حالة الطلب للطلبات العادية
                  ),

                  // الصف الرابع - المعلومات المالية والتاريخ
                  _buildOrderFooter(order),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // بناء معلومات الزبون مع حالة الطلب
  Widget _buildCustomerInfoWithStatus(Order order, bool isDark) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العمود الأيسر: معلومات الزبون
            Flexible(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // اسم الزبون
                  Text(
                    order.customerName,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? ThemeColors.textColor(isDark) : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 1),

                  // رقم الهاتف
                  Row(
                    children: [
                      const Icon(FontAwesomeIcons.phone, color: Color(0xFF28a745), size: 10),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          order.primaryPhone,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF00d4aa),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 1),

                  // العنوان (المحافظة والمدينة)
                  Row(
                    children: [
                      const Icon(FontAwesomeIcons.locationDot, color: Color(0xFFdc3545), size: 10),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${order.city} - ${order.province}',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFFffc107),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // تاريخ الجدولة (للطلبات المجدولة) أو صورة المنتج (للطلبات العادية)
            if (order.scheduledDate != null)
              // تاريخ الجدولة للطلبات المجدولة
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF8b5cf6), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(FontAwesomeIcons.calendar, color: Colors.white, size: 12),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MM/dd').format(order.scheduledDate!),
                      style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ],
                ),
              )
            else
              // صورة المنتج للطلبات العادية (أو أيقونة افتراضية)
              SizedBox(
                width: 45,
                height: 45,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1)),
                    child: order.items.isNotEmpty && order.items.first.image.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: order.items.first.image,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: const Color(0xFF6c757d).withValues(alpha: 0.3),
                              child: const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffd700)),
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: const Color(0xFF6c757d),
                              child: const Icon(FontAwesomeIcons.box, color: Colors.white, size: 18),
                            ),
                          )
                        : Container(
                            color: const Color(0xFF6c757d),
                            child: const Icon(FontAwesomeIcons.box, color: Colors.white, size: 18),
                          ),
                  ),
                ),
              ),

            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  // بناء شارة الحالة باستخدام OrderStatusHelper
  Widget _buildStatusBadge(Order order) {
    // ✅ OrderStatusHelper يقوم بتقصير النص تلقائياً
    final displayStatusText = OrderStatusHelper.getArabicStatus(order.rawStatus);
    final backgroundColor = OrderStatusHelper.getStatusColor(order.rawStatus);

    // تحديد لون النص بناءً على الحالة
    Color textColor = Colors.white;

    // للحالات النشطة: نص أسود على خلفية ذهبية
    if (_isActiveStatus(order.rawStatus)) {
      textColor = Colors.black; // أسود للنص
    }
    // للحالات الأخرى: نص أبيض
    else {
      textColor = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: backgroundColor.withValues(alpha: 0.7), width: 1),
        boxShadow: [
          BoxShadow(color: backgroundColor.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Text(
        displayStatusText,
        style: GoogleFonts.cairo(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
          shadows: [Shadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 1, offset: const Offset(0, 1))],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // بناء تذييل الطلب
  Widget _buildOrderFooter(Order order) {
    final bool isScheduled = order.scheduledDate != null;
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    return Container(
      height: isScheduled ? 38 : 35,
      margin: const EdgeInsets.only(left: 8, right: 8, top: 0, bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        // خلفية شفافة في الوضع الليلي، إطار فقط في الوضع النهاري
        color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isScheduled
              ? const Color(0xFF8b5cf6).withValues(alpha: isDark ? 0.3 : 0.5)
              : const Color(0xFFffd700).withValues(alpha: isDark ? 0.3 : 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // المبلغ الإجمالي
          Expanded(
            flex: 2,
            child: Text(
              '${NumberFormat('#,###').format(order.total)} د.ع',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFd4af37) : Colors.black,
                shadows: isDark
                    ? [
                        Shadow(
                          color: const Color(0xFFd4af37).withValues(alpha: 0.3),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : [],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // أزرار التعديل والحذف والمعالجة
          Row(
            children: [
              // زر المعالجة (للطلبات التي تحتاج معالجة)
              if (_needsProcessing(order) || _isSupportRequested(order))
                GestureDetector(
                  onTap: _isSupportRequested(order) ? null : () => _showProcessingDialog(order),
                  child: Container(
                    width: _isSupportRequested(order) ? 75 : 55,
                    height: 24,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: _isSupportRequested(order)
                          ? const Color(0xFF28a745) // أخضر للمعالج
                          : const Color(0xFFff8c00), // برتقالي للمعالجة
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: (_isSupportRequested(order) ? const Color(0xFF28a745) : const Color(0xFFff8c00))
                              .withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isSupportRequested(order) ? FontAwesomeIcons.circleCheck : FontAwesomeIcons.headset,
                          color: Colors.white,
                          size: 8,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _isSupportRequested(order) ? 'تم المعالجة' : 'معالجة',
                          style: GoogleFonts.cairo(fontSize: 7, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),

              // أزرار التعديل والحذف (للطلبات المجدولة والطلبات النشطة فقط)
              if (isScheduled || _isActiveStatus(order.rawStatus)) ...[
                // زر التعديل
                GestureDetector(
                  onTap: () => _editOrder(order),
                  child: Container(
                    width: 50,
                    height: 24,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF28a745),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF28a745).withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(FontAwesomeIcons.penToSquare, color: Colors.white, size: 8),
                        const SizedBox(width: 2),
                        Text(
                          'تعديل',
                          style: GoogleFonts.cairo(fontSize: 8, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                // زر الحذف
                GestureDetector(
                  onTap: () => _deleteOrder(order),
                  child: Container(
                    width: 40,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFdc3545),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFdc3545).withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(FontAwesomeIcons.trash, color: Colors.white, size: 8),
                        const SizedBox(width: 2),
                        Text(
                          'حذف',
                          style: GoogleFonts.cairo(fontSize: 8, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),

          // تاريخ الطلب
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  FontAwesomeIcons.calendar,
                  color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.6),
                  size: 10,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    isScheduled ? _formatDate(order.scheduledDate!) : _formatDate(order.createdAt),
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.w700, // تثخين الخط
                      color: isDark ? Colors.white : Colors.black.withValues(alpha: 0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// تنسيق التاريخ بتوقيت بغداد (UTC+3)
  /// ✅ محسّن مع تعليقات توضيحية
  ///
  /// ملاحظة: جميع التواريخ في قاعدة البيانات مخزنة بصيغة UTC
  /// يتم تحويلها إلى توقيت بغداد (GMT+3) للعرض
  String _formatDate(DateTime date) {
    // تحويل من UTC إلى توقيت بغداد (GMT+3)
    final baghdadDate = date.toUtc().add(const Duration(hours: 3));

    // تنسيق التاريخ: YYYY/MM/DD
    return '${baghdadDate.year}/${baghdadDate.month.toString().padLeft(2, '0')}/${baghdadDate.day.toString().padLeft(2, '0')}';
  }

  /// التحقق من أن الطلب يحتاج معالجة
  /// ✅ محسّن باستخدام Set الثابت
  bool _needsProcessing(Order order) {
    // استخدام Set الثابت المعرّف في الأعلى
    return _processingStatuses.contains(order.rawStatus) && !(order.supportRequested ?? false);
  }

  /// التحقق من أن الطلب تم إرسال طلب دعم له
  bool _isSupportRequested(Order order) {
    return order.supportRequested ?? false;
  }

  // عرض نافذة المعالجة
  void _showProcessingDialog(Order order) {
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1a1a2e),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(FontAwesomeIcons.headset, color: const Color(0xFFffd700), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'إرسال للدعم',
                    style: GoogleFonts.cairo(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // معلومات الطلب
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16213e),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📋 معلومات الطلب:',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: const Color(0xFFffd700),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow('🆔', 'رقم الطلب', '#${order.id}'),
                          _buildInfoRow('👤', 'اسم الزبون', order.customerName),
                          _buildInfoRow('📞', 'الهاتف الأساسي', order.primaryPhone),
                          if (order.secondaryPhone != null && order.secondaryPhone!.isNotEmpty)
                            _buildInfoRow('📱', 'الهاتف البديل', order.secondaryPhone!),
                          _buildInfoRow('🏛️', 'المحافظة', order.province),
                          _buildInfoRow('🏠', 'المدينة', order.city),
                          _buildInfoRow('⚠️', 'حالة الطلب', order.rawStatus),
                          _buildInfoRow('📅', 'تاريخ الطلب', _formatDate(order.createdAt)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // حقل الملاحظات
                    Text(
                      'ملاحظات إضافية:',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 4,
                      style: GoogleFonts.cairo(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'اكتب أي ملاحظات إضافية هنا...',
                        hintStyle: GoogleFonts.cairo(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: const Color(0xFFffd700).withValues(alpha: 0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: const Color(0xFFffd700).withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFffd700)),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                        filled: true,
                        fillColor: const Color(0xFF16213e),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() {
                            isLoading = true;
                          });
                          await _sendSupportRequest(order, notesController.text);
                          setState(() {
                            isLoading = false;
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF28a745),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text('إرسال للدعم', style: GoogleFonts.cairo()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // بناء صف معلومات
  Widget _buildInfoRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$emoji ', style: const TextStyle(fontSize: 14)),
          Text(
            '$label: ',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFFffd700)),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.cairo(fontSize: 12, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// إرسال طلب الدعم للخادم
  /// ✅ محسّن مع timeout و error handling
  Future<void> _sendSupportRequest(Order order, String notes) async {
    debugPrint('� إرسال طلب دعم للطلب: ${order.id}');
    debugPrint('� الملاحظات: $notes');

    try {
      // إرسال طلب الدعم للخادم (سيرسل تلقائياً للتلغرام)
      final response = await http
          .post(
            Uri.parse('${AppConfig.backendBaseUrl}/api/support/send-support-request'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'orderId': order.id,
              'customerName': order.customerName,
              'primaryPhone': order.primaryPhone,
              'alternativePhone': order.secondaryPhone,
              'governorate': order.province,
              'address': order.city,
              'orderStatus': order.rawStatus,
              'notes': notes,
              'waseetOrderId': order.waseetOrderId,
            }),
          )
          .timeout(
            Duration(seconds: AppConfig.requestTimeoutSeconds),
            onTimeout: () => throw TimeoutException('انتهت مهلة الانتظار'),
          );

      debugPrint('📡 رمز الاستجابة: ${response.statusCode}');

      final responseData = json.decode(response.body);

      if (response.statusCode != 200 || !responseData['success']) {
        throw Exception(responseData['message'] ?? 'فشل في إرسال الطلب للدعم');
      }

      debugPrint('✅ تم إرسال طلب الدعم بنجاح');

      // ✅ تحديث البيانات لضمان التحديث الفوري
      await _loadOrdersFromDatabase();

      // ✅ تحديث الواجهة فوراً
      if (mounted) {
        setState(() {
          // الواجهة ستتحدث تلقائياً لأن _ordersService.updateOrderSupportStatus يستدعي notifyListeners()
        });
      }

      if (!mounted) return;

      // إغلاق النافذة
      Navigator.of(context).pop();

      // إظهار رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('تم إرسال طلب  بنجاح', style: GoogleFonts.cairo()),
            ],
          ),
          backgroundColor: const Color(0xFF28a745),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('❌ ==خطأ في عملية إرسال طلب===');
      debugPrint('❌ نوع الخطأ: ${error.runtimeType}');
      debugPrint('❌ رسالة الخطأ: ${error.toString()}');
      debugPrint('❌ Stack Trace: $stackTrace');

      if (!mounted) return;

      // استخدام ErrorHandler لمعالجة أفضل للأخطاء
      ErrorHandler.showErrorSnackBar(
        context,
        error,
        customMessage: ErrorHandler.isNetworkError(error)
            ? 'لا يوجد اتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مرة أخرى.'
            : 'فشل في إرسال . يرجى المحاولة مرة أخرى.',
        onRetry: () => _sendSupportRequest(order, notes),
        duration: const Duration(seconds: 6),
      );
    }
  }

  // عرض تفاصيل الطلب
  void _showOrderDetails(Order order) {
    context.go('/orders/details/${order.id}');
  }

  // تعديل الطلب (للطلبات النشطة والمجدولة)
  void _editOrder(Order order) {
    final bool isScheduled = order.scheduledDate != null;

    if (isScheduled) {
      // للطلبات المجدولة - الانتقال لصفحة تعديل الطلب المجدول
      context.go('/scheduled-orders/edit/${order.id}');
      return;
    }

    // للطلبات العادية - التحقق من إمكانية التعديل
    if (!_isActiveStatus(order.rawStatus)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا يمكن تعديل الطلبات غير النشطة', style: GoogleFonts.cairo()),
          backgroundColor: const Color(0xFFdc3545),
        ),
      );
      return;
    }

    // الانتقال لصفحة تعديل الطلب
    context.go('/orders/edit/${order.id}');
  }

  // حذف الطلب (للطلبات النشطة والمجدولة)
  void _deleteOrder(Order order) {
    // التحقق من إمكانية الحذف
    bool isScheduledOrder = order.scheduledDate != null;

    // الطلبات المجدولة يمكن حذفها دائماً
    // الطلبات العادية يجب أن تكون نشطة للحذف
    if (!isScheduledOrder && !_isActiveStatus(order.rawStatus)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا يمكن حذف الطلبات غير النشطة', style: GoogleFonts.cairo()),
          backgroundColor: const Color(0xFFdc3545),
        ),
      );
      return;
    }

    // إظهار رسالة تأكيد بتصميم محسن
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: isDark ? 15 : 5, sigmaY: isDark ? 15 : 5),
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: isDark ? 0.3 : 0.5),
                    width: isDark ? 1 : 2,
                  ),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // أيقونة التحذير
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(FontAwesomeIcons.triangleExclamation, color: Colors.red, size: 30),
                    ),
                    const SizedBox(height: 20),
                    // العنوان
                    Text(
                      'حذف الطلب',
                      style: GoogleFonts.cairo(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    // المحتوى
                    Text(
                      'هل أنت متأكد من حذف طلب ${order.customerName}؟\nلا يمكن التراجع عن هذا الإجراء.',
                      style: GoogleFonts.cairo(
                        color: isDark ? Colors.white : Colors.black.withValues(alpha: 0.8),
                        fontSize: 16,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 25),
                    // الأزرار
                    Row(
                      children: [
                        // زر الإلغاء
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.grey.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.3)
                                      : Colors.grey.withValues(alpha: 0.4),
                                  width: isDark ? 1 : 2,
                                ),
                              ),
                              child: Text(
                                'إلغاء',
                                style: GoogleFonts.cairo(
                                  color: isDark ? Colors.white : Colors.black.withValues(alpha: 0.7),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        // زر الحذف
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              Navigator.pop(context);
                              await _confirmDeleteOrder(order);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1),
                              ),
                              child: Text(
                                'حذف',
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// تأكيد حذف الطلب
  /// ✅ محسّن مع retry mechanism
  Future<void> _confirmDeleteOrder(Order order) async {
    const int maxRetries = 3;
    int retryCount = 0;

    try {
      // إظهار مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFffd700))),
      );

      debugPrint('🗑️ بدء حذف الطلب: ${order.id}');

      // جلب رقم هاتف المستخدم
      final prefs = await SharedPreferences.getInstance();
      final currentUserPhone = prefs.getString('current_user_phone');

      if (currentUserPhone == null || currentUserPhone.isEmpty) {
        throw Exception('رقم الهاتف غير متوفر');
      }

      // تحديد نوع الطلب (عادي أم مجدول)
      final isScheduledOrder = _scheduledOrders.any((o) => o.id == order.id);

      // بناء URL للـ Backend API
      final url = isScheduledOrder
          ? Uri.parse(AppConfig.deleteScheduledOrderUrl(order.id, currentUserPhone))
          : Uri.parse(AppConfig.deleteOrderUrl(order.id, currentUserPhone));

      // محاولة الحذف مع retry
      http.Response? response;
      while (retryCount < maxRetries) {
        try {
          response = await http
              .delete(url)
              .timeout(
                Duration(seconds: AppConfig.requestTimeoutSeconds),
                onTimeout: () => throw TimeoutException('انتهت مهلة الانتظار'),
              );

          // إذا نجح الطلب، اخرج من الحلقة
          if (response.statusCode == 200 || response.statusCode == 403 || response.statusCode == 404) {
            break;
          }

          // إذا فشل بسبب خطأ في الخادم، حاول مرة أخرى
          retryCount++;
          if (retryCount < maxRetries) {
            debugPrint('⚠️ محاولة $retryCount من $maxRetries...');
            await Future.delayed(Duration(seconds: retryCount)); // تأخير تصاعدي
          }
        } catch (e) {
          retryCount++;
          if (retryCount >= maxRetries) rethrow;
          debugPrint('⚠️ خطأ في المحاولة $retryCount، إعادة المحاولة...');
          await Future.delayed(Duration(seconds: retryCount));
        }
      }

      if (response == null) {
        throw Exception('فشل الاتصال بالخادم بعد $maxRetries محاولات');
      }

      // معالجة الاستجابة
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['success'] != true) {
          throw Exception(json['error'] ?? 'فشل في حذف الطلب');
        }

        debugPrint('✅ تم حذف الطلب بنجاح');
      } else if (response.statusCode == 403) {
        throw Exception('غير مصرح لك بحذف هذا الطلب');
      } else if (response.statusCode == 404) {
        throw Exception('الطلب غير موجود');
      } else {
        throw Exception('خطأ في الخادم: ${response.statusCode}');
      }

      // تحديث القائمة المحلية
      setState(() {
        _orders.removeWhere((o) => o.id == order.id);
        _scheduledOrders.removeWhere((o) => o.id == order.id);
      });

      // إخفاء مؤشر التحميل
      if (mounted) Navigator.pop(context);

      // إظهار رسالة نجاح مع تحديد نوع الطلب
      if (mounted) {
        final orderType = isScheduledOrder ? 'المجدول' : 'العادي';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف الطلب $orderType بنجاح', style: GoogleFonts.cairo()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // إخفاء مؤشر التحميل
      if (mounted) Navigator.pop(context);

      // إظهار رسالة خطأ محسنة
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          e,
          customMessage: ErrorHandler.isNetworkError(e)
              ? 'لا يوجد اتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مرة أخرى.'
              : 'فشل في حذف الطلب. يرجى المحاولة مرة أخرى.',
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  /// دالة لتحديد ألوان الإطار والظل حسب حالة الطلب
  /// ✅ محسّنة باستخدام Map للأداء الأفضل
  Map<String, dynamic> _getOrderCardColors(String status, bool isScheduled) {
    // الطلبات المجدولة (بنفسجي)
    if (isScheduled) {
      return {
        'borderColor': const Color(0xFF8b5cf6),
        'shadowColor': const Color(0xFF8b5cf6).withValues(alpha: 0.3),
        'gradientColors': [
          const Color(0xFF2d1b69).withValues(alpha: 0.9),
          const Color(0xFF1e3a8a).withValues(alpha: 0.8),
        ],
      };
    }

    final statusText = status.trim();

    // البحث في خريطة الألوان أولاً
    if (_statusColorMap.containsKey(statusText)) {
      final colors = _statusColorMap[statusText]!;
      return {
        'borderColor': colors['borderColor'],
        'shadowColor': (colors['shadowColor'] as Color).withValues(alpha: 0.4),
        'gradientColors': (colors['gradientColors'] as List<Color>).map((c) => c.withValues(alpha: 0.9)).toList(),
      };
    }

    // 🟠 حالات المعالجة (برتقالي) - استخدام Set للأداء الأفضل
    if (_processingStatuses.contains(statusText)) {
      return {
        'borderColor': const Color(0xFFff6b35),
        'shadowColor': const Color(0xFFff6b35).withValues(alpha: 0.4),
        'gradientColors': [
          const Color(0xFF2e1f1a).withValues(alpha: 0.95),
          const Color(0xFF2e1e16).withValues(alpha: 0.9),
          const Color(0xFF3f2a1e).withValues(alpha: 0.85),
        ],
      };
    }

    // اللون الافتراضي للحالات غير المعروفة (رمادي)
    return {
      'borderColor': _defaultStatusColor['borderColor'],
      'shadowColor': (_defaultStatusColor['shadowColor'] as Color).withValues(alpha: 0.4),
      'gradientColors': (_defaultStatusColor['gradientColors'] as List<Color>)
          .map((c) => c.withValues(alpha: 0.9))
          .toList(),
    };
  }
}
