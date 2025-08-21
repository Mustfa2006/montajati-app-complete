// ===================================
// اختبار اتصال DigitalOcean
// Test DigitalOcean Connection
// ===================================

const axios = require('axios');

async function testDigitalOceanConnection() {
  console.log('🌊 === اختبار اتصال خادم DigitalOcean ===\n');

  // قائمة العناوين المحتملة لخادم DigitalOcean
  const possibleUrls = [
  'https://montajati-official-backend-production.up.railway.app', // Render (للمقارنة)
    'http://localhost:3002', // محلي
    'http://localhost:3003', // محلي بديل
    // أضف عنوان DigitalOcean هنا - يحتاج تحديث
    // مثال: 'https://montajati.your-domain.com',
    // مثال: 'http://your-server-ip:3002',
  ];

  console.log('🔍 اختبار العناوين المحتملة...\n');

  for (const url of possibleUrls) {
    try {
      console.log(`🔗 اختبار: ${url}`);
      
      const startTime = Date.now();
      const response = await axios.get(`${url}/health`, {
        timeout: 10000,
        validateStatus: () => true // قبول جميع رموز الحالة
      });
      const responseTime = Date.now() - startTime;

      if (response.status === 200) {
        console.log(`✅ ${url} - يعمل (${responseTime}ms)`);
        console.log(`   📊 البيانات:`, response.data);
        
        // اختبار endpoint مراقبة المخزون
        try {
          const inventoryTest = await axios.get(`${url}/api/inventory/test`, {
            timeout: 5000,
            validateStatus: () => true
          });
          
          if (inventoryTest.status === 200) {
            console.log(`   ✅ مراقبة المخزون: تعمل`);
          } else {
            console.log(`   ❌ مراقبة المخزون: لا تعمل (${inventoryTest.status})`);
          }
        } catch (invError) {
          console.log(`   ❌ مراقبة المخزون: خطأ في الاتصال`);
        }
        
      } else {
        console.log(`❌ ${url} - لا يعمل (${response.status})`);
      }
      
    } catch (error) {
      if (error.code === 'ECONNREFUSED') {
        console.log(`❌ ${url} - رفض الاتصال`);
      } else if (error.code === 'ENOTFOUND') {
        console.log(`❌ ${url} - العنوان غير موجود`);
      } else if (error.code === 'ETIMEDOUT') {
        console.log(`❌ ${url} - انتهت المهلة الزمنية`);
      } else {
        console.log(`❌ ${url} - خطأ: ${error.message}`);
      }
    }
    
    console.log(''); // سطر فارغ
  }

  console.log('💡 === التوصيات ===');
  console.log('1. إذا كان خادم DigitalOcean يعمل، أضف عنوانه للقائمة أعلاه');
  console.log('2. تأكد من أن الخادم يعمل على المنفذ الصحيح');
  console.log('3. تحقق من إعدادات الجدار الناري');
  console.log('4. تأكد من أن endpoints مراقبة المخزون متاحة');
}

// معلومات إضافية عن الخادم
function printServerInfo() {
  console.log('\n📋 === معلومات الخادم الحالي ===');
  console.log('🌐 المنفذ:', process.env.PORT || 3002);
  console.log('📊 البيئة:', process.env.NODE_ENV || 'development');
  console.log('📱 بوت التلغرام:', process.env.TELEGRAM_BOT_TOKEN ? 'موجود' : 'غير موجود');
  console.log('💬 كروب التلغرام:', process.env.TELEGRAM_CHAT_ID || 'غير محدد');
  console.log('🗄️ قاعدة البيانات:', process.env.SUPABASE_URL ? 'متصلة' : 'غير متصلة');
}

// تشغيل الاختبار
if (require.main === module) {
  printServerInfo();
  testDigitalOceanConnection()
    .then(() => {
      console.log('\n🎯 انتهى اختبار الاتصال');
    })
    .catch((error) => {
      console.error('❌ خطأ في اختبار الاتصال:', error);
    });
}

module.exports = { testDigitalOceanConnection };
