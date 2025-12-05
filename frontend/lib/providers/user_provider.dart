import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مزود بيانات المستخدم - يدير حالة المستخدم بشكل مركزي
class UserProvider extends ChangeNotifier {
  static UserProvider? _instance;

  /// الحصول على المثيل الوحيد
  static UserProvider get instance {
    _instance ??= UserProvider._();
    return _instance!;
  }

  UserProvider._();

  // مفاتيح التخزين المحلي
  static const String _keyUserId = 'current_user_id';
  static const String _keyUserName = 'current_user_name';
  static const String _keyUserPhone = 'current_user_phone';
  static const String _keyIsDataLoaded = 'user_data_loaded';

  // بيانات المستخدم
  String _firstName = 'صديقي';
  String _lastName = '';
  String _phoneNumber = '07512345154';
  String _userId = '';
  bool _isLoaded = false;

  // Getters
  String get firstName => _firstName;
  String get lastName => _lastName;
  String get fullName => '$_firstName $_lastName'.trim();
  String get phoneNumber => _phoneNumber;
  String get userId => _userId;
  bool get isLoaded => _isLoaded;

  /// تهيئة بيانات المستخدم من التخزين المحلي
  Future<void> initialize() async {
    if (_isLoaded) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // الحصول على البيانات المحفوظة
      final userId = prefs.getString(_keyUserId);
      final userName = prefs.getString(_keyUserName);
      final userPhone = prefs.getString(_keyUserPhone);

      // إذا لم تكن هناك بيانات، محاولة التحميل من AuthService
      if (userId == null || userName == null) {
        await _loadFromAuthService();
        return;
      }

      // تحليل الاسم
      final names = userName.split(' ');

      _userId = userId;
      _firstName = names.isNotEmpty ? names.first : 'صديقي';
      _lastName = names.length > 1 ? names.sublist(1).join(' ') : '';
      _phoneNumber = userPhone ?? '07512345154';
      _isLoaded = true;

      notifyListeners();
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة بيانات المستخدم: $e');
    }
  }

  /// تحميل البيانات من AuthService (للمرة الأولى)
  Future<void> _loadFromAuthService() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // الحصول على البيانات المحفوظة من AuthService
      final userId = prefs.getString('current_user_id');
      final userName = prefs.getString('current_user_name');
      final userPhone = prefs.getString('current_user_phone');

      if (userId == null || userName == null) {
        debugPrint('❌ لا توجد بيانات مستخدم في AuthService');
        _isLoaded = true;
        notifyListeners();
        return;
      }

      // تحليل الاسم
      final names = userName.split(' ');

      _userId = userId;
      _firstName = names.isNotEmpty ? names.first : 'صديقي';
      _lastName = names.length > 1 ? names.sublist(1).join(' ') : '';
      _phoneNumber = _formatPhoneNumber(userPhone ?? '07512345154');
      _isLoaded = true;

      // حفظ في التخزين المحلي
      await prefs.setString(_keyUserId, _userId);
      await prefs.setString(_keyUserName, userName);
      await prefs.setString(_keyUserPhone, _phoneNumber);
      await prefs.setBool(_keyIsDataLoaded, true);

      notifyListeners();
    } catch (e) {
      debugPrint('❌ خطأ في تحميل بيانات المستخدم: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// تحديث بيانات المستخدم
  Future<void> updateUserData({String? firstName, String? lastName, String? phone}) async {
    if (firstName != null) _firstName = firstName;
    if (lastName != null) _lastName = lastName;
    if (phone != null) _phoneNumber = _formatPhoneNumber(phone);

    notifyListeners();

    // حفظ في التخزين المحلي
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserName, fullName);
      await prefs.setString(_keyUserPhone, _phoneNumber);
    } catch (_) {}
  }

  /// مسح بيانات المستخدم (عند تسجيل الخروج)
  Future<void> clearUserData() async {
    _firstName = 'صديقي';
    _lastName = '';
    _phoneNumber = '07512345154';
    _userId = '';
    _isLoaded = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyUserName);
      await prefs.remove(_keyUserPhone);
      await prefs.remove(_keyIsDataLoaded);
    } catch (_) {}

    notifyListeners();
  }

  /// تنسيق رقم الهاتف العراقي
  String _formatPhoneNumber(String phone) {
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.startsWith('964')) cleanPhone = '0${cleanPhone.substring(3)}';
    if (!cleanPhone.startsWith('0')) cleanPhone = '0$cleanPhone';
    return cleanPhone.length == 11 ? cleanPhone : '07512345154';
  }
}
