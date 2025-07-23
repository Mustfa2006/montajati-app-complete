// ===================================
// اختبار طلب واحد بالتفصيل
// Single Order Detailed Test
// ===================================

const axios = require('axios');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

async function testSingleOrder() {
  try {
    console.log('🔍 اختبار طلب واحد بالتفصيل...\n');

    // إعداد Supabase
    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    // إعدادات شركة الوسيط
    const waseetConfig = {
      baseUrl: process.env.ALMASEET_BASE_URL || 'https://api.alwaseet-iq.net',
      username: process.env.WASEET_USERNAME,
      password: process.env.WASEET_PASSWORD
    };

    // 1. جلب طلب حديث للاختبار
    console.log('📋 جلب طلب للاختبار...');
    const { data: orders, error } = await supabase
      .from('orders')
      .select('*')
      .not('waseet_order_id', 'is', null)
      .order('created_at', { ascending: false })
      .limit(1);

    if (error || !orders || orders.length === 0) {
      throw new Error('لا توجد طلبات للاختبار');
    }

    const testOrder = orders[0];
    console.log(`✅ تم اختيار الطلب: ${testOrder.order_number}`);
    console.log(`🆔 معرف الوسيط: ${testOrder.waseet_order_id}`);
    console.log(`📊 الحالة الحالية: ${testOrder.status}`);
    console.log(`📅 تاريخ الإنشاء: ${testOrder.created_at}\n`);

    // 2. تسجيل الدخول
    console.log('🔐 تسجيل الدخول...');
    const loginData = new URLSearchParams({
      username: waseetConfig.username,
      password: waseetConfig.password
    });

    const loginResponse = await axios.post(
      `${waseetConfig.baseUrl}/merchant/login`,
      loginData,
      {
        timeout: 15000,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
        maxRedirects: 0,
        validateStatus: () => true
      }
    );

    if (loginResponse.status !== 302 && loginResponse.status !== 303) {
      throw new Error(`فشل تسجيل الدخول: ${loginResponse.status}`);
    }

    const token = loginResponse.headers['set-cookie']?.join('; ') || '';
    console.log('✅ تم تسجيل الدخول بنجاح\n');

    // 3. اختبار عدة طرق لجلب الحالة
    const testMethods = [
      {
        name: 'get_order_status',
        url: `${waseetConfig.baseUrl}/merchant/get_order_status`,
        params: { order_id: testOrder.waseet_order_id }
      },
      {
        name: 'order_details',
        url: `${waseetConfig.baseUrl}/merchant/order_details`,
        params: { id: testOrder.waseet_order_id }
      },
      {
        name: 'orders_list',
        url: `${waseetConfig.baseUrl}/merchant/orders`,
        params: {}
      }
    ];

    for (const method of testMethods) {
      try {
        console.log(`🔍 اختبار طريقة: ${method.name}`);
        console.log(`🌐 URL: ${method.url}`);

        const response = await axios.get(method.url, {
          params: method.params,
          timeout: 15000,
          headers: {
            'Cookie': token,
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
          },
          validateStatus: () => true
        });

        console.log(`📊 رمز الحالة: ${response.status}`);
        
        if (response.status === 200) {
          console.log(`✅ نجح! البيانات:`);
          
          if (typeof response.data === 'string') {
            // إذا كانت الاستجابة HTML
            if (response.data.includes('<html>')) {
              console.log('📄 استجابة HTML (صفحة ويب)');
              
              // البحث عن معرف الطلب في HTML
              if (response.data.includes(testOrder.waseet_order_id)) {
                console.log(`✅ تم العثور على معرف الطلب في الصفحة`);
              }
            } else {
              console.log('📝 استجابة نصية:', response.data.substring(0, 200));
            }
          } else {
            console.log('📊 استجابة JSON:', JSON.stringify(response.data, null, 2));
          }
        } else {
          console.log(`❌ فشل: ${response.status} - ${response.statusText}`);
        }

        console.log('-'.repeat(50));

      } catch (error) {
        console.log(`❌ خطأ في ${method.name}: ${error.message}`);
        console.log('-'.repeat(50));
      }
    }

    // 4. اختبار تحديث الحالة يدوياً
    console.log('\n🔄 اختبار تحديث الحالة يدوياً...');
    
    // محاكاة تحديث الحالة
    const simulatedWaseetStatus = 'delivered'; // محاكاة حالة جديدة
    const simulatedWaseetData = {
      status: simulatedWaseetStatus,
      order_id: testOrder.waseet_order_id,
      updated_at: new Date().toISOString(),
      test_mode: true
    };

    console.log(`📊 محاكاة حالة جديدة: ${simulatedWaseetStatus}`);

    // تحديث قاعدة البيانات
    const { error: updateError } = await supabase
      .from('orders')
      .update({
        waseet_status: simulatedWaseetStatus,
        waseet_data: simulatedWaseetData,
        last_status_check: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .eq('id', testOrder.id);

    if (updateError) {
      throw new Error(`خطأ في التحديث: ${updateError.message}`);
    }

    console.log('✅ تم تحديث قاعدة البيانات بنجاح');

    // إضافة سجل في التاريخ
    const { error: historyError } = await supabase
      .from('order_status_history')
      .insert({
        order_id: testOrder.id,
        old_status: testOrder.status,
        new_status: testOrder.status, // نفس الحالة للاختبار
        changed_by: 'manual_test',
        change_reason: 'اختبار يدوي للنظام',
        waseet_response: simulatedWaseetData
      });

    if (historyError) {
      console.warn('⚠️ تحذير: فشل في إضافة سجل التاريخ:', historyError.message);
    } else {
      console.log('✅ تم إضافة سجل في التاريخ');
    }

    // 5. التحقق من النتيجة النهائية
    console.log('\n📊 التحقق من النتيجة النهائية...');
    
    const { data: updatedOrder } = await supabase
      .from('orders')
      .select('*')
      .eq('id', testOrder.id)
      .single();

    if (updatedOrder) {
      console.log('✅ الطلب بعد التحديث:');
      console.log(`📊 الحالة: ${updatedOrder.status}`);
      console.log(`🔄 حالة الوسيط: ${updatedOrder.waseet_status}`);
      console.log(`⏰ آخر فحص: ${updatedOrder.last_status_check}`);
      console.log(`📅 آخر تحديث: ${updatedOrder.updated_at}`);
    }

    console.log('\n🎉 تم اختبار الطلب بنجاح!');

  } catch (error) {
    console.error('❌ خطأ في الاختبار:', error.message);
  }
}

// تشغيل الاختبار
testSingleOrder();
