// ===================================
// خدمة API شركة الوسيط الرسمية
// تطبيق التعليمات الرسمية بالضبط
// ===================================

const axios = require('axios');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

class WaseetAPIService {
  constructor() {
    // إعداد Supabase
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    // إعدادات شركة الوسيط - الرابط الصحيح
    this.config = {
      baseUrl: 'https://merchant.alwaseet-iq.net',
      username: process.env.WASEET_USERNAME || 'محمد@mustfaabd',
      password: process.env.WASEET_PASSWORD || 'mustfaabd2006@',
      timeout: 30000
    };

    this.loginToken = null;
    this.tokenExpiry = null;

    console.log('🌐 تم تهيئة خدمة API شركة الوسيط الرسمية');
  }

  /**
   * تسجيل الدخول للحصول على التوكن
   * جرب مسارات مختلفة للعثور على الصحيح
   */
  async authenticate() {
    try {
      // التحقق من صحة التوكن الحالي
      if (this.isTokenValid()) {
        return this.loginToken;
      }

      console.log('🔐 تسجيل الدخول لشركة الوسيط...');

      const loginData = new URLSearchParams({
        username: this.config.username,
        password: this.config.password
      });

      // المسار الصحيح لتسجيل الدخول
      const loginPaths = [
        '/merchant/login'
      ];

      let lastError = null;

      for (const path of loginPaths) {
        try {
          console.log(`🔍 جرب مسار: ${this.config.baseUrl}${path}`);

          const response = await axios.post(`${this.config.baseUrl}${path}`, loginData, {
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            },
            timeout: this.config.timeout,
            maxRedirects: 0,
            validateStatus: (status) => status < 500 // قبول حتى 4xx للتحقق
          });

          console.log(`📊 استجابة ${path}: ${response.status}`);

          if (response.status === 200 || response.status === 302) {
            // نجح التسجيل
            const cookies = response.headers['set-cookie'];
            if (cookies) {
              this.loginToken = cookies.map(cookie => cookie.split(';')[0]).join('; ');
              this.tokenExpiry = Date.now() + (30 * 60 * 1000);
              console.log(`✅ تم تسجيل الدخول بنجاح عبر ${path}`);
              return this.loginToken;
            }
          }

          // إذا كانت الاستجابة JSON، تحقق من وجود توكن
          if (response.data && typeof response.data === 'object') {
            console.log(`📄 استجابة JSON من ${path}:`, response.data);

            if (response.data.token || response.data.access_token) {
              this.loginToken = response.data.token || response.data.access_token;
              this.tokenExpiry = Date.now() + (30 * 60 * 1000);
              console.log(`✅ تم الحصول على توكن من ${path}`);
              return this.loginToken;
            }
          }

        } catch (error) {
          console.log(`❌ فشل ${path}: ${error.response?.status || error.message}`);
          lastError = error;
          continue;
        }
      }

      throw new Error(`فشل تسجيل الدخول في جميع المسارات. آخر خطأ: ${lastError?.message}`);

    } catch (error) {
      console.error('❌ فشل تسجيل الدخول:', error.message);
      throw error;
    }
  }

  /**
   * التحقق من صحة التوكن
   */
  isTokenValid() {
    return this.loginToken && this.tokenExpiry && Date.now() < this.tokenExpiry;
  }

  /**
   * جلب حالات الطلبات حسب API الرسمي
   * GET /v1/merchant/statuses?token=loginToken
   */
  async getOrderStatuses() {
    try {
      console.log('📊 جلب حالات الطلبات من شركة الوسيط...');

      // التأكد من تسجيل الدخول
      const token = await this.authenticate();

      // استدعاء API الرسمي بالضبط كما هو مطلوب
      const response = await axios.get(`${this.config.baseUrl}/v1/merchant/statuses`, {
        params: {
          token: token
        },
        headers: {
          'Cookie': token,
          'Content-Type': 'multipart/form-data',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
        timeout: this.config.timeout
      });

      console.log(`✅ استجابة API: ${response.status}`);
      console.log('📄 محتوى الاستجابة:', JSON.stringify(response.data, null, 2));

      // التحقق من نجاح الاستجابة حسب التعليمات
      if (!response.data.status || response.data.errNum !== 'S000') {
        throw new Error(`خطأ من API: ${response.data.msg || 'خطأ غير معروف'}`);
      }

      const statuses = response.data.data;
      console.log(`✅ تم جلب ${statuses.length} حالة من شركة الوسيط`);

      return {
        success: true,
        statuses: statuses,
        total: statuses.length
      };

    } catch (error) {
      console.error('❌ فشل جلب حالات الطلبات:', error.message);
      
      if (error.response) {
        console.error('📄 تفاصيل الخطأ:', {
          status: error.response.status,
          statusText: error.response.statusText,
          data: error.response.data
        });
      }

      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * مزامنة حالات الطلبات مع قاعدة البيانات
   */
  async syncOrderStatuses() {
    try {
      console.log('🔄 بدء مزامنة حالات الطلبات...');

      // جلب الحالات من شركة الوسيط
      const statusesResult = await this.getOrderStatuses();
      
      if (!statusesResult.success) {
        throw new Error(`فشل جلب الحالات: ${statusesResult.error}`);
      }

      const waseetStatuses = statusesResult.statuses;
      
      // جلب الطلبات من قاعدة البيانات التي لها معرف وسيط
      const { data: orders, error: ordersError } = await this.supabase
        .from('orders')
        .select('id, order_number, waseet_order_id, status, waseet_status')
        .not('waseet_order_id', 'is', null);

      if (ordersError) {
        throw new Error(`فشل جلب الطلبات: ${ordersError.message}`);
      }

      console.log(`📦 تم جلب ${orders.length} طلب من قاعدة البيانات`);

      let updatedCount = 0;
      const errors = [];

      // مزامنة كل طلب
      for (const order of orders) {
        try {
          // البحث عن حالة الطلب في بيانات الوسيط
          const waseetStatus = waseetStatuses.find(status => 
            status.id === order.waseet_order_id || 
            status.id === order.waseet_order_id?.toString()
          );

          if (waseetStatus) {
            // تحديث حالة الطلب إذا تغيرت
            if (order.waseet_status !== waseetStatus.status) {
              const { error: updateError } = await this.supabase
                .from('orders')
                .update({
                  status: waseetStatus.status,
                  waseet_status: waseetStatus.status,
                  last_status_check: new Date().toISOString(),
                  updated_at: new Date().toISOString()
                })
                .eq('id', order.id);

              if (updateError) {
                errors.push(`فشل تحديث الطلب ${order.order_number}: ${updateError.message}`);
              } else {
                console.log(`✅ تم تحديث الطلب ${order.order_number}: ${order.waseet_status} → ${waseetStatus.status}`);
                updatedCount++;
              }
            }
          }
        } catch (error) {
          errors.push(`خطأ في معالجة الطلب ${order.order_number}: ${error.message}`);
        }
      }

      console.log(`✅ انتهت المزامنة: تم تحديث ${updatedCount} طلب من ${orders.length}`);
      
      if (errors.length > 0) {
        console.log(`⚠️ أخطاء في ${errors.length} طلب:`, errors);
      }

      return {
        success: true,
        checked: orders.length,
        updated: updatedCount,
        errors: errors
      };

    } catch (error) {
      console.error('❌ فشل مزامنة حالات الطلبات:', error.message);
      return {
        success: false,
        error: error.message,
        checked: 0,
        updated: 0
      };
    }
  }
}

module.exports = WaseetAPIService;
