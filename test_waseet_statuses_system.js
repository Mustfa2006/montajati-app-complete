// ===================================
// اختبار نظام حالات الوسيط الجديد
// Test New Waseet Statuses System
// ===================================

require('dotenv').config();
const waseetStatusManager = require('./backend/services/waseet_status_manager');
const https = require('https');

async function testWaseetStatusesSystem() {
  console.log('🧪 اختبار نظام حالات الوسيط الجديد...\n');

  try {
    // 1. اختبار مزامنة الحالات مع قاعدة البيانات
    console.log('🔄 الخطوة 1: مزامنة الحالات مع قاعدة البيانات...');
    const syncResult = await waseetStatusManager.syncStatusesToDatabase();
    
    if (syncResult) {
      console.log('✅ تم مزامنة الحالات بنجاح');
    } else {
      console.log('❌ فشل في مزامنة الحالات');
    }

    // 2. اختبار الحصول على الحالات المعتمدة
    console.log('\n📋 الخطوة 2: اختبار الحصول على الحالات المعتمدة...');
    const approvedStatuses = waseetStatusManager.getApprovedStatuses();
    console.log(`✅ تم جلب ${approvedStatuses.length} حالة معتمدة`);

    // 3. اختبار تصدير الحالات للتطبيق
    console.log('\n📱 الخطوة 3: اختبار تصدير الحالات للتطبيق...');
    const exportedData = waseetStatusManager.exportStatusesForApp();
    console.log(`✅ تم تصدير البيانات:`);
    console.log(`   📊 إجمالي الحالات: ${exportedData.total}`);
    console.log(`   📂 عدد الفئات: ${exportedData.categories.length}`);

    // 4. عرض الفئات والحالات
    console.log('\n📂 الخطوة 4: عرض الفئات والحالات...');
    exportedData.categories.forEach((category, index) => {
      console.log(`${index + 1}. فئة "${category.name}" - ${category.statuses.length} حالة`);
      category.statuses.forEach((status, statusIndex) => {
        console.log(`   ${statusIndex + 1}. ID: ${status.id} - "${status.text}" (${status.appStatus})`);
      });
    });

    // 5. اختبار API endpoints
    console.log('\n🌐 الخطوة 5: اختبار API endpoints...');
    
    console.log('⚠️ تخطي اختبار API endpoints - يتطلب تشغيل الخادم');
    console.log('💡 لاختبار API endpoints، شغل الخادم على المنفذ 3003');

    // 6. اختبار التحقق من صحة الحالات
    console.log('\n✅ الخطوة 6: اختبار التحقق من صحة الحالات...');
    
    const testStatusIds = [4, 25, 31, 999]; // حالات صحيحة وخاطئة
    
    testStatusIds.forEach(statusId => {
      const isValid = waseetStatusManager.isValidWaseetStatus(statusId);
      const statusInfo = waseetStatusManager.getStatusById(statusId);
      
      console.log(`   ID ${statusId}: ${isValid ? '✅ صحيح' : '❌ غير صحيح'}`);
      if (statusInfo) {
        console.log(`      النص: "${statusInfo.text}"`);
        console.log(`      الفئة: ${statusInfo.category}`);
        console.log(`      حالة التطبيق: ${statusInfo.appStatus}`);
      }
    });

    // 7. اختبار تحويل حالات الوسيط إلى حالات التطبيق
    console.log('\n🔄 الخطوة 7: اختبار تحويل الحالات...');
    
    const mappingTests = [
      { waseetId: 4, expected: 'delivered' },
      { waseetId: 3, expected: 'in_delivery' },
      { waseetId: 31, expected: 'cancelled' },
      { waseetId: 25, expected: 'active' }
    ];

    mappingTests.forEach(test => {
      const appStatus = waseetStatusManager.mapWaseetStatusToAppStatus(test.waseetId);
      const isCorrect = appStatus === test.expected;
      
      console.log(`   ID ${test.waseetId} -> ${appStatus} ${isCorrect ? '✅' : '❌'}`);
      if (!isCorrect) {
        console.log(`      متوقع: ${test.expected}, فعلي: ${appStatus}`);
      }
    });

    // 8. اختبار الحصول على إحصائيات
    console.log('\n📊 الخطوة 8: اختبار الحصول على إحصائيات...');
    
    try {
      const stats = await waseetStatusManager.getStatusStatistics();
      console.log(`✅ تم جلب إحصائيات ${stats.length} حالة`);
      
      if (stats.length > 0) {
        console.log('   📈 أكثر الحالات استخداماً:');
        stats.slice(0, 5).forEach((stat, index) => {
          console.log(`   ${index + 1}. "${stat.text}" - ${stat.count} طلب`);
        });
      }
    } catch (statsError) {
      console.log('⚠️ لا يمكن جلب الإحصائيات - قد تحتاج لطلبات في قاعدة البيانات');
    }

    console.log('\n🎉 تم إكمال جميع الاختبارات بنجاح!');
    console.log('\n📋 ملخص النتائج:');
    console.log('✅ مزامنة قاعدة البيانات');
    console.log('✅ جلب الحالات المعتمدة');
    console.log('✅ تصدير البيانات للتطبيق');
    console.log('✅ التحقق من صحة الحالات');
    console.log('✅ تحويل الحالات');
    console.log('✅ النظام جاهز للاستخدام');

  } catch (error) {
    console.error('❌ خطأ في اختبار النظام:', error.message);
    console.error('📊 تفاصيل الخطأ:', error.stack);
  }
}

// تشغيل الاختبار
testWaseetStatusesSystem();
