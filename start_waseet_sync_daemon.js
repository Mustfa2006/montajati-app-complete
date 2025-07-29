const RealWaseetSyncSystem = require('./backend/services/real_waseet_sync_system');
require('dotenv').config();

/**
 * تشغيل نظام المزامنة المستمر مع الوسيط
 * Waseet Sync Daemon - يعمل كل 3 دقائق
 */
async function startWaseetSyncDaemon() {
  console.log('🚀 === تشغيل نظام المزامنة المستمر مع الوسيط ===\n');
  
  try {
    // إنشاء النظام
    const syncSystem = new RealWaseetSyncSystem();
    
    // بدء النظام المستمر
    await syncSystem.startRealTimeSync();
    
    // عرض الإحصائيات كل دقيقة
    setInterval(() => {
      const stats = syncSystem.getSystemStats();
      const now = new Date();
      
      console.log('\n📊 === إحصائيات النظام ===');
      console.log(`⏰ الوقت الحالي: ${now.toLocaleString('ar-EG')}`);
      console.log(`🔄 حالة النظام: ${stats.isRunning ? '🟢 يعمل' : '🔴 متوقف'}`);
      console.log(`⏰ آخر مزامنة: ${stats.lastSyncTime ? stats.lastSyncTime.toLocaleString('ar-EG') : 'لم تتم بعد'}`);
      
      if (stats.nextSyncIn) {
        const nextSyncMinutes = Math.round(stats.nextSyncIn / 60000);
        const nextSyncSeconds = Math.round((stats.nextSyncIn % 60000) / 1000);
        console.log(`⏳ المزامنة التالية خلال: ${nextSyncMinutes}:${nextSyncSeconds.toString().padStart(2, '0')}`);
      }
      
      console.log(`🔄 فترة المزامنة: كل ${stats.syncIntervalMinutes} دقيقة`);
      console.log(`📈 إجمالي المزامنات: ${stats.stats.totalSyncs}`);
      console.log(`✅ المزامنات الناجحة: ${stats.stats.successfulSyncs}`);
      console.log(`❌ المزامنات الفاشلة: ${stats.stats.failedSyncs}`);
      console.log(`🔄 الطلبات المحدثة: ${stats.stats.ordersUpdated}`);
      
      if (stats.stats.lastError) {
        console.log(`⚠️ آخر خطأ: ${stats.stats.lastError}`);
      }
      
      console.log('─'.repeat(50));
      
    }, 60000); // كل دقيقة
    
    // معالجة إيقاف النظام بأمان
    process.on('SIGINT', () => {
      console.log('\n⏹️ إيقاف النظام...');
      syncSystem.stopRealTimeSync();
      console.log('✅ تم إيقاف النظام بأمان');
      process.exit(0);
    });
    
    process.on('SIGTERM', () => {
      console.log('\n⏹️ إيقاف النظام...');
      syncSystem.stopRealTimeSync();
      console.log('✅ تم إيقاف النظام بأمان');
      process.exit(0);
    });
    
    // معالجة الأخطاء غير المتوقعة
    process.on('uncaughtException', (error) => {
      console.error('\n❌ خطأ غير متوقع:', error.message);
      console.error('📚 تفاصيل الخطأ:', error.stack);
      console.log('🔄 محاولة الاستمرار...');
    });
    
    process.on('unhandledRejection', (reason, promise) => {
      console.error('\n❌ Promise مرفوض:', reason);
      console.log('🔄 محاولة الاستمرار...');
    });
    
    console.log('\n🎉 === النظام يعمل بنجاح ===');
    console.log('📱 المزامنة المستمرة للطلبات كل 3 دقائق');
    console.log('🔄 تحديث تلقائي للحالات من الوسيط');
    console.log('📊 مراقبة مستمرة وإحصائيات دورية');
    console.log('⏹️ اضغط Ctrl+C للإيقاف');
    console.log('🎉'.repeat(50));
    
    // رسالة ترحيب
    console.log('\n🌟 === مرحباً بك في نظام المزامنة الذكي ===');
    console.log('🔗 متصل مع: API الوسيط الرسمي');
    console.log('📊 يراقب: جميع طلبات التاجر');
    console.log('🔄 يحدث: الحالات تلقائياً');
    console.log('⚡ السرعة: كل 3 دقائق');
    console.log('🎯 الهدف: مزامنة مثالية 100%');
    
  } catch (error) {
    console.error('\n❌ === فشل تشغيل النظام ===');
    console.error(`📝 الخطأ: ${error.message}`);
    console.error('🔄 محاولة إعادة التشغيل خلال 30 ثانية...');
    
    // إعادة المحاولة بعد 30 ثانية
    setTimeout(() => {
      console.log('🔄 إعادة تشغيل النظام...');
      startWaseetSyncDaemon();
    }, 30000);
  }
}

// تشغيل النظام
startWaseetSyncDaemon();
