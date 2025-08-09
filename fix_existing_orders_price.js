const { createClient } = require('@supabase/supabase-js');

// إعداد Supabase
const supabaseUrl = 'https://ixqjqfkqvqjqjqjqjqjq.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml4cWpxZmtxdnFqcWpxanFqcWpxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzM3NTU4NzQsImV4cCI6MjA0OTMzMTg3NH0.example';
const supabase = createClient(supabaseUrl, supabaseKey);

/**
 * إصلاح جميع الطلبات الموجودة التي تحتوي على مبلغ خاطئ في بيانات الوسيط
 */
async function fixExistingOrdersPrices() {
  console.log('🔧 بدء إصلاح أسعار الطلبات الموجودة...');
  console.log('='.repeat(60));

  try {
    // 1. جلب جميع الطلبات التي تحتوي على بيانات وسيط
    console.log('\n1️⃣ جلب الطلبات التي تحتوي على بيانات وسيط...');
    
    const { data: orders, error: ordersError } = await supabase
      .from('orders')
      .select('id, customer_name, total, waseet_data')
      .not('waseet_data', 'is', null);

    if (ordersError) {
      console.log('❌ خطأ في جلب الطلبات:', ordersError.message);
      return;
    }

    console.log(`✅ تم جلب ${orders.length} طلب يحتوي على بيانات وسيط`);

    let fixedCount = 0;
    let alreadyCorrectCount = 0;
    let errorCount = 0;

    // 2. فحص وإصلاح كل طلب
    for (let i = 0; i < orders.length; i++) {
      const order = orders[i];
      console.log(`\n📦 معالجة الطلب ${i + 1}/${orders.length}: ${order.id}`);
      console.log(`   👤 العميل: ${order.customer_name}`);
      console.log(`   💰 المبلغ الإجمالي: ${order.total} د.ع`);

      try {
        // تحليل بيانات الوسيط
        let waseetData = null;
        try {
          waseetData = JSON.parse(order.waseet_data);
        } catch (parseError) {
          console.log(`   ❌ خطأ في تحليل بيانات الوسيط: ${parseError.message}`);
          errorCount++;
          continue;
        }

        const currentWaseetPrice = waseetData.totalPrice;
        const correctPrice = order.total;

        console.log(`   📊 المبلغ الحالي في الوسيط: ${currentWaseetPrice} د.ع`);
        console.log(`   📊 المبلغ الصحيح: ${correctPrice} د.ع`);

        if (currentWaseetPrice === correctPrice) {
          console.log(`   ✅ المبلغ صحيح - لا حاجة للإصلاح`);
          alreadyCorrectCount++;
        } else {
          console.log(`   🔧 إصلاح المبلغ من ${currentWaseetPrice} إلى ${correctPrice} د.ع`);
          
          // تحديث بيانات الوسيط
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
            .eq('id', order.id);

          if (updateError) {
            console.log(`   ❌ خطأ في التحديث: ${updateError.message}`);
            errorCount++;
          } else {
            console.log(`   ✅ تم الإصلاح بنجاح`);
            fixedCount++;
          }
        }

      } catch (error) {
        console.log(`   ❌ خطأ في معالجة الطلب: ${error.message}`);
        errorCount++;
      }

      // انتظار قصير لتجنب الضغط على قاعدة البيانات
      if (i < orders.length - 1) {
        await new Promise(resolve => setTimeout(resolve, 100));
      }
    }

    // 3. تقرير النتائج
    console.log('\n📊 تقرير النتائج:');
    console.log('='.repeat(40));
    console.log(`📦 إجمالي الطلبات المعالجة: ${orders.length}`);
    console.log(`✅ الطلبات المصلحة: ${fixedCount}`);
    console.log(`✅ الطلبات الصحيحة مسبقاً: ${alreadyCorrectCount}`);
    console.log(`❌ الطلبات التي فشل إصلاحها: ${errorCount}`);

    if (fixedCount > 0) {
      console.log(`\n🎉 تم إصلاح ${fixedCount} طلب بنجاح!`);
    }

    if (errorCount > 0) {
      console.log(`\n⚠️ فشل في إصلاح ${errorCount} طلب - يحتاج مراجعة يدوية`);
    }

    console.log('\n✅ انتهى الإصلاح');

  } catch (error) {
    console.error('❌ خطأ عام في الإصلاح:', error.message);
  }
}

/**
 * فحص طلب محدد
 */
async function checkSpecificOrder(orderId) {
  console.log(`🔍 فحص الطلب: ${orderId}`);
  
  try {
    const { data: order, error } = await supabase
      .from('orders')
      .select('*')
      .eq('id', orderId)
      .single();

    if (error || !order) {
      console.log('❌ لم يتم العثور على الطلب');
      return;
    }

    console.log(`👤 العميل: ${order.customer_name}`);
    console.log(`💰 المبلغ الإجمالي: ${order.total} د.ع`);

    if (order.waseet_data) {
      try {
        const waseetData = JSON.parse(order.waseet_data);
        console.log(`📊 المبلغ في بيانات الوسيط: ${waseetData.totalPrice} د.ع`);
        
        if (waseetData.totalPrice === order.total) {
          console.log('✅ المبلغ صحيح');
        } else {
          console.log('❌ المبلغ خاطئ - يحتاج إصلاح');
        }
      } catch (e) {
        console.log('❌ خطأ في تحليل بيانات الوسيط');
      }
    } else {
      console.log('ℹ️ لا توجد بيانات وسيط');
    }

  } catch (error) {
    console.error('❌ خطأ في فحص الطلب:', error.message);
  }
}

// تشغيل السكريبت
if (require.main === module) {
  const args = process.argv.slice(2);
  
  if (args.length > 0 && args[0] === 'check') {
    // فحص طلب محدد
    const orderId = args[1];
    if (orderId) {
      checkSpecificOrder(orderId).then(() => process.exit(0));
    } else {
      console.log('❌ يرجى تحديد معرف الطلب');
      console.log('الاستخدام: node fix_existing_orders_price.js check ORDER_ID');
      process.exit(1);
    }
  } else {
    // إصلاح جميع الطلبات
    fixExistingOrdersPrices().then(() => {
      console.log('\n🎯 تم الانتهاء من الإصلاح');
      process.exit(0);
    }).catch(error => {
      console.error('💥 خطأ فادح:', error);
      process.exit(1);
    });
  }
}

module.exports = { fixExistingOrdersPrices, checkSpecificOrder };
