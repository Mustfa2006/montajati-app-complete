// ===================================
// فحص متغيرات Firebase
// ===================================

require('dotenv').config();

function checkFirebaseVars() {
  console.log('🔍 فحص متغيرات Firebase...\n');
  
  // فحص المتغيرات المطلوبة
  const requiredVars = [
    'FIREBASE_PROJECT_ID',
    'FIREBASE_PRIVATE_KEY', 
    'FIREBASE_CLIENT_EMAIL'
  ];
  
  console.log('📋 المتغيرات المطلوبة:');
  requiredVars.forEach(varName => {
    const value = process.env[varName];
    const exists = !!value;
    const isValid = exists && !value.includes('your-') && !value.includes('YOUR_') && !value.includes('xxxxx');
    
    console.log(`  ${varName}:`);
    console.log(`    ✅ موجود: ${exists}`);
    console.log(`    ✅ صالح: ${isValid}`);
    
    if (exists) {
      if (varName === 'FIREBASE_PRIVATE_KEY') {
        console.log(`    📏 الطول: ${value.length} حرف`);
        console.log(`    🔑 يبدأ بـ: ${value.substring(0, 30)}...`);
        console.log(`    🔑 ينتهي بـ: ...${value.substring(value.length - 30)}`);
      } else {
        console.log(`    📝 القيمة: ${value}`);
      }
    }
    console.log('');
  });
  
  // فحص المتغيرات الاختيارية
  const optionalVars = [
    'FIREBASE_PRIVATE_KEY_ID',
    'FIREBASE_CLIENT_ID',
    'FIREBASE_AUTH_URI',
    'FIREBASE_TOKEN_URI'
  ];
  
  console.log('📋 المتغيرات الاختيارية:');
  optionalVars.forEach(varName => {
    const value = process.env[varName];
    const exists = !!value;
    
    console.log(`  ${varName}: ${exists ? '✅ موجود' : '❌ غير موجود'}`);
    if (exists) {
      console.log(`    📝 القيمة: ${value}`);
    }
  });
  
  // النتيجة النهائية
  const hasRequired = requiredVars.every(varName => {
    const value = process.env[varName];
    return value && !value.includes('your-') && !value.includes('YOUR_') && !value.includes('xxxxx');
  });
  
  console.log('\n🎯 النتيجة النهائية:');
  if (hasRequired) {
    console.log('✅ جميع متغيرات Firebase مكتملة وصحيحة');
    console.log('✅ Firebase سيعمل بنجاح');
  } else {
    console.log('❌ متغيرات Firebase غير مكتملة أو غير صحيحة');
    console.log('❌ Firebase لن يعمل - الإشعارات معطلة');
    
    console.log('\n💡 لإصلاح المشكلة:');
    console.log('1. تأكد من إضافة المتغيرات في Render Environment Variables');
    console.log('2. تأكد من أن القيم صحيحة وليست وهمية');
    console.log('3. تأكد من تنسيق FIREBASE_PRIVATE_KEY الصحيح');
  }
}

if (require.main === module) {
  checkFirebaseVars();
}

module.exports = checkFirebaseVars;
