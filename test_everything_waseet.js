const axios = require('axios');

async function testEverything() {
  console.log('🔍 === اختبار شامل لجميع طرق الوسيط ===\n');
  
  const credentials = {
    username: 'mustfaabd',
    password: '65888304'
  };

  let sessionCookie = null;

  try {
    // ===== الخطوة 1: تسجيل الدخول =====
    console.log('🔐 === الخطوة 1: تسجيل الدخول ===');
    
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

    const cookies = loginResponse.headers['set-cookie'];
    sessionCookie = cookies.map(cookie => cookie.split(';')[0]).join('; ');
    console.log('✅ تم تسجيل الدخول بنجاح');
    console.log(`🍪 الكوكيز: ${sessionCookie}`);

    // ===== الخطوة 2: جرب جميع أشكال التوكن =====
    console.log('\n🎯 === الخطوة 2: جرب جميع أشكال التوكن ===');
    
    const sessionId = sessionCookie.match(/ci_session=([^;]+)/)?.[1];
    console.log(`📋 Session ID: ${sessionId}`);

    const tokenVariations = [
      sessionId,                    // Session ID فقط
      sessionCookie,               // الكوكيز كاملة
      `ci_session=${sessionId}`,   // مع البادئة
      sessionId?.substring(0, 32), // أول 32 حرف
      sessionId?.substring(8),     // بدون أول 8 أحرف
    ];

    for (let i = 0; i < tokenVariations.length; i++) {
      const token = tokenVariations[i];
      if (!token) continue;

      console.log(`\n🔍 جرب التوكن ${i + 1}: ${token.substring(0, 20)}...`);
      
      try {
        const response = await axios.get('https://api.alwaseet-iq.net/v1/merchant/statuses', {
          params: { token: token },
          headers: {
            'Content-Type': 'multipart/form-data',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
          },
          timeout: 15000
        });

        console.log(`✅ نجح! الحالة: ${response.status}`);
        console.log('📄 الاستجابة:', JSON.stringify(response.data, null, 2));
        
        if (response.data.status && response.data.errNum === 'S000') {
          console.log('🎉 === وجدنا التوكن الصحيح! ===');
          console.log(`🎯 التوكن الصحيح: ${token}`);
          return;
        }

      } catch (error) {
        console.log(`❌ فشل: ${error.response?.status} - ${error.response?.data?.msg || error.message}`);
      }
    }

    // ===== الخطوة 3: جرب endpoints مختلفة للحصول على توكن =====
    console.log('\n🔍 === الخطوة 3: البحث عن endpoints للتوكن ===');
    
    const endpoints = [
      'https://merchant.alwaseet-iq.net/api/token',
      'https://merchant.alwaseet-iq.net/merchant/api/token',
      'https://merchant.alwaseet-iq.net/merchant/token',
      'https://merchant.alwaseet-iq.net/profile',
      'https://merchant.alwaseet-iq.net/merchant/profile',
      'https://merchant.alwaseet-iq.net/merchant/dashboard',
      'https://merchant.alwaseet-iq.net/merchant/settings',
      'https://api.alwaseet-iq.net/v1/auth/login',
      'https://api.alwaseet-iq.net/login'
    ];

    for (const endpoint of endpoints) {
      try {
        console.log(`\n🔍 جرب: ${endpoint}`);
        
        // جرب GET أولاً
        try {
          const getResponse = await axios.get(endpoint, {
            headers: {
              'Cookie': sessionCookie,
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              'Accept': 'application/json'
            },
            timeout: 10000
          });

          console.log(`✅ GET ${endpoint}: ${getResponse.status}`);
          
          if (getResponse.data && typeof getResponse.data === 'object') {
            console.log('📄 استجابة JSON:', JSON.stringify(getResponse.data, null, 2));
            
            // البحث عن توكن
            const responseStr = JSON.stringify(getResponse.data);
            if (responseStr.includes('token') || responseStr.includes('api_key')) {
              console.log('🎯 يحتوي على توكن!');
            }
          }

        } catch (getError) {
          console.log(`❌ GET فشل: ${getError.response?.status || getError.message}`);
          
          // جرب POST إذا فشل GET
          try {
            const postResponse = await axios.post(endpoint, loginData, {
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'Cookie': sessionCookie,
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
              },
              timeout: 10000
            });

            console.log(`✅ POST ${endpoint}: ${postResponse.status}`);
            console.log('📄 استجابة POST:', JSON.stringify(postResponse.data, null, 2));

          } catch (postError) {
            console.log(`❌ POST فشل: ${postError.response?.status || postError.message}`);
          }
        }

      } catch (error) {
        console.log(`❌ خطأ عام: ${error.message}`);
      }
    }

    // ===== الخطوة 4: فحص صفحة التاجر للبحث عن توكن مخفي =====
    console.log('\n🔍 === الخطوة 4: فحص صفحة التاجر ===');
    
    try {
      const merchantResponse = await axios.get('https://merchant.alwaseet-iq.net/merchant', {
        headers: {
          'Cookie': sessionCookie,
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
        timeout: 15000
      });

      console.log('✅ تم جلب صفحة التاجر');
      const pageContent = merchantResponse.data;

      // البحث عن أنماط مختلفة للتوكن
      const patterns = [
        /token['":\s]*['"]([a-zA-Z0-9_-]{20,})['"]/gi,
        /api_token['":\s]*['"]([a-zA-Z0-9_-]{20,})['"]/gi,
        /access_token['":\s]*['"]([a-zA-Z0-9_-]{20,})['"]/gi,
        /loginToken['":\s]*['"]([a-zA-Z0-9_-]{20,})['"]/gi,
        /_token['":\s]*['"]([a-zA-Z0-9_-]{20,})['"]/gi,
        /csrf_token['":\s]*['"]([a-zA-Z0-9_-]{20,})['"]/gi,
        /bearer['":\s]*['"]([a-zA-Z0-9_-]{20,})['"]/gi
      ];

      console.log('🔍 البحث عن توكنات في الصفحة...');
      
      for (const pattern of patterns) {
        const matches = pageContent.match(pattern);
        if (matches) {
          console.log(`🎯 وجدت توكنات محتملة:`, matches.slice(0, 3));
          
          // جرب كل توكن
          for (const match of matches.slice(0, 3)) {
            const tokenMatch = match.match(/['"]([a-zA-Z0-9_-]{20,})['"]/);
            if (tokenMatch) {
              const foundToken = tokenMatch[1];
              console.log(`🔍 جرب توكن من الصفحة: ${foundToken.substring(0, 20)}...`);
              
              try {
                const testResponse = await axios.get('https://api.alwaseet-iq.net/v1/merchant/statuses', {
                  params: { token: foundToken },
                  headers: {
                    'Content-Type': 'multipart/form-data',
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
                  },
                  timeout: 10000
                });

                console.log(`✅ نجح! الحالة: ${testResponse.status}`);
                console.log('📄 الاستجابة:', JSON.stringify(testResponse.data, null, 2));
                
                if (testResponse.data.status && testResponse.data.errNum === 'S000') {
                  console.log('🎉 === وجدنا التوكن الصحيح في الصفحة! ===');
                  console.log(`🎯 التوكن الصحيح: ${foundToken}`);
                  return;
                }

              } catch (testError) {
                console.log(`❌ فشل: ${testError.response?.data?.msg || testError.message}`);
              }
            }
          }
        }
      }

    } catch (error) {
      console.log(`❌ فشل فحص صفحة التاجر: ${error.message}`);
    }

    console.log('\n❌ لم يتم العثور على التوكن الصحيح في جميع المحاولات');

  } catch (error) {
    console.log('\n❌ فشل الاختبار الشامل:');
    console.log(`خطأ: ${error.message}`);
  }
}

testEverything().catch(console.error);
