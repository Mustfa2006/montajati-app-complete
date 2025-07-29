const OfficialWaseetAPI = require('./official_waseet_api');
const { createClient } = require('@supabase/supabase-js');

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

      // جلب الطلبات من قاعدة البيانات
      const { data: dbOrders, error } = await this.supabase
        .from('orders')
        .select('id, waseet_order_id, waseet_status_id, waseet_status_text')
        .not('waseet_order_id', 'is', null);

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

        // تحديث الطلب
        const { error: updateError } = await this.supabase
          .from('orders')
          .update({
            status: waseetStatusText,
            waseet_status_id: waseetStatusId,
            waseet_status_text: waseetStatusText,
            last_status_check: new Date().toISOString(),
            status_updated_at: new Date().toISOString()
          })
          .eq('id', dbOrder.id);

        if (!updateError) {
          updatedCount++;
          console.log(`🔄 تحديث الطلب ${waseetOrder.id}: ${waseetStatusText}`);
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
}

// إنشاء instance واحد للتطبيق
const waseetSyncInstance = new IntegratedWaseetSync();

module.exports = waseetSyncInstance;
