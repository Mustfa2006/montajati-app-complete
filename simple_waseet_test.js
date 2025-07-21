// ===================================
// اختبار بسيط لـ API الوسيط
// ===================================

const https = require('https');
require('dotenv').config();

async function simpleTest() {
  console.log('🔐 اختبار بسيط لـ API الوسيط...');
  
  const username = process.env.WASEET_USERNAME;
  const password = process.env.WASEET_PASSWORD;
  
  console.log(`👤 المستخدم: ${username}`);
  
  // اختبار GET أولاً
  try {
    console.log('🔄 اختبار GET /merchant/login...');
    
    const getResponse = await makeSimpleRequest('GET', '/merchant/login');
    console.log(`📊 GET النتيجة: ${getResponse.statusCode}`);
    console.log(`📄 محتوى: ${getResponse.rawData.substring(0, 200)}`);
    
  } catch (error) {
    console.log(`❌ GET خطأ: ${error.message}`);
  }
  
  // اختبار POST
  try {
    console.log('\n🔄 اختبار POST /merchant/login...');
    
    const postData = JSON.stringify({
      username: username,
      password: password
    });
    
    const postResponse = await makeSimpleRequest('POST', '/merchant/login', postData);
    console.log(`📊 POST النتيجة: ${postResponse.statusCode}`);
    console.log(`📄 محتوى: ${postResponse.rawData.substring(0, 500)}`);
    
  } catch (error) {
    console.log(`❌ POST خطأ: ${error.message}`);
  }
}

function makeSimpleRequest(method, path, data = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'api.alwaseet-iq.net',
      port: 443,
      path: path,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      timeout: 15000
    };

    if (data) {
      options.headers['Content-Length'] = Buffer.byteLength(data);
    }

    const req = https.request(options, (res) => {
      let responseData = '';
      
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      
      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          rawData: responseData
        });
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.on('timeout', () => {
      req.destroy();
      reject(new Error('Timeout'));
    });

    if (data) {
      req.write(data);
    }
    
    req.end();
  });
}

simpleTest();
