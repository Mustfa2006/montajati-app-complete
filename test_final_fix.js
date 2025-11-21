const axios = require('axios');

async function testFinalFix() {
  console.log('🎯 === اختبار الإصلاح النهائي ===\n');
  console.log('🔧 اختبار جميع الحالات التي كانت تسبب خطأ 500\n');

  const baseURL = 'https://montajati-official-backend-production.up.railway.app';
  
  const allStatuses = [
    // الحالات التي كانت تسبب مشكلة
    { status: '3', description: 'الرقم 3' },
    { status: 'قيد التوصيل', description: 'النص المختصر' },
    { status: 'shipping', description: 'الحالة الإنجليزية shipping' },
    { status: 'shipped', description: 'الحالة الإنجليزية shipped' },
    
    // الحالات التي تعمل (للتأكد)
    { status: 'in_delivery', description: 'الحالة الإنجليزية in_delivery' },
    { status: 'قيد التوصيل الى الزبون (في عهدة المندوب)', description: 'النص العربي الكامل' }
  ];
  
  let successCount = 0;
  let failCount = 0;
  
  try {
    for (const [index, statusTest] of allStatuses.entries()) {
      console.log(`\n🧪 اختبار ${index + 1}: ${statusTest.description}`);
      console.log(`   📝 الحالة: "${statusTest.status}"`);
      
      // إنشاء طلب جديد لكل اختبار
      const newOrderData = {
        customer_name: `اختبار الإصلاح النهائي ${index + 1}`,
        primary_phone: '07901234567',
        customer_address: 'بغداد - الكرخ - اختبار الإصلاح النهائي',
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
        order_number: `ORD-FINALFIX-${index + 1}-${Date.now()}`,
        notes: `اختبار الإصلاح النهائي: ${statusTest.description}`
      };
      
      const createResponse = await axios.post(`${baseURL}/api/orders`, newOrderData, {
        headers: {
          'Content-Type': 'application/json'
        },
        timeout: 30000
      });
      
      if (createResponse.data.success) {
        const orderId = createResponse.data.data.id;
        console.log(`   📦 طلب الاختبار: ${orderId}`);
        
        // تحديث الحالة
        const updateData = {
          status: statusTest.status,
          notes: `اختبار الإصلاح النهائي: ${statusTest.description}`,
          changedBy: 'final_fix_test'
        };
        
        console.log(`   📤 إرسال تحديث الحالة...`);
        
        try {
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
          
          console.log(`   📥 نتيجة التحديث:`);
          console.log(`      Status: ${updateResponse.status}`);
          console.log(`      Success: ${updateResponse.data.success}`);
          console.log(`      Message: ${updateResponse.data.message}`);
          
          if (updateResponse.data.success) {
            console.log(`   ✅ نجح تحديث الحالة!`);
            successCount++;
            
            // انتظار قصير ثم فحص النتيجة
            await new Promise(resolve => setTimeout(resolve, 10000));
            
            const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
            const updatedOrder = ordersResponse.data.data.find(o => o.id === orderId);
            
            if (updatedOrder) {
              console.log(`   📋 النتيجة النهائية:`);
              console.log(`      📊 الحالة في قاعدة البيانات: ${updatedOrder.status}`);
              console.log(`      🆔 معرف الوسيط: ${updatedOrder.waseet_order_id || 'غير محدد'}`);
              console.log(`      📦 حالة الوسيط: ${updatedOrder.waseet_status || 'غير محدد'}`);
              
              if (updatedOrder.waseet_order_id && updatedOrder.waseet_order_id !== 'null') {
                console.log(`   🎉 مثالي! تم إرسال الطلب للوسيط - QR ID: ${updatedOrder.waseet_order_id}`);
              } else {
                console.log(`   ⚠️ تم تحديث الحالة لكن لم يتم إرسال الطلب للوسيط`);
                
                // فحص سبب عدم الإرسال
                if (updatedOrder.status === 'قيد التوصيل الى الزبون (في عهدة المندوب)') {
                  console.log(`   🔍 الحالة صحيحة لكن لم يتم الإرسال - قد تكون مشكلة في خدمة الوسيط`);
                } else {
                  console.log(`   🔍 الحالة لم تتحول بشكل صحيح`);
                }
              }
            }
          } else {
            console.log(`   ❌ فشل في تحديث الحالة: ${updateResponse.data.error}`);
            failCount++;
          }
          
        } catch (error) {
          if (error.response && error.response.status === 500) {
            console.log(`   ❌ لا يزال يعطي خطأ 500 - الإصلاح لم ينجح كاملاً`);
            failCount++;
          } else {
            console.log(`   ❌ خطأ آخر: ${error.message}`);
            failCount++;
          }
        }
      } else {
        console.log(`   ❌ فشل في إنشاء طلب الاختبار`);
        failCount++;
      }
    }
    
    console.log('\n📊 === النتائج النهائية ===');
    console.log(`✅ نجح: ${successCount} من ${allStatuses.length}`);
    console.log(`❌ فشل: ${failCount} من ${allStatuses.length}`);
    
    if (successCount === allStatuses.length) {
      console.log('\n🎉 === الإصلاح نجح بالكامل! ===');
      console.log('✅ جميع الحالات تعمل الآن بدون خطأ 500');
      console.log('✅ يمكنك الآن استخدام أي حالة في التطبيق');
      console.log('✅ النظام سيحول الحالات تلقائياً ويرسل للوسيط');
    } else if (successCount > failCount) {
      console.log('\n🔧 === الإصلاح نجح جزئياً ===');
      console.log('✅ معظم الحالات تعمل الآن');
      console.log('⚠️ قد تحتاج لمزيد من التحسينات');
    } else {
      console.log('\n❌ === الإصلاح لم ينجح ===');
      console.log('❌ لا تزال هناك مشاكل في النظام');
      console.log('🔍 تحتاج لمزيد من التشخيص');
    }
    
    console.log('\n🎯 === التوصية النهائية ===');
    if (successCount >= 4) {
      console.log('✅ النظام يعمل! يمكنك الآن:');
      console.log('   1. استخدام التطبيق بشكل طبيعي');
      console.log('   2. تغيير حالة الطلبات إلى "قيد التوصيل"');
      console.log('   3. ستظهر معرفات الوسيط في التطبيق');
      console.log('   4. يمكنك فتح روابط الوسيط مباشرة');
    } else {
      console.log('⚠️ لا تزال هناك مشاكل - تحتاج لمزيد من الإصلاحات');
    }
    
  } catch (error) {
    console.error('❌ خطأ في اختبار الإصلاح النهائي:', error.message);
  }
}

testFinalFix();
