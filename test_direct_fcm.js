const admin = require('./backend/node_modules/firebase-admin');
require('./backend/node_modules/dotenv').config();

async function testDirectFCM() {
  try {
    console.log('🔥 اختبار إرسال FCM مباشرة...');
    
    // تهيئة Firebase
    if (admin.apps.length === 0) {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: serviceAccount.project_id
      });
    }

    const fcmToken = 'eVoyF0NzSqiOqbncW5OMaG:APA91bGDdl8PLKUq4hgZQczo1wYN1gCwj5VRP4u-RsvoOd-7gkbJj76Ms2bDWZJeF1_gGYRg0BBvGqP6sf9NgvrnWkQbcJ-KLYN960iWFgZRwAqKlIE4gmk';

    const message = {
      token: fcmToken,
      notification: {
        title: '🔔 اختبار إشعار مباشر',
        body: 'هذا اختبار لإرسال إشعار مباشر من الخادم'
      },
      data: {
        type: 'test',
        timestamp: new Date().toISOString()
      }
    };

    console.log('📤 إرسال الإشعار...');
    const response = await admin.messaging().send(message);
    console.log('✅ تم إرسال الإشعار بنجاح!');
    console.log('📊 Message ID:', response);
    
  } catch (error) {
    console.error('❌ خطأ في إرسال الإشعار:');
    console.error('📊 كود الخطأ:', error.code);
    console.error('📊 رسالة الخطأ:', error.message);
    
    if (error.code === 'messaging/registration-token-not-registered') {
      console.log('🔍 FCM Token غير مسجل أو منتهي الصلاحية');
    } else if (error.code === 'messaging/invalid-registration-token') {
      console.log('🔍 FCM Token غير صحيح');
    }
  }
}

testDirectFCM();
