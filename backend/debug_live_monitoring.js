// ===================================
// مراقبة مباشرة لتشخيص المشكلة
// Live Monitoring for Issue Diagnosis
// ===================================

const { createClient } = require('@supabase/supabase-js');
const InventoryMonitorService = require('./inventory_monitor_service');
const TelegramNotificationService = require('./telegram_notification_service');
require('dotenv').config();

class LiveMonitoringDebugger {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
    
    this.inventoryMonitor = new InventoryMonitorService();
    this.telegramService = new TelegramNotificationService();
    
    // تتبع آخر حالة للمنتجات
    this.lastProductStates = new Map();
    
    console.log('🔍 === مراقب التشخيص المباشر ===');
    console.log('📱 البوت:', process.env.TELEGRAM_BOT_TOKEN ? 'موجود' : 'غير موجود');
    console.log('💬 الكروب:', process.env.TELEGRAM_CHAT_ID);
  }

  // فحص شامل للنظام
  async performSystemCheck() {
    console.log('\n🔧 === فحص شامل للنظام ===');
    
    // 1. فحص التلغرام
    console.log('\n📱 1. فحص التلغرام...');
    const telegramTest = await this.telegramService.testConnection();
    
    if (telegramTest.success) {
      console.log('✅ التلغرام متصل:', telegramTest.botInfo.username);
      
      // اختبار إرسال رسالة
      const testMsg = await this.telegramService.sendMessage(
        '🔍 بدء مراقبة مباشرة للنظام\n\n⏰ ' + new Date().toLocaleString('ar-EG')
      );
      
      if (testMsg.success) {
        console.log('✅ تم إرسال رسالة اختبار بنجاح');
      } else {
        console.log('❌ فشل إرسال رسالة اختبار:', testMsg.error);
      }
    } else {
      console.log('❌ فشل اتصال التلغرام:', telegramTest.error);
      return false;
    }

    // 2. فحص قاعدة البيانات
    console.log('\n📊 2. فحص قاعدة البيانات...');
    try {
      const { data: products, error } = await this.supabase
        .from('products')
        .select('id, name, available_quantity, is_active, updated_at')
        .eq('is_active', true)
        .order('updated_at', { ascending: false });

      if (error) {
        console.log('❌ خطأ في قاعدة البيانات:', error.message);
        return false;
      }

      console.log(`✅ قاعدة البيانات تعمل - ${products.length} منتج نشط`);
      
      // عرض آخر المنتجات المحدثة
      console.log('\n📋 آخر المنتجات المحدثة:');
      products.slice(0, 5).forEach((product, index) => {
        const updateTime = new Date(product.updated_at).toLocaleString('ar-EG');
        console.log(`${index + 1}. ${product.name} - الكمية: ${product.available_quantity} - آخر تحديث: ${updateTime}`);
      });

      // حفظ الحالة الحالية
      products.forEach(product => {
        this.lastProductStates.set(product.id, {
          name: product.name,
          quantity: product.available_quantity,
          lastUpdate: product.updated_at
        });
      });

    } catch (error) {
      console.log('❌ خطأ في الاتصال بقاعدة البيانات:', error.message);
      return false;
    }

    return true;
  }

  // مراقبة التغييرات المباشرة
  async monitorChanges() {
    console.log('\n🔄 === بدء مراقبة التغييرات المباشرة ===');
    console.log('⏰ فحص كل 10 ثوان...');
    console.log('💡 غير كمية منتج في التطبيق وراقب النتائج هنا\n');

    let checkCount = 0;

    const monitorInterval = setInterval(async () => {
      try {
        checkCount++;
        console.log(`🔍 فحص #${checkCount} - ${new Date().toLocaleString('ar-EG')}`);

        // جلب المنتجات الحالية
        const { data: currentProducts, error } = await this.supabase
          .from('products')
          .select('id, name, available_quantity, is_active, updated_at')
          .eq('is_active', true);

        if (error) {
          console.log('❌ خطأ في جلب المنتجات:', error.message);
          return;
        }

        // فحص التغييرات
        const changes = [];
        
        for (const product of currentProducts) {
          const lastState = this.lastProductStates.get(product.id);
          
          if (!lastState) {
            // منتج جديد
            changes.push({
              type: 'new',
              product: product,
              message: `منتج جديد: ${product.name} - الكمية: ${product.available_quantity}`
            });
          } else if (lastState.quantity !== product.available_quantity) {
            // تغيير في الكمية
            changes.push({
              type: 'quantity_change',
              product: product,
              oldQuantity: lastState.quantity,
              newQuantity: product.available_quantity,
              message: `تغيير كمية: ${product.name} من ${lastState.quantity} إلى ${product.available_quantity}`
            });
          } else if (lastState.lastUpdate !== product.updated_at) {
            // تحديث بدون تغيير كمية
            changes.push({
              type: 'update',
              product: product,
              message: `تحديث: ${product.name} - الكمية: ${product.available_quantity}`
            });
          }

          // تحديث الحالة المحفوظة
          this.lastProductStates.set(product.id, {
            name: product.name,
            quantity: product.available_quantity,
            lastUpdate: product.updated_at
          });
        }

        // عرض التغييرات
        if (changes.length > 0) {
          console.log(`\n🚨 تم اكتشاف ${changes.length} تغيير:`);
          
          for (const change of changes) {
            console.log(`   ${change.message}`);
            
            // إذا كان تغيير في الكمية، اختبر المراقبة
            if (change.type === 'quantity_change') {
              console.log(`\n🔍 اختبار مراقبة المنتج: ${change.product.name}`);
              
              const monitorResult = await this.inventoryMonitor.monitorProduct(change.product.id);
              
              if (monitorResult.success) {
                console.log(`✅ نجحت المراقبة - الحالة: ${monitorResult.product.status}`);
                
                if (monitorResult.alerts && monitorResult.alerts.length > 0) {
                  monitorResult.alerts.forEach(alert => {
                    console.log(`🚨 تنبيه: ${alert.type} - ${alert.sent ? 'تم الإرسال ✅' : 'فشل الإرسال ❌'}`);
                    
                    if (!alert.sent) {
                      console.log(`❌ سبب فشل الإرسال: ${alert.reason || 'غير محدد'}`);
                    }
                  });
                } else {
                  console.log('📭 لا توجد تنبيهات (ربما تم إرسالها مؤخراً)');
                }
              } else {
                console.log(`❌ فشلت المراقبة: ${monitorResult.error}`);
              }
            }
          }
          
          console.log(''); // سطر فارغ
        } else {
          process.stdout.write('.');
        }

      } catch (error) {
        console.error(`❌ خطأ في مراقبة التغييرات: ${error.message}`);
      }
    }, 10000); // كل 10 ثوان

    // إيقاف المراقبة بعد 10 دقائق
    setTimeout(() => {
      clearInterval(monitorInterval);
      console.log('\n⏰ انتهت فترة المراقبة (10 دقائق)');
      console.log('🎯 لإعادة التشغيل: node debug_live_monitoring.js');
      process.exit(0);
    }, 10 * 60 * 1000);
  }

  // اختبار إرسال إشعار مباشر
  async testDirectAlert() {
    console.log('\n🧪 === اختبار إرسال إشعار مباشر ===');
    
    // إشعار نفاد مخزون
    console.log('🚨 اختبار إشعار نفاد المخزون...');
    const outOfStockResult = await this.telegramService.sendOutOfStockAlert({
      productId: 'test-id',
      productName: 'منتج اختبار مباشر',
      productImage: null
    });
    
    if (outOfStockResult.success) {
      console.log('✅ تم إرسال إشعار نفاد المخزون');
    } else {
      console.log('❌ فشل إرسال إشعار نفاد المخزون:', outOfStockResult.error);
    }

    // إشعار مخزون منخفض
    console.log('⚠️ اختبار إشعار مخزون منخفض...');
    const lowStockResult = await this.telegramService.sendLowStockAlert({
      productId: 'test-id',
      productName: 'منتج اختبار مباشر',
      currentStock: 5,
      productImage: null
    });
    
    if (lowStockResult.success) {
      console.log('✅ تم إرسال إشعار مخزون منخفض');
    } else {
      console.log('❌ فشل إرسال إشعار مخزون منخفض:', lowStockResult.error);
    }
  }

  // تشغيل التشخيص الكامل
  async run() {
    try {
      // فحص النظام
      const systemOk = await this.performSystemCheck();
      
      if (!systemOk) {
        console.log('❌ فشل فحص النظام - توقف التشخيص');
        return;
      }

      // اختبار إرسال إشعار مباشر
      await this.testDirectAlert();

      // بدء مراقبة التغييرات
      await this.monitorChanges();

    } catch (error) {
      console.error('❌ خطأ في التشخيص:', error.message);
    }
  }
}

// تشغيل المراقب
if (require.main === module) {
  const monitor = new LiveMonitoringDebugger();
  monitor.run();
}

module.exports = LiveMonitoringDebugger;
