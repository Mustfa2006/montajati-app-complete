const axios = require('axios');

async function analyzeRealUserProblem() {
  console.log('🔍 === تحليل دقيق لمشكلة المستخدم الحقيقية ===\n');
  console.log('📱 محاكاة نفس العملية التي يقوم بها المستخدم على التطبيق\n');

  const baseURL = 'https://montajati-backend.onrender.com';
  
  try {
    // 1. أولاً، دعني أرى الطلبات الحالية كما يراها المستخدم
    console.log('1️⃣ === فحص الطلبات الحالية (كما يراها المستخدم) ===');
    
    const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
    const allOrders = ordersResponse.data.data;
    
    console.log(`📊 إجمالي الطلبات في النظام: ${allOrders.length}`);
    
    // البحث عن طلبات حديثة (آخر 24 ساعة)
    const now = new Date();
    const yesterday = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    
    const recentOrders = allOrders.filter(order => {
      const orderDate = new Date(order.created_at);
      return orderDate > yesterday;
    });
    
    console.log(`📅 الطلبات الحديثة (آخر 24 ساعة): ${recentOrders.length}`);
    
    if (recentOrders.length > 0) {
      console.log('\n📋 آخر الطلبات الحديثة:');
      recentOrders.slice(0, 5).forEach(order => {
        console.log(`   📦 ${order.id}`);
        console.log(`      👤 العميل: ${order.customer_name}`);
        console.log(`      📊 الحالة: ${order.status}`);
        console.log(`      🆔 معرف الوسيط: ${order.waseet_order_id || 'غير محدد'}`);
        console.log(`      📦 حالة الوسيط: ${order.waseet_status || 'غير محدد'}`);
        console.log(`      🕐 تاريخ الإنشاء: ${order.created_at}`);
        console.log(`      🔄 آخر تحديث: ${order.updated_at}`);
        console.log('');
      });
    }
    
    // 2. البحث عن طلب مناسب لمحاكاة تجربة المستخدم
    console.log('2️⃣ === البحث عن طلب لمحاكاة تجربة المستخدم ===');
    
    // البحث عن طلب ليس في حالة توصيل
    const testableOrder = allOrders.find(order => 
      order.status !== 'قيد التوصيل الى الزبون (في عهدة المندوب)' &&
      order.status !== 'تم التسليم للزبون' &&
      order.status !== 'ملغي'
    );
    
    if (testableOrder) {
      console.log(`📦 وجدت طلب مناسب للاختبار: ${testableOrder.id}`);
      console.log(`👤 العميل: ${testableOrder.customer_name}`);
      console.log(`📊 الحالة الحالية: ${testableOrder.status}`);
      
      // 3. محاكاة تغيير حالة الطلب كما يفعل المستخدم
      console.log('\n3️⃣ === محاكاة تغيير حالة الطلب (كما يفعل المستخدم) ===');
      
      await simulateUserOrderStatusChange(baseURL, testableOrder);
      
    } else {
      console.log('⚠️ لم أجد طلب مناسب للاختبار');
      console.log('📝 سأنشئ طلب جديد لمحاكاة التجربة الكاملة...');
      
      // إنشاء طلب جديد لمحاكاة التجربة الكاملة
      await simulateCompleteUserExperience(baseURL);
    }
    
  } catch (error) {
    console.error('❌ خطأ في تحليل مشكلة المستخدم:', error.message);
    if (error.response) {
      console.error('📋 Response:', error.response.data);
    }
  }
}

async function simulateUserOrderStatusChange(baseURL, order) {
  try {
    console.log(`🎭 محاكاة تغيير حالة الطلب: ${order.id}`);
    console.log('📱 كما لو كان المستخدم يضغط على "قيد التوصيل" في التطبيق\n');
    
    // فحص الطلب قبل التغيير
    console.log('📋 حالة الطلب قبل التغيير:');
    console.log(`   📊 الحالة: ${order.status}`);
    console.log(`   🆔 معرف الوسيط: ${order.waseet_order_id || 'غير محدد'}`);
    console.log(`   📦 حالة الوسيط: ${order.waseet_status || 'غير محدد'}`);
    console.log(`   📞 هاتف العميل: ${order.primary_phone || order.customer_phone || 'غير محدد'}`);
    console.log(`   📍 عنوان العميل: ${order.customer_address || order.delivery_address || 'غير محدد'}`);
    console.log(`   💰 المبلغ: ${order.total || order.subtotal || 'غير محدد'}`);
    
    // التحقق من البيانات المطلوبة
    console.log('\n🔍 فحص البيانات المطلوبة للوسيط:');
    
    const hasPhone = order.primary_phone || order.customer_phone || order.secondary_phone;
    const hasAddress = order.customer_address || order.delivery_address || order.notes || 
                      (order.province && order.city);
    const hasAmount = order.total || order.subtotal;
    
    console.log(`   📞 هاتف صحيح: ${hasPhone ? '✅ نعم' : '❌ لا'}`);
    console.log(`   📍 عنوان صحيح: ${hasAddress ? '✅ نعم' : '❌ لا'}`);
    console.log(`   💰 مبلغ صحيح: ${hasAmount ? '✅ نعم' : '❌ لا'}`);
    
    if (!hasPhone || !hasAddress || !hasAmount) {
      console.log('\n⚠️ البيانات ناقصة - هذا قد يكون سبب عدم الإرسال للوسيط');
      if (!hasPhone) console.log('   ❌ لا يوجد رقم هاتف صحيح');
      if (!hasAddress) console.log('   ❌ لا يوجد عنوان صحيح');
      if (!hasAmount) console.log('   ❌ لا يوجد مبلغ صحيح');
    }
    
    // محاكاة الضغط على تغيير الحالة
    console.log('\n📱 المستخدم يضغط على "قيد التوصيل الى الزبون (في عهدة المندوب)"...');
    
    const updateData = {
      status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
      notes: 'تغيير حالة من التطبيق - تحليل مشكلة المستخدم',
      changedBy: 'real_user_simulation'
    };
    
    console.log('📤 إرسال طلب تغيير الحالة...');
    console.log('📋 البيانات المرسلة:', JSON.stringify(updateData, null, 2));
    
    const startTime = Date.now();
    
    const updateResponse = await axios.put(
      `${baseURL}/api/orders/${order.id}/status`,
      updateData,
      {
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        timeout: 60000
      }
    );
    
    const responseTime = Date.now() - startTime;
    
    console.log(`\n📥 استجابة الخادم (خلال ${responseTime}ms):`);
    console.log(`📊 Status Code: ${updateResponse.status}`);
    console.log(`📊 Success: ${updateResponse.data.success}`);
    console.log(`📋 Message: ${updateResponse.data.message}`);
    console.log(`📋 Full Response:`, JSON.stringify(updateResponse.data, null, 2));
    
    if (updateResponse.data.success) {
      console.log('\n✅ تم تحديث الحالة بنجاح في قاعدة البيانات');
      
      // الآن مراقبة ما يحدث للطلب
      console.log('\n4️⃣ === مراقبة دقيقة لما يحدث للطلب ===');
      
      await monitorOrderChanges(baseURL, order.id, 'تحليل مشكلة المستخدم');
      
    } else {
      console.log('\n❌ فشل في تحديث الحالة');
      console.log('📋 الخطأ:', updateResponse.data.error);
      console.log('🔍 هذا قد يكون سبب المشكلة - فشل في تحديث الحالة أصلاً');
    }
    
  } catch (error) {
    console.log(`❌ خطأ في محاكاة تغيير حالة الطلب: ${error.message}`);
    if (error.response) {
      console.log(`📋 Response Status: ${error.response.status}`);
      console.log(`📋 Response Data:`, error.response.data);
    }
  }
}

async function monitorOrderChanges(baseURL, orderId, context) {
  try {
    console.log(`🔍 مراقبة التغييرات على الطلب: ${orderId}`);
    console.log('⏱️ سأراقب كل 5 ثوان لمدة دقيقتين...\n');
    
    const checkIntervals = [2, 5, 10, 15, 20, 30, 45, 60, 90, 120];
    let previousState = null;
    
    for (const seconds of checkIntervals) {
      console.log(`⏳ فحص بعد ${seconds} ثانية...`);
      await new Promise(resolve => setTimeout(resolve, (seconds - (checkIntervals[checkIntervals.indexOf(seconds) - 1] || 0)) * 1000));
      
      try {
        const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
        const currentOrder = ordersResponse.data.data.find(o => o.id === orderId);
        
        if (!currentOrder) {
          console.log('❌ لم يتم العثور على الطلب');
          continue;
        }
        
        const currentState = {
          status: currentOrder.status,
          waseet_order_id: currentOrder.waseet_order_id,
          waseet_status: currentOrder.waseet_status,
          updated_at: currentOrder.updated_at
        };
        
        console.log(`📋 الحالة بعد ${seconds} ثانية:`);
        console.log(`   📊 الحالة: ${currentState.status}`);
        console.log(`   🆔 معرف الوسيط: ${currentState.waseet_order_id || 'غير محدد'}`);
        console.log(`   📦 حالة الوسيط: ${currentState.waseet_status || 'غير محدد'}`);
        console.log(`   🔄 آخر تحديث: ${currentState.updated_at}`);
        
        // تحليل التغييرات
        if (previousState) {
          const changes = [];
          
          if (currentState.status !== previousState.status) {
            changes.push(`الحالة: ${previousState.status} → ${currentState.status}`);
          }
          
          if (currentState.waseet_order_id !== previousState.waseet_order_id) {
            changes.push(`معرف الوسيط: ${previousState.waseet_order_id || 'غير محدد'} → ${currentState.waseet_order_id || 'غير محدد'}`);
          }
          
          if (currentState.waseet_status !== previousState.waseet_status) {
            changes.push(`حالة الوسيط: ${previousState.waseet_status || 'غير محدد'} → ${currentState.waseet_status || 'غير محدد'}`);
          }
          
          if (changes.length > 0) {
            console.log(`   🔄 التغييرات: ${changes.join(', ')}`);
          } else {
            console.log(`   ⚪ لا توجد تغييرات`);
          }
        }
        
        // تحليل الحالة الحالية
        if (currentState.waseet_order_id && currentState.waseet_order_id !== 'null') {
          console.log(`   🎉 نجح! تم إرسال الطلب للوسيط - QR ID: ${currentState.waseet_order_id}`);
          console.log(`   ✅ المشكلة محلولة - الطلب وصل للوسيط`);
          break;
        } else if (currentState.waseet_status === 'pending') {
          console.log(`   ⏳ الطلب في حالة pending - لا يزال قيد المعالجة`);
        } else if (currentState.waseet_status === 'في انتظار الإرسال للوسيط') {
          console.log(`   ❌ فشل في إرسال الطلب للوسيط`);
          console.log(`   🔍 هذا هو سبب المشكلة - فشل في الإرسال للوسيط`);
        } else if (!currentState.waseet_status) {
          console.log(`   ❓ لم يتم محاولة إرسال الطلب للوسيط أصلاً`);
          console.log(`   🔍 هذا قد يكون سبب المشكلة - النظام لم يحاول الإرسال`);
        }
        
        previousState = { ...currentState };
        console.log('');
        
      } catch (error) {
        console.log(`❌ خطأ في فحص الطلب: ${error.message}`);
      }
    }
    
    // تحليل نهائي
    console.log('📊 === تحليل نهائي للمشكلة ===');
    
    try {
      const finalOrdersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
      const finalOrder = finalOrdersResponse.data.data.find(o => o.id === orderId);
      
      if (finalOrder) {
        console.log(`📋 الحالة النهائية للطلب:`);
        console.log(`   📊 الحالة: ${finalOrder.status}`);
        console.log(`   🆔 معرف الوسيط: ${finalOrder.waseet_order_id || 'غير محدد'}`);
        console.log(`   📦 حالة الوسيط: ${finalOrder.waseet_status || 'غير محدد'}`);
        
        if (finalOrder.waseet_data) {
          try {
            const waseetData = typeof finalOrder.waseet_data === 'string' 
              ? JSON.parse(finalOrder.waseet_data) 
              : finalOrder.waseet_data;
            console.log(`   📋 بيانات الوسيط:`, JSON.stringify(waseetData, null, 2));
          } catch (e) {
            console.log(`   📋 بيانات الوسيط (خام): ${finalOrder.waseet_data}`);
          }
        }
        
        // تشخيص المشكلة
        if (finalOrder.waseet_order_id && finalOrder.waseet_order_id !== 'null') {
          console.log('\n✅ === لا توجد مشكلة - الطلب وصل للوسيط ===');
          console.log(`🎉 QR ID: ${finalOrder.waseet_order_id}`);
        } else {
          console.log('\n❌ === تأكيد وجود المشكلة ===');
          console.log('🔍 الطلب لم يصل للوسيط رغم تغيير الحالة');
          
          // تحليل أسباب محتملة
          await diagnosePossibleCauses(baseURL, finalOrder);
        }
      }
      
    } catch (error) {
      console.log(`❌ خطأ في التحليل النهائي: ${error.message}`);
    }
    
  } catch (error) {
    console.log(`❌ خطأ في مراقبة التغييرات: ${error.message}`);
  }
}

async function diagnosePossibleCauses(baseURL, order) {
  console.log('\n🔍 === تشخيص الأسباب المحتملة للمشكلة ===');
  
  // 1. فحص بيانات الطلب
  console.log('\n1️⃣ فحص بيانات الطلب:');
  
  const requiredFields = {
    'customer_name': order.customer_name,
    'primary_phone': order.primary_phone || order.customer_phone,
    'customer_address': order.customer_address || order.delivery_address,
    'total': order.total || order.subtotal,
    'user_id': order.user_id,
    'user_phone': order.user_phone
  };
  
  let missingFields = [];
  
  Object.entries(requiredFields).forEach(([field, value]) => {
    if (!value || value === 'null' || value === '') {
      missingFields.push(field);
      console.log(`   ❌ ${field}: مفقود أو فارغ`);
    } else {
      console.log(`   ✅ ${field}: ${value}`);
    }
  });
  
  if (missingFields.length > 0) {
    console.log(`\n🚨 مشكلة محتملة: حقول مفقودة (${missingFields.join(', ')})`);
  }
  
  // 2. فحص خدمة المزامنة
  console.log('\n2️⃣ فحص خدمة المزامنة:');
  
  try {
    const syncResponse = await axios.get(`${baseURL}/api/sync/status`, { 
      timeout: 10000,
      validateStatus: () => true 
    });
    
    if (syncResponse.status === 200) {
      console.log('   ✅ خدمة المزامنة تعمل');
      console.log('   📋 حالة الخدمة:', syncResponse.data);
    } else {
      console.log(`   ❌ خدمة المزامنة تعطي status: ${syncResponse.status}`);
      console.log('   🚨 مشكلة محتملة: خدمة المزامنة معطلة');
    }
  } catch (error) {
    console.log(`   ❌ خطأ في خدمة المزامنة: ${error.message}`);
    console.log('   🚨 مشكلة محتملة: خدمة المزامنة لا تعمل');
  }
  
  // 3. فحص اتصال الوسيط
  console.log('\n3️⃣ فحص اتصال الوسيط:');
  
  try {
    const waseetResponse = await axios.post(`${baseURL}/api/waseet/test-connection`, {}, { 
      timeout: 15000,
      validateStatus: () => true 
    });
    
    if (waseetResponse.status === 200 && waseetResponse.data.success) {
      console.log('   ✅ اتصال الوسيط يعمل');
    } else {
      console.log(`   ❌ مشكلة في اتصال الوسيط - Status: ${waseetResponse.status}`);
      console.log('   📋 الاستجابة:', waseetResponse.data);
      console.log('   🚨 مشكلة محتملة: اتصال الوسيط معطل');
    }
  } catch (error) {
    console.log(`   ❌ خطأ في اتصال الوسيط: ${error.message}`);
    console.log('   🚨 مشكلة محتملة: الوسيط غير متاح');
  }
  
  // 4. محاولة إرسال يدوي
  console.log('\n4️⃣ محاولة إرسال يدوي للطلب:');
  
  try {
    const manualSendResponse = await axios.post(`${baseURL}/api/orders/${order.id}/send-to-waseet`, {}, {
      timeout: 30000,
      validateStatus: () => true
    });
    
    console.log(`   📊 Status: ${manualSendResponse.status}`);
    console.log(`   📋 Response:`, JSON.stringify(manualSendResponse.data, null, 2));
    
    if (manualSendResponse.data.success) {
      console.log('   ✅ نجح الإرسال اليدوي');
      console.log(`   🆔 QR ID: ${manualSendResponse.data.data?.qrId}`);
      console.log('   🔍 المشكلة: النظام التلقائي لا يعمل، لكن الإرسال اليدوي يعمل');
    } else {
      console.log('   ❌ فشل الإرسال اليدوي أيضاً');
      console.log('   🚨 مشكلة أساسية في إرسال الطلبات للوسيط');
    }
  } catch (error) {
    console.log(`   ❌ خطأ في الإرسال اليدوي: ${error.message}`);
  }
  
  console.log('\n📋 === خلاصة التشخيص ===');
  console.log('🔍 بناءً على التحليل أعلاه، المشكلة قد تكون في:');
  console.log('1. بيانات الطلب ناقصة أو غير صحيحة');
  console.log('2. خدمة المزامنة معطلة أو لا تعمل');
  console.log('3. اتصال الوسيط معطل أو غير متاح');
  console.log('4. مشكلة في النظام التلقائي لإرسال الطلبات');
}

async function simulateCompleteUserExperience(baseURL) {
  console.log('\n🎭 === محاكاة التجربة الكاملة للمستخدم ===');
  console.log('📱 إنشاء طلب جديد ثم تغيير حالته (كما يفعل المستخدم)\n');
  
  // إنشاء طلب جديد
  const newOrderData = {
    customer_name: 'عميل محاكاة حقيقية',
    primary_phone: '07901234567',
    secondary_phone: '07709876543',
    customer_address: 'بغداد - الكرخ - محاكاة تجربة المستخدم',
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
    order_number: `ORD-USER-SIM-${Date.now()}`,
    notes: 'طلب محاكاة تجربة المستخدم الحقيقية'
  };
  
  try {
    console.log('📝 المستخدم ينشئ طلب جديد...');
    
    const createResponse = await axios.post(`${baseURL}/api/orders`, newOrderData, {
      headers: {
        'Content-Type': 'application/json'
      },
      timeout: 30000
    });
    
    if (createResponse.data.success) {
      const orderId = createResponse.data.data.id;
      console.log(`✅ تم إنشاء الطلب: ${orderId}`);
      
      // انتظار قصير كما يفعل المستخدم
      await new Promise(resolve => setTimeout(resolve, 3000));
      
      // تغيير حالة الطلب
      console.log('\n📱 المستخدم يغير حالة الطلب إلى "قيد التوصيل"...');
      
      const fakeOrder = {
        id: orderId,
        customer_name: newOrderData.customer_name,
        status: newOrderData.status,
        primary_phone: newOrderData.primary_phone,
        customer_address: newOrderData.customer_address,
        total: newOrderData.total,
        waseet_order_id: null,
        waseet_status: null
      };
      
      await simulateUserOrderStatusChange(baseURL, fakeOrder);
      
    } else {
      console.log('❌ فشل في إنشاء الطلب');
      console.log('📋 الخطأ:', createResponse.data.error);
    }
    
  } catch (error) {
    console.log(`❌ خطأ في محاكاة التجربة الكاملة: ${error.message}`);
  }
}

analyzeRealUserProblem();
