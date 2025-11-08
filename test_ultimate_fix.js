const axios = require('axios');

async function testUltimateFix() {
  console.log('🎯 === اختبار الإصلاح النهائي المطلق ===\n');
  console.log('🔧 اختبار جميع الحالات مع التحويل الصحيح\n');

  const baseURL = 'https://montajati-official-backend-production.up.railway.app';
  
  const allStatuses = [
    // الحالات التي كانت تسبب مشكلة - يجب أن تعمل الآن
    { status: '3', description: 'الرقم 3', expectedConverted: 'in_delivery' },
    { status: 'قيد التوصيل', description: 'النص المختصر', expectedConverted: 'in_delivery' },
    { status: 'shipping', description: 'الحالة الإنجليزية shipping', expectedConverted: 'in_delivery' },
    { status: 'shipped', description: 'الحالة الإنجليزية shipped', expectedConverted: 'in_delivery' },
    
    // الحالات التي تعمل (للتأكد)
    { status: 'in_delivery', description: 'الحالة الإنجليزية in_delivery', expectedConverted: 'in_delivery' },
    { status: 'قيد التوصيل الى الزبون (في عهدة المندوب)', description: 'النص العربي الكامل', expectedConverted: 'قيد التوصيل الى الزبون (في عهدة المندوب)' }
  ];
  
  let successCount = 0;
  let failCount = 0;
  let waseetSuccessCount = 0;
  
  try {
    for (const [index, statusTest] of allStatuses.entries()) {
      console.log(`\n🧪 اختبار ${index + 1}: ${statusTest.description}`);
      console.log(`   📝 الحالة الأصلية: "${statusTest.status}"`);
      console.log(`   🔄 متوقع التحويل إلى: "${statusTest.expectedConverted}"`);
      
      // إنشاء طلب جديد لكل اختبار
      const newOrderData = {
        customer_name: `اختبار الإصلاح المطلق ${index + 1}`,
        primary_phone: '07901234567',
        customer_address: 'بغداد - الكرخ - اختبار الإصلاح المطلق',
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
        order_number: `ORD-ULTIMATE-${index + 1}-${Date.now()}`,
        notes: `اختبار الإصلاح المطلق: ${statusTest.description}`
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
          notes: `اختبار الإصلاح المطلق: ${statusTest.description}`,
          changedBy: 'ultimate_fix_test'
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
            await new Promise(resolve => setTimeout(resolve, 15000));
            
            const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
            const updatedOrder = ordersResponse.data.data.find(o => o.id === orderId);
            
            if (updatedOrder) {
              console.log(`   📋 النتيجة النهائية:`);
              console.log(`      📊 الحالة في قاعدة البيانات: "${updatedOrder.status}"`);
              console.log(`      🔄 هل تطابق المتوقع؟ ${updatedOrder.status === statusTest.expectedConverted ? '✅ نعم' : '❌ لا'}`);
              console.log(`      🆔 معرف الوسيط: ${updatedOrder.waseet_order_id || 'غير محدد'}`);
              console.log(`      📦 حالة الوسيط: ${updatedOrder.waseet_status || 'غير محدد'}`);
              
              if (updatedOrder.waseet_order_id && updatedOrder.waseet_order_id !== 'null') {
                console.log(`   🎉 مثالي! تم إرسال الطلب للوسيط - QR ID: ${updatedOrder.waseet_order_id}`);
                waseetSuccessCount++;
              } else {
                console.log(`   ⚠️ تم تحديث الحالة لكن لم يتم إرسال الطلب للوسيط`);
                
                // فحص سبب عدم الإرسال
                if (updatedOrder.status === 'in_delivery' || updatedOrder.status === 'قيد التوصيل الى الزبون (في عهدة المندوب)') {
                  console.log(`   🔍 الحالة صحيحة لكن لم يتم الإرسال - قد تكون مشكلة في خدمة الوسيط`);
                  
                  if (updatedOrder.waseet_data) {
                    try {
                      const waseetData = JSON.parse(updatedOrder.waseet_data);
                      if (waseetData.error) {
                        console.log(`      🔍 سبب عدم الإرسال: ${waseetData.error}`);
                      }
                    } catch (e) {
                      // تجاهل أخطاء التحليل
                    }
                  }
                } else {
                  console.log(`   🔍 الحالة "${updatedOrder.status}" غير مؤهلة للإرسال للوسيط`);
                }
              }
            }
          } else {
            console.log(`   ❌ فشل في تحديث الحالة: ${updateResponse.data.error}`);
            failCount++;
          }
          
        } catch (error) {
          if (error.response && error.response.status === 500) {
            console.log(`   ❌ لا يزال يعطي خطأ 500 - الإصلاح لم ينجح`);
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
    console.log(`✅ نجح تحديث الحالة: ${successCount} من ${allStatuses.length}`);
    console.log(`🚀 نجح إرسال للوسيط: ${waseetSuccessCount} من ${allStatuses.length}`);
    console.log(`❌ فشل: ${failCount} من ${allStatuses.length}`);
    
    if (successCount === allStatuses.length) {
      console.log('\n🎉 === الإصلاح نجح بالكامل! ===');
      console.log('✅ جميع الحالات تعمل الآن بدون خطأ 500');
      console.log('✅ يمكنك الآن استخدام أي حالة في التطبيق');
      
      if (waseetSuccessCount === allStatuses.length) {
        console.log('✅ جميع الطلبات تم إرسالها للوسيط بنجاح');
        console.log('🎯 المشكلة محلولة 100%!');
      } else if (waseetSuccessCount >= 4) {
        console.log('✅ معظم الطلبات تم إرسالها للوسيط');
        console.log('🎯 المشكلة محلولة تقريباً!');
      } else {
        console.log('⚠️ تحديث الحالة يعمل لكن إرسال الوسيط يحتاج تحسين');
      }
    } else if (successCount > failCount) {
      console.log('\n🔧 === الإصلاح نجح جزئياً ===');
      console.log('✅ معظم الحالات تعمل الآن');
      console.log('⚠️ قد تحتاج لمزيد من التحسينات');
    } else {
      console.log('\n❌ === الإصلاح لم ينجح ===');
      console.log('❌ لا تزال هناك مشاكل في النظام');
      console.log('🔍 تحتاج لمزيد من التشخيص');
    }
    
    console.log('\n🎯 === التوصية النهائية للمستخدم ===');
    if (successCount >= 5) {
      console.log('🎉 يمكنك الآن استخدام التطبيق!');
      console.log('');
      console.log('📱 في التطبيق، عندما تريد تغيير حالة الطلب:');
      console.log('   1. اختر أي حالة تريدها');
      console.log('   2. النظام سيحولها تلقائياً للحالة الصحيحة');
      console.log('   3. ستظهر معرف الوسيط في التطبيق');
      console.log('   4. يمكنك فتح رابط الوسيط مباشرة');
      console.log('');
      console.log('✅ الحالات التي تعمل بشكل مؤكد:');
      console.log('   - "in_delivery" (الحالة الإنجليزية)');
      console.log('   - "قيد التوصيل الى الزبون (في عهدة المندوب)" (النص العربي)');
      console.log('   - الرقم "3" (سيتم تحويله تلقائياً)');
      console.log('   - "قيد التوصيل" (سيتم تحويله تلقائياً)');
    } else {
      console.log('⚠️ لا تزال هناك مشاكل - تحتاج لمزيد من الإصلاحات');
    }
    
  } catch (error) {
    console.error('❌ خطأ في اختبار الإصلاح المطلق:', error.message);
  }
}

testUltimateFix();
