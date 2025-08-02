// ===================================
// تشغيل اختبارات التلغرام
// Run Telegram Tests
// ===================================

const TelegramIssueFixer = require('./fix_telegram_issues');
const { testTelegramAlerts } = require('./test_telegram_alerts');

async function runAllTelegramTests() {
  console.log('🚀 === بدء اختبارات التلغرام الشاملة ===\n');

  try {
    // 1. فحص الإعدادات والاتصال
    console.log('🔧 المرحلة 1: فحص الإعدادات والاتصال');
    const fixer = new TelegramIssueFixer();
    const fixerResults = await fixer.runAllTests();

    // 2. اختبار النظام الكامل إذا كانت الإعدادات صحيحة
    if (fixerResults.settings && fixerResults.connection) {
      console.log('\n🧪 المرحلة 2: اختبار النظام الكامل');
      await testTelegramAlerts();
    } else {
      console.log('\n⚠️ تم تخطي اختبار النظام الكامل بسبب مشاكل في الإعدادات');
    }

    console.log('\n✅ === انتهت جميع اختبارات التلغرام ===');

  } catch (error) {
    console.error('❌ خطأ في تشغيل اختبارات التلغرام:', error.message);
  }
}

// تشغيل الاختبارات
if (require.main === module) {
  runAllTelegramTests()
    .then(() => {
      console.log('\n🎯 تم الانتهاء من جميع الاختبارات');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ خطأ في تشغيل الاختبارات:', error);
      process.exit(1);
    });
}

module.exports = { runAllTelegramTests };
