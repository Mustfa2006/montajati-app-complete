console.log('🧪 اختبار تحديث حالة الطلب...');

const https = require('https');

// جلب طلب للاختبار
function getOrder() {
  return new Promise((resolve, reject) => {
    const options = {
  hostname: 'montajati-official-backend-production.up.railway.app',
      port: 443,
      path: '/api/orders?limit=1',
      method: 'GET',
      timeout: 15000
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          if (parsed.data && parsed.data.length > 0) {
            resolve(parsed.data[0]);
          } else {
            reject(new Error('No orders found'));
          }
        } catch (e) {
          reject(new Error('Failed to parse: ' + data));
        }
      });
    });

    req.on('error', reject);
    req.end();
  });
}

// تحديث حالة الطلب
function updateOrder(orderId, status) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify({ status: status });

    const options = {
  hostname: 'montajati-official-backend-production.up.railway.app',
      port: 443,
      path: `/api/orders/${orderId}/status`,
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      },
      timeout: 30000
    };

    console.log(`📤 تحديث الطلب ${orderId} إلى "${status}"`);

    const req = https.request(options, (res) => {
      console.log(`📊 Status: ${res.statusCode}`);
      
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        console.log(`📄 Response: ${data}`);
        try {
          const parsed = JSON.parse(data);
          resolve(parsed);
        } catch (e) {
          resolve({ raw: data, statusCode: res.statusCode });
        }
      });
    });

    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

// تشغيل الاختبار
async function runTest() {
  try {
    console.log('📋 جلب طلب للاختبار...');
    const order = await getOrder();
    
    console.log(`🎯 الطلب: ${order.id}`);
    console.log(`📊 الحالة الحالية: "${order.status}"`);
    console.log(`🚛 Waseet ID: ${order.waseet_order_id || 'null'}`);
    
    console.log('\n🔄 تحديث الحالة...');
    const result = await updateOrder(order.id, 'قيد التوصيل الى الزبون (في عهدة المندوب)');
    
    console.log('\n📊 النتيجة:');
    if (result.success) {
      console.log('✅ تم التحديث بنجاح');
      if (result.waseet_result) {
        console.log('🚛 نتيجة الوسيط:', result.waseet_result);
      }
    } else {
      console.log('❌ فشل التحديث');
      console.log('📄 الخطأ:', result.error || result.raw);
    }
    
  } catch (error) {
    console.error('❌ خطأ:', error.message);
  }
}

runTest();
