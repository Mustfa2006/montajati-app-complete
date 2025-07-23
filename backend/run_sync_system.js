// ===================================
// تشغيل نظام المزامنة الذكي المبسط
// Simple Smart Sync System Runner
// ===================================

const SmartSyncService = require('./sync/smart_sync_service');
require('dotenv').config();

async function main() {
  try {
    console.log('🚀 بدء تشغيل نظام المزامنة الذكي...\n');
    
    // إنشاء خدمة المزامنة الذكية
    const syncService = new SmartSyncService();
    
    // بدء المزامنة التلقائية
    syncService.startSmartAutoSync();
    
    console.log('\n' + '🎉'.repeat(50));
    console.log('نظام المزامنة الذكي يعمل بنجاح!');
    console.log('🎉'.repeat(50));
    console.log('⏰ المزامنة كل 5 دقائق');
    console.log('📊 التحديث الفوري للحالات');
    console.log('🧠 معالجة ذكية للأخطاء');
    console.log('🎉'.repeat(50));
    
    // عرض الإحصائيات كل دقيقة
    setInterval(() => {
      const stats = syncService.getDetailedStats();
      console.log('\n📊 إحصائيات النظام:');
      console.log(`🔄 دورات المزامنة: ${stats.sync_service.currentBatch}`);
      console.log(`✅ نجح: ${stats.sync_service.totalSynced}`);
      console.log(`❌ فشل: ${stats.sync_service.totalErrors}`);
      console.log(`📈 معدل النجاح: ${stats.sync_service.successRate.toFixed(1)}%`);
      console.log(`⚡ تحديثات فورية: ${stats.instant_updater.totalUpdates}`);
      console.log(`⏱️ آخر مزامنة: ${stats.sync_service.lastSyncTime || 'لم تبدأ بعد'}`);
    }, 60000); // كل دقيقة
    
    // معالجة إشارات النظام
    process.on('SIGINT', () => {
      console.log('\n🛑 تم استلام إشارة الإيقاف...');
      console.log('🔄 إيقاف النظام بأمان...');
      process.exit(0);
    });

    process.on('SIGTERM', () => {
      console.log('\n🛑 تم استلام إشارة الإنهاء...');
      console.log('🔄 إيقاف النظام بأمان...');
      process.exit(0);
    });

  } catch (error) {
    console.error('❌ فشل في بدء النظام:', error.message);
    process.exit(1);
  }
}

// تشغيل النظام
main();
