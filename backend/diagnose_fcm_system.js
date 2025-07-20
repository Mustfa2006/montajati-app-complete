// ===================================
// تشخيص شامل لنظام FCM والإشعارات
// FCM System Comprehensive Diagnosis
// ===================================

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

class FCMSystemDiagnosis {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
  }

  /**
   * تشخيص شامل للنظام
   */
  async runFullDiagnosis() {
    console.log('🔍 بدء التشخيص الشامل لنظام FCM...\n');

    // 1. فحص متغيرات البيئة
    await this.checkEnvironmentVariables();
    
    // 2. فحص قاعدة البيانات
    await this.checkDatabase();
    
    // 3. فحص جدول FCM tokens
    await this.checkFCMTokensTable();
    
    // 4. فحص المستخدمين
    await this.checkUsers();
    
    // 5. فحص Firebase
    await this.checkFirebase();
    
    // 6. اختبار إرسال إشعار
    await this.testNotificationSending();

    console.log('\n✅ انتهى التشخيص الشامل');
  }

  /**
   * فحص متغيرات البيئة
   */
  async checkEnvironmentVariables() {
    console.log('📋 فحص متغيرات البيئة...');
    
    const requiredVars = [
      'SUPABASE_URL',
      'SUPABASE_SERVICE_ROLE_KEY',
      'FIREBASE_SERVICE_ACCOUNT'
    ];

    for (const varName of requiredVars) {
      if (process.env[varName]) {
        console.log(`✅ ${varName}: موجود`);
      } else {
        console.log(`❌ ${varName}: مفقود`);
      }
    }
    console.log('');
  }

  /**
   * فحص قاعدة البيانات
   */
  async checkDatabase() {
    console.log('🗄️ فحص الاتصال بقاعدة البيانات...');
    
    try {
      const { data, error } = await this.supabase
        .from('users')
        .select('count')
        .limit(1);

      if (error) {
        console.log(`❌ خطأ في الاتصال: ${error.message}`);
      } else {
        console.log('✅ الاتصال بقاعدة البيانات يعمل بشكل صحيح');
      }
    } catch (error) {
      console.log(`❌ خطأ في الاتصال: ${error.message}`);
    }
    console.log('');
  }

  /**
   * فحص جدول FCM tokens
   */
  async checkFCMTokensTable() {
    console.log('📱 فحص جدول FCM tokens...');
    
    try {
      // فحص بنية الجدول
      const { data: tableInfo, error: tableError } = await this.supabase
        .rpc('get_table_info', { table_name: 'fcm_tokens' });

      if (tableError) {
        console.log(`❌ خطأ في فحص بنية الجدول: ${tableError.message}`);
      } else {
        console.log('✅ جدول fcm_tokens موجود');
      }

      // عدد الـ tokens
      const { count, error: countError } = await this.supabase
        .from('fcm_tokens')
        .select('*', { count: 'exact', head: true });

      if (countError) {
        console.log(`❌ خطأ في عد الـ tokens: ${countError.message}`);
      } else {
        console.log(`📊 عدد FCM tokens: ${count || 0}`);
      }

      // عرض آخر 5 tokens
      const { data: recentTokens, error: tokensError } = await this.supabase
        .from('fcm_tokens')
        .select('user_phone, created_at, is_active')
        .order('created_at', { ascending: false })
        .limit(5);

      if (tokensError) {
        console.log(`❌ خطأ في جلب الـ tokens: ${tokensError.message}`);
      } else if (recentTokens && recentTokens.length > 0) {
        console.log('📋 آخر FCM tokens:');
        recentTokens.forEach(token => {
          console.log(`   - ${token.user_phone} (${token.is_active ? 'نشط' : 'غير نشط'}) - ${token.created_at}`);
        });
      } else {
        console.log('⚠️ لا توجد FCM tokens في قاعدة البيانات');
      }

    } catch (error) {
      console.log(`❌ خطأ في فحص جدول FCM tokens: ${error.message}`);
    }
    console.log('');
  }

  /**
   * فحص المستخدمين
   */
  async checkUsers() {
    console.log('👥 فحص المستخدمين...');
    
    try {
      // عدد المستخدمين
      const { count, error: countError } = await this.supabase
        .from('users')
        .select('*', { count: 'exact', head: true });

      if (countError) {
        console.log(`❌ خطأ في عد المستخدمين: ${countError.message}`);
      } else {
        console.log(`👥 عدد المستخدمين: ${count || 0}`);
      }

      // آخر 5 مستخدمين سجلوا الدخول
      const { data: recentUsers, error: usersError } = await this.supabase
        .from('users')
        .select('phone, name, created_at')
        .order('created_at', { ascending: false })
        .limit(5);

      if (usersError) {
        console.log(`❌ خطأ في جلب المستخدمين: ${usersError.message}`);
      } else if (recentUsers && recentUsers.length > 0) {
        console.log('📋 آخر المستخدمين:');
        recentUsers.forEach(user => {
          console.log(`   - ${user.phone} (${user.name}) - ${user.created_at}`);
        });
      } else {
        console.log('⚠️ لا توجد مستخدمين في قاعدة البيانات');
      }

    } catch (error) {
      console.log(`❌ خطأ في فحص المستخدمين: ${error.message}`);
    }
    console.log('');
  }

  /**
   * فحص Firebase
   */
  async checkFirebase() {
    console.log('🔥 فحص Firebase...');
    
    try {
      if (!process.env.FIREBASE_SERVICE_ACCOUNT) {
        console.log('❌ متغير FIREBASE_SERVICE_ACCOUNT مفقود');
        return;
      }

      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      console.log(`✅ Project ID: ${serviceAccount.project_id}`);
      console.log(`✅ Client Email: ${serviceAccount.client_email}`);

      // محاولة تهيئة Firebase
      const admin = require('firebase-admin');
      
      if (admin.apps.length > 0) {
        await Promise.all(admin.apps.map(app => app.delete()));
      }

      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: serviceAccount.project_id
      });

      const messaging = admin.messaging();
      console.log('✅ Firebase Admin SDK يعمل بشكل صحيح');

    } catch (error) {
      console.log(`❌ خطأ في Firebase: ${error.message}`);
    }
    console.log('');
  }

  /**
   * اختبار إرسال إشعار
   */
  async testNotificationSending() {
    console.log('📤 اختبار إرسال إشعار...');
    
    try {
      // البحث عن أول FCM token نشط
      const { data: activeToken, error: tokenError } = await this.supabase
        .from('fcm_tokens')
        .select('fcm_token, user_phone')
        .eq('is_active', true)
        .limit(1)
        .maybeSingle();

      if (tokenError) {
        console.log(`❌ خطأ في البحث عن token: ${tokenError.message}`);
        return;
      }

      if (!activeToken) {
        console.log('⚠️ لا توجد FCM tokens نشطة للاختبار');
        return;
      }

      console.log(`📱 اختبار الإرسال للمستخدم: ${activeToken.user_phone}`);

      const admin = require('firebase-admin');
      const messaging = admin.messaging();

      const message = {
        token: activeToken.fcm_token,
        notification: {
          title: '🧪 اختبار الإشعارات',
          body: 'هذا إشعار تجريبي للتأكد من عمل النظام'
        },
        data: {
          type: 'test',
          timestamp: new Date().toISOString()
        }
      };

      const response = await messaging.send(message);
      console.log(`✅ تم إرسال الإشعار بنجاح: ${response}`);

    } catch (error) {
      console.log(`❌ خطأ في إرسال الإشعار: ${error.message}`);
    }
    console.log('');
  }

  /**
   * إضافة FCM token تجريبي
   */
  async addTestToken(userPhone, testToken) {
    console.log(`📱 إضافة FCM token تجريبي للمستخدم: ${userPhone}...`);
    
    try {
      const { data, error } = await this.supabase
        .from('fcm_tokens')
        .upsert({
          user_phone: userPhone,
          fcm_token: testToken,
          device_info: { platform: 'test', app: 'diagnosis' },
          is_active: true,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
          last_used_at: new Date().toISOString()
        })
        .select();

      if (error) {
        console.log(`❌ خطأ في إضافة token: ${error.message}`);
      } else {
        console.log('✅ تم إضافة FCM token تجريبي بنجاح');
      }

    } catch (error) {
      console.log(`❌ خطأ في إضافة token: ${error.message}`);
    }
  }
}

// تشغيل التشخيص
async function main() {
  const diagnosis = new FCMSystemDiagnosis();
  await diagnosis.runFullDiagnosis();
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = FCMSystemDiagnosis;
