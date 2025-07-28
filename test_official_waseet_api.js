const WaseetAPIService = require('./backend/services/waseet_api_service');

async function testOfficialWaseetAPI() {
  console.log('🔍 === اختبار API شركة الوسيط الرسمي ===\n');

  try {
    // إنشاء خدمة API
    const apiService = new WaseetAPIService();

    console.log('🔐 اختبار تسجيل الدخول...');
    const token = await apiService.authenticate();
    console.log('✅ تم تسجيل الدخول بنجاح');
    console.log(`🎫 التوكن: ${token.substring(0, 50)}...`);

    console.log('\n📊 اختبار جلب حالات الطلبات من API الرسمي...');
    const statusesResult = await apiService.getOrderStatuses();

    if (statusesResult.success) {
      console.log(`✅ تم جلب ${statusesResult.total} حالة بنجاح`);
      console.log('\n📋 الحالات المتاحة:');

      statusesResult.statuses.forEach((status, index) => {
        console.log(`${index + 1}. ID: ${status.id} - الحالة: ${status.status}`);
      });

    } else {
      console.log(`❌ فشل جلب الحالات: ${statusesResult.error}`);
      console.log('⏳ في انتظار رد شركة الوسيط لتفعيل صلاحية API...');
    }

    console.log('\n🎉 انتهى الاختبار!');

  } catch (error) {
    console.log('\n❌ فشل الاختبار:');
    console.log(`خطأ: ${error.message}`);
  }
}

testOfficialWaseetAPI().catch(console.error);
