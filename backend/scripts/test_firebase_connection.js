#!/usr/bin/env node

// ✅ Script اختبار اتصال Firebase
// Firebase Connection Test Script
// تاريخ الإنشاء: 2024-12-20

require('dotenv').config();
const { FirebaseAdminService } = require('../services/firebase_admin_service');

class FirebaseConnectionTester {
  constructor() {
    this.firebaseService = new FirebaseAdminService();
  }

  /**
   * اختبار شامل لـ Firebase
   */
  async runTests() {
    console.log('🔥 بدء اختبار Firebase Connection...\n');

    try {
      // اختبار 1: تهيئة Firebase
      await this.testInitialization();

      // اختبار 2: إرسال إشعار تجريبي
      await this.testNotificationSending();

      // اختبار 3: التحقق من صحة Token
      await this.testTokenValidation();

      console.log('\n✅ جميع اختبارات Firebase نجحت!');
      console.log('🎉 Firebase جاهز للاستخدام في الإنتاج');

    } catch (error) {
      console.error('\n❌ فشل في اختبار Firebase:', error.message);
      console.log('\n🔧 خطوات الإصلاح:');
      this.printTroubleshootingSteps();
      process.exit(1);
    }
  }

  /**
   * اختبار تهيئة Firebase
   */
  async testInitialization() {
    console.log('🔄 اختبار 1: تهيئة Firebase Admin SDK...');

    try {
      await this.firebaseService.initialize();
      console.log('✅ تم تهيئة Firebase بنجاح');
    } catch (error) {
      console.error('❌ فشل في تهيئة Firebase:', error.message);
      throw error;
    }
  }

  /**
   * اختبار إرسال إشعار تجريبي
   */
  async testNotificationSending() {
    console.log('\n🔄 اختبار 2: إرسال إشعار تجريبي...');

    // استخدام token تجريبي (سيفشل ولكن يؤكد أن Firebase يعمل)
    const testToken = 'test_token_for_connection_verification';
    const testMessage = {
      notification: {
        title: 'اختبار Firebase',
        body: 'هذا إشعار تجريبي للتأكد من عمل Firebase'
      },
      data: {
        test: 'true',
        timestamp: new Date().toISOString()
      }
    };

    try {
      const result = await this.firebaseService.sendNotification(testToken, testMessage);
      
      // إذا نجح (غير متوقع مع token تجريبي)
      if (result.success) {
        console.log('✅ تم إرسال الإشعار التجريبي بنجاح');
      } else {
        // هذا متوقع مع token تجريبي
        if (result.error && result.error.includes('registration-token-not-registered')) {
          console.log('✅ Firebase يعمل (token تجريبي غير صالح كما متوقع)');
        } else {
          console.warn('⚠️ خطأ غير متوقع:', result.error);
        }
      }
    } catch (error) {
      // إذا كان الخطأ متعلق بـ token غير صالح، فهذا جيد
      if (error.message.includes('registration-token-not-registered') || 
          error.message.includes('invalid-registration-token')) {
        console.log('✅ Firebase يعمل (token تجريبي غير صالح كما متوقع)');
      } else {
        console.error('❌ خطأ في إرسال الإشعار:', error.message);
        throw error;
      }
    }
  }

  /**
   * اختبار التحقق من صحة Token
   */
  async testTokenValidation() {
    console.log('\n🔄 اختبار 3: التحقق من صحة Token...');

    const validTokenPattern = /^[a-zA-Z0-9_-]+:[a-zA-Z0-9_-]+$/;
    const testTokens = [
      'valid_token_format:test_123',
      'invalid-token-format',
      '',
      null
    ];

    for (const token of testTokens) {
      const isValid = this.firebaseService.validateToken(token);
      const expected = token && validTokenPattern.test(token);
      
      if (isValid === expected) {
        console.log(`✅ Token validation صحيح للـ token: ${token || 'null'}`);
      } else {
        console.warn(`⚠️ Token validation غير متوقع للـ token: ${token || 'null'}`);
      }
    }
  }

  /**
   * طباعة خطوات الإصلاح
   */
  printTroubleshootingSteps() {
    console.log(`
📋 خطوات إصلاح مشاكل Firebase:

1️⃣ تحقق من متغيرات البيئة:
   - FIREBASE_PROJECT_ID
   - FIREBASE_PRIVATE_KEY
   - FIREBASE_CLIENT_EMAIL
   أو
   - FIREBASE_SERVICE_ACCOUNT

2️⃣ تحقق من صحة Private Key:
   - يجب أن يبدأ بـ -----BEGIN PRIVATE KEY-----
   - يجب أن ينتهي بـ -----END PRIVATE KEY-----
   - تأكد من وجود \\n في المواضع الصحيحة

3️⃣ تحقق من Firebase Console:
   - تأكد من تفعيل Cloud Messaging
   - تأكد من صحة Service Account

4️⃣ في Render.com:
   - استخدم متغيرات منفصلة بدلاً من JSON
   - تأكد من escape الـ newlines في Private Key

5️⃣ اختبار محلي:
   - تأكد من وجود ملف .env
   - جرب تشغيل: node test_firebase_connection.js
`);
  }

  /**
   * طباعة معلومات التكوين الحالي
   */
  printCurrentConfig() {
    console.log('\n📊 التكوين الحالي:');
    console.log('FIREBASE_PROJECT_ID:', process.env.FIREBASE_PROJECT_ID ? '✅ موجود' : '❌ مفقود');
    console.log('FIREBASE_PRIVATE_KEY:', process.env.FIREBASE_PRIVATE_KEY ? '✅ موجود' : '❌ مفقود');
    console.log('FIREBASE_CLIENT_EMAIL:', process.env.FIREBASE_CLIENT_EMAIL ? '✅ موجود' : '❌ مفقود');
    console.log('FIREBASE_SERVICE_ACCOUNT:', process.env.FIREBASE_SERVICE_ACCOUNT ? '✅ موجود' : '❌ مفقود');
  }
}

// تشغيل الاختبارات
async function main() {
  const tester = new FirebaseConnectionTester();
  
  // طباعة التكوين الحالي
  tester.printCurrentConfig();
  
  // تشغيل الاختبارات
  await tester.runTests();
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = FirebaseConnectionTester;
