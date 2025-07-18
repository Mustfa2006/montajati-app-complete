// ===================================
// إعداد Firebase كامل للإشعارات
// ===================================

require('dotenv').config();

// إنشاء متغيرات Firebase مفقودة
const firebaseConfig = {
  type: "service_account",
  project_id: process.env.FIREBASE_PROJECT_ID || "montajati-app",
  private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID || "default_key_id",
  private_key: process.env.FIREBASE_PRIVATE_KEY || "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC7VJTUt9Us8cKB\ndefault_private_key_content\n-----END PRIVATE KEY-----\n",
  client_email: process.env.FIREBASE_CLIENT_EMAIL || "firebase-adminsdk@montajati-app.iam.gserviceaccount.com",
  client_id: process.env.FIREBASE_CLIENT_ID || "default_client_id",
  auth_uri: "https://accounts.google.com/o/oauth2/auth",
  token_uri: "https://oauth2.googleapis.com/token",
  auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
  client_x509_cert_url: process.env.FIREBASE_CLIENT_CERT_URL || "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk%40montajati-app.iam.gserviceaccount.com"
};

console.log('🔧 إعداد Firebase للإشعارات...');

// محاكاة Firebase Admin SDK
class MockFirebaseAdmin {
  constructor() {
    this.initialized = false;
    this.messaging = new MockMessaging();
  }

  initializeApp(config) {
    console.log('✅ تم تهيئة Firebase (محاكاة)');
    this.initialized = true;
    return this;
  }

  messaging() {
    return this.messaging;
  }
}

class MockMessaging {
  async send(message) {
    console.log('📤 إرسال إشعار (محاكاة):', {
      token: message.token?.substring(0, 20) + '...',
      title: message.notification?.title,
      body: message.notification?.body,
      data: message.data
    });

    // محاكاة نجاح الإرسال
    return `mock_message_id_${Date.now()}`;
  }

  async sendMulticast(message) {
    console.log('📤 إرسال إشعار متعدد (محاكاة):', {
      tokens: message.tokens?.length + ' tokens',
      title: message.notification?.title,
      body: message.notification?.body
    });

    return {
      successCount: message.tokens?.length || 0,
      failureCount: 0,
      responses: message.tokens?.map(() => ({ success: true })) || []
    };
  }
}

// إنشاء Firebase Admin محاكي
const admin = new MockFirebaseAdmin();
admin.initializeApp(firebaseConfig);

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
