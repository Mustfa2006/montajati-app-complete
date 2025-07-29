/**
 * اختبار إشعارات السحب الجديدة
 * Test New Withdrawal Notifications
 */

const { createClient } = require('@supabase/supabase-js');
const targetedNotificationService = require('./services/targeted_notification_service');

// إعداد Supabase
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

// حالات السحب للاختبار
const withdrawalTestCases = [
  {
    status: 'processed',
    amount: '50000',
    description: 'تحويل المبلغ - قلب ذهبي',
    expectedTitle: '💛💛💛 قلب ذهبي',
    expectedMessage: 'تم تحويل مبلغ 50000 د.ع الى محفظتك'
  },
  {
    status: 'completed',
    amount: '75000',
    description: 'تحويل المبلغ - قلب ذهبي (completed)',
    expectedTitle: '💛💛💛 قلب ذهبي',
    expectedMessage: 'تم تحويل مبلغ 75000 د.ع الى محفظتك'
  },
  {
    status: 'rejected',
    amount: '30000',
    description: 'رفض السحب - قلب مكسور',
    expectedTitle: '💔💔💔 قلب مكسور',
    expectedMessage: 'تم الغاء عملية سحبك 30000 د.ع'
  },
  {
    status: 'cancelled',
    amount: '25000',
    description: 'إلغاء السحب - قلب مكسور',
    expectedTitle: '💔💔💔 قلب مكسور',
    expectedMessage: 'تم الغاء عملية سحبك 25000 د.ع'
  },
  {
    status: 'pending',
    amount: '40000',
    description: 'في انتظار المراجعة',
    expectedTitle: '💰 تحديث طلب السحب',
    expectedMessage: 'تم تحديث حالة طلب سحب 40000 د.ع إلى: في انتظار المراجعة'
  },
  {
    status: 'approved',
    amount: '60000',
    description: 'تم الموافقة',
    expectedTitle: '💰 تحديث طلب السحب',
    expectedMessage: 'تم تحديث حالة طلب سحب 60000 د.ع إلى: تم الموافقة'
  }
];

async function testWithdrawalNotifications() {
  console.log('🧪 بدء اختبار إشعارات السحب الجديدة...\n');

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

    // 3. اختبار جميع حالات السحب
    console.log('3️⃣ اختبار جميع حالات السحب...\n');
    
    let successCount = 0;
    let failCount = 0;

    for (let i = 0; i < withdrawalTestCases.length; i++) {
      const testCase = withdrawalTestCases[i];
      
      console.log(`📤 اختبار ${i + 1}/${withdrawalTestCases.length}: ${testCase.description}`);
      console.log(`   الحالة: ${testCase.status}`);
      console.log(`   المبلغ: ${testCase.amount} د.ع`);
      console.log(`   العنوان المتوقع: ${testCase.expectedTitle}`);
      console.log(`   الرسالة المتوقعة: ${testCase.expectedMessage}`);

      try {
        const result = await targetedNotificationService.sendWithdrawalStatusNotification(
          testUserPhone,
          `WD-TEST-${Date.now()}-${i}`,
          testCase.amount,
          testCase.status,
          'اختبار إشعارات السحب الجديدة'
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
      await new Promise(resolve => setTimeout(resolve, 2000));
      console.log('');
    }

    // 4. عرض النتائج
    console.log('📊 === نتائج اختبار إشعارات السحب ===');
    console.log(`✅ إشعارات ناجحة: ${successCount}`);
    console.log(`❌ إشعارات فاشلة: ${failCount}`);
    console.log(`📊 معدل النجاح: ${((successCount / withdrawalTestCases.length) * 100).toFixed(1)}%`);

    // 5. فحص سجل الإشعارات
    console.log('\n5️⃣ فحص سجل إشعارات السحب الأخيرة...');
    const { data: recentLogs, error: logsError } = await supabase
      .from('notification_logs')
      .select('user_phone, title, message, success, sent_at')
      .eq('user_phone', testUserPhone)
      .eq('notification_type', 'withdrawal_status_update')
      .order('sent_at', { ascending: false })
      .limit(6);

    if (logsError) {
      console.log(`⚠️ خطأ في جلب سجل الإشعارات: ${logsError.message}`);
    } else {
      console.log(`📋 آخر ${recentLogs.length} إشعار سحب للمستخدم ${testUserPhone}:`);
      
      recentLogs.forEach((log, index) => {
        console.log(`   ${index + 1}. ${log.title}`);
        console.log(`      - الرسالة: ${log.message}`);
        console.log(`      - النجاح: ${log.success ? '✅' : '❌'}`);
        console.log(`      - التوقيت: ${new Date(log.sent_at).toLocaleString('ar-EG')}`);
      });
    }

    console.log('\n🎉 تم إكمال اختبار إشعارات السحب!');

  } catch (error) {
    console.error('❌ خطأ في اختبار إشعارات السحب:', error.message);
    console.error('📋 تفاصيل الخطأ:', error.stack);
  }
}

// دالة اختبار إشعار سحب واحد
async function testSingleWithdrawalNotification(userPhone, status, amount) {
  console.log(`🧪 اختبار إشعار سحب واحد: ${status} - ${amount} د.ع`);
  
  try {
    const initialized = await targetedNotificationService.initialize();
    if (!initialized) {
      throw new Error('فشل في تهيئة خدمة الإشعارات');
    }

    const result = await targetedNotificationService.sendWithdrawalStatusNotification(
      userPhone,
      `SINGLE-WD-TEST-${Date.now()}`,
      amount,
      status,
      'اختبار إشعار سحب واحد'
    );

    if (result.success) {
      console.log(`✅ تم إرسال إشعار السحب بنجاح`);
      console.log(`   - معرف الرسالة: ${result.messageId}`);
    } else {
      console.log(`❌ فشل إرسال إشعار السحب: ${result.error}`);
    }

    return result;
  } catch (error) {
    console.error(`❌ خطأ في اختبار إشعار السحب: ${error.message}`);
    return { success: false, error: error.message };
  }
}

// تشغيل الاختبار
if (require.main === module) {
  // التحقق من وجود معاملات سطر الأوامر للاختبار المفرد
  const args = process.argv.slice(2);
  
  if (args.length >= 3 && args[0] === 'single') {
    // اختبار إشعار سحب واحد
    const userPhone = args[1];
    const status = args[2];
    const amount = args[3] || '50000';
    
    testSingleWithdrawalNotification(userPhone, status, amount)
      .then(() => {
        console.log('\n✅ تم إكمال اختبار السحب المفرد');
        process.exit(0);
      })
      .catch((error) => {
        console.error('\n❌ فشل اختبار السحب المفرد:', error.message);
        process.exit(1);
      });
  } else {
    // اختبار جميع إشعارات السحب
    testWithdrawalNotifications()
      .then(() => {
        console.log('\n✅ تم إكمال جميع اختبارات السحب');
        process.exit(0);
      })
      .catch((error) => {
        console.error('\n❌ فشل اختبارات السحب:', error.message);
        process.exit(1);
      });
  }
}

module.exports = { testWithdrawalNotifications, testSingleWithdrawalNotification };
