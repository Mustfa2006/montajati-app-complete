/**
 * 🔍 تشخيص مشكلة المبلغ المرسل للوسيط
 */

console.log('🔍 بدء تشخيص مشكلة المبلغ المرسل للوسيط...');
console.log('='.repeat(60));

// المشكلة المبلغة:
console.log('📋 المشكلة المبلغة:');
console.log('   💰 المبلغ الإجمالي في التطبيق: 24,000 د.ع');
console.log('   💰 المبلغ المرسل للوسيط: 21,000 د.ع');
console.log('   📉 الفرق: 3,000 د.ع (ناقص)');

console.log('\n🔍 التحليل:');
console.log('1. المشكلة لا تزال موجودة رغم الإصلاح السابق');
console.log('2. يجب أن يأخذ المبلغ الإجمالي كما هو من المعلومات المالية');
console.log('3. المشكلة قد تكون في:');
console.log('   - بيانات الوسيط المحفوظة مسبقاً (waseet_data)');
console.log('   - عدم تحديث الطلبات الموجودة');
console.log('   - مشكلة في حساب order.total نفسه');

console.log('\n🎯 الحلول المطلوبة:');
console.log('1. التأكد من أن order.total يحتوي على المبلغ الصحيح');
console.log('2. إعادة إنشاء بيانات الوسيط للطلبات الموجودة');
console.log('3. التأكد من أن الكود الجديد يعمل للطلبات الجديدة');

console.log('\n📝 خطة العمل:');
console.log('1. فحص طلب محدد وبياناته');
console.log('2. إعادة إنشاء بيانات الوسيط');
console.log('3. اختبار الإرسال للوسيط');

// نصائح للمطور
console.log('\n💡 نصائح للحل:');
console.log('1. تشغيل: node fix_existing_orders_price.js');
console.log('2. أو حذف waseet_data للطلبات الموجودة لإعادة إنشائها');
console.log('3. أو تحديث waseet_data.totalPrice يدوياً');

console.log('\n🔧 كود SQL لإصلاح المشكلة:');
console.log(`
-- إصلاح جميع الطلبات الموجودة
UPDATE orders 
SET waseet_data = NULL 
WHERE waseet_data IS NOT NULL;

-- أو تحديث totalPrice مباشرة
UPDATE orders 
SET waseet_data = jsonb_set(
    waseet_data::jsonb, 
    '{totalPrice}', 
    total::text::jsonb
)
WHERE waseet_data IS NOT NULL 
AND (waseet_data::jsonb->>'totalPrice')::numeric != total;
`);

console.log('\n🎯 الخلاصة:');
console.log('المشكلة: الطلبات الموجودة لديها بيانات وسيط قديمة بمبلغ خاطئ');
console.log('الحل: إعادة إنشاء بيانات الوسيط أو تحديث totalPrice');

console.log('\n✅ انتهى التشخيص');
