// ===================================
// اختبار شامل للاتصال مع شركة الوسيط
// Comprehensive Waseet Connection Test
// ===================================

const axios = require('axios');
const https = require('https');
require('dotenv').config();

class WaseetConnectionTester {
  constructor() {
    this.config = {
      baseUrl: process.env.ALMASEET_BASE_URL || 'https://api.alwaseet-iq.net',
      username: process.env.WASEET_USERNAME,
      password: process.env.WASEET_PASSWORD,
      timeout: 15000
    };

    this.testResults = {
      connectivity: false,
      authentication: false,
      apiAccess: false,
      orderRetrieval: false,
      statusCheck: false,
      errors: []
    };

    console.log('🧪 تهيئة اختبار الاتصال مع شركة الوسيط...');
  }

  // ===================================
  // اختبار الاتصال الأساسي
  // ===================================
  async testBasicConnectivity() {
    try {
      console.log('\n🔗 اختبار 1: الاتصال الأساسي...');
      
      const response = await axios.get(this.config.baseUrl, {
        timeout: this.config.timeout,
        validateStatus: () => true // قبول جميع رموز الحالة
      });

      if (response.status < 500) {
        console.log('✅ الاتصال الأساسي ناجح');
        console.log(`📊 رمز الحالة: ${response.status}`);
        this.testResults.connectivity = true;
        return true;
      } else {
        throw new Error(`خطأ في الخادم: ${response.status}`);
      }
    } catch (error) {
      console.error('❌ فشل الاتصال الأساسي:', error.message);
      this.testResults.errors.push(`connectivity: ${error.message}`);
      return false;
    }
  }

  // ===================================
  // اختبار تسجيل الدخول
  // ===================================
  async testAuthentication() {
    try {
      console.log('\n🔐 اختبار 2: تسجيل الدخول...');

      if (!this.config.username || !this.config.password) {
        throw new Error('بيانات الاعتماد غير متوفرة');
      }

      console.log(`👤 المستخدم: ${this.config.username}`);

      // محاولة تسجيل الدخول
      const loginData = new URLSearchParams({
        username: this.config.username,
        password: this.config.password
      });

      const response = await axios.post(
        `${this.config.baseUrl}/merchant/login`,
        loginData,
        {
          timeout: this.config.timeout,
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
          },
          maxRedirects: 0,
          validateStatus: () => true
        }
      );

      // فحص نجاح تسجيل الدخول
      if (response.status === 302 || response.status === 303 || 
          (response.headers['set-cookie'] && 
           response.headers['set-cookie'].some(cookie => cookie.includes('PHPSESSID')))) {
        
        console.log('✅ تسجيل الدخول ناجح');
        this.testResults.authentication = true;
        
        // حفظ الكوكيز للاختبارات التالية
        this.cookies = response.headers['set-cookie']?.join('; ') || '';
        console.log('🍪 تم حفظ الكوكيز للاختبارات التالية');
        
        return true;
      } else {
        throw new Error(`فشل تسجيل الدخول: ${response.status}`);
      }
    } catch (error) {
      console.error('❌ فشل تسجيل الدخول:', error.message);
      this.testResults.errors.push(`authentication: ${error.message}`);
      return false;
    }
  }

  // ===================================
  // اختبار الوصول لـ API
  // ===================================
  async testApiAccess() {
    try {
      console.log('\n🌐 اختبار 3: الوصول لـ API...');

      if (!this.cookies) {
        throw new Error('لا توجد كوكيز صالحة');
      }

      // اختبار الوصول لصفحة التاجر
      const response = await axios.get(
        `${this.config.baseUrl}/merchant-orders?token=${this.cookies}`,
        {
          timeout: this.config.timeout,
          headers: {
            'Cookie': this.cookies,
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
          },
          validateStatus: () => true
        }
      );

      if (response.status === 200) {
        console.log('✅ الوصول لـ API ناجح');
        this.testResults.apiAccess = true;
        return true;
      } else {
        throw new Error(`فشل الوصول: ${response.status}`);
      }
    } catch (error) {
      console.error('❌ فشل الوصول لـ API:', error.message);
      this.testResults.errors.push(`api_access: ${error.message}`);
      return false;
    }
  }

  // ===================================
  // اختبار جلب الطلبات
  // ===================================
  async testOrderRetrieval() {
    try {
      console.log('\n📦 اختبار 4: جلب الطلبات...');

      if (!this.cookies) {
        throw new Error('لا توجد كوكيز صالحة');
      }

      const response = await axios.get(
        `${this.config.baseUrl}/merchant-orders?token=${this.cookies}`,
        {
          timeout: this.config.timeout,
          headers: {
            'Cookie': this.cookies,
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
          },
          validateStatus: () => true
        }
      );

      if (response.status === 200) {
        console.log('✅ جلب الطلبات ناجح');
        console.log(`📊 حجم الاستجابة: ${response.data.length} حرف`);
        this.testResults.orderRetrieval = true;
        return true;
      } else {
        throw new Error(`فشل جلب الطلبات: ${response.status}`);
      }
    } catch (error) {
      console.error('❌ فشل جلب الطلبات:', error.message);
      this.testResults.errors.push(`order_retrieval: ${error.message}`);
      return false;
    }
  }

  // ===================================
  // اختبار فحص حالة طلب
  // ===================================
  async testStatusCheck() {
    try {
      console.log('\n🔍 اختبار 5: فحص حالة طلب...');

      if (!this.cookies) {
        throw new Error('لا توجد كوكيز صالحة');
      }

      // استخدام معرف طلب وهمي للاختبار
      const testOrderId = '12345';
      
      const response = await axios.get(
        `${this.config.baseUrl}/merchant/get_order_status`,
        {
          params: { order_id: testOrderId },
          timeout: this.config.timeout,
          headers: {
            'Cookie': this.cookies,
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
          },
          validateStatus: () => true
        }
      );

      // حتى لو كان الطلب غير موجود، المهم أن API يستجيب
      if (response.status === 200 || response.status === 404) {
        console.log('✅ فحص حالة الطلب ناجح');
        console.log(`📊 رمز الحالة: ${response.status}`);
        this.testResults.statusCheck = true;
        return true;
      } else {
        throw new Error(`فشل فحص الحالة: ${response.status}`);
      }
    } catch (error) {
      console.error('❌ فشل فحص حالة الطلب:', error.message);
      this.testResults.errors.push(`status_check: ${error.message}`);
      return false;
    }
  }

  // ===================================
  // تشغيل جميع الاختبارات
  // ===================================
  async runAllTests() {
    console.log('🚀 بدء الاختبار الشامل لشركة الوسيط...\n');
    console.log('=' * 50);

    const startTime = new Date();

    // تشغيل الاختبارات بالتسلسل
    await this.testBasicConnectivity();
    await this.testAuthentication();
    await this.testApiAccess();
    await this.testOrderRetrieval();
    await this.testStatusCheck();

    const endTime = new Date();
    const duration = endTime - startTime;

    // طباعة التقرير النهائي
    this.printFinalReport(duration);
  }

  // ===================================
  // طباعة التقرير النهائي
  // ===================================
  printFinalReport(duration) {
    console.log('\n' + '🎯'.repeat(50));
    console.log('التقرير النهائي - اختبار الاتصال مع شركة الوسيط');
    console.log('🎯'.repeat(50));

    console.log(`⏱️ مدة الاختبار: ${duration}ms`);
    console.log(`📅 التاريخ: ${new Date().toLocaleString('ar-EG')}`);

    console.log('\n📊 نتائج الاختبارات:');
    console.log('-'.repeat(30));
    
    const tests = [
      { name: 'الاتصال الأساسي', result: this.testResults.connectivity },
      { name: 'تسجيل الدخول', result: this.testResults.authentication },
      { name: 'الوصول لـ API', result: this.testResults.apiAccess },
      { name: 'جلب الطلبات', result: this.testResults.orderRetrieval },
      { name: 'فحص حالة الطلب', result: this.testResults.statusCheck }
    ];

    tests.forEach(test => {
      const icon = test.result ? '✅' : '❌';
      console.log(`${icon} ${test.name}: ${test.result ? 'نجح' : 'فشل'}`);
    });

    const successCount = tests.filter(test => test.result).length;
    const successRate = (successCount / tests.length * 100).toFixed(1);

    console.log(`\n📈 معدل النجاح: ${successRate}% (${successCount}/${tests.length})`);

    if (this.testResults.errors.length > 0) {
      console.log('\n❌ الأخطاء المسجلة:');
      console.log('-'.repeat(20));
      this.testResults.errors.forEach((error, index) => {
        console.log(`${index + 1}. ${error}`);
      });
    }

    console.log('\n' + '🎯'.repeat(50));

    // تقييم النتيجة الإجمالية
    if (successRate >= 80) {
      console.log('🎉 النتيجة: ممتاز - النظام جاهز للعمل!');
    } else if (successRate >= 60) {
      console.log('⚠️ النتيجة: جيد - يحتاج بعض التحسينات');
    } else {
      console.log('🚨 النتيجة: ضعيف - يحتاج إصلاحات جوهرية');
    }
  }
}

// تشغيل الاختبار
async function main() {
  const tester = new WaseetConnectionTester();
  await tester.runAllTests();
}

// تشغيل الاختبار إذا تم استدعاء الملف مباشرة
if (require.main === module) {
  main().catch(error => {
    console.error('❌ خطأ في تشغيل الاختبار:', error.message);
    process.exit(1);
  });
}

module.exports = WaseetConnectionTester;
