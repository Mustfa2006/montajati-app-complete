const axios = require('axios');

async function checkSpecificOrder() {
  console.log('🔍 === فحص طلب معين ===\n');

  // يمكنك تغيير معرف الطلب هنا
  const orderId = process.argv[2] || 'order_1753387932838_5555';
  
  console.log(`📦 فحص الطلب: ${orderId}`);
  
  const baseURL = 'https://montajati-backend.onrender.com';
  
  try {
    // جلب قائمة الطلبات
    console.log('📋 جلب بيانات الطلب...');
    const ordersResponse = await axios.get(`${baseURL}/api/orders`, {
      timeout: 30000
    });
    
    const order = ordersResponse.data.data.find(o => o.id === orderId);
    
    if (!order) {
      console.log('❌ لم يتم العثور على الطلب');
      console.log('💡 تأكد من معرف الطلب الصحيح');
      return;
    }
    
    console.log('\n📊 === تفاصيل الطلب ===');
    console.log(`🆔 معرف الطلب: ${order.id}`);
    console.log(`👤 اسم العميل: ${order.customer_name}`);
    console.log(`📞 رقم الهاتف: ${order.primary_phone || order.customer_phone}`);
    console.log(`📍 العنوان: ${order.delivery_address || order.notes}`);
    console.log(`📊 الحالة: ${order.status}`);
    console.log(`💰 المبلغ: ${order.total || order.subtotal}`);
    console.log(`📅 تاريخ الإنشاء: ${order.created_at}`);
    console.log(`🔄 آخر تحديث: ${order.updated_at}`);
    
    console.log('\n🚚 === معلومات الوسيط ===');
    console.log(`🆔 معرف الوسيط: ${order.waseet_order_id || 'غير محدد'}`);
    console.log(`📦 حالة الوسيط: ${order.waseet_status || 'غير محدد'}`);
    console.log(`📋 بيانات الوسيط: ${order.waseet_data ? 'موجودة' : 'غير موجودة'}`);
    
    if (order.waseet_data) {
      try {
        const waseetData = typeof order.waseet_data === 'string' 
          ? JSON.parse(order.waseet_data) 
          : order.waseet_data;
        console.log(`📊 تفاصيل الوسيط:`, JSON.stringify(waseetData, null, 2));
      } catch (e) {
        console.log(`📊 بيانات الوسيط (خام): ${order.waseet_data}`);
      }
    }
    
    // تحليل الحالة
    console.log('\n🔍 === تحليل الحالة ===');
    
    const isDeliveryStatus = [
      'قيد التوصيل',
      'قيد التوصيل الى الزبون (في عهدة المندوب)',
      'قيد التوصيل الى الزبون',
      'في عهدة المندوب',
      'قيد التوصيل للزبون',
      'shipping',
      'shipped'
    ].includes(order.status);
    
    console.log(`📊 هل الحالة تستدعي إرسال للوسيط؟ ${isDeliveryStatus ? '✅ نعم' : '❌ لا'}`);
    
    if (isDeliveryStatus) {
      if (order.waseet_order_id) {
        console.log('✅ الطلب مرسل للوسيط بنجاح');
        console.log(`🆔 QR ID: ${order.waseet_order_id}`);
        console.log('🎉 النظام يعمل بشكل صحيح لهذا الطلب');
      } else {
        console.log('⚠️ الطلب في حالة توصيل لكن لم يرسل للوسيط');
        console.log('🔍 أسباب محتملة:');
        console.log('   - الطلب حديث التحديث (انتظر دقيقة)');
        console.log('   - مشكلة في بيانات الطلب (رقم هاتف، عنوان)');
        console.log('   - مشكلة في اتصال الوسيط');
        console.log('   - مشكلة في خدمة المزامنة');
      }
    } else {
      console.log('ℹ️ الطلب ليس في حالة توصيل - لا يحتاج إرسال للوسيط');
    }
    
    // اقتراحات
    console.log('\n💡 === اقتراحات ===');
    
    if (isDeliveryStatus && !order.waseet_order_id) {
      console.log('🔄 جرب تحديث حالة الطلب مرة أخرى');
      console.log('⏳ انتظر 1-2 دقيقة بعد التحديث');
      console.log('🔄 أعد تحميل صفحة تفاصيل الطلب');
      console.log('📱 أو أعد فتح التطبيق');
    }
    
    if (!order.primary_phone && !order.customer_phone) {
      console.log('⚠️ الطلب لا يحتوي على رقم هاتف - قد يمنع إرسال للوسيط');
    }
    
    if (!order.delivery_address && !order.notes) {
      console.log('⚠️ الطلب لا يحتوي على عنوان - قد يمنع إرسال للوسيط');
    }
    
  } catch (error) {
    console.error('❌ خطأ في فحص الطلب:', error.message);
    if (error.response) {
      console.error('📋 Status:', error.response.status);
      console.error('📋 Response:', error.response.data);
    }
  }
}

console.log('💡 استخدام: node check_specific_order.js [معرف_الطلب]');
console.log('💡 مثال: node check_specific_order.js order_1753387932838_5555\n');

checkSpecificOrder();
