// ===================================
// اختبار بسيط لتحديث حالة الطلبات
// ===================================

const https = require('https');

// بيانات الاختبار
const serverUrl = 'montajati-official-backend-production.up.railway.app';
const testOrderId = 'order_1737158415000_test'; // معرف طلب تجريبي

function makeRequest(path, method, data) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: serverUrl,
      port: 443,
      path: path,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }
    };

    const req = https.request(options, (res) => {
      let responseData = '';
      
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      
      res.on('end', () => {
        try {
          const parsedData = JSON.parse(responseData);
          resolve({
            statusCode: res.statusCode,
            data: parsedData
          });
        } catch (e) {
          resolve({
            statusCode: res.statusCode,
            data: responseData
          });
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    if (data) {
      req.write(JSON.stringify(data));
    }
    
    req.end();
  });
}

async function testOrderStatusUpdate() {
  console.log('🧪 === اختبار تحديث حالة الطلبات ===\n');

  try {
    // 1. اختبار فحص صحة الخادم
    console.log('1️⃣ فحص صحة الخادم...');
    const healthCheck = await makeRequest('/health', 'GET');
    console.log(`✅ حالة الخادم: ${healthCheck.statusCode}`);
    console.log(`📊 البيانات: ${JSON.stringify(healthCheck.data, null, 2)}\n`);

    // 2. اختبار تحديث حالة طلب
    console.log('2️⃣ اختبار تحديث حالة الطلب...');
    console.log(`📦 معرف الطلب: ${testOrderId}`);
    console.log(`🔄 تغيير الحالة إلى: in_delivery`);

    const updateData = {
      status: 'in_delivery',
      notes: 'اختبار تحديث الحالة من سكريبت بسيط',
      changedBy: 'test_script'
    };

    const updateResult = await makeRequest(
      `/api/orders/${testOrderId}/status`,
      'PUT',
      updateData
    );

    console.log(`📊 كود الاستجابة: ${updateResult.statusCode}`);
    console.log(`📝 البيانات: ${JSON.stringify(updateResult.data, null, 2)}\n`);

    if (updateResult.statusCode === 200) {
      console.log('🎉 نجح تحديث الحالة!');
    } else if (updateResult.statusCode === 404) {
      console.log('⚠️ الطلب غير موجود - هذا طبيعي للاختبار');
    } else {
      console.log('❌ فشل في تحديث الحالة');
    }

  } catch (error) {
    console.error('❌ خطأ في الاختبار:', error.message);
  }

  console.log('\n🏁 انتهى الاختبار');
}

// تشغيل الاختبار
testOrderStatusUpdate();
