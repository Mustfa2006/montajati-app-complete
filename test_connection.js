console.log('🧪 اختبار الاتصال...');

const https = require('https');

// اختبار بسيط للخادم
const options = {
  hostname: 'montajati-backend.onrender.com',
  port: 443,
  path: '/health',
  method: 'GET',
  timeout: 10000
};

console.log('📡 اختبار الاتصال بالخادم...');

const req = https.request(options, (res) => {
  console.log(`✅ Status: ${res.statusCode}`);
  
  let data = '';
  res.on('data', (chunk) => {
    data += chunk;
  });
  
  res.on('end', () => {
    console.log('📄 Response received');
    try {
      const parsed = JSON.parse(data);
      console.log('🔧 Services:', parsed.services);
      console.log('📊 Server initialized:', parsed.server.isInitialized);
      console.log('🏃 Server running:', parsed.server.isRunning);
    } catch (e) {
      console.log('Raw:', data.substring(0, 100));
    }
  });
});

req.on('error', (err) => {
  console.error('❌ Error:', err.message);
});

req.on('timeout', () => {
  console.error('❌ Timeout');
  req.destroy();
});

req.end();
