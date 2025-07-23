// ===================================
// اختبار جميع endpoints شركة الوسيط
// Test All Waseet API Endpoints
// ===================================

const axios = require('axios');
require('dotenv').config();

async function testWaseetEndpoints() {
  try {
    console.log('🔍 اختبار جميع endpoints شركة الوسيط...\n');

    const waseetConfig = {
      baseUrl: process.env.ALMASEET_BASE_URL || 'https://api.alwaseet-iq.net',
      username: process.env.WASEET_USERNAME,
      password: process.env.WASEET_PASSWORD
    };

    // 1. تسجيل الدخول
    console.log('🔐 تسجيل الدخول...');
    const loginData = new URLSearchParams({
      username: waseetConfig.username,
      password: waseetConfig.password
    });

    const loginResponse = await axios.post(
      `${waseetConfig.baseUrl}/merchant/login`,
      loginData,
      {
        timeout: 15000,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
        maxRedirects: 0,
        validateStatus: () => true
      }
    );

    if (loginResponse.status !== 302 && loginResponse.status !== 303) {
      throw new Error(`فشل تسجيل الدخول: ${loginResponse.status}`);
    }

    const token = loginResponse.headers['set-cookie']?.join('; ') || '';
    console.log('✅ تم تسجيل الدخول بنجاح\n');

    // 2. اختبار endpoints مختلفة
    const endpoints = [
      // API endpoints
      '/v1/merchant-orders',
      '/merchant-orders',
      '/orders',
      '/api/orders',
      '/api/merchant/orders',
      
      // Web endpoints
      '/merchant/orders',
      '/merchant/dashboard',
      '/merchant/order-list',
      '/merchant/my-orders',
      
      // Status endpoints
      '/merchant/order-status',
      '/merchant/get-order-status',
      '/merchant/check-status',
      
      // Other possible endpoints
      '/merchant/home',
      '/merchant/index',
      '/merchant'
    ];

    const workingEndpoints = [];
    const failedEndpoints = [];

    for (const endpoint of endpoints) {
      try {
        console.log(`🔍 اختبار: ${endpoint}`);
        
        const response = await axios.get(`${waseetConfig.baseUrl}${endpoint}`, {
          timeout: 10000,
          headers: {
            'Cookie': token,
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
          },
          validateStatus: () => true
        });

        console.log(`📊 رمز الحالة: ${response.status}`);
        
        if (response.status === 200) {
          console.log(`✅ نجح!`);
          
          // تحليل نوع المحتوى
          const contentType = response.headers['content-type'] || '';
          const dataSize = response.data ? response.data.length : 0;
          
          console.log(`📄 نوع المحتوى: ${contentType}`);
          console.log(`📏 حجم البيانات: ${dataSize} حرف`);
          
          if (contentType.includes('application/json')) {
            console.log('📊 استجابة JSON');
            if (response.data && typeof response.data === 'object') {
              console.log('🔍 مفاتيح JSON:', Object.keys(response.data));
            }
          } else if (contentType.includes('text/html')) {
            console.log('📄 استجابة HTML');
            
            // البحث عن كلمات مفتاحية
            const keywords = ['order', 'طلب', 'status', 'حالة', 'delivery', 'توصيل'];
            const foundKeywords = keywords.filter(keyword => 
              response.data.toLowerCase().includes(keyword.toLowerCase())
            );
            
            if (foundKeywords.length > 0) {
              console.log('🔍 كلمات مفتاحية موجودة:', foundKeywords.join(', '));
            }
          }
          
          workingEndpoints.push({
            endpoint,
            status: response.status,
            contentType,
            dataSize
          });
          
        } else if (response.status === 302 || response.status === 303) {
          console.log(`🔄 إعادة توجيه إلى: ${response.headers.location}`);
          workingEndpoints.push({
            endpoint,
            status: response.status,
            redirect: response.headers.location
          });
        } else {
          console.log(`❌ فشل: ${response.status}`);
          failedEndpoints.push({
            endpoint,
            status: response.status
          });
        }

      } catch (error) {
        console.log(`❌ خطأ: ${error.message}`);
        failedEndpoints.push({
          endpoint,
          error: error.message
        });
      }
      
      console.log('-'.repeat(50));
    }

    // 3. تقرير النتائج
    console.log('\n📊 تقرير النتائج:');
    console.log('='.repeat(60));
    
    console.log(`\n✅ Endpoints تعمل (${workingEndpoints.length}):`);
    workingEndpoints.forEach((item, index) => {
      console.log(`${index + 1}. ${item.endpoint} - ${item.status}`);
      if (item.contentType) {
        console.log(`   📄 نوع: ${item.contentType}`);
      }
      if (item.redirect) {
        console.log(`   🔄 توجيه: ${item.redirect}`);
      }
    });

    console.log(`\n❌ Endpoints فاشلة (${failedEndpoints.length}):`);
    failedEndpoints.forEach((item, index) => {
      console.log(`${index + 1}. ${item.endpoint} - ${item.status || item.error}`);
    });

    // 4. اختبار endpoint واعد بالتفصيل
    if (workingEndpoints.length > 0) {
      console.log('\n🔍 اختبار مفصل للـ endpoint الأول الناجح...');
      
      const bestEndpoint = workingEndpoints[0];
      console.log(`🎯 اختبار: ${bestEndpoint.endpoint}`);
      
      try {
        const detailedResponse = await axios.get(`${waseetConfig.baseUrl}${bestEndpoint.endpoint}`, {
          timeout: 15000,
          headers: {
            'Cookie': token,
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
          }
        });

        console.log('📊 الاستجابة المفصلة:');
        
        if (typeof detailedResponse.data === 'string') {
          // إذا كانت HTML، ابحث عن جداول أو قوائم
          if (detailedResponse.data.includes('<table>')) {
            console.log('📋 تم العثور على جدول في الصفحة');
          }
          if (detailedResponse.data.includes('order')) {
            console.log('📦 تم العثور على كلمة "order" في الصفحة');
          }
          
          // عرض جزء من المحتوى
          const preview = detailedResponse.data.substring(0, 500);
          console.log('👀 معاينة المحتوى:');
          console.log(preview + '...');
          
        } else {
          console.log('📊 البيانات JSON:');
          console.log(JSON.stringify(detailedResponse.data, null, 2));
        }

      } catch (error) {
        console.log(`❌ خطأ في الاختبار المفصل: ${error.message}`);
      }
    }

    console.log('\n🎉 انتهى اختبار جميع endpoints!');

  } catch (error) {
    console.error('❌ خطأ عام في الاختبار:', error.message);
  }
}

// تشغيل الاختبار
testWaseetEndpoints();
