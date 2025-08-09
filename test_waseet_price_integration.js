const { createClient } = require('@supabase/supabase-js');
const OrderSyncService = require('./backend/services/order_sync_service');

// إعداد Supabase
const supabaseUrl = 'https://ixqjqfkqvqjqjqjqjqjq.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml4cWpxZmtxdnFqcWpxanFqcWpxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzM3NTU4NzQsImV4cCI6MjA0OTMzMTg3NH0.example';
const supabase = createClient(supabaseUrl, supabaseKey);

/**
 * اختبار شامل لإصلاح مشكلة حساب المبلغ للوسيط
 */
async function testWaseetPriceIntegration() {
  console.log('🧪 بدء الاختبار الشامل لإصلاح مشكلة حساب المبلغ للوسيط...');
  console.log('='.repeat(70));

  try {
    // 1. إنشاء طلب اختبار
    console.log('\n1️⃣ إنشاء طلب اختبار...');
    
    const testOrderData = {
      id: `TEST-${Date.now()}`,
      customer_name: 'عميل اختبار',
      primary_phone: '+9647901234567',
      province: 'بغداد',
      city: 'الكرخ',
      customer_address: 'بغداد - الكرخ - شارع الرئيسي',
      total: 25000, // المبلغ الإجمالي الكامل
      subtotal: 20000, // مجموع المنتجات
      delivery_fee: 5000, // رسوم التوصيل
      profit: 5000,
      status: 'active',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    // إدراج الطلب
    const { data: insertedOrder, error: insertError } = await supabase
      .from('orders')
      .insert(testOrderData)
      .select()
      .single();

    if (insertError) {
      console.log('❌ خطأ في إنشاء الطلب:', insertError.message);
      return;
    }

    console.log(`✅ تم إنشاء طلب اختبار: ${insertedOrder.id}`);
    console.log(`   💰 المبلغ الإجمالي: ${insertedOrder.total} د.ع`);

    // 2. إضافة عناصر للطلب
    console.log('\n2️⃣ إضافة عناصر للطلب...');
    
    const testItems = [
      {
        order_id: insertedOrder.id,
        product_name: 'منتج اختبار 1',
        quantity: 2,
        customer_price: 8000,
        wholesale_price: 6000,
        profit_per_item: 2000,
        created_at: new Date().toISOString()
      },
      {
        order_id: insertedOrder.id,
        product_name: 'منتج اختبار 2',
        quantity: 1,
        customer_price: 12000,
        wholesale_price: 9000,
        profit_per_item: 3000,
        created_at: new Date().toISOString()
      }
    ];

    const { error: itemsError } = await supabase
      .from('order_items')
      .insert(testItems);

    if (itemsError) {
      console.log('❌ خطأ في إضافة العناصر:', itemsError.message);
      return;
    }

    console.log(`✅ تم إضافة ${testItems.length} عنصر للطلب`);
    
    // حساب مجموع المنتجات
    const productsTotal = testItems.reduce((sum, item) => sum + (item.customer_price * item.quantity), 0);
    console.log(`   📦 مجموع المنتجات: ${productsTotal} د.ع`);
    console.log(`   🚚 رسوم التوصيل: ${insertedOrder.total - productsTotal} د.ع`);

    // 3. اختبار إنشاء بيانات الوسيط
    console.log('\n3️⃣ اختبار إنشاء بيانات الوسيط...');
    
    const orderSyncService = new OrderSyncService();
    const waseetData = await orderSyncService.createDefaultWaseetData(insertedOrder);

    console.log(`📋 بيانات الوسيط المُنشأة:`);
    console.log(`   💰 totalPrice: ${waseetData.totalPrice} د.ع`);
    console.log(`   📦 itemsCount: ${waseetData.itemsCount}`);
    console.log(`   🏙️ cityId: ${waseetData.cityId}`);

    // 4. التحقق من صحة المبلغ
    console.log('\n4️⃣ التحقق من صحة المبلغ...');
    
    const expectedPrice = insertedOrder.total; // 25000
    const actualPrice = waseetData.totalPrice;

    console.log(`📊 المقارنة:`);
    console.log(`   🎯 المبلغ المتوقع: ${expectedPrice} د.ع`);
    console.log(`   📊 المبلغ الفعلي: ${actualPrice} د.ع`);

    if (actualPrice === expectedPrice) {
      console.log('✅ نجح الاختبار! المبلغ صحيح');
    } else {
      console.log('❌ فشل الاختبار! المبلغ خاطئ');
      console.log(`   📈 الفرق: ${expectedPrice - actualPrice} د.ع`);
    }

    // 5. اختبار إرسال للوسيط (محاكاة)
    console.log('\n5️⃣ اختبار بيانات الإرسال للوسيط...');
    
    // جلب الطلب المحدث مع بيانات الوسيط
    const { data: updatedOrder, error: fetchError } = await supabase
      .from('orders')
      .select('*')
      .eq('id', insertedOrder.id)
      .single();

    if (fetchError) {
      console.log('❌ خطأ في جلب الطلب المحدث:', fetchError.message);
      return;
    }

    if (updatedOrder.waseet_data) {
      const savedWaseetData = JSON.parse(updatedOrder.waseet_data);
      console.log(`📋 البيانات المحفوظة في قاعدة البيانات:`);
      console.log(`   💰 totalPrice: ${savedWaseetData.totalPrice} د.ع`);
      
      if (savedWaseetData.totalPrice === expectedPrice) {
        console.log('✅ البيانات محفوظة بشكل صحيح');
      } else {
        console.log('❌ البيانات محفوظة بشكل خاطئ');
      }
    }

    // 6. تنظيف البيانات
    console.log('\n6️⃣ تنظيف بيانات الاختبار...');
    
    // حذف العناصر
    await supabase
      .from('order_items')
      .delete()
      .eq('order_id', insertedOrder.id);

    // حذف الطلب
    await supabase
      .from('orders')
      .delete()
      .eq('id', insertedOrder.id);

    console.log('✅ تم تنظيف بيانات الاختبار');

    console.log('\n🎉 انتهى الاختبار الشامل بنجاح!');

  } catch (error) {
    console.error('❌ خطأ في الاختبار الشامل:', error.message);
    console.error(error.stack);
  }
}

/**
 * اختبار سريع لطلب موجود
 */
async function quickTestExistingOrder() {
  console.log('⚡ اختبار سريع لطلب موجود...');
  
  try {
    const { data: orders, error } = await supabase
      .from('orders')
      .select('id, customer_name, total, waseet_data')
      .not('waseet_data', 'is', null)
      .limit(1);

    if (error || !orders || orders.length === 0) {
      console.log('❌ لم يتم العثور على طلبات للاختبار');
      return;
    }

    const order = orders[0];
    const waseetData = JSON.parse(order.waseet_data);
    
    console.log(`📦 الطلب: ${order.id}`);
    console.log(`💰 المبلغ الإجمالي: ${order.total} د.ع`);
    console.log(`💰 المبلغ في الوسيط: ${waseetData.totalPrice} د.ع`);
    
    if (waseetData.totalPrice === order.total) {
      console.log('✅ المبلغ صحيح');
    } else {
      console.log('❌ المبلغ خاطئ - يحتاج إصلاح');
    }

  } catch (error) {
    console.error('❌ خطأ في الاختبار السريع:', error.message);
  }
}

// تشغيل الاختبارات
if (require.main === module) {
  const args = process.argv.slice(2);
  
  if (args.length > 0 && args[0] === 'quick') {
    quickTestExistingOrder().then(() => process.exit(0));
  } else {
    testWaseetPriceIntegration().then(() => {
      console.log('\n🎯 تم الانتهاء من جميع الاختبارات');
      process.exit(0);
    }).catch(error => {
      console.error('💥 خطأ فادح:', error);
      process.exit(1);
    });
  }
}

module.exports = { testWaseetPriceIntegration, quickTestExistingOrder };
