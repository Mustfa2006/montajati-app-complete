// اختبار بسيط للإشعارات
require('dotenv').config({ path: '../.env' });

console.log('🔍 اختبار بسيط للإشعارات...');

// فحص متغيرات البيئة
console.log('1️⃣ فحص متغيرات البيئة:');
console.log(`   SUPABASE_URL: ${process.env.SUPABASE_URL ? '✅ موجود' : '❌ مفقود'}`);
console.log(`   SUPABASE_SERVICE_ROLE_KEY: ${process.env.SUPABASE_SERVICE_ROLE_KEY ? '✅ موجود' : '❌ مفقود'}`);
console.log(`   FIREBASE_SERVICE_ACCOUNT: ${process.env.FIREBASE_SERVICE_ACCOUNT ? '✅ موجود' : '❌ مفقود'}`);

// اختبار Firebase
console.log('\n2️⃣ اختبار Firebase:');
try {
  const admin = require('firebase-admin');
  
  if (admin.apps.length > 0) {
    admin.apps.forEach(app => app.delete());
  }

  const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: serviceAccount.project_id
  });

  console.log('   ✅ Firebase مُهيأ بنجاح');
  console.log(`   📋 Project ID: ${serviceAccount.project_id}`);
  
} catch (error) {
  console.log(`   ❌ خطأ في Firebase: ${error.message}`);
}

console.log('\n✅ انتهى الاختبار البسيط');
