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
   * تسجيل الدخول للحصول على التوكن حسب API الرسمي
   * POST /v1/merchant/login
   */
  async authenticate() {
    try {
      // التحقق من صحة التوكن الحالي
      if (this.isTokenValid()) {
        return this.loginToken;
      }

      console.log('🔐 تسجيل الدخول لشركة الوسيط باستخدام API الرسمي...');

      // إعداد البيانات حسب التوثيق الرسمي - multipart/form-data
      const FormData = require('form-data');
      const formData = new FormData();
      formData.append('username', this.config.username);
      formData.append('password', this.config.password);

      // استخدام المسار الرسمي المحدد في التوثيق
      const loginUrl = 'https://api.alwaseet-iq.net/v1/merchant/login';
      console.log(`🔗 URL: ${loginUrl}`);
      console.log(`👤 اسم المستخدم: ${this.config.username}`);

      try {
        console.log('📤 إرسال طلب تسجيل الدخول...');

        const response = await axios.post(loginUrl, formData, {
          headers: {
            ...formData.getHeaders(), // للحصول على Content-Type الصحيح لـ multipart/form-data
            'User-Agent': 'Montajati-App/2.2.0'
            },
            timeout: this.config.timeout,
            maxRedirects: 0,
            validateStatus: (status) => status < 500 // قبول حتى 4xx للتحقق
          });

        console.log(`📊 استجابة API: ${response.status}`);
        console.log(`📄 بيانات الاستجابة:`, response.data);

        // معالجة الاستجابة حسب التوثيق الرسمي
        if (response.status === 200 && response.data) {
          const responseData = response.data;

          // التحقق من نجاح العملية حسب التوثيق
          if (responseData.status === true && responseData.errNum === 'S000') {
            // استخراج التوكن من البيانات
            if (responseData.data && responseData.data.token) {
              this.loginToken = responseData.data.token;
              this.tokenExpiry = Date.now() + (30 * 60 * 1000); // صالح لمدة 30 دقيقة

              console.log(`✅ تم تسجيل الدخول بنجاح!`);
              console.log(`🎫 التوكن: ${this.loginToken.substring(0, 20)}...`);
              console.log(`📝 رسالة النجاح: ${responseData.msg}`);

              return this.loginToken;
            } else {
              throw new Error('لم يتم العثور على التوكن في الاستجابة');
            }
          } else {
            // معالجة الأخطاء حسب التوثيق
            const errorCode = responseData.errNum || 'غير محدد';
            const errorMessage = responseData.msg || 'خطأ غير معروف';
            throw new Error(`فشل تسجيل الدخول - كود الخطأ: ${errorCode}, الرسالة: ${errorMessage}`);
          }
        } else {
          throw new Error(`استجابة غير متوقعة من الخادم: ${response.status}`);
        }

            // إذا لم نجد في JSON، جرب الحصول على التوكن من صفحة التاجر
            const cookies = response.headers['set-cookie'];
            if (cookies) {
              const cookieString = cookies.map(cookie => cookie.split(';')[0]).join('; ');
              console.log(`🍪 تم الحصول على الكوكيز: ${cookieString}`);

              // الآن استخدم الكوكيز للوصول لصفحة التاجر والبحث عن التوكن الحقيقي
              try {
                const merchantResponse = await axios.get('https://merchant.alwaseet-iq.net/merchant', {
                  headers: {
                    'Cookie': cookieString,
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
                  },
                  timeout: this.config.timeout
                });

                console.log(`📄 تم جلب صفحة التاجر للبحث عن التوكن`);

                // البحث عن التوكن في الصفحة
                const pageContent = merchantResponse.data;

                // جرب أنماط مختلفة للبحث عن التوكن
                const tokenPatterns = [
                  /token['":\s]*['"]([^'"]+)['"]/gi,
                  /loginToken['":\s]*['"]([^'"]+)['"]/gi,
                  /api_token['":\s]*['"]([^'"]+)['"]/gi,
                  /access_token['":\s]*['"]([^'"]+)['"]/gi,
                  /_token['":\s]*['"]([^'"]+)['"]/gi
                ];

                for (const pattern of tokenPatterns) {
                  const matches = pageContent.match(pattern);
                  if (matches && matches.length > 0) {
                    const tokenMatch = matches[0].match(/['"]([^'"]+)['"]/);
                    if (tokenMatch && tokenMatch[1] && tokenMatch[1].length > 10) {
                      this.loginToken = tokenMatch[1];
                      this.tokenExpiry = Date.now() + (30 * 60 * 1000);
                      console.log(`✅ تم العثور على التوكن في الصفحة: ${this.loginToken}`);
                      return this.loginToken;
                    }
                  }
                }

                // إذا لم نجد توكن، استخدم session ID كبديل
                const sessionMatch = cookieString.match(/ci_session=([^;]+)/);
                if (sessionMatch) {
                  this.loginToken = sessionMatch[1];
                  this.tokenExpiry = Date.now() + (30 * 60 * 1000);
                  console.log(`⚠️ لم يتم العثور على توكن API، استخدام session ID: ${this.loginToken}`);
                  return this.loginToken;
                }

              } catch (merchantError) {
                console.log(`❌ فشل جلب صفحة التاجر: ${merchantError.message}`);

                // استخدم session ID كبديل
                const sessionMatch = cookieString.match(/ci_session=([^;]+)/);
                if (sessionMatch) {
                  this.loginToken = sessionMatch[1];
                  this.tokenExpiry = Date.now() + (30 * 60 * 1000);
                  console.log(`⚠️ استخدام session ID كبديل: ${this.loginToken}`);
                  return this.loginToken;
                }
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

      // جلب الحالات من شركة الوسيط (API الرسمي)
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
