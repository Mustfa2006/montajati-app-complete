import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfitsRepository {
  static const String _apiUrl = 'http://localhost:3002/api/users/profits';
  static const int _cacheExpireSeconds = 60;
  
  static Map<String, dynamic>? _cachedProfits;
  static DateTime? _cacheTime;

  /// جلب أرباح المستخدم مع نظام Retry وCaching
  static Future<Map<String, dynamic>> getUserProfits({int retries = 3}) async {
    // التحقق من الكاش
    if (_isCacheValid()) {
      return _cachedProfits!;
    }

    for (int i = 0; i < retries; i++) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final phone = prefs.getString('current_user_phone');

        if (phone == null || phone.isEmpty) {
          throw Exception('لا يوجد مستخدم مسجل دخول');
        }

        final response = await http
            .post(
              Uri.parse(_apiUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'phone': phone}),
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body);
          if (jsonData['success'] == true && jsonData['data'] != null) {
            // حفظ في الكاش
            _cachedProfits = jsonData['data'];
            _cacheTime = DateTime.now();
            return jsonData['data'];
          }
        }

        throw Exception('فشل في جلب الأرباح: ${response.statusCode}');
      } catch (e) {
        if (i == retries - 1) {
          rethrow;
        }
        await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
      }
    }
    throw Exception('فشل في جلب الأرباح بعد عدة محاولات');
  }

  /// التحقق من صحة الكاش
  static bool _isCacheValid() {
    if (_cachedProfits == null || _cacheTime == null) {
      return false;
    }
    final elapsed = DateTime.now().difference(_cacheTime!).inSeconds;
    return elapsed < _cacheExpireSeconds;
  }

  /// مسح الكاش (عند تحديث البيانات)
  static void clearCache() {
    _cachedProfits = null;
    _cacheTime = null;
  }
}

