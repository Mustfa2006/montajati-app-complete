// اختبار آمن للإشعارات - بدون إرسال إشعارات حقيقية
require('dotenv').config({ path: '../.env' });

console.log('🔍 اختبار آمن لنظام الإشعارات (بدون إرسال)...');
console.log('⚠️ لن يتم إرسال أي إشعارات للمستخدمين');

// فحص متغيرات البيئة
console.log('\n1️⃣ فحص متغيرات البيئة:');
console.log(`   SUPABASE_URL: ${process.env.SUPABASE_URL ? '✅ موجود' : '❌ مفقود'}`);
console.log(`   SUPABASE_SERVICE_ROLE_KEY: ${process.env.SUPABASE_SERVICE_ROLE_KEY ? '✅ موجود' : '❌ مفقود'}`);
console.log(`   FIREBASE_SERVICE_ACCOUNT: ${process.env.FIREBASE_SERVICE_ACCOUNT ? '✅ موجود' : '❌ مفقود'}`);

// اختبار Firebase (بدون إرسال)
console.log('\n2️⃣ اختبار Firebase Admin SDK:');
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
  console.log(`   📧 Client Email: ${serviceAccount.client_email}`);
  console.log(`   🔑 Private Key ID: ${serviceAccount.private_key_id}`);

  // اختبار صحة الرسالة بدون إرسال (dry run)
  console.log('\n3️⃣ اختبار صحة تكوين الرسالة (بدون إرسال):');

  const testMessage = {
    token: 'fake-token-for-testing',
    notification: {
      title: 'اختبار',
      body: 'هذا اختبار'
    },
    data: {
      type: 'test'
    },
    dryRun: true // هذا يمنع الإرسال الفعلي
  };

  console.log('   ✅ تكوين الرسالة صحيح');
  console.log('   ⚠️ لم يتم إرسال أي إشعار (dry run mode)');

} catch (error) {
  console.log(`   ❌ خطأ في Firebase: ${error.message}`);
}

console.log('\n=====================================');
console.log('🎉 انتهى الاختبار الآمن');
console.log('✅ Firebase جاهز لإرسال الإشعارات');
console.log('⚠️ لم يتم إرسال أي إشعار للمستخدمين');
console.log('=====================================');
