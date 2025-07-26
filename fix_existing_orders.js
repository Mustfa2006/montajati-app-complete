const axios = require('axios');

/**
 * 🔧 إصلاح سريع للطلبات الموجودة
 * 
 * يقوم بـ:
 * 1. البحث عن الطلبات قيد التوصيل التي لم ترسل للوسيط
 * 2. إعادة إرسالها للوسيط
 * 3. تحديث حالاتها في قاعدة البيانات
 */

const BASE_URL = 'https://montajati-backend.onrender.com';

async function fixExistingOrders() {
  console.log('🔧 === إصلاح الطلبات الموجودة قيد التوصيل ===\n');

  try {
    // 1. جلب جميع الطلبات قيد التوصيل
    console.log('📋 جلب الطلبات قيد التوصيل...');
    
    const ordersResponse = await axios.get(`${BASE_URL}/api/orders`, {
      timeout: 30000
    });

    if (!ordersResponse.data.success || !ordersResponse.data.data) {
      console.log('❌ فشل في جلب الطلبات');
      return;
    }

    const allOrders = ordersResponse.data.data;
    console.log(`📊 إجمالي الطلبات: ${allOrders.length}`);

    // البحث عن الطلبات قيد التوصيل التي لم ترسل للوسيط
    const deliveryStatuses = [
      'قيد التوصيل',
      'قيد التوصيل الى الزبون (في عهدة المندوب)',
      'قيد التوصيل الى الزبون',
      'في عهدة المندوب',
      'قيد التوصيل للزبون',
      'shipping',
      'shipped'
    ];

    const ordersNeedingFix = allOrders.filter(order => 
      deliveryStatuses.includes(order.status) && !order.waseet_order_id
    );

    console.log(`🔍 طلبات تحتاج إصلاح: ${ordersNeedingFix.length}`);

    if (ordersNeedingFix.length === 0) {
      console.log('✅ جميع الطلبات قيد التوصيل مرسلة للوسيط بالفعل');
      return;
    }

    console.log('\n📋 الطلبات التي تحتاج إصلاح:');
    ordersNeedingFix.forEach((order, index) => {
      console.log(`${index + 1}. ${order.id} - ${order.customer_name} (${order.status})`);
    });

    // 2. إصلاح كل طلب
    console.log('\n🔧 بدء إصلاح الطلبات...');
    
    let fixedCount = 0;
    let failedCount = 0;

    for (let i = 0; i < ordersNeedingFix.length; i++) {
      const order = ordersNeedingFix[i];
      
      console.log(`\n📦 إصلاح الطلب ${i + 1}/${ordersNeedingFix.length}: ${order.id}`);
      console.log(`👤 العميل: ${order.customer_name}`);
      console.log(`📊 الحالة: ${order.status}`);

      try {
        // إعادة تحديث حالة الطلب لتشغيل إرسال الوسيط
        const updateResponse = await axios.put(
          `${BASE_URL}/api/orders/${order.id}/status`,
          {
            status: 'قيد التوصيل الى الزبون (في عهدة المندوب)', // تحديث إلى الحالة المعيارية
            notes: 'إصلاح تلقائي - إعادة إرسال للوسيط',
            changedBy: 'fix_script'
          },
          {
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json'
            },
            timeout: 30000
          }
        );

        if (updateResponse.data.success) {
          console.log('✅ تم تحديث الطلب بنجاح');
          
          // انتظار قصير للسماح للنظام بمعالجة الطلب
          await new Promise(resolve => setTimeout(resolve, 2000));
          
          // التحقق من إرسال الطلب للوسيط
          const checkResponse = await axios.get(`${BASE_URL}/api/orders/${order.id}`, {
            timeout: 15000
          });

          if (checkResponse.data.success && checkResponse.data.data) {
            const updatedOrder = checkResponse.data.data;
            
            if (updatedOrder.waseet_order_id) {
              console.log(`🎉 نجح الإصلاح! معرف الوسيط: ${updatedOrder.waseet_order_id}`);
              fixedCount++;
            } else {
              console.log('⚠️ تم التحديث لكن لم يرسل للوسيط بعد');
              console.log(`📋 حالة الوسيط: ${updatedOrder.waseet_status || 'غير محدد'}`);
            }
          }
        } else {
          console.log('❌ فشل في تحديث الطلب');
          failedCount++;
        }

      } catch (error) {
        console.log(`❌ خطأ في إصلاح الطلب: ${error.message}`);
        failedCount++;
      }

      // انتظار بين الطلبات لتجنب الضغط على الخادم
      if (i < ordersNeedingFix.length - 1) {
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
    }

    // 3. تقرير النتائج
    console.log('\n🏆 === تقرير الإصلاح ===');
    console.log(`📊 إجمالي الطلبات المعالجة: ${ordersNeedingFix.length}`);
    console.log(`✅ طلبات تم إصلاحها: ${fixedCount}`);
    console.log(`❌ طلبات فشل إصلاحها: ${failedCount}`);
    console.log(`⏳ طلبات في الانتظار: ${ordersNeedingFix.length - fixedCount - failedCount}`);

    if (fixedCount > 0) {
      console.log('\n🎉 تم إصلاح بعض الطلبات بنجاح!');
    }

    if (failedCount > 0) {
      console.log('\n⚠️ بعض الطلبات تحتاج مراجعة يدوية');
      console.log('💡 تحقق من logs الخادم لمعرفة أسباب الفشل');
    }

    // 4. فحص نهائي
    console.log('\n🔍 فحص نهائي للطلبات...');
    
    const finalCheckResponse = await axios.get(`${BASE_URL}/api/orders`, {
      timeout: 30000
    });

    if (finalCheckResponse.data.success && finalCheckResponse.data.data) {
      const finalOrders = finalCheckResponse.data.data;
      const stillNeedingFix = finalOrders.filter(order => 
        deliveryStatuses.includes(order.status) && !order.waseet_order_id
      );

      console.log(`📊 طلبات لا تزال تحتاج إصلاح: ${stillNeedingFix.length}`);
      
      if (stillNeedingFix.length === 0) {
        console.log('🎉 تم إصلاح جميع الطلبات بنجاح!');
      } else {
        console.log('⚠️ بعض الطلبات لا تزال تحتاج إصلاح:');
        stillNeedingFix.slice(0, 5).forEach(order => {
          console.log(`   - ${order.id} (${order.customer_name})`);
        });
        if (stillNeedingFix.length > 5) {
          console.log(`   ... و ${stillNeedingFix.length - 5} طلب آخر`);
        }
      }
    }

  } catch (error) {
    console.error('❌ خطأ عام في إصلاح الطلبات:', error.message);
    
    if (error.response) {
      console.error('📋 تفاصيل الخطأ:', error.response.data);
    }
  }
}

// تشغيل الإصلاح
fixExistingOrders();
