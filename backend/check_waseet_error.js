// ===================================
// فحص تفاصيل خطأ الوسيط
// Check Waseet Error Details
// ===================================

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

async function checkWaseetError() {
  console.log('🔍 فحص تفاصيل خطأ الوسيط...');
  console.log('='.repeat(50));

  try {
    // إنشاء عميل Supabase
    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    // جلب الطلب الذي فشل
    const { data: order, error } = await supabase
      .from('orders')
      .select('*')
      .eq('id', 'order_1753390748341_3333')
      .single();

    if (error) {
      console.error('❌ خطأ في جلب الطلب:', error);
      return;
    }

    console.log('📋 تفاصيل الطلب:');
    console.log(`   🆔 المعرف: ${order.id}`);
    console.log(`   👤 العميل: ${order.customer_name}`);
    console.log(`   📞 الهاتف: ${order.customer_phone}`);
    console.log(`   📍 العنوان: ${order.customer_address}`);
    console.log(`   💰 المجموع: ${order.total}`);
    console.log(`   📊 الحالة: ${order.status}`);

    // فحص بيانات الوسيط بالتفصيل
    if (order.waseet_data) {
      try {
        const waseetData = JSON.parse(order.waseet_data);
        console.log('\n📋 تفاصيل بيانات الوسيط:');
        console.log(JSON.stringify(waseetData, null, 2));
        
        if (waseetData.error) {
          console.log(`\n❌ تفاصيل الخطأ: ${waseetData.error}`);
          
          // تحليل نوع الخطأ
          if (waseetData.error.includes('بيانات المصادقة')) {
            console.log('🔍 التشخيص: مشكلة في بيانات المصادقة مع الوسيط');
          } else if (waseetData.error.includes('فشل في المصادقة')) {
            console.log('🔍 التشخيص: بيانات المصادقة خاطئة');
          } else if (waseetData.error.includes('timeout') || waseetData.error.includes('ECONNRESET')) {
            console.log('🔍 التشخيص: مشكلة في الاتصال بخدمة الوسيط');
          } else if (waseetData.error.includes('رقم الهاتف')) {
            console.log('🔍 التشخيص: مشكلة في تنسيق رقم الهاتف');
          } else {
            console.log('🔍 التشخيص: خطأ غير محدد في خدمة الوسيط');
          }
        }
      } catch (e) {
        console.log('\n❌ بيانات الوسيط غير قابلة للقراءة');
        console.log('البيانات الخام:', order.waseet_data);
      }
    }

    // اختبار إرسال الطلب مرة أخرى
    console.log('\n🧪 اختبار إرسال الطلب للوسيط مرة أخرى...');
    
    // التحقق من متغيرات البيئة
    console.log('\n🔍 فحص متغيرات البيئة:');
    console.log(`   WASEET_USERNAME: ${process.env.WASEET_USERNAME ? 'موجود' : 'غير موجود'}`);
    console.log(`   WASEET_PASSWORD: ${process.env.WASEET_PASSWORD ? 'موجود' : 'غير موجود'}`);
    
    if (process.env.WASEET_USERNAME) {
      console.log(`   اسم المستخدم: ${process.env.WASEET_USERNAME}`);
    }

    // محاولة إنشاء خدمة الوسيط
    try {
      const WaseetAPIClient = require('./services/waseet_api_client');
      const waseetClient = new WaseetAPIClient();
      
      console.log('\n✅ تم إنشاء عميل الوسيط بنجاح');
      console.log(`   حالة التهيئة: ${waseetClient.isConfigured ? 'مهيأ' : 'غير مهيأ'}`);
      
      if (waseetClient.isConfigured) {
        // محاولة تسجيل الدخول
        console.log('\n🔐 محاولة تسجيل الدخول...');
        const loginResult = await waseetClient.login();
        
        if (loginResult) {
          console.log('✅ تم تسجيل الدخول بنجاح');
          console.log(`🔑 Token: ${waseetClient.token ? waseetClient.token.substring(0, 20) + '...' : 'غير موجود'}`);
          
          // محاولة إرسال الطلب
          console.log('\n📦 محاولة إرسال الطلب...');
          
          // تحضير بيانات الطلب
          let clientMobile = order.customer_phone;
          if (clientMobile && !clientMobile.startsWith('+964')) {
            if (clientMobile.startsWith('07')) {
              clientMobile = '+964' + clientMobile.substring(1);
            } else if (clientMobile.startsWith('7')) {
              clientMobile = '+964' + clientMobile;
            }
          }

          const orderData = {
            client_name: order.customer_name || 'عميل',
            client_mobile: clientMobile || '+9647901234567',
            city_id: 1,
            region_id: 1,
            location: order.customer_address || 'عنوان العميل',
            type_name: 'عادي',
            items_number: 1,
            price: order.total || 25000,
            package_size: 1,
            merchant_notes: `طلب من تطبيق منتجاتي - رقم الطلب: ${order.id}`,
            replacement: 0
          };

          console.log('📋 بيانات الطلب المرسلة:');
          console.log(JSON.stringify(orderData, null, 2));

          const createResult = await waseetClient.createOrder(orderData);
          
          if (createResult && createResult.success) {
            console.log('🎉 نجح! تم إرسال الطلب للوسيط');
            console.log(`🆔 QR ID: ${createResult.qrId}`);
            
            // تحديث الطلب في قاعدة البيانات
            await supabase
              .from('orders')
              .update({
                waseet_order_id: createResult.qrId,
                waseet_status: 'تم الإرسال للوسيط',
                waseet_data: JSON.stringify(createResult),
                updated_at: new Date().toISOString()
              })
              .eq('id', order.id);
              
            console.log('✅ تم تحديث الطلب في قاعدة البيانات');
          } else {
            console.log('❌ فشل في إرسال الطلب');
            console.log('تفاصيل الخطأ:', createResult);
          }
        } else {
          console.log('❌ فشل في تسجيل الدخول');
        }
      } else {
        console.log('❌ عميل الوسيط غير مهيأ - بيانات المصادقة ناقصة');
      }
    } catch (serviceError) {
      console.error('❌ خطأ في إنشاء خدمة الوسيط:', serviceError.message);
    }

  } catch (error) {
    console.error('❌ خطأ عام:', error);
  }
}

// تشغيل الفحص
checkWaseetError()
  .then(() => {
    console.log('\n✅ انتهى فحص خطأ الوسيط');
  })
  .catch((error) => {
    console.error('\n❌ خطأ في تشغيل الفحص:', error);
  });
