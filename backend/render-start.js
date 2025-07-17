// ===================================
// سكريبت بدء خاص لـ Render
// يحل مشاكل متغيرات البيئة في Render
// ===================================

// تحسين متغيرات Firebase لـ Render
if (process.env.FIREBASE_PRIVATE_KEY) {
  // إصلاح مشكلة الأسطر الجديدة في Render
  process.env.FIREBASE_PRIVATE_KEY = process.env.FIREBASE_PRIVATE_KEY
    .replace(/\\n/g, '\n')
    .replace(/\s+-----BEGIN PRIVATE KEY-----/g, '-----BEGIN PRIVATE KEY-----')
    .replace(/-----END PRIVATE KEY-----\s+/g, '-----END PRIVATE KEY-----')
    .trim();
}

// تعيين PORT من Render
if (process.env.PORT) {
  console.log(`🌐 Render PORT: ${process.env.PORT}`);
}

// تعيين NODE_ENV
process.env.NODE_ENV = process.env.NODE_ENV || 'production';

console.log('🚀 بدء تشغيل الخادم على Render...');
console.log(`📊 البيئة: ${process.env.NODE_ENV}`);
console.log(`🌐 المنفذ: ${process.env.PORT || 3003}`);

// تشغيل الخادم الرئيسي
require('./production_server.js');
