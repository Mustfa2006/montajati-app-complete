#!/usr/bin/env node

/**
 * اختبار بسيط لمتغيرات البيئة
 */

console.log('🧪 اختبار متغيرات البيئة...\n');

// طباعة جميع متغيرات البيئة
console.log('=== جميع متغيرات البيئة ===');
const allEnvVars = Object.keys(process.env).sort();
console.log(`إجمالي المتغيرات: ${allEnvVars.length}`);

// البحث عن متغيرات Firebase
const firebaseVars = allEnvVars.filter(key => 
  key.includes('FIREBASE') || 
  key.includes('firebase') || 
  key.includes('Firebase')
);

console.log(`\n=== متغيرات Firebase (${firebaseVars.length}) ===`);
firebaseVars.forEach(key => {
  const value = process.env[key];
  console.log(`${key}: ${value ? `"${value.substring(0, 30)}..." (${value.length} حرف)` : 'غير موجود'}`);
});

// فحص المتغيرات المطلوبة تحديداً
console.log('\n=== المتغيرات المطلوبة ===');
const requiredVars = [
  'FIREBASE_PROJECT_ID',
  'FIREBASE_PRIVATE_KEY', 
  'FIREBASE_CLIENT_EMAIL'
];

requiredVars.forEach(varName => {
  const value = process.env[varName];
  console.log(`${varName}:`);
  console.log(`  - موجود: ${value ? '✅' : '❌'}`);
  if (value) {
    console.log(`  - النوع: ${typeof value}`);
    console.log(`  - الطول: ${value.length} حرف`);
    console.log(`  - أول 20 حرف: "${value.substring(0, 20)}..."`);
    
    if (varName === 'FIREBASE_PRIVATE_KEY') {
      console.log(`  - يبدأ بـ BEGIN: ${value.includes('BEGIN PRIVATE KEY')}`);
      console.log(`  - ينتهي بـ END: ${value.includes('END PRIVATE KEY')}`);
      console.log(`  - يحتوي على \\n: ${value.includes('\\n')}`);
      console.log(`  - عدد الأسطر: ${value.split('\n').length}`);
    }
  }
  console.log('');
});

// محاولة قراءة المتغيرات بطرق مختلفة
console.log('=== اختبار طرق القراءة المختلفة ===');

// الطريقة 1: مباشرة
console.log('1. القراءة المباشرة:');
console.log(`   FIREBASE_PRIVATE_KEY موجود: ${!!process.env.FIREBASE_PRIVATE_KEY}`);

// الطريقة 2: بعد تحميل dotenv
console.log('2. بعد تحميل dotenv:');
try {
  require('dotenv').config();
  console.log(`   FIREBASE_PRIVATE_KEY موجود: ${!!process.env.FIREBASE_PRIVATE_KEY}`);
} catch (error) {
  console.log(`   خطأ في dotenv: ${error.message}`);
}

// الطريقة 3: فحص Object.keys
console.log('3. فحص Object.keys:');
const hasKey = Object.keys(process.env).includes('FIREBASE_PRIVATE_KEY');
console.log(`   FIREBASE_PRIVATE_KEY في Object.keys: ${hasKey}`);

// الطريقة 4: فحص hasOwnProperty
console.log('4. فحص hasOwnProperty:');
const hasOwnProp = process.env.hasOwnProperty('FIREBASE_PRIVATE_KEY');
console.log(`   FIREBASE_PRIVATE_KEY hasOwnProperty: ${hasOwnProp}`);

console.log('\n🧪 انتهى اختبار متغيرات البيئة');
