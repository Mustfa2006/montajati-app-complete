/// 📍 خدمة API للمواقع - المحافظات والمدن
/// Location API Service - Provinces and Cities
///
/// هذه الخدمة تتصل بالباك اند لجلب المحافظات والمدن
/// بدلاً من الاتصال المباشر بـ Supabase

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// 🏛️ نموذج المحافظة
class Province {
  final String id;
  final String name;
  final String externalId;

  Province({required this.id, required this.name, required this.externalId});

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      externalId: json['externalId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'external_id': externalId};
  }
}

/// 🏙️ نموذج المدينة
class City {
  final String id;
  final String name;
  final String externalId;
  final String provinceId;

  City({required this.id, required this.name, required this.externalId, required this.provinceId});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      externalId: json['externalId']?.toString() ?? '',
      provinceId: json['provinceId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'external_id': externalId, 'province_id': provinceId};
  }
}

/// 📍 خدمة API للمواقع
class LocationApiService {
  static const String _locationsEndpoint = '/api/locations';

  // Timeout settings
  static const Duration _timeout = Duration(seconds: 15);
  static const int _maxRetries = 3;

  /// 🏛️ جلب جميع المحافظات
  static Future<List<Province>> getProvinces({String provider = 'alwaseet'}) async {
    try {
      debugPrint('📍 [LocationAPI] جلب المحافظات...');

      final url = Uri.parse('${ApiConfig.baseUrl}$_locationsEndpoint/provinces?provider=$provider');

      final response = await http.get(url, headers: ApiConfig.defaultHeaders).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final provinces = (data['data'] as List).map((p) => Province.fromJson(p)).toList();

          debugPrint('✅ [LocationAPI] تم جلب ${provinces.length} محافظة');
          return provinces;
        }
      }

      throw Exception('فشل في جلب المحافظات: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [LocationAPI] خطأ في جلب المحافظات: $e');
      rethrow;
    }
  }

  /// 🏙️ جلب مدن محافظة محددة
  static Future<List<City>> getCities(String provinceId, {String provider = 'alwaseet'}) async {
    try {
      debugPrint('📍 [LocationAPI] جلب مدن المحافظة $provinceId...');

      final url = Uri.parse('${ApiConfig.baseUrl}$_locationsEndpoint/provinces/$provinceId/cities?provider=$provider');

      final response = await http.get(url, headers: ApiConfig.defaultHeaders).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final cities = (data['data'] as List).map((c) => City.fromJson(c)).toList();

          debugPrint('✅ [LocationAPI] تم جلب ${cities.length} مدينة');
          return cities;
        }
      }

      throw Exception('فشل في جلب المدن: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [LocationAPI] خطأ في جلب المدن: $e');
      rethrow;
    }
  }

  /// 🔄 جلب المحافظات مع نظام Retry ذكي
  static Future<List<Province>> getProvincesWithRetry({
    String provider = 'alwaseet',
    void Function(int attempt, int maxAttempts)? onRetry,
  }) async {
    Exception? lastError;

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        debugPrint('📍 [LocationAPI] محاولة $attempt/$_maxRetries لجلب المحافظات...');

        final provinces = await getProvinces(provider: provider);
        return provinces;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());

        if (attempt < _maxRetries) {
          onRetry?.call(attempt, _maxRetries);

          // Exponential backoff
          final delay = Duration(seconds: attempt * 2);
          debugPrint('🔄 [LocationAPI] إعادة المحاولة بعد ${delay.inSeconds} ثواني...');
          await Future.delayed(delay);
        }
      }
    }

    throw lastError ?? Exception('فشل في جلب المحافظات بعد $_maxRetries محاولات');
  }

  /// 🔄 جلب المدن مع نظام Retry ذكي
  static Future<List<City>> getCitiesWithRetry(
    String provinceId, {
    String provider = 'alwaseet',
    void Function(int attempt, int maxAttempts)? onRetry,
  }) async {
    Exception? lastError;

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        debugPrint('📍 [LocationAPI] محاولة $attempt/$_maxRetries لجلب المدن...');

        final cities = await getCities(provinceId, provider: provider);
        return cities;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());

        if (attempt < _maxRetries) {
          onRetry?.call(attempt, _maxRetries);

          final delay = Duration(seconds: attempt * 2);
          debugPrint('🔄 [LocationAPI] إعادة المحاولة بعد ${delay.inSeconds} ثواني...');
          await Future.delayed(delay);
        }
      }
    }

    throw lastError ?? Exception('فشل في جلب المدن بعد $_maxRetries محاولات');
  }

  /// 🔍 البحث في المواقع
  static Future<Map<String, List<dynamic>>> search(String query, {String? type, String? provinceId}) async {
    try {
      debugPrint('📍 [LocationAPI] البحث عن: $query');

      final params = <String, String>{'query': query};
      if (type != null) params['type'] = type;
      if (provinceId != null) params['provinceId'] = provinceId;

      final url = Uri.parse('${ApiConfig.baseUrl}$_locationsEndpoint/search').replace(queryParameters: params);

      final response = await http.get(url, headers: ApiConfig.defaultHeaders).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          return {'provinces': data['data']['provinces'] ?? [], 'cities': data['data']['cities'] ?? []};
        }
      }

      throw Exception('فشل في البحث: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [LocationAPI] خطأ في البحث: $e');
      rethrow;
    }
  }
}
