const https = require('https');

console.log('🧪 اختبار تحديث حالة الطلب...');

// أولاً، دعنا نجلب قائمة الطلبات لنجد طلب للاختبار
function getOrders() {
  return new Promise((resolve, reject) => {
    const options = {
  hostname: 'montajati-official-backend-production.up.railway.app',
      port: 443,
      path: '/api/orders?limit=5',
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
          resolve(parsed);
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

// ثانياً، تحديث حالة طلب
function updateOrderStatus(orderId, newStatus) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify({
      status: newStatus
    });

    const options = {
  hostname: 'montajati-official-backend-production.up.railway.app',
      port: 443,
      path: `/api/orders/${orderId}/status`,
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      },
      timeout: 15000
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        console.log(`📊 Status Code: ${res.statusCode}`);
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
    req.on('timeout', () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });

    req.write(postData);
    req.end();
  });
}

// تشغيل الاختبار
async function runTest() {
  try {
    console.log('📋 جلب قائمة الطلبات...');
    const orders = await getOrders();
    
    if (orders.data && orders.data.length > 0) {
      const testOrder = orders.data[0];
      console.log(`🎯 سيتم اختبار الطلب: ${testOrder.id}`);
      console.log(`📊 الحالة الحالية: ${testOrder.status}`);
      
      // اختبار تحديث الحالة بالرقم 3
      console.log('\n🧪 اختبار 1: تحديث الحالة بالرقم 3...');
      const result1 = await updateOrderStatus(testOrder.id, '3');
      console.log('✅ نتيجة الاختبار 1:', result1.success ? 'نجح' : 'فشل');
      
      // انتظار قليل
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // اختبار تحديث الحالة بالنص العربي
      console.log('\n🧪 اختبار 2: تحديث الحالة بالنص العربي...');
      const result2 = await updateOrderStatus(testOrder.id, 'قيد التوصيل الى الزبون (في عهدة المندوب)');
      console.log('✅ نتيجة الاختبار 2:', result2.success ? 'نجح' : 'فشل');
      
    } else {
      console.log('❌ لا توجد طلبات للاختبار');
    }
    
  } catch (error) {
    console.error('❌ خطأ في الاختبار:', error.message);
  }
}

runTest();
