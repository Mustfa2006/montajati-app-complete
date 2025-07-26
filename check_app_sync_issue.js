const axios = require('axios');

async function checkAppSyncIssue() {
  console.log('🔍 === فحص مشكلة مزامنة التطبيق ===\n');
  console.log('🤔 النظام يعمل، لكن المستخدم لا يرى النتائج في التطبيق\n');

  const baseURL = 'https://montajati-backend.onrender.com';
  
  try {
    // 1. فحص آخر الطلبات التي تم تحديثها
    console.log('1️⃣ === فحص آخر الطلبات المُحدثة ===');
    
    const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
    const allOrders = ordersResponse.data.data;
    
    // ترتيب الطلبات حسب آخر تحديث
    const recentlyUpdated = allOrders
      .filter(order => order.status === 'قيد التوصيل الى الزبون (في عهدة المندوب)')
      .sort((a, b) => new Date(b.updated_at) - new Date(a.updated_at))
      .slice(0, 10);
    
    console.log(`📊 الطلبات في حالة توصيل: ${recentlyUpdated.length}`);
    
    console.log('\n📋 آخر 10 طلبات تم تحديثها:');
    recentlyUpdated.forEach((order, index) => {
      const updateTime = new Date(order.updated_at);
      const timeDiff = Date.now() - updateTime.getTime();
      const minutesAgo = Math.floor(timeDiff / (1000 * 60));
      
      console.log(`${index + 1}. 📦 ${order.id}`);
      console.log(`   👤 العميل: ${order.customer_name}`);
      console.log(`   🆔 معرف الوسيط: ${order.waseet_order_id || 'غير محدد'}`);
      console.log(`   📦 حالة الوسيط: ${order.waseet_status || 'غير محدد'}`);
      console.log(`   🕐 آخر تحديث: ${minutesAgo} دقيقة مضت`);
      
      if (order.waseet_order_id && order.waseet_order_id !== 'null') {
        console.log(`   ✅ تم إرساله للوسيط بنجاح`);
      } else {
        console.log(`   ❌ لم يتم إرساله للوسيط`);
      }
      console.log('');
    });
    
    // 2. فحص مشكلة محتملة في التحديث
    console.log('2️⃣ === فحص مشكلة التحديث في التطبيق ===');
    
    // البحث عن طلبات حديثة بدون معرف وسيط
    const recentWithoutWaseet = allOrders.filter(order => {
      const updateTime = new Date(order.updated_at);
      const timeDiff = Date.now() - updateTime.getTime();
      const minutesAgo = Math.floor(timeDiff / (1000 * 60));
      
      return order.status === 'قيد التوصيل الى الزبون (في عهدة المندوب)' &&
             (!order.waseet_order_id || order.waseet_order_id === 'null') &&
             minutesAgo < 60; // آخر ساعة
    });
    
    console.log(`📊 طلبات حديثة بدون معرف وسيط: ${recentWithoutWaseet.length}`);
    
    if (recentWithoutWaseet.length > 0) {
      console.log('\n⚠️ طلبات حديثة لم تصل للوسيط:');
      for (const order of recentWithoutWaseet) {
        const updateTime = new Date(order.updated_at);
        const timeDiff = Date.now() - updateTime.getTime();
        const minutesAgo = Math.floor(timeDiff / (1000 * 60));

        console.log(`   📦 ${order.id} - ${order.customer_name}`);
        console.log(`      📦 حالة الوسيط: ${order.waseet_status || 'غير محدد'}`);
        console.log(`      🕐 منذ: ${minutesAgo} دقيقة`);

        // محاولة إصلاح هذا الطلب
        console.log(`      🔧 محاولة إصلاح الطلب...`);
        await tryFixOrder(baseURL, order.id);
      }
    } else {
      console.log('✅ جميع الطلبات الحديثة تم إرسالها للوسيط بنجاح');
    }
    
    // 3. فحص مشكلة التأخير في المعالجة
    console.log('\n3️⃣ === فحص مشكلة التأخير في المعالجة ===');
    
    // البحث عن طلبات في حالة pending لفترة طويلة
    const stuckPending = allOrders.filter(order => {
      const updateTime = new Date(order.updated_at);
      const timeDiff = Date.now() - updateTime.getTime();
      const minutesAgo = Math.floor(timeDiff / (1000 * 60));
      
      return order.waseet_status === 'pending' && minutesAgo > 5;
    });
    
    console.log(`📊 طلبات عالقة في pending: ${stuckPending.length}`);
    
    if (stuckPending.length > 0) {
      console.log('\n⚠️ طلبات عالقة في حالة pending:');
      for (const order of stuckPending) {
        const updateTime = new Date(order.updated_at);
        const timeDiff = Date.now() - updateTime.getTime();
        const minutesAgo = Math.floor(timeDiff / (1000 * 60));

        console.log(`   📦 ${order.id} - ${order.customer_name}`);
        console.log(`      📊 الحالة: ${order.status}`);
        console.log(`      🕐 عالق منذ: ${minutesAgo} دقيقة`);

        // محاولة إصلاح هذا الطلب
        console.log(`      🔧 محاولة إصلاح الطلب العالق...`);
        await tryFixOrder(baseURL, order.id);
      }
    } else {
      console.log('✅ لا توجد طلبات عالقة في pending');
    }
    
    // 4. اختبار إنشاء طلب جديد والتحقق من السرعة
    console.log('\n4️⃣ === اختبار سرعة المعالجة ===');
    await testProcessingSpeed(baseURL);
    
    // 5. فحص مشكلة محتملة في التطبيق
    console.log('\n5️⃣ === تحليل مشكلة محتملة في التطبيق ===');
    await analyzeAppIssue();
    
  } catch (error) {
    console.error('❌ خطأ في فحص مشكلة المزامنة:', error.message);
  }
}

async function tryFixOrder(baseURL, orderId) {
  try {
    const updateData = {
      status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
      notes: `إصلاح طلب - ${new Date().toISOString()}`,
      changedBy: 'sync_issue_fix'
    };
    
    const updateResponse = await axios.put(
      `${baseURL}/api/orders/${orderId}/status`,
      updateData,
      {
        headers: {
          'Content-Type': 'application/json'
        },
        timeout: 30000
      }
    );
    
    if (updateResponse.data.success) {
      console.log(`      ✅ تم إرسال طلب الإصلاح`);
      
      // انتظار قصير
      await new Promise(resolve => setTimeout(resolve, 10000));
      
      // فحص النتيجة
      const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
      const updatedOrder = ordersResponse.data.data.find(o => o.id === orderId);
      
      if (updatedOrder && updatedOrder.waseet_order_id && updatedOrder.waseet_order_id !== 'null') {
        console.log(`      🎉 تم إصلاح الطلب! QR ID: ${updatedOrder.waseet_order_id}`);
      } else {
        console.log(`      ❌ لم ينجح الإصلاح`);
        console.log(`      📦 حالة الوسيط: ${updatedOrder?.waseet_status || 'غير محدد'}`);
      }
    } else {
      console.log(`      ❌ فشل في إرسال طلب الإصلاح`);
    }
    
  } catch (error) {
    console.log(`      ❌ خطأ في إصلاح الطلب: ${error.message}`);
  }
}

async function testProcessingSpeed(baseURL) {
  try {
    console.log('⚡ اختبار سرعة معالجة طلب جديد...');
    
    const startTime = Date.now();
    
    // إنشاء طلب جديد
    const newOrderData = {
      customer_name: 'اختبار سرعة المعالجة',
      primary_phone: '07901234567',
      customer_address: 'بغداد - الكرخ - اختبار سرعة',
      province: 'بغداد',
      city: 'الكرخ',
      subtotal: 25000,
      delivery_fee: 5000,
      total: 30000,
      profit: 5000,
      profit_amount: 5000,
      status: 'active',
      user_id: 'bba1fc61-3db9-4c5f-8b19-d8689251990d',
      user_phone: '07503597589',
      order_number: `ORD-SPEED-${Date.now()}`,
      notes: 'اختبار سرعة المعالجة'
    };
    
    const createResponse = await axios.post(`${baseURL}/api/orders`, newOrderData, {
      headers: {
        'Content-Type': 'application/json'
      },
      timeout: 30000
    });
    
    const createTime = Date.now() - startTime;
    console.log(`📝 وقت إنشاء الطلب: ${createTime}ms`);
    
    if (createResponse.data.success) {
      const orderId = createResponse.data.data.id;
      console.log(`✅ تم إنشاء الطلب: ${orderId}`);
      
      // تحديث الحالة
      const updateStartTime = Date.now();
      
      const updateData = {
        status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
        notes: 'اختبار سرعة المعالجة - تحديث الحالة',
        changedBy: 'speed_test'
      };
      
      const updateResponse = await axios.put(
        `${baseURL}/api/orders/${orderId}/status`,
        updateData,
        {
          headers: {
            'Content-Type': 'application/json'
          },
          timeout: 60000
        }
      );
      
      const updateTime = Date.now() - updateStartTime;
      console.log(`🔄 وقت تحديث الحالة: ${updateTime}ms`);
      
      if (updateResponse.data.success) {
        console.log(`✅ تم تحديث الحالة بنجاح`);
        
        // مراقبة الإرسال للوسيط
        const waseetStartTime = Date.now();
        let waseetTime = null;
        
        for (let i = 0; i < 12; i++) { // فحص كل 5 ثوان لمدة دقيقة
          await new Promise(resolve => setTimeout(resolve, 5000));
          
          const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
          const currentOrder = ordersResponse.data.data.find(o => o.id === orderId);
          
          if (currentOrder && currentOrder.waseet_order_id && currentOrder.waseet_order_id !== 'null') {
            waseetTime = Date.now() - waseetStartTime;
            console.log(`🚚 وقت الإرسال للوسيط: ${waseetTime}ms (${Math.round(waseetTime/1000)} ثانية)`);
            console.log(`🆔 QR ID: ${currentOrder.waseet_order_id}`);
            break;
          }
        }
        
        if (!waseetTime) {
          console.log(`❌ لم يتم إرسال الطلب للوسيط خلال دقيقة`);
        }
        
        // خلاصة الأوقات
        console.log('\n📊 ملخص الأوقات:');
        console.log(`   📝 إنشاء الطلب: ${createTime}ms`);
        console.log(`   🔄 تحديث الحالة: ${updateTime}ms`);
        console.log(`   🚚 الإرسال للوسيط: ${waseetTime ? `${Math.round(waseetTime/1000)} ثانية` : 'فشل'}`);
        console.log(`   ⏱️ الوقت الإجمالي: ${waseetTime ? Math.round((createTime + updateTime + waseetTime)/1000) : 'غير محدد'} ثانية`);
        
      } else {
        console.log(`❌ فشل في تحديث الحالة`);
      }
      
    } else {
      console.log(`❌ فشل في إنشاء الطلب`);
    }
    
  } catch (error) {
    console.log(`❌ خطأ في اختبار السرعة: ${error.message}`);
  }
}

async function analyzeAppIssue() {
  console.log('🔍 تحليل مشكلة محتملة في التطبيق...');
  
  console.log('\n📱 المشاكل المحتملة في التطبيق:');
  
  console.log('\n1️⃣ مشكلة التحديث التلقائي:');
  console.log('   - التطبيق قد لا يحدث البيانات تلقائياً');
  console.log('   - المستخدم يحتاج لإعادة تحميل الصفحة أو التطبيق');
  console.log('   - مشكلة في الـ polling أو real-time updates');
  
  console.log('\n2️⃣ مشكلة التأخير في العرض:');
  console.log('   - النظام يعمل لكن التطبيق يأخذ وقت لعرض النتائج');
  console.log('   - مشكلة في الـ caching أو state management');
  console.log('   - تأخير في استدعاء API للحصول على البيانات المحدثة');
  
  console.log('\n3️⃣ مشكلة في واجهة المستخدم:');
  console.log('   - المعرف موجود لكن لا يظهر في التطبيق');
  console.log('   - مشكلة في عرض بيانات الوسيط');
  console.log('   - خطأ في parsing أو عرض البيانات');
  
  console.log('\n4️⃣ مشكلة في المزامنة:');
  console.log('   - التطبيق يعرض بيانات قديمة');
  console.log('   - مشكلة في sync بين local storage والخادم');
  console.log('   - تضارب في البيانات');
  
  console.log('\n🔧 الحلول المقترحة:');
  console.log('1. إضافة تحديث تلقائي كل 30 ثانية');
  console.log('2. إضافة زر "تحديث" يدوي');
  console.log('3. إضافة إشعار عند نجاح الإرسال للوسيط');
  console.log('4. تحسين عرض حالة الطلب في الوقت الفعلي');
  console.log('5. إضافة loading indicator أثناء المعالجة');
  
  console.log('\n📋 توصيات للمستخدم:');
  console.log('1. انتظر 30-60 ثانية بعد تغيير الحالة');
  console.log('2. أعد تحميل صفحة الطلبات');
  console.log('3. تحقق من قسم "قيد التوصيل" في التطبيق');
  console.log('4. ابحث عن QR ID في تفاصيل الطلب');
}

checkAppSyncIssue();
