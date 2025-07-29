const RealTimeWaseetSync = require('./backend/services/real_time_waseet_sync');
require('dotenv').config();

/**
 * تشغيل نظام المزامنة الحقيقي
 */
async function startRealTimeSystem() {
  console.log('🚀 === تشغيل نظام المزامنة الحقيقي مع الوسيط ===\n');
  
  try {
    // إنشاء النظام
    const syncSystem = new RealTimeWaseetSync();
    
    // بدء النظام
    await syncSystem.startRealTimeSync();
    
    // عرض الإحصائيات كل 30 ثانية
    setInterval(() => {
      const stats = syncSystem.getSystemStats();
      console.log('\n📊 === إحصائيات النظام ===');
      console.log(`🔄 حالة النظام: ${stats.isRunning ? '🟢 يعمل' : '🔴 متوقف'}`);
      console.log(`⏰ آخر مزامنة: ${stats.lastSyncTime ? stats.lastSyncTime.toLocaleString('ar-EG') : 'لم تتم بعد'}`);
      console.log(`⏳ المزامنة التالية خلال: ${stats.nextSyncIn ? Math.round(stats.nextSyncIn / 1000) + ' ثانية' : 'غير محدد'}`);
      console.log(`🔄 فترة المزامنة: كل ${stats.syncInterval / 60000} دقيقة`);
    }, 30000);
    
    // معالجة إيقاف النظام بأمان
    process.on('SIGINT', () => {
      console.log('\n⏹️ إيقاف النظام...');
      syncSystem.stopRealTimeSync();
      process.exit(0);
    });
    
    process.on('SIGTERM', () => {
      console.log('\n⏹️ إيقاف النظام...');
      syncSystem.stopRealTimeSync();
      process.exit(0);
    });
    
    console.log('\n🎉 === النظام يعمل بنجاح ===');
    console.log('📱 المزامنة المستمرة للطلبات');
    console.log('🔄 تحديث تلقائي للحالات');
    console.log('📊 مراقبة مستمرة');
    console.log('⏹️ اضغط Ctrl+C للإيقاف');
    console.log('🎉'.repeat(50));
    
  } catch (error) {
    console.error('\n❌ === فشل تشغيل النظام ===');
    console.error(`📝 الخطأ: ${error.message}`);
    process.exit(1);
  }
}

// تشغيل النظام
startRealTimeSystem();
