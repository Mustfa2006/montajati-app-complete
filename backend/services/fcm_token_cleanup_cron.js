// ===================================
// خدمة تنظيف FCM Tokens المكررة
// تعمل كل 6 ساعات لحذف الـ tokens القديمة
// ===================================

const cron = require('node-cron');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

class FCMTokenCleanupCron {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    this.isRunning = false;
    this.stats = {
      totalRuns: 0,
      totalUsersProcessed: 0,
      totalTokensDeleted: 0,
      lastRunTime: null,
      lastRunDuration: 0
    };

    console.log('🧹 تم تهيئة خدمة تنظيف FCM Tokens المكررة');
  }

  /**
   * بدء Cron Job - يعمل كل 6 ساعات
   */
  start() {
    console.log('🚀 بدء Cron Job لتنظيف FCM Tokens المكررة (كل 6 ساعات)');

    // تشغيل فوري عند البدء (بعد دقيقة واحدة)
    setTimeout(() => {
      this.cleanupDuplicateTokens();
    }, 60000);

    // جدولة التنظيف كل 6 ساعات
    // '0 */6 * * *' = كل 6 ساعات عند الدقيقة 0
    cron.schedule('0 */6 * * *', async () => {
      await this.cleanupDuplicateTokens();
    });

    console.log('✅ تم تفعيل Cron Job بنجاح');
  }

  /**
   * تنظيف FCM Tokens المكررة
   */
  async cleanupDuplicateTokens() {
    if (this.isRunning) {
      console.log('⚠️ عملية التنظيف قيد التشغيل بالفعل - تخطي');
      return;
    }

    this.isRunning = true;
    const startTime = Date.now();

    try {
      console.log('\n🧹 ========================================');
      console.log('🧹 بدء تنظيف FCM Tokens المكررة');
      console.log('🧹 ========================================');

      // 1. جلب جميع المستخدمين الذين لديهم أكثر من token نشط
      const { data: usersWithDuplicates, error: fetchError } = await this.supabase
        .from('fcm_tokens')
        .select('user_phone')
        .eq('is_active', true)
        .order('user_phone');

      if (fetchError) {
        throw new Error(`خطأ في جلب FCM Tokens: ${fetchError.message}`);
      }

      if (!usersWithDuplicates || usersWithDuplicates.length === 0) {
        console.log('✅ لا توجد FCM Tokens في قاعدة البيانات');
        this.isRunning = false;
        return;
      }

      // 2. تجميع المستخدمين حسب رقم الهاتف
      const userPhoneMap = {};
      usersWithDuplicates.forEach(token => {
        if (!userPhoneMap[token.user_phone]) {
          userPhoneMap[token.user_phone] = 0;
        }
        userPhoneMap[token.user_phone]++;
      });

      // 3. فلترة المستخدمين الذين لديهم أكثر من token واحد
      const duplicateUsers = Object.keys(userPhoneMap).filter(
        phone => userPhoneMap[phone] > 1
      );

      if (duplicateUsers.length === 0) {
        console.log('✅ لا توجد FCM Tokens مكررة');
        this.isRunning = false;
        return;
      }

      console.log(`📊 تم العثور على ${duplicateUsers.length} مستخدم لديهم tokens مكررة`);

      let totalTokensDeleted = 0;

      // 4. معالجة كل مستخدم على حدة
      for (const userPhone of duplicateUsers) {
        try {
          // جلب جميع tokens المستخدم (مرتبة من الأحدث للأقدم)
          const { data: userTokens, error: tokensError } = await this.supabase
            .from('fcm_tokens')
            .select('id, fcm_token, created_at, last_used_at')
            .eq('user_phone', userPhone)
            .eq('is_active', true)
            .order('last_used_at', { ascending: false, nullsFirst: false })
            .order('created_at', { ascending: false });

          if (tokensError || !userTokens || userTokens.length <= 1) {
            continue; // تخطي إذا كان هناك token واحد فقط أو خطأ
          }

          // الاحتفاظ بأحدث token فقط
          const latestToken = userTokens[0];
          const tokensToDelete = userTokens.slice(1); // جميع الـ tokens القديمة

          console.log(`\n👤 المستخدم: ${userPhone}`);
          console.log(`   📊 عدد الـ Tokens: ${userTokens.length}`);
          console.log(`   ✅ الاحتفاظ بـ Token: ${latestToken.id} (آخر استخدام: ${latestToken.last_used_at || latestToken.created_at})`);
          console.log(`   🗑️ حذف ${tokensToDelete.length} tokens قديمة`);

          // حذف الـ tokens القديمة
          for (const oldToken of tokensToDelete) {
            const { error: deleteError } = await this.supabase
              .from('fcm_tokens')
              .delete()
              .eq('id', oldToken.id);

            if (!deleteError) {
              totalTokensDeleted++;
              console.log(`   ❌ تم حذف Token: ${oldToken.id}`);
            } else {
              console.error(`   ⚠️ خطأ في حذف Token ${oldToken.id}: ${deleteError.message}`);
            }
          }

        } catch (userError) {
          console.error(`❌ خطأ في معالجة المستخدم ${userPhone}:`, userError.message);
        }
      }

      // 5. تحديث الإحصائيات
      const duration = Date.now() - startTime;
      this.stats.totalRuns++;
      this.stats.totalUsersProcessed += duplicateUsers.length;
      this.stats.totalTokensDeleted += totalTokensDeleted;
      this.stats.lastRunTime = new Date().toISOString();
      this.stats.lastRunDuration = duration;

      console.log('\n✅ ========================================');
      console.log('✅ اكتمل تنظيف FCM Tokens المكررة');
      console.log('✅ ========================================');
      console.log(`📊 عدد المستخدمين المعالجين: ${duplicateUsers.length}`);
      console.log(`🗑️ عدد الـ Tokens المحذوفة: ${totalTokensDeleted}`);
      console.log(`⏱️ المدة: ${(duration / 1000).toFixed(2)} ثانية`);
      console.log(`📅 التاريخ: ${this.stats.lastRunTime}`);
      console.log('========================================\n');

    } catch (error) {
      console.error('❌ خطأ في تنظيف FCM Tokens المكررة:', error.message);
    } finally {
      this.isRunning = false;
    }
  }

  /**
   * الحصول على إحصائيات التنظيف
   */
  getStats() {
    return {
      ...this.stats,
      isRunning: this.isRunning
    };
  }

  /**
   * تشغيل التنظيف يدوياً
   */
  async runManually() {
    console.log('🔧 تشغيل التنظيف يدوياً...');
    await this.cleanupDuplicateTokens();
  }
}

// تصدير مثيل واحد (Singleton)
const fcmTokenCleanupCron = new FCMTokenCleanupCron();

module.exports = fcmTokenCleanupCron;

