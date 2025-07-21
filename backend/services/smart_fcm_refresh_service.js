// ===================================
// خدمة تحديث FCM Tokens الذكية
// Smart FCM Token Refresh Service
// ===================================

const { createClient } = require('@supabase/supabase-js');

class SmartFCMRefreshService {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
    
    this.isRunning = false;
    this.refreshInterval = null;
  }

  // بدء خدمة التحديث الذكي
  start() {
    if (this.isRunning) {
      console.log('⚠️ خدمة تحديث FCM Tokens الذكية تعمل بالفعل');
      return;
    }

    console.log('🔄 بدء خدمة تحديث FCM Tokens الذكية...');
    
    // تشغيل التحديث كل 24 ساعة (مرة واحدة يومياً)
    this.refreshInterval = setInterval(async () => {
      await this.smartTokenRefresh();
    }, 24 * 60 * 60 * 1000); // 24 ساعة

    // تشغيل التحديث فور البدء (بعد 10 دقائق)
    setTimeout(() => {
      this.smartTokenRefresh();
    }, 10 * 60 * 1000); // بعد 10 دقائق من البدء

    this.isRunning = true;
    console.log('✅ تم بدء خدمة تحديث FCM Tokens الذكية (كل 24 ساعة)');
  }

  // إيقاف خدمة التحديث
  stop() {
    if (this.refreshInterval) {
      clearInterval(this.refreshInterval);
      this.refreshInterval = null;
    }
    
    this.isRunning = false;
    console.log('🛑 تم إيقاف خدمة تحديث FCM Tokens الذكية');
  }

  // تحديث ذكي لـ FCM Tokens
  async smartTokenRefresh() {
    try {
      console.log('🧠 بدء التحديث الذكي لـ FCM Tokens...');
      
      const startTime = Date.now();
      
      // 1. تنظيف Tokens المكررة (نفس المستخدم له عدة tokens)
      await this.cleanupDuplicateTokens();
      
      // 2. تعطيل Tokens القديمة جداً (أكثر من 30 يوم بدون استخدام)
      await this.deactivateVeryOldTokens();
      
      // 3. تحديث إحصائيات الاستخدام
      await this.updateUsageStats();
      
      const duration = Date.now() - startTime;
      console.log(`✅ تم التحديث الذكي لـ FCM Tokens في ${duration}ms`);

    } catch (error) {
      console.error('❌ خطأ في التحديث الذكي لـ FCM Tokens:', error.message);
    }
  }

  // تنظيف Tokens المكررة
  async cleanupDuplicateTokens() {
    try {
      console.log('🧹 تنظيف FCM Tokens المكررة...');

      // الحصول على المستخدمين الذين لديهم أكثر من token نشط
      const { data: duplicateUsers, error } = await this.supabase
        .rpc('get_users_with_multiple_tokens');

      if (error) {
        console.error('❌ خطأ في جلب المستخدمين المكررين:', error.message);
        return;
      }

      if (!duplicateUsers || duplicateUsers.length === 0) {
        console.log('✅ لا توجد FCM Tokens مكررة');
        return;
      }

      let cleanedCount = 0;

      for (const user of duplicateUsers) {
        // الاحتفاظ بأحدث token فقط وتعطيل الباقي
        const { error: updateError } = await this.supabase
          .from('fcm_tokens')
          .update({ 
            is_active: false,
            deactivated_at: new Date().toISOString(),
            deactivation_reason: 'duplicate_cleanup'
          })
          .eq('user_phone', user.user_phone)
          .eq('is_active', true)
          .neq('id', user.latest_token_id);

        if (!updateError) {
          cleanedCount++;
          console.log(`🧹 تم تنظيف tokens مكررة للمستخدم: ${user.user_phone}`);
        }
      }

      console.log(`✅ تم تنظيف ${cleanedCount} مستخدم من FCM Tokens المكررة`);

    } catch (error) {
      console.error('❌ خطأ في تنظيف FCM Tokens المكررة:', error.message);
    }
  }

  // تعطيل Tokens القديمة جداً
  async deactivateVeryOldTokens() {
    try {
      console.log('🗑️ تعطيل FCM Tokens القديمة جداً...');

      // تعطيل tokens لم تُستخدم لأكثر من 30 يوم
      const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();

      const { data, error } = await this.supabase
        .from('fcm_tokens')
        .update({ 
          is_active: false,
          deactivated_at: new Date().toISOString(),
          deactivation_reason: 'very_old_token'
        })
        .eq('is_active', true)
        .lt('last_used_at', thirtyDaysAgo)
        .select('user_phone');

      if (error) {
        console.error('❌ خطأ في تعطيل FCM Tokens القديمة:', error.message);
        return;
      }

      const deactivatedCount = data ? data.length : 0;
      console.log(`✅ تم تعطيل ${deactivatedCount} FCM token قديم (أكثر من 30 يوم)`);

    } catch (error) {
      console.error('❌ خطأ في تعطيل FCM Tokens القديمة:', error.message);
    }
  }

  // تحديث إحصائيات الاستخدام
  async updateUsageStats() {
    try {
      // حفظ إحصائيات يومية
      const { data: stats, error } = await this.supabase
        .rpc('get_fcm_tokens_stats');

      if (error) {
        console.warn('⚠️ فشل في جلب إحصائيات FCM Tokens:', error.message);
        return;
      }

      await this.supabase
        .from('fcm_daily_stats')
        .insert({
          date: new Date().toISOString().split('T')[0],
          total_tokens: stats.total_tokens || 0,
          active_tokens: stats.active_tokens || 0,
          unique_users: stats.unique_users || 0,
          created_at: new Date().toISOString()
        });

      console.log(`📊 تم حفظ إحصائيات FCM Tokens: ${stats.active_tokens} نشط من ${stats.total_tokens} إجمالي`);

    } catch (error) {
      console.warn('⚠️ فشل في تحديث إحصائيات FCM Tokens:', error.message);
    }
  }

  // تحديث يدوي فوري
  async manualRefresh() {
    console.log('🔄 تحديث يدوي ذكي لـ FCM Tokens...');
    await this.smartTokenRefresh();
  }

  // الحصول على إحصائيات الخدمة
  getServiceStats() {
    return {
      isRunning: this.isRunning,
      hasInterval: this.refreshInterval !== null,
      intervalMs: 24 * 60 * 60 * 1000, // 24 ساعة
      nextRefresh: this.isRunning ? 'كل 24 ساعة' : 'متوقف'
    };
  }
}

// تصدير مثيل واحد من الخدمة (Singleton)
const smartFCMRefreshService = new SmartFCMRefreshService();

module.exports = smartFCMRefreshService;
