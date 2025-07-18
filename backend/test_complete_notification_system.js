// ===================================
// اختبار شامل لنظام الإشعارات المحدث
// ===================================

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
const TargetedNotificationService = require('./services/targeted_notification_service');
const InventoryMonitorService = require('./inventory_monitor_service');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

class CompleteNotificationTester {
  constructor() {
    this.targetedService = new TargetedNotificationService();
    this.inventoryService = new InventoryMonitorService();
  }

  async runAllTests() {
    console.log('🧪 بدء الاختبار الشامل لنظام الإشعارات المحدث...\n');

    try {
      // 1. اختبار FCM Tokens
      await this.testFCMTokens();
      
      // 2. اختبار إشعارات السحب
      await this.testWithdrawalNotifications();
      
      // 3. اختبار إشعارات المخزون
      await this.testInventoryNotifications();
      
      // 4. اختبار منع التكرار
      await this.testNotificationDuplication();

      console.log('\n🎉 انتهى الاختبار الشامل بنجاح!');

    } catch (error) {
      console.error('❌ خطأ في الاختبار الشامل:', error.message);
    }
  }

  // ===================================
  // اختبار FCM Tokens
  // ===================================
  async testFCMTokens() {
    console.log('📱 اختبار FCM Tokens...');

    try {
      // فحص FCM Tokens الموجودة
      const { data: tokens, error } = await supabase
        .from('user_fcm_tokens')
        .select('*')
        .eq('is_active', true);

      if (error) {
        console.error('❌ خطأ في جلب FCM Tokens:', error.message);
        return;
      }

      console.log(`✅ تم العثور على ${tokens?.length || 0} FCM Token نشط`);

      if (tokens && tokens.length > 0) {
        tokens.forEach(token => {
          console.log(`📱 ${token.user_phone} - ${token.platform} - ${token.fcm_token.substring(0, 20)}...`);
        });
      } else {
        console.log('⚠️ لا توجد FCM Tokens نشطة - إضافة tokens تجريبية...');
        
        // إضافة tokens تجريبية
        const testTokens = [
          {
            user_phone: '07503597589',
            fcm_token: `test_token_admin_${Date.now()}`,
            platform: 'android'
          },
          {
            user_phone: '07801234567',
            fcm_token: `test_token_user_${Date.now()}`,
            platform: 'android'
          }
        ];

        for (const testToken of testTokens) {
          const { error: insertError } = await supabase
            .from('user_fcm_tokens')
            .upsert({
              ...testToken,
              is_active: true,
              updated_at: new Date().toISOString()
            });

          if (insertError) {
            console.error(`❌ خطأ في إضافة token لـ ${testToken.user_phone}:`, insertError.message);
          } else {
            console.log(`✅ تم إضافة token لـ ${testToken.user_phone}`);
          }
        }
      }

    } catch (error) {
      console.error('❌ خطأ في اختبار FCM Tokens:', error.message);
    }

    console.log('');
  }

  // ===================================
  // اختبار إشعارات السحب
  // ===================================
  async testWithdrawalNotifications() {
    console.log('💰 اختبار إشعارات السحب...');

    try {
      // اختبار إرسال إشعار سحب للمستخدم
      const testPhone = '07503597589';
      const testRequestId = `test_withdrawal_${Date.now()}`;
      const testAmount = 100.50;

      console.log(`📤 إرسال إشعار سحب تجريبي للمستخدم ${testPhone}...`);

      const result = await this.targetedService.sendWithdrawalStatusNotification(
        testPhone,
        testRequestId,
        testAmount,
        'approved',
        ''
      );

      if (result.success) {
        console.log('✅ تم إرسال إشعار السحب بنجاح');
      } else {
        console.log('❌ فشل إرسال إشعار السحب:', result.error);
      }

    } catch (error) {
      console.error('❌ خطأ في اختبار إشعارات السحب:', error.message);
    }

    console.log('');
  }

  // ===================================
  // اختبار إشعارات المخزون
  // ===================================
  async testInventoryNotifications() {
    console.log('📦 اختبار إشعارات المخزون...');

    try {
      // محاكاة منتج بمخزون منخفض
      const testProduct = {
        id: `test_product_${Date.now()}`,
        name: 'منتج تجريبي للاختبار',
        stock: 5,
        image: 'https://example.com/test-product.jpg'
      };

      console.log(`📤 إرسال إشعار مخزون منخفض للمنتج ${testProduct.name}...`);

      // اختبار إشعار المخزون المنخفض
      const canSend = this.inventoryService.canSendNotification(testProduct.id, 'low_stock', testProduct.stock);
      
      if (canSend) {
        console.log('✅ يمكن إرسال إشعار المخزون المنخفض');
        this.inventoryService.markNotificationSent(testProduct.id, 'low_stock', testProduct.stock);
      } else {
        console.log('⏰ تم منع إرسال إشعار المخزون المنخفض (منع التكرار)');
      }

      // اختبار تغيير الكمية
      console.log('🔄 اختبار تغيير الكمية...');
      const newStock = 0;
      const canSendAfterChange = this.inventoryService.canSendNotification(testProduct.id, 'out_of_stock', newStock);
      
      if (canSendAfterChange) {
        console.log('✅ يمكن إرسال إشعار نفاد المخزون بعد تغيير الكمية');
        this.inventoryService.markNotificationSent(testProduct.id, 'out_of_stock', newStock);
      } else {
        console.log('⏰ تم منع إرسال إشعار نفاد المخزون');
      }

    } catch (error) {
      console.error('❌ خطأ في اختبار إشعارات المخزون:', error.message);
    }

    console.log('');
  }

  // ===================================
  // اختبار منع التكرار
  // ===================================
  async testNotificationDuplication() {
    console.log('🔄 اختبار منع تكرار الإشعارات...');

    try {
      const testProductId = `test_dup_${Date.now()}`;
      
      // محاولة إرسال نفس الإشعار مرتين
      console.log('📤 المحاولة الأولى...');
      const firstAttempt = this.inventoryService.canSendNotification(testProductId, 'low_stock', 5);
      console.log(`النتيجة: ${firstAttempt ? 'يمكن الإرسال' : 'لا يمكن الإرسال'}`);
      
      if (firstAttempt) {
        this.inventoryService.markNotificationSent(testProductId, 'low_stock', 5);
      }

      console.log('📤 المحاولة الثانية (نفس الكمية)...');
      const secondAttempt = this.inventoryService.canSendNotification(testProductId, 'low_stock', 5);
      console.log(`النتيجة: ${secondAttempt ? 'يمكن الإرسال' : 'لا يمكن الإرسال (منع التكرار)'}`);

      console.log('📤 المحاولة الثالثة (كمية مختلفة)...');
      const thirdAttempt = this.inventoryService.canSendNotification(testProductId, 'low_stock', 3);
      console.log(`النتيجة: ${thirdAttempt ? 'يمكن الإرسال (كمية مختلفة)' : 'لا يمكن الإرسال'}`);

      if (thirdAttempt) {
        this.inventoryService.markNotificationSent(testProductId, 'low_stock', 3);
      }

    } catch (error) {
      console.error('❌ خطأ في اختبار منع التكرار:', error.message);
    }

    console.log('');
  }
}

// تشغيل الاختبار
const tester = new CompleteNotificationTester();
tester.runAllTests();
