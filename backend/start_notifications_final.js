#!/usr/bin/env node

// ===================================
// تشغيل نظام الإشعارات النهائي
// ===================================

require('dotenv').config();
const SimpleNotificationProcessor = require('./notification_processor_simple');

console.log('🚀 بدء تشغيل نظام الإشعارات النهائي...\n');

// التحقق من متغيرات البيئة
const requiredEnvVars = [
  'SUPABASE_URL',
  'SUPABASE_SERVICE_ROLE_KEY',
  'FIREBASE_SERVICE_ACCOUNT'
];

console.log('🔍 فحص متغيرات البيئة...');
let missingVars = [];

for (const envVar of requiredEnvVars) {
  if (!process.env[envVar]) {
    missingVars.push(envVar);
  } else {
    console.log(`✅ ${envVar}: موجود`);
  }
}

if (missingVars.length > 0) {
  console.error('❌ متغيرات البيئة المفقودة:');
  missingVars.forEach(varName => {
    console.error(`   - ${varName}`);
  });
  console.error('\nيرجى إضافة هذه المتغيرات في ملف .env');
  process.exit(1);
}

console.log('✅ جميع متغيرات البيئة موجودة\n');

// إنشاء معالج الإشعارات
const processor = new SimpleNotificationProcessor();

// بدء المعالجة
processor.startProcessing();

// معلومات النظام
console.log('==================================================');
console.log('🎉 نظام الإشعارات يعمل بنجاح!');
console.log('📱 يتم معالجة الإشعارات كل 10 ثواني');
console.log('🔄 إعادة المحاولة التلقائية: 3 مرات');
console.log('📊 تسجيل جميع الإشعارات في قاعدة البيانات');
console.log('==================================================');
console.log('⚡ للإيقاف: اضغط Ctrl+C');
console.log('==================================================\n');

// إيقاف نظيف عند الإنهاء
process.on('SIGINT', () => {
  console.log('\n🛑 إيقاف نظام الإشعارات...');
  processor.stopProcessing();
  console.log('✅ تم إيقاف النظام بنجاح');
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n🛑 إيقاف نظام الإشعارات (SIGTERM)...');
  processor.stopProcessing();
  console.log('✅ تم إيقاف النظام بنجاح');
  process.exit(0);
});

// معالجة الأخطاء غير المتوقعة
process.on('uncaughtException', (error) => {
  console.error('❌ خطأ غير متوقع:', error.message);
  processor.stopProcessing();
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ رفض غير معالج:', reason);
  processor.stopProcessing();
  process.exit(1);
});

// إبقاء العملية قيد التشغيل
setInterval(() => {
  // فحص دوري لحالة النظام
}, 60000); // كل دقيقة
