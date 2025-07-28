const axios = require('axios');

async function testWaseetAPI() {
  console.log('=== اختبار API شركة الوسيط ===\n');
  
  try {
    // تسجيل الدخول
    console.log('1. تسجيل الدخول:');
    console.log('   URL: https://merchant.alwaseet-iq.net/merchant/login');
    console.log('   الحساب: mustfaabd');
    
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
    const sessionId = cookies.map(cookie => cookie.split(';')[0]).join('; ').match(/ci_session=([^;]+)/)?.[1];
    
    console.log('   النتيجة: تم تسجيل الدخول بنجاح');
    console.log('   Session Token: ' + sessionId);
    console.log('');

    // اختبار API
    console.log('2. اختبار API:');
    console.log('   URL: https://api.alwaseet-iq.net/v1/merchant/statuses');
    console.log('   Method: GET');
    console.log('   Token: ' + sessionId);
    console.log('   Full Request: https://api.alwaseet-iq.net/v1/merchant/statuses?token=' + sessionId);
    console.log('');

    const apiResponse = await axios.get('https://api.alwaseet-iq.net/v1/merchant/statuses', {
      params: { token: sessionId },
      headers: {
        'Content-Type': 'multipart/form-data',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      },
      timeout: 30000
    });

    console.log('   النتيجة: نجح API');
    console.log('   Response: ' + JSON.stringify(apiResponse.data, null, 2));

  } catch (error) {
    if (error.response && error.response.status === 400) {
      console.log('   النتيجة: فشل API');
      console.log('   HTTP Status: 400 Bad Request');
      console.log('   Error Response:');
      console.log('   ' + JSON.stringify(error.response.data, null, 2));
      console.log('');
      
      console.log('=== المطلوب من شركة الوسيط ===');
      console.log('');
      console.log('الحساب "mustfaabd" يحتاج تفعيل الصلاحيات التالية:');
      console.log('');
      console.log('1. صلاحية الوصول لـ API endpoint:');
      console.log('   https://api.alwaseet-iq.net/v1/merchant/statuses');
      console.log('');
      console.log('2. حل مشكلة الخطأ رقم 21:');
      console.log('   Error Code: ' + error.response.data.errNum);
      console.log('   Error Message: ' + error.response.data.msg);
      console.log('');
      console.log('3. توضيح طريقة الحصول على التوكن الصحيح:');
      console.log('   - هل Session Token كافي؟');
      console.log('   - أم يحتاج API Key منفصل؟');
      console.log('   - أم يحتاج تفعيل خاص في الحساب؟');
      console.log('');
      console.log('4. تأكيد أن الحساب مفعل لاستخدام API Services');
      console.log('');
      console.log('=== تفاصيل تقنية للدعم ===');
      console.log('');
      console.log('Account: mustfaabd');
      console.log('API Endpoint: GET https://api.alwaseet-iq.net/v1/merchant/statuses?token=SESSION_ID');
      console.log('Current Error: HTTP 400 - errNum: 21 - "ليس لديك صلاحية الوصول"');
      console.log('Login Status: Success (Session token obtained successfully)');
      console.log('Request Headers: Content-Type: multipart/form-data');
      console.log('');
      
    } else {
      console.log('   خطأ غير متوقع:');
      console.log('   ' + error.message);
      if (error.response) {
        console.log('   HTTP Status: ' + error.response.status);
        console.log('   Response: ' + JSON.stringify(error.response.data, null, 2));
      }
    }
  }

  console.log('=== انتهى الاختبار ===');
}

testWaseetAPI().catch(error => {
  console.log('خطأ عام: ' + error.message);
});
