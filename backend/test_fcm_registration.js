// ===================================
// اختبار تسجيل FCM Token يدوياً
// Manual FCM Token Registration Test
// ===================================

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

class FCMRegistrationTest {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
  }

  /**
   * اختبار تسجيل FCM token باستخدام الدالة المخزنة
   */
  async testUpsertFunction(userPhone, fcmToken) {
    console.log('🧪 اختبار دالة upsert_fcm_token...');
    console.log(`📱 المستخدم: ${userPhone}`);
    console.log(`🔑 Token: ${fcmToken.substring(0, 20)}...`);

    try {
      const { data, error } = await this.supabase.rpc('upsert_fcm_token', {
        p_user_phone: userPhone,
        p_fcm_token: fcmToken,
        p_device_info: {
          platform: 'test',
          app: 'manual_test',
          timestamp: new Date().toISOString()
        }
      });

      if (error) {
        console.log(`❌ خطأ في دالة upsert_fcm_token: ${error.message}`);
        return false;
      } else {
        console.log('✅ تم تسجيل FCM token بنجاح باستخدام الدالة المخزنة');
        console.log('📊 النتيجة:', data);
        return true;
      }

    } catch (error) {
      console.log(`❌ خطأ في اختبار الدالة: ${error.message}`);
      return false;
    }
  }

  /**
   * اختبار تسجيل FCM token باستخدام upsert مباشر
   */
  async testDirectUpsert(userPhone, fcmToken) {
    console.log('\n🧪 اختبار upsert مباشر...');
    console.log(`📱 المستخدم: ${userPhone}`);
    console.log(`🔑 Token: ${fcmToken.substring(0, 20)}...`);

    try {
      const { data, error } = await this.supabase
        .from('fcm_tokens')
        .upsert({
          user_phone: userPhone,
          fcm_token: fcmToken,
          device_info: {
            platform: 'test',
            app: 'direct_upsert',
            timestamp: new Date().toISOString()
          },
          is_active: true,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
          last_used_at: new Date().toISOString()
        })
        .select();

      if (error) {
        console.log(`❌ خطأ في upsert مباشر: ${error.message}`);
        return false;
      } else {
        console.log('✅ تم تسجيل FCM token بنجاح باستخدام upsert مباشر');
        console.log('📊 النتيجة:', data);
        return true;
      }

    } catch (error) {
      console.log(`❌ خطأ في اختبار upsert مباشر: ${error.message}`);
      return false;
    }
  }

  /**
   * التحقق من وجود token في قاعدة البيانات
   */
  async checkTokenExists(userPhone, fcmToken) {
    console.log('\n🔍 التحقق من وجود Token في قاعدة البيانات...');

    try {
      const { data, error } = await this.supabase
        .from('fcm_tokens')
        .select('*')
        .eq('user_phone', userPhone)
        .eq('fcm_token', fcmToken)
        .maybeSingle();

      if (error) {
        console.log(`❌ خطأ في البحث: ${error.message}`);
        return false;
      }

      if (data) {
        console.log('✅ تم العثور على Token في قاعدة البيانات');
        console.log('📊 البيانات:', {
          id: data.id,
          user_phone: data.user_phone,
          is_active: data.is_active,
          created_at: data.created_at,
          updated_at: data.updated_at
        });
        return true;
      } else {
        console.log('❌ لم يتم العثور على Token في قاعدة البيانات');
        return false;
      }

    } catch (error) {
      console.log(`❌ خطأ في التحقق: ${error.message}`);
      return false;
    }
  }

  /**
   * عرض جميع tokens للمستخدم
   */
  async showUserTokens(userPhone) {
    console.log(`\n📋 عرض جميع tokens للمستخدم: ${userPhone}...`);

    try {
      const { data, error } = await this.supabase
        .from('fcm_tokens')
        .select('*')
        .eq('user_phone', userPhone)
        .order('created_at', { ascending: false });

      if (error) {
        console.log(`❌ خطأ في جلب tokens: ${error.message}`);
        return;
      }

      if (data && data.length > 0) {
        console.log(`📊 عدد tokens للمستخدم: ${data.length}`);
        data.forEach((token, index) => {
          console.log(`\n   Token ${index + 1}:`);
          console.log(`   - ID: ${token.id}`);
          console.log(`   - Token: ${token.fcm_token.substring(0, 30)}...`);
          console.log(`   - نشط: ${token.is_active ? 'نعم' : 'لا'}`);
          console.log(`   - تاريخ الإنشاء: ${token.created_at}`);
          console.log(`   - آخر استخدام: ${token.last_used_at}`);
        });
      } else {
        console.log('⚠️ لا توجد tokens لهذا المستخدم');
      }

    } catch (error) {
      console.log(`❌ خطأ في عرض tokens: ${error.message}`);
    }
  }

  /**
   * تنظيف tokens قديمة للمستخدم
   */
  async cleanupUserTokens(userPhone) {
    console.log(`\n🧹 تنظيف tokens قديمة للمستخدم: ${userPhone}...`);

    try {
      const { data, error } = await this.supabase
        .from('fcm_tokens')
        .delete()
        .eq('user_phone', userPhone)
        .select();

      if (error) {
        console.log(`❌ خطأ في التنظيف: ${error.message}`);
      } else {
        console.log(`✅ تم حذف ${data?.length || 0} token`);
      }

    } catch (error) {
      console.log(`❌ خطأ في التنظيف: ${error.message}`);
    }
  }

  /**
   * اختبار شامل
   */
  async runFullTest(userPhone, fcmToken) {
    console.log('🚀 بدء الاختبار الشامل لتسجيل FCM Token...\n');

    // 1. عرض tokens الحالية
    await this.showUserTokens(userPhone);

    // 2. اختبار الدالة المخزنة
    const upsertSuccess = await this.testUpsertFunction(userPhone, fcmToken);

    // 3. التحقق من النتيجة
    if (upsertSuccess) {
      await this.checkTokenExists(userPhone, fcmToken);
    }

    // 4. اختبار upsert مباشر (مع token مختلف قليلاً)
    const modifiedToken = fcmToken + '_direct';
    const directSuccess = await this.testDirectUpsert(userPhone, modifiedToken);

    // 5. عرض النتيجة النهائية
    await this.showUserTokens(userPhone);

    console.log('\n✅ انتهى الاختبار الشامل');
  }
}

// دالة مساعدة لتوليد FCM token تجريبي
function generateTestFCMToken() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
  let result = '';
  for (let i = 0; i < 152; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

// تشغيل الاختبار
async function main() {
  const tester = new FCMRegistrationTest();
  
  // استخدام رقم هاتف تجريبي
  const testPhone = '07503597589'; // يمكن تغييره
  const testToken = generateTestFCMToken();

  await tester.runFullTest(testPhone, testToken);
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = FCMRegistrationTest;
