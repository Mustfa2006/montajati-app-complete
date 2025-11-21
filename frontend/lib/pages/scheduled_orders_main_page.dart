import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/scheduled_order.dart';
import '../services/scheduled_orders_service.dart';

class ScheduledOrdersMainPage extends StatefulWidget {
  const ScheduledOrdersMainPage({super.key});

  @override
  State<ScheduledOrdersMainPage> createState() =>
      _ScheduledOrdersMainPageState();
}

class _ScheduledOrdersMainPageState extends State<ScheduledOrdersMainPage>
    with TickerProviderStateMixin {
  // Controllers للرسوم المتحركة
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController
  _statisticsController; // ✅ إضافة controller للإحصائيات
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _statisticsAnimation; // ✅ إضافة animation للإحصائيات

  // بيانات الطلبات المجدولة
  List<ScheduledOrder> _scheduledOrders = [];
  List<ScheduledOrder> _filteredOrders = [];
  bool _isLoading = true;
  // تم إزالة _isRefreshing غير المستخدم

  // فلاتر البحث
  String _searchQuery = '';
  String _selectedDateRange = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  // ✅ إضافة متغير للتحكم في إظهار الإحصائيات
  bool _showStatistics = false;

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 بدء تهيئة صفحة الطلبات المجدولة...');
    _initializeAnimations();
    debugPrint('🔄 بدء تحميل الطلبات المجدولة من initState...');
    _loadScheduledOrders();

    // تشغيل التحويل التلقائي عند بدء الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runAutoConversion();
    });
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

    // ✅ إضافة animation controller للإحصائيات
    _statisticsController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // ✅ إضافة animation للإحصائيات
    _statisticsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _statisticsController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadScheduledOrders() async {
    try {
      setState(() => _isLoading = true);
      debugPrint('🔄 بدء تحميل الطلبات المجدولة من قاعدة البيانات...');

      // تحميل الطلبات من الخدمة الحقيقية
      final service = ScheduledOrdersService();
      await service.loadScheduledOrders();

      final orders = service.scheduledOrders;
      debugPrint('📋 تم تحميل ${orders.length} طلب مجدول من قاعدة البيانات');

      setState(() {
        _scheduledOrders = List.from(orders);
        // ✅ ضمان الترتيب الصحيح: الأحدث أولاً دائماً
        _scheduledOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isLoading = false;
      });

      _applyFilters();
      debugPrint(
        '✅ تم تطبيق الفلاتر. عدد الطلبات المفلترة: ${_filteredOrders.length}',
      );
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الطلبات المجدولة: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('خطأ في تحميل الطلبات المجدولة: $e');
    }
  }

  // تشغيل التحويل التلقائي للطلبات المجدولة
  Future<void> _runAutoConversion() async {
    try {
      debugPrint('🔄 بدء التحويل التلقائي للطلبات المجدولة...');

      final service = ScheduledOrdersService();
      final convertedCount = await service.convertScheduledOrdersToActive();

      if (convertedCount > 0) {
        _showSuccessSnackBar(
          'تم تحويل $convertedCount طلب مجدول إلى نشط تلقائياً',
        );
        // إعادة تحميل الطلبات لتحديث القائمة
        await _loadScheduledOrders();
      } else {
        debugPrint('ℹ️ لا توجد طلبات مجدولة تحتاج للتحويل');
      }
    } catch (e) {
      debugPrint('❌ خطأ في التحويل التلقائي: $e');
      _showErrorSnackBar('خطأ في التحويل التلقائي: $e');
    }
  }

  // ✅ دالة للتحكم في إظهار/إخفاء الإحصائيات
  void _toggleStatistics() {
    setState(() {
      _showStatistics = !_showStatistics;
    });

    if (_showStatistics) {
      _statisticsController.forward();
    } else {
      _statisticsController.reverse();
    }
  }

  void _applyFilters() {
    debugPrint('🔍 تطبيق الفلاتر...');
    debugPrint('📊 عدد الطلبات الأصلية: ${_scheduledOrders.length}');
    debugPrint('🔍 استعلام البحث: "$_searchQuery"');
    debugPrint('📅 نطاق التاريخ المحدد: $_selectedDateRange');

    setState(() {
      _filteredOrders = _scheduledOrders.where((order) {
        // فلتر البحث
        bool matchesSearch =
            _searchQuery.isEmpty ||
            order.orderNumber.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            order.customerName.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            order.customerPhone.contains(_searchQuery);

        // فلتر التاريخ
        bool matchesDate =
            _selectedDateRange == 'all' || _isDateInRange(order.scheduledDate);

        debugPrint(
          '📋 طلب ${order.orderNumber}: البحث=$matchesSearch, التاريخ=$matchesDate',
        );
        return matchesSearch && matchesDate;
      }).toList();

      // ترتيب حسب تاريخ الإنشاء (الطلبات الجديدة أولاً)
      _filteredOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      debugPrint('✅ عدد الطلبات بعد الفلترة: ${_filteredOrders.length}');
    });
  }

  bool _isDateInRange(DateTime date) {
    switch (_selectedDateRange) {
      case 'today':
        return _isSameDay(date, DateTime.now());
      case 'tomorrow':
        return _isSameDay(date, DateTime.now().add(const Duration(days: 1)));
      case 'week':
        return date.isBefore(DateTime.now().add(const Duration(days: 7)));
      case 'month':
        return date.isBefore(DateTime.now().add(const Duration(days: 30)));
      case 'overdue':
        return date.isBefore(DateTime.now()) &&
            !_isSameDay(date, DateTime.now());
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

  Future<void> _refreshOrders() async {
    // تم إزالة تعيين _isRefreshing غير المستخدم
    await _loadScheduledOrders();
    // تم إزالة تعيين _isRefreshing غير المستخدم
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _statisticsController.dispose(); // ✅ إضافة تنظيف statistics controller
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingScreen() : _buildMainContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1a1a2e),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFFffd700)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFffd700).withValues(alpha: 0.2),
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
                    color: Color(0xFFffd700),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'إدارة الطلبات المؤجلة لتواريخ محددة',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.autorenew, color: Color(0xFFffd700)),
          onPressed: _runAutoConversion,
          tooltip: 'تحويل تلقائي للطلبات المجدولة',
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFFffd700)),
          onPressed: _refreshOrders,
        ),
        IconButton(
          icon: const Icon(Icons.add_alarm, color: Color(0xFFffd700)),
          onPressed: _createNewScheduledOrder,
        ),
        const SizedBox(width: 8),
      ],
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
              'جاري تحميل الطلبات المجدولة...',
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
        child: Column(
          children: [
            _buildStatisticsBar(),
            _buildToolbar(),
            Expanded(child: _buildOrdersList()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsBar() {
    final totalOrders = _filteredOrders.length;
    final totalAmount = _filteredOrders.fold<double>(
      0,
      (sum, order) => sum + order.totalAmount,
    );
    final upcomingToday = _filteredOrders
        .where((order) => _isSameDay(order.scheduledDate, DateTime.now()))
        .length;
    final overdue = _filteredOrders
        .where(
          (order) =>
              order.scheduledDate.isBefore(DateTime.now()) &&
              !_isSameDay(order.scheduledDate, DateTime.now()),
        )
        .length;

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF16213e), Color(0xFF1a1a2e)],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // ✅ شريط التحكم مع زر إظهار/إخفاء الإحصائيات
          InkWell(
            onTap: _toggleStatistics,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.analytics,
                    color: Color(0xFFffd700),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'إحصائيات سريعة',
                    style: TextStyle(
                      color: Color(0xFFffd700),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // ✅ زر إظهار/إخفاء مع animation
                  AnimatedRotation(
                    turns: _showStatistics ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFFffd700),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ✅ الجزء القابل للطي للإحصائيات
          AnimatedBuilder(
            animation: _statisticsAnimation,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _statisticsAnimation.value,
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'إجمالي الطلبات',
                          totalOrders.toString(),
                          Icons.schedule,
                          const Color(0xFF2196F3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'القيمة الإجمالية',
                          '${totalAmount.toStringAsFixed(0)} د.ع',
                          Icons.attach_money,
                          const Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'اليوم',
                          upcomingToday.toString(),
                          Icons.today,
                          const Color(0xFFFF9800),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'متأخرة',
                          overdue.toString(),
                          Icons.warning,
                          Colors.red,
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

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
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
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _createNewScheduledOrder() {
    _showSuccessSnackBar('سيتم إضافة ميزة إنشاء طلب مجدول جديد قريباً');
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          // شريط البحث
          Container(
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
                hintText:
                    'البحث في الطلبات المجدولة (رقم الطلب، اسم العميل، الهاتف...)',
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
          ),
          const SizedBox(height: 12),
          // فلاتر سريعة
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('الكل', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('اليوم', 'today'),
                const SizedBox(width: 8),
                _buildFilterChip('غداً', 'tomorrow'),
                const SizedBox(width: 8),
                _buildFilterChip('هذا الأسبوع', 'week'),
                const SizedBox(width: 8),
                _buildFilterChip('متأخرة', 'overdue'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedDateRange == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDateRange = value;
        });
        _applyFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFffd700) : const Color(0xFF16213e),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFffd700)
                : const Color(0xFFffd700).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
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
  }

  Widget _buildOrdersList() {
    if (_filteredOrders.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshOrders,
      color: const Color(0xFFffd700),
      backgroundColor: const Color(0xFF1a1a2e),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        itemCount: _filteredOrders.length,
        itemBuilder: (context, index) {
          final order = _filteredOrders[index];
          return _buildOrderCard(order, index);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    debugPrint(
      '🚫 عرض حالة فارغة - عدد الطلبات المفلترة: ${_filteredOrders.length}',
    );
    debugPrint('📊 عدد الطلبات الأصلية: ${_scheduledOrders.length}');
    debugPrint('🔍 استعلام البحث الحالي: "$_searchQuery"');
    debugPrint('📅 نطاق التاريخ المحدد: $_selectedDateRange');

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
              Icons.schedule_outlined,
              color: Color(0xFFffd700),
              size: 64,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'لا توجد طلبات مجدولة',
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
                : 'لم يتم إنشاء أي طلبات مجدولة بعد',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'عدد الطلبات الأصلية: ${_scheduledOrders.length}',
            style: TextStyle(
              color: Colors.orange.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _searchQuery.isNotEmpty
                ? _clearFilters
                : _createNewScheduledOrder,
            icon: Icon(_searchQuery.isNotEmpty ? Icons.clear : Icons.add_alarm),
            label: Text(
              _searchQuery.isNotEmpty ? 'مسح الفلاتر' : 'إنشاء طلب مجدول جديد',
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

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedDateRange = 'all';
      _startDate = null;
      _endDate = null;
    });
    _searchController.clear();
    _applyFilters();
  }

  Widget _buildOrderCard(ScheduledOrder order, int index) {
    final daysUntilScheduled = order.scheduledDate
        .difference(DateTime.now())
        .inDays;
    final isToday = _isSameDay(order.scheduledDate, DateTime.now());
    final isTomorrow = _isSameDay(
      order.scheduledDate,
      DateTime.now().add(const Duration(days: 1)),
    );
    final isOverdue = order.scheduledDate.isBefore(DateTime.now()) && !isToday;

    Color priorityColor;
    switch (order.priority) {
      case 'عالية':
        priorityColor = Colors.red;
        break;
      case 'متوسطة':
        priorityColor = Colors.orange;
        break;
      case 'منخفضة':
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isOverdue
              ? Colors.red.withValues(alpha: 0.5)
              : isToday
              ? const Color(0xFFffd700).withValues(alpha: 0.8)
              : const Color(0xFFffd700).withValues(alpha: 0.3),
          width: isOverdue || isToday ? 2 : 1,
        ),
        boxShadow: [
          if (isToday || isOverdue)
            BoxShadow(
              color: (isOverdue ? Colors.red : const Color(0xFFffd700))
                  .withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        childrenPadding: const EdgeInsets.all(16),
        leading: _buildOrderLeading(order, priorityColor, isOverdue, isToday),
        title: _buildOrderTitle(order),
        subtitle: _buildOrderSubtitle(
          order,
          daysUntilScheduled,
          isToday,
          isTomorrow,
          isOverdue,
        ),
        trailing: _buildOrderTrailing(order),
        children: [_buildOrderDetails(order)],
      ),
    );
  }

  Widget _buildOrderLeading(
    ScheduledOrder order,
    Color priorityColor,
    bool isOverdue,
    bool isToday,
  ) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: priorityColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: priorityColor.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Icon(
            isOverdue
                ? Icons.warning
                : isToday
                ? Icons.today
                : Icons.schedule,
            color: priorityColor,
            size: 20,
          ),
        ),
        if (order.reminderSent)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Color(0xFFffd700),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications,
                color: Color(0xFF1a1a2e),
                size: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOrderTitle(ScheduledOrder order) {
    return Row(
      children: [
        Expanded(
          child: Text(
            order.orderNumber,
            style: const TextStyle(
              color: Color(0xFFffd700),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getPriorityColor(order.priority).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getPriorityColor(order.priority).withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Text(
            order.priority,
            style: TextStyle(
              color: _getPriorityColor(order.priority),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'عالية':
        return Colors.red;
      case 'متوسطة':
        return Colors.orange;
      case 'منخفضة':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildOrderSubtitle(
    ScheduledOrder order,
    int daysUntilScheduled,
    bool isToday,
    bool isTomorrow,
    bool isOverdue,
  ) {
    String timeText;
    Color timeColor;

    if (isOverdue) {
      timeText = 'متأخر ${-daysUntilScheduled} يوم';
      timeColor = Colors.red;
    } else if (isToday) {
      timeText = 'اليوم';
      timeColor = const Color(0xFFffd700);
    } else if (isTomorrow) {
      timeText = 'غداً';
      timeColor = Colors.orange;
    } else if (daysUntilScheduled <= 7) {
      timeText = 'خلال $daysUntilScheduled أيام';
      timeColor = Colors.blue;
    } else {
      timeText = 'خلال $daysUntilScheduled يوم';
      timeColor = Colors.grey;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          order.customerName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(Icons.phone, color: Colors.white70, size: 12),
            const SizedBox(width: 4),
            Text(
              order.customerPhone,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(width: 12),
            Icon(Icons.access_time, color: timeColor, size: 12),
            const SizedBox(width: 4),
            Text(
              timeText,
              style: TextStyle(
                color: timeColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'مجدول: ${DateFormat('yyyy/MM/dd').format(order.scheduledDate)}',
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildOrderTrailing(ScheduledOrder order) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${order.totalAmount.toStringAsFixed(0)} د.ع',
          style: const TextStyle(
            color: Color(0xFFffd700),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a2e),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${order.items.length} منتج',
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ),
        const SizedBox(height: 8),
        // زر تحويل سريع
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _confirmOrder(order),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_arrow,
                      color: const Color(0xFF4CAF50),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'تثبيت',
                      style: TextStyle(
                        color: const Color(0xFF4CAF50),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetails(ScheduledOrder order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // معلومات العميل
          _buildDetailSection('معلومات العميل', Icons.person, [
            _buildDetailRow('الاسم', order.customerName),
            _buildDetailRow('الهاتف', order.customerPhone),
            _buildDetailRow('العنوان', order.customerAddress),
          ]),
          const SizedBox(height: 16),

          // تفاصيل التواريخ
          _buildDetailSection('تفاصيل التواريخ', Icons.schedule, [
            _buildDetailRow(
              'تاريخ الإنشاء',
              DateFormat('yyyy/MM/dd HH:mm').format(order.createdAt),
            ),
            _buildDetailRow(
              'تاريخ التثبيت المجدول',
              DateFormat('yyyy/MM/dd').format(order.scheduledDate),
            ),
            _buildDetailRow(
              'الوقت المتبقي',
              _getTimeRemaining(order.scheduledDate),
            ),
          ]),
          const SizedBox(height: 16),

          // المنتجات
          _buildDetailSection(
            'المنتجات (${order.items.length})',
            Icons.shopping_cart,
            order.items.map((item) => _buildProductItem(item)).toList(),
          ),
          const SizedBox(height: 16),

          // الملاحظات
          if (order.notes.isNotEmpty) ...[
            _buildDetailSection('ملاحظات', Icons.note, [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213e),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.notes,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ]),
            const SizedBox(height: 16),
          ],

          // أزرار الإجراءات
          _buildActionButtons(order),
        ],
      ),
    );
  }

  Widget _buildDetailSection(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFFffd700), size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFffd700),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(ScheduledOrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFffd700).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${item.price.toStringAsFixed(0)} د.ع',
                style: const TextStyle(
                  color: Color(0xFFffd700),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'الكمية: ${item.quantity}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              if (item.notes.isNotEmpty) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'ملاحظة: ${item.notes}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _getTimeRemaining(DateTime scheduledDate) {
    final now = DateTime.now();
    final difference = scheduledDate.difference(now);

    if (difference.isNegative) {
      final days = -difference.inDays;
      return 'متأخر $days يوم';
    } else if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'خلال ${difference.inMinutes} دقيقة';
      }
      return 'خلال ${difference.inHours} ساعة';
    } else {
      return 'خلال ${difference.inDays} يوم';
    }
  }

  Widget _buildActionButtons(ScheduledOrder order) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _confirmOrder(order),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('تثبيت الآن'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _editScheduledDate(order),
            icon: const Icon(Icons.edit_calendar, size: 16),
            label: const Text('تعديل التاريخ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFffd700),
              foregroundColor: const Color(0xFF1a1a2e),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _cancelScheduledOrder(order),
            icon: const Icon(Icons.cancel, size: 16),
            label: const Text('إلغاء'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmOrder(ScheduledOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: const Text(
          'تثبيت الطلب',
          style: TextStyle(color: Color(0xFFffd700)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل تريد تحويل الطلب المجدول إلى طلب نشط؟',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a2e),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFffd700).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'رقم الطلب: ${order.orderNumber}',
                    style: const TextStyle(
                      color: Color(0xFFffd700),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'العميل: ${order.customerName}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Text(
                    'المبلغ: ${order.totalAmount.toStringAsFixed(0)} د.ع',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سيتم نقل الطلب إلى قسم إدارة الطلبات كطلب نشط',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _convertToActiveOrder(order);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            child: const Text('تثبيت الآن'),
          ),
        ],
      ),
    );
  }

  Future<void> _convertToActiveOrder(ScheduledOrder order) async {
    if (!mounted) return;

    try {
      // عرض مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF16213e),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffd700)),
              ),
              const SizedBox(height: 16),
              Text(
                'جاري تحويل الطلب...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      // تحويل الطلب
      final service = ScheduledOrdersService();
      final result = await service.convertScheduledOrderToActive(order.id);

      // إغلاق مؤشر التحميل
      if (mounted) Navigator.pop(context);

      if (result['success'] == true) {
        if (mounted) {
          _showSuccessSnackBar(
            'تم تحويل الطلب بنجاح! رقم الطلب الجديد: ${result['newOrderNumber']}',
          );
        }

        // تحديث القائمة
        await _loadScheduledOrders();

        // عرض رسالة إضافية
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF16213e),
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'تم التحويل بنجاح',
                    style: TextStyle(color: Colors.green),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تم تحويل الطلب المجدول إلى طلب نشط بنجاح',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'رقم الطلب الجديد: ${result['newOrderNumber']}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'يمكنك الآن العثور على الطلب في قسم إدارة الطلبات',
                          style: TextStyle(
                            color: Colors.green.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFffd700),
                    foregroundColor: const Color(0xFF1a1a2e),
                  ),
                  child: const Text('حسناً'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          _showErrorSnackBar('فشل في تحويل الطلب: ${result['message']}');
        }
      }
    } catch (e) {
      // إغلاق مؤشر التحميل في حالة الخطأ
      if (mounted) Navigator.pop(context);
      if (mounted) {
        _showErrorSnackBar('خطأ في تحويل الطلب: $e');
      }
    }
  }

  void _editScheduledDate(ScheduledOrder order) {
    _showSuccessSnackBar('سيتم تعديل تاريخ الطلب ${order.orderNumber}');
  }

  void _cancelScheduledOrder(ScheduledOrder order) {
    _showSuccessSnackBar('سيتم إلغاء الطلب المجدول ${order.orderNumber}');
  }
}
