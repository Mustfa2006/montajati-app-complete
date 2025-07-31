// ===================================
// نظام المزامنة الذكي المحسن
// Smart Enhanced Sync Service
// ===================================

const axios = require('axios');
const cron = require('node-cron');
const { createClient } = require('@supabase/supabase-js');
const statusMapper = require('./status_mapper');
const InstantStatusUpdater = require('./instant_status_updater');
require('dotenv').config();

class SmartSyncService {
  constructor() {
    // إعداد Supabase
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    // إعدادات شركة الوسيط
    this.waseetConfig = {
      baseUrl: process.env.ALMASEET_BASE_URL || 'https://api.alwaseet-iq.net',
      username: process.env.WASEET_USERNAME,
      password: process.env.WASEET_PASSWORD,
      token: null,
      tokenExpiry: null
    };

    // إعدادات المزامنة الذكية
    this.syncConfig = {
      interval: 5, // 5 دقائق
      batchSize: 20, // عدد الطلبات في كل دفعة
      maxRetries: 3, // عدد المحاولات القصوى
      timeout: 15000, // مهلة الطلب
      backoffMultiplier: 2 // مضاعف التأخير
    };

    // إحصائيات المزامنة
    this.stats = {
      totalSynced: 0,
      totalErrors: 0,
      lastSyncTime: null,
      isRunning: false,
      currentBatch: 0,
      successRate: 100
    };

    // قائمة انتظار الطلبات
    this.syncQueue = new Set();
    this.errorQueue = new Map(); // طلبات فشلت مع عدد المحاولات

    // نظام التحديث الفوري
    this.instantUpdater = new InstantStatusUpdater();

    console.log('🧠 تم تهيئة نظام المزامنة الذكي مع التحديث الفوري');
  }

  // ===================================
  // تسجيل الدخول الذكي مع إعادة المحاولة
  // ===================================
  async smartAuthenticate() {
    try {
      // التحقق من صحة التوكن الحالي
      if (this.waseetConfig.token && this.waseetConfig.tokenExpiry) {
        const now = new Date();
        if (now < this.waseetConfig.tokenExpiry) {
          return this.waseetConfig.token;
        }
      }

      console.log('🔐 محاولة تسجيل دخول ذكي...');

      for (let attempt = 1; attempt <= this.syncConfig.maxRetries; attempt++) {
        try {
          const loginData = new URLSearchParams({
            username: this.waseetConfig.username,
            password: this.waseetConfig.password
          });

          const response = await axios.post(
            `${this.waseetConfig.baseUrl}/merchant/login`,
            loginData,
            {
              timeout: this.syncConfig.timeout,
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
              },
              maxRedirects: 0,
              validateStatus: () => true
            }
          );

          // فحص نجاح تسجيل الدخول
          if (response.status === 302 || response.status === 303 || 
              (response.headers['set-cookie'] && 
               response.headers['set-cookie'].some(cookie => cookie.includes('PHPSESSID')))) {
            
            this.waseetConfig.token = response.headers['set-cookie']?.join('; ') || '';
            this.waseetConfig.tokenExpiry = new Date(Date.now() + 24 * 60 * 60 * 1000);
            
            console.log(`✅ تسجيل دخول ناجح في المحاولة ${attempt}`);
            return this.waseetConfig.token;
          }

          throw new Error(`فشل تسجيل الدخول: ${response.status}`);

        } catch (error) {
          console.warn(`⚠️ فشل المحاولة ${attempt}/${this.syncConfig.maxRetries}: ${error.message}`);
          
          if (attempt < this.syncConfig.maxRetries) {
            const delay = 1000 * Math.pow(this.syncConfig.backoffMultiplier, attempt - 1);
            console.log(`⏳ انتظار ${delay}ms قبل المحاولة التالية...`);
            await new Promise(resolve => setTimeout(resolve, delay));
          }
        }
      }

      throw new Error('فشل في جميع محاولات تسجيل الدخول');

    } catch (error) {
      console.error('❌ خطأ في التسجيل الذكي:', error.message);
      return null;
    }
  }

  // ===================================
  // جلب الطلبات المؤهلة للمزامنة بذكاء
  // ===================================
  async getSmartSyncOrders() {
    try {
      const cutoffTime = new Date(Date.now() - (this.syncConfig.interval * 60 * 1000));

      const { data, error } = await this.supabase
        .from('orders')
        .select(`
          id,
          order_number,
          customer_name,
          primary_phone,
          status,
          waseet_order_id,
          waseet_status,
          last_status_check,
          created_at
        `)
        .not('waseet_order_id', 'is', null)
        .in('status', ['active', 'in_delivery'])
        // ✅ استبعاد الحالات النهائية - استخدام فلتر منفصل لتجنب مشكلة النص العربي
        .neq('status', 'تم التسليم للزبون')
        .neq('status', 'الغاء الطلب')
        .neq('status', 'رفض الطلب')
        .neq('status', 'delivered')
        .neq('status', 'cancelled')
        .or(`last_status_check.is.null,last_status_check.lt.${cutoffTime.toISOString()}`)
        .order('last_status_check', { ascending: true, nullsFirst: true })
        .limit(this.syncConfig.batchSize);

      if (error) {
        throw new Error(`خطأ في جلب الطلبات: ${error.message}`);
      }

      // إضافة الطلبات الفاشلة للمعالجة مرة أخرى
      const failedOrders = Array.from(this.errorQueue.keys())
        .filter(orderId => this.errorQueue.get(orderId) < this.syncConfig.maxRetries)
        .slice(0, Math.max(0, this.syncConfig.batchSize - (data?.length || 0)));

      if (failedOrders.length > 0) {
        const { data: retryData } = await this.supabase
          .from('orders')
          .select('*')
          .in('id', failedOrders);

        if (retryData) {
          data.push(...retryData);
        }
      }

      return data || [];

    } catch (error) {
      console.error('❌ خطأ في جلب الطلبات الذكي:', error.message);
      return [];
    }
  }

  // ===================================
  // فحص حالة طلب واحد بذكاء
  // ===================================
  async smartCheckOrderStatus(order) {
    try {
      const token = await this.smartAuthenticate();
      if (!token) {
        throw new Error('لا يوجد توكن صالح');
      }

      const response = await axios.get(
        `${this.waseetConfig.baseUrl}/merchant/get_order_status`,
        {
          params: { order_id: order.waseet_order_id },
          timeout: this.syncConfig.timeout,
          headers: {
            'Cookie': token,
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
          }
        }
      );

      if (response.data && response.data.status) {
        const waseetStatus = response.data.status;
        const localStatus = statusMapper.mapWaseetToLocal(waseetStatus);

        return {
          success: true,
          waseetStatus,
          localStatus,
          waseetData: response.data,
          hasChanged: localStatus !== order.status,
          timestamp: new Date().toISOString()
        };
      } else {
        throw new Error('استجابة غير صحيحة من شركة الوسيط');
      }

    } catch (error) {
      // إضافة الطلب لقائمة الأخطاء
      const currentRetries = this.errorQueue.get(order.id) || 0;
      this.errorQueue.set(order.id, currentRetries + 1);

      return {
        success: false,
        error: error.message,
        retryCount: currentRetries + 1
      };
    }
  }

  // ===================================
  // تحديث حالة الطلب بذكاء
  // ===================================
  async smartUpdateOrderStatus(order, statusResult) {
    try {
      // ✅ فحص إذا كانت الحالة الحالية نهائية
      const finalStatuses = ['تم التسليم للزبون', 'الغاء الطلب', 'رفض الطلب', 'delivered', 'cancelled'];
      if (finalStatuses.includes(order.status)) {
        console.log(`⏹️ تم تجاهل تحديث الطلب ${order.order_number} - الحالة نهائية: ${order.status}`);
        return false;
      }

      const now = new Date().toISOString();

      // بدء معاملة قاعدة البيانات
      const { error: updateError } = await this.supabase
        .from('orders')
        .update({
          status: statusResult.localStatus,
          waseet_status: statusResult.waseetStatus,
          waseet_data: statusResult.waseetData,
          last_status_check: now,
          status_updated_at: now,
          updated_at: now
        })
        .eq('id', order.id);

      if (updateError) {
        throw new Error(`خطأ في تحديث الطلب: ${updateError.message}`);
      }

      // إضافة سجل في تاريخ الحالات
      await this.addStatusHistory(order, statusResult);

      // إزالة الطلب من قائمة الأخطاء إذا نجح
      this.errorQueue.delete(order.id);

      console.log(`✅ تم تحديث الطلب ${order.order_number}: ${order.status} → ${statusResult.localStatus}`);
      return true;

    } catch (error) {
      console.error(`❌ فشل في تحديث الطلب ${order.order_number}:`, error.message);
      return false;
    }
  }

  // ===================================
  // إضافة سجل في تاريخ الحالات
  // ===================================
  async addStatusHistory(order, statusResult) {
    try {
      await this.supabase
        .from('order_status_history')
        .insert({
          order_id: order.id,
          old_status: order.status,
          new_status: statusResult.localStatus,
          changed_by: 'smart_sync_service',
          change_reason: 'تحديث تلقائي من شركة الوسيط',
          waseet_response: statusResult.waseetData
        });
    } catch (error) {
      console.warn('⚠️ تحذير: فشل في إضافة سجل التاريخ:', error.message);
    }
  }

  // ===================================
  // دورة المزامنة الذكية
  // ===================================
  async runSmartSyncCycle() {
    if (this.stats.isRunning) {
      console.log('⏳ دورة مزامنة قيد التشغيل، تخطي...');
      return;
    }

    this.stats.isRunning = true;
    this.stats.currentBatch++;
    const startTime = new Date();

    try {
      console.log(`🚀 بدء دورة المزامنة الذكية #${this.stats.currentBatch}`);

      // جلب الطلبات
      const orders = await this.getSmartSyncOrders();
      
      if (orders.length === 0) {
        console.log('📭 لا توجد طلبات تحتاج مزامنة');
        return;
      }

      console.log(`📊 معالجة ${orders.length} طلب...`);

      let successCount = 0;
      let errorCount = 0;

      // معالجة الطلبات بالتوازي (مع تحديد العدد)
      const batchPromises = orders.map(async (order) => {
        try {
          const statusResult = await this.smartCheckOrderStatus(order);

          if (statusResult.success) {
            // تحديث وقت آخر فحص
            await this.supabase
              .from('orders')
              .update({
                last_status_check: new Date().toISOString(),
                waseet_data: statusResult.waseetData
              })
              .eq('id', order.id);

            if (statusResult.hasChanged) {
              // استخدام نظام التحديث الفوري
              const updateResult = await this.instantUpdater.instantUpdateOrderStatus(
                order.id,
                statusResult.waseetStatus,
                statusResult.waseetData
              );

              if (updateResult.success) {
                successCount++;
              } else {
                errorCount++;
              }
            }
          } else {
            errorCount++;
          }
        } catch (error) {
          console.error(`❌ خطأ في معالجة الطلب ${order.order_number}:`, error.message);
          errorCount++;
        }
      });

      await Promise.all(batchPromises);

      // تحديث الإحصائيات
      this.stats.totalSynced += successCount;
      this.stats.totalErrors += errorCount;
      this.stats.lastSyncTime = new Date().toISOString();
      this.stats.successRate = this.stats.totalSynced / (this.stats.totalSynced + this.stats.totalErrors) * 100;

      const duration = new Date() - startTime;
      console.log(`✅ انتهت دورة المزامنة #${this.stats.currentBatch} في ${duration}ms`);
      console.log(`📊 النتائج: ${successCount} نجح، ${errorCount} فشل`);

    } catch (error) {
      console.error('❌ خطأ في دورة المزامنة الذكية:', error.message);
      this.stats.totalErrors++;
    } finally {
      this.stats.isRunning = false;
    }
  }

  // ===================================
  // بدء المزامنة التلقائية الذكية
  // ===================================
  startSmartAutoSync() {
    console.log(`🧠 بدء المزامنة التلقائية الذكية كل ${this.syncConfig.interval} دقائق`);

    // تشغيل دورة أولى بعد 10 ثوان
    setTimeout(() => {
      this.runSmartSyncCycle();
    }, 10000);

    // جدولة المزامنة كل 5 دقائق
    cron.schedule(`*/${this.syncConfig.interval} * * * *`, () => {
      this.runSmartSyncCycle();
    });

    // تنظيف قائمة الأخطاء كل ساعة
    cron.schedule('0 * * * *', () => {
      this.cleanupErrorQueue();
    });

    console.log('✅ تم تفعيل المزامنة التلقائية الذكية');
  }

  // ===================================
  // الحصول على إحصائيات مفصلة
  // ===================================
  getDetailedStats() {
    return {
      sync_service: {
        ...this.stats,
        config: this.syncConfig,
        errorQueueSize: this.errorQueue.size,
        syncQueueSize: this.syncQueue.size,
        uptime: this.stats.lastSyncTime ?
          new Date() - new Date(this.stats.lastSyncTime) : 0
      },
      instant_updater: this.instantUpdater.getUpdateStats()
    };
  }

  // ===================================
  // تنظيف قائمة الأخطاء
  // ===================================
  cleanupErrorQueue() {
    const maxAge = 24 * 60 * 60 * 1000; // 24 ساعة
    const cutoff = Date.now() - maxAge;

    for (const [orderId, retryCount] of this.errorQueue.entries()) {
      if (retryCount >= this.syncConfig.maxRetries) {
        this.errorQueue.delete(orderId);
        console.log(`🧹 تم حذف الطلب ${orderId} من قائمة الأخطاء (تجاوز الحد الأقصى)`);
      }
    }
  }
}

module.exports = SmartSyncService;
