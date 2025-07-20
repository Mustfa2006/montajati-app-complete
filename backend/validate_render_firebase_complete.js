// ===================================
// فحص شامل لمتغير Firebase في Render
// ===================================

require('dotenv').config();

console.log('🔍 فحص شامل لمتغير Firebase في Render');
console.log('=' * 60);

/**
 * فحص متغير FIREBASE_SERVICE_ACCOUNT
 */
function validateFirebaseServiceAccount() {
  console.log('\n🔄 فحص 1: التحقق من وجود FIREBASE_SERVICE_ACCOUNT...');
  
  const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT;
  
  if (!serviceAccount) {
    console.log('❌ متغير FIREBASE_SERVICE_ACCOUNT غير موجود');
    return false;
  }
  
  console.log('✅ متغير FIREBASE_SERVICE_ACCOUNT موجود');
  console.log(`📏 طول البيانات: ${serviceAccount.length} حرف`);
  
  // فحص تحليل JSON
  console.log('\n🔄 فحص 2: تحليل JSON...');
  
  let parsedAccount;
  try {
    parsedAccount = JSON.parse(serviceAccount);
    console.log('✅ تم تحليل JSON بنجاح');
  } catch (error) {
    console.log(`❌ خطأ في تحليل JSON: ${error.message}`);
    return false;
  }
  
  // فحص الحقول المطلوبة
  console.log('\n🔄 فحص 3: التحقق من الحقول المطلوبة...');
  
  const requiredFields = [
    'type',
    'project_id', 
    'private_key_id',
    'private_key',
    'client_email',
    'client_id',
    'auth_uri',
    'token_uri'
  ];
  
  let allFieldsPresent = true;
  
  for (const field of requiredFields) {
    if (!parsedAccount[field]) {
      console.log(`❌ حقل مفقود: ${field}`);
      allFieldsPresent = false;
    } else {
      console.log(`✅ ${field}: موجود`);
    }
  }
  
  if (!allFieldsPresent) {
    return false;
  }
  
  // فحص تفصيلي للحقول المهمة
  console.log('\n🔄 فحص 4: التحقق من صحة البيانات...');
  
  // فحص project_id
  if (parsedAccount.project_id !== 'montajati-app-7767d') {
    console.log(`⚠️ project_id غير متطابق: ${parsedAccount.project_id}`);
    console.log('   المتوقع: montajati-app-7767d');
  } else {
    console.log('✅ project_id صحيح: montajati-app-7767d');
  }
  
  // فحص client_email
  const expectedEmail = 'firebase-adminsdk-fbsvc@montajati-app-7767d.iam.gserviceaccount.com';
  if (parsedAccount.client_email !== expectedEmail) {
    console.log(`⚠️ client_email غير متطابق: ${parsedAccount.client_email}`);
    console.log(`   المتوقع: ${expectedEmail}`);
  } else {
    console.log('✅ client_email صحيح');
  }
  
  // فحص private_key
  const privateKey = parsedAccount.private_key;
  if (!privateKey.includes('-----BEGIN PRIVATE KEY-----') || 
      !privateKey.includes('-----END PRIVATE KEY-----')) {
    console.log('❌ private_key لا يحتوي على تنسيق صحيح');
    return false;
  } else {
    console.log('✅ private_key يحتوي على تنسيق صحيح');
    
    // فحص طول المفتاح
    const keyContent = privateKey
      .replace('-----BEGIN PRIVATE KEY-----', '')
      .replace('-----END PRIVATE KEY-----', '')
      .replace(/\s/g, '');
    
    console.log(`📏 طول محتوى المفتاح: ${keyContent.length} حرف`);
    
    if (keyContent.length < 1000) {
      console.log('⚠️ المفتاح قصير جداً - قد يكون غير صحيح');
    } else {
      console.log('✅ طول المفتاح مناسب');
    }
  }
  
  // فحص private_key_id
  if (parsedAccount.private_key_id !== 'ce43ffe8abd4ffc11eaae853291526b3e11ccbc6') {
    console.log(`⚠️ private_key_id غير متطابق: ${parsedAccount.private_key_id}`);
    console.log('   المتوقع: ce43ffe8abd4ffc11eaae853291526b3e11ccbc6');
  } else {
    console.log('✅ private_key_id صحيح');
  }
  
  return true;
}

/**
 * فحص إمكانية تهيئة Firebase
 */
async function testFirebaseInitialization() {
  console.log('\n🔄 فحص 5: اختبار تهيئة Firebase...');
  
  try {
    const admin = require('firebase-admin');
    
    // إذا كان Firebase مهيأ مسبقاً، احذف التطبيق
    if (admin.apps.length > 0) {
      await admin.app().delete();
    }
    
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: serviceAccount.project_id
    });
    
    console.log('✅ تم تهيئة Firebase بنجاح');
    
    // اختبار إنشاء messaging instance
    const messaging = admin.messaging();
    console.log('✅ تم إنشاء messaging instance بنجاح');
    
    return true;
    
  } catch (error) {
    console.log(`❌ خطأ في تهيئة Firebase: ${error.message}`);
    return false;
  }
}

/**
 * مقارنة مع ملف .env المحلي
 */
function compareWithLocalEnv() {
  console.log('\n🔄 فحص 6: مقارنة مع ملف .env المحلي...');
  
  const localProjectId = process.env.FIREBASE_PROJECT_ID;
  const localClientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  
  if (!localProjectId || !localClientEmail) {
    console.log('⚠️ متغيرات Firebase المحلية غير موجودة في .env');
    return;
  }
  
  const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  
  if (serviceAccount.project_id !== localProjectId) {
    console.log(`⚠️ project_id مختلف بين Render والمحلي:`);
    console.log(`   Render: ${serviceAccount.project_id}`);
    console.log(`   محلي: ${localProjectId}`);
  } else {
    console.log('✅ project_id متطابق بين Render والمحلي');
  }
  
  if (serviceAccount.client_email !== localClientEmail) {
    console.log(`⚠️ client_email مختلف بين Render والمحلي:`);
    console.log(`   Render: ${serviceAccount.client_email}`);
    console.log(`   محلي: ${localClientEmail}`);
  } else {
    console.log('✅ client_email متطابق بين Render والمحلي');
  }
}

/**
 * فحص المتغيرات المطلوبة للإشعارات
 */
function checkNotificationRequirements() {
  console.log('\n🔄 فحص 7: التحقق من متغيرات الإشعارات...');
  
  const requiredVars = [
    'SUPABASE_URL',
    'SUPABASE_SERVICE_ROLE_KEY',
    'TELEGRAM_BOT_TOKEN',
    'TELEGRAM_CHAT_ID'
  ];
  
  let allPresent = true;
  
  for (const varName of requiredVars) {
    if (!process.env[varName]) {
      console.log(`❌ متغير مفقود: ${varName}`);
      allPresent = false;
    } else {
      console.log(`✅ ${varName}: موجود`);
    }
  }
  
  return allPresent;
}

/**
 * تشغيل جميع الفحوصات
 */
async function runAllChecks() {
  console.log('🚀 بدء الفحص الشامل...\n');
  
  const results = {
    serviceAccount: validateFirebaseServiceAccount(),
    notificationVars: checkNotificationRequirements()
  };
  
  if (results.serviceAccount) {
    compareWithLocalEnv();
    results.firebaseInit = await testFirebaseInitialization();
  }
  
  // النتيجة النهائية
  console.log('\n' + '=' * 60);
  console.log('📊 ملخص النتائج:');
  console.log('=' * 60);
  
  console.log(`🔥 Firebase Service Account: ${results.serviceAccount ? '✅ صحيح' : '❌ خطأ'}`);
  console.log(`🔔 متغيرات الإشعارات: ${results.notificationVars ? '✅ مكتملة' : '❌ ناقصة'}`);
  
  if (results.firebaseInit !== undefined) {
    console.log(`🚀 تهيئة Firebase: ${results.firebaseInit ? '✅ نجحت' : '❌ فشلت'}`);
  }
  
  const allGood = results.serviceAccount && results.notificationVars && 
                  (results.firebaseInit === undefined || results.firebaseInit);
  
  console.log('\n' + '=' * 60);
  if (allGood) {
    console.log('🎉 جميع الفحوصات نجحت! الإشعارات ستعمل بشكل صحيح');
  } else {
    console.log('⚠️ يوجد مشاكل تحتاج إلى إصلاح');
  }
  console.log('=' * 60);
}

// تشغيل الفحص
runAllChecks().catch(console.error);
