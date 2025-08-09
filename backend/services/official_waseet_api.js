const axios = require('axios');
const FormData = require('form-data');

/**
 * خدمة API الوسيط الرسمية حسب التوثيق المحدث
 * URL: https://api.alwaseet-iq.net/v1/merchant/login
 * Method: POST
 * Content-Type: multipart/form-data
 */
class OfficialWaseetAPI {
  constructor(username, password) {
    this.username = username;
    this.password = password;
    this.baseUrl = 'https://api.alwaseet-iq.net';
    this.token = null;
    this.tokenExpiry = null;
    this.timeout = 30000;
  }

  /**
   * تسجيل الدخول حسب API الرسمي
   * POST /v1/merchant/login
   * Content-Type: multipart/form-data
   */
  async authenticate() {
    try {
      // التحقق من صحة التوكن الحالي
      if (this.isTokenValid()) {
        console.log('✅ استخدام التوكن الحالي الصالح');
        return this.token;
      }

      console.log('🔐 تسجيل الدخول باستخدام API الرسمي...');
      console.log(`👤 اسم المستخدم: ${this.username}`);

      // إعداد البيانات حسب التوثيق الرسمي - multipart/form-data
      const formData = new FormData();
      formData.append('username', this.username);
      formData.append('password', this.password);

      const loginUrl = `${this.baseUrl}/v1/merchant/login`;
      console.log(`🔗 URL: ${loginUrl}`);

      const response = await axios.post(loginUrl, formData, {
        headers: {
          ...formData.getHeaders(), // للحصول على Content-Type الصحيح
          'User-Agent': 'Montajati-App/2.2.0'
        },
        timeout: this.timeout,
        validateStatus: (status) => status < 500 // قبول حتى 4xx للتحقق
      });

      console.log(`📊 كود الاستجابة: ${response.status}`);
      console.log(`📄 بيانات الاستجابة:`, response.data);

      // معالجة الاستجابة حسب التوثيق الرسمي
      if (response.status === 200 && response.data) {
        const responseData = response.data;
        
        // التحقق من نجاح العملية حسب التوثيق
        if (responseData.status === true && responseData.errNum === 'S000') {
          // استخراج التوكن من البيانات
          if (responseData.data && responseData.data.token) {
            this.token = responseData.data.token;
            this.tokenExpiry = Date.now() + (30 * 60 * 1000); // صالح لمدة 30 دقيقة
            
            console.log(`✅ تم تسجيل الدخول بنجاح!`);
            console.log(`🎫 التوكن: ${this.token.substring(0, 20)}...`);
            console.log(`📝 رسالة النجاح: ${responseData.msg}`);
            
            return this.token;
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

    } catch (error) {
      console.error('❌ فشل تسجيل الدخول:', error.message);
      
      // طباعة تفاصيل الخطأ للتشخيص
      if (error.response) {
        console.error(`📊 كود الاستجابة: ${error.response.status}`);
        console.error(`📄 بيانات الخطأ:`, error.response.data);
      }
      
      throw new Error(`فشل في تسجيل الدخول: ${error.message}`);
    }
  }

  /**
   * التحقق من صحة التوكن
   */
  isTokenValid() {
    return this.token && this.tokenExpiry && Date.now() < this.tokenExpiry;
  }

  /**
   * جلب حالات الطلبات من API الوسيط
   * سأجرب عدة endpoints محتملة
   */
  async getOrderStatuses() {
    try {
      // التأكد من تسجيل الدخول
      const token = await this.authenticate();

      console.log('📊 جلب حالات الطلبات من الوسيط...');
      console.log(`🎫 استخدام التوكن: ${token.substring(0, 20)}...`);

      // قائمة endpoints محتملة لجلب الحالات
      const possibleEndpoints = [
        '/v1/merchant/orders',
        '/v1/merchant/statuses',
        '/v1/orders',
        '/v1/statuses',
        '/merchant/orders',
        '/merchant/statuses',
        '/orders',
        '/statuses'
      ];

      let lastError = null;

      for (const endpoint of possibleEndpoints) {
        try {
          const fullUrl = `${this.baseUrl}${endpoint}`;
          console.log(`🔍 جرب endpoint: ${fullUrl}`);

          // جرب مع التوكن في query parameter
          const response = await axios.get(fullUrl, {
            params: {
              token: token
            },
            headers: {
              'User-Agent': 'Montajati-App/2.2.0',
              'Accept': 'application/json'
            },
            timeout: this.timeout,
            validateStatus: (status) => status < 500
          });

          console.log(`📊 استجابة ${endpoint}: ${response.status}`);

          if (response.status === 200 && response.data) {
            console.log(`✅ نجح endpoint: ${endpoint}`);
            console.log(`📄 بيانات الاستجابة:`, response.data);

            return {
              success: true,
              endpoint: endpoint,
              data: response.data,
              total: Array.isArray(response.data) ? response.data.length :
                     (response.data.data && Array.isArray(response.data.data)) ? response.data.data.length : 'غير محدد'
            };
          }

        } catch (error) {
          console.log(`❌ فشل ${endpoint}: ${error.response?.status || error.message}`);
          lastError = error;

          // إذا كان 401 أو 403، قد يكون التوكن خاطئ
          if (error.response?.status === 401 || error.response?.status === 403) {
            console.log('🔄 إعادة تعيين التوكن والمحاولة مرة أخرى...');
            this.resetToken();
            break; // اخرج من الحلقة وأعد المحاولة
          }

          continue;
        }
      }

      // إذا فشلت جميع المحاولات، جرب مع التوكن في header
      console.log('🔄 جرب مع التوكن في Authorization header...');

      for (const endpoint of possibleEndpoints.slice(0, 4)) { // جرب أهم 4 endpoints فقط
        try {
          const fullUrl = `${this.baseUrl}${endpoint}`;
          console.log(`🔍 جرب مع header: ${fullUrl}`);

          const response = await axios.get(fullUrl, {
            headers: {
              'Authorization': `Bearer ${token}`,
              'User-Agent': 'Montajati-App/2.2.0',
              'Accept': 'application/json'
            },
            timeout: this.timeout,
            validateStatus: (status) => status < 500
          });

          console.log(`📊 استجابة ${endpoint} مع header: ${response.status}`);

          if (response.status === 200 && response.data) {
            console.log(`✅ نجح endpoint مع header: ${endpoint}`);
            console.log(`📄 بيانات الاستجابة:`, response.data);

            return {
              success: true,
              endpoint: endpoint,
              method: 'header',
              data: response.data,
              total: Array.isArray(response.data) ? response.data.length :
                     (response.data.data && Array.isArray(response.data.data)) ? response.data.data.length : 'غير محدد'
            };
          }

        } catch (error) {
          console.log(`❌ فشل ${endpoint} مع header: ${error.response?.status || error.message}`);
          lastError = error;
          continue;
        }
      }

      // إذا فشل كل شيء
      throw new Error(`فشل في جلب الحالات من جميع endpoints. آخر خطأ: ${lastError?.message}`);

    } catch (error) {
      console.error('❌ فشل جلب حالات الطلبات:', error.message);
      return {
        success: false,
        error: error.message,
        details: error.response?.data || null
      };
    }
  }

  /**
   * جلب حالة طلب محدد من الوسيط
   */
  async getOrderStatus(waseetOrderId) {
    try {
      // التأكد من تسجيل الدخول
      const token = await this.authenticate();

      console.log(`🔍 جلب حالة الطلب ${waseetOrderId}...`);

      // قائمة endpoints محتملة لجلب حالة طلب محدد
      const possibleEndpoints = [
        `/v1/merchant/order/${waseetOrderId}`,
        `/v1/merchant/orders/${waseetOrderId}`,
        `/v1/order/${waseetOrderId}`,
        `/v1/orders/${waseetOrderId}`,
        `/merchant/order/${waseetOrderId}`,
        `/merchant/orders/${waseetOrderId}`
      ];

      let lastError = null;

      for (const endpoint of possibleEndpoints) {
        try {
          const fullUrl = `${this.baseUrl}${endpoint}`;
          console.log(`🔍 جرب endpoint: ${fullUrl}`);

          // جرب مع التوكن في query parameter
          const response = await axios.get(fullUrl, {
            params: {
              token: token
            },
            headers: {
              'User-Agent': 'Montajati-App/2.2.0',
              'Accept': 'application/json'
            },
            timeout: this.timeout,
            validateStatus: (status) => status < 500
          });

          console.log(`📊 استجابة ${endpoint}: ${response.status}`);

          if (response.status === 200 && response.data) {
            console.log(`✅ نجح endpoint: ${endpoint}`);
            console.log(`📄 بيانات الطلب:`, response.data);

            return {
              success: true,
              endpoint: endpoint,
              data: response.data
            };
          }

        } catch (error) {
          console.log(`❌ فشل ${endpoint}: ${error.response?.status || error.message}`);
          lastError = error;
          continue;
        }
      }

      // إذا فشلت جميع المحاولات، جرب مع التوكن في header
      console.log('🔄 جرب مع التوكن في Authorization header...');

      for (const endpoint of possibleEndpoints.slice(0, 3)) { // جرب أهم 3 endpoints فقط
        try {
          const fullUrl = `${this.baseUrl}${endpoint}`;
          console.log(`🔍 جرب مع header: ${fullUrl}`);

          const response = await axios.get(fullUrl, {
            headers: {
              'Authorization': `Bearer ${token}`,
              'User-Agent': 'Montajati-App/2.2.0',
              'Accept': 'application/json'
            },
            timeout: this.timeout,
            validateStatus: (status) => status < 500
          });

          console.log(`📊 استجابة ${endpoint} مع header: ${response.status}`);

          if (response.status === 200 && response.data) {
            console.log(`✅ نجح endpoint مع header: ${endpoint}`);
            console.log(`📄 بيانات الطلب:`, response.data);

            return {
              success: true,
              endpoint: endpoint,
              method: 'header',
              data: response.data
            };
          }

        } catch (error) {
          console.log(`❌ فشل ${endpoint} مع header: ${error.response?.status || error.message}`);
          lastError = error;
          continue;
        }
      }

      // إذا فشل كل شيء
      throw new Error(`فشل في جلب حالة الطلب ${waseetOrderId}. آخر خطأ: ${lastError?.message}`);

    } catch (error) {
      console.error(`❌ فشل جلب حالة الطلب ${waseetOrderId}:`, error.message);
      return {
        success: false,
        error: error.message,
        details: error.response?.data || null
      };
    }
  }

  /**
   * جلب جميع طلبات التاجر (API الرسمي)
   */
  async getAllMerchantOrders() {
    try {
      // التأكد من تسجيل الدخول
      const token = await this.authenticate();

      console.log('📊 جلب جميع طلبات التاجر من API الرسمي...');

      const response = await axios.get(`${this.baseUrl}/v1/merchant/merchant-orders`, {
        params: {
          token: token
        },
        headers: {
          'User-Agent': 'Montajati-App/2.2.0',
          'Accept': 'application/json'
        },
        timeout: this.timeout,
        validateStatus: (status) => status < 500
      });

      console.log(`📊 استجابة جلب الطلبات: ${response.status}`);

      if (response.status === 200 && response.data) {
        const responseData = response.data;

        if (responseData.status === true && responseData.errNum === 'S000') {
          const orders = responseData.data || [];
          console.log(`✅ تم جلب ${orders.length} طلب بنجاح`);

          return {
            success: true,
            orders: orders,
            total: orders.length
          };
        } else {
          throw new Error(`فشل API: ${responseData.errNum} - ${responseData.msg}`);
        }
      } else {
        throw new Error(`استجابة غير متوقعة: ${response.status}`);
      }

    } catch (error) {
      console.error('❌ فشل جلب طلبات التاجر:', error.message);
      return {
        success: false,
        error: error.message,
        details: error.response?.data || null
      };
    }
  }

  /**
   * جلب طلبات محددة بالـ IDs (API الرسمي)
   */
  async getOrdersByIds(orderIds) {
    try {
      // التأكد من تسجيل الدخول
      const token = await this.authenticate();

      if (!Array.isArray(orderIds) || orderIds.length === 0) {
        throw new Error('يجب تمرير مصفوفة من IDs الطلبات');
      }

      // حد أقصى 25 طلب حسب التوثيق
      const limitedIds = orderIds.slice(0, 25);
      const idsString = limitedIds.join(',');

      console.log(`📊 جلب ${limitedIds.length} طلب محدد من API الرسمي...`);

      const FormData = require('form-data');
      const formData = new FormData();
      formData.append('ids', idsString);

      const response = await axios.post(`${this.baseUrl}/v1/merchant/get-orders-by-ids-bulk`, formData, {
        params: {
          token: token
        },
        headers: {
          ...formData.getHeaders(),
          'User-Agent': 'Montajati-App/2.2.0',
          'Accept': 'application/json'
        },
        timeout: this.timeout,
        validateStatus: (status) => status < 500
      });

      console.log(`📊 استجابة جلب الطلبات المحددة: ${response.status}`);

      if (response.status === 200 && response.data) {
        const responseData = response.data;

        if (responseData.status === true && responseData.errNum === 'S000') {
          const orders = responseData.data || [];
          console.log(`✅ تم جلب ${orders.length} طلب محدد بنجاح`);

          return {
            success: true,
            orders: orders,
            total: orders.length,
            requestedIds: limitedIds
          };
        } else {
          throw new Error(`فشل API: ${responseData.errNum} - ${responseData.msg}`);
        }
      } else {
        throw new Error(`استجابة غير متوقعة: ${response.status}`);
      }

    } catch (error) {
      console.error('❌ فشل جلب الطلبات المحددة:', error.message);
      return {
        success: false,
        error: error.message,
        details: error.response?.data || null
      };
    }
  }

  /**
   * إعادة تعيين التوكن
   */
  resetToken() {
    this.token = null;
    this.tokenExpiry = null;
    console.log('🔄 تم إعادة تعيين التوكن');
  }
}

module.exports = OfficialWaseetAPI;
