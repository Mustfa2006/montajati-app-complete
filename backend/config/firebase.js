// إعداد Firebase Admin SDK للإنتاج
const admin = require('firebase-admin');

// تحميل متغيرات البيئة
require('dotenv').config();

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
        console.warn('⚠️ لا توجد بيانات Firebase صحيحة - سيتم تعطيل الإشعارات');
        this.initialized = false;
        return null;
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
      console.warn('⚠️ سيتم تعطيل خدمة الإشعارات');
      this.initialized = false;
      return null; // لا نرمي الخطأ لتجنب توقف النظام
    }
  }

  /**
   * التحقق من وجود Environment Variables
   */
  hasEnvironmentVariables() {
    // تحميل متغيرات البيئة مرة أخرى للتأكد
    require('dotenv').config();

    const hasVars = !!(
      process.env.FIREBASE_PROJECT_ID &&
      process.env.FIREBASE_PRIVATE_KEY &&
      process.env.FIREBASE_CLIENT_EMAIL
    );

    // فحص إضافي للـ Service Account
    const hasServiceAccount = !!(process.env.FIREBASE_SERVICE_ACCOUNT);

    if (!hasVars && hasServiceAccount) {
      console.log('🔄 محاولة استخدام FIREBASE_SERVICE_ACCOUNT...');
      try {
        const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
        if (serviceAccount.project_id && serviceAccount.private_key && serviceAccount.client_email) {
          // تعيين المتغيرات من Service Account
          process.env.FIREBASE_PROJECT_ID = serviceAccount.project_id;
          process.env.FIREBASE_PRIVATE_KEY = serviceAccount.private_key;
          process.env.FIREBASE_CLIENT_EMAIL = serviceAccount.client_email;
          console.log('✅ تم استخراج متغيرات Firebase من FIREBASE_SERVICE_ACCOUNT');
          return true;
        }
      } catch (error) {
        console.log('❌ خطأ في تحليل FIREBASE_SERVICE_ACCOUNT:', error.message);
      }
    }

    // التحقق من أن القيم ليست وهمية
    const hasValidValues = !!(
      process.env.FIREBASE_PROJECT_ID !== 'your-firebase-project-id' &&
      process.env.FIREBASE_PRIVATE_KEY !== '"-----BEGIN PRIVATE KEY-----\\nYOUR_PRIVATE_KEY_HERE\\n-----END PRIVATE KEY-----"' &&
      process.env.FIREBASE_CLIENT_EMAIL !== 'firebase-adminsdk-xxxxx@your-project-id.iam.gserviceaccount.com'
    );

    // تسجيل مفصل للتشخيص في حالة الفشل
    if (!hasVars || !hasValidValues) {
      console.log('🔍 تشخيص متغيرات Firebase:');
      console.log(`  FIREBASE_PROJECT_ID: ${process.env.FIREBASE_PROJECT_ID ? 'موجود' : 'مفقود'}`);
      console.log(`  FIREBASE_PRIVATE_KEY: ${process.env.FIREBASE_PRIVATE_KEY ? `موجود (${process.env.FIREBASE_PRIVATE_KEY.length} حرف)` : 'مفقود'}`);
      console.log(`  FIREBASE_CLIENT_EMAIL: ${process.env.FIREBASE_CLIENT_EMAIL ? 'موجود' : 'مفقود'}`);

      // فحص إضافي للـ Private Key
      if (process.env.FIREBASE_PRIVATE_KEY) {
        const key = process.env.FIREBASE_PRIVATE_KEY;
        console.log(`🔍 تفاصيل Private Key:`);
        console.log(`  - الطول: ${key.length} حرف`);
        console.log(`  - يبدأ بـ: "${key.substring(0, 30)}..."`);
        console.log(`  - ينتهي بـ: "...${key.substring(key.length - 30)}"`);
        console.log(`  - يحتوي على BEGIN: ${key.includes('BEGIN PRIVATE KEY')}`);
        console.log(`  - يحتوي على END: ${key.includes('END PRIVATE KEY')}`);
      }
    }

    return hasVars && hasValidValues;
  }

  /**
   * الحصول على Service Account من Environment Variables
   */
  getServiceAccountFromEnv() {
    const projectId = process.env.FIREBASE_PROJECT_ID;
    const privateKey = process.env.FIREBASE_PRIVATE_KEY;
    const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;

    // تنظيف المفتاح الخاص (معالجة خاصة لـ Render)
    let cleanPrivateKey = privateKey;

    // إزالة escape characters
    if (cleanPrivateKey) {
      cleanPrivateKey = cleanPrivateKey.replace(/\\n/g, '\n');

      // إضافة header و footer إذا لم يكونا موجودين
      if (!cleanPrivateKey.includes('-----BEGIN PRIVATE KEY-----')) {
        cleanPrivateKey = `-----BEGIN PRIVATE KEY-----\n${cleanPrivateKey}\n-----END PRIVATE KEY-----`;
      }

      // تنظيف إضافي للمسافات والأسطر الفارغة
      cleanPrivateKey = cleanPrivateKey
        .replace(/\s+-----BEGIN PRIVATE KEY-----/g, '-----BEGIN PRIVATE KEY-----')
        .replace(/-----END PRIVATE KEY-----\s+/g, '-----END PRIVATE KEY-----')
        .trim();
    }

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
