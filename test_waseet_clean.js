const axios = require('axios');

async function testWaseetAPI() {
  console.log('=== اختبار API شركة الوسيط ===\n');
  
  const credentials = {
    username: 'mustfaabd',
    password: '65888304'
  };

  try {
    // الخطوة 1: تسجيل الدخول
    console.log('الخطوة 1: تسجيل الدخول');
    console.log('URL: https://merchant.alwaseet-iq.net/merchant/login');
    console.log('Method: POST');
    console.log('Data: username=' + credentials.username + ', password=' + credentials.password);
    
    const loginData = new URLSearchParams(credentials);
    const loginResponse = await axios.post('https://merchant.alwaseet-iq.net/merchant/login', loginData, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      },
      timeout: 30000,
      maxRedirects: 0,
      validateStatus: (status) => status < 400
    });

    console.log('نتيجة تسجيل الدخول:');
    console.log('- HTTP Status: ' + loginResponse.status);
    console.log('- Status Text: ' + loginResponse.statusText);
    
    const cookies = loginResponse.headers['set-cookie'];
    if (!cookies) {
      console.log('خطأ: لم يتم الحصول على cookies من تسجيل الدخول');
      return;
    }

    const sessionCookie = cookies.map(cookie => cookie.split(';')[0]).join('; ');
    const sessionId = sessionCookie.match(/ci_session=([^;]+)/)?.[1];
    
    console.log('- تم تسجيل الدخول بنجاح');
    console.log('- Session Cookie: ' + sessionCookie);
    console.log('- Session ID: ' + sessionId);
    console.log('');

    // الخطوة 2: اختبار API
    console.log('الخطوة 2: اختبار API');
    console.log('URL: https://api.alwaseet-iq.net/v1/merchant/statuses');
    console.log('Method: GET');
    console.log('Token: ' + sessionId);
    console.log('Full URL: https://api.alwaseet-iq.net/v1/merchant/statuses?token=' + sessionId);
    
    try {
      const apiResponse = await axios.get('https://api.alwaseet-iq.net/v1/merchant/statuses', {
        params: {
          token: sessionId
        },
        headers: {
          'Content-Type': 'multipart/form-data',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
        timeout: 30000
      });

      console.log('نتيجة API:');
      console.log('- HTTP Status: ' + apiResponse.status);
      console.log('- Status Text: ' + apiResponse.statusText);
      console.log('- Response Headers:');
      Object.keys(apiResponse.headers).forEach(key => {
        console.log('  ' + key + ': ' + apiResponse.headers[key]);
      });
      console.log('- Response Body:');
      console.log(JSON.stringify(apiResponse.data, null, 2));

      if (apiResponse.data.status && apiResponse.data.errNum === 'S000') {
        console.log('نجح الاتصال بـ API!');
        console.log('عدد الحالات المستلمة: ' + apiResponse.data.data.length);
      } else {
        console.log('فشل API - تفاصيل الخطأ:');
        console.log('- status: ' + apiResponse.data.status);
        console.log('- errNum: ' + apiResponse.data.errNum);
        console.log('- msg: ' + apiResponse.data.msg);
      }

    } catch (apiError) {
      console.log('خطأ في API:');
      console.log('- Error Type: ' + apiError.name);
      console.log('- Error Message: ' + apiError.message);
      
      if (apiError.response) {
        console.log('- HTTP Status: ' + apiError.response.status);
        console.log('- Status Text: ' + apiError.response.statusText);
        console.log('- Response Headers:');
        Object.keys(apiError.response.headers).forEach(key => {
          console.log('  ' + key + ': ' + apiError.response.headers[key]);
        });
        console.log('- Error Response Body:');
        console.log(JSON.stringify(apiError.response.data, null, 2));
      } else if (apiError.request) {
        console.log('- Request was made but no response received');
        console.log('- Request details: ' + apiError.request);
      } else {
        console.log('- Error in setting up request: ' + apiError.message);
      }
      
      if (apiError.code) {
        console.log('- Error Code: ' + apiError.code);
      }
      
      if (apiError.config) {
        console.log('- Request Config:');
        console.log('  URL: ' + apiError.config.url);
        console.log('  Method: ' + apiError.config.method);
        console.log('  Headers: ' + JSON.stringify(apiError.config.headers, null, 2));
        console.log('  Params: ' + JSON.stringify(apiError.config.params, null, 2));
      }
    }

    // الخطوة 3: اختبار طرق أخرى للتوكن
    console.log('\nالخطوة 3: اختبار طرق أخرى للتوكن');
    
    const tokenVariations = [
      { name: 'Session Cookie كامل', value: sessionCookie },
      { name: 'Session مع البادئة', value: 'ci_session=' + sessionId },
      { name: 'أول 32 حرف من Session', value: sessionId?.substring(0, 32) },
      { name: 'Session بدون أول 8 أحرف', value: sessionId?.substring(8) }
    ];

    for (const variation of tokenVariations) {
      if (!variation.value) continue;
      
      console.log('\nاختبار: ' + variation.name);
      console.log('Token: ' + variation.value);
      
      try {
        const testResponse = await axios.get('https://api.alwaseet-iq.net/v1/merchant/statuses', {
          params: { token: variation.value },
          headers: {
            'Content-Type': 'multipart/form-data',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
          },
          timeout: 15000
        });

        console.log('نتيجة: نجح - HTTP ' + testResponse.status);
        console.log('Response: ' + JSON.stringify(testResponse.data, null, 2));

      } catch (testError) {
        console.log('نتيجة: فشل');
        if (testError.response) {
          console.log('HTTP Status: ' + testError.response.status);
          console.log('Error: ' + JSON.stringify(testError.response.data, null, 2));
        } else {
          console.log('Error: ' + testError.message);
        }
      }
    }

  } catch (loginError) {
    console.log('خطأ في تسجيل الدخول:');
    console.log('- Error Type: ' + loginError.name);
    console.log('- Error Message: ' + loginError.message);
    
    if (loginError.response) {
      console.log('- HTTP Status: ' + loginError.response.status);
      console.log('- Status Text: ' + loginError.response.statusText);
      console.log('- Response Body: ' + JSON.stringify(loginError.response.data, null, 2));
    }
  }

  console.log('\n=== انتهى الاختبار ===');
}

testWaseetAPI().catch(error => {
  console.log('خطأ عام في الاختبار:');
  console.log('Error: ' + error.message);
  console.log('Stack: ' + error.stack);
});
