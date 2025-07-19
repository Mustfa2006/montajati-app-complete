// ===================================
// تشخيص مشكلة تسجيل الدخول لشركة الوسيط
// ===================================

require('dotenv').config();
const axios = require('axios');

async function debugWaseetLogin() {
  console.log('🔍 تشخيص مشكلة تسجيل الدخول لشركة الوسيط...\n');
  
  // إعدادات الاتصال
  const baseUrl = process.env.ALMASEET_BASE_URL || 'https://api.alwaseet-iq.net';
  const username = process.env.WASEET_USERNAME;
  const password = process.env.WASEET_PASSWORD;
  
  console.log('📋 إعدادات الاتصال:');
  console.log('🔗 الرابط:', baseUrl);
  console.log('👤 اسم المستخدم:', username);
  console.log('🔑 كلمة المرور:', password ? '***' + password.slice(-3) : 'غير محددة');
  console.log('');
  
  try {
    // الخطوة 1: اختبار الوصول لصفحة تسجيل الدخول
    console.log('📝 الخطوة 1: اختبار الوصول لصفحة تسجيل الدخول...');
    const loginUrl = `${baseUrl}/merchant/login`;
    
    const loginPageResponse = await axios.get(loginUrl, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
      },
      timeout: 30000
    });
    
    console.log('✅ تم الوصول لصفحة تسجيل الدخول');
    console.log('📊 حالة الاستجابة:', loginPageResponse.status);
    console.log('🍪 عدد الكوكيز:', loginPageResponse.headers['set-cookie']?.length || 0);
    
    // استخراج الكوكيز
    const cookies = loginPageResponse.headers['set-cookie'] || [];
    const cookieString = cookies.map(cookie => cookie.split(';')[0]).join('; ');
    console.log('🍪 الكوكيز:', cookieString);
    console.log('');
    
    // الخطوة 2: محاولة تسجيل الدخول
    console.log('📝 الخطوة 2: محاولة تسجيل الدخول...');
    
    const loginData = new URLSearchParams();
    loginData.append('username', username);
    loginData.append('password', password);
    loginData.append('submit', 'Login');
    
    console.log('📤 بيانات تسجيل الدخول:');
    console.log('   username:', username);
    console.log('   password:', '***');
    console.log('');
    
    const loginResponse = await axios.post(loginUrl, loginData, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Cookie': cookieString,
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Referer': loginUrl,
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.5',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1'
      },
      timeout: 30000,
      maxRedirects: 0,
      validateStatus: function (status) {
        return status < 500; // قبول جميع الحالات أقل من 500
      }
    });
    
    console.log('📊 نتيجة تسجيل الدخول:');
    console.log('   حالة الاستجابة:', loginResponse.status);
    console.log('   نوع المحتوى:', loginResponse.headers['content-type']);
    console.log('   حجم الاستجابة:', loginResponse.data?.length || 0, 'حرف');
    
    // فحص الكوكيز الجديدة
    const newCookies = loginResponse.headers['set-cookie'] || [];
    console.log('🍪 كوكيز جديدة:', newCookies.length);
    
    const allCookies = [...cookies, ...newCookies];
    const finalCookieString = allCookies.map(cookie => cookie.split(';')[0]).join('; ');
    
    console.log('🍪 جميع الكوكيز:', finalCookieString);
    console.log('');
    
    // فحص محتوى الاستجابة
    const responseText = loginResponse.data;
    
    // البحث عن علامات نجاح/فشل تسجيل الدخول
    if (responseText.includes('dashboard') || responseText.includes('لوحة التحكم')) {
      console.log('✅ تسجيل الدخول نجح! تم توجيهك للوحة التحكم');
      return { success: true, token: finalCookieString };
    }
    
    if (responseText.includes('error') || responseText.includes('خطأ') || responseText.includes('Invalid')) {
      console.log('❌ تسجيل الدخول فشل - خطأ في البيانات');
      
      // البحث عن رسالة الخطأ
      const errorMatch = responseText.match(/<div[^>]*error[^>]*>(.*?)<\/div>/i);
      if (errorMatch) {
        console.log('📝 رسالة الخطأ:', errorMatch[1]);
      }
      
      return { success: false, error: 'بيانات تسجيل الدخول غير صحيحة' };
    }
    
    if (responseText.includes('login') || responseText.includes('تسجيل دخول')) {
      console.log('❌ تسجيل الدخول فشل - تم إرجاعك لصفحة تسجيل الدخول');
      return { success: false, error: 'فشل في تسجيل الدخول' };
    }
    
    // إذا كان هناك إعادة توجيه
    if (loginResponse.status === 302 || loginResponse.status === 301 || loginResponse.status === 303) {
      const location = loginResponse.headers['location'];
      console.log('🔄 إعادة توجيه إلى:', location);

      if (location && !location.includes('login')) {
        console.log('✅ تسجيل الدخول نجح! تم إعادة التوجيه');

        // محاولة الوصول للصفحة المعاد التوجيه إليها
        try {
          const redirectResponse = await axios.get(location, {
            headers: {
              'Cookie': finalCookieString,
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            },
            timeout: 15000
          });

          console.log('📊 صفحة إعادة التوجيه:');
          console.log('   حالة:', redirectResponse.status);
          console.log('   حجم المحتوى:', redirectResponse.data?.length || 0);

          if (redirectResponse.data.includes('dashboard') || redirectResponse.data.includes('لوحة')) {
            console.log('✅ تأكيد: تم الوصول للوحة التحكم');
          }

        } catch (redirectError) {
          console.log('⚠️ خطأ في الوصول لصفحة إعادة التوجيه:', redirectError.message);
        }

        return { success: true, token: finalCookieString };
      } else {
        console.log('❌ تسجيل الدخول فشل - إعادة توجيه لصفحة تسجيل الدخول');
        return { success: false, error: 'فشل في تسجيل الدخول' };
      }
    }
    
    // فحص وجود PHPSESSID في الكوكيز
    if (finalCookieString.includes('PHPSESSID')) {
      console.log('✅ تم العثور على PHPSESSID - تسجيل الدخول نجح على الأرجح');
      return { success: true, token: finalCookieString };
    }
    
    console.log('⚠️ حالة غير واضحة - فحص المحتوى...');
    console.log('📄 أول 500 حرف من الاستجابة:');
    console.log(responseText.substring(0, 500));
    
    return { success: false, error: 'حالة غير واضحة' };
    
  } catch (error) {
    console.error('❌ خطأ في تسجيل الدخول:', error.message);
    
    if (error.response) {
      console.log('📊 تفاصيل الخطأ:');
      console.log('   حالة الاستجابة:', error.response.status);
      console.log('   رسالة الحالة:', error.response.statusText);
      console.log('   العناوين:', JSON.stringify(error.response.headers, null, 2));
    }
    
    return { success: false, error: error.message };
  }
}

// تشغيل التشخيص
if (require.main === module) {
  debugWaseetLogin().then(result => {
    console.log('\n' + '='.repeat(50));
    console.log('📊 النتيجة النهائية:');
    console.log('='.repeat(50));
    
    if (result.success) {
      console.log('✅ تسجيل الدخول نجح!');
      console.log('🎫 التوكن متوفر');
    } else {
      console.log('❌ تسجيل الدخول فشل');
      console.log('📝 السبب:', result.error);
    }
    
    console.log('='.repeat(50));
    process.exit(result.success ? 0 : 1);
  });
}

module.exports = debugWaseetLogin;
