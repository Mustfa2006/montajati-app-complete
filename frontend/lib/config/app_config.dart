// ===================================
// إعدادات التطبيق - App Configuration
// ===================================

/// إعدادات التطبيق المركزية
/// يحتوي على جميع الثوابت والإعدادات المستخدمة في التطبيق
class AppConfig {
  // ===================================
  // Backend API Configuration
  // ===================================
  
  /// رابط الخادم الخلفي (Backend)
  /// يمكن تغييره من خلال Environment Variables
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://montajati-official-backend-production.up.railway.app',
  );
  
  /// رابط API الطلبات
  static String get ordersApiUrl => '$backendBaseUrl/api/orders';
  
  // ===================================
  // API Endpoints
  // ===================================
  
  /// جلب طلبات المستخدم
  static String getUserOrdersUrl(String userPhone, {int page = 0, int limit = 10}) {
    return '$ordersApiUrl/user/$userPhone?page=$page&limit=$limit';
  }
  
  /// جلب عدادات الطلبات
  static String getOrderCountsUrl(String userPhone) {
    return '$ordersApiUrl/user/$userPhone/counts';
  }
  
  /// جلب الطلبات المجدولة
  static String getScheduledOrdersUrl(String userPhone, {int page = 0, int limit = 10}) {
    return '$ordersApiUrl/scheduled-orders/user/$userPhone?page=$page&limit=$limit';
  }
  
  /// حذف طلب
  static String deleteOrderUrl(String orderId, String userPhone) {
    return '$ordersApiUrl/$orderId?userPhone=$userPhone';
  }
  
  /// تعديل طلب
  static String updateOrderUrl(String orderId) {
    return '$ordersApiUrl/$orderId';
  }
  
  /// حذف طلب مجدول
  static String deleteScheduledOrderUrl(String orderId, String userPhone) {
    return '$ordersApiUrl/scheduled-orders/$orderId?userPhone=$userPhone';
  }
  
  // ===================================
  // Timeout Configuration
  // ===================================
  
  /// مهلة الانتظار للطلبات (بالثواني)
  static const int requestTimeoutSeconds = 10;
  
  /// مدة الـ Debounce للـ Scroll (بالميلي ثانية)
  static const int scrollDebounceDuration = 300;
  
  // ===================================
  // Pagination Configuration
  // ===================================
  
  /// عدد العناصر في كل صفحة
  static const int defaultPageSize = 10;
  
  /// المسافة من نهاية القائمة لبدء التحميل (بالبكسل)
  static const double scrollLoadThreshold = 200;
}

