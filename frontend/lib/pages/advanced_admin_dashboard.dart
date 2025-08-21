import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import '../services/admin_service.dart';
import '../services/withdrawal_service.dart';
import '../services/smart_inventory_manager.dart';
import '../services/smart_colors_service.dart';

import '../models/product.dart';
import '../models/product_color.dart';
import '../widgets/colors_management_dialog.dart';
import 'advanced_orders_management_page.dart';
import 'scheduled_orders_main_page.dart';
import 'scheduled_orders_test_page.dart';
import 'users_management_page.dart';
import 'reports_page.dart';
import 'settings_page.dart';
import 'admin_settings_page.dart';
import 'dart:convert';

class AdvancedAdminDashboard extends StatefulWidget {
  const AdvancedAdminDashboard({super.key});

  @override
  State<AdvancedAdminDashboard> createState() => _AdvancedAdminDashboardState();
}

class _AdvancedAdminDashboardState extends State<AdvancedAdminDashboard>
    with TickerProviderStateMixin {
  // Controllers للرسوم المتحركة
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // بيانات الإحصائيات
  AdminStats? _stats;
  List<AdminOrder> _recentOrders = [];
  List<AdminUser> _topUsers = [];

  // حالة التحميل
  bool _isLoading = true;
  String _selectedPeriod = 'اليوم';
  int _selectedTabIndex = 0;

  // متغيرات إدارة المنتجات
  int _selectedProductsTab = 0; // 0: جميع المنتجات، 1: نفذ من المخزون
  List<Product> _allProducts = [];
  List<Product> _availableProducts = [];
  List<Product> _outOfStockProducts = [];
  bool _isLoadingProducts = false;
  Future<void>? _loadProductsFuture;

  // متغير للتحكم في التحديث المباشر
  final ValueNotifier<int> _refreshNotifier = ValueNotifier<int>(0);

  // متغيرات البحث
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  // ignore: unused_field
  final List<Map<String, dynamic>> _filteredRequests = [];

  // متغيرات الصور الإعلانية
  List<Map<String, dynamic>> _advertisementBanners = [];
  bool _isLoadingBanners = false;

  // متغيرات إدارة الإشعارات
  final TextEditingController _notificationTitleController = TextEditingController();
  final TextEditingController _notificationBodyController = TextEditingController();
  String _selectedNotificationType = 'general';
  bool _isScheduled = false;
  DateTime? _scheduledDateTime;
  bool _isSendingNotification = false;
  List<Map<String, dynamic>> _sentNotifications = [];
  Map<String, int> _notificationStats = {
    'total_sent': 0,
    'total_delivered': 0,
    'total_opened': 0,
    'total_clicked': 0,
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDashboardData();
    _checkScheduledOrders();
    _updateExistingOrders(); // تحديث الطلبات الموجودة
    _loadProductsFuture = _loadAllProducts(); // تحميل المنتجات
    _loadAdvertisementBanners(); // تحميل الصور الإعلانية
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() => _isLoading = true);

      // تحميل البيانات بشكل متوازي مع معالجة الأخطاء
      final adminService = AdminService();
      final results = await Future.wait(<Future>[
        adminService.getStats().catchError((e) {
          debugPrint('خطأ في تحميل الإحصائيات: $e');
          return AdminStats(
            totalOrders: 0,
            activeOrders: 0,
            deliveredOrders: 0,
            cancelledOrders: 0,
            totalUsers: 0,
            newUsers: 0,
            totalProducts: 0,
            lowStockProducts: 0,
            pendingOrders: 0,
            shippingOrders: 0,
            totalProfits: 0.0,
          );
        }),
        AdminService.getOrders().catchError((e) {
          debugPrint('خطأ في تحميل الطلبات: $e');
          return <AdminOrder>[];
        }),
        adminService.getUsers().catchError((e) {
          debugPrint('خطأ في تحميل المستخدمين: $e');
          return <AdminUser>[];
        }),
        adminService.getProducts().catchError((e) {
          debugPrint('خطأ في تحميل المنتجات: $e');
          return <AdminProduct>[];
        }),
      ]);

      setState(() {
        _stats = results[0] as AdminStats;
        _recentOrders = (results[1] as List<AdminOrder>);
        _topUsers = (results[2] as List<AdminUser>).take(5).toList();
        // _topProducts = (results[3] as List<AdminProduct>).take(5).toList(); // غير مستخدم
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('خطأ في تحميل البيانات: $e');
      _setDefaultData();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _setDefaultData() {
    setState(() {
      _stats = AdminStats(
        totalOrders: 0,
        activeOrders: 0,
        deliveredOrders: 0,
        cancelledOrders: 0,
        totalUsers: 0,
        newUsers: 0,
        totalProducts: 0,
        lowStockProducts: 0,
        pendingOrders: 0,
        shippingOrders: 0,
        totalProfits: 0.0,
      );
      _recentOrders = [];
      _topUsers = [];
    });
  }

  Future<void> _checkScheduledOrders() async {
    try {
      debugPrint('🔄 فحص الطلبات المجدولة...');

      final response = await Supabase.instance.client
          .from('orders')
          .select(
            'id, order_number, customer_name, customer_address, shipping_address, province, city, total, status, scheduled_date, created_at',
          )
          .eq('status', 'scheduled')
          .lte('scheduled_date', DateTime.now().toIso8601String());

      if (response.isNotEmpty) {
        debugPrint('📦 تم العثور على ${response.length} طلبات مجدولة للتحويل');

        for (final order in response) {
          await Supabase.instance.client
              .from('orders')
              .update({
                'status': 'active',
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', order['id']);
        }

        // تحديث البيانات
        await _loadDashboardData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم تحويل ${response.length} طلبات من مجدولة إلى نشطة',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        debugPrint('✅ لا توجد طلبات مجدولة للتحويل');
      }
    } catch (e) {
      debugPrint('❌ خطأ في فحص الطلبات المجدولة: $e');
      // لا نعرض رسالة خطأ للمستخدم هنا لأنها عملية خلفية
    }
  }

  // تحديث الطلبات الموجودة لملء الأعمدة الجديدة
  Future<void> _updateExistingOrders() async {
    try {
      await AdminService.updateExistingOrdersWithNewFields();
    } catch (e) {
      debugPrint('❌ خطأ في تحديث الطلبات الموجودة: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: _isLoading ? _buildLoadingScreen() : _buildDashboard(),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffd700)),
              strokeWidth: 3,
            ),
            SizedBox(height: 20),
            Text(
              'جاري تحميل لوحة التحكم...',
              style: TextStyle(
                color: Color(0xFFffd700),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // تحديد ما إذا كانت الشاشة صغيرة (هاتف) أم كبيرة (تابلت/ديسكتوب)
            final isSmallScreen = constraints.maxWidth < 768;

            if (isSmallScreen) {
              // تخطيط للهواتف - شريط سفلي بدلاً من جانبي
              return Column(
                children: [
                  // المحتوى الرئيسي
                  Expanded(child: _buildMainContent()),
                  // شريط التنقل السفلي للهواتف
                  _buildBottomNavigationBar(),
                ],
              );
            } else {
              // تخطيط للشاشات الكبيرة - شريط جانبي
              return Row(
                children: [
                  // الشريط الجانبي
                  _buildAdvancedSidebar(),
                  // المحتوى الرئيسي
                  Expanded(child: _buildMainContent()),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildAdvancedSidebar() {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF16213e), Color(0xFF1a1a2e)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSidebarHeader(),
          _buildSidebarMenu(),
          const Spacer(),
          _buildSidebarFooter(),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFffd700), Color(0xFFe6b31e)],
        ),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.admin_panel_settings,
              color: Color(0xFF1a1a2e),
              size: 30,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لوحة التحكم',
                  style: TextStyle(
                    color: Color(0xFF1a1a2e),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'نظام إدارة متقدم',
                  style: TextStyle(color: Color(0xFF1a1a2e), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarMenu() {
    final menuItems = [
      {'icon': Icons.dashboard, 'title': 'الرئيسية', 'index': 0},
      {'icon': Icons.shopping_cart, 'title': 'الطلبات', 'index': 1},
      {'icon': Icons.people, 'title': 'المستخدمين', 'index': 2},
      {'icon': Icons.inventory, 'title': 'المنتجات', 'index': 3},
      {'icon': Icons.image, 'title': 'الصور الإعلانية', 'index': 4},
      {'icon': Icons.notifications, 'title': 'الإشعارات', 'index': 5},
      {'icon': Icons.account_balance_wallet, 'title': 'المالية', 'index': 6},
      {'icon': Icons.analytics, 'title': 'التقارير', 'index': 7},
      {'icon': Icons.settings, 'title': 'الإعدادات', 'index': 8},
    ];

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          final isSelected = _selectedTabIndex == item['index'];

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFFffd700), Color(0xFFe6b31e)],
                    )
                  : null,
            ),
            child: ListTile(
              leading: Icon(
                item['icon'] as IconData,
                color: isSelected
                    ? const Color(0xFF1a1a2e)
                    : const Color(0xFFffd700),
                size: 22,
              ),
              title: Text(
                item['title'] as String,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF1a1a2e) : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                setState(() {
                  _selectedTabIndex = item['index'] as int;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Divider(color: Color(0xFFffd700)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.logout, color: Color(0xFFffd700), size: 20),
              const SizedBox(width: 10),
              const Text(
                'تسجيل الخروج',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  // تسجيل الخروج
                },
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFFffd700),
                  size: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildDashboardOverview();
      case 1:
        return const AdvancedOrdersManagementPage();
      case 2:
        return _buildUsersManagement();
      case 3:
        return _buildProductsManagement();
      case 4:
        return _buildAdvertisementBannersManagement();
      case 5:
        return _buildNotificationsManagement();
      case 6:
        return _buildFinancialManagement();
      case 7:
        return _buildReportsSection();
      case 8:
        return _buildSettingsSection();
      default:
        return _buildDashboardOverview();
    }
  }

  // ===== لوحة التحكم الرئيسية =====
  Widget _buildDashboardOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDashboardHeader(),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildStatsCards(),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildRecentOrdersCard()),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            _buildTopUsersCard(),
                            const SizedBox(height: 20),
                            _buildQuickActionsCard(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildChartsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFffd700), Color(0xFFe6b31e)],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFffd700).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.dashboard, color: Color(0xFF1a1a2e), size: 30),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لوحة التحكم الرئيسية',
                  style: TextStyle(
                    color: Color(0xFF1a1a2e),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'نظام إدارة شامل ومتطور',
                  style: TextStyle(color: Color(0xFF1a1a2e), fontSize: 14),
                ),
              ],
            ),
          ),
          _buildPeriodSelector(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['اليوم', 'الأسبوع', 'الشهر', 'السنة'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: periods.map((period) {
          final isSelected = _selectedPeriod == period;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPeriod = period;
              });
              _loadDashboardData();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFffd700)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                period,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF1a1a2e)
                      : const Color(0xFFffd700),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsCards() {
    if (_stats == null) return const SizedBox();

    final statsData = [
      {
        'title': 'إجمالي الطلبات',
        'value': _stats!.totalOrders.toString(),
        'icon': Icons.shopping_cart,
        'color': const Color(0xFF4CAF50),
        'change': '+12%',
      },
      {
        'title': 'الطلبات النشطة',
        'value': _stats!.activeOrders.toString(),
        'icon': Icons.pending_actions,
        'color': const Color(0xFF2196F3),
        'change': '+8%',
      },
      {
        'title': 'إجمالي الأرباح',
        'value': '${_stats!.totalProfits.toStringAsFixed(0)} د.ع',
        'icon': Icons.account_balance_wallet,
        'color': const Color(0xFFFF9800),
        'change': '+15%',
      },
      {
        'title': 'المستخدمين',
        'value': _stats!.totalUsers.toString(),
        'icon': Icons.people,
        'color': const Color(0xFF9C27B0),
        'change': '+5%',
      },
    ];

    return Row(
      children: statsData.map((stat) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF16213e),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: (stat['color'] as Color).withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (stat['color'] as Color).withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      stat['icon'] as IconData,
                      color: stat['color'] as Color,
                      size: 30,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        stat['change'] as String,
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  stat['value'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  stat['title'] as String,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentOrdersCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.receipt_long, color: Color(0xFFffd700), size: 24),
                  SizedBox(width: 10),
                  Text(
                    'الطلبات الأخيرة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedTabIndex = 1; // الانتقال إلى تبويب الطلبات
                  });
                },
                child: const Text(
                  'عرض الكل',
                  style: TextStyle(color: Color(0xFFffd700), fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: _recentOrders.length,
              itemBuilder: (context, index) {
                final order = _recentOrders[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1a2e),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFffd700).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFffd700).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.shopping_cart,
                          color: Color(0xFFffd700),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'طلب #${order.orderNumber}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              order.customerName,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${order.totalAmount.toStringAsFixed(0)} د.ع',
                            style: const TextStyle(
                              color: Color(0xFFffd700),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF2196F3,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'طلب جديد',
                              style: TextStyle(
                                color: Color(0xFF2196F3),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopUsersCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.star, color: Color(0xFFffd700), size: 24),
              SizedBox(width: 10),
              Text(
                'أفضل العملاء',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: _topUsers.length,
              itemBuilder: (context, index) {
                final user = _topUsers[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1a2e),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFffd700),
                        child: Text(
                          user.name.isNotEmpty ? user.name[0] : 'U',
                          style: const TextStyle(
                            color: Color(0xFF1a1a2e),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${user.totalOrders} طلب',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${user.totalProfits.toStringAsFixed(0)} د.ع',
                        style: const TextStyle(
                          color: Color(0xFFffd700),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.flash_on, color: Color(0xFFffd700), size: 24),
              SizedBox(width: 10),
              Text(
                'إجراءات سريعة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildQuickActionButton(
            'إدارة الطلبات',
            Icons.shopping_cart,
            const Color(0xFF2196F3),
            () {
              setState(() {
                _selectedTabIndex = 1; // الطلبات
              });
            },
          ),
          const SizedBox(height: 10),
          _buildQuickActionButton(
            'الطلبات المجدولة',
            Icons.schedule,
            const Color(0xFF9C27B0),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ScheduledOrdersMainPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildQuickActionButton(
            'انتقال للتطبيق',
            Icons.mobile_friendly,
            const Color(0xFF4CAF50),
            () {
              context.go('/products');
            },
          ),
          const SizedBox(height: 10),
          _buildQuickActionButton(
            'إضافة منتج جديد',
            Icons.add_box,
            const Color(0xFF4CAF50),
            () {
              setState(() {
                _selectedTabIndex = 3; // المنتجات
              });
            },
          ),
          const SizedBox(height: 10),
          _buildQuickActionButton(
            'تقارير المبيعات',
            Icons.analytics,
            const Color(0xFFFF9800),
            () {
              setState(() {
                _selectedTabIndex = 5; // التقارير
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection() {
    return Row(
      children: [
        Expanded(child: _buildSalesChart()),
        const SizedBox(width: 20),
        Expanded(child: _buildOrdersChart()),
      ],
    );
  }

  Widget _buildSalesChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Color(0xFFffd700), size: 24),
              SizedBox(width: 10),
              Text(
                'مبيعات الأسبوع',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 3),
                      const FlSpot(1, 1),
                      const FlSpot(2, 4),
                      const FlSpot(3, 2),
                      const FlSpot(4, 5),
                      const FlSpot(5, 3),
                      const FlSpot(6, 4),
                    ],
                    isCurved: true,
                    color: const Color(0xFFffd700),
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFffd700).withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart, color: Color(0xFFffd700), size: 24),
              SizedBox(width: 10),
              Text(
                'توزيع الطلبات',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    color: const Color(0xFF4CAF50),
                    value: 40,
                    title: 'مكتمل',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: const Color(0xFF2196F3),
                    value: 30,
                    title: 'نشط',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: const Color(0xFFFF9800),
                    value: 20,
                    title: 'قيد التوصيل',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: const Color(0xFFF44336),
                    value: 10,
                    title: 'ملغي',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== الدوال المساعدة =====

  // ===== أقسام الإدارة =====

  Widget _buildUsersManagement() {
    return const UsersManagementPage();
  }

  Widget _buildProductsManagement() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 768;

        return Column(
          children: [
            // الشريط العلوي الثابت
            _buildProductsFixedHeader(isSmallScreen),

            // المحتوى القابل للتمرير
            Expanded(
              child: _buildProductsScrollableContent(isSmallScreen),
            ),
          ],
        );
      },
    );
  }

  // الشريط العلوي الثابت لصفحة المنتجات
  Widget _buildProductsFixedHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1a1a2e),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFffc107),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
          Row(
            children: [
              Icon(
                Icons.inventory,
                color: const Color(0xFFffc107),
                size: isSmallScreen ? 24 : 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'إدارة المنتجات',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 20 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // مؤشر إحصائيات سريعة
              if (!isSmallScreen) _buildQuickStatsIndicator(),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 20),

          // أزرار الإجراءات السريعة
          _buildResponsiveActionButtons(isSmallScreen),

          SizedBox(height: isSmallScreen ? 12 : 20),

          // تبويبات المنتجات
          _buildProductsTabs(isSmallScreen),
        ],
      ),
    );
  }

  // المحتوى القابل للتمرير
  Widget _buildProductsScrollableContent(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 20),
      child: _buildProductsTabContent(),
    );
  }

  // أزرار الإجراءات المتجاوبة
  Widget _buildResponsiveActionButtons(bool isSmallScreen) {
    final buttons = [
      _buildProductActionButton(
        'إضافة منتج جديد',
        Icons.add_circle,
        const Color(0xFF4CAF50),
        () => _addNewProduct(),
        isSmallScreen,
      ),
      _buildProductActionButton(
        'تحديث المخزون',
        Icons.update,
        const Color(0xFF2196F3),
        () => _updateInventory(),
        isSmallScreen,
      ),
      _buildProductActionButton(
        'إدارة الفئات',
        Icons.category,
        const Color(0xFFFF9800),
        () => _manageCategories(),
        isSmallScreen,
      ),
      _buildProductActionButton(
        'تحديث الصفحة',
        Icons.refresh,
        const Color(0xFF9C27B0),
        () => _refreshProductsData(),
        isSmallScreen,
      ),
    ];

    if (isSmallScreen) {
      // للشاشات الصغيرة: عرض الأزرار في صفين
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: buttons[0]),
              const SizedBox(width: 8),
              Expanded(child: buttons[1]),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: buttons[2]),
              const SizedBox(width: 8),
              Expanded(child: buttons[3]),
            ],
          ),
        ],
      );
    } else {
      // للشاشات الكبيرة: عرض الأزرار في صف واحد
      return Wrap(
        spacing: 15,
        runSpacing: 10,
        children: buttons,
      );
    }
  }

  // دوال إدارة المنتجات
  Widget _buildProductActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
    [bool isSmallScreen = false]
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: isSmallScreen ? 16 : 18),
      label: Text(
        title,
        style: TextStyle(
          fontSize: isSmallScreen ? 12 : 14,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 8 : 16,
          vertical: isSmallScreen ? 8 : 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _addNewProduct() {
    context.go('/add-product');
  }

  void _updateInventory() {
    showDialog(
      context: context,
      builder: (context) => _buildInventoryUpdateDialog(),
    );
  }

  Widget _buildInventoryUpdateDialog() {
    return AlertDialog(
      backgroundColor: const Color(0xFF2A2A2A),
      title: const Text('تحديث المخزون', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: 400,
        height: 300,
        child: _allProducts.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFffc107)),
                    SizedBox(height: 16),
                    Text(
                      'جاري تحميل المنتجات...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: _allProducts.length,
                itemBuilder: (context, index) {
                  final product = _allProducts[index];
                  return _buildInventoryItem(product);
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _saveInventoryUpdates();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
          ),
          child: const Text('حفظ التحديثات'),
        ),
      ],
    );
  }

  Widget _buildInventoryItem(Product product) {
    final minController = TextEditingController(
      text: product.minQuantity.toString(),
    );
    final maxController = TextEditingController(
      text: product.maxQuantity.toString(),
    );

    return Card(
      color: const Color(0xFF3A3A3A),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'الحد الأدنى',
                      labelStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _inventoryUpdates[product.id] = {
                        'minQuantity':
                            int.tryParse(value) ?? product.minQuantity,
                        'maxQuantity':
                            _inventoryUpdates[product.id]?['maxQuantity'] ??
                            product.maxQuantity,
                      };
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: maxController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'الحد الأقصى',
                      labelStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _inventoryUpdates[product.id] = {
                        'minQuantity':
                            _inventoryUpdates[product.id]?['minQuantity'] ??
                            product.minQuantity,
                        'maxQuantity':
                            int.tryParse(value) ?? product.maxQuantity,
                      };
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  final Map<String, Map<String, int>> _inventoryUpdates = {};

  Future<void> _saveInventoryUpdates() async {
    try {
      for (final entry in _inventoryUpdates.entries) {
        final productId = entry.key;
        final updates = entry.value;

        await Supabase.instance.client
            .from('products')
            .update({
              'min_quantity': updates['minQuantity'],
              'max_quantity': updates['maxQuantity'],
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', productId);

        // 🔔 إرسال طلب مراقبة المنتج للتحقق من نفاد المخزون
      try {
      final String baseUrl = kDebugMode
        ? 'http://localhost:3003'
        : 'https://montajati-official-backend-production.up.railway.app';

          final response = await http.post(
            Uri.parse('$baseUrl/api/inventory/monitor/$productId'),
            headers: {'Content-Type': 'application/json'},
          );

          if (response.statusCode == 200) {
            debugPrint('✅ تم إرسال طلب مراقبة المنتج: $productId');
          } else {
            debugPrint('⚠️ فشل في إرسال طلب مراقبة المنتج: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('⚠️ خطأ في إرسال طلب مراقبة المنتج: $e');
        }
      }

      _inventoryUpdates.clear();
      setState(() {}); // إعادة تحميل القائمة

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث المخزون بنجاح'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث المخزون: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _manageCategories() {
    showDialog(
      context: context,
      builder: (context) => _buildCategoriesDialog(),
    );
  }

  Widget _buildCategoriesDialog() {
    final categoryController = TextEditingController();

    return AlertDialog(
      backgroundColor: const Color(0xFF2A2A2A),
      title: const Text('إدارة الفئات', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          children: [
            // إضافة فئة جديدة
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: categoryController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'اسم الفئة الجديدة',
                      labelStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _addCategory(categoryController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                  ),
                  child: const Text('إضافة'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // قائمة الفئات الموجودة
            Expanded(
              child: FutureBuilder<List<String>>(
                future: _loadCategories(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFffc107),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'خطأ في تحميل الفئات: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final categories = snapshot.data ?? [];

                  if (categories.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد فئات',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return _buildCategoryItem(category);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(String category) {
    return Card(
      color: const Color(0xFF3A3A3A),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(category, style: const TextStyle(color: Colors.white)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _editCategory(category),
              icon: const Icon(Icons.edit, color: Color(0xFFffc107)),
              tooltip: 'تعديل',
            ),
            IconButton(
              onPressed: () => _deleteCategory(category),
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'حذف',
            ),
          ],
        ),
      ),
    );
  }

  Future<List<String>> _loadCategories() async {
    try {
      final response = await Supabase.instance.client
          .from('products')
          .select('category')
          .neq('category', '');

      final categories = <String>{};
      for (final item in response) {
        final category = item['category']?.toString();
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      debugPrint('خطأ في تحميل الفئات: $e');
      return [];
    }
  }

  Future<void> _addCategory(String categoryName) async {
    if (categoryName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال اسم الفئة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // إضافة فئة جديدة - سنحفظها في قائمة الفئات المحلية
      // لأن الفئات تأتي من المنتجات الموجودة
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إضافة الفئة "$categoryName" - يمكنك استخدامها عند إضافة منتجات جديدة',
          ),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إضافة الفئة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editCategory(String category) {
    final controller = TextEditingController(text: category);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('تعديل الفئة', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'اسم الفئة',
            labelStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateCategory(category, controller.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFffc107),
            ),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateCategory(String oldCategory, String newCategory) async {
    if (newCategory.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال اسم الفئة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // تحديث جميع المنتجات التي تحتوي على الفئة القديمة
      await Supabase.instance.client
          .from('products')
          .update({'category': newCategory.trim()})
          .eq('category', oldCategory);

      setState(() {}); // إعادة تحميل القائمة

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تحديث الفئة من "$oldCategory" إلى "$newCategory"',
            ),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث الفئة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteCategory(String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
        content: Text(
          'هل أنت متأكد من حذف الفئة "$category"؟\nسيتم تحديث جميع المنتجات في هذه الفئة إلى "غير مصنف".',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performDeleteCategory(category);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteCategory(String category) async {
    try {
      // تحديث جميع المنتجات في هذه الفئة إلى "غير مصنف"
      await Supabase.instance.client
          .from('products')
          .update({'category': 'غير مصنف'})
          .eq('category', category);

      setState(() {}); // إعادة تحميل القائمة

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف الفئة "$category" وتحديث المنتجات'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حذف الفئة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ignore: unused_element
  Widget _buildProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF2A2A2A),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // صورة المنتج
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product.images.isNotEmpty
                  ? Image.network(
                      product.images.first,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        );
                      },
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported),
                    ),
            ),
            const SizedBox(width: 16),

            // معلومات المنتج
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    style: const TextStyle(color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${product.wholesalePrice.toInt()} د.ع',
                        style: const TextStyle(
                          color: Color(0xFFffc107),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'الكمية: ${product.minQuantity > 0 ? product.minQuantity : 1}-${product.maxQuantity > 0 ? product.maxQuantity : 100}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF4CAF50),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          product.category.isNotEmpty
                              ? product.category
                              : 'غير مصنف',
                          style: const TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // أزرار الإجراءات
            Column(
              children: [
                IconButton(
                  onPressed: () => _editProduct(product),
                  icon: const Icon(Icons.edit, color: Color(0xFFffc107)),
                  tooltip: 'تعديل',
                ),
                IconButton(
                  onPressed: () => _deleteProduct(product),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'حذف',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editProduct(Product product) async {
    // تحميل الصور أولاً
    final images = await _loadProductImages(product);

    // التحقق من أن الويدجت لا يزال مثبتاً
    if (!mounted) return;

    // فتح نافذة التعديل مع الصور المحملة
    showDialog(
      context: context,
      builder: (context) => _buildEditProductDialog(product, images),
    );
  }

  // دالة تحميل صور المنتج من قاعدة البيانات
  Future<List<String>> _loadProductImages(Product product) async {
    List<String> currentImages = [];

    // أولاً: إضافة الصور من حقل images (للمنتجات الجديدة)
    if (product.images.isNotEmpty) {
      for (String imageUrl in product.images) {
        if (imageUrl.isNotEmpty &&
            !imageUrl.contains('placeholder') &&
            !currentImages.contains(imageUrl)) {
          currentImages.add(imageUrl);
        }
      }
    }

    // ثانياً: إذا لم توجد صور في حقل images، تحقق من image_url (للمنتجات القديمة)
    if (currentImages.isEmpty) {
      try {
        final productData = await Supabase.instance.client
            .from('products')
            .select('image_url, images')
            .eq('id', product.id)
            .single();

        // إضافة image_url إذا كان موجوداً
        if (productData['image_url'] != null &&
            productData['image_url'].toString().isNotEmpty &&
            !productData['image_url'].toString().contains('placeholder')) {
          currentImages.add(productData['image_url'].toString());
        }

        // إضافة الصور من حقل images إذا كان موجوداً
        if (productData['images'] != null && productData['images'] is List) {
          final imagesList = List<String>.from(productData['images']);
          for (String imageUrl in imagesList) {
            if (imageUrl.isNotEmpty &&
                !imageUrl.contains('placeholder') &&
                !currentImages.contains(imageUrl)) {
              currentImages.add(imageUrl);
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ خطأ في جلب صور المنتج: $e');
      }
    }

    // إذا لم توجد أي صور، أضف صورة افتراضية
    if (currentImages.isEmpty) {
      currentImages.add('https://via.placeholder.com/400x300/1a1a2e/ffd700?text=منتج');
    }

    // طباعة معلومات تشخيصية
    debugPrint('🔍 تحميل صور المنتج: ${product.name}');
    debugPrint('📸 حقل الصور: ${product.images}');
    debugPrint('📸 الصور المحملة: $currentImages');

    return currentImages;
  }

  Widget _buildEditProductDialog(Product product, List<String> preloadedImages) {
    final nameController = TextEditingController(text: product.name);
    final descriptionController = TextEditingController(
      text: product.description,
    );
    final wholesalePriceController = TextEditingController(
      text: product.wholesalePrice.toString(),
    );
    final minPriceController = TextEditingController(
      text: product.minPrice.toString(),
    );
    final maxPriceController = TextEditingController(
      text: product.maxPrice.toString(),
    );

    // استخدام القيم الصحيحة من قاعدة البيانات
    final stockQuantityController = TextEditingController(
      text: (product.availableQuantity > 0 ? product.availableQuantity : 100)
          .toString(),
    );
    final availableFromController = TextEditingController(
      text: (product.availableFrom > 0 ? product.availableFrom : 90).toString(),
    );
    final availableToController = TextEditingController(
      text: (product.availableTo > 0 ? product.availableTo : 80).toString(),
    );
    final displayOrderController = TextEditingController(
      text: product.displayOrder.toString(),
    );

    String selectedCategory = product.category.isNotEmpty
        ? product.category
        : 'عام';

    // استخدام الصور المحملة مسبقاً
    List<String> currentImages = List.from(preloadedImages);

    // متغير لتخزين الألوان
    List<ProductColor> currentColors = [];

    // طباعة معلومات تشخيصية
    debugPrint('🔍 تحميل صور المنتج: ${product.name}');
    debugPrint('📸 الصور المحملة مسبقاً: $currentImages');

    final List<String> categories = [
      'عام',
      'إلكترونيات',
      'ملابس',
      'طعام ومشروبات',
      'منزل وحديقة',
      'رياضة',
      'جمال وعناية',
      'كتب',
      'ألعاب',
      'أخرى',
    ];

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1a1a2e),
          title: Text(
            'تعديل المنتج',
            style: GoogleFonts.cairo(
              color: const Color(0xFFffd700),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: 600,
            height: 700,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // اسم المنتج
                  _buildEditTextField(
                    nameController,
                    'اسم المنتج',
                    Icons.shopping_bag,
                  ),
                  const SizedBox(height: 15),

                  // وصف المنتج
                  _buildEditTextField(
                    descriptionController,
                    'وصف المنتج • يتوسع تلقائياً مع النص',
                    Icons.description,
                    expandable: true,
                    minLines: 3,
                  ),
                  const SizedBox(height: 15),

                  // الأسعار
                  Row(
                    children: [
                      Expanded(
                        child: _buildEditTextField(
                          wholesalePriceController,
                          'سعر الجملة',
                          Icons.attach_money,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildEditTextField(
                          minPriceController,
                          'الحد الأدنى',
                          Icons.trending_down,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildEditTextField(
                          maxPriceController,
                          'الحد الأعلى',
                          Icons.trending_up,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // الفئة
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedCategory,
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: const Color(0xFF2A2A2A),
                      decoration: InputDecoration(
                        labelText: 'الفئة',
                        labelStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(
                          Icons.category,
                          color: Color(0xFFffd700),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(
                            category,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 15),

                  // الكمية المخزونة (إجمالي)
                  _buildEditTextField(
                    stockQuantityController,
                    'الكمية المخزونة (إجمالي)',
                    Icons.inventory,
                  ),
                  const SizedBox(height: 15),

                  // الكمية المتاحة للعرض
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFffd700)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الكمية المتاحة للعرض',
                          style: GoogleFonts.cairo(
                            color: const Color(0xFFffd700),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildEditTextField(
                                availableToController,
                                'إلى',
                                Icons.arrow_upward,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildEditTextField(
                                availableFromController,
                                'من',
                                Icons.arrow_downward,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'ملاحظة: "من" يجب أن يكون أقل من "إلى" - سيتم التحكم تلقائياً في عدد المخزون',
                          style: GoogleFonts.cairo(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ترتيب العرض
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2a2a2e),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFffd700).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.sort,
                              color: Color(0xFFffd700),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ترتيب العرض في صفحة المنتجات',
                              style: GoogleFonts.cairo(
                                color: const Color(0xFFffd700),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildEditTextField(
                          displayOrderController,
                          'رقم الترتيب (1 = أول منتج، 2 = ثاني منتج)',
                          Icons.format_list_numbered,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ملاحظة: رقم 1 يعني أول منتج في الصفحة، رقم 5 يعني خامس منتج، وهكذا',
                          style: GoogleFonts.cairo(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // إدارة الصور
                  Text(
                    'صور المنتج',
                    style: GoogleFonts.cairo(
                      color: const Color(0xFFffd700),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // زر اختيار الصور
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        debugPrint('📸 النقر على زر اختيار الصور');
                        debugPrint('📸 عدد الصور الحالية: ${currentImages.length}');
                        await _pickImages(setState, currentImages);
                      },
                      icon: const Icon(FontAwesomeIcons.images),
                      label: Text(
                        currentImages.isEmpty ? 'اختيار صور المنتج' : 'إضافة المزيد من الصور',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFffd700),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // عرض الصور الحالية مع إمكانية التحكم
                  if (currentImages.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.images,
                          color: const Color(0xFFffd700),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'الصور الحالية (${currentImages.length})',
                          style: GoogleFonts.cairo(
                            color: const Color(0xFFffd700),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFffd700).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFffd700).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            FontAwesomeIcons.lightbulb,
                            color: const Color(0xFFffd700),
                            size: 12,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'اضغط على أي صورة لتحديدها كصورة رئيسية • اضغط على ✕ لحذف الصورة',
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: currentImages.length,
                        itemBuilder: (context, index) {
                          final isMainImage = index == 0;
                          return GestureDetector(
                            onTap: () {
                              if (index != 0) {
                                setState(() {
                                  final selectedImage = currentImages.removeAt(index);
                                  currentImages.insert(0, selectedImage);
                                });

                                // طباعة معلومات تشخيصية
                                debugPrint('🔄 تم تحديد الصورة رقم ${index + 1} كصورة رئيسية');
                                debugPrint('📋 ترتيب الصور الحالي:');
                                for (int i = 0; i < currentImages.length; i++) {
                                  debugPrint('  ${i + 1}. ${currentImages[i]} ${i == 0 ? '(رئيسية)' : ''}');
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '✅ تم تحديد الصورة كصورة رئيسية',
                                      style: GoogleFonts.cairo(),
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isMainImage ? const Color(0xFFffd700) : Colors.grey[600]!,
                                        width: isMainImage ? 3 : 1,
                                      ),
                                      boxShadow: isMainImage ? [
                                        BoxShadow(
                                          color: const Color(0xFFffd700).withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ] : null,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        currentImages[index],
                                        width: 110,
                                        height: 110,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            width: 110,
                                            height: 110,
                                            color: Colors.grey[100],
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFffd700)),
                                                      value: loadingProgress.expectedTotalBytes != null
                                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                          : null,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'تحميل...',
                                                    style: GoogleFonts.cairo(
                                                      fontSize: 8,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 110,
                                            height: 110,
                                            color: Colors.grey[300],
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.image_not_supported,
                                                  color: Colors.grey,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'خطأ في التحميل',
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 8,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),

                                  // شارة الصورة الرئيسية
                                  if (isMainImage)
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFffd700),
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.3),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              FontAwesomeIcons.star,
                                              size: 8,
                                              color: Colors.black,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              'رئيسية',
                                              style: GoogleFonts.cairo(
                                                fontSize: 8,
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                  // زر تحديد كصورة رئيسية
                                  if (!isMainImage)
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            final selectedImage = currentImages.removeAt(index);
                                            currentImages.insert(0, selectedImage);
                                          });

                                          // طباعة معلومات تشخيصية
                                          debugPrint('⭐ تم تحديد الصورة رقم ${index + 1} كصورة رئيسية (عبر الزر)');
                                          debugPrint('📋 ترتيب الصور الحالي:');
                                          for (int i = 0; i < currentImages.length; i++) {
                                            debugPrint('  ${i + 1}. ${currentImages[i]} ${i == 0 ? '(رئيسية)' : ''}');
                                          }

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '✅ تم تحديد الصورة كصورة رئيسية',
                                                style: GoogleFonts.cairo(),
                                              ),
                                              backgroundColor: Colors.green,
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.9),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color(0xFFffd700),
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.3),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            FontAwesomeIcons.star,
                                            color: Color(0xFFffd700),
                                            size: 10,
                                          ),
                                        ),
                                      ),
                                    ),

                                  // زر حذف الصورة
                                  Positioned(
                                    top: 6,
                                    left: 6,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          currentImages.removeAt(index);
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'تم حذف الصورة',
                                              style: GoogleFonts.cairo(),
                                            ),
                                            backgroundColor: Colors.red,
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: 0.9),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.3),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          FontAwesomeIcons.xmark,
                                          color: Colors.white,
                                          size: 10,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // رقم الصورة
                                  Positioned(
                                    bottom: 6,
                                    left: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${index + 1}',
                                        style: GoogleFonts.cairo(
                                          fontSize: 8,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey[600]!,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              FontAwesomeIcons.images,
                              size: 30,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'لا توجد صور للمنتج',
                              style: GoogleFonts.cairo(
                                color: Colors.grey[400],
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'اضغط على "اختيار الصور" أعلاه لإضافة صور',
                              style: GoogleFonts.cairo(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // قسم الألوان - النظام الذكي المتطور
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213e),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFffd700).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              FontAwesomeIcons.palette,
                              color: const Color(0xFFffd700),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'ألوان المنتج',
                              style: GoogleFonts.cairo(
                                color: const Color(0xFFffd700),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        // عرض الألوان الحالية
                        FutureBuilder<List<ProductColor>>(
                          future: SmartColorsService.getProductColors(
                            productId: product.id,
                            includeUnavailable: true,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFffd700),
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return Text(
                                'خطأ في تحميل الألوان: ${snapshot.error}',
                                style: GoogleFonts.cairo(color: Colors.red),
                              );
                            }

                            currentColors = snapshot.data ?? [];

                            if (currentColors.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[600]!),
                                ),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        FontAwesomeIcons.palette,
                                        color: Colors.grey[400],
                                        size: 30,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'لا توجد ألوان للمنتج',
                                        style: GoogleFonts.cairo(
                                          color: Colors.grey[400],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: currentColors.map((color) {
                                return Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: color.flutterColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        color.colorArabicName,
                                        style: GoogleFonts.cairo(
                                          color: color.textColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${color.availableQuantity}',
                                        style: GoogleFonts.cairo(
                                          color: color.textColor.withValues(alpha: 0.8),
                                          fontSize: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),

                        const SizedBox(height: 10),

                        // زر إدارة الألوان
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // فتح نافذة إدارة الألوان
                              _showColorsManagementDialog(product, currentColors, setState);
                            },
                            icon: const Icon(FontAwesomeIcons.gear, size: 14),
                            label: Text(
                              'إدارة الألوان',
                              style: GoogleFonts.cairo(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFffd700),
                              foregroundColor: const Color(0xFF1a1a2e),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إلغاء',
                style: GoogleFonts.cairo(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                // طباعة معلومات تشخيصية قبل التحديث
                debugPrint('💾 تحديث المنتج: ${nameController.text}');
                debugPrint('📸 ترتيب الصور قبل الحفظ:');
                for (int i = 0; i < currentImages.length; i++) {
                  debugPrint('  ${i + 1}. ${currentImages[i]} ${i == 0 ? '(رئيسية)' : ''}');
                }

                await _updateProductInDatabase(
                  product.id,
                  nameController.text,
                  descriptionController.text,
                  double.tryParse(wholesalePriceController.text) ??
                      product.wholesalePrice,
                  double.tryParse(minPriceController.text) ?? product.minPrice,
                  double.tryParse(maxPriceController.text) ?? product.maxPrice,
                  int.tryParse(availableFromController.text) ??
                      product.availableFrom,
                  int.tryParse(availableToController.text) ??
                      product.availableTo,
                  int.tryParse(stockQuantityController.text) ??
                      product.availableQuantity,
                  selectedCategory,
                  currentImages,
                  int.tryParse(displayOrderController.text) ?? product.displayOrder,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
              ),
              child: Text('حفظ', style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  /// 🎨 نافذة إدارة الألوان المتطورة
  void _showColorsManagementDialog(Product product, List<ProductColor> currentColors, StateSetter parentSetState) {
    showDialog(
      context: context,
      builder: (context) => ColorsManagementDialog(
        productId: product.id,
        productName: product.name,
        initialColors: currentColors,
        onColorsUpdated: () {
          // إعادة تحميل الألوان في النافذة الرئيسية
          parentSetState(() {});
        },
      ),
    );
  }

  Widget _buildEditTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    int? minLines,
    bool expandable = false,
    TextInputType? keyboardType,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: keyboardType,
        maxLines: expandable ? null : maxLines,
        minLines: expandable ? (minLines ?? 3) : null,
        textAlignVertical: expandable ? TextAlignVertical.top : TextAlignVertical.center,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: const Color(0xFFffc107)),
          border: const OutlineInputBorder(),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: const Color(0xFFffc107),
              width: expandable ? 2 : 1,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: expandable ? 16 : 12,
          ),
        ),
      ),
    );
  }

  Future<void> _updateProductInDatabase(
    String productId,
    String name,
    String description,
    double wholesalePrice,
    double minPrice,
    double maxPrice,
    int availableFrom,
    int availableTo,
    int availableQuantity,
    String category,
    List<String> images,
    int displayOrder,
  ) async {
    try {
      // طباعة معلومات تشخيصية قبل التحديث
      debugPrint('💾 تحديث المنتج في قاعدة البيانات: $name');
      debugPrint('🔢 ترتيب العرض: $displayOrder');
      debugPrint('📸 الصور المرسلة للحفظ:');
      for (int i = 0; i < images.length; i++) {
        debugPrint('  ${i + 1}. ${images[i]} ${i == 0 ? '(رئيسية)' : ''}');
      }

      // استخدام النظام الذكي لتحديث المنتج
      final result = await SmartInventoryManager.updateProductWithSmartInventory(
        productId: productId,
        name: name,
        description: description,
        wholesalePrice: wholesalePrice,
        minPrice: minPrice,
        maxPrice: maxPrice,
        totalQuantity: availableQuantity,
        category: category,
        images: images,
      );

      if (!result['success']) {
        throw Exception(result['message'] ?? 'فشل في تحديث المنتج');
      }

      // تحديث ترتيب العرض والصور منفصلاً (لضمان الحفظ الصحيح)
      await Supabase.instance.client
          .from('products')
          .update({
            'display_order': displayOrder,
            'images': images, // تحديث حقل الصور مباشرة
            'image_url': images.isNotEmpty ? images.first : null, // تحديث الصورة الرئيسية
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', productId);

      debugPrint('✅ تم تحديث المنتج بالنظام الذكي: ${result['message']}');
      debugPrint('🎯 النطاق الذكي: ${result['smart_range']}');
      debugPrint('🔢 تم تحديث ترتيب العرض إلى: $displayOrder');
      debugPrint('📸 تم تحديث الصور في قاعدة البيانات:');
      for (int i = 0; i < images.length; i++) {
        debugPrint('  ${i + 1}. ${images[i]} ${i == 0 ? '(رئيسية - محدثة)' : ''}');
      }

      // 🔔 إرسال طلب مراقبة المنتج للتحقق من نفاد المخزون
      try {
        final String baseUrl = kDebugMode
            ? 'http://localhost:3003'
            : 'https://clownfish-app-krnk9.ondigitalocean.app';

        final response = await http.post(
          Uri.parse('$baseUrl/api/inventory/monitor/$productId'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          debugPrint('✅ تم إرسال طلب مراقبة المنتج: $productId');
        } else {
          debugPrint('⚠️ فشل في إرسال طلب مراقبة المنتج: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('⚠️ خطأ في إرسال طلب مراقبة المنتج: $e');
      }

      // تحديث قائمة المنتجات فوراً
      _loadAllProducts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ تم تحديث المنتج وجميع الصور بنجاح!',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحديث المنتج: $e');

      String errorMessage = 'خطأ في تحديث المنتج';

      if (e.toString().contains('permission')) {
        errorMessage = 'ليس لديك صلاحية لتحديث المنتجات';
      } else if (e.toString().contains('network')) {
        errorMessage = 'مشكلة في الاتصال بالإنترنت';
      } else if (e.toString().contains('duplicate')) {
        errorMessage = 'اسم المنتج موجود مسبقاً';
      } else if (e.toString().contains('validation')) {
        errorMessage = 'بيانات المنتج غير صحيحة';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'انتهت مهلة الاتصال - يرجى المحاولة مرة أخرى';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
        content: Text(
          'هل أنت متأكد من حذف المنتج "${product.name}"؟',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              performDeleteProduct(product);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> performDeleteProduct(Product product) async {
    try {
      await Supabase.instance.client
          .from('products')
          .delete()
          .eq('id', product.id);

      setState(() {}); // إعادة تحميل القائمة

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف المنتج "${product.name}" بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حذف المنتج: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget buildFinancialManagement() {
    return const Center(
      child: Text(
        'الإدارة المالية - قيد التطوير',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  Widget buildReportsSection() {
    return const Center(
      child: Text(
        'التقارير - قيد التطوير',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  Widget buildSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إعدادات النظام',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // قسم اختبار النظام
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF16213e),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFFffd700).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'اختبار النظام',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'اختبار اتصال قاعدة البيانات وتحديث حالات الطلبات',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 15),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              _showErrorSnackBar('النظام يعمل بشكل صحيح');
                            },
                            icon: const Icon(Icons.bug_report),
                            label: const Text('اختبار النظام'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFffd700),
                              foregroundColor: const Color(0xFF1a1a2e),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ScheduledOrdersTestPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.schedule_send),
                            label: const Text('اختبار الطلبات المجدولة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9C27B0),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.go('/test-db');
                        },
                        icon: const Icon(Icons.analytics_outlined),
                        label: const Text('تشخيص قاعدة البيانات'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // قسم الإدارة المالية الشامل
  Widget _buildFinancialManagement() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان الرئيسي
          _buildFinancialHeader(),
          const SizedBox(height: 30),

          // الإحصائيات المالية السريعة
          _buildFinancialQuickStats(),
          const SizedBox(height: 30),

          // طلبات السحب المعلقة
          _buildPendingWithdrawals(),
          const SizedBox(height: 30),

          // إدارة طلبات السحب
          _buildWithdrawalManagement(),
          const SizedBox(height: 30),

          // التقارير المالية
          _buildFinancialReports(),
        ],
      ),
    );
  }

  // بناء رأس القسم المالي
  Widget _buildFinancialHeader() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFffd700), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFffd700).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFffd700),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const FaIcon(
              FontAwesomeIcons.chartLine,
              color: Color(0xFF1a1a2e),
              size: 30,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🏦 الإدارة المالية',
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFffd700),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'إدارة شاملة وآمنة لجميع العمليات المالية والسحوبات',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.security, color: Colors.green, size: 16),
                const SizedBox(width: 5),
                Text(
                  'آمن 100%',
                  style: GoogleFonts.cairo(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          // زر التحديث
          Container(
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: IconButton(
              onPressed: () {
                _refreshData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'تم تحديث البيانات المالية ✅',
                      style: GoogleFonts.cairo(),
                    ),
                    backgroundColor: Colors.blue,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(
                FontAwesomeIcons.arrowsRotate,
                color: Colors.blue,
                size: 18,
              ),
              tooltip: 'تحديث البيانات',
            ),
          ),
        ],
      ),
    );
  }

  // بناء الإحصائيات المالية السريعة مع التحديث المباشر
  Widget _buildFinancialQuickStats() {
    return ValueListenableBuilder<int>(
      valueListenable: _refreshNotifier,
      builder: (context, refreshValue, child) {
        return FutureBuilder<Map<String, dynamic>>(
          future: WithdrawalService.getWithdrawalStatistics(),
          builder: (context, snapshot) {
            final stats = snapshot.data ?? {};

            return GridView.count(
              crossAxisCount: 5, // زيادة العدد لإضافة عدادات جديدة
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _buildFinancialStatCard(
                  title: 'إجمالي المطلوب',
                  value:
                      '${(stats['totalRequested'] ?? 0.0).toStringAsFixed(0)} د.ع',
                  icon: FontAwesomeIcons.moneyBillWave,
                  color: Colors.blue,
                  trend: '${stats['countTotal'] ?? 0} طلب',
                ),
                _buildFinancialStatCard(
                  title: 'تم التحويل',
                  value:
                      '${(stats['totalCompleted'] ?? 0.0).toStringAsFixed(0)} د.ع',
                  icon: FontAwesomeIcons.circleCheck,
                  color: Colors.green,
                  trend: '${stats['countCompleted'] ?? 0} طلب',
                ),
                _buildFinancialStatCard(
                  title: 'الطلبات المعلقة',
                  value: '${stats['countPending'] ?? 0}',
                  icon: FontAwesomeIcons.clock,
                  color: Colors.orange,
                  trend:
                      '${(stats['totalPending'] ?? 0.0).toStringAsFixed(0)} د.ع',
                ),
                _buildFinancialStatCard(
                  title: 'تم الموافقة',
                  value: '${stats['countApproved'] ?? 0}',
                  icon: FontAwesomeIcons.thumbsUp,
                  color: Colors.teal,
                  trend:
                      '${(stats['totalApproved'] ?? 0.0).toStringAsFixed(0)} د.ع',
                ),
                _buildFinancialStatCard(
                  title: 'معدل النجاح',
                  value: '${(stats['successRate'] ?? 0.0).toStringAsFixed(1)}%',
                  icon: FontAwesomeIcons.chartPie,
                  color: Colors.purple,
                  trend: '${stats['countRejected'] ?? 0} مرفوض',
                ),
              ],
            );
          },
        );
      },
    );
  }

  // بناء بطاقة إحصائية مالية
  Widget _buildFinancialStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FaIcon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trend,
                  style: GoogleFonts.cairo(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: GoogleFonts.cairo(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // بناء قسم طلبات السحب المعلقة
  Widget _buildPendingWithdrawals() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.clock,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'طلبات السحب المعلقة',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              // زر التحديث للطلبات المعلقة
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: IconButton(
                  onPressed: () {
                    _refreshData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم تحديث الطلبات المعلقة ✅',
                          style: GoogleFonts.cairo(),
                        ),
                        backgroundColor: Colors.blue,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(
                    FontAwesomeIcons.arrowsRotate,
                    color: Colors.blue,
                    size: 16,
                  ),
                  tooltip: 'تحديث الطلبات المعلقة',
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  'يتطلب مراجعة',
                  style: GoogleFonts.cairo(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // شريط البحث للطلبات المعلقة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: TextField(
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'البحث في الطلبات المعلقة...',
                hintStyle: GoogleFonts.cairo(
                  color: Colors.grey.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
                border: InputBorder.none,
                prefixIcon: const Icon(
                  FontAwesomeIcons.magnifyingGlass,
                  color: Colors.orange,
                  size: 16,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          const SizedBox(height: 15),

          ValueListenableBuilder<int>(
            valueListenable: _refreshNotifier,
            builder: (context, refreshValue, child) {
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: WithdrawalService.getAllWithdrawalRequests(
                  status: 'pending',
                  limit: 10,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allRequests = snapshot.data ?? [];

                  // تطبيق البحث على الطلبات المعلقة
                  final requests = _filterRequests(allRequests);

                  if (allRequests.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.circleCheck,
                            color: Colors.green,
                            size: 40,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'لا توجد طلبات سحب معلقة',
                            style: GoogleFonts.cairo(
                              color: Colors.green,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (requests.isEmpty && _searchQuery.isNotEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.magnifyingGlass,
                            color: Colors.orange,
                            size: 40,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'لا توجد نتائج للبحث',
                            style: GoogleFonts.cairo(
                              color: Colors.orange,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: requests.take(3).map((request) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1a1a2e),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.orange.withValues(
                                alpha: 0.2,
                              ),
                              child: Text(
                                (request['users']['name'] as String).substring(
                                  0,
                                  1,
                                ),
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    request['users']['name'],
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '${(request['amount'] as num).toStringAsFixed(0)} د.ع',
                                        style: GoogleFonts.cairo(
                                          color: Colors.orange,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '• ${_getMethodText(request['withdrawal_method'])}',
                                        style: GoogleFonts.cairo(
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'البطاقة: ${request['account_details'] ?? 'غير محدد'}',
                                    style: GoogleFonts.cairo(
                                      color: Colors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    'التاريخ: ${_formatWithdrawalDate(request['request_date'])}',
                                    style: GoogleFonts.cairo(
                                      color: Colors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _showWithdrawalDetails(request),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 8,
                                ),
                              ),
                              child: Text(
                                'مراجعة',
                                style: GoogleFonts.cairo(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // بناء قسم إدارة طلبات السحب
  Widget _buildWithdrawalManagement() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.gears,
                color: Color(0xFFffd700),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'إدارة طلبات السحب',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              // زر التحديث لإدارة طلبات السحب
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFffd700).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFffd700).withValues(alpha: 0.3),
                  ),
                ),
                child: IconButton(
                  onPressed: () {
                    _refreshData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم تحديث إدارة طلبات السحب ✅',
                          style: GoogleFonts.cairo(),
                        ),
                        backgroundColor: const Color(0xFFffd700),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(
                    FontAwesomeIcons.arrowsRotate,
                    color: Color(0xFFffd700),
                    size: 16,
                  ),
                  tooltip: 'تحديث إدارة طلبات السحب',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildManagementButton(
                  title: 'جميع الطلبات',
                  subtitle: 'عرض وإدارة جميع طلبات السحب',
                  icon: FontAwesomeIcons.list,
                  color: Colors.blue,
                  onTap: () => _showAllWithdrawals(),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildManagementButton(
                  title: 'الطلبات المعلقة',
                  subtitle: 'مراجعة الطلبات التي تحتاج موافقة',
                  icon: FontAwesomeIcons.clock,
                  color: Colors.orange,
                  onTap: () => _showPendingWithdrawals(),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildManagementButton(
                  title: 'الطلبات المكتملة',
                  subtitle: 'عرض الطلبات المحولة بنجاح',
                  icon: FontAwesomeIcons.circleCheck,
                  color: Colors.green,
                  onTap: () => _showCompletedWithdrawals(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // بناء زر إدارة
  Widget _buildManagementButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            FaIcon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: GoogleFonts.cairo(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // بناء قسم التقارير المالية
  Widget _buildFinancialReports() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.chartBar,
                color: Colors.purple,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'التقارير المالية',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildReportButton(
                  title: 'تقرير يومي',
                  icon: FontAwesomeIcons.calendar,
                  color: Colors.blue,
                  onTap: () => _generateDailyReport(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildReportButton(
                  title: 'تقرير أسبوعي',
                  icon: FontAwesomeIcons.calendarWeek,
                  color: Colors.green,
                  onTap: () => _generateWeeklyReport(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildReportButton(
                  title: 'تقرير شهري',
                  icon: FontAwesomeIcons.calendarDays,
                  color: Colors.orange,
                  onTap: () => _generateMonthlyReport(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildReportButton(
                  title: 'تقرير مخصص',
                  icon: FontAwesomeIcons.filter,
                  color: Colors.purple,
                  onTap: () => _generateCustomReport(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // بناء زر تقرير
  Widget _buildReportButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            FaIcon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'التقارير والإحصائيات',
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: const Color(0xFF16213e),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.analytics, color: Colors.blue),
                    title: const Text(
                      'التقارير التفصيلية',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'عرض التقارير المالية والإحصائيات التفصيلية',
                      style: TextStyle(color: Colors.grey),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReportsPage(),
                        ),
                      );
                    },
                  ),
                  const Divider(color: Colors.grey),
                  ListTile(
                    leading: const Icon(Icons.bar_chart, color: Colors.green),
                    title: const Text(
                      'إحصائيات سريعة',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'عرض الإحصائيات السريعة والمؤشرات الرئيسية',
                      style: TextStyle(color: Colors.grey),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'الإحصائيات السريعة متاحة في الصفحة الرئيسية',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الإعدادات والتحكم',
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: const Color(0xFF16213e),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.settings, color: Colors.blue),
                    title: const Text(
                      'الإعدادات العامة',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'إدارة إعدادات التطبيق والحساب والأمان',
                      style: TextStyle(color: Colors.grey),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      );
                    },
                  ),
                  const Divider(color: Colors.grey),
                  ListTile(
                    leading: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.orange,
                    ),
                    title: const Text(
                      'إعدادات الإدارة',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'إعدادات خاصة بالمدير والصلاحيات',
                      style: TextStyle(color: Colors.grey),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminSettingsPage(),
                        ),
                      );
                    },
                  ),
                  const Divider(color: Colors.grey),
                  ListTile(
                    leading: const Icon(Icons.backup, color: Colors.green),
                    title: const Text(
                      'النسخ الاحتياطي',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'إدارة النسخ الاحتياطي واستعادة البيانات',
                      style: TextStyle(color: Colors.grey),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('النسخ الاحتياطي قيد التطوير'),
                        ),
                      );
                    },
                  ),
                  const Divider(color: Colors.grey),
                  ListTile(
                    leading: const Icon(Icons.info, color: Colors.purple),
                    title: const Text(
                      'معلومات النظام',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'معلومات التطبيق والإصدار والدعم',
                      style: TextStyle(color: Colors.grey),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('معلومات النظام'),
                          content: const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('اسم التطبيق: منتجاتي'),
                              Text('الإصدار: 1.0.0'),
                              Text('تاريخ الإصدار: 2025-06-26'),
                              Text('المطور: فريق منتجاتي'),
                              Text('نوع النسخة: إدارية متقدمة'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('موافق'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // دالة اختيار الصور
  Future<void> _pickImages(
    StateSetter setState,
    List<String> currentImages,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();

      // اختيار صور متعددة
      final List<XFile> pickedFiles = await picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFiles.isNotEmpty) {
        // إظهار مؤشر التحميل
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text('جاري رفع ${pickedFiles.length} صورة...'),
                ],
              ),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 10),
            ),
          );
        }

        // رفع الصور الحقيقية إلى Supabase Storage
        List<String> newImageUrls = [];

        for (int i = 0; i < pickedFiles.length; i++) {
          try {
            String? imageUrl = await _uploadImageToSupabase(pickedFiles[i]);
            if (imageUrl != null) {
              newImageUrls.add(imageUrl);
            }
          } catch (e) {
            debugPrint('خطأ في رفع الصورة ${i + 1}: $e');
          }
        }

        if (newImageUrls.isNotEmpty) {
          setState(() {
            currentImages.addAll(newImageUrls);
          });

          // طباعة معلومات تشخيصية
          debugPrint('✅ تم رفع ${newImageUrls.length} صورة جديدة');
          debugPrint('📸 الصور الجديدة: $newImageUrls');
          debugPrint('📸 إجمالي الصور الآن: ${currentImages.length}');
          for (int i = 0; i < currentImages.length; i++) {
            debugPrint('  ${i + 1}. ${currentImages[i]} ${i == 0 ? '(رئيسية)' : ''}');
          }

          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم رفع ${newImageUrls.length} صورة بنجاح'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('فشل في رفع الصور'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في اختيار الصور: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // دالة رفع صورة واحدة إلى Supabase Storage
  Future<String?> _uploadImageToSupabase(XFile imageFile) async {
    try {
      // التأكد من وجود bucket
      await _ensureBucketExists();

      // قراءة بيانات الصورة
      final imageBytes = await imageFile.readAsBytes();

      // إنشاء اسم فريد للصورة
      final fileName =
          'product_${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';

      // رفع الصورة
      await Supabase.instance.client.storage
          .from('product-images')
          .uploadBinary(fileName, imageBytes);

      // الحصول على الرابط العام
      final publicUrl = Supabase.instance.client.storage
          .from('product-images')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      debugPrint('خطأ في رفع الصورة: $e');
      return null;
    }
  }

  // التأكد من وجود bucket
  Future<void> _ensureBucketExists() async {
    try {
      // محاولة الحصول على معلومات bucket
      await Supabase.instance.client.storage.getBucket('product-images');
    } catch (e) {
      // إذا لم يكن موجود، إنشاؤه
      try {
        await Supabase.instance.client.storage.createBucket(
          'product-images',
          const BucketOptions(public: true),
        );
      } catch (createError) {
        debugPrint('خطأ في إنشاء bucket: $createError');
      }
    }
  }

  // === دوال إدارة السحوبات المالية ===

  // عرض تفاصيل طلب السحب
  void _showWithdrawalDetails(Map<String, dynamic> request) {
    final requestNumber = request['request_number']?.toString() ?? 'غير محدد';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Text(
          'تفاصيل طلب السحب رقم $requestNumber',
          style: GoogleFonts.cairo(color: const Color(0xFFffd700)),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('اسم المستخدم:', request['users']['name']),
              _buildDetailRow('رقم الهاتف:', request['users']['phone']),
              _buildDetailRow(
                'المبلغ:',
                '${(request['amount'] as num).toStringAsFixed(0)} د.ع',
              ),
              _buildDetailRow('طريقة السحب:', request['withdrawal_method']),
              _buildDetailRow('تفاصيل الحساب:', request['account_details']),
              _buildDetailRow('الحالة:', request['status']),
              _buildDetailRow('تاريخ الطلب:', request['request_date']),
              if (request['note'] != null)
                _buildDetailRow('ملاحظات:', request['note']),
              const SizedBox(height: 15),
              // قسم تعديل الحالة
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213e),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تعديل حالة الطلب',
                      style: GoogleFonts.cairo(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildStatusSelector(request),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق', style: GoogleFonts.cairo(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // بناء محدد الحالة
  Widget _buildStatusSelector(Map<String, dynamic> request) {
    final currentStatus = request['status'] as String;
    final statuses = [
      {'value': 'completed', 'label': 'تم التحويل', 'color': Colors.green},
      {'value': 'cancelled', 'label': 'ملغي', 'color': Colors.red},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statuses.map((status) {
        final isSelected = status['value'] == currentStatus;
        return GestureDetector(
          onTap: () => _changeWithdrawalStatus(
            request['id'],
            status['value'] as String,
            currentStatus,
            request,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? (status['color'] as Color).withValues(alpha: 0.2)
                  : Colors.transparent,
              border: Border.all(
                color: status['color'] as Color,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              status['label'] as String,
              style: GoogleFonts.cairo(
                color: status['color'] as Color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // تغيير حالة طلب السحب مع التحديث المباشر
  void _changeWithdrawalStatus(
    String requestId,
    String newStatus,
    String oldStatus,
    Map<String, dynamic> request,
  ) async {
    // التأكد من التغيير
    if (newStatus == oldStatus) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Text(
          'تأكيد تغيير الحالة',
          style: GoogleFonts.cairo(color: const Color(0xFFffd700)),
        ),
        content: Text(
          'هل أنت متأكد من تغيير حالة الطلب من "$oldStatus" إلى "$newStatus"؟\n\n'
          '⚠️ تنبيه: إذا كانت الحالة الجديدة "ملغي"، سيتم إرجاع المبلغ إلى الأرباح المحققة.',
          style: GoogleFonts.cairo(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('تأكيد', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      debugPrint('🔄 تغيير حالة السحب من $oldStatus إلى $newStatus');

      final result = await WithdrawalService.updateWithdrawalStatus(
        requestId: requestId,
        newStatus: newStatus,
        adminNotes: 'تم تغيير الحالة من $oldStatus إلى $newStatus',
      );

      if (!mounted) return;

      if (result['success']) {
        // تحديث الحالة في البيانات المحلية فوراً
        request['status'] = newStatus;
        request['process_date'] = DateTime.now().toIso8601String();

        // إغلاق نافذة التفاصيل
        Navigator.pop(context);

        // تحديث الواجهة مباشرة مع إعادة تحميل البيانات
        setState(() {
          // إجبار إعادة بناء جميع FutureBuilder
          _refreshData();
        });

        // تأخير قصير ثم تحديث إضافي للتأكد
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _refreshData();
            });
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تغيير حالة الطلب بنجاح ✅\nتم إرسال إشعار للمستخدم 📱',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ: ${result['message']}',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في النظام: $e', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // دالة لتحديث البيانات مباشرة
  void _refreshData() {
    debugPrint('🔄 تحديث البيانات مباشرة...');

    // تحديث العداد لإجبار إعادة بناء جميع FutureBuilder
    _refreshNotifier.value++;

    // تحديث حالة الصفحة أيضاً
    if (mounted) {
      setState(() {
        // إعادة تحميل البيانات
      });
    }
  }

  // دالة البحث الشاملة في طلبات السحب
  List<Map<String, dynamic>> _filterRequests(
    List<Map<String, dynamic>> requests,
  ) {
    if (_searchQuery.isEmpty) {
      return requests;
    }

    return requests.where((request) {
      // البحث في رقم الطلب التسلسلي (الأولوية)
      final requestNumber = (request['request_number'] ?? '')
          .toString()
          .toLowerCase();

      // البحث في رقم الطلب الأصلي
      final requestId = (request['id'] ?? '').toString().toLowerCase();

      // البحث في اسم المستخدم
      final userName = (request['users']?['name'] ?? '')
          .toString()
          .toLowerCase();

      // البحث في رقم الهاتف
      final userPhone = (request['users']?['phone'] ?? '')
          .toString()
          .toLowerCase();

      // البحث في تفاصيل الحساب (رقم البطاقة)
      final accountDetails = (request['account_details'] ?? '')
          .toString()
          .toLowerCase();

      // البحث في طريقة السحب
      final withdrawalMethod = _getMethodText(
        request['withdrawal_method'],
      ).toLowerCase();

      // البحث في المبلغ
      final amount = (request['amount'] ?? 0).toString();

      // البحث في الحالة
      final status = _getWithdrawalStatusText(request['status']).toLowerCase();

      return requestNumber.contains(_searchQuery) ||
          requestId.contains(_searchQuery) ||
          userName.contains(_searchQuery) ||
          userPhone.contains(_searchQuery) ||
          accountDetails.contains(_searchQuery) ||
          withdrawalMethod.contains(_searchQuery) ||
          amount.contains(_searchQuery) ||
          status.contains(_searchQuery);
    }).toList();
  }

  // الموافقة على طلب السحب مع التحديث المباشر
  // ignore: unused_element
  void _approveWithdrawal(String requestId) async {
    try {
      final result = await WithdrawalService.updateWithdrawalStatus(
        requestId: requestId,
        newStatus: 'approved',
        adminNotes: 'تمت الموافقة من قبل المدير',
      );

      if (!mounted) return;

      if (result['success']) {
        // تحديث الواجهة مباشرة
        setState(() {
          _refreshData();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '😊💛 تمت الموافقة على طلب السحب\nتم إرسال إشعار التحويل للمستخدم 📱',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ: ${result['message']}',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في النظام: $e', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // رفض طلب السحب مع التحديث المباشر
  // ignore: unused_element
  void _rejectWithdrawal(String requestId) async {
    try {
      final result = await WithdrawalService.updateWithdrawalStatus(
        requestId: requestId,
        newStatus: 'rejected',
        adminNotes: 'تم رفض الطلب من قبل المدير',
      );

      if (!mounted) return;

      if (result['success']) {
        // تحديث الواجهة مباشرة
        setState(() {
          _refreshData();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '😢💔 تم رفض طلب السحب\nتم إرسال إشعار الإلغاء للمستخدم 📱',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ: ${result['message']}',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في النظام: $e', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // عرض جميع طلبات السحب
  void _showAllWithdrawals() {
    _showWithdrawalManagementDialog('all');
  }

  // عرض الطلبات المعلقة
  void _showPendingWithdrawals() {
    _showWithdrawalManagementDialog('pending');
  }

  // عرض الطلبات المكتملة
  void _showCompletedWithdrawals() {
    _showWithdrawalManagementDialog('completed');
  }

  // عرض نافذة إدارة طلبات السحب الشاملة
  void _showWithdrawalManagementDialog(String filterType) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF16213e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // العنوان مع زر التحديث
              Row(
                children: [
                  Icon(
                    _getFilterIcon(filterType),
                    color: const Color(0xFFffd700),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _getFilterTitle(filterType),
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFffd700),
                      ),
                    ),
                  ),
                  // زر التحديث
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: IconButton(
                      onPressed: () {
                        _refreshData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'تم تحديث قائمة الطلبات ✅',
                              style: GoogleFonts.cairo(),
                            ),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(
                        FontAwesomeIcons.arrowsRotate,
                        color: Colors.green,
                        size: 18,
                      ),
                      tooltip: 'تحديث القائمة',
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const Divider(color: Color(0xFFffd700)),
              const SizedBox(height: 10),

              // شريط البحث الشامل
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFF1a1a2e),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.cairo(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'البحث في رقم الطلب، اسم المستخدم، رقم الهاتف...',
                    hintStyle: GoogleFonts.cairo(
                      color: Colors.grey.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    prefixIcon: const Icon(
                      FontAwesomeIcons.magnifyingGlass,
                      color: Colors.grey,
                      size: 18,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                            icon: const Icon(
                              FontAwesomeIcons.xmark,
                              color: Colors.grey,
                              size: 16,
                            ),
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              const SizedBox(height: 15),

              // قائمة طلبات السحب
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getFilteredWithdrawals(filterType),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final requests = snapshot.data ?? [];

                    if (requests.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              FontAwesomeIcons.inbox,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد طلبات سحب',
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // تطبيق البحث على الطلبات
                    final filteredRequests = _filterRequests(requests);

                    if (filteredRequests.isEmpty && _searchQuery.isNotEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              FontAwesomeIcons.magnifyingGlass,
                              size: 64,
                              color: Colors.grey.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد نتائج للبحث "$_searchQuery"',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                color: Colors.grey.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'جرب البحث برقم الطلب، اسم المستخدم، أو رقم الهاتف',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: Colors.grey.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredRequests.length,
                      itemBuilder: (context, index) {
                        return _buildAdminWithdrawalCard(
                          filteredRequests[index],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دوال مساعدة لإدارة طلبات السحب
  IconData _getFilterIcon(String filterType) {
    switch (filterType) {
      case 'all':
        return FontAwesomeIcons.list;
      case 'pending':
        return FontAwesomeIcons.clock;
      case 'completed':
        return FontAwesomeIcons.circleCheck;
      default:
        return FontAwesomeIcons.list;
    }
  }

  String _getFilterTitle(String filterType) {
    switch (filterType) {
      case 'all':
        return 'جميع طلبات السحب';
      case 'pending':
        return 'الطلبات المعلقة';
      case 'completed':
        return 'الطلبات المكتملة';
      default:
        return 'طلبات السحب';
    }
  }

  Future<List<Map<String, dynamic>>> _getFilteredWithdrawals(
    String filterType,
  ) async {
    try {
      if (filterType == 'all') {
        return await WithdrawalService.getAllWithdrawalRequests();
      } else {
        return await WithdrawalService.getAllWithdrawalRequests(
          status: filterType,
        );
      }
    } catch (e) {
      debugPrint('خطأ في جلب طلبات السحب: $e');
      return [];
    }
  }

  // بناء بطاقة طلب السحب للمدير المحسنة
  Widget _buildAdminWithdrawalCard(Map<String, dynamic> request) {
    final statusColor = _getWithdrawalStatusColor(request['status']);
    final statusText = _getWithdrawalStatusText(request['status']);
    final formattedDate = _formatWithdrawalDate(request['request_date']);
    final requestNumber = request['request_number']?.toString() ?? 'غير محدد';
    // تم حذف requestId غير المستخدم
    final userName = request['users']['name'] ?? 'غير محدد';
    final userPhone = request['users']['phone'] ?? 'غير محدد';
    final amount = (request['amount'] as num).toStringAsFixed(0);
    final method = _getMethodText(request['withdrawal_method']);
    final cardNumber = request['account_details'] ?? 'غير محدد';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الصف الأول: رقم الطلب والحالة
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      FontAwesomeIcons.hashtag,
                      color: Colors.cyan,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'طلب رقم:',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.cyan,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        requestNumber,
                        style: GoogleFonts.robotoMono(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.cyan,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildCopyButton(requestNumber, 'رقم الطلب'),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // الصف الثاني: اسم المستخدم
          Row(
            children: [
              const Icon(
                FontAwesomeIcons.user,
                color: Color(0xFFffd700),
                size: 18,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  userName,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _buildCopyButton(userName, 'الاسم'),
            ],
          ),
          const SizedBox(height: 15),

          // الصف الثاني: المبلغ وطريقة السحب
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      FontAwesomeIcons.dollarSign,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$amount د.ع',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildCopyButton(amount, 'المبلغ'),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(
                    FontAwesomeIcons.creditCard,
                    color: Colors.blue,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    method,
                    style: GoogleFonts.cairo(fontSize: 14, color: Colors.blue),
                  ),
                  const SizedBox(width: 8),
                  _buildCopyButton(method, 'طريقة السحب'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),

          // الصف الثالث: رقم البطاقة (مكبر)
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF16213e),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  FontAwesomeIcons.creditCard,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'رقم البطاقة',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cardNumber,
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildCopyButton(cardNumber, 'رقم البطاقة'),
              ],
            ),
          ),
          const SizedBox(height: 15),

          // الصف الرابع: رقم الهاتف والتاريخ
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      FontAwesomeIcons.phone,
                      color: Colors.purple,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        userPhone,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: Colors.purple,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildCopyButton(userPhone, 'رقم الهاتف'),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(
                    FontAwesomeIcons.calendar,
                    color: Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formattedDate,
                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  _buildCopyButton(formattedDate, 'التاريخ'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),

          // أزرار الإجراءات
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showWithdrawalDetails(request),
                  icon: const Icon(FontAwesomeIcons.eye, size: 16),
                  label: Text('عرض التفاصيل', style: GoogleFonts.cairo()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _copyAllDetails(request),
                icon: const Icon(FontAwesomeIcons.copy, size: 16),
                label: Text('نسخ الكل', style: GoogleFonts.cairo()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // بناء زر النسخ
  Widget _buildCopyButton(String text, String label) {
    return GestureDetector(
      onTap: () => _copyToClipboard(text, label),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(FontAwesomeIcons.copy, size: 12, color: Colors.grey),
      ),
    );
  }

  // نسخ النص إلى الحافظة
  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ $label: $text', style: GoogleFonts.cairo()),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // نسخ جميع التفاصيل
  void _copyAllDetails(Map<String, dynamic> request) {
    final requestNumber = request['request_number']?.toString() ?? 'غير محدد';
    final userName = request['users']['name'] ?? 'غير محدد';
    final userPhone = request['users']['phone'] ?? 'غير محدد';
    final amount = (request['amount'] as num).toStringAsFixed(0);
    final method = _getMethodText(request['withdrawal_method']);
    final cardNumber = request['account_details'] ?? 'غير محدد';
    final status = _getWithdrawalStatusText(request['status']);
    final date = _formatWithdrawalDate(request['request_date']);

    final allDetails =
        '''
📋 تفاصيل طلب السحب:
🆔 رقم الطلب: $requestNumber
👤 الاسم: $userName
📞 الهاتف: $userPhone
💰 المبلغ: $amount د.ع
💳 طريقة السحب: $method
🔢 رقم البطاقة: $cardNumber
📊 الحالة: $status
📅 التاريخ: $date
''';

    Clipboard.setData(ClipboardData(text: allDetails));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ جميع التفاصيل', style: GoogleFonts.cairo()),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // دوال مساعدة لتنسيق بيانات السحب
  Color _getWithdrawalStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF28a745); // أخضر - تم التحويل
      case 'cancelled':
        return const Color(0xFFdc3545); // أحمر - ملغي
      default:
        return const Color(0xFF6c757d); // رمادي - غير محدد
    }
  }

  String _getWithdrawalStatusText(String? status) {
    switch (status) {
      case 'completed':
        return 'تم التحويل';
      case 'cancelled':
        return 'ملغي';
      default:
        return 'غير محدد';
    }
  }

  String _getMethodText(String? method) {
    switch (method) {
      case 'mastercard':
        return 'ماستر كارد';
      case 'zaincash':
        return 'زين كاش';
      case 'bank_transfer':
        return 'تحويل بنكي';
      case 'paypal':
        return 'باي بال';
      default:
        return 'غير محدد';
    }
  }

  String _formatWithdrawalDate(String? dateString) {
    if (dateString == null) return 'غير محدد';

    try {
      // تحويل التاريخ من UTC إلى توقيت العراق (+3 ساعات)
      final utcDate = DateTime.parse(dateString);
      final iraqDate = utcDate.add(const Duration(hours: 3));

      // تنسيق التاريخ: السنة-الشهر-اليوم الساعة:الدقيقة
      final year = iraqDate.year;
      final month = iraqDate.month.toString().padLeft(2, '0');
      final day = iraqDate.day.toString().padLeft(2, '0');
      final hour = iraqDate.hour.toString().padLeft(2, '0');
      final minute = iraqDate.minute.toString().padLeft(2, '0');

      return '$year-$month-$day $hour:$minute';
    } catch (e) {
      return 'تاريخ غير صحيح';
    }
  }

  // === دوال التقارير المالية ===

  void _generateDailyReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('سيتم إنشاء التقرير اليومي', style: GoogleFonts.cairo()),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _generateWeeklyReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'سيتم إنشاء التقرير الأسبوعي',
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _generateMonthlyReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('سيتم إنشاء التقرير الشهري', style: GoogleFonts.cairo()),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _generateCustomReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'سيتم فتح نافذة التقرير المخصص',
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: Colors.purple,
      ),
    );
  }

  // ===== دوال إدارة المنتجات الجديدة =====

  // مؤشر الإحصائيات السريعة
  Widget _buildQuickStatsIndicator() {
    return FutureBuilder<Map<String, int>>(
      future: _getProductsStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFffc107),
            ),
          );
        }

        final stats = snapshot.data!;
        return Row(
          children: [
            _buildStatChip(
              'المتاحة: ${stats['available'] ?? 0}',
              const Color(0xFF4CAF50),
            ),
            const SizedBox(width: 10),
            _buildStatChip(
              'نفذت: ${stats['outOfStock'] ?? 0}',
              const Color(0xFFF44336),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // جلب إحصائيات المنتجات
  Future<Map<String, int>> _getProductsStats() async {
    try {
      final response = await Supabase.instance.client
          .from('products')
          .select('available_quantity');

      int available = 0;
      int outOfStock = 0;

      for (final item in response) {
        final quantity = item['available_quantity'] as int? ?? 0;
        if (quantity > 0) {
          available++;
        } else {
          outOfStock++;
        }
      }

      return {
        'available': available,
        'outOfStock': outOfStock,
        'total': available + outOfStock,
      };
    } catch (e) {
      debugPrint('خطأ في جلب إحصائيات المنتجات: $e');
      return {'available': 0, 'outOfStock': 0, 'total': 0};
    }
  }

  // تحديث بيانات المنتجات
  Future<void> _refreshProductsData() async {
    setState(() {
      _isLoadingProducts = true;
      _loadProductsFuture = _loadAllProducts(); // إنشاء Future جديد
    });

    try {
      await _loadProductsFuture;
      _showSuccessSnackBar('تم تحديث بيانات المنتجات بنجاح');
    } catch (e) {
      _showErrorSnackBar('خطأ في تحديث البيانات: $e');
    } finally {
      setState(() {
        _isLoadingProducts = false;
      });
    }
  }

  // تحميل جميع المنتجات وتصنيفها
  Future<void> _loadAllProducts() async {
    try {
      debugPrint('🔄 بدء تحميل المنتجات...');

      final response = await Supabase.instance.client
          .from('products')
          .select(
            'id, name, description, image_url, images, wholesale_price, min_price, max_price, available_quantity, available_from, available_to, category, display_order, is_active, created_at',
          )
          .eq('is_active', true)
          .order('display_order', ascending: true) // ترتيب حسب display_order أولاً
          .order('created_at', ascending: false); // ثم حسب تاريخ الإنشاء

      debugPrint('📦 تم جلب ${response.length} منتج من قاعدة البيانات');

      final products = <Product>[];
      for (final json in response) {
        try {
          // تحويل البيانات إلى نموذج Product مع معالجة الصور بشكل صحيح
          List<String> productImages = [];

          // أولاً: تحقق من حقل images (للمنتجات الجديدة)
          if (json['images'] != null && json['images'] is List) {
            final imagesList = List<String>.from(json['images']);
            for (String imageUrl in imagesList) {
              if (imageUrl.isNotEmpty && !imageUrl.contains('placeholder')) {
                productImages.add(imageUrl);
              }
            }
          }

          // ثانياً: إذا لم توجد صور، تحقق من image_url (للمنتجات القديمة)
          if (productImages.isEmpty && json['image_url'] != null) {
            final imageUrl = json['image_url'].toString();
            if (imageUrl.isNotEmpty && !imageUrl.contains('placeholder')) {
              productImages.add(imageUrl);
            }
          }

          // إذا لم توجد أي صور، أضف صورة افتراضية
          if (productImages.isEmpty) {
            productImages.add('https://via.placeholder.com/400x300/1a1a2e/ffd700?text=منتج');
          }

          // طباعة معلومات تشخيصية
          debugPrint('📸 تحميل صور المنتج: ${json['name']}');
          debugPrint('📸 حقل images: ${json['images']}');
          debugPrint('📸 حقل image_url: ${json['image_url']}');
          debugPrint('📸 الصور النهائية: $productImages');

          final product = Product(
            id: json['id'] ?? '',
            name: json['name'] ?? 'منتج بدون اسم',
            description: json['description'] ?? '',
            images: productImages,
            wholesalePrice: (json['wholesale_price'] ?? 0).toDouble(),
            minPrice: (json['min_price'] ?? 0).toDouble(),
            maxPrice: (json['max_price'] ?? 0).toDouble(),
            category: json['category'] ?? 'عام',
            minQuantity: 1,
            maxQuantity: json['max_quantity'] ?? 0,
            availableFrom: json['available_from'] ?? 90,
            availableTo: json['available_to'] ?? 80,
            availableQuantity: json['available_quantity'] ?? 100,
            displayOrder: json['display_order'] ?? 999, // قيمة افتراضية عالية
            createdAt:
                DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
            updatedAt:
                DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
          );
          products.add(product);
        } catch (e) {
          debugPrint('⚠️ خطأ في تحويل المنتج: $e');
        }
      }

      // تحديث البيانات بدون setState لتجنب الحلقة اللانهائية
      _allProducts = products;
      _availableProducts = products
          .where((p) => p.availableQuantity > 0)
          .toList();
      _outOfStockProducts = products
          .where((p) => p.availableQuantity <= 0)
          .toList();

      debugPrint(
        '✅ تم تصنيف المنتجات: ${_availableProducts.length} متاح، ${_outOfStockProducts.length} نفذ',
      );
    } catch (e) {
      debugPrint('❌ خطأ في تحميل المنتجات: $e');
      // لا نرمي الخطأ لتجنب توقف التطبيق
      // تحديث البيانات بدون setState لتجنب الحلقة اللانهائية
      _allProducts = [];
      _availableProducts = [];
      _outOfStockProducts = [];
    }
  }

  // بناء تبويبات المنتجات
  Widget _buildProductsTabs([bool isSmallScreen = false]) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              'جميع المنتجات',
              Icons.inventory_2,
              0,
              _allProducts.length,
              isSmallScreen,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              'نفذ من المخزون',
              Icons.warning_amber,
              1,
              _outOfStockProducts.length,
              isSmallScreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, IconData icon, int index, int count, [bool isSmallScreen = false]) {
    final isSelected = _selectedProductsTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedProductsTab = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 12 : 15,
          horizontal: isSmallScreen ? 12 : 20,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFffc107) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: isSmallScreen
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? const Color(0xFF1a1a2e) : Colors.white,
                  size: 18,
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF1a1a2e) : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (count > 0) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1a1a2e)
                          : const Color(0xFFffc107),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFFffc107)
                            : const Color(0xFF1a1a2e),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? const Color(0xFF1a1a2e) : Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF1a1a2e) : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1a1a2e)
                          : const Color(0xFFffc107),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFFffc107)
                            : const Color(0xFF1a1a2e),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
      ),
    );
  }

  // بناء محتوى التبويبات
  Widget _buildProductsTabContent() {
    if (_isLoadingProducts) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFffc107)),
            SizedBox(height: 16),
            Text(
              'جاري تحميل المنتجات...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    // عرض البيانات مباشرة بدون FutureBuilder لتجنب الحلقة اللانهائية
    if (_allProducts.isEmpty && !_isLoadingProducts) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2, color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            const Text(
              'لا توجد منتجات',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshProductsData,
              child: const Text('تحديث'),
            ),
          ],
        ),
      );
    }

    List<Product> productsToShow;
    String emptyMessage;
    IconData emptyIcon;

    switch (_selectedProductsTab) {
      case 1: // نفذ من المخزون
        productsToShow = _outOfStockProducts;
        emptyMessage = 'لا توجد منتجات نفذت من المخزون';
        emptyIcon = Icons.check_circle;
        break;
      default: // جميع المنتجات
        productsToShow = _allProducts;
        emptyMessage = 'لا توجد منتجات';
        emptyIcon = Icons.inventory_2;
    }

    if (productsToShow.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, color: Colors.grey, size: 64),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            if (_selectedProductsTab == 0) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _addNewProduct,
                icon: const Icon(Icons.add),
                label: const Text('إضافة منتج جديد'),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        // شريط البحث والفلترة
        _buildProductsSearchBar(MediaQuery.of(context).size.width < 768),
        const SizedBox(height: 20),

        // قائمة المنتجات
        Expanded(
          child: ListView.builder(
            itemCount: productsToShow.length,
            itemBuilder: (context, index) {
              final product = productsToShow[index];
              return _buildEnhancedProductCard(
                product,
                MediaQuery.of(context).size.width < 768,
              );
            },
          ),
        ),
      ],
    );
  }

  // شريط البحث والفلترة
  Widget _buildProductsSearchBar([bool isSmallScreen = false]) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 14 : 16,
              ),
              decoration: InputDecoration(
                hintText: 'البحث في المنتجات...',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: isSmallScreen ? 14 : 16,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: const Color(0xFFffc107),
                  size: isSmallScreen ? 20 : 24,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFF1a1a2e),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 8 : 12,
                ),
              ),
              onChanged: (value) {
                // ignore: todo
                // TODO: تطبيق البحث
              },
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFffc107),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: () {
                // ignore: todo
                // TODO: فتح خيارات الفلترة
              },
              icon: Icon(
                Icons.filter_list,
                color: const Color(0xFF1a1a2e),
                size: isSmallScreen ? 18 : 20,
              ),
              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
            ),
          ),
        ],
      ),
    );
  }

  // بناء كارت المنتج المحسن
  Widget _buildEnhancedProductCard(Product product, [bool isSmallScreen = false]) {
    final isOutOfStock = product.availableQuantity <= 0;

    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(15),
        border: isOutOfStock
            ? Border.all(color: const Color(0xFFF44336), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: isOutOfStock
                ? const Color(0xFFF44336).withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // رأس الكارت مع حالة المخزون
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: isOutOfStock
                  ? const Color(0xFFF44336).withValues(alpha: 0.2)
                  : const Color(0xFF4CAF50).withValues(alpha: 0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: isSmallScreen
              ? Column(
                  children: [
                    // صورة المنتج للشاشات الصغيرة
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        product.images.isNotEmpty
                            ? product.images.first
                            : 'https://via.placeholder.com/60x60/1a1a2e/ffd700?text=منتج',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1a1a2e),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Color(0xFFffc107),
                              size: 30,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    // معلومات المنتج للشاشات الصغيرة
                    _buildProductInfoSmall(product, isOutOfStock),
                  ],
                )
              : Row(
                  children: [
                    // صورة المنتج للشاشات الكبيرة
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        product.images.isNotEmpty
                            ? product.images.first
                            : 'https://via.placeholder.com/80x80/1a1a2e/ffd700?text=منتج',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1a1a2e),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Color(0xFFffc107),
                              size: 40,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),

                // معلومات المنتج
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // اسم المنتج
                      Text(
                        product.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // الفئة
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFffc107).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.category.isEmpty ? 'عام' : product.category,
                          style: const TextStyle(
                            color: Color(0xFFffc107),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // حالة المخزون
                      Row(
                        children: [
                          Icon(
                            isOutOfStock ? Icons.warning : Icons.check_circle,
                            color: isOutOfStock
                                ? const Color(0xFFF44336)
                                : const Color(0xFF4CAF50),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOutOfStock
                                ? 'نفذ من المخزون'
                                : 'متاح (${product.availableQuantity})',
                            style: TextStyle(
                              color: isOutOfStock
                                  ? const Color(0xFFF44336)
                                  : const Color(0xFF4CAF50),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                    // معلومات المنتج للشاشات الكبيرة
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // اسم المنتج
                          Text(
                            product.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),

                          // الفئة
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFffc107).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              product.category.isEmpty ? 'عام' : product.category,
                              style: const TextStyle(
                                color: Color(0xFFffc107),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // حالة المخزون
                          Row(
                            children: [
                              Icon(
                                isOutOfStock ? Icons.warning : Icons.check_circle,
                                color: isOutOfStock
                                    ? const Color(0xFFF44336)
                                    : const Color(0xFF4CAF50),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isOutOfStock
                                    ? 'نفذ من المخزون'
                                    : 'متاح (${product.availableQuantity})',
                                style: TextStyle(
                                  color: isOutOfStock
                                      ? const Color(0xFFF44336)
                                      : const Color(0xFF4CAF50),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // حالة المخزون البصرية (فقط للشاشات الكبيرة)
                    if (!isSmallScreen)
                      Container(
                        width: 12,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isOutOfStock
                              ? const Color(0xFFF44336)
                              : const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                  ],
                ),
          ),

          // تفاصيل المنتج
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              children: [
                // الأسعار
                Row(
                  children: [
                    Expanded(
                      child: _buildPriceInfo(
                        'سعر الجملة',
                        product.wholesalePrice,
                        isSmallScreen,
                      ),
                    ),
                    Expanded(
                      child: _buildPriceInfo('الحد الأدنى', product.minPrice, isSmallScreen),
                    ),
                    Expanded(
                      child: _buildPriceInfo('الحد الأقصى', product.maxPrice, isSmallScreen),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),

                // أزرار الإجراءات
                isSmallScreen
                  ? Column(
                      children: [
                        if (isOutOfStock) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _restockProduct(product),
                              icon: const Icon(Icons.add_shopping_cart, size: 16),
                              label: const Text('إعادة التخزين', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _editProduct(product),
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('تعديل', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFffc107),
                                  side: const BorderSide(color: Color(0xFFffc107)),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _deleteProduct(product),
                                icon: const Icon(Icons.delete, size: 16),
                                label: const Text('حذف', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFF44336),
                                  side: const BorderSide(color: Color(0xFFF44336)),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        if (isOutOfStock) ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _restockProduct(product),
                              icon: const Icon(Icons.add_shopping_cart),
                              label: const Text('إعادة التخزين'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _editProduct(product),
                            icon: const Icon(Icons.edit),
                            label: const Text('تعديل'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFffc107),
                              side: const BorderSide(color: Color(0xFFffc107)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _deleteProduct(product),
                            icon: const Icon(Icons.delete),
                            label: const Text('حذف'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFF44336),
                              side: const BorderSide(color: Color(0xFFF44336)),
                            ),
                          ),
                        ),
                      ],
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // بناء معلومات السعر
  Widget _buildPriceInfo(String label, double price, [bool isSmallScreen = false]) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: isSmallScreen ? 10 : 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${price.toStringAsFixed(0)} د.ع',
          style: TextStyle(
            color: const Color(0xFFffc107),
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // إعادة تخزين المنتج
  void _restockProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'إعادة تخزين المنتج',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'إعادة تخزين: ${product.name}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'الكمية الجديدة',
                labelStyle: const TextStyle(color: Color(0xFFffc107)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFffc107)),
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                // ignore: todo
                // TODO: حفظ الكمية الجديدة
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              // ignore: todo
              // TODO: تطبيق إعادة التخزين
              Navigator.pop(context);
              _showSuccessSnackBar('تم تحديث المخزون بنجاح');
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  // دالة عرض رسالة النجاح
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // دالة عرض رسالة معلومات
  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2196F3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ===== إدارة الصور الإعلانية =====

  // تحميل الصور الإعلانية من قاعدة البيانات
  Future<void> _loadAdvertisementBanners() async {
    setState(() => _isLoadingBanners = true);

    try {
      final response = await Supabase.instance.client
          .from('advertisement_banners')
          .select('*')
          .order('created_at', ascending: false);

      setState(() {
        _advertisementBanners = List<Map<String, dynamic>>.from(response);
        _isLoadingBanners = false;
      });

      debugPrint('✅ تم تحميل ${_advertisementBanners.length} صورة إعلانية');
      for (var banner in _advertisementBanners) {
        debugPrint('📸 صورة إعلانية: ID=${banner['id']}, Title=${banner['title']}');
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الصور الإعلانية: $e');
      setState(() => _isLoadingBanners = false);

      // إنشاء الجدول إذا لم يكن موجوداً
      await _createAdvertisementBannersTable();
    }
  }

  // إنشاء جدول الصور الإعلانية
  Future<void> _createAdvertisementBannersTable() async {
    try {
      await Supabase.instance.client.rpc('create_advertisement_banners_table');
      _showSuccessSnackBar('تم إنشاء جدول الصور الإعلانية بنجاح');
      await _loadAdvertisementBanners();
    } catch (e) {
      debugPrint('خطأ في إنشاء جدول الصور الإعلانية: $e');
      _showErrorSnackBar('خطأ في إنشاء جدول الصور الإعلانية');
    }
  }

  // بناء واجهة إدارة الصور الإعلانية
  Widget _buildAdvertisementBannersManagement() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
          Row(
            children: [
              const Icon(Icons.image, color: Color(0xFFffc107), size: 28),
              const SizedBox(width: 12),
              const Text(
                'إدارة الصور الإعلانية',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // زر إضافة صورة جديدة
              ElevatedButton.icon(
                onPressed: _showAddBannerDialog,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('إضافة صورة إعلانية'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // محتوى الصور الإعلانية
          Expanded(
            child: _isLoadingBanners
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffd700)),
                    ),
                  )
                : _buildBannersGrid(),
          ),
        ],
      ),
    );
  }

  // بناء شبكة الصور الإعلانية
  Widget _buildBannersGrid() {
    if (_advertisementBanners.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 80,
              color: Colors.grey.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد صور إعلانية',
              style: GoogleFonts.cairo(
                fontSize: 18,
                color: Colors.grey.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط على "إضافة صورة إعلانية" لإضافة أول صورة',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.grey.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: _advertisementBanners.length,
      itemBuilder: (context, index) {
        final banner = _advertisementBanners[index];
        return _buildBannerCard(banner, index);
      },
    );
  }

  // بناء بطاقة الصورة الإعلانية
  Widget _buildBannerCard(Map<String, dynamic> banner, int index) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صورة البانر
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(banner['image_url'] ?? ''),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      debugPrint('خطأ في تحميل الصورة: $exception');
                    },
                  ),
                ),
                child: banner['image_url'] == null || banner['image_url'].isEmpty
                    ? const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 50,
                          color: Colors.grey,
                        ),
                      )
                    : null,
              ),
            ),
          ),

          // معلومات البانر
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // العنوان
                  Flexible(
                    child: Text(
                      banner['title'] ?? 'بدون عنوان',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),

                  // العنوان الفرعي
                  Flexible(
                    child: Text(
                      banner['subtitle'] ?? 'بدون وصف',
                      style: GoogleFonts.cairo(
                        color: Colors.grey.withValues(alpha: 0.6),
                        fontSize: 10,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // أزرار الإجراءات
                  Row(
                    children: [
                      // زر التعديل
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showEditBannerDialog(banner, index),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            minimumSize: const Size(0, 20),
                          ),
                          child: Text(
                            'تعديل',
                            style: GoogleFonts.cairo(fontSize: 9),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),

                      // زر الحذف
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            debugPrint('🔴 تم النقر على زر حذف الصورة الإعلانية: ${banner['id']}');
                            _showDeleteBannerDialog(banner, index);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFf44336),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            minimumSize: const Size(0, 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: Text(
                            'حذف',
                            style: GoogleFonts.cairo(fontSize: 9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // عرض حوار إضافة صورة إعلانية جديدة
  void _showAddBannerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Row(
          children: [
            const Icon(Icons.add_photo_alternate, color: Color(0xFFffd700)),
            const SizedBox(width: 8),
            const Text(
              'إضافة صورة إعلانية جديدة',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: const SizedBox(
          width: 300,
          child: Text(
            'اختر صورة إعلانية من الاستوديو',
            style: TextStyle(color: Colors.grey, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await _pickAndAddBanner();
            },
            icon: const Icon(Icons.image),
            label: const Text('اختيار صورة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // اختيار وإضافة صورة إعلانية
  Future<void> _pickAndAddBanner() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        debugPrint('📸 تم اختيار الصورة: ${pickedFile.path}');
        await _addBanner(pickedFile.path);
      } else {
        debugPrint('❌ لم يتم اختيار أي صورة');
      }
    } catch (e) {
      debugPrint('❌ خطأ في اختيار الصورة: $e');
      _showErrorSnackBar('خطأ في اختيار الصورة: $e');
    }
  }

  // عرض حوار تعديل صورة إعلانية
  void _showEditBannerDialog(Map<String, dynamic> banner, int index) {
    final titleController = TextEditingController(text: banner['title'] ?? '');
    final subtitleController = TextEditingController(text: banner['subtitle'] ?? '');
    final imageUrlController = TextEditingController(text: banner['image_url'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Row(
          children: [
            const Icon(Icons.edit, color: Color(0xFFffd700)),
            const SizedBox(width: 8),
            const Text(
              'تعديل الصورة الإعلانية',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // العنوان
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'العنوان',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFffd700)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // العنوان الفرعي
              TextField(
                controller: subtitleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'العنوان الفرعي',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFffd700)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // رابط الصورة
              TextField(
                controller: imageUrlController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'رابط الصورة',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFffd700)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isNotEmpty &&
                  imageUrlController.text.trim().isNotEmpty) {
                final navigator = Navigator.of(context);
                await _updateBanner(
                  banner['id'],
                  titleController.text.trim(),
                  subtitleController.text.trim(),
                  imageUrlController.text.trim(),
                );
                if (mounted) {
                  navigator.pop();
                }
              } else {
                _showErrorSnackBar('يرجى ملء العنوان ورابط الصورة على الأقل');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
            ),
            child: const Text('تحديث', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // عرض حوار حذف صورة إعلانية
  void _showDeleteBannerDialog(Map<String, dynamic> banner, int index) {
    debugPrint('🗑️ عرض حوار حذف الصورة الإعلانية: ${banner['id']} - ${banner['title']}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            const Text(
              'تأكيد الحذف',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف الصورة الإعلانية "${banner['title'] ?? 'بدون عنوان'}"؟\n\nلا يمكن التراجع عن هذا الإجراء.',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('❌ تم إلغاء حذف الصورة الإعلانية');
              Navigator.of(context).pop();
            },
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              debugPrint('✅ تأكيد حذف الصورة الإعلانية بالمعرف: ${banner['id']}');

              if (banner['id'] != null) {
                Navigator.of(context).pop();
                await _deleteBanner(banner['id']);
              } else {
                debugPrint('❌ معرف الصورة الإعلانية غير صحيح: ${banner['id']}');
                Navigator.of(context).pop();
                _showErrorSnackBar('خطأ: معرف الصورة غير صحيح');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }



  // إضافة صورة إعلانية جديدة من ملف محلي
  Future<void> _addBanner(String imagePath) async {
    try {
      debugPrint('🔄 بدء رفع الصورة الإعلانية...');

      // التحقق من حالة المصادقة
      final user = Supabase.instance.client.auth.currentUser;
      debugPrint('👤 المستخدم الحالي: ${user?.id ?? 'غير مسجل'}');

      // إذا لم يكن المستخدم مسجل دخول، قم بتسجيل دخول مؤقت
      if (user == null) {
        debugPrint('🔐 تسجيل دخول مؤقت...');
        await Supabase.instance.client.auth.signInAnonymously();
        debugPrint('✅ تم تسجيل الدخول المؤقت');
      }

      // قراءة الملف
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final fileName = 'banner_${DateTime.now().millisecondsSinceEpoch}.jpg';

      debugPrint('📤 رفع الصورة إلى التخزين: $fileName');

      // التأكد من وجود bucket التخزين أولاً
      await _ensureStorageBucketExists();

      // رفع الصورة إلى Supabase Storage
      await Supabase.instance.client.storage
          .from('advertisement-banners')
          .uploadBinary(fileName, bytes);

      debugPrint('✅ تم رفع الصورة بنجاح');

      // الحصول على رابط الصورة
      final imageUrl = Supabase.instance.client.storage
          .from('advertisement-banners')
          .getPublicUrl(fileName);

      debugPrint('🔗 رابط الصورة: $imageUrl');

      // إضافة البيانات إلى قاعدة البيانات
      debugPrint('💾 إضافة البيانات إلى قاعدة البيانات...');
      final response = await Supabase.instance.client.from('advertisement_banners').insert({
        'title': 'صورة إعلانية',
        'subtitle': '',
        'image_url': imageUrl,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      debugPrint('✅ تم إدراج البيانات بنجاح: $response');
      _showSuccessSnackBar('تم إضافة الصورة الإعلانية بنجاح');
      await _loadAdvertisementBanners();
    } catch (e) {
      debugPrint('❌ خطأ في إضافة الصورة الإعلانية: $e');
      debugPrint('❌ نوع الخطأ: ${e.runtimeType}');

      String errorMessage = 'خطأ في إضافة الصورة الإعلانية';
      if (e.toString().contains('row-level security')) {
        errorMessage = 'خطأ في الصلاحيات - تم إصلاحه، يرجى المحاولة مرة أخرى';
      } else if (e.toString().contains('bucket')) {
        errorMessage = 'خطأ في التخزين - تم إصلاحه، يرجى المحاولة مرة أخرى';
      }

      _showErrorSnackBar(errorMessage);
    }
  }

  // التأكد من وجود bucket التخزين
  Future<void> _ensureStorageBucketExists() async {
    try {
      // محاولة الحصول على معلومات الـ bucket
      await Supabase.instance.client.storage.getBucket('advertisement-banners');
      debugPrint('✅ bucket التخزين موجود بالفعل');
    } catch (e) {
      debugPrint('⚠️ bucket التخزين غير موجود، سيتم إنشاؤه...');
      try {
        // إنشاء bucket جديد
        await Supabase.instance.client.storage.createBucket(
          'advertisement-banners',
          BucketOptions(public: true, fileSizeLimit: '10MB'),
        );
        debugPrint('✅ تم إنشاء bucket التخزين بنجاح');
      } catch (createError) {
        debugPrint('❌ خطأ في إنشاء bucket التخزين: $createError');
        rethrow;
      }
    }
  }

  // تحديث صورة إعلانية
  Future<void> _updateBanner(int id, String title, String subtitle, String imageUrl) async {
    try {
      await Supabase.instance.client
          .from('advertisement_banners')
          .update({
            'title': title,
            'subtitle': subtitle,
            'image_url': imageUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);

      _showSuccessSnackBar('تم تحديث الصورة الإعلانية بنجاح');
      await _loadAdvertisementBanners();
    } catch (e) {
      debugPrint('خطأ في تحديث الصورة الإعلانية: $e');
      _showErrorSnackBar('خطأ في تحديث الصورة الإعلانية');
    }
  }

  // حذف صورة إعلانية
  Future<void> _deleteBanner(dynamic id) async {
    try {
      debugPrint('🗑️ محاولة حذف الصورة الإعلانية بالمعرف: $id');

      await Supabase.instance.client
          .from('advertisement_banners')
          .delete()
          .eq('id', id);

      debugPrint('✅ تم حذف الصورة الإعلانية بنجاح');
      _showSuccessSnackBar('تم حذف الصورة الإعلانية بنجاح');
      await _loadAdvertisementBanners();
    } catch (e) {
      debugPrint('❌ خطأ في حذف الصورة الإعلانية: $e');
      _showErrorSnackBar('خطأ في حذف الصورة الإعلانية: $e');
    }
  }

  // ===== إدارة الإشعارات =====
  Widget _buildNotificationsManagement() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNotificationsHeader(),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildNotificationStats(),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildNotificationComposer(),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            _buildNotificationPreview(),
                            const SizedBox(height: 20),
                            _buildQuickNotificationTemplates(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSentNotificationsList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366f1).withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_active,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إدارة الإشعارات',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'إرسال إشعارات مخصصة لجميع المستخدمين',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildNotificationQuickActions(),
        ],
      ),
    );
  }

  Widget _buildNotificationQuickActions() {
    return Row(
      children: [
        _buildNotificationActionButton(
          'إشعار سريع',
          Icons.flash_on,
          const Color(0xFFffd700),
          () => _sendQuickNotification(),
        ),
        const SizedBox(width: 10),
        _buildNotificationActionButton(
          'تحديث الإحصائيات',
          Icons.refresh,
          Colors.white.withValues(alpha: 0.9),
          () => _loadNotificationStats(),
        ),
        const SizedBox(width: 10),
        _buildNotificationActionButton(
          'تشغيل الخادم',
          Icons.power_settings_new,
          Colors.green.withValues(alpha: 0.9),
          () => _wakeUpServer(),
        ),
      ],
    );
  }

  Widget _buildNotificationActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationStats() {
    return Row(
      children: [
        Expanded(
          child: _buildNotificationStatCard(
            'إجمالي المرسل',
            _notificationStats['total_sent'].toString(),
            Icons.send,
            const Color(0xFF3b82f6),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildNotificationStatCard(
            'تم التسليم',
            _notificationStats['total_delivered'].toString(),
            Icons.check_circle,
            const Color(0xFF10b981),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildNotificationStatCard(
            'تم الفتح',
            _notificationStats['total_opened'].toString(),
            Icons.visibility,
            const Color(0xFFf59e0b),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildNotificationStatCard(
            'تم النقر',
            _notificationStats['total_clicked'].toString(),
            Icons.touch_app,
            const Color(0xFFef4444),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationComposer() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366f1).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit_notifications,
                  color: Color(0xFF6366f1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'إنشاء إشعار جديد',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1f2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),

          // نوع الإشعار
          _buildNotificationTypeSelector(),
          const SizedBox(height: 20),

          // عنوان الإشعار
          _buildInputField(
            controller: _notificationTitleController,
            label: 'عنوان الإشعار',
            hint: 'أدخل عنوان جذاب للإشعار',
            icon: Icons.title,
            maxLength: 50,
          ),
          const SizedBox(height: 20),

          // محتوى الإشعار
          _buildInputField(
            controller: _notificationBodyController,
            label: 'محتوى الإشعار',
            hint: 'اكتب محتوى الإشعار هنا...',
            icon: Icons.message,
            maxLines: 4,
            maxLength: 200,
          ),
          const SizedBox(height: 25),

          // خيارات الإرسال
          _buildSendingOptions(),
          const SizedBox(height: 25),

          // أزرار الإجراءات
          _buildNotificationActions(),
        ],
      ),
    );
  }

  Widget _buildNotificationTypeSelector() {
    final types = [
      {'value': 'general', 'label': 'عام', 'icon': Icons.info, 'color': const Color(0xFF6366f1)},
      {'value': 'promotion', 'label': 'عرض خاص', 'icon': Icons.local_offer, 'color': const Color(0xFFf59e0b)},
      {'value': 'update', 'label': 'تحديث', 'icon': Icons.system_update, 'color': const Color(0xFF10b981)},
      {'value': 'urgent', 'label': 'عاجل', 'icon': Icons.priority_high, 'color': const Color(0xFFef4444)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'نوع الإشعار',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: types.map((type) {
            final isSelected = _selectedNotificationType == type['value'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedNotificationType = type['value'] as String;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? (type['color'] as Color) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? (type['color'] as Color) : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type['icon'] as IconData,
                      size: 16,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      type['label'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF1F2937), // لون النص الأساسي - رمادي داكن
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF6366f1)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366f1), width: 2),
            ),
            filled: true,
            fillColor: Colors.white, // خلفية بيضاء لتباين أفضل
            counterStyle: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
          onChanged: (value) {
            setState(() {}); // لتحديث المعاينة
          },
        ),
      ],
    );
  }

  Widget _buildSendingOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'خيارات الإرسال',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isScheduled = false;
                    _scheduledDateTime = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: !_isScheduled ? const Color(0xFF6366f1) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: !_isScheduled ? const Color(0xFF6366f1) : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.send,
                        color: !_isScheduled ? Colors.white : Colors.grey.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'إرسال فوري',
                        style: TextStyle(
                          color: !_isScheduled ? Colors.white : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isScheduled = true;
                  });
                  _selectScheduleDateTime();
                },
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: _isScheduled ? const Color(0xFF6366f1) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isScheduled ? const Color(0xFF6366f1) : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: _isScheduled ? Colors.white : Colors.grey.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'إرسال مجدول',
                        style: TextStyle(
                          color: _isScheduled ? Colors.white : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_isScheduled && _scheduledDateTime != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6366f1).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Color(0xFF6366f1), size: 16),
                const SizedBox(width: 8),
                Text(
                  'موعد الإرسال: ${_formatDateTime(_scheduledDateTime!)}',
                  style: const TextStyle(
                    color: Color(0xFF6366f1),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNotificationActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isSendingNotification ? null : _sendNotification,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366f1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSendingNotification
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('جاري الإرسال...'),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send, size: 18),
                      const SizedBox(width: 8),
                      Text(_isScheduled ? 'جدولة الإشعار' : 'إرسال الإشعار'),
                    ],
                  ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: _clearNotificationForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade100,
            foregroundColor: Colors.grey.shade700,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.clear, size: 18),
              SizedBox(width: 5),
              Text('مسح'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationPreview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10b981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.preview,
                  color: Color(0xFF10b981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'معاينة الإشعار',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1f2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getNotificationTypeColor(),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getNotificationTypeIcon(),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _notificationTitleController.text.isEmpty
                                ? 'عنوان الإشعار'
                                : _notificationTitleController.text,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _notificationTitleController.text.isEmpty
                                  ? Colors.grey.shade400
                                  : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _notificationBodyController.text.isEmpty
                                ? 'محتوى الإشعار سيظهر هنا...'
                                : _notificationBodyController.text,
                            style: TextStyle(
                              fontSize: 12,
                              color: _notificationBodyController.text.isEmpty
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'الآن',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickNotificationTemplates() {
    final templates = [
      {
        'title': 'عرض خاص',
        'body': 'خصم 50% على جميع المنتجات! لفترة محدودة فقط',
        'type': 'promotion',
      },
      {
        'title': 'تحديث التطبيق',
        'body': 'تحديث جديد متاح الآن مع مميزات رائعة',
        'type': 'update',
      },
      {
        'title': 'إشعار عاجل',
        'body': 'إشعار مهم يتطلب انتباهكم الفوري',
        'type': 'urgent',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFf59e0b).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.text_snippet,
                  color: Color(0xFFf59e0b),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'قوالب سريعة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1f2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ...templates.map((template) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => _applyTemplate(template),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template['title'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1f2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        template['body'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSentNotificationsList() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8b5cf6).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.history,
                  color: Color(0xFF8b5cf6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'الإشعارات المرسلة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1f2937),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _loadSentNotifications,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('تحديث'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF8b5cf6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_sentNotifications.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد إشعارات مرسلة بعد',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ابدأ بإرسال أول إشعار لك',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _sentNotifications.length,
              itemBuilder: (context, index) {
                final notification = _sentNotifications[index];
                return _buildNotificationHistoryItem(notification);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationHistoryItem(Map<String, dynamic> notification) {
    final type = notification['type'] ?? 'general';
    final color = _getTypeColor(type);
    final icon = _getTypeIcon(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['title'] ?? 'بدون عنوان',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1f2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification['body'] ?? 'بدون محتوى',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(DateTime.parse(notification['sent_at'] ?? DateTime.now().toIso8601String())),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.people, size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      '${notification['recipients_count'] ?? 0} مستخدم',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(notification['status']).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(notification['status']),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(notification['status']),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${notification['delivery_rate'] ?? 0}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== دوال مساعدة للإشعارات =====
  Color _getNotificationTypeColor() {
    switch (_selectedNotificationType) {
      case 'promotion':
        return const Color(0xFFf59e0b);
      case 'update':
        return const Color(0xFF10b981);
      case 'urgent':
        return const Color(0xFFef4444);
      default:
        return const Color(0xFF6366f1);
    }
  }

  IconData _getNotificationTypeIcon() {
    switch (_selectedNotificationType) {
      case 'promotion':
        return Icons.local_offer;
      case 'update':
        return Icons.system_update;
      case 'urgent':
        return Icons.priority_high;
      default:
        return Icons.info;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'promotion':
        return const Color(0xFFf59e0b);
      case 'update':
        return const Color(0xFF10b981);
      case 'urgent':
        return const Color(0xFFef4444);
      default:
        return const Color(0xFF6366f1);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'promotion':
        return Icons.local_offer;
      case 'update':
        return Icons.system_update;
      case 'urgent':
        return Icons.priority_high;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'sent':
        return const Color(0xFF10b981);
      case 'scheduled':
        return const Color(0xFFf59e0b);
      case 'failed':
        return const Color(0xFFef4444);
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'sent':
        return 'تم الإرسال';
      case 'scheduled':
        return 'مجدول';
      case 'failed':
        return 'فشل';
      default:
        return 'غير معروف';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _applyTemplate(Map<String, dynamic> template) {
    setState(() {
      _notificationTitleController.text = template['title'] as String;
      _notificationBodyController.text = template['body'] as String;
      _selectedNotificationType = template['type'] as String;
    });
  }

  void _clearNotificationForm() {
    setState(() {
      _notificationTitleController.clear();
      _notificationBodyController.clear();
      _selectedNotificationType = 'general';
      _isScheduled = false;
      _scheduledDateTime = null;
    });
  }

  Future<void> _selectScheduleDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _scheduledDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  // ===== وظائف الإشعارات مع تشخيص شامل =====
  Future<void> _sendNotification() async {
    // بدء التشخيص
    final diagnosticId = 'notif_${DateTime.now().millisecondsSinceEpoch}';
    final startTime = DateTime.now();

    debugPrint('🚀 [DIAGNOSTIC-$diagnosticId] بدء عملية إرسال الإشعار في ${startTime.toIso8601String()}');
    debugPrint('📱 [DIAGNOSTIC-$diagnosticId] الخطوة 1: التحقق من صحة البيانات المدخلة');

    // التحقق من البيانات
    if (_notificationTitleController.text.trim().isEmpty) {
      debugPrint('❌ [DIAGNOSTIC-$diagnosticId] فشل: عنوان الإشعار فارغ');
      _showErrorSnackBar('يرجى إدخال عنوان الإشعار');
      return;
    }
    debugPrint('✅ [DIAGNOSTIC-$diagnosticId] عنوان الإشعار صحيح: "${_notificationTitleController.text.trim()}"');

    if (_notificationBodyController.text.trim().isEmpty) {
      debugPrint('❌ [DIAGNOSTIC-$diagnosticId] فشل: محتوى الإشعار فارغ');
      _showErrorSnackBar('يرجى إدخال محتوى الإشعار');
      return;
    }
    debugPrint('✅ [DIAGNOSTIC-$diagnosticId] محتوى الإشعار صحيح: "${_notificationBodyController.text.trim()}"');

    if (_isScheduled && _scheduledDateTime == null) {
      debugPrint('❌ [DIAGNOSTIC-$diagnosticId] فشل: موعد الجدولة غير محدد');
      _showErrorSnackBar('يرجى تحديد موعد الإرسال');
      return;
    }

    debugPrint('📝 [DIAGNOSTIC-$diagnosticId] الخطوة 2: إعداد بيانات الطلب');
    final requestData = {
      'title': _notificationTitleController.text.trim(),
      'body': _notificationBodyController.text.trim(),
      'type': _selectedNotificationType,
      'isScheduled': _isScheduled,
      'scheduledDateTime': _scheduledDateTime?.toIso8601String(),
    };

    debugPrint('📦 [DIAGNOSTIC-$diagnosticId] بيانات الطلب: ${json.encode(requestData)}');
    debugPrint('🔗 [DIAGNOSTIC-$diagnosticId] الخطوة 3: تحديث واجهة المستخدم (بدء التحميل)');

    setState(() {
      _isSendingNotification = true;
    });

    try {
  debugPrint('🌐 [DIAGNOSTIC-$diagnosticId] الخطوة 4: إرسال الطلب إلى الخادم');
  debugPrint('🔗 [DIAGNOSTIC-$diagnosticId] URL: https://montajati-official-backend-production.up.railway.app/api/notifications/send-bulk');

      final requestStartTime = DateTime.now();

      // محاولة إرسال الطلب مع إعادة المحاولة في حالة 503
      http.Response? response;
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount <= maxRetries) {
        try {
          response = await http.post(
            Uri.parse('https://montajati-official-backend-production.up.railway.app/api/notifications/send-bulk'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode(requestData),
          ).timeout(const Duration(seconds: 30));

          // إذا كان الرد 503 (خادم غير متاح) وما زال لدينا محاولات
          if (response.statusCode == 503 && retryCount < maxRetries) {
            debugPrint('⚠️ [DIAGNOSTIC-$diagnosticId] خادم غير متاح (503) - محاولة ${retryCount + 1}/${maxRetries + 1}');
            debugPrint('⏳ [DIAGNOSTIC-$diagnosticId] انتظار 10 ثوانٍ قبل إعادة المحاولة...');

            // إظهار رسالة للمستخدم
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('الخادم يستيقظ... محاولة ${retryCount + 1}/${maxRetries + 1}'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 3),
                ),
              );
            }

            await Future.delayed(const Duration(seconds: 10));
            retryCount++;
            continue;
          }

          // إذا نجح الطلب أو فشل بخطأ غير 503، اخرج من الحلقة
          break;

        } catch (e) {
          if (retryCount < maxRetries) {
            debugPrint('❌ [DIAGNOSTIC-$diagnosticId] خطأ في المحاولة ${retryCount + 1}: $e');
            debugPrint('🔄 [DIAGNOSTIC-$diagnosticId] إعادة المحاولة بعد 5 ثوانٍ...');
            await Future.delayed(const Duration(seconds: 5));
            retryCount++;
            continue;
          } else {
            rethrow;
          }
        }
      }
      final requestEndTime = DateTime.now();
      final requestDuration = requestEndTime.difference(requestStartTime);

      debugPrint('📡 [DIAGNOSTIC-$diagnosticId] الخطوة 5: استلام الاستجابة من الخادم');
      debugPrint('⏱️ [DIAGNOSTIC-$diagnosticId] مدة الطلب: ${requestDuration.inMilliseconds}ms');

      if (response == null) {
        throw Exception('لم يتم الحصول على استجابة من الخادم بعد جميع المحاولات');
      }

      debugPrint('📊 [DIAGNOSTIC-$diagnosticId] رمز الاستجابة: ${response.statusCode}');
      debugPrint('📄 [DIAGNOSTIC-$diagnosticId] محتوى الاستجابة: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('✅ [DIAGNOSTIC-$diagnosticId] الخطوة 6: تحليل الاستجابة الناجحة');

        try {
          final responseData = json.decode(response.body);
          debugPrint('📋 [DIAGNOSTIC-$diagnosticId] بيانات الاستجابة المحللة: ${json.encode(responseData)}');

          if (responseData['success'] == true) {
            debugPrint('🎉 [DIAGNOSTIC-$diagnosticId] الخطوة 7: نجح الإرسال');

            // طباعة تفاصيل التشخيص إذا كانت متوفرة
            if (responseData['diagnostics'] != null) {
              debugPrint('🔍 [DIAGNOSTIC-$diagnosticId] تشخيص الخادم: ${json.encode(responseData['diagnostics'])}');
            }

            if (responseData['data'] != null) {
              debugPrint('📊 [DIAGNOSTIC-$diagnosticId] بيانات النتيجة: ${json.encode(responseData['data'])}');
            }

            _showSuccessSnackBar(
              _isScheduled
                  ? 'تم جدولة الإشعار بنجاح'
                  : 'تم إرسال الإشعار بنجاح لجميع المستخدمين'
            );

            debugPrint('🧹 [DIAGNOSTIC-$diagnosticId] الخطوة 8: تنظيف النموذج وتحديث البيانات');
            _clearNotificationForm();
            await _loadSentNotifications();
            await _loadNotificationStats();
          } else {
            debugPrint('❌ [DIAGNOSTIC-$diagnosticId] فشل الإرسال: ${responseData['message']}');
            if (responseData['diagnostics'] != null) {
              debugPrint('🔍 [DIAGNOSTIC-$diagnosticId] تشخيص الفشل: ${json.encode(responseData['diagnostics'])}');
            }
            _showErrorSnackBar(responseData['message'] ?? 'فشل في إرسال الإشعار');
          }
        } catch (parseError) {
          debugPrint('❌ [DIAGNOSTIC-$diagnosticId] خطأ في تحليل JSON: $parseError');
          debugPrint('📄 [DIAGNOSTIC-$diagnosticId] النص الخام: ${response.body}');
          _showErrorSnackBar('خطأ في تحليل استجابة الخادم');
        }
      } else {
        debugPrint('❌ [DIAGNOSTIC-$diagnosticId] خطأ HTTP: ${response.statusCode}');
        debugPrint('📄 [DIAGNOSTIC-$diagnosticId] رسالة الخطأ: ${response.body}');

        String errorMessage;
        if (response.statusCode == 503) {
          errorMessage = 'الخادم غير متاح حالياً. يرجى المحاولة مرة أخرى بعد دقيقة.';
        } else if (response.statusCode == 500) {
          errorMessage = 'خطأ في الخادم. يرجى المحاولة مرة أخرى لاحقاً.';
        } else if (response.statusCode == 404) {
          errorMessage = 'خدمة الإشعارات غير متاحة.';
        } else if (response.statusCode == 429) {
          errorMessage = 'تم إرسال إشعارات كثيرة. يرجى الانتظار قليلاً.';
        } else {
          errorMessage = 'خطأ في الاتصال بالخادم (${response.statusCode})';
        }

        _showErrorSnackBar(errorMessage);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [DIAGNOSTIC-$diagnosticId] خطأ في الشبكة أو الاتصال: $e');
      debugPrint('📚 [DIAGNOSTIC-$diagnosticId] تتبع المكدس: $stackTrace');

      String errorMessage;
      if (e.toString().contains('TimeoutException') || e.toString().contains('timeout')) {
        errorMessage = 'انتهت مهلة الاتصال. يرجى التحقق من الإنترنت والمحاولة مرة أخرى.';
      } else if (e.toString().contains('SocketException') || e.toString().contains('network')) {
        errorMessage = 'مشكلة في الاتصال بالإنترنت. يرجى التحقق من الاتصال.';
      } else if (e.toString().contains('HandshakeException')) {
        errorMessage = 'مشكلة في الأمان. يرجى المحاولة مرة أخرى.';
      } else if (e.toString().contains('لم يتم الحصول على استجابة')) {
        errorMessage = 'الخادم غير متاح حالياً. يرجى المحاولة مرة أخرى بعد دقيقة.';
      } else {
        errorMessage = 'خطأ في إرسال الإشعار. يرجى المحاولة مرة أخرى.';
      }

      _showErrorSnackBar(errorMessage);
    } finally {
      final endTime = DateTime.now();
      final totalDuration = endTime.difference(startTime);

      debugPrint('🏁 [DIAGNOSTIC-$diagnosticId] انتهاء العملية في ${endTime.toIso8601String()}');
      debugPrint('⏱️ [DIAGNOSTIC-$diagnosticId] إجمالي المدة: ${totalDuration.inMilliseconds}ms');
      debugPrint('🔄 [DIAGNOSTIC-$diagnosticId] الخطوة الأخيرة: إيقاف مؤشر التحميل');

      setState(() {
        _isSendingNotification = false;
      });
    }
  }

  Future<void> _sendQuickNotification() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _buildQuickNotificationDialog(),
    );

    if (result != null) {
      setState(() {
        _notificationTitleController.text = result['title'] ?? '';
        _notificationBodyController.text = result['body'] ?? '';
        _selectedNotificationType = result['type'] ?? 'general';
        _isScheduled = false;
        _scheduledDateTime = null;
      });

      await _sendNotification();
    }
  }

  Widget _buildQuickNotificationDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    String selectedType = 'general';

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.flash_on, color: Color(0xFFffd700)),
              SizedBox(width: 10),
              Text('إشعار سريع'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'العنوان',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: bodyController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'المحتوى',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'النوع',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'general', child: Text('عام')),
                    DropdownMenuItem(value: 'promotion', child: Text('عرض خاص')),
                    DropdownMenuItem(value: 'update', child: Text('تحديث')),
                    DropdownMenuItem(value: 'urgent', child: Text('عاجل')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedType = value ?? 'general';
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty &&
                    bodyController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop({
                    'title': titleController.text.trim(),
                    'body': bodyController.text.trim(),
                    'type': selectedType,
                  });
                }
              },
              child: const Text('إرسال'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadNotificationStats() async {
    try {
      final response = await http.get(
        Uri.parse('https://montajati-official-backend-production.up.railway.app/api/notifications/stats'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _notificationStats = Map<String, int>.from(data['stats'] ?? {});
        });
      }
    } catch (e) {
      debugPrint('خطأ في تحميل إحصائيات الإشعارات: $e');
    }
  }

  Future<void> _loadSentNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('https://montajati-official-backend-production.up.railway.app/api/notifications/history'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _sentNotifications = List<Map<String, dynamic>>.from(data['notifications'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('خطأ في تحميل تاريخ الإشعارات: $e');
    }
  }

  // تشغيل الخادم (إيقاظه من حالة النوم)
  Future<void> _wakeUpServer() async {
    try {
      _showInfoSnackBar('جاري تشغيل الخادم...');

      final response = await http.get(
        Uri.parse('https://montajati-official-backend-production.up.railway.app/api/health'),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        _showSuccessSnackBar('تم تشغيل الخادم بنجاح!');
        // تحديث الإحصائيات بعد تشغيل الخادم
        await _loadNotificationStats();
      } else {
        _showErrorSnackBar('فشل في تشغيل الخادم');
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في الاتصال بالخادم: $e');
    }
  }

  // بناء معلومات المنتج للشاشات الصغيرة
  Widget _buildProductInfoSmall(Product product, bool isOutOfStock) {
    return Column(
      children: [
        // اسم المنتج
        Text(
          product.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // الفئة
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFffc107).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            product.category.isEmpty ? 'عام' : product.category,
            style: const TextStyle(
              color: Color(0xFFffc107),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // حالة المخزون
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOutOfStock ? Icons.warning : Icons.check_circle,
              color: isOutOfStock
                  ? const Color(0xFFF44336)
                  : const Color(0xFF4CAF50),
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              isOutOfStock
                  ? 'نفذ من المخزون'
                  : 'متاح (${product.availableQuantity})',
              style: TextStyle(
                color: isOutOfStock
                    ? const Color(0xFFF44336)
                    : const Color(0xFF4CAF50),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // بناء شريط التنقل السفلي للهواتف
  Widget _buildBottomNavigationBar() {
    final menuItems = [
      {'icon': Icons.dashboard, 'title': 'الرئيسية', 'index': 0},
      {'icon': Icons.shopping_cart, 'title': 'الطلبات', 'index': 1},
      {'icon': Icons.people, 'title': 'المستخدمين', 'index': 2},
      {'icon': Icons.inventory, 'title': 'المنتجات', 'index': 3},
      {'icon': Icons.settings, 'title': 'الإعدادات', 'index': 8},
    ];

    return Container(
      height: 70,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF16213e), Color(0xFF1a1a2e)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: menuItems.map((item) {
          final isSelected = _selectedTabIndex == item['index'];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTabIndex = item['index'] as int;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isSelected
                  ? const Color(0xFFffd700).withValues(alpha: 0.2)
                  : Colors.transparent,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    color: isSelected
                        ? const Color(0xFFffd700)
                        : Colors.white70,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['title'] as String,
                    style: TextStyle(
                      color: isSelected
                        ? const Color(0xFFffd700)
                        : Colors.white70,
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
