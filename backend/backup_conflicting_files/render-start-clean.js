// ===================================
// سكريبت بدء مبسط لـ Render
// نسخة نظيفة بدون رسائل تشخيص مفصلة
// ===================================

// تحميل متغيرات البيئة أولاً
require('dotenv').config();

// تحسين متغيرات Firebase لـ Render
if (process.env.FIREBASE_PRIVATE_KEY) {
  let privateKey = process.env.FIREBASE_PRIVATE_KEY;

  // إصلاح شامل لمشكلة Private Key في Render
  privateKey = privateKey
    .replace(/\\n/g, '\n')  // تحويل \\n إلى أسطر جديدة حقيقية
    .replace(/\s+-----BEGIN PRIVATE KEY-----/g, '-----BEGIN PRIVATE KEY-----')
    .replace(/-----END PRIVATE KEY-----\s+/g, '-----END PRIVATE KEY-----')
    .replace(/\s+/g, ' ')  // تنظيف المسافات الزائدة
    .trim();

  // التأكد من وجود header و footer
  if (!privateKey.includes('-----BEGIN PRIVATE KEY-----')) {
    privateKey = '-----BEGIN PRIVATE KEY-----\n' + privateKey;
  }
  if (!privateKey.includes('-----END PRIVATE KEY-----')) {
    privateKey = privateKey + '\n-----END PRIVATE KEY-----';
  }

  // إعادة تنسيق المفتاح بشكل صحيح
  const lines = privateKey.split('\n');
  const cleanLines = [];

  for (let line of lines) {
    line = line.trim();
    if (line === '-----BEGIN PRIVATE KEY-----' || line === '-----END PRIVATE KEY-----') {
      cleanLines.push(line);
    } else if (line.length > 0 && !line.includes('-----')) {
      // تقسيم السطور الطويلة إلى 64 حرف
      while (line.length > 64) {
        cleanLines.push(line.substring(0, 64));
        line = line.substring(64);
      }
      if (line.length > 0) {
        cleanLines.push(line);
      }
    }
  }

  process.env.FIREBASE_PRIVATE_KEY = cleanLines.join('\n');
  console.log('🔧 تم إصلاح Firebase Private Key للـ Render');
}

// معالجة FIREBASE_SERVICE_ACCOUNT
const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT;
if (serviceAccount && !process.env.FIREBASE_PRIVATE_KEY) {
  console.log('🔄 استخراج متغيرات Firebase من FIREBASE_SERVICE_ACCOUNT...');
  try {
    const parsedAccount = JSON.parse(serviceAccount);
    if (parsedAccount.private_key && parsedAccount.project_id && parsedAccount.client_email) {
      process.env.FIREBASE_PRIVATE_KEY = parsedAccount.private_key;
      process.env.FIREBASE_PROJECT_ID = parsedAccount.project_id;
      process.env.FIREBASE_CLIENT_EMAIL = parsedAccount.client_email;
      console.log('✅ تم استخراج متغيرات Firebase بنجاح');
    }
  } catch (error) {
    console.log('❌ خطأ في تحليل FIREBASE_SERVICE_ACCOUNT:', error.message);
  }
}

// تعيين PORT من Render
const renderPort = process.env.PORT;
if (renderPort) {
  console.log(`🌐 Render PORT: ${renderPort}`);
  process.env.PORT = renderPort;
} else {
  console.log('⚠️ لم يتم العثور على PORT من Render - استخدام 3003');
  process.env.PORT = '3003';
}

// تعيين NODE_ENV و RENDER flag
process.env.NODE_ENV = process.env.NODE_ENV || 'production';
process.env.RENDER = 'true';

console.log('🚀 بدء تشغيل الخادم على Render...');
console.log(`📊 البيئة: ${process.env.NODE_ENV}`);
console.log(`🌐 المنفذ: ${process.env.PORT || 3003}`);

// فحص سريع للمتغيرات المهمة
const hasFirebase = !!(
  process.env.FIREBASE_PROJECT_ID && 
  process.env.FIREBASE_PRIVATE_KEY && 
  process.env.FIREBASE_CLIENT_EMAIL
) || !!process.env.FIREBASE_SERVICE_ACCOUNT;

console.log(`🔥 Firebase: ${hasFirebase ? '✅ جاهز' : '⚠️ غير متوفر'}`);

if (process.env.NODE_ENV === 'production') {
  console.log('⚡ تطبيق تحسينات الإنتاج');

  // تطبيق تحسينات الأداء
  try {
    const { initializeOptimizations } = require('./performance-optimizations.js');
    initializeOptimizations();
  } catch (error) {
    console.log('ℹ️ تخطي تحسينات الأداء:', error.message);
  }
}

// تشغيل الخادم الرئيسي
require('./production_server.js');
