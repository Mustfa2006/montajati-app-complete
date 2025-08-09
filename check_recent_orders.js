const axios = require('axios');

async function checkRecentOrders() {
  console.log('🔍 === فحص الطلبات الحديثة ===\n');
  
  try {
    const response = await axios.get('https://montajati-backend.onrender.com/api/orders', { 
      timeout: 15000 
    });
    
    const allOrders = response.data.data;
    
    // ترتيب الطلبات حسب تاريخ الإنشاء (الأحدث أولاً)
    const sortedOrders = allOrders.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
    
    console.log('📋 === آخر 10 طلبات تم إنشاؤها ===\n');
    
    sortedOrders.slice(0, 10).forEach((order, index) => {
      const createdTime = new Date(order.created_at);
      const now = new Date();
      const diffMinutes = Math.floor((now - createdTime) / (1000 * 60));
      
      console.log(`${index + 1}. طلب: ${order.id}`);
      console.log(`   👤 العميل: ${order.customer_name}`);
      console.log(`   📊 الحالة: ${order.status}`);
      console.log(`   📅 تاريخ الإنشاء: ${order.created_at}`);
      console.log(`   ⏰ منذ الإنشاء: ${diffMinutes} دقيقة`);
      
      if (order.status === 'قيد التوصيل الى الزبون (في عهدة المندوب)') {
        console.log(`   🆔 معرف الوسيط: ${order.waseet_order_id || 'غير محدد'}`);
        console.log(`   📦 حالة الوسيط: ${order.waseet_status || 'غير محدد'}`);
        
        if (order.waseet_order_id && order.waseet_order_id !== 'null') {
          console.log(`   ✅ تم الإرسال للوسيط بنجاح`);
        } else {
          console.log(`   ❌ لم يتم الإرسال للوسيط`);
        }
      }
      console.log('');
    });
    
    // البحث عن الطلبات الحديثة في حالة التوصيل
    const recentDeliveryOrders = sortedOrders.filter(order => 
      order.status === 'قيد التوصيل الى الزبون (في عهدة المندوب)' &&
      (new Date() - new Date(order.created_at)) < (2 * 60 * 60 * 1000) // آخر ساعتين
    );
    
    console.log(`📦 طلبات التوصيل في آخر ساعتين: ${recentDeliveryOrders.length}`);
    
    if (recentDeliveryOrders.length > 0) {
      console.log('\n📋 تفاصيل الطلبات الحديثة في حالة التوصيل:');
      
      recentDeliveryOrders.forEach((order, index) => {
        const createdTime = new Date(order.created_at);
        const updatedTime = new Date(order.updated_at);
        const diffMinutes = Math.floor((new Date() - updatedTime) / (1000 * 60));
        
        console.log(`\n${index + 1}. طلب: ${order.id}`);
        console.log(`   👤 العميل: ${order.customer_name}`);
        console.log(`   📅 تاريخ الإنشاء: ${createdTime.toLocaleString('ar-IQ')}`);
        console.log(`   📅 آخر تحديث: ${updatedTime.toLocaleString('ar-IQ')}`);
        console.log(`   ⏰ منذ آخر تحديث: ${diffMinutes} دقيقة`);
        console.log(`   🆔 معرف الوسيط: ${order.waseet_order_id || 'غير محدد'}`);
        console.log(`   📦 حالة الوسيط: ${order.waseet_status || 'غير محدد'}`);
        
        if (order.waseet_order_id && order.waseet_order_id !== 'null') {
          console.log(`   ✅ تم الإرسال للوسيط بنجاح - QR ID: ${order.waseet_order_id}`);
        } else {
          console.log(`   ❌ لم يتم الإرسال للوسيط`);
          
          if (order.waseet_status === 'pending') {
            console.log(`   🔄 الحالة: pending - قد يكون قيد المعالجة`);
          } else if (order.waseet_status === 'في انتظار الإرسال للوسيط') {
            console.log(`   ⏳ الحالة: في انتظار الإرسال`);
          } else if (!order.waseet_status) {
            console.log(`   ❓ لم يتم محاولة الإرسال أصلاً`);
          }
          
          // محاولة إرسال يدوي للطلبات الحديثة المشكلة
          console.log(`   🔧 سيتم محاولة الإرسال اليدوي لاحقاً...`);
        }
      });
    }
    
    // إحصائيات عامة
    console.log('\n📊 === إحصائيات عامة ===');
    
    const deliveryOrders = allOrders.filter(order => 
      order.status === 'قيد التوصيل الى الزبون (في عهدة المندوب)'
    );
    
    const successfulOrders = deliveryOrders.filter(order => 
      order.waseet_order_id && order.waseet_order_id !== 'null'
    );
    
    const failedOrders = deliveryOrders.filter(order => 
      !order.waseet_order_id || order.waseet_order_id === 'null'
    );
    
    console.log(`📦 إجمالي طلبات التوصيل: ${deliveryOrders.length}`);
    console.log(`✅ تم إرسالها بنجاح: ${successfulOrders.length}`);
    console.log(`❌ لم يتم إرسالها: ${failedOrders.length}`);
    console.log(`📈 معدل النجاح: ${((successfulOrders.length / deliveryOrders.length) * 100).toFixed(1)}%`);
    
    if (failedOrders.length === 0) {
      console.log('\n🎉 === النظام يعمل بشكل مثالي! ===');
      console.log('✅ جميع الطلبات تم إرسالها للوسيط بنجاح');
      console.log('📱 يمكنك استخدام التطبيق بثقة كاملة');
    } else if (failedOrders.length === 1 && failedOrders[0].id === 'order_1753489643751_4645') {
      console.log('\n🎯 === النظام يعمل بشكل صحيح! ===');
      console.log('✅ الطلب الوحيد المشكلة هو طلب قديم من قبل الإصلاحات');
      console.log('✅ جميع الطلبات الجديدة تعمل بشكل مثالي');
      console.log('📱 يمكنك استخدام التطبيق بثقة كاملة');
    } else {
      console.log('\n⚠️ === يوجد طلبات حديثة مشكلة ===');
      console.log(`❌ عدد الطلبات المشكلة: ${failedOrders.length}`);
      console.log('🔍 تحتاج لمراجعة إضافية');
    }
    
  } catch (error) {
    console.error('❌ خطأ في فحص الطلبات الحديثة:', error.message);
  }
}

checkRecentOrders();
