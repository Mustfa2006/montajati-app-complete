const OfficialWaseetAPI = require('./official_waseet_api');
const { createClient } = require('@supabase/supabase-js');

/**
 * نظام المزامنة الحقيقي مع الوسيط - حسب التوثيق الرسمي
 * Real Waseet Sync System - Official API
 */
class RealWaseetSyncSystem {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
    
    // استخدام الحساب الجديد
    this.waseetAPI = new OfficialWaseetAPI(
      'mustfaabd',
      '65888304'
    );
    
    this.isRunning = false;
    this.syncInterval = 3 * 60 * 1000; // كل 3 دقائق
    this.syncIntervalId = null;
    this.lastSyncTime = null;
    this.stats = {
      totalSyncs: 0,
      successfulSyncs: 0,
      failedSyncs: 0,
      ordersUpdated: 0,
      lastError: null
    };
    
    console.log('🚀 تم تهيئة نظام المزامنة الحقيقي مع API الرسمي');
  }

  /**
   * بدء النظام الكامل
   */
  async startRealTimeSync() {
    try {
      console.log('🔄 === بدء نظام المزامنة الحقيقي ===');
      
      if (this.isRunning) {
        console.log('⚠️ النظام يعمل بالفعل');
        return;
      }

      this.isRunning = true;
      
      // مزامنة فورية أولى
      await this.performFullSync();
      
      // بدء المزامنة الدورية
      this.syncIntervalId = setInterval(async () => {
        await this.performFullSync();
      }, this.syncInterval);
      
      console.log(`✅ نظام المزامنة يعمل - كل ${this.syncInterval / 60000} دقيقة`);
      
    } catch (error) {
      console.error('❌ فشل بدء نظام المزامنة:', error.message);
      this.isRunning = false;
      this.stats.lastError = error.message;
    }
  }

  /**
   * إيقاف النظام
   */
  stopRealTimeSync() {
    if (this.syncIntervalId) {
      clearInterval(this.syncIntervalId);
      this.syncIntervalId = null;
    }
    this.isRunning = false;
    console.log('⏹️ تم إيقاف نظام المزامنة');
  }

  /**
   * تنفيذ مزامنة شاملة
   */
  async performFullSync() {
    const startTime = Date.now();
    this.stats.totalSyncs++;
    
    try {
      console.log('\n🔄 === بدء المزامنة الشاملة ===');
      
      // 1. جلب جميع الطلبات من الوسيط
      const waseetResult = await this.waseetAPI.getAllMerchantOrders();
      
      if (!waseetResult.success) {
        throw new Error(`فشل جلب الطلبات من الوسيط: ${waseetResult.error}`);
      }

      const waseetOrders = waseetResult.orders;
      console.log(`📊 تم جلب ${waseetOrders.length} طلب من الوسيط`);

      // 2. جلب الطلبات من قاعدة البيانات
      const dbOrders = await this.getOrdersFromDatabase();
      console.log(`📋 تم جلب ${dbOrders.length} طلب من قاعدة البيانات`);

      // 3. مزامنة الطلبات
      let updatedCount = 0;
      let matchedCount = 0;
      let newCount = 0;

      for (const waseetOrder of waseetOrders) {
        try {
          const result = await this.syncSingleOrder(waseetOrder, dbOrders);
          
          if (result === 'updated') updatedCount++;
          else if (result === 'matched') matchedCount++;
          else if (result === 'new') newCount++;
          
        } catch (error) {
          console.error(`❌ خطأ في مزامنة الطلب ${waseetOrder.id}:`, error.message);
        }
      }

      const duration = Date.now() - startTime;
      this.lastSyncTime = new Date();
      this.stats.successfulSyncs++;
      this.stats.ordersUpdated += updatedCount;
      
      console.log(`✅ انتهت المزامنة: ${updatedCount} محدث، ${matchedCount} مطابق، ${newCount} جديد في ${duration}ms`);
      
      return {
        success: true,
        totalWaseetOrders: waseetOrders.length,
        totalDbOrders: dbOrders.length,
        updated: updatedCount,
        matched: matchedCount,
        new: newCount,
        duration
      };
      
    } catch (error) {
      console.error('❌ فشل المزامنة الشاملة:', error.message);
      this.stats.failedSyncs++;
      this.stats.lastError = error.message;
      
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * جلب الطلبات من قاعدة البيانات
   */
  async getOrdersFromDatabase() {
    try {
      const { data: orders, error } = await this.supabase
        .from('orders')
        .select(`
          id,
          order_number,
          customer_name,
          status,
          waseet_order_id,
          waseet_status,
          waseet_status_id,
          waseet_status_text,
          last_status_check,
          created_at
        `)
        .not('waseet_order_id', 'is', null);

      if (error) {
        throw new Error(`خطأ في جلب الطلبات: ${error.message}`);
      }

      return orders || [];
      
    } catch (error) {
      console.error('❌ خطأ في جلب الطلبات من قاعدة البيانات:', error.message);
      return [];
    }
  }

  /**
   * مزامنة طلب واحد
   */
  async syncSingleOrder(waseetOrder, dbOrders) {
    try {
      // البحث عن الطلب في قاعدة البيانات
      const dbOrder = dbOrders.find(order => 
        order.waseet_order_id === waseetOrder.id
      );

      if (!dbOrder) {
        // طلب جديد - قد نحتاج لإضافته
        console.log(`➕ طلب جديد في الوسيط: ${waseetOrder.id}`);
        return 'new';
      }

      // مقارنة الحالات
      const waseetStatusId = waseetOrder.status_id;
      const waseetStatusText = waseetOrder.status;
      const waseetUpdatedAt = waseetOrder.updated_at;

      const currentStatusId = dbOrder.waseet_status_id;
      const currentStatusText = dbOrder.waseet_status_text;

      // التحقق من وجود تغيير
      if (currentStatusId === waseetStatusId && currentStatusText === waseetStatusText) {
        return 'matched';
      }

      // تحديث الطلب في قاعدة البيانات
      const { error } = await this.supabase
        .from('orders')
        .update({
          status: waseetStatusText,
          waseet_status: 'active',
          waseet_status_id: parseInt(waseetStatusId),
          waseet_status_text: waseetStatusText,
          last_status_check: new Date().toISOString(),
          status_updated_at: new Date().toISOString()
        })
        .eq('id', dbOrder.id);

      if (error) {
        throw new Error(`خطأ في تحديث الطلب: ${error.message}`);
      }

      console.log(`🔄 تم تحديث الطلب ${waseetOrder.id}: ${currentStatusText} → ${waseetStatusText}`);
      
      // إضافة سجل في تاريخ الحالات
      await this.addStatusHistory(dbOrder.id, currentStatusText, waseetStatusText);
      
      return 'updated';
      
    } catch (error) {
      console.error(`❌ خطأ في مزامنة الطلب ${waseetOrder.id}:`, error.message);
      throw error;
    }
  }

  /**
   * إضافة سجل في تاريخ الحالات
   */
  async addStatusHistory(orderId, oldStatus, newStatus) {
    try {
      const { error } = await this.supabase
        .from('order_status_history')
        .insert({
          order_id: orderId,
          old_status: oldStatus,
          new_status: newStatus,
          changed_at: new Date().toISOString(),
          source: 'waseet_official_api'
        });

      if (error && error.code !== '42P01') { // تجاهل خطأ عدم وجود الجدول
        console.error('❌ خطأ في إضافة سجل الحالة:', error.message);
      }
    } catch (error) {
      // تجاهل الأخطاء في سجل التاريخ
    }
  }

  /**
   * الحصول على إحصائيات النظام
   */
  getSystemStats() {
    return {
      isRunning: this.isRunning,
      syncInterval: this.syncInterval,
      syncIntervalMinutes: this.syncInterval / 60000,
      lastSyncTime: this.lastSyncTime,
      nextSyncIn: this.isRunning && this.lastSyncTime ? 
        Math.max(0, this.syncInterval - (Date.now() - this.lastSyncTime.getTime())) : null,
      stats: this.stats
    };
  }
}

module.exports = RealWaseetSyncSystem;
