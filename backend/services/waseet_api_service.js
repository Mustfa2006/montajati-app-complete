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
      username: process.env.WASEET_USERNAME || 'mustfaabd',
      password: process.env.WASEET_PASSWORD || '65888304',
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

          if (response.status === 200 || response.status === 302 || response.status === 303) {
            console.log(`📄 استجابة تسجيل الدخول من ${path}:`, {
              status: response.status,
              headers: Object.keys(response.headers),
              dataType: typeof response.data,
              dataLength: response.data?.length || 'N/A'
            });

            // البحث عن التوكن في الاستجابة JSON
            if (response.data && typeof response.data === 'object') {
              console.log(`📄 بيانات JSON:`, response.data);

              if (response.data.token || response.data.access_token || response.data.loginToken) {
                this.loginToken = response.data.token || response.data.access_token || response.data.loginToken;
                this.tokenExpiry = Date.now() + (30 * 60 * 1000);
                console.log(`✅ تم الحصول على loginToken من ${path}: ${this.loginToken}`);
                return this.loginToken;
              }
            }

            // البحث عن التوكن في الكوكيز كبديل
            const cookies = response.headers['set-cookie'];
            if (cookies) {
              const cookieString = cookies.map(cookie => cookie.split(';')[0]).join('; ');

              // استخراج session ID كـ loginToken
              const sessionMatch = cookieString.match(/ci_session=([^;]+)/);
              if (sessionMatch) {
                this.loginToken = sessionMatch[1]; // فقط قيمة الـ session
                this.tokenExpiry = Date.now() + (30 * 60 * 1000);
                console.log(`✅ تم استخراج loginToken من الكوكيز: ${this.loginToken}`);
                return this.loginToken;
              }
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

      // استدعاء API بالضبط حسب التعليمات الرسمية
      console.log(`🔍 استدعاء API الرسمي: https://api.alwaseet-iq.net/v1/merchant/statuses?token=${token}`);

      const response = await axios.get('https://api.alwaseet-iq.net/v1/merchant/statuses', {
        params: {
          token: token  // التوكن في query parameter كما هو مطلوب
        },
        headers: {
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
   * جلب حالات الطلبات حسب API الرسمي بالضبط
   * GET /v1/merchant/statuses?token=loginToken
   */
  async getOrderStatuses() {
    try {
      console.log('� جلب حالات الطلبات من شركة الوسيط (API الرسمي)...');

      // التأكد من تسجيل الدخول
      const token = await this.authenticate();

      console.log(`🔍 استدعاء API الرسمي: https://api.alwaseet-iq.net/v1/merchant/statuses?token=${token}`);

      const response = await axios.get('https://api.alwaseet-iq.net/v1/merchant/statuses', {
        params: {
          token: token  // التوكن في query parameter كما هو مطلوب بالضبط
        },
        headers: {
          'Content-Type': 'multipart/form-data',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
        timeout: this.config.timeout
      });

      console.log(`✅ استجابة API: ${response.status}`);
      console.log('📄 محتوى الاستجابة:', JSON.stringify(response.data, null, 2));

      // التحقق من نجاح الاستجابة حسب التعليمات بالضبط
      if (!response.data.status || response.data.errNum !== 'S000') {
        console.log(`⚠️ خطأ من API: ${response.data.msg}`);
        console.log(`📋 رمز الخطأ: ${response.data.errNum}`);

        // إذا كان الخطأ متعلق بالصلاحية، جرب طرق أخرى للحصول على التوكن
        if (response.data.errNum === '21' || response.data.msg?.includes('صلاحية')) {
          console.log('🔄 محاولة الحصول على توكن API مختلف...');
          return await this.tryAlternativeTokenMethods();
        }

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
   * محاولة طرق بديلة للحصول على توكن API صالح
   */
  async tryAlternativeTokenMethods() {
    try {
      console.log('🔄 جرب طرق بديلة للحصول على توكن API...');

      // الطريقة 1: استخدام الكوكيز كاملة
      const fullCookies = await this.getFullCookies();
      if (fullCookies) {
        const result = await this.testTokenWithAPI(fullCookies);
        if (result.success) return result;
      }

      // الطريقة 2: البحث عن توكن في صفحة التاجر
      const pageToken = await this.extractTokenFromPage();
      if (pageToken) {
        const result = await this.testTokenWithAPI(pageToken);
        if (result.success) return result;
      }

      throw new Error('فشل جميع طرق الحصول على توكن API صالح');

    } catch (error) {
      console.error('❌ فشل الطرق البديلة:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * الحصول على الكوكيز كاملة
   */
  async getFullCookies() {
    try {
      const cookieString = await this.authenticate();
      return `ci_session=${cookieString}`;
    } catch (error) {
      return null;
    }
  }

  /**
   * استخراج توكن من صفحة التاجر
   */
  async extractTokenFromPage() {
    try {
      const cookieString = await this.authenticate();

      const response = await axios.get('https://merchant.alwaseet-iq.net/merchant', {
        headers: {
          'Cookie': `ci_session=${cookieString}`,
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
        timeout: this.config.timeout
      });

      // البحث عن توكن في الصفحة
      const tokenMatches = response.data.match(/token['":\s]*['"]([^'"]+)['"]/gi);
      if (tokenMatches && tokenMatches.length > 0) {
        const token = tokenMatches[0].match(/['"]([^'"]+)['"]/)[1];
        console.log(`🎯 تم العثور على توكن في الصفحة: ${token}`);
        return token;
      }

      return null;
    } catch (error) {
      return null;
    }
  }

  /**
   * اختبار توكن مع API
   */
  async testTokenWithAPI(token) {
    try {
      const response = await axios.get('https://api.alwaseet-iq.net/v1/merchant/statuses', {
        params: { token: token },
        headers: {
          'Content-Type': 'multipart/form-data',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
        timeout: this.config.timeout
      });

      if (response.data.status && response.data.errNum === 'S000') {
        console.log(`✅ توكن صالح: ${token}`);
        return {
          success: true,
          statuses: response.data.data,
          total: response.data.data.length
        };
      }

      return { success: false };
    } catch (error) {
      return { success: false };
    }
  }

  /**
   * استخراج بيانات الطلبات من صفحة التاجر
   */
  extractOrdersFromPage(pageContent) {
    try {
      console.log('🔍 استخراج بيانات الطلبات من الصفحة...');

      const orders = [];

      // البحث عن جدول الطلبات باستخدام regex
      const tableRegex = /<table[^>]*class[^>]*table[^>]*>(.*?)<\/table>/gs;
      const tableMatch = pageContent.match(tableRegex);

      if (!tableMatch) {
        console.log('⚠️ لم يتم العثور على جدول الطلبات');
        return orders;
      }

      const tableContent = tableMatch[0];
      const rowRegex = /<tr[^>]*>(.*?)<\/tr>/gs;
      const rows = tableContent.match(rowRegex) || [];

      console.log(`📊 تم العثور على ${rows.length} صف في الجدول`);

      for (let i = 1; i < rows.length; i++) { // تجاهل الهيدر
        const row = rows[i];
        const cellRegex = /<td[^>]*>(.*?)<\/td>/gs;
        const cells = [];
        let match;

        while ((match = cellRegex.exec(row)) !== null) {
          const cellContent = match[1].replace(/<[^>]*>/g, '').trim();
          cells.push(cellContent);
        }

        if (cells.length >= 4) {
          const order = {
            id: cells[0] || '',
            order_number: cells[1] || '',
            client_name: cells[2] || '',
            status: cells[3] || '',
            status_id: this.getStatusId(cells[3] || ''),
            created_at: cells[4] || '',
            price: cells[5] || '',
            updated_at: new Date().toISOString()
          };

          orders.push(order);
        }
      }

      console.log(`✅ تم استخراج ${orders.length} طلب من الصفحة`);

      // طباعة عينة من الطلبات
      if (orders.length > 0) {
        console.log('📋 عينة من الطلبات:');
        orders.slice(0, 3).forEach((order, index) => {
          console.log(`   ${index + 1}. ID: ${order.id}, الحالة: ${order.status}`);
        });
      }

      return orders;

    } catch (error) {
      console.error('❌ فشل استخراج بيانات الطلبات:', error.message);
      return [];
    }
  }

  /**
   * تحويل نص الحالة إلى ID
   */
  getStatusId(statusText) {
    const statusMap = {
      'تم الاستلام من قبل المندوب': '1',
      'قيد التوصيل': '2',
      'تم التوصيل': '3',
      'مرتجع': '4',
      'ملغي': '5',
      'في انتظار التأكيد': '6',
      'تم التأكيد': '7'
    };

    return statusMap[statusText] || '0';
  }

  /**
   * مزامنة حالات الطلبات مع قاعدة البيانات
   */
  async syncOrderStatuses() {
    try {
      console.log('🔄 بدء مزامنة حالات الطلبات...');

      // جلب الحالات من شركة الوسيط (من صفحة التاجر)
      const statusesResult = await this.getMerchantPageData();
      
      if (!statusesResult.success) {
        throw new Error(`فشل جلب الحالات: ${statusesResult.error}`);
      }

      const waseetOrders = statusesResult.orders;
      
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
          // البحث عن الطلب في بيانات الوسيط
          const waseetOrder = waseetOrders.find(waseetOrder =>
            waseetOrder.id === order.waseet_order_id ||
            waseetOrder.id === order.waseet_order_id?.toString()
          );

          if (waseetOrder) {
            // تحديث حالة الطلب إذا تغيرت
            if (order.waseet_status !== waseetOrder.status) {
              const { error: updateError } = await this.supabase
                .from('orders')
                .update({
                  status: waseetOrder.status,
                  waseet_status: waseetOrder.status,
                  last_status_check: new Date().toISOString(),
                  updated_at: new Date().toISOString()
                })
                .eq('id', order.id);

              if (updateError) {
                errors.push(`فشل تحديث الطلب ${order.order_number}: ${updateError.message}`);
              } else {
                console.log(`✅ تم تحديث الطلب ${order.order_number}: ${order.waseet_status} → ${waseetOrder.status}`);
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
