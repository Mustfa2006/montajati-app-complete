const axios = require('axios');
require('dotenv').config();

/**
 * اختبار المزامنة على طلبات المستخدم 07503597589
 */
async function testUserSync() {
  console.log('🧪 اختبار المزامنة على طلبات المستخدم 07503597589');
  console.log('='.repeat(70));

  const baseURL = 'https://clownfish-app-krnk9.ondigitalocean.app';
  const testUserPhone = '07503597589';

  try {
    // 1. جلب طلبات المستخدم
    console.log(`\n1️⃣ جلب طلبات المستخدم ${testUserPhone}...`);
    console.log('-'.repeat(50));

    const ordersResponse = await axios.get(`${baseURL}/api/orders`, {
      timeout: 30000
    });

    const allOrders = ordersResponse.data.data || [];
    console.log(`📊 إجمالي الطلبات في النظام: ${allOrders.length}`);

    // البحث عن طلبات المستخدم
    const userOrders = allOrders.filter(order => 
      order.user_phone === testUserPhone || 
      order.primary_phone === testUserPhone ||
      order.customer_phone === testUserPhone
    );

    console.log(`👤 طلبات المستخدم ${testUserPhone}: ${userOrders.length}`);

    if (userOrders.length === 0) {
      console.log('❌ لا توجد طلبات لهذا المستخدم');
      console.log('💡 سأنشئ طلب اختبار جديد...');
      
      // إنشاء طلب اختبار
      const testOrder = await createTestOrder(baseURL, testUserPhone);
      if (testOrder) {
        userOrders.push(testOrder);
      }
    }

    // 2. عرض تفاصيل طلبات المستخدم
    console.log(`\n2️⃣ تفاصيل طلبات المستخدم:`);
    console.log('-'.repeat(50));

    userOrders.forEach((order, index) => {
      console.log(`\n📦 الطلب ${index + 1}:`);
      console.log(`   🆔 ID: ${order.id}`);
      console.log(`   📋 رقم الطلب: ${order.order_number || 'غير محدد'}`);
      console.log(`   👤 اسم العميل: ${order.customer_name}`);
      console.log(`   📞 رقم الهاتف: ${order.primary_phone || order.customer_phone}`);
      console.log(`   📊 الحالة الحالية: "${order.status}"`);
      console.log(`   🚛 معرف الوسيط: ${order.waseet_order_id || 'لم يرسل بعد'}`);
      console.log(`   📈 حالة الوسيط: "${order.waseet_status_text || 'غير محدد'}"`);
      console.log(`   🕐 تاريخ الإنشاء: ${new Date(order.created_at).toLocaleString('ar-IQ')}`);
    });

    // 3. اختيار طلب للاختبار
    console.log(`\n3️⃣ اختيار طلب للاختبار:`);
    console.log('-'.repeat(50));

    // البحث عن طلب مناسب للاختبار
    let testOrder = userOrders.find(order => 
      order.waseet_order_id && 
      order.status !== 'تم التسليم للزبون' &&
      order.status !== 'الغاء الطلب'
    );

    if (!testOrder) {
      testOrder = userOrders[0]; // أخذ أول طلب
    }

    if (!testOrder) {
      console.log('❌ لا يوجد طلب مناسب للاختبار');
      return;
    }

    console.log(`🎯 طلب الاختبار المختار:`);
    console.log(`   🆔 ID: ${testOrder.id}`);
    console.log(`   📊 الحالة: "${testOrder.status}"`);
    console.log(`   🚛 معرف الوسيط: ${testOrder.waseet_order_id || 'غير مرسل'}`);

    // 4. اختبار المزامنة
    console.log(`\n4️⃣ اختبار المزامنة:`);
    console.log('-'.repeat(50));

    if (!testOrder.waseet_order_id) {
      console.log('📤 الطلب لم يرسل للوسيط بعد - سأرسله أولاً...');
      
      // تحديث الحالة لإرسال الطلب للوسيط
      const updateResult = await updateOrderStatus(
        baseURL, 
        testOrder.id, 
        'قيد التوصيل الى الزبون (في عهدة المندوب)'
      );

      if (updateResult.success) {
        console.log('✅ تم تحديث الحالة وإرسال الطلب للوسيط');
        
        // انتظار قليل ثم جلب البيانات المحدثة
        await new Promise(resolve => setTimeout(resolve, 5000));
        
        const updatedOrder = await getOrderDetails(baseURL, testOrder.id);
        if (updatedOrder) {
          testOrder = updatedOrder;
          console.log(`🆔 معرف الوسيط الجديد: ${testOrder.waseet_order_id}`);
        }
      }
    }

    // 5. تشغيل المزامنة الفورية
    console.log(`\n5️⃣ تشغيل المزامنة الفورية:`);
    console.log('-'.repeat(50));

    try {
      const syncResponse = await axios.post(`${baseURL}/api/orders/force-sync`, {}, {
        timeout: 60000
      });

      if (syncResponse.data.success) {
        console.log('✅ تم تشغيل المزامنة الفورية بنجاح');
        console.log(`📊 النتائج:`, syncResponse.data.data);
      } else {
        console.log('❌ فشل في تشغيل المزامنة الفورية');
      }
    } catch (syncError) {
      console.log('⚠️ خطأ في تشغيل المزامنة الفورية:', syncError.message);
    }

    // 6. فحص النتائج بعد المزامنة
    console.log(`\n6️⃣ فحص النتائج بعد المزامنة:`);
    console.log('-'.repeat(50));

    await new Promise(resolve => setTimeout(resolve, 3000));

    const finalOrder = await getOrderDetails(baseURL, testOrder.id);
    if (finalOrder) {
      console.log(`📊 حالة الطلب بعد المزامنة:`);
      console.log(`   📈 الحالة: "${finalOrder.status}"`);
      console.log(`   🚛 معرف الوسيط: ${finalOrder.waseet_order_id || 'غير محدد'}`);
      console.log(`   📋 حالة الوسيط: "${finalOrder.waseet_status_text || 'غير محدد'}"`);
      console.log(`   🆔 معرف حالة الوسيط: ${finalOrder.waseet_status_id || 'غير محدد'}`);
      
      // مقارنة الحالات
      if (testOrder.status !== finalOrder.status) {
        console.log(`🔄 تغيرت الحالة: "${testOrder.status}" → "${finalOrder.status}"`);
        console.log('✅ المزامنة تعمل بشكل صحيح!');
      } else {
        console.log('📝 لم تتغير الحالة - قد تكون الحالة محدثة بالفعل');
      }
    }

    console.log(`\n🎉 انتهى اختبار المزامنة!`);

  } catch (error) {
    console.error('❌ خطأ في اختبار المزامنة:', error.message);
    if (error.response) {
      console.error('📋 تفاصيل الخطأ:', error.response.data);
    }
  }
}

// دالة مساعدة لإنشاء طلب اختبار
async function createTestOrder(baseURL, userPhone) {
  try {
    console.log('🆕 إنشاء طلب اختبار جديد...');
    
    const testOrderData = {
      customer_name: 'اختبار المزامنة',
      primary_phone: userPhone,
      customer_address: 'بغداد - الكرخ - اختبار المزامنة',
      province: 'بغداد',
      city: 'الكرخ',
      subtotal: 25000,
      delivery_fee: 5000,
      total: 30000,
      profit: 5000,
      status: 'فعال',
      user_phone: userPhone,
      order_number: `TEST-SYNC-${Date.now()}`,
      notes: 'طلب اختبار المزامنة مع الوسيط'
    };

    const response = await axios.post(`${baseURL}/api/orders`, testOrderData, {
      timeout: 30000
    });

    if (response.data.success) {
      console.log('✅ تم إنشاء طلب اختبار جديد');
      return response.data.data;
    }
  } catch (error) {
    console.error('❌ فشل في إنشاء طلب اختبار:', error.message);
  }
  return null;
}

// دالة مساعدة لتحديث حالة الطلب
async function updateOrderStatus(baseURL, orderId, newStatus) {
  try {
    const response = await axios.put(`${baseURL}/api/orders/${orderId}/status`, {
      status: newStatus,
      notes: 'اختبار المزامنة مع الوسيط'
    }, {
      timeout: 30000
    });

    return response.data;
  } catch (error) {
    console.error('❌ فشل في تحديث حالة الطلب:', error.message);
    return { success: false, error: error.message };
  }
}

// دالة مساعدة لجلب تفاصيل الطلب
async function getOrderDetails(baseURL, orderId) {
  try {
    const response = await axios.get(`${baseURL}/api/orders/${orderId}`, {
      timeout: 15000
    });

    return response.data.data;
  } catch (error) {
    console.error('❌ فشل في جلب تفاصيل الطلب:', error.message);
    return null;
  }
}

// تشغيل الاختبار
if (require.main === module) {
  testUserSync().catch(console.error);
}

module.exports = { testUserSync };
