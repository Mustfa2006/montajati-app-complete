// ===================================
// الخدمة الرئيسية لإدارة جميع أنواع الإشعارات المستهدفة
// Master Notification Service for All Targeted Notifications
// ===================================

const SimpleNotificationProcessor = require('../notification_processor_simple');

class NotificationMasterService {
  constructor() {
    this.isRunning = false;
    this.processor = new SimpleNotificationProcessor();
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

      console.log('🚀 بدء تشغيل جميع خدمات الإشعارات...');

      // بدء معالج الإشعارات البسيط
      console.log('📱 تشغيل معالج الإشعارات...');
      this.processor.startProcessing();

      this.isRunning = true;

      console.log('✅ تم تشغيل جميع خدمات الإشعارات بنجاح');
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
      console.log('🛑 إيقاف جميع خدمات الإشعارات...');

      // إيقاف معالج الإشعارات
      this.processor.stopProcessing();

      this.isRunning = false;

      console.log('✅ تم إيقاف جميع خدمات الإشعارات');
      
      return {
        success: true,
        message: 'تم إيقاف جميع خدمات الإشعارات'
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
   * الحصول على حالة الخدمات
   */
  getServicesStatus() {
    return {
      notificationProcessor: {
        name: 'معالج الإشعارات',
        status: this.processor.isProcessing ? 'running' : 'stopped',
        isRunning: this.processor.isProcessing
      },
      masterService: {
        name: 'الخدمة الرئيسية',
        status: this.isRunning ? 'running' : 'stopped',
        isRunning: this.isRunning
      }
    };
  }

  /**
   * اختبار إرسال إشعار
   */
  async testNotification(userPhone, message = 'اختبار نظام الإشعارات') {
    try {
      console.log(`🧪 اختبار إرسال إشعار للمستخدم: ${userPhone}`);
      
      // إنشاء إشعار تجريبي في قائمة الانتظار
      const { createClient } = require('@supabase/supabase-js');
      const supabase = createClient(
        process.env.SUPABASE_URL,
        process.env.SUPABASE_SERVICE_ROLE_KEY
      );

      const { error } = await supabase
        .from('notification_queue')
        .insert({
          order_id: `TEST-${Date.now()}`,
          user_phone: userPhone,
          customer_name: 'اختبار النظام',
          old_status: 'test',
          new_status: 'test_notification',
          notification_data: {
            title: 'اختبار الإشعارات 🧪',
            message: message,
            type: 'test',
            priority: 1,
            timestamp: Date.now()
          },
          priority: 1
        });

      if (error) {
        console.error('❌ خطأ في إنشاء إشعار الاختبار:', error.message);
        return { success: false, error: error.message };
      }

      console.log('✅ تم إنشاء إشعار الاختبار بنجاح');
      return { success: true, message: 'تم إنشاء إشعار الاختبار' };

    } catch (error) {
      console.error('❌ خطأ في اختبار الإشعار:', error.message);
      return { success: false, error: error.message };
    }
  }
}

module.exports = new NotificationMasterService();
