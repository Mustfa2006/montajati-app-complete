import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// خدمة الإشعارات المحسنة للسحب
class NotificationService {
  static final _supabase = Supabase.instance.client;

  /// إرسال إشعار تحديث حالة السحب
  static Future<void> sendWithdrawalStatusNotification({
    required String userId,
    required String requestId,
    required String newStatus,
    required double amount,
  }) async {
    try {
      debugPrint('📱 إرسال إشعار تحديث حالة السحب...');
      debugPrint('👤 المستخدم: $userId');
      debugPrint('📋 الطلب: $requestId');
      debugPrint('🔄 الحالة الجديدة: $newStatus');
      debugPrint('💰 المبلغ: $amount د.ع');

      // تحديد عنوان ونص الإشعار
      final notificationData = _getNotificationContent(newStatus, amount);
      
      // إرسال الإشعار إلى قاعدة البيانات
      await _saveNotificationToDatabase(
        userId: userId,
        title: notificationData['title']!,
        body: notificationData['body']!,
        type: 'withdrawal_status',
        data: {
          'request_id': requestId,
          'status': newStatus,
          'amount': amount.toString(),
        },
      );

      // طباعة تفاصيل الإشعار
      debugPrint('📱 === تم إرسال الإشعار ===');
      debugPrint('📋 العنوان: ${notificationData['title']}');
      debugPrint('💬 النص: ${notificationData['body']}');
      debugPrint('✅ تم حفظ الإشعار في قاعدة البيانات');

    } catch (e) {
      debugPrint('❌ خطأ في إرسال إشعار السحب: $e');
    }
  }

  /// تحديد محتوى الإشعار حسب الحالة
  static Map<String, String> _getNotificationContent(String status, double amount) {
    final formattedAmount = amount.toStringAsFixed(0);
    
    switch (status) {
      case 'completed':
        return {
          'title': '🎉 مبروك! تم التحويل',
          'body': 'تم تحويل مبلغ $formattedAmount د.ع إلى حسابك بنجاح! 💰✨',
        };
        
      case 'cancelled':
        return {
          'title': '😔 إلغاء السحب',
          'body': 'تم إلغاء سحبك بمبلغ $formattedAmount د.ع. تم إرجاع المبلغ إلى رصيدك 💰',
        };
        
      default:
        return {
          'title': 'تحديث حالة السحب',
          'body': 'تم تحديث حالة طلب السحب الخاص بك بمبلغ $formattedAmount د.ع',
        };
    }
  }

  /// حفظ الإشعار في قاعدة البيانات
  static Future<void> _saveNotificationToDatabase({
    required String userId,
    required String title,
    required String body,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        'data': data,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      debugPrint('✅ تم حفظ الإشعار في قاعدة البيانات');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ الإشعار: $e');
      // لا نرمي خطأ هنا لأن الإشعار ليس ضرورياً لنجاح العملية
    }
  }

  /// إرسال إشعار عام
  static Future<void> sendGeneralNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    try {
      await _saveNotificationToDatabase(
        userId: userId,
        title: title,
        body: body,
        type: type,
        data: data ?? {},
      );
      
      debugPrint('📱 تم إرسال إشعار عام: $title');
    } catch (e) {
      debugPrint('❌ خطأ في إرسال الإشعار العام: $e');
    }
  }

  /// جلب الإشعارات للمستخدم
  static Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);
          
      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ خطأ في جلب الإشعارات: $e');
      return [];
    }
  }

  /// تحديد الإشعار كمقروء
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
          
      debugPrint('✅ تم تحديد الإشعار كمقروء');
    } catch (e) {
      debugPrint('❌ خطأ في تحديث حالة الإشعار: $e');
    }
  }

  /// عدد الإشعارات غير المقروءة
  static Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);
          
      return response.length;
    } catch (e) {
      debugPrint('❌ خطأ في جلب عدد الإشعارات غير المقروءة: $e');
      return 0;
    }
  }
}
