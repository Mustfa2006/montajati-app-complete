// ===================================
// مدير الإشعارات الرسمي المتكامل
// Official Notification Manager
// ===================================

const EventEmitter = require('events');
const { firebaseAdminService } = require('./firebase_admin_service');
const targetedNotificationService = require('./targeted_notification_service');
const tokenManagementService = require('./token_management_service');

class OfficialNotificationManager extends EventEmitter {
  constructor() {
    super(); // استدعاء EventEmitter constructor
    this.isInitialized = false;
    this.firebaseService = null;
    this.targetedService = null;
    this.tokenService = null;
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
   * إرسال إشعار عام
   */
  async sendGeneralNotification(data) {
    try {
      if (!this.isInitialized) {
        throw new Error('مدير الإشعارات غير مهيأ');
      }

      const { userPhone, title, message, additionalData } = data;

      console.log(`📢 إرسال إشعار عام للعميل: ${userPhone}`);

      // إرسال الإشعار
      const result = await this.targetedService.sendGeneralNotification(
        userPhone,
        title,
        message,
        additionalData
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
      console.error('❌ خطأ في إرسال الإشعار العام:', error);
      this.stats.totalSent++;
      this.stats.failedSent++;

      // إرسال حدث خطأ
      this.emit('error', error);

      return { success: false, error: error.message };
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
