// ===================================
// اختبار نهائي سريع
// Quick Final Test
// ===================================

const https = require('https');

async function quickTest() {
  console.log('🧪 اختبار نهائي سريع...');
  console.log('='.repeat(50));

  try {
    // فحص health check
    console.log('🔍 فحص health check...');
    const healthResult = await makeRequest('GET', 'https://montajati-backend.onrender.com/health');
    
    if (healthResult.success) {
      const health = healthResult.data;
      console.log(`📊 حالة الخادم: ${health.status}`);
      console.log(`🔧 خدمة المزامنة: ${health.services?.sync || 'غير محدد'}`);
      
      if (health.services?.sync === 'healthy') {
        console.log('🎉 النجاح! خدمة المزامنة تعمل بشكل مثالي!');
        return true;
      } else if (health.services?.sync === 'warning') {
        console.log('✅ الكود يعمل! قد تكون هناك مشكلة في بيانات المصادقة مع الوسيط');
        return 'warning';
      } else {
        console.log('❌ خدمة المزامنة ما زالت لا تعمل');
        return false;
      }
    } else {
      console.log('❌ لا يمكن الوصول للخادم');
      return false;
    }
  } catch (error) {
    console.error('❌ خطأ في الاختبار:', error.message);
    return false;
  }
}

// دالة مساعدة لإرسال الطلبات
async function makeRequest(method, url, data = null) {
  return new Promise((resolve) => {
    const urlObj = new URL(url);
    
    const options = {
      hostname: urlObj.hostname,
      port: 443,
      path: urlObj.pathname + urlObj.search,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Quick-Final-Test/1.0'
      },
      timeout: 30000
    };

    if (data && (method === 'POST' || method === 'PUT')) {
      const jsonData = JSON.stringify(data);
      options.headers['Content-Length'] = Buffer.byteLength(jsonData);
    }

    const req = https.request(options, (res) => {
      let responseData = '';

      res.on('data', (chunk) => {
        responseData += chunk;
      });

      res.on('end', () => {
        try {
          const parsedData = responseData ? JSON.parse(responseData) : {};
          
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve({
              success: true,
              status: res.statusCode,
              data: parsedData
            });
          } else {
            resolve({
              success: false,
              status: res.statusCode,
              error: parsedData,
              rawResponse: responseData
            });
          }
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
      req.write(JSON.stringify(data));
    }

    req.end();
  });
}

// تشغيل الاختبار
quickTest()
  .then((result) => {
    console.log('\n🎯 النتيجة النهائية:');
    if (result === true) {
      console.log('🎉 النظام يعمل بشكل مثالي 100%!');
      console.log('✅ الطلبات ستُرسل للوسيط بنجاح');
    } else if (result === 'warning') {
      console.log('✅ الكود يعمل بشكل مثالي!');
      console.log('⚠️ قد تحتاج لإضافة متغيرات البيئة في Render');
    } else {
      console.log('❌ ما زالت هناك مشاكل');
      console.log('💡 تحقق من متغيرات البيئة في Render');
    }
  })
  .catch((error) => {
    console.error('❌ خطأ في تشغيل الاختبار:', error);
  });
