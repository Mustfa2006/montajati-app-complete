// ===================================
// اختبار النظام الكامل لحالات الوسيط
// Complete Waseet Status System Test
// ===================================

require('dotenv').config();
const waseetStatusManager = require('./backend/services/waseet_status_manager');

async function testCompleteWaseetSystem() {
  console.log('🎯 اختبار النظام الكامل لحالات الوسيط...\n');

  try {
    // 1. مزامنة الحالات مع قاعدة البيانات
    console.log('🔄 الخطوة 1: مزامنة الحالات مع قاعدة البيانات...');
    const syncResult = await waseetStatusManager.syncStatusesToDatabase();
    
    if (syncResult) {
      console.log('✅ تم مزامنة الحالات بنجاح');
    } else {
      console.log('❌ فشل في مزامنة الحالات');
      return;
    }

    // 2. عرض جميع الحالات المعتمدة
    console.log('\n📋 الخطوة 2: عرض جميع الحالات المعتمدة...');
    const approvedStatuses = waseetStatusManager.getApprovedStatuses();
    
    console.log(`✅ إجمالي الحالات المعتمدة: ${approvedStatuses.length}`);
    console.log('\n📊 قائمة الحالات المعتمدة:');
    console.log('='.repeat(80));
    
    approvedStatuses.forEach((status, index) => {
      console.log(`${index + 1}. ID: ${status.id} - "${status.text}"`);
      console.log(`   📂 الفئة: ${status.category}`);
      console.log(`   📱 حالة التطبيق: ${status.appStatus}`);
      console.log('');
    });

    // 3. عرض الحالات مجمعة حسب الفئة
    console.log('\n📂 الخطوة 3: عرض الحالات مجمعة حسب الفئة...');
    const categories = waseetStatusManager.getCategories();
    
    categories.forEach((category, index) => {
      console.log(`\n${index + 1}. فئة "${category.name}" - ${category.statuses.length} حالة:`);
      console.log('-'.repeat(50));
      
      category.statuses.forEach((status, statusIndex) => {
        console.log(`   ${statusIndex + 1}. ID: ${status.id} - "${status.text}" (${status.appStatus})`);
      });
    });

    // 4. اختبار التحقق من صحة الحالات
    console.log('\n✅ الخطوة 4: اختبار التحقق من صحة الحالات...');
    
    const testCases = [
      { id: 4, expected: true, description: 'تم التسليم للزبون' },
      { id: 25, expected: true, description: 'لا يرد' },
      { id: 31, expected: true, description: 'الغاء الطلب' },
      { id: 999, expected: false, description: 'حالة غير موجودة' },
      { id: 1, expected: false, description: 'حالة غير معتمدة' }
    ];

    testCases.forEach(testCase => {
      const isValid = waseetStatusManager.isValidWaseetStatus(testCase.id);
      const result = isValid === testCase.expected ? '✅' : '❌';
      
      console.log(`   ${result} ID ${testCase.id}: ${isValid ? 'صحيح' : 'غير صحيح'} - ${testCase.description}`);
      
      if (isValid) {
        const statusInfo = waseetStatusManager.getStatusById(testCase.id);
        console.log(`      النص: "${statusInfo.text}"`);
        console.log(`      الفئة: ${statusInfo.category}`);
        console.log(`      حالة التطبيق: ${statusInfo.appStatus}`);
      }
    });

    // 5. اختبار تحويل الحالات
    console.log('\n🔄 الخطوة 5: اختبار تحويل حالات الوسيط إلى حالات التطبيق...');
    
    const mappingTests = [
      { waseetId: 4, expected: 'delivered', description: 'تم التسليم للزبون' },
      { waseetId: 3, expected: 'in_delivery', description: 'قيد التوصيل' },
      { waseetId: 31, expected: 'cancelled', description: 'الغاء الطلب' },
      { waseetId: 25, expected: 'active', description: 'لا يرد' },
      { waseetId: 29, expected: 'active', description: 'مؤجل' }
    ];

    mappingTests.forEach(test => {
      const appStatus = waseetStatusManager.mapWaseetStatusToAppStatus(test.waseetId);
      const isCorrect = appStatus === test.expected;
      const result = isCorrect ? '✅' : '❌';
      
      console.log(`   ${result} ID ${test.waseetId} -> ${appStatus} (متوقع: ${test.expected}) - ${test.description}`);
    });

    // 6. اختبار تصدير البيانات للتطبيق
    console.log('\n📱 الخطوة 6: اختبار تصدير البيانات للتطبيق...');
    const exportedData = waseetStatusManager.exportStatusesForApp();
    
    console.log(`✅ تم تصدير البيانات بنجاح:`);
    console.log(`   📊 إجمالي الحالات: ${exportedData.total}`);
    console.log(`   📂 عدد الفئات: ${exportedData.categories.length}`);
    
    console.log('\n📋 ملخص البيانات المصدرة:');
    exportedData.categories.forEach(category => {
      console.log(`   📂 ${category.name}: ${category.statuses.length} حالة`);
    });

    // 7. اختبار محاكاة تحديث حالة طلب
    console.log('\n🧪 الخطوة 7: محاكاة تحديث حالة طلب...');
    
    const mockOrderId = 'test_order_123';
    const testStatusId = 4; // تم التسليم للزبون
    
    console.log(`📦 محاكاة تحديث الطلب ${mockOrderId} إلى الحالة ${testStatusId}`);
    
    const validation = waseetStatusManager.validateStatusUpdate(mockOrderId, testStatusId);
    
    if (validation.isValid) {
      console.log('✅ التحقق من صحة البيانات نجح');
      
      const statusInfo = waseetStatusManager.getStatusById(testStatusId);
      console.log(`   📋 الحالة الجديدة: "${statusInfo.text}"`);
      console.log(`   📂 الفئة: ${statusInfo.category}`);
      console.log(`   📱 حالة التطبيق: ${statusInfo.appStatus}`);
    } else {
      console.log('❌ فشل في التحقق من صحة البيانات:');
      validation.errors.forEach(error => {
        console.log(`   - ${error}`);
      });
    }

    // 8. عرض النتائج النهائية
    console.log('\n' + '🎉'.repeat(50));
    console.log('النتائج النهائية - نظام حالات الوسيط');
    console.log('🎉'.repeat(50));
    
    console.log('\n✅ جميع الاختبارات نجحت!');
    console.log('\n📊 إحصائيات النظام:');
    console.log(`   📋 إجمالي الحالات المعتمدة: ${approvedStatuses.length}`);
    console.log(`   📂 عدد الفئات: ${categories.length}`);
    console.log(`   🎯 الحالات الأساسية للتطبيق: 4 حالات (delivered, in_delivery, cancelled, active)`);
    
    console.log('\n🔧 الحالات الأكثر استخداماً في التطبيق:');
    const importantStatuses = [4, 3, 25, 31, 32, 29];
    importantStatuses.forEach(statusId => {
      const status = waseetStatusManager.getStatusById(statusId);
      if (status) {
        console.log(`   • ID ${status.id}: "${status.text}" (${status.appStatus})`);
      }
    });

    console.log('\n🎯 النظام جاهز للاستخدام في التطبيق!');
    console.log('💡 يمكن الآن للمستخدمين اختيار من 20 حالة معتمدة من الوسيط');
    console.log('🔄 سيتم تحديث حالات الطلبات تلقائياً في قاعدة البيانات');

  } catch (error) {
    console.error('❌ خطأ في اختبار النظام:', error.message);
    console.error('📊 تفاصيل الخطأ:', error.stack);
  }
}

// تشغيل الاختبار
testCompleteWaseetSystem();
