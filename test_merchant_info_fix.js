const { createClient } = require('@supabase/supabase-js');

// إعداد Supabase
const supabaseUrl = process.env.SUPABASE_URL || 'https://xtdqhqjqjqjqjqjqjqjq.supabase.co';
const supabaseKey = process.env.SUPABASE_ANON_KEY || 'your-anon-key';
const supabase = createClient(supabaseUrl, supabaseKey);

async function testMerchantInfoFix() {
  try {
    console.log('🧪 اختبار إصلاح عرض معلومات التاجر...');

    // 1. اختبار جلب طلب موجود
    console.log('\n📋 1. جلب طلب موجود لاختبار معلومات التاجر...');
    const { data: orders, error: ordersError } = await supabase
      .from('orders')
      .select('id, user_phone')
      .not('user_phone', 'is', null)
      .limit(1);

    if (ordersError) {
      console.error('❌ خطأ في جلب الطلبات:', ordersError);
      return;
    }

    if (!orders || orders.length === 0) {
      console.log('⚠️ لا توجد طلبات مع user_phone');
      return;
    }

    const testOrder = orders[0];
    console.log(`✅ تم العثور على طلب للاختبار: ${testOrder.id}`);
    console.log(`📱 رقم هاتف التاجر: ${testOrder.user_phone}`);

    // 2. اختبار جلب معلومات التاجر من جدول users
    console.log('\n👤 2. جلب معلومات التاجر من جدول users...');
    const { data: userData, error: userError } = await supabase
      .from('users')
      .select('name, phone')
      .eq('phone', testOrder.user_phone)
      .single();

    if (userError) {
      console.error('❌ خطأ في جلب معلومات التاجر:', userError);
    } else {
      console.log(`✅ اسم التاجر: ${userData.name}`);
      console.log(`📱 هاتف التاجر: ${userData.phone}`);
    }

    // 3. اختبار الـ view المحدث
    console.log('\n🔍 3. اختبار الـ view المحدث...');
    const { data: viewData, error: viewError } = await supabase
      .from('order_details_view')
      .select('id, user_name, user_phone')
      .eq('id', testOrder.id)
      .single();

    if (viewError) {
      console.error('❌ خطأ في جلب البيانات من الـ view:', viewError);
    } else {
      console.log(`✅ اسم التاجر من الـ view: ${viewData.user_name || 'غير محدد'}`);
      console.log(`📱 هاتف التاجر من الـ view: ${viewData.user_phone || 'غير محدد'}`);
    }

    // 4. إنشاء طلب اختبار جديد
    console.log('\n📦 4. إنشاء طلب اختبار جديد...');
    const testOrderId = `TEST_${Date.now()}`;
    const testUserPhone = '07503597589';

    const { error: insertError } = await supabase
      .from('orders')
      .insert({
        id: testOrderId,
        customer_name: 'عميل اختبار',
        primary_phone: '07901234567',
        province: 'بغداد',
        city: 'الكرادة',
        customer_address: 'بغداد - الكرادة',
        subtotal: 25000,
        delivery_fee: 5000,
        total: 30000,
        profit: 5000,
        status: 'active',
        user_phone: testUserPhone,
        order_number: `ORD-TEST-${Date.now()}`,
        notes: 'طلب اختبار لفحص معلومات التاجر'
      });

    if (insertError) {
      console.error('❌ خطأ في إنشاء طلب الاختبار:', insertError);
    } else {
      console.log(`✅ تم إنشاء طلب اختبار: ${testOrderId}`);

      // 5. اختبار جلب الطلب الجديد مع معلومات التاجر
      console.log('\n🔍 5. اختبار جلب الطلب الجديد مع معلومات التاجر...');
      const { data: newOrderData, error: newOrderError } = await supabase
        .from('order_details_view')
        .select('id, user_name, user_phone')
        .eq('id', testOrderId)
        .single();

      if (newOrderError) {
        console.error('❌ خطأ في جلب الطلب الجديد:', newOrderError);
      } else {
        console.log(`✅ الطلب الجديد - اسم التاجر: ${newOrderData.user_name || 'غير محدد'}`);
        console.log(`📱 الطلب الجديد - هاتف التاجر: ${newOrderData.user_phone || 'غير محدد'}`);
      }

      // تنظيف: حذف طلب الاختبار
      await supabase.from('orders').delete().eq('id', testOrderId);
      console.log('🗑️ تم حذف طلب الاختبار');
    }

    console.log('\n✅ انتهى اختبار إصلاح معلومات التاجر');

  } catch (error) {
    console.error('❌ خطأ في الاختبار:', error.message);
  }
}

// تشغيل الاختبار
testMerchantInfoFix();
