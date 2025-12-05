import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../core/exceptions.dart';
import '../../models/banner_model.dart';

/// خدمة API البانرات الإعلانية
class BannersApi {
  /// جلب البانرات من السيرفر
  Future<List<BannerModel>> fetchBanners() async {
    try {
      final uri = Uri.parse('${ApiConfig.productsUrl}/banners');

      final response = await http
          .get(uri, headers: ApiConfig.defaultHeaders)
          .timeout(ApiConfig.defaultTimeout);

      if (response.statusCode != 200) {
        throw ApiException(
          'فشل تحميل البانرات',
          statusCode: response.statusCode,
        );
      }

      final jsonData = jsonDecode(response.body);

      if (jsonData['success'] != true) {
        throw ApiException(jsonData['message'] ?? 'خطأ غير معروف');
      }

      final List<dynamic> data = jsonData['data'] ?? [];
      return data
          .map<BannerModel>((json) => BannerModel.fromJson(json))
          .where((banner) => banner.isActive)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
    } on http.ClientException {
      throw NetworkException('لا يمكن الاتصال بالسيرفر');
    } catch (e) {
      if (e is ApiException || e is NetworkException) rethrow;
      throw ApiException('خطأ غير متوقع: $e');
    }
  }
}

