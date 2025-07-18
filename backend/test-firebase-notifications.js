#!/usr/bin/env node

/**
 * اختبار إرسال إشعار Firebase تجريبي
 * للتأكد من أن Firebase يعمل بشكل صحيح
 */

console.log('🧪 اختبار إرسال إشعار Firebase...\n');

// تحميل dotenv
require('dotenv').config();

async function testFirebaseNotification() {
  try {
    // تهيئة Firebase
    const admin = require('firebase-admin');
    
    // حذف التهيئة السابقة إن وجدت
    if (admin.apps.length > 0) {
      admin.apps.forEach(app => app.delete());
    }
    
    let serviceAccount = null;
    
    // محاولة استخدام FIREBASE_SERVICE_ACCOUNT أولاً
    const serviceAccountEnv = process.env.FIREBASE_SERVICE_ACCOUNT;
    if (serviceAccountEnv) {
      console.log('🔄 استخدام FIREBASE_SERVICE_ACCOUNT...');
      try {
        serviceAccount = JSON.parse(serviceAccountEnv);
        console.log('✅ تم تحليل FIREBASE_SERVICE_ACCOUNT بنجاح');
      } catch (error) {
        console.log('❌ خطأ في تحليل FIREBASE_SERVICE_ACCOUNT:', error.message);
      }
    }
    
    // إذا لم يتم العثور على FIREBASE_SERVICE_ACCOUNT، استخدم المتغيرات المنفصلة
    if (!serviceAccount) {
      const projectId = process.env.FIREBASE_PROJECT_ID;
      const privateKey = process.env.FIREBASE_PRIVATE_KEY;
      const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
      
      if (projectId && privateKey && clientEmail) {
        console.log('🔄 استخدام المتغيرات المنفصلة...');
        serviceAccount = {
          type: "service_account",
          project_id: projectId,
          private_key: privateKey,
          client_email: clientEmail,
        };
      }
    }
    
    if (!serviceAccount) {
      throw new Error('لا توجد بيانات Firebase صحيحة');
    }
    
    // تهيئة Firebase Admin
    console.log('🔥 تهيئة Firebase Admin SDK...');
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: serviceAccount.project_id
    });
    
    console.log('✅ تم تهيئة Firebase بنجاح!');
    console.log(`📋 Project ID: ${serviceAccount.project_id}`);
    console.log(`📧 Client Email: ${serviceAccount.client_email}`);
    
    // الحصول على خدمة Messaging
    const messaging = admin.messaging();
    console.log('✅ تم الحصول على خدمة Firebase Messaging');
    
    // إنشاء رسالة تجريبية (لن يتم إرسالها فعلياً)
    const testMessage = {
      notification: {
        title: 'اختبار Firebase',
        body: 'هذه رسالة اختبار من خادم منتجاتي'
      },
      topic: 'test-topic'
    };
    
    console.log('📱 تم إنشاء رسالة اختبار بنجاح');
    console.log('🎉 Firebase جاهز لإرسال الإشعارات!');
    
    // معلومات إضافية
    console.log('\n📊 معلومات Firebase:');
    console.log(`🔑 Project ID: ${serviceAccount.project_id}`);
    console.log(`📧 Service Account: ${serviceAccount.client_email}`);
    console.log(`🔐 Private Key: ${serviceAccount.private_key ? 'موجود' : 'مفقود'}`);
    
    return true;
    
  } catch (error) {
    console.log('❌ فشل في اختبار Firebase:');
    console.log(`   النوع: ${error.constructor.name}`);
    console.log(`   الرسالة: ${error.message}`);
    if (error.code) {
      console.log(`   الكود: ${error.code}`);
    }
    return false;
  }
}

// تشغيل الاختبار
testFirebaseNotification().then(success => {
  if (success) {
    console.log('\n🎉 اختبار Firebase نجح بالكامل!');
    console.log('✅ يمكن الآن إرسال الإشعارات للمستخدمين');
  } else {
    console.log('\n❌ فشل اختبار Firebase');
    console.log('💡 تحقق من متغيرات البيئة في Render');
  }
  
  console.log('\n🏁 انتهى الاختبار');
  process.exit(success ? 0 : 1);
});
