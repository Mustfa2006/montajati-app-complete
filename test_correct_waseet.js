// ===================================
// اختبار الرابط الصحيح للوسيط
// ===================================

const https = require('https');
require('dotenv').config();

async function testCorrectWaseet() {
  console.log('🔐 اختبار الرابط الصحيح للوسيط...\n');
  
  const username = process.env.WASEET_USERNAME;
  const password = process.env.WASEET_PASSWORD;
  
  console.log(`👤 المستخدم: ${username}`);
  console.log(`🌐 الرابط الجديد: https://merchant.alwaseet-iq.net\n`);
  
  // اختبار المسارات المحتملة
  const paths = [
    '/merchant/login',
    '/api/merchant/login',
    '/api/login',
    '/login',
    '/auth/login'
  ];
  
  for (const path of paths) {
    console.log(`🔄 اختبار ${path}...`);
    
    try {
      // اختبار GET أولاً
      const getResponse = await makeRequest('GET', path);
      console.log(`   GET: ${getResponse.statusCode}`);
      
      // اختبار POST
      const postData = JSON.stringify({
        username: username,
        password: password
      });
      
      const postResponse = await makeRequest('POST', path, postData);
      console.log(`   POST: ${postResponse.statusCode}`);
      
      // فحص إذا كان يرجع JSON
      if (postResponse.rawData && !postResponse.rawData.includes('<!DOCTYPE html>')) {
        console.log(`   🎯 يبدو أنه API! محتوى:`);
        console.log(`   📄 ${postResponse.rawData.substring(0, 300)}...`);
        
        // محاولة تحليل JSON
        try {
          const data = JSON.parse(postResponse.rawData);
          console.log(`   📊 JSON صالح:`, data);
          
          if (data.token || data.access_token) {
            console.log(`   🎉 تم العثور على Token!`);
          }
        } catch (e) {
          console.log(`   ⚠️ ليس JSON صالح`);
        }
      } else if (postResponse.statusCode === 302 || postResponse.statusCode === 301) {
        console.log(`   🔄 إعادة توجيه - قد يكون نجح التسجيل`);
      }
      
    } catch (error) {
      console.log(`   ❌ خطأ: ${error.message}`);
    }
    
    console.log();
  }
  
  // اختبار إذا كان هناك API منفصل
  console.log('🔍 البحث عن API منفصل...');
  
  const apiPaths = [
    '/api',
    '/api/v1',
    '/webapi',
    '/rest'
  ];
  
  for (const apiPath of apiPaths) {
    try {
      const response = await makeRequest('GET', apiPath);
      if (response.statusCode !== 404) {
        console.log(`✅ ${apiPath} متاح (${response.statusCode})`);
        
        if (!response.rawData.includes('<!DOCTYPE html>')) {
          console.log(`   🎯 قد يكون API! محتوى:`);
          console.log(`   📄 ${response.rawData.substring(0, 200)}...`);
        }
      }
    } catch (error) {
      // تجاهل الأخطاء
    }
  }
}

function makeRequest(method, path, data = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'merchant.alwaseet-iq.net',
      port: 443,
      path: path,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Montajati-App/1.0'
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
          headers: res.headers,
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

testCorrectWaseet();
