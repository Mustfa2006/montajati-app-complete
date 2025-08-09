const axios = require('axios');

async function analyzeProblematicOrders() {
  console.log('🔍 === تحليل الطلبات المشكوك فيها ===\n');

  const baseURL = 'https://montajati-backend.onrender.com';
  
  // قائمة الطلبات المشكوك فيها من الفحص السابق
  const problematicOrders = [
    'order_1753478889109_1111',
    'order_1753473073199_6564', 
    'order_1753465511829_2222',
    'order_1753451944028_5555',
    'order_1753450297027_5555'
  ];
  
  try {
    // جلب تفاصيل الطلبات
    const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 30000 });
    const allOrders = ordersResponse.data.data;
    
    console.log('📊 تحليل تفصيلي للطلبات المشكوك فيها:\n');
    
    for (const orderId of problematicOrders) {
      const order = allOrders.find(o => o.id === orderId);
      
      if (!order) {
        console.log(`❌ لم يتم العثور على الطلب: ${orderId}\n`);
        continue;
      }
      
      console.log(`📦 === ${orderId} ===`);
      console.log(`👤 العميل: ${order.customer_name}`);
      console.log(`📊 الحالة: ${order.status}`);
      console.log(`📞 الهاتف الأساسي: ${order.primary_phone || 'غير محدد'}`);
      console.log(`📞 الهاتف الثانوي: ${order.secondary_phone || 'غير محدد'}`);
      console.log(`📞 هاتف العميل: ${order.customer_phone || 'غير محدد'}`);
      console.log(`🏙️ المحافظة: ${order.province || 'غير محدد'}`);
      console.log(`🏘️ المدينة: ${order.city || 'غير محدد'}`);
      console.log(`📍 عنوان العميل: ${order.customer_address || 'غير محدد'}`);
      console.log(`📍 عنوان التوصيل: ${order.delivery_address || 'غير محدد'}`);
      console.log(`📝 الملاحظات: ${order.notes || 'غير محدد'}`);
      console.log(`💰 المجموع: ${order.total || order.subtotal || 'غير محدد'}`);
      console.log(`🆔 معرف الوسيط: ${order.waseet_order_id || 'غير محدد'}`);
      console.log(`📦 حالة الوسيط: ${order.waseet_status || 'غير محدد'}`);
      console.log(`📋 بيانات الوسيط: ${order.waseet_data ? 'موجودة' : 'غير موجودة'}`);
      console.log(`🕐 تاريخ الإنشاء: ${order.created_at}`);
      console.log(`🔄 آخر تحديث: ${order.updated_at}`);
      
      // تحليل البيانات
      console.log('\n🔍 تحليل البيانات:');
      
      // فحص الهاتف
      const hasValidPhone = order.primary_phone || order.customer_phone || order.secondary_phone;
      console.log(`📞 هاتف صحيح: ${hasValidPhone ? '✅ نعم' : '❌ لا'}`);
      
      // فحص العنوان
      const hasValidAddress = order.customer_address || order.delivery_address || order.notes || 
                             (order.province && order.city);
      console.log(`📍 عنوان صحيح: ${hasValidAddress ? '✅ نعم' : '❌ لا'}`);
      
      // فحص المبلغ
      const hasValidAmount = order.total || order.subtotal;
      console.log(`💰 مبلغ صحيح: ${hasValidAmount ? '✅ نعم' : '❌ لا'}`);
      
      // فحص الحالة
      const isDeliveryStatus = order.status === 'قيد التوصيل الى الزبون (في عهدة المندوب)';
      console.log(`📊 حالة توصيل: ${isDeliveryStatus ? '✅ نعم' : '❌ لا'}`);
      
      // تحليل سبب عدم الإرسال
      if (isDeliveryStatus && hasValidPhone && hasValidAddress && hasValidAmount) {
        console.log('🤔 البيانات تبدو صحيحة، لكن لم يرسل للوسيط');
        
        if (order.waseet_status === 'pending') {
          console.log('📋 السبب المحتمل: النظام لم ينجح في الإرسال بعد');
        } else if (order.waseet_status === 'في انتظار الإرسال للوسيط') {
          console.log('📋 السبب المحتمل: النظام يحاول لكن يفشل');
        } else if (!order.waseet_status) {
          console.log('📋 السبب المحتمل: النظام لم يحاول الإرسال أصلاً');
        }
        
        // محاولة إعادة إرسال هذا الطلب
        console.log('\n🔄 محاولة إعادة إرسال الطلب...');
        await retryOrderToWaseet(baseURL, order);
        
      } else {
        console.log('❌ البيانات ناقصة - هذا يفسر عدم الإرسال');
        if (!hasValidPhone) console.log('   - لا يوجد رقم هاتف صحيح');
        if (!hasValidAddress) console.log('   - لا يوجد عنوان صحيح');
        if (!hasValidAmount) console.log('   - لا يوجد مبلغ صحيح');
        if (!isDeliveryStatus) console.log('   - ليس في حالة توصيل');
      }
      
      console.log('\n' + '='.repeat(60) + '\n');
    }
    
    // تحليل عام
    console.log('📊 === تحليل عام ===');
    
    // فحص جميع الطلبات في حالة توصيل
    const deliveryOrders = allOrders.filter(order => 
      order.status === 'قيد التوصيل الى الزبون (في عهدة المندوب)'
    );
    
    const sentToWaseet = deliveryOrders.filter(order => 
      order.waseet_order_id && order.waseet_order_id !== 'null'
    );
    
    const notSentToWaseet = deliveryOrders.filter(order => 
      !order.waseet_order_id || order.waseet_order_id === 'null'
    );
    
    console.log(`📦 إجمالي الطلبات في حالة توصيل: ${deliveryOrders.length}`);
    console.log(`✅ مرسلة للوسيط: ${sentToWaseet.length}`);
    console.log(`❌ غير مرسلة للوسيط: ${notSentToWaseet.length}`);
    console.log(`📈 معدل النجاح: ${((sentToWaseet.length / deliveryOrders.length) * 100).toFixed(1)}%`);
    
    // تحليل الطلبات الناجحة
    if (sentToWaseet.length > 0) {
      console.log('\n✅ تحليل الطلبات الناجحة:');
      sentToWaseet.slice(0, 3).forEach(order => {
        console.log(`   📦 ${order.id} - ${order.customer_name} - QR: ${order.waseet_order_id}`);
      });
    }
    
    // تحليل الطلبات الفاشلة
    if (notSentToWaseet.length > 0) {
      console.log('\n❌ تحليل الطلبات الفاشلة:');
      
      const failureReasons = {
        noPhone: 0,
        noAddress: 0,
        noAmount: 0,
        systemError: 0
      };
      
      notSentToWaseet.forEach(order => {
        const hasPhone = order.primary_phone || order.customer_phone || order.secondary_phone;
        const hasAddress = order.customer_address || order.delivery_address || order.notes || 
                          (order.province && order.city);
        const hasAmount = order.total || order.subtotal;
        
        if (!hasPhone) failureReasons.noPhone++;
        if (!hasAddress) failureReasons.noAddress++;
        if (!hasAmount) failureReasons.noAmount++;
        if (hasPhone && hasAddress && hasAmount) failureReasons.systemError++;
      });
      
      console.log(`   📞 بدون هاتف: ${failureReasons.noPhone}`);
      console.log(`   📍 بدون عنوان: ${failureReasons.noAddress}`);
      console.log(`   💰 بدون مبلغ: ${failureReasons.noAmount}`);
      console.log(`   🔧 خطأ في النظام: ${failureReasons.systemError}`);
    }
    
  } catch (error) {
    console.error('❌ خطأ في تحليل الطلبات:', error.message);
  }
}

async function retryOrderToWaseet(baseURL, order) {
  try {
    const updateData = {
      status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
      notes: `إعادة محاولة إرسال للوسيط - ${new Date().toISOString()}`,
      changedBy: 'retry_analysis'
    };
    
    const updateResponse = await axios.put(
      `${baseURL}/api/orders/${order.id}/status`,
      updateData,
      {
        headers: {
          'Content-Type': 'application/json'
        },
        timeout: 30000
      }
    );
    
    if (updateResponse.data.success) {
      console.log('✅ تم إرسال طلب إعادة المحاولة');
      
      // انتظار قصير
      await new Promise(resolve => setTimeout(resolve, 15000));
      
      // فحص النتيجة
      const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
      const updatedOrder = ordersResponse.data.data.find(o => o.id === order.id);
      
      if (updatedOrder && updatedOrder.waseet_order_id && updatedOrder.waseet_order_id !== 'null') {
        console.log(`🎉 نجحت إعادة المحاولة! QR ID: ${updatedOrder.waseet_order_id}`);
      } else {
        console.log('❌ فشلت إعادة المحاولة');
        if (updatedOrder && updatedOrder.waseet_status) {
          console.log(`📋 حالة الوسيط: ${updatedOrder.waseet_status}`);
        }
      }
      
    } else {
      console.log('❌ فشل في إرسال طلب إعادة المحاولة');
    }
    
  } catch (error) {
    console.log(`❌ خطأ في إعادة المحاولة: ${error.message}`);
  }
}

analyzeProblematicOrders();
