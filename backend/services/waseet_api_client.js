// ===================================
// عميل API الوسيط الرسمي
// Official Waseet API Client
// ===================================

const https = require('https');
const { URLSearchParams } = require('url');

class WaseetAPIClient {
  constructor(username, password) {
    // استخدام متغيرات البيئة إذا لم يتم تمرير البيانات
    this.username = username || process.env.WASEET_USERNAME;
    this.password = password || process.env.WASEET_PASSWORD;
    this.baseURL = 'https://api.alwaseet-iq.net/v1/merchant';
    this.token = null;
    this.tokenExpiresAt = null;

    // التحقق من وجود بيانات المصادقة (تحذير فقط، لا نرمي خطأ)
    if (!this.username || !this.password) {
      console.warn('⚠️ بيانات المصادقة مع الوسيط غير موجودة: WASEET_USERNAME و WASEET_PASSWORD');
      console.warn('💡 سيتم تخطي إرسال الطلبات للوسيط حتى يتم إضافة البيانات');
      this.isConfigured = false;
    } else {
      this.isConfigured = true;
      console.log('✅ تم العثور على بيانات المصادقة مع الوسيط');
    }
  }

  // تسجيل الدخول والحصول على Token
  async login() {
    try {
      // التحقق من وجود بيانات المصادقة
      if (!this.isConfigured) {
        console.warn('⚠️ لا يمكن تسجيل الدخول - بيانات المصادقة غير موجودة');
        return false;
      }

      console.log('🔐 تسجيل الدخول إلى API الوسيط الرسمي...');

      const formData = new URLSearchParams();
      formData.append('username', this.username);
      formData.append('password', this.password);
      
      const response = await this.makeRequest('POST', '/login', formData.toString(), {
        'Content-Type': 'application/x-www-form-urlencoded'
      });

      if (response.data && response.data.status === true && response.data.data && response.data.data.token) {
        this.token = response.data.data.token;
        this.tokenExpiresAt = new Date(Date.now() + (24 * 60 * 60 * 1000)); // 24 ساعة
        
        console.log('✅ تم تسجيل الدخول بنجاح');
        console.log(`🔑 Token: ${this.token.substring(0, 20)}...`);
        
        return true;
      } else {
        console.error('❌ فشل في تسجيل الدخول:', response.data);
        return false;
      }
      
    } catch (error) {
      console.error('❌ خطأ في تسجيل الدخول:', error.message);
      return false;
    }
  }

  // التحقق من صحة Token
  isTokenValid() {
    return this.token && this.tokenExpiresAt && new Date() < this.tokenExpiresAt;
  }

  // تسجيل الدخول التلقائي إذا لزم الأمر
  async ensureAuthenticated() {
    if (!this.isTokenValid()) {
      console.log('🔄 Token منتهي الصلاحية، إعادة تسجيل الدخول...');
      return await this.login();
    }
    return true;
  }

  // جلب جميع حالات الطلبات
  async getOrderStatuses() {
    try {
      console.log('📊 جلب جميع حالات الطلبات من الوسيط...');
      
      if (!await this.ensureAuthenticated()) {
        throw new Error('فشل في المصادقة');
      }

      const response = await this.makeRequest('GET', `/statuses?token=${this.token}`);

      if (response.data && response.data.status === true && response.data.data) {
        const statuses = response.data.data;
        
        console.log(`✅ تم جلب ${statuses.length} حالة من الوسيط`);
        
        console.log('\n📋 جميع حالات الطلبات في الوسيط:');
        console.log('='.repeat(60));
        
        statuses.forEach((status, index) => {
          console.log(`${index + 1}. ID: ${status.id} - "${status.status}"`);
        });
        
        return statuses;
      } else {
        console.error('❌ فشل في جلب الحالات:', response.data);
        return null;
      }
      
    } catch (error) {
      console.error('❌ خطأ في جلب حالات الطلبات:', error.message);
      return null;
    }
  }

  // إنشاء طلب جديد
  async createOrder(orderData) {
    try {
      // التحقق من وجود بيانات المصادقة
      if (!this.isConfigured) {
        console.warn('⚠️ لا يمكن إنشاء طلب - بيانات المصادقة مع الوسيط غير موجودة');
        return {
          success: false,
          error: 'بيانات المصادقة مع الوسيط غير موجودة (WASEET_USERNAME, WASEET_PASSWORD)',
          needsConfiguration: true
        };
      }

      console.log('📦 إنشاء طلب جديد في الوسيط...');
      console.log('📋 بيانات الطلب:', orderData);

      if (!await this.ensureAuthenticated()) {
        throw new Error('فشل في المصادقة');
      }

      // تحضير بيانات الطلب
      const formData = new URLSearchParams();
      formData.append('token', this.token);
      formData.append('clientName', orderData.clientName);
      formData.append('clientMobile', orderData.clientMobile);
      if (orderData.clientMobile2) {
        formData.append('clientMobile2', orderData.clientMobile2);
      }
      formData.append('cityId', orderData.cityId);
      formData.append('regionId', orderData.regionId);
      formData.append('location', orderData.location);
      formData.append('typeName', orderData.typeName);
      formData.append('itemsNumber', orderData.itemsNumber);
      formData.append('price', orderData.price);
      formData.append('packageSize', orderData.packageSize);
      if (orderData.merchantNotes) {
        formData.append('merchantNotes', orderData.merchantNotes);
      }
      formData.append('replacement', orderData.replacement || 0);

      const response = await this.makeRequest('POST', '/create-order', formData.toString(), {
        'Content-Type': 'application/x-www-form-urlencoded'
      });

      if (response.data && response.data.status === true && response.data.data) {
        const orderResult = response.data.data;
        console.log('✅ تم إنشاء الطلب بنجاح');
        console.log(`🆔 QR ID: ${orderResult.qrId || orderResult.id}`);

        return {
          success: true,
          qrId: orderResult.qrId || orderResult.id,
          data: orderResult
        };
      } else {
        console.error('❌ فشل في إنشاء الطلب:', response.data);
        return {
          success: false,
          error: response.data?.message || 'فشل في إنشاء الطلب'
        };
      }

    } catch (error) {
      console.error('❌ خطأ في إنشاء الطلب:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  // جلب حالة طلب محدد
  async getOrderStatus(qrId) {
    try {
      console.log(`🔍 جلب حالة الطلب ${qrId}...`);

      if (!await this.ensureAuthenticated()) {
        throw new Error('فشل في المصادقة');
      }

      const formData = new URLSearchParams();
      formData.append('token', this.token);
      formData.append('qrId', qrId);

      const response = await this.makeRequest('POST', '/get-order-status', formData.toString(), {
        'Content-Type': 'application/x-www-form-urlencoded'
      });

      if (response.data && response.data.status === true && response.data.data) {
        const orderStatus = response.data.data;
        console.log(`✅ تم جلب حالة الطلب ${qrId}: ${orderStatus.status}`);

        return {
          success: true,
          status: orderStatus.status,
          localStatus: this.mapWaseetStatusToLocal(orderStatus.status),
          data: orderStatus
        };
      } else {
        console.error(`❌ فشل في جلب حالة الطلب ${qrId}:`, response.data);
        return {
          success: false,
          error: response.data?.message || 'فشل في جلب حالة الطلب'
        };
      }

    } catch (error) {
      console.error(`❌ خطأ في جلب حالة الطلب ${qrId}:`, error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  // تحويل حالة الوسيط إلى حالة محلية
  mapWaseetStatusToLocal(waseetStatus) {
    const statusMap = {
      'pending': 'in_delivery',
      'picked_up': 'in_delivery',
      'in_transit': 'in_delivery',
      'delivered': 'delivered',
      'returned': 'returned',
      'cancelled': 'cancelled'
    };

    return statusMap[waseetStatus] || 'in_delivery';
  }

  // جلب جميع الطلبات
  async getOrders() {
    try {
      console.log('📦 جلب جميع الطلبات من الوسيط...');
      
      if (!await this.ensureAuthenticated()) {
        throw new Error('فشل في المصادقة');
      }

      const response = await this.makeRequest('GET', `/merchant-orders?token=${this.token}`);

      if (response.data && response.data.status === true && response.data.data) {
        const orders = response.data.data;
        
        console.log(`✅ تم جلب ${orders.length} طلب من الوسيط`);
        
        // استخراج الحالات من الطلبات
        const statusesFromOrders = new Set();
        orders.forEach(order => {
          if (order.status) {
            statusesFromOrders.add(order.status);
          }
        });
        
        if (statusesFromOrders.size > 0) {
          console.log('\n📊 الحالات المستخدمة في الطلبات الفعلية:');
          console.log('-'.repeat(50));
          Array.from(statusesFromOrders).forEach((status, index) => {
            console.log(`${index + 1}. "${status}"`);
          });
        }
        
        return orders;
      } else {
        console.error('❌ فشل في جلب الطلبات:', response.data);
        return null;
      }
      
    } catch (error) {
      console.error('❌ خطأ في جلب الطلبات:', error.message);
      return null;
    }
  }

  // جلب المدن
  async getCities() {
    try {
      if (!await this.ensureAuthenticated()) {
        throw new Error('فشل في المصادقة');
      }

      const response = await this.makeRequest('GET', `/citys?token=${this.token}`);
      
      if (response.data && response.data.status === true && response.data.data) {
        console.log(`✅ تم جلب ${response.data.data.length} مدينة`);
        return response.data.data;
      }
      
      return null;
    } catch (error) {
      console.error('❌ خطأ في جلب المدن:', error.message);
      return null;
    }
  }

  // جلب أحجام الطرود
  async getPackageSizes() {
    try {
      if (!await this.ensureAuthenticated()) {
        throw new Error('فشل في المصادقة');
      }

      const response = await this.makeRequest('GET', `/package-sizes?token=${this.token}`);
      
      if (response.data && response.data.status === true && response.data.data) {
        console.log(`✅ تم جلب ${response.data.data.length} حجم طرد`);
        return response.data.data;
      }
      
      return null;
    } catch (error) {
      console.error('❌ خطأ في جلب أحجام الطرود:', error.message);
      return null;
    }
  }

  // دالة مساعدة لإرسال الطلبات
  makeRequest(method, path, data = null, extraHeaders = {}) {
    return new Promise((resolve, reject) => {
      const url = new URL(this.baseURL + path);
      
      const options = {
        hostname: url.hostname,
        port: url.port || 443,
        path: url.pathname + url.search,
        method: method,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Montajati-App/1.0',
          ...extraHeaders
        },
        timeout: 30000
      };

      if (data && method !== 'GET') {
        options.headers['Content-Length'] = Buffer.byteLength(data);
      }

      const req = https.request(options, (res) => {
        let responseData = '';
        
        res.on('data', (chunk) => {
          responseData += chunk;
        });
        
        res.on('end', () => {
          try {
            const parsedData = responseData ? JSON.parse(responseData) : {};
            resolve({
              statusCode: res.statusCode,
              headers: res.headers,
              data: parsedData,
              rawData: responseData
            });
          } catch (parseError) {
            resolve({
              statusCode: res.statusCode,
              headers: res.headers,
              data: null,
              rawData: responseData,
              parseError: parseError.message
            });
          }
        });
      });

      req.on('error', (error) => {
        reject(error);
      });

      req.on('timeout', () => {
        req.destroy();
        reject(new Error('Request timeout'));
      });

      if (data && method !== 'GET') {
        req.write(data);
      }
      
      req.end();
    });
  }

  // تحليل شامل لجميع البيانات
  async getCompleteAnalysis() {
    try {
      console.log('🔍 بدء التحليل الشامل لـ API الوسيط...\n');
      
      const results = {
        statuses: null,
        orders: null,
        cities: null,
        packageSizes: null,
        summary: {}
      };

      // 1. جلب الحالات
      results.statuses = await this.getOrderStatuses();
      
      // 2. جلب الطلبات
      results.orders = await this.getOrders();
      
      // 3. جلب المدن
      results.cities = await this.getCities();
      
      // 4. جلب أحجام الطرود
      results.packageSizes = await this.getPackageSizes();

      // 5. إنشاء ملخص
      results.summary = {
        totalStatuses: results.statuses ? results.statuses.length : 0,
        totalOrders: results.orders ? results.orders.length : 0,
        totalCities: results.cities ? results.cities.length : 0,
        totalPackageSizes: results.packageSizes ? results.packageSizes.length : 0,
        timestamp: new Date().toISOString()
      };

      console.log('\n📊 ملخص التحليل الشامل:');
      console.log('='.repeat(50));
      console.log(`📋 إجمالي الحالات: ${results.summary.totalStatuses}`);
      console.log(`📦 إجمالي الطلبات: ${results.summary.totalOrders}`);
      console.log(`🏙️ إجمالي المدن: ${results.summary.totalCities}`);
      console.log(`📏 إجمالي أحجام الطرود: ${results.summary.totalPackageSizes}`);

      return results;
      
    } catch (error) {
      console.error('❌ خطأ في التحليل الشامل:', error.message);
      return null;
    }
  }
}

module.exports = WaseetAPIClient;
