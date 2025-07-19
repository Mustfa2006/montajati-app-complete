// ===================================
// تنظيف الإشعارات المعلقة
// Cleanup Stuck Notifications
// ===================================

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

class NotificationCleanup {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
  }

  async cleanupStuckNotifications() {
    try {
      console.log('🧹 بدء تنظيف الإشعارات المعلقة...');

      // 1. حذف الإشعارات القديمة (أكثر من 7 أيام)
      const sevenDaysAgo = new Date(Date.now() - (7 * 24 * 60 * 60 * 1000)).toISOString();
      
      const { data: oldNotifications, error: deleteOldError } = await this.supabase
        .from('notification_queue')
        .delete()
        .lt('created_at', sevenDaysAgo);

      if (deleteOldError) {
        console.error('❌ خطأ في حذف الإشعارات القديمة:', deleteOldError);
      } else {
        console.log(`✅ تم حذف الإشعارات القديمة (أكثر من 7 أيام)`);
      }

      // 2. تحديث الإشعارات المعلقة لأكثر من ساعة إلى فاشلة
      const oneHourAgo = new Date(Date.now() - (60 * 60 * 1000)).toISOString();

      const { data: stuckNotifications, error: updateStuckError } = await this.supabase
        .from('notification_queue')
        .update({
          status: 'failed',
          error_message: 'تم إلغاء الإشعار بسبب التعليق لفترة طويلة',
          processed_at: new Date().toISOString()
        })
        .eq('status', 'pending')
        .lt('created_at', oneHourAgo);

      if (updateStuckError) {
        console.error('❌ خطأ في تحديث الإشعارات المعلقة:', updateStuckError);
      } else {
        console.log(`✅ تم تحديث الإشعارات المعلقة لأكثر من ساعة`);
      }

      // 3. إعادة تعيين الإشعارات التي تجاوزت الحد الأقصى للمحاولات
      const { data: maxRetriedNotifications, error: updateMaxRetriedError } = await this.supabase
        .from('notification_queue')
        .update({
          status: 'failed',
          error_message: 'تجاوز الحد الأقصى للمحاولات',
          processed_at: new Date().toISOString()
        })
        .eq('status', 'pending')
        .gte('retry_count', 3);

      if (updateMaxRetriedError) {
        console.error('❌ خطأ في تحديث الإشعارات التي تجاوزت الحد الأقصى:', updateMaxRetriedError);
      } else {
        console.log(`✅ تم تحديث الإشعارات التي تجاوزت الحد الأقصى للمحاولات`);
      }

      // 4. إحصائيات التنظيف
      const { data: stats, error: statsError } = await this.supabase
        .from('notification_queue')
        .select('status')
        .then(result => {
          if (result.error) throw result.error;
          
          const statusCounts = result.data.reduce((acc, notification) => {
            acc[notification.status] = (acc[notification.status] || 0) + 1;
            return acc;
          }, {});
          
          return { data: statusCounts, error: null };
        });

      if (statsError) {
        console.error('❌ خطأ في جمع الإحصائيات:', statsError);
      } else {
        console.log('📊 إحصائيات الإشعارات بعد التنظيف:');
        Object.entries(stats.data).forEach(([status, count]) => {
          console.log(`   - ${status}: ${count}`);
        });
      }

      console.log('✅ تم الانتهاء من تنظيف الإشعارات');

    } catch (error) {
      console.error('❌ خطأ في تنظيف الإشعارات:', error);
    }
  }

  async resetSpecificNotification(notificationId) {
    try {
      console.log(`🔄 إعادة تعيين الإشعار ${notificationId}...`);

      const { data, error } = await this.supabase
        .from('notification_queue')
        .update({
          status: 'failed',
          error_message: 'تم إعادة تعيين الإشعار يدوياً',
          processed_at: new Date().toISOString()
        })
        .eq('id', notificationId);

      if (error) {
        console.error('❌ خطأ في إعادة تعيين الإشعار:', error);
      } else {
        console.log(`✅ تم إعادة تعيين الإشعار ${notificationId}`);
      }

    } catch (error) {
      console.error('❌ خطأ في إعادة تعيين الإشعار:', error);
    }
  }
}

// تشغيل التنظيف
if (require.main === module) {
  const cleanup = new NotificationCleanup();
  
  // إذا تم تمرير معرف إشعار محدد
  const notificationId = process.argv[2];
  
  if (notificationId) {
    cleanup.resetSpecificNotification(notificationId).then(() => {
      console.log('✅ انتهى إعادة تعيين الإشعار');
      process.exit(0);
    });
  } else {
    cleanup.cleanupStuckNotifications().then(() => {
      console.log('✅ انتهى تنظيف الإشعارات');
      process.exit(0);
    });
  }
}

module.exports = NotificationCleanup;
