// ===================================
// فحص حالة الطلب الذي تم إنشاؤه
// Check Order Status
// ===================================

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

async function checkOrderStatus() {
  console.log('🔍 فحص حالة الطلبات الأخيرة...');
  console.log('='.repeat(50));

  try {
    // إنشاء عميل Supabase
    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    // جلب آخر 5 طلبات
    const { data: orders, error } = await supabase
      .from('orders')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(5);

    if (error) {
      console.error('❌ خطأ في جلب الطلبات:', error);
      return;
    }

    console.log(`📦 تم العثور على ${orders.length} طلب`);

    orders.forEach((order, index) => {
      console.log(`\n📋 الطلب ${index + 1}:`);
      console.log(`   🆔 المعرف: ${order.id}`);
      console.log(`   👤 العميل: ${order.customer_name}`);
      console.log(`   📞 الهاتف: ${order.customer_phone}`);
      console.log(`   📊 الحالة: ${order.status}`);
      console.log(`   🕐 تاريخ الإنشاء: ${order.created_at}`);
      console.log(`   🕐 آخر تحديث: ${order.updated_at}`);
      
      // فحص بيانات الوسيط
      console.log(`   🚚 معرف الوسيط: ${order.waseet_order_id || 'غير محدد'}`);
      console.log(`   📋 حالة الوسيط: ${order.waseet_status || 'غير محدد'}`);
      
      if (order.waseet_data) {
        try {
          const waseetData = JSON.parse(order.waseet_data);
          console.log(`   📋 بيانات الوسيط: موجودة`);
          
          if (waseetData.error) {
            console.log(`   ❌ خطأ الوسيط: ${waseetData.error}`);
          }
          
          if (waseetData.qrId) {
            console.log(`   🆔 QR ID: ${waseetData.qrId}`);
          }
          
          if (waseetData.success) {
            console.log(`   ✅ حالة الإرسال: نجح`);
          }
        } catch (e) {
          console.log(`   ❌ بيانات الوسيط غير قابلة للقراءة`);
        }
      } else {
        console.log(`   ⚠️ لا توجد بيانات وسيط`);
      }
    });

    // البحث عن طلبات في حالة "قيد التوصيل"
    console.log('\n🔍 البحث عن طلبات في حالة "قيد التوصيل"...');
    
    const { data: deliveryOrders, error: deliveryError } = await supabase
      .from('orders')
      .select('*')
      .or('status.eq.قيد التوصيل الى الزبون (في عهدة المندوب),status.eq.قيد التوصيل,status.eq.in_delivery')
      .order('updated_at', { ascending: false });

    if (deliveryError) {
      console.error('❌ خطأ في البحث:', deliveryError);
    } else {
      console.log(`📦 تم العثور على ${deliveryOrders.length} طلب في حالة توصيل`);
      
      deliveryOrders.forEach((order, index) => {
        console.log(`\n🚚 طلب التوصيل ${index + 1}:`);
        console.log(`   🆔 المعرف: ${order.id}`);
        console.log(`   📊 الحالة: ${order.status}`);
        console.log(`   🚚 معرف الوسيط: ${order.waseet_order_id || 'غير محدد'}`);
        console.log(`   📋 حالة الوسيط: ${order.waseet_status || 'غير محدد'}`);
        console.log(`   🕐 آخر تحديث: ${order.updated_at}`);
        
        if (!order.waseet_order_id && order.waseet_status !== 'sent') {
          console.log(`   ⚠️ هذا الطلب لم يُرسل للوسيط!`);
        }
      });
    }

  } catch (error) {
    console.error('❌ خطأ عام:', error);
  }
}

// تشغيل الفحص
checkOrderStatus()
  .then(() => {
    console.log('\n✅ انتهى فحص الطلبات');
  })
  .catch((error) => {
    console.error('\n❌ خطأ في تشغيل الفحص:', error);
  });
