const axios = require('axios');

async function tracePendingSource() {
  console.log('🔍 === تتبع مصدر مشكلة pending ===\n');

  const baseURL = 'https://montajati-official-backend-production.up.railway.app';
  
  // استخدام طلب موجود من التحليل السابق
  const testOrderId = 'order_1753478889109_1111';
  
  try {
    console.log(`📦 تتبع الطلب: ${testOrderId}`);
    
    // 1. فحص الطلب قبل التحديث
    console.log('\n1️⃣ فحص الطلب قبل التحديث...');
    await checkOrderDetailed(baseURL, testOrderId, 'قبل التحديث');
    
    // 2. تحديث الحالة مع مراقبة مفصلة
    console.log('\n2️⃣ تحديث الحالة مع مراقبة مفصلة...');
    
    // أولاً، تغيير الحالة إلى شيء آخر لإعادة تعيين waseet_status
    console.log('🔄 تغيير الحالة إلى "نشط" أولاً لإعادة تعيين waseet_status...');
    
    const resetData = {
      status: 'نشط',
      notes: 'إعادة تعيين لاختبار pending',
      changedBy: 'pending_trace_reset'
    };
    
    const resetResponse = await axios.put(
      `${baseURL}/api/orders/${testOrderId}/status`,
      resetData,
      {
        headers: {
          'Content-Type': 'application/json'
        },
        timeout: 30000
      }
    );
    
    console.log(`📊 Reset Response: ${resetResponse.status} - ${resetResponse.data.success}`);
    
    // انتظار قصير
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    // فحص بعد إعادة التعيين
    console.log('\n📋 فحص بعد إعادة التعيين...');
    await checkOrderDetailed(baseURL, testOrderId, 'بعد إعادة التعيين');
    
    // الآن تحديث إلى قيد التوصيل مع مراقبة دقيقة
    console.log('\n🚀 تحديث إلى قيد التوصيل مع مراقبة دقيقة...');
    
    const updateData = {
      status: 'قيد التوصيل الى الزبون (في عهدة المندوب)',
      notes: 'اختبار تتبع pending - مراقبة دقيقة',
      changedBy: 'pending_trace_test'
    };
    
    console.log('📤 إرسال طلب تحديث الحالة...');
    
    const updateResponse = await axios.put(
      `${baseURL}/api/orders/${testOrderId}/status`,
      updateData,
      {
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        timeout: 60000
      }
    );
    
    console.log('\n📥 استجابة تحديث الحالة:');
    console.log(`📊 Status: ${updateResponse.status}`);
    console.log(`📊 Success: ${updateResponse.data.success}`);
    console.log(`📋 Message: ${updateResponse.data.message}`);
    
    if (updateResponse.data.success) {
      console.log('✅ تم تحديث الحالة بنجاح');
      
      // مراقبة مفصلة كل 5 ثوان
      const checkIntervals = [2, 5, 10, 15, 20, 30, 45, 60];
      
      for (const seconds of checkIntervals) {
        console.log(`\n⏳ انتظار ${seconds} ثانية...`);
        await new Promise(resolve => setTimeout(resolve, (seconds - (checkIntervals[checkIntervals.indexOf(seconds) - 1] || 0)) * 1000));
        
        console.log(`\n🔍 فحص بعد ${seconds} ثانية:`);
        const currentStatus = await checkOrderDetailed(baseURL, testOrderId, `بعد ${seconds} ثانية`);
        
        // إذا تغيرت الحالة، توقف عن المراقبة
        if (currentStatus && currentStatus.waseet_status && currentStatus.waseet_status !== 'pending') {
          console.log(`\n🎯 تغيرت حالة الوسيط إلى: ${currentStatus.waseet_status}`);
          break;
        }
        
        // إذا حصل على QR ID، توقف
        if (currentStatus && currentStatus.waseet_order_id) {
          console.log(`\n🎉 حصل على QR ID: ${currentStatus.waseet_order_id}`);
          break;
        }
      }
      
    } else {
      console.log('❌ فشل في تحديث الحالة');
      console.log('📋 الخطأ:', updateResponse.data.error);
    }
    
  } catch (error) {
    console.error('❌ خطأ في تتبع مشكلة pending:', error.message);
    if (error.response) {
      console.error('📋 Response Status:', error.response.status);
      console.error('📋 Response Data:', error.response.data);
    }
  }
}

async function checkOrderDetailed(baseURL, orderId, stage) {
  try {
    const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
    const order = ordersResponse.data.data.find(o => o.id === orderId);
    
    if (!order) {
      console.log('❌ لم يتم العثور على الطلب');
      return null;
    }
    
    console.log(`📋 === ${stage} ===`);
    console.log(`   📊 الحالة: ${order.status}`);
    console.log(`   🆔 معرف الوسيط: ${order.waseet_order_id || 'غير محدد'}`);
    console.log(`   📦 حالة الوسيط: ${order.waseet_status || 'غير محدد'}`);
    console.log(`   📋 بيانات الوسيط: ${order.waseet_data ? 'موجودة' : 'غير موجودة'}`);
    console.log(`   🕐 آخر تحديث: ${order.updated_at}`);
    
    // تحليل مفصل لبيانات الوسيط
    if (order.waseet_data) {
      try {
        const waseetData = typeof order.waseet_data === 'string' 
          ? JSON.parse(order.waseet_data) 
          : order.waseet_data;
        
        console.log(`   📊 تفاصيل بيانات الوسيط:`);
        
        if (waseetData.error) {
          console.log(`      ❌ خطأ: ${waseetData.error}`);
        }
        
        if (waseetData.success !== undefined) {
          console.log(`      📈 نجح: ${waseetData.success}`);
        }
        
        if (waseetData.qrId) {
          console.log(`      🆔 QR ID: ${waseetData.qrId}`);
        }
        
        if (waseetData.retry_needed) {
          console.log(`      🔄 يحتاج إعادة محاولة: ${waseetData.retry_needed}`);
        }
        
        if (waseetData.last_attempt) {
          console.log(`      🕐 آخر محاولة: ${waseetData.last_attempt}`);
        }
        
        if (waseetData.needsConfiguration) {
          console.log(`      ⚙️ يحتاج إعداد: ${waseetData.needsConfiguration}`);
        }
        
        // عرض البيانات الكاملة إذا كانت قصيرة
        const dataString = JSON.stringify(waseetData);
        if (dataString.length < 200) {
          console.log(`      📋 البيانات الكاملة: ${dataString}`);
        }
        
      } catch (e) {
        console.log(`   ⚠️ خطأ في تحليل بيانات الوسيط: ${e.message}`);
        console.log(`   📊 البيانات الخام: ${order.waseet_data.substring(0, 100)}...`);
      }
    }
    
    // تحليل خاص بحالة pending
    if (order.waseet_status === 'pending') {
      console.log(`   ⚠️ === تحليل حالة pending ===`);
      
      const timeDiff = new Date() - new Date(order.updated_at);
      const minutesAgo = Math.floor(timeDiff / (1000 * 60));
      const secondsAgo = Math.floor(timeDiff / 1000);
      
      console.log(`   ⏰ في حالة pending منذ: ${minutesAgo} دقيقة و ${secondsAgo % 60} ثانية`);
      
      if (minutesAgo > 2) {
        console.log(`   🚨 تحذير: الطلب في حالة pending لفترة طويلة!`);
        console.log(`   💡 هذا يشير إلى مشكلة في المعالجة أو timeout`);
      }
    }
    
    return {
      status: order.status,
      waseet_order_id: order.waseet_order_id,
      waseet_status: order.waseet_status,
      waseet_data: order.waseet_data,
      updated_at: order.updated_at
    };
    
  } catch (error) {
    console.log(`❌ خطأ في فحص الطلب: ${error.message}`);
    return null;
  }
}

tracePendingSource();
