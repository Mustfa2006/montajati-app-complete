const { createClient } = require('@supabase/supabase-js');

// إعداد Supabase
const supabaseUrl = process.env.SUPABASE_URL || 'https://xtdqhqjqjqjqjqjqjqjq.supabase.co';
const supabaseKey = process.env.SUPABASE_ANON_KEY || 'your-anon-key';
const supabase = createClient(supabaseUrl, supabaseKey);

async function updateMerchantView() {
  try {
    console.log('🔄 تحديث view لعرض معلومات التاجر الصحيحة...');

    // تحديث الـ view
    const { error } = await supabase.rpc('exec_sql', {
      sql: `
        CREATE OR REPLACE VIEW order_details_view AS
        SELECT
            o.id,
            o.order_number,
            o.customer_name,
            o.customer_phone,
            o.customer_alternate_phone,
            o.customer_province,
            o.customer_city,
            o.customer_address,
            o.customer_notes,
            o.status,
            o.total_amount,
            o.delivery_cost,
            o.profit_amount,
            o.created_at,
            o.updated_at,
            u.name as user_name,
            u.phone as user_phone,
            COUNT(oi.id) as items_count,
            COALESCE(SUM(oi.profit_per_item * oi.quantity), 0) as calculated_profit
        FROM orders o
        LEFT JOIN users u ON o.user_phone = u.phone
        LEFT JOIN order_items oi ON o.id = oi.order_id
        GROUP BY o.id, u.name, u.phone
        ORDER BY o.created_at DESC;
      `
    });

    if (error) {
      throw error;
    }

    console.log('✅ تم تحديث view بنجاح');

    // اختبار الـ view الجديد
    console.log('\n🧪 اختبار الـ view الجديد...');
    const { data: testData, error: testError } = await supabase
      .from('order_details_view')
      .select('id, user_name, user_phone')
      .limit(3);

    if (testError) {
      console.error('❌ خطأ في اختبار الـ view:', testError);
    } else {
      console.log('✅ نتائج الاختبار:');
      testData.forEach((order, index) => {
        console.log(`${index + 1}. طلب ${order.id}: التاجر: ${order.user_name || 'غير محدد'}, الهاتف: ${order.user_phone || 'غير محدد'}`);
      });
    }

  } catch (error) {
    console.error('❌ خطأ في تحديث view:', error.message);
  }
}

// تشغيل التحديث
updateMerchantView();