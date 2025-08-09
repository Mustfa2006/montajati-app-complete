/**
 * اختبار جميع أنواع الإشعارات الجديدة
 * Test All New Notification Types
 */

const { createClient } = require('@supabase/supabase-js');
const targetedNotificationService = require('./services/targeted_notification_service');

// إعداد Supabase
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

// جميع حالات الإشعارات للاختبار
const testStatuses = [
  // الحالات الأساسية
  { status: 'active', description: 'نشط' },
  { status: 'in_delivery', description: 'قيد التوصيل' },
  { status: 'delivered', description: 'تم التسليم' },
  { status: 'cancelled', description: 'ملغي' },
  
  // حالات الوسيط التفصيلية
  { status: 'فعال', description: 'فعال' },
  { status: 'قيد التوصيل الى الزبون (في عهدة المندوب)', description: 'قيد التوصيل' },
  { status: 'تم تغيير محافظة الزبون', description: 'تغيير المحافظة' },
  { status: 'لا يرد', description: 'لا يرد' },
  { status: 'لا يرد بعد الاتفاق', description: 'لا يرد بعد الاتفاق' },
  { status: 'مغلق', description: 'مغلق' },
  { status: 'مغلق بعد الاتفاق', description: 'مغلق بعد الاتفاق' },
  { status: 'مؤجل', description: 'مؤجل' },
  { status: 'مؤجل لحين اعادة الطلب لاحقا', description: 'مؤجل لاحقاً' },
  { status: 'الغاء الطلب', description: 'إلغاء الطلب' },
  { status: 'رفض الطلب', description: 'رفض الطلب' },
  { status: 'مفصول عن الخدمة', description: 'مفصول عن الخدمة' },
  { status: 'طلب مكرر', description: 'طلب مكرر' },
  { status: 'مستلم مسبقا', description: 'مستلم مسبقاً' },
  { status: 'الرقم غير معرف', description: 'رقم غير معرف' },
  { status: 'الرقم غير داخل في الخدمة', description: 'رقم خارج الخدمة' },
  { status: 'العنوان غير دقيق', description: 'عنوان غير دقيق' },
  { status: 'لم يطلب', description: 'لم يطلب' },
  { status: 'حظر المندوب', description: 'حظر المندوب' },
  { status: 'لا يمكن الاتصال بالرقم', description: 'لا يمكن الاتصال' },
  { status: 'تغيير المندوب', description: 'تغيير المندوب' }
];

async function testAllNotifications() {
  console.log('🧪 بدء اختبار جميع أنواع الإشعارات...\n');

  try {
    // 1. تهيئة خدمة الإشعارات
    console.log('1️⃣ تهيئة خدمة الإشعارات...');
    const initialized = await targetedNotificationService.initialize();
    
    if (!initialized) {
      throw new Error('فشل في تهيئة خدمة الإشعارات');
    }
    console.log('✅ تم تهيئة خدمة الإشعارات بنجاح\n');

    // 2. البحث عن مستخدم للاختبار
    console.log('2️⃣ البحث عن مستخدم للاختبار...');
    const { data: fcmTokens, error: fcmError } = await supabase
      .from('fcm_tokens')
      .select('user_phone')
      .eq('is_active', true)
      .limit(1);

    if (fcmError || !fcmTokens || fcmTokens.length === 0) {
      console.log('⚠️ لا يوجد مستخدمون للاختبار');
      return;
    }

    const testUserPhone = fcmTokens[0].user_phone;
    console.log(`📱 سيتم الاختبار مع المستخدم: ${testUserPhone}\n`);

    // 3. اختبار كل نوع من الإشعارات
    console.log('3️⃣ اختبار جميع أنواع الإشعارات...\n');
    
    let successCount = 0;
    let failCount = 0;

    for (let i = 0; i < testStatuses.length; i++) {
      const { status, description } = testStatuses[i];
      
      console.log(`📤 اختبار ${i + 1}/${testStatuses.length}: ${description}`);
      console.log(`   الحالة: ${status}`);

      try {
        const result = await targetedNotificationService.sendOrderStatusNotification(
          testUserPhone,
          `TEST-${Date.now()}-${i}`,
          status,
          'أحمد محمد (اختبار)',
          'اختبار النظام'
        );

        if (result.success) {
          console.log(`   ✅ نجح الإرسال - معرف الرسالة: ${result.messageId}`);
          successCount++;
        } else {
          console.log(`   ❌ فشل الإرسال: ${result.error}`);
          failCount++;
        }
      } catch (error) {
        console.log(`   ❌ خطأ في الإرسال: ${error.message}`);
        failCount++;
      }

      // انتظار قصير بين الإشعارات
      await new Promise(resolve => setTimeout(resolve, 1000));
      console.log('');
    }

    // 4. عرض النتائج
    console.log('📊 === نتائج الاختبار ===');
    console.log(`✅ إشعارات ناجحة: ${successCount}`);
    console.log(`❌ إشعارات فاشلة: ${failCount}`);
    console.log(`📊 معدل النجاح: ${((successCount / testStatuses.length) * 100).toFixed(1)}%`);

    // 5. فحص سجل الإشعارات
    console.log('\n5️⃣ فحص سجل الإشعارات الأخير...');
    const { data: recentLogs, error: logsError } = await supabase
      .from('notification_logs')
      .select('user_phone, title, message, success, sent_at')
      .eq('user_phone', testUserPhone)
      .order('sent_at', { ascending: false })
      .limit(5);

    if (logsError) {
      console.log(`⚠️ خطأ في جلب سجل الإشعارات: ${logsError.message}`);
    } else {
      console.log(`📋 آخر ${recentLogs.length} إشعار للمستخدم ${testUserPhone}:`);
      
      recentLogs.forEach((log, index) => {
        console.log(`   ${index + 1}. ${log.title}`);
        console.log(`      - الرسالة: ${log.message}`);
        console.log(`      - النجاح: ${log.success ? '✅' : '❌'}`);
        console.log(`      - التوقيت: ${new Date(log.sent_at).toLocaleString('ar-EG')}`);
      });
    }

    console.log('\n🎉 تم إكمال اختبار جميع الإشعارات!');

  } catch (error) {
    console.error('❌ خطأ في اختبار الإشعارات:', error.message);
    console.error('📋 تفاصيل الخطأ:', error.stack);
  }
}

// دالة اختبار إشعار واحد
async function testSingleNotification(userPhone, status, customerName = 'عميل اختبار') {
  console.log(`🧪 اختبار إشعار واحد: ${status}`);
  
  try {
    const initialized = await targetedNotificationService.initialize();
    if (!initialized) {
      throw new Error('فشل في تهيئة خدمة الإشعارات');
    }

    const result = await targetedNotificationService.sendOrderStatusNotification(
      userPhone,
      `SINGLE-TEST-${Date.now()}`,
      status,
      customerName,
      'اختبار إشعار واحد'
    );

    if (result.success) {
      console.log(`✅ تم إرسال الإشعار بنجاح`);
      console.log(`   - معرف الرسالة: ${result.messageId}`);
    } else {
      console.log(`❌ فشل إرسال الإشعار: ${result.error}`);
    }

    return result;
  } catch (error) {
    console.error(`❌ خطأ في اختبار الإشعار: ${error.message}`);
    return { success: false, error: error.message };
  }
}

// تشغيل الاختبار
if (require.main === module) {
  // التحقق من وجود معاملات سطر الأوامر للاختبار المفرد
  const args = process.argv.slice(2);
  
  if (args.length >= 2 && args[0] === 'single') {
    // اختبار إشعار واحد
    const userPhone = args[1];
    const status = args[2] || 'delivered';
    const customerName = args[3] || 'عميل اختبار';
    
    testSingleNotification(userPhone, status, customerName)
      .then(() => {
        console.log('\n✅ تم إكمال الاختبار المفرد');
        process.exit(0);
      })
      .catch((error) => {
        console.error('\n❌ فشل الاختبار المفرد:', error.message);
        process.exit(1);
      });
  } else {
    // اختبار جميع الإشعارات
    testAllNotifications()
      .then(() => {
        console.log('\n✅ تم إكمال جميع الاختبارات');
        process.exit(0);
      })
      .catch((error) => {
        console.error('\n❌ فشل الاختبارات:', error.message);
        process.exit(1);
      });
  }
}

module.exports = { testAllNotifications, testSingleNotification };
