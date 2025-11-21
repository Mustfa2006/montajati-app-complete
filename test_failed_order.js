console.log('🧪 اختبار طلب فاشل...');

const https = require('https');

// اختبار الطلب الثاني الذي لم يتم إرساله للوسيط
const failedOrderId = 'order_1753540733476_5845'; // لغال - كركوك

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
    console.log(`🎯 اختبار الطلب الفاشل: ${failedOrderId}`);
    console.log('📊 هذا الطلب بحالة "قيد التوصيل الى الزبون (في عهدة المندوب)" لكن waseet_order_id = null');
    
    console.log('\n🔄 تحديث الحالة إلى "active" أولاً...');
    const result1 = await updateOrder(failedOrderId, 'active');
    console.log('✅ نتيجة التحديث الأول:', result1.success ? 'نجح' : 'فشل');
    
    // انتظار قليل
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    console.log('\n🔄 تحديث الحالة إلى "قيد التوصيل الى الزبون (في عهدة المندوب)"...');
    const result2 = await updateOrder(failedOrderId, 'قيد التوصيل الى الزبون (في عهدة المندوب)');
    
    console.log('\n📊 النتيجة النهائية:');
    if (result2.success) {
      console.log('✅ تم التحديث بنجاح');
      if (result2.waseet_result) {
        console.log('🚛 نتيجة الوسيط:', result2.waseet_result);
      } else {
        console.log('❌ لا توجد نتيجة وسيط في الاستجابة');
      }
    } else {
      console.log('❌ فشل التحديث');
      console.log('📄 الخطأ:', result2.error || result2.raw);
    }
    
  } catch (error) {
    console.error('❌ خطأ:', error.message);
  }
}

runTest();
