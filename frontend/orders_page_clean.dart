import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


import '../services/simple_orders_service.dart';
import '../services/scheduled_orders_service.dart';
import '../services/global_orders_cache.dart';
import '../widgets/pull_to_refresh_wrapper.dart';
import '../utils/error_handler.dart';
import '../services/order_sync_service.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../widgets/common_header.dart';
import '../utils/order_status_helper.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  String selectedFilter = 'all';

  // ┘à╪ز╪║┘è╪▒╪د╪ز ╪د┘╪ذ╪ص╪س
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // ╪«╪»┘à╪د╪ز ╪د┘╪╖┘╪ذ╪د╪ز
  final SimpleOrdersService _ordersService = SimpleOrdersService();
  final ScheduledOrdersService _scheduledOrdersService =
      ScheduledOrdersService();

  // ظأة Global Cache ┘┘╪╣╪▒╪╢ ╪د┘┘┘ê╪▒┘è
  final GlobalOrdersCache _globalCache = GlobalOrdersCache();

  // ┘à╪ز╪ص┘â┘à ╪د┘╪ز┘à╪▒┘è╪▒ ┘┘╪ز╪ص┘à┘è┘ ╪د┘╪ز╪»╪▒┘è╪ش┘è
  final ScrollController _scrollController = ScrollController();

  final List<Order> _scheduledOrders = [];



  // ╪»╪د┘╪ر ┘à╪▒╪د┘é╪ذ╪ر ╪د┘╪ز┘à╪▒┘è╪▒ ┘┘╪ز╪ص┘à┘è┘ ╪د┘╪ز╪»╪▒┘è╪ش┘è
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // ╪╣┘╪»┘à╪د ┘è╪╡┘ ╪د┘┘à╪│╪ز╪«╪»┘à ┘┘é╪▒╪ذ ┘┘ç╪د┘è╪ر ╪د┘┘é╪د╪خ┘à╪ر (200 ╪ذ┘â╪│┘ ┘à┘ ╪د┘┘┘ç╪د┘è╪ر)
      if (_ordersService.hasMoreData && !_ordersService.isLoadingMore) {
        _ordersService.loadMoreOrders();
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // ╪ح╪╣╪»╪د╪» ┘à╪│╪ز┘à╪╣ ╪د┘╪ز┘à╪▒┘è╪▒ ┘┘╪ز╪ص┘à┘è┘ ╪د┘╪ز╪»╪▒┘è╪ش┘è
    _scrollController.addListener(_onScroll);

    // ظأة ╪╣╪▒╪╢ ┘┘ê╪▒┘è ┘┘╪ذ┘è╪د┘╪د╪ز ╪د┘┘à╪«╪▓┘╪ر - ╪ذ╪»┘ê┘ ╪د┘╪ز╪╕╪د╪▒!
    _displayCachedDataInstantly();

    // ╪ح╪╢╪د┘╪ر ┘à╪│╪ز┘à╪╣ ┘╪ح╪╣╪د╪»╪ر ╪ز╪ص┘à┘è┘ ╪د┘╪╖┘╪ذ╪د╪ز ╪╣┘╪» ╪د┘╪╣┘ê╪»╪ر ┘┘╪╡┘╪ص╪ر
    _ordersService.addListener(_onOrdersChanged);

    // ظ£à ╪ح╪╢╪د┘╪ر ┘à╪│╪ز┘à╪╣ ┘┘╪╖┘╪ذ╪د╪ز ╪د┘┘à╪ش╪»┘ê┘╪ر
    _scheduledOrdersService.addListener(_onScheduledOrdersChanged);

    // ظأة ╪ح╪╢╪د┘╪ر ┘à╪│╪ز┘à╪╣ ┘┘┘â╪د╪┤ ╪د┘╪╣╪د┘┘à┘è
    _globalCache.addListener(_onGlobalCacheChanged);

    // ╪ح╪╣╪د╪»╪ر ╪ز╪╣┘è┘è┘ ╪د┘┘┘╪ز╪▒ ╪ح┘┘ë "╪د┘┘â┘" ┘╪╢┘à╪د┘ ╪▒╪ج┘è╪ر ╪د┘╪╖┘╪ذ╪د╪ز ╪د┘╪ش╪»┘è╪»╪ر
    selectedFilter = 'all';

    // ╪ذ╪»╪ة ┘à╪▒╪د┘é╪ذ╪ر ╪ز╪ص╪»┘è╪س╪د╪ز ╪د┘╪╖┘╪ذ╪د╪ز ┘à┘ ╪┤╪▒┘â╪ر ╪د┘┘ê╪│┘è╪╖
    OrderSyncService.startOrderSync();

    // ≡ا¤ ╪ز╪ص╪»┘è╪س ┘┘è ╪د┘╪«┘┘┘è╪ر (╪ذ╪»┘ê┘ ╪ز┘ê┘é┘ ╪د┘┘ê╪د╪ش┘ç╪ر)
    _updateInBackground();
  }

  /// ظأة ╪╣╪▒╪╢ ┘┘ê╪▒┘è ┘┘╪ذ┘è╪د┘╪د╪ز ╪د┘┘à╪«╪▓┘╪ر
  void _displayCachedDataInstantly() {
    debugPrint('ظأة ╪╣╪▒╪╢ ┘┘ê╪▒┘è ┘┘╪ذ┘è╪د┘╪د╪ز ╪د┘┘à╪«╪▓┘╪ر...');

    if (_globalCache.isInitialized) {
      debugPrint('ظأة ╪د┘┘â╪د╪┤ ┘à┘ç┘è╪ث - ╪╣╪▒╪╢ ${_globalCache.orders.length} ╪╖┘╪ذ ┘┘ê╪▒╪د┘ï');
      if (mounted) {
        setState(() {});
      }
    } else {
      debugPrint('ظأبي╕ ╪د┘┘â╪د╪┤ ╪║┘è╪▒ ┘à┘ç┘è╪ث - ╪│┘è╪ز┘à ╪د┘╪ز┘ç┘è╪خ╪ر');
    }
  }

  /// ≡ا¤ ╪ز╪ص╪»┘è╪س ┘┘è ╪د┘╪«┘┘┘è╪ر
  Future<void> _updateInBackground() async {
    debugPrint('≡ا¤ ╪ذ╪»╪ة ╪د┘╪ز╪ص╪»┘è╪س ┘┘è ╪د┘╪«┘┘┘è╪ر...');

    // ╪ز┘ç┘è╪خ╪ر ╪د┘┘â╪د╪┤ ╪ح╪░╪د ┘┘à ┘è┘â┘ ┘à┘ç┘è╪ث
    if (!_globalCache.isInitialized) {
      await _globalCache.initialize();
    }

    // ╪ز╪ص╪»┘è╪س ┘┘è ╪د┘╪«┘┘┘è╪ر
    _globalCache.updateInBackground();
  }

  /// ظأة ┘à╪│╪ز┘à╪╣ ╪ز╪║┘è┘è╪▒╪د╪ز ╪د┘┘â╪د╪┤ ╪د┘╪╣╪د┘┘à┘è
  void _onGlobalCacheChanged() {
    debugPrint('ظأة ╪ز┘à ╪ز╪ص╪»┘è╪س ╪د┘┘â╪د╪┤ ╪د┘╪╣╪د┘┘à┘è - ╪ح╪╣╪د╪»╪ر ╪ذ┘╪د╪ة ╪د┘┘ê╪د╪ش┘ç╪ر');
    if (mounted) {
      setState(() {});
    }
  }

  /// ╪ز╪ص╪»┘è╪س ╪د┘╪ذ┘è╪د┘╪د╪ز ╪╣┘╪» ╪د┘╪│╪ص╪ذ ┘┘╪ث╪│┘┘
  Future<void> _refreshData() async {
    try {
      debugPrint('≡ا¤ ╪ز╪ص╪»┘è╪س ╪ذ┘è╪د┘╪د╪ز ╪╡┘╪ص╪ر ╪د┘╪╖┘╪ذ╪د╪ز...');

      // ظ£à ┘╪▒╪╢ ╪ز╪ص╪»┘è╪س ╪د┘┘â╪د╪┤ ╪د┘╪╣╪د┘┘à┘è
      await _globalCache.forceRefresh();

      debugPrint('ظ£à ╪ز┘à ╪ز╪ص╪»┘è╪س ╪ذ┘è╪د┘╪د╪ز ╪╡┘╪ص╪ر ╪د┘╪╖┘╪ذ╪د╪ز ╪ذ┘╪ش╪د╪ص');
    } catch (e) {
      debugPrint('ظإî ╪«╪╖╪ث ┘┘è ╪د┘╪ز╪ص╪»┘è╪س: $e');
    }
  }

  // ╪ش┘╪ذ ╪د┘╪╖┘╪ذ╪د╪ز ╪د┘╪╣╪د╪»┘è╪ر ┘ê╪د┘┘à╪ش╪»┘ê┘╪ر
  Future<void> _loadOrders() async {
    debugPrint('≡ا¤ ╪ذ╪»╪ة ╪ز╪ص┘à┘è┘ ╪د┘╪╖┘╪ذ╪د╪ز ┘┘è ╪╡┘╪ص╪ر ╪د┘╪╖┘╪ذ╪د╪ز...');

    // ظأة ╪╣╪▒╪╢ ╪د┘╪ذ┘è╪د┘╪د╪ز ╪د┘┘à╪«╪▓┘╪ر ┘┘ê╪▒╪د┘ï (╪ح┘ ┘ê╪ش╪»╪ز)
    if (_ordersService.orders.isNotEmpty) {
      debugPrint('ظأة ╪╣╪▒╪╢ ╪د┘╪ذ┘è╪د┘╪د╪ز ╪د┘┘à╪«╪▓┘╪ر ┘┘ê╪▒╪د┘ï: ${_ordersService.orders.length} ╪╖┘╪ذ');
      if (mounted) {
        setState(() {});
      }
    }

    // ≡ا¤ ╪ز╪ص╪»┘è╪س ╪د┘╪ذ┘è╪د┘╪د╪ز ┘┘è ╪د┘╪«┘┘┘è╪ر (╪ذ╪»┘ê┘ ┘à╪│╪ص ╪د┘┘â╪د╪┤)
    await _ordersService.loadOrders(
      forceRefresh: false, // ╪د╪│╪ز╪«╪»╪د┘à ╪د┘┘â╪د╪┤ ╪ح╪░╪د ┘â╪د┘ ┘à╪ز╪د╪ص╪د┘ï
      statusFilter: selectedFilter == 'all' || selectedFilter == 'scheduled' ? null : selectedFilter,
    );

    // ╪ش┘╪ذ ╪د┘╪╖┘╪ذ╪د╪ز ╪د┘┘à╪ش╪»┘ê┘╪ر
    await _loadScheduledOrders();

    // ظ£à ╪د┘╪╖┘╪ذ╪د╪ز ┘à╪▒╪ز╪ذ╪ر ╪ذ╪د┘┘╪╣┘ ┘à┘ ┘é╪د╪╣╪»╪ر ╪د┘╪ذ┘è╪د┘╪د╪ز (ORDER BY created_at DESC)

    debugPrint(
      'ظ£à ╪د┘╪ز┘ç┘ë ╪ز╪ص┘à┘è┘ ╪د┘╪╖┘╪ذ╪د╪ز - ╪د┘╪╣╪د╪»┘è╪ر: ${_ordersService.orders.length}, ╪د┘┘à╪ش╪»┘ê┘╪ر: ${_scheduledOrders.length}',
    );
    if (mounted) {
      setState(() {});
    }
  }

  // ╪ش┘╪ذ ╪د┘╪╖┘╪ذ╪د╪ز ╪د┘┘à╪ش╪»┘ê┘╪ر
  Future<void> _loadScheduledOrders() async {
    try {
      // ظ£à ╪د┘╪ص╪╡┘ê┘ ╪╣┘┘ë ╪▒┘é┘à ┘ç╪د╪ز┘ ╪د┘┘à╪│╪ز╪«╪»┘à ╪د┘╪ص╪د┘┘è
      final prefs = await SharedPreferences.getInstance();
      final currentUserPhone = prefs.getString('current_user_phone');

      debugPrint('≡اô▒ ╪ز╪ص┘à┘è┘ ╪د┘╪╖┘╪ذ╪د╪ز ╪د┘┘à╪ش╪»┘ê┘╪ر ┘┘┘à╪│╪ز╪«╪»┘à: $currentUserPhone');

      await _scheduledOrdersService.loadScheduledOrders(
        userPhone: currentUserPhone,
      );
      _scheduledOrders.clear();
      _scheduledOrders.addAll(
        _scheduledOrdersService.scheduledOrders.map((scheduledOrder) {
          // ╪ز╪ص┘ê┘è┘ ScheduledOrder ╪ح┘┘ë Order ┘à╪╣ ╪ح╪┤╪د╪▒╪ر ╪ث┘┘ç ┘à╪ش╪»┘ê┘
          return Order(
            id: scheduledOrder.id,
            customerName: scheduledOrder.customerName,
            primaryPhone: scheduledOrder.customerPhone,
            secondaryPhone: scheduledOrder.customerAlternatePhone,
            province: scheduledOrder.customerProvince ?? '╪║┘è╪▒ ┘à╪ص╪»╪»',
            city: scheduledOrder.customerCity ?? '╪║┘è╪▒ ┘à╪ص╪»╪»',
            notes: scheduledOrder.customerNotes ?? scheduledOrder.notes,
            totalCost: scheduledOrder.totalAmount.toInt(),
            totalProfit: 0, // ╪║┘è╪▒ ┘à╪ز┘ê┘╪▒ ┘┘è ScheduledOrder
            subtotal: scheduledOrder.totalAmount.toInt(),
            total: scheduledOrder.totalAmount.toInt(),
            status: OrderStatus.pending,
            createdAt: scheduledOrder.createdAt,
            items: [], // ╪│┘╪╢┘è┘ ╪د┘╪╣┘╪د╪╡╪▒ ┘╪د╪ص┘é╪د┘ï ╪ح╪░╪د ┘╪▓┘à ╪د┘╪ث┘à╪▒
            scheduledDate: scheduledOrder.scheduledDate,
            scheduleNotes: scheduledOrder.notes,
          );
        }),
      );

      debugPrint('ظ£à ╪ز┘à ╪ز╪ص┘à┘è┘ ${_scheduledOrders.length} ╪╖┘╪ذ ┘à╪ش╪»┘ê┘ ┘┘┘à╪│╪ز╪«╪»┘à');
    } catch (e) {
      debugPrint('ظإî ╪«╪╖╪ث ┘┘è ╪ش┘╪ذ ╪د┘╪╖┘╪ذ╪د╪ز ╪د┘┘à╪ش╪»┘ê┘╪ر: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ظ£à ╪ز╪ص┘à┘è┘ ╪«┘┘è┘ - ╪د╪│╪ز╪«╪»╪د┘à ╪د┘┘ cache ╪ح╪░╪د ┘â╪د┘ ┘à╪ز╪د╪ص╪د┘ï
    debugPrint('≡اô▒ ╪ز┘à ╪د╪│╪ز╪»╪╣╪د╪ة didChangeDependencies - ╪ز╪ص┘à┘è┘ ╪«┘┘è┘');
    _loadOrdersLight();
  }

  // ظأة ╪ز╪ص┘à┘è┘ ╪«┘┘è┘ ┘┘╪╖┘╪ذ╪د╪ز - ┘è╪│╪ز╪«╪»┘à ╪د┘┘ cache ┘┘é╪╖
  Future<void> _loadOrdersLight() async {
    debugPrint('ظأة ╪ذ╪»╪ة ╪ز╪ص┘à┘è┘ ╪«┘┘è┘ ┘┘╪╖┘╪ذ╪د╪ز (╪د╪│╪ز╪«╪»╪د┘à ╪د┘┘â╪د╪┤)...');

    // ظأة ╪د╪│╪ز╪«╪»╪د┘à ╪د┘╪ذ┘è╪د┘╪د╪ز ╪د┘┘à╪«╪▓┘╪ر ┘┘é╪╖ - ╪ذ╪»┘ê┘ ╪ز╪ص┘à┘è┘ ┘à┘ ┘é╪د╪╣╪»╪ر ╪د┘╪ذ┘è╪د┘╪د╪ز
    if (_ordersService.orders.isNotEmpty) {
      debugPrint('ظأة ╪د╪│╪ز╪«╪»╪د┘à ╪د┘╪ذ┘è╪د┘╪د╪ز ╪د┘┘à╪«╪▓┘╪ر: ${_ordersService.orders.length} ╪╖┘╪ذ');
      if (mounted) {
        setState(() {});
      }
      return; // ╪د┘╪«╪▒┘ê╪ش ┘┘ê╪▒╪د┘ï ╪ذ╪»┘ê┘ ╪ز╪ص┘à┘è┘ ╪ح╪╢╪د┘┘è
    }

    // ┘┘é╪╖ ╪ح╪░╪د ┘┘à ╪ز┘â┘ ┘ç┘╪د┘â ╪ذ┘è╪د┘╪د╪ز ┘à╪«╪▓┘╪ر╪î ┘é┘à ╪ذ╪د┘╪ز╪ص┘à┘è┘
    await _ordersService.loadOrders(
      forceRefresh: false,
      statusFilter: selectedFilter == 'all' || selectedFilter == 'scheduled' ? null : selectedFilter,
    );

    // ╪ش┘╪ذ ╪د┘╪╖┘╪ذ╪د╪ز ╪د┘┘à╪ش╪»┘ê┘╪ر ┘┘é╪╖ ╪ح╪░╪د ┘┘à ╪ز┘â┘ ┘à╪ص┘à┘╪ر
    if (_scheduledOrders.isEmpty) {
      await _loadScheduledOrders();
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _ordersService.removeListener(_onOrdersChanged);
    _scheduledOrdersService.removeListener(_onScheduledOrdersChanged);
    _globalCache.removeListener(_onGlobalCacheChanged); // ظأة ╪ح╪▓╪د┘╪ر ┘à╪│╪ز┘à╪╣ ╪د┘┘â╪د╪┤ ╪د┘╪╣╪د┘┘à┘è
    super.dispose();
  }

  // ╪»╪د┘╪ر ┘╪ح╪╣╪د╪»╪ر ╪ذ┘╪د╪ة ╪د┘┘ê╪د╪ش┘ç╪ر ╪╣┘╪» ╪ز╪║┘è┘è╪▒ ╪د┘╪╖┘╪ذ╪د╪ز
  void _onOrdersChanged() {
    debugPrint('≡ا¤ === ╪ز┘à ╪د╪│╪ز╪»╪╣╪د╪ة _onOrdersChanged ===');
    debugPrint('≡اôè ╪╣╪»╪» ╪د┘╪╖┘╪ذ╪د╪ز ╪د┘╪ص╪د┘┘è: ${_ordersService.orders.length}');
    debugPrint('ظ░ ┘ê┘é╪ز ╪ت╪«╪▒ ╪ز╪ص╪»┘è╪س: ${_ordersService.lastUpdate}');
    debugPrint('≡ا¤ ╪ص╪د┘╪ر ╪د┘╪ز╪ص┘à┘è┘: ${_ordersService.isLoading}');

    if (_ordersService.orders.isNotEmpty) {
      debugPrint('≡اôï ╪ث╪ص╪»╪س 3 ╪╖┘╪ذ╪د╪ز ┘┘è ╪د┘╪«╪»┘à╪ر:');
      for (int i = 0; i < _ordersService.orders.length && i < 3; i++) {
        final order = _ordersService.orders[i];
        debugPrint('   ${i + 1}. ${order.customerName} - ${order.id}');
      }
    } else {
      debugPrint('ظأبي╕ ┘╪د ╪ز┘ê╪ش╪» ╪╖┘╪ذ╪د╪ز ┘┘è ╪د┘╪«╪»┘à╪ر!');
    }

    if (mounted) {
      debugPrint('≡ا¤ ╪د╪│╪ز╪»╪╣╪د╪ة setState() ┘╪ح╪╣╪د╪»╪ر ╪ذ┘╪د╪ة UI...');
      setState(() {
        debugPrint('ظ£à === ╪ز┘à ╪ح╪╣╪د╪»╪ر ╪ذ┘╪د╪ة UI ┘┘è orders_page ╪ذ┘╪ش╪د╪ص ===');
      });
    } else {
      debugPrint('ظإî Widget ╪║┘è╪▒ mounted - ┘╪د ┘è┘à┘â┘ ╪د╪│╪ز╪»╪╣╪د╪ة setState()');
    }
  }

  // ظ£à ╪»╪د┘╪ر ┘╪ح╪╣╪د╪»╪ر ╪ذ┘╪د╪ة ╪د┘┘ê╪د╪ش┘ç╪ر ╪╣┘╪» ╪ز╪║┘è┘è╪▒ ╪د┘╪╖┘╪ذ╪د╪ز ╪د┘┘à╪ش╪»┘ê┘╪ر
  void _onScheduledOrdersChanged() {
    debugPrint('≡اôà === ╪ز┘à ╪د╪│╪ز╪»╪╣╪د╪ة _onScheduledOrdersChanged ===');
    debugPrint(
      '≡اôè ╪╣╪»╪» ╪د┘╪╖┘╪ذ╪د╪ز ╪د┘┘à╪ش╪»┘ê┘╪ر: ${_scheduledOrdersService.scheduledOrders.length}',
    );

    // ظ£à ╪ز╪ص┘ê┘è┘ ╪د┘╪╖┘╪ذ╪د╪ز ╪د┘┘à╪ش╪»┘ê┘╪ر ╪ح┘┘ë Order ╪ذ╪»┘ê┘ ╪ح╪╣╪د╪»╪ر ╪ز╪ص┘à┘è┘
    _convertScheduledOrdersToOrderList();

    if (mounted) {
      setState(() {});
    }
  }

  // ظ£à ╪ز╪ص┘ê┘è┘ ╪د┘╪╖┘╪ذ╪د╪ز ╪د┘┘à╪ش╪»┘ê┘╪ر ╪ح┘┘ë ┘é╪د╪خ┘à╪ر Order ╪ذ╪»┘ê┘ ╪ح╪╣╪د╪»╪ر ╪ز╪ص┘à┘è┘
  void _convertScheduledOrdersToOrderList() {
    try {
      // ظ£à ╪ح┘╪┤╪د╪ة ┘é╪د╪خ┘à╪ر ╪ش╪»┘è╪»╪ر ╪ذ╪»┘╪د┘ï ┘à┘ ┘à╪ص╪د┘ê┘╪ر ╪ز╪╣╪»┘è┘ ╪د┘┘é╪د╪خ┘à╪ر ╪د┘┘à┘ê╪ش┘ê╪»╪ر
      final List<Order> newScheduledOrders = [];

      for (final scheduledOrder in _scheduledOrdersService.scheduledOrders) {
        final order = Order(
          id: scheduledOrder.id,
          customerName: scheduledOrder.customerName,
          primaryPhone: scheduledOrder.customerPhone,
          secondaryPhone: scheduledOrder.customerAlternatePhone,
          province:
              scheduledOrder.province ??
              scheduledOrder.customerProvince ??
              '╪║┘è╪▒ ┘à╪ص╪»╪»',
          city:
              scheduledOrder.city ?? scheduledOrder.customerCity ?? '╪║┘è╪▒ ┘à╪ص╪»╪»',
          notes: scheduledOrder.customerNotes ?? scheduledOrder.notes,
          totalCost: scheduledOrder.totalAmount.toInt(),
          totalProfit: 0, // ╪│┘è╪ز┘à ╪ص╪│╪د╪ذ┘ç ┘╪د╪ص┘é╪د┘ï
          subtotal: scheduledOrder.totalAmount.toInt(),
          total: scheduledOrder.totalAmount.toInt(),
          status: OrderStatus.pending, // ظ£à ╪ص╪د┘╪ر ╪د┘╪ز╪╕╪د╪▒ ┘┘╪╖┘╪ذ╪د╪ز ╪د┘┘à╪ش╪»┘ê┘╪ر
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
        newScheduledOrders.add(order);
      }

      // ظ£à ╪د╪│╪ز╪ذ╪»╪د┘ ╪د┘┘é╪د╪خ┘à╪ر ╪ذ╪د┘┘â╪د┘à┘ ╪ذ╪»┘╪د┘ï ┘à┘ ╪ز╪╣╪»┘è┘┘ç╪د
      _scheduledOrders.clear();
      _scheduledOrders.addAll(newScheduledOrders);

      debugPrint('ظ£à ╪ز┘à ╪ز╪ص┘ê┘è┘ ${_scheduledOrders.length} ╪╖┘╪ذ ┘à╪ش╪»┘ê┘ ╪ح┘┘ë Order');
    } catch (e) {
      debugPrint('ظإî ╪«╪╖╪ث ┘┘è ╪ز╪ص┘ê┘è┘ ╪د┘╪╖┘╪ذ╪د╪ز ╪د┘┘à╪ش╪»┘ê┘╪ر: $e');
    }
  }

  // ╪ص╪│╪د╪ذ ╪╣╪»╪» ╪د┘╪╖┘╪ذ╪د╪ز ┘┘â┘ ╪ص╪د┘╪ر ╪ذ╪د╪│╪ز╪«╪»╪د┘à ╪د┘┘╪╡ ╪د┘╪ص┘é┘è┘é┘è
  Map<String, int> get orderCounts {
    // ظ£à ╪د╪│╪ز╪«╪»╪د┘à ╪د┘╪╣╪»╪د╪»╪د╪ز ╪د┘┘â╪د┘à┘╪ر ┘à┘ ┘é╪د╪╣╪»╪ر ╪د┘╪ذ┘è╪د┘╪د╪ز ┘┘é╪╖
    final fullCounts = _ordersService.fullOrderCounts;
    final regularOrders = _ordersService.orders;

    return {
      'all': fullCounts['all'] ?? 0, // ╪د┘╪╣╪»╪» ╪د┘┘â╪د┘à┘ ┘à┘ ┘é╪د╪╣╪»╪ر ╪د┘╪ذ┘è╪د┘╪د╪ز
      'processing': regularOrders
          .where((order) => _isProcessingStatus(order.rawStatus))
          .length,
      'active': fullCounts['active'] ?? 0, // ╪د┘╪╣╪»╪» ╪د┘┘â╪د┘à┘ ┘à┘ ┘é╪د╪╣╪»╪ر ╪د┘╪ذ┘è╪د┘╪د╪ز
      'in_delivery': fullCounts['in_delivery'] ?? 0, // ╪د┘╪╣╪»╪» ╪د┘┘â╪د┘à┘ ┘à┘ ┘é╪د╪╣╪»╪ر ╪د┘╪ذ┘è╪د┘╪د╪ز
      'delivered': fullCounts['delivered'] ?? 0, // ╪د┘╪╣╪»╪» ╪د┘┘â╪د┘à┘ ┘à┘ ┘é╪د╪╣╪»╪ر ╪د┘╪ذ┘è╪د┘╪د╪ز
      'cancelled': fullCounts['cancelled'] ?? 0, // ╪د┘╪╣╪»╪» ╪د┘┘â╪د┘à┘ ┘à┘ ┘é╪د╪╣╪»╪ر ╪د┘╪ذ┘è╪د┘╪د╪ز
      // ظ£à ╪د┘╪╖┘╪ذ╪د╪ز ╪د┘┘à╪ش╪»┘ê┘╪ر ┘à┘┘╪╡┘╪ر
      'scheduled': _scheduledOrders.length,
    };
  }

  // ╪»┘ê╪د┘ ┘à╪│╪د╪╣╪»╪ر ┘╪ز╪ص╪»┘è╪» ┘┘ê╪╣ ╪د┘╪ص╪د┘╪ر

  // ┘é╪│┘à ┘à╪╣╪د┘╪ش╪ر - ╪د┘╪╖┘╪ذ╪د╪ز ╪د┘╪ز┘è ╪ز╪ص╪ز╪د╪ش ┘à╪╣╪د┘╪ش╪ر
  bool _isProcessingStatus(String status) {
    return status == '╪ز┘à ╪ز╪║┘è┘è╪▒ ┘à╪ص╪د┘╪╕╪ر ╪د┘╪▓╪ذ┘ê┘' ||
           status == '╪ز╪║┘è┘è╪▒ ╪د┘┘à┘╪»┘ê╪ذ' ||
           status == '┘╪د ┘è╪▒╪»' ||
           status == '┘╪د ┘è╪▒╪» ╪ذ╪╣╪» ╪د┘╪د╪ز┘╪د┘é' ||
           status == '┘à╪║┘┘é' ||
           status == '┘à╪║┘┘é ╪ذ╪╣╪» ╪د┘╪د╪ز┘╪د┘é' ||
           status == '╪د┘╪▒┘é┘à ╪║┘è╪▒ ┘à╪╣╪▒┘' ||
           status == '╪د┘╪▒┘é┘à ╪║┘è╪▒ ╪»╪د╪«┘ ┘┘è ╪د┘╪«╪»┘à╪ر' ||
           status == '┘╪د ┘è┘à┘â┘ ╪د┘╪د╪ز╪╡╪د┘ ╪ذ╪د┘╪▒┘é┘à' ||
           status == '┘à╪ج╪ش┘' ||
           status == '┘à╪ج╪ش┘ ┘╪ص┘è┘ ╪د╪╣╪د╪»╪ر ╪د┘╪╖┘╪ذ ┘╪د╪ص┘é╪د' ||
           status == '┘à┘╪╡┘ê┘ ╪╣┘ ╪د┘╪«╪»┘à╪ر' ||
           status == '╪╖┘╪ذ ┘à┘â╪▒╪▒' ||
           status == '┘à╪│╪ز┘┘à ┘à╪│╪ذ┘é╪د' ||
           status == '╪د┘╪╣┘┘ê╪د┘ ╪║┘è╪▒ ╪»┘é┘è┘é' ||
           status == '┘┘à ┘è╪╖┘╪ذ' ||
           status == '╪ص╪╕╪▒ ╪د┘┘à┘╪»┘ê╪ذ';
  }

  // ┘é╪│┘à ┘╪┤╪╖ - ╪د┘╪╖┘╪ذ╪د╪ز ╪د┘┘╪┤╪╖╪ر ┘┘é╪╖
  bool _isActiveStatus(String status) {
    return status == '┘╪┤╪╖' || status == 'active';
  }

  // ┘é╪│┘à ┘é┘è╪» ╪د┘╪ز┘ê╪╡┘è┘
  bool _isInDeliveryStatus(String status) {
    return status == '┘é┘è╪» ╪د┘╪ز┘ê╪╡┘è┘ ╪د┘┘ë ╪د┘╪▓╪ذ┘ê┘ (┘┘è ╪╣┘ç╪»╪ر ╪د┘┘à┘╪»┘ê╪ذ)' ||
           status == 'in_delivery';
  }

  // ┘é╪│┘à ╪ز┘à ╪د┘╪ز╪│┘┘è┘à
  bool _isDeliveredStatus(String status) {
    return status == '╪ز┘à ╪د┘╪ز╪│┘┘è┘à ┘┘╪▓╪ذ┘ê┘' ||
           status == 'delivered';
  }

  // ┘é╪│┘à ┘à┘╪║┘è - ╪د┘╪╖┘╪ذ╪د╪ز ╪د┘┘à┘╪║┘è╪ر ┘ê╪د┘┘à╪▒┘┘ê╪╢╪ر
  bool _isCancelledStatus(String status) {
    return status == '╪د┘╪║╪د╪ة ╪د┘╪╖┘╪ذ' ||
           status == '╪▒┘╪╢ ╪د┘╪╖┘╪ذ' ||
           status == 'cancelled';
  }

  // ┘┘╪ز╪▒╪ر ╪د┘╪╖┘╪ذ╪د╪ز ╪ص╪│╪ذ ╪د┘╪ص╪د┘╪ر ┘ê╪د┘╪ذ╪ص╪س
  List<Order> get filteredOrders {
    // ظأة ╪د╪│╪ز╪«╪»╪د┘à ╪د┘┘â╪د╪┤ ╪د┘╪╣╪د┘┘à┘è ┘┘╪╣╪▒╪╢ ╪د┘┘┘ê╪▒┘è
    List<Order> baseOrders;
    if (selectedFilter == 'scheduled') {
      // ╪ح╪░╪د ┘â╪د┘ ╪د┘┘┘╪ز╪▒ "┘à╪ش╪»┘ê┘"╪î ╪د╪╣╪▒╪╢ ╪د┘╪╖┘╪ذ╪د╪ز ╪د┘┘à╪ش╪»┘ê┘╪ر ┘┘é╪╖
      baseOrders = _globalCache.getScheduledOrdersAsOrders();
      debugPrint('≡اôï ╪╣╪▒╪╢ ╪د┘╪╖┘╪ذ╪د╪ز ╪د┘┘à╪ش╪»┘ê┘╪ر ┘┘é╪╖: ${baseOrders.length}');
    } else {
      // ┘╪ش┘à┘è╪╣ ╪د┘┘┘╪د╪ز╪▒ ╪د┘╪ث╪«╪▒┘ë╪î ╪د╪╣╪▒╪╢ ╪د┘╪╖┘╪ذ╪د╪ز ╪د┘╪╣╪د╪»┘è╪ر ┘┘é╪╖ ┘à┘ ╪د┘┘â╪د╪┤
      baseOrders = _globalCache.getFilteredOrders(
        selectedFilter == 'all' ? null : selectedFilter
      );
      debugPrint('≡اôï ╪╣╪▒╪╢ ╪د┘╪╖┘╪ذ╪د╪ز ╪د┘╪╣╪د╪»┘è╪ر ┘┘é╪╖: ${baseOrders.length}');
    }

    // ظ£à ╪╢┘à╪د┘ ╪د┘╪ز╪▒╪ز┘è╪ذ ╪د┘╪╡╪ص┘è╪ص: ╪د┘╪ث╪ص╪»╪س ╪ث┘ê┘╪د┘ï ╪»╪د╪خ┘à╪د┘ï
    baseOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    debugPrint(
      '≡اôï ╪د┘┘┘╪ز╪▒ ╪د┘╪ص╪د┘┘è: $selectedFilter, ╪╣╪»╪» ╪د┘╪╖┘╪ذ╪د╪ز: ${baseOrders.length}',
    );

    // ظ£à ╪╖╪ذ╪د╪╣╪ر ╪ز┘╪د╪╡┘è┘ ╪ث┘ê┘ 3 ╪╖┘╪ذ╪د╪ز ┘┘╪ز╪┤╪«┘è╪╡
    if (baseOrders.isNotEmpty) {
      debugPrint('≡اôï ╪ث┘ê┘ 3 ╪╖┘╪ذ╪د╪ز ┘┘è filteredOrders (╪ذ╪╣╪» ╪د┘╪ز╪▒╪ز┘è╪ذ):');
      for (int i = 0; i < baseOrders.length && i < 3; i++) {
        final order = baseOrders[i];
        debugPrint(
          '   ${i + 1}. ${order.customerName} - ${order.id} - ${order.createdAt}',
        );
      }
    } else {
      debugPrint('ظأبي╕ ┘╪د ╪ز┘ê╪ش╪» ╪╖┘╪ذ╪د╪ز ┘┘è filteredOrders!');
    }

    // ╪╖╪ذ╪د╪╣╪ر ╪ص╪د┘╪د╪ز ╪د┘╪╖┘╪ذ╪د╪ز ╪د┘┘à┘ê╪ش┘ê╪»╪ر ┘┘╪ز╪┤╪«┘è╪╡
    final statusCounts = <String, int>{};
    for (final order in baseOrders) {
      final statusKey = order.status.toString().split('.').last;
      statusCounts[statusKey] = (statusCounts[statusKey] ?? 0) + 1;
    }
    debugPrint('≡اôè ╪ح╪ص╪╡╪د╪خ┘è╪د╪ز ╪د┘╪ص╪د┘╪د╪ز: $statusCounts');

    // ╪ز╪╖╪ذ┘è┘é ┘┘╪ز╪▒ ╪د┘╪ص╪د┘╪ر ╪ث┘ê┘╪د┘ï
    List<Order> statusFiltered = baseOrders;

    if (selectedFilter == 'scheduled') {
      // ظ£à ┘┘╪╖┘╪ذ╪د╪ز ╪د┘┘à╪ش╪»┘ê┘╪ر╪î ╪د╪│╪ز╪«╪»┘à ╪ش┘à┘è╪╣ ╪د┘╪╖┘╪ذ╪د╪ز ┘à┘ baseOrders
      statusFiltered = baseOrders;
      debugPrint('≡ا¤ ╪╣╪»╪» ╪د┘╪╖┘╪ذ╪د╪ز ╪د┘┘à╪ش╪»┘ê┘╪ر: ${statusFiltered.length}');
    } else {
      // ظ£à ┘┘╪╖┘╪ذ╪د╪ز ╪د┘╪╣╪د╪»┘è╪ر╪î ╪د┘┘┘╪ز╪▒╪ر ╪ز┘à╪ز ╪ذ╪د┘┘╪╣┘ ╪╣┘┘ë ┘à╪│╪ز┘ê┘ë ┘é╪د╪╣╪»╪ر ╪د┘╪ذ┘è╪د┘╪د╪ز
      statusFiltered = baseOrders;
      debugPrint(
        '≡ا¤ ╪╣╪»╪» ╪د┘╪╖┘╪ذ╪د╪ز ╪د┘┘à┘┘╪ز╪▒╪ر ┘┘╪ص╪د┘╪ر $selectedFilter: ${statusFiltered.length}',
      );
    }

    // ╪ز╪╖╪ذ┘è┘é ┘┘╪ز╪▒ ╪د┘╪ذ╪ص╪س
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

      debugPrint('≡ا¤ ╪╣╪»╪» ╪د┘╪╖┘╪ذ╪د╪ز ╪ذ╪╣╪» ╪د┘╪ذ╪ص╪س: ${statusFiltered.length}');
    }

    return statusFiltered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      extendBody: true, // ╪د┘╪│┘à╪د╪ص ┘┘┘à╪ص╪ز┘ê┘ë ╪ذ╪د┘╪╕┘ç┘ê╪▒ ╪«┘┘ ╪د┘╪┤╪▒┘è╪╖ ╪د┘╪│┘┘┘è
      body: ListenableBuilder(
        listenable: _ordersService,
        builder: (context, child) {
          return Column(
            children: [
              // ╪د┘╪┤╪▒┘è╪╖ ╪د┘╪╣┘┘ê┘è ╪د┘┘à┘ê╪ص╪»
              CommonHeader(
                title: '╪د┘╪╖┘╪ذ╪د╪ز',
                rightActions: [
                  // ╪▓╪▒ ╪د┘╪▒╪ش┘ê╪╣ ╪╣┘┘ë ╪د┘┘è┘à┘è┘
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

              // ┘à┘╪╖┘é╪ر ╪د┘┘à╪ص╪ز┘ê┘ë ╪د┘┘é╪د╪ذ┘ ┘┘╪ز┘à╪▒┘è╪▒ (╪ز╪ص╪ز┘ê┘è ╪╣┘┘ë ╪د┘╪ذ╪ص╪س ┘ê╪د┘┘┘╪ز╪▒ ┘ê╪د┘╪╖┘╪ذ╪د╪ز)
              Expanded(child: _buildScrollableContent()),
            ],
          );
        },
      ),
      // ╪د┘╪┤╪▒┘è╪╖ ╪د┘╪│┘┘┘è
      bottomNavigationBar: const CustomBottomNavigationBar(
        currentRoute: '/orders',
      ),
    );
  }



  // ╪ذ┘╪د╪ة ╪د┘┘à╪ص╪ز┘ê┘ë ╪د┘┘é╪د╪ذ┘ ┘┘╪ز┘à╪▒┘è╪▒
  Widget _buildScrollableContent() {
    List<Order> displayedOrders = filteredOrders;

    return PullToRefreshWrapper(
      onRefresh: _refreshData,
      refreshMessage: '╪ز┘à ╪ز╪ص╪»┘è╪س ╪د┘╪╖┘╪ذ╪د╪ز',
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ╪┤╪▒┘è╪╖ ╪د┘╪ذ╪ص╪س
          SliverToBoxAdapter(child: _buildSearchBar()),

          // ╪┤╪▒┘è╪╖ ┘┘╪ز╪▒ ╪د┘╪ص╪د┘╪ر
          SliverToBoxAdapter(child: _buildFilterBar()),

          // ┘é╪د╪خ┘à╪ر ╪د┘╪╖┘╪ذ╪د╪ز
          displayedOrders.isEmpty
              ? SliverFillRemaining(child: _buildEmptyState())
              : SliverPadding(
                  padding: const EdgeInsets.only(
                    left: 8,
                    right: 8,
                    top: 15,
                    bottom: 100, // ┘à╪│╪د╪ص╪ر ┘┘╪┤╪▒┘è╪╖ ╪د┘╪│┘┘┘è
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return _buildOrderCard(displayedOrders[index]);
                    }, childCount: displayedOrders.length),
                  ),
                ),

          // ┘à╪ج╪┤╪▒ ╪د┘╪ز╪ص┘à┘è┘ ╪د┘╪ز╪»╪▒┘è╪ش┘è
          if (_ordersService.isLoadingMore)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffd700)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ╪ذ┘╪د╪ة ╪┤╪▒┘è╪╖ ╪د┘╪ذ╪ص╪س
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a3e),
        borderRadius: BorderRadius.circular(12), // ظ£à ╪▓┘ê╪د┘è╪د ┘à┘é┘ê╪│╪ر ╪«┘┘è┘╪ر
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
          hintText: '╪د┘╪ذ╪ص╪س ╪ذ╪▒┘é┘à ╪د┘┘ç╪د╪ز┘ ╪ث┘ê ╪د╪│┘à ╪د┘╪╣┘à┘è┘...',
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

  // ╪ذ┘╪د╪ة ╪┤╪▒┘è╪╖ ┘┘╪ز╪▒ ╪د┘╪ص╪د┘╪ر
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
              '╪د┘┘â┘',
              FontAwesomeIcons.list,
              const Color(0xFF6c757d),
            ),
            const SizedBox(width: 12),
            _buildFilterButton(
              'processing',
              '┘à╪╣╪د┘╪ش╪ر',
              FontAwesomeIcons.wrench,
              const Color(0xFFff6b35),
            ),
            const SizedBox(width: 12),
            _buildFilterButton(
              'active',
              '┘╪┤╪╖',
              FontAwesomeIcons.clock,
              const Color(0xFFffc107),
            ),
            const SizedBox(width: 12),
            _buildFilterButton(
              'in_delivery',
              '┘é┘è╪» ╪د┘╪ز┘ê╪╡┘è┘',
              FontAwesomeIcons.truck,
              const Color(0xFF007bff),
            ),
            const SizedBox(width: 12),
            _buildFilterButton(
              'delivered',
              '╪ز┘à ╪د┘╪ز╪│┘┘è┘à',
              FontAwesomeIcons.circleCheck,
              const Color(0xFF28a745),
            ),
            const SizedBox(width: 12),
            _buildFilterButton(
              'cancelled',
              '┘à┘╪║┘è',
              FontAwesomeIcons.circleXmark,
              const Color(0xFFdc3545),
            ),
            const SizedBox(width: 12),
            // ظ£à ┘┘╪ز╪▒ ╪د┘╪╖┘╪ذ╪د╪ز ╪د┘┘à╪ش╪»┘ê┘╪ر
            _buildFilterButton(
              'scheduled',
              '┘à╪ش╪»┘ê┘',
              FontAwesomeIcons.calendar,
              const Color(0xFF8b5cf6),
            ),
            const SizedBox(width: 20), // ┘à╪│╪د╪ص╪ر ╪ح╪╢╪د┘┘è╪ر ┘┘è ╪د┘┘┘ç╪د┘è╪ر
          ],
        ),
      ),
    );
  }

  // ╪ذ┘╪د╪ة ╪▓╪▒ ╪د┘┘┘╪ز╪▒ ┘à╪╣ ╪د┘╪╣╪»╪د╪»
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
        // ظأة ╪ز╪ص╪»┘è╪س ┘┘ê╪▒┘è ┘┘┘ê╪د╪ش┘ç╪ر - ╪╣╪▒╪╢ ┘┘ê╪▒┘è ┘à┘ ╪د┘┘â╪د╪┤
        setState(() {
          selectedFilter = status;
        });

        debugPrint('ظأة ╪ز╪║┘è┘è╪▒ ╪د┘┘┘╪ز╪▒ ╪ح┘┘ë: $status - ╪╣╪▒╪╢ ┘┘ê╪▒┘è ┘à┘ ╪د┘┘â╪د╪┤');

        // ظأة ╪╣╪▒╪╢ ╪د┘┘╪ز╪د╪خ╪ش ┘┘ê╪▒╪د┘ï ┘à┘ ╪د┘┘â╪د╪┤ ╪د┘╪╣╪د┘┘à┘è
        if (mounted) {
          setState(() {});
        }

        // ≡ا¤ ╪ز╪ص╪»┘è╪س ┘┘è ╪د┘╪«┘┘┘è╪ر (╪د╪«╪ز┘è╪د╪▒┘è)
        if (status != 'scheduled') {
          _globalCache.updateInBackground();
        }
      },
      child: IntrinsicHeight(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: width * 0.95, // ╪ز┘â╪ذ┘è╪▒ ╪د┘╪╣╪▒╪╢ ┘é┘┘è┘╪د┘ï
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
                    size: 12, // ╪ز┘â╪ذ┘è╪▒ ╪د┘╪ث┘è┘é┘ê┘╪ر ┘é┘┘è┘╪د┘ï
                  ),
                  const SizedBox(width: 4), // ╪▓┘è╪د╪»╪ر ╪د┘┘à╪│╪د┘╪ر ┘é┘┘è┘╪د┘ï
                  Text(
                    label,
                    style: GoogleFonts.cairo(
                      fontSize: _isInDeliveryStatus(status) || _isDeliveredStatus(status) || status == 'processing'
                          ? 10 // ╪ز┘â╪ذ┘è╪▒ ╪د┘┘╪╡ ┘é┘┘è┘╪د┘ï
                          : 11, // ╪ز┘â╪ذ┘è╪▒ ╪د┘┘╪╡ ┘é┘┘è┘╪د┘ï
                      fontWeight: FontWeight.w600,
                      color: status == 'active' ? Colors.black : Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2), // ╪▓┘è╪د╪»╪ر ╪د┘┘à╪│╪د┘╪ر ┘é┘┘è┘╪د┘ï
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 2,
                ), // ╪ز┘â╪ذ┘è╪▒ ╪د┘╪ص╪┤┘ê ┘é┘┘è┘╪د┘ï
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(
                    8,
                  ), // ╪ز┘â╪ذ┘è╪▒ ╪د┘╪▓┘ê╪د┘è╪د ┘é┘┘è┘╪د┘ï
                ),
                child: Text(
                  count.toString(),
                  style: GoogleFonts.cairo(
                    fontSize: 10, // ╪ز┘â╪ذ┘è╪▒ ╪د┘┘╪╡ ┘é┘┘è┘╪د┘ï
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

  // ╪ذ┘╪د╪ة ╪ص╪د┘╪ر ╪╣╪»┘à ┘ê╪ش┘ê╪» ╪╖┘╪ذ╪د╪ز
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
            '┘╪د ╪ز┘ê╪ش╪» ╪╖┘╪ذ╪د╪ز ╪ص╪د┘┘è╪د┘ï',
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

  // ╪ذ┘╪د╪ة ╪ذ╪╖╪د┘é╪ر ╪د┘╪╖┘╪ذ ╪د┘┘ê╪د╪ص╪»╪ر
  Widget _buildOrderCard(Order order) {
    // ظ£à ╪ز╪ص╪»┘è╪» ╪ح╪░╪د ┘â╪د┘ ╪د┘╪╖┘╪ذ ┘à╪ش╪»┘ê┘
    final bool isScheduled = order.scheduledDate != null;

    // ≡اذ ╪د┘╪ص╪╡┘ê┘ ╪╣┘┘ë ╪ث┘┘ê╪د┘ ╪د┘╪ذ╪╖╪د┘é╪ر ╪ص╪│╪ذ ╪ص╪د┘╪ر ╪د┘╪╖┘╪ذ ╪د┘╪ص┘é┘è┘é┘è╪ر
    final cardColors = _getOrderCardColors(
      order.rawStatus, // ╪د╪│╪ز╪«╪»╪د┘à ╪د┘┘╪╡ ╪د┘╪ص┘é┘è┘é┘è ┘à┘ ┘é╪د╪╣╪»╪ر ╪د┘╪ذ┘è╪د┘╪د╪ز
      isScheduled,
    );

    return GestureDetector(
      onTap: () => _showOrderDetails(order),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        width: MediaQuery.of(context).size.width * 0.95,
        height: isScheduled ? 145 : 145, // ╪د╪▒╪ز┘╪د╪╣ ╪ث┘é┘ ┘┘╪╖┘╪ذ╪د╪ز ╪د┘┘à╪ش╪»┘ê┘╪ر
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
            // ╪╕┘ ┘à┘┘ê┘ ╪ص╪│╪ذ ╪ص╪د┘╪ر ╪د┘╪╖┘╪ذ
            BoxShadow(
              color: cardColors['shadowColor'],
              blurRadius: 25,
              offset: const Offset(0, 10),
              spreadRadius: 3,
            ),
            // ╪╕┘ ╪»╪د╪«┘┘è ┘┘╪╣┘à┘é
            BoxShadow(
              color: cardColors['borderColor'].withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 0),
              spreadRadius: 1,
            ),
            // ╪╕┘ ╪ث╪│┘ê╪» ┘┘╪╣┘à┘é
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            // ╪╕┘ ╪«┘┘è┘ ┘┘╪ص┘ê╪د┘
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(2), // ╪ز┘é┘┘è┘ ╪د┘┘à╪│╪د╪ص╪ر ╪د┘╪»╪د╪«┘┘è╪ر
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ╪د┘╪╡┘ ╪د┘╪ث┘ê┘ - ┘à╪╣┘┘ê┘à╪د╪ز ╪د┘╪▓╪ذ┘ê┘
              _buildCustomerInfoWithStatus(order),

              // ╪د┘╪╡┘ ╪د┘╪س╪د┘╪س - ╪ص╪د┘╪ر ╪د┘╪╖┘╪ذ
              Container(
                height: 32, // ╪د╪▒╪ز┘╪د╪╣ ┘â╪د┘┘è ┘╪╣╪▒╪╢ ╪د┘┘╪╡ ┘â╪د┘à┘╪د┘ï
                margin: const EdgeInsets.symmetric(vertical: 2), // ┘à╪│╪د╪ص╪ر ┘à┘╪د╪│╪ذ╪ر
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
                            '┘à╪ش╪»┘ê┘',
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
                      ), // ╪╣╪▒╪╢ ╪ص╪د┘╪ر ╪د┘╪╖┘╪ذ ┘┘╪╖┘╪ذ╪د╪ز ╪د┘╪╣╪د╪»┘è╪ر
              ),

              // ╪د┘╪╡┘ ╪د┘╪▒╪د╪ذ╪╣ - ╪د┘┘à╪╣┘┘ê┘à╪د╪ز ╪د┘┘à╪د┘┘è╪ر ┘ê╪د┘╪ز╪د╪▒┘è╪«
              _buildOrderFooter(order),
            ],
          ),
        ),
      ),
    );
  }

  // ╪ذ┘╪د╪ة ┘à╪╣┘┘ê┘à╪د╪ز ╪د┘╪▓╪ذ┘ê┘ ┘à╪╣ ╪ص╪د┘╪ر ╪د┘╪╖┘╪ذ
  Widget _buildCustomerInfoWithStatus(Order order) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 2,
        ), // ╪ز┘é┘┘è┘ ╪د┘┘à╪│╪د╪ص╪ر
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ╪د┘╪╣┘à┘ê╪» ╪د┘╪ث┘è╪│╪▒: ┘à╪╣┘┘ê┘à╪د╪ز ╪د┘╪▓╪ذ┘ê┘
            Flexible(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ╪د╪│┘à ╪د┘╪▓╪ذ┘ê┘
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

                  // ╪▒┘é┘à ╪د┘┘ç╪د╪ز┘
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

                  // ╪د┘╪╣┘┘ê╪د┘ (╪د┘┘à╪ص╪د┘╪╕╪ر ┘ê╪د┘┘à╪»┘è┘╪ر)
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

            // ╪ز╪د╪▒┘è╪« ╪د┘╪ش╪»┘ê┘╪ر (┘┘╪╖┘╪ذ╪د╪ز ╪د┘┘à╪ش╪»┘ê┘╪ر) ╪ث┘ê ╪╡┘ê╪▒╪ر ╪د┘┘à┘╪ز╪ش (┘┘╪╖┘╪ذ╪د╪ز ╪د┘╪╣╪د╪»┘è╪ر)
            if (order.scheduledDate != null)
              // ╪ز╪د╪▒┘è╪« ╪د┘╪ش╪»┘ê┘╪ر ┘┘╪╖┘╪ذ╪د╪ز ╪د┘┘à╪ش╪»┘ê┘╪ر
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
              // ╪╡┘ê╪▒╪ر ╪د┘┘à┘╪ز╪ش ┘┘╪╖┘╪ذ╪د╪ز ╪د┘╪╣╪د╪»┘è╪ر (╪ث┘ê ╪ث┘è┘é┘ê┘╪ر ╪د┘╪ز╪▒╪د╪╢┘è╪ر)
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

  // ╪ذ┘╪د╪ة ╪┤╪د╪▒╪ر ╪د┘╪ص╪د┘╪ر ╪ذ╪د╪│╪ز╪«╪»╪د┘à OrderStatusHelper ┘ê╪د┘┘╪╡ ╪د┘╪ث╪╡┘┘è
  Widget _buildStatusBadge(Order order) {
    // ╪د╪│╪ز╪«╪»╪د┘à ╪د┘┘╪╡ ╪د┘╪ث╪╡┘┘è ┘à┘ ┘é╪د╪╣╪»╪ر ╪د┘╪ذ┘è╪د┘╪د╪ز
    final statusText = OrderStatusHelper.getArabicStatus(order.rawStatus);
    final backgroundColor = OrderStatusHelper.getStatusColor(order.rawStatus);

    // ╪ز╪ص╪»┘è╪» ┘┘ê┘ ╪د┘┘╪╡ ╪ذ┘╪د╪ة┘ï ╪╣┘┘ë ╪د┘╪ص╪د┘╪ر
    Color textColor = Colors.white;

    // ┘┘╪ص╪د┘╪د╪ز ╪د┘┘╪┤╪╖╪ر: ┘╪╡ ╪ث╪│┘ê╪» ╪╣┘┘ë ╪«┘┘┘è╪ر ╪░┘ç╪ذ┘è╪ر
    if (_isActiveStatus(order.rawStatus)) {
      textColor = Colors.black; // ╪ث╪│┘ê╪» ┘┘┘╪╡
    }
    // ┘┘╪ص╪د┘╪د╪ز ╪د┘╪ث╪«╪▒┘ë: ┘╪╡ ╪ث╪ذ┘è╪╢
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

  // ╪ذ┘╪د╪ة ╪ز╪░┘è┘è┘ ╪د┘╪╖┘╪ذ
  Widget _buildOrderFooter(Order order) {
    final bool isScheduled = order.scheduledDate != null;

    return Container(
      height: isScheduled ? 38 : 35, // ╪ز╪╡╪║┘è╪▒ ╪د╪▒╪ز┘╪د╪╣ ╪د┘╪┤╪▒┘è╪╖ ╪د┘╪│┘┘┘è
      margin: const EdgeInsets.only(
        left: 8,
        right: 8,
        top: 0,
        bottom: 6,
      ), // ╪▒┘╪╣ ╪د┘╪┤╪▒┘è╪╖ ┘é┘┘è┘╪د┘ï
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
          // ╪د┘┘à╪ذ┘╪║ ╪د┘╪ح╪ش┘à╪د┘┘è
          Expanded(
            flex: 2,
            child: Text(
              '${order.total} ╪».╪╣',
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

          // ╪ث╪▓╪▒╪د╪▒ ╪د┘╪ز╪╣╪»┘è┘ ┘ê╪د┘╪ص╪░┘ ┘ê╪د┘┘à╪╣╪د┘╪ش╪ر
          Row(
            children: [
              // ╪▓╪▒ ╪د┘┘à╪╣╪د┘╪ش╪ر (┘┘╪╖┘╪ذ╪د╪ز ╪د┘╪ز┘è ╪ز╪ص╪ز╪د╪ش ┘à╪╣╪د┘╪ش╪ر)
              if (_needsProcessing(order) || _isSupportRequested(order))
                GestureDetector(
                  onTap: _isSupportRequested(order) ? null : () => _showProcessingDialog(order),
                  child: Container(
                    width: _isSupportRequested(order) ? 75 : 55,
                    height: 24,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: _isSupportRequested(order)
                          ? const Color(0xFF28a745) // ╪ث╪«╪╢╪▒ ┘┘┘à╪╣╪د┘╪ش
                          : const Color(0xFFff8c00), // ╪ذ╪▒╪ز┘é╪د┘┘è ┘┘┘à╪╣╪د┘╪ش╪ر
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
                          _isSupportRequested(order) ? '╪ز┘à ╪د┘┘à╪╣╪د┘╪ش╪ر' : '┘à╪╣╪د┘╪ش╪ر',
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

              // ╪ث╪▓╪▒╪د╪▒ ╪د┘╪ز╪╣╪»┘è┘ ┘ê╪د┘╪ص╪░┘ (┘┘╪╖┘╪ذ╪د╪ز ╪د┘┘à╪ش╪»┘ê┘╪ر ┘ê╪د┘╪╖┘╪ذ╪د╪ز ╪د┘┘╪┤╪╖╪ر ┘┘é╪╖)
              if (isScheduled || _isActiveStatus(order.rawStatus)) ...[
                // ╪▓╪▒ ╪د┘╪ز╪╣╪»┘è┘
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
                          '╪ز╪╣╪»┘è┘',
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
                // ╪▓╪▒ ╪د┘╪ص╪░┘
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
                          '╪ص╪░┘',
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

          // ╪ز╪د╪▒┘è╪« ╪د┘╪╖┘╪ذ
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

  // ╪ز┘╪│┘è┘é ╪د┘╪ز╪د╪▒┘è╪«
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  // ╪د┘╪ز╪ص┘é┘é ┘à┘ ╪ث┘ ╪د┘╪╖┘╪ذ ┘è╪ص╪ز╪د╪ش ┘à╪╣╪د┘╪ش╪ر
  bool _needsProcessing(Order order) {
    // ╪د┘╪ص╪د┘╪د╪ز ╪د┘╪ز┘è ╪ز╪ص╪ز╪د╪ش ┘à╪╣╪د┘╪ش╪ر (╪ذ┘╪د╪ة┘ï ╪╣┘┘ë ╪د┘┘╪╡)
    final statusesNeedProcessing = [
      '┘╪د ┘è╪▒╪»',
      '┘╪د ┘è╪▒╪» ╪ذ╪╣╪» ╪د┘╪د╪ز┘╪د┘é',
      '┘à╪║┘┘é',
      '┘à╪║┘┘é ╪ذ╪╣╪» ╪د┘╪د╪ز┘╪د┘é',
      '╪د┘╪▒┘é┘à ╪║┘è╪▒ ┘à╪╣╪▒┘',
      '╪د┘╪▒┘é┘à ╪║┘è╪▒ ╪»╪د╪«┘ ┘┘è ╪د┘╪«╪»┘à╪ر',
      '┘╪د ┘è┘à┘â┘ ╪د┘╪د╪ز╪╡╪د┘ ╪ذ╪د┘╪▒┘é┘à',
      '┘à╪ج╪ش┘',
      '┘à╪ج╪ش┘ ┘╪ص┘è┘ ╪د╪╣╪د╪»╪ر ╪د┘╪╖┘╪ذ ┘╪د╪ص┘é╪د',
      '┘à┘╪╡┘ê┘ ╪╣┘ ╪د┘╪«╪»┘à╪ر',
      '╪╖┘╪ذ ┘à┘â╪▒╪▒',
      '┘à╪│╪ز┘┘à ┘à╪│╪ذ┘é╪د',
      '╪د┘╪╣┘┘ê╪د┘ ╪║┘è╪▒ ╪»┘é┘è┘é',
      '┘┘à ┘è╪╖┘╪ذ',
      '╪ص╪╕╪▒ ╪د┘┘à┘╪»┘ê╪ذ',
    ];

    return statusesNeedProcessing.contains(order.rawStatus) &&
           !(order.supportRequested ?? false);
  }

  // ╪د┘╪ز╪ص┘é┘é ┘à┘ ╪ث┘ ╪د┘╪╖┘╪ذ ╪ز┘à ╪ح╪▒╪│╪د┘ ╪╖┘╪ذ ╪»╪╣┘à ┘┘ç
  bool _isSupportRequested(Order order) {
    return order.supportRequested ?? false;
  }

  // ╪╣╪▒╪╢ ┘╪د┘╪░╪ر ╪د┘┘à╪╣╪د┘╪ش╪ر
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
                    '╪ح╪▒╪│╪د┘ ┘┘╪»╪╣┘à',
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
                    // ┘à╪╣┘┘ê┘à╪د╪ز ╪د┘╪╖┘╪ذ
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
                            '≡اôï ┘à╪╣┘┘ê┘à╪د╪ز ╪د┘╪╖┘╪ذ:',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: const Color(0xFFffd700),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow('≡ا¤', '╪▒┘é┘à ╪د┘╪╖┘╪ذ', '#${order.id}'),
                          _buildInfoRow('≡اّج', '╪د╪│┘à ╪د┘╪▓╪ذ┘ê┘', order.customerName),
                          _buildInfoRow('≡اôئ', '╪د┘┘ç╪د╪ز┘ ╪د┘╪ث╪│╪د╪│┘è', order.primaryPhone),
                          if (order.secondaryPhone != null && order.secondaryPhone!.isNotEmpty)
                            _buildInfoRow('≡اô▒', '╪د┘┘ç╪د╪ز┘ ╪د┘╪ذ╪»┘è┘', order.secondaryPhone!),
                          _buildInfoRow('≡اؤي╕', '╪د┘┘à╪ص╪د┘╪╕╪ر', order.province),
                          _buildInfoRow('≡اب', '╪د┘┘à╪»┘è┘╪ر', order.city),
                          _buildInfoRow('ظأبي╕', '╪ص╪د┘╪ر ╪د┘╪╖┘╪ذ', order.rawStatus),
                          _buildInfoRow('≡اôà', '╪ز╪د╪▒┘è╪« ╪د┘╪╖┘╪ذ', _formatDate(order.createdAt)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ╪ص┘é┘ ╪د┘┘à┘╪د╪ص╪╕╪د╪ز
                    Text(
                      '┘à┘╪د╪ص╪╕╪د╪ز ╪ح╪╢╪د┘┘è╪ر:',
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
                        hintText: '╪د┘â╪ز╪ذ ╪ث┘è ┘à┘╪د╪ص╪╕╪د╪ز ╪ح╪╢╪د┘┘è╪ر ┘ç┘╪د...',
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
                    '╪ح┘╪║╪د╪ة',
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
                          '╪ح╪▒╪│╪د┘ ┘┘╪»╪╣┘à',
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

  // ╪ذ┘╪د╪ة ╪╡┘ ┘à╪╣┘┘ê┘à╪د╪ز
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

  // ╪ح╪▒╪│╪د┘ ╪╖┘╪ذ ╪د┘╪»╪╣┘à
  Future<void> _sendSupportRequest(Order order, String notes) async {
    debugPrint('≡ا¤ح === ╪ز┘à ╪د┘┘┘é╪▒ ╪╣┘┘ë ╪▓╪▒ ╪ح╪▒╪│╪د┘ ┘┘╪»╪╣┘à - ╪ح╪▒╪│╪د┘ ╪ز┘┘é╪د╪خ┘è ===');
    debugPrint('≡ا¤ح ┘à╪╣┘┘ê┘à╪د╪ز ╪د┘╪╖┘╪ذ: ${order.toJson()}');
    debugPrint('≡ا¤ح ╪د┘┘à┘╪د╪ص╪╕╪د╪ز: $notes');

    try {
      debugPrint('≡اôة Step 1: ╪ح╪▒╪│╪د┘ ╪╖┘╪ذ ╪د┘╪»╪╣┘à ┘┘╪«╪د╪»┘à...');

      // ╪ح╪▒╪│╪د┘ ╪╖┘╪ذ ╪د┘╪»╪╣┘à ┘┘╪«╪د╪»┘à (╪│┘è╪▒╪│┘ ╪ز┘┘é╪د╪خ┘è╪د┘ï ┘┘╪ز┘╪║╪▒╪د┘à)
      final response = await http.post(
        Uri.parse('https://clownfish-app-krnk9.ondigitalocean.app/api/support/send-support-request'),
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
          'waseetOrderId': order.waseetOrderId, // ظ£à ╪ح╪╢╪د┘╪ر ╪▒┘é┘à ╪د┘╪╖┘╪ذ ┘┘è ╪د┘┘ê╪│┘è╪╖
        }),
      );

      debugPrint('≡اôة ╪▒┘à╪▓ ╪د┘╪د╪│╪ز╪ش╪د╪ذ╪ر: ${response.statusCode}');
      debugPrint('≡اôة ┘à╪ص╪ز┘ê┘ë ╪د┘╪د╪│╪ز╪ش╪د╪ذ╪ر: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode != 200 || !responseData['success']) {
        throw Exception(responseData['message'] ?? '┘╪┤┘ ┘┘è ╪ح╪▒╪│╪د┘ ╪د┘╪╖┘╪ذ ┘┘╪»╪╣┘à');
      }

      debugPrint('ظ£à ╪ز┘à ╪ح╪▒╪│╪د┘ ╪╖┘╪ذ ╪د┘╪»╪╣┘à ╪ذ┘╪ش╪د╪ص');

      // ظ£à ╪ز╪ص╪»┘è╪س ╪ص╪د┘╪ر ╪د┘╪╖┘╪ذ ┘┘è ╪د┘╪«╪»┘à╪ر ┘ê┘é╪د╪╣╪»╪ر ╪د┘╪ذ┘è╪د┘╪د╪ز ┘┘ê╪▒╪د┘ï
      await _ordersService.updateOrderSupportStatus(order.id, true);

      // ظ£à ╪ح╪╣╪د╪»╪ر ╪ز╪ص┘à┘è┘ ╪د┘╪╖┘╪ذ╪د╪ز ┘╪╢┘à╪د┘ ╪د┘╪ز╪ص╪»┘è╪س ╪د┘┘┘ê╪▒┘è
      await _ordersService.loadOrders(forceRefresh: true);

      // ظ£à ╪ز╪ص╪»┘è╪س ╪د┘┘ê╪د╪ش┘ç╪ر ┘┘ê╪▒╪د┘ï
      if (mounted) {
        setState(() {
          // ╪د┘┘ê╪د╪ش┘ç╪ر ╪│╪ز╪ز╪ص╪»╪س ╪ز┘┘é╪د╪خ┘è╪د┘ï ┘╪ث┘ _ordersService.updateOrderSupportStatus ┘è╪│╪ز╪»╪╣┘è notifyListeners()
        });
      }

      if (!mounted) return;

      // ╪ح╪║┘╪د┘é ╪د┘┘╪د┘╪░╪ر
      Navigator.of(context).pop();

      // ╪ح╪╕┘ç╪د╪▒ ╪▒╪│╪د┘╪ر ┘╪ش╪د╪ص
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                '╪ز┘à ╪ح╪▒╪│╪د┘ ╪╖┘╪ذ ╪د┘╪»╪╣┘à ╪ذ┘╪ش╪د╪ص',
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
      debugPrint('ظإî === ╪«╪╖╪ث ┘┘è ╪╣┘à┘┘è╪ر ╪ح╪▒╪│╪د┘ ╪╖┘╪ذ ╪د┘╪»╪╣┘à ===');
      debugPrint('ظإî ┘┘ê╪╣ ╪د┘╪«╪╖╪ث: ${error.runtimeType}');
      debugPrint('ظإî ╪▒╪│╪د┘╪ر ╪د┘╪«╪╖╪ث: ${error.toString()}');
      debugPrint('ظإî Stack Trace: $stackTrace');

      if (!mounted) return;

      // ╪د╪│╪ز╪«╪»╪د┘à ErrorHandler ┘┘à╪╣╪د┘╪ش╪ر ╪ث┘╪╢┘ ┘┘╪ث╪«╪╖╪د╪ة
      ErrorHandler.showErrorSnackBar(
        context,
        error,
        customMessage: ErrorHandler.isNetworkError(error)
            ? '┘╪د ┘è┘ê╪ش╪» ╪د╪ز╪╡╪د┘ ╪ذ╪د┘╪ح┘╪ز╪▒┘╪ز. ┘è╪▒╪ش┘ë ╪د┘╪ز╪ص┘é┘é ┘à┘ ╪د┘╪د╪ز╪╡╪د┘ ┘ê╪د┘┘à╪ص╪د┘ê┘╪ر ┘à╪▒╪ر ╪ث╪«╪▒┘ë.'
            : '┘╪┤┘ ┘┘è ╪ح╪▒╪│╪د┘ ╪╖┘╪ذ ╪د┘╪»╪╣┘à. ┘è╪▒╪ش┘ë ╪د┘┘à╪ص╪د┘ê┘╪ر ┘à╪▒╪ر ╪ث╪«╪▒┘ë.',
        onRetry: () => _sendSupportRequest(order, notes),
        duration: const Duration(seconds: 6),
      );
    }
  }

  // ╪╣╪▒╪╢ ╪ز┘╪د╪╡┘è┘ ╪د┘╪╖┘╪ذ
  void _showOrderDetails(Order order) {
    context.go('/orders/details/${order.id}');
  }

  // ╪ز╪╣╪»┘è┘ ╪د┘╪╖┘╪ذ (┘┘╪╖┘╪ذ╪د╪ز ╪د┘┘╪┤╪╖╪ر ┘ê╪د┘┘à╪ش╪»┘ê┘╪ر)
  void _editOrder(Order order) {
    final bool isScheduled = order.scheduledDate != null;

    if (isScheduled) {
      // ┘┘╪╖┘╪ذ╪د╪ز ╪د┘┘à╪ش╪»┘ê┘╪ر - ╪د┘╪د┘╪ز┘é╪د┘ ┘╪╡┘╪ص╪ر ╪ز╪╣╪»┘è┘ ╪د┘╪╖┘╪ذ ╪د┘┘à╪ش╪»┘ê┘
      context.go('/scheduled-orders/edit/${order.id}');
      return;
    }

    // ┘┘╪╖┘╪ذ╪د╪ز ╪د┘╪╣╪د╪»┘è╪ر - ╪د┘╪ز╪ص┘é┘é ┘à┘ ╪ح┘à┘â╪د┘┘è╪ر ╪د┘╪ز╪╣╪»┘è┘
    if (!_isActiveStatus(order.rawStatus)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '┘╪د ┘è┘à┘â┘ ╪ز╪╣╪»┘è┘ ╪د┘╪╖┘╪ذ╪د╪ز ╪║┘è╪▒ ╪د┘┘╪┤╪╖╪ر',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: const Color(0xFFdc3545),
        ),
      );
      return;
    }

    // ╪د┘╪ز╪ص┘é┘é ┘à┘ ╪د┘┘ê┘é╪ز ╪د┘┘à╪ز╪ذ┘é┘è (24 ╪│╪د╪╣╪ر)
    final now = DateTime.now();
    final deadline = order.createdAt.add(const Duration(hours: 24));
    if (now.isAfter(deadline)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '╪د┘╪ز┘ç╪ز ┘╪ز╪▒╪ر ╪د┘╪ز╪╣╪»┘è┘ ╪د┘┘à╪│┘à┘ê╪ص╪ر (24 ╪│╪د╪╣╪ر)',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: const Color(0xFFdc3545),
        ),
      );
      return;
    }

    // ╪د┘╪د┘╪ز┘é╪د┘ ┘╪╡┘╪ص╪ر ╪ز╪╣╪»┘è┘ ╪د┘╪╖┘╪ذ
    context.go('/orders/edit/${order.id}');
  }

  // ╪ص╪░┘ ╪د┘╪╖┘╪ذ (┘┘╪╖┘╪ذ╪د╪ز ╪د┘┘╪┤╪╖╪ر ┘┘é╪╖)
  void _deleteOrder(Order order) {
    // ╪د┘╪ز╪ص┘é┘é ┘à┘ ╪ح┘à┘â╪د┘┘è╪ر ╪د┘╪ص╪░┘
    if (!_isActiveStatus(order.rawStatus)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '┘╪د ┘è┘à┘â┘ ╪ص╪░┘ ╪د┘╪╖┘╪ذ╪د╪ز ╪║┘è╪▒ ╪د┘┘╪┤╪╖╪ر',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: const Color(0xFFdc3545),
        ),
      );
      return;
    }

    // ╪ح╪╕┘ç╪د╪▒ ╪▒╪│╪د┘╪ر ╪ز╪ث┘â┘è╪»
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Text('╪ص╪░┘ ╪د┘╪╖┘╪ذ', style: GoogleFonts.cairo(color: Colors.red)),
        content: Text(
          '┘ç┘ ╪ث┘╪ز ┘à╪ز╪ث┘â╪» ┘à┘ ╪ص╪░┘ ╪╖┘╪ذ ${order.customerName}╪ا\n┘╪د ┘è┘à┘â┘ ╪د┘╪ز╪▒╪د╪ش╪╣ ╪╣┘ ┘ç╪░╪د ╪د┘╪ح╪ش╪▒╪د╪ة.',
          style: GoogleFonts.cairo(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '╪ح┘╪║╪د╪ة',
              style: GoogleFonts.cairo(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirmDeleteOrder(order);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('╪ص╪░┘', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ╪ز╪ث┘â┘è╪» ╪ص╪░┘ ╪د┘╪╖┘╪ذ
  Future<void> _confirmDeleteOrder(Order order) async {
    try {
      // ╪ح╪╕┘ç╪د╪▒ ┘à╪ج╪┤╪▒ ╪د┘╪ز╪ص┘à┘è┘
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFffd700)),
        ),
      );

      // ╪ص╪░┘ ╪د┘╪╖┘╪ذ ╪╣╪ذ╪▒ HTTP API
      bool success = await _ordersService.deleteOrder(order.id);

      if (!success) {
        throw Exception('┘╪┤┘ ┘┘è ╪ص╪░┘ ╪د┘╪╖┘╪ذ ┘à┘ ╪د┘╪«╪د╪»┘à');
      }

      // ╪ح╪«┘╪د╪ة ┘à╪ج╪┤╪▒ ╪د┘╪ز╪ص┘à┘è┘
      if (mounted) Navigator.pop(context);

      // ╪ح╪╕┘ç╪د╪▒ ╪▒╪│╪د┘╪ر ┘╪ش╪د╪ص
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('╪ز┘à ╪ص╪░┘ ╪د┘╪╖┘╪ذ ╪ذ┘╪ش╪د╪ص', style: GoogleFonts.cairo()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // ╪ح╪«┘╪د╪ة ┘à╪ج╪┤╪▒ ╪د┘╪ز╪ص┘à┘è┘
      if (mounted) Navigator.pop(context);

      // ╪ح╪╕┘ç╪د╪▒ ╪▒╪│╪د┘╪ر ╪«╪╖╪ث ┘à╪ص╪│┘╪ر
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          e,
          customMessage: ErrorHandler.isNetworkError(e)
              ? '┘╪د ┘è┘ê╪ش╪» ╪د╪ز╪╡╪د┘ ╪ذ╪د┘╪ح┘╪ز╪▒┘╪ز. ┘è╪▒╪ش┘ë ╪د┘╪ز╪ص┘é┘é ┘à┘ ╪د┘╪د╪ز╪╡╪د┘ ┘ê╪د┘┘à╪ص╪د┘ê┘╪ر ┘à╪▒╪ر ╪ث╪«╪▒┘ë.'
              : '┘╪┤┘ ┘┘è ╪ص╪░┘ ╪د┘╪╖┘╪ذ. ┘è╪▒╪ش┘ë ╪د┘┘à╪ص╪د┘ê┘╪ر ┘à╪▒╪ر ╪ث╪«╪▒┘ë.',
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  // ╪»╪د┘╪ر ┘╪ز╪ص╪»┘è╪» ╪ث┘┘ê╪د┘ ╪د┘╪ح╪╖╪د╪▒ ┘ê╪د┘╪╕┘ ╪ص╪│╪ذ ╪ص╪د┘╪ر ╪د┘╪╖┘╪ذ ╪د┘╪ص┘é┘è┘é┘è╪ر
  Map<String, dynamic> _getOrderCardColors(String status, bool isScheduled) {
    if (isScheduled) {
      // ╪د┘╪╖┘╪ذ╪د╪ز ╪د┘┘à╪ش╪»┘ê┘╪ر ╪ز╪ذ┘é┘ë ╪ذ┘┘╪│ ╪د┘╪ز╪╡┘à┘è┘à (╪ذ┘┘╪│╪ش┘è)
      return {
        'borderColor': const Color(0xFF8b5cf6),
        'shadowColor': const Color(0xFF8b5cf6).withValues(alpha: 0.3),
        'gradientColors': [
          const Color(0xFF2d1b69).withValues(alpha: 0.9),
          const Color(0xFF1e3a8a).withValues(alpha: 0.8),
        ],
      };
    }

    // ╪ث┘┘ê╪د┘ ╪د┘╪╖┘╪ذ╪د╪ز ╪د┘╪╣╪د╪»┘è╪ر ╪ص╪│╪ذ ╪د┘┘╪╡ ╪د┘╪ص┘é┘è┘é┘è ┘à┘ ┘é╪د╪╣╪»╪ر ╪د┘╪ذ┘è╪د┘╪د╪ز
    final statusText = status.trim();

    // ≡ااة ╪د┘╪ص╪د┘╪د╪ز ╪د┘┘╪┤╪╖╪ر (╪ث╪╡┘╪▒ ╪░┘ç╪ذ┘è) - ╪ث┘ê┘┘ê┘è╪ر ╪╣╪د┘┘è╪ر
    if (statusText == '┘╪┤╪╖' || statusText == 'active') {
      return {
        'borderColor': const Color(0xFFffc107), // ╪ث╪╡┘╪▒ ╪░┘ç╪ذ┘è ┘┘┘╪┤╪╖
        'shadowColor': const Color(0xFFffc107).withValues(alpha: 0.4),
        'gradientColors': [
          const Color(0xFF2e2a1a).withValues(alpha: 0.95),
          const Color(0xFF2e2616).withValues(alpha: 0.9),
          const Color(0xFF3f3a1e).withValues(alpha: 0.85),
        ],
      };
    }

    // ≡اات ╪د┘╪ص╪د┘╪د╪ز ╪د┘┘à┘â╪ز┘à┘╪ر (╪ث╪«╪╢╪▒)
    if (_isDeliveredStatus(statusText)) {
      return {
        'borderColor': const Color(0xFF28a745), // ╪ث╪«╪╢╪▒ ┘╪ز┘à ╪د┘╪ز╪│┘┘è┘à
        'shadowColor': const Color(0xFF28a745).withValues(alpha: 0.4),
        'gradientColors': [
          const Color(0xFF1a2e1a).withValues(alpha: 0.95),
          const Color(0xFF162e16).withValues(alpha: 0.9),
          const Color(0xFF1e3f1e).withValues(alpha: 0.85),
        ],
      };
    }

    // ≡ا¤╡ ╪د┘╪ص╪د┘╪د╪ز ┘é┘è╪» ╪د┘╪ز┘ê╪╡┘è┘ (╪ث╪▓╪▒┘é)
    if (_isInDeliveryStatus(statusText)) {
      return {
        'borderColor': const Color(0xFF007bff), // ╪ث╪▓╪▒┘é ┘┘é┘è╪» ╪د┘╪ز┘ê╪╡┘è┘
        'shadowColor': const Color(0xFF007bff).withValues(alpha: 0.4),
        'gradientColors': [
          const Color(0xFF1a2332).withValues(alpha: 0.95),
          const Color(0xFF162838).withValues(alpha: 0.9),
          const Color(0xFF1e3a5f).withValues(alpha: 0.85),
        ],
      };
    }

    // ≡ااب ╪د┘╪ص╪د┘╪د╪ز ╪د┘╪ز┘è ╪ز╪ص╪ز╪د╪ش ┘à╪╣╪د┘╪ش╪ر (╪ذ╪▒╪ز┘é╪د┘┘è)
    if (statusText == '╪ز┘à ╪ز╪║┘è┘è╪▒ ┘à╪ص╪د┘╪╕╪ر ╪د┘╪▓╪ذ┘ê┘' ||
        statusText == '╪ز╪║┘è┘è╪▒ ╪د┘┘à┘╪»┘ê╪ذ' ||
        statusText == '┘╪د ┘è╪▒╪»' ||
        statusText == '┘╪د ┘è╪▒╪» ╪ذ╪╣╪» ╪د┘╪د╪ز┘╪د┘é' ||
        statusText == '┘à╪║┘┘é' ||
        statusText == '┘à╪║┘┘é ╪ذ╪╣╪» ╪د┘╪د╪ز┘╪د┘é' ||
        statusText == '╪د┘╪▒┘é┘à ╪║┘è╪▒ ┘à╪╣╪▒┘' ||
        statusText == '╪د┘╪▒┘é┘à ╪║┘è╪▒ ╪»╪د╪«┘ ┘┘è ╪د┘╪«╪»┘à╪ر' ||
        statusText == '┘╪د ┘è┘à┘â┘ ╪د┘╪د╪ز╪╡╪د┘ ╪ذ╪د┘╪▒┘é┘à' ||
        statusText == '┘à╪ج╪ش┘' ||
        statusText == '┘à╪ج╪ش┘ ┘╪ص┘è┘ ╪د╪╣╪د╪»╪ر ╪د┘╪╖┘╪ذ ┘╪د╪ص┘é╪د' ||
        statusText == '┘à┘╪╡┘ê┘ ╪╣┘ ╪د┘╪«╪»┘à╪ر' ||
        statusText == '╪╖┘╪ذ ┘à┘â╪▒╪▒' ||
        statusText == '┘à╪│╪ز┘┘à ┘à╪│╪ذ┘é╪د' ||
        statusText == '╪د┘╪╣┘┘ê╪د┘ ╪║┘è╪▒ ╪»┘é┘è┘é' ||
        statusText == '┘┘à ┘è╪╖┘╪ذ' ||
        statusText == '╪ص╪╕╪▒ ╪د┘┘à┘╪»┘ê╪ذ') {
      return {
        'borderColor': const Color(0xFFff6b35), // ╪ذ╪▒╪ز┘é╪د┘┘è ┘┘┘à╪╣╪د┘╪ش╪ر
        'shadowColor': const Color(0xFFff6b35).withValues(alpha: 0.4),
        'gradientColors': [
          const Color(0xFF2e1f1a).withValues(alpha: 0.95),
          const Color(0xFF2e1e16).withValues(alpha: 0.9),
          const Color(0xFF3f2a1e).withValues(alpha: 0.85),
        ],
      };
    }

    // ≡ا¤┤ ╪د┘╪ص╪د┘╪د╪ز ╪د┘┘à┘╪║┘è╪ر ┘ê╪د┘┘à╪▒┘┘ê╪╢╪ر (╪ث╪ص┘à╪▒)
    if (_isCancelledStatus(statusText)) {
      return {
        'borderColor': const Color(0xFFdc3545), // ╪ث╪ص┘à╪▒ ┘┘┘à┘╪║┘è ┘ê╪د┘┘à╪▒┘┘ê╪╢
        'shadowColor': const Color(0xFFdc3545).withValues(alpha: 0.4),
        'gradientColors': [
          const Color(0xFF2e1a1a).withValues(alpha: 0.95),
          const Color(0xFF2e1616).withValues(alpha: 0.9),
          const Color(0xFF3f1e1e).withValues(alpha: 0.85),
        ],
      };
    }

    // ╪د┘╪ص╪د┘╪د╪ز ╪د┘┘é╪»┘è┘à╪ر ┘┘╪ز┘ê╪د┘┘é
    final statusLower = statusText.toLowerCase();
    if (statusLower.contains('╪ز┘à') || statusLower.contains('delivered')) {
      return {
        'borderColor': const Color(0xFF28a745), // ╪ث╪«╪╢╪▒
        'shadowColor': const Color(0xFF28a745).withValues(alpha: 0.4),
        'gradientColors': [
          const Color(0xFF1a2e1a).withValues(alpha: 0.95),
          const Color(0xFF162e16).withValues(alpha: 0.9),
          const Color(0xFF1e3f1e).withValues(alpha: 0.85),
        ],
      };
    } else if (statusLower.contains('┘à┘╪║┘è') || statusLower.contains('cancelled')) {
      return {
        'borderColor': const Color(0xFFdc3545), // ╪ث╪ص┘à╪▒
        'shadowColor': const Color(0xFFdc3545).withValues(alpha: 0.4),
        'gradientColors': [
          const Color(0xFF2e1a1a).withValues(alpha: 0.95),
          const Color(0xFF2e1616).withValues(alpha: 0.9),
          const Color(0xFF3f1e1e).withValues(alpha: 0.85),
        ],
      };
    }

    // ╪د┘╪ز╪▒╪د╪╢┘è (╪░┘ç╪ذ┘è ┘à╪س┘ ╪▓╪▒ ┘╪┤╪╖)
    return {
      'borderColor': const Color(0xFFffc107), // ┘┘╪│ ┘┘ê┘ ╪▓╪▒ ┘╪┤╪╖
      'shadowColor': const Color(0xFFffc107).withValues(alpha: 0.4),
      'gradientColors': [
        const Color(0xFF2e2a1a).withValues(alpha: 0.95),
        const Color(0xFF2e2616).withValues(alpha: 0.9),
        const Color(0xFF3f3a1e).withValues(alpha: 0.85),
      ],
    };
  }


}
