// ===================================
// 🔧 خدمة التحقق من صحة بيانات المواقع
// ===================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationValidationService {
  static final _supabase = Supabase.instance.client;

  /// التحقق من وجود external_id للمحافظة
  static Future<LocationValidationResult> validateProvince(String provinceId) async {
    try {
      debugPrint('🔍 التحقق من صحة المحافظة: $provinceId');
      debugPrint('🔍 نوع المعرف: ${provinceId.runtimeType}');
      debugPrint('🔍 طول المعرف: ${provinceId.length}');

      // البحث عن المحافظة بدون تقييد provider_name أولاً
      final response = await _supabase
          .from('provinces')
          .select('id, name, external_id, provider_name')
          .eq('id', provinceId)
          .maybeSingle();

      debugPrint('🔍 نتيجة البحث: $response');

      if (response == null) {
        debugPrint('❌ المحافظة غير موجودة: $provinceId');

        // دعنا نبحث عن جميع المحافظات لمعرفة ما هو متاح
        final allProvinces = await _supabase
            .from('provinces')
            .select('id, name')
            .limit(5);
        debugPrint('🔍 أول 5 محافظات متاحة: $allProvinces');

        return LocationValidationResult(
          isValid: false,
          error: 'المحافظة غير موجودة في قاعدة البيانات',
          suggestion: 'يرجى اختيار محافظة صحيحة',
        );
      }

      // التحقق من وجود external_id
      if (response['external_id'] == null || response['external_id'].toString().isEmpty) {
        debugPrint('❌ المحافظة "${response['name']}" لا تحتوي على external_id');
        return LocationValidationResult(
          isValid: false,
          error: 'المحافظة "${response['name']}" لا تحتوي على معرف خارجي صحيح',
          suggestion: 'يرجى تحديث بيانات المواقع من شركة الوسيط',
        );
      }

      debugPrint('✅ المحافظة "${response['name']}" صحيحة - external_id: ${response['external_id']}');
      return LocationValidationResult(
        isValid: true,
        provinceName: response['name'],
        externalId: response['external_id'].toString(),
      );

    } catch (e) {
      debugPrint('❌ خطأ في التحقق من المحافظة: $e');
      return LocationValidationResult(
        isValid: false,
        error: 'خطأ في التحقق من صحة المحافظة: $e',
      );
    }
  }

  /// التحقق من وجود external_id للمدينة
  static Future<LocationValidationResult> validateCity(String cityId, String provinceId) async {
    try {
      debugPrint('🔍 التحقق من صحة المدينة: $cityId في المحافظة: $provinceId');
      debugPrint('🔍 نوع معرف المدينة: ${cityId.runtimeType}');
      debugPrint('🔍 نوع معرف المحافظة: ${provinceId.runtimeType}');

      // البحث عن المدينة بدون تقييد provider_name أولاً
      final response = await _supabase
          .from('cities')
          .select('id, name, external_id, province_id, provider_name')
          .eq('id', cityId)
          .eq('province_id', provinceId)
          .maybeSingle();

      debugPrint('🔍 نتيجة البحث عن المدينة: $response');

      if (response == null) {
        debugPrint('❌ المدينة غير موجودة: $cityId في المحافظة: $provinceId');

        // دعنا نبحث عن المدن في هذه المحافظة
        final citiesInProvince = await _supabase
            .from('cities')
            .select('id, name')
            .eq('province_id', provinceId)
            .limit(3);
        debugPrint('🔍 أول 3 مدن في المحافظة: $citiesInProvince');

        return LocationValidationResult(
          isValid: false,
          error: 'المدينة غير موجودة في قاعدة البيانات',
          suggestion: 'يرجى اختيار مدينة صحيحة',
        );
      }

      // التحقق من وجود external_id
      if (response['external_id'] == null || response['external_id'].toString().isEmpty) {
        debugPrint('❌ المدينة "${response['name']}" لا تحتوي على external_id');
        return LocationValidationResult(
          isValid: false,
          error: 'المدينة "${response['name']}" لا تحتوي على معرف خارجي صحيح',
          suggestion: 'يرجى تحديث بيانات المواقع من شركة الوسيط',
        );
      }

      debugPrint('✅ المدينة "${response['name']}" صحيحة - external_id: ${response['external_id']}');
      return LocationValidationResult(
        isValid: true,
        cityName: response['name'],
        externalId: response['external_id'].toString(),
      );

    } catch (e) {
      debugPrint('❌ خطأ في التحقق من المدينة: $e');
      return LocationValidationResult(
        isValid: false,
        error: 'خطأ في التحقق من صحة المدينة: $e',
      );
    }
  }

  /// التحقق من صحة بيانات الطلب قبل الإرسال
  static Future<OrderLocationValidation> validateOrderLocation({
    required String provinceId,
    required String cityId,
  }) async {
    try {
      debugPrint('🔍 التحقق من صحة بيانات موقع الطلب...');
      debugPrint('   المحافظة: $provinceId');
      debugPrint('   المدينة: $cityId');

      // التحقق من المحافظة
      final provinceValidation = await validateProvince(provinceId);
      if (!provinceValidation.isValid) {
        return OrderLocationValidation(
          isValid: false,
          error: 'خطأ في بيانات المحافظة: ${provinceValidation.error}',
          suggestion: provinceValidation.suggestion,
        );
      }

      // التحقق من المدينة
      final cityValidation = await validateCity(cityId, provinceId);
      if (!cityValidation.isValid) {
        return OrderLocationValidation(
          isValid: false,
          error: 'خطأ في بيانات المدينة: ${cityValidation.error}',
          suggestion: cityValidation.suggestion,
        );
      }

      debugPrint('✅ تم التحقق من صحة بيانات الموقع بنجاح');
      debugPrint('   المحافظة: "${provinceValidation.provinceName}" (${provinceValidation.externalId})');
      debugPrint('   المدينة: "${cityValidation.cityName}" (${cityValidation.externalId})');

      return OrderLocationValidation(
        isValid: true,
        provinceName: provinceValidation.provinceName!,
        cityName: cityValidation.cityName!,
        provinceExternalId: provinceValidation.externalId!,
        cityExternalId: cityValidation.externalId!,
      );

    } catch (e) {
      debugPrint('❌ خطأ في التحقق من بيانات موقع الطلب: $e');
      return OrderLocationValidation(
        isValid: false,
        error: 'خطأ في التحقق من بيانات الموقع: $e',
      );
    }
  }

  /// فحص جميع المحافظات والمدن للتأكد من وجود external_id
  static Future<LocationHealthCheck> performHealthCheck() async {
    try {
      debugPrint('🔍 بدء فحص صحة بيانات المواقع...');

      // فحص المحافظات
      final provincesResponse = await _supabase
          .from('provinces')
          .select('id, name, external_id')
          .eq('provider_name', 'alwaseet');

      final totalProvinces = provincesResponse.length;
      final provincesWithoutExternalId = provincesResponse
          .where((p) => p['external_id'] == null || p['external_id'].toString().isEmpty)
          .toList();

      // فحص المدن
      final citiesResponse = await _supabase
          .from('cities')
          .select('id, name, external_id, province_id')
          .eq('provider_name', 'alwaseet');

      final totalCities = citiesResponse.length;
      final citiesWithoutExternalId = citiesResponse
          .where((c) => c['external_id'] == null || c['external_id'].toString().isEmpty)
          .toList();

      final isHealthy = provincesWithoutExternalId.isEmpty && citiesWithoutExternalId.isEmpty;

      debugPrint('📊 نتائج فحص صحة البيانات:');
      debugPrint('   المحافظات: ${totalProvinces - provincesWithoutExternalId.length}/$totalProvinces صحيحة');
      debugPrint('   المدن: ${totalCities - citiesWithoutExternalId.length}/$totalCities صحيحة');
      debugPrint('   الحالة العامة: ${isHealthy ? "صحية ✅" : "تحتاج إصلاح ❌"}');

      return LocationHealthCheck(
        isHealthy: isHealthy,
        totalProvinces: totalProvinces,
        provincesWithoutExternalId: provincesWithoutExternalId.length,
        totalCities: totalCities,
        citiesWithoutExternalId: citiesWithoutExternalId.length,
        missingProvinces: provincesWithoutExternalId.map((p) => p['name'].toString()).toList(),
        missingCities: citiesWithoutExternalId.map((c) => c['name'].toString()).toList(),
      );

    } catch (e) {
      debugPrint('❌ خطأ في فحص صحة بيانات المواقع: $e');
      return LocationHealthCheck(
        isHealthy: false,
        error: 'خطأ في فحص البيانات: $e',
      );
    }
  }
}

/// نتيجة التحقق من موقع واحد
class LocationValidationResult {
  final bool isValid;
  final String? error;
  final String? suggestion;
  final String? provinceName;
  final String? cityName;
  final String? externalId;

  LocationValidationResult({
    required this.isValid,
    this.error,
    this.suggestion,
    this.provinceName,
    this.cityName,
    this.externalId,
  });
}

/// نتيجة التحقق من بيانات موقع الطلب
class OrderLocationValidation {
  final bool isValid;
  final String? error;
  final String? suggestion;
  final String? provinceName;
  final String? cityName;
  final String? provinceExternalId;
  final String? cityExternalId;

  OrderLocationValidation({
    required this.isValid,
    this.error,
    this.suggestion,
    this.provinceName,
    this.cityName,
    this.provinceExternalId,
    this.cityExternalId,
  });
}

/// نتيجة فحص صحة جميع بيانات المواقع
class LocationHealthCheck {
  final bool isHealthy;
  final String? error;
  final int totalProvinces;
  final int provincesWithoutExternalId;
  final int totalCities;
  final int citiesWithoutExternalId;
  final List<String> missingProvinces;
  final List<String> missingCities;

  LocationHealthCheck({
    required this.isHealthy,
    this.error,
    this.totalProvinces = 0,
    this.provincesWithoutExternalId = 0,
    this.totalCities = 0,
    this.citiesWithoutExternalId = 0,
    this.missingProvinces = const [],
    this.missingCities = const [],
  });

  /// رسالة تلخص حالة البيانات
  String get statusMessage {
    if (error != null) return error!;
    
    if (isHealthy) {
      return 'جميع بيانات المواقع صحيحة ✅\n'
             'المحافظات: $totalProvinces\n'
             'المدن: $totalCities';
    } else {
      return 'بيانات المواقع تحتاج إصلاح ❌\n'
             'محافظات بدون external_id: $provincesWithoutExternalId\n'
             'مدن بدون external_id: $citiesWithoutExternalId';
    }
  }
}
