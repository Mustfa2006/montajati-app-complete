// ===================================
// مراقب تغيير حالة طلبات السحب مع إشعارات مستهدفة
// Withdrawal Status Watcher with Targeted Notifications
// ===================================

const { createClient } = require('@supabase/supabase-js');
const targetedNotificationService = require('./targeted_notification_service');

// إعداد Supabase
const supabaseUrl = process.env.SUPABASE_URL || 'https://your-project.supabase.co';
const supabaseKey = process.env.SUPABASE_ANON_KEY || 'your-anon-key';
const supabase = createClient(supabaseUrl, supabaseKey);

class WithdrawalStatusWatcher {
  constructor() {
    this.isWatching = false;
    this.watchInterval = null;
    this.checkIntervalMs = 30000; // فحص كل 30 ثانية
    this.lastCheckedTimestamp = new Date().toISOString();
    this.lastNoRequestsLog = 0; // لتقليل الرسائل المكررة

    console.log('💰 تم تهيئة مراقب حالة طلبات السحب');
  }

  /**
   * بدء مراقبة تغيير حالة طلبات السحب
   */
  startWatching() {
    if (this.isWatching) {
      console.log('⚠️ مراقب حالة طلبات السحب يعمل بالفعل');
      return;
    }

    console.log('💰 بدء مراقبة تغيير حالة طلبات السحب...');
    this.isWatching = true;
    this.lastCheckedTimestamp = new Date().toISOString();

    // فحص فوري
    this.checkWithdrawalStatusChanges();

    // فحص دوري
    this.watchInterval = setInterval(() => {
      this.checkWithdrawalStatusChanges();
    }, this.checkIntervalMs);

    console.log(`✅ مراقب حالة طلبات السحب نشط - فحص كل ${this.checkIntervalMs / 1000} ثانية`);
  }

  /**
   * إيقاف مراقبة تغيير حالة طلبات السحب
   */
  stopWatching() {
    if (!this.isWatching) {
      console.log('⚠️ مراقب حالة طلبات السحب متوقف بالفعل');
      return;
    }

    console.log('🛑 إيقاف مراقبة تغيير حالة طلبات السحب...');
    this.isWatching = false;

    if (this.watchInterval) {
      clearInterval(this.watchInterval);
      this.watchInterval = null;
    }

    console.log('✅ تم إيقاف مراقب حالة طلبات السحب');
  }

  /**
   * فحص تغييرات حالة طلبات السحب
   */
  async checkWithdrawalStatusChanges() {
    try {
      console.log('💰 فحص تغييرات حالة طلبات السحب...');

      // جلب طلبات السحب التي تم تحديثها منذ آخر فحص
      const { data: recentWithdrawals, error } = await supabase
        .from('withdrawal_requests')
        .select(`
          id,
          user_id,
          amount,
          status,
          admin_notes,
          updated_at,
          created_at
        `)
        .gte('updated_at', this.lastCheckedTimestamp)
        .order('updated_at', { ascending: false });

      if (error) {
        console.error('❌ خطأ في جلب طلبات السحب المحدثة:', error.message);
        return;
      }

      if (!recentWithdrawals || recentWithdrawals.length === 0) {
        // تقليل عدد الرسائل المكررة
        if (Date.now() - this.lastNoRequestsLog > 300000) { // كل 5 دقائق
          console.log('📝 لا توجد طلبات سحب محدثة مؤخراً');
          this.lastNoRequestsLog = Date.now();
        }
        this.updateLastCheckedTimestamp();
        return;
      }

      console.log(`💰 تم العثور على ${recentWithdrawals.length} طلب سحب محدث مؤخراً`);

      // فحص كل طلب سحب للتحقق من تغيير الحالة
      for (const withdrawal of recentWithdrawals) {
        await this.checkSingleWithdrawalStatusChange(withdrawal);
      }

      // تحديث وقت آخر فحص
      this.updateLastCheckedTimestamp();

    } catch (error) {
      console.error('❌ خطأ في فحص تغييرات حالة طلبات السحب:', error.message);
    }
  }

  /**
   * فحص تغيير حالة طلب سحب واحد
   */
  async checkSingleWithdrawalStatusChange(withdrawal) {
    try {
      // التحقق من أن الطلب تم تحديثه مؤخراً (ليس مجرد إنشاء)
      const createdTime = new Date(withdrawal.created_at);
      const updatedTime = new Date(withdrawal.updated_at);
      
      // إذا كان وقت الإنشاء والتحديث متطابقين، فهذا طلب جديد وليس تحديث
      if (Math.abs(updatedTime - createdTime) < 1000) {
        console.log(`📝 طلب سحب جديد: ${withdrawal.id} - الحالة: ${withdrawal.status}`);
        return;
      }

      console.log(`💰 فحص طلب السحب: ${withdrawal.id} - الحالة: ${withdrawal.status}`);

      // التحقق من أن الحالة تستحق إشعار
      const notifiableStatuses = ['approved', 'rejected'];
      if (!notifiableStatuses.includes(withdrawal.status)) {
        console.log(`📝 الحالة ${withdrawal.status} لا تستحق إشعار`);
        return;
      }

      // إرسال إشعار مستهدف للمستخدم صاحب طلب السحب فقط
      await this.sendTargetedWithdrawalStatusNotification(
        withdrawal.id,
        withdrawal.user_id,
        withdrawal.amount,
        withdrawal.status,
        withdrawal.admin_notes || ''
      );

    } catch (error) {
      console.error(`❌ خطأ في فحص حالة طلب السحب ${withdrawal.id}:`, error.message);
    }
  }

  /**
   * إرسال إشعار مستهدف لتغيير حالة طلب السحب
   */
  async sendTargetedWithdrawalStatusNotification(requestId, userId, amount, status, reason = '') {
    try {
      console.log(`🎯 إرسال إشعار مستهدف لتغيير حالة طلب السحب:`);
      console.log(`📄 طلب السحب: ${requestId}`);
      console.log(`👤 المستخدم: ${userId}`);
      console.log(`💵 المبلغ: ${amount}`);
      console.log(`📊 الحالة: ${status}`);

      // التأكد من وجود معرف المستخدم
      if (!userId) {
        console.log('⚠️ لا يوجد معرف مستخدم لطلب السحب، لا يمكن إرسال إشعار');
        return;
      }

      // الحصول على رقم هاتف المستخدم من قاعدة البيانات
      const { data: userData, error: userError } = await this.supabase
        .from('users')
        .select('phone')
        .eq('id', userId)
        .single();

      if (userError || !userData || !userData.phone) {
        console.log(`⚠️ لا يمكن العثور على رقم هاتف للمستخدم ${userId}`);
        return;
      }

      const userPhone = userData.phone;
      console.log(`📱 رقم هاتف المستخدم: ${userPhone}`);

      // التحقق من تهيئة خدمة الإشعارات
      if (!targetedNotificationService || !targetedNotificationService.initialized) {
        console.warn('⚠️ خدمة الإشعارات المستهدفة غير مهيأة - تم تخطي الإشعار');
        return;
      }

      // إرسال الإشعار المستهدف باستخدام رقم الهاتف
      const result = await targetedNotificationService.sendWithdrawalStatusNotification(
        userPhone, // استخدام رقم الهاتف بدلاً من userId
        requestId,
        amount,
        status,
        reason
      );

      if (result.success) {
        console.log(`✅ تم إرسال إشعار طلب السحب للمستخدم ${userId} بنجاح`);

        // تسجيل نجاح الإرسال
        await this.logNotificationSuccess(requestId, userId, status, amount);
      } else {
        console.log(`❌ فشل إرسال إشعار طلب السحب للمستخدم ${userId}: ${result.error}`);

        // تسجيل فشل الإرسال
        await this.logNotificationFailure(requestId, userId, status, amount, result.error);
      }

    } catch (error) {
      console.error('❌ خطأ في إرسال إشعار مستهدف لطلب السحب:', error.message);
    }
  }

  /**
   * تحديث وقت آخر فحص
   */
  updateLastCheckedTimestamp() {
    this.lastCheckedTimestamp = new Date().toISOString();
  }

  /**
   * تسجيل نجاح إرسال الإشعار
   */
  async logNotificationSuccess(requestId, userId, status, amount) {
    try {
      await supabase
        .from('system_logs')
        .insert({
          event_type: 'withdrawal_notification_sent',
          event_data: {
            request_id: requestId,
            user_id: userId,
            status: status,
            amount: amount,
            success: true
          },
          service: 'withdrawal_status_watcher'
        });
    } catch (error) {
      console.error('❌ خطأ في تسجيل نجاح إشعار السحب:', error.message);
    }
  }

  /**
   * تسجيل فشل إرسال الإشعار
   */
  async logNotificationFailure(requestId, userId, status, amount, errorMessage) {
    try {
      await supabase
        .from('system_logs')
        .insert({
          event_type: 'withdrawal_notification_failed',
          event_data: {
            request_id: requestId,
            user_id: userId,
            status: status,
            amount: amount,
            success: false,
            error: errorMessage
          },
          service: 'withdrawal_status_watcher'
        });
    } catch (error) {
      console.error('❌ خطأ في تسجيل فشل إشعار السحب:', error.message);
    }
  }

  /**
   * معالجة تحديث حالة طلب السحب يدوياً (للاستخدام من Admin Panel)
   */
  async handleManualWithdrawalStatusUpdate(requestId, newStatus, adminNotes = '') {
    try {
      console.log(`🔧 معالجة تحديث يدوي لطلب السحب: ${requestId} → ${newStatus}`);

      // جلب بيانات طلب السحب
      const { data: withdrawal, error } = await supabase
        .from('withdrawal_requests')
        .select('id, user_id, amount, status')
        .eq('id', requestId)
        .single();

      if (error || !withdrawal) {
        console.error('❌ خطأ في جلب بيانات طلب السحب:', error?.message);
        return { success: false, error: 'طلب السحب غير موجود' };
      }

      // إرسال إشعار فوري
      const notificationResult = await this.sendTargetedWithdrawalStatusNotification(
        withdrawal.id,
        withdrawal.user_id,
        withdrawal.amount,
        newStatus,
        adminNotes
      );

      return notificationResult;

    } catch (error) {
      console.error('❌ خطأ في معالجة التحديث اليدوي لطلب السحب:', error.message);
      return { success: false, error: error.message };
    }
  }

  /**
   * الحصول على إحصائيات المراقبة
   */
  getWatcherStats() {
    return {
      isWatching: this.isWatching,
      checkInterval: this.checkIntervalMs,
      lastChecked: this.lastCheckedTimestamp,
      nextCheck: this.watchInterval ? new Date(Date.now() + this.checkIntervalMs) : null
    };
  }
}

module.exports = WithdrawalStatusWatcher;
