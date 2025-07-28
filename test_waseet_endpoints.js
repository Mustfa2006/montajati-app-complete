const axios = require('axios');

async function testWaseetEndpoints() {
  console.log('🔍 === اختبار endpoints مختلفة للحصول على API token ===\n');
  
  try {
    // تسجيل الدخول أولاً
    console.log('🔐 تسجيل الدخول...');
    
    const loginData = new URLSearchParams({
      username: 'mustfaabd',
      password: '65888304'
    });

    const loginResponse = await axios.post('https://merchant.alwaseet-iq.net/merchant/login', loginData, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      },
      timeout: 30000,
      maxRedirects: 0,
      validateStatus: (status) => status < 400
    });

    const cookies = loginResponse.headers['set-cookie'];
    const cookieString = cookies.map(cookie => cookie.split(';')[0]).join('; ');
    console.log('✅ تم تسجيل الدخول بنجاح');

    // جرب endpoints مختلفة للحصول على API token
    const endpoints = [
      '/api/token',
      '/api/auth/token', 
      '/merchant/api/token',
      '/merchant/token',
      '/v1/auth/token',
      '/v1/token',
      '/auth/api-token',
      '/profile',
      '/merchant/profile',
      '/api/profile'
    ];

    for (const endpoint of endpoints) {
      try {
        console.log(`\n🔍 جرب endpoint: https://merchant.alwaseet-iq.net${endpoint}`);
        
        const response = await axios.get(`https://merchant.alwaseet-iq.net${endpoint}`, {
          headers: {
            'Cookie': cookieString,
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept': 'application/json'
          },
          timeout: 15000
        });

        console.log(`✅ ${endpoint}: ${response.status}`);
        
        if (response.data && typeof response.data === 'object') {
          console.log('📄 استجابة JSON:', JSON.stringify(response.data, null, 2));
          
          // البحث عن توكن في الاستجابة
          const responseStr = JSON.stringify(response.data);
          if (responseStr.includes('token') || responseStr.includes('api') || responseStr.includes('key')) {
            console.log('🎯 يحتوي على معلومات توكن!');
          }
        } else {
          console.log(`📄 نوع الاستجابة: ${typeof response.data}, الطول: ${response.data?.length || 'N/A'}`);
        }

      } catch (error) {
        console.log(`❌ ${endpoint}: ${error.response?.status || error.message}`);
      }
    }

    // جرب أيضاً على الرابط الأساسي للـ API
    console.log('\n🔍 === جرب endpoints على api.alwaseet-iq.net ===');
    
    const apiEndpoints = [
      '/v1/auth/login',
      '/v1/login', 
      '/login',
      '/auth/token'
    ];

    for (const endpoint of apiEndpoints) {
      try {
        console.log(`\n🔍 جرب: https://api.alwaseet-iq.net${endpoint}`);
        
        // جرب POST مع بيانات تسجيل الدخول
        const response = await axios.post(`https://api.alwaseet-iq.net${endpoint}`, loginData, {
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
          },
          timeout: 15000
        });

        console.log(`✅ ${endpoint}: ${response.status}`);
        console.log('📄 استجابة:', JSON.stringify(response.data, null, 2));

      } catch (error) {
        console.log(`❌ ${endpoint}: ${error.response?.status || error.message}`);
        if (error.response?.data) {
          console.log('📄 خطأ:', JSON.stringify(error.response.data, null, 2));
        }
      }
    }

  } catch (error) {
    console.log('\n❌ فشل الاختبار:');
    console.log(`خطأ: ${error.message}`);
  }
}

testWaseetEndpoints().catch(console.error);
