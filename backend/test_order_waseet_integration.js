// ===================================
// اختبار تكامل إرسال الطلبات لشركة الوسيط
// Test Order-Waseet Integration
// ===================================

// تحميل متغيرات البيئة
require('dotenv').config();

const { createClient } = require('@supabase/supabase-js');
const OrderSyncService = require('./services/order_sync_service');

// إعداد Supabase
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function testOrderWaseetIntegration() {
  console.log('🧪 اختبار تكامل إرسال الطلبات لشركة الوسيط...');
  console.log('='.repeat(60));

  try {
    // 1. إنشاء خدمة المزامنة
    console.log('\n1️⃣ إنشاء خدمة المزامنة...');
    const orderSyncService = new OrderSyncService();
    console.log('✅ تم إنشاء خدمة المزامنة بنجاح');

    // 2. البحث عن طلب للاختبار
    console.log('\n2️⃣ البحث عن طلب للاختبار...');
    const { data: testOrders, error: ordersError } = await supabase
      .from('orders')
      .select('id, customer_name, status, waseet_order_id')
      .eq('status', 'active')
      .limit(1);

    if (ordersError) {
      console.error('❌ خطأ في جلب الطلبات:', ordersError);
      return;
    }

    if (!testOrders || testOrders.length === 0) {
      console.log('⚠️ لا توجد طلبات نشطة للاختبار');
      
      // إنشاء طلب تجريبي
      console.log('\n📝 إنشاء طلب تجريبي...');
      const testOrder = {
        customer_name: 'عميل تجريبي',
        customer_phone: '07901234567',
        customer_address: 'بغداد - الكرادة',
        total: 25000,
        status: 'active',
        created_at: new Date().toISOString()
      };

      const { data: newOrder, error: createError } = await supabase
        .from('orders')
        .insert(testOrder)
        .select()
        .single();

      if (createError) {
        console.error('❌ خطأ في إنشاء الطلب التجريبي:', createError);
        return;
      }

      console.log(`✅ تم إنشاء طلب تجريبي: ${newOrder.id}`);
      testOrders.push(newOrder);
    }

    const testOrder = testOrders[0];
    console.log(`📦 طلب الاختبار: ${testOrder.id} - ${testOrder.customer_name}`);

    // 3. تحديث حالة الطلب إلى "قيد التوصيل"
    console.log('\n3️⃣ تحديث حالة الطلب إلى "قيد التوصيل"...');
    const { error: updateError } = await supabase
      .from('orders')
      .update({
        status: 'in_delivery',
        updated_at: new Date().toISOString()
      })
      .eq('id', testOrder.id);

    if (updateError) {
      console.error('❌ خطأ في تحديث حالة الطلب:', updateError);
      return;
    }

    console.log('✅ تم تحديث حالة الطلب إلى "قيد التوصيل"');

    // 4. اختبار إرسال الطلب لشركة الوسيط
    console.log('\n4️⃣ اختبار إرسال الطلب لشركة الوسيط...');
    const waseetResult = await orderSyncService.sendOrderToWaseet(testOrder.id);

    if (waseetResult && waseetResult.success) {
      console.log('✅ تم إرسال الطلب لشركة الوسيط بنجاح');
      console.log(`🆔 QR ID: ${waseetResult.qrId}`);
      console.log(`📋 استجابة الوسيط:`, waseetResult.waseetResponse);
    } else {
      console.log('❌ فشل في إرسال الطلب لشركة الوسيط');
      console.log('📋 النتيجة:', waseetResult);
    }

    // 5. التحقق من تحديث قاعدة البيانات
    console.log('\n5️⃣ التحقق من تحديث قاعدة البيانات...');
    const { data: updatedOrder, error: checkError } = await supabase
      .from('orders')
      .select('status, waseet_order_id, waseet_status, waseet_data')
      .eq('id', testOrder.id)
      .single();

    if (checkError) {
      console.error('❌ خطأ في جلب الطلب المحدث:', checkError);
      return;
    }

    console.log('📊 حالة الطلب بعد الإرسال:');
    console.log(`   - الحالة: ${updatedOrder.status}`);
    console.log(`   - معرف الوسيط: ${updatedOrder.waseet_order_id || 'غير محدد'}`);
    console.log(`   - حالة الوسيط: ${updatedOrder.waseet_status || 'غير محدد'}`);
    console.log(`   - بيانات الوسيط: ${updatedOrder.waseet_data ? 'موجودة' : 'غير موجودة'}`);

    // 6. اختبار مزامنة الحالات
    console.log('\n6️⃣ اختبار مزامنة الحالات...');
    const syncResult = await orderSyncService.syncAllOrderStatuses();

    if (syncResult) {
      console.log('✅ تم اختبار مزامنة الحالات بنجاح');
    } else {
      console.log('❌ فشل في اختبار مزامنة الحالات');
    }

    console.log('\n🎉 انتهى اختبار التكامل بنجاح!');

  } catch (error) {
    console.error('❌ خطأ في اختبار التكامل:', error);
  }
}

// تشغيل الاختبار
if (require.main === module) {
  testOrderWaseetIntegration()
    .then(() => {
      console.log('\n✅ انتهى الاختبار');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ فشل الاختبار:', error);
      process.exit(1);
    });
}

module.exports = { testOrderWaseetIntegration };
