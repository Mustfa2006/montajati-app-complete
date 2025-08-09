const axios = require('axios');

async function debugDatabaseConstraint() {
  console.log('🔍 === تشخيص قيود قاعدة البيانات ===\n');
  console.log('🎯 معرفة الحالات المسموحة في قاعدة البيانات\n');

  const baseURL = 'https://montajati-backend.onrender.com';
  
  try {
    // إنشاء طلب جديد
    const newOrderData = {
      customer_name: 'تشخيص قيود قاعدة البيانات',
      primary_phone: '07901234567',
      customer_address: 'بغداد - الكرخ - تشخيص قيود قاعدة البيانات',
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
      order_number: `ORD-DBCONSTRAINT-${Date.now()}`,
      notes: 'تشخيص قيود قاعدة البيانات'
    };
    
    const createResponse = await axios.post(`${baseURL}/api/orders`, newOrderData, {
      headers: {
        'Content-Type': 'application/json'
      },
      timeout: 30000
    });
    
    if (createResponse.data.success) {
      const orderId = createResponse.data.data.id;
      console.log(`📦 طلب التشخيص: ${orderId}`);
      
      // اختبار الحالات المحولة مباشرة
      const statusesToTest = [
        'قيد التوصيل الى الزبون (في عهدة المندوب)', // المحولة من "3"
        'تم التسليم للزبون',                        // المحولة من "4"
        'مغلق',                                     // المحولة من "27"
        'active',                                   // حالة أساسية
        'pending',                                  // حالة أساسية
        'confirmed',                                // حالة أساسية
        'in_delivery',                              // حالة إنجليزية
        'delivered',                                // حالة إنجليزية
        'cancelled'                                 // حالة إنجليزية
      ];
      
      for (const [index, status] of statusesToTest.entries()) {
        console.log(`\n🧪 اختبار ${index + 1}: "${status}"`);
        
        try {
          const updateResponse = await axios.put(
            `${baseURL}/api/orders/${orderId}/status`,
            {
              status: status,
              notes: `اختبار قيود قاعدة البيانات: ${status}`,
              changedBy: 'db_constraint_test'
            },
            {
              headers: {
                'Content-Type': 'application/json'
              },
              timeout: 30000,
              validateStatus: () => true
            }
          );
          
          if (updateResponse.status === 200 && updateResponse.data.success) {
            console.log(`   ✅ نجح - الحالة "${status}" مقبولة في قاعدة البيانات`);
          } else if (updateResponse.status === 500) {
            console.log(`   ❌ فشل - الحالة "${status}" مرفوضة من قاعدة البيانات`);
            
            if (updateResponse.data && updateResponse.data.error) {
              console.log(`      🔍 رسالة الخطأ: ${updateResponse.data.error}`);
            }
          } else {
            console.log(`   ⚠️ استجابة غير متوقعة - Status: ${updateResponse.status}`);
          }
          
        } catch (error) {
          console.log(`   ❌ خطأ في الطلب: ${error.message}`);
        }
        
        // انتظار قصير بين الاختبارات
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
      
      // فحص الحالات الموجودة فعلاً في قاعدة البيانات
      console.log('\n📋 === فحص الحالات الموجودة في قاعدة البيانات ===');
      
      try {
        const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
        const allOrders = ordersResponse.data.data;
        
        // جمع جميع الحالات الفريدة
        const uniqueStatuses = [...new Set(allOrders.map(order => order.status))];
        
        console.log(`📊 الحالات الموجودة فعلاً في قاعدة البيانات (${uniqueStatuses.length} حالة):`);
        uniqueStatuses.forEach((status, index) => {
          console.log(`   ${index + 1}. "${status}"`);
        });
        
        console.log('\n🔍 === تحليل النتائج ===');
        
        const arabicStatuses = uniqueStatuses.filter(status => /[\u0600-\u06FF]/.test(status));
        const englishStatuses = uniqueStatuses.filter(status => /^[a-zA-Z_]+$/.test(status));
        
        console.log(`📝 حالات عربية: ${arabicStatuses.length}`);
        arabicStatuses.forEach(status => console.log(`   - "${status}"`));
        
        console.log(`📝 حالات إنجليزية: ${englishStatuses.length}`);
        englishStatuses.forEach(status => console.log(`   - "${status}"`));
        
        console.log('\n💡 === التوصيات ===');
        
        if (uniqueStatuses.includes('قيد التوصيل الى الزبون (في عهدة المندوب)')) {
          console.log('✅ الحالة العربية الطويلة موجودة - يجب أن تعمل');
        } else {
          console.log('❌ الحالة العربية الطويلة غير موجودة - هذا قد يكون سبب المشكلة');
        }
        
        if (uniqueStatuses.includes('in_delivery')) {
          console.log('✅ الحالة الإنجليزية in_delivery موجودة - يجب أن تعمل');
        } else {
          console.log('❌ الحالة الإنجليزية in_delivery غير موجودة');
        }
        
      } catch (error) {
        console.log(`❌ خطأ في فحص الطلبات الموجودة: ${error.message}`);
      }
      
    } else {
      console.log('❌ فشل في إنشاء طلب التشخيص');
    }
    
  } catch (error) {
    console.error('❌ خطأ في تشخيص قيود قاعدة البيانات:', error.message);
  }
}

debugDatabaseConstraint();
