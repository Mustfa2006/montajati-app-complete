const RealTimeWaseetSync = require('./backend/services/real_time_waseet_sync');
require('dotenv').config();

async function testRealTimeSync() {
  console.log('🚀 === اختبار نظام المزامنة الحقيقي ===\n');
  
  try {
    // إنشاء النظام
    const syncSystem = new RealTimeWaseetSync();
    
    // اختبار مزامنة واحدة
    console.log('🔄 اختبار مزامنة واحدة...');
    const result = await syncSystem.performFullSync();
    
    if (result.success) {
      console.log('\n✅ === نجح الاختبار ===');
      console.log(`📊 إجمالي الطلبات: ${result.totalOrders}`);
      console.log(`🔄 تم تحديث: ${result.updated} طلب`);
      console.log(`❌ أخطاء: ${result.errors}`);
      console.log(`⏱️ المدة: ${result.duration}ms`);
      
      // عرض إحصائيات النظام
      const stats = syncSystem.getSystemStats();
      console.log('\n📊 === إحصائيات النظام ===');
      console.log(`🔄 حالة النظام: ${stats.isRunning ? '🟢 يعمل' : '🔴 متوقف'}`);
      console.log(`⏰ آخر مزامنة: ${stats.lastSyncTime ? stats.lastSyncTime.toLocaleString('ar-EG') : 'لم تتم بعد'}`);
      console.log(`🔄 فترة المزامنة: كل ${stats.syncInterval / 60000} دقيقة`);
      
    } else {
      console.log('\n❌ === فشل الاختبار ===');
      console.log(`📝 الخطأ: ${result.error}`);
    }

  } catch (error) {
    console.error('\n❌ === خطأ في الاختبار ===');
    console.error(`📝 الخطأ: ${error.message}`);
  }
}

// تشغيل الاختبار
testRealTimeSync();
