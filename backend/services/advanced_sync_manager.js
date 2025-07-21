// ===================================
// نظام المزامنة المتقدم مع شركة الوسيط
// Advanced Sync Manager for Waseet Integration
// ===================================

const axios = require('axios');
const { createClient } = require('@supabase/supabase-js');
const EventEmitter = require('events');

class AdvancedSyncManager extends EventEmitter {
  constructor() {
    super();
    
    // إعدادات النظام
    this.config = {
      syncInterval: 10 * 60 * 1000,      // 10 دقائق
      batchSize: 20,                     // عدد الطلبات في الدفعة
      maxRetries: 3,                     // عدد المحاولات القصوى
      retryDelay: 60000,                 // تأخير إعادة المحاولة (دقيقة)
      healthCheckInterval: 5 * 60 * 1000, // فحص الصحة كل 5 دقائق
      tokenRefreshInterval: 30 * 60 * 1000, // تحديث التوكن كل 30 دقيقة
    };

    // حالة النظام
    this.state = {
      isRunning: false,
      isInitialized: false,
      lastSyncAt: null,
      totalSynced: 0,
      totalErrors: 0,
      currentToken: null,
      tokenExpiresAt: null,
    };

    // معرفات العمليات
    this.intervals = {
      sync: null,
      healthCheck: null,
      tokenRefresh: null,
    };

    // إعداد قاعدة البيانات
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    // إعدادات API الوسيط (تم إصلاح الرابط الصحيح)
    this.waseetConfig = {
      baseURL: 'https://merchant.alwaseet-iq.net',
      username: process.env.WASEET_USERNAME,
      password: process.env.WASEET_PASSWORD,
      timeout: 30000,
    };

    this.setupEventHandlers();
  }

  // ===================================
  // تهيئة النظام
  // ===================================
  async initialize() {
    try {
      console.log('🚀 تهيئة نظام المزامنة المتقدم...');

      // التحقق من متغيرات البيئة
      this.validateEnvironment();

      // التحقق من قاعدة البيانات
      await this.verifyDatabase();

      // الحصول على توكن الوسيط
      await this.refreshWaseetToken();

      // بدء الخدمات
      this.startServices();

      this.state.isInitialized = true;
      console.log('✅ تم تهيئة نظام المزامنة بنجاح');

      this.emit('initialized');
      return true;

    } catch (error) {
      console.error('❌ خطأ في تهيئة نظام المزامنة:', error);
      this.emit('error', error);
      throw error;
    }
  }

  // ===================================
  // التحقق من متغيرات البيئة
  // ===================================
  validateEnvironment() {
    const required = [
      'SUPABASE_URL',
      'SUPABASE_SERVICE_ROLE_KEY',
      'WASEET_USERNAME',
      'WASEET_PASSWORD'
    ];

    const missing = required.filter(key => !process.env[key]);
    
    if (missing.length > 0) {
      throw new Error(`متغيرات البيئة المفقودة: ${missing.join(', ')}`);
    }

    console.log('✅ تم التحقق من متغيرات البيئة');
  }

  // ===================================
  // التحقق من قاعدة البيانات
  // ===================================
  async verifyDatabase() {
    try {
      const { data, error } = await this.supabase
        .from('orders')
        .select('count')
        .limit(1);

      if (error) {
        throw new Error(`خطأ في الاتصال بقاعدة البيانات: ${error.message}`);
      }

      console.log('✅ تم التحقق من قاعدة البيانات');

    } catch (error) {
      throw new Error(`فشل في التحقق من قاعدة البيانات: ${error.message}`);
    }
  }

  // ===================================
  // تحديث توكن الوسيط
  // ===================================
  async refreshWaseetToken() {
    try {
      console.log('🔐 تحديث توكن الوسيط...');

      // التحقق من توفر بيانات الاعتماد
      if (!this.waseetConfig.username || !this.waseetConfig.password) {
        console.warn('⚠️ بيانات اعتماد الوسيط غير متوفرة، تخطي تحديث التوكن');
        return null;
      }

      // استخدام API الوسيط الرسمي الصحيح
      const WaseetAPIClient = require('./waseet_api_client');
      const client = new WaseetAPIClient(this.waseetConfig.username, this.waseetConfig.password);

      const loginSuccess = await client.login();

      if (loginSuccess) {
        console.log('✅ تم تسجيل الدخول للوسيط بنجاح عبر API الرسمي');
        this.state.currentToken = client.token;
        this.state.tokenExpiresAt = client.tokenExpiresAt;
        this.emit('tokenRefreshed', this.state.currentToken);
        return this.state.currentToken;
      } else {
        console.warn('⚠️ فشل في تسجيل الدخول للوسيط');
        return null;
      }

      /* الكود القديم - محفوظ للمرجع
      // محاولة عدة مسارات API مختلفة (تم إصلاح المسار الصحيح)
      const apiPaths = ['/merchant/login', '/login', '/auth/login', '/api/login', '/api/auth/login'];

      /*
      for (const path of apiPaths) {
        try {
          const response = await axios.post(`${this.waseetConfig.baseURL}${path}`, {
            username: this.waseetConfig.username,
            password: this.waseetConfig.password
          }, {
            timeout: 10000,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json'
            }
          });

          if (response.data && (response.data.token || response.data.access_token)) {
            this.state.currentToken = response.data.token || response.data.access_token;
            this.state.tokenExpiresAt = new Date(Date.now() + (24 * 60 * 60 * 1000)); // 24 ساعة

            console.log(`✅ تم تحديث توكن الوسيط بنجاح عبر ${path}`);
            this.emit('tokenRefreshed', this.state.currentToken);

            return this.state.currentToken;
          }
        } catch (pathError) {
          console.log(`⚠️ فشل المسار ${path}: ${pathError.response?.status || pathError.message}`);
          continue;
        }
      }

      // إذا فشلت جميع المسارات
      console.warn('⚠️ فشل في جميع مسارات API للوسيط، سيتم المتابعة بدون مزامنة');
      return null;
      */

    } catch (error) {
      console.error('❌ خطأ عام في تحديث توكن الوسيط:', error);
      console.warn('⚠️ سيتم المتابعة بدون خدمة المزامنة');
      return null;
    }
  }

  // ===================================
  // بدء الخدمات
  // ===================================
  startServices() {
    // خدمة المزامنة التلقائية
    this.intervals.sync = setInterval(() => {
      this.performSync();
    }, this.config.syncInterval);

    // خدمة فحص الصحة
    this.intervals.healthCheck = setInterval(() => {
      this.performHealthCheck();
    }, this.config.healthCheckInterval);

    // خدمة تحديث التوكن
    this.intervals.tokenRefresh = setInterval(() => {
      this.refreshWaseetToken();
    }, this.config.tokenRefreshInterval);

    this.state.isRunning = true;
    console.log('✅ تم بدء جميع خدمات المزامنة');
  }

  // ===================================
  // تنفيذ المزامنة
  // ===================================
  async performSync() {
    if (!this.state.isInitialized || !this.state.isRunning) {
      return;
    }

    try {
      console.log('🔄 بدء عملية المزامنة...');

      // جلب الطلبات التي تحتاج مزامنة
      const ordersToSync = await this.getOrdersToSync();

      if (ordersToSync.length === 0) {
        console.log('📝 لا توجد طلبات تحتاج مزامنة');
        return;
      }

      console.log(`📦 مزامنة ${ordersToSync.length} طلب...`);

      // معالجة الطلبات في دفعات
      const batches = this.createBatches(ordersToSync, this.config.batchSize);
      
      for (const batch of batches) {
        await this.processBatch(batch);
      }

      this.state.lastSyncAt = new Date();
      this.emit('syncCompleted', {
        totalOrders: ordersToSync.length,
        timestamp: this.state.lastSyncAt
      });

      console.log('✅ تم إكمال المزامنة بنجاح');

    } catch (error) {
      console.error('❌ خطأ في عملية المزامنة:', error);
      this.state.totalErrors++;
      this.emit('syncError', error);
    }
  }

  // ===================================
  // جلب الطلبات التي تحتاج مزامنة
  // ===================================
  async getOrdersToSync() {
    try {
      const cutoffTime = new Date(Date.now() - (15 * 60 * 1000)); // آخر 15 دقيقة

      const { data, error } = await this.supabase
        .from('orders')
        .select('*')
        .not('waseet_order_id', 'is', null)
        .in('status', ['active', 'processing', 'shipped', 'in_delivery'])
        .or(`last_status_check.is.null,last_status_check.lt.${cutoffTime.toISOString()}`)
        .order('created_at', { ascending: true })
        .limit(this.config.batchSize * 3); // جلب أكثر للتأكد

      if (error) {
        throw new Error(`خطأ في جلب الطلبات: ${error.message}`);
      }

      return data || [];

    } catch (error) {
      console.error('❌ خطأ في جلب الطلبات للمزامنة:', error);
      return [];
    }
  }

  // ===================================
  // تقسيم الطلبات إلى دفعات
  // ===================================
  createBatches(orders, batchSize) {
    const batches = [];
    for (let i = 0; i < orders.length; i += batchSize) {
      batches.push(orders.slice(i, i + batchSize));
    }
    return batches;
  }

  // ===================================
  // معالجة دفعة من الطلبات
  // ===================================
  async processBatch(batch) {
    try {
      const promises = batch.map(order => this.syncOrder(order));
      const results = await Promise.allSettled(promises);

      // تحليل النتائج
      const successful = results.filter(r => r.status === 'fulfilled').length;
      const failed = results.filter(r => r.status === 'rejected').length;

      console.log(`📊 دفعة مكتملة: ${successful} نجح، ${failed} فشل`);

      this.state.totalSynced += successful;

    } catch (error) {
      console.error('❌ خطأ في معالجة الدفعة:', error);
    }
  }

  // ===================================
  // مزامنة طلب واحد
  // ===================================
  async syncOrder(order) {
    try {
      // جلب حالة الطلب من الوسيط
      const waseetStatus = await this.getOrderStatusFromWaseet(order.waseet_order_id);
      
      if (!waseetStatus) {
        throw new Error('لم يتم العثور على الطلب في الوسيط');
      }

      // تحويل حالة الوسيط إلى حالة محلية
      const localStatus = this.mapWaseetStatusToLocal(waseetStatus.status);

      // التحقق من تغيير الحالة
      if (localStatus !== order.status) {
        await this.updateOrderStatus(order, localStatus, waseetStatus);
      }

      // تحديث وقت آخر فحص
      await this.updateLastStatusCheck(order.id);

      return { success: true, order: order.id, status: localStatus };

    } catch (error) {
      console.error(`❌ خطأ في مزامنة الطلب ${order.id}:`, error);
      return { success: false, order: order.id, error: error.message };
    }
  }

  // ===================================
  // جلب حالة الطلب من الوسيط
  // ===================================
  async getOrderStatusFromWaseet(waseetOrderId) {
    try {
      if (!this.state.currentToken) {
        await this.refreshWaseetToken();
      }

      const response = await axios.get(
        `${this.waseetConfig.baseURL}/orders/${waseetOrderId}/status`,
        {
          headers: {
            'Authorization': `Bearer ${this.state.currentToken}`,
            'Accept': 'application/json'
          },
          timeout: this.waseetConfig.timeout
        }
      );

      return response.data;

    } catch (error) {
      if (error.response?.status === 401) {
        // توكن منتهي الصلاحية، حاول التحديث
        await this.refreshWaseetToken();
        return this.getOrderStatusFromWaseet(waseetOrderId);
      }
      
      throw error;
    }
  }

  // ===================================
  // تحويل حالة الوسيط إلى حالة محلية
  // ===================================
  mapWaseetStatusToLocal(waseetStatus) {
    const statusMap = {
      'pending': 'active',
      'confirmed': 'processing',
      'picked_up': 'shipped',
      'in_transit': 'in_delivery',
      'delivered': 'delivered',
      'cancelled': 'cancelled',
      'returned': 'returned'
    };

    return statusMap[waseetStatus] || 'active';
  }

  // ===================================
  // تحديث حالة الطلب
  // ===================================
  async updateOrderStatus(order, newStatus, waseetData) {
    try {
      // تحديث الطلب في قاعدة البيانات
      const { error } = await this.supabase
        .from('orders')
        .update({
          status: newStatus,
          waseet_status: waseetData.status,
          waseet_data: waseetData,
          updated_at: new Date().toISOString()
        })
        .eq('id', order.id);

      if (error) {
        throw new Error(`خطأ في تحديث الطلب: ${error.message}`);
      }

      // إضافة سجل في تاريخ الحالات
      await this.addStatusHistory(order, newStatus, waseetData);

      // إرسال إشعار للعميل
      await this.triggerNotification(order, { from: order.status, to: newStatus });

      console.log(`✅ تم تحديث حالة الطلب ${order.id}: ${order.status} → ${newStatus}`);

    } catch (error) {
      console.error(`❌ خطأ في تحديث حالة الطلب ${order.id}:`, error);
      throw error;
    }
  }

  // ===================================
  // إضافة سجل في تاريخ الحالات
  // ===================================
  async addStatusHistory(order, newStatus, waseetData) {
    try {
      await this.supabase
        .from('order_status_history')
        .insert({
          order_id: order.id,
          old_status: order.status,
          new_status: newStatus,
          changed_by: 'system_sync',
          change_reason: 'تحديث تلقائي من شركة الوسيط',
          waseet_response: waseetData,
          created_at: new Date().toISOString()
        });

    } catch (error) {
      console.error('❌ خطأ في إضافة سجل التاريخ:', error);
    }
  }

  // ===================================
  // تحديث وقت آخر فحص
  // ===================================
  async updateLastStatusCheck(orderId) {
    try {
      await this.supabase
        .from('orders')
        .update({
          last_status_check: new Date().toISOString()
        })
        .eq('id', orderId);

    } catch (error) {
      console.error('❌ خطأ في تحديث وقت آخر فحص:', error);
    }
  }

  // ===================================
  // تشغيل إشعار للعميل
  // ===================================
  async triggerNotification(order, statusChange) {
    try {
      // إضافة إشعار إلى قائمة الانتظار
      await this.supabase
        .from('notification_queue')
        .insert({
          order_id: order.id,
          user_phone: order.user_phone || order.primary_phone,
          customer_name: order.customer_name,
          old_status: statusChange.from,
          new_status: statusChange.to,
          notification_data: {
            title: `تحديث على طلبك رقم ${order.id}`,
            message: `تم تحديث حالة طلبك إلى: ${statusChange.to}`,
            type: 'order_status_change'
          },
          priority: this.getNotificationPriority(statusChange.to),
          status: 'pending',
          created_at: new Date().toISOString()
        });

    } catch (error) {
      console.error('❌ خطأ في تشغيل الإشعار:', error);
    }
  }

  // ===================================
  // تحديد أولوية الإشعار
  // ===================================
  getNotificationPriority(status) {
    const priorities = {
      'delivered': 1,
      'in_delivery': 2,
      'cancelled': 2,
      'shipped': 3,
      'processing': 4,
      'active': 5
    };

    return priorities[status] || 5;
  }

  // ===================================
  // إعداد معالجات الأحداث
  // ===================================
  setupEventHandlers() {
    this.on('error', (error) => {
      console.error('🚨 خطأ في نظام المزامنة:', error);
    });

    this.on('syncCompleted', (data) => {
      console.log(`📊 تم إكمال المزامنة: ${data.totalOrders} طلب`);
    });

    this.on('tokenRefreshed', () => {
      console.log('🔐 تم تحديث توكن الوسيط');
    });
  }

  // ===================================
  // فحص صحة النظام
  // ===================================
  async performHealthCheck() {
    try {
      const health = {
        timestamp: new Date().toISOString(),
        status: 'healthy',
        services: {
          database: 'unknown',
          waseet_api: 'unknown',
          token: this.state.currentToken ? 'active' : 'inactive'
        },
        stats: {
          totalSynced: this.state.totalSynced,
          totalErrors: this.state.totalErrors,
          lastSyncAt: this.state.lastSyncAt,
          uptime: Date.now() - (this.state.lastSyncAt?.getTime() || Date.now())
        }
      };

      // فحص قاعدة البيانات
      try {
        await this.supabase.from('orders').select('count').limit(1);
        health.services.database = 'active';
      } catch (error) {
        health.services.database = 'error';
        health.status = 'degraded';
      }

      // فحص API الوسيط
      try {
        if (this.state.currentToken) {
          // يمكن إضافة فحص بسيط لـ API الوسيط هنا
          health.services.waseet_api = 'active';
        }
      } catch (error) {
        health.services.waseet_api = 'error';
        health.status = 'degraded';
      }

      this.emit('healthCheck', health);

    } catch (error) {
      console.error('❌ خطأ في فحص صحة النظام:', error);
    }
  }

  // ===================================
  // إيقاف النظام
  // ===================================
  async shutdown() {
    try {
      console.log('🛑 إيقاف نظام المزامنة...');

      this.state.isRunning = false;

      // إيقاف جميع الفترات الزمنية
      Object.values(this.intervals).forEach(interval => {
        if (interval) clearInterval(interval);
      });

      console.log('✅ تم إيقاف نظام المزامنة بأمان');
      this.emit('shutdown');

    } catch (error) {
      console.error('❌ خطأ في إيقاف النظام:', error);
    }
  }

  // ===================================
  // الحصول على إحصائيات النظام
  // ===================================
  getStats() {
    return {
      state: { ...this.state },
      config: { ...this.config },
      uptime: this.state.lastSyncAt 
        ? Date.now() - this.state.lastSyncAt.getTime()
        : 0
    };
  }
}

module.exports = AdvancedSyncManager;
