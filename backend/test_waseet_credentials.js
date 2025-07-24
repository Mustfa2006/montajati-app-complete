// ===================================
// اختبار بيانات المصادقة مع الوسيط
// Test Waseet Credentials
// ===================================

require('dotenv').config();

console.log('🔍 فحص بيانات المصادقة مع الوسيط...');
console.log('='.repeat(60));

console.log('📋 متغيرات البيئة:');
console.log(`WASEET_USERNAME: ${process.env.WASEET_USERNAME ? 'موجود' : 'غير موجود'}`);
console.log(`WASEET_PASSWORD: ${process.env.WASEET_PASSWORD ? 'موجود' : 'غير موجود'}`);

if (process.env.WASEET_USERNAME) {
  console.log(`📝 اسم المستخدم: ${process.env.WASEET_USERNAME}`);
}

if (process.env.WASEET_PASSWORD) {
  console.log(`🔑 كلمة المرور: ${process.env.WASEET_PASSWORD.substring(0, 3)}***`);
}

// اختبار إنشاء WaseetAPIClient
console.log('\n🧪 اختبار إنشاء WaseetAPIClient...');
try {
  const WaseetAPIClient = require('./services/waseet_api_client');
  const client = new WaseetAPIClient();
  
  console.log(`✅ تم إنشاء WaseetAPIClient بنجاح`);
  console.log(`📊 حالة التهيئة: ${client.isConfigured ? 'مهيأ' : 'غير مهيأ'}`);
  
  if (client.isConfigured) {
    console.log('🎉 بيانات المصادقة صحيحة!');
  } else {
    console.log('⚠️ بيانات المصادقة غير صحيحة أو ناقصة');
  }
  
} catch (error) {
  console.error('❌ خطأ في إنشاء WaseetAPIClient:', error.message);
}

// اختبار إنشاء OrderSyncService
console.log('\n🧪 اختبار إنشاء OrderSyncService...');
try {
  const OrderSyncService = require('./services/order_sync_service');
  const service = new OrderSyncService();
  
  console.log(`✅ تم إنشاء OrderSyncService بنجاح`);
  console.log(`📊 حالة التهيئة: ${service.isInitialized ? 'مهيأ' : 'غير مهيأ'}`);
  console.log(`📊 عميل الوسيط: ${service.waseetClient ? 'موجود' : 'غير موجود'}`);
  
  if (service.waseetClient) {
    console.log(`📊 حالة عميل الوسيط: ${service.waseetClient.isConfigured ? 'مهيأ' : 'غير مهيأ'}`);
  }
  
} catch (error) {
  console.error('❌ خطأ في إنشاء OrderSyncService:', error.message);
  console.error('📋 تفاصيل الخطأ:', error.stack);
}

console.log('\n🎯 انتهى الاختبار');
