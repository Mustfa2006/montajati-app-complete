// ===================================
// الخدمة الرئيسية لإدارة جميع أنواع الإشعارات المستهدفة
// Master Notification Service for All Targeted Notifications
// ===================================

const orderStatusWatcher = require('./order_status_watcher');
const withdrawalStatusWatcher = require('./withdrawal_status_watcher');
const targetedNotificationService = require('./targeted_notification_service');

class NotificationMasterService {
  constructor() {
    this.isRunning = false;
    this.services = {
      orderWatcher: orderStatusWatcher,
      withdrawalWatcher: withdrawalStatusWatcher,
      notificationService: targetedNotificationService
    };
  }

  /**
   * بدء جميع خدمات الإشعارات
   */
  async startAllServices() {
    try {
      if (this.isRunning) {
        console.log('⚠️ خدمات الإشعارات تعمل بالفعل');
        return { success: true, message: 'الخدمات تعمل بالفعل' };
      }

      console.log('🚀 بدء تشغيل جميع خدمات الإشعارات المستهدفة...');

      // بدء مراقب حالة الطلبات
      console.log('📦 تشغيل مراقب حالة الطلبات...');
      this.services.orderWatcher.startWatching();

      // بدء مراقب حالة طلبات السحب
      console.log('💰 تشغيل مراقب حالة طلبات السحب...');
      this.services.withdrawalWatcher.startWatching();

      this.isRunning = true;

      console.log('✅ تم تشغيل جميع خدمات الإشعارات المستهدفة بنجاح');
      console.log('🎯 الإشعارات ستصل للمستخدمين المحددين فقط');
      
      return {
        success: true,
        message: 'تم تشغيل جميع خدمات الإشعارات بنجاح',
        services: this.getServicesStatus()
      };

    } catch (error) {
      console.error('❌ خطأ في تشغيل خدمات الإشعارات:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * إيقاف جميع خدمات الإشعارات
   */
  async stopAllServices() {
    try {
      if (!this.isRunning) {
        console.log('⚠️ خدمات الإشعارات متوقفة بالفعل');
        return { success: true, message: 'الخدمات متوقفة بالفعل' };
      }

      console.log('🛑 إيقاف جميع خدمات الإشعارات...');

      // إيقاف مراقب حالة الطلبات
      console.log('📦 إيقاف مراقب حالة الطلبات...');
      this.services.orderWatcher.stopWatching();

      // إيقاف مراقب حالة طلبات السحب
      console.log('💰 إيقاف مراقب حالة طلبات السحب...');
      this.services.withdrawalWatcher.stopWatching();

      this.isRunning = false;

      console.log('✅ تم إيقاف جميع خدمات الإشعارات');
      
      return {
        success: true,
        message: 'تم إيقاف جميع خدمات الإشعارات',
        services: this.getServicesStatus()
      };

    } catch (error) {
      console.error('❌ خطأ في إيقاف خدمات الإشعارات:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * إعادة تشغيل جميع خدمات الإشعارات
   */
  async restartAllServices() {
    try {
      console.log('🔄 إعادة تشغيل جميع خدمات الإشعارات...');

      // إيقاف الخدمات أولاً
      await this.stopAllServices();

      // انتظار ثانية واحدة
      await new Promise(resolve => setTimeout(resolve, 1000));

      // تشغيل الخدمات مرة أخرى
      const result = await this.startAllServices();

      console.log('✅ تم إعادة تشغيل جميع خدمات الإشعارات');
      return result;

    } catch (error) {
      console.error('❌ خطأ في إعادة تشغيل خدمات الإشعارات:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * الحصول على حالة جميع الخدمات
   */
  getServicesStatus() {
    return {
      masterService: {
        isRunning: this.isRunning,
        startedAt: this.isRunning ? new Date().toISOString() : null
      },
      orderWatcher: this.services.orderWatcher.getWatcherStats(),
      withdrawalWatcher: this.services.withdrawalWatcher.getWatcherStats()
    };
  }

  /**
   * إرسال إشعار حالة طلب يدوياً (للاستخدام من API)
   */
  async sendOrderStatusNotification(orderId, userId, customerName, oldStatus, newStatus) {
    try {
      console.log('🔧 إرسال إشعار حالة طلب يدوياً...');
      
      const result = await targetedNotificationService.sendOrderStatusNotification(
        orderId,
        userId,
        customerName,
        oldStatus,
        newStatus
      );

      return result;

    } catch (error) {
      console.error('❌ خطأ في إرسال إشعار حالة الطلب يدوياً:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * إرسال إشعار حالة طلب سحب يدوياً (للاستخدام من API)
   */
  async sendWithdrawalStatusNotification(userId, requestId, amount, status, reason = '') {
    try {
      console.log('🔧 إرسال إشعار حالة طلب سحب يدوياً...');
      
      const result = await targetedNotificationService.sendWithdrawalStatusNotification(
        userId,
        requestId,
        amount,
        status,
        reason
      );

      return result;

    } catch (error) {
      console.error('❌ خطأ في إرسال إشعار حالة طلب السحب يدوياً:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * معالجة تحديث حالة طلب سحب من Admin Panel
   */
  async handleAdminWithdrawalStatusUpdate(requestId, newStatus, adminNotes = '') {
    try {
      console.log('🔧 معالجة تحديث حالة طلب سحب من Admin Panel...');
      
      const result = await this.services.withdrawalWatcher.handleManualWithdrawalStatusUpdate(
        requestId,
        newStatus,
        adminNotes
      );

      return result;

    } catch (error) {
      console.error('❌ خطأ في معالجة تحديث حالة طلب السحب من Admin Panel:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * اختبار إرسال إشعار تجريبي
   */
  async sendTestNotification(userId, type = 'order') {
    try {
      console.log(`🧪 إرسال إشعار تجريبي للمستخدم ${userId}...`);

      let result;

      if (type === 'order') {
        result = await this.sendOrderStatusNotification(
          'test-order-123',
          userId,
          'عميل تجريبي',
          'pending',
          'delivered'
        );
      } else if (type === 'withdrawal') {
        result = await this.sendWithdrawalStatusNotification(
          userId,
          'test-withdrawal-123',
          50000,
          'approved'
        );
      } else {
        return {
          success: false,
          error: 'نوع إشعار غير مدعوم'
        };
      }

      return result;

    } catch (error) {
      console.error('❌ خطأ في إرسال الإشعار التجريبي:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * الحصول على إحصائيات شاملة
   */
  async getComprehensiveStats() {
    try {
      const stats = {
        timestamp: new Date().toISOString(),
        services: this.getServicesStatus(),
        summary: {
          totalServices: Object.keys(this.services).length,
          activeServices: this.isRunning ? 2 : 0, // orderWatcher + withdrawalWatcher
          status: this.isRunning ? 'running' : 'stopped'
        }
      };

      return {
        success: true,
        data: stats
      };

    } catch (error) {
      console.error('❌ خطأ في جلب الإحصائيات:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }
}

module.exports = new NotificationMasterService();
