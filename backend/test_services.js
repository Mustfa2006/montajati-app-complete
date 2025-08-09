// ===================================
// اختبار الخدمات الأساسية
// Test Core Services
// ===================================

require('dotenv').config();

async function testServices() {
  console.log('🧪 بدء اختبار الخدمات الأساسية...\n');

  try {
    // اختبار OfficialNotificationManager
    console.log('1️⃣ اختبار OfficialNotificationManager...');
    const OfficialNotificationManager = require('./services/official_notification_manager');
    const notificationManager = new OfficialNotificationManager();
    
    // التحقق من أن EventEmitter يعمل
    notificationManager.on('error', (error) => {
      console.log('   ✅ Event Emitter يعمل بشكل صحيح');
    });
    
    console.log('   ✅ OfficialNotificationManager تم تحميله بنجاح');

    // اختبار AdvancedSyncManager
    console.log('2️⃣ اختبار AdvancedSyncManager...');
    const AdvancedSyncManager = require('./services/advanced_sync_manager');
    const syncManager = new AdvancedSyncManager();
    console.log('   ✅ AdvancedSyncManager تم تحميله بنجاح');

    // اختبار SystemMonitor
    console.log('3️⃣ اختبار SystemMonitor...');
    const SystemMonitor = require('./services/system_monitor');
    const systemMonitor = new SystemMonitor();
    console.log('   ✅ SystemMonitor تم تحميله بنجاح');

    // اختبار FCM Tokens Route
    console.log('4️⃣ اختبار FCM Tokens Route...');
    const fcmTokensRoute = require('./routes/fcm_tokens');
    console.log('   ✅ FCM Tokens Route تم تحميله بنجاح');

    // اختبار متغيرات البيئة
    console.log('5️⃣ اختبار متغيرات البيئة...');
    const requiredVars = ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY', 'FIREBASE_SERVICE_ACCOUNT'];
    let allPresent = true;

    for (const varName of requiredVars) {
      if (process.env[varName]) {
        console.log(`   ✅ ${varName}: موجود`);
      } else {
        console.log(`   ❌ ${varName}: مفقود`);
        allPresent = false;
      }
    }

    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      try {
        const parsed = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
        if (parsed.project_id && parsed.private_key && parsed.client_email) {
          console.log('   ✅ FIREBASE_SERVICE_ACCOUNT: JSON صالح');
        } else {
          console.log('   ❌ FIREBASE_SERVICE_ACCOUNT: JSON ناقص');
          allPresent = false;
        }
      } catch (e) {
        console.log('   ❌ FIREBASE_SERVICE_ACCOUNT: JSON غير صالح');
        allPresent = false;
      }
    }

    console.log('\n' + '='.repeat(50));
    
    if (allPresent) {
      console.log('🎉 جميع الاختبارات نجحت! الخادم جاهز للتشغيل');
      process.exit(0);
    } else {
      console.log('❌ بعض الاختبارات فشلت! يرجى مراجعة الأخطاء أعلاه');
      process.exit(1);
    }

  } catch (error) {
    console.error('❌ خطأ في اختبار الخدمات:', error.message);
    console.error('Stack:', error.stack);
    process.exit(1);
  }
}

// تشغيل الاختبار
testServices();
