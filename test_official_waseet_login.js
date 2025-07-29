const OfficialWaseetAPI = require('./backend/services/official_waseet_api');
require('dotenv').config();

async function testOfficialLogin() {
  console.log('🔍 === اختبار API الوسيط الرسمي ===\n');
  
  try {
    const username = process.env.WASEET_USERNAME;
    const password = process.env.WASEET_PASSWORD;
    
    if (!username || !password) {
      throw new Error('يرجى تعيين WASEET_USERNAME و WASEET_PASSWORD في ملف .env');
    }
    
    console.log(`👤 اسم المستخدم: ${username}`);
    console.log(`🔑 كلمة المرور: ${'*'.repeat(password.length)}\n`);

    // إنشاء خدمة API
    const api = new OfficialWaseetAPI(username, password);

    // اختبار تسجيل الدخول
    console.log('🔐 اختبار تسجيل الدخول...');
    const token = await api.authenticate();
    
    if (token) {
      console.log('\n✅ === نجح تسجيل الدخول ===');
      console.log(`🎫 التوكن: ${token.substring(0, 30)}...`);
      console.log(`📏 طول التوكن: ${token.length} حرف`);
      
      // اختبار جلب الحالات
      console.log('\n📊 اختبار جلب حالات الطلبات...');
      const statusResult = await api.getOrderStatuses();
      
      if (statusResult.success) {
        console.log('✅ تم الاتصال بنجاح');
        console.log(`📝 الرسالة: ${statusResult.message}`);
      } else {
        console.log('❌ فشل جلب الحالات:', statusResult.error);
      }
      
    } else {
      console.log('❌ فشل في الحصول على التوكن');
    }

  } catch (error) {
    console.error('\n❌ === فشل الاختبار ===');
    console.error(`📝 الخطأ: ${error.message}`);
    
    if (error.response) {
      console.error(`📊 كود HTTP: ${error.response.status}`);
      console.error(`📄 بيانات الخطأ:`, error.response.data);
    }
  }
}

// تشغيل الاختبار
testOfficialLogin();
