const axios = require('axios');
require('dotenv').config();

async function testWaseetConnection() {
  console.log('🔍 === اختبار الاتصال بشركة الوسيط ===\n');
  
  // فحص متغيرات البيئة
  console.log('📋 فحص متغيرات البيئة:');
  console.log(`WASEET_USERNAME: ${process.env.WASEET_USERNAME ? '✅ موجود' : '❌ مفقود'}`);
  console.log(`WASEET_PASSWORD: ${process.env.WASEET_PASSWORD ? '✅ موجود' : '❌ مفقود'}`);
  console.log(`ALMASEET_BASE_URL: ${process.env.ALMASEET_BASE_URL || 'https://api.alwaseet-iq.net'}`);
  
  if (!process.env.WASEET_USERNAME || !process.env.WASEET_PASSWORD) {
    console.log('\n❌ متغيرات الوسيط مفقودة! إضافة القيم الافتراضية...');
    process.env.WASEET_USERNAME = 'mustfaabd2006@gmail.com';
    process.env.WASEET_PASSWORD = 'mustfaabd2006@';
    console.log('✅ تم إضافة القيم الافتراضية');
  }
  
  const baseUrl = process.env.ALMASEET_BASE_URL || 'https://api.alwaseet-iq.net';
  
  try {
    console.log('\n🔐 محاولة تسجيل الدخول...');
    
    const loginData = new URLSearchParams({
      username: process.env.WASEET_USERNAME,
      password: process.env.WASEET_PASSWORD
    });
    
    const loginResponse = await axios.post(`${baseUrl}/login`, loginData, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      },
      timeout: 15000,
      maxRedirects: 0,
      validateStatus: (status) => status < 400
    });
    
    console.log(`✅ تسجيل الدخول نجح: ${loginResponse.status}`);
    
    // استخراج الكوكيز
    const cookies = loginResponse.headers['set-cookie'];
    if (!cookies) {
      throw new Error('لم يتم الحصول على كوكيز من تسجيل الدخول');
    }
    
    const cookieString = cookies.map(cookie => cookie.split(';')[0]).join('; ');
    console.log('🍪 تم الحصول على الكوكيز');
    
    console.log('\n📄 محاولة جلب صفحة التاجر...');
    
    const merchantResponse = await axios.get(`${baseUrl}/merchant`, {
      headers: {
        'Cookie': cookieString,
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      },
      timeout: 15000
    });
    
    console.log(`✅ جلب صفحة التاجر نجح: ${merchantResponse.status}`);
    console.log(`📊 حجم الصفحة: ${merchantResponse.data.length} حرف`);
    
    // فحص محتوى الصفحة
    const pageContent = merchantResponse.data;
    
    if (pageContent.includes('table') || pageContent.includes('طلب')) {
      console.log('✅ الصفحة تحتوي على جدول الطلبات');
      
      // محاولة استخراج عدد الطلبات
      const tableMatches = pageContent.match(/<tr[^>]*>/g);
      if (tableMatches) {
        console.log(`📦 عدد الصفوف المحتمل: ${tableMatches.length - 1}`); // -1 للهيدر
      }
      
    } else {
      console.log('⚠️ الصفحة لا تحتوي على جدول طلبات واضح');
      console.log('📄 أول 500 حرف من الصفحة:');
      console.log(pageContent.substring(0, 500));
    }
    
    console.log('\n🎉 الاختبار نجح! الاتصال بشركة الوسيط يعمل');
    
  } catch (error) {
    console.log('\n❌ فشل الاختبار:');
    console.log(`خطأ: ${error.message}`);
    
    if (error.response) {
      console.log(`رمز الاستجابة: ${error.response.status}`);
      console.log(`رسالة الخادم: ${error.response.statusText}`);
      
      if (error.response.data) {
        console.log('محتوى الاستجابة:');
        console.log(typeof error.response.data === 'string' 
          ? error.response.data.substring(0, 500)
          : JSON.stringify(error.response.data, null, 2)
        );
      }
    }
  }
}

testWaseetConnection().catch(console.error);
