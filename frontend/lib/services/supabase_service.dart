// خدمة Supabase للتعامل مع قاعدة البيانات والمصادقة
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static final SupabaseClient _client = SupabaseConfig.client;

  // المصادقة

  // تسجيل حساب جديد
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // تسجيل الدخول
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // تسجيل الخروج
  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // الحصول على المستخدم الحالي
  static User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  // الاستماع لتغييرات المصادقة
  static Stream<AuthState> get authStateChanges {
    return _client.auth.onAuthStateChange;
  }

  // قاعدة البيانات

  // الحصول على بيانات المستخدم
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return response;
    } catch (e) {
      debugPrint('خطأ في الحصول على بيانات المستخدم: $e');
      return null;
    }
  }

  // تحديث بيانات المستخدم
  static Future<bool> updateUserProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _client.from('users').update(data).eq('id', userId);

      return true;
    } catch (e) {
      debugPrint('خطأ في تحديث بيانات المستخدم: $e');
      return false;
    }
  }

  // الحصول على المنتجات
  static Future<List<Map<String, dynamic>>> getProducts({
    String? ownerId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _client.from('products').select().eq('is_active', true);

      if (ownerId != null) {
        query = query.eq('owner_id', ownerId);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('خطأ في الحصول على المنتجات: $e');
      return [];
    }
  }

  // إضافة منتج جديد
  static Future<Map<String, dynamic>?> addProduct({
    required String ownerId,
    required String name,
    required String description,
    required double price,
    String? category,
    List<String>? images,
    int stockQuantity = 0,
  }) async {
    try {
      final response = await _client
          .from('products')
          .insert({
            'owner_id': ownerId,
            'name': name,
            'description': description,
            'price': price,
            'category': category,
            'images': images,
            'stock_quantity': stockQuantity,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      debugPrint('خطأ في إضافة المنتج: $e');
      return null;
    }
  }

  // الحصول على الطلبات
  static Future<List<Map<String, dynamic>>> getOrders({
    String? customerId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _client.from('orders').select('*, order_items(*)');

      if (customerId != null) {
        query = query.eq('customer_id', customerId);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('خطأ في الحصول على الطلبات: $e');
      return [];
    }
  }

  // ملاحظة: تم إزالة دالة createOrder - يجب استخدام HTTP API عبر official_order_service.dart

  // رفع صورة
  static Future<String?> uploadImage({
    required String bucket,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    try {
      await _client.storage.from(bucket).uploadBinary(fileName, fileBytes);

      final publicUrl = _client.storage.from(bucket).getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      debugPrint('خطأ في رفع الصورة: $e');
      return null;
    }
  }

  // حذف صورة
  static Future<bool> deleteImage({
    required String bucket,
    required String fileName,
  }) async {
    try {
      await _client.storage.from(bucket).remove([fileName]);

      return true;
    } catch (e) {
      debugPrint('خطأ في حذف الصورة: $e');
      return false;
    }
  }
}
