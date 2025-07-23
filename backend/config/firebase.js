// ===================================
// إعداد Firebase للإشعارات
// ===================================

const admin = require('firebase-admin');
require('dotenv').config();

let firebaseApp = null;

function initializeFirebase() {
  try {
    // التحقق من وجود المتغيرات المطلوبة
    if (!process.env.FIREBASE_PROJECT_ID || 
        !process.env.FIREBASE_PRIVATE_KEY || 
        !process.env.FIREBASE_CLIENT_EMAIL) {
      console.warn('⚠️ تحذير: متغيرات Firebase غير مكتملة، سيتم تخطي تهيئة Firebase');
      return null;
    }

    // تنظيف المفتاح الخاص
    const privateKey = process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n');

    const serviceAccount = {
      type: "service_account",
      project_id: process.env.FIREBASE_PROJECT_ID,
      private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
      private_key: privateKey,
      client_email: process.env.FIREBASE_CLIENT_EMAIL,
      client_id: process.env.FIREBASE_CLIENT_ID,
      auth_uri: "https://accounts.google.com/o/oauth2/auth",
      token_uri: "https://oauth2.googleapis.com/token",
      auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
      client_x509_cert_url: `https://www.googleapis.com/robot/v1/metadata/x509/${process.env.FIREBASE_CLIENT_EMAIL}`
    };

    // تهيئة Firebase Admin SDK
    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: process.env.FIREBASE_PROJECT_ID
    });

    console.log('✅ تم تهيئة Firebase بنجاح');
    return firebaseApp;

  } catch (error) {
    console.warn('⚠️ تحذير: فشل في تهيئة Firebase:', error.message);
    return null;
  }
}

// تهيئة Firebase عند تحميل الملف
firebaseApp = initializeFirebase();

module.exports = {
  admin: firebaseApp ? admin : null,
  app: firebaseApp,
  isInitialized: () => firebaseApp !== null
};
