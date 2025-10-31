import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true; // الوضع الافتراضي: ليلي

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('is_dark_mode') ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الوضع: $e');
    }
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_dark_mode', _isDarkMode);
      debugPrint('✅ تم حفظ الوضع: ${_isDarkMode ? "ليلي" : "نهاري"}');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ الوضع: $e');
    }
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    
    _isDarkMode = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_dark_mode', value);
      debugPrint('✅ تم حفظ الوضع: ${value ? "ليلي" : "نهاري"}');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ الوضع: $e');
    }
  }

  String getThemeName() {
    return _isDarkMode ? 'الوضع الليلي' : 'الوضع النهاري';
  }
}

