import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  static final _supabase = Supabase.instance.client;

  // مفاتيح التخزين المحلي
  static const String _keyUserId = 'current_user_id';
  static const String _keyUserName = 'current_user_name';
  static const String _keyUserPhone = 'current_user_phone';
  static const String _keyIsDataLoaded = 'user_data_loaded';

  /// تحميل وحفظ بيانات المستخدم عند تسجيل الدخول (يتم استدعاؤها مرة واحدة فقط)
  static Future<void> loadAndSaveUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // الحصول على البيانات المحفوظة من AuthService
      final userId = prefs.getString('current_user_id');
      final userName = prefs.getString('current_user_name');
      final userPhone = prefs.getString('current_user_phone');

      if (userId == null || userName == null || userPhone == null) {
        debugPrint('❌ لا توجد بيانات مستخدم محفوظة من AuthService');
        return;
      }

      // التحقق من أن البيانات لم تُحفظ مسبقاً في UserService
      final savedUserId = prefs.getString(_keyUserId);
      if (savedUserId == userId) {
        debugPrint('✅ بيانات المستخدم محفوظة مسبقاً في UserService');
        return;
      }

      debugPrint('🔄 نسخ بيانات المستخدم من AuthService إلى UserService...');

      // حفظ البيانات في UserService
      await prefs.setString(_keyUserId, userId);
      await prefs.setString(_keyUserName, userName);
      await prefs.setString(_keyUserPhone, _formatPhoneNumber(userPhone));
      await prefs.setBool(_keyIsDataLoaded, true);

      debugPrint('✅ تم حفظ بيانات المستخدم في UserService:');
      debugPrint('   المعرف: $userId');
      debugPrint('   الاسم: $userName');
      debugPrint('   الهاتف: ${_formatPhoneNumber(userPhone)}');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل وحفظ بيانات المستخدم: $e');
    }
  }

  /// مسح البيانات المحلية عند تسجيل الخروج
  static Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyUserName);
      await prefs.remove(_keyUserPhone);
      await prefs.remove(_keyIsDataLoaded);
      debugPrint('🗑️  مسح بيانات المستخدم ');
    } catch (e) {
      debugPrint('❌ خطأ في مسح بيانات المستخدم: $e');
    }
  }

  /// الحصول على الاسم الأول للمستخدم من التخزين المحلي
  static Future<String> getFirstName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fullName = prefs.getString(_keyUserName) ?? 'المستخدم';
      final names = fullName.split(' ');
      final firstName = names.isNotEmpty ? names.first : 'المستخدم';
      debugPrint('📱 تم جلب الاسم: $firstName');
      return firstName;
    } catch (e) {
      debugPrint('❌ خطأ في جلب الاسم: $e');
      return 'المستخدم';
    }
  }

  /// الحصول على رقم هاتف المستخدم من التخزين المحلي
  static Future<String> getPhoneNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString(_keyUserPhone) ?? '07512345154';
      debugPrint('📱 تم جلب رقم الهاتف من التخزين المحلي: $phone');
      return phone;
    } catch (e) {
      debugPrint('❌ خطأ في جلب رقم الهاتف: $e');
      return '07512345154';
    }
  }

  /// تنسيق رقم الهاتف العراقي
  static String _formatPhoneNumber(String phone) {
    // إزالة جميع الرموز والمسافات
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

    // إذا كان الرقم يبدأ بـ 964، إزالته واستبداله بـ 0
    if (cleanPhone.startsWith('964')) {
      cleanPhone = '0${cleanPhone.substring(3)}';
    }

    // إذا لم يبدأ بـ 0، إضافته
    if (!cleanPhone.startsWith('0')) {
      cleanPhone = '0$cleanPhone';
    }

    // التأكد من أن الرقم 11 رقم (الطول الصحيح للرقم العراقي)
    if (cleanPhone.length == 11) {
      return cleanPhone;
    }

    // إذا كان الرقم غير صحيح، إرجاع رقم افتراضي
    return '07512345154';
  }

  /// التحقق من وجود بيانات المستخدم المحفوظة
  static Future<bool> isUserDataSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = _supabase.auth.currentUser;

      if (user == null) return false;

      final savedUserId = prefs.getString(_keyUserId);
      final isDataLoaded = prefs.getBool(_keyIsDataLoaded) ?? false;

      return savedUserId == user.id && isDataLoaded;
    } catch (e) {
      return false;
    }
  }

  /// الحصول على التحية المناسبة حسب الوقت في العراق
  static Map<String, String> getGreeting() {
    // الحصول على الوقت الحالي في العراق (UTC+3)
    final now = DateTime.now().toUtc().add(const Duration(hours: 3));
    final hour = now.hour;

    // تم إزالة طباعة الوقت لتوفير الأداء

    // تحديد التحية والإيموجي حسب الوقت
    if (hour >= 5 && hour < 12) {
      // الصباح: من 5 صباحاً إلى 12 ظهراً
      return {'greeting': 'صباح الخير', 'emoji': '☀️'};
    } else if (hour >= 12 && hour < 18) {
      // بعد الظهر: من 12 ظهراً إلى 6 مساءً
      return {'greeting': 'مساء الخير', 'emoji': '🌤️'};
    } else if (hour >= 18 && hour < 22) {
      // المساء: من 6 مساءً إلى 10 مساءً
      return {'greeting': 'مساء الخير', 'emoji': '🌅'};
    } else {
      // الليل: من 10 مساءً إلى 5 صباحاً
      return {'greeting': 'تصبح على خير', 'emoji': '🌙'};
    }
  }
}
