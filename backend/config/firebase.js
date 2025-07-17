// إعداد Firebase Admin SDK للإنتاج
const admin = require('firebase-admin');

class FirebaseConfig {
  constructor() {
    this.initialized = false;
    this.app = null;
  }

  /**
   * تهيئة Firebase Admin SDK
   * يدعم طريقتين:
   * 1. Environment Variables (الطريقة الآمنة للإنتاج)
   * 2. Service Account File (للتطوير المحلي فقط)
   */
  async initialize() {
    try {
      // تجنب التهيئة المتكررة
      if (this.initialized && admin.apps.length > 0) {
        console.log('✅ Firebase Admin SDK مهيأ مسبقاً');
        return this.app;
      }

      console.log('🔥 بدء تهيئة Firebase Admin SDK...');

      let serviceAccount = null;
      let initMethod = '';

      // الطريقة 1: استخدام Environment Variables (الأولوية)
      if (this.hasEnvironmentVariables()) {
        serviceAccount = this.getServiceAccountFromEnv();
        initMethod = 'Environment Variables (Production)';
        console.log('✅ استخدام Environment Variables');
      }
      // الطريقة 2: استخدام ملف Service Account (للتطوير المحلي)
      else if (this.hasServiceAccountFile()) {
        serviceAccount = this.getServiceAccountFromFile();
        initMethod = 'Service Account File (Development)';
        console.log('✅ استخدام Service Account File');
      }
      else {
        throw new Error('لا توجد بيانات Firebase صحيحة');
      }

      // تهيئة Firebase Admin
      this.app = admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: serviceAccount.project_id || serviceAccount.projectId
      });

      this.initialized = true;
      console.log('✅ تم تهيئة Firebase Admin SDK بنجاح');
      console.log(`📋 طريقة التهيئة: ${initMethod}`);
      console.log(`📋 Project ID: ${serviceAccount.project_id || serviceAccount.projectId}`);

      return this.app;

    } catch (error) {
      console.error('❌ خطأ في تهيئة Firebase Admin SDK:', error.message);
      this.initialized = false;
      throw error;
    }
  }

  /**
   * التحقق من وجود Environment Variables
   */
  hasEnvironmentVariables() {
    return !!(
      process.env.FIREBASE_PROJECT_ID &&
      process.env.FIREBASE_PRIVATE_KEY &&
      process.env.FIREBASE_CLIENT_EMAIL
    );
  }

  /**
   * الحصول على Service Account من Environment Variables
   */
  getServiceAccountFromEnv() {
    const projectId = process.env.FIREBASE_PROJECT_ID;
    const privateKey = process.env.FIREBASE_PRIVATE_KEY;
    const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;

    // تنظيف المفتاح الخاص (إزالة escape characters)
    const cleanPrivateKey = privateKey.replace(/\\n/g, '\n');

    return {
      project_id: projectId,
      private_key: cleanPrivateKey,
      client_email: clientEmail,
      type: 'service_account'
    };
  }

  /**
   * التحقق من وجود ملف Service Account
   */
  hasServiceAccountFile() {
    try {
      require.resolve('../firebase-service-account.json');
      return true;
    } catch {
      return false;
    }
  }

  /**
   * الحصول على Service Account من الملف
   */
  getServiceAccountFromFile() {
    try {
      const serviceAccount = require('../firebase-service-account.json');
      
      // التحقق من صحة البيانات
      if (!serviceAccount.project_id || !serviceAccount.private_key || !serviceAccount.client_email) {
        throw new Error('ملف Service Account ناقص أو غير صحيح');
      }

      return serviceAccount;
    } catch (error) {
      throw new Error(`فشل في قراءة ملف Service Account: ${error.message}`);
    }
  }

  /**
   * الحصول على Firebase App المهيأ
   */
  getApp() {
    if (!this.initialized || !this.app) {
      throw new Error('Firebase Admin SDK غير مهيأ. استخدم initialize() أولاً');
    }
    return this.app;
  }

  /**
   * إرسال إشعار FCM
   */
  async sendNotification(token, title, body, data = {}) {
    try {
      if (!this.initialized) {
        await this.initialize();
      }

      const message = {
        notification: {
          title: title,
          body: body
        },
        data: data,
        token: token
      };

      const response = await admin.messaging().send(message);
      console.log('✅ تم إرسال الإشعار بنجاح:', response);
      return response;

    } catch (error) {
      console.error('❌ خطأ في إرسال الإشعار:', error.message);
      throw error;
    }
  }

  /**
   * إرسال إشعار لعدة أجهزة
   */
  async sendMulticastNotification(tokens, title, body, data = {}) {
    try {
      if (!this.initialized) {
        await this.initialize();
      }

      const message = {
        notification: {
          title: title,
          body: body
        },
        data: data,
        tokens: tokens
      };

      const response = await admin.messaging().sendMulticast(message);
      console.log(`✅ تم إرسال ${response.successCount} إشعار من أصل ${tokens.length}`);
      
      if (response.failureCount > 0) {
        console.log(`⚠️ فشل في إرسال ${response.failureCount} إشعار`);
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            console.log(`❌ فشل الإشعار ${idx}: ${resp.error.message}`);
          }
        });
      }

      return response;

    } catch (error) {
      console.error('❌ خطأ في إرسال الإشعارات المتعددة:', error.message);
      throw error;
    }
  }
}

// إنشاء instance واحد للاستخدام في التطبيق
const firebaseConfig = new FirebaseConfig();

module.exports = {
  firebaseConfig,
  admin
};
