console.log('🔄 اختبار تحديث مباشر...');

// اختبار تحديث مباشر في قاعدة البيانات
async function testDirectUpdate() {
  try {
    require('dotenv').config();
    
    const { createClient } = require('@supabase/supabase-js');
    const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);
    
    console.log('🔍 فحص الطلب قبل التحديث...');
    const { data: beforeData } = await supabase
      .from('orders')
      .select('id, status, waseet_status, waseet_status_id, waseet_status_text')
      .eq('id', 'order_1754571218521_7589')
      .single();
    
    console.log('📋 قبل التحديث:', beforeData);
    
    console.log('🔄 تحديث الطلب...');
    const { data: updateData, error: updateError } = await supabase
      .from('orders')
      .update({
        status: 'الغاء الطلب',
        waseet_status: 'الغاء الطلب',
        waseet_status_id: 23,
        waseet_status_text: 'ارسال الى مخزن الارجاعات',
        last_status_check: new Date().toISOString(),
        status_updated_at: new Date().toISOString()
      })
      .eq('id', 'order_1754571218521_7589')
      .select();
    
    if (updateError) {
      console.error('❌ خطأ في التحديث:', updateError);
    } else {
      console.log('✅ تم التحديث بنجاح:', updateData);
    }
    
    console.log('🔍 فحص الطلب بعد التحديث...');
    const { data: afterData } = await supabase
      .from('orders')
      .select('id, status, waseet_status, waseet_status_id, waseet_status_text')
      .eq('id', 'order_1754571218521_7589')
      .single();
    
    console.log('📋 بعد التحديث:', afterData);
    
  } catch (error) {
    console.error('❌ خطأ:', error);
  }
  
  process.exit(0);
}

testDirectUpdate();
