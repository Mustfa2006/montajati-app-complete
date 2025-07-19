const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(
  process.env.SUPABASE_URL, // URL الخاص بـ Supabase
  process.env.SUPABASE_SERVICE_ROLE_KEY // مفتاح الخدمة الخاص بـ Supabase
);

module.exports = supabase;
