import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/api_config.dart';
import '../models/order_details.dart';
import 'real_auth_service.dart';

class OrderApiService {
  static const String _ordersEndpoint = '/api/orders';

  // 📝 Helper to get Auth Headers safely with Logging
  static Future<Map<String, String>> _getAuthHeaders() async {
    debugPrint('🔐 [AuthCheck] Starting check...');

    // 1. Try Custom Auth Service (Primary)
    var token = await AuthService.getToken();
    if (token != null && token.trim().isEmpty) token = null; // 🛡️ Treat empty string as null

    debugPrint('🔐 [AuthCheck] Custom Token: ${token != null ? "Found (${token.substring(0, 5)}...)" : "NULL"}');

    // 2. If null, try Supabase Session (Fallback)
    if (token == null) {
      final session = Supabase.instance.client.auth.currentSession;
      token = session?.accessToken;
      if (token != null && token.trim().isEmpty) token = null; // 🛡️ Safety check
      debugPrint('🔐 [AuthCheck] Supabase Token: ${token != null ? "Found" : "NULL"}');
    }

    if (token == null || token.trim().isEmpty) {
      debugPrint('❌ [AuthCheck] Token is NULL or Empty. User is NOT logged in.');
      throw Exception('المستخدم غير مسجل الدخول');
    }

    debugPrint('✅ [AuthCheck] Token found. Proceeding.');
    final finalHeaders = {...ApiConfig.defaultHeaders, 'Authorization': 'Bearer $token'};
    debugPrint('🔑 [AuthService] Final Authorization Header: ${finalHeaders['Authorization']}');
    return finalHeaders;
  }

  // 📥 Get Scheduled Order
  static Future<OrderDetails> getScheduledOrder(String id) async {
    try {
      debugPrint('⏳ [OrderAPI] Get Scheduled Order: $id');
      final url = Uri.parse('${ApiConfig.baseUrl}$_ordersEndpoint/scheduled/$id');

      final headers = await _getAuthHeaders();
      final response = await http.get(url, headers: headers);

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

      final headers = await _getAuthHeaders();
      debugPrint('📨 [OrderAPI] Headers: $headers');
      final response = await http.get(url, headers: headers);

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

      final headers = await _getAuthHeaders();
      final response = await http.put(url, headers: headers, body: json.encode(updateData));

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

      final headers = await _getAuthHeaders();
      final response = await http.put(url, headers: headers, body: json.encode(updateData));

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
