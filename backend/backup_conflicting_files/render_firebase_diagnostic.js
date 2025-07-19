// ===================================
// تشخيص شامل لمتغيرات Firebase في Render
// ===================================

require('dotenv').config();

console.log('🔥 تشخيص Firebase في Render - الإصدار المحدث');
console.log('📅 تاريخ التحديث: 2025-07-17');
console.log('🔍 معرف الـ commit: 0a82b90');
console.log('=' * 50);

// فحص متغيرات البيئة
console.log('\n📋 فحص متغيرات البيئة:');
console.log(`NODE_ENV: ${process.env.NODE_ENV || 'غير محدد'}`);
console.log(`PORT: ${process.env.PORT || 'غير محدد'}`);
console.log(`RENDER: ${process.env.RENDER || 'غير محدد'}`);

// فحص متغيرات Firebase
console.log('\n🔥 فحص متغيرات Firebase:');

const projectId = process.env.FIREBASE_PROJECT_ID;
const privateKey = process.env.FIREBASE_PRIVATE_KEY;
const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;

console.log(`FIREBASE_PROJECT_ID: ${projectId ? '✅ موجود' : '❌ مفقود'}`);
console.log(`FIREBASE_CLIENT_EMAIL: ${clientEmail ? '✅ موجود' : '❌ مفقود'}`);
console.log(`FIREBASE_PRIVATE_KEY: ${privateKey ? '✅ موجود' : '❌ مفقود'}`);

if (projectId) {
  console.log(`  📋 Project ID: "${projectId}"`);
}

if (clientEmail) {
  console.log(`  📧 Client Email: "${clientEmail}"`);
}

if (privateKey) {
  console.log(`  🔐 Private Key Details:`);
  console.log(`    📏 الطول: ${privateKey.length} حرف`);
  console.log(`    🔤 يبدأ بـ BEGIN: ${privateKey.includes('-----BEGIN PRIVATE KEY-----') ? '✅' : '❌'}`);
  console.log(`    🔤 ينتهي بـ END: ${privateKey.includes('-----END PRIVATE KEY-----') ? '✅' : '❌'}`);
  console.log(`    📝 عدد الأسطر: ${privateKey.split('\n').length}`);
  
  const lines = privateKey.split('\n');
  console.log(`    📋 السطر الأول: "${lines[0]}"`);
  console.log(`    📋 السطر الأخير: "${lines[lines.length - 1]}"`);
  
  // فحص المحتوى
  const keyContent = privateKey
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '');
  console.log(`    🔐 محتوى المفتاح: ${keyContent.length} حرف`);
  console.log(`    🔍 أول 30 حرف: "${keyContent.substring(0, 30)}..."`);
  console.log(`    🔍 آخر 30 حرف: "...${keyContent.substring(keyContent.length - 30)}"`);
  
  // اختبار تحويل المفتاح
  try {
    const testKey = privateKey.replace(/\\n/g, '\n');
    console.log(`    🧪 اختبار تحويل \\n: ${testKey.length !== privateKey.length ? 'تم التحويل' : 'لا يحتاج تحويل'}`);
  } catch (error) {
    console.log(`    ❌ خطأ في اختبار التحويل: ${error.message}`);
  }
}

// فحص جميع متغيرات Firebase
console.log('\n🔍 جميع متغيرات Firebase في البيئة:');
const firebaseVars = Object.keys(process.env).filter(key => key.startsWith('FIREBASE'));
if (firebaseVars.length > 0) {
  firebaseVars.forEach(key => {
    const value = process.env[key];
    console.log(`  ${key}: ${value ? `موجود (${value.length} حرف)` : 'غير موجود'}`);
  });
} else {
  console.log('  ❌ لا توجد متغيرات Firebase في البيئة');
}

// اختبار إنشاء Service Account
console.log('\n🧪 اختبار إنشاء Service Account:');
if (projectId && privateKey && clientEmail) {
  try {
    const serviceAccount = {
      project_id: projectId,
      private_key: privateKey.replace(/\\n/g, '\n'),
      client_email: clientEmail,
      type: 'service_account'
    };
    
    console.log('✅ تم إنشاء Service Account بنجاح');
    console.log(`  📋 Project ID: ${serviceAccount.project_id}`);
    console.log(`  📧 Client Email: ${serviceAccount.client_email}`);
    console.log(`  🔐 Private Key: ${serviceAccount.private_key.length} حرف`);
    
    // اختبار Firebase Admin SDK
    try {
      const admin = require('firebase-admin');
      if (admin.apps.length === 0) {
        const app = admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
          projectId: serviceAccount.project_id
        });
        console.log('✅ تم تهيئة Firebase Admin SDK بنجاح');
        console.log(`  📱 App Name: ${app.name}`);
      } else {
        console.log('✅ Firebase Admin SDK مهيأ مسبقاً');
      }
    } catch (firebaseError) {
      console.log(`❌ خطأ في تهيئة Firebase Admin SDK: ${firebaseError.message}`);
    }
    
  } catch (error) {
    console.log(`❌ خطأ في إنشاء Service Account: ${error.message}`);
  }
} else {
  console.log('❌ لا يمكن إنشاء Service Account - متغيرات مفقودة');
}

console.log('\n' + '=' * 50);
console.log('🏁 انتهى التشخيص');
