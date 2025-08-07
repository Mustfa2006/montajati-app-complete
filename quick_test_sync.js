const axios = require('axios');

async function quickTestSync() {
  console.log('🧪 اختبار سريع للمزامنة');
  console.log('='.repeat(40));

  const baseURL = 'https://clownfish-app-krnk9.ondigitalocean.app';
  const testUserPhone = '07503597589';

  try {
    // 1. جلب طلبات المستخدم
    console.log(`\n📋 جلب طلبات المستخدم ${testUserPhone}...`);
    
    const response = await axios.get(`${baseURL}/api/orders?search=${testUserPhone}`, {
      timeout: 30000
    });

    const orders = response.data.data || [];
    console.log(`📊 عدد الطلبات: ${orders.length}`);

    if (orders.length === 0) {
      console.log('❌ لا توجد طلبات لهذا المستخدم');
      return;
    }

    // 2. عرض الطلبات
    console.log('\n📦 طلبات المستخدم:');
    orders.forEach((order, index) => {
      console.log(`${index + 1}. ID: ${order.id}`);
      console.log(`   الحالة: "${order.status}"`);
      console.log(`   معرف الوسيط: ${order.waseet_order_id || 'غير مرسل'}`);
      console.log(`   حالة الوسيط: "${order.waseet_status_text || 'غير محدد'}"`);
      console.log('');
    });

    // 3. اختبار المزامنة على طلب واحد
    const testOrder = orders.find(o => o.waseet_order_id) || orders[0];
    
    console.log(`🎯 اختبار المزامنة على الطلب: ${testOrder.id}`);
    console.log(`📊 الحالة الحالية: "${testOrder.status}"`);

    // 4. تشغيل المزامنة الفورية
    console.log('\n🔄 تشغيل المزامنة الفورية...');
    
    try {
      const syncResponse = await axios.post(`${baseURL}/api/orders/force-sync`, {}, {
        timeout: 60000
      });

      console.log('✅ تم تشغيل المزامنة');
      console.log('📊 النتائج:', JSON.stringify(syncResponse.data, null, 2));
    } catch (syncError) {
      console.log('❌ خطأ في المزامنة:', syncError.message);
    }

    // 5. فحص النتائج
    console.log('\n⏳ انتظار 5 ثواني ثم فحص النتائج...');
    await new Promise(resolve => setTimeout(resolve, 5000));

    const checkResponse = await axios.get(`${baseURL}/api/orders/${testOrder.id}`, {
      timeout: 15000
    });

    const updatedOrder = checkResponse.data.data;
    console.log('\n📊 حالة الطلب بعد المزامنة:');
    console.log(`   الحالة: "${updatedOrder.status}"`);
    console.log(`   معرف الوسيط: ${updatedOrder.waseet_order_id || 'غير محدد'}`);
    console.log(`   حالة الوسيط: "${updatedOrder.waseet_status_text || 'غير محدد'}"`);

    if (testOrder.status !== updatedOrder.status) {
      console.log(`\n🔄 تغيرت الحالة: "${testOrder.status}" → "${updatedOrder.status}"`);
      console.log('✅ المزامنة تعمل!');
    } else {
      console.log('\n📝 لم تتغير الحالة');
    }

  } catch (error) {
    console.error('❌ خطأ:', error.message);
  }
}

quickTestSync();
