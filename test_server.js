const https = require('https');

console.log('🧪 اختبار الخادم...');

// اختبار health endpoint
const healthOptions = {
  hostname: 'montajati-backend.onrender.com',
  port: 443,
  path: '/health',
  method: 'GET',
  timeout: 10000
};

const healthReq = https.request(healthOptions, (res) => {
  console.log(`✅ Health Status: ${res.statusCode}`);
  
  let data = '';
  res.on('data', (chunk) => {
    data += chunk;
  });
  
  res.on('end', () => {
    try {
      const parsed = JSON.parse(data);
      console.log(`📊 Server Status: ${parsed.status}`);
      console.log(`🔧 Services: notifications=${parsed.services.notifications}, sync=${parsed.services.sync}`);
      
      // اختبار orders endpoint
      testOrdersEndpoint();
    } catch (e) {
      console.log('📄 Raw response:', data);
    }
  });
});

healthReq.on('error', (err) => {
  console.error('❌ Health check failed:', err.message);
});

healthReq.on('timeout', () => {
  console.error('❌ Health check timeout');
  healthReq.destroy();
});

healthReq.end();

function testOrdersEndpoint() {
  console.log('\n🧪 اختبار orders endpoint...');
  
  const ordersOptions = {
    hostname: 'montajati-backend.onrender.com',
    port: 443,
    path: '/api/orders',
    method: 'GET',
    timeout: 10000
  };

  const ordersReq = https.request(ordersOptions, (res) => {
    console.log(`✅ Orders Status: ${res.statusCode}`);
    
    let data = '';
    res.on('data', (chunk) => {
      data += chunk;
    });
    
    res.on('end', () => {
      if (res.statusCode === 200) {
        console.log('🎉 Orders endpoint يعمل بنجاح!');
      } else {
        console.log('📄 Response:', data.substring(0, 200));
      }
    });
  });

  ordersReq.on('error', (err) => {
    console.error('❌ Orders test failed:', err.message);
  });

  ordersReq.on('timeout', () => {
    console.error('❌ Orders test timeout');
    ordersReq.destroy();
  });

  ordersReq.end();
}
