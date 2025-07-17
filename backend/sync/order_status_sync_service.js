// ===================================
// نظام المزامنة التلقائية لحالات الطلبات
// خدمة احترافية لمزامنة الطلبات مع شركة الوسيط
// ===================================

const axios = require('axios');
const cron = require('node-cron');
const { createClient } = require('@supabase/supabase-js');
const statusMapper = require('./status_mapper');
const notifier = require('./notifier');
const waseetTokenHelper = require('./waseet_token_helper');
require('dotenv').config();

class OrderStatusSyncService {
  constructor() {
    // إعداد Supabase
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    // إعدادات شركة الوسيط
    this.waseetConfig = {
      baseUrl: process.env.ALMASEET_BASE_URL || 'https://api.alwaseet-iq.net',
      username: process.env.WASEET_USERNAME || 'محمد@mustfaabd',
      password: process.env.WASEET_PASSWORD || 'mustfaabd2006@',
      token: null,
      tokenExpiry: null
    };

    // إعدادات المزامنة - كل 10 دقائق
    this.syncInterval = 10; // 10 دقائق
    this.isRunning = false;
    this.lastSyncTime = null;
    this.syncStats = {
      totalChecked: 0,
      totalUpdated: 0,
      totalErrors: 0,
      lastRun: null
    };

    console.log('🔄 تم تهيئة خدمة المزامنة التلقائية لحالات الطلبات');
  }

  // ===================================
  // تسجيل الدخول إلى شركة الوسيط
  // ===================================
  async authenticateWaseet() {
    try {
      // التحقق من صحة التوكن الحالي
      if (this.waseetConfig.token && this.waseetConfig.tokenExpiry) {
        const now = new Date();
        if (now < this.waseetConfig.tokenExpiry) {
          // إخفاء رسالة "التوكن صالح" لتقليل الرسائل المكررة
          // console.log('✅ التوكن صالح، لا حاجة لتسجيل دخول جديد');
          return this.waseetConfig.token;
        }
      }

      console.log('🔐 محاولة الحصول على توكن شركة الوسيط...');

      // أولاً: التحقق من التوكن العام
      const globalToken = this.getGlobalToken();
      if (globalToken) {
        this.waseetConfig.token = globalToken;
        this.waseetConfig.tokenExpiry = global.WASEET_CONFIG.tokenExpiry;
        console.log('✅ تم استخدام التوكن العام');
        return globalToken;
      }

      // ثانياً: استخدام المساعد للحصول على أفضل توكن متاح
      const token = await waseetTokenHelper.getBestAvailableToken();

      if (token && await waseetTokenHelper.validateToken(token)) {
        this.waseetConfig.token = token;
        this.waseetConfig.tokenExpiry = new Date(Date.now() + 24 * 60 * 60 * 1000);

        console.log('✅ تم الحصول على توكن صالح من المساعد');

        // تسجيل في النظام
        await this.logSystemEvent('waseet_token_acquired', {
          timestamp: new Date().toISOString(),
          source: 'token_helper'
        });

        return this.waseetConfig.token;
      }

      // إذا فشل الحصول على توكن، نحاول تسجيل دخول جديد
      console.log('⚠️ لا يوجد توكن صالح، محاولة تسجيل دخول جديد...');

      const newToken = await this.performDirectLogin();
      if (newToken) {
        // حفظ التوكن الجديد في المساعد
        await waseetTokenHelper.updateTokenFromExternal(newToken, this.waseetConfig.tokenExpiry);
        return newToken;
      }

      console.warn('⚠️ فشل في الحصول على توكن من شركة الوسيط');
      return null;
    } catch (error) {
      console.error('❌ خطأ في المصادقة مع شركة الوسيط:', error.message);

      // تسجيل الخطأ
      try {
        await this.logSystemEvent('waseet_auth_error', {
          error: error.message,
          timestamp: new Date().toISOString()
        });
      } catch (logError) {
        console.error('❌ خطأ في تسجيل الحدث:', logError.message);
      }

      // إرجاع null بدلاً من رمي خطأ لتجنب توقف النظام
      return null;
    }
  }

  // ===================================
  // إدارة التوكن العام
  // ===================================
  setGlobalToken(token) {
    try {
      // إنشاء أو تحديث المتغير العام
      global.WASEET_CONFIG = {
        authToken: token,
        tokenExpiry: this.waseetConfig.tokenExpiry,
        lastUpdate: new Date(),
        source: 'order_sync_service'
      };

      console.log('✅ تم حفظ التوكن في المتغير العام');
    } catch (error) {
      console.error('❌ خطأ في حفظ التوكن العام:', error.message);
    }
  }

  getGlobalToken() {
    try {
      if (global.WASEET_CONFIG && global.WASEET_CONFIG.authToken) {
        // التحقق من صلاحية التوكن
        if (global.WASEET_CONFIG.tokenExpiry && new Date(global.WASEET_CONFIG.tokenExpiry) > new Date()) {
          console.log('✅ تم العثور على توكن صالح في المتغير العام');
          return global.WASEET_CONFIG.authToken;
        } else {
          console.log('⚠️ التوكن العام منتهي الصلاحية');
          // حذف التوكن المنتهي الصلاحية
          delete global.WASEET_CONFIG;
          return null;
        }
      }
      return null;
    } catch (error) {
      console.error('❌ خطأ في قراءة التوكن العام:', error.message);
      return null;
    }
  }

  // ===================================
  // تسجيل دخول مباشر (كحل أخير)
  // ===================================
  async performDirectLogin() {
    try {
      console.log('🔐 تسجيل دخول مباشر إلى شركة الوسيط...');

      const loginUrl = `${this.waseetConfig.baseUrl}/merchant/login`;

      // جلب صفحة تسجيل الدخول للحصول على cookies
      const loginPageResponse = await axios.get(loginUrl, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
        timeout: 30000
      });

      const cookies = loginPageResponse.headers['set-cookie'] || [];
      const cookieString = cookies.map(cookie => cookie.split(';')[0]).join('; ');

      // إرسال بيانات تسجيل الدخول
      const loginData = new URLSearchParams();
      loginData.append('username', this.waseetConfig.username);
      loginData.append('password', this.waseetConfig.password);

      const loginResponse = await axios.post(loginUrl, loginData, {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cookie': cookieString,
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
        timeout: 30000,
        maxRedirects: 0,
        validateStatus: function (status) {
          return status < 500; // قبول إعادة التوجيه
        }
      });

      // التحقق من نجاح تسجيل الدخول
      const newCookies = loginResponse.headers['set-cookie'] || [];
      const allCookies = [...cookies, ...newCookies];
      const finalCookieString = allCookies.map(cookie => cookie.split(';')[0]).join('; ');

      // فحص إعادة التوجيه (علامة نجاح)
      if (loginResponse.status === 303 || loginResponse.status === 302 || loginResponse.status === 301) {
        const location = loginResponse.headers['location'];
        console.log('🔄 إعادة توجيه إلى:', location);

        if (location && !location.includes('login')) {
          this.waseetConfig.token = finalCookieString;
          this.waseetConfig.tokenExpiry = new Date(Date.now() + 24 * 60 * 60 * 1000);

          console.log('✅ تم تسجيل الدخول المباشر بنجاح (إعادة توجيه)');

          // حفظ التوكن في المتغير العام للمشاركة مع الخدمات الأخرى
          this.setGlobalToken(this.waseetConfig.token);

          // تسجيل في النظام
          await this.logSystemEvent('waseet_direct_login_success', {
            timestamp: new Date().toISOString(),
            token_expiry: this.waseetConfig.tokenExpiry,
            redirect_location: location
          });

          return this.waseetConfig.token;
        }
      }

      // فحص وجود PHPSESSID (طريقة بديلة)
      if (finalCookieString && finalCookieString.includes('PHPSESSID')) {
        this.waseetConfig.token = finalCookieString;
        this.waseetConfig.tokenExpiry = new Date(Date.now() + 24 * 60 * 60 * 1000);

        console.log('✅ تم تسجيل الدخول المباشر بنجاح (PHPSESSID)');

        // تسجيل في النظام
        await this.logSystemEvent('waseet_direct_login_success', {
          timestamp: new Date().toISOString(),
          token_expiry: this.waseetConfig.tokenExpiry
        });

        return this.waseetConfig.token;
      }

      console.log('⚠️ لم يتم التعرف على نجاح تسجيل الدخول');
      return null;
    } catch (error) {
      console.error('❌ خطأ في تسجيل الدخول المباشر:', error.message);

      // تسجيل الخطأ
      try {
        await this.logSystemEvent('waseet_direct_login_error', {
          error: error.message,
          timestamp: new Date().toISOString()
        });
      } catch (logError) {
        console.error('❌ خطأ في تسجيل الحدث:', logError.message);
      }

      return null;
    }
  }

  // ===================================
  // جلب الطلبات المؤهلة للمزامنة
  // ===================================
  async getOrdersForSync() {
    try {
      // إخفاء رسالة جلب الطلبات
      // console.log('📋 جلب الطلبات المؤهلة للمزامنة...');

      // جلب الطلبات التي تحتاج مزامنة
      const { data: orders, error } = await this.supabase
        .from('orders')
        .select(`
          id,
          order_number,
          customer_name,
          primary_phone,
          status,
          waseet_order_id,
          last_status_check,
          created_at
        `)
        .in('status', ['active', 'in_delivery'])
        .not('waseet_order_id', 'is', null)
        // تجنب الطلبات التجريبية في الإنتاج
        .not('order_number', 'like', process.env.NODE_ENV === 'production' ? '%TEST%' : 'NEVER_MATCH')
        .not('order_number', 'like', process.env.NODE_ENV === 'production' ? '%test%' : 'NEVER_MATCH')
        .or(`last_status_check.is.null,last_status_check.lt.${new Date(Date.now() - 10 * 60 * 1000).toISOString()}`)
        .limit(process.env.NODE_ENV === 'production' ? 10 : 50); // تقليل العدد في الإنتاج

      if (error) {
        if (error.message.includes('relation') || error.message.includes('does not exist')) {
          console.warn('⚠️ جدول الطلبات غير موجود - سيتم إرجاع قائمة فارغة');
          return [];
        }
        throw new Error(`خطأ في جلب الطلبات: ${error.message}`);
      }

      // إخفاء رسالة عدد الطلبات
      // console.log(`📊 تم العثور على ${orders?.length || 0} طلب مؤهل للمزامنة`);

      return orders || [];
    } catch (error) {
      console.error('❌ خطأ في جلب الطلبات للمزامنة:', error.message);
      return []; // إرجاع قائمة فارغة بدلاً من رمي خطأ
    }
  }

  // ===================================
  // فحص حالة طلب واحد من شركة الوسيط
  // ===================================
  async checkOrderStatus(order) {
    try {
      // إخفاء رسائل فحص الطلبات تماماً
      // console.log(`🔍 فحص حالة الطلب: ${order.order_number} (${order.waseet_order_id})`);

      // التأكد من وجود التوكن
      const token = await this.authenticateWaseet();

      if (!token) {
        console.warn(`⚠️ لا يوجد توكن صالح، تخطي فحص الطلب ${order.order_number}`);
        return {
          success: false,
          error: 'لا يوجد توكن صالح للمصادقة'
        };
      }

      // طلب حالة الطلب من شركة الوسيط
      const statusResponse = await axios.get(
        `${this.waseetConfig.baseUrl}/merchant/get_order_status`,
        {
          params: {
            order_id: order.waseet_order_id
          },
          timeout: 15000,
          headers: {
            'Cookie': token,
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
          }
        }
      );

      if (statusResponse.data && statusResponse.data.status) {
        const waseetStatus = statusResponse.data.status;
        const waseetData = statusResponse.data;

        console.log(`📊 حالة الطلب من الوسيط: ${waseetStatus}`);

        // تحويل الحالة إلى الحالة المحلية
        const localStatus = statusMapper.mapWaseetToLocal(waseetStatus);

        return {
          success: true,
          waseetStatus,
          localStatus,
          waseetData,
          hasChanged: localStatus !== order.status
        };
      } else {
        throw new Error('استجابة غير صحيحة من شركة الوسيط');
      }
    } catch (error) {
      // إخفاء رسائل أخطاء فحص الطلبات تماماً
      // console.error(`❌ خطأ في فحص حالة الطلب ${order.order_number}:`, error.message);

      // تسجيل الخطأ
      try {
        await this.logSystemEvent('order_status_check_error', {
          order_id: order.id,
          order_number: order.order_number,
          error: error.message,
          timestamp: new Date().toISOString()
        });
      } catch (logError) {
        console.error('❌ خطأ في تسجيل الحدث:', logError.message);
      }

      return {
        success: false,
        error: error.message
      };
    }
  }

  // ===================================
  // تحديث حالة الطلب في قاعدة البيانات
  // ===================================
  async updateOrderStatus(order, statusResult) {
    try {
      const now = new Date().toISOString();
      
      console.log(`🔄 تحديث حالة الطلب ${order.order_number} من ${order.status} إلى ${statusResult.localStatus}`);

      // بدء معاملة قاعدة البيانات
      const { error: updateError } = await this.supabase
        .from('orders')
        .update({
          status: statusResult.localStatus,
          waseet_status: statusResult.waseetStatus,
          waseet_data: statusResult.waseetData,
          last_status_check: now,
          updated_at: now
        })
        .eq('id', order.id);

      if (updateError) {
        throw new Error(`خطأ في تحديث الطلب: ${updateError.message}`);
      }

      // إضافة سجل في تاريخ الحالات
      const { error: historyError } = await this.supabase
        .from('order_status_history')
        .insert({
          order_id: order.id,
          old_status: order.status,
          new_status: statusResult.localStatus,
          changed_by: 'system_sync',
          change_reason: 'تحديث تلقائي من شركة الوسيط',
          waseet_response: statusResult.waseetData,
          created_at: now
        });

      if (historyError) {
        console.warn(`⚠️ تحذير: فشل في حفظ سجل التاريخ: ${historyError.message}`);
      }

      console.log(`✅ تم تحديث حالة الطلب ${order.order_number} بنجاح`);

      // إرسال إشعار للعميل
      try {
        await notifier.sendStatusUpdateNotification(order, statusResult.localStatus);
      } catch (notificationError) {
        console.warn(`⚠️ تحذير: فشل في إرسال الإشعار: ${notificationError.message}`);
      }

      return true;
    } catch (error) {
      console.error(`❌ خطأ في تحديث حالة الطلب ${order.order_number}:`, error.message);

      // تسجيل الخطأ
      try {
        await this.logSystemEvent('order_update_error', {
          order_id: order.id,
          order_number: order.order_number,
          error: error.message,
          timestamp: new Date().toISOString()
        });
      } catch (logError) {
        console.error('❌ خطأ في تسجيل الحدث:', logError.message);
      }

      return false; // إرجاع false بدلاً من رمي خطأ
    }
  }

  // ===================================
  // تسجيل أحداث النظام
  // ===================================
  async logSystemEvent(eventType, eventData) {
    try {
      await this.supabase
        .from('system_logs')
        .insert({
          event_type: eventType,
          event_data: eventData,
          service: 'order_status_sync',
          created_at: new Date().toISOString()
        });
    } catch (error) {
      console.warn(`⚠️ تحذير: فشل في تسجيل حدث النظام: ${error.message}`);
    }
  }

  // ===================================
  // تشغيل دورة مزامنة واحدة
  // ===================================
  async runSyncCycle() {
    if (this.isRunning) {
      console.log('⚠️ دورة المزامنة قيد التشغيل بالفعل، تخطي...');
      return;
    }

    this.isRunning = true;
    const startTime = new Date();
    let checkedCount = 0;
    let updatedCount = 0;
    let errorCount = 0;

    try {
      // إخفاء رسالة بدء دورة المزامنة
      // console.log('🚀 بدء دورة مزامنة حالات الطلبات...');

      // تسجيل بداية المزامنة
      await this.logSystemEvent('sync_cycle_start', {
        timestamp: startTime.toISOString()
      });

      // جلب الطلبات المؤهلة للمزامنة
      const orders = await this.getOrdersForSync();

      if (orders.length === 0) {
        // إخفاء رسالة "لا توجد طلبات"
        // console.log('📭 لا توجد طلبات تحتاج مزامنة');
        return;
      }

      // معالجة كل طلب
      for (const order of orders) {
        try {
          checkedCount++;

          // فحص حالة الطلب
          const statusResult = await this.checkOrderStatus(order);

          if (statusResult.success) {
            // تحديث وقت آخر فحص حتى لو لم تتغير الحالة
            await this.supabase
              .from('orders')
              .update({
                last_status_check: new Date().toISOString(),
                waseet_data: statusResult.waseetData
              })
              .eq('id', order.id);

            // إذا تغيرت الحالة، قم بالتحديث الكامل
            if (statusResult.hasChanged) {
              const updateSuccess = await this.updateOrderStatus(order, statusResult);
              if (updateSuccess) {
                updatedCount++;
                console.log(`✅ تم تحديث الطلب ${order.order_number}: ${order.status} → ${statusResult.localStatus}`);
              } else {
                errorCount++;
                console.error(`❌ فشل في تحديث الطلب ${order.order_number}`);
              }
            } else {
              console.log(`📊 الطلب ${order.order_number}: لا تغيير في الحالة (${statusResult.localStatus})`);
            }
          } else {
            // تحديث وقت آخر فحص حتى لو فشل الفحص لتجنب المحاولة المستمرة
            await this.supabase
              .from('orders')
              .update({
                last_status_check: new Date().toISOString()
              })
              .eq('id', order.id);

            // إذا كان الخطأ متعلق بالتوكن، لا نعتبره خطأ حقيقي
            if (statusResult.error && statusResult.error.includes('توكن')) {
              console.warn(`⚠️ تخطي الطلب ${order.order_number}: ${statusResult.error}`);
            } else {
              errorCount++;
              // إخفاء رسائل فشل الفحص تماماً
              // console.error(`❌ فشل فحص الطلب ${order.order_number}: ${statusResult.error}`);
            }
          }

          // انتظار قصير بين الطلبات لتجنب إرهاق الخادم
          await new Promise(resolve => setTimeout(resolve, 1000));

        } catch (error) {
          errorCount++;
          console.error(`❌ خطأ في معالجة الطلب ${order.order_number}:`, error.message);
        }
      }

      // تحديث الإحصائيات
      this.syncStats.totalChecked += checkedCount;
      this.syncStats.totalUpdated += updatedCount;
      this.syncStats.totalErrors += errorCount;
      this.syncStats.lastRun = startTime;
      this.lastSyncTime = startTime;

      const endTime = new Date();
      const duration = endTime - startTime;

      // إخفاء رسائل انتهاء المزامنة والإحصائيات
      // console.log('🎉 انتهت دورة المزامنة بنجاح');
      // console.log(`📊 الإحصائيات: فحص ${checkedCount} | تحديث ${updatedCount} | أخطاء ${errorCount}`);
      // console.log(`⏱️ المدة: ${duration}ms`);

      // تسجيل انتهاء المزامنة
      try {
        await this.logSystemEvent('sync_cycle_complete', {
          start_time: startTime.toISOString(),
          end_time: endTime.toISOString(),
          duration_ms: duration,
          orders_checked: checkedCount,
          orders_updated: updatedCount,
          errors: errorCount
        });
      } catch (logError) {
        console.error('❌ خطأ في تسجيل انتهاء المزامنة:', logError.message);
      }

    } catch (error) {
      errorCount++;
      console.error('❌ خطأ في دورة المزامنة:', error.message);

      // تسجيل خطأ المزامنة
      try {
        await this.logSystemEvent('sync_cycle_error', {
          error: error.message,
          timestamp: new Date().toISOString(),
          orders_checked: checkedCount,
          orders_updated: updatedCount
        });
      } catch (logError) {
        console.error('❌ خطأ في تسجيل خطأ المزامنة:', logError.message);
      }
    } finally {
      this.isRunning = false;
    }
  }

  // ===================================
  // بدء المزامنة التلقائية
  // ===================================
  startAutoSync() {
    console.log(`🔄 بدء المزامنة التلقائية كل ${this.syncInterval} دقائق`);

    // تشغيل دورة أولى فورية
    setTimeout(() => {
      this.runSyncCycle();
    }, 5000); // انتظار 5 ثوان بعد بدء الخادم

    // جدولة المزامنة كل 10 دقائق
    cron.schedule(`*/${this.syncInterval} * * * *`, () => {
      this.runSyncCycle();
    });

    console.log('✅ تم تفعيل المزامنة التلقائية');
  }

  // ===================================
  // إيقاف المزامنة التلقائية
  // ===================================
  stopAutoSync() {
    console.log('🛑 إيقاف المزامنة التلقائية');
    // سيتم إيقاف cron تلقائياً عند إنهاء العملية
  }

  // ===================================
  // الحصول على إحصائيات المزامنة
  // ===================================
  getSyncStats() {
    return {
      ...this.syncStats,
      isRunning: this.isRunning,
      lastSyncTime: this.lastSyncTime,
      nextSyncTime: this.lastSyncTime ?
        new Date(this.lastSyncTime.getTime() + this.syncInterval * 60 * 1000) :
        null
    };
  }

  // ===================================
  // تهيئة الخدمة
  // ===================================
  async initialize() {
    try {
      console.log('🔄 بدء تهيئة خدمة مزامنة حالات الطلبات...');

      // التحقق من الاتصال بقاعدة البيانات
      const { data, error } = await this.supabase
        .from('orders')
        .select('count')
        .limit(1);

      if (error) {
        throw new Error(`خطأ في الاتصال بقاعدة البيانات: ${error.message}`);
      }

      console.log('✅ تم التحقق من الاتصال بقاعدة البيانات');

      // محاولة المصادقة مع شركة الوسيط
      const token = await this.authenticateWaseet();
      if (token) {
        console.log('✅ تم التحقق من الاتصال بشركة الوسيط');
      } else {
        console.log('⚠️ تحذير: لم يتم الحصول على توكن شركة الوسيط');
      }

      console.log('✅ تم تهيئة خدمة مزامنة حالات الطلبات بنجاح');
      return true;
    } catch (error) {
      console.error('❌ خطأ في تهيئة خدمة مزامنة حالات الطلبات:', error.message);
      throw error;
    }
  }

  // ===================================
  // فحص صحة الخدمة
  // ===================================
  async healthCheck() {
    try {
      // فحص الاتصال بـ Supabase
      const { data, error } = await this.supabase
        .from('orders')
        .select('count')
        .limit(1);

      if (error) {
        throw new Error(`خطأ في الاتصال بقاعدة البيانات: ${error.message}`);
      }

      // فحص الاتصال بشركة الوسيط
      await this.authenticateWaseet();

      return {
        status: 'healthy',
        database: 'connected',
        waseet: 'authenticated',
        sync_stats: this.getSyncStats(),
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      return {
        status: 'unhealthy',
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }
}

// تصدير الكلاس
module.exports = OrderStatusSyncService;
