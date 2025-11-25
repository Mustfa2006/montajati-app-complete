import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/competition.dart';
import 'real_auth_service.dart';

class CompetitionsApiService {
  static Uri _u(String path, [Map<String, String>? q]) {
    final base = ApiConfig.apiUrl + path;
    return Uri.parse(base).replace(queryParameters: q);
  }

  // Public: list active competitions for users
  static Future<List<Competition>> fetchPublic() async {
    try {
      final res = await http
          .get(_u('/competitions/public'), headers: ApiConfig.defaultHeaders)
          .timeout(ApiConfig.defaultTimeout);
      if (res.statusCode == 200) {
        final List data = json.decode(res.body)['data'] ?? json.decode(res.body);
        return data.map((e) => Competition.fromMap(e as Map<String, dynamic>)).cast<Competition>().toList();
      }
      if (kDebugMode) debugPrint('⚠️ fetchPublic status ${res.statusCode}: ${res.body}');
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('❌ fetchPublic error: $e');
      return [];
    }
  }

  // Admin: list all competitions
  static Future<List<Competition>> fetchAllAdmin() async {
    try {
      final token = await AuthService.getToken();
      final headers = {...ApiConfig.defaultHeaders, if (token != null) 'Authorization': 'Bearer $token'};
      final res = await http.get(_u('/competitions'), headers: headers).timeout(ApiConfig.defaultTimeout);
      if (res.statusCode == 200) {
        final List data = json.decode(res.body)['data'] ?? json.decode(res.body);
        return data.map((e) => Competition.fromMap(e as Map<String, dynamic>)).cast<Competition>().toList();
      }
      if (kDebugMode) debugPrint('⚠️ fetchAllAdmin status ${res.statusCode}: ${res.body}');
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('❌ fetchAllAdmin error: $e');
      return [];
    }
  }

  // Admin: create
  static Future<Competition?> createAdmin(Competition c) async {
    try {
      final token = await AuthService.getToken();
      final headers = {...ApiConfig.defaultHeaders, if (token != null) 'Authorization': 'Bearer $token'};
      final res = await http
          .post(
            _u('/competitions'),
            headers: headers,
            body: json.encode({
              'name': c.name,
              'product_name': c.product,
              'prize': c.prize,
              'target': c.target,
              'starts_at': c.startsAt?.toIso8601String(),
              'ends_at': c.endsAt?.toIso8601String(),
            }),
          )
          .timeout(ApiConfig.defaultTimeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(res.body)['data'] ?? json.decode(res.body);
        return Competition.fromMap(data);
      }
      if (kDebugMode) debugPrint('⚠️ createAdmin status ${res.statusCode}: ${res.body}');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ createAdmin error: $e');
      return null;
    }
  }

  // Admin: update
  static Future<Competition?> updateAdmin(Competition c) async {
    try {
      final token = await AuthService.getToken();
      final headers = {...ApiConfig.defaultHeaders, if (token != null) 'Authorization': 'Bearer $token'};
      final res = await http
          .patch(
            _u('/competitions/${c.id}'),
            headers: headers,
            body: json.encode({
              'name': c.name,
              'product_name': c.product,
              'prize': c.prize,
              'target': c.target,
              'starts_at': c.startsAt?.toIso8601String(),
              'ends_at': c.endsAt?.toIso8601String(),
            }),
          )
          .timeout(ApiConfig.defaultTimeout);
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(res.body)['data'] ?? json.decode(res.body);
        return Competition.fromMap(data);
      }
      if (kDebugMode) debugPrint('⚠️ updateAdmin status ${res.statusCode}: ${res.body}');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ updateAdmin error: $e');
      return null;
    }
  }

  // Admin: delete
  static Future<bool> deleteAdmin(String id) async {
    try {
      final token = await AuthService.getToken();
      final headers = {...ApiConfig.defaultHeaders, if (token != null) 'Authorization': 'Bearer $token'};
      final res = await http.delete(_u('/competitions/$id'), headers: headers).timeout(ApiConfig.defaultTimeout);
      return res.statusCode == 200;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ deleteAdmin error: $e');
      return false;
    }
  }
}
