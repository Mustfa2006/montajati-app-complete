const https = require('https');

console.log('🔄 إعادة محاولة إرسال الطلبات الفاشلة للوسيط...');

function retryFailedOrders() {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'montajati-backend.onrender.com',
      port: 443,
      path: '/api/orders/retry-failed-waseet',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      timeout: 30000
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

    req.end();
  });
}

// تشغيل الاختبار
async function runRetry() {
  try {
    const result = await retryFailedOrders();
    console.log('✅ نتيجة إعادة المحاولة:', result);
    
  } catch (error) {
    console.error('❌ خطأ في إعادة المحاولة:', error.message);
  }
}

runRetry();
