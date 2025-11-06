const OfficialWaseetAPI = require('./official_waseet_api');
const { createClient } = require('@supabase/supabase-js');
const targetedNotificationService = require('./targeted_notification_service');
const EventEmitter = require('events');

/**
 * نظام المزامنة المدمج مع الخادم - للإنتاج على Render
 * Integrated Waseet Sync for Production Server
 */
class IntegratedWaseetSync extends EventEmitter {
  constructor() {
    super(); // استدعاء constructor الخاص بـ EventEmitter

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
      // انتظار 10 ثواني لضمان استقرار الخادم
      setTimeout(async () => {
        await this.start();
      }, 10000);

    } catch (error) {
      console.error('❌ فشل البدء التلقائي:', error.message);
      this.emit('error', error);
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

        // إرسال حدث الخطأ
        this.emit('error', new Error(testResult.error));

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
    if (this.syncTimeoutId) {
      clearTimeout(this.syncTimeoutId);
      this.syncTimeoutId = null;
    }
    this.isRunning = false;
    return { success: true };
  }

  /**
   * إغلاق آمن للنظام (لـ gracefulShutdown)
   */
  async shutdown() {
    this.stop();

    // انتظار أي عمليات جارية
    if (this.isCurrentlySyncing) {
      await new Promise(resolve => setTimeout(resolve, 2000));
    }

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

        // 🚫 تجاهل الحالات غير المهمة من الوسيط
        const ignoredStatusIds = [1, 5, 7]; // 1=فعال, 5=في موقع فرز بغداد, 7=في الطريق الى مكتب المحافظة
        const ignoredStatusTexts = ['فعال', 'في موقع فرز بغداد', 'في الطريق الى مكتب المحافظة'];

        if (ignoredStatusIds.includes(waseetStatusId) || ignoredStatusTexts.includes(waseetStatusText)) {
          continue;
        }

        // ✅ تحويل حالة الوسيط إلى حالة التطبيق المعيارية
        const appStatus = this.mapWaseetStatusToApp(waseetStatusId, waseetStatusText);

        // التحقق من وجود تغيير
        if (dbOrder.waseet_status_id === waseetStatusId &&
          dbOrder.waseet_status_text === waseetStatusText &&
          dbOrder.status === appStatus) {
          continue;
        }

        // فحص إذا تغيرت الحالة فعلياً
        if (dbOrder.status === appStatus) {
          continue;
        }

        // ✅ التحقق من وجود waseet_status_id في جدول waseet_statuses
        const { data: statusExists } = await this.supabase
          .from('waseet_statuses')
          .select('id')
          .eq('id', waseetStatusId)
          .maybeSingle();

        // تحديث الطلب
        const updateData = {
          status: appStatus,
          waseet_status: appStatus,
          waseet_status_text: waseetStatusText,
          last_status_check: new Date().toISOString(),
          status_updated_at: new Date().toISOString()
        };

        // ✅ فقط إضافة waseet_status_id إذا كان موجوداً في جدول waseet_statuses
        if (statusExists) {
          updateData['waseet_status_id'] = waseetStatusId;
        }

        const { error: updateError } = await this.supabase
          .from('orders')
          .update(updateData)
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
      console.error('❌ فشل المزامنة:', error.message);
      this.stats.failedSyncs++;
      this.stats.lastError = error.message;

      // إرسال حدث الخطأ
      this.emit('error', error);
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
    // ✅ تحويل حالات الوسيط إلى حالات التطبيق المعيارية
    try {
      const id = parseInt(waseetStatusId);
      const text = (waseetStatusText || '').trim();

      // ===================================
      // 📦 حالات قيد التوصيل (in_delivery)
      // ===================================

      // ID=2: "تم الاستلام من قبل المندوب"
      if (id === 2 || text === 'تم الاستلام من قبل المندوب') {
        return 'قيد التوصيل الى الزبون (في عهدة المندوب)';
      }

      // ID=3: "قيد التوصيل الى الزبون (في عهدة المندوب)"
      if (id === 3 || text === 'قيد التوصيل الى الزبون (في عهدة المندوب)') {
        return 'قيد التوصيل الى الزبون (في عهدة المندوب)';
      }

      // ID=6: "في مكتب المحافظة" → in_delivery
      if (id === 6 || text === 'في مكتب المحافظة') {
        return 'قيد التوصيل الى الزبون (في عهدة المندوب)';
      }

      // ===================================
      // ✅ حالات التسليم (delivered)
      // ===================================

      // ID=4: "تم التسليم للزبون"
      if (id === 4 || text === 'تم التسليم للزبون') {
        return 'تم التسليم للزبون';
      }

      // ===================================
      // ❌ حالات الإلغاء (cancelled)
      // ===================================

      // ID=23: "ارسال الى مخزن الارجاعات"
      if (id === 23 || text === 'ارسال الى مخزن الارجاعات') {
        return 'cancelled';
      }

      // ID=31: "الغاء الطلب"
      if (id === 31 || text === 'الغاء الطلب') {
        return 'cancelled';
      }

      // ID=32: "رفض الطلب"
      if (id === 32 || text === 'رفض الطلب') {
        return 'cancelled';
      }

      // ID=33: "مفصول عن الخدمة"
      if (id === 33 || text === 'مفصول عن الخدمة') {
        return 'cancelled';
      }

      // ID=34: "طلب مكرر"
      if (id === 34 || text === 'طلب مكرر') {
        return 'cancelled';
      }

      // ID=35: "مستلم مسبقا"
      if (id === 35 || text === 'مستلم مسبقا') {
        return 'cancelled';
      }

      // ID=39: "لم يطلب"
      if (id === 39 || text === 'لم يطلب') {
        return 'cancelled';
      }

      // ID=40: "حظر المندوب"
      if (id === 40 || text === 'حظر المندوب') {
        return 'cancelled';
      }

      // ID=17: "تم الارجاع الى التاجر"
      if (id === 17 || text === 'تم الارجاع الى التاجر') {
        return 'cancelled';
      }

      // ===================================
      // 🔄 حالات نشطة (active) - باقي الحالات
      // ===================================

      // جميع الحالات الأخرى تعتبر "active"
      return 'active';

    } catch (e) {
      console.error('❌ خطأ في تحويل حالة الوسيط:', e);
      // في حال أي خطأ، أعد "active" كحالة افتراضية آمنة
      return 'active';
    }
  }

  /**
   * إرسال إشعار للمستخدم عند تغيير حالة الطلب
   * ✅ نظام ذكي لمنع تكرار الإشعارات
   * @param {Object} order - بيانات الطلب
   * @param {string} newStatus - الحالة الجديدة
   * @param {string} waseetStatusText - نص حالة الوسيط
   */
  async sendStatusChangeNotification(order, newStatus, waseetStatusText) {
    try {
      const userPhone = order.user_phone || order.primary_phone;
      if (!userPhone) return;

      // قائمة الحالات المسموحة للإشعارات
      const allowedNotificationStatuses = [
        'قيد التوصيل الى الزبون (في عهدة المندوب)',
        'تم التسليم للزبون',
        'تم تغيير محافظة الزبون',
        'تغيير المندوب',
        'لا يرد',
        'لا يرد بعد الاتفاق',
        'مغلق',
        'مغلق بعد الاتفاق',
        'مؤجل',
        'مؤجل لحين اعادة الطلب لاحقا',
        'الغاء الطلب',
        'رفض الطلب',
        'مفصول عن الخدمة',
        'طلب مكرر',
        'مستلم مسبقا',
        'الرقم غير معرف',
        'الرقم غير داخل في الخدمة',
        'لا يمكن الاتصال بالرقم',
        'العنوان غير دقيق',
        'لم يطلب',
        'حظر المندوب'
      ];

      // فلترة الإشعارات
      if (!allowedNotificationStatuses.includes(newStatus)) return;

      // فحص ذكي لمنع التكرار
      if (order.last_notification_status === newStatus) return;

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
        // تحديث آخر حالة تم إرسال إشعار لها لمنع التكرار
        await this.supabase
          .from('orders')
          .update({ last_notification_status: newStatus })
          .eq('id', order.id);
      }

    } catch (error) {
      console.error(`❌ خطأ في إرسال إشعار الطلب ${order.id}:`, error.message);
    }
  }
}

// تصدير الـ Class للاستخدام
module.exports = IntegratedWaseetSync;
