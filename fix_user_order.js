const axios = require('axios');

async function fixUserOrder() {
  console.log('🔧 === إصلاح طلب المستخدم ===\n');
  
  const baseURL = 'https://montajati-backend.onrender.com';
  const problemOrderId = 'order_1753533667583_2222';
  
  try {
    console.log(`🎯 إصلاح الطلب: ${problemOrderId}`);
    
    // محاولة إرسال يدوي فوري
    console.log('🔧 محاولة إرسال يدوي للوسيط...');
    
    const manualSendResponse = await axios.post(
      `${baseURL}/api/orders/${problemOrderId}/send-to-waseet`, 
      {}, 
      { 
        timeout: 60000,
        validateStatus: () => true 
      }
    );
    
    console.log(`📊 نتيجة الإرسال اليدوي:`);
    console.log(`   Status: ${manualSendResponse.status}`);
    console.log(`   Success: ${manualSendResponse.data?.success}`);
    console.log(`   Message: ${manualSendResponse.data?.message}`);
    
    if (manualSendResponse.data?.success) {
      console.log(`✅ تم إصلاح الطلب بنجاح!`);
      console.log(`🆔 QR ID: ${manualSendResponse.data.data?.qrId}`);
      console.log(`🔗 رابط الوسيط: ${manualSendResponse.data.data?.qr_link || 'غير متوفر'}`);
      console.log(`\n🎉 الطلب الآن في الوسيط ويمكن طباعته!`);
      
      // التحقق من النتيجة
      console.log('\n🔍 التحقق من النتيجة...');
      await new Promise(resolve => setTimeout(resolve, 5000));
      
      const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
      const fixedOrder = ordersResponse.data.data.find(o => o.id === problemOrderId);
      
      if (fixedOrder && fixedOrder.waseet_order_id) {
        console.log(`✅ تأكيد: الطلب تم إصلاحه`);
        console.log(`🆔 معرف الوسيط: ${fixedOrder.waseet_order_id}`);
        console.log(`📦 حالة الوسيط: ${fixedOrder.waseet_status}`);
        console.log(`\n📱 ارجع للتطبيق - ستجد أيقونة الشاحنة الزرقاء الآن!`);
      }
      
    } else {
      console.log(`❌ فشل الإرسال اليدوي`);
      console.log(`🔍 تفاصيل الخطأ:`, manualSendResponse.data);
      
      // فحص تفصيلي للطلب
      console.log('\n🔍 فحص تفصيلي للطلب...');
      
      const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
      const problemOrder = ordersResponse.data.data.find(o => o.id === problemOrderId);
      
      if (problemOrder) {
        console.log(`📋 تفاصيل الطلب:`);
        console.log(`   👤 العميل: ${problemOrder.customer_name}`);
        console.log(`   📊 الحالة: ${problemOrder.status}`);
        console.log(`   🆔 معرف الوسيط: ${problemOrder.waseet_order_id || 'غير محدد'}`);
        console.log(`   📦 حالة الوسيط: ${problemOrder.waseet_status || 'غير محدد'}`);
        console.log(`   📞 الهاتف: ${problemOrder.primary_phone}`);
        console.log(`   📍 العنوان: ${problemOrder.customer_address}`);
        console.log(`   🏙️ المحافظة: ${problemOrder.province}`);
        console.log(`   🏘️ المدينة: ${problemOrder.city}`);
        
        if (problemOrder.waseet_data) {
          try {
            const waseetData = JSON.parse(problemOrder.waseet_data);
            console.log(`   📋 بيانات الوسيط:`, waseetData);
          } catch (e) {
            console.log(`   📋 بيانات الوسيط (خام): ${problemOrder.waseet_data}`);
          }
        }
      }
    }
    
  } catch (error) {
    console.error('❌ خطأ في إصلاح طلب المستخدم:', error.message);
    if (error.response) {
      console.log(`📊 Status: ${error.response.status}`);
      console.log(`📋 Data:`, error.response.data);
    }
  }
}

fixUserOrder();
