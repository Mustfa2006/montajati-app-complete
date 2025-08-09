const { createClient } = require('@supabase/supabase-js');

// إعداد Supabase
const supabaseUrl = 'https://ixqjqfkqvqjqjqjqjqjq.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml4cWpxZmtxdnFqcWpxanFqcWpxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzM3NTU4NzQsImV4cCI6MjA0OTMzMTg3NH0.example';
const supabase = createClient(supabaseUrl, supabaseKey);

/**
 * اختبار إصلاح مشكلة حساب المبلغ المرسل للوسيط
 */
async function testPriceFix() {
  console.log('🧪 بدء اختبار إصلاح مشكلة حساب المبلغ للوسيط...');
  console.log('='.repeat(60));

  try {
    // 1. البحث عن طلب للاختبار
    console.log('\n1️⃣ البحث عن طلب للاختبار...');
    
    const { data: orders, error: ordersError } = await supabase
      .from('orders')
      .select('*')
      .not('waseet_data', 'is', null)
      .limit(1);

    if (ordersError || !orders || orders.length === 0) {
      console.log('❌ لم يتم العثور على طلبات للاختبار');
      return;
    }

    const testOrder = orders[0];
    console.log(`✅ تم العثور على طلب للاختبار: ${testOrder.id}`);
    console.log(`   👤 العميل: ${testOrder.customer_name}`);
    console.log(`   💰 المبلغ الإجمالي: ${testOrder.total} د.ع`);

    // 2. فحص بيانات الوسيط الحالية
    console.log('\n2️⃣ فحص بيانات الوسيط الحالية...');
    
    let waseetData = null;
    if (testOrder.waseet_data) {
      try {
        waseetData = JSON.parse(testOrder.waseet_data);
        console.log(`📋 بيانات الوسيط الحالية:`);
        console.log(`   💰 totalPrice: ${waseetData.totalPrice} د.ع`);
        console.log(`   📦 itemsCount: ${waseetData.itemsCount}`);
        console.log(`   🏙️ cityId: ${waseetData.cityId}`);
      } catch (e) {
        console.log('❌ خطأ في تحليل بيانات الوسيط:', e.message);
      }
    }

    // 3. حساب المبلغ الصحيح من عناصر الطلب
    console.log('\n3️⃣ حساب المبلغ الصحيح من عناصر الطلب...');
    
    const { data: orderItems, error: itemsError } = await supabase
      .from('order_items')
      .select('quantity, customer_price, product_name')
      .eq('order_id', testOrder.id);

    if (itemsError) {
      console.log('❌ خطأ في جلب عناصر الطلب:', itemsError.message);
      return;
    }

    let productsSubtotal = 0;
    let itemsCount = 0;

    if (orderItems && orderItems.length > 0) {
      itemsCount = orderItems.reduce((sum, item) => sum + (item.quantity || 1), 0);
      productsSubtotal = orderItems.reduce((sum, item) => sum + ((item.customer_price || 0) * (item.quantity || 1)), 0);

      console.log(`📦 عدد العناصر: ${orderItems.length}`);
      console.log(`📦 إجمالي القطع: ${itemsCount}`);
      console.log(`💰 مجموع المنتجات فقط: ${productsSubtotal} د.ع`);
      console.log(`💰 المبلغ الإجمالي (مع التوصيل): ${testOrder.total} د.ع`);
      console.log(`🚚 رسوم التوصيل: ${testOrder.total - productsSubtotal} د.ع`);
    }

    // 4. مقارنة القيم
    console.log('\n4️⃣ مقارنة القيم...');
    
    if (waseetData && waseetData.totalPrice) {
      const currentWaseetPrice = waseetData.totalPrice;
      const correctPrice = testOrder.total;
      
      console.log(`📊 المقارنة:`);
      console.log(`   🔴 المبلغ الحالي في الوسيط: ${currentWaseetPrice} د.ع`);
      console.log(`   🟢 المبلغ الصحيح: ${correctPrice} د.ع`);
      console.log(`   📈 الفرق: ${correctPrice - currentWaseetPrice} د.ع`);

      if (currentWaseetPrice === correctPrice) {
        console.log('✅ المبلغ صحيح - لا حاجة للإصلاح');
      } else {
        console.log('❌ المبلغ خاطئ - يحتاج إصلاح');
        
        // 5. إصلاح البيانات
        console.log('\n5️⃣ إصلاح بيانات الوسيط...');
        
        const updatedWaseetData = {
          ...waseetData,
          totalPrice: correctPrice
        };

        const { error: updateError } = await supabase
          .from('orders')
          .update({
            waseet_data: JSON.stringify(updatedWaseetData),
            updated_at: new Date().toISOString()
          })
          .eq('id', testOrder.id);

        if (updateError) {
          console.log('❌ خطأ في تحديث البيانات:', updateError.message);
        } else {
          console.log('✅ تم إصلاح بيانات الوسيط بنجاح');
          console.log(`   💰 المبلغ الجديد: ${correctPrice} د.ع`);
        }
      }
    }

    console.log('\n✅ انتهى الاختبار بنجاح');

  } catch (error) {
    console.error('❌ خطأ في الاختبار:', error.message);
  }
}

// تشغيل الاختبار
if (require.main === module) {
  testPriceFix().then(() => {
    console.log('\n🎯 تم الانتهاء من الاختبار');
    process.exit(0);
  }).catch(error => {
    console.error('💥 خطأ فادح:', error);
    process.exit(1);
  });
}

module.exports = { testPriceFix };
