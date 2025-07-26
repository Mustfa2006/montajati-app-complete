const axios = require('axios');

async function debug500Error() {
  console.log('🔍 === تشخيص خطأ 500 ===\n');
  console.log('🎯 معرفة سبب خطأ 500 عند تحديث الحالة\n');

  const baseURL = 'https://montajati-backend.onrender.com';
  
  try {
    // إنشاء طلب جديد
    const newOrderData = {
      customer_name: 'تشخيص خطأ 500',
      primary_phone: '07901234567',
      customer_address: 'بغداد - الكرخ - تشخيص خطأ 500',
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
      order_number: `ORD-DEBUG500-${Date.now()}`,
      notes: 'تشخيص خطأ 500'
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
      
      // محاولة تحديث الحالة مع تفاصيل الخطأ
      const updateData = {
        status: '3',
        notes: 'تشخيص خطأ 500',
        changedBy: 'debug_500'
      };
      
      console.log('📤 إرسال تحديث الحالة مع تفاصيل الخطأ...');
      
      try {
        const updateResponse = await axios.put(
          `${baseURL}/api/orders/${orderId}/status`,
          updateData,
          {
            headers: {
              'Content-Type': 'application/json'
            },
            timeout: 60000,
            validateStatus: () => true // قبول جميع status codes
          }
        );
        
        console.log(`📥 تفاصيل الاستجابة:`);
        console.log(`   Status Code: ${updateResponse.status}`);
        console.log(`   Headers:`, updateResponse.headers);
        console.log(`   Data:`, updateResponse.data);
        
        if (updateResponse.status === 500) {
          console.log('\n🔍 === تحليل خطأ 500 ===');
          
          if (updateResponse.data && updateResponse.data.error) {
            console.log(`❌ رسالة الخطأ: ${updateResponse.data.error}`);
          }
          
          if (updateResponse.data && updateResponse.data.details) {
            console.log(`📋 تفاصيل الخطأ:`, updateResponse.data.details);
          }
          
          if (updateResponse.data && updateResponse.data.stack) {
            console.log(`📚 Stack trace:`, updateResponse.data.stack);
          }
        }
        
      } catch (error) {
        console.log(`❌ خطأ في الطلب: ${error.message}`);
        
        if (error.response) {
          console.log(`📋 Response Status: ${error.response.status}`);
          console.log(`📋 Response Data:`, error.response.data);
        }
      }
      
      // اختبار مع حالة تعمل للمقارنة
      console.log('\n🔄 === اختبار مع حالة تعمل للمقارنة ===');
      
      const workingUpdateData = {
        status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
        notes: 'اختبار حالة تعمل',
        changedBy: 'debug_500_working'
      };
      
      try {
        const workingUpdateResponse = await axios.put(
          `${baseURL}/api/orders/${orderId}/status`,
          workingUpdateData,
          {
            headers: {
              'Content-Type': 'application/json'
            },
            timeout: 60000
          }
        );
        
        console.log(`✅ الحالة التي تعمل:`);
        console.log(`   Status: ${workingUpdateResponse.status}`);
        console.log(`   Success: ${workingUpdateResponse.data.success}`);
        console.log(`   Message: ${workingUpdateResponse.data.message}`);
        
      } catch (error) {
        console.log(`❌ حتى الحالة التي تعمل فشلت: ${error.message}`);
      }
      
    } else {
      console.log('❌ فشل في إنشاء طلب التشخيص');
    }
    
    // فحص إضافي للخادم
    console.log('\n🔍 === فحص إضافي للخادم ===');
    
    try {
      const healthResponse = await axios.get(`${baseURL}/api/health`, { 
        timeout: 10000,
        validateStatus: () => true 
      });
      
      console.log(`🏥 صحة الخادم:`);
      console.log(`   Status: ${healthResponse.status}`);
      console.log(`   Data:`, healthResponse.data);
      
    } catch (error) {
      console.log(`❌ خطأ في فحص صحة الخادم: ${error.message}`);
    }
    
    // فحص endpoint تحديث الحالة
    try {
      const testResponse = await axios.get(`${baseURL}/api/orders`, { 
        timeout: 10000,
        validateStatus: () => true 
      });
      
      console.log(`📋 فحص endpoint الطلبات:`);
      console.log(`   Status: ${testResponse.status}`);
      console.log(`   عدد الطلبات: ${testResponse.data?.data?.length || 'غير محدد'}`);
      
    } catch (error) {
      console.log(`❌ خطأ في فحص endpoint الطلبات: ${error.message}`);
    }
    
  } catch (error) {
    console.error('❌ خطأ في تشخيص خطأ 500:', error.message);
  }
}

debug500Error();
