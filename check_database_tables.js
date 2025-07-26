const axios = require('axios');

async function checkDatabaseTables() {
  console.log('🔍 === فحص جداول قاعدة البيانات ===\n');
  console.log('🎯 التحقق من وجود جدول order_status_history\n');

  const baseURL = 'https://montajati-backend.onrender.com';
  
  try {
    // إنشاء طلب جديد
    const newOrderData = {
      customer_name: 'فحص قاعدة البيانات',
      primary_phone: '07901234567',
      customer_address: 'بغداد - الكرخ - فحص قاعدة البيانات',
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
      order_number: `ORD-DBCHECK-${Date.now()}`,
      notes: 'فحص قاعدة البيانات'
    };
    
    const createResponse = await axios.post(`${baseURL}/api/orders`, newOrderData, {
      headers: {
        'Content-Type': 'application/json'
      },
      timeout: 30000
    });
    
    if (createResponse.data.success) {
      const orderId = createResponse.data.data.id;
      console.log(`📦 طلب الفحص: ${orderId}`);
      
      // محاولة تحديث الحالة مع حالة تعمل أولاً
      console.log('\n1️⃣ === اختبار مع حالة تعمل ===');
      
      const workingUpdateData = {
        status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
        notes: 'اختبار حالة تعمل',
        changedBy: 'db_check_working'
      };
      
      try {
        const workingResponse = await axios.put(
          `${baseURL}/api/orders/${orderId}/status`,
          workingUpdateData,
          {
            headers: {
              'Content-Type': 'application/json'
            },
            timeout: 60000
          }
        );
        
        console.log(`✅ الحالة التي تعمل نجحت:`);
        console.log(`   Status: ${workingResponse.status}`);
        console.log(`   Success: ${workingResponse.data.success}`);
        
      } catch (error) {
        console.log(`❌ حتى الحالة التي تعمل فشلت: ${error.message}`);
        if (error.response) {
          console.log(`   Response:`, error.response.data);
        }
      }
      
      // الآن اختبار مع حالة تسبب مشكلة
      console.log('\n2️⃣ === اختبار مع حالة تسبب مشكلة ===');
      
      const problematicUpdateData = {
        status: '3',
        notes: 'اختبار حالة تسبب مشكلة',
        changedBy: 'db_check_problematic'
      };
      
      try {
        const problematicResponse = await axios.put(
          `${baseURL}/api/orders/${orderId}/status`,
          problematicUpdateData,
          {
            headers: {
              'Content-Type': 'application/json'
            },
            timeout: 60000,
            validateStatus: () => true
          }
        );
        
        console.log(`📋 نتيجة الحالة المشكلة:`);
        console.log(`   Status: ${problematicResponse.status}`);
        console.log(`   Data:`, problematicResponse.data);
        
        if (problematicResponse.status === 500) {
          console.log('\n🔍 === تحليل سبب الخطأ ===');
          console.log('المشكلة على الأرجح في جدول order_status_history');
          console.log('الجدول قد يكون غير موجود أو له structure مختلف');
        }
        
      } catch (error) {
        console.log(`❌ خطأ في الحالة المشكلة: ${error.message}`);
      }
      
    } else {
      console.log('❌ فشل في إنشاء طلب الفحص');
    }
    
    console.log('\n📋 === التوصيات ===');
    console.log('1. إما إنشاء جدول order_status_history');
    console.log('2. أو إزالة الكود الذي يحاول الكتابة فيه');
    console.log('3. أو إضافة try-catch حول عملية إدراج التاريخ');
    
  } catch (error) {
    console.error('❌ خطأ في فحص قاعدة البيانات:', error.message);
  }
}

checkDatabaseTables();
