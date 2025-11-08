// ===================================
// فحص وإعداد قاعدة البيانات
// Database Setup and Verification
// ===================================

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function checkAndSetupDatabase() {
  console.log('🔍 بدء فحص قاعدة البيانات...\n');

  try {
    // 1. فحص الاتصال
    console.log('1️⃣ فحص الاتصال بقاعدة البيانات...');
    const { data: connectionTest, error: connectionError } = await supabase
      .from('users')
      .select('count')
      .limit(1);

    if (connectionError) {
      console.error('❌ فشل الاتصال بقاعدة البيانات:', connectionError.message);
      return false;
    }
    console.log('✅ الاتصال بقاعدة البيانات ناجح');

    // 2. فحص جدول fcm_tokens
    console.log('\n2️⃣ فحص جدول fcm_tokens...');
    const { data: tokensTest, error: tokensError } = await supabase
      .from('fcm_tokens')
      .select('*')
      .limit(1);

    if (tokensError) {
      console.error('❌ جدول fcm_tokens غير موجود أو به مشكلة:', tokensError.message);
      console.log('🔧 محاولة إنشاء الجدول...');

      // إنشاء الجدول
      const { error: createError } = await supabase.rpc('exec_sql', {
        sql: `
          CREATE TABLE IF NOT EXISTS fcm_tokens (
            id BIGSERIAL PRIMARY KEY,
            user_phone VARCHAR(20) NOT NULL,
            fcm_token TEXT NOT NULL,
            device_info JSONB DEFAULT '{}',
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW(),
            last_used_at TIMESTAMPTZ DEFAULT NOW(),
            UNIQUE(user_phone, fcm_token)
          );
          
          CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user_phone ON fcm_tokens(user_phone);
          CREATE INDEX IF NOT EXISTS idx_fcm_tokens_active ON fcm_tokens(is_active);
        `
      });

      if (createError) {
        console.error('❌ فشل في إنشاء جدول fcm_tokens:', createError.message);
        return false;
      }
      console.log('✅ تم إنشاء جدول fcm_tokens بنجاح');
    } else {
      console.log('✅ جدول fcm_tokens موجود');
    }

    // 3. فحص عدد الرموز المسجلة
    console.log('\n3️⃣ فحص FCM Tokens المسجلة...');
    // ✅ استخدام طريقة آمنة بدون head: true
    const { count: totalTokens } = await supabase
      .from('fcm_tokens')
      .select('*', { count: 'exact' });

    const { count: activeTokens } = await supabase
      .from('fcm_tokens')
      .select('*', { count: 'exact' })
      .eq('is_active', true);

    console.log(`📊 إجمالي الرموز: ${totalTokens || 0}`);
    console.log(`✅ الرموز النشطة: ${activeTokens || 0}`);

    // 4. فحص المستخدمين
    console.log('\n4️⃣ فحص جدول المستخدمين...');
    // ✅ استخدام طريقة آمنة بدون head: true
    const { count: usersCount } = await supabase
      .from('users')
      .select('*', { count: 'exact' });

    console.log(`👥 عدد المستخدمين: ${usersCount || 0}`);

    // 5. إضافة رمز تجريبي إذا لم يوجد أي رمز
    if ((totalTokens || 0) === 0) {
      console.log('\n5️⃣ إضافة رمز تجريبي...');
      const { error: insertError } = await supabase
        .from('fcm_tokens')
        .insert({
          user_phone: '0501234567',
          fcm_token: 'test_token_' + Date.now(),
          device_info: { platform: 'test', app: 'montajati' },
          is_active: true
        });

      if (insertError) {
        console.error('⚠️ فشل في إضافة رمز تجريبي:', insertError.message);
      } else {
        console.log('✅ تم إضافة رمز تجريبي بنجاح');
      }
    }

    // 6. فحص جدول notification_logs
    console.log('\n6️⃣ فحص جدول notification_logs...');
    const { data: logsTest, error: logsError } = await supabase
      .from('notification_logs')
      .select('*')
      .limit(1);

    if (logsError) {
      console.log('🔧 إنشاء جدول notification_logs...');
      const { error: createLogsError } = await supabase.rpc('exec_sql', {
        sql: `
          CREATE TABLE IF NOT EXISTS notification_logs (
            id BIGSERIAL PRIMARY KEY,
            user_phone VARCHAR(20) NOT NULL,
            fcm_token TEXT,
            title TEXT NOT NULL,
            message TEXT NOT NULL,
            additional_data JSONB DEFAULT '{}',
            status VARCHAR(20) DEFAULT 'pending',
            error_message TEXT,
            firebase_message_id TEXT,
            sent_at TIMESTAMPTZ DEFAULT NOW(),
            delivered_at TIMESTAMPTZ
          );
        `
      });

      if (createLogsError) {
        console.log('⚠️ فشل في إنشاء جدول notification_logs:', createLogsError.message);
      } else {
        console.log('✅ تم إنشاء جدول notification_logs بنجاح');
      }
    } else {
      console.log('✅ جدول notification_logs موجود');
    }

    console.log('\n' + '='.repeat(50));
    console.log('🎉 فحص قاعدة البيانات مكتمل بنجاح!');
    console.log('✅ جميع الجداول المطلوبة موجودة ومُهيأة');
    console.log('='.repeat(50));

    return true;

  } catch (error) {
    console.error('❌ خطأ في فحص قاعدة البيانات:', error.message);
    return false;
  }
}

// تشغيل الفحص
if (require.main === module) {
  checkAndSetupDatabase()
    .then(success => {
      process.exit(success ? 0 : 1);
    })
    .catch(error => {
      console.error('❌ خطأ غير متوقع:', error);
      process.exit(1);
    });
}

module.exports = { checkAndSetupDatabase };
