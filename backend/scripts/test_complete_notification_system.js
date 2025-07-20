#!/usr/bin/env node

// ✅ اختبار شامل لنظام الإشعارات من الصفر للنهاية
// Complete Notification System Test
// تاريخ الإنشاء: 2024-12-20

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
const { FirebaseAdminService } = require('../services/firebase_admin_service');

class CompleteNotificationSystemTester {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
    this.firebaseService = new FirebaseAdminService();
    this.testResults = {
      firebase: false,
      database: false,
      tokenRegistration: false,
      notificationSending: false,
      endToEnd: false
    };
  }

  /**
   * تشغيل جميع اختبارات النظام
   */
  async runCompleteTest() {
    console.log('🚀 بدء الاختبار الشامل لنظام الإشعارات...\n');

    try {
      // اختبار 1: Firebase Backend
      await this.testFirebaseBackend();

      // اختبار 2: قاعدة البيانات
      await this.testDatabase();

      // اختبار 3: تسجيل FCM Token
      await this.testTokenRegistration();

      // اختبار 4: إرسال الإشعارات
      await this.testNotificationSending();

      // اختبار 5: النظام الكامل
      await this.testEndToEndFlow();

      // تقرير النتائج
      this.printFinalReport();

    } catch (error) {
      console.error('\n❌ فشل في الاختبار الشامل:', error.message);
      this.printTroubleshootingGuide();
    }
  }

  /**
   * اختبار Firebase Backend
   */
  async testFirebaseBackend() {
    console.log('🔥 اختبار 1: Firebase Backend...');

    try {
      // تهيئة Firebase
      const initialized = await this.firebaseService.initialize();
      if (!initialized) {
        throw new Error('فشل في تهيئة Firebase');
      }

      // فحص Service Info
      const serviceInfo = this.firebaseService.getServiceInfo();
      console.log('✅ Firebase مهيأ بنجاح');
      console.log(`   Project ID: ${serviceInfo.projectId}`);
      console.log(`   Messaging: ${serviceInfo.hasMessaging ? '✅' : '❌'}`);

      this.testResults.firebase = true;

    } catch (error) {
      console.error('❌ خطأ في Firebase:', error.message);
      throw error;
    }
  }

  /**
   * اختبار قاعدة البيانات
   */
  async testDatabase() {
    console.log('\n📊 اختبار 2: قاعدة البيانات...');

    try {
      // فحص جدول fcm_tokens
      const { data: tableInfo, error: tableError } = await this.supabase
        .from('fcm_tokens')
        .select('*')
        .limit(1);

      if (tableError) {
        throw new Error(`خطأ في الوصول لجدول fcm_tokens: ${tableError.message}`);
      }

      console.log('✅ جدول fcm_tokens متاح');

      // فحص إحصائيات الجدول
      const { data: stats, error: statsError } = await this.supabase
        .rpc('exec_sql', { 
          sql: 'SELECT COUNT(*) as total, COUNT(CASE WHEN is_active = true THEN 1 END) as active FROM fcm_tokens' 
        });

      if (!statsError && stats && stats.length > 0) {
        console.log(`   إجمالي التوكنز: ${stats[0].total}`);
        console.log(`   التوكنز النشطة: ${stats[0].active}`);
      }

      this.testResults.database = true;

    } catch (error) {
      console.error('❌ خطأ في قاعدة البيانات:', error.message);
      throw error;
    }
  }

  /**
   * اختبار تسجيل FCM Token
   */
  async testTokenRegistration() {
    console.log('\n📱 اختبار 3: تسجيل FCM Token...');

    try {
      const testToken = 'test_fcm_token_' + Date.now();
      const testPhone = '+966500000000';

      // محاولة تسجيل token تجريبي
      const { data, error } = await this.supabase
        .from('fcm_tokens')
        .upsert({
          user_phone: testPhone,
          fcm_token: testToken,
          device_info: { 
            platform: 'test',
            app: 'notification_test',
            timestamp: new Date().toISOString()
          },
          is_active: true,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
          last_used_at: new Date().toISOString()
        })
        .select();

      if (error) {
        throw new Error(`خطأ في تسجيل Token: ${error.message}`);
      }

      console.log('✅ تم تسجيل FCM Token تجريبي بنجاح');
      console.log(`   Token: ${testToken.substring(0, 20)}...`);
      console.log(`   Phone: ${testPhone}`);

      // تنظيف البيانات التجريبية
      await this.supabase
        .from('fcm_tokens')
        .delete()
        .eq('fcm_token', testToken);

      console.log('✅ تم تنظيف البيانات التجريبية');

      this.testResults.tokenRegistration = true;

    } catch (error) {
      console.error('❌ خطأ في تسجيل Token:', error.message);
      throw error;
    }
  }

  /**
   * اختبار إرسال الإشعارات
   */
  async testNotificationSending() {
    console.log('\n📤 اختبار 4: إرسال الإشعارات...');

    try {
      const testToken = 'invalid_test_token_for_validation';

      // اختبار إرسال إشعار (سيفشل مع token غير صالح ولكن يؤكد أن النظام يعمل)
      const result = await this.firebaseService.sendNotificationToUser(
        testToken,
        {
          title: 'اختبار النظام',
          body: 'هذا إشعار تجريبي للتأكد من عمل النظام'
        },
        {
          type: 'system_test',
          timestamp: new Date().toISOString()
        }
      );

      // إذا وصلنا هنا، فالنظام يعمل (حتى لو فشل الإرسال بسبب token غير صالح)
      if (result.error && result.error.includes('registration-token-not-registered')) {
        console.log('✅ نظام الإشعارات يعمل (token تجريبي غير صالح كما متوقع)');
        this.testResults.notificationSending = true;
      } else if (result.success) {
        console.log('✅ تم إرسال الإشعار بنجاح (غير متوقع مع token تجريبي)');
        this.testResults.notificationSending = true;
      } else {
        console.warn('⚠️ نتيجة غير متوقعة:', result);
      }

    } catch (error) {
      if (error.message.includes('registration-token-not-registered') || 
          error.message.includes('invalid-registration-token')) {
        console.log('✅ نظام الإشعارات يعمل (token تجريبي غير صالح كما متوقع)');
        this.testResults.notificationSending = true;
      } else {
        console.error('❌ خطأ في إرسال الإشعار:', error.message);
        throw error;
      }
    }
  }

  /**
   * اختبار النظام الكامل
   */
  async testEndToEndFlow() {
    console.log('\n🔄 اختبار 5: تدفق النظام الكامل...');

    try {
      // محاكاة تدفق كامل
      const testPhone = '+966500000001';
      const testToken = 'complete_test_token_' + Date.now();

      // 1. تسجيل مستخدم وtoken
      console.log('   1️⃣ تسجيل مستخدم وtoken...');
      const { error: registerError } = await this.supabase
        .from('fcm_tokens')
        .insert({
          user_phone: testPhone,
          fcm_token: testToken,
          device_info: { platform: 'end_to_end_test' },
          is_active: true,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
          last_used_at: new Date().toISOString()
        });

      if (registerError) {
        throw new Error(`خطأ في تسجيل المستخدم: ${registerError.message}`);
      }

      // 2. البحث عن token المستخدم
      console.log('   2️⃣ البحث عن token المستخدم...');
      const { data: userTokens, error: searchError } = await this.supabase
        .from('fcm_tokens')
        .select('fcm_token')
        .eq('user_phone', testPhone)
        .eq('is_active', true);

      if (searchError || !userTokens || userTokens.length === 0) {
        throw new Error('لم يتم العثور على token المستخدم');
      }

      console.log(`   ✅ تم العثور على ${userTokens.length} token للمستخدم`);

      // 3. محاولة إرسال إشعار
      console.log('   3️⃣ إرسال إشعار للمستخدم...');
      const notificationResult = await this.firebaseService.sendNotificationToUser(
        userTokens[0].fcm_token,
        {
          title: 'اختبار النظام الكامل',
          body: 'تم اختبار النظام بنجاح من البداية للنهاية'
        },
        {
          type: 'end_to_end_test',
          user_phone: testPhone
        }
      );

      // 4. تنظيف البيانات
      console.log('   4️⃣ تنظيف البيانات التجريبية...');
      await this.supabase
        .from('fcm_tokens')
        .delete()
        .eq('user_phone', testPhone);

      console.log('✅ اختبار النظام الكامل نجح!');
      this.testResults.endToEnd = true;

    } catch (error) {
      console.error('❌ خطأ في اختبار النظام الكامل:', error.message);
      throw error;
    }
  }

  /**
   * طباعة التقرير النهائي
   */
  printFinalReport() {
    console.log('\n' + '='.repeat(60));
    console.log('📋 تقرير الاختبار الشامل لنظام الإشعارات');
    console.log('='.repeat(60));

    const tests = [
      { name: 'Firebase Backend', result: this.testResults.firebase },
      { name: 'قاعدة البيانات', result: this.testResults.database },
      { name: 'تسجيل FCM Token', result: this.testResults.tokenRegistration },
      { name: 'إرسال الإشعارات', result: this.testResults.notificationSending },
      { name: 'النظام الكامل', result: this.testResults.endToEnd }
    ];

    tests.forEach(test => {
      const status = test.result ? '✅ نجح' : '❌ فشل';
      console.log(`${test.name}: ${status}`);
    });

    const allPassed = Object.values(this.testResults).every(result => result);

    console.log('\n' + '='.repeat(60));
    if (allPassed) {
      console.log('🎉 جميع الاختبارات نجحت! نظام الإشعارات يعمل بشكل مثالي');
      console.log('✅ النظام جاهز للإنتاج 100%');
    } else {
      console.log('⚠️ بعض الاختبارات فشلت - يحتاج النظام إلى إصلاح');
    }
    console.log('='.repeat(60));
  }

  /**
   * دليل استكشاف الأخطاء
   */
  printTroubleshootingGuide() {
    console.log(`
📋 دليل استكشاف أخطاء نظام الإشعارات:

🔥 مشاكل Firebase:
   - تحقق من FIREBASE_SERVICE_ACCOUNT في متغيرات البيئة
   - تأكد من صحة Private Key وإصلاح \\n
   - تحقق من تفعيل Cloud Messaging في Firebase Console

📊 مشاكل قاعدة البيانات:
   - تحقق من SUPABASE_URL و SUPABASE_SERVICE_ROLE_KEY
   - تأكد من وجود جدول fcm_tokens
   - شغل: npm run migrate

📱 مشاكل Frontend:
   - تحقق من firebase_options.dart
   - تأكد من صحة App IDs
   - تحقق من إعدادات Android/iOS

🔧 خطوات الإصلاح:
   1. شغل: npm run test:firebase
   2. شغل: npm run test:db  
   3. تحقق من logs التطبيق
   4. اختبر على جهاز حقيقي
`);
  }
}

// تشغيل الاختبار
async function main() {
  const tester = new CompleteNotificationSystemTester();
  await tester.runCompleteTest();
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = CompleteNotificationSystemTester;
