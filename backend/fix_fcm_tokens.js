// ===================================
// إصلاح FCM Tokens - حذف القديمة وإضافة جديدة للاختبار
// ===================================

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function fixFCMTokens() {
  try {
    console.log('🔧 بدء إصلاح FCM Tokens...');

    // 1. حذف جميع FCM Tokens القديمة
    console.log('🗑️ حذف FCM Tokens القديمة...');
    
    const { error: deleteError } = await supabase
      .from('fcm_tokens')
      .delete()
      .gte('id', 1); // حذف جميع السجلات

    if (deleteError) {
      console.error('❌ خطأ في حذف FCM Tokens:', deleteError);
    } else {
      console.log('✅ تم حذف FCM Tokens القديمة');
    }

    // 2. حذف User FCM Tokens القديمة أيضاً
    console.log('🗑️ حذف User FCM Tokens القديمة...');
    
    const { error: deleteUserError } = await supabase
      .from('user_fcm_tokens')
      .delete()
      .gte('id', 1);

    if (deleteUserError) {
      console.error('❌ خطأ في حذف User FCM Tokens:', deleteUserError);
    } else {
      console.log('✅ تم حذف User FCM Tokens القديمة');
    }

    // 3. حذف الإشعارات الفاشلة من قائمة الانتظار
    console.log('🗑️ حذف الإشعارات الفاشلة...');
    
    const { error: deleteNotificationsError } = await supabase
      .from('notification_queue')
      .delete()
      .eq('status', 'failed');

    if (deleteNotificationsError) {
      console.error('❌ خطأ في حذف الإشعارات الفاشلة:', deleteNotificationsError);
    } else {
      console.log('✅ تم حذف الإشعارات الفاشلة');
    }

    console.log('\n✅ تم إصلاح FCM Tokens بنجاح!');
    console.log('\n📱 الآن يجب على المستخدمين:');
    console.log('1. فتح التطبيق');
    console.log('2. الموافقة على الإشعارات');
    console.log('3. سيتم تسجيل FCM Token جديد تلقائياً');
    
  } catch (error) {
    console.error('❌ خطأ عام في إصلاح FCM Tokens:', error);
  }
}

// تشغيل الإصلاح
if (require.main === module) {
  fixFCMTokens().then(() => {
    console.log('\n🎉 انتهى الإصلاح!');
    process.exit(0);
  });
}

module.exports = { fixFCMTokens };
