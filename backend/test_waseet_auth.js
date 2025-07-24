// ===================================
// اختبار المصادقة مع شركة الوسيط
// Test Waseet Authentication
// ===================================

// تحميل متغيرات البيئة
require('dotenv').config();

const WaseetAPIClient = require('./services/waseet_api_client');

async function testWaseetAuth() {
  console.log('🧪 اختبار المصادقة مع شركة الوسيط...');
  console.log('='.repeat(50));

  try {
    // 1. إنشاء عميل API
    console.log('\n1️⃣ إنشاء عميل API...');
    const waseetClient = new WaseetAPIClient();
    console.log('✅ تم إنشاء عميل API بنجاح');

    // 2. عرض بيانات المصادقة (بدون كشف كلمة المرور)
    console.log('\n2️⃣ بيانات المصادقة:');
    console.log(`📧 اسم المستخدم: ${process.env.WASEET_USERNAME}`);
    console.log(`🔐 كلمة المرور: ${'*'.repeat(process.env.WASEET_PASSWORD?.length || 0)}`);

    // 3. اختبار تسجيل الدخول
    console.log('\n3️⃣ اختبار تسجيل الدخول...');
    const loginResult = await waseetClient.login();

    if (loginResult) {
      console.log('✅ تم تسجيل الدخول بنجاح');
      console.log(`🎫 Token: ${waseetClient.token ? 'موجود' : 'غير موجود'}`);
      
      // 4. اختبار جلب الطلبات
      console.log('\n4️⃣ اختبار جلب الطلبات...');
      const ordersResult = await waseetClient.getOrders();
      
      if (ordersResult && ordersResult.success) {
        console.log('✅ تم جلب الطلبات بنجاح');
        console.log(`📊 عدد الطلبات: ${ordersResult.orders?.length || 0}`);
      } else {
        console.log('❌ فشل في جلب الطلبات:', ordersResult?.error);
      }

      // 5. اختبار إنشاء طلب تجريبي (بدون إرسال فعلي)
      console.log('\n5️⃣ اختبار بيانات إنشاء طلب...');
      const testOrderData = {
        clientName: 'عميل تجريبي',
        clientMobile: '07901234567',
        cityId: '1',
        regionId: '1',
        location: 'بغداد - الكرادة',
        typeName: 'عادي',
        itemsNumber: 1,
        price: 25000,
        packageSize: '1',
        merchantNotes: 'طلب تجريبي للاختبار',
        replacement: 0
      };
      
      console.log('📋 بيانات الطلب التجريبي:');
      console.log(JSON.stringify(testOrderData, null, 2));
      
      console.log('\n⚠️ لن يتم إرسال الطلب فعلياً - هذا مجرد اختبار للبيانات');

    } else {
      console.log('❌ فشل في تسجيل الدخول');
      
      // محاولة تشخيص المشكلة
      console.log('\n🔍 تشخيص المشكلة:');
      console.log('1. تحقق من صحة اسم المستخدم وكلمة المرور');
      console.log('2. تحقق من اتصال الإنترنت');
      console.log('3. تحقق من أن API الوسيط يعمل');
      console.log('4. تحقق من أن الحساب غير مقفل');
    }

    console.log('\n🎯 انتهى اختبار المصادقة');

  } catch (error) {
    console.error('❌ خطأ في اختبار المصادقة:', error);
  }
}

// تشغيل الاختبار
if (require.main === module) {
  testWaseetAuth()
    .then(() => {
      console.log('\n✅ انتهى الاختبار');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ فشل الاختبار:', error);
      process.exit(1);
    });
}

module.exports = { testWaseetAuth };
