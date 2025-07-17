// ===================================
// اختبار تسجيل الدخول لشركة الوسيط
// فحص جميع الطرق المختلفة لتسجيل الدخول
// ===================================

const axios = require('axios');
require('dotenv').config();

class WaseetLoginTester {
  constructor() {
    this.baseUrl = 'https://api.alwaseet-iq.net';
    this.username = process.env.WASEET_USERNAME || 'محمد@mustfaabd';
    this.password = process.env.WASEET_PASSWORD || 'mustfaabd2006@';
    
    console.log('🧪 تم تهيئة اختبار تسجيل الدخول لشركة الوسيط');
    console.log(`👤 اسم المستخدم: ${this.username}`);
    console.log(`🔑 كلمة المرور: ${this.password}`);
  }

  // ===================================
  // الطريقة الأولى: JSON POST
  // ===================================
  async testJsonLogin() {
    try {
      console.log('\n🔄 اختبار الطريقة الأولى: JSON POST');
      
      const response = await axios.post(`${this.baseUrl}/merchant/login`, {
        username: this.username,
        password: this.password
      }, {
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
        timeout: 30000
      });

      console.log('📊 حالة الاستجابة:', response.status);
      console.log('📊 البيانات:', response.data);
      console.log('🍪 Cookies:', response.headers['set-cookie']);

      if (response.data && response.data.status) {
        console.log('✅ نجح تسجيل الدخول بطريقة JSON');
        return { success: true, method: 'JSON', data: response.data };
      } else {
        console.log('❌ فشل تسجيل الدخول بطريقة JSON');
        return { success: false, method: 'JSON', error: 'لا توجد بيانات صحيحة' };
      }
    } catch (error) {
      console.log('❌ خطأ في طريقة JSON:', error.message);
      return { success: false, method: 'JSON', error: error.message };
    }
  }

  // ===================================
  // الطريقة الثانية: Form Data
  // ===================================
  async testFormLogin() {
    try {
      console.log('\n🔄 اختبار الطريقة الثانية: Form Data');
      
      const loginData = new URLSearchParams();
      loginData.append('username', this.username);
      loginData.append('password', this.password);

      const response = await axios.post(`${this.baseUrl}/merchant/login`, loginData, {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
        timeout: 30000
      });

      console.log('📊 حالة الاستجابة:', response.status);
      console.log('📊 البيانات:', response.data);
      console.log('🍪 Cookies:', response.headers['set-cookie']);

      if (response.data && response.data.status) {
        console.log('✅ نجح تسجيل الدخول بطريقة Form Data');
        return { success: true, method: 'Form', data: response.data };
      } else {
        console.log('❌ فشل تسجيل الدخول بطريقة Form Data');
        return { success: false, method: 'Form', error: 'لا توجد بيانات صحيحة' };
      }
    } catch (error) {
      console.log('❌ خطأ في طريقة Form Data:', error.message);
      return { success: false, method: 'Form', error: error.message };
    }
  }

  // ===================================
  // الطريقة الثالثة: Cookie-based (مثل الخادم الرئيسي)
  // ===================================
  async testCookieLogin() {
    try {
      console.log('\n🔄 اختبار الطريقة الثالثة: Cookie-based');
      
      const loginUrl = `${this.baseUrl}/merchant/login`;

      // جلب صفحة تسجيل الدخول للحصول على cookies
      console.log('📄 جلب صفحة تسجيل الدخول...');
      const loginPageResponse = await axios.get(loginUrl, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
        timeout: 30000
      });

      const cookies = loginPageResponse.headers['set-cookie'] || [];
      const cookieString = cookies.map(cookie => cookie.split(';')[0]).join('; ');
      console.log('🍪 Cookies من الصفحة:', cookieString);

      // إرسال بيانات تسجيل الدخول
      const loginData = new URLSearchParams();
      loginData.append('username', this.username);
      loginData.append('password', this.password);

      const response = await axios.post(loginUrl, loginData, {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cookie': cookieString,
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
        timeout: 30000,
        maxRedirects: 0,
        validateStatus: function (status) {
          return status < 400;
        }
      });

      console.log('📊 حالة الاستجابة:', response.status);
      console.log('🍪 Cookies الجديدة:', response.headers['set-cookie']);

      // التحقق من نجاح تسجيل الدخول
      const newCookies = response.headers['set-cookie'] || [];
      const allCookies = [...cookies, ...newCookies];
      const finalCookieString = allCookies.map(cookie => cookie.split(';')[0]).join('; ');

      if (finalCookieString && finalCookieString.includes('PHPSESSID')) {
        console.log('✅ نجح تسجيل الدخول بطريقة Cookie');
        return { success: true, method: 'Cookie', token: finalCookieString };
      } else {
        console.log('❌ فشل تسجيل الدخول بطريقة Cookie');
        return { success: false, method: 'Cookie', error: 'لا توجد session صحيحة' };
      }
    } catch (error) {
      console.log('❌ خطأ في طريقة Cookie:', error.message);
      return { success: false, method: 'Cookie', error: error.message };
    }
  }

  // ===================================
  // الطريقة الرابعة: API v1
  // ===================================
  async testApiV1Login() {
    try {
      console.log('\n🔄 اختبار الطريقة الرابعة: API v1');
      
      const response = await axios.post(`${this.baseUrl}/v1/merchant/login`, {
        username: this.username,
        password: this.password
      }, {
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
        timeout: 30000
      });

      console.log('📊 حالة الاستجابة:', response.status);
      console.log('📊 البيانات:', response.data);

      if (response.data && response.data.token) {
        console.log('✅ نجح تسجيل الدخول بطريقة API v1');
        return { success: true, method: 'API v1', token: response.data.token };
      } else {
        console.log('❌ فشل تسجيل الدخول بطريقة API v1');
        return { success: false, method: 'API v1', error: 'لا يوجد توكن' };
      }
    } catch (error) {
      console.log('❌ خطأ في طريقة API v1:', error.message);
      return { success: false, method: 'API v1', error: error.message };
    }
  }

  // ===================================
  // اختبار فحص حالة طلب
  // ===================================
  async testOrderStatus(token, method) {
    try {
      console.log(`\n🔍 اختبار فحص حالة طلب باستخدام ${method}...`);
      
      // استخدام معرف طلب تجريبي
      const testOrderId = '95580376'; // معرف طلب موجود
      
      let headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      };

      let url = `${this.baseUrl}/merchant/get_order_status`;
      let params = { order_id: testOrderId };

      if (method === 'Cookie') {
        headers['Cookie'] = token;
      } else if (method === 'API v1') {
        url = `${this.baseUrl}/v1/merchant/get_order_status`;
        params.token = token;
      }

      const response = await axios.get(url, {
        params,
        headers,
        timeout: 15000
      });

      console.log('📊 حالة الاستجابة:', response.status);
      console.log('📊 البيانات:', response.data);

      if (response.data && response.data.status) {
        console.log('✅ نجح فحص حالة الطلب');
        return { success: true, data: response.data };
      } else {
        console.log('❌ فشل فحص حالة الطلب');
        return { success: false, error: 'لا توجد بيانات صحيحة' };
      }
    } catch (error) {
      console.log('❌ خطأ في فحص حالة الطلب:', error.message);
      return { success: false, error: error.message };
    }
  }

  // ===================================
  // تشغيل جميع الاختبارات
  // ===================================
  async runAllTests() {
    console.log('🚀 بدء اختبار جميع طرق تسجيل الدخول لشركة الوسيط');
    console.log('=' .repeat(60));

    const results = [];

    // اختبار جميع الطرق
    const tests = [
      this.testJsonLogin(),
      this.testFormLogin(),
      this.testCookieLogin(),
      this.testApiV1Login()
    ];

    for (const test of tests) {
      const result = await test;
      results.push(result);

      // إذا نجح تسجيل الدخول، اختبر فحص حالة الطلب
      if (result.success && (result.token || result.data)) {
        const token = result.token || result.data.token;
        if (token) {
          const statusTest = await this.testOrderStatus(token, result.method);
          result.statusTest = statusTest;
        }
      }

      // انتظار قصير بين الاختبارات
      await new Promise(resolve => setTimeout(resolve, 2000));
    }

    // عرض النتائج النهائية
    console.log('\n' + '=' .repeat(60));
    console.log('📊 نتائج اختبار تسجيل الدخول:');
    
    const successfulMethods = results.filter(r => r.success);
    const failedMethods = results.filter(r => !r.success);

    console.log(`✅ طرق ناجحة: ${successfulMethods.length}`);
    console.log(`❌ طرق فاشلة: ${failedMethods.length}`);

    if (successfulMethods.length > 0) {
      console.log('\n🎉 الطرق الناجحة:');
      successfulMethods.forEach(method => {
        console.log(`  ✅ ${method.method}`);
        if (method.statusTest) {
          console.log(`     📊 فحص الحالة: ${method.statusTest.success ? 'نجح' : 'فشل'}`);
        }
      });

      // اختيار أفضل طريقة
      const bestMethod = successfulMethods.find(m => m.statusTest && m.statusTest.success) || 
                        successfulMethods[0];
      
      console.log(`\n🏆 أفضل طريقة للاستخدام: ${bestMethod.method}`);
      
      return {
        success: true,
        bestMethod: bestMethod.method,
        token: bestMethod.token || bestMethod.data?.token,
        allResults: results
      };
    } else {
      console.log('\n❌ جميع الطرق فشلت');
      console.log('🔍 الأخطاء:');
      failedMethods.forEach(method => {
        console.log(`  ❌ ${method.method}: ${method.error}`);
      });

      return {
        success: false,
        allResults: results
      };
    }
  }
}

// تشغيل الاختبار إذا تم استدعاء الملف مباشرة
if (require.main === module) {
  const tester = new WaseetLoginTester();
  
  tester.runAllTests()
    .then(results => {
      if (results.success) {
        console.log(`\n🎯 النتيجة: استخدم طريقة ${results.bestMethod} لتسجيل الدخول`);
        process.exit(0);
      } else {
        console.log('\n💥 فشل في جميع طرق تسجيل الدخول');
        process.exit(1);
      }
    })
    .catch(error => {
      console.error('❌ خطأ في تشغيل الاختبارات:', error);
      process.exit(1);
    });
}

module.exports = WaseetLoginTester;
