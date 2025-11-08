const axios = require('axios');

async function testFix() {
  console.log('🔧 === اختبار الإصلاح ===\n');
  console.log('🎯 اختبار جميع الحالات التي كانت تسبب خطأ 500\n');

  const baseURL = 'https://montajati-official-backend-production.up.railway.app';
  
  const problematicStatuses = [
    '3',                    // الرقم الذي يسبب مشكلة
    'قيد التوصيل',         // النص المختصر
    'shipping',             // الحالة الإنجليزية
    'shipped'               // الحالة الإنجليزية
  ];
  
  try {
    for (const [index, status] of problematicStatuses.entries()) {
      console.log(`\n🧪 اختبار ${index + 1}: "${status}"`);
      
      // إنشاء طلب جديد
      const newOrderData = {
        customer_name: `اختبار الإصلاح ${index + 1}`,
        primary_phone: '07901234567',
        customer_address: 'بغداد - الكرخ - اختبار الإصلاح',
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
        order_number: `ORD-FIX-${index + 1}-${Date.now()}`,
        notes: `اختبار إصلاح الحالة: ${status}`
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
          status: status,
          notes: `اختبار إصلاح الحالة: ${status}`,
          changedBy: 'fix_test'
        };
        
        console.log(`   📤 إرسال تحديث الحالة: "${status}"`);
        
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
            console.log(`   ✅ تم تحديث الحالة بنجاح - الإصلاح يعمل!`);
            
            // انتظار قصير ثم فحص النتيجة
            await new Promise(resolve => setTimeout(resolve, 15000));
            
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
              }
            }
          } else {
            console.log(`   ❌ فشل في تحديث الحالة: ${updateResponse.data.error}`);
          }
          
        } catch (error) {
          if (error.response && error.response.status === 500) {
            console.log(`   ❌ لا يزال يعطي خطأ 500 - الإصلاح لم ينجح`);
          } else {
            console.log(`   ❌ خطأ آخر: ${error.message}`);
          }
        }
      } else {
        console.log(`   ❌ فشل في إنشاء طلب الاختبار`);
      }
    }
    
    console.log('\n📊 === خلاصة الاختبار ===');
    console.log('إذا رأيت "✅ تم تحديث الحالة بنجاح" لجميع الحالات، فالإصلاح نجح!');
    console.log('إذا رأيت "❌ لا يزال يعطي خطأ 500"، فهناك مشكلة أخرى.');
    
  } catch (error) {
    console.error('❌ خطأ في اختبار الإصلاح:', error.message);
  }
}

testFix();
