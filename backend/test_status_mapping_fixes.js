// ===================================
// اختبار شامل لإصلاحات خريطة تحويل الحالات
// ===================================

require('dotenv').config({ path: '../.env' });
const statusMapper = require('./sync/status_mapper');

async function testStatusMappingFixes() {
  console.log('🧪 اختبار شامل لإصلاحات خريطة تحويل الحالات...');
  console.log('=====================================\n');

  // 1. اختبار الحالات المُصلحة
  console.log('1️⃣ اختبار الحالات المُصلحة:');
  
  const testCases = [
    // الحالة المفقودة الأساسية
    { input: '4', expected: 'delivered', description: 'ID 4 من الوسيط' },
    { input: 'تم التسليم للزبون', expected: 'delivered', description: 'النص العربي الكامل' },
    
    // حالات الإرجاع
    { input: '23', expected: 'cancelled', description: 'ID 23 - ارسال الى مخزن الارجاعات' },
    { input: 'ارسال الى مخزن الارجاعات', expected: 'cancelled', description: 'النص الكامل' },
    { input: 'ارسال الى مخزن الارجاع', expected: 'cancelled', description: 'النص المختصر' },
    { input: 'مخزن الارجاعات', expected: 'cancelled', description: 'النص المختصر أكثر' },
    { input: 'مخزن الارجاع', expected: 'cancelled', description: 'النص المختصر أكثر' },
    
    // حالات أخرى
    { input: '17', expected: 'cancelled', description: 'ID 17 - تم الارجاع الى التاجر' },
    { input: 'تم الارجاع الى التاجر', expected: 'cancelled', description: 'النص الكامل' },
    
    // حالات موجودة مسبقاً (للتأكد من عدم كسرها)
    { input: '3', expected: 'in_delivery', description: 'ID 3 - قيد التوصيل' },
    { input: 'قيد التوصيل الى الزبون (في عهدة المندوب)', expected: 'in_delivery', description: 'النص الكامل' },
    { input: '1', expected: 'active', description: 'ID 1 - فعال' },
    { input: 'فعال', expected: 'active', description: 'النص العربي' }
  ];

  let passedTests = 0;
  let failedTests = 0;

  for (const testCase of testCases) {
    try {
      const result = statusMapper.mapWaseetToLocal(testCase.input);
      
      if (result === testCase.expected) {
        console.log(`   ✅ ${testCase.description}: "${testCase.input}" → "${result}"`);
        passedTests++;
      } else {
        console.log(`   ❌ ${testCase.description}: "${testCase.input}" → "${result}" (متوقع: "${testCase.expected}")`);
        failedTests++;
      }
    } catch (error) {
      console.log(`   💥 خطأ في ${testCase.description}: ${error.message}`);
      failedTests++;
    }
  }

  // 2. اختبار الحالات النهائية
  console.log('\n2️⃣ اختبار الحالات النهائية:');
  
  const finalStatusTests = [
    // الحالات المحلية
    { status: 'delivered', expected: true, description: 'delivered (محلية)' },
    { status: 'cancelled', expected: true, description: 'cancelled (محلية)' },
    { status: 'active', expected: false, description: 'active (غير نهائية)' },
    { status: 'in_delivery', expected: false, description: 'in_delivery (غير نهائية)' },
    
    // النصوص العربية
    { status: 'تم التسليم للزبون', expected: true, description: 'تم التسليم للزبون' },
    { status: 'ارسال الى مخزن الارجاعات', expected: true, description: 'ارسال الى مخزن الارجاعات' },
    { status: 'ارسال الى مخزن الارجاع', expected: true, description: 'ارسال الى مخزن الارجاع' },
    { status: 'مخزن الارجاعات', expected: true, description: 'مخزن الارجاعات' },
    { status: 'مخزن الارجاع', expected: true, description: 'مخزن الارجاع' },
    { status: 'تم الارجاع الى التاجر', expected: true, description: 'تم الارجاع الى التاجر' },
    { status: 'الغاء الطلب', expected: true, description: 'الغاء الطلب' },
    { status: 'رفض الطلب', expected: true, description: 'رفض الطلب' },
    { status: 'مستلم مسبقا', expected: true, description: 'مستلم مسبقا' },
    
    // حالات غير نهائية
    { status: 'فعال', expected: false, description: 'فعال (غير نهائية)' },
    { status: 'قيد التوصيل الى الزبون (في عهدة المندوب)', expected: false, description: 'قيد التوصيل (غير نهائية)' }
  ];

  let finalPassedTests = 0;
  let finalFailedTests = 0;

  for (const test of finalStatusTests) {
    try {
      const result = statusMapper.isFinalStatus(test.status);
      
      if (result === test.expected) {
        console.log(`   ✅ ${test.description}: ${result ? 'نهائية' : 'غير نهائية'}`);
        finalPassedTests++;
      } else {
        console.log(`   ❌ ${test.description}: ${result ? 'نهائية' : 'غير نهائية'} (متوقع: ${test.expected ? 'نهائية' : 'غير نهائية'})`);
        finalFailedTests++;
      }
    } catch (error) {
      console.log(`   💥 خطأ في ${test.description}: ${error.message}`);
      finalFailedTests++;
    }
  }

  // 3. اختبار الحصول على قائمة الحالات النهائية
  console.log('\n3️⃣ اختبار قائمة الحالات النهائية:');
  
  try {
    const finalStatuses = statusMapper.getFinalStatuses();
    console.log(`   ✅ تم الحصول على ${finalStatuses.length} حالة نهائية`);
    console.log('   📋 الحالات النهائية:');
    finalStatuses.forEach((status, index) => {
      console.log(`      ${index + 1}. "${status}"`);
    });
  } catch (error) {
    console.log(`   ❌ خطأ في الحصول على قائمة الحالات النهائية: ${error.message}`);
  }

  // 4. اختبار إحصائيات الخريطة
  console.log('\n4️⃣ اختبار إحصائيات الخريطة:');
  
  try {
    const stats = statusMapper.getMapStats();
    console.log('   ✅ إحصائيات الخريطة:');
    console.log(`      📊 حالات الوسيط: ${stats.waseet_statuses}`);
    console.log(`      📊 الحالات المحلية: ${stats.local_statuses}`);
    console.log(`      📊 الحالات المدعومة: ${stats.supported_statuses.length}`);
    console.log(`      📊 الحالات النهائية: ${stats.final_statuses.length}`);
    console.log(`      📊 حالات المزامنة: ${stats.sync_statuses.length}`);
  } catch (error) {
    console.log(`   ❌ خطأ في الحصول على إحصائيات الخريطة: ${error.message}`);
  }

  // النتائج النهائية
  console.log('\n=====================================');
  console.log('🏁 نتائج الاختبار الشامل');
  console.log('=====================================');
  
  const totalTests = passedTests + failedTests;
  const totalFinalTests = finalPassedTests + finalFailedTests;
  
  console.log(`\n📊 اختبارات تحويل الحالات:`);
  console.log(`   ✅ نجح: ${passedTests}/${totalTests}`);
  console.log(`   ❌ فشل: ${failedTests}/${totalTests}`);
  console.log(`   📈 نسبة النجاح: ${totalTests > 0 ? Math.round((passedTests / totalTests) * 100) : 0}%`);
  
  console.log(`\n📊 اختبارات الحالات النهائية:`);
  console.log(`   ✅ نجح: ${finalPassedTests}/${totalFinalTests}`);
  console.log(`   ❌ فشل: ${finalFailedTests}/${totalFinalTests}`);
  console.log(`   📈 نسبة النجاح: ${totalFinalTests > 0 ? Math.round((finalPassedTests / totalFinalTests) * 100) : 0}%`);
  
  const overallSuccess = (passedTests + finalPassedTests);
  const overallTotal = (totalTests + totalFinalTests);
  
  console.log(`\n🎯 النتيجة الإجمالية:`);
  console.log(`   ✅ إجمالي النجاح: ${overallSuccess}/${overallTotal}`);
  console.log(`   📈 نسبة النجاح الإجمالية: ${overallTotal > 0 ? Math.round((overallSuccess / overallTotal) * 100) : 0}%`);
  
  if (failedTests === 0 && finalFailedTests === 0) {
    console.log('\n🎉 جميع الاختبارات نجحت! الإصلاحات تعمل بشكل مثالي.');
  } else {
    console.log('\n⚠️ بعض الاختبارات فشلت. يرجى مراجعة الأخطاء أعلاه.');
  }
  
  console.log('\n💡 الإصلاحات المُطبقة:');
  console.log('✅ إضافة حالة "تم التسليم للزبون" (ID: 4)');
  console.log('✅ إضافة حالات "ارسال الى مخزن الارجاعات" (ID: 23)');
  console.log('✅ توحيد قائمة الحالات النهائية');
  console.log('✅ منع التحديث العشوائي للحالات النهائية');
  console.log('✅ إصلاح خرائط التحويل في جميع الملفات');
}

// تشغيل الاختبار
testStatusMappingFixes().catch(error => {
  console.error('❌ خطأ في تشغيل الاختبار:', error);
  process.exit(1);
});
