// إعداد Supabase
const { createClient } = require('@supabase/supabase-js');

// إعدادات Supabase
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

// إنشاء عميل Supabase للمستخدمين العاديين
const supabase = createClient(supabaseUrl, supabaseAnonKey);

// إنشاء عميل Supabase للعمليات الإدارية
const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

module.exports = {
  supabase,
  supabaseAdmin
};
