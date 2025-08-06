// ===================================
// اختبار عدم تكرار الإشعارات
// Test No Duplicate Alerts
// ===================================

const { createClient } = require('@supabase/supabase-js');
const InventoryMonitorService = require('./inventory_monitor_service');
require('dotenv').config();

async function testNoDuplicateAlerts() {
  console.log('🧪 === اختبار عدم تكرار الإشعارات ===\n');

  try {
    // إعداد Supabase
    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    // إعداد خدمة المراقبة
    const inventoryMonitor = new InventoryMonitorService();

    // 1. الحصول على منتج موجود
    console.log('📦 البحث عن منتج موجود...');
    const { data: products, error: fetchError } = await supabase
      .from('products')
      .select('*')
      .eq('is_active', true)
      .limit(1);

    if (fetchError || !products || products.length === 0) {
      throw new Error('لا توجد منتجات متاحة للاختبار');
    }

    const product = products[0];
    console.log(`✅ تم العثور على المنتج: ${product.name} (ID: ${product.id})`);

    // تحديث الكمية إلى 10 أولاً
    console.log('🔄 تحديث الكمية إلى 10...');
    const { error: updateInitialError } = await supabase
      .from('products')
      .update({ available_quantity: 10 })
      .eq('id', product.id);

    if (updateInitialError) {
      throw updateInitialError;
    }

    // 2. تحديث الكمية إلى 0 (نفاد)
    console.log('\n🔄 تحديث الكمية إلى 0...');
    const { error: updateError1 } = await supabase
      .from('products')
      .update({ available_quantity: 0 })
      .eq('id', product.id);

    if (updateError1) {
      throw updateError1;
    }

    // 3. مراقبة المنتج (يجب أن يرسل إشعار)
    console.log('🔍 مراقبة المنتج (المرة الأولى - يجب أن يرسل إشعار)...');
    const result1 = await inventoryMonitor.monitorProduct(product.id);
    
    console.log(`النتيجة الأولى: ${result1.success ? 'نجح' : 'فشل'}`);
    if (result1.alerts && result1.alerts.length > 0) {
      result1.alerts.forEach(alert => {
        console.log(`🚨 ${alert.type}: ${alert.sent ? 'تم الإرسال ✅' : 'لم يتم الإرسال ❌'}`);
      });
    } else {
      console.log('📭 لا توجد تنبيهات');
    }

    // 4. انتظار ثانية واحدة
    console.log('\n⏳ انتظار ثانية واحدة...');
    await new Promise(resolve => setTimeout(resolve, 1000));

    // 5. مراقبة المنتج مرة أخرى (يجب ألا يرسل إشعار)
    console.log('🔍 مراقبة المنتج (المرة الثانية - يجب ألا يرسل إشعار)...');
    const result2 = await inventoryMonitor.monitorProduct(product.id);
    
    console.log(`النتيجة الثانية: ${result2.success ? 'نجح' : 'فشل'}`);
    if (result2.alerts && result2.alerts.length > 0) {
      result2.alerts.forEach(alert => {
        console.log(`🚨 ${alert.type}: ${alert.sent ? 'تم الإرسال ✅' : 'لم يتم الإرسال ❌'}`);
      });
    } else {
      console.log('📭 لا توجد تنبيهات (هذا صحيح!)');
    }

    // 6. تحديث الكمية إلى 10 (تجديد المخزون)
    console.log('\n🔄 تحديث الكمية إلى 10 (تجديد المخزون)...');
    const { error: updateError2 } = await supabase
      .from('products')
      .update({ available_quantity: 10 })
      .eq('id', product.id);

    if (updateError2) {
      throw updateError2;
    }

    // 7. مراقبة المنتج (يجب أن يمسح تاريخ الإشعارات)
    console.log('🔍 مراقبة المنتج (بعد تجديد المخزون)...');
    const result3 = await inventoryMonitor.monitorProduct(product.id);
    
    console.log(`النتيجة الثالثة: ${result3.success ? 'نجح' : 'فشل'}`);
    console.log(`حالة المنتج: ${result3.product ? result3.product.status : 'غير محدد'}`);

    // 8. تحديث الكمية إلى 0 مرة أخرى
    console.log('\n🔄 تحديث الكمية إلى 0 مرة أخرى...');
    const { error: updateError3 } = await supabase
      .from('products')
      .update({ available_quantity: 0 })
      .eq('id', product.id);

    if (updateError3) {
      throw updateError3;
    }

    // 9. مراقبة المنتج (يجب أن يرسل إشعار جديد)
    console.log('🔍 مراقبة المنتج (نفاد جديد - يجب أن يرسل إشعار)...');
    const result4 = await inventoryMonitor.monitorProduct(product.id);
    
    console.log(`النتيجة الرابعة: ${result4.success ? 'نجح' : 'فشل'}`);
    if (result4.alerts && result4.alerts.length > 0) {
      result4.alerts.forEach(alert => {
        console.log(`🚨 ${alert.type}: ${alert.sent ? 'تم الإرسال ✅' : 'لم يتم الإرسال ❌'}`);
      });
    } else {
      console.log('📭 لا توجد تنبيهات');
    }

    // 10. إعادة تعيين الكمية الأصلية
    console.log('\n🔄 إعادة تعيين الكمية الأصلية...');
    const { error: resetError } = await supabase
      .from('products')
      .update({ available_quantity: 10 })
      .eq('id', product.id);

    if (resetError) {
      throw resetError;
    }

    console.log('✅ تم إعادة تعيين الكمية الأصلية');

    console.log('\n✅ === انتهى اختبار عدم تكرار الإشعارات ===');
    console.log('\n📋 الخلاصة:');
    console.log('- المرة الأولى: يجب أن يرسل إشعار');
    console.log('- المرة الثانية: يجب ألا يرسل إشعار (منع التكرار)');
    console.log('- بعد تجديد المخزون: يجب أن يمسح تاريخ الإشعارات');
    console.log('- النفاد الجديد: يجب أن يرسل إشعار جديد');

  } catch (error) {
    console.error('❌ خطأ في الاختبار:', error);
  }
}

// تشغيل الاختبار
testNoDuplicateAlerts()
  .then(() => {
    console.log('\n🎉 تم الانتهاء من الاختبار');
    process.exit(0);
  })
  .catch(error => {
    console.error('💥 فشل الاختبار:', error);
    process.exit(1);
  });
