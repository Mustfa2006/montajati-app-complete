// ===================================
// اختبار تسجيل الدخول للتاجر في الوسيط
// Test Merchant Login for Waseet
// ===================================

const https = require('https');
require('dotenv').config();

async function testMerchantLogin() {
  try {
    console.log('🔐 اختبار تسجيل الدخول للتاجر في الوسيط...\n');
    
    const username = process.env.WASEET_USERNAME;
    const password = process.env.WASEET_PASSWORD;
    
    console.log(`👤 اسم المستخدم: ${username}`);
    console.log(`🔑 كلمة المرور: ${password ? '***' + password.slice(-3) : 'غير موجودة'}\n`);

    // اختبار المسار الصحيح
    const loginData = JSON.stringify({
      username: username,
      password: password
    });

    const options = {
      hostname: 'api.alwaseet-iq.net',
      port: 443,
      path: '/merchant/login',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Montajati-App/1.0',
        'Content-Length': Buffer.byteLength(loginData)
      }
    };

    console.log('🔄 محاولة تسجيل الدخول عبر /merchant/login...');
    
    const response = await makeRequest(options, loginData);
    
    console.log(`📊 كود الاستجابة: ${response.statusCode}`);
    console.log(`📋 Headers:`, response.headers);
    
    if (response.data) {
      console.log(`📄 محتوى الاستجابة:`);
      console.log(JSON.stringify(response.data, null, 2));
      
      // فحص إذا كان هناك token
      if (response.data.token || response.data.access_token || response.data.auth_token) {
        console.log('\n🎉 تم العثور على Token بنجاح!');
        const token = response.data.token || response.data.access_token || response.data.auth_token;
        console.log(`🔑 Token: ${token.substring(0, 20)}...`);
        
        // اختبار استخدام Token
        await testTokenUsage(token);
      } else {
        console.log('\n⚠️ لم يتم العثور على token في الاستجابة');
      }
    } else {
      console.log(`📄 محتوى خام: ${response.rawData}`);
    }
    
  } catch (error) {
    console.error('❌ خطأ في اختبار تسجيل الدخول:', error.message);
  }
}

// اختبار استخدام Token
async function testTokenUsage(token) {
  try {
    console.log('\n🧪 اختبار استخدام Token...');
    
    const ordersPaths = ['/orders', '/api/orders', '/merchant/orders', '/orders/list'];
    
    for (const path of ordersPaths) {
      try {
        console.log(`🔄 اختبار ${path}...`);
        
        const options = {
          hostname: 'api.alwaseet-iq.net',
          port: 443,
          path: path,
          method: 'GET',
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          }
        };

        const response = await makeRequest(options);
        
        console.log(`   📊 ${path}: ${response.statusCode}`);
        
        if (response.statusCode === 200 && response.data) {
          console.log(`   ✅ نجح! عدد الطلبات: ${Array.isArray(response.data) ? response.data.length : 'غير محدد'}`);
          
          // إذا وجدنا طلبات، دعنا نفحص الحالات
          if (Array.isArray(response.data) && response.data.length > 0) {
            console.log('\n📋 فحص حالات الطلبات...');
            const statuses = new Set();
            
            response.data.forEach(order => {
              const status = order.status || order.order_status || order.state || order.delivery_status;
              if (status) statuses.add(status);
            });
            
            console.log(`📊 الحالات الموجودة: ${Array.from(statuses).join(', ')}`);
          }
          
          break; // وجدنا مسار يعمل
        }
      } catch (pathError) {
        console.log(`   ❌ ${path}: ${pathError.message}`);
      }
    }
    
  } catch (error) {
    console.error('❌ خطأ في اختبار Token:', error.message);
  }
}

// دالة مساعدة لإرسال الطلبات
function makeRequest(options, data = null) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let responseData = '';
      
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      
      res.on('end', () => {
        try {
          const parsedData = responseData ? JSON.parse(responseData) : null;
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
            rawData: responseData
          });
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    if (data) {
      req.write(data);
    }
    
    req.end();
  });
}

// تشغيل الاختبار
testMerchantLogin();
