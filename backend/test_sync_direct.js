// اختبار مباشر لنظام المزامنة
require('dotenv').config();

async function testSyncDirect() {
  try {
    console.log('🔄 بدء الاختبار...');
    console.log('🌐 SUPABASE_URL:', process.env.SUPABASE_URL ? 'موجود' : 'غير موجود');
    console.log('🔑 SUPABASE_SERVICE_ROLE_KEY:', process.env.SUPABASE_SERVICE_ROLE_KEY ? 'موجود' : 'غير موجود');

    // اختبار استيراد النظام المدمج
    console.log('📦 استيراد النظام المدمج...');
    const waseetSync = require('./services/integrated_waseet_sync');
    console.log('✅ تم استيراد النظام المدمج بنجاح');

    // فحص حالة النظام
    console.log('🔍 فحص حالة النظام...');
    console.log('   - isRunning:', waseetSync.isRunning);
    console.log('   - isCurrentlySyncing:', waseetSync.isCurrentlySyncing);

    // محاولة الحصول على الإحصائيات
    console.log('📊 محاولة الحصول على الإحصائيات...');
    const stats = waseetSync.getStats();
    console.log('📈 الإحصائيات:', JSON.stringify(stats, null, 2));

    // بدء النظام
    if (!waseetSync.isRunning) {
      console.log('🚀 بدء النظام...');
      const startResult = await waseetSync.start();
      console.log('📊 نتيجة البدء:', startResult);
    }

    // فحص الطلب المحدد في قاعدة البيانات
    console.log('🔍 فحص الطلب order_1754571218521_7589 في قاعدة البيانات...');
    const { createClient } = require('@supabase/supabase-js');
    const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

    const { data: orderData, error } = await supabase
      .from('orders')
      .select('id, status, waseet_status, waseet_status_id, waseet_status_text')
      .eq('id', 'order_1754571218521_7589')
      .single();

    if (error) {
      console.log('❌ خطأ في جلب الطلب:', error.message);
    } else {
      console.log('📋 بيانات الطلب في قاعدة البيانات:');
      console.log('   - status:', orderData.status);
      console.log('   - waseet_status:', orderData.waseet_status);
      console.log('   - waseet_status_id:', orderData.waseet_status_id);
      console.log('   - waseet_status_text:', orderData.waseet_status_text);
    }

    // تنفيذ مزامنة فورية
    console.log('⚡ تنفيذ مزامنة فورية...');
    const syncResult = await waseetSync.forcSync();
    console.log('📊 نتيجة المزامنة:', JSON.stringify(syncResult, null, 2));

    console.log('✅ انتهى الاختبار بنجاح');

  } catch (error) {
    console.error('❌ خطأ في الاختبار:', error.message);
    console.error('📋 تفاصيل الخطأ:', error.stack);
  }
}

// تشغيل الاختبار
testSyncDirect();
