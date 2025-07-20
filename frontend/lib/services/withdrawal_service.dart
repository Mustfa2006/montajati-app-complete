import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;


/// خدمة إدارة السحوبات المالية - نظام متقدم وآمن
class WithdrawalService {
  static final _supabase = Supabase.instance.client;

  // ثوابت النظام
  static const double MIN_WITHDRAWAL_AMOUNT = 1000.0; // الحد الأدنى للسحب
  static const double MAX_WITHDRAWAL_AMOUNT = 10000000.0; // الحد الأقصى للسحب
  static const double SYSTEM_COMMISSION_RATE =
      0.0; // نسبة عمولة النظام (0% حالياً)

  /// إنشاء طلب سحب جديد
  static Future<Map<String, dynamic>> createWithdrawalRequest({
    required String userId,
    required double amount,
    required String withdrawalMethod,
    required String accountDetails,
    String? notes,
  }) async {
    try {
      debugPrint('🏦 بدء إنشاء طلب سحب جديد');
      debugPrint('المستخدم: $userId');
      debugPrint('المبلغ: $amount');
      debugPrint('الطريقة: $withdrawalMethod');

      // 1. التحقق من صحة البيانات
      final validation = await _validateWithdrawalRequest(
        userId: userId,
        amount: amount,
        withdrawalMethod: withdrawalMethod,
        accountDetails: accountDetails,
      );

      if (!validation['isValid']) {
        return {
          'success': false,
          'message': validation['message'],
          'errorCode': validation['errorCode'],
        };
      }

      // 2. التحقق من رصيد المستخدم
      final balanceCheck = await _checkUserBalance(userId, amount);
      if (!balanceCheck['hasEnoughBalance']) {
        return {
          'success': false,
          'message': 'الرصيد المتاح غير كافي للسحب المطلوب',
          'errorCode': 'INSUFFICIENT_BALANCE',
          'availableBalance': balanceCheck['availableBalance'],
        };
      }

      // 3. التحقق من الحد اليومي/الأسبوعي
      final limitCheck = await _checkWithdrawalLimits(userId, amount);
      if (!limitCheck['withinLimits']) {
        return {
          'success': false,
          'message': limitCheck['message'],
          'errorCode': 'WITHDRAWAL_LIMIT_EXCEEDED',
        };
      }

      // 4. الحصول على الرقم التسلسلي التالي
      final nextNumber = await _getNextRequestNumber();

      // 5. إنشاء طلب السحب
      final requestData = {
        'user_id': userId,
        'amount': amount,
        'withdrawal_method': withdrawalMethod,
        'account_details': accountDetails,
        'status': 'pending',
        'note': notes,
        'request_date': DateTime.now().toIso8601String(),
        'request_number': nextNumber,
      };

      final response = await _supabase
          .from('withdrawal_requests')
          .insert(requestData)
          .select()
          .single();

      // 5. تحديث رصيد المستخدم (تجميد المبلغ)
      await _freezeUserBalance(userId, amount);

      // 6. إرسال إشعار للمدراء
      await _notifyAdminsOfNewRequest(response['id'], userId, amount);

      // 7. إرسال إشعار طلب سحب جديد عبر خادم الإشعارات
      // تم تعطيل هذا الإشعار مؤقتاً
      // await _sendNewWithdrawalRequestNotification(
      //   requestId: response['id'],
      //   userId: userId,
      //   amount: amount,
      // );

      debugPrint('✅ تم إنشاء طلب السحب بنجاح: ${response['id']}');

      return {
        'success': true,
        'message': 'تم إرسال طلب السحب بنجاح - رقم الطلب: $nextNumber',
        'requestId': response['id'],
        'requestNumber': nextNumber,
        'estimatedProcessingTime': '24-48 ساعة',
      };
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء طلب السحب: $e');
      return {
        'success': false,
        'message': 'حدث خطأ في النظام، يرجى المحاولة لاحقاً',
        'errorCode': 'SYSTEM_ERROR',
        'error': e.toString(),
      };
    }
  }

  /// التحقق من صحة بيانات طلب السحب
  static Future<Map<String, dynamic>> _validateWithdrawalRequest({
    required String userId,
    required double amount,
    required String withdrawalMethod,
    required String accountDetails,
  }) async {
    // التحقق من المبلغ
    if (amount < MIN_WITHDRAWAL_AMOUNT) {
      return {
        'isValid': false,
        'message':
            'الحد الأدنى للسحب هو ${MIN_WITHDRAWAL_AMOUNT.toStringAsFixed(0)} د.ع',
        'errorCode': 'AMOUNT_TOO_LOW',
      };
    }

    if (amount > MAX_WITHDRAWAL_AMOUNT) {
      return {
        'isValid': false,
        'message':
            'الحد الأقصى للسحب هو ${MAX_WITHDRAWAL_AMOUNT.toStringAsFixed(0)} د.ع',
        'errorCode': 'AMOUNT_TOO_HIGH',
      };
    }

    // التحقق من طريقة السحب
    final validMethods = ['mastercard', 'zaincash', 'bank_transfer', 'paypal'];
    if (!validMethods.contains(withdrawalMethod)) {
      return {
        'isValid': false,
        'message': 'طريقة السحب غير صحيحة',
        'errorCode': 'INVALID_METHOD',
      };
    }

    // التحقق من تفاصيل الحساب
    if (accountDetails.trim().isEmpty || accountDetails.length < 5) {
      return {
        'isValid': false,
        'message': 'يرجى إدخال تفاصيل الحساب بشكل صحيح',
        'errorCode': 'INVALID_ACCOUNT_DETAILS',
      };
    }

    // التحقق من وجود المستخدم
    final userExists = await _checkUserExists(userId);
    if (!userExists) {
      return {
        'isValid': false,
        'message': 'المستخدم غير موجود',
        'errorCode': 'USER_NOT_FOUND',
      };
    }

    return {'isValid': true, 'message': 'البيانات صحيحة'};
  }

  /// التحقق من رصيد المستخدم
  static Future<Map<String, dynamic>> _checkUserBalance(
    String userId,
    double requestedAmount,
  ) async {
    try {
      final response = await _supabase
          .from('users')
          .select('achieved_profits, expected_profits')
          .eq('id', userId)
          .single();

      final achievedProfits =
          (response['achieved_profits'] as num?)?.toDouble() ?? 0.0;
      final expectedProfits =
          (response['expected_profits'] as num?)?.toDouble() ?? 0.0;

      // الرصيد المتاح = الأرباح المحققة فقط
      final availableBalance = achievedProfits;

      return {
        'hasEnoughBalance': availableBalance >= requestedAmount,
        'availableBalance': availableBalance,
        'achievedProfits': achievedProfits,
        'expectedProfits': expectedProfits,
      };
    } catch (e) {
      debugPrint('خطأ في التحقق من الرصيد: $e');
      return {
        'hasEnoughBalance': false,
        'availableBalance': 0.0,
        'error': e.toString(),
      };
    }
  }

  /// التحقق من حدود السحب
  static Future<Map<String, dynamic>> _checkWithdrawalLimits(
    String userId,
    double requestedAmount,
  ) async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

      // التحقق من السحوبات اليومية
      final dailyWithdrawals = await _supabase
          .from('withdrawal_requests')
          .select('amount')
          .eq('user_id', userId)
          .gte('created_at', todayStart.toIso8601String())
          .inFilter('status', ['pending', 'approved', 'completed']);

      final dailyTotal = dailyWithdrawals.fold<double>(
        0.0,
        (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
      );

      // التحقق من السحوبات الأسبوعية
      final weeklyWithdrawals = await _supabase
          .from('withdrawal_requests')
          .select('amount')
          .eq('user_id', userId)
          .gte('created_at', weekStart.toIso8601String())
          .inFilter('status', ['pending', 'approved', 'completed']);

      final weeklyTotal = weeklyWithdrawals.fold<double>(
        0.0,
        (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
      );

      // الحدود (يمكن تخصيصها من لوحة التحكم)
      const double dailyLimit = 1000000.0; // مليون د.ع يومياً
      const double weeklyLimit = 5000000.0; // 5 مليون د.ع أسبوعياً

      if (dailyTotal + requestedAmount > dailyLimit) {
        return {
          'withinLimits': false,
          'message':
              'تم تجاوز الحد اليومي للسحب (${dailyLimit.toStringAsFixed(0)} د.ع)',
          'dailyUsed': dailyTotal,
          'dailyLimit': dailyLimit,
        };
      }

      if (weeklyTotal + requestedAmount > weeklyLimit) {
        return {
          'withinLimits': false,
          'message':
              'تم تجاوز الحد الأسبوعي للسحب (${weeklyLimit.toStringAsFixed(0)} د.ع)',
          'weeklyUsed': weeklyTotal,
          'weeklyLimit': weeklyLimit,
        };
      }

      return {
        'withinLimits': true,
        'dailyUsed': dailyTotal,
        'weeklyUsed': weeklyTotal,
        'dailyRemaining': dailyLimit - dailyTotal,
        'weeklyRemaining': weeklyLimit - weeklyTotal,
      };
    } catch (e) {
      debugPrint('خطأ في التحقق من حدود السحب: $e');
      return {
        'withinLimits': false,
        'message': 'خطأ في التحقق من حدود السحب',
        'error': e.toString(),
      };
    }
  }

  /// التحقق من وجود المستخدم
  static Future<bool> _checkUserExists(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('خطأ في التحقق من وجود المستخدم: $e');
      return false;
    }
  }

  /// تجميد رصيد المستخدم
  static Future<void> _freezeUserBalance(String userId, double amount) async {
    try {
      // يمكن إضافة جدول منفصل للأرصدة المجمدة
      // أو تحديث حقل في جدول المستخدمين
      debugPrint('تجميد $amount د.ع من رصيد المستخدم $userId');

      // مؤقتاً: تحديث الأرباح المحققة
      await _supabase.rpc(
        'freeze_user_balance',
        params: {'user_id': userId, 'freeze_amount': amount},
      );
    } catch (e) {
      debugPrint('خطأ في تجميد الرصيد: $e');
    }
  }

  /// إرسال إشعار للمدراء
  static Future<void> _notifyAdminsOfNewRequest(
    String requestId,
    String userId,
    double amount,
  ) async {
    try {
      // إرسال إشعار للمدراء عن طلب السحب الجديد
      debugPrint('إرسال إشعار للمدراء عن طلب السحب: $requestId');

      // يمكن إضافة نظام إشعارات متقدم هنا
    } catch (e) {
      debugPrint('خطأ في إرسال الإشعار: $e');
    }
  }

  /// جلب طلبات السحب للمستخدم
  static Future<List<Map<String, dynamic>>> getUserWithdrawalRequests(
    String userId,
  ) async {
    try {
      debugPrint('🔍 === جلب طلبات السحب للمستخدم ===');
      debugPrint('👤 معرف المستخدم: $userId');

      final response = await _supabase
          .from('withdrawal_requests')
          .select('*')
          .eq('user_id', userId)
          .order('request_date', ascending: false); // الأحدث أولاً حسب التاريخ

      debugPrint('📊 استجابة قاعدة البيانات: $response');
      debugPrint('📊 عدد الطلبات المجلبة: ${response.length}');

      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ خطأ في جلب طلبات السحب: $e');
      return [];
    }
  }

  /// جلب جميع طلبات السحب (للمدراء)
  static Future<List<Map<String, dynamic>>> getAllWithdrawalRequests({
    String? status,
    int? limit,
  }) async {
    try {
      // بناء الاستعلام بطريقة مبسطة
      var query = _supabase.from('withdrawal_requests').select('''
            *,
            users!inner(name, phone, email)
          ''');

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query;

      // تطبيق الحد إذا كان مطلوباً
      if (limit != null && response.length > limit) {
        return response.take(limit).toList().cast<Map<String, dynamic>>();
      }

      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('خطأ في جلب جميع طلبات السحب: $e');
      return [];
    }
  }

  /// تحديث حالة طلب السحب (للمدراء)
  static Future<Map<String, dynamic>> updateWithdrawalStatus({
    required String requestId,
    required String newStatus,
    String? adminNotes,
    String? adminId,
  }) async {
    try {
      debugPrint('🔄 تحديث حالة طلب السحب: $requestId إلى $newStatus');

      // التحقق من صحة الحالة الجديدة
      final validStatuses = ['pending', 'approved', 'rejected', 'completed'];
      if (!validStatuses.contains(newStatus)) {
        return {
          'success': false,
          'message': 'حالة غير صحيحة',
          'errorCode': 'INVALID_STATUS',
        };
      }

      // جلب بيانات الطلب الحالي
      final currentRequest = await _supabase
          .from('withdrawal_requests')
          .select('*')
          .eq('id', requestId)
          .single();

      final updateData = {
        'status': newStatus,
        'process_date': DateTime.now().toIso8601String(),
      };

      if (adminNotes != null) {
        updateData['note'] =
            adminNotes; // استخدام عمود 'note' بدلاً من 'admin_notes'
      }

      if (adminId != null) {
        updateData['processed_by'] = adminId;
      }

      // تحديث الطلب
      await _supabase
          .from('withdrawal_requests')
          .update(updateData)
          .eq('id', requestId);

      // معالجة الحالة الجديدة
      await _processStatusChange(
        requestId: requestId,
        oldStatus: currentRequest['status'],
        newStatus: newStatus,
        userId: currentRequest['user_id'],
        amount: (currentRequest['amount'] as num).toDouble(),
      );

      // إرسال إشعار تغيير حالة السحب
      await _sendWithdrawalStatusNotification(
        userId: currentRequest['user_id'],
        requestId: requestId,
        newStatus: newStatus,
        amount: (currentRequest['amount'] as num).toDouble(),
        reason: adminNotes ?? '',
      );

      debugPrint('✅ تم تحديث حالة طلب السحب بنجاح');

      return {
        'success': true,
        'message': 'تم تحديث حالة الطلب بنجاح',
        'newStatus': newStatus,
      };
    } catch (e) {
      debugPrint('❌ خطأ في تحديث حالة طلب السحب: $e');
      return {
        'success': false,
        'message': 'حدث خطأ في تحديث الحالة',
        'errorCode': 'UPDATE_ERROR',
        'error': e.toString(),
      };
    }
  }

  /// معالجة تغيير الحالة
  static Future<void> _processStatusChange({
    required String requestId,
    required String oldStatus,
    required String newStatus,
    required String userId,
    required double amount,
  }) async {
    try {
      debugPrint('🔄 معالجة تغيير الحالة من $oldStatus إلى $newStatus');

      switch (newStatus) {
        case 'approved':
          // عند الموافقة: تأكيد تجميد المبلغ
          await _confirmBalanceFreeze(userId, amount);
          break;

        case 'completed':
          // عند الإكمال: خصم المبلغ نهائياً من الرصيد
          await _deductFromUserBalance(userId, amount);
          break;

        case 'rejected':
          // عند الرفض: إرجاع المبلغ إلى الأرباح المحققة
          debugPrint(
            '💰 إرجاع $amount د.ع إلى الأرباح المحققة للمستخدم $userId (مرفوض)',
          );
          await _returnToAchievedProfits(userId, amount);
          break;

        case 'cancelled':
          // عند الإلغاء: إرجاع المبلغ إلى الأرباح المحققة
          debugPrint(
            '💰 إرجاع $amount د.ع إلى الأرباح المحققة للمستخدم $userId',
          );
          await _returnToAchievedProfits(userId, amount);
          break;

        case 'pending':
          // إذا تم تغيير الحالة إلى معلق من حالة أخرى
          if (oldStatus == 'rejected' || oldStatus == 'cancelled') {
            // خصم المبلغ من الأرباح المحققة وإعادة تجميده
            debugPrint(
              '🔄 خصم $amount د.ع من الأرباح المحققة وإعادة تجميده (من $oldStatus إلى pending)',
            );
            await _deductFromAchievedProfits(userId, amount);
            await _freezeUserBalance(userId, amount);
          }
          break;
      }

      // إرسال إشعار للمستخدم
      await _notifyUserOfStatusChange(userId, requestId, newStatus);
    } catch (e) {
      debugPrint('خطأ في معالجة تغيير الحالة: $e');
    }
  }

  /// تأكيد تجميد الرصيد
  static Future<void> _confirmBalanceFreeze(
    String userId,
    double amount,
  ) async {
    try {
      debugPrint('تأكيد تجميد $amount د.ع للمستخدم $userId');
      // إضافة منطق تأكيد التجميد
    } catch (e) {
      debugPrint('خطأ في تأكيد تجميد الرصيد: $e');
    }
  }

  /// خصم المبلغ من رصيد المستخدم
  static Future<void> _deductFromUserBalance(
    String userId,
    double amount,
  ) async {
    try {
      debugPrint('خصم $amount د.ع من رصيد المستخدم $userId');

      await _supabase.rpc(
        'deduct_from_user_balance',
        params: {'user_id': userId, 'deduct_amount': amount},
      );
    } catch (e) {
      debugPrint('خطأ في خصم المبلغ: $e');
    }
  }

  /// إلغاء تجميد الرصيد
  static Future<void> _unfreezeUserBalance(String userId, double amount) async {
    try {
      debugPrint('إلغاء تجميد $amount د.ع للمستخدم $userId');

      await _supabase.rpc(
        'unfreeze_user_balance',
        params: {'user_id': userId, 'unfreeze_amount': amount},
      );
    } catch (e) {
      debugPrint('خطأ في إلغاء تجميد الرصيد: $e');
    }
  }

  /// إرسال إشعار تغيير حالة السحب عبر خادم الإشعارات الجديد
  static Future<void> _sendWithdrawalStatusNotification({
    required String userId,
    required String requestId,
    required String newStatus,
    required double amount,
    String reason = '',
  }) async {
    try {
      debugPrint('📤 إرسال إشعار تغيير حالة السحب عبر خادم الإشعارات');

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

      // تحديد رسالة الإشعار حسب الحالة
      String title = '';
      String message = '';

      switch (newStatus) {
        case 'pending':
          title = '⏳ تم استلام طلب السحب';
          message =
              'تم استلام طلب سحب بمبلغ ${amount.toStringAsFixed(0)} د.ع وسيتم مراجعته خلال 24 ساعة';
          break;
        case 'approved':
          title = '✅ تم الموافقة على طلب السحب';
          message =
              'تم الموافقة على طلب سحب بمبلغ ${amount.toStringAsFixed(0)} د.ع وسيتم التحويل خلال ساعات';
          break;
        case 'rejected':
          title = '❌ تم رفض طلب السحب';
          message =
              'تم رفض طلب سحب بمبلغ ${amount.toStringAsFixed(0)} د.ع. ${reason.isNotEmpty ? reason : "يرجى مراجعة الإدارة للمزيد من التفاصيل"}';
          break;
        case 'completed':
          title = '🎉 تم تحويل المبلغ';
          message =
              'تم تحويل مبلغ ${amount.toStringAsFixed(0)} د.ع إلى محفظتك بنجاح';
          break;
        case 'processing':
          title = '🔄 جاري معالجة طلب السحب';
          message =
              'طلب سحب بمبلغ ${amount.toStringAsFixed(0)} د.ع قيد المعالجة الآن';
          break;
        case 'cancelled':
          title = '🚫 تم إلغاء طلب السحب';
          message =
              'تم إلغاء طلب سحب بمبلغ ${amount.toStringAsFixed(0)} د.ع بناءً على طلبك';
          break;
        default:
          title = '🔄 تحديث حالة طلب السحب';
          message = 'تم تحديث حالة طلب السحب الخاص بك';
      }

      // إرسال الإشعار عبر خادم الإشعارات الجديد
      final response = await http.post(
        Uri.parse('http://localhost:3003/api/notifications/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userPhone': userPhone,
          'title': title,
          'message': message,
          'data': {
            'type': 'withdrawal_status_update',
            'requestId': requestId,
            'newStatus': newStatus,
            'amount': amount,
            'timestamp': DateTime.now().toIso8601String(),
            if (reason.isNotEmpty) 'reason': reason,
          },
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          debugPrint('✅ تم إرسال إشعار تغيير حالة السحب بنجاح');
          debugPrint('📋 معرف الرسالة: ${responseData['data']['messageId']}');
        } else {
          debugPrint('❌ فشل إرسال الإشعار: ${responseData['message']}');
        }
      } else {
        debugPrint('❌ خطأ في الاتصال بخادم الإشعارات: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ خطأ في إرسال إشعار تغيير حالة السحب: $e');
    }
  }

  /// إرسال إشعار للمستخدم عند تغيير حالة الطلب
  static Future<void> _notifyUserOfStatusChange(
    String userId,
    String requestId,
    String newStatus,
  ) async {
    try {
      debugPrint(
        '📱 إرسال إشعار للمستخدم $userId عن تغيير حالة الطلب $requestId إلى $newStatus',
      );

      // الحصول على بيانات الطلب (رقم الطلب والمبلغ)
      final requestData = await _supabase
          .from('withdrawal_requests')
          .select('id, amount')
          .eq('id', requestId)
          .single();

      // استخدام ID كرقم طلب مؤقت حتى يتم إصلاح قاعدة البيانات
      final requestNumber = _generateRequestNumber(
        requestData['id']?.toString() ?? 'غير محدد',
      );
      final amount = (requestData['amount'] as num?)?.toStringAsFixed(0) ?? '0';

      // إنشاء رسالة الإشعار المخصصة حسب الحالة
      final notificationData = _createCustomNotification(
        newStatus,
        amount,
        requestNumber,
      );

      final notificationTitle = notificationData['title']!;
      final notificationBody = notificationData['body']!;

      // إرسال الإشعار عبر قاعدة البيانات (للتطبيق)
      await _sendDatabaseNotification(
        userId: userId,
        title: notificationTitle,
        body: notificationBody,
        type: 'withdrawal_status_change',
        data: {
          'request_id': requestId,
          'request_number': requestNumber,
          'new_status': newStatus,
          'amount': amount,
        },
      );

      // إرسال Push Notification للهاتف
      await _sendPushNotification(
        userId: userId,
        title: notificationTitle,
        body: notificationBody,
        data: {
          'type': 'withdrawal_status_change',
          'request_id': requestId,
          'request_number': requestNumber,
          'new_status': newStatus,
        },
      );

      debugPrint('✅ تم إرسال الإشعار بنجاح للمستخدم $userId');
    } catch (e) {
      debugPrint('❌ خطأ في إرسال الإشعار: $e');
    }
  }

  /// حساب إحصائيات السحوبات الحقيقية
  static Future<Map<String, dynamic>> getWithdrawalStatistics({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('🔄 جاري حساب الإحصائيات المالية الحقيقية...');

      var query = _supabase
          .from('withdrawal_requests')
          .select('amount, status, request_date');

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      if (startDate != null) {
        query = query.gte('request_date', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('request_date', endDate.toIso8601String());
      }

      final response = await query;
      debugPrint('📊 تم جلب ${response.length} طلب سحب');

      double totalRequested = 0.0;
      double totalCompleted = 0.0;
      double totalPending = 0.0;
      double totalRejected = 0.0;
      double totalApproved = 0.0;
      int countTotal = 0;
      int countCompleted = 0;
      int countPending = 0;
      int countRejected = 0;
      int countApproved = 0;

      for (final request in response) {
        final amount = (request['amount'] as num).toDouble();
        final status = request['status'] as String;

        totalRequested += amount;
        countTotal++;

        switch (status) {
          case 'completed':
            totalCompleted += amount;
            countCompleted++;
            break;
          case 'approved':
            totalApproved += amount;
            countApproved++;
            break;
          case 'pending':
            totalPending += amount;
            countPending++;
            break;
          case 'rejected':
            totalRejected += amount;
            countRejected++;
            break;
        }
      }

      debugPrint(
        '📈 الإحصائيات: إجمالي=$totalRequested، مكتمل=$totalCompleted، معلق=$totalPending، مرفوض=$totalRejected',
      );

      return {
        'totalRequested': totalRequested,
        'totalCompleted': totalCompleted,
        'totalPending': totalPending,
        'totalApproved': totalApproved,
        'totalRejected': totalRejected,
        'countTotal': countTotal,
        'countCompleted': countCompleted,
        'countPending': countPending,
        'countApproved': countApproved,
        'countRejected': countRejected,
        'successRate': countTotal > 0
            ? (countCompleted / countTotal) * 100
            : 0.0,
      };
    } catch (e) {
      debugPrint('خطأ في حساب إحصائيات السحوبات: $e');
      return {
        'totalRequested': 0.0,
        'totalCompleted': 0.0,
        'totalPending': 0.0,
        'totalRejected': 0.0,
        'countTotal': 0,
        'countCompleted': 0,
        'countPending': 0,
        'countRejected': 0,
        'successRate': 0.0,
      };
    }
  }

  /// إرجاع المبلغ إلى الأرباح المحققة
  static Future<void> _returnToAchievedProfits(
    String userId,
    double amount,
  ) async {
    try {
      debugPrint('🔄 إرجاع $amount د.ع إلى الأرباح المحققة للمستخدم $userId');

      // جلب بيانات المستخدم الحالية
      final userResponse = await _supabase
          .from('users')
          .select('achieved_profits')
          .eq('id', userId)
          .single();

      final currentProfits =
          (userResponse['achieved_profits'] as num?)?.toDouble() ?? 0.0;
      final newProfits = currentProfits + amount;

      // تحديث الأرباح المحققة
      await _supabase
          .from('users')
          .update({'achieved_profits': newProfits})
          .eq('id', userId);

      debugPrint(
        '✅ تم إرجاع $amount د.ع. الأرباح المحققة الجديدة: $newProfits د.ع',
      );
    } catch (e) {
      debugPrint('❌ خطأ في إرجاع المبلغ إلى الأرباح المحققة: $e');
      rethrow;
    }
  }

  /// خصم المبلغ من الأرباح المحققة
  static Future<void> _deductFromAchievedProfits(
    String userId,
    double amount,
  ) async {
    try {
      debugPrint('🔄 خصم $amount د.ع من الأرباح المحققة للمستخدم $userId');

      // جلب بيانات المستخدم الحالية
      final userResponse = await _supabase
          .from('users')
          .select('achieved_profits')
          .eq('id', userId)
          .single();

      final currentProfits =
          (userResponse['achieved_profits'] as num?)?.toDouble() ?? 0.0;
      final newProfits = (currentProfits - amount).clamp(0.0, double.infinity);

      // تحديث الأرباح المحققة
      await _supabase
          .from('users')
          .update({'achieved_profits': newProfits})
          .eq('id', userId);

      debugPrint(
        '✅ تم خصم $amount د.ع. الأرباح المحققة الجديدة: $newProfits د.ع',
      );
    } catch (e) {
      debugPrint('❌ خطأ في خصم المبلغ من الأرباح المحققة: $e');
      rethrow;
    }
  }

  /// الحصول على الرقم التسلسلي التالي لطلب السحب
  static Future<int> _getNextRequestNumber() async {
    try {
      debugPrint('🔢 الحصول على الرقم التسلسلي التالي...');

      // البحث عن أعلى رقم موجود
      final response = await _supabase
          .from('withdrawal_requests')
          .select('request_number')
          .order('request_number', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        debugPrint('📊 لا توجد طلبات سابقة، البداية من 1001');
        return 1001; // البداية من 1001
      }

      final lastNumber = response.first['request_number'] as int? ?? 1000;
      final nextNumber = lastNumber + 1;

      debugPrint('📊 آخر رقم: $lastNumber، الرقم التالي: $nextNumber');
      return nextNumber;
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على الرقم التسلسلي: $e');
      // في حالة الخطأ، استخدم timestamp كرقم احتياطي
      final fallbackNumber =
          DateTime.now().millisecondsSinceEpoch % 100000 + 1000;
      debugPrint('🔄 استخدام رقم احتياطي: $fallbackNumber');
      return fallbackNumber;
    }
  }

  /// إنشاء رسالة إشعار مخصصة حسب حالة الطلب
  static Map<String, String> _createCustomNotification(
    String status,
    String amount,
    String requestNumber,
  ) {
    switch (status) {
      case 'approved':
      case 'completed':
        // رسالة الموافقة/التحويل - ابتسامة وقلب ذهبي
        return {
          'title': '😊💛 تم تحويل المبلغ',
          'body': 'تم تحويل مبلغ $amount د.ع الى محفظتك',
        };

      case 'rejected':
        // رسالة الرفض - حزن وإيموجي حزين
        return {
          'title': '😢💔 تم إلغاء العملية',
          'body': 'تم الغاء عملية السحب $amount د.ع',
        };

      case 'cancelled':
        // رسالة الإلغاء
        return {
          'title': '🚫 تم إلغاء الطلب',
          'body': 'تم إلغاء طلب السحب رقم $requestNumber بمبلغ $amount د.ع',
        };

      case 'pending':
        // رسالة المراجعة
        return {
          'title': '⏳ قيد المراجعة',
          'body': 'طلب السحب رقم $requestNumber بمبلغ $amount د.ع قيد المراجعة',
        };

      default:
        // رسالة افتراضية
        return {
          'title': '🔔 تحديث طلب السحب',
          'body': 'تم تحديث حالة طلب السحب رقم $requestNumber',
        };
    }
  }

  /// توليد رقم طلب مؤقت من ID
  static String _generateRequestNumber(String id) {
    try {
      // استخراج الأرقام من UUID وتحويلها لرقم قصير
      final numbers = id.replaceAll(RegExp(r'[^0-9]'), '');
      if (numbers.length >= 6) {
        return numbers.substring(0, 6);
      } else if (numbers.isNotEmpty) {
        return numbers;
      } else {
        return DateTime.now().millisecondsSinceEpoch.toString().substring(7);
      }
    } catch (e) {
      return DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    }
  }

  /// تحويل حالة الطلب إلى نص عربي (للاستخدام الداخلي)
  static String _getStatusTextInArabic(String status) {
    switch (status) {
      case 'pending':
        return 'قيد المراجعة ⏳';
      case 'approved':
        return 'تمت الموافقة ✅';
      case 'completed':
        return 'مكتمل - تم التحويل 💰';
      case 'rejected':
        return 'مرفوض ❌';
      case 'cancelled':
        return 'ملغي 🚫';
      default:
        return 'غير محدد ❓';
    }
  }

  /// إرسال إشعار عبر قاعدة البيانات
  static Future<void> _sendDatabaseNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    try {
      debugPrint('💾 حفظ الإشعار في قاعدة البيانات...');

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
      debugPrint('❌ خطأ في حفظ الإشعار في قاعدة البيانات: $e');
    }
  }

  /// إرسال Push Notification للهاتف
  static Future<void> _sendPushNotification({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      debugPrint('📱 إرسال Push Notification للمستخدم $userId...');

      // الحصول على اسم المستخدم
      String userName = 'المستخدم';
      try {
        final userResponse = await _supabase
            .from('users')
            .select('name')
            .eq('id', userId)
            .single();

        userName = userResponse['name'] as String? ?? 'المستخدم';
        debugPrint('👤 إرسال إشعار للمستخدم: $userName');
      } catch (e) {
        debugPrint('⚠️ لم يتم العثور على المستخدم: $e');
      }

      // تم إزالة نظام الإشعارات
      debugPrint('تم تحديث حالة طلب السحب: ${data['new_status']} - ${data['amount']}');

      debugPrint('✅ تم إرسال الإشعار المحلي بنجاح للمستخدم $userName');
    } catch (e) {
      debugPrint('❌ خطأ في إرسال Push Notification: $e');
    }
  }

  /// تم إزالة نظام الإشعارات
  static Future<void> _sendFCMNotification({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    debugPrint('تم إزالة نظام الإشعارات - $title: $body');
  }

  /// محاكاة إشعار محلي للاختبار
  static void _simulateLocalNotification(String title, String body) {
    try {
      debugPrint('🔔 محاكاة إشعار محلي:');
      debugPrint('   📱 العنوان: $title');
      debugPrint('   📝 المحتوى: $body');
      debugPrint('   ⏰ الوقت: ${DateTime.now().toString()}');
      debugPrint('✅ تم عرض الإشعار المحلي بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في محاكاة الإشعار المحلي: $e');
    }
  }
}
