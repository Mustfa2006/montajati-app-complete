// ===================================
// اختبار تحديث حالة الطلبات
// ===================================

const { createClient } = require('@supabase/supabase-js');
const axios = require('axios');

// إعداد Supabase
const supabaseUrl = process.env.SUPABASE_URL || 'https://fqdhskaolzfavapmqodl.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZxZGhza2FvbHpmYXZhcG1xb2RsIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MDA4MTcyNiwiZXhwIjoyMDY1NjU3NzI2fQ.tRHMAogrSzjRwSIJ9-m0YMoPhlHeR6U8kfob0wyvf_I';
const supabase = createClient(supabaseUrl, supabaseKey);

// رابط الخادم
const serverUrl = 'https://montajati-backend.onrender.com';

async function testOrderStatusUpdate() {
  console.log('🧪 === اختبار تحديث حالة الطلبات ===\n');

  try {
    // 1. جلب طلب للاختبار
    console.log('1️⃣ البحث عن طلب للاختبار...');
    const { data: orders, error: fetchError } = await supabase
      .from('orders')
      .select('id, order_number, status, customer_name')
      .limit(1);

    if (fetchError || !orders || orders.length === 0) {
      console.log('❌ لا توجد طلبات للاختبار');
      return;
    }

    const testOrder = orders[0];
    console.log(`✅ تم العثور على طلب للاختبار:`);
    console.log(`   📦 معرف الطلب: ${testOrder.id}`);
    console.log(`   🔢 رقم الطلب: ${testOrder.order_number}`);
    console.log(`   📊 الحالة الحالية: ${testOrder.status}`);
    console.log(`   👤 العميل: ${testOrder.customer_name}\n`);

    // 2. اختبار تحديث الحالة عبر API
    console.log('2️⃣ اختبار تحديث الحالة عبر API...');
    
    const newStatus = testOrder.status === 'active' ? 'in_delivery' : 'active';
    console.log(`🔄 تغيير الحالة من "${testOrder.status}" إلى "${newStatus}"`);

    try {
      const response = await axios.put(
        `${serverUrl}/api/orders/${testOrder.id}/status`,
        {
          status: newStatus,
          notes: 'اختبار تحديث الحالة من سكريبت الاختبار',
          changedBy: 'test_script'
        },
        {
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          },
          timeout: 30000
        }
      );

      console.log(`✅ نجح تحديث الحالة عبر API:`);
      console.log(`   📊 كود الاستجابة: ${response.status}`);
      console.log(`   📝 الرسالة: ${response.data.message}`);
      console.log(`   🔄 الحالة القديمة: ${response.data.data.oldStatus}`);
      console.log(`   🔄 الحالة الجديدة: ${response.data.data.newStatus}\n`);

    } catch (apiError) {
      console.error('❌ فشل في تحديث الحالة عبر API:');
      console.error(`   📊 كود الخطأ: ${apiError.response?.status || 'غير معروف'}`);
      console.error(`   📝 رسالة الخطأ: ${apiError.response?.data?.error || apiError.message}`);
      console.error(`   🔗 الرابط: ${serverUrl}/api/orders/${testOrder.id}/status\n`);
      return;
    }

    // 3. التحقق من التحديث في قاعدة البيانات
    console.log('3️⃣ التحقق من التحديث في قاعدة البيانات...');
    
    const { data: updatedOrder, error: verifyError } = await supabase
      .from('orders')
      .select('id, status, updated_at')
      .eq('id', testOrder.id)
      .single();

    if (verifyError) {
      console.error('❌ خطأ في التحقق من التحديث:', verifyError.message);
      return;
    }

    console.log(`✅ تم التحقق من التحديث في قاعدة البيانات:`);
    console.log(`   📊 الحالة المحدثة: ${updatedOrder.status}`);
    console.log(`   ⏰ وقت التحديث: ${updatedOrder.updated_at}`);
    
    if (updatedOrder.status === newStatus) {
      console.log(`🎉 نجح الاختبار! تم تحديث الحالة بنجاح\n`);
    } else {
      console.log(`❌ فشل الاختبار! الحالة لم تتحدث كما متوقع\n`);
    }

    // 4. فحص سجل تاريخ الحالات
    console.log('4️⃣ فحص سجل تاريخ الحالات...');
    
    const { data: statusHistory, error: historyError } = await supabase
      .from('order_status_history')
      .select('*')
      .eq('order_id', testOrder.id)
      .order('created_at', { ascending: false })
      .limit(1);

    if (historyError) {
      console.warn('⚠️ تحذير: لا يمكن فحص سجل التاريخ:', historyError.message);
    } else if (statusHistory && statusHistory.length > 0) {
      const latestHistory = statusHistory[0];
      console.log(`✅ تم العثور على سجل تاريخ الحالة:`);
      console.log(`   🔄 من: ${latestHistory.old_status} إلى: ${latestHistory.new_status}`);
      console.log(`   👤 بواسطة: ${latestHistory.changed_by}`);
      console.log(`   📝 السبب: ${latestHistory.change_reason}`);
    } else {
      console.log(`⚠️ لم يتم العثور على سجل تاريخ الحالة`);
    }

  } catch (error) {
    console.error('❌ خطأ عام في الاختبار:', error.message);
  }

  console.log('\n🏁 انتهى الاختبار');
}

// تشغيل الاختبار
if (require.main === module) {
  testOrderStatusUpdate();
}

module.exports = testOrderStatusUpdate;
