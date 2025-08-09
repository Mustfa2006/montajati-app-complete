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
    this.syncInterval = 5 * 60 * 1000; // كل 5 دقائق
    this.syncIntervalId = null;
    // مؤقت بديل يعتمد على setTimeout المتسلسل (أكثر موثوقية على الاستضافة)
    this.syncTimeoutId = null;
    this.lastSyncTime = null;
    this.nextRunAt = null;
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
        // إعادة المحاولة بعد دقيقة
        setTimeout(() => this.start(), 60000);
        return { success: false, error: testResult.error };
      }

      this.isRunning = true;
      this.stats.startTime = Date.now();
      
      // مزامنة فورية أولى
      await this.performSync();

      // جدولة بالمؤقت التسلسلي لضمان العمل حتى لو تم قتل event loop لفترة قصيرة
      const scheduleNext = () => {
        // لا نضاعف التايمر
        if (this.syncTimeoutId) clearTimeout(this.syncTimeoutId);
        this.nextRunAt = new Date(Date.now() + this.syncInterval);
        this.syncTimeoutId = setTimeout(async () => {
          try {
            await this.performSync();
          } finally {
            scheduleNext(); // أعِد الجدولة دائماً
          }
        }, this.syncInterval);
      };

      scheduleNext();

      return { success: true, message: 'تم بدء النظام بنجاح', nextRunAt: this.nextRunAt };

    } catch (error) {
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
    if (this.syncTimeoutId) {
      clearTimeout(this.syncTimeoutId);
      this.syncTimeoutId = null;
    }
    this.isRunning = false;
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
        .select('id, waseet_order_id, waseet_qr_id, waseet_status_id, waseet_status_text, waseet_status, user_phone, primary_phone, customer_name, status')
        .or('waseet_order_id.not.is.null,waseet_qr_id.not.is.null')
        // ✅ استبعاد الحالات النهائية - استخدام القائمة الموحدة
        .neq('status', 'تم التسليم للزبون')
        .neq('status', 'الغاء الطلب')
        .neq('status', 'رفض الطلب')
        .neq('status', 'تم الارجاع الى التاجر')
        // ملاحظة: "ارسال الى مخزن الارجاعات" يتم تحويلها إلى "الغاء الطلب"
        .neq('status', 'مفصول عن الخدمة')
        .neq('status', 'طلب مكرر')
        .neq('status', 'حظر المندوب')
        .neq('status', 'مستلم مسبقا')
        .neq('status', 'delivered')
        .neq('status', 'cancelled');

      if (error) {
        throw new Error(`خطأ في جلب الطلبات: ${error.message}`);
      }

      // مزامنة الطلبات
      let updatedCount = 0;
      
      for (const waseetOrder of waseetResult.orders) {
        const dbOrder = dbOrders?.find(order =>
          order.waseet_order_id === waseetOrder.id ||
          order.waseet_qr_id === waseetOrder.qrId ||
          order.waseet_qr_id === waseetOrder.id // في بعض الاستجابات يكون نفس الحقل
        );

        if (!dbOrder) continue;

        const waseetStatusId = parseInt(waseetOrder.status_id);
        const waseetStatusText = waseetOrder.status;

        // ✅ تحويل حالة الوسيط إلى حالة التطبيق المعيارية (قبل قرار التخطي)
        const appStatus = this.mapWaseetStatusToApp(waseetStatusId, waseetStatusText);

        // التحقق من وجود تغيير حقيقي يؤثر على ما يظهر في التطبيق
        if (dbOrder.waseet_status_id === waseetStatusId &&
            dbOrder.waseet_status_text === waseetStatusText &&
            dbOrder.status === appStatus) {
          continue;
        }

        // تحديث الطلب بالحالة المعيارية + حفظ حالة الوسيط كما هي
        const { error: updateError } = await this.supabase
          .from('orders')
          .update({
            status: appStatus,
            // اجعل waseet_status يعكس الحالة القياسية للتطبيق لضمان عرض صحيح في الواجهة
            waseet_status: appStatus,
            waseet_status_id: waseetStatusId,
            waseet_status_text: waseetStatusText,
            last_status_check: new Date().toISOString(),
            status_updated_at: new Date().toISOString()
          })
          .eq('id', dbOrder.id);

        if (!updateError) {
          updatedCount++;

          // إرسال إشعار للمستخدم عند تغيير الحالة
          await this.sendStatusChangeNotification(dbOrder, appStatus, waseetStatusText);
        }
      }

      this.stats.successfulSyncs++;
      this.stats.ordersUpdated += updatedCount;
      this.lastSyncTime = new Date();

    } catch (error) {
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
      syncIntervalMinutes: this.syncInterval / (60 * 1000),
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
    // ✅ القاعدة الوحيدة المطلوبة:
    // إذا الحالة من الوسيط هي "ارسال الى مخزن الارجاعات" (ID=23) → "الغاء الطلب"
    try {
      const id = parseInt(waseetStatusId);
      const text = (waseetStatusText || '').trim();

      if (id === 23 || text === 'ارسال الى مخزن الارجاعات') {
        return 'الغاء الطلب';
      }

      // غير ذلك: أعرض نص الوسيط كما هو (نص عربي)
      return text || waseetStatusId?.toString() || '';
    } catch (e) {
      // في حال أي خطأ غير متوقع، أعد النص كما هو
      return (waseetStatusText || '').trim();
    }
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
