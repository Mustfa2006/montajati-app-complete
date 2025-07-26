const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  'https://fqdhskaolzfavapmqodl.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZxZGhza2FvbHpmYXZhcG1xb2RsIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MDA4MTcyNiwiZXhwIjoyMDY1NjU3NzI2fQ.6G7ETs4PkK9WynRgVeZ-F_DPEf1BjaLq1-6AGeSHfIg'
);

async function checkWaseetData() {
  try {
    console.log('🔍 البحث عن آخر طلب تم إرساله للوسيط...');
    
    const { data: orders, error } = await supabase
      .from('orders')
      .select('*')
      .not('waseet_order_id', 'is', null)
      .order('updated_at', { ascending: false })
      .limit(1);
    
    if (error) {
      console.log('❌ خطأ في الاستعلام:', error);
      return;
    }
    
    if (!orders || orders.length === 0) {
      console.log('❌ لا توجد طلبات مرسلة للوسيط');
      
      // البحث عن أي طلب حديث
      const { data: recentOrders } = await supabase
        .from('orders')
        .select('*')
        .order('updated_at', { ascending: false })
        .limit(3);
      
      console.log('\n📋 آخر 3 طلبات:');
      recentOrders.forEach((order, index) => {
        console.log(`${index + 1}. ${order.id} - ${order.customer_name} - Waseet ID: ${order.waseet_order_id || 'null'}`);
      });
      
      return;
    }
    
    const order = orders[0];
    console.log('\n📦 آخر طلب مرسل للوسيط:');
    console.log('🆔 معرف الطلب:', order.id);
    console.log('👤 اسم العميل:', order.customer_name);
    console.log('🏛️ المحافظة:', order.province);
    console.log('🏙️ المدينة:', order.city);
    console.log('📍 العنوان:', order.customer_address);
    console.log('🚛 Waseet Order ID:', order.waseet_order_id);
    console.log('📊 Waseet Status:', order.waseet_status);

    // فحص البيانات الأولية المحفوظة
    console.log('\n🔍 فحص البيانات الأولية:');
    console.log('📱 primary_phone:', order.primary_phone);
    console.log('📱 secondary_phone:', order.secondary_phone);
    console.log('🆔 province_id:', order.province_id);
    console.log('🆔 city_id:', order.city_id);
    console.log('🆔 region_id:', order.region_id);
    
    if (order.waseet_data) {
      try {
        const waseetData = JSON.parse(order.waseet_data);
        console.log('\n📋 بيانات الوسيط المرسلة:');
        console.log(JSON.stringify(waseetData, null, 2));
      } catch (e) {
        console.log('❌ خطأ في تحليل بيانات الوسيط:', e.message);
        console.log('📄 البيانات الخام:', order.waseet_data);
      }
    }
    
  } catch (error) {
    console.error('❌ خطأ:', error.message);
  }
}

checkWaseetData();
