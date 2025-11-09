const OfficialWaseetAPI = require('./official_waseet_api');
const { createClient } = require('@supabase/supabase-js');
const targetedNotificationService = require('./targeted_notification_service');
const EventEmitter = require('events');

/**
 * ═══════════════════════════════════════════════════════════════════════════════
 * 🚀 نظام المزامنة الذكي المدمج مع الخادم
 * Intelligent Integrated Waseet Sync System for Production
 *
 * ✨ المميزات:
 * - نظام ذكي لمنع تكرار التحديثات
 * - أداء عالي مع استخدام Map للبحث السريع
 * - معالجة أخطاء شاملة وآمنة
 * - نظام إحصائيات متقدم
 * - جدولة موثوقة مع setTimeout المتسلسل
 * ═══════════════════════════════════════════════════════════════════════════════
 */
class IntegratedWaseetSync extends EventEmitter {
  constructor() {
    super();

    // ✅ تهيئة العملاء
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    this.waseetAPI = new OfficialWaseetAPI(
      process.env.WASEET_USERNAME || 'mustfaabd',
      process.env.WASEET_PASSWORD || '65888304'
    );

    // ✅ إعدادات المزامنة
    this.config = {
      syncInterval: 5 * 60 * 1000, // 5 دقائق
      minTimeBetweenUpdates: 4 * 60 * 1000, // 4 دقائق - منع التحديثات المتكررة
      notificationCooldown: 12 * 60 * 60 * 1000, // 12 ساعة - منع الإشعارات المتكررة
      maxRetries: 3,
      retryDelay: 60000, // دقيقة واحدة
      connectionTestInterval: 30 * 60 * 1000 // 30 دقيقة
    };

    // ✅ حالة النظام
    this.state = {
      isRunning: false,
      isCurrentlySyncing: false,
      lastSyncTime: null,
      nextRunAt: null,
      lastConnectionTest: null,
      syncTimeoutId: null
    };

    // 🔧 Backward-compatibility flags for optional notification columns
    this.state.hasOrderNotificationColumns = true;
    this.state.notificationMemory = new Map();
    this.state.notificationWarned = false;

    // ✅ الإحصائيات المتقدمة
    this.stats = {
      totalSyncs: 0,
      successfulSyncs: 0,
      failedSyncs: 0,
      ordersUpdated: 0,
      ordersSkipped: 0,
      notificationsSent: 0,
      startTime: Date.now(),
      lastError: null,
      lastErrorTime: null,
      averageSyncDuration: 0,
      totalSyncDuration: 0
    };

    // ✅ خريطة حالات الوسيط (للبحث السريع O(1))
    this.statusMap = this._initializeStatusMap();

    // ✅ قائمة الحالات المسموحة للإشعارات
    this.allowedNotificationStatuses = this._initializeNotificationStatuses();

    // ✅ قائمة الحالات المستبعدة من المزامنة
    this.excludedStatuses = this._initializeExcludedStatuses();

    // ✅ قائمة الحالات المتجاهلة من الوسيط
    this.ignoredWaseetStatuses = this._initializeIgnoredStatuses();
  }

  /**
   * ═══════════════════════════════════════════════════════════════════════════════
   * 🔧 دوال التهيئة والإعدادات
   * ═══════════════════════════════════════════════════════════════════════════════
   */

  /**
   * تهيئة خريطة حالات الوسيط
   * @returns {Map} خريطة تحويل الحالات
   */
  _initializeStatusMap() {
    return new Map([
      // 📦 حالات قيد التوصيل
      [2, 'قيد التوصيل الى الزبون (في عهدة المندوب)'],
      [3, 'قيد التوصيل الى الزبون (في عهدة المندوب)'],
      [6, 'قيد التوصيل الى الزبون (في عهدة المندوب)'],

      // ✅ حالات التسليم
      [4, 'تم التسليم للزبون'],

      // ❌ حالات الإلغاء
      [17, 'الغاء الطلب'],
      [23, 'الغاء الطلب'],
      [31, 'الغاء الطلب'],
      [32, 'الغاء الطلب'],
      [33, 'الغاء الطلب'],
      [34, 'الغاء الطلب'],
      [35, 'الغاء الطلب'],
      [39, 'الغاء الطلب'],
      [40, 'الغاء الطلب']
    ]);
  }

  /**
   * تهيئة قائمة الحالات المسموحة للإشعارات
   */
  _initializeNotificationStatuses() {
    return new Set([
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
      'cancelled',
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
    ]);
  }

  /**
   * تهيئة قائمة الحالات المستبعدة من المزامنة
   */
  _initializeExcludedStatuses() {
    return new Set([
      'تم التسليم للزبون',
      'الغاء الطلب',
      'رفض الطلب',
      'تم الارجاع الى التاجر',
      'مفصول عن الخدمة',
      'طلب مكرر',
      'حظر المندوب',
      'مستلم مسبقا',
      'delivered',
      'cancelled'
    ]);
  }

  /**
   * تهيئة قائمة الحالات المتجاهلة من الوسيط
   */
  _initializeIgnoredStatuses() {
    return new Map([
      [1, 'فعال'],
      [5, 'في موقع فرز بغداد'],
      [6, 'في مكتب المحافظة'],
      [7, 'في الطريق الى مكتب المحافظة']
    ]);
  }

  /**
   * بدء النظام تلقائياً مع الخادم
   */
  async autoStart() {
    try {
      console.log('⏳ جاري بدء نظام المزامنة الذكي...');
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
   * ═══════════════════════════════════════════════════════════════════════════════
   * 🎯 دوال إدارة دورة حياة النظام
   * ═══════════════════════════════════════════════════════════════════════════════
   */

  /**
   * بدء النظام بشكل آمن وموثوق
   */
  async start() {
    try {
      if (this.state.isRunning) {
        console.log('ℹ️ النظام يعمل بالفعل');
        return { success: true, message: 'النظام يعمل بالفعل' };
      }

      console.log('🚀 جاري بدء نظام المزامنة الذكي...');

      // ✅ اختبار الاتصال
      const testResult = await this._testConnectionWithRetry();
      if (!testResult.success) {
        console.error('❌ فشل اختبار الاتصال:', testResult.error);
        this.emit('error', new Error(testResult.error));

        // إعادة المحاولة بعد دقيقة
        setTimeout(() => this.start(), this.config.retryDelay);
        return { success: false, error: testResult.error };
      }

      this.state.isRunning = true;
      this.stats.startTime = Date.now();
      console.log('✅ تم بدء النظام بنجاح');

      // ✅ مزامنة فورية أولى
      await this.performSync();

      // ✅ جدولة المزامنة المتسلسلة
      this._scheduleNextSync();

      return {
        success: true,
        message: 'تم بدء النظام بنجاح',
        nextRunAt: this.state.nextRunAt
      };

    } catch (error) {
      console.error('❌ فشل بدء النظام:', error.message);
      this._recordError(error);

      // إعادة المحاولة بعد دقيقة
      setTimeout(() => this.start(), this.config.retryDelay);
      return { success: false, error: error.message };
    }
  }

  /**
   * جدولة المزامنة التالية بشكل آمن
   */
  _scheduleNextSync() {
    // تنظيف أي جدولة سابقة
    if (this.state.syncTimeoutId) {
      clearTimeout(this.state.syncTimeoutId);
    }

    this.state.nextRunAt = new Date(Date.now() + this.config.syncInterval);

    this.state.syncTimeoutId = setTimeout(async () => {
      try {
        await this.performSync();
      } catch (error) {
        console.error('❌ خطأ في المزامنة المجدولة:', error.message);
      } finally {
        // إعادة الجدولة دائماً
        if (this.state.isRunning) {
          this._scheduleNextSync();
        }
      }
    }, this.config.syncInterval);
  }

  /**
   * اختبار الاتصال مع إعادة محاولة
   */
  async _testConnectionWithRetry(retries = 0) {
    try {
      const result = await this.testConnection();
      if (result.success) {
        this.state.lastConnectionTest = Date.now();
      }
      return result;
    } catch (error) {
      if (retries < this.config.maxRetries) {
        await new Promise(resolve => setTimeout(resolve, 1000));
        return this._testConnectionWithRetry(retries + 1);
      }
      return { success: false, error: error.message };
    }
  }

  /**
   * إيقاف النظام بشكل آمن
   */
  stop() {
    console.log('⏹️ جاري إيقاف نظام المزامنة...');

    if (this.state.syncTimeoutId) {
      clearTimeout(this.state.syncTimeoutId);
      this.state.syncTimeoutId = null;
    }

    this.state.isRunning = false;
    console.log('✅ تم إيقاف النظام');

    return { success: true };
  }

  /**
   * إغلاق آمن للنظام (graceful shutdown)
   */
  async shutdown() {
    console.log('🛑 جاري إغلاق النظام بشكل آمن...');

    this.stop();

    // انتظار أي عمليات جارية
    if (this.state.isCurrentlySyncing) {
      console.log('⏳ انتظار انتهاء المزامنة الجارية...');
      await new Promise(resolve => setTimeout(resolve, 5000));
    }

    console.log('✅ تم إغلاق النظام بنجاح');
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
   * ═══════════════════════════════════════════════════════════════════════════════
   * 🔄 دوال المزامنة الرئيسية
   * ═══════════════════════════════════════════════════════════════════════════════
   */

  /**
   * تنفيذ المزامنة الذكية مع منع التكرار
   */
  async performSync() {
    // ✅ منع المزامنة المتزامنة
    if (this.state.isCurrentlySyncing) {
      console.log('⚠️ المزامنة قيد التنفيذ بالفعل، تجاهل الطلب الجديد');
      return;
    }

    const syncStartTime = Date.now();
    this.state.isCurrentlySyncing = true;
    this.stats.totalSyncs++;

    try {
      console.log(`\n🔄 بدء المزامنة #${this.stats.totalSyncs}...`);

      // ✅ جلب الطلبات من الوسيط
      const waseetResult = await this.waseetAPI.getAllMerchantOrders();
      if (!waseetResult.success) {
        throw new Error(`فشل جلب الطلبات من الوسيط: ${waseetResult.error}`);
      }

      // ✅ جلب الطلبات من قاعدة البيانات (بدون الحالات النهائية)
      const dbOrders = await this._fetchActiveOrders();
      if (!dbOrders) {
        throw new Error('فشل جلب الطلبات من قاعدة البيانات');
      }

      // ✅ إنشاء خريطة للبحث السريع O(1)
      const dbOrdersMap = this._createOrdersMap(dbOrders);

      // ✅ مزامنة الطلبات
      let updatedCount = 0;
      let skippedCount = 0;

      for (const waseetOrder of waseetResult.orders) {
        const dbOrder = this._findOrderInMap(dbOrdersMap, waseetOrder);
        if (!dbOrder) continue;

        const waseetStatusId = parseInt(waseetOrder.status_id);
        const waseetStatusText = waseetOrder.status;

        // ✅ تجاهل الحالات غير المهمة
        if (this.ignoredWaseetStatuses.has(waseetStatusId)) {
          skippedCount++;
          continue;
        }

        // ✅ تحويل الحالة
        const appStatus = this._mapWaseetStatusToApp(waseetStatusId, waseetStatusText);

        // ✅ فحص ذكي لمنع التكرار
        if (this._shouldSkipUpdate(dbOrder, waseetStatusId, waseetStatusText, appStatus)) {
          skippedCount++;
          continue;
        }

        // ✅ تحديث الطلب
        const updateSuccess = await this._updateOrder(dbOrder, appStatus, waseetStatusId, waseetStatusText);
        if (updateSuccess) {
          updatedCount++;
          // إرسال إشعار
          await this._sendNotificationSafely(dbOrder, appStatus, waseetStatusText);
        }
      }

      // ✅ تحديث الإحصائيات
      this.stats.successfulSyncs++;
      this.stats.ordersUpdated += updatedCount;
      this.stats.ordersSkipped += skippedCount;
      this.state.lastSyncTime = new Date();

      const syncDuration = Date.now() - syncStartTime;
      this.stats.totalSyncDuration += syncDuration;
      this.stats.averageSyncDuration = this.stats.totalSyncDuration / this.stats.successfulSyncs;

      console.log(`✅ انتهت المزامنة #${this.stats.totalSyncs}`);
      console.log(`   📊 تم تحديث: ${updatedCount} | تم تجاهل: ${skippedCount}`);
      console.log(`   ⏱️ المدة: ${syncDuration}ms`);


      // 🔁 محاولة رفع الطلبات التي أصبحت "قيد التوصيل" ولم تُرسل للوسيط بعد
      try {
        const { data: pendingOrders, error: pendingErr } = await this.supabase
          .from('orders')
          .select('id, status, waseet_order_id')
          .in('status', ['in_delivery', 'قيد التوصيل الى الزبون (في عهدة المندوب)'])
          .is('waseet_order_id', null)
          .limit(20);

        if (!pendingErr && Array.isArray(pendingOrders) && pendingOrders.length > 0) {
          console.log(`🚚 يوجد ${pendingOrders.length} طلب(ات) قيد التوصيل بدون معرف وسيط، سيتم رفعها الآن...`);
          const OrderSyncService = require('./order_sync_service');
          const orderSyncService = new OrderSyncService();

          for (const o of pendingOrders) {
            try {
              await orderSyncService.sendOrderToWaseet(o.id);
            } catch (e) {
              console.warn(`⚠️ تعذّر رفع الطلب ${o.id} للوسيط: ${e.message}`);
            }
          }
        }
      } catch (e) {
        console.warn('⚠️ فشل تمرير الطلبات المعلقة إلى الوسيط:', e.message);
      }

    } catch (error) {
      console.error('❌ فشل المزامنة:', error.message);
      this.stats.failedSyncs++;
      this._recordError(error);
      this.emit('error', error);
    } finally {
      this.state.isCurrentlySyncing = false;
    }
  }

  /**
   * جلب الطلبات النشطة من قاعدة البيانات
   */
  async _fetchActiveOrders() {
    try {
      const { data, error } = await this.supabase
        .from('orders')
        .select('id, waseet_order_id, waseet_qr_id, waseet_status_id, waseet_status_text, status, status_updated_at, user_phone, primary_phone, customer_name')
        .or('waseet_order_id.not.is.null,waseet_qr_id.not.is.null');

      if (error) throw error;

      // ✅ فلترة الحالات المستبعدة
      return data?.filter(order => !this.excludedStatuses.has(order.status)) || [];
    } catch (error) {
      console.error('❌ خطأ في جلب الطلبات:', error.message);
      return null;
    }
  }

  /**
   * إنشاء خريطة للبحث السريع
   */
  _createOrdersMap(orders) {
    const map = new Map();
    for (const order of orders) {
      if (order.waseet_order_id) {
        map.set(`waseet_${order.waseet_order_id}`, order);
      }
      if (order.waseet_qr_id) {
        map.set(`qr_${order.waseet_qr_id}`, order);
      }
    }
    return map;
  }

  /**
   * البحث عن الطلب في الخريطة
   */
  _findOrderInMap(map, waseetOrder) {
    return map.get(`waseet_${waseetOrder.id}`) ||
      map.get(`qr_${waseetOrder.qrId}`) ||
      map.get(`qr_${waseetOrder.id}`);
  }

  /**
   * فحص ذكي لمنع التحديثات المتكررة
   */
  _shouldSkipUpdate(dbOrder, waseetStatusId, waseetStatusText, appStatus) {
    // ✅ إذا لم تتغير الحالة
    if (dbOrder.status === appStatus &&
      dbOrder.waseet_status_id === waseetStatusId &&
      dbOrder.waseet_status_text === waseetStatusText) {
      return true;
    }

    // ✅ إذا مرت أقل من 4 دقائق منذ آخر تحديث
    if (dbOrder.status_updated_at) {
      const timeSinceLastUpdate = Date.now() - new Date(dbOrder.status_updated_at).getTime();
      if (timeSinceLastUpdate < this.config.minTimeBetweenUpdates) {
        return true;
      }
    }

    return false;
  }

  /**
   * تحديث الطلب بشكل آمن
   */
  async _updateOrder(dbOrder, appStatus, waseetStatusId, waseetStatusText) {
    try {
      // 🛡️ ProfitGuard (integrated sync): منع أي تغيير غير متوقع في أرباح المستخدم عند التحويل إلى "قيد التوصيل"
      const isInDeliveryStatus = (s) => {
        const t = (s || '').toString().toLowerCase();
        return t.includes('in_delivery') || t.includes('قيد التوصيل');
      };
      let __profitGuardShouldRun = isInDeliveryStatus(appStatus);
      const __profitGuardUserPhone = dbOrder.user_phone || dbOrder.primary_phone;
      let __profitGuardBefore = null;
      const __orderId = dbOrder.id;

      if (__profitGuardShouldRun && __profitGuardUserPhone) {
        try {
          const { data: __u, error: __uErr } = await this.supabase
            .from('users')
            .select('achieved_profits, expected_profits')
            .eq('phone', __profitGuardUserPhone)
            .single();
          if (!__uErr && __u) {
            __profitGuardBefore = {
              achieved: Number(__u.achieved_profits) || 0,
              expected: Number(__u.expected_profits) || 0,
            };
            if (process.env.LOG_LEVEL === 'debug') console.log(`🛡️ [SYNC] ProfitGuard snapshot for ${__profitGuardUserPhone} (order ${__orderId}):`, __profitGuardBefore);
          } else {
            __profitGuardShouldRun = false;
          }
        } catch (gErr) {
          __profitGuardShouldRun = false;
        }
      }

      let updateData = {
        waseet_status: appStatus,
        waseet_status_text: waseetStatusText,
        last_status_check: new Date().toISOString(),
        status_updated_at: new Date().toISOString()
      };

      // ✅ لا نحدّث waseet_status_id إلا إذا كان ضمن القائمة المعتمدة لتفادي كسر FK
      const allowedWaseetIds = new Set([2, 3, 4, 17, 23, 31, 32, 33, 34, 35, 39, 40]);
      const parsedId = parseInt(waseetStatusId);
      if (allowedWaseetIds.has(parsedId)) {
        updateData.waseet_status_id = parsedId;
      }
      // ✅ لا نقوم بتحديث عمود status إذا لم تتغير الحالة فعلياً لمنع تشغيل Trigger التربح مرتين
      if (dbOrder.status !== appStatus) {
        const lower = (appStatus || '').toString().toLowerCase().trim();
        const isActiveLike = ['active', 'فعال', 'نشط', 'confirmed'].includes(lower);
        if (!isActiveLike) {
          updateData.status = appStatus;
        }
      }

      // شرط إضافي: نمنع تحديث صف يحتوي نفس القيمة في status باستخدام neq لمنع تشغيل التريجر بلا داعٍ
      let __q = this.supabase
        .from('orders')
        .update(updateData)
        .eq('id', dbOrder.id);
      if (Object.prototype.hasOwnProperty.call(updateData, 'status')) {
        __q = __q.neq('status', appStatus);
      }
      const { error } = await __q;

      if (error) {
        console.error(`❌ خطأ في تحديث الطلب ${dbOrder.id}:`, error.message);
        return false;
      }

      // 🛡️ ProfitGuard: فحص فوري بعد التحديث
      if (__profitGuardShouldRun && __profitGuardBefore && __profitGuardUserPhone) {
        try {
          const { data: __after, error: __afterErr } = await this.supabase
            .from('users')
            .select('achieved_profits, expected_profits')
            .eq('phone', __profitGuardUserPhone)
            .single();
          if (!__afterErr && __after) {
            const achievedAfter = Number(__after.achieved_profits) || 0;
            const expectedAfter = Number(__after.expected_profits) || 0;
            const __changed = achievedAfter !== __profitGuardBefore.achieved || expectedAfter !== __profitGuardBefore.expected;
            if (__changed) {
              console.warn(`🛡️ [SYNC] ProfitGuard: unexpected change detected after in-delivery sync update. Reverting.`, {
                orderId: __orderId,
                before: __profitGuardBefore,
                after: { achieved: achievedAfter, expected: expectedAfter }
              });
              await this.supabase
                .from('users')
                .update({
                  achieved_profits: __profitGuardBefore.achieved,
                  expected_profits: __profitGuardBefore.expected,
                  updated_at: new Date().toISOString(),
                })
                .eq('phone', __profitGuardUserPhone);
              if (process.env.LOG_LEVEL === 'debug') console.log(`✅ [SYNC] ProfitGuard: user profits reverted to snapshot for ${__profitGuardUserPhone}.`);
            }
          }
        } catch (pgErr2) {
          // تجاهل
        }

        // 🔁 تحقق متأخر لالتقاط أي تغييرات تأتي متأخرة من مستمعين خارجيين
        setTimeout(async () => {
          try {
            const { data: __later, error: __laterErr } = await this.supabase
              .from('users')
              .select('achieved_profits, expected_profits')
              .eq('phone', __profitGuardUserPhone)
              .single();
            if (!__laterErr && __later) {
              const achievedLater = Number(__later.achieved_profits) || 0;
              const expectedLater = Number(__later.expected_profits) || 0;
              const __lateChanged = achievedLater !== __profitGuardBefore.achieved || expectedLater !== __profitGuardBefore.expected;
              if (__lateChanged) {
                console.warn(`🛡️ [SYNC] ProfitGuard (delayed): late change detected. Reverting now.`, {
                  orderId: __orderId,
                  before: __profitGuardBefore,
                  later: { achieved: achievedLater, expected: expectedLater }
                });
                await this.supabase
                  .from('users')
                  .update({
                    achieved_profits: __profitGuardBefore.achieved,
                    expected_profits: __profitGuardBefore.expected,
                    updated_at: new Date().toISOString(),
                  })
                  .eq('phone', __profitGuardUserPhone);
                if (process.env.LOG_LEVEL === 'debug') console.log(`✅ [SYNC] ProfitGuard (delayed): user profits reverted for ${__profitGuardUserPhone}.`);
              }
            }
          } catch (pgErr3) {
            // تجاهل
          }
        }, 1500);
      }

      return true;
    } catch (error) {
      console.error(`❌ خطأ في تحديث الطلب ${dbOrder.id}:`, error.message);
      return false;
    }
  }

  /**
   * مزامنة فورية (للـ API) - اسم صحيح
   */
  async forceSync() {
    if (this.state.isCurrentlySyncing) {
      return {
        success: false,
        error: 'المزامنة قيد التنفيذ بالفعل'
      };
    }

    console.log('🚀 جاري تنفيذ مزامنة فورية...');
    const startTime = Date.now();

    try {
      await this.performSync();
      const duration = Date.now() - startTime;

      return {
        success: true,
        message: 'تم تنفيذ المزامنة الفورية بنجاح',
        duration,
        stats: this.getStats()
      };
    } catch (error) {
      console.error('❌ فشل المزامنة الفورية:', error.message);
      return {
        success: false,
        error: error.message,
        stats: this.getStats()
      };
    }
  }

  /**
   * ═══════════════════════════════════════════════════════════════════════════════
   * 📊 دوال الإحصائيات والمراقبة
   * ═══════════════════════════════════════════════════════════════════════════════
   */

  /**
   * الحصول على الإحصائيات المتقدمة
   */
  getStats() {
    const uptime = Date.now() - this.stats.startTime;
    const uptimeHours = Math.floor(uptime / (1000 * 60 * 60));
    const uptimeMinutes = Math.floor((uptime % (1000 * 60 * 60)) / (1000 * 60));
    const successRate = this.stats.totalSyncs > 0
      ? ((this.stats.successfulSyncs / this.stats.totalSyncs) * 100).toFixed(2)
      : 0;

    return {
      // ✅ حالة النظام
      isRunning: this.state.isRunning,
      isCurrentlySyncing: this.state.isCurrentlySyncing,

      // ✅ إعدادات المزامنة
      syncIntervalMinutes: this.config.syncInterval / (60 * 1000),
      minTimeBetweenUpdatesMinutes: this.config.minTimeBetweenUpdates / (60 * 1000),

      // ✅ أوقات المزامنة
      lastSyncTime: this.state.lastSyncTime,
      nextSyncIn: this.state.isRunning && this.state.lastSyncTime ?
        Math.max(0, this.config.syncInterval - (Date.now() - this.state.lastSyncTime.getTime())) : null,

      // ✅ وقت التشغيل
      uptime: `${uptimeHours}:${uptimeMinutes.toString().padStart(2, '0')}`,

      // ✅ إحصائيات المزامنة
      totalSyncs: this.stats.totalSyncs,
      successfulSyncs: this.stats.successfulSyncs,
      failedSyncs: this.stats.failedSyncs,
      successRate: `${successRate}%`,

      // ✅ إحصائيات الطلبات
      ordersUpdated: this.stats.ordersUpdated,
      ordersSkipped: this.stats.ordersSkipped,
      notificationsSent: this.stats.notificationsSent,

      // ✅ الأداء
      averageSyncDuration: `${this.stats.averageSyncDuration.toFixed(2)}ms`,
      totalSyncDuration: `${(this.stats.totalSyncDuration / 1000).toFixed(2)}s`,

      // ✅ الأخطاء
      lastError: this.stats.lastError,
      lastErrorTime: this.stats.lastErrorTime
    };
  }

  /**
   * تسجيل الخطأ
   */
  _recordError(error) {
    this.stats.lastError = error.message;
    this.stats.lastErrorTime = new Date().toISOString();
  }

  /**
   * إعادة تشغيل النظام بشكل آمن
   */
  async restart() {
    console.log('🔄 جاري إعادة تشغيل النظام...');

    this.stop();

    // انتظار آمن
    await new Promise(resolve => setTimeout(resolve, 2000));

    return await this.start();
  }

  /**
   * ═══════════════════════════════════════════════════════════════════════════════
   * 🔀 دوال تحويل الحالات
   * ═══════════════════════════════════════════════════════════════════════════════
   */

  /**
   * تحويل حالة الوسيط إلى حالة التطبيق (استخدام Map للأداء العالي)
   * @param {number} waseetStatusId - معرف حالة الوسيط
   * @param {string} waseetStatusText - نص حالة الوسيط
   * @returns {string} حالة التطبيق
   */
  _mapWaseetStatusToApp(waseetStatusId, waseetStatusText) {
    try {
      const id = parseInt(waseetStatusId);

      // ✅ البحث في الخريطة أولاً (O(1))
      if (this.statusMap.has(id)) {
        return this.statusMap.get(id);
      }

      // ✅ البحث بالنص كبديل
      const text = (waseetStatusText || '').trim();
      for (const [mapId, mapStatus] of this.statusMap) {
        if (text === this._getStatusTextForId(mapId)) {
          return mapStatus;
        }
      }

      // ✅ الحالة الافتراضية الآمنة (لا نعود إلى نشط)
      return 'قيد التوصيل الى الزبون (في عهدة المندوب)';

    } catch (error) {
      console.error('❌ خطأ في تحويل حالة الوسيط:', error.message);
      return 'قيد التوصيل الى الزبون (في عهدة المندوب)';
    }
  }

  /**
   * الحصول على نص الحالة من المعرف (للمرجعية)
   */
  _getStatusTextForId(id) {
    const statusTexts = {
      2: 'تم الاستلام من قبل المندوب',
      3: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
      4: 'تم التسليم للزبون',
      6: 'في مكتب المحافظة',
      17: 'تم الارجاع الى التاجر',
      23: 'ارسال الى مخزن الارجاعات',
      31: 'الغاء الطلب',
      32: 'رفض الطلب',
      33: 'مفصول عن الخدمة',
      34: 'طلب مكرر',
      35: 'مستلم مسبقا',
      39: 'لم يطلب',
      40: 'حظر المندوب'
    };
    return statusTexts[id] || '';
  }

  /**
   * دالة عامة للتوافق مع الكود القديم
   */
  mapWaseetStatusToApp(waseetStatusId, waseetStatusText) {
    return this._mapWaseetStatusToApp(waseetStatusId, waseetStatusText);
  }

  /**
   * ═══════════════════════════════════════════════════════════════════════════════
   * 📢 دوال الإشعارات الذكية
   * ═══════════════════════════════════════════════════════════════════════════════
   */

  /**
   * إرسال إشعار بشكل آمن مع منع التكرار الذكي
   */
  async _sendNotificationSafely(order, newStatus, waseetStatusText) {
    try {
      // ✅ التحقق من رقم الهاتف
      const userPhone = order.user_phone || order.primary_phone;
      if (!userPhone) {
        return;
      }

      // ✅ التحقق من أن الحالة مسموحة للإشعارات
      if (!this.allowedNotificationStatuses.has(newStatus)) {
        return;
      }

      // ✅ فحص ذكي لمنع التكرار (نفس الحالة)
      if (order.last_notification_status === newStatus) {
        return;
      }

      // ✅ فحص ذكي لمنع التكرار (cooldown 12 ساعة)
      if (order.last_notification_at) {
        const timeSinceLastNotification = Date.now() - new Date(order.last_notification_at).getTime();
        if (timeSinceLastNotification < this.config.notificationCooldown) {
          return;
        }
      }

      // 🧠 بديل آمن: منع التكرار اعتمادًا على الذاكرة في حال عدم توفر الأعمدة في قاعدة البيانات
      try {
        const __mem = this.state.notificationMemory;
        const __oid = order.id?.toString();
        if (__oid && __mem) {
          const __m = __mem.get(__oid);
          if (__m) {
            if (__m.status === newStatus) {
              return;
            }
            const __elapsed = Date.now() - __m.at;
            if (__elapsed < this.config.notificationCooldown) {
              return;
            }
          }
        }
      } catch (_) { }

      // ✅ تهيئة خدمة الإشعارات
      if (!targetedNotificationService.initialized) {
        await targetedNotificationService.initialize();
      }

      // ✅ إرسال الإشعار
      const result = await targetedNotificationService.sendOrderStatusNotification(
        userPhone,
        order.id.toString(),
        newStatus,
        order.customer_name || 'عميل',
        waseetStatusText
      );

      if (result.success) {
        // 🧠 تحديث سجل الذاكرة لمنع التكرار أثناء عمل الخدمة
        try {
          const __oid2 = order.id?.toString();
          if (__oid2) {
            this.state.notificationMemory.set(__oid2, { status: newStatus, at: Date.now() });
          }
        } catch (_) { }

        // ✅ تحديث بيانات الإشعار في قاعدة البيانات (إن كانت الأعمدة متاحة)
        await this._updateNotificationStatus(order.id, newStatus);
        this.stats.notificationsSent++;
      }

    } catch (error) {
      console.error(`❌ خطأ في إرسال إشعار الطلب ${order.id}:`, error.message);
    }
  }

  /**
   * تحديث حالة الإشعار في قاعدة البيانات
   */
  async _updateNotificationStatus(orderId, newStatus) {
    try {
      // إذا كانت الأعمدة غير متاحة تم تعطيل الحفظ - نخرج مبكرًا
      if (this.state && this.state.hasOrderNotificationColumns === false) {
        return;
      }

      const { error } = await this.supabase
        .from('orders')
        .update({
          last_notification_status: newStatus,
          last_notification_at: new Date().toISOString()
        })
        .eq('id', orderId);

      if (error) throw error;
    } catch (error) {
      const msg = error?.message || String(error);
      if (/last_notification_(status|at)/i.test(msg) || /does not exist/i.test(msg)) {
        // تعطيل المحاولة مستقبلًا والاكتفاء بمنع التكرار ضمن الذاكرة
        if (this.state) {
          this.state.hasOrderNotificationColumns = false;
          if (!this.state.notificationWarned) {
            console.warn('ℹ️ تعطيل تحديث حقول الإشعار في جدول orders لعدم توفر الأعمدة (last_notification_status/last_notification_at). سيتم استخدام منع التكرار ضمن الذاكرة فقط.');
            this.state.notificationWarned = true;
          }
        }
      } else {
        console.error(`❌ خطأ في تحديث حالة الإشعار للطلب ${orderId}:`, msg);
      }
    }
  }

  /**
   * دالة عامة للتوافق مع الكود القديم
   */
  async sendStatusChangeNotification(order, newStatus, waseetStatusText) {
    return this._sendNotificationSafely(order, newStatus, waseetStatusText);
  }
}

// تصدير الـ Class للاستخدام
module.exports = IntegratedWaseetSync;
