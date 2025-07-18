import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AuthService {
  static SupabaseClient get _supabase => SupabaseConfig.client;

  // تشفير كلمة المرور
  static String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // حفظ التوكن
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // الحصول على التوكن
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // حذف التوكن
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // تسجيل الدخول باستخدام Supabase
  static Future<AuthResult> login({
    required String usernameOrPhone,
    required String password,
  }) async {
    try {
      // التحقق من صحة البيانات
      if (usernameOrPhone.isEmpty || password.isEmpty) {
        return AuthResult(success: false, message: 'يرجى ملء جميع الحقول');
      }

      // التحقق من رقم الهاتف
      if (!RegExp(r'^[0-9]+$').hasMatch(usernameOrPhone)) {
        return AuthResult(
          success: false,
          message: 'رقم الهاتف يجب أن يحتوي على أرقام فقط',
        );
      }

      if (usernameOrPhone.length != 11) {
        return AuthResult(
          success: false,
          message: 'يجب كتابة رقم الهاتف 11 رقم',
        );
      }

      // تشفير كلمة المرور
      String hashedPassword = _hashPassword(password);

      // البحث عن المستخدم في قاعدة البيانات
      final response = await _supabase
          .from('users')
          .select('id, name, phone, password_hash, is_admin')
          .eq('phone', usernameOrPhone)
          .maybeSingle();

      if (response == null) {
        return AuthResult(success: false, message: 'رقم الهاتف غير مسجل');
      }

      // التحقق من كلمة المرور
      if (response['password_hash'] != hashedPassword) {
        return AuthResult(success: false, message: 'كلمة المرور غير صحيحة');
      }

      // إنشاء توكن وحفظه مع بيانات المستخدم
      final userData = response; // ✅ البيانات مباشرة من Supabase
      String token =
          'token_${userData['id']}_${DateTime.now().millisecondsSinceEpoch}';
      await _saveToken(token);

      // ✅ حفظ بيانات المستخدم في SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', userData['id'].toString());
      await prefs.setString('current_user_name', userData['name'] ?? '');
      await prefs.setString('current_user_phone', userData['phone'] ?? '');
      await prefs.setBool(
        'current_user_is_admin',
        userData['is_admin'] ?? false,
      );

      return AuthResult(
        success: true,
        message: 'تم تسجيل الدخول بنجاح',
        token: token,
        user: UserData(
          id: userData['id'],
          name: userData['name'],
          phone: userData['phone'],
          username: null,
          isAdmin: userData['is_admin'] ?? false,
        ),
      );
    } on PostgrestException catch (e) {
      return AuthResult(
        success: false,
        message: 'خطأ في قاعدة البيانات: ${e.message}',
      );
    } catch (e) {
      return AuthResult(success: false, message: 'خطأ في الاتصال بالإنترنت');
    }
  }

  // تسجيل حساب جديد باستخدام Supabase
  static Future<AuthResult> register({
    required String name,
    required String phone,
    required String password,
  }) async {
    try {
      // التحقق من صحة البيانات
      if (name.isEmpty || phone.isEmpty || password.isEmpty) {
        return AuthResult(success: false, message: 'يرجى ملء جميع الحقول');
      }

      if (phone.length != 11 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
        return AuthResult(
          success: false,
          message: 'رقم الهاتف يجب أن يكون 11 رقم بالضبط',
        );
      }

      if (password.length < 8) {
        return AuthResult(
          success: false,
          message: 'كلمة المرور يجب أن تكون 8 أحرف على الأقل',
        );
      }

      if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(password)) {
        return AuthResult(
          success: false,
          message: 'كلمة المرور يجب أن تحتوي على أحرف إنجليزية وأرقام فقط',
        );
      }

      // تشفير كلمة المرور
      String hashedPassword = _hashPassword(password);

      // التحقق من وجود رقم الهاتف مسبقاً
      final existingUser = await _supabase
          .from('users')
          .select('phone')
          .eq('phone', phone)
          .maybeSingle();

      if (existingUser != null) {
        return AuthResult(success: false, message: 'رقم الهاتف مستخدم بالفعل');
      }

      // إدراج المستخدم الجديد
      await _supabase.from('users').insert({
        'name': name,
        'phone': phone,
        'email': '$phone@temp.com', // إنشاء email مؤقت من رقم الهاتف
        'password_hash': hashedPassword,
      });

      return AuthResult(
        success: true,
        message: 'تم إنشاء الحساب بنجاح! يمكنك الآن تسجيل الدخول',
      );
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // unique constraint violation
        return AuthResult(success: false, message: 'رقم الهاتف مستخدم بالفعل');
      }
      return AuthResult(
        success: false,
        message: 'خطأ في قاعدة البيانات: ${e.message}',
      );
    } catch (e) {
      return AuthResult(success: false, message: 'خطأ في الاتصال بالإنترنت');
    }
  }

  // التحقق من صحة التوكن
  static Future<bool> validateToken() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // تسجيل الخروج
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    // حذف جميع بيانات المستخدم
    await prefs.remove('auth_token');
    await prefs.remove('current_user_id');
    await prefs.remove('current_user_name');
    await prefs.remove('current_user_phone');
    await prefs.remove('current_user_is_admin');

    await removeToken();
  }

  // ✅ التحقق من وجود مستخدم مسجل دخول
  static Future<Map<String, String>?> getCurrentUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userPhone = prefs.getString('current_user_phone');
    final userName = prefs.getString('current_user_name');
    final userId = prefs.getString('current_user_id');

    if (userPhone != null && userPhone.isNotEmpty) {
      return {
        'phone': userPhone,
        'name': userName ?? 'مستخدم',
        'id': userId ?? '',
      };
    }

    return null;
  }

  // ✅ التحقق من حالة تسجيل الدخول
  static Future<bool> isLoggedIn() async {
    final userInfo = await getCurrentUserInfo();
    return userInfo != null;
  }

  // الحصول على معلومات المستخدم الحالي
  static Future<UserData?> getCurrentUser() async {
    try {
      // استخدام المعلومات المحفوظة محلياً بدلاً من Supabase Auth
      final userInfo = await getCurrentUserInfo();
      if (userInfo == null) return null;

      final token = await getToken();
      if (token == null) return null;

      // استخراج ID المستخدم من التوكن
      final parts = token.split('_');
      if (parts.length < 2) return null;

      final userId = parts[1];

      // جلب بيانات المستخدم من قاعدة البيانات باستخدام service key
      final response = await _supabase
          .from('users')
          .select('id, name, phone, is_admin')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        // إذا فشل الاستعلام، استخدم البيانات المحفوظة محلياً
        return UserData(
          id: userInfo['id']!,
          name: userInfo['name']!,
          phone: userInfo['phone']!,
          isAdmin: false, // افتراضي
        );
      }

      return UserData(
        id: response['id'],
        name: response['name'],
        phone: response['phone'],
        isAdmin: response['is_admin'] ?? false,
      );
    } catch (e) {
      // في حالة الخطأ، حاول استخدام البيانات المحفوظة محلياً
      final userInfo = await getCurrentUserInfo();
      if (userInfo != null) {
        return UserData(
          id: userInfo['id']!,
          name: userInfo['name']!,
          phone: userInfo['phone']!,
          isAdmin: false, // افتراضي
        );
      }
      return null;
    }
  }

  // التحقق من صلاحيات المدير للمستخدم الحالي
  static Future<bool> isCurrentUserAdmin() async {
    try {
      // التحقق من البيانات المحفوظة محلياً أولاً
      final prefs = await SharedPreferences.getInstance();
      final isAdminLocal = prefs.getBool('current_user_is_admin');

      if (isAdminLocal != null) {
        return isAdminLocal;
      }

      // إذا لم تكن محفوظة محلياً، جلب من قاعدة البيانات
      final user = await getCurrentUser();

      // حفظ النتيجة محلياً للمرات القادمة
      if (user != null) {
        await prefs.setBool('current_user_is_admin', user.isAdmin);
      }

      return user?.isAdmin ?? false;
    } catch (e) {
      return false;
    }
  }
}

// نموذج نتيجة المصادقة
class AuthResult {
  final bool success;
  final String message;
  final String? token;
  final UserData? user;

  AuthResult({
    required this.success,
    required this.message,
    this.token,
    this.user,
  });
}

// نموذج بيانات المستخدم
class UserData {
  final String id;
  final String name;
  final String phone;
  final String? username;
  final bool isAdmin;

  UserData({
    required this.id,
    required this.name,
    required this.phone,
    this.username,
    this.isAdmin = false,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'].toString(),
      name: json['name'],
      phone: json['phone'],
      username: json['username'],
      isAdmin: json['is_admin'] ?? false,
    );
  }
}
