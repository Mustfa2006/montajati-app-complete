const OfficialWaseetAPI = require('./official_waseet_api');
const { createClient } = require('@supabase/supabase-js');
const targetedNotificationService = require('./targeted_notification_service');

/**
 * نظام المزامنة المدمج مع الخادم - للإنتاج على Render
 * Integrated Waseet Sync for Production Server
 */
class IntegratedWaseetSync {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
    
    this.waseetAPI = new OfficialWaseetAPI(
      process.env.WASEET_USERNAME || 'mustfaabd',
      process.env.WASEET_PASSWORD || '65888304'
    );
    
    // إعدادات المزامنة
    this.isRunning = false;
    this.syncInterval = 60 * 1000; // كل دقيقة
    this.syncIntervalId = null;
    this.lastSyncTime = null;
    this.isCurrentlySyncing = false;
    
    // إحصائيات
    this.stats = {
      totalSyncs: 0,
      successfulSyncs: 0,
      failedSyncs: 0,
      ordersUpdated: 0,
      startTime: Date.now(),
      lastError: null
    };
  }

  /**
   * بدء النظام تلقائياً مع الخادم
   */
  async autoStart() {
    try {
      console.log('🚀 بدء نظام المزامنة التلقائي مع الخادم...');
      
      // انتظار 10 ثواني لضمان استقرار الخادم
      setTimeout(async () => {
        await this.start();
      }, 10000);
      
    } catch (error) {
      console.error('❌ فشل البدء التلقائي:', error.message);
    }
  }

  /**
   * بدء النظام
   */
  async start() {
    try {
      if (this.isRunning) {
        return { success: true, message: 'النظام يعمل بالفعل' };
      }

      // اختبار الاتصال
      const testResult = await this.testConnection();
      if (!testResult.success) {
        console.error('❌ فشل اختبار الاتصال:', testResult.error);
        // إعادة المحاولة بعد دقيقة
        setTimeout(() => this.start(), 60000);
        return { success: false, error: testResult.error };
      }

      this.isRunning = true;
      this.stats.startTime = Date.now();
      
      // مزامنة فورية
      await this.performSync();
      
      // بدء المزامنة المستمرة
      this.syncIntervalId = setInterval(async () => {
        if (!this.isCurrentlySyncing) {
          await this.performSync();
        }
      }, this.syncInterval);
      
      console.log(`✅ نظام المزامنة يعمل - كل ${this.syncInterval / 1000} ثانية`);
      
      return { success: true, message: 'تم بدء النظام بنجاح' };
      
    } catch (error) {
      console.error('❌ فشل بدء النظام:', error.message);
      this.stats.lastError = error.message;
      
      // إعادة المحاولة بعد دقيقة
      setTimeout(() => this.start(), 60000);
      
      return { success: false, error: error.message };
    }
  }

  /**
   * إيقاف النظام
   */
  stop() {
    if (this.syncIntervalId) {
      clearInterval(this.syncIntervalId);
      this.syncIntervalId = null;
    }
    this.isRunning = false;
    console.log('⏹️ تم إيقاف نظام المزامنة');
    return { success: true };
  }

  /**
   * اختبار الاتصال
   */
  async testConnection() {
    try {
      // اختبار الوسيط
      const token = await this.waseetAPI.authenticate();
      if (!token) {
        throw new Error('فشل تسجيل الدخول للوسيط');
      }

      // اختبار قاعدة البيانات
      const { error } = await this.supabase
        .from('orders')
        .select('id')
        .limit(1);
        
      if (error) {
        throw new Error(`فشل الاتصال بقاعدة البيانات: ${error.message}`);
      }

      return { success: true };
      
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * تنفيذ المزامنة
   */
  async performSync() {
    if (this.isCurrentlySyncing) {
      return;
    }

    this.isCurrentlySyncing = true;
    this.stats.totalSyncs++;
    
    try {
      // جلب الطلبات من الوسيط
      const waseetResult = await this.waseetAPI.getAllMerchantOrders();
      
      if (!waseetResult.success) {
        throw new Error(waseetResult.error);
      }

      // جلب الطلبات من قاعدة البيانات مع بيانات الإشعارات (استبعاد الحالات النهائية)
      const { data: dbOrders, error } = await this.supabase
        .from('orders')
        .select('id, waseet_order_id, waseet_status_id, waseet_status_text, user_phone, primary_phone, customer_name, status')
        .not('waseet_order_id', 'is', null)
        // ✅ استبعاد الحالات النهائية - استخدام فلتر منفصل لتجنب مشكلة النص العربي
        .neq('status', 'تم التسليم للزبون')
        .neq('status', 'الغاء الطلب')
        .neq('status', 'رفض الطلب')
        .neq('status', 'delivered')
        .neq('status', 'cancelled');

      if (error) {
        throw new Error(`خطأ في جلب الطلبات: ${error.message}`);
      }

      // مزامنة الطلبات
      let updatedCount = 0;
      
      for (const waseetOrder of waseetResult.orders) {
        const dbOrder = dbOrders?.find(order => 
          order.waseet_order_id === waseetOrder.id
        );

        if (!dbOrder) continue;

        const waseetStatusId = parseInt(waseetOrder.status_id);
        const waseetStatusText = waseetOrder.status;

        // التحقق من وجود تغيير
        if (dbOrder.waseet_status_id === waseetStatusId &&
            dbOrder.waseet_status_text === waseetStatusText) {
          continue;
        }

        // تحويل حالة الوسيط إلى حالة التطبيق
        let appStatus = this.mapWaseetStatusToApp(waseetStatusId, waseetStatusText);

        // تحديث الطلب
        const { error: updateError } = await this.supabase
          .from('orders')
          .update({
            status: appStatus,
            waseet_status_id: waseetStatusId,
            waseet_status_text: waseetStatusText,
            last_status_check: new Date().toISOString(),
            status_updated_at: new Date().toISOString()
          })
          .eq('id', dbOrder.id);

        if (!updateError) {
          updatedCount++;
          console.log(`🔄 تحديث الطلب ${waseetOrder.id}: ${waseetStatusText}`);

          // إرسال إشعار للمستخدم عند تغيير الحالة
          await this.sendStatusChangeNotification(dbOrder, appStatus, waseetStatusText);
        }
      }

      this.stats.successfulSyncs++;
      this.stats.ordersUpdated += updatedCount;
      this.lastSyncTime = new Date();
      
      if (updatedCount > 0) {
        console.log(`✅ تم تحديث ${updatedCount} طلب`);
      }
      
    } catch (error) {
      console.error('❌ فشل المزامنة:', error.message);
      this.stats.failedSyncs++;
      this.stats.lastError = error.message;
    } finally {
      this.isCurrentlySyncing = false;
    }
  }

  /**
   * مزامنة فورية (للـ API)
   */
  async forcSync() {
    if (this.isCurrentlySyncing) {
      return { success: false, error: 'المزامنة قيد التنفيذ' };
    }

    const startTime = Date.now();
    await this.performSync();
    const duration = Date.now() - startTime;
    
    return {
      success: true,
      message: 'تم تنفيذ المزامنة الفورية',
      duration,
      stats: this.getStats()
    };
  }

  /**
   * الحصول على الإحصائيات
   */
  getStats() {
    const uptime = Date.now() - this.stats.startTime;
    const uptimeHours = Math.floor(uptime / (1000 * 60 * 60));
    const uptimeMinutes = Math.floor((uptime % (1000 * 60 * 60)) / (1000 * 60));

    return {
      isRunning: this.isRunning,
      isCurrentlySyncing: this.isCurrentlySyncing,
      syncIntervalSeconds: this.syncInterval / 1000,
      lastSyncTime: this.lastSyncTime,
      nextSyncIn: this.isRunning && this.lastSyncTime ? 
        Math.max(0, this.syncInterval - (Date.now() - this.lastSyncTime.getTime())) : null,
      uptime: `${uptimeHours}:${uptimeMinutes.toString().padStart(2, '0')}`,
      totalSyncs: this.stats.totalSyncs,
      successfulSyncs: this.stats.successfulSyncs,
      failedSyncs: this.stats.failedSyncs,
      ordersUpdated: this.stats.ordersUpdated,
      lastError: this.stats.lastError
    };
  }

  /**
   * إعادة تشغيل النظام
   */
  async restart() {
    console.log('🔄 إعادة تشغيل نظام المزامنة...');
    this.stop();
    await new Promise(resolve => setTimeout(resolve, 2000));
    return await this.start();
  }

  /**
   * تحويل حالة الوسيط إلى حالة التطبيق
   * @param {number} waseetStatusId - معرف حالة الوسيط
   * @param {string} waseetStatusText - نص حالة الوسيط
   * @returns {string} حالة التطبيق
   */
  mapWaseetStatusToApp(waseetStatusId, waseetStatusText) {
    // خريطة تحويل حالات الوسيط إلى حالات التطبيق
    const statusMap = {
      // حالات الإلغاء والإرجاع
      23: 'الغاء الطلب',
      31: 'الغاء الطلب',
      32: 'رفض الطلب',
      33: 'مفصول عن الخدمة',
      34: 'طلب مكرر',
      40: 'حظر المندوب',

      // حالات التوصيل
      1: 'فعال',
      2: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
      3: 'تم تغيير محافظة الزبون',
      4: 'لا يرد',
      5: 'لا يرد بعد الاتفاق',
      6: 'مغلق',
      7: 'مغلق بعد الاتفاق',
      8: 'مؤجل',
      9: 'مؤجل لحين اعادة الطلب لاحقا',
      10: 'مستلم مسبقا',
      11: 'الرقم غير معرف',
      12: 'الرقم غير داخل في الخدمة',
      13: 'العنوان غير دقيق',
      14: 'لم يطلب',
      15: 'لا يمكن الاتصال بالرقم',
      16: 'تغيير المندوب'
    };

    // التحويل بالمعرف أولاً
    if (statusMap[waseetStatusId]) {
      return statusMap[waseetStatusId];
    }

    // التحويل بالنص إذا لم يوجد معرف
    const textMap = {
      'ارسال الى مخزن الارجاعات': 'الغاء الطلب',
      'الغاء الطلب': 'الغاء الطلب',
      'رفض الطلب': 'رفض الطلب',
      'مفصول عن الخدمة': 'مفصول عن الخدمة',
      'طلب مكرر': 'طلب مكرر',
      'حظر المندوب': 'حظر المندوب',
      'فعال': 'فعال',
      'قيد التوصيل الى الزبون (في عهدة المندوب)': 'قيد التوصيل الى الزبون (في عهدة المندوب)',
      'تم تغيير محافظة الزبون': 'تم تغيير محافظة الزبون',
      'لا يرد': 'لا يرد',
      'لا يرد بعد الاتفاق': 'لا يرد بعد الاتفاق',
      'مغلق': 'مغلق',
      'مغلق بعد الاتفاق': 'مغلق بعد الاتفاق',
      'مؤجل': 'مؤجل',
      'مؤجل لحين اعادة الطلب لاحقا': 'مؤجل لحين اعادة الطلب لاحقا',
      'مستلم مسبقا': 'مستلم مسبقا',
      'الرقم غير معرف': 'الرقم غير معرف',
      'الرقم غير داخل في الخدمة': 'الرقم غير داخل في الخدمة',
      'العنوان غير دقيق': 'العنوان غير دقيق',
      'لم يطلب': 'لم يطلب',
      'لا يمكن الاتصال بالرقم': 'لا يمكن الاتصال بالرقم',
      'تغيير المندوب': 'تغيير المندوب'
    };

    if (textMap[waseetStatusText]) {
      return textMap[waseetStatusText];
    }

    // إذا لم يوجد تحويل، استخدم النص كما هو
    console.log(`⚠️ حالة غير معروفة من الوسيط: ID=${waseetStatusId}, Text=${waseetStatusText}`);
    return waseetStatusText;
  }

  /**
   * إرسال إشعار للمستخدم عند تغيير حالة الطلب
   * @param {Object} order - بيانات الطلب
   * @param {string} newStatus - الحالة الجديدة
   * @param {string} waseetStatusText - نص حالة الوسيط
   */
  async sendStatusChangeNotification(order, newStatus, waseetStatusText) {
    try {
      // التحقق من وجود رقم هاتف المستخدم
      const userPhone = order.user_phone || order.primary_phone;

      if (!userPhone) {
        console.log(`⚠️ لا يوجد رقم هاتف للطلب ${order.id} - تخطي الإشعار`);
        return;
      }

      // التحقق من تغيير الحالة (لا نرسل إشعار إذا لم تتغير الحالة)
      if (order.status === newStatus) {
        console.log(`📝 لم تتغير حالة الطلب ${order.id} - تخطي الإشعار`);
        return;
      }

      console.log(`📱 إرسال إشعار تحديث الطلب ${order.id} للمستخدم ${userPhone}`);
      console.log(`🔄 الحالة الجديدة: ${newStatus} (${waseetStatusText})`);

      // تهيئة خدمة الإشعارات إذا لم تكن مهيأة
      if (!targetedNotificationService.initialized) {
        await targetedNotificationService.initialize();
      }

      // إرسال الإشعار
      const result = await targetedNotificationService.sendOrderStatusNotification(
        userPhone,
        order.id.toString(),
        newStatus,
        order.customer_name || 'عميل',
        waseetStatusText
      );

      if (result.success) {
        console.log(`✅ تم إرسال إشعار الطلب ${order.id} بنجاح`);
      } else {
        console.log(`❌ فشل إرسال إشعار الطلب ${order.id}: ${result.error}`);
      }

    } catch (error) {
      console.error(`❌ خطأ في إرسال إشعار الطلب ${order.id}:`, error.message);
    }
  }
}

// إنشاء instance واحد للتطبيق
const waseetSyncInstance = new IntegratedWaseetSync();

module.exports = waseetSyncInstance;
