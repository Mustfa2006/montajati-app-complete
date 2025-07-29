const OfficialWaseetAPI = require('./official_waseet_api');
const { createClient } = require('@supabase/supabase-js');

/**
 * نظام المزامنة الإنتاجي مع الوسيط - النسخة النهائية
 * Production Waseet Sync System - Final Version
 */
class ProductionWaseetSync {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
    
    this.waseetAPI = new OfficialWaseetAPI(
      process.env.WASEET_USERNAME || 'mustfaabd',
      process.env.WASEET_PASSWORD || '65888304'
    );
    
    // إعدادات النظام
    this.isRunning = false;
    this.syncInterval = 60 * 1000; // كل دقيقة للكشف الفوري
    this.syncIntervalId = null;
    this.lastSyncTime = null;
    this.isCurrentlySyncing = false;
    
    // إحصائيات النظام
    this.stats = {
      totalSyncs: 0,
      successfulSyncs: 0,
      failedSyncs: 0,
      ordersUpdated: 0,
      ordersProcessed: 0,
      lastError: null,
      uptime: Date.now()
    };
    
    console.log('🏭 تم تهيئة نظام المزامنة الإنتاجي مع الوسيط');
  }

  /**
   * بدء النظام الإنتاجي
   */
  async start() {
    try {
      if (this.isRunning) {
        console.log('⚠️ النظام يعمل بالفعل');
        return { success: true, message: 'النظام يعمل بالفعل' };
      }

      console.log('🚀 === بدء نظام المزامنة الإنتاجي ===');
      
      // اختبار الاتصال أولاً
      const testResult = await this.testConnection();
      if (!testResult.success) {
        throw new Error(`فشل اختبار الاتصال: ${testResult.error}`);
      }

      this.isRunning = true;
      this.stats.uptime = Date.now();
      
      // مزامنة فورية أولى
      await this.performSync();
      
      // بدء المزامنة المستمرة
      this.syncIntervalId = setInterval(async () => {
        if (!this.isCurrentlySyncing) {
          await this.performSync();
        }
      }, this.syncInterval);
      
      console.log(`✅ النظام الإنتاجي يعمل - مزامنة كل ${this.syncInterval / 1000} ثانية`);
      
      return { 
        success: true, 
        message: 'تم بدء النظام الإنتاجي بنجاح',
        syncInterval: this.syncInterval
      };
      
    } catch (error) {
      console.error('❌ فشل بدء النظام الإنتاجي:', error.message);
      this.isRunning = false;
      this.stats.lastError = error.message;
      
      return { 
        success: false, 
        error: error.message 
      };
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
    console.log('⏹️ تم إيقاف النظام الإنتاجي');
    
    return { success: true, message: 'تم إيقاف النظام بنجاح' };
  }

  /**
   * اختبار الاتصال
   */
  async testConnection() {
    try {
      // اختبار API الوسيط
      const token = await this.waseetAPI.authenticate();
      if (!token) {
        throw new Error('فشل تسجيل الدخول للوسيط');
      }

      // اختبار قاعدة البيانات
      const { data, error } = await this.supabase
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
      return { success: false, error: 'المزامنة قيد التنفيذ بالفعل' };
    }

    const startTime = Date.now();
    this.isCurrentlySyncing = true;
    this.stats.totalSyncs++;
    
    try {
      // جلب الطلبات من الوسيط
      const waseetResult = await this.waseetAPI.getAllMerchantOrders();
      
      if (!waseetResult.success) {
        throw new Error(`فشل جلب الطلبات: ${waseetResult.error}`);
      }

      const waseetOrders = waseetResult.orders;
      
      // جلب الطلبات من قاعدة البيانات
      const dbOrders = await this.getOrdersFromDatabase();
      
      // مزامنة الطلبات
      const syncResults = await this.syncOrders(waseetOrders, dbOrders);
      
      // تحديث الإحصائيات
      const duration = Date.now() - startTime;
      this.lastSyncTime = new Date();
      this.stats.successfulSyncs++;
      this.stats.ordersUpdated += syncResults.updated;
      this.stats.ordersProcessed += waseetOrders.length;
      
      // طباعة النتائج فقط إذا كان هناك تحديثات
      if (syncResults.updated > 0) {
        console.log(`🔄 مزامنة: ${syncResults.updated} طلب محدث من ${waseetOrders.length} في ${duration}ms`);
      }
      
      return {
        success: true,
        totalOrders: waseetOrders.length,
        updated: syncResults.updated,
        matched: syncResults.matched,
        duration
      };
      
    } catch (error) {
      console.error('❌ فشل المزامنة:', error.message);
      this.stats.failedSyncs++;
      this.stats.lastError = error.message;
      
      return {
        success: false,
        error: error.message
      };
    } finally {
      this.isCurrentlySyncing = false;
    }
  }

  /**
   * جلب الطلبات من قاعدة البيانات
   */
  async getOrdersFromDatabase() {
    const { data: orders, error } = await this.supabase
      .from('orders')
      .select(`
        id,
        order_number,
        customer_name,
        status,
        waseet_order_id,
        waseet_status_id,
        waseet_status_text,
        last_status_check
      `)
      .not('waseet_order_id', 'is', null);

    if (error) {
      throw new Error(`خطأ في جلب الطلبات: ${error.message}`);
    }

    return orders || [];
  }

  /**
   * مزامنة الطلبات
   */
  async syncOrders(waseetOrders, dbOrders) {
    let updated = 0;
    let matched = 0;

    for (const waseetOrder of waseetOrders) {
      try {
        const dbOrder = dbOrders.find(order => 
          order.waseet_order_id === waseetOrder.id
        );

        if (!dbOrder) {
          continue; // تجاهل الطلبات غير الموجودة في قاعدة البيانات
        }

        // التحقق من وجود تغيير
        const waseetStatusId = parseInt(waseetOrder.status_id);
        const waseetStatusText = waseetOrder.status;

        if (dbOrder.waseet_status_id === waseetStatusId && 
            dbOrder.waseet_status_text === waseetStatusText) {
          matched++;
          continue;
        }

        // تحديث الطلب
        const { error } = await this.supabase
          .from('orders')
          .update({
            status: waseetStatusText,
            waseet_status_id: waseetStatusId,
            waseet_status_text: waseetStatusText,
            last_status_check: new Date().toISOString(),
            status_updated_at: new Date().toISOString()
          })
          .eq('id', dbOrder.id);

        if (error) {
          console.error(`❌ خطأ في تحديث الطلب ${waseetOrder.id}:`, error.message);
          continue;
        }

        updated++;
        console.log(`🔄 تحديث الطلب ${waseetOrder.id}: ${dbOrder.waseet_status_text} → ${waseetStatusText}`);
        
        // إضافة سجل في تاريخ الحالات
        await this.addStatusHistory(dbOrder.id, dbOrder.waseet_status_text, waseetStatusText);
        
      } catch (error) {
        console.error(`❌ خطأ في معالجة الطلب ${waseetOrder.id}:`, error.message);
      }
    }

    return { updated, matched };
  }

  /**
   * إضافة سجل في تاريخ الحالات
   */
  async addStatusHistory(orderId, oldStatus, newStatus) {
    try {
      await this.supabase
        .from('order_status_history')
        .insert({
          order_id: orderId,
          old_status: oldStatus,
          new_status: newStatus,
          changed_at: new Date().toISOString(),
          source: 'waseet_production_sync'
        });
    } catch (error) {
      // تجاهل أخطاء سجل التاريخ
    }
  }

  /**
   * الحصول على إحصائيات النظام
   */
  getStats() {
    const uptime = Date.now() - this.stats.uptime;
    const uptimeHours = Math.floor(uptime / (1000 * 60 * 60));
    const uptimeMinutes = Math.floor((uptime % (1000 * 60 * 60)) / (1000 * 60));

    return {
      isRunning: this.isRunning,
      isCurrentlySyncing: this.isCurrentlySyncing,
      syncInterval: this.syncInterval,
      syncIntervalSeconds: this.syncInterval / 1000,
      lastSyncTime: this.lastSyncTime,
      nextSyncIn: this.isRunning && this.lastSyncTime ? 
        Math.max(0, this.syncInterval - (Date.now() - this.lastSyncTime.getTime())) : null,
      uptime: `${uptimeHours}:${uptimeMinutes.toString().padStart(2, '0')}`,
      stats: this.stats
    };
  }

  /**
   * إعادة تشغيل النظام
   */
  async restart() {
    console.log('🔄 إعادة تشغيل النظام...');
    this.stop();
    await new Promise(resolve => setTimeout(resolve, 2000)); // انتظار ثانيتين
    return await this.start();
  }
}

module.exports = ProductionWaseetSync;
