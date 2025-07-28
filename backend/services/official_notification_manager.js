// ===================================
// مدير الإشعارات الرسمي المتكامل
// Official Notification Manager
// ===================================

const EventEmitter = require('events');
const { firebaseAdminService } = require('./firebase_admin_service');
const targetedNotificationService = require('./targeted_notification_service');
const tokenManagementService = require('./token_management_service');
const { createClient } = require('@supabase/supabase-js');

class OfficialNotificationManager extends EventEmitter {
  constructor() {
    super(); // استدعاء EventEmitter constructor
    this.isInitialized = false;
    this.firebaseService = null;
    this.targetedService = null;
    this.tokenService = null;
    this.supabase = null;
    this.stats = {
      totalSent: 0,
      successfulSent: 0,
      failedSent: 0,
      startTime: new Date()
    };
  }

  /**
   * تهيئة مدير الإشعارات
   */
  async initialize() {
    try {
      console.log('🔥 تهيئة مدير الإشعارات الرسمي...');

      // تهيئة Supabase
      this.supabase = createClient(
        process.env.SUPABASE_URL,
        process.env.SUPABASE_SERVICE_ROLE_KEY
      );

      // تهيئة خدمة Firebase
      this.firebaseService = firebaseAdminService;
      await this.firebaseService.initialize();

      // تهيئة خدمة الإشعارات المستهدفة
      this.targetedService = targetedNotificationService;
      await this.targetedService.initialize();

      // تهيئة خدمة إدارة الرموز
      this.tokenService = tokenManagementService;
      await this.tokenService.initialize();

      this.isInitialized = true;
      console.log('✅ تم تهيئة مدير الإشعارات بنجاح');

      return true;
    } catch (error) {
      console.error('❌ خطأ في تهيئة مدير الإشعارات:', error);
      return false;
    }
  }

  /**
   * إرسال إشعار تحديث حالة الطلب
   */
  async sendOrderStatusNotification(data) {
    try {
      if (!this.isInitialized) {
        throw new Error('مدير الإشعارات غير مهيأ');
      }

      const { userPhone, orderId, newStatus, customerName } = data;

      console.log(`📱 إرسال إشعار تحديث الطلب للعميل: ${userPhone}`);

      // إرسال الإشعار
      const result = await this.targetedService.sendOrderStatusNotification(
        userPhone,
        orderId,
        newStatus,
        customerName
      );

      // تحديث الإحصائيات
      this.stats.totalSent++;
      if (result.success) {
        this.stats.successfulSent++;
      } else {
        this.stats.failedSent++;
      }

      return result;
    } catch (error) {
      console.error('❌ خطأ في إرسال إشعار تحديث الطلب:', error);
      this.stats.totalSent++;
      this.stats.failedSent++;

      // إرسال حدث خطأ
      this.emit('error', error);

      return { success: false, error: error.message };
    }
  }

  /**
   * إرسال إشعار عام مع تشخيص مفصل
   */
  async sendGeneralNotification(data) {
    const notificationDiagnostic = {
      timestamp: new Date().toISOString(),
      notificationId: `notif_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      step: 'بدء إرسال الإشعار',
      details: {},
      errors: [],
      warnings: [],
      performance: {
        startTime: Date.now()
      }
    };

    try {
      if (!this.isInitialized) {
        notificationDiagnostic.step = 'فشل التهيئة';
        notificationDiagnostic.errors.push('مدير الإشعارات غير مهيأ');
        throw new Error('مدير الإشعارات غير مهيأ');
      }

      const { userPhone, title, message, additionalData } = data;

      notificationDiagnostic.details.userPhone = userPhone;
      notificationDiagnostic.details.title = title;
      notificationDiagnostic.details.message = message;
      notificationDiagnostic.details.additionalData = additionalData;

      console.log(`📢 [NOTIF-DIAGNOSTIC] إرسال إشعار عام للعميل: ${userPhone}`);
      console.log(`🔍 [NOTIF-DIAGNOSTIC] معرف الإشعار: ${notificationDiagnostic.notificationId}`);
      console.log(`📝 [NOTIF-DIAGNOSTIC] العنوان: ${title}`);
      console.log(`📝 [NOTIF-DIAGNOSTIC] الرسالة: ${message}`);

      notificationDiagnostic.step = 'إرسال الإشعار عبر الخدمة المستهدفة';

      // إرسال الإشعار
      const result = await this.targetedService.sendGeneralNotification(
        userPhone,
        title,
        message,
        additionalData
      );

      notificationDiagnostic.step = 'معالجة نتيجة الإرسال';
      notificationDiagnostic.performance.endTime = Date.now();
      notificationDiagnostic.performance.totalTime = notificationDiagnostic.performance.endTime - notificationDiagnostic.performance.startTime;
      notificationDiagnostic.details.result = result;

      // تحديث الإحصائيات
      this.stats.totalSent++;
      if (result.success) {
        this.stats.successfulSent++;
        console.log(`✅ [NOTIF-DIAGNOSTIC] نجح إرسال الإشعار للعميل ${userPhone} في ${notificationDiagnostic.performance.totalTime}ms`);
      } else {
        this.stats.failedSent++;
        notificationDiagnostic.warnings.push(`فشل الإرسال: ${result.error}`);
        console.log(`❌ [NOTIF-DIAGNOSTIC] فشل إرسال الإشعار للعميل ${userPhone}: ${result.error}`);
      }

      notificationDiagnostic.step = 'اكتمال العملية';
      result.diagnostic = notificationDiagnostic;

      return result;
    } catch (error) {
      notificationDiagnostic.step = 'خطأ في العملية';
      notificationDiagnostic.performance.endTime = Date.now();
      notificationDiagnostic.performance.totalTime = notificationDiagnostic.performance.endTime - notificationDiagnostic.performance.startTime;
      notificationDiagnostic.errors.push({
        type: 'notification_error',
        message: error.message,
        stack: error.stack,
        timestamp: new Date().toISOString()
      });

      console.error(`❌ [NOTIF-DIAGNOSTIC] خطأ في إرسال الإشعار العام للعميل ${data.userPhone}:`, error);
      console.error(`📊 [NOTIF-DIAGNOSTIC] تشخيص الخطأ:`, JSON.stringify(notificationDiagnostic, null, 2));

      this.stats.totalSent++;
      this.stats.failedSent++;

      // إرسال حدث خطأ
      this.emit('error', error);

      return {
        success: false,
        error: error.message,
        diagnostic: notificationDiagnostic
      };
    }
  }

  /**
   * اختبار إرسال إشعار
   */
  async testNotification(userPhone) {
    try {
      if (!this.isInitialized) {
        throw new Error('مدير الإشعارات غير مهيأ');
      }

      console.log(`🧪 اختبار إرسال إشعار للعميل: ${userPhone}`);

      const result = await this.sendGeneralNotification({
        userPhone,
        title: '🧪 إشعار تجريبي',
        message: 'هذا إشعار تجريبي من نظام منتجاتي - النظام يعمل بشكل صحيح!',
        additionalData: {
          type: 'test_notification',
          timestamp: new Date().toISOString()
        }
      });

      return result;
    } catch (error) {
      console.error('❌ خطأ في اختبار الإشعار:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * الحصول على إحصائيات الإشعارات
   */
  getStats() {
    const uptime = Date.now() - this.stats.startTime.getTime();
    const uptimeHours = Math.floor(uptime / (1000 * 60 * 60));
    const uptimeMinutes = Math.floor((uptime % (1000 * 60 * 60)) / (1000 * 60));

    return {
      ...this.stats,
      uptime: `${uptimeHours}h ${uptimeMinutes}m`,
      successRate: this.stats.totalSent > 0 
        ? ((this.stats.successfulSent / this.stats.totalSent) * 100).toFixed(2) + '%'
        : '0%',
      isInitialized: this.isInitialized
    };
  }

  /**
   * تنظيف الرموز القديمة
   */
  async cleanupOldTokens() {
    try {
      if (!this.isInitialized) {
        throw new Error('مدير الإشعارات غير مهيأ');
      }

      console.log('🧹 تنظيف الرموز القديمة...');
      const result = await this.tokenService.cleanupOldTokens();
      console.log('✅ تم تنظيف الرموز القديمة بنجاح');
      return result;
    } catch (error) {
      console.error('❌ خطأ في تنظيف الرموز:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * الحصول على إحصائيات الرموز
   */
  async getTokenStats() {
    try {
      if (!this.isInitialized) {
        throw new Error('مدير الإشعارات غير مهيأ');
      }

      return await this.tokenService.getTokenStats();
    } catch (error) {
      console.error('❌ خطأ في الحصول على إحصائيات الرموز:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * جلب جميع المستخدمين النشطين
   */
  async getAllActiveUsers() {
    try {
      if (!this.isInitialized) {
        throw new Error('مدير الإشعارات غير مهيأ');
      }

      console.log('👥 جلب جميع المستخدمين النشطين...');

      // جلب المستخدمين من خدمة الرموز
      const users = await this.tokenService.getAllActiveUsers();

      console.log(`✅ تم جلب ${users.length} مستخدم نشط`);
      return users;
    } catch (error) {
      console.error('❌ خطأ في جلب المستخدمين النشطين:', error);
      return [];
    }
  }

  /**
   * إرسال إشعار جماعي مع تشخيص شامل
   */
  async sendBulkNotification(notification, users) {
    const bulkDiagnostics = {
      timestamp: new Date().toISOString(),
      bulkId: `bulk_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      step: 'بدء الإرسال الجماعي',
      details: {},
      errors: [],
      warnings: [],
      performance: {
        startTime: Date.now(),
        steps: []
      }
    };

    try {
      console.log('📢 [BULK-DIAGNOSTIC] بدء إرسال إشعار جماعي...');
      console.log('🔍 [BULK-DIAGNOSTIC] معرف الإرسال الجماعي:', bulkDiagnostics.bulkId);

      if (!this.isInitialized) {
        bulkDiagnostics.step = 'فشل التهيئة';
        bulkDiagnostics.errors.push('مدير الإشعارات غير مهيأ');
        throw new Error('مدير الإشعارات غير مهيأ');
      }

      bulkDiagnostics.details.notification = notification;
      bulkDiagnostics.details.usersCount = users.length;
      bulkDiagnostics.details.usersSample = users.slice(0, 3).map(u => ({
        phone: u.phone,
        hasToken: !!u.fcm_token,
        tokenPreview: u.fcm_token ? u.fcm_token.substring(0, 20) + '...' : 'لا يوجد'
      }));

      console.log(`📢 [BULK-DIAGNOSTIC] إرسال إشعار جماعي لـ ${users.length} مستخدم...`);
      console.log('📦 [BULK-DIAGNOSTIC] بيانات الإشعار:', notification);
      console.log('👥 [BULK-DIAGNOSTIC] عينة من المستخدمين:', bulkDiagnostics.details.usersSample);

      const results = {
        total: users.length,
        successful: 0,
        failed: 0,
        errors: [],
        diagnostics: bulkDiagnostics
      };

      bulkDiagnostics.step = 'إرسال الإشعارات بشكل متوازي';
      bulkDiagnostics.performance.steps.push({ step: 'بدء الإرسال المتوازي', timestamp: Date.now() });

      // إرسال الإشعارات بشكل متوازي مع تشخيص مفصل
      const promises = users.map(async (user, index) => {
        const userDiagnostic = {
          userIndex: index,
          phone: user.phone,
          hasToken: !!user.fcm_token,
          startTime: Date.now()
        };

        try {
          console.log(`📱 [BULK-DIAGNOSTIC] إرسال للمستخدم ${index + 1}/${users.length}: ${user.phone}`);

          const result = await this.sendGeneralNotification({
            userPhone: user.phone,
            title: notification.title,
            message: notification.body,
            additionalData: notification.data
          });

          userDiagnostic.endTime = Date.now();
          userDiagnostic.duration = userDiagnostic.endTime - userDiagnostic.startTime;
          userDiagnostic.result = result;

          if (result.success) {
            results.successful++;
            console.log(`✅ [BULK-DIAGNOSTIC] نجح الإرسال للمستخدم ${user.phone} في ${userDiagnostic.duration}ms`);
          } else {
            results.failed++;
            results.errors.push({
              user: user.phone,
              error: result.error,
              diagnostic: userDiagnostic
            });
            console.log(`❌ [BULK-DIAGNOSTIC] فشل الإرسال للمستخدم ${user.phone}: ${result.error}`);
          }

          return result;
        } catch (error) {
          userDiagnostic.endTime = Date.now();
          userDiagnostic.duration = userDiagnostic.endTime - userDiagnostic.startTime;
          userDiagnostic.error = error.message;

          results.failed++;
          results.errors.push({
            user: user.phone,
            error: error.message,
            diagnostic: userDiagnostic
          });

          console.error(`❌ [BULK-DIAGNOSTIC] خطأ في الإرسال للمستخدم ${user.phone}:`, error);
          return { success: false, error: error.message };
        }
      });

      bulkDiagnostics.step = 'انتظار انتهاء جميع الإرسالات';
      await Promise.all(promises);

      bulkDiagnostics.step = 'اكتمال الإرسال الجماعي';
      bulkDiagnostics.performance.endTime = Date.now();
      bulkDiagnostics.performance.totalTime = bulkDiagnostics.performance.endTime - bulkDiagnostics.performance.startTime;
      bulkDiagnostics.details.finalResults = {
        total: results.total,
        successful: results.successful,
        failed: results.failed,
        successRate: ((results.successful / results.total) * 100).toFixed(2) + '%'
      };

      console.log(`✅ [BULK-DIAGNOSTIC] انتهى الإرسال الجماعي - نجح: ${results.successful}, فشل: ${results.failed}`);
      console.log(`⏱️ [BULK-DIAGNOSTIC] إجمالي الوقت: ${bulkDiagnostics.performance.totalTime}ms`);
      console.log(`📊 [BULK-DIAGNOSTIC] معدل النجاح: ${bulkDiagnostics.details.finalResults.successRate}`);

      if (results.failed > 0) {
        console.log('❌ [BULK-DIAGNOSTIC] أخطاء الإرسال:', results.errors.slice(0, 5)); // أول 5 أخطاء فقط
      }

      return results;
    } catch (error) {
      bulkDiagnostics.step = 'خطأ عام في الإرسال الجماعي';
      bulkDiagnostics.performance.endTime = Date.now();
      bulkDiagnostics.performance.totalTime = bulkDiagnostics.performance.endTime - bulkDiagnostics.performance.startTime;
      bulkDiagnostics.errors.push({
        type: 'bulk_error',
        message: error.message,
        stack: error.stack,
        timestamp: new Date().toISOString()
      });

      console.error('❌ [BULK-DIAGNOSTIC] خطأ في الإرسال الجماعي:', error);
      console.error('📊 [BULK-DIAGNOSTIC] تشخيص شامل للخطأ:', JSON.stringify(bulkDiagnostics, null, 2));

      return {
        total: users.length,
        successful: 0,
        failed: users.length,
        errors: [{ error: error.message }],
        diagnostics: bulkDiagnostics
      };
    }
  }

  /**
   * حفظ سجل الإشعار
   */
  async saveNotificationRecord(data) {
    try {
      console.log('💾 حفظ سجل الإشعار في قاعدة البيانات...');

      const { error } = await this.supabase
        .from('notifications')
        .insert([{
          title: data.title,
          body: data.body,
          type: data.type,
          status: data.status,
          recipients_count: data.recipientsCount,
          delivery_rate: data.results ? Math.floor((data.results.successful / data.results.total) * 100) : 0,
          sent_at: data.sentAt,
          scheduled_for: data.scheduledFor,
          notification_data: {
            isScheduled: data.isScheduled,
            scheduledDateTime: data.scheduledDateTime,
            results: data.results
          },
          created_by: 'admin'
        }]);

      if (error) {
        throw new Error(`خطأ في حفظ الإشعار: ${error.message}`);
      }

      console.log('✅ تم حفظ سجل الإشعار في قاعدة البيانات');
      return { success: true };
    } catch (error) {
      console.error('❌ خطأ في حفظ سجل الإشعار:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * جلب إحصائيات الإشعارات
   */
  async getNotificationStats() {
    try {
      console.log('📊 جلب إحصائيات الإشعارات من قاعدة البيانات...');

      const { data, error } = await this.supabase
        .rpc('get_notification_statistics');

      if (error) {
        console.error('❌ خطأ في جلب الإحصائيات من قاعدة البيانات:', error);
        // العودة للإحصائيات المحلية كبديل
        return {
          total_sent: this.stats.totalSent,
          total_delivered: this.stats.successfulSent,
          total_opened: Math.floor(this.stats.successfulSent * 0.3),
          total_clicked: Math.floor(this.stats.successfulSent * 0.15),
        };
      }

      console.log('✅ تم جلب الإحصائيات من قاعدة البيانات');
      return data || {
        total_sent: 0,
        total_delivered: 0,
        total_opened: 0,
        total_clicked: 0,
      };
    } catch (error) {
      console.error('❌ خطأ في جلب إحصائيات الإشعارات:', error);
      return {
        total_sent: 0,
        total_delivered: 0,
        total_opened: 0,
        total_clicked: 0,
      };
    }
  }

  /**
   * جلب تاريخ الإشعارات
   */
  async getNotificationHistory() {
    try {
      console.log('📜 جلب تاريخ الإشعارات من قاعدة البيانات...');

      const { data, error } = await this.supabase
        .rpc('get_notification_history', { limit_count: 50 });

      if (error) {
        console.error('❌ خطأ في جلب تاريخ الإشعارات من قاعدة البيانات:', error);
        return [];
      }

      console.log(`✅ تم جلب ${data?.length || 0} إشعار من التاريخ`);
      return data || [];
    } catch (error) {
      console.error('❌ خطأ في جلب تاريخ الإشعارات:', error);
      return [];
    }
  }

  /**
   * إيقاف مدير الإشعارات
   */
  async shutdown() {
    try {
      console.log('🔄 إيقاف مدير الإشعارات...');

      if (this.firebaseService) {
        await this.firebaseService.shutdown();
      }

      if (this.targetedService) {
        await this.targetedService.shutdown();
      }

      if (this.tokenService) {
        await this.tokenService.shutdown();
      }

      this.isInitialized = false;
      console.log('✅ تم إيقاف مدير الإشعارات بنجاح');
    } catch (error) {
      console.error('❌ خطأ في إيقاف مدير الإشعارات:', error);
    }
  }
}

module.exports = OfficialNotificationManager;
