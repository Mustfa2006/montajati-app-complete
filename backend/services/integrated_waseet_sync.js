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
      console.log('🚀 بدء نظام المزامنة التلقائي مع الخادم...');

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

      const intervalMinutes = this.syncInterval / (60 * 1000);
      console.log(`✅ نظام المزامنة يعمل - كل ${intervalMinutes} دقيقة (timeout-loop)`);

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
          const statusName = waseetStatusText || `ID=${waseetStatusId}`;
          console.log(`🚫 تم تجاهل حالة "${statusName}" للطلب ${dbOrder.id} - حالة غير مهمة للمستخدم`);

          // ⚠️ لا نحدث أي شيء في قاعدة البيانات لتجنب إطلاق realtime events
          // أي UPDATE على جدول orders سيطلق event ويسبب تحديث الأرباح!
          console.log(`⏭️ تخطي الطلب ${dbOrder.id} بالكامل - لا تحديث في قاعدة البيانات`);
          continue;
        }

        // ✅ تحويل حالة الوسيط إلى حالة التطبيق المعيارية (بعد التأكد أنها ليست فعال)
        const appStatus = this.mapWaseetStatusToApp(waseetStatusId, waseetStatusText);

        // التحقق من وجود تغيير حقيقي يؤثر على ما يظهر في التطبيق
        console.log(`🔍 فحص الطلب ${dbOrder.id}:`);
        console.log(`   📊 قاعدة البيانات - waseet_status_id: ${dbOrder.waseet_status_id}, waseet_status_text: "${dbOrder.waseet_status_text}", status: "${dbOrder.status}"`);
        console.log(`   📊 الوسيط - waseet_status_id: ${waseetStatusId}, waseet_status_text: "${waseetStatusText}", appStatus: "${appStatus}"`);
        console.log(`   🔍 مقارنة - status_id: ${dbOrder.waseet_status_id === waseetStatusId}, status_text: ${dbOrder.waseet_status_text === waseetStatusText}, status: ${dbOrder.status === appStatus}`);

        if (dbOrder.waseet_status_id === waseetStatusId &&
          dbOrder.waseet_status_text === waseetStatusText &&
          dbOrder.status === appStatus) {
          console.log(`   ⏭️ تخطي الطلب ${dbOrder.id} - لا يوجد تغيير`);
          continue;
        }

        console.log(`🔄 تحديث الطلب ${dbOrder.id}:`);
        console.log(`   الحالة من الوسيط: "${waseetStatusText}" (ID=${waseetStatusId})`);
        console.log(`   الحالة بعد التحويل: "${appStatus}"`);

        // ✅ التحقق من وجود waseet_status_id في جدول waseet_statuses قبل التحديث
        const { data: statusExists } = await this.supabase
          .from('waseet_statuses')
          .select('id')
          .eq('id', waseetStatusId)
          .maybeSingle();

        // تحديث الطلب بالحالة المعيارية + حفظ حالة الوسيط كما هي
        const updateData = {
          status: appStatus,
          // اجعل waseet_status يعكس الحالة القياسية للتطبيق لضمان عرض صحيح في الواجهة
          waseet_status: appStatus,
          waseet_status_text: waseetStatusText,
          last_status_check: new Date().toISOString(),
          status_updated_at: new Date().toISOString()
        };

        // ✅ فقط إضافة waseet_status_id إذا كان موجوداً في جدول waseet_statuses
        if (statusExists) {
          // @ts-ignore - إضافة الحقل ديناميكياً
          updateData['waseet_status_id'] = waseetStatusId;
        } else {
          console.warn(`⚠️ تحذير: waseet_status_id=${waseetStatusId} غير موجود في جدول waseet_statuses - سيتم تجاهله`);
        }

        const { error: updateError } = await this.supabase
          .from('orders')
          .update(updateData)
          .eq('id', dbOrder.id);

        if (!updateError) {
          updatedCount++;
          console.log(`✅ تم تحديث الطلب ${dbOrder.id} بنجاح: ${waseetStatusText} → ${appStatus}`);

          // إرسال إشعار للمستخدم عند تغيير الحالة
          await this.sendStatusChangeNotification(dbOrder, appStatus, waseetStatusText);
        } else {
          console.error(`❌ فشل تحديث الطلب ${dbOrder.id}:`, updateError);
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
    // ✅ تحويل حالات الوسيط إلى النصوص المناسبة للمستخدم
    try {
      const id = parseInt(waseetStatusId);
      const text = (waseetStatusText || '').trim();

      // حالة "ارسال الى مخزن الارجاعات" → "الغاء الطلب"
      if (id === 23 || text === 'ارسال الى مخزن الارجاعات') {
        return 'الغاء الطلب';
      }

      // 🚫 حالة "تم الاستلام من قبل المندوب" → "قيد التوصيل الى الزبون (في عهدة المندوب)"
      if (id === 2 || text === 'تم الاستلام من قبل المندوب') {
        return 'قيد التوصيل الى الزبون (في عهدة المندوب)';
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

      // 🎯 قائمة الحالات المسموحة للإشعارات (فقط الحالات المهمة للمستخدم)
      const allowedNotificationStatuses = [
        // الحالات الأساسية
        'تم التسليم للزبون',
        'قيد التوصيل الى الزبون (في عهدة المندوب)',

        // حالات التعديل
        'تم تغيير محافظة الزبون',
        'تغيير المندوب',

        // حالات عدم الرد
        'لا يرد',
        'لا يرد بعد الاتفاق',

        // حالات الإغلاق
        'مغلق',
        'مغلق بعد الاتفاق',

        // حالات مشاكل الاتصال
        'الرقم غير معرف',
        'الرقم غير داخل في الخدمة'
      ];

      // 🚫 فلترة الإشعارات - فقط الحالات المسموحة
      if (!allowedNotificationStatuses.includes(newStatus)) {
        console.log(`🚫 تم تجاهل إشعار الحالة "${newStatus}" - غير مدرجة في القائمة المسموحة`);
        console.log(`   الحالات المسموحة: ${allowedNotificationStatuses.join(', ')}`);
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

// تصدير الـ Class للاستخدام
module.exports = IntegratedWaseetSync;
