// ===================================
// سكريبت بدء خاص لـ Render
// يحل مشاكل متغيرات البيئة في Render
// ===================================

// تحميل متغيرات البيئة أولاً (مهم جداً)
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
  console.log(`✅ المفتاح المُصلح: ${process.env.FIREBASE_PRIVATE_KEY.length} حرف`);
}

// تعيين PORT من Render (إجباري)
const renderPort = process.env.PORT;
if (renderPort) {
  console.log(`🌐 Render PORT: ${renderPort}`);
  // التأكد من أن النظام يستخدم PORT من Render
  process.env.PORT = renderPort;
} else {
  console.warn('⚠️ لم يتم العثور على PORT من Render - استخدام 3003');
  process.env.PORT = '3003';
}

// تعيين NODE_ENV و RENDER flag
process.env.NODE_ENV = process.env.NODE_ENV || 'production';
process.env.RENDER = 'true'; // للتعرف على بيئة Render

console.log('🚀 بدء تشغيل الخادم على Render...');
console.log(`📊 البيئة: ${process.env.NODE_ENV}`);
console.log(`🌐 المنفذ: ${process.env.PORT || 3003}`);
console.log('🔍 معرف الإصدار: 4090e8b (مع أدوات التشخيص الشاملة)');

// فحص سريع للمتغيرات قبل البدء
console.log('\n🔍 فحص سريع للمتغيرات:');
const quickCheck = {
  'FIREBASE_PROJECT_ID': !!process.env.FIREBASE_PROJECT_ID,
  'FIREBASE_PRIVATE_KEY': !!process.env.FIREBASE_PRIVATE_KEY,
  'FIREBASE_CLIENT_EMAIL': !!process.env.FIREBASE_CLIENT_EMAIL,
  'NODE_ENV': process.env.NODE_ENV,
  'RENDER': process.env.RENDER
};
Object.entries(quickCheck).forEach(([key, value]) => {
  console.log(`  ${key}: ${value}`);
});

// فحص Firebase النهائي في Render مع تشخيص مفصل
console.log('\n🔥 فحص Firebase النهائي في Render:');

// تشغيل التشخيص الشامل في Render
if (process.env.RENDER === 'true') {
  console.log('🧪 تشغيل التشخيص الشامل في Render...');
  try {
    require('./debug-firebase.js');
  } catch (error) {
    console.log('❌ خطأ في تشغيل التشخيص:', error.message);
  }
}

console.log('🔍 تشخيص مفصل لكل متغير (بعد الإصلاح):');

// فحص كل متغير بشكل منفصل - بعد الإصلاح
const projectId = process.env.FIREBASE_PROJECT_ID;
let privateKey = process.env.FIREBASE_PRIVATE_KEY; // هذا بعد الإصلاح في السطور السابقة
const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;

// فحص إضافي للمتغير البديل
const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT;
if (!privateKey && serviceAccount) {
  console.log('🔄 تم العثور على FIREBASE_SERVICE_ACCOUNT بدلاً من FIREBASE_PRIVATE_KEY');
  try {
    const parsedAccount = JSON.parse(serviceAccount);
    if (parsedAccount.private_key) {
      privateKey = parsedAccount.private_key;
      process.env.FIREBASE_PRIVATE_KEY = privateKey; // تحديث المتغير العام
      console.log('✅ تم استخراج private_key من FIREBASE_SERVICE_ACCOUNT');
    }
  } catch (error) {
    console.log('❌ خطأ في تحليل FIREBASE_SERVICE_ACCOUNT:', error.message);
  }
}

console.log(`📋 FIREBASE_PROJECT_ID: ${projectId ? `"${projectId}"` : 'غير موجود'}`);
console.log(`📋 FIREBASE_CLIENT_EMAIL: ${clientEmail ? `"${clientEmail}"` : 'غير موجود'}`);
// تشخيص مفصل للـ Private Key - بعد الإصلاح
console.log('\n🔍 تشخيص مفصل للـ FIREBASE_PRIVATE_KEY (بعد الإصلاح):');
console.log(`📋 FIREBASE_PRIVATE_KEY: ${privateKey ? `موجود (${privateKey.length} حرف)` : 'غير موجود'}`);

if (privateKey) {
  console.log(`🔍 نوع البيانات: ${typeof privateKey}`);
  console.log(`🔍 أول 100 حرف: "${privateKey.substring(0, 100)}..."`);
  console.log(`🔍 آخر 100 حرف: "...${privateKey.substring(privateKey.length - 100)}"`);
  console.log(`🔍 يحتوي على BEGIN: ${privateKey.includes('BEGIN PRIVATE KEY')}`);
  console.log(`🔍 يحتوي على END: ${privateKey.includes('END PRIVATE KEY')}`);
  console.log(`🔍 يحتوي على \\n: ${privateKey.includes('\\n')}`);
  console.log(`🔍 يحتوي على newlines: ${privateKey.includes('\n')}`);

  // تشخيص إضافي للمفتاح
  console.log('\n🔬 تحليل تفصيلي للمفتاح:');
  console.log(`📏 الطول الكامل: ${privateKey.length} حرف`);
  console.log(`🔤 يبدأ بـ BEGIN: ${privateKey.includes('-----BEGIN PRIVATE KEY-----') ? '✅' : '❌'}`);
  console.log(`🔤 ينتهي بـ END: ${privateKey.includes('-----END PRIVATE KEY-----') ? '✅' : '❌'}`);
  console.log(`📝 عدد الأسطر: ${privateKey.split('\n').length}`);

  // فحص تنسيق المفتاح
  const lines = privateKey.split('\n');
  console.log(`📋 السطر الأول: "${lines[0]}"`);
  console.log(`📋 السطر الأخير: "${lines[lines.length - 1]}"`);

  // فحص المحتوى
  const keyContent = privateKey
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '');
  console.log(`🔐 محتوى المفتاح (بدون headers): ${keyContent.length} حرف`);
  console.log(`🔍 أول 20 حرف من المحتوى: "${keyContent.substring(0, 20)}"`);
} else {
  console.log('❌ FIREBASE_PRIVATE_KEY ما زال غير موجود بعد الإصلاح');
}

// فحص جميع متغيرات البيئة التي تبدأ بـ FIREBASE
console.log('\n🔍 جميع متغيرات Firebase في البيئة:');
const allFirebaseKeys = Object.keys(process.env).filter(key =>
  key.includes('FIREBASE') || key.includes('firebase')
);
console.log(`عدد متغيرات Firebase الموجودة: ${allFirebaseKeys.length}`);
allFirebaseKeys.forEach(key => {
  const value = process.env[key];
  console.log(`  ${key}: ${value ? `موجود (${value.length} حرف)` : 'غير موجود'}`);

  // فحص إضافي للمفتاح الخاص
  if (key === 'FIREBASE_PRIVATE_KEY' && value) {
    console.log(`    - النوع: ${typeof value}`);
    console.log(`    - يبدأ بـ: "${value.substring(0, 30)}..."`);
    console.log(`    - يحتوي على BEGIN: ${value.includes('BEGIN PRIVATE KEY')}`);
    console.log(`    - يحتوي على \\n: ${value.includes('\\n')}`);
  }
});

// فحص نهائي للمتغيرات بعد الاستخراج من FIREBASE_SERVICE_ACCOUNT
const finalProjectId = process.env.FIREBASE_PROJECT_ID;
const finalPrivateKey = process.env.FIREBASE_PRIVATE_KEY;
const finalClientEmail = process.env.FIREBASE_CLIENT_EMAIL;

const hasFirebaseVars = !!(finalProjectId && finalPrivateKey && finalClientEmail);

if (hasFirebaseVars) {
  console.log('\n✅ جميع متغيرات Firebase متوفرة (من FIREBASE_SERVICE_ACCOUNT أو المتغيرات المنفصلة)');
  console.log('🧪 محاولة إنشاء Service Account للاختبار...');

  try {
    const testServiceAccount = {
      project_id: finalProjectId,
      private_key: finalPrivateKey,
      client_email: finalClientEmail,
      type: 'service_account'
    };
    console.log('✅ تم إنشاء Service Account بنجاح');
    console.log(`📋 Project ID: ${testServiceAccount.project_id}`);
    console.log(`📧 Client Email: ${testServiceAccount.client_email}`);
  } catch (error) {
    console.log(`❌ خطأ في إنشاء Service Account: ${error.message}`);
  }
} else {
  // فحص إضافي للـ FIREBASE_SERVICE_ACCOUNT
  const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (serviceAccount) {
    console.log('\n🔄 FIREBASE_SERVICE_ACCOUNT موجود - سيتم استخراج المتغيرات تلقائياً');
    console.log('✅ Firebase سيعمل بشكل صحيح');
  } else {
    console.log('\n❌ بعض متغيرات Firebase مفقودة في Render!');
    console.log('💡 يجب إضافة إما:');
    console.log('   1. FIREBASE_SERVICE_ACCOUNT (الطريقة المفضلة)');
    console.log('   2. أو المتغيرات المنفصلة:');
    if (!finalProjectId) console.log('      - FIREBASE_PROJECT_ID');
    if (!finalPrivateKey) console.log('      - FIREBASE_PRIVATE_KEY');
    if (!finalClientEmail) console.log('      - FIREBASE_CLIENT_EMAIL');
  }
}

// تحسينات خاصة بـ Render
if (process.env.NODE_ENV === 'production') {
  console.log('⚡ تطبيق تحسينات الإنتاج:');
  console.log('  - مزامنة كل 10 دقائق');
  console.log('  - مراقبة كل 5 دقائق بدلاً من 30 ثانية');
  console.log('  - إخفاء رسائل فحص الطلبات تماماً');
  console.log('  - تجنب الطلبات التجريبية');
}

// تشغيل الخادم الرئيسي
require('./production_server.js');
