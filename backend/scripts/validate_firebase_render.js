#!/usr/bin/env node

// ✅ Script فحص Firebase Service Account من Render
// Firebase Render Validation Script
// تاريخ الإنشاء: 2024-12-20

require('dotenv').config();

class FirebaseRenderValidator {
  constructor() {
    this.renderServiceAccount = null;
  }

  /**
   * فحص شامل لـ Firebase Service Account من Render
   */
  async validateRenderFirebase() {
    console.log('🔍 بدء فحص Firebase Service Account من Render...\n');

    try {
      // فحص 1: التحقق من وجود FIREBASE_SERVICE_ACCOUNT
      await this.checkServiceAccountVariable();

      // فحص 2: تحليل JSON وفحص البنية
      await this.parseAndValidateJSON();

      // فحص 3: التحقق من الحقول المطلوبة
      await this.validateRequiredFields();

      // فحص 4: فحص Private Key
      await this.validatePrivateKey();

      // فحص 5: اختبار تهيئة Firebase
      await this.testFirebaseInitialization();

      console.log('\n✅ جميع فحوصات Firebase Service Account نجحت!');
      console.log('🎉 Firebase جاهز للعمل في Render');

      return true;

    } catch (error) {
      console.error('\n❌ فشل في فحص Firebase:', error.message);
      this.printTroubleshootingSteps();
      return false;
    }
  }

  /**
   * فحص وجود متغير FIREBASE_SERVICE_ACCOUNT
   */
  async checkServiceAccountVariable() {
    console.log('🔄 فحص 1: التحقق من وجود FIREBASE_SERVICE_ACCOUNT...');

    if (!process.env.FIREBASE_SERVICE_ACCOUNT) {
      throw new Error('متغير FIREBASE_SERVICE_ACCOUNT غير موجود في البيئة');
    }

    console.log('✅ متغير FIREBASE_SERVICE_ACCOUNT موجود');
    console.log(`📏 طول البيانات: ${process.env.FIREBASE_SERVICE_ACCOUNT.length} حرف`);
  }

  /**
   * تحليل JSON وفحص البنية
   */
  async parseAndValidateJSON() {
    console.log('\n🔄 فحص 2: تحليل JSON وفحص البنية...');

    try {
      this.renderServiceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      console.log('✅ تم تحليل JSON بنجاح');
      
      // فحص نوع البيانات
      if (typeof this.renderServiceAccount !== 'object') {
        throw new Error('Service Account ليس object صحيح');
      }

      console.log('✅ بنية JSON صحيحة');

    } catch (parseError) {
      throw new Error(`خطأ في تحليل JSON: ${parseError.message}`);
    }
  }

  /**
   * التحقق من الحقول المطلوبة
   */
  async validateRequiredFields() {
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

    const missingFields = [];

    for (const field of requiredFields) {
      if (!this.renderServiceAccount[field]) {
        missingFields.push(field);
      } else {
        console.log(`✅ ${field}: موجود`);
      }
    }

    if (missingFields.length > 0) {
      throw new Error(`حقول مفقودة: ${missingFields.join(', ')}`);
    }

    // فحص قيم محددة
    if (this.renderServiceAccount.type !== 'service_account') {
      throw new Error(`نوع Service Account غير صحيح: ${this.renderServiceAccount.type}`);
    }

    console.log('✅ جميع الحقول المطلوبة موجودة وصحيحة');
  }

  /**
   * فحص Private Key
   */
  async validatePrivateKey() {
    console.log('\n🔄 فحص 4: فحص Private Key...');

    const privateKey = this.renderServiceAccount.private_key;

    // فحص بداية ونهاية Private Key
    if (!privateKey.startsWith('-----BEGIN PRIVATE KEY-----')) {
      throw new Error('Private Key لا يبدأ بـ -----BEGIN PRIVATE KEY-----');
    }

    if (!privateKey.endsWith('-----END PRIVATE KEY-----')) {
      throw new Error('Private Key لا ينتهي بـ -----END PRIVATE KEY-----');
    }

    // فحص وجود أسطر جديدة
    if (!privateKey.includes('\n')) {
      console.warn('⚠️ تحذير: Private Key قد لا يحتوي على أسطر جديدة صحيحة');
    }

    // فحص طول Private Key
    const keyLength = privateKey.length;
    if (keyLength < 1600 || keyLength > 2000) {
      console.warn(`⚠️ تحذير: طول Private Key غير عادي: ${keyLength} حرف`);
    }

    console.log('✅ Private Key يبدو صحيحاً');
    console.log(`📏 طول Private Key: ${keyLength} حرف`);
  }

  /**
   * اختبار تهيئة Firebase
   */
  async testFirebaseInitialization() {
    console.log('\n🔄 فحص 5: اختبار تهيئة Firebase...');

    try {
      const admin = require('firebase-admin');

      // حذف التهيئة السابقة إن وجدت
      if (admin.apps.length > 0) {
        await Promise.all(admin.apps.map(app => app.delete()));
      }

      // تهيئة Firebase مع Service Account من Render
      admin.initializeApp({
        credential: admin.credential.cert(this.renderServiceAccount),
        projectId: this.renderServiceAccount.project_id
      });

      console.log('✅ تم تهيئة Firebase بنجاح');
      console.log(`📋 Project ID: ${this.renderServiceAccount.project_id}`);
      console.log(`📧 Client Email: ${this.renderServiceAccount.client_email}`);

      // اختبار Messaging
      const messaging = admin.messaging();
      console.log('✅ تم تهيئة Firebase Messaging بنجاح');

      // تنظيف
      await admin.app().delete();

    } catch (firebaseError) {
      throw new Error(`خطأ في تهيئة Firebase: ${firebaseError.message}`);
    }
  }

  /**
   * طباعة خطوات الإصلاح
   */
  printTroubleshootingSteps() {
    console.log(`
📋 خطوات إصلاح مشاكل Firebase في Render:

1️⃣ تحقق من Firebase Console:
   - تأكد من تفعيل Cloud Messaging API
   - تأكد من صحة Service Account

2️⃣ في Render.com:
   - تأكد من نسخ Service Account JSON كاملاً
   - تأكد من عدم وجود مسافات إضافية
   - استخدم متغير واحد FIREBASE_SERVICE_ACCOUNT

3️⃣ فحص Private Key:
   - يجب أن يبدأ بـ -----BEGIN PRIVATE KEY-----
   - يجب أن ينتهي بـ -----END PRIVATE KEY-----
   - يجب أن يحتوي على \\n للأسطر الجديدة

4️⃣ اختبار محلي:
   - جرب تشغيل: node validate_firebase_render.js
   - تأكد من عمل Firebase محلياً أولاً

5️⃣ إعادة النشر:
   - بعد تصحيح المتغيرات، أعد نشر التطبيق في Render
`);
  }

  /**
   * طباعة معلومات Service Account (بدون كشف البيانات الحساسة)
   */
  printServiceAccountInfo() {
    if (!this.renderServiceAccount) return;

    console.log('\n📊 معلومات Service Account:');
    console.log(`Project ID: ${this.renderServiceAccount.project_id}`);
    console.log(`Client Email: ${this.renderServiceAccount.client_email}`);
    console.log(`Client ID: ${this.renderServiceAccount.client_id}`);
    console.log(`Private Key ID: ${this.renderServiceAccount.private_key_id?.substring(0, 8)}...`);
    console.log(`Type: ${this.renderServiceAccount.type}`);
  }
}

// تشغيل الفحص
async function main() {
  const validator = new FirebaseRenderValidator();
  
  const isValid = await validator.validateRenderFirebase();
  
  if (isValid) {
    validator.printServiceAccountInfo();
    console.log('\n🎉 Firebase Service Account من Render صحيح ومُعد بشكل مثالي!');
  } else {
    console.log('\n❌ يحتاج Firebase Service Account إلى إصلاح');
    process.exit(1);
  }
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = FirebaseRenderValidator;
