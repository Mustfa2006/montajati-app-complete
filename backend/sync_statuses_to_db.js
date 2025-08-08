console.log('🔄 مزامنة حالات الوسيط مع قاعدة البيانات...');

async function syncStatusesToDB() {
  try {
    require('dotenv').config();
    
    const statusManager = require('./services/waseet_status_manager');
    
    console.log('🚀 بدء مزامنة الحالات...');
    const result = await statusManager.syncStatusesToDatabase();
    
    if (result) {
      console.log('✅ تم مزامنة الحالات بنجاح');
      
      // فحص إذا كان ID=23 موجود الآن
      const { createClient } = require('@supabase/supabase-js');
      const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);
      
      const { data: status23 } = await supabase
        .from('waseet_statuses')
        .select('*')
        .eq('id', 23)
        .single();
      
      if (status23) {
        console.log('✅ تم العثور على الحالة ID=23:', status23);
      } else {
        console.log('❌ الحالة ID=23 لا تزال غير موجودة');
      }
      
    } else {
      console.log('❌ فشل في مزامنة الحالات');
    }
    
  } catch (error) {
    console.error('❌ خطأ:', error);
  }
  
  process.exit(0);
}

syncStatusesToDB();
