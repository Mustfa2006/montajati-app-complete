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
console.log('🔍 معرف الإصدار: 0a82b90 (آخر تحديث مع التشخيص المفصل)');

// فحص Firebase النهائي في Render مع تشخيص مفصل
console.log('\n🔥 فحص Firebase النهائي في Render:');
console.log('🔍 تشخيص مفصل لكل متغير:');

// فحص كل متغير بشكل منفصل
const projectId = process.env.FIREBASE_PROJECT_ID;
let privateKey = process.env.FIREBASE_PRIVATE_KEY;
const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;

// فحص إضافي للمتغير البديل
const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT;
if (!privateKey && serviceAccount) {
  console.log('🔄 تم العثور على FIREBASE_SERVICE_ACCOUNT بدلاً من FIREBASE_PRIVATE_KEY');
  try {
    const parsedAccount = JSON.parse(serviceAccount);
    if (parsedAccount.private_key) {
      privateKey = parsedAccount.private_key;
      console.log('✅ تم استخراج private_key من FIREBASE_SERVICE_ACCOUNT');
    }
  } catch (error) {
    console.log('❌ خطأ في تحليل FIREBASE_SERVICE_ACCOUNT:', error.message);
  }
}

console.log(`📋 FIREBASE_PROJECT_ID: ${projectId ? `"${projectId}"` : 'غير موجود'}`);
console.log(`📋 FIREBASE_CLIENT_EMAIL: ${clientEmail ? `"${clientEmail}"` : 'غير موجود'}`);
console.log(`📋 FIREBASE_PRIVATE_KEY: ${privateKey ? `موجود (${privateKey.length} حرف)` : 'غير موجود'}`);

if (privateKey) {
  console.log(`🔍 أول 50 حرف من Private Key: "${privateKey.substring(0, 50)}..."`);
  console.log(`🔍 آخر 50 حرف من Private Key: "...${privateKey.substring(privateKey.length - 50)}"`);

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
}

// فحص جميع متغيرات البيئة التي تبدأ بـ FIREBASE
console.log('\n🔍 جميع متغيرات Firebase في البيئة:');
Object.keys(process.env).filter(key => key.startsWith('FIREBASE')).forEach(key => {
  const value = process.env[key];
  console.log(`  ${key}: ${value ? `موجود (${value.length} حرف)` : 'غير موجود'}`);
});

const hasFirebaseVars = !!(projectId && privateKey && clientEmail);

if (hasFirebaseVars) {
  console.log('\n✅ جميع متغيرات Firebase موجودة في Render');
  console.log('🧪 محاولة إنشاء Service Account للاختبار...');

  try {
    const testServiceAccount = {
      project_id: projectId,
      private_key: privateKey,
      client_email: clientEmail,
      type: 'service_account'
    };
    console.log('✅ تم إنشاء Service Account بنجاح');
    console.log(`📋 Project ID: ${testServiceAccount.project_id}`);
    console.log(`📧 Client Email: ${testServiceAccount.client_email}`);
  } catch (error) {
    console.log(`❌ خطأ في إنشاء Service Account: ${error.message}`);
  }
} else {
  console.log('\n❌ بعض متغيرات Firebase مفقودة في Render!');
  console.log('💡 يجب إضافة المتغيرات في Render Environment Variables:');
  if (!projectId) console.log('   - FIREBASE_PROJECT_ID');
  if (!privateKey) console.log('   - FIREBASE_PRIVATE_KEY');
  if (!clientEmail) console.log('   - FIREBASE_CLIENT_EMAIL');
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
