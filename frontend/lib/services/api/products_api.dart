import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../core/exceptions.dart';
import '../../models/product.dart';

/// خدمة API المنتجات - للاتصال بالسيرفر فقط
class ProductsApi {
  /// جلب المنتجات من السيرفر
  Future<List<Product>> fetchProducts({int page = 1, int limit = 10}) async {
    try {
      final uri = Uri.parse(ApiConfig.productsUrl).replace(
        queryParameters: {'page': '$page', 'limit': '$limit'},
      );

      final response = await http
          .get(uri, headers: ApiConfig.defaultHeaders)
          .timeout(ApiConfig.defaultTimeout);

      if (response.statusCode != 200) {
        throw ApiException(
          'فشل تحميل المنتجات',
          statusCode: response.statusCode,
        );
      }

      final jsonData = jsonDecode(response.body);

      if (jsonData['success'] != true) {
        throw ApiException(jsonData['message'] ?? 'خطأ غير معروف');
      }

      final List<dynamic> data = jsonData['data']?['products'] ?? [];
      return data.map<Product>((json) => Product.fromJson(json)).toList();
    } on http.ClientException {
      throw NetworkException('لا يمكن الاتصال بالسيرفر');
    } catch (e) {
      if (e is ApiException || e is NetworkException) rethrow;
      throw ApiException('خطأ غير متوقع: $e');
    }
  }

  /// جلب منتج واحد بالـ ID
  Future<Product> fetchProductById(String productId) async {
    try {
      final uri = Uri.parse('${ApiConfig.productsUrl}/$productId');

      final response = await http
          .get(uri, headers: ApiConfig.defaultHeaders)
          .timeout(ApiConfig.defaultTimeout);

      if (response.statusCode == 404) {
        throw NotFoundException('المنتج غير موجود');
      }

      if (response.statusCode != 200) {
        throw ApiException(
          'فشل تحميل المنتج',
          statusCode: response.statusCode,
        );
      }

      final jsonData = jsonDecode(response.body);

      if (jsonData['success'] != true) {
        throw ApiException(jsonData['message'] ?? 'خطأ غير معروف');
      }

      return Product.fromJson(jsonData['data']);
    } on http.ClientException {
      throw NetworkException('لا يمكن الاتصال بالسيرفر');
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is NotFoundException) {
        rethrow;
      }
      throw ApiException('خطأ غير متوقع: $e');
    }
  }

  /// البحث في المنتجات (اختياري - للبحث من السيرفر)
  Future<List<Product>> searchProducts(String query, {int limit = 20}) async {
    try {
      final uri = Uri.parse('${ApiConfig.productsUrl}/search').replace(
        queryParameters: {'q': query, 'limit': '$limit'},
      );

      final response = await http
          .get(uri, headers: ApiConfig.defaultHeaders)
          .timeout(ApiConfig.defaultTimeout);

      if (response.statusCode != 200) {
        throw ApiException(
          'فشل البحث',
          statusCode: response.statusCode,
        );
      }

      final jsonData = jsonDecode(response.body);

      if (jsonData['success'] != true) {
        throw ApiException(jsonData['message'] ?? 'خطأ غير معروف');
      }

      final List<dynamic> data = jsonData['data']?['products'] ?? [];
      return data.map<Product>((json) => Product.fromJson(json)).toList();
    } on http.ClientException {
      throw NetworkException('لا يمكن الاتصال بالسيرفر');
    } catch (e) {
      if (e is ApiException || e is NetworkException) rethrow;
      throw ApiException('خطأ غير متوقع: $e');
    }
  }
}

