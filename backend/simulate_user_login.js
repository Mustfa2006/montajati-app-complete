// ===================================
// محاكاة تسجيل دخول مستخدم واختبار FCM
// Simulate User Login and Test FCM
// ===================================

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

class UserLoginSimulator {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
  }

  /**
   * محاكاة تسجيل دخول مستخدم
   */
  async simulateUserLogin(userPhone) {
    console.log(`🔐 محاكاة تسجيل دخول للمستخدم: ${userPhone}...`);

    try {
      // 1. التحقق من وجود المستخدم
      const { data: user, error: userError } = await this.supabase
        .from('users')
        .select('*')
        .eq('phone', userPhone)
        .maybeSingle();

      if (userError) {
        console.log(`❌ خطأ في البحث عن المستخدم: ${userError.message}`);
        return false;
      }

      if (!user) {
        console.log(`❌ المستخدم غير موجود: ${userPhone}`);
        return false;
      }

      console.log(`✅ تم العثور على المستخدم: ${user.name} (${user.phone})`);

      // 2. محاكاة تسجيل FCM token
      const fcmToken = this.generateMockFCMToken();
      console.log(`🔑 إنشاء FCM token تجريبي: ${fcmToken.substring(0, 30)}...`);

      // 3. تسجيل FCM token في قاعدة البيانات
      const tokenSuccess = await this.registerFCMToken(userPhone, fcmToken);

      if (tokenSuccess) {
        console.log(`✅ تم تسجيل دخول المستخدم وحفظ FCM token بنجاح`);
        return true;
      } else {
        console.log(`❌ فشل في حفظ FCM token`);
        return false;
      }

    } catch (error) {
      console.log(`❌ خطأ في محاكاة تسجيل الدخول: ${error.message}`);
      return false;
    }
  }

  /**
   * تسجيل FCM token
   */
  async registerFCMToken(userPhone, fcmToken) {
    console.log(`📱 تسجيل FCM token للمستخدم: ${userPhone}...`);

    try {
      // استخدام الدالة المخزنة
      const { data, error } = await this.supabase.rpc('upsert_fcm_token', {
        p_user_phone: userPhone,
        p_fcm_token: fcmToken,
        p_device_info: {
          platform: 'simulation',
          app: 'login_test',
          timestamp: new Date().toISOString(),
          device_model: 'Test Device',
          os_version: 'Test OS 1.0'
        }
      });

      if (error) {
        console.log(`❌ خطأ في تسجيل FCM token: ${error.message}`);
        return false;
      }

      console.log(`✅ تم تسجيل FCM token بنجاح`);
      return true;

    } catch (error) {
      console.log(`❌ خطأ في تسجيل FCM token: ${error.message}`);
      return false;
    }
  }

  /**
   * إنشاء FCM token تجريبي
   */
  generateMockFCMToken() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
    let result = '';
    for (let i = 0; i < 152; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
  }

  /**
   * عرض إحصائيات FCM tokens
   */
  async showFCMStats() {
    console.log('\n📊 إحصائيات FCM tokens...');

    try {
      // إجمالي عدد الـ tokens
      const { count: totalTokens, error: countError } = await this.supabase
        .from('fcm_tokens')
        .select('*', { count: 'exact', head: true });

      if (countError) {
        console.log(`❌ خطأ في عد الـ tokens: ${countError.message}`);
        return;
      }

      console.log(`📱 إجمالي FCM tokens: ${totalTokens || 0}`);

      // عدد الـ tokens النشطة
      const { count: activeTokens, error: activeError } = await this.supabase
        .from('fcm_tokens')
        .select('*', { count: 'exact', head: true })
        .eq('is_active', true);

      if (!activeError) {
        console.log(`✅ FCM tokens نشطة: ${activeTokens || 0}`);
      }

      // آخر 5 tokens
      const { data: recentTokens, error: recentError } = await this.supabase
        .from('fcm_tokens')
        .select('user_phone, created_at, is_active')
        .order('created_at', { ascending: false })
        .limit(5);

      if (!recentError && recentTokens && recentTokens.length > 0) {
        console.log('\n📋 آخر FCM tokens:');
        recentTokens.forEach((token, index) => {
          console.log(`   ${index + 1}. ${token.user_phone} (${token.is_active ? 'نشط' : 'غير نشط'}) - ${token.created_at}`);
        });
      }

    } catch (error) {
      console.log(`❌ خطأ في عرض الإحصائيات: ${error.message}`);
    }
  }

  /**
   * محاكاة تسجيل دخول عدة مستخدمين
   */
  async simulateMultipleLogins() {
    console.log('🚀 محاكاة تسجيل دخول عدة مستخدمين...\n');

    try {
      // جلب آخر 5 مستخدمين
      const { data: users, error: usersError } = await this.supabase
        .from('users')
        .select('phone, name')
        .order('created_at', { ascending: false })
        .limit(5);

      if (usersError) {
        console.log(`❌ خطأ في جلب المستخدمين: ${usersError.message}`);
        return;
      }

      if (!users || users.length === 0) {
        console.log('⚠️ لا توجد مستخدمين في قاعدة البيانات');
        return;
      }

      console.log(`👥 سيتم محاكاة تسجيل دخول ${users.length} مستخدمين...\n`);

      let successCount = 0;
      for (const user of users) {
        console.log(`\n--- المستخدم: ${user.name} (${user.phone}) ---`);
        const success = await this.simulateUserLogin(user.phone);
        if (success) {
          successCount++;
        }
        
        // تأخير قصير بين المحاولات
        await new Promise(resolve => setTimeout(resolve, 1000));
      }

      console.log(`\n✅ تم تسجيل دخول ${successCount} من ${users.length} مستخدمين بنجاح`);

      // عرض الإحصائيات النهائية
      await this.showFCMStats();

    } catch (error) {
      console.log(`❌ خطأ في محاكاة تسجيل دخول متعدد: ${error.message}`);
    }
  }

  /**
   * تنظيف tokens تجريبية
   */
  async cleanupTestTokens() {
    console.log('🧹 تنظيف FCM tokens التجريبية...');

    try {
      const { data, error } = await this.supabase
        .from('fcm_tokens')
        .delete()
        .like('device_info->app', '%test%')
        .select();

      if (error) {
        console.log(`❌ خطأ في التنظيف: ${error.message}`);
      } else {
        console.log(`✅ تم حذف ${data?.length || 0} token تجريبي`);
      }

    } catch (error) {
      console.log(`❌ خطأ في التنظيف: ${error.message}`);
    }
  }
}

// تشغيل المحاكاة
async function main() {
  const simulator = new UserLoginSimulator();

  console.log('🎭 بدء محاكاة تسجيل دخول المستخدمين...\n');

  // عرض الإحصائيات الحالية
  await simulator.showFCMStats();

  console.log('\n' + '='.repeat(50));

  // محاكاة تسجيل دخول عدة مستخدمين
  await simulator.simulateMultipleLogins();

  console.log('\n' + '='.repeat(50));
  console.log('✅ انتهت المحاكاة');
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = UserLoginSimulator;
