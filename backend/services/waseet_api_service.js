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

    // إعدادات شركة الوسيط حسب التعليمات الرسمية
    this.config = {
      baseUrl: 'https://api.alwaseet-iq.net',
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

      const response = await axios.post(`${this.config.baseUrl}/login`, loginData, {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
        timeout: this.config.timeout,
        maxRedirects: 0,
        validateStatus: (status) => status < 400
      });

      // استخراج التوكن من الكوكيز
      const cookies = response.headers['set-cookie'];
      if (!cookies) {
        throw new Error('لم يتم الحصول على توكن من تسجيل الدخول');
      }

      this.loginToken = cookies.map(cookie => cookie.split(';')[0]).join('; ');
      this.tokenExpiry = Date.now() + (30 * 60 * 1000); // 30 دقيقة

      console.log('✅ تم تسجيل الدخول بنجاح');
      return this.loginToken;

    } catch (error) {
      console.error('❌ فشل تسجيل الدخول:', error.message);
      throw new Error(`فشل تسجيل الدخول: ${error.message}`);
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
