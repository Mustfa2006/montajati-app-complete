const OrderSyncService = require('./backend/services/order_sync_service');
require('dotenv').config();

async function testStatusSync() {
  console.log('🔄 === اختبار مزامنة حالات الوسيط ===\n');
  
  try {
    // إنشاء خدمة المزامنة
    const syncService = new OrderSyncService();

    // تشغيل مزامنة الحالات
    console.log('🔄 بدء مزامنة حالات الوسيط...');
    const syncResult = await syncService.syncWaseetStatuses();
    
    if (syncResult.success) {
      console.log('\n✅ === نجحت المزامنة ===');
      console.log(`📊 إجمالي الحالات من الوسيط: ${syncResult.totalStatuses}`);
      console.log(`🔄 تم تحديث: ${syncResult.updated} حالة`);
      console.log(`✅ مطابق: ${syncResult.matched} حالة`);
      console.log(`⏭️ مُتجاهل: ${syncResult.ignored} حالة`);
      
    } else {
      console.log('\n❌ === فشلت المزامنة ===');
      console.log(`📝 الخطأ: ${syncResult.error}`);
    }

  } catch (error) {
    console.error('\n❌ === خطأ في الاختبار ===');
    console.error(`📝 الخطأ: ${error.message}`);
  }
}

// تشغيل الاختبار
testStatusSync();
