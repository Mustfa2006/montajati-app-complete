import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';


// تم إزالة Smart Cache - الجلب المباشر من قاعدة البيانات
import '../widgets/pull_to_refresh_wrapper.dart';
import '../utils/error_handler.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../widgets/curved_navigation_bar.dart';
import '../widgets/common_header.dart';
import '../utils/order_status_helper.dart';
import '../core/design_system.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  String selectedFilter = 'all';

  // متغيرات البحث
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // الجلب المباشر من قاعدة البيانات
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Order> _orders = [];
  List<Order> _scheduledOrders = []; // قائمة منفصلة للطلبات المجدولة
  bool _isLoading = false;

  // متغيرات التحميل التدريجي
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 0;
  final int _pageSize = 25;

  // العدادات الكاملة من قاعدة البيانات
  Map<String, int> _orderCounts = {
    'all': 0,
    'processing': 0,
    'active': 0,
    'in_delivery': 0,
    'delivered': 0,
    'cancelled': 0,
    'scheduled': 0,
  };

  // متحكم التمرير للتحميل التدريجي
  final ScrollController _scrollController = ScrollController();

  // تم حذف _scheduledOrders - Smart Cache يتولى جميع الطلبات



  // دالة مراقبة التمرير للتحميل التدريجي
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreOrders();
    }
  }

  @override
  void initState() {
    super.initState();

    // إعداد مستمع التمرير
    _scrollController.addListener(_onScroll);

    // 🚀 تحميل العدادات والطلبات
    _loadOrderCounts();
    _loadOrdersFromDatabase();

    // جلب الطلبات المجدولة أيضاً
    _loadScheduledOrdersOnInit();

    // إعادة تعيين الفلتر إلى "الكل"
    selectedFilter = 'all';

    // تم حذف OrderSyncService - كان معطلاً ولا يؤثر على التطبيق
  }

  // تم حذف دالة _initializeSmartCache - استخدام التحميل التدريجي المباشر

  // تم حذف الدالة القديمة - Smart Cache يتولى العرض الفوري



  // تم حذف _onGlobalCacheChanged - Smart Cache يتولى التحديثات

  // دالة مساعدة للحصول على رقم هاتف المستخدم الحالي
  Future<String?> _getCurrentUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_user_phone');
  }

  // جلب عدد الطلبات المجدولة من جدول scheduled_orders
  Future<int> _getScheduledOrdersCount(String userPhone) async {
    try {
      final response = await _supabase
          .from('scheduled_orders')
          .select('id')
          .eq('user_phone', userPhone)
          .eq('is_converted', false) // فقط الطلبات غير المحولة
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      debugPrint('❌ خطأ في جلب عدد الطلبات المجدولة: $e');
      return 0;
    }
  }

  // جلب الطلبات المجدولة الفعلية من جدول scheduled_orders
  Future<List<Order>> _getScheduledOrders(String userPhone) async {
    try {
      debugPrint('🔄 جلب الطلبات المجدولة للمستخدم: $userPhone');

      final response = await _supabase
          .from('scheduled_orders')
          .select('''
            *,
            scheduled_order_items (
              id,
              product_name,
              quantity,
              price,
              notes,
              product_id,
              product_image
            )
          ''')
          .eq('user_phone', userPhone)
          .eq('is_converted', false) // فقط الطلبات غير المحولة
          .order('scheduled_date', ascending: true);

      if (response.isEmpty) {
        debugPrint('📋 لا توجد طلبات مجدولة للمستخدم');
        return [];
      }

      // تحويل الطلبات المجدولة إلى نموذج Order
      List<Order> scheduledOrders = [];
      for (var orderData in response) {
        try {
          // تحويل عناصر الطلب المجدول
          List<OrderItem> items = [];
          if (orderData['scheduled_order_items'] != null) {
            for (var itemData in orderData['scheduled_order_items']) {
              items.add(OrderItem(
                id: itemData['id'] ?? '',
                productId: itemData['product_id'] ?? '',
                name: itemData['product_name'] ?? '',
                image: itemData['product_image'] ?? '',
                wholesalePrice: 0.0, // سيتم حسابه لاحقاً
                customerPrice: (itemData['price'] ?? 0.0).toDouble(),
                quantity: itemData['quantity'] ?? 1,
              ));
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
            totalCost: ((orderData['total_amount'] ?? 0.0) * 100).toInt(),
            totalProfit: 0, // سيتم حسابه لاحقاً
            subtotal: ((orderData['total_amount'] ?? 0.0) * 100).toInt(),
            total: ((orderData['total_amount'] ?? 0.0) * 100).toInt(),
            status: OrderStatus.pending, // حالة افتراضية للطلبات المجدولة
            rawStatus: 'مجدول', // حالة مجدول
            createdAt: DateTime.parse(orderData['created_at'] ?? DateTime.now().toIso8601String()),
            items: items,
            scheduledDate: DateTime.parse(orderData['scheduled_date']),
            scheduleNotes: orderData['notes'] ?? '',
            supportRequested: false,
            waseetOrderId: null,
          );

          scheduledOrders.add(order);
        } catch (e) {
          debugPrint('❌ خطأ في تحويل الطلب المجدول ${orderData['id']}: $e');
        }
      }

      debugPrint('✅ تم جلب ${scheduledOrders.length} طلب مجدول');
      return scheduledOrders;

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

  /// تحديث البيانات عند السحب للأسفل
  Future<void> _refreshData() async {
    try {
      debugPrint('🔄 تحديث بيانات صفحة الطلبات...');

      // التحقق من رقم هاتف المستخدم
      final prefs = await SharedPreferences.getInstance();
      String? currentUserPhone = prefs.getString('current_user_phone');

      if (currentUserPhone != null && currentUserPhone.isNotEmpty) {
        debugPrint('📱 تحديث للمستخدم: $currentUserPhone');

        // تحديث العدادات والطلبات للمستخدم الحالي
        await _loadOrderCounts();
        await _loadOrdersFromDatabase();
        await _loadScheduledOrdersFromDatabase(currentUserPhone);
      }

      // ✅ تم الاستغناء عن الكاش العالمي - Smart Cache يتولى كل شيء

      debugPrint('✅ تم تحديث بيانات صفحة الطلبات بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في التحديث: $e');
    }
  }





  // تم حذف دالة _loadOrders القديمة - Smart Cache يتولى التحميل

  // تم حذف دالة _loadScheduledOrders القديمة - Smart Cache يتولى الطلبات المجدولة أيضاً

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Smart Cache يتولى التحميل تلقائياً
    debugPrint('📱 تم استدعاء didChangeDependencies - Smart Cache يتولى التحميل');
  }

  // تم حذف دالة _loadOrdersLight القديمة - Smart Cache يتولى التحميل الخفيف

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();

    // تم إزالة Smart Cache

    super.dispose();
  }

  // تحميل الطلبات مباشرة من قاعدة البيانات مع التحميل التدريجي
  Future<void> _loadOrdersFromDatabase({bool isLoadMore = false}) async {
    if (_isLoading || (isLoadMore && _isLoadingMore) || (isLoadMore && !_hasMoreData)) return;

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
      final prefs = await SharedPreferences.getInstance();
      final currentUserPhone = prefs.getString('current_user_phone');

      if (currentUserPhone == null) {
        debugPrint('❌ رقم هاتف المستخدم غير متوفر');
        return;
      }

      final offset = _currentPage * _pageSize;
      debugPrint('🔍 جلب طلبات المستخدم: $currentUserPhone - الصفحة: $_currentPage ($offset-${offset + _pageSize - 1})');

      final response = await _supabase
          .from('orders')
          .select('''
            *,
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
          .eq('user_phone', currentUserPhone)
          .order('created_at', ascending: false)
          .range(offset, offset + _pageSize - 1);

      debugPrint('📡 تم جلب ${response.length} طلب من قاعدة البيانات');

      final List<Order> newOrders = [];
      for (final orderData in response) {
        try {
          final order = Order.fromJson(orderData);
          newOrders.add(order);
        } catch (e) {
          debugPrint('❌ خطأ في تحويل طلب ${orderData['id']}: $e');
        }
      }

      setState(() {
        if (isLoadMore) {
          _orders.addAll(newOrders);
        } else {
          _orders = newOrders;
        }

        _hasMoreData = newOrders.length == _pageSize;
        _currentPage++;
      });

      debugPrint('✅ تم تحميل ${newOrders.length} طلب جديد - المجموع: ${_orders.length}');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الطلبات: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  // تحميل المزيد من الطلبات (التحميل التدريجي)
  Future<void> _loadMoreOrders() async {
    await _loadOrdersFromDatabase(isLoadMore: true);
  }

  // جلب العدادات الكاملة من قاعدة البيانات
  Future<void> _loadOrderCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserPhone = prefs.getString('current_user_phone');

      if (currentUserPhone == null) {
        debugPrint('❌ رقم هاتف المستخدم غير متوفر لجلب العدادات');
        return;
      }

      debugPrint('📊 جلب العدادات الكاملة للمستخدم: $currentUserPhone');

      // 🎯 استعلام COUNT مباشر - جلب العدد فقط بدون البيانات

      // 1. العدد الكامل
      final totalResponse = await _supabase
          .from('orders')
          .select('id')
          .eq('user_phone', currentUserPhone)
          .count(CountOption.exact);
      final total = totalResponse.count;

      // 2. عدد طلبات المعالجة
      final processingResponse = await _supabase
          .from('orders')
          .select('id')
          .eq('user_phone', currentUserPhone)
          .inFilter('status', [
            'تم تغيير محافظة الزبون', 'تغيير المندوب', 'لا يرد', 'لا يرد بعد الاتفاق',
            'مغلق', 'مغلق بعد الاتفاق', 'الرقم غير معرف', 'الرقم غير داخل في الخدمة',
            'لا يمكن الاتصال بالرقم', 'مؤجل', 'مؤجل لحين اعادة الطلب لاحقا',
            'مفصول عن الخدمة', 'طلب مكرر', 'مستلم مسبقا', 'العنوان غير دقيق',
            'لم يطلب', 'حظر المندوب'
          ])
          .count(CountOption.exact);
      final processing = processingResponse.count;

      // 3. عدد الطلبات النشطة
      final activeResponse = await _supabase
          .from('orders')
          .select('id')
          .eq('user_phone', currentUserPhone)
          .eq('status', 'active')
          .count(CountOption.exact);
      final active = activeResponse.count;

      // 4. عدد طلبات قيد التوصيل
      final inDeliveryResponse = await _supabase
          .from('orders')
          .select('id')
          .eq('user_phone', currentUserPhone)
          .inFilter('status', ['قيد التوصيل الى الزبون (في عهدة المندوب)', 'in_delivery'])
          .count(CountOption.exact);
      final inDelivery = inDeliveryResponse.count;

      // 5. عدد الطلبات المسلمة
      final deliveredResponse = await _supabase
          .from('orders')
          .select('id')
          .eq('user_phone', currentUserPhone)
          .inFilter('status', ['تم التسليم للزبون', 'delivered'])
          .count(CountOption.exact);
      final delivered = deliveredResponse.count;

      // 6. عدد الطلبات الملغية
      final cancelledResponse = await _supabase
          .from('orders')
          .select('id')
          .eq('user_phone', currentUserPhone)
          .inFilter('status', ['الغاء الطلب', 'رفض الطلب', 'تم الارجاع الى التاجر', 'cancelled'])
          .count(CountOption.exact);
      final cancelled = cancelledResponse.count;

      // جلب عدد الطلبات المجدولة
      final scheduledCount = await _getScheduledOrdersCount(currentUserPhone);

      setState(() {
        _orderCounts = {
          'all': total,
          'processing': processing,
          'active': active,
          'in_delivery': inDelivery,
          'delivered': delivered,
          'cancelled': cancelled,
          'scheduled': scheduledCount,
        };
      });

      debugPrint('✅ تم جلب العدادات الحقيقية من قاعدة البيانات:');
      debugPrint('   📊 المجموع الكامل: $total');
      debugPrint('   🔧 يحتاج معالجة: $processing');
      debugPrint('   ⚡ نشط: $active');
      debugPrint('   🚚 قيد التوصيل: $inDelivery');
      debugPrint('   ✅ تم التسليم: $delivered');
      debugPrint('   ❌ ملغي: $cancelled');
    } catch (e) {
      debugPrint('❌ خطأ في جلب العدادات: $e');
      // في حالة الخطأ، استخدم العدادات من الطلبات المحملة
      setState(() {
        _orderCounts = {
          'all': _orders.length,
          'processing': _orders.where((order) => _isProcessingStatus(order.rawStatus)).length,
          'active': _orders.where((order) => _isActiveStatus(order.rawStatus)).length,
          'in_delivery': _orders.where((order) => _isInDeliveryStatus(order.rawStatus)).length,
          'delivered': _orders.where((order) => _isDeliveredStatus(order.rawStatus)).length,
          'cancelled': _orders.where((order) => _isCancelledStatus(order.rawStatus)).length,
          'scheduled': 0,
        };
      });
    }
  }

  // تم حذف _onOrdersChanged - Smart Cache يتولى التحديثات

  // تم حذف _onScheduledOrdersChanged - Smart Cache يتولى الطلبات المجدولة

  // تم حذف _convertScheduledOrdersToOrderList - Smart Cache يتولى التحويل

  // حساب عدد الطلبات لكل حالة (من قاعدة البيانات مباشرة)
  Map<String, int> get orderCounts {
    return _orderCounts;
  }

  // دوال مساعدة للواجهة فقط

  // قسم معالجة - الطلبات التي تحتاج معالجة
  bool _isProcessingStatus(String status) {
    return status == 'تم تغيير محافظة الزبون' ||
           status == 'تغيير المندوب' ||
           status == 'لا يرد' ||
           status == 'لا يرد بعد الاتفاق' ||
           status == 'مغلق' ||
           status == 'مغلق بعد الاتفاق' ||
           status == 'الرقم غير معرف' ||
           status == 'الرقم غير داخل في الخدمة' ||
           status == 'لا يمكن الاتصال بالرقم' ||
           status == 'مؤجل' ||
           status == 'مؤجل لحين اعادة الطلب لاحقا' ||
           status == 'مفصول عن الخدمة' ||
           status == 'طلب مكرر' ||
           status == 'مستلم مسبقا' ||
           status == 'العنوان غير دقيق' ||
           status == 'لم يطلب' ||
           status == 'حظر المندوب';
  }

  bool _isActiveStatus(String status) {
    return status == 'active';
  }

  bool _isInDeliveryStatus(String status) {
    return status == 'قيد التوصيل الى الزبون (في عهدة المندوب)' ||
           status == 'in_delivery';
  }

  bool _isDeliveredStatus(String status) {
    return status == 'تم التسليم للزبون' ||
           status == 'delivered';
  }

  bool _isCancelledStatus(String status) {
    return status == 'الغاء الطلب' ||
           status == 'رفض الطلب' ||
           status == 'تم الارجاع الى التاجر' ||
           status == 'cancelled';
  }

  // تم حذف الدالة المكررة

  // فلترة الطلبات حسب الحالة والبحث
  List<Order> get filteredOrders {
    debugPrint('🔍 فلترة الطلبات بالفلتر: $selectedFilter');

    List<Order> baseOrders = _orders;

    // تطبيق فلتر الحالة
    if (selectedFilter != 'all') {
      switch (selectedFilter) {
        case 'processing':
          // قسم المعالجة - الطلبات التي تحتاج معالجة
          baseOrders = _orders.where((order) => _isProcessingStatus(order.rawStatus)).toList();
          break;
        case 'active':
          // قسم النشط - الطلبات النشطة فقط
          baseOrders = _orders.where((order) => _isActiveStatus(order.rawStatus)).toList();
          break;
        case 'in_delivery':
          // قسم قيد التوصيل
          baseOrders = _orders.where((order) => _isInDeliveryStatus(order.rawStatus)).toList();
          break;
        case 'delivered':
          // قسم تم التسليم
          baseOrders = _orders.where((order) => _isDeliveredStatus(order.rawStatus)).toList();
          break;
        case 'cancelled':
          // قسم ملغي
          baseOrders = _orders.where((order) => _isCancelledStatus(order.rawStatus)).toList();
          break;
      }
    }

    debugPrint('🚀 تم الحصول على ${baseOrders.length} طلب بعد الفلترة');

    // ✅ ضمان الترتيب الصحيح: الأحدث أولاً دائماً
    baseOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    debugPrint(
      '📋 الفلتر الحالي: $selectedFilter, عدد الطلبات: ${baseOrders.length}',
    );

    // ✅ طباعة تفاصيل أول 3 طلبات للتشخيص
    if (baseOrders.isNotEmpty) {
      debugPrint('📋 أول 3 طلبات في filteredOrders (بعد الترتيب):');
      for (int i = 0; i < baseOrders.length && i < 3; i++) {
        final order = baseOrders[i];
        debugPrint(
          '   ${i + 1}. ${order.customerName} - ${order.id} - ${order.createdAt}',
        );
      }
    } else {
      debugPrint('⚠️ لا توجد طلبات في filteredOrders!');
    }

    // طباعة حالات الطلبات الموجودة للتشخيص
    final statusCounts = <String, int>{};
    for (final order in baseOrders) {
      final statusKey = order.status.toString().split('.').last;
      statusCounts[statusKey] = (statusCounts[statusKey] ?? 0) + 1;
    }
    debugPrint('📊 إحصائيات الحالات: $statusCounts');

    // تطبيق فلتر الحالة أولاً
    List<Order> statusFiltered = baseOrders;

    if (selectedFilter == 'scheduled') {
      // ✅ للطلبات المجدولة، استخدم القائمة المحفوظة
      statusFiltered = _scheduledOrders;
      debugPrint('🔍 عدد الطلبات المجدولة: ${statusFiltered.length}');
    } else {
      // ✅ للطلبات العادية، الفلترة تمت بالفعل على مستوى قاعدة البيانات
      statusFiltered = baseOrders;
      debugPrint(
        '🔍 عدد الطلبات المفلترة للحالة $selectedFilter: ${statusFiltered.length}',
      );
    }

    // تطبيق فلتر البحث
    if (searchQuery.isNotEmpty) {
      statusFiltered = statusFiltered.where((order) {
        final customerName = order.customerName.toLowerCase();
        final primaryPhone = order.primaryPhone.toLowerCase();
        final secondaryPhone = order.secondaryPhone?.toLowerCase() ?? '';
        final query = searchQuery.toLowerCase();

        return customerName.contains(query) ||
            primaryPhone.contains(query) ||
            secondaryPhone.contains(query);
      }).toList();

      debugPrint('🔍 عدد الطلبات بعد البحث: ${statusFiltered.length}');
    }

    return statusFiltered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.primaryBackground,
      extendBody: true, // السماح للمحتوى بالظهور خلف الشريط السفلي
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // الشريط العلوي الموحد
              CommonHeader(
                title: 'الطلبات',
                rightActions: [
                  // زر الرجوع على اليمين
                  GestureDetector(
                    onTap: () => context.go('/products'),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFffd700).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFffd700).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        FontAwesomeIcons.arrowRight,
                        color: Color(0xFFffd700),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),

              // منطقة المحتوى القابل للتمرير (تحتوي على البحث والفلتر والطلبات)
              Expanded(child: _buildScrollableContent()),
            ],
          ),
      // الشريط السفلي المنحني
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
    );
  }



  // بناء المحتوى القابل للتمرير
  Widget _buildScrollableContent() {
    List<Order> displayedOrders = filteredOrders;

    return PullToRefreshWrapper(
      onRefresh: _refreshData,
      refreshMessage: 'تم تحديث الطلبات',
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // شريط البحث
          SliverToBoxAdapter(child: _buildSearchBar()),

          // شريط فلتر الحالة
          SliverToBoxAdapter(child: _buildFilterBar()),

          // قائمة الطلبات
          displayedOrders.isEmpty
              ? SliverFillRemaining(child: _buildEmptyState())
              : SliverPadding(
                  padding: const EdgeInsets.only(
                    left: 8,
                    right: 8,
                    top: 15,
                    bottom: 100, // مساحة للشريط السفلي
                  ),
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
                      return _buildOrderCard(displayedOrders[index]);
                    }, childCount: displayedOrders.length + (_isLoadingMore ? 1 : 0)),
                  ),
                ),
        ],
      ),
    );
  }

  // بناء شريط البحث
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a3e),
        borderRadius: BorderRadius.circular(12), // ✅ زوايا مقوسة خفيفة
        border: Border.all(color: const Color(0xFF3a3a5e), width: 1),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        textAlign: TextAlign.right,
        onChanged: (value) {
          setState(() {
            searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'البحث برقم الهاتف أو اسم العميل...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFFffc107),
            size: 22,
          ),
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  // بناء شريط فلتر الحالة
  Widget _buildFilterBar() {
    return Container(
      height: 70,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Row(
          children: [
            _buildFilterButton(
              'all',
              'الكل',
              FontAwesomeIcons.list,
              const Color(0xFF6c757d),
            ),
            const SizedBox(width: 12),
            _buildFilterButton(
              'processing',
              'معالجة',
              FontAwesomeIcons.wrench,
              const Color(0xFFff6b35),
            ),
            const SizedBox(width: 12),
            _buildFilterButton(
              'active',
              'نشط',
              FontAwesomeIcons.clock,
              const Color(0xFFffc107),
            ),
            const SizedBox(width: 12),
            _buildFilterButton(
              'in_delivery',
              'قيد التوصيل',
              FontAwesomeIcons.truck,
              const Color(0xFF007bff),
            ),
            const SizedBox(width: 12),
            _buildFilterButton(
              'delivered',
              'تم التسليم',
              FontAwesomeIcons.circleCheck,
              const Color(0xFF28a745),
            ),
            const SizedBox(width: 12),
            _buildFilterButton(
              'cancelled',
              'ملغي',
              FontAwesomeIcons.circleXmark,
              const Color(0xFFdc3545),
            ),
            const SizedBox(width: 12),
            // ✅ فلتر الطلبات المجدولة
            _buildFilterButton(
              'scheduled',
              'مجدول',
              FontAwesomeIcons.calendar,
              const Color(0xFF8b5cf6),
            ),
            const SizedBox(width: 20), // مساحة إضافية في النهاية
          ],
        ),
      ),
    );
  }

  // بناء زر الفلتر مع العداد
  Widget _buildFilterButton(
    String status,
    String label,
    IconData icon,
    Color color,
  ) {
    bool isSelected = selectedFilter == status;
    int count = orderCounts[status] ?? 0;
    double width = _isInDeliveryStatus(status) || _isDeliveredStatus(status) || status == 'processing' ? 130 : 95;

    return GestureDetector(
      onTap: () async {
        // ⚡ تحديث فوري للواجهة - عرض فوري من Smart Cache
        setState(() {
          selectedFilter = status;
        });

        debugPrint('🚀 تغيير الفلتر إلى: $status');

        // ⚡ عرض النتائج فوراً
        if (mounted) {
          setState(() {});
        }

        // 🔄 تحديث البيانات في الخلفية
        await _loadOrdersFromDatabase();
      },
      child: IntrinsicHeight(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: width * 0.95, // تكبير العرض قليلاً
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            border: isSelected
                ? Border.all(color: const Color(0xFFffd700), width: 2)
                : Border.all(color: Colors.transparent, width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: isSelected ? 10 : 6,
                offset: const Offset(0, 2),
              ),
              if (isSelected)
                BoxShadow(
                  color: const Color(0xFFffd700).withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 0),
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: status == 'active' ? Colors.black : Colors.white,
                    size: 12, // تكبير الأيقونة قليلاً
                  ),
                  const SizedBox(width: 4), // زيادة المسافة قليلاً
                  Text(
                    label,
                    style: GoogleFonts.cairo(
                      fontSize: _isInDeliveryStatus(status) || _isDeliveredStatus(status) || status == 'processing'
                          ? 10 // تكبير النص قليلاً
                          : 11, // تكبير النص قليلاً
                      fontWeight: FontWeight.w600,
                      color: status == 'active' ? Colors.black : Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2), // زيادة المسافة قليلاً
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 2,
                ), // تكبير الحشو قليلاً
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(
                    8,
                  ), // تكبير الزوايا قليلاً
                ),
                child: Text(
                  count.toString(),
                  style: GoogleFonts.cairo(
                    fontSize: 10, // تكبير النص قليلاً
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
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
          Icon(
            FontAwesomeIcons.bagShopping,
            size: 64,
            color: const Color(0xFF6c757d),
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد طلبات حالياً',
            style: GoogleFonts.cairo(
              fontSize: 19.2,
              color: const Color(0xFF6c757d),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // بناء بطاقة الطلب الواحدة
  Widget _buildOrderCard(Order order) {
    // ✅ تحديد إذا كان الطلب مجدول
    final bool isScheduled = order.scheduledDate != null;

    // 🎨 الحصول على ألوان البطاقة حسب حالة الطلب الحقيقية
    final cardColors = _getOrderCardColors(
      order.rawStatus, // استخدام النص الحقيقي من قاعدة البيانات
      isScheduled,
    );

    return GestureDetector(
      onTap: () => _showOrderDetails(order),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        width: MediaQuery.of(context).size.width * 0.95,
        height: isScheduled ? 145 : 145, // ارتفاع أقل للطلبات المجدولة
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: cardColors['gradientColors'],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardColors['borderColor'], width: 2),
          boxShadow: [
            // ظل ملون حسب حالة الطلب
            BoxShadow(
              color: cardColors['shadowColor'],
              blurRadius: 25,
              offset: const Offset(0, 10),
              spreadRadius: 3,
            ),
            // ظل داخلي للعمق
            BoxShadow(
              color: cardColors['borderColor'].withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 0),
              spreadRadius: 1,
            ),
            // ظل أسود للعمق
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            // ظل خفيف للحواف
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(2), // تقليل المساحة الداخلية
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // الصف الأول - معلومات الزبون
              _buildCustomerInfoWithStatus(order),

              // الصف الثالث - حالة الطلب
              Container(
                height: 32, // ارتفاع كافي لعرض النص كاملاً
                margin: const EdgeInsets.symmetric(vertical: 2), // مساحة مناسبة
                child: isScheduled
                    ? Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8b5cf6),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF8b5cf6,
                                ).withValues(alpha: 0.3),
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
                    : Center(
                        child: _buildStatusBadge(order),
                      ), // عرض حالة الطلب للطلبات العادية
              ),

              // الصف الرابع - المعلومات المالية والتاريخ
              _buildOrderFooter(order),
            ],
          ),
        ),
      ),
    );
  }

  // بناء معلومات الزبون مع حالة الطلب
  Widget _buildCustomerInfoWithStatus(Order order) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 2,
        ), // تقليل المساحة
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
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 1),

                  // رقم الهاتف
                  Row(
                    children: [
                      const Icon(
                        FontAwesomeIcons.phone,
                        color: Color(0xFF28a745),
                        size: 10,
                      ),
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
                      const Icon(
                        FontAwesomeIcons.locationDot,
                        color: Color(0xFFdc3545),
                        size: 10,
                      ),
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
                decoration: BoxDecoration(
                  color: const Color(0xFF8b5cf6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      FontAwesomeIcons.calendar,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MM/dd').format(order.scheduledDate!),
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child:
                        order.items.isNotEmpty &&
                            order.items.first.image.isNotEmpty
                        ? Image.network(
                            order.items.first.image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFF6c757d),
                                child: const Icon(
                                  FontAwesomeIcons.box,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: const Color(0xFF6c757d),
                            child: const Icon(
                              FontAwesomeIcons.box,
                              color: Colors.white,
                              size: 18,
                            ),
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

  // بناء شارة الحالة باستخدام OrderStatusHelper والنص الأصلي
  Widget _buildStatusBadge(Order order) {
    // استخدام النص الأصلي من قاعدة البيانات
    final statusText = OrderStatusHelper.getArabicStatus(order.rawStatus);
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
        border: Border.all(
          color: backgroundColor.withValues(alpha: 0.7),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        statusText,
        style: GoogleFonts.cairo(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // بناء تذييل الطلب
  Widget _buildOrderFooter(Order order) {
    final bool isScheduled = order.scheduledDate != null;

    return Container(
      height: isScheduled ? 38 : 35, // تصغير ارتفاع الشريط السفلي
      margin: const EdgeInsets.only(
        left: 8,
        right: 8,
        top: 0,
        bottom: 6,
      ), // رفع الشريط قليلاً
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isScheduled
              ? const Color(0xFF8b5cf6).withValues(alpha: 0.3)
              : const Color(0xFFffd700).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // المبلغ الإجمالي
          Expanded(
            flex: 2,
            child: Text(
              '${order.total} د.ع',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFd4af37),
                shadows: [
                  Shadow(
                    color: const Color(0xFFd4af37).withValues(alpha: 0.3),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
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
                          color: (_isSupportRequested(order)
                              ? const Color(0xFF28a745)
                              : const Color(0xFFff8c00)).withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isSupportRequested(order)
                              ? FontAwesomeIcons.circleCheck
                              : FontAwesomeIcons.headset,
                          color: Colors.white,
                          size: 8,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _isSupportRequested(order) ? 'تم المعالجة' : 'معالجة',
                          style: GoogleFonts.cairo(
                            fontSize: 7,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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
                        const Icon(
                          FontAwesomeIcons.penToSquare,
                          color: Colors.white,
                          size: 8,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'تعديل',
                          style: GoogleFonts.cairo(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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
                        const Icon(
                          FontAwesomeIcons.trash,
                          color: Colors.white,
                          size: 8,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'حذف',
                          style: GoogleFonts.cairo(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 10,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    isScheduled
                        ? _formatDate(order.scheduledDate!)
                        : _formatDate(order.createdAt),
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
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

  // تنسيق التاريخ
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  // التحقق من أن الطلب يحتاج معالجة
  bool _needsProcessing(Order order) {
    // الحالات التي تحتاج معالجة (بناءً على النص)
    final statusesNeedProcessing = [
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
    ];

    return statusesNeedProcessing.contains(order.rawStatus) &&
           !(order.supportRequested ?? false);
  }

  // التحقق من أن الطلب تم إرسال طلب دعم له
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    FontAwesomeIcons.headset,
                    color: const Color(0xFFffd700),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'إرسال للدعم',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
                        border: Border.all(
                          color: const Color(0xFFffd700).withValues(alpha: 0.3),
                        ),
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
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
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
                          borderSide: BorderSide(
                            color: const Color(0xFFffd700).withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: const Color(0xFFffd700).withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFffd700),
                          ),
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
                  child: Text(
                    'إلغاء',
                    style: GoogleFonts.cairo(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
                      : Text(
                          'إرسال للدعم',
                          style: GoogleFonts.cairo(),
                        ),
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
          Text(
            '$emoji ',
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            '$label: ',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: const Color(0xFFffd700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // إرسال طلب الدعم
  Future<void> _sendSupportRequest(Order order, String notes) async {
    debugPrint('🔥 === تم النقر على زر إرسال للدعم - إرسال تلقائي ===');
    debugPrint('🔥 معلومات الطلب: ${order.toJson()}');
    debugPrint('🔥 الملاحظات: $notes');

    try {
      debugPrint('📡 Step 1: إرسال طلب الدعم للخادم...');

      // إرسال طلب الدعم للخادم (سيرسل تلقائياً للتلغرام)
      final response = await http.post(
  Uri.parse('https://montajati-official-backend-production.up.railway.app/api/support/send-support-request'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'orderId': order.id,
          'customerName': order.customerName,
          'primaryPhone': order.primaryPhone,
          'alternativePhone': order.secondaryPhone,
          'governorate': order.province,
          'address': order.city,
          'orderStatus': order.rawStatus,
          'notes': notes,
          'waseetOrderId': order.waseetOrderId, // ✅ إضافة رقم الطلب في الوسيط
        }),
      );

      debugPrint('📡 رمز الاستجابة: ${response.statusCode}');
      debugPrint('📡 محتوى الاستجابة: ${response.body}');

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
              Text(
                'تم إرسال طلب الدعم بنجاح',
                style: GoogleFonts.cairo(),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF28a745),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );



    } catch (error, stackTrace) {
      debugPrint('❌ === خطأ في عملية إرسال طلب الدعم ===');
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
            : 'فشل في إرسال طلب الدعم. يرجى المحاولة مرة أخرى.',
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
          content: Text(
            'لا يمكن تعديل الطلبات غير النشطة',
            style: GoogleFonts.cairo(),
          ),
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
          content: Text(
            'لا يمكن حذف الطلبات غير النشطة',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: const Color(0xFFdc3545),
        ),
      );
      return;
    }

    // إظهار رسالة تأكيد
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Text('حذف الطلب', style: GoogleFonts.cairo(color: Colors.red)),
        content: Text(
          'هل أنت متأكد من حذف طلب ${order.customerName}؟\nلا يمكن التراجع عن هذا الإجراء.',
          style: GoogleFonts.cairo(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirmDeleteOrder(order);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('حذف', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // تأكيد حذف الطلب
  Future<void> _confirmDeleteOrder(Order order) async {
    try {
      // إظهار مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFffd700)),
        ),
      );

      // حذف الطلب من قاعدة البيانات
      debugPrint('🗑️ بدء حذف الطلب: ${order.id}');

      // تحديد نوع الطلب (عادي أم مجدول)
      final isScheduledOrder = _scheduledOrders.any((o) => o.id == order.id);

      if (isScheduledOrder) {
        debugPrint('🗓️ حذف طلب مجدول من جدول scheduled_orders');

        // ✅ الخطوة 1: حذف عناصر الطلب المجدول أولاً
        final deleteItemsResponse = await Supabase.instance.client
            .from('scheduled_order_items')
            .delete()
            .eq('scheduled_order_id', order.id)
            .select();

        debugPrint('✅ تم حذف ${deleteItemsResponse.length} عنصر من الطلب المجدول');

        // ✅ الخطوة 2: حذف الطلب المجدول
        final deleteScheduledResponse = await Supabase.instance.client
            .from('scheduled_orders')
            .delete()
            .eq('id', order.id)
            .select();

        if (deleteScheduledResponse.isEmpty) {
          throw Exception('لم يتم العثور على الطلب المجدول أو فشل في الحذف');
        }

        debugPrint('✅ تم حذف الطلب المجدول بنجاح من قاعدة البيانات');

      } else {
        debugPrint('📦 حذف طلب عادي من جدول orders');

        // ✅ الخطوة 1: حذف معاملات الربح أولاً (مهم لتجنب خطأ Foreign Key)
        final deleteProfitResponse = await Supabase.instance.client
            .from('profit_transactions')
            .delete()
            .eq('order_id', order.id)
            .select();

        debugPrint('✅ تم حذف ${deleteProfitResponse.length} معاملة ربح للطلب');

        // ✅ الخطوة 2: حذف الطلب العادي
        final deleteOrderResponse = await Supabase.instance.client
            .from('orders')
            .delete()
            .eq('id', order.id)
            .select();

        if (deleteOrderResponse.isEmpty) {
          throw Exception('لم يتم العثور على الطلب أو فشل في الحذف');
        }

        debugPrint('✅ تم حذف الطلب العادي بنجاح من قاعدة البيانات');
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

  // دالة لتحديد ألوان الإطار والظل حسب حالة الطلب الحقيقية
  Map<String, dynamic> _getOrderCardColors(String status, bool isScheduled) {
    if (isScheduled) {
      // الطلبات المجدولة تبقى بنفس التصميم (بنفسجي)
      return {
        'borderColor': const Color(0xFF8b5cf6),
        'shadowColor': const Color(0xFF8b5cf6).withValues(alpha: 0.3),
        'gradientColors': [
          const Color(0xFF2d1b69).withValues(alpha: 0.9),
          const Color(0xFF1e3a8a).withValues(alpha: 0.8),
        ],
      };
    }

    // ألوان الطلبات العادية حسب النص الحقيقي من قاعدة البيانات
    final statusText = status.trim();

    // 🟡 الحالات النشطة (أصفر ذهبي) - أولوية عالية
    if (statusText == 'نشط' || statusText == 'active') {
      return {
        'borderColor': const Color(0xFFffc107), // أصفر ذهبي للنشط
        'shadowColor': const Color(0xFFffc107).withValues(alpha: 0.4),
        'gradientColors': [
          const Color(0xFF2e2a1a).withValues(alpha: 0.95),
          const Color(0xFF2e2616).withValues(alpha: 0.9),
          const Color(0xFF3f3a1e).withValues(alpha: 0.85),
        ],
      };
    }

    // 🟢 الحالات المكتملة (أخضر)
    if (_isDeliveredStatus(statusText)) {
      return {
        'borderColor': const Color(0xFF28a745), // أخضر لتم التسليم
        'shadowColor': const Color(0xFF28a745).withValues(alpha: 0.4),
        'gradientColors': [
          const Color(0xFF1a2e1a).withValues(alpha: 0.95),
          const Color(0xFF162e16).withValues(alpha: 0.9),
          const Color(0xFF1e3f1e).withValues(alpha: 0.85),
        ],
      };
    }

    // 🔵 الحالات قيد التوصيل (أزرق)
    if (_isInDeliveryStatus(statusText)) {
      return {
        'borderColor': const Color(0xFF007bff), // أزرق لقيد التوصيل
        'shadowColor': const Color(0xFF007bff).withValues(alpha: 0.4),
        'gradientColors': [
          const Color(0xFF1a2332).withValues(alpha: 0.95),
          const Color(0xFF162838).withValues(alpha: 0.9),
          const Color(0xFF1e3a5f).withValues(alpha: 0.85),
        ],
      };
    }

    // 🟠 الحالات التي تحتاج معالجة (برتقالي)
    if (statusText == 'تم تغيير محافظة الزبون' ||
        statusText == 'تغيير المندوب' ||
        statusText == 'لا يرد' ||
        statusText == 'لا يرد بعد الاتفاق' ||
        statusText == 'مغلق' ||
        statusText == 'مغلق بعد الاتفاق' ||
        statusText == 'الرقم غير معرف' ||
        statusText == 'الرقم غير داخل في الخدمة' ||
        statusText == 'لا يمكن الاتصال بالرقم' ||
        statusText == 'مؤجل' ||
        statusText == 'مؤجل لحين اعادة الطلب لاحقا' ||
        statusText == 'مفصول عن الخدمة' ||
        statusText == 'طلب مكرر' ||
        statusText == 'مستلم مسبقا' ||
        statusText == 'العنوان غير دقيق' ||
        statusText == 'لم يطلب' ||
        statusText == 'حظر المندوب') {
      return {
        'borderColor': const Color(0xFFff6b35), // برتقالي للمعالجة
        'shadowColor': const Color(0xFFff6b35).withValues(alpha: 0.4),
        'gradientColors': [
          const Color(0xFF2e1f1a).withValues(alpha: 0.95),
          const Color(0xFF2e1e16).withValues(alpha: 0.9),
          const Color(0xFF3f2a1e).withValues(alpha: 0.85),
        ],
      };
    }

    // 🔴 الحالات الملغية والمرفوضة (أحمر)
    if (_isCancelledStatus(statusText)) {
      return {
        'borderColor': const Color(0xFFdc3545), // أحمر للملغي والمرفوض
        'shadowColor': const Color(0xFFdc3545).withValues(alpha: 0.4),
        'gradientColors': [
          const Color(0xFF2e1a1a).withValues(alpha: 0.95),
          const Color(0xFF2e1616).withValues(alpha: 0.9),
          const Color(0xFF3f1e1e).withValues(alpha: 0.85),
        ],
      };
    }

    // الحالات القديمة للتوافق
    final statusLower = statusText.toLowerCase();
    if (statusLower.contains('تم') || statusLower.contains('delivered')) {
      return {
        'borderColor': const Color(0xFF28a745), // أخضر
        'shadowColor': const Color(0xFF28a745).withValues(alpha: 0.4),
        'gradientColors': [
          const Color(0xFF1a2e1a).withValues(alpha: 0.95),
          const Color(0xFF162e16).withValues(alpha: 0.9),
          const Color(0xFF1e3f1e).withValues(alpha: 0.85),
        ],
      };
    } else if (statusLower.contains('ملغي') || statusLower.contains('cancelled')) {
      return {
        'borderColor': const Color(0xFFdc3545), // أحمر
        'shadowColor': const Color(0xFFdc3545).withValues(alpha: 0.4),
        'gradientColors': [
          const Color(0xFF2e1a1a).withValues(alpha: 0.95),
          const Color(0xFF2e1616).withValues(alpha: 0.9),
          const Color(0xFF3f1e1e).withValues(alpha: 0.85),
        ],
      };
    }

    // افتراضي (ذهبي مثل زر نشط)
    return {
      'borderColor': const Color(0xFFffc107), // نفس لون زر نشط
      'shadowColor': const Color(0xFFffc107).withValues(alpha: 0.4),
      'gradientColors': [
        const Color(0xFF2e2a1a).withValues(alpha: 0.95),
        const Color(0xFF2e2616).withValues(alpha: 0.9),
        const Color(0xFF3f3a1e).withValues(alpha: 0.85),
      ],
    };
  }


}
