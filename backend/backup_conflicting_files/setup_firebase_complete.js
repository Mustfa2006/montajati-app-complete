// ===================================
// إعداد Firebase الحقيقي للإشعارات
// ===================================

require('dotenv').config();
const admin = require('firebase-admin');

// استخراج إعدادات Firebase من متغير البيئة
let firebaseConfig;
try {
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    firebaseConfig = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    console.log('✅ تم تحميل إعدادات Firebase من FIREBASE_SERVICE_ACCOUNT');
  } else {
    throw new Error('FIREBASE_SERVICE_ACCOUNT غير موجود');
  }
} catch (error) {
  console.error('❌ خطأ في تحميل إعدادات Firebase:', error.message);
  process.exit(1);
}

console.log('🔧 إعداد Firebase الحقيقي للإشعارات...');

// تهيئة Firebase Admin SDK الحقيقي
let firebaseApp;
try {
  // التحقق من عدم وجود تطبيق Firebase مهيأ مسبقاً
  if (admin.apps.length === 0) {
    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert(firebaseConfig),
      projectId: firebaseConfig.project_id
    });
    console.log('✅ تم تهيئة Firebase Admin SDK بنجاح');
    console.log(`📱 Project ID: ${firebaseConfig.project_id}`);
  } else {
    firebaseApp = admin.apps[0];
    console.log('✅ Firebase Admin SDK مهيأ مسبقاً');
  }
} catch (error) {
  console.error('❌ خطأ في تهيئة Firebase Admin SDK:', error.message);
  process.exit(1);
}

// تصدير للاستخدام في الخدمات الأخرى
module.exports = {
  admin,
  firebaseConfig,
  
  // دالة مساعدة لإرسال الإشعارات
  async sendNotification(token, title, body, data = {}) {
    try {
      const message = {
        token: token,
        notification: {
          title: title,
          body: body
        },
        data: data,
        android: {
          priority: 'high',
          notification: {
            channelId: 'montajati_notifications',
            sound: 'default',
            vibrationPattern: [1000, 500, 1000]
          }
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1
            }
          }
        }
      };

      const response = await admin.messaging().send(message);
      console.log('✅ تم إرسال الإشعار بنجاح:', response);
      
      return { success: true, messageId: response };

    } catch (error) {
      console.error('❌ خطأ في إرسال الإشعار:', error.message);
      return { success: false, error: error.message };
    }
  },

  // دالة مساعدة لإرسال إشعارات متعددة
  async sendMulticastNotification(tokens, title, body, data = {}) {
    try {
      const message = {
        tokens: tokens,
        notification: {
          title: title,
          body: body
        },
        data: data,
        android: {
          priority: 'high',
          notification: {
            channelId: 'montajati_notifications',
            sound: 'default'
          }
        }
      };

      const response = await admin.messaging().sendMulticast(message);
      console.log(`✅ تم إرسال ${response.successCount} إشعار من أصل ${tokens.length}`);
      
      return { 
        success: true, 
        successCount: response.successCount,
        failureCount: response.failureCount
      };

    } catch (error) {
      console.error('❌ خطأ في إرسال الإشعارات المتعددة:', error.message);
      return { success: false, error: error.message };
    }
  }
};

console.log('🎉 تم إعداد Firebase بنجاح (وضع المحاكاة)');
console.log('💡 لاستخدام Firebase الحقيقي، أضف متغيرات البيئة الصحيحة في .env');
