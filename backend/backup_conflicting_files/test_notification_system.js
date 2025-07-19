// ===================================
// اختبار نظام الإشعارات المحسن
// ===================================

require('dotenv').config();
const TargetedNotificationService = require('./services/targeted_notification_service');

async function testNotificationSystem() {
  console.log('🔔 اختبار نظام الإشعارات المحسن...');
  
  try {
    const notificationService = new TargetedNotificationService();
    
    // معرف مستخدم تجريبي (استخدم معرف مستخدم حقيقي من قاعدة البيانات)
    const testUserId = '3879219d-7b4a-4d00-bca2-f49936bf72a4';
    
    console.log('\n📱 اختبار إشعار حالة الطلب...');
    
    // اختبار إشعار حالة الطلب
    const orderResult = await notificationService.sendOrderStatusNotification(
      testUserId,
      'test-order-123',
      'تم التسليم',
      'عميل تجريبي'
    );
    
    console.log('نتيجة إشعار الطلب:', orderResult);
    
    console.log('\n💰 اختبار إشعار حالة السحب...');
    
    // اختبار إشعار حالة السحب
    const withdrawalResult = await notificationService.sendWithdrawalStatusNotification(
      testUserId,
      'test-withdrawal-456',
      150.75,
      'approved',
      'تم الموافقة على طلب السحب'
    );
    
    console.log('نتيجة إشعار السحب:', withdrawalResult);
    
    console.log('\n🔍 اختبار البحث عن FCM Token بديل...');
    
    // اختبار البحث عن FCM Token بديل
    const alternativeToken = await notificationService.getAlternativeFCMToken(testUserId);
    
    if (alternativeToken) {
      console.log('✅ تم العثور على FCM Token بديل:', alternativeToken.substring(0, 50) + '...');
    } else {
      console.log('❌ لم يتم العثور على FCM Token بديل');
    }
    
    console.log('\n📊 اختبار الحصول على FCM Token العادي...');
    
    // اختبار الحصول على FCM Token العادي
    const normalToken = await notificationService.getUserFCMToken(testUserId);
    
    if (normalToken) {
      console.log('✅ تم العثور على FCM Token عادي:', normalToken.substring(0, 50) + '...');
    } else {
      console.log('❌ لم يتم العثور على FCM Token عادي');
    }
    
    console.log('\n✅ انتهى اختبار نظام الإشعارات');
    
  } catch (error) {
    console.error('❌ خطأ في اختبار نظام الإشعارات:', error.message);
    console.error('التفاصيل:', error);
  }
}

// تشغيل الاختبار
testNotificationSystem();
