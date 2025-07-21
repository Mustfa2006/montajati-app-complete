// ===================================
// اختبار عميل الويب للوسيط
// ===================================

const WaseetWebClient = require('./backend/services/waseet_web_client');
require('dotenv').config();

async function testWaseetWebClient() {
  console.log('🌐 اختبار عميل الويب للوسيط...\n');
  
  const username = process.env.WASEET_USERNAME;
  const password = process.env.WASEET_PASSWORD;
  
  console.log(`👤 المستخدم: ${username}`);
  
  const client = new WaseetWebClient(username, password);
  
  try {
    // محاولة تسجيل الدخول
    console.log('\n🔐 محاولة تسجيل الدخول...');
    const loginSuccess = await client.login();
    
    if (loginSuccess) {
      console.log('✅ تم تسجيل الدخول بنجاح!');
      
      // محاولة جلب الطلبات
      console.log('\n📦 محاولة جلب الطلبات...');
      const orders = await client.getOrders();
      
      if (orders) {
        console.log(`📊 تم جلب ${orders.length} طلب`);
        
        if (orders.length > 0) {
          console.log('\n📋 عينة من الطلبات:');
          orders.slice(0, 3).forEach((order, index) => {
            console.log(`${index + 1}. ${JSON.stringify(order, null, 2)}`);
          });
        }
      } else {
        console.log('⚠️ لم يتم جلب الطلبات');
      }
      
    } else {
      console.log('❌ فشل في تسجيل الدخول');
    }
    
  } catch (error) {
    console.error('❌ خطأ في الاختبار:', error.message);
  }
}

testWaseetWebClient();
