// ===================================
// البحث عن API endpoints الحقيقية للوسيط
// ===================================

const https = require('https');
require('dotenv').config();

async function findRealAPI() {
  console.log('🔍 البحث عن API endpoints الحقيقية...\n');
  
  // قائمة شاملة من المسارات المحتملة
  const apiPaths = [
    // API مسارات عامة
    '/api',
    '/api/v1',
    '/api/v2',
    '/v1',
    '/v2',
    
    // مسارات تسجيل الدخول
    '/api/login',
    '/api/auth',
    '/api/auth/login',
    '/api/merchant/login',
    '/api/merchant/auth',
    '/api/user/login',
    '/api/signin',
    '/api/authenticate',
    '/api/token',
    
    // مسارات مع إصدارات
    '/api/v1/login',
    '/api/v1/auth',
    '/api/v1/auth/login',
    '/api/v1/merchant/login',
    '/api/v2/login',
    '/api/v2/auth',
    '/api/v2/merchant/login',
    
    // مسارات أخرى محتملة
    '/rest/login',
    '/rest/auth',
    '/webapi/login',
    '/webapi/auth',
    '/service/login',
    '/service/auth',
    
    // مسارات خاصة بالوسيط
    '/waseet/login',
    '/waseet/auth',
    '/delivery/login',
    '/delivery/auth',
    '/courier/login',
    '/courier/auth'
  ];

  console.log(`🔄 فحص ${apiPaths.length} مسار محتمل...\n`);
  
  const workingPaths = [];
  
  for (const path of apiPaths) {
    try {
      const response = await makeRequest('GET', path);
      
      if (response.statusCode !== 404) {
        console.log(`✅ ${path} - ${response.statusCode}`);
        
        // فحص إذا كان يرجع JSON وليس HTML
        if (response.rawData && !response.rawData.includes('<!DOCTYPE html>')) {
          console.log(`   🎯 يبدو أنه API حقيقي!`);
          console.log(`   📄 محتوى: ${response.rawData.substring(0, 150)}...`);
          workingPaths.push(path);
        } else {
          console.log(`   📄 صفحة HTML`);
        }
      }
    } catch (error) {
      // تجاهل الأخطاء
    }
  }
  
  console.log(`\n📋 المسارات التي تعمل: ${workingPaths.length}`);
  
  if (workingPaths.length > 0) {
    console.log('\n🎯 اختبار المسارات الواعدة...');
    
    for (const path of workingPaths) {
      await testAPIPath(path);
    }
  } else {
    console.log('\n❌ لم يتم العثور على API endpoints حقيقية');
    console.log('💡 ربما يكون API الوسيط:');
    console.log('   1. يتطلب مصادقة مسبقة');
    console.log('   2. يستخدم subdomain مختلف');
    console.log('   3. غير متاح حالياً');
    
    // محاولة subdomains مختلفة
    await tryDifferentSubdomains();
  }
}

async function testAPIPath(path) {
  console.log(`\n🧪 اختبار ${path}...`);
  
  const username = process.env.WASEET_USERNAME;
  const password = process.env.WASEET_PASSWORD;
  
  try {
    const postData = JSON.stringify({
      username: username,
      password: password
    });
    
    const response = await makeRequest('POST', path, postData);
    
    console.log(`   📊 POST: ${response.statusCode}`);
    
    if (response.rawData && !response.rawData.includes('<!DOCTYPE html>')) {
      console.log(`   📄 استجابة: ${response.rawData.substring(0, 200)}...`);
      
      // فحص إذا كان هناك token أو رسالة خطأ مفيدة
      try {
        const data = JSON.parse(response.rawData);
        if (data.token || data.access_token || data.error || data.message) {
          console.log(`   🎉 استجابة API صالحة!`);
        }
      } catch (e) {
        // ليس JSON صالح
      }
    }
  } catch (error) {
    console.log(`   ❌ خطأ: ${error.message}`);
  }
}

async function tryDifferentSubdomains() {
  console.log('\n🌐 محاولة subdomains مختلفة...');
  
  const subdomains = [
    'api.alwaseet-iq.net',
    'app.alwaseet-iq.net',
    'merchant.alwaseet-iq.net',
    'delivery.alwaseet-iq.net',
    'service.alwaseet-iq.net',
    'rest.alwaseet-iq.net',
    'webapi.alwaseet-iq.net'
  ];
  
  for (const subdomain of subdomains) {
    try {
      console.log(`🔄 فحص ${subdomain}...`);
      
      const response = await makeRequestToHost(subdomain, '/');
      
      if (response.statusCode === 200) {
        console.log(`✅ ${subdomain} متاح`);
        
        if (!response.rawData.includes('<!DOCTYPE html>')) {
          console.log(`   🎯 قد يكون API!`);
          console.log(`   📄 محتوى: ${response.rawData.substring(0, 100)}...`);
        }
      }
    } catch (error) {
      console.log(`❌ ${subdomain} غير متاح`);
    }
  }
}

function makeRequest(method, path, data = null) {
  return makeRequestToHost('api.alwaseet-iq.net', path, method, data);
}

function makeRequestToHost(hostname, path, method = 'GET', data = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: hostname,
      port: 443,
      path: path,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      timeout: 10000
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

findRealAPI();
