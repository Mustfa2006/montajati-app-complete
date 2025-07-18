import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/admin_user.dart';
import '../services/user_management_service.dart';

class UserDetailsPage extends StatefulWidget {
  final AdminUser user;

  const UserDetailsPage({super.key, required this.user});

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  AdminUser? _currentUser;
  bool _isLoading = true;
  final bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserDetails() async {
    setState(() => _isLoading = true);

    try {
      final user = await UserManagementService.getUserById(widget.user.id);
      setState(() {
        _currentUser = user ?? widget.user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _currentUser = widget.user;
        _isLoading = false;
      });
      _showErrorSnackBar('خطأ في تحميل تفاصيل المستخدم: $e');
    }
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
      title: Text(
        _currentUser?.name ?? 'تفاصيل المستخدم',
        style: const TextStyle(
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
          icon: FaIcon(
            _isEditing ? FontAwesomeIcons.check : FontAwesomeIcons.edit,
            color: Colors.white,
            size: 20,
          ),
          onPressed: _showEditUserDialog,
        ),
        PopupMenuButton<String>(
          icon: const FaIcon(
            FontAwesomeIcons.ellipsisVertical,
            color: Colors.white,
            size: 20,
          ),
          color: const Color(0xFF0f1419),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.arrowsRotate,
                    color: Color(0xFF2196F3),
                    size: 16,
                  ),
                  SizedBox(width: 12),
                  Text('تحديث', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              value: _currentUser?.isActive == true ? 'deactivate' : 'activate',
              child: Row(
                children: [
                  FaIcon(
                    _currentUser?.isActive == true
                        ? FontAwesomeIcons.userSlash
                        : FontAwesomeIcons.userCheck,
                    color: _currentUser?.isActive == true
                        ? const Color(0xFFF44336)
                        : const Color(0xFF4CAF50),
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _currentUser?.isActive == true ? 'تعطيل' : 'تفعيل',
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
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFFffc107),
        labelColor: const Color(0xFFffc107),
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(icon: FaIcon(FontAwesomeIcons.user, size: 16), text: 'المعلومات'),
          Tab(
            icon: FaIcon(FontAwesomeIcons.chartLine, size: 16),
            text: 'الإحصائيات',
          ),
          Tab(
            icon: FaIcon(FontAwesomeIcons.shoppingCart, size: 16),
            text: 'الطلبات',
          ),
          Tab(
            icon: FaIcon(FontAwesomeIcons.clockRotateLeft, size: 16),
            text: 'النشاط',
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFffc107)),
          SizedBox(height: 16),
          Text(
            'جاري تحميل تفاصيل المستخدم...',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_currentUser == null) {
      return const Center(
        child: Text(
          'لم يتم العثور على المستخدم',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return Column(
      children: [
        _buildUserHeader(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildUserInfoTab(),
              _buildStatisticsTab(),
              _buildOrdersTab(),
              _buildActivityTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1a1a2e),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // صورة المستخدم
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFFffc107),
                backgroundImage: _currentUser!.avatarUrl != null
                    ? NetworkImage(_currentUser!.avatarUrl!)
                    : null,
                child: _currentUser!.avatarUrl == null
                    ? Text(
                        _currentUser!.name.isNotEmpty
                            ? _currentUser!.name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              if (_currentUser!.isOnline)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF1a1a2e),
                        width: 3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 20),

          // معلومات المستخدم
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentUser!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentUser!.phone,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentUser!.email,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatusBadge(),
                    const SizedBox(width: 12),
                    _buildRoleBadge(),
                  ],
                ),
              ],
            ),
          ),

          // إحصائيات سريعة
          Column(
            children: [
              _buildQuickStat('الطلبات', _currentUser!.totalOrders.toString()),
              const SizedBox(height: 8),
              _buildQuickStat(
                'المبيعات',
                '${_currentUser!.totalSales.toStringAsFixed(0)} د.ع',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;
    IconData icon;

    if (!_currentUser!.isActive) {
      color = const Color(0xFFF44336);
      text = 'معطل';
      icon = FontAwesomeIcons.ban;
    } else if (_currentUser!.isOnline) {
      color = const Color(0xFF4CAF50);
      text = 'متصل';
      icon = FontAwesomeIcons.circle;
    } else {
      color = const Color(0xFF2196F3);
      text = 'نشط';
      icon = FontAwesomeIcons.check;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, color: color, size: 12),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _currentUser!.isAdmin
            ? const Color(0xFFFF9800).withOpacity(0.2)
            : const Color(0xFF2196F3).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _currentUser!.isAdmin
              ? const Color(0xFFFF9800).withOpacity(0.5)
              : const Color(0xFF2196F3).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            _currentUser!.isAdmin
                ? FontAwesomeIcons.userTie
                : FontAwesomeIcons.user,
            color: _currentUser!.isAdmin
                ? const Color(0xFFFF9800)
                : const Color(0xFF2196F3),
            size: 12,
          ),
          const SizedBox(width: 6),
          Text(
            _currentUser!.roleDisplay,
            style: TextStyle(
              color: _currentUser!.isAdmin
                  ? const Color(0xFFFF9800)
                  : const Color(0xFF2196F3),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFffc107),
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

  Widget _buildUserInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard('المعلومات الشخصية', [
            _buildInfoRow(
              'الاسم الكامل',
              _currentUser!.name,
              FontAwesomeIcons.user,
            ),
            _buildInfoRow(
              'رقم الهاتف',
              _currentUser!.phone,
              FontAwesomeIcons.phone,
            ),
            _buildInfoRow(
              'البريد الإلكتروني',
              _currentUser!.email,
              FontAwesomeIcons.envelope,
            ),
            _buildPasswordRow(), // إضافة كلمة المرور هنا
            _buildInfoRow(
              'تاريخ التسجيل',
              _formatDate(_currentUser!.createdAt),
              FontAwesomeIcons.calendar,
            ),
            if (_currentUser!.lastLogin != null)
              _buildInfoRow(
                'آخر دخول',
                _formatDate(_currentUser!.lastLogin!),
                FontAwesomeIcons.clock,
              ),
          ]),

          const SizedBox(height: 16),

          if (_currentUser!.province != null ||
              _currentUser!.city != null ||
              _currentUser!.address != null)
            _buildInfoCard('معلومات العنوان', [
              if (_currentUser!.province != null)
                _buildInfoRow(
                  'المحافظة',
                  _currentUser!.province!,
                  FontAwesomeIcons.mapMarkerAlt,
                ),
              if (_currentUser!.city != null)
                _buildInfoRow(
                  'المدينة',
                  _currentUser!.city!,
                  FontAwesomeIcons.city,
                ),
              if (_currentUser!.address != null)
                _buildInfoRow(
                  'العنوان',
                  _currentUser!.address!,
                  FontAwesomeIcons.home,
                ),
            ]),

          const SizedBox(height: 16),

          _buildProfitsCard(), // إضافة قسم الأرباح

          const SizedBox(height: 16),

          _buildInfoCard('معلومات الحساب', [
            _buildInfoRow(
              'حالة الحساب',
              _currentUser!.displayStatus,
              FontAwesomeIcons.userCheck,
            ),
            _buildInfoRow(
              'نوع المستخدم',
              _currentUser!.roleDisplay,
              FontAwesomeIcons.userTie,
            ),
            _buildInfoRow(
              'تم التحقق من البريد',
              _currentUser!.isEmailVerified ? 'نعم' : 'لا',
              FontAwesomeIcons.envelope,
            ),
            _buildInfoRow(
              'عدد مرات الدخول',
              _currentUser!.loginCount.toString(),
              FontAwesomeIcons.signInAlt,
            ),
          ]),

          if (_currentUser!.notes != null &&
              _currentUser!.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoCard('ملاحظات', [
              _buildInfoRow(
                'ملاحظات',
                _currentUser!.notes!,
                FontAwesomeIcons.stickyNote,
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x000ff333), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFffc107),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          FaIcon(icon, color: Colors.white54, size: 14),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // دالة خاصة لعرض كلمة المرور مع إمكانية إظهار/إخفاء
  Widget _buildPasswordRow() {
    bool isPasswordVisible = false;

    return StatefulBuilder(
      builder: (context, setState) {
        // استخدام كلمة المرور الحقيقية من قاعدة البيانات فقط
        final password = _currentUser!.password ?? 'لم يتم تعيين كلمة مرور';

        // طباعة للتشخيص
        debugPrint('🔐 كلمة المرور للمستخدم ${_currentUser!.name}: $password');

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.key,
                color: Colors.white54,
                size: 14,
              ),
              const SizedBox(width: 12),
              const Expanded(
                flex: 2,
                child: Text(
                  'كلمة المرور',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        isPasswordVisible ? password : '••••••••',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: FaIcon(
                        isPasswordVisible
                            ? FontAwesomeIcons.eyeSlash
                            : FontAwesomeIcons.eye,
                        color: const Color(0xFFffc107),
                        size: 16,
                      ),
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    ),
                    IconButton(
                      icon: const FaIcon(
                        FontAwesomeIcons.copy,
                        color: Color(0xFFffc107),
                        size: 16,
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: password));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم نسخ كلمة المرور'),
                            backgroundColor: Color(0xFF4CAF50),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // قسم الأرباح مع إمكانية التعديل
  Widget _buildProfitsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFffc107), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الأرباح',
                style: TextStyle(
                  color: Color(0xFFffc107),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const FaIcon(
                  FontAwesomeIcons.edit,
                  color: Color(0xFFffc107),
                  size: 16,
                ),
                onPressed: _showEditProfitsDialog,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildProfitItem(
                  'الأرباح المحققة',
                  '${_currentUser!.achievedProfits.toStringAsFixed(2)} د.ع',
                  FontAwesomeIcons.checkCircle,
                  const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProfitItem(
                  'الأرباح المنتظرة',
                  '${_currentUser!.expectedProfits.toStringAsFixed(2)} د.ع',
                  FontAwesomeIcons.clock,
                  const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfitItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          FaIcon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // دالة تعديل الأرباح
  void _showEditProfitsDialog() {
    final achievedController = TextEditingController(
      text: _currentUser!.achievedProfits.toString(),
    );
    final expectedController = TextEditingController(
      text: _currentUser!.expectedProfits.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text(
          'تعديل الأرباح',
          style: TextStyle(color: Color(0xFFffc107)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: achievedController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'الأرباح المحققة',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFffc107)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFffc107)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: expectedController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'الأرباح المنتظرة',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFffc107)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFffc107)),
                ),
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
            onPressed: () => _updateProfits(
              double.tryParse(achievedController.text) ?? 0.0,
              double.tryParse(expectedController.text) ?? 0.0,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFffc107),
            ),
            child: const Text('حفظ', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // دالة تحديث الأرباح
  void _updateProfits(double achieved, double expected) async {
    try {
      // تحديث في قاعدة البيانات (يمكن إضافة جدول منفصل للأرباح)
      await UserManagementService.updateUserProfits(
        _currentUser!.id,
        achieved,
        expected,
      );

      // تحديث البيانات المحلية
      setState(() {
        _currentUser = AdminUser(
          id: _currentUser!.id,
          name: _currentUser!.name,
          phone: _currentUser!.phone,
          email: _currentUser!.email,
          password: _currentUser!.password,
          isAdmin: _currentUser!.isAdmin,
          isActive: _currentUser!.isActive,
          isEmailVerified: _currentUser!.isEmailVerified,
          avatarUrl: _currentUser!.avatarUrl,
          createdAt: _currentUser!.createdAt,
          updatedAt: _currentUser!.updatedAt,
          lastLogin: _currentUser!.lastLogin,
          passwordChangedAt: _currentUser!.passwordChangedAt,
          totalOrders: _currentUser!.totalOrders,
          totalProducts: _currentUser!.totalProducts,
          totalSales: _currentUser!.totalSales,
          totalPurchases: _currentUser!.totalPurchases,
          completedOrders: _currentUser!.completedOrders,
          cancelledOrders: _currentUser!.cancelledOrders,
          pendingOrders: _currentUser!.pendingOrders,
          achievedProfits: achieved,
          expectedProfits: expected,
          province: _currentUser!.province,
          city: _currentUser!.city,
          address: _currentUser!.address,
          notes: _currentUser!.notes,
          roles: _currentUser!.roles,
          permissions: _currentUser!.permissions,
          preferences: _currentUser!.preferences,
          accountStatus: _currentUser!.accountStatus,
          suspensionReason: _currentUser!.suspensionReason,
          suspensionDate: _currentUser!.suspensionDate,
          suspensionExpiry: _currentUser!.suspensionExpiry,
          loginCount: _currentUser!.loginCount,
          lastActivity: _currentUser!.lastActivity,
          lastIpAddress: _currentUser!.lastIpAddress,
          deviceInfo: _currentUser!.deviceInfo,
        );
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث الأرباح بنجاح'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحديث الأرباح: $e'),
          backgroundColor: const Color(0xFFF44336),
        ),
      );
    }
  }

  // دالة تعديل المستخدم الشاملة
  void _showEditUserDialog() {
    debugPrint('🔄 فتح نافذة تعديل المستخدم');

    if (_currentUser == null) {
      debugPrint('❌ المستخدم غير موجود');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ: بيانات المستخدم غير متوفرة'),
          backgroundColor: Color(0xFFF44336),
        ),
      );
      return;
    }
    final nameController = TextEditingController(text: _currentUser!.name);
    final phoneController = TextEditingController(text: _currentUser!.phone);
    final emailController = TextEditingController(text: _currentUser!.email);
    final passwordController = TextEditingController(
      text: _currentUser!.password ?? '',
    );
    final provinceController = TextEditingController(
      text: _currentUser!.province ?? '',
    );
    final cityController = TextEditingController(
      text: _currentUser!.city ?? '',
    );
    final addressController = TextEditingController(
      text: _currentUser!.address ?? '',
    );
    final notesController = TextEditingController(
      text: _currentUser!.notes ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text(
          'تعديل بيانات المستخدم',
          style: TextStyle(color: Color(0xFFffc107)),
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEditField('الاسم', nameController),
                const SizedBox(height: 12),
                _buildEditField('رقم الهاتف', phoneController),
                const SizedBox(height: 12),
                _buildEditField('البريد الإلكتروني', emailController),
                const SizedBox(height: 12),
                _buildPasswordEditField(passwordController),
                const SizedBox(height: 12),
                _buildEditField('المحافظة', provinceController),
                const SizedBox(height: 12),
                _buildEditField('المدينة', cityController),
                const SizedBox(height: 12),
                _buildEditField('العنوان', addressController),
                const SizedBox(height: 12),
                _buildEditField('ملاحظات', notesController, maxLines: 3),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Map<String, String> updates = {
                'name': nameController.text,
                'phone': phoneController.text,
                'email': emailController.text,
                'province': provinceController.text,
                'city': cityController.text,
                'address': addressController.text,
                'notes': notesController.text,
              };

              // إضافة كلمة المرور فقط إذا لم تكن فارغة
              if (passwordController.text.isNotEmpty) {
                updates['password'] = passwordController.text;
              }

              _updateUserData(updates);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFffc107),
            ),
            child: const Text(
              'حفظ التغييرات',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFffc107)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFffc107)),
        ),
      ),
    );
  }

  // حقل خاص لتعديل كلمة المرور مع إظهار/إخفاء
  Widget _buildPasswordEditField(TextEditingController controller) {
    bool isPasswordVisible = false;

    return StatefulBuilder(
      builder: (context, setStateLocal) {
        return TextField(
          controller: controller,
          obscureText: !isPasswordVisible,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'كلمة المرور',
            labelStyle: const TextStyle(color: Colors.white70),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white30),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFffc107)),
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white54,
                  ),
                  onPressed: () {
                    setStateLocal(() {
                      isPasswordVisible = !isPasswordVisible;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white54),
                  onPressed: () {
                    // توليد كلمة مرور عشوائية
                    controller.text = _generateRandomPassword();
                  },
                  tooltip: 'توليد كلمة مرور عشوائية',
                ),
              ],
            ),
            helperText: 'اتركه فارغاً إذا كنت لا تريد تغيير كلمة المرور',
            helperStyle: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        );
      },
    );
  }

  // توليد كلمة مرور عشوائية
  String _generateRandomPassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(
      8,
      (index) => chars[(random + index) % chars.length],
    ).join();
  }

  // دالة تحديث بيانات المستخدم
  void _updateUserData(Map<String, String> data) async {
    try {
      final updatedUser = await UserManagementService.updateUser(
        _currentUser!.id,
        data,
      );

      if (updatedUser != null) {
        setState(() {
          _currentUser = updatedUser;
        });

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث بيانات المستخدم بنجاح'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحديث البيانات: $e'),
          backgroundColor: const Color(0xFFF44336),
        ),
      );
    }
  }

  Widget _buildStatisticsTab() {
    if (_currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // إحصائيات الطلبات
          _buildStatCard('إحصائيات الطلبات', [
            _buildStatRow(
              'إجمالي الطلبات',
              _currentUser!.totalOrders.toString(),
              FontAwesomeIcons.shoppingCart,
              const Color(0xFF2196F3),
            ),
            _buildStatRow(
              'الطلبات المكتملة',
              _currentUser!.completedOrders.toString(),
              FontAwesomeIcons.checkCircle,
              const Color(0xFF4CAF50),
            ),
            _buildStatRow(
              'الطلبات الملغية',
              _currentUser!.cancelledOrders.toString(),
              FontAwesomeIcons.timesCircle,
              const Color(0xFFF44336),
            ),
            _buildStatRow(
              'الطلبات المعلقة',
              _currentUser!.pendingOrders.toString(),
              FontAwesomeIcons.clock,
              const Color(0xFFFF9800),
            ),
          ]),

          const SizedBox(height: 16),

          // إحصائيات المبيعات
          _buildStatCard('إحصائيات المبيعات', [
            _buildStatRow(
              'إجمالي المبيعات',
              '${_currentUser!.totalSales.toStringAsFixed(0)} د.ع',
              FontAwesomeIcons.dollarSign,
              const Color(0xFF4CAF50),
            ),
            _buildStatRow(
              'متوسط قيمة الطلب',
              '${_currentUser!.averageOrderValue.toStringAsFixed(0)} د.ع',
              FontAwesomeIcons.chartBar,
              const Color(0xFF2196F3),
            ),
            _buildStatRow(
              'معدل الإكمال',
              '${_currentUser!.completionRate.toStringAsFixed(1)}%',
              FontAwesomeIcons.percentage,
              const Color(0xFFFF9800),
            ),
            _buildStatRow(
              'معدل الإلغاء',
              '${_currentUser!.cancellationRate.toStringAsFixed(1)}%',
              FontAwesomeIcons.ban,
              const Color(0xFFF44336),
            ),
          ]),

          const SizedBox(height: 16),

          // تصنيف العميل
          _buildStatCard('تصنيف العميل', [
            _buildStatRow(
              'مستوى العميل',
              _currentUser!.customerTier,
              FontAwesomeIcons.crown,
              _getTierColor(_currentUser!.customerTier),
            ),
            _buildStatRow(
              'عميل متكرر',
              _currentUser!.isFrequentBuyer ? 'نعم' : 'لا',
              FontAwesomeIcons.repeat,
              _currentUser!.isFrequentBuyer
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFF757575),
            ),
            _buildStatRow(
              'عميل عالي القيمة',
              _currentUser!.isHighValueCustomer ? 'نعم' : 'لا',
              FontAwesomeIcons.gem,
              _currentUser!.isHighValueCustomer
                  ? const Color(0xFFFFD700)
                  : const Color(0xFF757575),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FontAwesomeIcons.shoppingCart,
            color: Colors.white30,
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'طلبات المستخدم',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'قيد التطوير - سيتم عرض طلبات المستخدم هنا',
            style: TextStyle(color: Colors.white54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FontAwesomeIcons.clockRotateLeft,
            color: Colors.white30,
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'سجل النشاط',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'قيد التطوير - سيتم عرض سجل نشاط المستخدم هنا',
            style: TextStyle(color: Colors.white54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        debugPrint('🔄 تم الضغط على زر التعديل');
        _showEditUserDialog();
      },
      backgroundColor: const Color(0xFFffc107),
      foregroundColor: Colors.black,
      icon: const FaIcon(FontAwesomeIcons.edit, size: 16),
      label: const Text('تعديل'),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildStatCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x000ff333), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFffc107),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FaIcon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
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

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'VIP':
        return const Color(0xFFFFD700);
      case 'ذهبي':
        return const Color(0xFFFFD700);
      case 'فضي':
        return const Color(0xFFC0C0C0);
      case 'برونزي':
        return const Color(0xFFCD7F32);
      default:
        return const Color(0xFF757575);
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'refresh':
        _loadUserDetails();
        break;
      case 'activate':
      case 'deactivate':
        _toggleUserStatus();
        break;
      case 'delete':
        _deleteUser();
        break;
    }
  }

  Future<void> _toggleUserStatus() async {
    try {
      final success = await UserManagementService.toggleUserStatus(
        _currentUser!.id,
        !_currentUser!.isActive,
      );

      if (success) {
        _showSuccessSnackBar(
          _currentUser!.isActive
              ? 'تم تعطيل المستخدم بنجاح'
              : 'تم تفعيل المستخدم بنجاح',
        );
        _loadUserDetails();
      } else {
        _showErrorSnackBar('فشل في تغيير حالة المستخدم');
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في تغيير حالة المستخدم: $e');
    }
  }

  Future<void> _deleteUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
        content: Text(
          'هل أنت متأكد من حذف المستخدم "${_currentUser!.name}"؟\nهذا الإجراء لا يمكن التراجع عنه.',
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
        final success = await UserManagementService.deleteUser(
          _currentUser!.id,
        );

        if (success) {
          _showSuccessSnackBar('تم حذف المستخدم بنجاح');
          Navigator.pop(context, true);
        } else {
          _showErrorSnackBar('فشل في حذف المستخدم');
        }
      } catch (e) {
        _showErrorSnackBar('خطأ في حذف المستخدم: $e');
      }
    }
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
