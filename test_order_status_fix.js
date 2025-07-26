const axios = require('axios');

/**
 * 🧪 اختبار شامل لحل مشكلة عدم إرسال الطلبات للوسيط
 * 
 * هذا الاختبار يتحقق من:
 * 1. تحديث حالة الطلب إلى "قيد التوصيل"
 * 2. التأكد من إرسال الطلب للوسيط تلقائياً
 * 3. التحقق من تحديث بيانات الوسيط في قاعدة البيانات
 */

const BASE_URL = 'https://montajati-backend.onrender.com';

async function testOrderStatusFix() {
  try {
    console.log('🧪 === اختبار حل مشكلة إرسال الطلبات للوسيط ===\n');

    // 1. جلب طلب للاختبار
    console.log('📋 جلب طلب للاختبار...');
    const ordersResponse = await axios.get(`${BASE_URL}/api/orders`, {
      timeout: 30000
    });

    if (!ordersResponse.data.success || !ordersResponse.data.data || ordersResponse.data.data.length === 0) {
      console.log('❌ لا توجد طلبات للاختبار');
      return;
    }

    // اختيار طلب لم يتم إرساله للوسيط بعد
    const testOrder = ordersResponse.data.data.find(order => 
      !order.waseet_order_id && order.status !== 'in_delivery'
    ) || ordersResponse.data.data[0];

    console.log(`✅ تم اختيار الطلب: ${testOrder.id}`);
    console.log(`📊 الحالة الحالية: ${testOrder.status}`);
    console.log(`🆔 معرف الوسيط الحالي: ${testOrder.waseet_order_id || 'غير محدد'}`);
    console.log(`📋 حالة الوسيط: ${testOrder.waseet_status || 'غير محدد'}\n`);

    // 2. تحديث الحالة إلى "قيد التوصيل"
    console.log('🔄 تحديث حالة الطلب إلى "قيد التوصيل"...');
    
    const updateResponse = await axios.put(
      `${BASE_URL}/api/orders/${testOrder.id}/status`,
      {
        status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
        notes: 'اختبار حل مشكلة إرسال الطلبات للوسيط',
        changedBy: 'test_fix_script'
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        timeout: 60000
      }
    );

    if (updateResponse.data.success) {
      console.log('✅ تم تحديث حالة الطلب بنجاح');
      console.log(`📊 الحالة الجديدة: ${updateResponse.data.data.newStatus}`);
    } else {
      console.log('❌ فشل في تحديث حالة الطلب');
      console.log('تفاصيل الخطأ:', updateResponse.data);
      return;
    }

    // 3. انتظار قليل للسماح للنظام بمعالجة الطلب
    console.log('\n⏳ انتظار 10 ثوانِ للسماح للنظام بإرسال الطلب للوسيط...');
    await new Promise(resolve => setTimeout(resolve, 10000));

    // 4. التحقق من حالة الطلب بعد التحديث
    console.log('🔍 فحص حالة الطلب بعد التحديث...');
    
    const checkResponse = await axios.get(`${BASE_URL}/api/orders/${testOrder.id}`, {
      timeout: 30000
    });

    if (checkResponse.data.success && checkResponse.data.data) {
      const updatedOrder = checkResponse.data.data;
      
      console.log('\n📋 === نتائج الاختبار ===');
      console.log(`🆔 معرف الطلب: ${updatedOrder.id}`);
      console.log(`📊 الحالة الحالية: ${updatedOrder.status}`);
      console.log(`🔗 معرف الوسيط: ${updatedOrder.waseet_order_id || 'غير محدد'}`);
      console.log(`📋 حالة الوسيط: ${updatedOrder.waseet_status || 'غير محدد'}`);
      
      if (updatedOrder.waseet_data) {
        try {
          const waseetData = typeof updatedOrder.waseet_data === 'string' 
            ? JSON.parse(updatedOrder.waseet_data) 
            : updatedOrder.waseet_data;
          console.log(`📦 بيانات الوسيط: ${JSON.stringify(waseetData, null, 2)}`);
        } catch (e) {
          console.log(`📦 بيانات الوسيط (نص): ${updatedOrder.waseet_data}`);
        }
      }

      // تحليل النتائج
      console.log('\n🎯 === تحليل النتائج ===');
      
      if (updatedOrder.status === 'قيد التوصيل الى الزبون (في عهدة المندوب)') {
        console.log('✅ الحالة تم تحديثها بنجاح إلى "قيد التوصيل الى الزبون (في عهدة المندوب)"');
      } else {
        console.log(`⚠️ الحالة لم تتحدث كما متوقع. الحالة الحالية: ${updatedOrder.status}`);
      }

      if (updatedOrder.waseet_order_id) {
        console.log('✅ تم إرسال الطلب للوسيط بنجاح');
        console.log(`🆔 معرف الوسيط: ${updatedOrder.waseet_order_id}`);
      } else {
        console.log('❌ لم يتم إرسال الطلب للوسيط');
        
        if (updatedOrder.waseet_status === 'في انتظار الإرسال للوسيط') {
          console.log('ℹ️ الطلب في قائمة الانتظار للإرسال');
        }
      }

      if (updatedOrder.waseet_data) {
        console.log('✅ تم حفظ بيانات الوسيط');
      } else {
        console.log('⚠️ لا توجد بيانات وسيط محفوظة');
      }

      // النتيجة النهائية
      console.log('\n🏆 === النتيجة النهائية ===');
      
      const expectedStatus = 'قيد التوصيل الى الزبون (في عهدة المندوب)';
      if (updatedOrder.status === expectedStatus && updatedOrder.waseet_order_id) {
        console.log('🎉 نجح الاختبار! تم حل المشكلة بالكامل');
        console.log('✅ الطلب تم تحديث حالته وإرساله للوسيط بنجاح');
      } else if (updatedOrder.status === expectedStatus && !updatedOrder.waseet_order_id) {
        console.log('⚠️ نجح جزئياً: تم تحديث الحالة لكن لم يتم إرسال الطلب للوسيط');
        console.log('🔍 يرجى فحص logs الخادم لمعرفة سبب عدم الإرسال');
      } else {
        console.log('❌ فشل الاختبار: لم يتم تحديث الحالة أو إرسال الطلب');
      }

    } else {
      console.log('❌ فشل في جلب بيانات الطلب المحدث');
    }

  } catch (error) {
    console.error('❌ خطأ في اختبار حل المشكلة:', error.message);
    
    if (error.response) {
      console.error('📋 تفاصيل الخطأ:', error.response.data);
      console.error('📊 كود الحالة:', error.response.status);
    }
  }
}

// تشغيل الاختبار
testOrderStatusFix();
