const https = require('https');

async function testNotificationAPI() {
  try {
    console.log('🔥 اختبار API إرسال الإشعارات...');

    const postData = JSON.stringify({
      userPhone: '07503597589',
      orderId: 'test_order_' + Date.now(),
      newStatus: 'cancelled',
      customerName: 'محمد علي',
      notes: 'اختبار الرسائل الجديدة'
    });

    const options = {
      hostname: 'montajati-backend.onrender.com',
      port: 443,
      path: '/api/notifications/order-status',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = https.request(options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        console.log('✅ نجح الطلب!');
        console.log('📊 كود الاستجابة:', res.statusCode);
        console.log('📊 الاستجابة:', data);
      });
    });

    req.on('error', (error) => {
      console.error('❌ خطأ في الطلب:', error.message);
    });

    req.write(postData);
    req.end();

  } catch (error) {
    console.error('❌ خطأ عام:', error.message);
  }
}

testNotificationAPI();
