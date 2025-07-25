// ===================================
// تشخيص ذكي للمشكلة
// Smart Problem Diagnosis
// ===================================

require('dotenv').config();

async function smartDiagnosis() {
  console.log('🧠 تشخيص ذكي للمشكلة...');
  console.log('='.repeat(60));

  try {
    // المرحلة 1: فحص متغيرات البيئة بذكاء
    console.log('\n🔍 المرحلة 1: فحص متغيرات البيئة');
    console.log('='.repeat(40));
    
    const requiredEnvVars = {
      'SUPABASE_URL': process.env.SUPABASE_URL,
      'SUPABASE_SERVICE_ROLE_KEY': process.env.SUPABASE_SERVICE_ROLE_KEY,
      'WASEET_USERNAME': process.env.WASEET_USERNAME,
      'WASEET_PASSWORD': process.env.WASEET_PASSWORD
    };

    let envIssues = [];
    for (const [key, value] of Object.entries(requiredEnvVars)) {
      if (!value) {
        envIssues.push(key);
        console.log(`❌ ${key}: غير موجود`);
      } else {
        console.log(`✅ ${key}: موجود`);
      }
    }

    if (envIssues.length > 0) {
      console.log(`\n⚠️ متغيرات البيئة الناقصة: ${envIssues.join(', ')}`);
      return false;
    }

    // المرحلة 2: اختبار تحميل الملفات بذكاء
    console.log('\n📦 المرحلة 2: اختبار تحميل الملفات');
    console.log('='.repeat(40));
    
    let loadingIssues = [];
    
    try {
      console.log('🔧 تحميل WaseetAPIClient...');
      const WaseetAPIClient = require('./services/waseet_api_client');
      const waseetClient = new WaseetAPIClient();
      console.log(`✅ WaseetAPIClient: ${waseetClient.isConfigured ? 'مهيأ' : 'غير مهيأ'}`);
      
      if (!waseetClient.isConfigured) {
        loadingIssues.push('WaseetAPIClient غير مهيأ');
      }
    } catch (error) {
      console.log(`❌ WaseetAPIClient: خطأ في التحميل - ${error.message}`);
      loadingIssues.push(`WaseetAPIClient: ${error.message}`);
    }

    try {
      console.log('🔧 تحميل OrderSyncService...');
      const OrderSyncService = require('./services/order_sync_service');
      const syncService = new OrderSyncService();
      console.log(`✅ OrderSyncService: ${syncService.isInitialized ? 'مهيأ' : 'غير مهيأ'}`);
      
      if (!syncService.isInitialized) {
        loadingIssues.push('OrderSyncService غير مهيأ');
      }
    } catch (error) {
      console.log(`❌ OrderSyncService: خطأ في التحميل - ${error.message}`);
      loadingIssues.push(`OrderSyncService: ${error.message}`);
    }

    if (loadingIssues.length > 0) {
      console.log(`\n⚠️ مشاكل التحميل: ${loadingIssues.join(', ')}`);
    }

    // المرحلة 3: محاكاة تهيئة الخدمة بذكاء
    console.log('\n🚀 المرحلة 3: محاكاة تهيئة الخدمة');
    console.log('='.repeat(40));
    
    try {
      console.log('🔄 بدء تهيئة خدمة مزامنة الطلبات مع الوسيط...');

      // استيراد خدمة المزامنة
      console.log('📦 استيراد OrderSyncService...');
      const OrderSyncService = require('./services/order_sync_service');
      console.log('✅ تم استيراد OrderSyncService بنجاح');

      // إنشاء instance من الخدمة
      console.log('🔧 إنشاء instance من OrderSyncService...');
      const syncService = new OrderSyncService();
      console.log('✅ تم إنشاء instance بنجاح');

      // فحص تفصيلي للخدمة
      console.log('\n🔍 فحص تفصيلي للخدمة:');
      console.log(`   isInitialized: ${syncService.isInitialized}`);
      console.log(`   waseetClient موجود: ${syncService.waseetClient ? 'نعم' : 'لا'}`);
      
      if (syncService.waseetClient) {
        console.log(`   waseetClient.isConfigured: ${syncService.waseetClient.isConfigured}`);
        console.log(`   waseetClient.username: ${syncService.waseetClient.username ? 'موجود' : 'غير موجود'}`);
        console.log(`   waseetClient.password: ${syncService.waseetClient.password ? 'موجود' : 'غير موجود'}`);
        console.log(`   waseetClient.baseURL: ${syncService.waseetClient.baseURL}`);
      }

      // التحقق من حالة التهيئة
      if (syncService.isInitialized === false) {
        console.warn('⚠️ خدمة المزامنة مهيأة لكن عميل الوسيط غير مهيأ (بيانات المصادقة ناقصة)');
        console.warn('💡 يرجى إضافة WASEET_USERNAME و WASEET_PASSWORD في متغيرات البيئة');
      } else {
        console.log('✅ خدمة المزامنة مهيأة بالكامل مع عميل الوسيط');
      }

      // اختبار تسجيل الدخول
      if (syncService.waseetClient && syncService.waseetClient.isConfigured) {
        console.log('\n🔐 اختبار تسجيل الدخول للوسيط...');
        try {
          const loginResult = await syncService.waseetClient.login();
          if (loginResult) {
            console.log('✅ تم تسجيل الدخول بنجاح');
            console.log(`🔑 Token: ${syncService.waseetClient.token ? syncService.waseetClient.token.substring(0, 20) + '...' : 'غير موجود'}`);
          } else {
            console.log('❌ فشل في تسجيل الدخول');
          }
        } catch (loginError) {
          console.log(`❌ خطأ في تسجيل الدخول: ${loginError.message}`);
        }
      }

      global.orderSyncService = syncService;
      console.log('✅ تم تهيئة خدمة مزامنة الطلبات مع الوسيط بنجاح');
      
      // فحص global.orderSyncService
      console.log('\n🔍 فحص global.orderSyncService:');
      console.log(`   موجود: ${global.orderSyncService ? '✅ نعم' : '❌ لا'}`);
      if (global.orderSyncService) {
        console.log(`   isInitialized: ${global.orderSyncService.isInitialized}`);
        console.log(`   waseetClient: ${global.orderSyncService.waseetClient ? 'موجود' : 'غير موجود'}`);
        if (global.orderSyncService.waseetClient) {
          console.log(`   waseetClient.isConfigured: ${global.orderSyncService.waseetClient.isConfigured}`);
        }
        
        // اختبار الدوال
        console.log('\n🧪 اختبار الدوال:');
        console.log(`   sendOrderToWaseet: ${typeof global.orderSyncService.sendOrderToWaseet === 'function' ? '✅ موجود' : '❌ غير موجود'}`);
        console.log(`   retryFailedOrders: ${typeof global.orderSyncService.retryFailedOrders === 'function' ? '✅ موجود' : '❌ غير موجود'}`);
      }
      
      return true;

    } catch (error) {
      console.error('❌ خطأ في تهيئة خدمة مزامنة الطلبات مع الوسيط:', error.message);
      console.error('📋 تفاصيل الخطأ:', error.stack);
      return false;
    }

  } catch (error) {
    console.error('❌ خطأ عام في التشخيص:', error);
    return false;
  }
}

// المرحلة 4: اختبار API الوسيط الحقيقي
async function testRealWaseetAPI() {
  console.log('\n🌐 المرحلة 4: اختبار API الوسيط الحقيقي');
  console.log('='.repeat(40));
  
  try {
    const WaseetAPIClient = require('./services/waseet_api_client');
    const waseetClient = new WaseetAPIClient();
    
    console.log(`🔗 API URL: ${waseetClient.baseURL}`);
    console.log(`🔧 حالة التهيئة: ${waseetClient.isConfigured ? '✅ مهيأ' : '❌ غير مهيأ'}`);
    
    if (waseetClient.isConfigured) {
      console.log('\n🔐 اختبار تسجيل الدخول...');
      const loginResult = await waseetClient.login();
      
      if (loginResult) {
        console.log('✅ تم تسجيل الدخول بنجاح');
        console.log(`🔑 Token: ${waseetClient.token ? waseetClient.token.substring(0, 20) + '...' : 'غير موجود'}`);
        
        // اختبار إنشاء طلب
        console.log('\n📦 اختبار إنشاء طلب...');
        const testOrderData = {
          client_name: 'عميل اختبار',
          client_mobile: '+9647901234567',
          city_id: 1,
          region_id: 1,
          location: 'عنوان اختبار',
          type_name: 'عادي',
          items_number: 1,
          price: 25000,
          package_size: 1,
          merchant_notes: 'طلب اختبار من تطبيق منتجاتي',
          replacement: 0
        };
        
        console.log('📋 بيانات الطلب:', JSON.stringify(testOrderData, null, 2));
        
        const createResult = await waseetClient.createOrder(testOrderData);
        
        if (createResult && createResult.success) {
          console.log('🎉 نجح! تم إنشاء الطلب في الوسيط');
          console.log(`🆔 QR ID: ${createResult.qrId}`);
          console.log('📋 استجابة الوسيط:', JSON.stringify(createResult, null, 2));
        } else {
          console.log('❌ فشل في إنشاء الطلب');
          console.log('تفاصيل الخطأ:', createResult);
        }
      } else {
        console.log('❌ فشل في تسجيل الدخول');
      }
    } else {
      console.log('❌ لا يمكن اختبار API - بيانات المصادقة غير موجودة');
    }
    
  } catch (error) {
    console.error('❌ خطأ في اختبار API الوسيط:', error);
  }
}

// تشغيل التشخيص الذكي
smartDiagnosis()
  .then(async (result) => {
    console.log('\n🎯 النتيجة الأولية:');
    console.log('='.repeat(60));
    if (result) {
      console.log('🎉 التشخيص الأولي نجح!');
      
      // اختبار API الوسيط
      await testRealWaseetAPI();
      
    } else {
      console.log('❌ هناك مشكلة في التشخيص الأولي');
    }
    
    console.log('\n🏁 النتيجة النهائية:');
    console.log('='.repeat(60));
    console.log('📊 تم تحليل المشكلة بذكاء');
    console.log('🔗 API الوسيط: https://api.alwaseet-iq.net/v1/merchant/create-order?token=loginToken');
  })
  .catch((error) => {
    console.error('❌ خطأ في تشغيل التشخيص الذكي:', error);
  });
