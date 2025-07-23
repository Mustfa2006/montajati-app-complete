// ===================================
// فحص جميع متغيرات الإشعارات
// ===================================

require('dotenv').config();

console.log('🔔 فحص جميع متغيرات الإشعارات');
console.log('='.repeat(60));

/**
 * فحص متغيرات Supabase
 */
function checkSupabaseVars() {
  console.log('\n🗄️ فحص متغيرات Supabase...');
  
  const supabaseVars = {
    'SUPABASE_URL': process.env.SUPABASE_URL,
    'SUPABASE_SERVICE_ROLE_KEY': process.env.SUPABASE_SERVICE_ROLE_KEY,
    'DATABASE_URL': process.env.DATABASE_URL
  };
  
  let allPresent = true;
  
  for (const [varName, value] of Object.entries(supabaseVars)) {
    if (!value) {
      console.log(`❌ ${varName}: مفقود`);
      allPresent = false;
    } else {
      console.log(`✅ ${varName}: موجود (${value.length} حرف)`);
    }
  }
  
  return allPresent;
}

/**
 * فحص متغيرات Firebase
 */
function checkFirebaseVars() {
  console.log('\n🔥 فحص متغيرات Firebase...');
  
  const firebaseServiceAccount = process.env.FIREBASE_SERVICE_ACCOUNT;
  
  if (!firebaseServiceAccount) {
    console.log('❌ FIREBASE_SERVICE_ACCOUNT: مفقود');
    return false;
  }
  
  console.log(`✅ FIREBASE_SERVICE_ACCOUNT: موجود (${firebaseServiceAccount.length} حرف)`);
  
  // محاولة تحليل JSON
  try {
    const parsed = JSON.parse(firebaseServiceAccount);
    console.log(`   🆔 Project ID: ${parsed.project_id}`);
    console.log(`   📧 Client Email: ${parsed.client_email}`);
    console.log(`   🔑 Private Key ID: ${parsed.private_key_id}`);
    
    // فحص المفتاح الخاص
    if (parsed.private_key && parsed.private_key.length > 100) {
      console.log('   🔐 Private Key: موجود');
    } else {
      console.log('   ❌ Private Key: مفقود أو قصير');
      return false;
    }
    
    return true;
    
  } catch (error) {
    console.log(`   ❌ خطأ في تحليل JSON: ${error.message}`);
    return false;
  }
}

/**
 * فحص متغيرات Telegram
 */
function checkTelegramVars() {
  console.log('\n📱 فحص متغيرات Telegram...');
  
  const telegramVars = {
    'TELEGRAM_BOT_TOKEN': process.env.TELEGRAM_BOT_TOKEN,
    'TELEGRAM_CHAT_ID': process.env.TELEGRAM_CHAT_ID,
    'TELEGRAM_NOTIFICATIONS_ENABLED': process.env.TELEGRAM_NOTIFICATIONS_ENABLED
  };
  
  let allPresent = true;
  
  for (const [varName, value] of Object.entries(telegramVars)) {
    if (!value) {
      console.log(`❌ ${varName}: مفقود`);
      if (varName !== 'TELEGRAM_NOTIFICATIONS_ENABLED') {
        allPresent = false;
      }
    } else {
      console.log(`✅ ${varName}: موجود`);
      
      // فحص إضافي للتوكن
      if (varName === 'TELEGRAM_BOT_TOKEN' && !value.includes(':')) {
        console.log('   ⚠️ تنسيق التوكن قد يكون خاطئ (يجب أن يحتوي على :)');
      }
      
      // فحص إضافي لمعرف المجموعة
      if (varName === 'TELEGRAM_CHAT_ID' && !value.startsWith('-')) {
        console.log('   ⚠️ معرف المجموعة يجب أن يبدأ بـ -');
      }
    }
  }
  
  return allPresent;
}

/**
 * فحص متغيرات أخرى مهمة
 */
function checkOtherVars() {
  console.log('\n⚙️ فحص متغيرات أخرى مهمة...');
  
  const otherVars = {
    'JWT_SECRET': process.env.JWT_SECRET,
    'NODE_ENV': process.env.NODE_ENV,
    'PORT': process.env.PORT
  };
  
  let allPresent = true;
  
  for (const [varName, value] of Object.entries(otherVars)) {
    if (!value) {
      console.log(`❌ ${varName}: مفقود`);
      allPresent = false;
    } else {
      console.log(`✅ ${varName}: ${value}`);
    }
  }
  
  return allPresent;
}

/**
 * اختبار اتصال Firebase
 */
async function testFirebaseConnection() {
  console.log('\n🔥 اختبار اتصال Firebase...');
  
  if (!process.env.FIREBASE_SERVICE_ACCOUNT) {
    console.log('❌ لا يمكن اختبار Firebase - المتغير مفقود');
    return false;
  }
  
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
    
    const messaging = admin.messaging();
    console.log('✅ Firebase يعمل بشكل صحيح');
    
    return true;
    
  } catch (error) {
    console.log(`❌ خطأ في Firebase: ${error.message}`);
    
    if (error.message.includes('private key')) {
      console.log('💡 الحل: تحديث المفتاح الخاص في Firebase Console');
    }
    
    return false;
  }
}

/**
 * تشغيل جميع الفحوصات
 */
async function runAllChecks() {
  console.log('🚀 بدء فحص جميع متغيرات الإشعارات...\n');
  
  const results = {
    supabase: checkSupabaseVars(),
    firebase: checkFirebaseVars(),
    telegram: checkTelegramVars(),
    other: checkOtherVars()
  };
  
  // اختبار Firebase إذا كان المتغير موجود
  if (results.firebase) {
    results.firebaseConnection = await testFirebaseConnection();
  }
  
  // النتيجة النهائية
  console.log('\n' + '=' * 60);
  console.log('📊 ملخص النتائج:');
  console.log('=' * 60);
  
  console.log(`🗄️ Supabase: ${results.supabase ? '✅ مكتمل' : '❌ ناقص'}`);
  console.log(`🔥 Firebase (متغيرات): ${results.firebase ? '✅ مكتمل' : '❌ ناقص'}`);
  console.log(`📱 Telegram: ${results.telegram ? '✅ مكتمل' : '❌ ناقص'}`);
  console.log(`⚙️ متغيرات أخرى: ${results.other ? '✅ مكتمل' : '❌ ناقص'}`);
  
  if (results.firebaseConnection !== undefined) {
    console.log(`🔥 Firebase (اتصال): ${results.firebaseConnection ? '✅ يعمل' : '❌ لا يعمل'}`);
  }
  
  // تقييم عام
  const criticalVars = results.supabase && results.firebase && results.telegram;
  const firebaseWorks = results.firebaseConnection !== false;
  
  console.log('\n' + '=' * 60);
  if (criticalVars && firebaseWorks) {
    console.log('🎉 جميع متغيرات الإشعارات جاهزة!');
    console.log('✅ الإشعارات ستعمل بشكل صحيح');
  } else {
    console.log('⚠️ يوجد متغيرات ناقصة أو مشاكل');
    
    if (!criticalVars) {
      console.log('💡 أضف المتغيرات الناقصة في Render');
    }
    
    if (!firebaseWorks) {
      console.log('💡 حدث المفتاح الخاص في Firebase');
    }
  }
  console.log('=' * 60);
}

// تشغيل الفحص
runAllChecks().catch(console.error);
