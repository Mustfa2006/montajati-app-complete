// ===================================
// خدمة المزامنة الإنتاجية الرئيسية
// Main Production Sync Service
// ===================================

const { createClient } = require('@supabase/supabase-js');
const config = require('./config');
const logger = require('./logger');
const ProductionWaseetService = require('./waseet_service');

class ProductionSyncService {
  constructor() {
    this.config = config.get('sync');
    this.supabase = createClient(
      config.get('database', 'supabase').url,
      config.get('database', 'supabase').serviceRoleKey
    );
    
    this.waseetService = new ProductionWaseetService();
    this.isRunning = false;
    this.syncInterval = null;
    this.lastSyncTime = null;
    this.syncCount = 0;
    
    // إحصائيات المزامنة
    this.stats = {
      totalSyncs: 0,
      successfulSyncs: 0,
      failedSyncs: 0,
      ordersProcessed: 0,
      ordersUpdated: 0,
      averageSyncTime: 0,
      lastSyncDuration: 0,
      errors: []
    };

    logger.info('🔄 تم تهيئة خدمة المزامنة الإنتاجية');
  }

  /**
   * بدء خدمة المزامنة
   */
  async start() {
    if (this.isRunning) {
      logger.warn('⚠️ خدمة المزامنة تعمل بالفعل');
      return;
    }

    try {
      // بدء خدمة المزامنة بصمت
      
      // التحقق من التكوين
      await this.validateConfiguration();
      
      // إجراء مزامنة أولية
      await this.performSync();
      
      // بدء المزامنة الدورية
      this.startPeriodicSync();
      
      this.isRunning = true;
      // تم بدء خدمة المزامنة بصمت
      
    } catch (error) {
      logger.error('❌ فشل بدء خدمة المزامنة', {
        error: error.message
      });
      throw error;
    }
  }

  /**
   * إيقاف خدمة المزامنة
   */
  async stop() {
    if (!this.isRunning) {
      logger.warn('⚠️ خدمة المزامنة متوقفة بالفعل');
      return;
    }

    logger.info('🛑 إيقاف خدمة المزامنة');
    
    if (this.syncInterval) {
      clearInterval(this.syncInterval);
      this.syncInterval = null;
    }
    
    this.isRunning = false;
    logger.info('✅ تم إيقاف خدمة المزامنة');
  }

  /**
   * التحقق من صحة التكوين
   */
  async validateConfiguration() {
    // التحقق من صحة التكوين بصمت
    
    // التحقق من الاتصال بقاعدة البيانات
    const { error: dbError } = await this.supabase
      .from('orders')
      .select('id')
      .limit(1);
    
    if (dbError) {
      throw new Error(`فشل الاتصال بقاعدة البيانات: ${dbError.message}`);
    }
    
    // التحقق من الاتصال بشركة الوسيط
    await this.waseetService.authenticate();
    
    // تم التحقق من صحة التكوين بصمت
  }

  /**
   * بدء المزامنة الدورية
   */
  startPeriodicSync() {
    this.syncInterval = setInterval(async () => {
      try {
        await this.performSync();
      } catch (error) {
        logger.error('❌ خطأ في المزامنة الدورية', {
          error: error.message
        });
      }
    }, this.config.interval);
  }

  /**
   * إجراء مزامنة كاملة
   */
  async performSync() {
    if (!this.config.enabled) {
      logger.info('⏸️ المزامنة معطلة في التكوين');
      return;
    }

    const operationId = await logger.startOperation('full_sync');
    const startTime = Date.now();
    
    try {
      this.syncCount++;
      this.stats.totalSyncs++;
      
      // جلب الطلبات من قاعدة البيانات
      const localOrders = await this.getOrdersToSync();
      
      if (localOrders.length === 0) {
        logger.info('📭 لا توجد طلبات للمزامنة');
        await this.logSyncResult(operationId, true, 0, 0, 0);
        return;
      }

      // جلب الحالات من شركة الوسيط
      const waseetData = await this.waseetService.fetchAllOrderStatuses();
      
      if (!waseetData.success) {
        throw new Error(`فشل جلب البيانات من الوسيط: ${waseetData.error}`);
      }

      // تم جلب الطلبات من الوسيط بصمت
      
      // مزامنة الطلبات
      const syncResults = await this.syncOrders(localOrders, waseetData.orders);
      
      // تسجيل النتائج
      const duration = Date.now() - startTime;
      await this.logSyncResult(operationId, true, localOrders.length, 
        syncResults.updated, duration);
      
      this.updateStats(true, localOrders.length, syncResults.updated, duration);
      this.lastSyncTime = new Date().toISOString();
      
      // رسالة مبسطة للنتيجة
      if (syncResults.updated > 0) {
        logger.info(`✅ مزامنة ${this.syncCount}: تم تحديث ${syncResults.updated} من ${localOrders.length} طلب`);
      } else {
        logger.info(`✅ مزامنة ${this.syncCount}: فحص ${localOrders.length} طلب - لا توجد تحديثات`);
      }

    } catch (error) {
      const duration = Date.now() - startTime;
      
      await logger.error('❌ فشلت المزامنة', {
        error: error.message,
        syncCount: this.syncCount,
        duration
      });
      
      await this.logSyncResult(operationId, false, 0, 0, duration, error.message);
      this.updateStats(false, 0, 0, duration, error.message);
      
      throw error;
    }
  }

  /**
   * جلب الطلبات التي تحتاج مزامنة
   */
  async getOrdersToSync() {
    try {
      const { data, error } = await this.supabase
        .from('orders')
        .select('id, order_number, waseet_order_id, status, waseet_status, last_status_check')
        .not('waseet_order_id', 'is', null)
        // ✅ استبعاد الحالات النهائية - استخدام فلتر منفصل لتجنب مشكلة النص العربي
        .neq('status', 'تم التسليم للزبون')
        .neq('status', 'الغاء الطلب')
        .neq('status', 'رفض الطلب')
        .neq('status', 'delivered')
        .neq('status', 'cancelled')
        .order('created_at', { ascending: false });

      if (error) {
        throw new Error(`فشل جلب الطلبات: ${error.message}`);
      }

      // فلترة الطلبات التي تحتاج مزامنة
      const ordersToSync = data.filter(order => {
        // مزامنة جميع الطلبات في المزامنة الأولى
        if (!this.lastSyncTime) {
          return true;
        }

        // مزامنة الطلبات التي لم يتم فحصها مؤخراً
        if (!order.last_status_check) {
          return true;
        }

        const lastCheck = new Date(order.last_status_check);
        const timeSinceCheck = Date.now() - lastCheck.getTime();
        const maxAge = this.config.interval * 2; // ضعف فترة المزامنة

        return timeSinceCheck > maxAge;
      });

      return ordersToSync;

    } catch (error) {
      logger.error('❌ فشل جلب الطلبات للمزامنة', {
        error: error.message
      });
      throw error;
    }
  }

  /**
   * مزامنة الطلبات
   */
  async syncOrders(localOrders, waseetOrders) {
    const results = {
      processed: 0,
      updated: 0,
      errors: 0,
      details: []
    };

    // إنشاء خريطة للطلبات من الوسيط
    const waseetOrdersMap = new Map();
    waseetOrders.forEach(order => {
      waseetOrdersMap.set(order.order_id.toString(), order);
    });

    // معالجة الطلبات بدفعات
    const batches = this.createBatches(localOrders, this.config.batchSize);
    
    for (const batch of batches) {
      const batchResults = await this.processBatch(batch, waseetOrdersMap);
      
      results.processed += batchResults.processed;
      results.updated += batchResults.updated;
      results.errors += batchResults.errors;
      results.details.push(...batchResults.details);
    }

    return results;
  }

  /**
   * إنشاء دفعات من الطلبات
   */
  createBatches(orders, batchSize) {
    const batches = [];
    for (let i = 0; i < orders.length; i += batchSize) {
      batches.push(orders.slice(i, i + batchSize));
    }
    return batches;
  }

  /**
   * معالجة دفعة من الطلبات
   */
  async processBatch(batch, waseetOrdersMap) {
    const results = {
      processed: 0,
      updated: 0,
      errors: 0,
      details: []
    };

    const promises = batch.map(async (localOrder) => {
      try {
        results.processed++;
        
        const waseetOrder = waseetOrdersMap.get(localOrder.waseet_order_id.toString());
        
        if (!waseetOrder) {
          // طلب غير موجود في الوسيط (طبيعي للطلبات القديمة)
          return;
        }

        // التحقق من تغيير الحالة
        const needsUpdate = this.shouldUpdateOrder(localOrder, waseetOrder);
        
        if (needsUpdate) {
          await this.updateOrderStatus(localOrder, waseetOrder);
          results.updated++;
          
          results.details.push({
            orderId: localOrder.id,
            orderNumber: localOrder.order_number,
            oldStatus: localOrder.status,
            newStatus: waseetOrder.local_status,
            waseetStatus: waseetOrder.status_text
          });
        }

        // تحديث وقت آخر فحص
        await this.updateLastStatusCheck(localOrder.id);

      } catch (error) {
        results.errors++;
        logger.error(`❌ خطأ في معالجة الطلب ${localOrder.order_number}`, {
          error: error.message,
          orderId: localOrder.id
        });
      }
    });

    await Promise.all(promises);
    return results;
  }

  /**
   * التحقق من ضرورة تحديث الطلب
   */
  shouldUpdateOrder(localOrder, waseetOrder) {
    // التحقق من تغيير الحالة المحلية
    if (localOrder.status !== waseetOrder.local_status) {
      return true;
    }

    // التحقق من تغيير حالة الوسيط
    if (localOrder.waseet_status !== waseetOrder.status_text) {
      return true;
    }

    return false;
  }

  /**
   * تحديث حالة الطلب
   */
  async updateOrderStatus(localOrder, waseetOrder) {
    try {
      // ✅ فحص إذا كانت الحالة الحالية نهائية
      const finalStatuses = ['تم التسليم للزبون', 'الغاء الطلب', 'رفض الطلب', 'delivered', 'cancelled'];
      if (finalStatuses.includes(localOrder.status)) {
        console.log(`⏹️ تم تجاهل تحديث الطلب ${localOrder.order_number} - الحالة نهائية: ${localOrder.status}`);
        return false;
      }

      const updateData = {
        status: waseetOrder.local_status,
        waseet_status: waseetOrder.status_text,
        waseet_data: {
          status_id: waseetOrder.status_id,
          status_text: waseetOrder.status_text,
          updated_at: waseetOrder.updated_at,
          sync_timestamp: new Date().toISOString()
        },
        updated_at: new Date().toISOString()
      };

      const { error } = await this.supabase
        .from('orders')
        .update(updateData)
        .eq('id', localOrder.id);

      if (error) {
        throw new Error(`فشل تحديث الطلب: ${error.message}`);
      }

      // تسجيل التغيير في التاريخ
      await this.logStatusChange(localOrder, waseetOrder);

      logger.info(`✅ تم تحديث الطلب ${localOrder.order_number}: ${localOrder.status} → ${waseetOrder.local_status}`);

    } catch (error) {
      logger.error(`❌ فشل تحديث الطلب ${localOrder.order_number}`, {
        error: error.message,
        orderId: localOrder.id
      });
      throw error;
    }
  }

  /**
   * تسجيل تغيير الحالة في التاريخ
   */
  async logStatusChange(localOrder, waseetOrder) {
    try {
      await this.supabase
        .from('order_status_history')
        .insert({
          order_id: localOrder.id,
          old_status: localOrder.status,
          new_status: waseetOrder.local_status,
          old_waseet_status: localOrder.waseet_status,
          new_waseet_status: waseetOrder.status_text,
          changed_by: 'production_sync_service',
          change_reason: `مزامنة تلقائية: ${localOrder.waseet_status || 'غير محدد'} → ${waseetOrder.status_text}`,
          waseet_data: {
            status_id: waseetOrder.status_id,
            status_text: waseetOrder.status_text,
            sync_timestamp: new Date().toISOString()
          }
        });

    } catch (error) {
      logger.warn('⚠️ فشل تسجيل تغيير الحالة في التاريخ', {
        error: error.message,
        orderId: localOrder.id
      });
    }
  }

  /**
   * تحديث وقت آخر فحص
   */
  async updateLastStatusCheck(orderId) {
    try {
      await this.supabase
        .from('orders')
        .update({ last_status_check: new Date().toISOString() })
        .eq('id', orderId);

    } catch (error) {
      logger.warn('⚠️ فشل تحديث وقت آخر فحص', {
        error: error.message,
        orderId
      });
    }
  }

  /**
   * تسجيل نتيجة المزامنة
   */
  async logSyncResult(operationId, success, processed, updated, duration, error = null) {
    try {
      await this.supabase
        .from('sync_logs')
        .insert({
          operation_id: operationId,
          sync_type: 'full_sync',
          success,
          orders_processed: processed,
          orders_updated: updated,
          duration_ms: duration,
          error_message: error,
          sync_timestamp: new Date().toISOString(),
          service_version: config.get('system', 'version')
        });

      await logger.endOperation(operationId, 'full_sync', success, {
        processed,
        updated,
        duration,
        error
      });

    } catch (logError) {
      logger.warn('⚠️ فشل تسجيل نتيجة المزامنة', {
        error: logError.message
      });
    }
  }

  /**
   * تحديث الإحصائيات
   */
  updateStats(success, processed, updated, duration, error = null) {
    if (success) {
      this.stats.successfulSyncs++;
    } else {
      this.stats.failedSyncs++;
      if (error) {
        this.stats.errors.push({
          timestamp: new Date().toISOString(),
          error,
          syncCount: this.syncCount
        });
        
        // الاحتفاظ بآخر 10 أخطاء فقط
        if (this.stats.errors.length > 10) {
          this.stats.errors = this.stats.errors.slice(-10);
        }
      }
    }

    this.stats.ordersProcessed += processed;
    this.stats.ordersUpdated += updated;
    this.stats.lastSyncDuration = duration;

    // تحديث متوسط وقت المزامنة
    if (this.stats.averageSyncTime === 0) {
      this.stats.averageSyncTime = duration;
    } else {
      this.stats.averageSyncTime = 
        (this.stats.averageSyncTime + duration) / 2;
    }
  }

  /**
   * الحصول على حالة الخدمة
   */
  getStatus() {
    return {
      isRunning: this.isRunning,
      syncCount: this.syncCount,
      lastSyncTime: this.lastSyncTime,
      stats: this.stats,
      config: {
        enabled: this.config.enabled,
        interval: this.config.interval,
        batchSize: this.config.batchSize
      },
      waseetService: this.waseetService.getStats()
    };
  }

  /**
   * إعادة تعيين الإحصائيات
   */
  resetStats() {
    this.stats = {
      totalSyncs: 0,
      successfulSyncs: 0,
      failedSyncs: 0,
      ordersProcessed: 0,
      ordersUpdated: 0,
      averageSyncTime: 0,
      lastSyncDuration: 0,
      errors: []
    };
    
    this.syncCount = 0;
    this.waseetService.resetStats();
    
    logger.info('📊 تم إعادة تعيين إحصائيات المزامنة');
  }
}

module.exports = ProductionSyncService;
