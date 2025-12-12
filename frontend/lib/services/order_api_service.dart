import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/api_config.dart';
import '../models/order_details.dart';

class OrderApiService {
  static const String _ordersEndpoint = '/api/orders';

  // 📝 Helper to get Auth Headers
  static Map<String, String> get _authHeaders {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) {
      throw Exception('المستخدم غير مسجل الدخول');
    }
    return {...ApiConfig.defaultHeaders, 'Authorization': 'Bearer $token'};
  }

  // 📥 Get Scheduled Order
  static Future<OrderDetails> getScheduledOrder(String id) async {
    try {
      debugPrint('⏳ [OrderAPI] Get Scheduled Order: $id');
      final url = Uri.parse('${ApiConfig.baseUrl}$_ordersEndpoint/scheduled/$id');

      final response = await http.get(url, headers: _authHeaders);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return OrderDetails.fromJson(data['data']);
        }
      }

      throw _parseError(response);
    } catch (e) {
      debugPrint('❌ [OrderAPI] Error: $e');
      rethrow;
    }
  }

  // 📥 Get Regular Order
  static Future<OrderDetails> getOrder(String id) async {
    try {
      debugPrint('⏳ [OrderAPI] Get Order: $id');
      final url = Uri.parse('${ApiConfig.baseUrl}$_ordersEndpoint/$id');

      final response = await http.get(url, headers: _authHeaders);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return OrderDetails.fromJson(data['data']);
        }
      }

      throw _parseError(response);
    } catch (e) {
      debugPrint('❌ [OrderAPI] Error: $e');
      rethrow;
    }
  }

  // 📤 Update Scheduled Order
  static Future<void> updateScheduledOrder(String id, Map<String, dynamic> updateData) async {
    try {
      debugPrint('⏳ [OrderAPI] Update Scheduled Order: $id');
      final url = Uri.parse('${ApiConfig.baseUrl}$_ordersEndpoint/scheduled/$id');

      final response = await http.put(url, headers: _authHeaders, body: json.encode(updateData));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ [OrderAPI] Update Success');
          return;
        }
      }

      throw _parseError(response);
    } catch (e) {
      debugPrint('❌ [OrderAPI] Error: $e');
      rethrow;
    }
  }

  // 📤 Update Regular Order
  static Future<void> updateOrder(String id, Map<String, dynamic> updateData) async {
    try {
      debugPrint('⏳ [OrderAPI] Update Order: $id');
      final url = Uri.parse('${ApiConfig.baseUrl}$_ordersEndpoint/$id');

      final response = await http.put(url, headers: _authHeaders, body: json.encode(updateData));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ [OrderAPI] Update Success');
          return;
        }
      }

      throw _parseError(response);
    } catch (e) {
      debugPrint('❌ [OrderAPI] Error: $e');
      rethrow;
    }
  }

  // ⚠️ Error Parser
  static Exception _parseError(http.Response response) {
    try {
      final data = json.decode(response.body);
      return Exception(data['error'] ?? 'حدث خطأ غير معروف');
    } catch (_) {
      return Exception('خطأ في الاتصال: ${response.statusCode}');
    }
  }
}
