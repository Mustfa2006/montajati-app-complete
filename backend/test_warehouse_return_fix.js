// ===================================
// اختبار إصلاح حالة "ارسال الى مخزن الارجاعات"
// ===================================

require('dotenv').config({ path: '../.env' });
const statusMapper = require('./sync/status_mapper');

async function testWarehouseReturnFix() {
  console.log('🧪 اختبار إصلاح حالة "ارسال الى مخزن الارجاعات"...');
  console.log('=====================================\n');

  // 1. اختبار تحويل حالة "ارسال الى مخزن الارجاعات" إلى "الغاء الطلب"
  console.log('1️⃣ اختبار تحويل حالة "ارسال الى مخزن الارجاعات":');
  
  const warehouseReturnTests = [
    // ID 23 من الوسيط
    { 
      input: '23', 
      expected: 'cancelled', 
      description: 'ID 23 من الوسيط → cancelled (الغاء الطلب)' 
    },
    
    // النصوص العربية المختلفة
    { 
      input: 'ارسال الى مخزن الارجاعات', 
      expected: 'cancelled', 
      description: 'النص الكامل → cancelled (الغاء الطلب)' 
    },
    { 
      input: 'ارسال الى مخزن الارجاع', 
      expected: 'cancelled', 
      description: 'النص المختصر → cancelled (الغاء الطلب)' 
    },
    { 
      input: 'مخزن الارجاعات', 
      expected: 'cancelled', 
      description: 'النص المختصر أكثر → cancelled (الغاء الطلب)' 
    },
    { 
      input: 'مخزن الارجاع', 
      expected: 'cancelled', 
      description: 'النص المختصر أكثر → cancelled (الغاء الطلب)' 
    }
  ];

  let passedTests = 0;
  let failedTests = 0;

  for (const test of warehouseReturnTests) {
    try {
      const result = statusMapper.mapWaseetToLocal(test.input);
      
      if (result === test.expected) {
        console.log(`   ✅ ${test.description}`);
        console.log(`      📥 المدخل: "${test.input}"`);
        console.log(`      📤 المخرج: "${result}"`);
        console.log(`      💡 المعنى: سيظهر في التطبيق كـ "الغاء الطلب"`);
        passedTests++;
      } else {
        console.log(`   ❌ ${test.description}`);
        console.log(`      📥 المدخل: "${test.input}"`);
        console.log(`      📤 المخرج الفعلي: "${result}"`);
        console.log(`      📤 المخرج المتوقع: "${test.expected}"`);
        failedTests++;
      }
      console.log('');
    } catch (error) {
      console.log(`   💥 خطأ في ${test.description}: ${error.message}`);
      failedTests++;
    }
  }

  // 2. اختبار أن الحالة النهائية تعمل بشكل صحيح
  console.log('2️⃣ اختبار الحالات النهائية:');
  
  const finalStatusTests = [
    { status: 'الغاء الطلب', expected: true, description: 'الغاء الطلب (نهائية)' },
    { status: 'cancelled', expected: true, description: 'cancelled (نهائية)' },
    { status: 'تم التسليم للزبون', expected: true, description: 'تم التسليم للزبون (نهائية)' },
    { status: 'delivered', expected: true, description: 'delivered (نهائية)' },
    { status: 'active', expected: false, description: 'active (غير نهائية)' },
    { status: 'in_delivery', expected: false, description: 'in_delivery (غير نهائية)' }
  ];

  let finalPassedTests = 0;
  let finalFailedTests = 0;

  for (const test of finalStatusTests) {
    try {
      const result = statusMapper.isFinalStatus(test.status);
      
      if (result === test.expected) {
        console.log(`   ✅ ${test.description}: ${result ? '🔒 نهائية' : '🔄 قابلة للتحديث'}`);
        finalPassedTests++;
      } else {
        console.log(`   ❌ ${test.description}: ${result ? '🔒 نهائية' : '🔄 قابلة للتحديث'} (متوقع: ${test.expected ? '🔒 نهائية' : '🔄 قابلة للتحديث'})`);
        finalFailedTests++;
      }
    } catch (error) {
      console.log(`   💥 خطأ في ${test.description}: ${error.message}`);
      finalFailedTests++;
    }
  }

  // 3. محاكاة السيناريو الكامل
  console.log('\n3️⃣ محاكاة السيناريو الكامل:');
  
  console.log('   📋 السيناريو:');
  console.log('   1. الوسيط يرسل: statusId=23, statusText="ارسال الى مخزن الارجاعات"');
  console.log('   2. النظام يحول: "23" → "cancelled"');
  console.log('   3. التطبيق يعرض: "الغاء الطلب"');
  console.log('   4. الحالة تصبح نهائية ولا تتغير مرة أخرى');
  
  // محاكاة التحويل
  const waseetStatusId = '23';
  const waseetStatusText = 'ارسال الى مخزن الارجاعات';
  
  console.log('\n   🔄 تطبيق السيناريو:');
  console.log(`   📥 من الوسيط: ID="${waseetStatusId}", Text="${waseetStatusText}"`);
  
  // الخطوة 1: تحويل ID إلى حالة محلية
  const localStatus = statusMapper.mapWaseetToLocal(waseetStatusId);
  console.log(`   🔄 التحويل: "${waseetStatusId}" → "${localStatus}"`);
  
  // الخطوة 2: فحص إذا كانت نهائية
  const isFinal = statusMapper.isFinalStatus(localStatus);
  console.log(`   🔒 الحالة النهائية: ${isFinal ? 'نعم' : 'لا'}`);
  
  // الخطوة 3: النتيجة في التطبيق
  const appDisplayStatus = localStatus === 'cancelled' ? 'الغاء الطلب' : localStatus;
  console.log(`   📱 في التطبيق: "${appDisplayStatus}"`);
  
  if (localStatus === 'cancelled' && isFinal) {
    console.log('   ✅ السيناريو نجح! الحالة ستظهر كـ "الغاء الطلب" ولن تتغير مرة أخرى');
  } else {
    console.log('   ❌ السيناريو فشل! هناك مشكلة في التحويل');
  }

  // النتائج النهائية
  console.log('\n=====================================');
  console.log('🏁 نتائج اختبار إصلاح "ارسال الى مخزن الارجاعات"');
  console.log('=====================================');
  
  const totalTests = passedTests + failedTests;
  const totalFinalTests = finalPassedTests + finalFailedTests;
  
  console.log(`\n📊 اختبارات التحويل:`);
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
    console.log('\n🎉 جميع الاختبارات نجحت!');
    console.log('✅ حالة "ارسال الى مخزن الارجاعات" تتحول بنجاح إلى "الغاء الطلب"');
    console.log('✅ الحالة تصبح نهائية ولا تتغير مرة أخرى');
    console.log('✅ المستخدم سيرى "الغاء الطلب" في التطبيق');
  } else {
    console.log('\n⚠️ بعض الاختبارات فشلت. يرجى مراجعة الأخطاء أعلاه.');
  }
  
  console.log('\n💡 الإصلاح المُطبق:');
  console.log('🔄 الوسيط: "ارسال الى مخزن الارجاعات" (ID: 23)');
  console.log('⬇️ يتحول إلى');
  console.log('📱 التطبيق: "الغاء الطلب" (cancelled)');
  console.log('🔒 حالة نهائية: لا تتغير مرة أخرى');
}

// تشغيل الاختبار
testWarehouseReturnFix().catch(error => {
  console.error('❌ خطأ في تشغيل الاختبار:', error);
  process.exit(1);
});
