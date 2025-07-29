const RealWaseetSyncSystem = require('./backend/services/real_waseet_sync_system');
require('dotenv').config();

async function testRealWaseetSystem() {
  console.log('🚀 === اختبار نظام المزامنة الحقيقي مع API الرسمي ===\n');
  
  try {
    // إنشاء النظام
    const syncSystem = new RealWaseetSyncSystem();
    
    // اختبار مزامنة واحدة
    console.log('🔄 اختبار مزامنة واحدة...');
    const result = await syncSystem.performFullSync();
    
    if (result.success) {
      console.log('\n✅ === نجح الاختبار ===');
      console.log(`📊 إجمالي الطلبات في الوسيط: ${result.totalWaseetOrders}`);
      console.log(`📋 إجمالي الطلبات في قاعدة البيانات: ${result.totalDbOrders}`);
      console.log(`🔄 تم تحديث: ${result.updated} طلب`);
      console.log(`✅ مطابق: ${result.matched} طلب`);
      console.log(`➕ جديد: ${result.new} طلب`);
      console.log(`⏱️ المدة: ${result.duration}ms`);
      
      // عرض إحصائيات النظام
      const stats = syncSystem.getSystemStats();
      console.log('\n📊 === إحصائيات النظام ===');
      console.log(`🔄 حالة النظام: ${stats.isRunning ? '🟢 يعمل' : '🔴 متوقف'}`);
      console.log(`⏰ آخر مزامنة: ${stats.lastSyncTime ? stats.lastSyncTime.toLocaleString('ar-EG') : 'لم تتم بعد'}`);
      console.log(`🔄 فترة المزامنة: كل ${stats.syncIntervalMinutes} دقيقة`);
      console.log(`📈 إجمالي المزامنات: ${stats.stats.totalSyncs}`);
      console.log(`✅ المزامنات الناجحة: ${stats.stats.successfulSyncs}`);
      console.log(`❌ المزامنات الفاشلة: ${stats.stats.failedSyncs}`);
      console.log(`🔄 الطلبات المحدثة: ${stats.stats.ordersUpdated}`);
      
      if (stats.stats.lastError) {
        console.log(`⚠️ آخر خطأ: ${stats.stats.lastError}`);
      }
      
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
testRealWaseetSystem();
