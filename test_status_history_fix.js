const { createClient } = require('@supabase/supabase-js');

// إعداد Supabase
const supabaseUrl = process.env.SUPABASE_URL || 'https://xtdqhqjqjqjqjqjqjqjq.supabase.co';
const supabaseKey = process.env.SUPABASE_ANON_KEY || 'your-anon-key';
const supabase = createClient(supabaseUrl, supabaseKey);

async function testStatusHistoryFix() {
  try {
    console.log('🧪 اختبار إصلاح تكرار سجل الحالات...');

    // 1. جلب طلب للاختبار
    const { data: orders, error: ordersError } = await supabase
      .from('orders')
      .select('id, status')
      .limit(1);

    if (ordersError || !orders || orders.length === 0) {
      console.error('❌ لا توجد طلبات للاختبار');
      return;
    }

    const testOrder = orders[0];
    console.log(`✅ طلب الاختبار: ${testOrder.id}`);

    // 2. فحص سجل الحالات الحالي
    const { data: currentHistory, error: historyError } = await supabase
      .from('order_status_history')
      .select('*')
      .eq('order_id', testOrder.id)
      .order('created_at', { ascending: false })
      .limit(5);

    if (historyError) {
      console.error('❌ خطأ في جلب سجل الحالات:', historyError);
      return;
    }

    console.log(`📋 عدد سجلات الحالة الحالية: ${currentHistory.length}`);
    
    if (currentHistory.length > 0) {
      console.log('📝 آخر سجلات الحالة:');
      currentHistory.forEach((record, index) => {
        console.log(`   ${index + 1}. ${record.old_status} → ${record.new_status} (${record.created_at}) - ${record.changed_by}`);
      });
    }

    // 3. فحص التكرار في آخر ساعة
    const oneHourAgo = new Date(Date.now() - 3600000).toISOString();
    
    const { data: recentHistory } = await supabase
      .from('order_status_history')
      .select('new_status, created_at, changed_by')
      .eq('order_id', testOrder.id)
      .gte('created_at', oneHourAgo)
      .order('created_at', { ascending: false });

    if (recentHistory && recentHistory.length > 1) {
      console.log('\n🔍 فحص التكرار في آخر ساعة:');
      
      const statusGroups = {};
      recentHistory.forEach(record => {
        const key = `${record.new_status}_${new Date(record.created_at).getMinutes()}`;
        if (!statusGroups[key]) {
          statusGroups[key] = [];
        }
        statusGroups[key].push(record);
      });

      let duplicatesFound = false;
      Object.keys(statusGroups).forEach(key => {
        if (statusGroups[key].length > 1) {
          duplicatesFound = true;
          console.log(`⚠️ تكرار وجد: ${statusGroups[key].length} سجل لنفس الحالة في نفس الدقيقة`);
          statusGroups[key].forEach((record, index) => {
            console.log(`     ${index + 1}. ${record.new_status} - ${record.created_at} - ${record.changed_by}`);
          });
        }
      });

      if (!duplicatesFound) {
        console.log('✅ لا توجد سجلات مكررة في آخر ساعة');
      }
    } else {
      console.log('✅ لا توجد سجلات كافية للفحص');
    }

    console.log('\n✅ انتهى اختبار سجل الحالات');

  } catch (error) {
    console.error('❌ خطأ في الاختبار:', error.message);
  }
}

// تشغيل الاختبار
testStatusHistoryFix();
