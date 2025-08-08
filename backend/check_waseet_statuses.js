console.log('🔍 فحص جدول waseet_statuses...');

async function checkWaseetStatuses() {
  try {
    require('dotenv').config();
    
    const { createClient } = require('@supabase/supabase-js');
    const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);
    
    console.log('📊 جلب جميع الحالات من جدول waseet_statuses...');
    const { data: statuses, error } = await supabase
      .from('waseet_statuses')
      .select('*')
      .order('id');

    if (error) {
      console.error('❌ خطأ في جلب الحالات:', error);
    } else {
      console.log('📋 الحالات الموجودة:');
      console.log('📋 أول سجل كمثال:', JSON.stringify(statuses[0], null, 2));
      statuses.forEach(status => {
        console.log(`   ID=${status.id}: جميع الحقول:`, Object.keys(status));
        console.log(`   القيم:`, Object.values(status));
      });
      
      // البحث عن حالة "الغاء الطلب"
      const cancelledStatus = statuses.find(s => 
        s.name_ar && s.name_ar.includes('الغاء') || 
        s.name_ar && s.name_ar.includes('ملغي') ||
        s.name_en && s.name_en.toLowerCase().includes('cancel')
      );
      
      if (cancelledStatus) {
        console.log(`✅ وجدت حالة الإلغاء: ID=${cancelledStatus.id}, "${cancelledStatus.name_ar}"`);
      } else {
        console.log('❌ لم أجد حالة إلغاء مناسبة');
      }
    }
    
  } catch (error) {
    console.error('❌ خطأ:', error);
  }
  
  process.exit(0);
}

checkWaseetStatuses();
