import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/admin_user.dart';
import '../models/user_statistics.dart';
import '../services/user_management_service.dart';
import 'user_details_page.dart';
import 'add_user_page.dart';

class UsersManagementPage extends StatefulWidget {
  const UsersManagementPage({super.key});

  @override
  State<UsersManagementPage> createState() => _UsersManagementPageState();
}

class _UsersManagementPageState extends State<UsersManagementPage> {
  List<AdminUser> _users = [];
  UserStatistics? _statistics;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _searchQuery = '';
  String _statusFilter = 'all';
  final String _roleFilter = 'all';
  String _sortBy = 'created_at';
  bool _ascending = false;
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMoreData = true;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreUsers();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _hasMoreData = true;
    });

    try {
      // جلب الإحصائيات
      final statistics = await UserManagementService.getUserStatistics();

      // جلب المستخدمين
      final users = await UserManagementService.getAllUsers(
        limit: _pageSize,
        offset: 0,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        statusFilter: _statusFilter == 'all' ? null : _statusFilter,
        roleFilter: _roleFilter == 'all' ? null : _roleFilter,
        sortBy: _sortBy,
        ascending: _ascending,
      );

      setState(() {
        _statistics = statistics;
        _users = users;
        _hasMoreData = users.length == _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('خطأ في تحميل البيانات: $e');
    }
  }

  Future<void> _loadMoreUsers() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final newUsers = await UserManagementService.getAllUsers(
        limit: _pageSize,
        offset: (_currentPage + 1) * _pageSize,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        statusFilter: _statusFilter == 'all' ? null : _statusFilter,
        roleFilter: _roleFilter == 'all' ? null : _roleFilter,
        sortBy: _sortBy,
        ascending: _ascending,
      );

      setState(() {
        _currentPage++;
        _users.addAll(newUsers);
        _hasMoreData = newUsers.length == _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      _showErrorSnackBar('خطأ في تحميل المزيد: $e');
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _debounceSearch();
  }

  Timer? _searchTimer;
  void _debounceSearch() {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      _loadInitialData();
    });
  }

  void _onFilterChanged() {
    _loadInitialData();
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f1419),
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingWidget() : _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1a1a2e),
      elevation: 0,
      title: const Text(
        'إدارة المستخدمين',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const FaIcon(
            FontAwesomeIcons.chartLine,
            color: Colors.white,
            size: 20,
          ),
          onPressed: _showStatisticsDialog,
        ),
        IconButton(
          icon: const FaIcon(
            FontAwesomeIcons.filter,
            color: Colors.white,
            size: 20,
          ),
          onPressed: _showFilterDialog,
        ),
        IconButton(
          icon: const FaIcon(
            FontAwesomeIcons.arrowsRotate,
            color: Colors.white,
            size: 20,
          ),
          onPressed: _loadInitialData,
        ),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF16213e),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFffc107).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFffc107),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'جاري تحميل بيانات المستخدمين...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'قد يستغرق هذا بضع ثوانٍ',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildSearchAndStats(),
        Expanded(
          child: _users.isEmpty ? _buildEmptyState() : _buildUsersList(),
        ),
      ],
    );
  }

  Widget _buildSearchAndStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1a1a2e),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // شريط البحث
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0f1419),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x000ff333), width: 1),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'البحث في المستخدمين...',
                hintStyle: TextStyle(color: Colors.white54),
                prefixIcon: Icon(Icons.search, color: Color(0xFFffc107)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          if (_statistics != null) ...[
            const SizedBox(height: 16),
            _buildQuickStats(),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'إجمالي المستخدمين',
            _statistics!.totalUsers.toString(),
            FontAwesomeIcons.users,
            const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'المستخدمين النشطين',
            _statistics!.activeUsers.toString(),
            FontAwesomeIcons.userCheck,
            const Color(0xFF2196F3),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'المديرين',
            _statistics!.adminUsers.toString(),
            FontAwesomeIcons.userTie,
            const Color(0xFFFF9800),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'متصل الآن',
            _statistics!.onlineUsers.toString(),
            FontAwesomeIcons.circle,
            const Color(0xFF4CAF50),
          ),
        ),
      ],
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
        color: const Color(0xFF0f1419),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          FaIcon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const FaIcon(
            FontAwesomeIcons.userSlash,
            color: Colors.white30,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد مستخدمين',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'لم يتم العثور على أي مستخدمين مطابقين للبحث',
            style: TextStyle(color: Colors.white54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddUserPage()),
            ).then((_) => _loadInitialData()),
            icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
            label: const Text('إضافة مستخدم جديد'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFffc107),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _users.length + (_hasMoreData ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _users.length) {
          return _buildLoadMoreIndicator();
        }
        return _buildUserCard(_users[index]);
      },
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: _isLoadingMore
          ? const CircularProgressIndicator(color: Color(0xFFffc107))
          : const SizedBox.shrink(),
    );
  }

  Widget _buildUserCard(AdminUser user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: user.isOnline ? const Color(0xFF4CAF50) : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToUserDetails(user),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // صورة المستخدم
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFFffc107),
                        backgroundImage: user.avatarUrl != null
                            ? NetworkImage(user.avatarUrl!)
                            : null,
                        child: user.avatarUrl == null
                            ? Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      if (user.isOnline)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF1a1a2e),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // معلومات المستخدم
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                user.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _buildUserStatusBadge(user),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.phone,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            FaIcon(
                              user.isAdmin
                                  ? FontAwesomeIcons.userTie
                                  : FontAwesomeIcons.user,
                              color: user.isAdmin
                                  ? const Color(0xFFFF9800)
                                  : const Color(0xFF2196F3),
                              size: 12,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              user.roleDisplay,
                              style: TextStyle(
                                color: user.isAdmin
                                    ? const Color(0xFFFF9800)
                                    : const Color(0xFF2196F3),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                            if (user.lastLogin != null) ...[
                              const FaIcon(
                                FontAwesomeIcons.clock,
                                color: Colors.white54,
                                size: 12,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatLastLogin(user.lastLogin!),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // أزرار الإجراءات
                  PopupMenuButton<String>(
                    icon: const FaIcon(
                      FontAwesomeIcons.ellipsisVertical,
                      color: Colors.white70,
                      size: 16,
                    ),
                    color: const Color(0xFF0f1419),
                    onSelected: (value) => _handleUserAction(user, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.eye,
                              color: Color(0xFF2196F3),
                              size: 16,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'عرض التفاصيل',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.edit,
                              color: Color(0xFFFF9800),
                              size: 16,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'تعديل',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: user.isActive ? 'deactivate' : 'activate',
                        child: Row(
                          children: [
                            FaIcon(
                              user.isActive
                                  ? FontAwesomeIcons.userSlash
                                  : FontAwesomeIcons.userCheck,
                              color: user.isActive
                                  ? const Color(0xFFF44336)
                                  : const Color(0xFF4CAF50),
                              size: 16,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              user.isActive ? 'تعطيل' : 'تفعيل',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.trash,
                              color: Color(0xFFF44336),
                              size: 16,
                            ),
                            SizedBox(width: 12),
                            Text('حذف', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserStatusBadge(AdminUser user) {
    Color color;
    String text;
    IconData icon;

    if (!user.isActive) {
      color = const Color(0xFFF44336);
      text = 'معطل';
      icon = FontAwesomeIcons.ban;
    } else if (user.isOnline) {
      color = const Color(0xFF4CAF50);
      text = 'متصل';
      icon = FontAwesomeIcons.circle;
    } else {
      color = const Color(0xFF2196F3);
      text = 'نشط';
      icon = FontAwesomeIcons.check;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, color: color, size: 10),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _navigateToAddUser(),
      backgroundColor: const Color(0xFFffc107),
      foregroundColor: Colors.black,
      icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
      label: const Text('إضافة مستخدم'),
    );
  }

  String _formatLastLogin(DateTime lastLogin) {
    final now = DateTime.now();
    final difference = now.difference(lastLogin);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return '${lastLogin.day}/${lastLogin.month}/${lastLogin.year}';
    }
  }

  void _navigateToUserDetails(AdminUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserDetailsPage(user: user)),
    ).then((result) {
      if (result == true) {
        _loadInitialData();
      }
    });
  }

  void _navigateToAddUser() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddUserPage()),
    ).then((result) {
      if (result == true) {
        _loadInitialData();
      }
    });
  }

  void _handleUserAction(AdminUser user, String action) {
    switch (action) {
      case 'view':
        _navigateToUserDetails(user);
        break;
      case 'edit':
        _editUser(user);
        break;
      case 'activate':
      case 'deactivate':
        _toggleUserStatus(user);
        break;
      case 'delete':
        _deleteUser(user);
        break;
    }
  }

  void _editUser(AdminUser user) {
    // TODO: Show edit user dialog
    _showErrorSnackBar('تعديل المستخدم قيد التطوير');
  }

  Future<void> _toggleUserStatus(AdminUser user) async {
    try {
      final success = await UserManagementService.toggleUserStatus(
        user.id,
        !user.isActive,
      );

      if (success) {
        _showSuccessSnackBar(
          user.isActive ? 'تم تعطيل المستخدم بنجاح' : 'تم تفعيل المستخدم بنجاح',
        );
        _loadInitialData();
      } else {
        _showErrorSnackBar('فشل في تغيير حالة المستخدم');
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في تغيير حالة المستخدم: $e');
    }
  }

  Future<void> _deleteUser(AdminUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
        content: Text(
          'هل أنت متأكد من حذف المستخدم "${user.name}"؟\nهذا الإجراء لا يمكن التراجع عنه.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await UserManagementService.deleteUser(user.id);

        if (success) {
          _showSuccessSnackBar('تم حذف المستخدم بنجاح');
          _loadInitialData();
        } else {
          _showErrorSnackBar('فشل في حذف المستخدم');
        }
      } catch (e) {
        _showErrorSnackBar('خطأ في حذف المستخدم: $e');
      }
    }
  }

  void _showStatisticsDialog() {
    if (_statistics == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text(
          'إحصائيات المستخدمين',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatRow(
                'إجمالي المستخدمين',
                _statistics!.totalUsers.toString(),
              ),
              _buildStatRow(
                'المستخدمين النشطين',
                _statistics!.activeUsers.toString(),
              ),
              _buildStatRow(
                'المستخدمين غير النشطين',
                _statistics!.inactiveUsers.toString(),
              ),
              _buildStatRow('المديرين', _statistics!.adminUsers.toString()),
              _buildStatRow(
                'المستخدمين العاديين',
                _statistics!.regularUsers.toString(),
              ),
              _buildStatRow(
                'المتصلين الآن',
                _statistics!.onlineUsers.toString(),
              ),
              const Divider(color: Colors.white30),
              _buildStatRow(
                'تسجيلات اليوم',
                _statistics!.todayRegistrations.toString(),
              ),
              _buildStatRow(
                'تسجيلات الأسبوع',
                _statistics!.weekRegistrations.toString(),
              ),
              _buildStatRow(
                'تسجيلات الشهر',
                _statistics!.monthRegistrations.toString(),
              ),
              const Divider(color: Colors.white30),
              _buildStatRow(
                'إجمالي المبيعات',
                '${_statistics!.totalSales.toStringAsFixed(0)} د.ع',
              ),
              _buildStatRow(
                'متوسط قيمة الطلب',
                '${_statistics!.averageOrderValue.toStringAsFixed(0)} د.ع',
              ),
              _buildStatRow(
                'إجمالي الطلبات',
                _statistics!.totalOrders.toString(),
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
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFffc107),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text(
          'فلترة المستخدمين',
          style: TextStyle(color: Colors.white),
        ),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // فلتر الحالة
              DropdownButtonFormField<String>(
                value: _statusFilter,
                decoration: const InputDecoration(
                  labelText: 'الحالة',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                dropdownColor: const Color(0xFF0f1419),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('الكل')),
                  DropdownMenuItem(value: 'active', child: Text('نشط')),
                  DropdownMenuItem(value: 'inactive', child: Text('غير نشط')),
                  DropdownMenuItem(value: 'admin', child: Text('مدير')),
                  DropdownMenuItem(value: 'user', child: Text('مستخدم عادي')),
                ],
                onChanged: (value) => setState(() => _statusFilter = value!),
              ),
              const SizedBox(height: 16),

              // فلتر الترتيب
              DropdownButtonFormField<String>(
                value: _sortBy,
                decoration: const InputDecoration(
                  labelText: 'ترتيب حسب',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                dropdownColor: const Color(0xFF0f1419),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(
                    value: 'created_at',
                    child: Text('تاريخ التسجيل'),
                  ),
                  DropdownMenuItem(value: 'name', child: Text('الاسم')),
                  DropdownMenuItem(
                    value: 'last_login',
                    child: Text('آخر دخول'),
                  ),
                  DropdownMenuItem(
                    value: 'total_orders',
                    child: Text('عدد الطلبات'),
                  ),
                  DropdownMenuItem(
                    value: 'total_sales',
                    child: Text('إجمالي المبيعات'),
                  ),
                ],
                onChanged: (value) => setState(() => _sortBy = value!),
              ),
              const SizedBox(height: 16),

              // اتجاه الترتيب
              SwitchListTile(
                title: const Text(
                  'ترتيب تصاعدي',
                  style: TextStyle(color: Colors.white),
                ),
                value: _ascending,
                onChanged: (value) => setState(() => _ascending = value),
                activeColor: const Color(0xFFffc107),
              ),
            ],
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
              _onFilterChanged();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFffc107),
              foregroundColor: Colors.black,
            ),
            child: const Text('تطبيق'),
          ),
        ],
      ),
    );
  }
}
