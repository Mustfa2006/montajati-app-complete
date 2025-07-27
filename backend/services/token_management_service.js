// ===================================
// خدمة إدارة FCM Tokens الاحترافية
// Professional FCM Token Management Service
// ===================================

const { createClient } = require('@supabase/supabase-js');
const { firebaseAdminService } = require('./firebase_admin_service');

class TokenManagementService {
  constructor() {
    // إعداد Supabase
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
    this.initialized = false;
  }

  /**
   * تهيئة خدمة إدارة الرموز
   */
  async initialize() {
    try {
      console.log('🔧 تهيئة خدمة إدارة FCM Tokens...');
      this.initialized = true;
      console.log('✅ تم تهيئة خدمة إدارة FCM Tokens بنجاح');
      return true;
    } catch (error) {
      console.error('❌ خطأ في تهيئة خدمة إدارة FCM Tokens:', error);
      this.initialized = false;
      return false;
    }
  }

  /**
   * تنظيف الرموز القديمة وغير النشطة
   * @returns {Promise<Object>} نتيجة التنظيف
   */
  async cleanupOldTokens() {
    try {
      console.log('🧹 بدء تنظيف FCM Tokens القديمة...');
      
      // استدعاء دالة التنظيف في قاعدة البيانات
      const { data, error } = await this.supabase.rpc('cleanup_old_fcm_tokens');
      
      if (error) {
        throw new Error(`خطأ في تنظيف الرموز: ${error.message}`);
      }
      
      const deletedCount = data || 0;
      console.log(`✅ تم حذف ${deletedCount} رمز قديم`);
      
      return {
        success: true,
        deletedCount: deletedCount,
        timestamp: new Date().toISOString()
      };
      
    } catch (error) {
      console.error('❌ خطأ في تنظيف FCM Tokens:', error.message);
      return {
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }

  /**
   * التحقق من صحة جميع الرموز النشطة
   * @returns {Promise<Object>} نتيجة التحقق
   */
  async validateAllActiveTokens() {
    try {
      console.log('🔍 بدء التحقق من صحة جميع FCM Tokens النشطة...');
      
      // الحصول على جميع الرموز النشطة
      const { data: tokens, error } = await this.supabase
        .from('fcm_tokens')
        .select('id, user_phone, fcm_token')
        .eq('is_active', true);
      
      if (error) {
        throw new Error(`خطأ في جلب الرموز: ${error.message}`);
      }
      
      if (!tokens || tokens.length === 0) {
        console.log('ℹ️ لا توجد رموز نشطة للتحقق منها');
        return {
          success: true,
          totalTokens: 0,
          validTokens: 0,
          invalidTokens: 0,
          timestamp: new Date().toISOString()
        };
      }
      
      console.log(`📊 سيتم التحقق من ${tokens.length} رمز`);
      
      let validCount = 0;
      let invalidCount = 0;
      const invalidTokenIds = [];
      
      // التحقق من كل رمز
      for (const token of tokens) {
        try {
          const isValid = await firebaseAdminService.validateFCMToken(token.fcm_token);
          
          if (isValid) {
            validCount++;
          } else {
            invalidCount++;
            invalidTokenIds.push(token.id);
          }
          
          // تأخير قصير لتجنب تجاوز حدود Firebase
          await new Promise(resolve => setTimeout(resolve, 100));
          
        } catch (error) {
          console.error(`⚠️ خطأ في التحقق من الرمز ${token.id}:`, error.message);
          invalidCount++;
          invalidTokenIds.push(token.id);
        }
      }
      
      // تعطيل الرموز غير الصالحة
      if (invalidTokenIds.length > 0) {
        const { error: updateError } = await this.supabase
          .from('fcm_tokens')
          .update({ 
            is_active: false,
            updated_at: new Date().toISOString()
          })
          .in('id', invalidTokenIds);
        
        if (updateError) {
          console.error('⚠️ خطأ في تعطيل الرموز غير الصالحة:', updateError.message);
        } else {
          console.log(`🔄 تم تعطيل ${invalidTokenIds.length} رمز غير صالح`);
        }
      }
      
      console.log(`✅ انتهى التحقق - صالح: ${validCount}, غير صالح: ${invalidCount}`);
      
      return {
        success: true,
        totalTokens: tokens.length,
        validTokens: validCount,
        invalidTokens: invalidCount,
        deactivatedTokens: invalidTokenIds.length,
        timestamp: new Date().toISOString()
      };
      
    } catch (error) {
      console.error('❌ خطأ في التحقق من صحة الرموز:', error.message);
      return {
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }

  /**
   * الحصول على إحصائيات الرموز
   * @returns {Promise<Object>} إحصائيات الرموز
   */
  async getTokenStatistics() {
    try {
      // إحصائيات عامة
      const { data: stats, error: statsError } = await this.supabase
        .from('fcm_tokens')
        .select('is_active, created_at, last_used_at');
      
      if (statsError) {
        throw new Error(`خطأ في جلب الإحصائيات: ${statsError.message}`);
      }
      
      const now = new Date();
      const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);
      const oneWeekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
      const oneMonthAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
      
      const totalTokens = stats.length;
      const activeTokens = stats.filter(token => token.is_active).length;
      const inactiveTokens = totalTokens - activeTokens;
      
      const usedToday = stats.filter(token => 
        token.last_used_at && new Date(token.last_used_at) > oneDayAgo
      ).length;
      
      const usedThisWeek = stats.filter(token => 
        token.last_used_at && new Date(token.last_used_at) > oneWeekAgo
      ).length;
      
      const usedThisMonth = stats.filter(token => 
        token.last_used_at && new Date(token.last_used_at) > oneMonthAgo
      ).length;
      
      const createdToday = stats.filter(token => 
        new Date(token.created_at) > oneDayAgo
      ).length;
      
      const createdThisWeek = stats.filter(token => 
        new Date(token.created_at) > oneWeekAgo
      ).length;
      
      // إحصائيات المستخدمين الفريدين
      const { data: uniqueUsers, error: usersError } = await this.supabase
        .from('fcm_tokens')
        .select('user_phone')
        .eq('is_active', true);
      
      if (usersError) {
        throw new Error(`خطأ في جلب المستخدمين: ${usersError.message}`);
      }
      
      const uniqueUserCount = new Set(
        uniqueUsers.map(user => user.user_phone)
      ).size;
      
      return {
        success: true,
        statistics: {
          total: {
            tokens: totalTokens,
            activeTokens: activeTokens,
            inactiveTokens: inactiveTokens,
            uniqueUsers: uniqueUserCount
          },
          usage: {
            usedToday: usedToday,
            usedThisWeek: usedThisWeek,
            usedThisMonth: usedThisMonth
          },
          growth: {
            createdToday: createdToday,
            createdThisWeek: createdThisWeek
          },
          health: {
            activePercentage: totalTokens > 0 ? Math.round((activeTokens / totalTokens) * 100) : 0,
            usageRate: activeTokens > 0 ? Math.round((usedToday / activeTokens) * 100) : 0
          }
        },
        timestamp: new Date().toISOString()
      };
      
    } catch (error) {
      console.error('❌ خطأ في الحصول على إحصائيات الرموز:', error.message);
      return {
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }

  /**
   * حذف رموز مستخدم معين
   * @param {string} userPhone - رقم هاتف المستخدم
   * @returns {Promise<Object>} نتيجة الحذف
   */
  async deleteUserTokens(userPhone) {
    try {
      console.log(`🗑️ حذف جميع رموز المستخدم: ${userPhone}`);
      
      const { data, error } = await this.supabase
        .from('fcm_tokens')
        .delete()
        .eq('user_phone', userPhone);
      
      if (error) {
        throw new Error(`خطأ في حذف الرموز: ${error.message}`);
      }
      
      console.log(`✅ تم حذف رموز المستخدم ${userPhone}`);
      
      return {
        success: true,
        userPhone: userPhone,
        timestamp: new Date().toISOString()
      };
      
    } catch (error) {
      console.error('❌ خطأ في حذف رموز المستخدم:', error.message);
      return {
        success: false,
        error: error.message,
        userPhone: userPhone,
        timestamp: new Date().toISOString()
      };
    }
  }

  /**
   * تشغيل مهام الصيانة الدورية
   * @returns {Promise<Object>} نتيجة الصيانة
   */
  async runMaintenanceTasks() {
    try {
      console.log('🔧 بدء مهام الصيانة الدورية لـ FCM Tokens...');
      
      const results = {
        cleanup: await this.cleanupOldTokens(),
        validation: await this.validateAllActiveTokens(),
        statistics: await this.getTokenStatistics(),
        timestamp: new Date().toISOString()
      };
      
      console.log('✅ انتهت مهام الصيانة الدورية');
      
      return {
        success: true,
        results: results,
        timestamp: new Date().toISOString()
      };
      
    } catch (error) {
      console.error('❌ خطأ في مهام الصيانة:', error.message);
      return {
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }

  /**
   * جلب جميع المستخدمين النشطين
   * @returns {Promise<Array>} قائمة المستخدمين النشطين
   */
  async getAllActiveUsers() {
    try {
      console.log('👥 جلب جميع المستخدمين النشطين...');

      // جلب المستخدمين الذين لديهم رموز نشطة
      const { data: activeTokens, error } = await this.supabase
        .from('fcm_tokens')
        .select('user_phone, fcm_token')
        .eq('is_active', true);

      if (error) {
        throw new Error(`خطأ في جلب الرموز النشطة: ${error.message}`);
      }

      if (!activeTokens || activeTokens.length === 0) {
        console.log('ℹ️ لا توجد رموز نشطة');
        return [];
      }

      // إنشاء قائمة فريدة من المستخدمين
      const uniqueUsers = [];
      const seenPhones = new Set();

      for (const token of activeTokens) {
        if (!seenPhones.has(token.user_phone)) {
          seenPhones.add(token.user_phone);
          uniqueUsers.push({
            phone: token.user_phone,
            fcm_token: token.fcm_token
          });
        }
      }

      console.log(`✅ تم جلب ${uniqueUsers.length} مستخدم نشط فريد`);
      return uniqueUsers;

    } catch (error) {
      console.error('❌ خطأ في جلب المستخدمين النشطين:', error.message);
      return [];
    }
  }

  /**
   * جلب إحصائيات الرموز (alias للتوافق)
   */
  async getTokenStats() {
    return await this.getTokenStatistics();
  }

  /**
   * إيقاف الخدمة
   */
  async shutdown() {
    try {
      console.log('🔄 إيقاف خدمة إدارة FCM Tokens...');
      this.initialized = false;
      console.log('✅ تم إيقاف خدمة إدارة FCM Tokens بنجاح');
    } catch (error) {
      console.error('❌ خطأ في إيقاف خدمة إدارة FCM Tokens:', error);
    }
  }
}

// إنشاء instance واحد للخدمة
const tokenManagementService = new TokenManagementService();

module.exports = tokenManagementService;
