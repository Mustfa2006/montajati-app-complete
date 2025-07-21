// ===================================
// خدمة تنظيف FCM Tokens المنتهية الصلاحية
// FCM Token Cleanup Service
// ===================================

const { createClient } = require('@supabase/supabase-js');
const admin = require('firebase-admin');

class FCMCleanupService {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
    
    this.isRunning = false;
    this.cleanupInterval = null;
  }

  // بدء خدمة التنظيف التلقائي
  start() {
    if (this.isRunning) {
      console.log('⚠️ خدمة تنظيف FCM Tokens تعمل بالفعل');
      return;
    }

    console.log('🧹 بدء خدمة تنظيف FCM Tokens التلقائية...');
    
    // تشغيل التنظيف كل 12 ساعة (أقل إزعاجاً)
    this.cleanupInterval = setInterval(async () => {
      await this.cleanupExpiredTokens();
    }, 12 * 60 * 60 * 1000); // 12 ساعة

    // تشغيل التنظيف فور البدء (بعد 5 دقائق لتجنب الحمل عند البدء)
    setTimeout(() => {
      this.cleanupExpiredTokens();
    }, 5 * 60 * 1000); // بعد 5 دقائق من البدء

    this.isRunning = true;
    console.log('✅ تم بدء خدمة تنظيف FCM Tokens (كل 12 ساعة)');
  }

  // إيقاف خدمة التنظيف
  stop() {
    if (this.cleanupInterval) {
      clearInterval(this.cleanupInterval);
      this.cleanupInterval = null;
    }
    
    this.isRunning = false;
    console.log('🛑 تم إيقاف خدمة تنظيف FCM Tokens');
  }

  // تنظيف FCM Tokens المنتهية الصلاحية
  async cleanupExpiredTokens() {
    try {
      console.log('🧹 بدء تنظيف FCM Tokens المنتهية الصلاحية...');
      
      const startTime = Date.now();
      
      // الحصول على Tokens القديمة فقط (أكثر من 7 أيام بدون استخدام)
      const { data: tokens, error } = await this.supabase
        .from('fcm_tokens')
        .select('id, fcm_token, user_phone, created_at, last_used_at')
        .eq('is_active', true)
        .lt('last_used_at', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString())
        .order('last_used_at', { ascending: true });

      if (error) {
        console.error('❌ خطأ في جلب FCM Tokens:', error.message);
        return;
      }

      if (!tokens || tokens.length === 0) {
        console.log('📱 لا توجد FCM Tokens قديمة للفحص (جميع Tokens مستخدمة حديثاً)');
        return;
      }

      console.log(`🔍 فحص ${tokens.length} FCM token قديم (غير مستخدم لأكثر من 7 أيام)...`);

      let expiredCount = 0;
      let validCount = 0;
      let errorCount = 0;

      // فحص كل Token على دفعات لتجنب الحمل الزائد
      const batchSize = 10;
      for (let i = 0; i < tokens.length; i += batchSize) {
        const batch = tokens.slice(i, i + batchSize);
        
        await Promise.all(batch.map(async (tokenData) => {
          try {
            // اختبار Token بإرسال رسالة صامتة (data-only message)
            const testMessage = {
              token: tokenData.fcm_token,
              data: {
                type: 'silent_validation',
                timestamp: new Date().toISOString()
              }
              // لا notification - رسالة صامتة تماماً
            };

            await admin.messaging().send(testMessage);

            // Token صالح - تحديث آخر استخدام
            await this.supabase
              .from('fcm_tokens')
              .update({ last_used_at: new Date().toISOString() })
              .eq('id', tokenData.id);

            validCount++;

          } catch (firebaseError) {
            // Token منتهي الصلاحية - تعطيله
            if (firebaseError.code === 'messaging/registration-token-not-registered' ||
                firebaseError.code === 'messaging/invalid-registration-token') {

              await this.supabase
                .from('fcm_tokens')
                .update({
                  is_active: false,
                  deactivated_at: new Date().toISOString(),
                  deactivation_reason: firebaseError.code
                })
                .eq('id', tokenData.id);

              expiredCount++;
              console.log(`🗑️ تم تعطيل Token منتهي الصلاحية للمستخدم: ${tokenData.user_phone}`);
            } else {
              errorCount++;
              console.warn(`⚠️ خطأ غير متوقع في Token: ${firebaseError.code}`);
            }
          }
        }));

        // انتظار قصير بين الدفعات
        if (i + batchSize < tokens.length) {
          await new Promise(resolve => setTimeout(resolve, 1000));
        }
      }

      const duration = Date.now() - startTime;
      
      console.log(`✅ تم تنظيف FCM Tokens في ${duration}ms:`);
      console.log(`   📊 إجمالي: ${tokens.length}`);
      console.log(`   ✅ صالح: ${validCount}`);
      console.log(`   🗑️ منتهي الصلاحية: ${expiredCount}`);
      console.log(`   ⚠️ أخطاء: ${errorCount}`);

      // حفظ إحصائيات التنظيف
      await this.saveCleanupStats({
        totalTokens: tokens.length,
        validTokens: validCount,
        expiredTokens: expiredCount,
        errorTokens: errorCount,
        duration: duration
      });

    } catch (error) {
      console.error('❌ خطأ في تنظيف FCM Tokens:', error.message);
    }
  }

  // حفظ إحصائيات التنظيف
  async saveCleanupStats(stats) {
    try {
      await this.supabase
        .from('fcm_cleanup_logs')
        .insert({
          total_tokens: stats.totalTokens,
          valid_tokens: stats.validTokens,
          expired_tokens: stats.expiredTokens,
          error_tokens: stats.errorTokens,
          duration_ms: stats.duration,
          created_at: new Date().toISOString()
        });
    } catch (error) {
      console.warn('⚠️ فشل في حفظ إحصائيات التنظيف:', error.message);
    }
  }

  // تنظيف يدوي فوري
  async manualCleanup() {
    console.log('🧹 تنظيف يدوي لـ FCM Tokens...');
    await this.cleanupExpiredTokens();
  }

  // الحصول على إحصائيات الخدمة
  getServiceStats() {
    return {
      isRunning: this.isRunning,
      hasInterval: this.cleanupInterval !== null,
      intervalMs: 6 * 60 * 60 * 1000, // 6 ساعات
      nextCleanup: this.isRunning ? 'كل 6 ساعات' : 'متوقف'
    };
  }
}

// تصدير مثيل واحد من الخدمة (Singleton)
const fcmCleanupService = new FCMCleanupService();

module.exports = fcmCleanupService;
