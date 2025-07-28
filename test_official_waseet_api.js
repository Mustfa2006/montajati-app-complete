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
    
    console.log('\n📊 اختبار جلب حالات الطلبات...');
    const statusesResult = await apiService.getOrderStatuses();
    
    if (statusesResult.success) {
      console.log(`✅ تم جلب ${statusesResult.total} حالة بنجاح`);
      console.log('\n📋 الحالات المتاحة:');
      
      statusesResult.statuses.forEach((status, index) => {
        console.log(`${index + 1}. ID: ${status.id} - الحالة: ${status.status}`);
      });
      
      console.log('\n🔄 اختبار مزامنة حالات الطلبات...');
      const syncResult = await apiService.syncOrderStatuses();
      
      if (syncResult.success) {
        console.log(`✅ المزامنة نجحت:`);
        console.log(`   📦 تم فحص: ${syncResult.checked} طلب`);
        console.log(`   🔄 تم تحديث: ${syncResult.updated} طلب`);
        
        if (syncResult.errors && syncResult.errors.length > 0) {
          console.log(`   ⚠️ أخطاء: ${syncResult.errors.length}`);
          syncResult.errors.forEach(error => console.log(`      - ${error}`));
        }
      } else {
        console.log(`❌ فشلت المزامنة: ${syncResult.error}`);
      }
      
    } else {
      console.log(`❌ فشل جلب الحالات: ${statusesResult.error}`);
    }
    
    console.log('\n🎉 انتهى الاختبار بنجاح!');
    
  } catch (error) {
    console.log('\n❌ فشل الاختبار:');
    console.log(`خطأ: ${error.message}`);
    console.log(`التفاصيل: ${error.stack}`);
  }
}

testOfficialWaseetAPI().catch(console.error);
