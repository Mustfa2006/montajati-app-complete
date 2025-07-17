// ===================================
// مراقب تغيير حالة الطلبات مع إشعارات مستهدفة
// Order Status Watcher with Targeted Notifications
// ===================================

const { createClient } = require('@supabase/supabase-js');
const targetedNotificationService = require('./targeted_notification_service');

// إعداد Supabase
const supabaseUrl = process.env.SUPABASE_URL || 'https://your-project.supabase.co';
const supabaseKey = process.env.SUPABASE_ANON_KEY || 'your-anon-key';
const supabase = createClient(supabaseUrl, supabaseKey);

class OrderStatusWatcher {
  constructor() {
    this.isWatching = false;
    this.watchInterval = null;
    // تقليل التكرار في الإنتاج لتوفير موارد Render
    this.checkIntervalMs = process.env.NODE_ENV === 'production' ? 300000 : 30000; // 5 دقائق في الإنتاج، 30 ثانية في التطوير
    this.lastNoOrdersLog = 0; // لتقليل الرسائل المكررة

    console.log('👁️ تم تهيئة مراقب حالة الطلبات');
  }

  /**
   * بدء مراقبة تغيير حالة الطلبات
   */
  startWatching() {
    if (this.isWatching) {
      console.log('⚠️ مراقب حالة الطلبات يعمل بالفعل');
      return;
    }

    console.log('🚀 بدء مراقبة تغيير حالة الطلبات...');
    this.isWatching = true;

    // فحص فوري
    this.checkOrderStatusChanges();

    // فحص دوري
    this.watchInterval = setInterval(() => {
      this.checkOrderStatusChanges();
    }, this.checkIntervalMs);

    console.log(`✅ مراقب حالة الطلبات نشط - فحص كل ${this.checkIntervalMs / 1000} ثانية`);
  }

  /**
   * إيقاف مراقبة تغيير حالة الطلبات
   */
  stopWatching() {
    if (!this.isWatching) {
      console.log('⚠️ مراقب حالة الطلبات متوقف بالفعل');
      return;
    }

    console.log('🛑 إيقاف مراقبة تغيير حالة الطلبات...');
    this.isWatching = false;

    if (this.watchInterval) {
      clearInterval(this.watchInterval);
      this.watchInterval = null;
    }

    console.log('✅ تم إيقاف مراقب حالة الطلبات');
  }

  /**
   * فحص تغييرات حالة الطلبات
   */
  async checkOrderStatusChanges() {
    try {
      console.log('🔍 فحص تغييرات حالة الطلبات...');

      // جلب الطلبات التي تم تحديثها مؤخراً (آخر دقيقة)
      const oneMinuteAgo = new Date(Date.now() - 60000).toISOString();
      
      const { data: recentOrders, error } = await supabase
        .from('orders')
        .select(`
          id,
          customer_id,
          customer_name,
          status,
          updated_at,
          created_at
        `)
        .gte('updated_at', oneMinuteAgo)
        .order('updated_at', { ascending: false });

      if (error) {
        // تحقق من نوع الخطأ
        if (error.message.includes('relation') || error.message.includes('does not exist')) {
          console.warn('⚠️ جدول الطلبات غير موجود - سيتم إنشاؤه تلقائياً');
          await this.createOrdersTableIfNotExists();
          return;
        }
        console.error('❌ خطأ في جلب الطلبات المحدثة:', error.message);
        return;
      }

      if (!recentOrders || recentOrders.length === 0) {
        // تقليل عدد الرسائل المكررة
        if (Date.now() - this.lastNoOrdersLog > 300000) { // كل 5 دقائق
          console.log('📝 لا توجد طلبات محدثة مؤخراً');
          this.lastNoOrdersLog = Date.now();
        }
        return;
      }

      console.log(`📦 تم العثور على ${recentOrders.length} طلب محدث مؤخراً`);

      // فحص كل طلب للتحقق من تغيير الحالة
      for (const order of recentOrders) {
        await this.checkSingleOrderStatusChange(order);
      }

    } catch (error) {
      console.error('❌ خطأ في فحص تغييرات حالة الطلبات:', error.message);
    }
  }

  /**
   * إنشاء جدول الطلبات إذا لم يكن موجوداً
   */
  async createOrdersTableIfNotExists() {
    try {
      console.log('🔧 محاولة إنشاء جدول الطلبات...');

      // هذا مجرد تحذير - يجب إنشاء الجداول يدوياً في الإنتاج
      console.warn('⚠️ يجب إنشاء جدول الطلبات يدوياً في قاعدة البيانات');
      console.warn('⚠️ راجع ملف database/official_schema_complete.sql');

    } catch (error) {
      console.error('❌ خطأ في إنشاء جدول الطلبات:', error.message);
    }
  }

  /**
   * فحص تغيير حالة طلب واحد
   */
  async checkSingleOrderStatusChange(order) {
    try {
      // جلب آخر سجل حالة من تاريخ الحالات
      const { data: lastStatusHistory, error } = await supabase
        .from('order_status_history')
        .select('old_status, new_status, created_at')
        .eq('order_id', order.id)
        .order('created_at', { ascending: false })
        .limit(1);

      if (error) {
        console.error(`❌ خطأ في جلب تاريخ حالة الطلب ${order.id}:`, error.message);
        return;
      }

      // إذا لم يكن هناك تاريخ حالة، فهذا طلب جديد
      if (!lastStatusHistory || lastStatusHistory.length === 0) {
        console.log(`📝 طلب جديد: ${order.id} - الحالة: ${order.status}`);
        return;
      }

      const lastHistory = lastStatusHistory[0];
      
      // التحقق من أن التغيير حدث مؤخراً (آخر دقيقة)
      const historyTime = new Date(lastHistory.created_at);
      const oneMinuteAgo = new Date(Date.now() - 60000);
      
      if (historyTime < oneMinuteAgo) {
        // التغيير قديم، لا نرسل إشعار
        return;
      }

      // التحقق من أن الحالة تغيرت فعلاً
      if (lastHistory.old_status === lastHistory.new_status) {
        console.log(`📝 لا يوجد تغيير في حالة الطلب ${order.id}`);
        return;
      }

      console.log(`🔄 تغيرت حالة الطلب ${order.id}: ${lastHistory.old_status} → ${lastHistory.new_status}`);

      // التحقق من أن الحالة الجديدة تستحق إشعار
      const notifiableStatuses = ['in_delivery', 'delivered', 'cancelled'];
      if (!notifiableStatuses.includes(lastHistory.new_status)) {
        console.log(`📝 الحالة ${lastHistory.new_status} لا تستحق إشعار`);
        return;
      }

      // إرسال إشعار مستهدف للمستخدم صاحب الطلب فقط
      await this.sendTargetedOrderStatusNotification(
        order.id,
        order.customer_id,
        order.customer_name,
        lastHistory.old_status,
        lastHistory.new_status
      );

    } catch (error) {
      console.error(`❌ خطأ في فحص حالة الطلب ${order.id}:`, error.message);
    }
  }

  /**
   * إرسال إشعار مستهدف لتغيير حالة الطلب
   */
  async sendTargetedOrderStatusNotification(orderId, customerId, customerName, oldStatus, newStatus) {
    try {
      console.log(`🎯 إرسال إشعار مستهدف لتغيير حالة الطلب:`);
      console.log(`📦 الطلب: ${orderId}`);
      console.log(`👤 المستخدم: ${customerId}`);
      console.log(`👥 العميل: ${customerName}`);
      console.log(`🔄 التغيير: ${oldStatus} → ${newStatus}`);

      // التأكد من وجود معرف المستخدم
      if (!customerId) {
        console.log('⚠️ لا يوجد معرف مستخدم للطلب، لا يمكن إرسال إشعار');
        return;
      }

      // التحقق من تهيئة خدمة الإشعارات
      if (!targetedNotificationService || !targetedNotificationService.initialized) {
        console.warn('⚠️ خدمة الإشعارات المستهدفة غير مهيأة - تم تخطي الإشعار');
        return;
      }

      // إرسال الإشعار المستهدف
      const result = await targetedNotificationService.sendOrderStatusNotification(
        orderId,
        customerId,
        customerName,
        oldStatus,
        newStatus
      );

      if (result.success) {
        console.log(`✅ تم إرسال إشعار حالة الطلب للمستخدم ${customerId} بنجاح`);

        // تسجيل نجاح الإرسال
        await this.logNotificationSuccess(orderId, customerId, newStatus);
      } else {
        console.log(`❌ فشل إرسال إشعار حالة الطلب للمستخدم ${customerId}: ${result.error}`);

        // تسجيل فشل الإرسال
        await this.logNotificationFailure(orderId, customerId, newStatus, result.error);
      }

    } catch (error) {
      console.error('❌ خطأ في إرسال إشعار مستهدف لحالة الطلب:', error.message);
    }
  }

  /**
   * تسجيل نجاح إرسال الإشعار
   */
  async logNotificationSuccess(orderId, userId, status) {
    try {
      await supabase
        .from('system_logs')
        .insert({
          event_type: 'order_notification_sent',
          event_data: {
            order_id: orderId,
            user_id: userId,
            status: status,
            success: true
          },
          service: 'order_status_watcher'
        });
    } catch (error) {
      console.error('❌ خطأ في تسجيل نجاح الإشعار:', error.message);
    }
  }

  /**
   * تسجيل فشل إرسال الإشعار
   */
  async logNotificationFailure(orderId, userId, status, errorMessage) {
    try {
      await supabase
        .from('system_logs')
        .insert({
          event_type: 'order_notification_failed',
          event_data: {
            order_id: orderId,
            user_id: userId,
            status: status,
            success: false,
            error: errorMessage
          },
          service: 'order_status_watcher'
        });
    } catch (error) {
      console.error('❌ خطأ في تسجيل فشل الإشعار:', error.message);
    }
  }

  /**
   * الحصول على إحصائيات المراقبة
   */
  getWatcherStats() {
    return {
      isWatching: this.isWatching,
      checkInterval: this.checkIntervalMs,
      nextCheck: this.watchInterval ? new Date(Date.now() + this.checkIntervalMs) : null
    };
  }
}

module.exports = OrderStatusWatcher;
