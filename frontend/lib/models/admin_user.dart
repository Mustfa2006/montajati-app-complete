// نموذج المستخدم للإدارة المتقدمة
class AdminUser {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String? password; // كلمة المرور (للعرض الإداري فقط)
  final bool isAdmin;
  final bool isActive;
  final bool isEmailVerified;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLogin;
  final DateTime? passwordChangedAt;

  // إحصائيات المستخدم
  final int totalOrders;
  final int totalProducts;
  final double totalSales;
  final double totalPurchases;
  final int completedOrders;
  final int cancelledOrders;
  final int pendingOrders;

  // الأرباح
  final double achievedProfits; // الأرباح المحققة
  final double expectedProfits; // الأرباح المنتظرة

  // معلومات إضافية
  final String? province;
  final String? city;
  final String? address;
  final String? notes;
  final List<String> roles;
  final Map<String, dynamic> permissions;
  final Map<String, dynamic> preferences;

  // حالة الحساب
  final String accountStatus; // active, suspended, banned, pending
  final String? suspensionReason;
  final DateTime? suspensionDate;
  final DateTime? suspensionExpiry;

  // إحصائيات النشاط
  final int loginCount;
  final DateTime? lastActivity;
  final String? lastIpAddress;
  final String? deviceInfo;

  AdminUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.password,
    this.isAdmin = false,
    this.isActive = true,
    this.isEmailVerified = false,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    this.lastLogin,
    this.passwordChangedAt,
    this.totalOrders = 0,
    this.totalProducts = 0,
    this.totalSales = 0.0,
    this.totalPurchases = 0.0,
    this.completedOrders = 0,
    this.cancelledOrders = 0,
    this.pendingOrders = 0,
    this.achievedProfits = 0.0,
    this.expectedProfits = 0.0,
    this.province,
    this.city,
    this.address,
    this.notes,
    this.roles = const [],
    this.permissions = const {},
    this.preferences = const {},
    this.accountStatus = 'active',
    this.suspensionReason,
    this.suspensionDate,
    this.suspensionExpiry,
    this.loginCount = 0,
    this.lastActivity,
    this.lastIpAddress,
    this.deviceInfo,
  });

  // إنشاء من JSON
  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      password: json['password']?.toString(), // كلمة المرور الأصلية
      isAdmin: json['is_admin'] ?? false,
      isActive: json['is_active'] ?? true,
      isEmailVerified: json['is_email_verified'] ?? false,
      avatarUrl: json['avatar_url'],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : null,
      passwordChangedAt: json['password_changed_at'] != null
          ? DateTime.parse(json['password_changed_at'])
          : null,
      totalOrders: json['total_orders'] ?? 0,
      totalProducts: json['total_products'] ?? 0,
      totalSales: (json['total_sales'] ?? 0.0).toDouble(),
      totalPurchases: (json['total_purchases'] ?? 0.0).toDouble(),
      completedOrders: json['completed_orders'] ?? 0,
      cancelledOrders: json['cancelled_orders'] ?? 0,
      pendingOrders: json['pending_orders'] ?? 0,
      achievedProfits: (json['achieved_profits'] ?? 0).toDouble(),
      expectedProfits: (json['expected_profits'] ?? 0).toDouble(),
      province: json['province'],
      city: json['city'],
      address: json['address'],
      notes: json['notes'],
      roles: List<String>.from(json['roles'] ?? []),
      permissions: Map<String, dynamic>.from(json['permissions'] ?? {}),
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      accountStatus: json['account_status'] ?? 'active',
      suspensionReason: json['suspension_reason'],
      suspensionDate: json['suspension_date'] != null
          ? DateTime.parse(json['suspension_date'])
          : null,
      suspensionExpiry: json['suspension_expiry'] != null
          ? DateTime.parse(json['suspension_expiry'])
          : null,
      loginCount: json['login_count'] ?? 0,
      lastActivity: json['last_activity'] != null
          ? DateTime.parse(json['last_activity'])
          : null,
      lastIpAddress: json['last_ip_address'],
      deviceInfo: json['device_info'],
    );
  }

  // تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'is_admin': isAdmin,
      'is_active': isActive,
      'is_email_verified': isEmailVerified,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'password_changed_at': passwordChangedAt?.toIso8601String(),
      'total_orders': totalOrders,
      'total_products': totalProducts,
      'total_sales': totalSales,
      'total_purchases': totalPurchases,
      'completed_orders': completedOrders,
      'cancelled_orders': cancelledOrders,
      'pending_orders': pendingOrders,
      'province': province,
      'city': city,
      'address': address,
      'notes': notes,
      'roles': roles,
      'permissions': permissions,
      'preferences': preferences,
      'account_status': accountStatus,
      'suspension_reason': suspensionReason,
      'suspension_date': suspensionDate?.toIso8601String(),
      'suspension_expiry': suspensionExpiry?.toIso8601String(),
      'login_count': loginCount,
      'last_activity': lastActivity?.toIso8601String(),
      'last_ip_address': lastIpAddress,
      'device_info': deviceInfo,
    };
  }

  // نسخ مع تعديل
  AdminUser copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    bool? isAdmin,
    bool? isActive,
    bool? isEmailVerified,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLogin,
    DateTime? passwordChangedAt,
    int? totalOrders,
    int? totalProducts,
    double? totalSales,
    double? totalPurchases,
    int? completedOrders,
    int? cancelledOrders,
    int? pendingOrders,
    String? province,
    String? city,
    String? address,
    String? notes,
    List<String>? roles,
    Map<String, dynamic>? permissions,
    Map<String, dynamic>? preferences,
    String? accountStatus,
    String? suspensionReason,
    DateTime? suspensionDate,
    DateTime? suspensionExpiry,
    int? loginCount,
    DateTime? lastActivity,
    String? lastIpAddress,
    String? deviceInfo,
  }) {
    return AdminUser(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isAdmin: isAdmin ?? this.isAdmin,
      isActive: isActive ?? this.isActive,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLogin: lastLogin ?? this.lastLogin,
      passwordChangedAt: passwordChangedAt ?? this.passwordChangedAt,
      totalOrders: totalOrders ?? this.totalOrders,
      totalProducts: totalProducts ?? this.totalProducts,
      totalSales: totalSales ?? this.totalSales,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      completedOrders: completedOrders ?? this.completedOrders,
      cancelledOrders: cancelledOrders ?? this.cancelledOrders,
      pendingOrders: pendingOrders ?? this.pendingOrders,
      province: province ?? this.province,
      city: city ?? this.city,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
      preferences: preferences ?? this.preferences,
      accountStatus: accountStatus ?? this.accountStatus,
      suspensionReason: suspensionReason ?? this.suspensionReason,
      suspensionDate: suspensionDate ?? this.suspensionDate,
      suspensionExpiry: suspensionExpiry ?? this.suspensionExpiry,
      loginCount: loginCount ?? this.loginCount,
      lastActivity: lastActivity ?? this.lastActivity,
      lastIpAddress: lastIpAddress ?? this.lastIpAddress,
      deviceInfo: deviceInfo ?? this.deviceInfo,
    );
  }

  // دوال مساعدة
  bool get isSuspended => accountStatus == 'suspended';
  bool get isBanned => accountStatus == 'banned';
  bool get isPending => accountStatus == 'pending';
  bool get isOnline =>
      lastActivity != null &&
      DateTime.now().difference(lastActivity!).inMinutes < 15;

  String get displayStatus {
    switch (accountStatus) {
      case 'active':
        return 'نشط';
      case 'suspended':
        return 'معلق';
      case 'banned':
        return 'محظور';
      case 'pending':
        return 'في الانتظار';
      default:
        return 'غير معروف';
    }
  }

  String get roleDisplay {
    if (isAdmin) return 'مدير';
    if (roles.isNotEmpty) return roles.join(', ');
    return 'مستخدم';
  }

  double get averageOrderValue {
    if (totalOrders == 0) return 0.0;
    return totalSales / totalOrders;
  }

  double get completionRate {
    if (totalOrders == 0) return 0.0;
    return (completedOrders / totalOrders) * 100;
  }

  double get cancellationRate {
    if (totalOrders == 0) return 0.0;
    return (cancelledOrders / totalOrders) * 100;
  }

  bool get isFrequentBuyer => totalOrders >= 5;

  bool get isHighValueCustomer => totalSales >= 500000; // 500,000 IQD

  String get customerTier {
    if (totalSales >= 1000000) return 'VIP';
    if (totalSales >= 500000) return 'ذهبي';
    if (totalSales >= 200000) return 'فضي';
    if (totalSales >= 50000) return 'برونزي';
    return 'عادي';
  }
}
