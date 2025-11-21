const axios = require('axios');

async function testExactUserFlow() {
  console.log('🎯 === اختبار التدفق الدقيق للمستخدم ===\n');
  console.log('📱 محاكاة ما يحدث بالضبط عندما تختار الحالة في التطبيق\n');

  const baseURL = 'https://montajati-official-backend-production.up.railway.app';
  
  try {
    // 1. إنشاء طلب جديد (كما تفعل أنت)
    console.log('1️⃣ === إنشاء طلب جديد (كما تفعل أنت) ===');
    
    const newOrderData = {
      customer_name: 'اختبار التدفق الدقيق',
      primary_phone: '07901234567',
      customer_address: 'بغداد - الكرخ - اختبار التدفق الدقيق',
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
      order_number: `ORD-USER-${Date.now()}`,
      notes: 'اختبار التدفق الدقيق للمستخدم'
    };
    
    const createResponse = await axios.post(`${baseURL}/api/orders`, newOrderData, {
      headers: {
        'Content-Type': 'application/json'
      },
      timeout: 30000
    });
    
    if (!createResponse.data.success) {
      console.log('❌ فشل في إنشاء الطلب');
      return;
    }
    
    const orderId = createResponse.data.data.id;
    console.log(`✅ تم إنشاء الطلب: ${orderId}`);
    
    // 2. اختبار جميع الطرق المحتملة لتحديث الحالة
    console.log('\n2️⃣ === اختبار جميع الطرق المحتملة لتحديث الحالة ===');
    
    const possibleStatuses = [
      // الطرق المحتملة التي قد يرسلها التطبيق
      'in_delivery',                                           // القيمة الإنجليزية
      '3',                                                     // الرقم
      'قيد التوصيل الى الزبون (في عهدة المندوب)',              // النص العربي الكامل
      'قيد التوصيل',                                          // النص المختصر
      'shipping',                                              // قيمة أخرى محتملة
      'shipped'                                                // قيمة أخرى محتملة
    ];
    
    for (const [index, status] of possibleStatuses.entries()) {
      console.log(`\n🧪 اختبار ${index + 1}: "${status}"`);
      
      // إنشاء طلب جديد لكل اختبار
      const testOrderData = {
        ...newOrderData,
        order_number: `ORD-TEST-${index + 1}-${Date.now()}`,
        notes: `اختبار الحالة: ${status}`
      };
      
      const testCreateResponse = await axios.post(`${baseURL}/api/orders`, testOrderData, {
        headers: {
          'Content-Type': 'application/json'
        },
        timeout: 30000
      });
      
      if (testCreateResponse.data.success) {
        const testOrderId = testCreateResponse.data.data.id;
        console.log(`   📦 طلب الاختبار: ${testOrderId}`);
        
        // تحديث الحالة
        const updateData = {
          status: status,
          notes: `اختبار الحالة: ${status}`,
          changedBy: 'exact_user_flow_test'
        };
        
        console.log(`   📤 إرسال تحديث الحالة: "${status}"`);
        
        try {
          const updateResponse = await axios.put(
            `${baseURL}/api/orders/${testOrderId}/status`,
            updateData,
            {
              headers: {
                'Content-Type': 'application/json'
              },
              timeout: 60000
            }
          );
          
          console.log(`   📥 نتيجة التحديث:`);
          console.log(`      Status: ${updateResponse.status}`);
          console.log(`      Success: ${updateResponse.data.success}`);
          console.log(`      Message: ${updateResponse.data.message}`);
          
          if (updateResponse.data.success) {
            console.log(`   ✅ تم تحديث الحالة بنجاح`);
            
            // انتظار قصير ثم فحص النتيجة
            await new Promise(resolve => setTimeout(resolve, 10000));
            
            const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
            const updatedOrder = ordersResponse.data.data.find(o => o.id === testOrderId);
            
            if (updatedOrder) {
              console.log(`   📋 النتيجة:`);
              console.log(`      📊 الحالة في قاعدة البيانات: ${updatedOrder.status}`);
              console.log(`      🆔 معرف الوسيط: ${updatedOrder.waseet_order_id || 'غير محدد'}`);
              console.log(`      📦 حالة الوسيط: ${updatedOrder.waseet_status || 'غير محدد'}`);
              
              if (updatedOrder.waseet_order_id && updatedOrder.waseet_order_id !== 'null') {
                console.log(`   🎉 نجح! تم إرسال الطلب للوسيط - QR ID: ${updatedOrder.waseet_order_id}`);
              } else {
                console.log(`   ❌ لم يتم إرسال الطلب للوسيط`);
                
                if (updatedOrder.waseet_data) {
                  try {
                    const waseetData = JSON.parse(updatedOrder.waseet_data);
                    if (waseetData.error) {
                      console.log(`      🔍 سبب الفشل: ${waseetData.error}`);
                    }
                  } catch (e) {
                    // تجاهل أخطاء التحليل
                  }
                }
              }
            }
          } else {
            console.log(`   ❌ فشل في تحديث الحالة: ${updateResponse.data.error}`);
          }
          
        } catch (error) {
          console.log(`   ❌ خطأ في تحديث الحالة: ${error.message}`);
        }
      }
    }
    
    // 3. اختبار محاكاة دقيقة لما يحدث في التطبيق
    console.log('\n3️⃣ === محاكاة دقيقة لما يحدث في التطبيق ===');
    
    // محاكاة دالة التحويل من التطبيق
    function convertStatusToDatabase(status) {
      console.log(`🔄 تحويل الحالة: "${status}"`);
      
      // أولاً: التعامل مع القيم الإنجليزية من dropdown
      if (status === 'in_delivery') {
        console.log('   ✅ تم التعرف على "in_delivery" - تحويل إلى النص العربي');
        return 'قيد التوصيل الى الزبون (في عهدة المندوب)';
      }
      
      if (status === 'delivered') {
        console.log('   ✅ تم التعرف على "delivered" - تحويل إلى النص العربي');
        return 'تم التسليم للزبون';
      }
      
      if (status === 'cancelled') {
        console.log('   ✅ تم التعرف على "cancelled" - تحويل إلى النص العربي');
        return 'مغلق';
      }
      
      // ثانياً: التعامل مع الأرقام (للتوافق مع النظام القديم)
      switch (status) {
        case '3':
          console.log('   ✅ تم التعرف على "3" - تحويل إلى النص العربي');
          return 'قيد التوصيل الى الزبون (في عهدة المندوب)';
        case '4':
          console.log('   ✅ تم التعرف على "4" - تحويل إلى النص العربي');
          return 'تم التسليم للزبون';
        case '27':
          console.log('   ✅ تم التعرف على "27" - تحويل إلى النص العربي');
          return 'مغلق';
        default:
          console.log(`   ⚠️ حالة غير معروفة: "${status}" - إرجاع كما هي`);
          return status;
      }
    }
    
    // اختبار دالة التحويل
    console.log('\n🧪 اختبار دالة التحويل:');
    const testStatuses = ['in_delivery', '3', 'delivered', '4', 'cancelled', '27', 'unknown'];
    
    testStatuses.forEach(status => {
      const converted = convertStatusToDatabase(status);
      console.log(`   "${status}" → "${converted}"`);
    });
    
    // 4. اختبار مع الحالة المحولة
    console.log('\n4️⃣ === اختبار مع الحالة المحولة ===');
    
    // إنشاء طلب نهائي للاختبار
    const finalTestOrderData = {
      ...newOrderData,
      order_number: `ORD-FINAL-${Date.now()}`,
      notes: 'اختبار نهائي مع الحالة المحولة'
    };
    
    const finalCreateResponse = await axios.post(`${baseURL}/api/orders`, finalTestOrderData, {
      headers: {
        'Content-Type': 'application/json'
      },
      timeout: 30000
    });
    
    if (finalCreateResponse.data.success) {
      const finalOrderId = finalCreateResponse.data.data.id;
      console.log(`📦 الطلب النهائي: ${finalOrderId}`);
      
      // محاكاة ما يحدث في التطبيق بالضبط
      const userSelectedStatus = 'in_delivery'; // ما يختاره المستخدم
      const convertedStatus = convertStatusToDatabase(userSelectedStatus); // ما يتم تحويله
      
      console.log(`👤 المستخدم اختار: "${userSelectedStatus}"`);
      console.log(`🔄 التطبيق حول إلى: "${convertedStatus}"`);
      
      const finalUpdateData = {
        status: convertedStatus,
        notes: 'اختبار نهائي - محاكاة التطبيق',
        changedBy: 'app_simulation'
      };
      
      console.log(`📤 إرسال للخادم: "${convertedStatus}"`);
      
      const finalUpdateResponse = await axios.put(
        `${baseURL}/api/orders/${finalOrderId}/status`,
        finalUpdateData,
        {
          headers: {
            'Content-Type': 'application/json'
          },
          timeout: 60000
        }
      );
      
      console.log(`📥 استجابة الخادم:`);
      console.log(`   Status: ${finalUpdateResponse.status}`);
      console.log(`   Success: ${finalUpdateResponse.data.success}`);
      console.log(`   Message: ${finalUpdateResponse.data.message}`);
      
      if (finalUpdateResponse.data.success) {
        console.log(`✅ تم تحديث الحالة بنجاح`);
        
        // مراقبة النتيجة
        console.log('\n👀 مراقبة النتيجة...');
        
        for (let i = 0; i < 6; i++) {
          await new Promise(resolve => setTimeout(resolve, 10000));
          
          const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
          const finalOrder = ordersResponse.data.data.find(o => o.id === finalOrderId);
          
          if (finalOrder) {
            console.log(`📋 فحص ${i + 1}:`);
            console.log(`   📊 الحالة: ${finalOrder.status}`);
            console.log(`   🆔 معرف الوسيط: ${finalOrder.waseet_order_id || 'غير محدد'}`);
            console.log(`   📦 حالة الوسيط: ${finalOrder.waseet_status || 'غير محدد'}`);
            
            if (finalOrder.waseet_order_id && finalOrder.waseet_order_id !== 'null') {
              console.log(`🎉 نجح! تم إرسال الطلب للوسيط - QR ID: ${finalOrder.waseet_order_id}`);
              break;
            }
          }
        }
      }
    }
    
  } catch (error) {
    console.error('❌ خطأ في اختبار التدفق الدقيق:', error.message);
  }
}

testExactUserFlow();
