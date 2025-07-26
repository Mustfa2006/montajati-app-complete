const axios = require('axios');

async function testRenderUpdates() {
  console.log('🚀 === اختبار التحديثات على Render ===\n');
  console.log('🎯 اختبار جميع الحالات بعد رفع التغييرات\n');

  const baseURL = 'https://montajati-backend.onrender.com';
  
  const allStatuses = [
    // الحالات التي كانت تسبب مشكلة - يجب أن تعمل الآن
    { status: '3', description: 'الرقم 3 (يجب أن يتحول إلى in_delivery)' },
    { status: 'قيد التوصيل', description: 'النص المختصر (يجب أن يتحول إلى in_delivery)' },
    { status: 'shipping', description: 'الحالة الإنجليزية shipping (يجب أن تتحول إلى in_delivery)' },
    { status: 'shipped', description: 'الحالة الإنجليزية shipped (يجب أن تتحول إلى in_delivery)' },
    
    // الحالات التي تعمل (للتأكد)
    { status: 'in_delivery', description: 'الحالة الإنجليزية in_delivery (تبقى كما هي)' },
    { status: 'قيد التوصيل الى الزبون (في عهدة المندوب)', description: 'النص العربي الكامل (يبقى كما هو)' }
  ];
  
  let successCount = 0;
  let failCount = 0;
  let waseetSuccessCount = 0;
  
  try {
    console.log('⏰ انتظار 30 ثانية للتأكد من اكتمال النشر على Render...\n');
    await new Promise(resolve => setTimeout(resolve, 30000));
    
    for (const [index, statusTest] of allStatuses.entries()) {
      console.log(`\n🧪 اختبار ${index + 1}: ${statusTest.description}`);
      console.log(`   📝 الحالة: "${statusTest.status}"`);
      
      // إنشاء طلب جديد لكل اختبار
      const newOrderData = {
        customer_name: `اختبار Render ${index + 1}`,
        primary_phone: '07901234567',
        customer_address: 'بغداد - الكرخ - اختبار Render',
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
        order_number: `ORD-RENDER-${index + 1}-${Date.now()}`,
        notes: `اختبار Render: ${statusTest.description}`
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
          notes: `اختبار Render: ${statusTest.description}`,
          changedBy: 'render_test'
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
              console.log(`      🆔 معرف الوسيط: ${updatedOrder.waseet_order_id || 'غير محدد'}`);
              console.log(`      📦 حالة الوسيط: ${updatedOrder.waseet_status || 'غير محدد'}`);
              
              if (updatedOrder.waseet_order_id && updatedOrder.waseet_order_id !== 'null') {
                console.log(`   🎉 مثالي! تم إرسال الطلب للوسيط - QR ID: ${updatedOrder.waseet_order_id}`);
                waseetSuccessCount++;
                
                // فحص رابط الوسيط
                if (updatedOrder.waseet_data) {
                  try {
                    const waseetData = JSON.parse(updatedOrder.waseet_data);
                    if (waseetData.waseetResponse && waseetData.waseetResponse.data && waseetData.waseetResponse.data.qr_link) {
                      console.log(`   🔗 رابط الوسيط: ${waseetData.waseetResponse.data.qr_link}`);
                    }
                  } catch (e) {
                    // تجاهل أخطاء التحليل
                  }
                }
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
            console.log(`   ❌ لا يزال يعطي خطأ 500`);
            console.log(`      📋 تفاصيل الخطأ:`, error.response.data);
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
    
    const successRate = (successCount / allStatuses.length) * 100;
    const waseetRate = (waseetSuccessCount / allStatuses.length) * 100;
    
    console.log(`📈 معدل نجاح تحديث الحالة: ${successRate.toFixed(1)}%`);
    console.log(`📈 معدل نجاح إرسال الوسيط: ${waseetRate.toFixed(1)}%`);
    
    if (successCount === allStatuses.length) {
      console.log('\n🎉 === الإصلاح نجح بالكامل! ===');
      console.log('✅ جميع الحالات تعمل الآن بدون خطأ 500');
      console.log('✅ يمكنك الآن استخدام أي حالة في التطبيق');
      
      if (waseetSuccessCount === allStatuses.length) {
        console.log('✅ جميع الطلبات تم إرسالها للوسيط بنجاح');
        console.log('🎯 المشكلة محلولة 100%!');
        
        console.log('\n🎊 === تهانينا! ===');
        console.log('🎉 تم حل المشكلة بالكامل!');
        console.log('📱 يمكنك الآن استخدام التطبيق بشكل طبيعي');
        console.log('🔄 عند تغيير حالة الطلب إلى "قيد التوصيل":');
        console.log('   ✅ ستظهر معرف الوسيط');
        console.log('   ✅ يمكنك فتح رابط الوسيط');
        console.log('   ✅ ستتمكن من طباعة تفاصيل الطلب');
        
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
    
    console.log('\n🎯 === التوصية النهائية ===');
    if (successCount >= 5) {
      console.log('🎉 يمكنك الآن استخدام التطبيق!');
      console.log('');
      console.log('📱 في التطبيق:');
      console.log('   1. أنشئ طلب جديد');
      console.log('   2. غير حالته إلى "قيد التوصيل"');
      console.log('   3. ستظهر معرف الوسيط تلقائياً');
      console.log('   4. اضغط على زر فتح رابط الوسيط');
      console.log('');
      console.log('✅ المشكلة محلولة!');
    } else {
      console.log('⚠️ لا تزال هناك مشاكل - انتظر قليلاً وأعد المحاولة');
    }
    
  } catch (error) {
    console.error('❌ خطأ في اختبار تحديثات Render:', error.message);
  }
}

testRenderUpdates();
