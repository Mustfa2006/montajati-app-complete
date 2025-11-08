import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

      // إرسال إشعار FCM فعلي عبر خادم الإشعارات
      await _sendFCMNotification(
        userId: userId,
        requestId: requestId,
        newStatus: newStatus,
        amount: amount,
      );

      // طباعة تفاصيل الإشعار
      debugPrint('📱 === تم إرسال الإشعار ===');
      debugPrint('📋 العنوان: ${notificationData['title']}');
      debugPrint('💬 النص: ${notificationData['body']}');
      debugPrint('✅ تم حفظ الإشعار في قاعدة البيانات');
      debugPrint('📤 تم إرسال إشعار FCM للمستخدم');

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

      case 'rejected':
        return {
          'title': '❌ رفض طلب السحب',
          'body': 'تم رفض طلب السحب بمبلغ $formattedAmount د.ع. تم إرجاع المبلغ إلى رصيدك 💰',
        };

      default:
        return {
          'title': 'تحديث حالة السحب',
          'body': 'تم تحديث حالة طلب السحب الخاص بك بمبلغ $formattedAmount د.ع',
        };
    }
  }

  /// إرسال إشعار FCM فعلي عبر الخادم الخلفي
  static Future<void> _sendFCMNotification({
    required String userId,
    required String requestId,
    required String newStatus,
    required double amount,
  }) async {
    try {
      debugPrint('📤 إرسال إشعار FCM عبر الخادم الخلفي...');

      // جلب رقم هاتف المستخدم
      final userResponse = await _supabase
          .from('users')
          .select('phone')
          .eq('id', userId)
          .single();

      final userPhone = userResponse['phone'] ?? '';

      if (userPhone.isEmpty) {
        debugPrint('⚠️ لا يوجد رقم هاتف للمستخدم');
        return;
      }

      // تحديد محتوى الإشعار
      final notificationData = _getNotificationContent(newStatus, amount);

      debugPrint('📱 إرسال إشعار لرقم: $userPhone');
      debugPrint('📋 العنوان: ${notificationData['title']}');
      debugPrint('💬 الرسالة: ${notificationData['body']}');

      // إرسال الإشعار عبر الخادم الخلفي
      final response = await http.post(
  Uri.parse('https://montajati-official-backend-production.up.railway.app/api/notifications/withdrawal-status'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'userPhone': userPhone,
          'requestId': requestId,
          'status': newStatus,
          'amount': amount,
          'title': notificationData['title'],
          'message': notificationData['body'],
          'reason': 'تحديث حالة السحب من لوحة التحكم',
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('📡 استجابة الخادم: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          debugPrint('✅ تم إرسال إشعار FCM بنجاح عبر الخادم الخلفي');

          // حفظ سجل الإشعار الناجح
          await _saveNotificationLog(
            userPhone: userPhone,
            requestId: requestId,
            status: newStatus,
            amount: amount,
            title: notificationData['title']!,
            message: notificationData['body']!,
            success: true,
            firebaseMessageId: responseData['messageId'],
          );
        } else {
          debugPrint('❌ فشل في إرسال إشعار FCM: ${responseData['message']}');
          await _saveNotificationLog(
            userPhone: userPhone,
            requestId: requestId,
            status: newStatus,
            amount: amount,
            title: notificationData['title']!,
            message: notificationData['body']!,
            success: false,
            errorMessage: responseData['message'],
          );
        }
      } else {
        debugPrint('❌ خطأ HTTP في الخادم: ${response.statusCode}');
        debugPrint('📄 محتوى الاستجابة: ${response.body}');

        await _saveNotificationLog(
          userPhone: userPhone,
          requestId: requestId,
          status: newStatus,
          amount: amount,
          title: notificationData['title']!,
          message: notificationData['body']!,
          success: false,
          errorMessage: 'HTTP ${response.statusCode}: ${response.body}',
        );
      }

    } catch (e) {
      debugPrint('❌ خطأ في إرسال إشعار FCM: $e');

      // حفظ سجل الخطأ
      try {
        final userResponse = await _supabase
            .from('users')
            .select('phone')
            .eq('id', userId)
            .single();

        await _saveNotificationLog(
          userPhone: userResponse['phone'] ?? '',
          requestId: requestId,
          status: newStatus,
          amount: amount,
          title: 'خطأ في الإشعار',
          message: 'فشل في إرسال إشعار تحديث السحب',
          success: false,
          errorMessage: e.toString(),
        );
      } catch (logError) {
        debugPrint('❌ خطأ في حفظ سجل الخطأ: $logError');
      }
    }
  }

  /// حفظ سجل الإشعار في قاعدة البيانات
  static Future<void> _saveNotificationLog({
    required String userPhone,
    required String requestId,
    required String status,
    required double amount,
    required String title,
    required String message,
    required bool success,
    String? errorMessage,
    String? firebaseMessageId,
  }) async {
    try {
      await _supabase.from('notification_logs').insert({
        'user_phone': userPhone,
        'notification_type': 'withdrawal_status',
        'title': title,
        'message': message,
        'data': {
          'request_id': requestId,
          'status': status,
          'amount': amount.toString(),
        },
        'success': success,
        'error_message': errorMessage,
        'firebase_message_id': firebaseMessageId,
        'created_at': DateTime.now().toIso8601String(),
        'sent_at': success ? DateTime.now().toIso8601String() : null,
      });

      debugPrint('✅ تم حفظ سجل الإشعار في قاعدة البيانات');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ سجل الإشعار: $e');
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
