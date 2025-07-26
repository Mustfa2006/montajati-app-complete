const axios = require('axios');

async function checkServerStatus() {
  console.log('🔍 === فحص حالة الخادم ===\n');

  const baseURL = 'https://montajati-backend.onrender.com';
  
  // قائمة endpoints للفحص
  const endpoints = [
    { path: '/', name: 'الصفحة الرئيسية' },
    { path: '/health', name: 'فحص الصحة' },
    { path: '/api/orders', name: 'API الطلبات' },
    { path: '/api/sync/status', name: 'حالة المزامنة' },
    { path: '/api/waseet/test-connection', name: 'اختبار الوسيط', method: 'POST' }
  ];

  for (const endpoint of endpoints) {
    try {
      console.log(`🔍 فحص ${endpoint.name}: ${baseURL}${endpoint.path}`);
      
      const method = endpoint.method || 'GET';
      const config = {
        method: method,
        url: `${baseURL}${endpoint.path}`,
        timeout: 15000,
        validateStatus: function (status) {
          return status < 500; // قبول أي status code أقل من 500
        }
      };

      if (method === 'POST') {
        config.data = {};
      }

      const response = await axios(config);
      
      console.log(`   📊 Status: ${response.status}`);
      console.log(`   📋 Response: ${response.statusText}`);
      
      if (response.status === 200) {
        console.log(`   ✅ ${endpoint.name} يعمل بشكل طبيعي`);
      } else if (response.status === 404) {
        console.log(`   ⚠️ ${endpoint.name} غير موجود (404)`);
      } else if (response.status === 503) {
        console.log(`   ❌ ${endpoint.name} غير متاح (503) - الخادم متوقف أو محمل زائد`);
      } else {
        console.log(`   ⚠️ ${endpoint.name} يعطي status غير متوقع: ${response.status}`);
      }
      
    } catch (error) {
      console.log(`   ❌ خطأ في ${endpoint.name}:`);
      
      if (error.code === 'ECONNREFUSED') {
        console.log(`   📋 السبب: الخادم رفض الاتصال`);
      } else if (error.code === 'ETIMEDOUT') {
        console.log(`   📋 السبب: انتهت مهلة الاتصال`);
      } else if (error.response) {
        console.log(`   📋 Status: ${error.response.status}`);
        console.log(`   📋 السبب: ${error.response.statusText}`);
      } else {
        console.log(`   📋 السبب: ${error.message}`);
      }
    }
    
    console.log(''); // سطر فارغ
  }

  // فحص إضافي لـ Render
  console.log('🔍 === فحص خاص بـ Render ===');
  
  try {
    console.log('📡 محاولة ping للخادم...');
    const pingResponse = await axios.get(baseURL, {
      timeout: 30000,
      validateStatus: () => true
    });
    
    console.log(`📊 Ping Status: ${pingResponse.status}`);
    
    if (pingResponse.status === 503) {
      console.log('⚠️ الخادم يعطي 503 - قد يكون في حالة cold start');
      console.log('💡 Render قد يحتاج وقت لتشغيل الخادم إذا كان متوقف');
      console.log('⏳ جاري المحاولة مرة أخرى بعد 30 ثانية...');
      
      // انتظار 30 ثانية ثم محاولة مرة أخرى
      await new Promise(resolve => setTimeout(resolve, 30000));
      
      console.log('🔄 محاولة ثانية...');
      const retryResponse = await axios.get(baseURL, {
        timeout: 30000,
        validateStatus: () => true
      });
      
      console.log(`📊 Retry Status: ${retryResponse.status}`);
      
      if (retryResponse.status === 200) {
        console.log('✅ الخادم يعمل الآن بعد cold start');
      } else {
        console.log('❌ الخادم لا يزال لا يستجيب');
      }
    }
    
  } catch (error) {
    console.log('❌ فشل في ping الخادم:', error.message);
  }

  console.log('\n🏆 === خلاصة فحص الخادم ===');
  console.log('📋 إذا كان الخادم يعطي 503، فهو متوقف أو في cold start');
  console.log('💡 Render قد يوقف الخادم بعد فترة عدم استخدام');
  console.log('⏳ قد يحتاج الخادم 1-2 دقيقة للتشغيل مرة أخرى');
  console.log('🔄 حاول مرة أخرى بعد بضع دقائق');
}

checkServerStatus();
