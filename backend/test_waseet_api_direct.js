// ===================================
// اختبار مباشر لـ API الوسيط
// Direct Waseet API Test
// ===================================

require('dotenv').config();
const https = require('https');
const { URLSearchParams } = require('url');

class WaseetAPITester {
  constructor() {
    this.username = process.env.WASEET_USERNAME;
    this.password = process.env.WASEET_PASSWORD;
    this.baseURL = 'https://api.alwaseet-iq.net/v1/merchant';
    this.token = null;
  }

  // دالة مساعدة لإرسال الطلبات
  makeRequest(method, url, data = null, headers = {}) {
    return new Promise((resolve) => {
      const urlObj = new URL(url);
      
      const options = {
        hostname: urlObj.hostname,
        port: 443,
        path: urlObj.pathname + urlObj.search,
        method: method,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Waseet-API-Tester/1.0',
          ...headers
        },
        timeout: 30000
      };

      if (data && (method === 'POST' || method === 'PUT')) {
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
              success: res.statusCode >= 200 && res.statusCode < 300,
              status: res.statusCode,
              data: parsedData,
              rawResponse: responseData
            });
          } catch (parseError) {
            resolve({
              success: false,
              status: res.statusCode,
              error: 'فشل في تحليل الاستجابة',
              rawResponse: responseData
            });
          }
        });
      });

      req.on('error', (error) => {
        resolve({
          success: false,
          error: error.message
        });
      });

      req.on('timeout', () => {
        req.destroy();
        resolve({
          success: false,
          error: 'انتهت مهلة الاتصال'
        });
      });

      if (data && (method === 'POST' || method === 'PUT')) {
        req.write(data);
      }

      req.end();
    });
  }

  // اختبار تسجيل الدخول
  async testLogin() {
    console.log('🔐 اختبار تسجيل الدخول...');
    
    if (!this.username || !this.password) {
      console.error('❌ بيانات المصادقة غير موجودة');
      return false;
    }

    console.log(`📝 اسم المستخدم: ${this.username}`);
    console.log(`🔑 كلمة المرور: ${this.password.substring(0, 3)}***`);

    const formData = new URLSearchParams();
    formData.append('username', this.username);
    formData.append('password', this.password);
    
    const response = await this.makeRequest('POST', `${this.baseURL}/login`, formData.toString());

    console.log(`📊 حالة الاستجابة: ${response.status}`);
    console.log(`📋 الاستجابة:`, JSON.stringify(response.data, null, 2));

    if (response.success && response.data?.status === true && response.data?.data?.token) {
      this.token = response.data.data.token;
      console.log(`✅ تم تسجيل الدخول بنجاح`);
      console.log(`🔑 Token: ${this.token.substring(0, 20)}...`);
      return true;
    } else {
      console.error('❌ فشل في تسجيل الدخول');
      return false;
    }
  }

  // اختبار إنشاء طلب
  async testCreateOrder() {
    console.log('\n📦 اختبار إنشاء طلب...');
    
    if (!this.token) {
      console.error('❌ لا يوجد token - يجب تسجيل الدخول أولاً');
      return false;
    }

    // بيانات طلب تجريبي حسب التعليمات الرسمية من شركة الوسيط
    const orderData = {
      client_name: 'عميل تجريبي',
      client_mobile: '+9647901234567', // تنسيق صحيح للرقم العراقي
      client_mobile2: '+9647901234568',
      city_id: 1, // بغداد
      region_id: 1,
      location: 'عنوان تجريبي - منطقة الكرادة',
      type_name: 'منتج تجريبي',
      items_number: 1,
      price: 25000,
      package_size: 1, // ID حجم الطرد
      merchant_notes: 'طلب تجريبي من النظام',
      replacement: 0
    };

    const formData = new URLSearchParams();
    Object.entries(orderData).forEach(([key, value]) => {
      if (value !== undefined && value !== null) {
        formData.append(key, value);
      }
    });

    console.log('📋 بيانات الطلب:', orderData);

    // اختبار الطريقة الجديدة: token في URL
    console.log('\n🧪 اختبار الطريقة الجديدة: token في URL...');
    const newResponse = await this.makeRequest('POST', `${this.baseURL}/create-order?token=${this.token}`, formData.toString());

    console.log(`📊 حالة الاستجابة (طريقة جديدة): ${newResponse.status}`);
    console.log(`📋 الاستجابة (طريقة جديدة):`, JSON.stringify(newResponse.data, null, 2));

    if (newResponse.success && newResponse.data?.status === true) {
      console.log('🎉 نجح! الطريقة الجديدة تعمل (token في URL)');
      return true;
    }

    // اختبار الطريقة القديمة: token في body
    console.log('\n🧪 اختبار الطريقة القديمة: token في body...');
    const formDataWithToken = new URLSearchParams();
    formDataWithToken.append('token', this.token);
    Object.entries(orderData).forEach(([key, value]) => {
      if (value !== undefined && value !== null) {
        formDataWithToken.append(key, value);
      }
    });

    const oldResponse = await this.makeRequest('POST', `${this.baseURL}/create-order`, formDataWithToken.toString());

    console.log(`📊 حالة الاستجابة (طريقة قديمة): ${oldResponse.status}`);
    console.log(`📋 الاستجابة (طريقة قديمة):`, JSON.stringify(oldResponse.data, null, 2));

    if (oldResponse.success && oldResponse.data?.status === true) {
      console.log('🎉 نجح! الطريقة القديمة تعمل (token في body)');
      return true;
    }

    console.error('❌ فشل في إنشاء الطلب بكلا الطريقتين');
    return false;
  }

  // تشغيل جميع الاختبارات
  async runAllTests() {
    console.log('🧪 بدء اختبار API الوسيط المباشر...');
    console.log('='.repeat(60));

    try {
      // اختبار تسجيل الدخول
      const loginSuccess = await this.testLogin();
      
      if (loginSuccess) {
        // اختبار إنشاء طلب
        const createOrderSuccess = await this.testCreateOrder();
        
        console.log('\n🎯 النتيجة النهائية:');
        if (createOrderSuccess) {
          console.log('🎉 جميع الاختبارات نجحت! API الوسيط يعمل بشكل مثالي');
          return true;
        } else {
          console.log('⚠️ تسجيل الدخول نجح لكن إنشاء الطلب فشل');
          return 'partial';
        }
      } else {
        console.log('❌ فشل في تسجيل الدخول');
        return false;
      }
    } catch (error) {
      console.error('❌ خطأ في الاختبار:', error);
      return false;
    }
  }
}

// تشغيل الاختبار
async function runWaseetAPITest() {
  const tester = new WaseetAPITester();
  
  try {
    const result = await tester.runAllTests();
    
    console.log('\n🎯 انتهى اختبار API الوسيط');
    return result;
  } catch (error) {
    console.error('❌ خطأ في تشغيل الاختبار:', error);
    return false;
  }
}

// تشغيل الاختبار إذا تم استدعاء الملف مباشرة
if (require.main === module) {
  runWaseetAPITest()
    .then((result) => {
      if (result === true) {
        console.log('\n✅ API الوسيط يعمل بشكل مثالي!');
        process.exit(0);
      } else if (result === 'partial') {
        console.log('\n⚠️ API الوسيط يعمل جزئياً - يحتاج فحص إضافي');
        process.exit(0);
      } else {
        console.log('\n❌ API الوسيط لا يعمل');
        process.exit(1);
      }
    })
    .catch((error) => {
      console.error('\n❌ خطأ في تشغيل اختبار API الوسيط:', error);
      process.exit(1);
    });
}

module.exports = { WaseetAPITester, runWaseetAPITest };
