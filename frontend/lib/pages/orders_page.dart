import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../services/simple_orders_service.dart';
import '../services/scheduled_orders_service.dart';
import '../widgets/pull_to_refresh_wrapper.dart';
import '../utils/error_handler.dart';
import '../services/order_sync_service.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../widgets/common_header.dart';

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

  // خدمات الطلبات
  final SimpleOrdersService _ordersService = SimpleOrdersService();
  final ScheduledOrdersService _scheduledOrdersService =
      ScheduledOrdersService();

  final List<Order> _scheduledOrders = [];

  @override
  void initState() {
    super.initState();

    // جلب الطلبات من قاعدة البيانات
    _loadOrders();

    // إضافة مستمع لإعادة تحميل الطلبات عند العودة للصفحة
    _ordersService.addListener(_onOrdersChanged);

    // ✅ إضافة مستمع للطلبات المجدولة
    _scheduledOrdersService.addListener(_onScheduledOrdersChanged);

    // إعادة تعيين الفلتر إلى "الكل" لضمان رؤية الطلبات الجديدة
    selectedFilter = 'all';

    // بدء مراقبة تحديثات الطلبات من شركة الوسيط
    OrderSyncService.startOrderSync();
  }

  /// تحديث البيانات عند السحب للأسفل
  Future<void> _refreshData() async {
    debugPrint('🔄 تحديث بيانات صفحة الطلبات...');

    // إعادة تحميل الطلبات
    await _loadOrders();

    debugPrint('✅ تم تحديث بيانات صفحة الطلبات');
  }

  // جلب الطلبات العادية والمجدولة
  Future<void> _loadOrders() async {
    debugPrint('🔄 بدء تحميل الطلبات في صفحة الطلبات...');

    // ✅ مسح الـ cache وإجبار إعادة التحميل من قاعدة البيانات
    _ordersService.clearCache();
    await _ordersService.loadOrders(forceRefresh: true);

    // جلب الطلبات المجدولة
    await _loadScheduledOrders();

    // ✅ الطلبات مرتبة بالفعل من قاعدة البيانات (ORDER BY created_at DESC)

    debugPrint(
      '✅ انتهى تحميل الطلبات - العادية: ${_ordersService.orders.length}, المجدولة: ${_scheduledOrders.length}',
    );
    if (mounted) {
      setState(() {});
    }
  }

  // جلب الطلبات المجدولة
  Future<void> _loadScheduledOrders() async {
    try {
      // ✅ الحصول على رقم هاتف المستخدم الحالي
      final prefs = await SharedPreferences.getInstance();
      final currentUserPhone = prefs.getString('current_user_phone');

      debugPrint('📱 تحميل الطلبات المجدولة للمستخدم: $currentUserPhone');

      await _scheduledOrdersService.loadScheduledOrders(
        userPhone: currentUserPhone,
      );
      _scheduledOrders.clear();
      _scheduledOrders.addAll(
        _scheduledOrdersService.scheduledOrders.map((scheduledOrder) {
          // تحويل ScheduledOrder إلى Order مع إشارة أنه مجدول
          return Order(
            id: scheduledOrder.id,
            customerName: scheduledOrder.customerName,
            primaryPhone: scheduledOrder.customerPhone,
            secondaryPhone: scheduledOrder.customerAlternatePhone,
            province: scheduledOrder.customerProvince ?? 'غير محدد',
            city: scheduledOrder.customerCity ?? 'غير محدد',
            notes: scheduledOrder.customerNotes ?? scheduledOrder.notes,
            totalCost: scheduledOrder.totalAmount.toInt(),
            totalProfit: 0, // غير متوفر في ScheduledOrder
            subtotal: scheduledOrder.totalAmount.toInt(),
            total: scheduledOrder.totalAmount.toInt(),
            status: OrderStatus.pending,
            createdAt: scheduledOrder.createdAt,
            items: [], // سنضيف العناصر لاحقاً إذا لزم الأمر
            scheduledDate: scheduledOrder.scheduledDate,
            scheduleNotes: scheduledOrder.notes,
          );
        }),
      );

      debugPrint('✅ تم تحميل ${_scheduledOrders.length} طلب مجدول للمستخدم');
    } catch (e) {
      debugPrint('❌ خطأ في جلب الطلبات المجدولة: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ تحميل خفيف - استخدام الـ cache إذا كان متاحاً
    debugPrint('📱 تم استدعاء didChangeDependencies - تحميل خفيف');
    _loadOrdersLight();
  }

  // ✅ تحميل خفيف للطلبات - يستخدم الـ cache
  Future<void> _loadOrdersLight() async {
    debugPrint('🔄 بدء تحميل خفيف للطلبات...');

    // ✅ حتى التحميل الخفيف يجب أن يتحقق من قاعدة البيانات
    await _ordersService.loadOrders(forceRefresh: true);

    // جلب الطلبات المجدولة فقط إذا لم تكن محملة
    if (_scheduledOrders.isEmpty) {
      await _loadScheduledOrders();
    }

    // ✅ الطلبات مرتبة بالفعل من قاعدة البيانات (ORDER BY created_at DESC)

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _ordersService.removeListener(_onOrdersChanged);
    _scheduledOrdersService.removeListener(
      _onScheduledOrdersChanged,
    ); // ✅ إزالة مستمع الطلبات المجدولة
    super.dispose();
  }

  // دالة لإعادة بناء الواجهة عند تغيير الطلبات
  void _onOrdersChanged() {
    debugPrint('🔄 === تم استدعاء _onOrdersChanged ===');
    debugPrint('📊 عدد الطلبات الحالي: ${_ordersService.orders.length}');
    debugPrint('⏰ وقت آخر تحديث: ${_ordersService.lastUpdate}');
    debugPrint('🔄 حالة التحميل: ${_ordersService.isLoading}');

    if (_ordersService.orders.isNotEmpty) {
      debugPrint('📋 أحدث 3 طلبات في الخدمة:');
      for (int i = 0; i < _ordersService.orders.length && i < 3; i++) {
        final order = _ordersService.orders[i];
        debugPrint('   ${i + 1}. ${order.customerName} - ${order.id}');
      }
    } else {
      debugPrint('⚠️ لا توجد طلبات في الخدمة!');
    }

    if (mounted) {
      debugPrint('🔄 استدعاء setState() لإعادة بناء UI...');
      setState(() {
        debugPrint('✅ === تم إعادة بناء UI في orders_page بنجاح ===');
      });
    } else {
      debugPrint('❌ Widget غير mounted - لا يمكن استدعاء setState()');
    }
  }

  // ✅ دالة لإعادة بناء الواجهة عند تغيير الطلبات المجدولة
  void _onScheduledOrdersChanged() {
    debugPrint('📅 === تم استدعاء _onScheduledOrdersChanged ===');
    debugPrint(
      '📊 عدد الطلبات المجدولة: ${_scheduledOrdersService.scheduledOrders.length}',
    );

    // ✅ تحويل الطلبات المجدولة إلى Order بدون إعادة تحميل
    _convertScheduledOrdersToOrderList();

    if (mounted) {
      setState(() {});
    }
  }

  // ✅ تحويل الطلبات المجدولة إلى قائمة Order بدون إعادة تحميل
  void _convertScheduledOrdersToOrderList() {
    try {
      _scheduledOrders.clear();

      for (final scheduledOrder in _scheduledOrdersService.scheduledOrders) {
        final order = Order(
          id: scheduledOrder.id,
          customerName: scheduledOrder.customerName,
          primaryPhone: scheduledOrder.customerPhone,
          secondaryPhone: scheduledOrder.customerAlternatePhone,
          province:
              scheduledOrder.province ??
              scheduledOrder.customerProvince ??
              'غير محدد',
          city:
              scheduledOrder.city ?? scheduledOrder.customerCity ?? 'غير محدد',
          notes: scheduledOrder.customerNotes ?? scheduledOrder.notes,
          totalCost: scheduledOrder.totalAmount.toInt(),
          totalProfit: 0, // سيتم حسابه لاحقاً
          subtotal: scheduledOrder.totalAmount.toInt(),
          total: scheduledOrder.totalAmount.toInt(),
          status: OrderStatus.pending, // ✅ حالة انتظار للطلبات المجدولة
          createdAt: scheduledOrder.createdAt,
          items: scheduledOrder.items
              .map(
                (item) => OrderItem(
                  id: '',
                  productId: '',
                  name: item.name,
                  image: '',
                  wholesalePrice: 0.0,
                  customerPrice: item.price,
                  quantity: item.quantity,
                ),
              )
              .toList(),
          scheduledDate: scheduledOrder.scheduledDate,
          scheduleNotes: scheduledOrder.notes,
        );
        _scheduledOrders.add(order);
      }

      debugPrint('✅ تم تحويل ${_scheduledOrders.length} طلب مجدول إلى Order');
    } catch (e) {
      debugPrint('❌ خطأ في تحويل الطلبات المجدولة: $e');
    }
  }

  // حساب عدد الطلبات لكل حالة
  Map<String, int> get orderCounts {
    // ✅ الطلبات العادية فقط (بدون المجدولة)
    final regularOrders = _ordersService.orders;
    return {
      'all': regularOrders.length, // الطلبات العادية فقط
      'active': regularOrders
          .where(
            (order) =>
                order.status == OrderStatus.pending ||
                order.status == OrderStatus.confirmed,
          )
          .length,
      'in_delivery': regularOrders
          .where((order) => order.status == OrderStatus.inDelivery)
          .length,
      'delivered': regularOrders
          .where((order) => order.status == OrderStatus.delivered)
          .length,
      'cancelled': regularOrders
          .where((order) => order.status == OrderStatus.cancelled)
          .length,
      // ✅ الطلبات المجدولة منفصلة
      'scheduled': _scheduledOrders.length,
    };
  }

  // فلترة الطلبات حسب الحالة والبحث
  List<Order> get filteredOrders {
    // ✅ اختيار الطلبات حسب الفلتر المحدد
    List<Order> baseOrders;
    if (selectedFilter == 'scheduled') {
      // إذا كان الفلتر "مجدول"، اعرض الطلبات المجدولة فقط
      baseOrders = _scheduledOrders;
      debugPrint('📋 عرض الطلبات المجدولة فقط: ${baseOrders.length}');
    } else {
      // لجميع الفلاتر الأخرى، اعرض الطلبات العادية فقط
      baseOrders = _ordersService.orders;
      debugPrint('📋 عرض الطلبات العادية فقط: ${baseOrders.length}');
    }

    debugPrint(
      '📋 الفلتر الحالي: $selectedFilter, عدد الطلبات: ${baseOrders.length}',
    );

    // ✅ طباعة تفاصيل أول 3 طلبات للتشخيص
    if (baseOrders.isNotEmpty) {
      debugPrint('📋 أول 3 طلبات في filteredOrders:');
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

    if (selectedFilter != 'all' && selectedFilter != 'scheduled') {
      // ✅ فلترة الطلبات العادية حسب الحالة (لا تنطبق على المجدولة)
      switch (selectedFilter) {
        case 'active':
          // إظهار الطلبات النشطة (pending و confirmed)
          statusFiltered = baseOrders
              .where(
                (order) =>
                    order.status == OrderStatus.pending ||
                    order.status == OrderStatus.confirmed,
              )
              .toList();
          debugPrint('🔍 عدد الطلبات النشطة: ${statusFiltered.length}');
          break;
        case 'in_delivery':
          statusFiltered = baseOrders
              .where((order) => order.status == OrderStatus.inDelivery)
              .toList();
          break;
        case 'delivered':
          statusFiltered = baseOrders
              .where((order) => order.status == OrderStatus.delivered)
              .toList();
          break;
        case 'cancelled':
          statusFiltered = baseOrders
              .where((order) => order.status == OrderStatus.cancelled)
              .toList();
          break;
      }
    } else {
      // ✅ للفلاتر "all" و "scheduled"، استخدم جميع الطلبات من baseOrders
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
      backgroundColor: const Color(0xFF1a1a2e),
      extendBody: true, // السماح للمحتوى بالظهور خلف الشريط السفلي
      body: ListenableBuilder(
        listenable: _ordersService,
        builder: (context, child) {
          return Column(
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
          );
        },
      ),
      // الشريط السفلي
      bottomNavigationBar: const CustomBottomNavigationBar(
        currentRoute: '/orders',
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
                      return _buildOrderCard(displayedOrders[index]);
                    }, childCount: displayedOrders.length),
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
              'تم التوصيل',
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
    double width = status == 'in_delivery' || status == 'delivered' ? 130 : 95;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = status;
        });
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
                      fontSize: status == 'in_delivery' || status == 'delivered'
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

    // 🎨 الحصول على ألوان البطاقة حسب حالة الطلب
    final cardColors = _getOrderCardColors(
      order.status.toString(),
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
                        child: _buildStatusBadge(order.status),
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

  // بناء شارة الحالة
  Widget _buildStatusBadge(OrderStatus status) {
    Color backgroundColor;
    Color textColor;
    String statusText;

    switch (status) {
      case OrderStatus.pending:
        backgroundColor = const Color(0xFFffd700); // أصفر ذهبي
        textColor = Colors.black;
        statusText = 'نشط';
        break;
      case OrderStatus.confirmed:
        backgroundColor = const Color(0xFFffd700); // أصفر ذهبي
        textColor = Colors.black;
        statusText = 'نشط';
        break;
      case OrderStatus.inDelivery:
        backgroundColor = const Color(0xFF17a2b8); // سماوي
        textColor = Colors.white;
        statusText = 'قيد التوصيل';
        break;
      case OrderStatus.delivered:
        backgroundColor = const Color(0xFF28a745); // أخضر
        textColor = Colors.white;
        statusText = 'تم التوصيل';
        break;
      case OrderStatus.cancelled:
        backgroundColor = const Color(0xFFdc3545); // أحمر
        textColor = Colors.white;
        statusText = 'ملغي';
        break;
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

          // أزرار التعديل والحذف (للطلبات المجدولة والطلبات النشطة فقط)
          if (isScheduled ||
              order.status == OrderStatus.pending ||
              order.status == OrderStatus.confirmed)
            Row(
              children: [
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
    if (order.status != OrderStatus.pending &&
        order.status != OrderStatus.confirmed) {
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

    // التحقق من الوقت المتبقي (24 ساعة)
    final now = DateTime.now();
    final deadline = order.createdAt.add(const Duration(hours: 24));
    if (now.isAfter(deadline)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'انتهت فترة التعديل المسموحة (24 ساعة)',
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

  // حذف الطلب (للطلبات النشطة فقط)
  void _deleteOrder(Order order) {
    // التحقق من إمكانية الحذف
    if (order.status != OrderStatus.pending &&
        order.status != OrderStatus.confirmed) {
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

      // حذف الطلب عبر HTTP API
      bool success = await _ordersService.deleteOrder(order.id);

      if (!success) {
        throw Exception('فشل في حذف الطلب');
      }

      // إخفاء مؤشر التحميل
      if (mounted) Navigator.pop(context);

      // إظهار رسالة نجاح
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف الطلب بنجاح', style: GoogleFonts.cairo()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // إخفاء مؤشر التحميل
      if (mounted) Navigator.pop(context);

      // إظهار رسالة خطأ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حذف الطلب: $e', style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // دالة لتحديد ألوان الإطار والظل حسب حالة الطلب
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

    // ألوان الطلبات العادية حسب حالة الطلب
    // تحويل OrderStatus enum إلى string للمقارنة
    final statusString = status.toLowerCase().replaceAll('orderstatus.', '');

    switch (statusString) {
      case 'pending':
      case 'confirmed':
      case 'active':
      case 'نشط':
      case 'مؤكد':
        return {
          'borderColor': const Color(0xFFffd700), // ذهبي للنشط
          'shadowColor': const Color(0xFFffd700).withValues(alpha: 0.4),
          'gradientColors': [
            const Color(0xFF1a1a2e).withValues(alpha: 0.95),
            const Color(0xFF16213e).withValues(alpha: 0.9),
            const Color(0xFF2d2438).withValues(alpha: 0.85),
          ],
        };
      case 'indelivery':
      case 'in_delivery':
      case 'قيد التوصيل':
        return {
          'borderColor': const Color(0xFF007bff), // أزرق لقيد التوصيل
          'shadowColor': const Color(0xFF007bff).withValues(alpha: 0.4),
          'gradientColors': [
            const Color(0xFF1a2332).withValues(alpha: 0.95),
            const Color(0xFF162838).withValues(alpha: 0.9),
            const Color(0xFF1e3a5f).withValues(alpha: 0.85),
          ],
        };
      case 'delivered':
      case 'تم التوصيل':
        return {
          'borderColor': const Color(0xFF28a745), // أخضر لتم التوصيل
          'shadowColor': const Color(0xFF28a745).withValues(alpha: 0.4),
          'gradientColors': [
            const Color(0xFF1a2e1a).withValues(alpha: 0.95),
            const Color(0xFF162e16).withValues(alpha: 0.9),
            const Color(0xFF1e3f1e).withValues(alpha: 0.85),
          ],
        };
      case 'cancelled':
      case 'ملغي':
        return {
          'borderColor': const Color(0xFFdc3545), // أحمر للملغي
          'shadowColor': const Color(0xFFdc3545).withValues(alpha: 0.4),
          'gradientColors': [
            const Color(0xFF2e1a1a).withValues(alpha: 0.95),
            const Color(0xFF2e1616).withValues(alpha: 0.9),
            const Color(0xFF3f1e1e).withValues(alpha: 0.85),
          ],
        };
      default:
        return {
          'borderColor': const Color(0xFFffc107), // أصفر للحالات غير المعروفة
          'shadowColor': const Color(0xFFffc107).withValues(alpha: 0.3),
          'gradientColors': [
            const Color(0xFF2e2a1a).withValues(alpha: 0.9),
            const Color(0xFF2e2616).withValues(alpha: 0.8),
          ],
        };
    }
  }
}
