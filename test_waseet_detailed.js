const https = require('https');

console.log('🔍 فحص مفصل لحالة الوسيط...');

// اختبار تحديث حالة طلب مع مراقبة مفصلة
function updateOrderWithMonitoring(orderId, newStatus) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify({
      status: newStatus
    });

    console.log(`📤 إرسال طلب تحديث الحالة:`);
    console.log(`   🆔 معرف الطلب: ${orderId}`);
    console.log(`   📊 الحالة الجديدة: "${newStatus}"`);
    console.log(`   📦 البيانات المرسلة: ${postData}`);

    const options = {
      hostname: 'montajati-backend.onrender.com',
      port: 443,
      path: `/api/orders/${orderId}/status`,
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      },
      timeout: 30000
    };

    console.log(`🌐 URL: https://${options.hostname}${options.path}`);
    console.log(`📋 Headers:`, options.headers);

    const req = https.request(options, (res) => {
      console.log(`📊 Response Status: ${res.statusCode}`);
      console.log(`📋 Response Headers:`, res.headers);
      
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        console.log(`📄 Raw Response: ${data}`);
        
        try {
          const parsed = JSON.parse(data);
          console.log(`✅ Parsed Response:`, JSON.stringify(parsed, null, 2));
          resolve(parsed);
        } catch (e) {
          console.log(`⚠️ Failed to parse JSON, returning raw data`);
          resolve({ raw: data, statusCode: res.statusCode });
        }
      });
    });

    req.on('error', (err) => {
      console.error('❌ Request Error:', err);
      reject(err);
    });

    req.on('timeout', () => {
      console.error('❌ Request Timeout');
      req.destroy();
      reject(new Error('Request timeout'));
    });

    req.write(postData);
    req.end();
  });
}

// جلب طلب للاختبار
function getTestOrder() {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'montajati-backend.onrender.com',
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
          reject(new Error('Failed to parse response: ' + data));
        }
      });
    });

    req.on('error', reject);
    req.on('timeout', () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });

    req.end();
  });
}

// تشغيل الاختبار المفصل
async function runDetailedTest() {
  try {
    console.log('📋 جلب طلب للاختبار...');
    const testOrder = await getTestOrder();
    
    console.log(`🎯 طلب الاختبار:`);
    console.log(`   🆔 ID: ${testOrder.id}`);
    console.log(`   📊 الحالة الحالية: "${testOrder.status}"`);
    console.log(`   🚛 Waseet Order ID: ${testOrder.waseet_order_id || 'null'}`);
    console.log(`   📈 Waseet Status: "${testOrder.waseet_status || 'null'}"`);
    
    console.log('\n🧪 اختبار تحديث الحالة إلى "قيد التوصيل الى الزبون (في عهدة المندوب)"...');
    
    const result = await updateOrderWithMonitoring(
      testOrder.id, 
      'قيد التوصيل الى الزبون (في عهدة المندوب)'
    );
    
    console.log('\n📊 نتيجة الاختبار:');
    if (result.success) {
      console.log('✅ تم تحديث الحالة بنجاح');
      if (result.waseet_result) {
        console.log('🚛 نتيجة الوسيط:', result.waseet_result);
      }
    } else {
      console.log('❌ فشل في تحديث الحالة');
      console.log('📄 الخطأ:', result.error || result.raw);
    }
    
  } catch (error) {
    console.error('❌ خطأ في الاختبار:', error.message);
  }
}

runDetailedTest();
