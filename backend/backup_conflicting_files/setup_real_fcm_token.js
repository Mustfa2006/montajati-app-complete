// ===================================
// إعداد FCM Token حقيقي للاختبار
// ===================================

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

class RealFCMTokenSetup {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
  }

  // ===================================
  // إضافة FCM Token حقيقي
  // ===================================
  async addRealFCMToken(userPhone, fcmToken, platform = 'android') {
    try {
      console.log(`📱 إضافة FCM Token حقيقي للمستخدم: ${userPhone}`);
      console.log(`🔑 Token: ${fcmToken.substring(0, 30)}...`);

      // التحقق من صحة FCM Token
      if (!fcmToken || fcmToken.length < 100) {
        throw new Error('FCM Token غير صالح - يجب أن يكون أطول من 100 حرف');
      }

      // إضافة أو تحديث FCM Token
      const { data, error } = await this.supabase
        .from('user_fcm_tokens')
        .upsert({
          user_phone: userPhone,
          fcm_token: fcmToken,
          platform: platform,
          is_active: true,
          updated_at: new Date().toISOString()
        }, {
          onConflict: 'user_phone,platform'
        })
        .select();

      if (error) {
        throw new Error(`فشل في حفظ FCM Token: ${error.message}`);
      }

      console.log('✅ تم حفظ FCM Token الحقيقي بنجاح');
      console.log(`📋 ID: ${data[0]?.id}`);
      console.log(`📱 Platform: ${data[0]?.platform}`);
      console.log(`🔄 Updated: ${data[0]?.updated_at}`);

      return data[0];

    } catch (error) {
      console.error('❌ خطأ في إضافة FCM Token الحقيقي:', error.message);
      throw error;
    }
  }

  // ===================================
  // عرض FCM Tokens الموجودة
  // ===================================
  async showExistingTokens() {
    try {
      console.log('📱 FCM Tokens الموجودة:');
      console.log('═══════════════════════════════');

      const { data: tokens, error } = await this.supabase
        .from('user_fcm_tokens')
        .select('*')
        .order('updated_at', { ascending: false });

      if (error) {
        throw new Error(`فشل في جلب FCM Tokens: ${error.message}`);
      }

      if (!tokens || tokens.length === 0) {
        console.log('📭 لا توجد FCM Tokens محفوظة');
        return;
      }

      tokens.forEach((token, index) => {
        console.log(`\n${index + 1}. المستخدم: ${token.user_phone}`);
        console.log(`   Token: ${token.fcm_token.substring(0, 30)}...`);
        console.log(`   Platform: ${token.platform}`);
        console.log(`   نشط: ${token.is_active ? 'نعم' : 'لا'}`);
        console.log(`   آخر تحديث: ${new Date(token.updated_at).toLocaleString('ar-EG')}`);
      });

      console.log('═══════════════════════════════');

    } catch (error) {
      console.error('❌ خطأ في عرض FCM Tokens:', error.message);
    }
  }

  // ===================================
  // حذف FCM Token
  // ===================================
  async removeFCMToken(userPhone, platform = 'android') {
    try {
      console.log(`🗑️ حذف FCM Token للمستخدم: ${userPhone} (${platform})`);

      const { error } = await this.supabase
        .from('user_fcm_tokens')
        .delete()
        .eq('user_phone', userPhone)
        .eq('platform', platform);

      if (error) {
        throw new Error(`فشل في حذف FCM Token: ${error.message}`);
      }

      console.log('✅ تم حذف FCM Token بنجاح');

    } catch (error) {
      console.error('❌ خطأ في حذف FCM Token:', error.message);
      throw error;
    }
  }

  // ===================================
  // إلغاء تفعيل FCM Token
  // ===================================
  async deactivateFCMToken(userPhone, platform = 'android') {
    try {
      console.log(`⏸️ إلغاء تفعيل FCM Token للمستخدم: ${userPhone} (${platform})`);

      const { error } = await this.supabase
        .from('user_fcm_tokens')
        .update({ is_active: false })
        .eq('user_phone', userPhone)
        .eq('platform', platform);

      if (error) {
        throw new Error(`فشل في إلغاء تفعيل FCM Token: ${error.message}`);
      }

      console.log('✅ تم إلغاء تفعيل FCM Token بنجاح');

    } catch (error) {
      console.error('❌ خطأ في إلغاء تفعيل FCM Token:', error.message);
      throw error;
    }
  }

  // ===================================
  // عرض دليل الاستخدام
  // ===================================
  showUsageGuide() {
    console.log('📋 دليل استخدام إعداد FCM Token الحقيقي:');
    console.log('═══════════════════════════════════════════════');
    console.log('');
    console.log('📱 إضافة FCM Token حقيقي:');
    console.log('  node setup_real_fcm_token.js add <رقم_الهاتف> <fcm_token>');
    console.log('');
    console.log('📋 عرض FCM Tokens الموجودة:');
    console.log('  node setup_real_fcm_token.js list');
    console.log('');
    console.log('🗑️ حذف FCM Token:');
    console.log('  node setup_real_fcm_token.js remove <رقم_الهاتف>');
    console.log('');
    console.log('⏸️ إلغاء تفعيل FCM Token:');
    console.log('  node setup_real_fcm_token.js deactivate <رقم_الهاتف>');
    console.log('');
    console.log('═══════════════════════════════════════════════');
    console.log('');
    console.log('📝 ملاحظات مهمة:');
    console.log('• FCM Token يجب أن يكون حقيقي من التطبيق');
    console.log('• يمكن الحصول عليه من Firebase SDK في التطبيق');
    console.log('• Token صالح لفترة محدودة ويحتاج تحديث دوري');
    console.log('• استخدم Token حقيقي للاختبار الفعلي');
    console.log('');
    console.log('🔥 للحصول على FCM Token حقيقي:');
    console.log('1. افتح التطبيق على الهاتف');
    console.log('2. سجل دخول المستخدم');
    console.log('3. احصل على FCM Token من Firebase SDK');
    console.log('4. استخدم هذا الأمر لحفظه');
    console.log('');
  }
}

// ===================================
// تشغيل الإعداد
// ===================================
if (require.main === module) {
  const setup = new RealFCMTokenSetup();
  const command = process.argv[2];
  const userPhone = process.argv[3];
  const fcmToken = process.argv[4];

  switch (command) {
    case 'add':
      if (!userPhone || !fcmToken) {
        console.log('❌ يجب تحديد رقم الهاتف و FCM Token');
        console.log('الاستخدام: node setup_real_fcm_token.js add <رقم_الهاتف> <fcm_token>');
        process.exit(1);
      }
      
      setup.addRealFCMToken(userPhone, fcmToken)
        .then(() => process.exit(0))
        .catch(() => process.exit(1));
      break;
      
    case 'list':
      setup.showExistingTokens()
        .then(() => process.exit(0))
        .catch(() => process.exit(1));
      break;
      
    case 'remove':
      if (!userPhone) {
        console.log('❌ يجب تحديد رقم الهاتف');
        console.log('الاستخدام: node setup_real_fcm_token.js remove <رقم_الهاتف>');
        process.exit(1);
      }
      
      setup.removeFCMToken(userPhone)
        .then(() => process.exit(0))
        .catch(() => process.exit(1));
      break;
      
    case 'deactivate':
      if (!userPhone) {
        console.log('❌ يجب تحديد رقم الهاتف');
        console.log('الاستخدام: node setup_real_fcm_token.js deactivate <رقم_الهاتف>');
        process.exit(1);
      }
      
      setup.deactivateFCMToken(userPhone)
        .then(() => process.exit(0))
        .catch(() => process.exit(1));
      break;
      
    default:
      setup.showUsageGuide();
      process.exit(1);
  }
}

module.exports = RealFCMTokenSetup;
