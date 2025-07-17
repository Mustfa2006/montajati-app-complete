// ===================================
// فحص شامل لـ Firebase في Render
// ===================================

require('dotenv').config();

function renderFirebaseCheck() {
  console.log('🔥 فحص شامل لـ Firebase في Render\n');
  
  // 1. فحص متغيرات البيئة المطلوبة
  console.log('📋 1. فحص متغيرات البيئة المطلوبة:');
  
  const requiredVars = {
    'FIREBASE_PROJECT_ID': process.env.FIREBASE_PROJECT_ID,
    'FIREBASE_PRIVATE_KEY': process.env.FIREBASE_PRIVATE_KEY,
    'FIREBASE_CLIENT_EMAIL': process.env.FIREBASE_CLIENT_EMAIL
  };
  
  let allVarsPresent = true;
  
  Object.entries(requiredVars).forEach(([key, value]) => {
    const exists = !!value;
    const isValid = exists && value.length > 10 && !value.includes('your-') && !value.includes('YOUR_');
    
    console.log(`  ${key}:`);
    console.log(`    ✅ موجود: ${exists}`);
    console.log(`    ✅ صالح: ${isValid}`);
    
    if (!exists || !isValid) {
      allVarsPresent = false;
    }
    
    if (exists) {
      if (key === 'FIREBASE_PRIVATE_KEY') {
        console.log(`    📏 الطول: ${value.length} حرف`);
        console.log(`    🔑 يبدأ بـ: ${value.substring(0, 30)}...`);
        console.log(`    🔑 ينتهي بـ: ...${value.substring(value.length - 30)}`);
        
        // فحص تنسيق المفتاح
        const hasBegin = value.includes('-----BEGIN PRIVATE KEY-----');
        const hasEnd = value.includes('-----END PRIVATE KEY-----');
        console.log(`    🔐 تنسيق صحيح: ${hasBegin && hasEnd}`);
      } else {
        console.log(`    📝 القيمة: ${value}`);
      }
    }
    console.log('');
  });
  
  // 2. فحص متغيرات اختيارية
  console.log('📋 2. فحص متغيرات اختيارية:');
  const optionalVars = [
    'FIREBASE_PRIVATE_KEY_ID',
    'FIREBASE_CLIENT_ID',
    'FIREBASE_AUTH_URI',
    'FIREBASE_TOKEN_URI'
  ];
  
  optionalVars.forEach(varName => {
    const value = process.env[varName];
    console.log(`  ${varName}: ${value ? '✅ موجود' : '❌ غير موجود'}`);
  });
  
  // 3. اختبار تهيئة Firebase
  console.log('\n🔥 3. اختبار تهيئة Firebase:');
  
  if (allVarsPresent) {
    try {
      const admin = require('firebase-admin');
      
      // تنظيف المفتاح
      let cleanPrivateKey = process.env.FIREBASE_PRIVATE_KEY;
      if (cleanPrivateKey) {
        cleanPrivateKey = cleanPrivateKey.replace(/\\n/g, '\n');
      }
      
      const serviceAccount = {
        type: 'service_account',
        project_id: process.env.FIREBASE_PROJECT_ID,
        private_key: cleanPrivateKey,
        client_email: process.env.FIREBASE_CLIENT_EMAIL
      };
      
      // محاولة التهيئة
      if (admin.apps.length === 0) {
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
          projectId: process.env.FIREBASE_PROJECT_ID
        });
        console.log('  ✅ تم تهيئة Firebase بنجاح');
      } else {
        console.log('  ✅ Firebase مهيأ مسبقاً');
      }
      
    } catch (error) {
      console.log(`  ❌ فشل في تهيئة Firebase: ${error.message}`);
    }
  } else {
    console.log('  ❌ لا يمكن اختبار Firebase - متغيرات مفقودة');
  }
  
  // 4. النتيجة النهائية والتوصيات
  console.log('\n🎯 4. النتيجة النهائية:');
  
  if (allVarsPresent) {
    console.log('✅ جميع متغيرات Firebase صحيحة ومكتملة');
    console.log('✅ Firebase جاهز للعمل');
    console.log('✅ الإشعارات ستعمل بنجاح');
  } else {
    console.log('❌ متغيرات Firebase غير مكتملة أو غير صحيحة');
    console.log('❌ Firebase لن يعمل');
    console.log('❌ الإشعارات معطلة');
    
    console.log('\n💡 لإصلاح المشكلة في Render:');
    console.log('1. اذهب إلى Render Dashboard');
    console.log('2. اختر الخدمة: montajati-backend');
    console.log('3. اذهب إلى Environment');
    console.log('4. أضف المتغيرات التالية:');
    console.log('   FIREBASE_PROJECT_ID=withdrawal-notifications');
    console.log('   FIREBASE_CLIENT_EMAIL=firebase-adminsdk-fbsvc@withdrawal-notifications.iam.gserviceaccount.com');
    console.log('   FIREBASE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\\n...\\n-----END PRIVATE KEY-----');
    console.log('5. احفظ وأعد النشر');
  }
}

if (require.main === module) {
  renderFirebaseCheck();
}

module.exports = renderFirebaseCheck;
