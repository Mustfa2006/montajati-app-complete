const OfficialWaseetAPI = require('./official_waseet_api');
const { createClient } = require('@supabase/supabase-js');

/**
 * نظام المزامنة الحقيقي والمستمر مع الوسيط
 * Real-time Waseet Sync System
 */
class RealTimeWaseetSync {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
    
    this.waseetAPI = new OfficialWaseetAPI(
      process.env.WASEET_USERNAME,
      process.env.WASEET_PASSWORD
    );
    
    this.isRunning = false;
    this.syncInterval = 2 * 60 * 1000; // كل دقيقتين
    this.syncIntervalId = null;
    this.lastSyncTime = null;
    
    console.log('🚀 تم تهيئة نظام المزامنة الحقيقي مع الوسيط');
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
    try {
      const startTime = Date.now();
      console.log('\n🔄 === بدء المزامنة الشاملة ===');
      
      // 1. جلب الطلبات المرسلة للوسيط
      const ordersToSync = await this.getOrdersToSync();
      
      if (ordersToSync.length === 0) {
        console.log('📭 لا توجد طلبات للمزامنة');
        return {
          success: true,
          totalOrders: 0,
          updated: 0,
          errors: 0,
          duration: Date.now() - startTime
        };
      }

      console.log(`📊 تم العثور على ${ordersToSync.length} طلب للمزامنة`);
      
      // 2. مزامنة كل طلب
      let updatedCount = 0;
      let errorCount = 0;
      
      for (const order of ordersToSync) {
        try {
          const updated = await this.syncSingleOrder(order);
          if (updated) updatedCount++;
        } catch (error) {
          console.error(`❌ خطأ في مزامنة الطلب ${order.waseet_order_id}:`, error.message);
          errorCount++;
        }
        
        // توقف قصير لتجنب التحميل الزائد
        await this.sleep(500);
      }
      
      const duration = Date.now() - startTime;
      this.lastSyncTime = new Date();
      
      console.log(`✅ انتهت المزامنة: ${updatedCount} محدث، ${errorCount} خطأ في ${duration}ms`);
      
      return {
        success: true,
        totalOrders: ordersToSync.length,
        updated: updatedCount,
        errors: errorCount,
        duration
      };
      
    } catch (error) {
      console.error('❌ فشل المزامنة الشاملة:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * جلب الطلبات التي تحتاج مزامنة
   */
  async getOrdersToSync() {
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
        .not('waseet_order_id', 'is', null)
        // ✅ استبعاد الحالات النهائية التي لا تحتاج مراقبة
        .not('status', 'in', ['تم التسليم للزبون', 'الغاء الطلب', 'رفض الطلب', 'delivered', 'cancelled'])
        .order('created_at', { ascending: false })
        .limit(50); // حد أقصى 50 طلب في المرة الواحدة

      if (error) {
        throw new Error(`خطأ في جلب الطلبات: ${error.message}`);
      }

      return orders || [];
      
    } catch (error) {
      console.error('❌ خطأ في جلب الطلبات للمزامنة:', error.message);
      return [];
    }
  }

  /**
   * مزامنة طلب واحد
   */
  async syncSingleOrder(order) {
    try {
      console.log(`🔍 مزامنة الطلب ${order.waseet_order_id} (${order.order_number})`);
      
      // جلب الحالة الحقيقية من الوسيط
      const statusResult = await this.getOrderStatusFromWaseet(order.waseet_order_id);
      
      if (!statusResult.success) {
        console.log(`⚠️ فشل جلب حالة الطلب ${order.waseet_order_id}: ${statusResult.error}`);
        return false;
      }

      const newStatus = statusResult.status;
      const newStatusId = statusResult.statusId;
      const newStatusText = statusResult.statusText;
      
      // التحقق من وجود تغيير
      if (order.waseet_status_id === newStatusId && order.status === newStatusText) {
        console.log(`✅ الطلب ${order.waseet_order_id} لم يتغير`);
        return false;
      }

      // تحديث الطلب في قاعدة البيانات
      const { error } = await this.supabase
        .from('orders')
        .update({
          status: newStatusText,
          waseet_status: newStatus,
          waseet_status_id: newStatusId,
          waseet_status_text: newStatusText,
          last_status_check: new Date().toISOString(),
          status_updated_at: new Date().toISOString()
        })
        .eq('id', order.id);

      if (error) {
        throw new Error(`خطأ في تحديث الطلب: ${error.message}`);
      }

      console.log(`🔄 تم تحديث الطلب ${order.waseet_order_id}: ${order.status} → ${newStatusText}`);
      
      // إضافة سجل في تاريخ الحالات
      await this.addStatusHistory(order.id, order.status, newStatusText);
      
      return true;
      
    } catch (error) {
      console.error(`❌ خطأ في مزامنة الطلب ${order.waseet_order_id}:`, error.message);
      return false;
    }
  }

  /**
   * جلب حالة طلب من الوسيط باستخدام Web Scraping الحقيقي
   */
  async getOrderStatusFromWaseet(waseetOrderId) {
    try {
      console.log(`📡 جلب حالة الطلب ${waseetOrderId} من الوسيط (Web Scraping)...`);

      // استخدام Web Scraper الموجود
      const RealWaseetFetcher = require('../sync/real_waseet_fetcher');
      const fetcher = new RealWaseetFetcher();

      // جلب جميع الطلبات من صفحة التاجر
      const result = await fetcher.fetchAllOrderStatuses();

      if (!result.success) {
        throw new Error(`فشل جلب الطلبات: ${result.error}`);
      }

      // البحث عن الطلب المحدد
      const order = result.orders.find(o => o.order_id === waseetOrderId);

      if (!order) {
        return {
          success: false,
          error: `لم يتم العثور على الطلب ${waseetOrderId} في صفحة التاجر`
        };
      }

      console.log(`✅ تم العثور على الطلب ${waseetOrderId}: ${order.status_text}`);

      return {
        success: true,
        status: 'active',
        statusId: order.status_id,
        statusText: order.status_text,
        clientName: order.client_name,
        updatedAt: order.updated_at,
        price: order.price,
        cityName: order.city_name,
        regionName: order.region_name
      };

    } catch (error) {
      console.error(`❌ خطأ في جلب حالة الطلب ${waseetOrderId}:`, error.message);
      return {
        success: false,
        error: error.message
      };
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
          source: 'waseet_sync'
        });

      if (error) {
        console.error('❌ خطأ في إضافة سجل الحالة:', error.message);
      }
    } catch (error) {
      console.error('❌ خطأ في إضافة سجل الحالة:', error.message);
    }
  }

  /**
   * توقف لفترة محددة
   */
  sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * الحصول على إحصائيات النظام
   */
  getSystemStats() {
    return {
      isRunning: this.isRunning,
      syncInterval: this.syncInterval,
      lastSyncTime: this.lastSyncTime,
      nextSyncIn: this.isRunning ? 
        Math.max(0, this.syncInterval - (Date.now() - (this.lastSyncTime?.getTime() || 0))) : null
    };
  }
}

module.exports = RealTimeWaseetSync;
