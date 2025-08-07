const IntegratedWaseetSync = require('./backend/services/integrated_waseet_sync');

/**
 * اختبار إصلاح مشكلة المزامنة مع الوسيط
 */
async function testWaseetSyncFix() {
  console.log('🧪 اختبار إصلاح مشكلة المزامنة مع الوسيط');
  console.log('='.repeat(60));

  const sync = new IntegratedWaseetSync();

  // اختبار تحويل الحالات
  console.log('\n📋 اختبار تحويل حالات الوسيط:');
  console.log('-'.repeat(40));

  const testCases = [
    { id: 4, text: 'تم التسليم للزبون', expected: 'تم التسليم للزبون' },
    { id: 3, text: 'قيد التوصيل الى الزبون (في عهدة المندوب)', expected: 'قيد التوصيل الى الزبون (في عهدة المندوب)' },
    { id: 25, text: 'لا يرد', expected: 'لا يرد' },
    { id: 27, text: 'مغلق', expected: 'مغلق' },
    { id: 31, text: 'الغاء الطلب', expected: 'الغاء الطلب' },
    { id: 17, text: 'تم الارجاع الى التاجر', expected: 'تم الارجاع الى التاجر' }
  ];

  let passedTests = 0;
  let totalTests = testCases.length;

  for (const testCase of testCases) {
    const result = sync.mapWaseetStatusToApp(testCase.id, testCase.text);
    const passed = result === testCase.expected;
    
    console.log(`${passed ? '✅' : '❌'} ID ${testCase.id}: "${testCase.text}"`);
    console.log(`   النتيجة: "${result}"`);
    console.log(`   المتوقع: "${testCase.expected}"`);
    
    if (passed) {
      passedTests++;
    } else {
      console.log(`   ❌ فشل الاختبار!`);
    }
    console.log();
  }

  // النتيجة النهائية
  console.log('📊 نتائج الاختبار:');
  console.log('-'.repeat(40));
  console.log(`✅ نجح: ${passedTests}/${totalTests}`);
  console.log(`❌ فشل: ${totalTests - passedTests}/${totalTests}`);
  console.log(`📈 معدل النجاح: ${Math.round((passedTests / totalTests) * 100)}%`);

  if (passedTests === totalTests) {
    console.log('\n🎉 جميع الاختبارات نجحت! المشكلة تم حلها.');
  } else {
    console.log('\n⚠️ بعض الاختبارات فشلت. يحتاج مراجعة إضافية.');
  }

  // اختبار الحالات الخاصة
  console.log('\n🔍 اختبار الحالات الخاصة:');
  console.log('-'.repeat(40));

  // حالة غير معروفة
  const unknownResult = sync.mapWaseetStatusToApp(999, 'حالة غير معروفة');
  console.log(`🔍 حالة غير معروفة (ID: 999): "${unknownResult}"`);

  // حالة بالنص فقط
  const textOnlyResult = sync.mapWaseetStatusToApp(null, 'تم التسليم للزبون');
  console.log(`📝 حالة بالنص فقط: "${textOnlyResult}"`);

  console.log('\n✅ انتهى الاختبار!');
}

// تشغيل الاختبار
if (require.main === module) {
  testWaseetSyncFix().catch(console.error);
}

module.exports = { testWaseetSyncFix };
