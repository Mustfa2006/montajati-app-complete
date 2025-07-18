// ===================================
// إصلاح نظام FCM Tokens الموحد
// ===================================

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function fixFCMSystem() {
  console.log('🔧 إصلاح نظام FCM Tokens...');
  
  try {
    // 1. التأكد من وجود جدول user_fcm_tokens
    console.log('📋 فحص جدول user_fcm_tokens...');
    
    // فحص وجود الجدول مباشرة
    const { data: tables, error: tablesError } = await supabase
      .from('user_fcm_tokens')
      .select('id')
      .limit(1);
    
    if (tablesError && tablesError.message.includes('does not exist')) {
      console.log('📝 إنشاء جدول user_fcm_tokens...');
      
      const { error: createError } = await supabase.rpc('exec_sql', {
        sql: `
          CREATE TABLE IF NOT EXISTS user_fcm_tokens (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            user_id UUID REFERENCES users(id) ON DELETE CASCADE,
            user_phone VARCHAR(20) NOT NULL,
            fcm_token TEXT NOT NULL,
            platform VARCHAR(20) DEFAULT 'android',
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
          );
          
          CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_user_id ON user_fcm_tokens(user_id);
          CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_phone ON user_fcm_tokens(user_phone);
          CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_active ON user_fcm_tokens(is_active);
          
          CREATE OR REPLACE FUNCTION update_updated_at_column()
          RETURNS TRIGGER AS $$
          BEGIN
              NEW.updated_at = NOW();
              RETURN NEW;
          END;
          $$ language 'plpgsql';
          
          CREATE TRIGGER update_user_fcm_tokens_updated_at 
              BEFORE UPDATE ON user_fcm_tokens 
              FOR EACH ROW 
              EXECUTE FUNCTION update_updated_at_column();
        `
      });
      
      if (createError) {
        console.error('❌ خطأ في إنشاء الجدول:', createError.message);
        return;
      }
      
      console.log('✅ تم إنشاء جدول user_fcm_tokens');
    } else {
      console.log('✅ جدول user_fcm_tokens موجود');
    }
    
    // 2. نقل FCM tokens من جدول users إلى user_fcm_tokens
    console.log('🔄 نقل FCM tokens من جدول users...');
    
    const { data: usersWithTokens, error: usersError } = await supabase
      .from('users')
      .select('id, phone, fcm_token')
      .not('fcm_token', 'is', null)
      .not('fcm_token', 'eq', '');
    
    if (usersError) {
      console.error('❌ خطأ في جلب المستخدمين:', usersError.message);
    } else if (usersWithTokens && usersWithTokens.length > 0) {
      console.log(`📱 تم العثور على ${usersWithTokens.length} مستخدم لديهم FCM tokens`);
      
      for (const user of usersWithTokens) {
        try {
          const { error: upsertError } = await supabase
            .from('user_fcm_tokens')
            .upsert({
              user_id: user.id,
              user_phone: user.phone || 'unknown',
              fcm_token: user.fcm_token,
              platform: 'android',
              is_active: true,
              updated_at: new Date().toISOString()
            }, {
              onConflict: 'user_id,platform'
            });
          
          if (upsertError) {
            console.error(`❌ خطأ في نقل token للمستخدم ${user.id}:`, upsertError.message);
          } else {
            console.log(`✅ تم نقل token للمستخدم ${user.phone}`);
          }
        } catch (error) {
          console.error(`❌ خطأ في معالجة المستخدم ${user.id}:`, error.message);
        }
      }
    } else {
      console.log('📱 لا توجد FCM tokens في جدول users للنقل');
    }
    
    // 3. إضافة FCM tokens تجريبية للاختبار
    console.log('🧪 إضافة FCM tokens تجريبية...');
    
    const testTokens = [
      {
        user_phone: '07503597589',
        fcm_token: `test_token_admin_${Date.now()}`,
        platform: 'android'
      },
      {
        user_phone: '07801234567',
        fcm_token: `test_token_user_${Date.now()}`,
        platform: 'android'
      }
    ];
    
    for (const testToken of testTokens) {
      const { error: testError } = await supabase
        .from('user_fcm_tokens')
        .upsert({
          ...testToken,
          is_active: true,
          updated_at: new Date().toISOString()
        });
      
      if (testError) {
        console.error(`❌ خطأ في إضافة token تجريبي لـ ${testToken.user_phone}:`, testError.message);
      } else {
        console.log(`✅ تم إضافة token تجريبي لـ ${testToken.user_phone}`);
      }
    }
    
    // 4. فحص النتائج النهائية
    console.log('\n📊 فحص النتائج النهائية...');
    
    const { data: finalTokens, error: finalError } = await supabase
      .from('user_fcm_tokens')
      .select('*')
      .eq('is_active', true);
    
    if (finalError) {
      console.error('❌ خطأ في فحص النتائج:', finalError.message);
    } else {
      console.log(`✅ إجمالي FCM tokens نشطة: ${finalTokens?.length || 0}`);
      
      if (finalTokens && finalTokens.length > 0) {
        finalTokens.forEach(token => {
          console.log(`📱 ${token.user_phone} - ${token.platform} - ${token.fcm_token.substring(0, 20)}...`);
        });
      }
    }
    
    console.log('\n🎉 تم إصلاح نظام FCM Tokens بنجاح!');
    
  } catch (error) {
    console.error('❌ خطأ عام في إصلاح النظام:', error.message);
  }
}

// تشغيل الإصلاح
fixFCMSystem();
