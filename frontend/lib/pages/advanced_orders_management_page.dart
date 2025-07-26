import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order_summary.dart';
import '../services/admin_service.dart';
import '../utils/order_status_helper.dart';
import 'advanced_order_details_page.dart';

class AdvancedOrdersManagementPage extends StatefulWidget {
  const AdvancedOrdersManagementPage({super.key});

  @override
  State<AdvancedOrdersManagementPage> createState() =>
      _AdvancedOrdersManagementPageState();
}

class _AdvancedOrdersManagementPageState
    extends State<AdvancedOrdersManagementPage>
    with TickerProviderStateMixin {
  // Controllers للرسوم المتحركة
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // بيانات الطلبات - النظام الجديد الذكي
  List<OrderSummary> _orderSummaries = []; // للعرض السريع
  List<AdminOrder> _loadedOrderDetails = []; // للتفاصيل المحملة
  Map<String, AdminOrder> _orderDetailsCache = {}; // تخزين مؤقت للتفاصيل
  List<OrderSummary> _filteredSummaries = [];
  List<AdminOrder> _selectedOrders = [];

  // حالة التحميل والعرض
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _isSelectMode = false;
  bool _isBatchConverting = false;

  // متغيرات pagination
  int _currentPage = 0;
  final int _pageSize = 30;
  bool _hasMoreData = true;
  String _currentView = 'table'; // table, grid, timeline
  String _sortBy = 'created_at';
  bool _sortAscending = false;

  // فلاتر البحث
  String _searchQuery = '';
  String _selectedStatus = 'all';
  String _selectedDateRange = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedUser = 'all';
  double _minAmount = 0;
  double _maxAmount = double.infinity;

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // إحصائيات
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadOrders();
    _setupScrollListener();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
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

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadMoreOrders();
      }
    });
  }

  Future<void> _loadOrders({bool loadMore = false}) async {
    try {
      if (loadMore) {
        setState(() => _isLoadingMore = true);
      } else {
        setState(() {
          _isLoading = true;
          _currentPage = 0;
          _hasMoreData = true;
          _orderSummaries.clear();
          _orderDetailsCache.clear(); // مسح التخزين المؤقت
        });
      }

      // 🚀 جلب ملخص الطلبات فقط (سريع جداً)
      final summaries = await AdminService.getOrdersSummary(
        statusFilter: _selectedStatus == 'all' ? null : _selectedStatus,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      setState(() {
        if (loadMore) {
          _orderSummaries.addAll(summaries);
          _isLoadingMore = false;
        } else {
          _orderSummaries = summaries;
          _isLoading = false;
        }

        // إذا كان عدد الطلبات أقل من حجم الصفحة، فلا توجد بيانات أكثر
        _hasMoreData = summaries.length == _pageSize;
        _currentPage++;
      });

      _applyFilters();
      if (!loadMore) {
        _calculateStatistics();
      }
    } catch (e) {
      setState(() {
        if (loadMore) {
          _isLoadingMore = false;
        } else {
          _isLoading = false;
        }
      });
      _showErrorSnackBar('خطأ في تحميل الطلبات: $e');
    }
  }

  Future<void> _loadMoreOrders() async {
    if (!_hasMoreData || _isLoadingMore) return;

    await _loadOrders(loadMore: true);
  }

  Future<void> _refreshOrders() async {
    setState(() => _isRefreshing = true);
    await _loadOrders();
    setState(() => _isRefreshing = false);
  }

  void _applyFilters() {
    // تطبيق الفلاتر بدون logs مفرطة
    final statusCounts = <String, int>{};
    for (final summary in _orderSummaries) {
      statusCounts[summary.status] = (statusCounts[summary.status] ?? 0) + 1;
    }

    setState(() {
      _filteredSummaries = _orderSummaries.where((summary) {
        // فلتر البحث
        bool matchesSearch =
            _searchQuery.isEmpty ||
            summary.orderNumber.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            summary.customerName.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            summary.customerPhone.contains(_searchQuery) ||
            summary.province.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            summary.city.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );

        // فلتر الحالة مع تشخيص محسن
        bool matchesStatus = _selectedStatus == 'all';

        if (!matchesStatus) {
          // تنظيف النص من المسافات والأحرف الخفية
          final cleanOrderStatus = summary.status.trim().toLowerCase();
          final cleanSelectedStatus = _selectedStatus.trim().toLowerCase();

          // فلترة مبسطة تطابق حالات قاعدة البيانات الفعلية
          switch (cleanSelectedStatus) {
            case 'active':
              // الطلبات النشطة (17 طلب موجود)
              matchesStatus = cleanOrderStatus == 'active';
              break;
            case 'in_delivery':
              // الطلبات قيد التوصيل (1 طلب موجود)
              matchesStatus = cleanOrderStatus == 'in_delivery';
              break;
            case 'delivered':
              // الطلبات المكتملة
              matchesStatus = cleanOrderStatus == 'delivered';
              break;
            case 'cancelled':
              // الطلبات الملغية
              matchesStatus = cleanOrderStatus == 'cancelled';
              break;
            default:
              // مطابقة مباشرة
              matchesStatus = cleanOrderStatus == cleanSelectedStatus;
          }
        }

        // إزالة الطباعة التشخيصية المفرطة لتحسين الأداء

        // فلتر التاريخ
        bool matchesDate =
            _selectedDateRange == 'all' || _isDateInRange(summary.createdAt);

        // فلتر المبلغ
        bool matchesAmount =
            summary.totalAmount >= _minAmount && summary.totalAmount <= _maxAmount;

        // فلتر المستخدم (تخطي لأنه غير متوفر في الملخص)
        bool matchesUser = true;

        return matchesSearch &&
            matchesStatus &&
            matchesDate &&
            matchesAmount &&
            matchesUser;
      }).toList();

      // تم تطبيق الفلاتر بنجاح

      // ترتيب النتائج
      _sortOrders();
    });
  }

  bool _isDateInRange(DateTime date) {
    switch (_selectedDateRange) {
      case 'today':
        return _isSameDay(date, DateTime.now());
      case 'yesterday':
        return _isSameDay(
          date,
          DateTime.now().subtract(const Duration(days: 1)),
        );
      case 'week':
        return date.isAfter(DateTime.now().subtract(const Duration(days: 7)));
      case 'month':
        return date.isAfter(DateTime.now().subtract(const Duration(days: 30)));
      case 'custom':
        if (_startDate != null && _endDate != null) {
          return date.isAfter(_startDate!) &&
              date.isBefore(_endDate!.add(const Duration(days: 1)));
        }
        return true;
      default:
        return true;
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _sortOrders() {
    _filteredSummaries.sort((a, b) {
      int comparison = 0;

      switch (_sortBy) {
        case 'created_at':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case 'order_number':
          comparison = a.orderNumber.compareTo(b.orderNumber);
          break;
        case 'customer_name':
          comparison = a.customerName.compareTo(b.customerName);
          break;
        case 'total':
          comparison = a.totalAmount.compareTo(b.totalAmount);
          break;
        case 'status':
          comparison = a.status.compareTo(b.status);
          break;
        case 'profit':
          // الربح غير متوفر في الملخص، استخدم المبلغ الإجمالي
          comparison = a.totalAmount.compareTo(b.totalAmount);
          break;
      }

      return _sortAscending ? comparison : -comparison;
    });
  }

  void _calculateStatistics() {
    // حساب الإحصائيات من ملخص الطلبات (سريع)
    if (_orderSummaries.isEmpty) {
      _statistics = {};
      return;
    }

    // حساب الإحصائيات الأساسية من ملخص الطلبات
    final totalOrders = _orderSummaries.length;
    final totalAmount = _orderSummaries.fold<double>(
      0,
      (sum, summary) => sum + summary.totalAmount,
    );
    // الربح غير متوفر في الملخص، سنحسبه لاحقاً عند الحاجة
    final totalProfit = 0.0;

    // حساب عدد الطلبات لكل حالة من جميع الطلبات
    final statusCounts = <String, int>{
      'نشط': 0,
      'قيد التوصيل': 0,
      'تم التوصيل': 0,
      'ملغي': 0,
    };

    for (final summary in _orderSummaries) {
      switch (summary.status.toLowerCase().trim()) {
        case 'active':
        case 'confirmed':
        case 'pending':
          statusCounts['نشط'] = (statusCounts['نشط'] ?? 0) + 1;
          break;
        case 'in_delivery':
        case 'processing':
        case 'shipped':
        case 'shipping':
          statusCounts['قيد التوصيل'] = (statusCounts['قيد التوصيل'] ?? 0) + 1;
          break;
        case 'delivered':
        case 'completed':
          statusCounts['تم التوصيل'] = (statusCounts['تم التوصيل'] ?? 0) + 1;
          break;
        case 'cancelled':
        case 'rejected':
          statusCounts['ملغي'] = (statusCounts['ملغي'] ?? 0) + 1;
          break;
      }
    }

    final averageAmount = totalOrders > 0 ? totalAmount / totalOrders : 0.0;
    final averageProfit = totalOrders > 0 ? totalProfit / totalOrders : 0.0;

    // تم حساب الإحصائيات بنجاح

    setState(() {
      _statistics = {
        'totalOrders': totalOrders,
        'totalAmount': totalAmount,
        'totalProfit': totalProfit,
        'averageAmount': averageAmount,
        'averageProfit': averageProfit,
        'statusCounts': statusCounts,
      };
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: _isLoading ? _buildLoadingScreen() : _buildMainContent(),
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
              'جاري تحميل الطلبات...',
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

  Widget _buildMainContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // الهيدر كجزء من المحتوى القابل للتمرير
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildToolbar(),
                  _buildQuickFilters(),
                  if (_statistics.isNotEmpty) _buildStatisticsBar(),
                ],
              ),
            ),
            // محتوى الطلبات
            SliverFillRemaining(
              child: _buildOrdersContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
      margin: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              color: Color(0xFFffd700),
              size: 28,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إدارة الطلبات المتطورة',
                  style: TextStyle(
                    color: Color(0xFF1a1a2e),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'نظام إدارة شامل ومتقدم للطلبات والعملاء',
                  style: TextStyle(color: Color(0xFF1a1a2e), fontSize: 14),
                ),
              ],
            ),
          ),
          _buildHeaderActions(),
        ],
      ),
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      children: [
        _buildHeaderButton(
          icon: Icons.refresh,
          label: 'تحديث',
          onPressed: _refreshOrders,
          isLoading: _isRefreshing,
        ),
        const SizedBox(width: 10),
        _buildHeaderButton(
          icon: Icons.add,
          label: 'طلب جديد',
          onPressed: _createNewOrder,
        ),
        const SizedBox(width: 10),
        _buildHeaderButton(
          icon: Icons.download,
          label: 'تصدير',
          onPressed: _showExportOptions,
        ),
        const SizedBox(width: 10),
        _buildHeaderButton(
          icon: Icons.schedule,
          label: 'الطلبات المجدولة',
          onPressed: _showScheduledOrders,
        ),
        const SizedBox(width: 10),
        _buildHeaderButton(
          icon: Icons.local_shipping,
          label: 'تحويل للتوصيل (20)',
          onPressed: _batchConvertToDelivery,
          isLoading: _isBatchConverting,
        ),
      ],
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFffd700),
                      ),
                    ),
                  )
                else
                  Icon(icon, color: const Color(0xFFffd700), size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFffd700),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(child: _buildSearchBar()),
          const SizedBox(width: 15),
          _buildViewToggle(),
          const SizedBox(width: 15),
          _buildSortOptions(),
          const SizedBox(width: 15),
          _buildFilterButton(),
          if (_isSelectMode) ...[
            const SizedBox(width: 15),
            _buildBulkActions(),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'البحث في الطلبات (رقم الطلب، اسم العميل، الهاتف...)',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFFffd700),
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: Color(0xFFffd700),
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    _applyFilters();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
          _applyFilters();
        },
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewButton(Icons.table_rows, 'table', 'جدول'),
          _buildViewButton(Icons.grid_view, 'grid', 'شبكة'),
          _buildViewButton(Icons.timeline, 'timeline', 'خط زمني'),
        ],
      ),
    );
  }

  Widget _buildViewButton(IconData icon, String view, String tooltip) {
    final isSelected = _currentView == view;
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFffd700) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: Icon(
            icon,
            color: isSelected
                ? const Color(0xFF1a1a2e)
                : const Color(0xFFffd700),
            size: 18,
          ),
          onPressed: () {
            setState(() => _currentView = view);
          },
        ),
      ),
    );
  }

  Widget _buildSortOptions() {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF16213e),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFffd700).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort, color: Color(0xFFffd700), size: 18),
            const SizedBox(width: 4),
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              color: const Color(0xFFffd700),
              size: 14,
            ),
          ],
        ),
      ),
      color: const Color(0xFF16213e),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      itemBuilder: (context) => [
        _buildSortMenuItem('created_at', 'تاريخ الإنشاء'),
        _buildSortMenuItem('order_number', 'رقم الطلب'),
        _buildSortMenuItem('customer_name', 'اسم العميل'),
        _buildSortMenuItem('total', 'المبلغ الإجمالي'),
        _buildSortMenuItem('status', 'الحالة'),
        _buildSortMenuItem('profit', 'الربح المتوقع'),
      ],
    );
  }

  PopupMenuItem<String> _buildSortMenuItem(String value, String label) {
    final isSelected = _sortBy == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.check : Icons.radio_button_unchecked,
            color: isSelected ? const Color(0xFFffd700) : Colors.white54,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFFffd700) : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      onTap: () {
        setState(() {
          if (_sortBy == value) {
            _sortAscending = !_sortAscending;
          } else {
            _sortBy = value;
            _sortAscending = true;
          }
        });
        _applyFilters();
      },
    );
  }

  Widget _buildFilterButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: const Icon(Icons.filter_list, color: Color(0xFFffd700), size: 18),
        onPressed: _showAdvancedFilters,
        tooltip: 'فلاتر متقدمة',
      ),
    );
  }

  Widget _buildBulkActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_selectedOrders.length} محدد',
            style: const TextStyle(
              color: Color(0xFFffd700),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Color(0xFFffd700),
              size: 16,
            ),
            color: const Color(0xFF16213e),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'update_status',
                child: Row(
                  children: [
                    Icon(Icons.update, color: Color(0xFFffd700), size: 16),
                    SizedBox(width: 8),
                    Text('تحديث الحالة', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_selected',
                child: Row(
                  children: [
                    Icon(Icons.download, color: Color(0xFFffd700), size: 16),
                    SizedBox(width: 8),
                    Text('تصدير المحدد', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete_selected',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Text('حذف المحدد', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: _handleBulkAction,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildQuickFilterChip('الكل', 'all', Icons.list),
            const SizedBox(width: 8),
            _buildQuickFilterChip('نشط', 'active', Icons.check_circle),
            const SizedBox(width: 8),
            _buildQuickFilterChip(
              'قيد التوصيل',
              'in_delivery',
              Icons.local_shipping,
            ),
            const SizedBox(width: 8),
            _buildQuickFilterChip('تم التوصيل', 'delivered', Icons.done_all),
            const SizedBox(width: 8),
            _buildQuickFilterChip('ملغي', 'cancelled', Icons.cancel),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedStatus == value;
    final color = OrderStatusHelper.getStatusColor(
      value == 'all' ? 'confirmed' : value,
    );

    // حساب عدد الطلبات لكل حالة
    int count = 0;
    if (value == 'all') {
      count = _orderSummaries.length;
    } else {
      final statusCounts =
          _statistics['statusCounts'] as Map<String, int>? ?? {};
      switch (value) {
        case 'active':
          count = statusCounts['نشط'] ?? 0;
          break;
        case 'in_delivery':
          count = statusCounts['قيد التوصيل'] ?? 0;
          break;
        case 'delivered':
          count = statusCounts['تم التوصيل'] ?? 0;
          break;
        case 'cancelled':
          count = statusCounts['ملغي'] ?? 0;
          break;
      }
    }

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.black : color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected ? Colors.black26 : color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: isSelected ? Colors.black : color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = value;
        });
        _applyFilters();
      },
      backgroundColor: const Color(0xFF16213e),
      selectedColor: color,
      checkmarkColor: Colors.black,
      side: BorderSide(color: color.withValues(alpha: 0.5), width: 1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildStatisticsBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildStatCard(
            'إجمالي الطلبات',
            _statistics['totalOrders']?.toString() ?? '0',
            Icons.shopping_cart,
            const Color(0xFF2196F3),
          ),
          const SizedBox(width: 15),
          _buildStatCard(
            'إجمالي المبيعات',
            '${(_statistics['totalAmount'] ?? 0).toStringAsFixed(0)} د.ع',
            Icons.attach_money,
            const Color(0xFF4CAF50),
          ),
          const SizedBox(width: 15),
          _buildStatCard(
            'إجمالي الأرباح',
            '${(_statistics['totalProfit'] ?? 0).toStringAsFixed(0)} د.ع',
            Icons.trending_up,
            const Color(0xFFFF9800),
          ),
          const SizedBox(width: 15),
          _buildStatCard(
            'متوسط الطلب',
            '${(_statistics['averageAmount'] ?? 0).toStringAsFixed(0)} د.ع',
            Icons.analytics,
            const Color(0xFF9C27B0),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersContent() {
    if (_filteredSummaries.isEmpty) {
      return _buildEmptyState();
    }

    switch (_currentView) {
      case 'grid':
        return _buildGridView();
      case 'timeline':
        return _buildTimelineView();
      default:
        return _buildTableView();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF16213e),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFffd700).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.inbox_outlined,
              color: Color(0xFFffd700),
              size: 64,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'لا توجد طلبات',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'لم يتم العثور على طلبات تطابق البحث'
                : 'لم يتم إنشاء أي طلبات بعد',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _searchQuery.isNotEmpty
                ? _clearFilters
                : _createNewOrder,
            icon: Icon(_searchQuery.isNotEmpty ? Icons.clear : Icons.add),
            label: Text(
              _searchQuery.isNotEmpty ? 'مسح الفلاتر' : 'إنشاء طلب جديد',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFffd700),
              foregroundColor: const Color(0xFF1a1a2e),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // دوال الأحداث والإجراءات
  void _createNewOrder() {
    // TODO: تنفيذ إنشاء طلب جديد
    _showInfoSnackBar('سيتم إضافة ميزة إنشاء طلب جديد قريباً');
  }

  void _showExportOptions() {
    // TODO: تنفيذ خيارات التصدير
    _showInfoSnackBar('سيتم إضافة خيارات التصدير قريباً');
  }

  void _showScheduledOrders() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: const Color(0xFF16213e),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFffd700).withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              _buildScheduledOrdersHeader(),
              Expanded(child: _buildScheduledOrdersList()),
            ],
          ),
        ),
      ),
    );
  }

  // تحويل الطلبات النشطة إلى حالة التوصيل (20 طلب في كل مرة)
  Future<void> _batchConvertToDelivery() async {
    try {
      setState(() => _isBatchConverting = true);

      // جلب الطلبات النشطة (أول 20 طلب)
      final activeOrders = await AdminService.getOrdersSummary(
        statusFilter: 'active',
        limit: 20,
        offset: 0,
      );

      if (activeOrders.isEmpty) {
        _showInfoSnackBar('لا توجد طلبات نشطة للتحويل');
        return;
      }

      // تأكيد من المستخدم
      final confirmed = await _showConfirmationDialog(
        'تحويل ${activeOrders.length} طلب للتوصيل',
        'هل أنت متأكد من تحويل ${activeOrders.length} طلب من الحالة النشطة إلى حالة "قيد التوصيل الى الزبون (في عهدة المندوب)"؟\n\nسيتم إرسال هذه الطلبات إلى شركة الوسيط تلقائياً.',
      );

      if (!confirmed) return;

      // تحويل الطلبات واحد تلو الآخر
      int successCount = 0;
      int failCount = 0;

      for (final orderSummary in activeOrders) {
        try {
          await AdminService.updateOrderStatus(
            orderSummary.id,
            'قيد التوصيل الى الزبون (في عهدة المندوب)',
            notes: 'تم التحويل للتوصيل بواسطة التحويل المجمع',
            updatedBy: 'admin',
          );
          successCount++;
        } catch (e) {
          failCount++;
          debugPrint('❌ فشل في تحويل الطلب ${orderSummary.id}: $e');
        }
      }

      // عرض النتيجة
      if (successCount > 0) {
        _showSuccessSnackBar(
          'تم تحويل $successCount طلب بنجاح${failCount > 0 ? ' (فشل $failCount طلب)' : ''}',
        );
        _refreshOrders(); // تحديث القائمة
      } else {
        _showErrorSnackBar('فشل في تحويل جميع الطلبات');
      }

    } catch (e) {
      debugPrint('❌ خطأ في التحويل المجمع: $e');
      _showErrorSnackBar('حدث خطأ أثناء تحويل الطلبات');
    } finally {
      setState(() => _isBatchConverting = false);
    }
  }

  // دالة مساعدة لعرض تأكيد
  Future<bool> _showConfirmationDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: Text(
          title,
          style: const TextStyle(color: Color(0xFFffd700)),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFffd700),
              foregroundColor: const Color(0xFF1a1a2e),
            ),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showAdvancedFilters() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: const Text(
          'فلاتر متقدمة',
          style: TextStyle(color: Color(0xFFffd700)),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // فلتر الحالة
              const Text(
                'حالة الطلب',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildStatusFilter(),
              const SizedBox(height: 20),

              // فلتر التاريخ
              const Text(
                'فترة زمنية',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildDateFilter(),
              const SizedBox(height: 20),

              // فلتر المبلغ
              const Text(
                'نطاق المبلغ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildAmountFilter(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: _clearFilters,
            child: const Text(
              'مسح الكل',
              style: TextStyle(color: Colors.orange),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _applyFilters();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFffd700),
            ),
            child: const Text('تطبيق', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _handleBulkAction(String action) {
    // TODO: تنفيذ الإجراءات المجمعة
    _showInfoSnackBar('سيتم إضافة الإجراءات المجمعة قريباً');
  }

  Widget _buildStatusFilter() {
    final statuses = [
      {'value': 'all', 'label': 'جميع الحالات', 'color': Colors.grey},
      {'value': 'active', 'label': 'نشط', 'color': Colors.blue},
      {'value': 'in_delivery', 'label': 'قيد التوصيل', 'color': Colors.orange},
      {'value': 'delivered', 'label': 'تم التوصيل', 'color': Colors.green},
      {'value': 'cancelled', 'label': 'ملغي', 'color': Colors.red},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statuses.map((status) {
        final isSelected = _selectedStatus == status['value'];
        return FilterChip(
          label: Text(
            status['label'] as String,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontSize: 12,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedStatus = status['value'] as String;
            });
            _applyFilters(); // إضافة استدعاء الفلترة
          },
          backgroundColor: const Color(0xFF1a1a2e),
          selectedColor: status['color'] as Color,
          checkmarkColor: Colors.black,
          side: BorderSide(
            color: (status['color'] as Color).withValues(alpha: 0.5),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateFilter() {
    final dateRanges = [
      {'value': 'all', 'label': 'جميع التواريخ'},
      {'value': 'today', 'label': 'اليوم'},
      {'value': 'yesterday', 'label': 'أمس'},
      {'value': 'week', 'label': 'آخر أسبوع'},
      {'value': 'month', 'label': 'آخر شهر'},
      {'value': 'custom', 'label': 'فترة مخصصة'},
    ];

    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: dateRanges.map((range) {
            final isSelected = _selectedDateRange == range['value'];
            return FilterChip(
              label: Text(
                range['label'] as String,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedDateRange = range['value'] as String;
                });
              },
              backgroundColor: const Color(0xFF1a1a2e),
              selectedColor: const Color(0xFFffd700),
              checkmarkColor: Colors.black,
              side: const BorderSide(color: Color(0xFFffd700)),
            );
          }).toList(),
        ),
        if (_selectedDateRange == 'custom') ...[
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _startDate = date;
                      });
                    }
                  },
                  child: Text(
                    _startDate != null
                        ? DateFormat('yyyy/MM/dd').format(_startDate!)
                        : 'من تاريخ',
                    style: const TextStyle(color: Color(0xFFffd700)),
                  ),
                ),
              ),
              const Text(' - ', style: TextStyle(color: Colors.white)),
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: _startDate ?? DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _endDate = date;
                      });
                    }
                  },
                  child: Text(
                    _endDate != null
                        ? DateFormat('yyyy/MM/dd').format(_endDate!)
                        : 'إلى تاريخ',
                    style: const TextStyle(color: Color(0xFFffd700)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAmountFilter() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'الحد الأدنى',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFffd700)),
                  ),
                  suffixText: 'د.ع',
                  suffixStyle: TextStyle(color: Colors.white70),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _minAmount = double.tryParse(value) ?? 0;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'الحد الأعلى',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFffd700)),
                  ),
                  suffixText: 'د.ع',
                  suffixStyle: TextStyle(color: Colors.white70),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _maxAmount = double.tryParse(value) ?? double.infinity;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedStatus = 'all';
      _selectedDateRange = 'all';
      _selectedUser = 'all';
      _minAmount = 0;
      _maxAmount = double.infinity;
      _startDate = null;
      _endDate = null;
    });
    _searchController.clear();
    _applyFilters();
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

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildScheduledOrdersHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFffd700), Color(0xFFe6b31e)],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.schedule,
              color: Color(0xFFffd700),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الطلبات المجدولة',
                  style: TextStyle(
                    color: Color(0xFF1a1a2e),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'الطلبات المؤجلة لتواريخ محددة',
                  style: TextStyle(color: Color(0xFF1a1a2e), fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Color(0xFF1a1a2e), size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildTableView() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          // قائمة الطلبات مع Expanded لتجنب overflow
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshOrders,
              color: const Color(0xFFffd700),
              backgroundColor: const Color(0xFF1a1a2e),
              child: ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: _filteredSummaries.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _filteredSummaries.length) {
                    // مؤشر التحميل في النهاية
                    return Container(
                      padding: const EdgeInsets.all(20),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffd700)),
                        ),
                      ),
                    );
                  }
                  final summary = _filteredSummaries[index];
                  return _buildOrderSummaryRow(summary, index);
                },
              ),
            ),
          ),
          _buildTableFooter(),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: const BoxDecoration(
        color: Color(0xFF1a1a2e),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      child: Row(
        children: [
          if (_isSelectMode)
            Checkbox(
              value: _selectedOrders.length == _filteredSummaries.length,
              onChanged: _toggleSelectAll,
              activeColor: const Color(0xFFffd700),
            ),
          const Expanded(
            flex: 2,
            child: Text(
              'معلومات الطلب',
              style: TextStyle(
                color: Color(0xFFffd700),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'العميل',
              style: TextStyle(
                color: Color(0xFFffd700),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'المبلغ',
              style: TextStyle(
                color: Color(0xFFffd700),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'الحالة',
              style: TextStyle(
                color: Color(0xFFffd700),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'التاريخ',
              style: TextStyle(
                color: Color(0xFFffd700),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            width: 120,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'الإجراءات',
                  style: TextStyle(
                    color: Color(0xFFffd700),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _isSelectMode ? Icons.close : Icons.checklist,
                    color: const Color(0xFFffd700),
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSelectMode = !_isSelectMode;
                      if (!_isSelectMode) {
                        _selectedOrders.clear();
                      }
                    });
                  },
                  tooltip: _isSelectMode ? 'إلغاء التحديد' : 'تحديد متعدد',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 تحميل تفاصيل الطلب عند النقر (ذكي جداً)
  Future<void> _loadOrderDetails(OrderSummary summary) async {
    try {
      // التحقق من التخزين المؤقت أولاً
      if (_orderDetailsCache.containsKey(summary.id)) {
        final cachedOrder = _orderDetailsCache[summary.id]!;
        _navigateToOrderDetails(cachedOrder);
        return;
      }

      // إظهار مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffd700)),
          ),
        ),
      );

      // جلب التفاصيل الكاملة
      final orderDetails = await AdminService.getOrderDetailsFast(summary.id);

      // إغلاق مؤشر التحميل
      Navigator.of(context).pop();

      if (orderDetails != null) {
        // حفظ في التخزين المؤقت
        _orderDetailsCache[summary.id] = orderDetails;
        _navigateToOrderDetails(orderDetails);
      } else {
        _showErrorSnackBar('لم يتم العثور على تفاصيل الطلب');
      }
    } catch (e) {
      // إغلاق مؤشر التحميل في حالة الخطأ
      Navigator.of(context).pop();
      _showErrorSnackBar('خطأ في تحميل تفاصيل الطلب: $e');
    }
  }

  void _navigateToOrderDetails(AdminOrder order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdvancedOrderDetailsPage(orderId: order.id),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'confirmed':
        return const Color(0xFF2196F3);
      case 'in_delivery':
        return const Color(0xFFFF9800);
      case 'delivered':
        return const Color(0xFF4CAF50);
      case 'cancelled':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  // 🚀 عرض ملخص الطلب فقط (سريع جداً)
  Widget _buildOrderSummaryRow(OrderSummary summary, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _loadOrderDetails(summary),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                // رقم الطلب
                Expanded(
                  flex: 2,
                  child: Text(
                    summary.orderNumber,
                    style: const TextStyle(
                      color: Color(0xFFffd700),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                // اسم العميل
                Expanded(
                  flex: 3,
                  child: Text(
                    summary.customerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                // المحافظة والمدينة
                Expanded(
                  flex: 3,
                  child: Text(
                    '${summary.province} - ${summary.city}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
                // المبلغ
                Expanded(
                  flex: 2,
                  child: Text(
                    '${summary.totalAmount.toStringAsFixed(0)} د.ع',
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                // الحالة
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(summary.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      OrderStatusHelper.getArabicStatus(summary.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                // التاريخ
                Expanded(
                  flex: 2,
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(summary.createdAt),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
                // أيقونة التحميل
                const SizedBox(width: 10),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFFffd700),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderRow(AdminOrder order, int index) {
    final isSelected = _selectedOrders.contains(order);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFffd700).withValues(alpha: 0.1)
            : const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? const Color(0xFFffd700).withValues(alpha: 0.5)
              : OrderStatusHelper.getStatusColor(
                  order.status,
                ).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _viewOrderDetails(order),
          onLongPress: () => _toggleOrderSelection(order),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (_isSelectMode)
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleOrderSelection(order),
                    activeColor: const Color(0xFFffd700),
                  ),
                _buildOrderInfo(order),
                _buildCustomerInfo(order),
                _buildAmountInfo(order),
                _buildStatusInfo(order),
                _buildDateInfo(order),
                _buildActionsInfo(order),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderInfo(AdminOrder order) {
    return Expanded(
      flex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFffd700).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${order.orderNumber}',
                  style: const TextStyle(
                    color: Color(0xFFffd700),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${order.itemsCount} منتج',
                  style: const TextStyle(
                    color: Color(0xFF2196F3),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'ربح: ${order.expectedProfit.toStringAsFixed(0)} د.ع',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(AdminOrder order) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order.customerName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            order.customerPhone,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInfo(AdminOrder order) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${order.totalAmount.toStringAsFixed(0)} د.ع',
            style: const TextStyle(
              color: Color(0xFFffd700),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'المجموع',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInfo(AdminOrder order) {
    final statusColor = OrderStatusHelper.getStatusColor(order.status);
    final statusText = OrderStatusHelper.getArabicStatus(order.status);
    final statusIcon = OrderStatusHelper.getStatusIcon(order.status);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, color: statusColor, size: 14),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateInfo(AdminOrder order) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('dd/MM/yyyy').format(order.createdAt),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('HH:mm').format(order.createdAt),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsInfo(AdminOrder order) {
    return SizedBox(
      width: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            Icons.visibility,
            const Color(0xFF2196F3),
            'عرض',
            () => _viewOrderDetails(order),
          ),
          _buildActionButton(
            Icons.edit,
            const Color(0xFFFF9800),
            'تحديث',
            () => _updateOrderStatus(order),
          ),
          _buildActionButton(
            Icons.more_vert,
            const Color(0xFF9E9E9E),
            'المزيد',
            () => _showOrderMenu(order),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    Color color,
    String tooltip,
    VoidCallback onPressed,
  ) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 14),
        tooltip: tooltip,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildTableFooter() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: const BoxDecoration(
        color: Color(0xFF1a1a2e),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'عرض ${_filteredSummaries.length} من إجمالي ${_orderSummaries.length} طلب',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          if (_selectedOrders.isNotEmpty)
            Text(
              '${_selectedOrders.length} محدد',
              style: const TextStyle(
                color: Color(0xFFffd700),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  // دوال العرض البديلة
  Widget _buildGridView() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: RefreshIndicator(
        onRefresh: _refreshOrders,
        color: const Color(0xFFffd700),
        backgroundColor: const Color(0xFF1a1a2e),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
          ),
          itemCount: _filteredSummaries.length,
          itemBuilder: (context, index) {
            final summary = _filteredSummaries[index];
            // تحويل الملخص إلى AdminOrder مؤقت للعرض
            final order = summary.toAdminOrder();
            return _buildOrderCard(order);
          },
        ),
      ),
    );
  }

  Widget _buildOrderCard(AdminOrder order) {
    final isSelected = _selectedOrders.contains(order);
    final statusColor = OrderStatusHelper.getStatusColor(order.status);

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFffd700).withValues(alpha: 0.1)
            : const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? const Color(0xFFffd700).withValues(alpha: 0.5)
              : statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _viewOrderDetails(order),
          onLongPress: () => _toggleOrderSelection(order),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFffd700).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#${order.orderNumber}',
                        style: const TextStyle(
                          color: Color(0xFFffd700),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_isSelectMode)
                      Checkbox(
                        value: isSelected,
                        onChanged: (_) => _toggleOrderSelection(order),
                        activeColor: const Color(0xFFffd700),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  order.customerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${order.totalAmount.toStringAsFixed(0)} د.ع',
                  style: const TextStyle(
                    color: Color(0xFFffd700),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        OrderStatusHelper.getArabicStatus(order.status),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM').format(order.createdAt),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineView() {
    // تجميع الطلبات حسب التاريخ
    final groupedOrders = <String, List<AdminOrder>>{};
    // تحويل الملخصات إلى AdminOrder للعرض
    final filteredOrders = _filteredSummaries.map((s) => s.toAdminOrder()).toList();
    for (final order in filteredOrders) {
      final dateKey = DateFormat('yyyy-MM-dd').format(order.createdAt);
      groupedOrders[dateKey] = (groupedOrders[dateKey] ?? [])..add(order);
    }

    final sortedDates = groupedOrders.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // ترتيب تنازلي

    return Container(
      margin: const EdgeInsets.all(20),
      child: RefreshIndicator(
        onRefresh: _refreshOrders,
        color: const Color(0xFFffd700),
        backgroundColor: const Color(0xFF1a1a2e),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final dateKey = sortedDates[index];
            final orders = groupedOrders[dateKey]!;
            final date = DateTime.parse(dateKey);

            return _buildTimelineSection(date, orders);
          },
        ),
      ),
    );
  }

  Widget _buildTimelineSection(DateTime date, List<AdminOrder> orders) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF16213e),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFffd700).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Color(0xFFffd700),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE، dd MMMM yyyy', 'ar').format(date),
                  style: const TextStyle(
                    color: Color(0xFFffd700),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFffd700).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${orders.length} طلب',
                    style: const TextStyle(
                      color: Color(0xFFffd700),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ...orders.map((order) => _buildTimelineOrderCard(order)),
        ],
      ),
    );
  }

  Widget _buildTimelineOrderCard(AdminOrder order) {
    final isSelected = _selectedOrders.contains(order);
    final statusColor = OrderStatusHelper.getStatusColor(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFffd700).withValues(alpha: 0.1)
            : const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? const Color(0xFFffd700).withValues(alpha: 0.5)
              : statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _viewOrderDetails(order),
          onLongPress: () => _toggleOrderSelection(order),
          borderRadius: BorderRadius.circular(10),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '#${order.orderNumber}',
                          style: const TextStyle(
                            color: Color(0xFFffd700),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('HH:mm').format(order.createdAt),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        if (_isSelectMode)
                          Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleOrderSelection(order),
                            activeColor: const Color(0xFFffd700),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          order.customerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${order.totalAmount.toStringAsFixed(0)} د.ع',
                          style: const TextStyle(
                            color: Color(0xFFffd700),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دوال التفاعل والإجراءات
  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedOrders = _filteredSummaries.map((s) => s.toAdminOrder()).toList();
      } else {
        _selectedOrders.clear();
      }
    });
  }

  void _toggleOrderSelection(AdminOrder order) {
    setState(() {
      if (_selectedOrders.contains(order)) {
        _selectedOrders.remove(order);
      } else {
        _selectedOrders.add(order);
      }
    });
  }

  void _viewOrderDetails(AdminOrder order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdvancedOrderDetailsPage(orderId: order.id),
      ),
    ).then((_) {
      _refreshOrders();
    });
  }

  void _updateOrderStatus(AdminOrder order) {
    _viewOrderDetails(order);
  }

  void _showOrderMenu(AdminOrder order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFffd700),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'خيارات الطلب #${order.orderNumber}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildMenuOption(Icons.visibility, 'عرض التفاصيل', () {
              Navigator.pop(context);
              _viewOrderDetails(order);
            }),
            _buildMenuOption(Icons.edit, 'تحديث الحالة', () {
              Navigator.pop(context);
              _updateOrderStatus(order);
            }),
            _buildMenuOption(Icons.print, 'طباعة الطلب', () {
              Navigator.pop(context);
              _showInfoSnackBar('سيتم طباعة الطلب قريباً');
            }),
            _buildMenuOption(Icons.message, 'إرسال رسالة للعميل', () {
              Navigator.pop(context);
              _showInfoSnackBar('سيتم إرسال رسالة للعميل قريباً');
            }),
            _buildMenuOption(Icons.delete, 'حذف الطلب', () {
              Navigator.pop(context);
              _confirmDeleteOrder(order);
            }, isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : const Color(0xFFffd700),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.white,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }

  void _confirmDeleteOrder(AdminOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
        content: Text(
          'هل أنت متأكد من حذف الطلب #${order.orderNumber}؟\nلا يمكن التراجع عن هذا الإجراء.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteOrder(order);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteOrder(AdminOrder order) async {
    try {
      await AdminService.deleteOrder(order.id);
      _showInfoSnackBar('تم حذف الطلب بنجاح');
      _refreshOrders();
    } catch (e) {
      _showErrorSnackBar('خطأ في حذف الطلب: $e');
    }
  }

  Widget _buildScheduledOrdersList() {
    // بيانات تجريبية للطلبات المجدولة
    final scheduledOrders = [
      {
        'id': 'scheduled_001',
        'orderNumber': 'ORD-SCH-001',
        'customerName': 'أحمد محمد',
        'customerPhone': '07701234567',
        'totalAmount': 25000.0,
        'scheduledDate': DateTime.now().add(const Duration(days: 2)),
        'createdAt': DateTime.now().subtract(const Duration(hours: 3)),
        'notes': 'طلب مجدول لعيد الميلاد',
        'items': [
          {'name': 'كيك شوكولاتة', 'quantity': 1, 'price': 15000.0},
          {'name': 'ورود حمراء', 'quantity': 2, 'price': 5000.0},
        ],
      },
      {
        'id': 'scheduled_002',
        'orderNumber': 'ORD-SCH-002',
        'customerName': 'فاطمة علي',
        'customerPhone': '07801234567',
        'totalAmount': 18000.0,
        'scheduledDate': DateTime.now().add(const Duration(days: 5)),
        'createdAt': DateTime.now().subtract(const Duration(days: 1)),
        'notes': 'طلب لحفل زفاف',
        'items': [
          {'name': 'باقة ورود', 'quantity': 3, 'price': 6000.0},
        ],
      },
      {
        'id': 'scheduled_003',
        'orderNumber': 'ORD-SCH-003',
        'customerName': 'محمد حسن',
        'customerPhone': '07901234567',
        'totalAmount': 32000.0,
        'scheduledDate': DateTime.now().add(const Duration(days: 7)),
        'createdAt': DateTime.now().subtract(const Duration(hours: 12)),
        'notes': 'طلب لمناسبة تخرج',
        'items': [
          {'name': 'تورتة تخرج', 'quantity': 1, 'price': 20000.0},
          {'name': 'بالونات', 'quantity': 10, 'price': 1200.0},
        ],
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // إحصائيات سريعة
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFffd700).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScheduledStat(
                  'العدد الكلي',
                  '${scheduledOrders.length}',
                  Icons.schedule,
                ),
                _buildScheduledStat(
                  'القيمة الإجمالية',
                  '${scheduledOrders.fold(0.0, (sum, order) => sum + (order['totalAmount'] as double)).toStringAsFixed(0)} د.ع',
                  Icons.attach_money,
                ),
                _buildScheduledStat('الأقرب', 'خلال يومين', Icons.access_time),
              ],
            ),
          ),

          // قائمة الطلبات المجدولة
          Expanded(
            child: ListView.builder(
              itemCount: scheduledOrders.length,
              itemBuilder: (context, index) {
                final order = scheduledOrders[index];
                return _buildScheduledOrderCard(order);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFffd700), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFffd700),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildScheduledOrderCard(Map<String, dynamic> order) {
    final scheduledDate = order['scheduledDate'] as DateTime;
    final createdAt = order['createdAt'] as DateTime;
    final items = order['items'] as List<Map<String, dynamic>>;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        childrenPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFffd700).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.schedule, color: Color(0xFFffd700), size: 20),
        ),
        title: Text(
          order['orderNumber'] as String,
          style: const TextStyle(
            color: Color(0xFFffd700),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              order['customerName'] as String,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              order['customerPhone'] as String,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${(order['totalAmount'] as double).toStringAsFixed(0)} د.ع',
              style: const TextStyle(
                color: Color(0xFFffd700),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'مجدول: ${DateFormat('yyyy/MM/dd').format(scheduledDate)}',
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF16213e),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // تفاصيل التواريخ
                Row(
                  children: [
                    Expanded(
                      child: _buildScheduledDetailItem(
                        'تاريخ الإنشاء',
                        DateFormat('yyyy/MM/dd HH:mm').format(createdAt),
                        Icons.create,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildScheduledDetailItem(
                        'تاريخ التثبيت المجدول',
                        DateFormat('yyyy/MM/dd').format(scheduledDate),
                        Icons.event,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // المنتجات
                const Text(
                  'المنتجات:',
                  style: TextStyle(
                    color: Color(0xFFffd700),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...items.map(
                  (item) => Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a1a2e),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['name'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          'الكمية: ${item['quantity']}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(item['price'] as double).toStringAsFixed(0)} د.ع',
                          style: const TextStyle(
                            color: Color(0xFFffd700),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // الملاحظات
                if (order['notes'] != null &&
                    (order['notes'] as String).isNotEmpty) ...[
                  const Text(
                    'ملاحظات:',
                    style: TextStyle(
                      color: Color(0xFFffd700),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a1a2e),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      order['notes'] as String,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // أزرار الإجراءات
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showInfoSnackBar('سيتم تثبيت الطلب الآن');
                        },
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('تثبيت الآن'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showInfoSnackBar('سيتم تعديل تاريخ الجدولة');
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('تعديل التاريخ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFffd700),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showInfoSnackBar('سيتم إلغاء الطلب المجدول');
                        },
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text('إلغاء'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
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

  Widget _buildScheduledDetailItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFffd700), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
