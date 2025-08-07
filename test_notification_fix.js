// ===================================
// اختبار إصلاح الإشعارات - تشخيص شامل
// ===================================

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

async function testNotificationSystem() {
  console.log('🔍 بدء تشخيص نظام الإشعارات...');
  console.log('=====================================\n');

  // 1. فحص متغيرات البيئة
  console.log('1️⃣ فحص متغيرات البيئة...');
  
  const requiredVars = [
    'SUPABASE_URL',
    'SUPABASE_SERVICE_ROLE_KEY',
    'FIREBASE_SERVICE_ACCOUNT'
  ];

  let allVarsPresent = true;
  for (const varName of requiredVars) {
    if (process.env[varName]) {
      console.log(`   ✅ ${varName}: موجود`);
    } else {
      console.log(`   ❌ ${varName}: مفقود`);
      allVarsPresent = false;
    }
  }

  if (!allVarsPresent) {
    console.log('\n❌ بعض متغيرات البيئة مفقودة!');
    return;
  }

  // 2. اختبار Firebase
  console.log('\n2️⃣ اختبار Firebase Admin SDK...');
  
  try {
    const admin = require('firebase-admin');
    
    // حذف التهيئة السابقة
    if (admin.apps.length > 0) {
      admin.apps.forEach(app => app.delete());
    }

    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: serviceAccount.project_id
    });

    console.log('   ✅ Firebase Admin SDK مُهيأ بنجاح');
    console.log(`   📋 Project ID: ${serviceAccount.project_id}`);
    console.log(`   📧 Client Email: ${serviceAccount.client_email}`);

  } catch (error) {
    console.log(`   ❌ خطأ في Firebase: ${error.message}`);
    return;
  }

  // 3. اختبار Supabase
  console.log('\n3️⃣ اختبار اتصال Supabase...');
  
  try {
    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    // اختبار الاتصال
    const { data, error } = await supabase
      .from('orders')
      .select('id')
      .limit(1);

    if (error) {
      console.log(`   ❌ خطأ في Supabase: ${error.message}`);
      return;
    }

    console.log('   ✅ اتصال Supabase يعمل بنجاح');

  } catch (error) {
    console.log(`   ❌ خطأ في اتصال Supabase: ${error.message}`);
    return;
  }

  // 4. فحص جدول FCM Tokens
  console.log('\n4️⃣ فحص جدول FCM Tokens...');
  
  try {
    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    const { data: tokens, error } = await supabase
      .from('fcm_tokens')
      .select('*')
      .eq('is_active', true)
      .limit(5);

    if (error) {
      console.log(`   ❌ خطأ في جدول FCM Tokens: ${error.message}`);
      console.log('   💡 قد تحتاج لإنشاء الجدول أولاً');
      return;
    }

    console.log(`   ✅ جدول FCM Tokens موجود`);
    console.log(`   📊 عدد الرموز النشطة: ${tokens.length}`);

    if (tokens.length > 0) {
      console.log('   📱 أمثلة على الرموز:');
      tokens.forEach((token, index) => {
        console.log(`      ${index + 1}. المستخدم: ${token.user_phone}`);
        console.log(`         الرمز: ${token.fcm_token.substring(0, 20)}...`);
      });
    } else {
      console.log('   ⚠️ لا توجد رموز FCM مسجلة');
      console.log('   💡 تأكد من أن المستخدمين سجلوا في التطبيق');
    }

  } catch (error) {
    console.log(`   ❌ خطأ في فحص FCM Tokens: ${error.message}`);
    return;
  }

  // 5. اختبار خدمة الإشعارات
  console.log('\n5️⃣ اختبار خدمة الإشعارات...');
  
  try {
    const targetedNotificationService = require('./backend/services/targeted_notification_service');
    
    const initialized = await targetedNotificationService.initialize();
    
    if (initialized) {
      console.log('   ✅ خدمة الإشعارات المستهدفة مُهيأة بنجاح');
    } else {
      console.log('   ❌ فشل في تهيئة خدمة الإشعارات المستهدفة');
      return;
    }

  } catch (error) {
    console.log(`   ❌ خطأ في خدمة الإشعارات: ${error.message}`);
    return;
  }

  // 6. اختبار إرسال إشعار تجريبي
  console.log('\n6️⃣ اختبار إرسال إشعار تجريبي...');
  
  try {
    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    // البحث عن رمز FCM نشط
    const { data: activeTokens, error } = await supabase
      .from('fcm_tokens')
      .select('*')
      .eq('is_active', true)
      .limit(1);

    if (error || !activeTokens || activeTokens.length === 0) {
      console.log('   ⚠️ لا توجد رموز FCM نشطة للاختبار');
      console.log('   💡 سجل دخول في التطبيق أولاً لإنشاء رمز FCM');
    } else {
      const testToken = activeTokens[0];
      console.log(`   📱 اختبار الإرسال للمستخدم: ${testToken.user_phone}`);
      
      const admin = require('firebase-admin');
      const message = {
        token: testToken.fcm_token,
        notification: {
          title: '🔧 اختبار الإشعارات',
          body: 'تم إصلاح نظام الإشعارات بنجاح! 🎉'
        },
        data: {
          type: 'test',
          timestamp: new Date().toISOString()
        }
      };

      const response = await admin.messaging().send(message);
      console.log(`   ✅ تم إرسال الإشعار التجريبي بنجاح: ${response}`);
    }

  } catch (error) {
    console.log(`   ❌ خطأ في إرسال الإشعار التجريبي: ${error.message}`);
  }

  // 7. النتيجة النهائية
  console.log('\n=====================================');
  console.log('🎉 تم الانتهاء من تشخيص نظام الإشعارات');
  console.log('=====================================');
  
  console.log('\n📋 ملخص النتائج:');
  console.log('✅ متغيرات البيئة: موجودة');
  console.log('✅ Firebase Admin SDK: يعمل');
  console.log('✅ Supabase: متصل');
  console.log('✅ جدول FCM Tokens: موجود');
  console.log('✅ خدمة الإشعارات: مُهيأة');
  
  console.log('\n🚀 الخطوات التالية:');
  console.log('1. تأكد من أن المستخدمين سجلوا دخول في التطبيق');
  console.log('2. اختبر تحديث حالة طلب من لوحة التحكم');
  console.log('3. تحقق من وصول الإشعار للهاتف');
  
  console.log('\n💡 إذا لم تصل الإشعارات:');
  console.log('- تحقق من إعدادات الإشعارات في الهاتف');
  console.log('- تأكد من أن التطبيق لديه أذونات الإشعارات');
  console.log('- جرب إعادة تسجيل الدخول في التطبيق');
}

// تشغيل الاختبار
testNotificationSystem().catch(error => {
  console.error('❌ خطأ في تشغيل الاختبار:', error);
  process.exit(1);
});
