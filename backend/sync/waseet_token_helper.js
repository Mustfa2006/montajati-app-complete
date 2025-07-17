// ===================================
// مساعد توكن شركة الوسيط
// نسخ التوكن من الخادم الرئيسي لاستخدامه في المزامنة
// ===================================

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

class WaseetTokenHelper {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    console.log('🔑 تم تهيئة مساعد توكن شركة الوسيط');
  }

  // ===================================
  // نسخ التوكن من متغير عام في الخادم الرئيسي
  // ===================================
  async copyTokenFromMainServer() {
    try {
      // محاولة الوصول للمتغير العام WASEET_CONFIG
      if (global.WASEET_CONFIG && global.WASEET_CONFIG.authToken) {
        console.log('✅ تم العثور على توكن في المتغير العام');
        
        // حفظ التوكن في قاعدة البيانات
        await this.saveToken(global.WASEET_CONFIG.authToken);
        
        return global.WASEET_CONFIG.authToken;
      }

      console.log('⚠️ لا يوجد توكن في المتغير العام');
      return null;
    } catch (error) {
      console.error('❌ خطأ في نسخ التوكن:', error.message);
      return null;
    }
  }

  // ===================================
  // الحصول على التوكن المحفوظ
  // ===================================
  async getSavedToken() {
    try {
      const { data: provider, error } = await this.supabase
        .from('delivery_providers')
        .select('token, token_expires_at')
        .eq('name', 'alwaseet')
        .single();

      if (error) {
        console.log('⚠️ لا يوجد توكن محفوظ في قاعدة البيانات');
        return null;
      }

      if (provider && provider.token) {
        // التحقق من انتهاء الصلاحية
        if (provider.token_expires_at && new Date(provider.token_expires_at) > new Date()) {
          console.log('✅ تم العثور على توكن صالح في قاعدة البيانات');
          return provider.token;
        } else {
          console.log('⚠️ التوكن المحفوظ منتهي الصلاحية');
          return null;
        }
      }

      return null;
    } catch (error) {
      console.error('❌ خطأ في جلب التوكن المحفوظ:', error.message);
      return null;
    }
  }

  // ===================================
  // حفظ التوكن في قاعدة البيانات
  // ===================================
  async saveToken(token, expiresAt = null) {
    try {
      const expiry = expiresAt || new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 ساعة افتراضية

      await this.supabase
        .from('delivery_providers')
        .upsert({
          name: 'alwaseet',
          token: token,
          token_expires_at: expiry.toISOString(),
          updated_at: new Date().toISOString()
        });

      console.log('✅ تم حفظ التوكن في قاعدة البيانات');
      return true;
    } catch (error) {
      console.error('❌ خطأ في حفظ التوكن:', error.message);
      return false;
    }
  }

  // ===================================
  // الحصول على أفضل توكن متاح
  // ===================================
  async getBestAvailableToken() {
    try {
      console.log('🔍 البحث عن أفضل توكن متاح...');

      // أولاً: محاولة نسخ من الخادم الرئيسي
      const mainServerToken = await this.copyTokenFromMainServer();
      if (mainServerToken) {
        return mainServerToken;
      }

      // ثانياً: محاولة جلب من قاعدة البيانات
      const savedToken = await this.getSavedToken();
      if (savedToken) {
        return savedToken;
      }

      console.log('❌ لا يوجد توكن متاح');
      return null;
    } catch (error) {
      console.error('❌ خطأ في الحصول على التوكن:', error.message);
      return null;
    }
  }

  // ===================================
  // تحديث التوكن من مصدر خارجي
  // ===================================
  async updateTokenFromExternal(token, expiresAt = null) {
    try {
      console.log('🔄 تحديث التوكن من مصدر خارجي...');
      
      const success = await this.saveToken(token, expiresAt);
      
      if (success) {
        // تحديث المتغير العام أيضاً
        if (global.WASEET_CONFIG) {
          global.WASEET_CONFIG.authToken = token;
          global.WASEET_CONFIG.tokenExpiry = expiresAt || new Date(Date.now() + 24 * 60 * 60 * 1000);
        }
        
        console.log('✅ تم تحديث التوكن بنجاح');
        return true;
      }

      return false;
    } catch (error) {
      console.error('❌ خطأ في تحديث التوكن:', error.message);
      return false;
    }
  }

  // ===================================
  // فحص صحة التوكن
  // ===================================
  async validateToken(token) {
    try {
      if (!token) {
        return false;
      }

      // فحص بسيط للتوكن (يجب أن يحتوي على PHPSESSID)
      if (typeof token === 'string' && token.includes('PHPSESSID')) {
        return true;
      }

      return false;
    } catch (error) {
      console.error('❌ خطأ في فحص التوكن:', error.message);
      return false;
    }
  }

  // ===================================
  // تنظيف التوكنات المنتهية الصلاحية
  // ===================================
  async cleanupExpiredTokens() {
    try {
      console.log('🧹 تنظيف التوكنات المنتهية الصلاحية...');

      const { error } = await this.supabase
        .from('delivery_providers')
        .update({ 
          token: null, 
          token_expires_at: null,
          updated_at: new Date().toISOString()
        })
        .lt('token_expires_at', new Date().toISOString());

      if (error) {
        throw error;
      }

      console.log('✅ تم تنظيف التوكنات المنتهية الصلاحية');
      return true;
    } catch (error) {
      console.error('❌ خطأ في تنظيف التوكنات:', error.message);
      return false;
    }
  }

  // ===================================
  // الحصول على إحصائيات التوكنات
  // ===================================
  async getTokenStats() {
    try {
      const { data: providers, error } = await this.supabase
        .from('delivery_providers')
        .select('name, token, token_expires_at, updated_at')
        .eq('name', 'alwaseet');

      if (error) {
        throw error;
      }

      const stats = {
        total_providers: providers.length,
        active_tokens: providers.filter(p => p.token && new Date(p.token_expires_at) > new Date()).length,
        expired_tokens: providers.filter(p => p.token && new Date(p.token_expires_at) <= new Date()).length,
        no_tokens: providers.filter(p => !p.token).length,
        last_update: providers[0]?.updated_at || null
      };

      return stats;
    } catch (error) {
      console.error('❌ خطأ في جلب إحصائيات التوكنات:', error.message);
      return null;
    }
  }

  // ===================================
  // مراقبة التوكن بشكل دوري
  // ===================================
  startTokenMonitoring(intervalMinutes = 5) {
    console.log(`🔍 بدء مراقبة التوكن كل ${intervalMinutes} دقائق`);

    setInterval(async () => {
      try {
        // تنظيف التوكنات المنتهية الصلاحية
        await this.cleanupExpiredTokens();

        // محاولة تحديث التوكن إذا لزم الأمر
        const currentToken = await this.getSavedToken();
        if (!currentToken) {
          console.log('⚠️ لا يوجد توكن صالح، محاولة الحصول على واحد جديد...');
          await this.getBestAvailableToken();
        }
      } catch (error) {
        console.error('❌ خطأ في مراقبة التوكن:', error.message);
      }
    }, intervalMinutes * 60 * 1000);
  }
}

// تصدير مثيل واحد من المساعد (Singleton)
const waseetTokenHelper = new WaseetTokenHelper();

module.exports = waseetTokenHelper;
