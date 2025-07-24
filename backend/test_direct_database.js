// ===================================
// فحص مباشر لقاعدة البيانات والطلبات
// Direct Database and Orders Check
// ===================================

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

async function testDirectDatabase() {
  console.log('🔍 فحص مباشر لقاعدة البيانات والطلبات...');
  console.log('='.repeat(60));

  try {
    // إنشاء عميل Supabase
    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    console.log('✅ تم الاتصال بقاعدة البيانات');
    console.log(`🔗 URL: ${process.env.SUPABASE_URL}`);

    // 1. فحص جميع الطلبات
    console.log('\n1️⃣ فحص جميع الطلبات في قاعدة البيانات...');
    const { data: allOrders, error: fetchError } = await supabase
      .from('orders')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(10);

    if (fetchError) {
      console.error('❌ خطأ في جلب الطلبات:', fetchError);
      return;
    }

    console.log(`📊 عدد الطلبات الموجودة: ${allOrders.length}`);

    if (allOrders.length === 0) {
      console.log('⚠️ لا توجد طلبات في قاعدة البيانات');
      console.log('💡 يرجى إنشاء طلب من التطبيق أولاً');
      return;
    }

    // 2. عرض تفاصيل الطلبات
    console.log('\n2️⃣ تفاصيل الطلبات الموجودة:');
    allOrders.forEach((order, index) => {
      console.log(`\n📦 الطلب ${index + 1}:`);
      console.log(`   - المعرف: ${order.id}`);
      console.log(`   - العميل: ${order.customer_name}`);
      console.log(`   - الحالة: ${order.status}`);
      console.log(`   - الهاتف: ${order.customer_phone || order.primary_phone}`);
      console.log(`   - المجموع: ${order.total}`);
      console.log(`   - تاريخ الإنشاء: ${order.created_at}`);
      console.log(`   - تاريخ التحديث: ${order.updated_at}`);
      console.log(`   - معرف الوسيط: ${order.waseet_order_id || 'غير محدد'}`);
      console.log(`   - حالة الوسيط: ${order.waseet_status || 'غير محدد'}`);
      
      if (order.waseet_data) {
        try {
          const waseetData = JSON.parse(order.waseet_data);
          console.log(`   - بيانات الوسيط: موجودة`);
          if (waseetData.error) {
            console.log(`   - خطأ الوسيط: ${waseetData.error}`);
          }
          if (waseetData.qrId) {
            console.log(`   - QR ID: ${waseetData.qrId}`);
          }
        } catch (e) {
          console.log(`   - بيانات الوسيط: غير قابلة للقراءة`);
        }
      } else {
        console.log(`   - بيانات الوسيط: غير موجودة`);
      }
    });

    // 3. فحص الطلبات التي في حالة "قيد التوصيل"
    console.log('\n3️⃣ فحص الطلبات في حالة "قيد التوصيل"...');
    const { data: deliveryOrders, error: deliveryError } = await supabase
      .from('orders')
      .select('*')
      .eq('status', 'in_delivery')
      .order('updated_at', { ascending: false });

    if (deliveryError) {
      console.error('❌ خطأ في جلب طلبات التوصيل:', deliveryError);
    } else {
      console.log(`📊 عدد الطلبات في حالة "قيد التوصيل": ${deliveryOrders.length}`);
      
      if (deliveryOrders.length > 0) {
        console.log('\n📋 تفاصيل طلبات التوصيل:');
        deliveryOrders.forEach((order, index) => {
          console.log(`\n🚚 طلب التوصيل ${index + 1}:`);
          console.log(`   - المعرف: ${order.id}`);
          console.log(`   - العميل: ${order.customer_name}`);
          console.log(`   - تاريخ التحديث: ${order.updated_at}`);
          console.log(`   - معرف الوسيط: ${order.waseet_order_id || 'غير محدد'}`);
          console.log(`   - حالة الوسيط: ${order.waseet_status || 'غير محدد'}`);
          
          // تحليل حالة الطلب
          if (order.waseet_order_id) {
            console.log(`   ✅ تم إرسال الطلب للوسيط بنجاح`);
          } else if (order.waseet_status === 'في انتظار الإرسال للوسيط') {
            console.log(`   ⚠️ فشل في إرسال الطلب للوسيط - في قائمة الانتظار`);
          } else {
            console.log(`   ❌ لم يتم محاولة إرسال الطلب للوسيط`);
          }
        });
      }
    }

    // 4. اختبار تحديث حالة طلب موجود
    if (allOrders.length > 0) {
      const testOrder = allOrders.find(order => order.status !== 'in_delivery') || allOrders[0];
      
      console.log(`\n4️⃣ اختبار تحديث حالة الطلب: ${testOrder.id}`);
      console.log(`👤 العميل: ${testOrder.customer_name}`);
      console.log(`📊 الحالة الحالية: ${testOrder.status}`);

      // تحديث الحالة مباشرة في قاعدة البيانات
      console.log('\n🔄 تحديث الحالة إلى "قيد التوصيل" مباشرة...');
      
      const { data: updatedOrder, error: updateError } = await supabase
        .from('orders')
        .update({
          status: 'in_delivery',
          updated_at: new Date().toISOString(),
          notes: 'تحديث مباشر من اختبار قاعدة البيانات'
        })
        .eq('id', testOrder.id)
        .select()
        .single();

      if (updateError) {
        console.error('❌ خطأ في تحديث الطلب:', updateError);
      } else {
        console.log('✅ تم تحديث الطلب مباشرة في قاعدة البيانات');
        console.log(`📊 الحالة الجديدة: ${updatedOrder.status}`);
        
        // انتظار قليل ثم فحص ما إذا تم إرسال الطلب للوسيط
        console.log('\n⏳ انتظار 10 ثوان ثم فحص ما إذا تم إرسال الطلب للوسيط...');
        await new Promise(resolve => setTimeout(resolve, 10000));
        
        const { data: finalOrder, error: finalError } = await supabase
          .from('orders')
          .select('*')
          .eq('id', testOrder.id)
          .single();

        if (finalError) {
          console.error('❌ خطأ في جلب الطلب النهائي:', finalError);
        } else {
          console.log('\n📊 حالة الطلب بعد التحديث المباشر:');
          console.log(`   - الحالة: ${finalOrder.status}`);
          console.log(`   - معرف الوسيط: ${finalOrder.waseet_order_id || 'غير محدد'}`);
          console.log(`   - حالة الوسيط: ${finalOrder.waseet_status || 'غير محدد'}`);
          console.log(`   - تاريخ التحديث: ${finalOrder.updated_at}`);
          
          if (finalOrder.waseet_data) {
            try {
              const waseetData = JSON.parse(finalOrder.waseet_data);
              console.log(`   - بيانات الوسيط: موجودة`);
              if (waseetData.error) {
                console.log(`   - خطأ الوسيط: ${waseetData.error}`);
              }
            } catch (e) {
              console.log(`   - بيانات الوسيط: غير قابلة للقراءة`);
            }
          }
          
          // تحليل النتيجة
          console.log('\n🎯 تحليل النتيجة:');
          if (finalOrder.waseet_order_id) {
            console.log('✅ النظام يعمل! تم إرسال الطلب للوسيط تلقائياً');
          } else if (finalOrder.waseet_status === 'في انتظار الإرسال للوسيط') {
            console.log('⚠️ النظام يحاول الإرسال لكن يفشل - مشكلة في بيانات الوسيط');
          } else {
            console.log('❌ النظام لا يحاول إرسال الطلبات للوسيط - مشكلة في الكود');
          }
        }
      }
    }

    console.log('\n🎯 انتهى فحص قاعدة البيانات المباشر');

  } catch (error) {
    console.error('❌ خطأ في فحص قاعدة البيانات:', error);
  }
}

// تشغيل الاختبار
if (require.main === module) {
  testDirectDatabase()
    .then(() => {
      console.log('\n✅ انتهى فحص قاعدة البيانات المباشر');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ فشل فحص قاعدة البيانات المباشر:', error);
      process.exit(1);
    });
}

module.exports = { testDirectDatabase };
