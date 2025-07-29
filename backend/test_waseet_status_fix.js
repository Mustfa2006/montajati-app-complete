/**
 * اختبار إصلاح تحويل حالة "ارسال الى مخزن الارجاعات"
 * Test Fix for "ارسال الى مخزن الارجاعات" Status Mapping
 */

const IntegratedWaseetSync = require('./services/integrated_waseet_sync');

async function testWaseetStatusFix() {
  console.log('🔧 اختبار إصلاح تحويل حالة الوسيط...\n');

  try {
    // إنشاء مثيل من خدمة المزامنة
    const syncService = new IntegratedWaseetSync();

    // الحالة المشكلة
    const problemCase = {
      waseetStatusId: 23,
      waseetStatusText: 'ارسال الى مخزن الارجاعات',
      expectedAppStatus: 'الغاء الطلب'
    };

    console.log('🎯 === اختبار الحالة المشكلة ===');
    console.log(`📥 المدخل من الوسيط:`);
    console.log(`   - ID: ${problemCase.waseetStatusId}`);
    console.log(`   - النص: "${problemCase.waseetStatusText}"`);
    console.log(`🎯 المتوقع في التطبيق: "${problemCase.expectedAppStatus}"`);

    // تطبيق التحويل
    const result = syncService.mapWaseetStatusToApp(
      problemCase.waseetStatusId,
      problemCase.waseetStatusText
    );

    console.log(`📤 النتيجة الفعلية: "${result}"`);

    if (result === problemCase.expectedAppStatus) {
      console.log('✅ تم إصلاح المشكلة بنجاح!');
      console.log('🎉 الآن ستظهر الحالة في التطبيق كـ "الغاء الطلب" بدلاً من "الرقم غير معرف"');
    } else {
      console.log('❌ المشكلة لا تزال موجودة!');
      console.log(`   متوقع: "${problemCase.expectedAppStatus}"`);
      console.log(`   فعلي: "${result}"`);
    }

    // اختبار حالات إضافية للتأكد
    console.log('\n🔍 === اختبار حالات إضافية ===');
    
    const additionalTests = [
      { id: 31, text: 'الغاء الطلب', expected: 'الغاء الطلب' },
      { id: 11, text: 'الرقم غير معرف', expected: 'الرقم غير معرف' },
      { id: 6, text: 'مغلق', expected: 'مغلق' },
      { id: 7, text: 'مغلق بعد الاتفاق', expected: 'مغلق بعد الاتفاق' }
    ];

    let passedCount = 0;
    let totalCount = additionalTests.length;

    for (const test of additionalTests) {
      const testResult = syncService.mapWaseetStatusToApp(test.id, test.text);
      const passed = testResult === test.expected;
      
      console.log(`${passed ? '✅' : '❌'} ID=${test.id}, Text="${test.text}" → "${testResult}"`);
      
      if (passed) passedCount++;
    }

    console.log(`\n📊 نتائج الاختبارات الإضافية: ${passedCount}/${totalCount} نجحت`);

    // محاكاة تحديث طلب من الوسيط
    console.log('\n🔄 === محاكاة تحديث طلب من الوسيط ===');
    console.log('محاكاة استلام البيانات التالية من الوسيط:');
    console.log(`{`);
    console.log(`  "id": "12345",`);
    console.log(`  "status_id": "23",`);
    console.log(`  "status": "ارسال الى مخزن الارجاعات"`);
    console.log(`}`);

    const simulatedResult = syncService.mapWaseetStatusToApp(23, 'ارسال الى مخزن الارجاعات');
    console.log(`\n📱 ستظهر في التطبيق كـ: "${simulatedResult}"`);

    if (simulatedResult === 'الغاء الطلب') {
      console.log('✅ المحاكاة نجحت! لن تظهر "الرقم غير معرف" بعد الآن');
    } else {
      console.log('❌ المحاكاة فشلت! ستظهر حالة خاطئة');
    }

    return result === problemCase.expectedAppStatus;

  } catch (error) {
    console.error('❌ خطأ في اختبار إصلاح الحالة:', error.message);
    console.error('📋 تفاصيل الخطأ:', error.stack);
    return false;
  }
}

// دالة لاختبار تحويل حالة واحدة
function testSingleMapping(statusId, statusText) {
  console.log(`🧪 اختبار تحويل: ID=${statusId}, Text="${statusText}"`);
  
  try {
    const syncService = new IntegratedWaseetSync();
    const result = syncService.mapWaseetStatusToApp(statusId, statusText);
    
    console.log(`📤 النتيجة: "${result}"`);
    return result;
  } catch (error) {
    console.error(`❌ خطأ: ${error.message}`);
    return null;
  }
}

// تشغيل الاختبار
if (require.main === module) {
  const args = process.argv.slice(2);
  
  if (args.length >= 2 && args[0] === 'single') {
    // اختبار حالة واحدة
    const statusId = parseInt(args[1]);
    const statusText = args[2] || '';
    
    testSingleMapping(statusId, statusText);
  } else {
    // اختبار إصلاح المشكلة
    testWaseetStatusFix()
      .then((success) => {
        if (success) {
          console.log('\n🎉 تم إصلاح مشكلة تحويل الحالة بنجاح!');
          console.log('💡 الآن عندما يأتي من الوسيط:');
          console.log('   - ID: 23');
          console.log('   - النص: "ارسال الى مخزن الارجاعات"');
          console.log('   سيظهر في التطبيق: "الغاء الطلب"');
          process.exit(0);
        } else {
          console.log('\n❌ فشل في إصلاح مشكلة تحويل الحالة');
          process.exit(1);
        }
      })
      .catch((error) => {
        console.error('\n❌ خطأ في اختبار الإصلاح:', error.message);
        process.exit(1);
      });
  }
}

module.exports = { testWaseetStatusFix, testSingleMapping };
