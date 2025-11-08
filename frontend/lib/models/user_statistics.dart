// نموذج إحصائيات المستخدمين
class UserStatistics {
  final int totalUsers;
  final int activeUsers;
  final int inactiveUsers;
  final int adminUsers;
  final int regularUsers;
  final int suspendedUsers;
  final int bannedUsers;
  final int pendingUsers;
  final int verifiedUsers;
  final int unverifiedUsers;
  
  // إحصائيات النشاط
  final int onlineUsers;
  final int todayRegistrations;
  final int weekRegistrations;
  final int monthRegistrations;
  final int todayLogins;
  final int weekLogins;
  final int monthLogins;
  
  // إحصائيات الطلبات
  final double totalSales;
  final double averageOrderValue;
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final int pendingOrders;
  
  // إحصائيات زمنية
  final DateTime lastUpdated;
  final Map<String, int> registrationsByMonth;
  final Map<String, int> loginsByDay;
  final Map<String, double> salesByMonth;
  final Map<String, int> ordersByStatus;
  
  // إحصائيات جغرافية
  final Map<String, int> usersByProvince;
  final Map<String, int> usersByCity;
  
  // إحصائيات الأجهزة
  final Map<String, int> usersByDevice;
  final Map<String, int> usersByPlatform;
  
  UserStatistics({
    this.totalUsers = 0,
    this.activeUsers = 0,
    this.inactiveUsers = 0,
    this.adminUsers = 0,
    this.regularUsers = 0,
    this.suspendedUsers = 0,
    this.bannedUsers = 0,
    this.pendingUsers = 0,
    this.verifiedUsers = 0,
    this.unverifiedUsers = 0,
    this.onlineUsers = 0,
    this.todayRegistrations = 0,
    this.weekRegistrations = 0,
    this.monthRegistrations = 0,
    this.todayLogins = 0,
    this.weekLogins = 0,
    this.monthLogins = 0,
    this.totalSales = 0.0,
    this.averageOrderValue = 0.0,
    this.totalOrders = 0,
    this.completedOrders = 0,
    this.cancelledOrders = 0,
    this.pendingOrders = 0,
    required this.lastUpdated,
    this.registrationsByMonth = const {},
    this.loginsByDay = const {},
    this.salesByMonth = const {},
    this.ordersByStatus = const {},
    this.usersByProvince = const {},
    this.usersByCity = const {},
    this.usersByDevice = const {},
    this.usersByPlatform = const {},
  });

  factory UserStatistics.fromJson(Map<String, dynamic> json) {
    return UserStatistics(
      totalUsers: json['total_users'] ?? 0,
      activeUsers: json['active_users'] ?? 0,
      inactiveUsers: json['inactive_users'] ?? 0,
      adminUsers: json['admin_users'] ?? 0,
      regularUsers: json['regular_users'] ?? 0,
      suspendedUsers: json['suspended_users'] ?? 0,
      bannedUsers: json['banned_users'] ?? 0,
      pendingUsers: json['pending_users'] ?? 0,
      verifiedUsers: json['verified_users'] ?? 0,
      unverifiedUsers: json['unverified_users'] ?? 0,
      onlineUsers: json['online_users'] ?? 0,
      todayRegistrations: json['today_registrations'] ?? 0,
      weekRegistrations: json['week_registrations'] ?? 0,
      monthRegistrations: json['month_registrations'] ?? 0,
      todayLogins: json['today_logins'] ?? 0,
      weekLogins: json['week_logins'] ?? 0,
      monthLogins: json['month_logins'] ?? 0,
      totalSales: (json['total_sales'] ?? 0.0).toDouble(),
      averageOrderValue: (json['average_order_value'] ?? 0.0).toDouble(),
      totalOrders: json['total_orders'] ?? 0,
      completedOrders: json['completed_orders'] ?? 0,
      cancelledOrders: json['cancelled_orders'] ?? 0,
      pendingOrders: json['pending_orders'] ?? 0,
      lastUpdated: DateTime.parse(json['last_updated'] ?? DateTime.now().toIso8601String()),
      registrationsByMonth: Map<String, int>.from(json['registrations_by_month'] ?? {}),
      loginsByDay: Map<String, int>.from(json['logins_by_day'] ?? {}),
      salesByMonth: Map<String, double>.from(json['sales_by_month'] ?? {}),
      ordersByStatus: Map<String, int>.from(json['orders_by_status'] ?? {}),
      usersByProvince: Map<String, int>.from(json['users_by_province'] ?? {}),
      usersByCity: Map<String, int>.from(json['users_by_city'] ?? {}),
      usersByDevice: Map<String, int>.from(json['users_by_device'] ?? {}),
      usersByPlatform: Map<String, int>.from(json['users_by_platform'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_users': totalUsers,
      'active_users': activeUsers,
      'inactive_users': inactiveUsers,
      'admin_users': adminUsers,
      'regular_users': regularUsers,
      'suspended_users': suspendedUsers,
      'banned_users': bannedUsers,
      'pending_users': pendingUsers,
      'verified_users': verifiedUsers,
      'unverified_users': unverifiedUsers,
      'online_users': onlineUsers,
      'today_registrations': todayRegistrations,
      'week_registrations': weekRegistrations,
      'month_registrations': monthRegistrations,
      'today_logins': todayLogins,
      'week_logins': weekLogins,
      'month_logins': monthLogins,
      'total_sales': totalSales,
      'average_order_value': averageOrderValue,
      'total_orders': totalOrders,
      'completed_orders': completedOrders,
      'cancelled_orders': cancelledOrders,
      'pending_orders': pendingOrders,
      'last_updated': lastUpdated.toIso8601String(),
      'registrations_by_month': registrationsByMonth,
      'logins_by_day': loginsByDay,
      'sales_by_month': salesByMonth,
      'orders_by_status': ordersByStatus,
      'users_by_province': usersByProvince,
      'users_by_city': usersByCity,
      'users_by_device': usersByDevice,
      'users_by_platform': usersByPlatform,
    };
  }

  // دوال مساعدة للحصول على النسب المئوية
  double get activeUsersPercentage {
    if (totalUsers == 0) return 0.0;
    return (activeUsers / totalUsers) * 100;
  }

  double get adminUsersPercentage {
    if (totalUsers == 0) return 0.0;
    return (adminUsers / totalUsers) * 100;
  }

  double get verifiedUsersPercentage {
    if (totalUsers == 0) return 0.0;
    return (verifiedUsers / totalUsers) * 100;
  }

  double get completionRate {
    if (totalOrders == 0) return 0.0;
    return (completedOrders / totalOrders) * 100;
  }

  double get cancellationRate {
    if (totalOrders == 0) return 0.0;
    return (cancelledOrders / totalOrders) * 100;
  }

  // نمو التسجيلات
  double get weeklyGrowthRate {
    if (weekRegistrations == 0) return 0.0;
    return ((todayRegistrations * 7) / weekRegistrations - 1) * 100;
  }

  double get monthlyGrowthRate {
    if (monthRegistrations == 0) return 0.0;
    return ((weekRegistrations * 4) / monthRegistrations - 1) * 100;
  }

  // أكثر المحافظات نشاطاً
  String get topProvince {
    if (usersByProvince.isEmpty) return 'غير محدد';
    return usersByProvince.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // أكثر المدن نشاطاً
  String get topCity {
    if (usersByCity.isEmpty) return 'غير محدد';
    return usersByCity.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // أكثر الأجهزة استخداماً
  String get topDevice {
    if (usersByDevice.isEmpty) return 'غير محدد';
    return usersByDevice.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // أكثر المنصات استخداماً
  String get topPlatform {
    if (usersByPlatform.isEmpty) return 'غير محدد';
    return usersByPlatform.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}

// نموذج إحصائيات المستخدم الفردي
class IndividualUserStatistics {
  final String userId;
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final int pendingOrders;
  final double totalSpent;
  final double averageOrderValue;
  final int totalProducts;
  final int loginCount;
  final DateTime? lastLogin;
  final DateTime? lastActivity;
  final List<Map<String, dynamic>> recentOrders;
  final List<Map<String, dynamic>> favoriteProducts;
  final Map<String, int> ordersByMonth;
  final Map<String, double> spendingByMonth;
  final Map<String, int> activityByDay;

  IndividualUserStatistics({
    required this.userId,
    this.totalOrders = 0,
    this.completedOrders = 0,
    this.cancelledOrders = 0,
    this.pendingOrders = 0,
    this.totalSpent = 0.0,
    this.averageOrderValue = 0.0,
    this.totalProducts = 0,
    this.loginCount = 0,
    this.lastLogin,
    this.lastActivity,
    this.recentOrders = const [],
    this.favoriteProducts = const [],
    this.ordersByMonth = const {},
    this.spendingByMonth = const {},
    this.activityByDay = const {},
  });

  factory IndividualUserStatistics.fromJson(Map<String, dynamic> json) {
    return IndividualUserStatistics(
      userId: json['user_id'] ?? '',
      totalOrders: json['total_orders'] ?? 0,
      completedOrders: json['completed_orders'] ?? 0,
      cancelledOrders: json['cancelled_orders'] ?? 0,
      pendingOrders: json['pending_orders'] ?? 0,
      totalSpent: (json['total_spent'] ?? 0.0).toDouble(),
      averageOrderValue: (json['average_order_value'] ?? 0.0).toDouble(),
      totalProducts: json['total_products'] ?? 0,
      loginCount: json['login_count'] ?? 0,
      lastLogin: json['last_login'] != null ? DateTime.parse(json['last_login']) : null,
      lastActivity: json['last_activity'] != null ? DateTime.parse(json['last_activity']) : null,
      recentOrders: List<Map<String, dynamic>>.from(json['recent_orders'] ?? []),
      favoriteProducts: List<Map<String, dynamic>>.from(json['favorite_products'] ?? []),
      ordersByMonth: Map<String, int>.from(json['orders_by_month'] ?? {}),
      spendingByMonth: Map<String, double>.from(json['spending_by_month'] ?? {}),
      activityByDay: Map<String, int>.from(json['activity_by_day'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'total_orders': totalOrders,
      'completed_orders': completedOrders,
      'cancelled_orders': cancelledOrders,
      'pending_orders': pendingOrders,
      'total_spent': totalSpent,
      'average_order_value': averageOrderValue,
      'total_products': totalProducts,
      'login_count': loginCount,
      'last_login': lastLogin?.toIso8601String(),
      'last_activity': lastActivity?.toIso8601String(),
      'recent_orders': recentOrders,
      'favorite_products': favoriteProducts,
      'orders_by_month': ordersByMonth,
      'spending_by_month': spendingByMonth,
      'activity_by_day': activityByDay,
    };
  }

  double get completionRate {
    if (totalOrders == 0) return 0.0;
    return (completedOrders / totalOrders) * 100;
  }

  double get cancellationRate {
    if (totalOrders == 0) return 0.0;
    return (cancelledOrders / totalOrders) * 100;
  }

  bool get isActiveUser => lastActivity != null && 
    DateTime.now().difference(lastActivity!).inDays < 30;

  bool get isFrequentBuyer => totalOrders >= 5;

  bool get isHighValueCustomer => totalSpent >= 500000; // 500,000 IQD

  String get customerTier {
    if (totalSpent >= 1000000) return 'VIP';
    if (totalSpent >= 500000) return 'ذهبي';
    if (totalSpent >= 200000) return 'فضي';
    if (totalSpent >= 50000) return 'برونزي';
    return 'عادي';
  }
}
