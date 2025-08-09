/**
 * 🎯 تطبيق إصلاح مشكلة المبلغ المرسل للوسيط
 * إضافة حقل waseet_total وتحديث البيانات الموجودة
 */

const { createClient } = require('@supabase/supabase-js');

// إعداد Supabase (استخدم بياناتك الحقيقية)
const supabaseUrl = 'YOUR_SUPABASE_URL';
const supabaseKey = 'YOUR_SUPABASE_KEY';
const supabase = createClient(supabaseUrl, supabaseKey);

async function applyWaseetTotalFix() {
  console.log('🎯 بدء تطبيق إصلاح مشكلة المبلغ المرسل للوسيط...');
  console.log('='.repeat(60));

  try {
    // 1. إضافة حقل waseet_total
    console.log('\n1️⃣ إضافة حقل waseet_total...');
    
    const addColumnQuery = `
      ALTER TABLE orders 
      ADD COLUMN IF NOT EXISTS waseet_total DECIMAL(12,2);
    `;

    try {
      await supabase.rpc('execute_sql', { sql: addColumnQuery });
      console.log('✅ تم إضافة حقل waseet_total بنجاح');
    } catch (error) {
      console.log('⚠️ خطأ في إضافة الحقل (قد يكون موجود مسبقاً):', error.message);
    }

    // 2. تحديث الطلبات الموجودة
    console.log('\n2️⃣ تحديث الطلبات الموجودة...');
    
    // جلب الطلبات التي ليس لديها waseet_total
    const { data: orders, error: fetchError } = await supabase
      .from('orders')
      .select('id, customer_name, total, subtotal, delivery_fee')
      .is('waseet_total', null);

    if (fetchError) {
      console.log('❌ خطأ في جلب الطلبات:', fetchError.message);
      return;
    }

    console.log(`📦 تم العثور على ${orders.length} طلب يحتاج تحديث`);

    let updatedCount = 0;
    let errorCount = 0;

    for (const order of orders) {
      try {
        // حساب المبلغ الكامل للوسيط
        const waseetTotal = order.total; // في البداية نسخ total إلى waseet_total
        
        const { error: updateError } = await supabase
          .from('orders')
          .update({
            waseet_total: waseetTotal,
            updated_at: new Date().toISOString()
          })
          .eq('id', order.id);

        if (updateError) {
          console.log(`❌ خطأ في تحديث الطلب ${order.id}:`, updateError.message);
          errorCount++;
        } else {
          console.log(`✅ تم تحديث الطلب ${order.id} - العميل: ${order.customer_name}`);
          updatedCount++;
        }

        // انتظار قصير لتجنب الضغط على قاعدة البيانات
        await new Promise(resolve => setTimeout(resolve, 100));

      } catch (error) {
        console.log(`❌ خطأ في معالجة الطلب ${order.id}:`, error.message);
        errorCount++;
      }
    }

    // 3. حذف بيانات الوسيط القديمة لإعادة إنشائها
    console.log('\n3️⃣ حذف بيانات الوسيط القديمة...');
    
    const { error: resetError } = await supabase
      .from('orders')
      .update({
        waseet_data: null,
        updated_at: new Date().toISOString()
      })
      .not('waseet_data', 'is', null);

    if (resetError) {
      console.log('❌ خطأ في حذف بيانات الوسيط:', resetError.message);
    } else {
      console.log('✅ تم حذف بيانات الوسيط القديمة لإعادة إنشائها');
    }

    // 4. إضافة تعليقات للحقول
    console.log('\n4️⃣ إضافة تعليقات للحقول...');
    
    const commentQueries = [
      `COMMENT ON COLUMN orders.waseet_total IS 'المبلغ الكامل المرسل لشركة الوسيط (يشمل رسوم التوصيل الكاملة)';`,
      `COMMENT ON COLUMN orders.total IS 'المبلغ المدفوع من العميل (قد يكون مخفض)';`
    ];

    for (const query of commentQueries) {
      try {
        await supabase.rpc('execute_sql', { sql: query });
        console.log('✅ تم إضافة تعليق للحقل');
      } catch (error) {
        console.log('⚠️ خطأ في إضافة التعليق:', error.message);
      }
    }

    // 5. إنشاء فهرس للأداء
    console.log('\n5️⃣ إنشاء فهرس للأداء...');
    
    const indexQuery = `CREATE INDEX IF NOT EXISTS idx_orders_waseet_total ON orders (waseet_total);`;
    
    try {
      await supabase.rpc('execute_sql', { sql: indexQuery });
      console.log('✅ تم إنشاء فهرس waseet_total');
    } catch (error) {
      console.log('⚠️ خطأ في إنشاء الفهرس:', error.message);
    }

    // 6. عرض النتائج النهائية
    console.log('\n6️⃣ النتائج النهائية...');
    
    const { data: finalOrders, error: finalError } = await supabase
      .from('orders')
      .select('id, customer_name, total, waseet_total')
      .not('waseet_total', 'is', null)
      .order('created_at', { ascending: false })
      .limit(5);

    if (finalError) {
      console.log('❌ خطأ في جلب النتائج النهائية:', finalError.message);
    } else {
      console.log('📊 عينة من الطلبات المحدثة:');
      finalOrders.forEach(order => {
        console.log(`   📦 ${order.customer_name}: العميل=${order.total} د.ع، الوسيط=${order.waseet_total} د.ع`);
      });
    }

    // تقرير النتائج
    console.log('\n📊 تقرير النتائج:');
    console.log('='.repeat(40));
    console.log(`✅ الطلبات المحدثة: ${updatedCount}`);
    console.log(`❌ الطلبات التي فشل تحديثها: ${errorCount}`);
    console.log(`📈 معدل النجاح: ${((updatedCount / (updatedCount + errorCount)) * 100).toFixed(1)}%`);

    console.log('\n🎉 تم تطبيق الإصلاح بنجاح!');
    console.log('\n📝 الخطوات التالية:');
    console.log('1. اختبار إنشاء طلب جديد');
    console.log('2. التحقق من المبلغ المرسل للوسيط');
    console.log('3. مراقبة الطلبات الجديدة');

  } catch (error) {
    console.error('❌ خطأ عام في تطبيق الإصلاح:', error.message);
  }
}

// تشغيل الإصلاح
if (require.main === module) {
  applyWaseetTotalFix().then(() => {
    console.log('\n🎯 تم الانتهاء من تطبيق الإصلاح');
    process.exit(0);
  }).catch(error => {
    console.error('💥 خطأ فادح:', error);
    process.exit(1);
  });
}

module.exports = { applyWaseetTotalFix };
