// ===================================
// جلب حالات الطلبات من شركة الوسيط - بسيط
// ===================================

const https = require('https');
require('./backend/node_modules/dotenv').config();

async function getWaseetStatuses() {
  try {
    console.log('🔐 تسجيل الدخول إلى API الوسيط...');
    
    // تسجيل الدخول
    const loginData = JSON.stringify({
      username: process.env.WASEET_USERNAME,
      password: process.env.WASEET_PASSWORD
    });

    const loginOptions = {
      hostname: 'api.alwaseet-iq.net',
      port: 443,
      path: '/login',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(loginData)
      }
    };

    const loginResponse = await makeRequest(loginOptions, loginData);
    
    if (!loginResponse.success || !loginResponse.token) {
      console.error('❌ فشل في تسجيل الدخول:', loginResponse.message);
      return;
    }

    console.log('✅ تم تسجيل الدخول بنجاح');
    
    // جلب الطلبات
    console.log('📦 جلب الطلبات من الوسيط...');
    
    const ordersOptions = {
      hostname: 'api.alwaseet-iq.net',
      port: 443,
      path: '/orders',
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${loginResponse.token}`,
        'Content-Type': 'application/json'
      }
    };

    const ordersResponse = await makeRequest(ordersOptions);
    
    if (!ordersResponse.success || !ordersResponse.data) {
      console.error('❌ فشل في جلب الطلبات:', ordersResponse.message);
      return;
    }

    console.log(`✅ تم جلب ${ordersResponse.data.length} طلب`);
    
    // استخراج الحالات الفريدة
    const statuses = new Set();
    const statusExamples = {};
    
    ordersResponse.data.forEach(order => {
      const status = order.status || order.order_status || order.state;
      if (status) {
        statuses.add(status);
        if (!statusExamples[status]) {
          statusExamples[status] = {
            orderId: order.id || order.order_id,
            customerName: order.customer_name || order.name || 'غير محدد'
          };
        }
      }
    });

    // طباعة النتائج
    console.log('\n' + '='.repeat(60));
    console.log('📋 حالات الطلبات في شركة الوسيط');
    console.log('='.repeat(60));
    console.log(`📊 إجمالي الحالات المختلفة: ${statuses.size}`);
    console.log(`📦 إجمالي الطلبات: ${ordersResponse.data.length}`);
    console.log('\n🔍 قائمة الحالات:');
    console.log('-'.repeat(60));
    
    Array.from(statuses).sort().forEach((status, index) => {
      const example = statusExamples[status];
      console.log(`${index + 1}. "${status}"`);
      console.log(`   📝 مثال: طلب ${example.orderId} - ${example.customerName}`);
      console.log('-'.repeat(30));
    });
    
    console.log('\n📝 الحالات فقط (للنسخ):');
    Array.from(statuses).sort().forEach((status, index) => {
      console.log(`${index + 1}. ${status}`);
    });
    
    console.log('\n✅ تم الانتهاء من جلب الحالات!');
    
  } catch (error) {
    console.error('❌ خطأ:', error.message);
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
          const parsedData = JSON.parse(responseData);
          resolve(parsedData);
        } catch (parseError) {
          resolve({
            success: false,
            message: 'خطأ في تحليل الاستجابة',
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

// تشغيل السكريبت
getWaseetStatuses();
