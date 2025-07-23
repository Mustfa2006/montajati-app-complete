#!/usr/bin/env node

// ===================================
// ملف التشغيل الخاص بـ Render
// Render-specific startup file
// ===================================

const path = require('path');

// تعيين بيئة الإنتاج
process.env.NODE_ENV = 'production';

console.log('🚀 بدء النظام على Render...');
console.log('🌍 البيئة: production');
console.log('📊 متغيرات البيئة المطلوبة:');

// التحقق من متغيرات البيئة المطلوبة
const requiredEnvVars = [
  'SUPABASE_URL',
  'SUPABASE_SERVICE_ROLE_KEY', 
  'WASEET_USERNAME',
  'WASEET_PASSWORD'
];

const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);

if (missingVars.length > 0) {
  console.error('\n❌ متغيرات البيئة المطلوبة مفقودة في Render:');
  missingVars.forEach(varName => {
    console.error(`   ❌ ${varName}`);
  });
  
  console.error('\n📋 يجب إضافة هذه المتغيرات في Render Dashboard:');
  console.error('   1. اذهب إلى Render Dashboard');
  console.error('   2. اختر الخدمة (Service)');
  console.error('   3. اذهب إلى Environment');
  console.error('   4. أضف المتغيرات التالية:');
  console.error('');
  requiredEnvVars.forEach(varName => {
    console.error(`   ${varName}=your_${varName.toLowerCase()}_value`);
  });
  console.error('');
  console.error('   5. اضغط Save Changes');
  console.error('   6. أعد نشر الخدمة');
  
  process.exit(1);
}

// عرض المتغيرات الموجودة (بدون القيم الحساسة)
console.log('✅ متغيرات البيئة الموجودة:');
requiredEnvVars.forEach(varName => {
  const value = process.env[varName];
  const maskedValue = value ? `${value.substring(0, 10)}...` : 'غير موجود';
  console.log(`   ✅ ${varName}: ${maskedValue}`);
});

// متغيرات اختيارية
const optionalVars = [
  'ADMIN_PORT',
  'ADMIN_USERNAME', 
  'ADMIN_PASSWORD',
  'WEBHOOK_URL',
  'ALERT_EMAIL'
];

console.log('\n📋 متغيرات اختيارية:');
optionalVars.forEach(varName => {
  const value = process.env[varName];
  if (value) {
    const maskedValue = varName.includes('PASSWORD') ? '***' : 
                       value.length > 20 ? `${value.substring(0, 15)}...` : value;
    console.log(`   ✅ ${varName}: ${maskedValue}`);
  } else {
    console.log(`   ⚪ ${varName}: غير محدد (سيتم استخدام القيمة الافتراضية)`);
  }
});

// تعيين القيم الافتراضية للمتغيرات الاختيارية
if (!process.env.ADMIN_PORT) {
  process.env.ADMIN_PORT = process.env.PORT || '3001';
}

if (!process.env.ADMIN_USERNAME) {
  process.env.ADMIN_USERNAME = 'admin';
}

if (!process.env.ADMIN_PASSWORD) {
  process.env.ADMIN_PASSWORD = 'admin123';
}

console.log('\n⚙️ إعدادات النظام:');
console.log(`   🌐 منفذ الخادم: ${process.env.PORT || 'غير محدد'}`);
console.log(`   🖥️ منفذ الإدارة: ${process.env.ADMIN_PORT}`);
console.log(`   👤 مستخدم الإدارة: ${process.env.ADMIN_USERNAME}`);

// تشغيل النظام الرئيسي
console.log('\n🎯 تشغيل النظام الإنتاجي...');
console.log('=' * 60);

try {
  // استيراد وتشغيل النظام
  const ProductionSystem = require('./production/main');
  const AdminInterface = require('./production/admin_interface');
  
  class RenderProductionLauncher {
    constructor() {
      this.productionSystem = null;
      this.adminInterface = null;
    }

    async start() {
      try {
        console.log('🚀 بدء النظام على Render...');
        
        // بدء النظام الأساسي
        this.productionSystem = new ProductionSystem();
        await this.productionSystem.start();
        
        // بدء واجهة الإدارة على منفذ Render
        this.adminInterface = new AdminInterface(this.productionSystem);
        
        // تعديل منفذ واجهة الإدارة لـ Render
        this.adminInterface.config.port = process.env.PORT || process.env.ADMIN_PORT || 3001;
        
        await this.adminInterface.start();
        
        console.log('\n🎉 تم بدء النظام على Render بنجاح!');
        console.log('=' * 60);
        console.log('📊 الخدمات النشطة:');
        console.log('   ✅ نظام المزامنة الإنتاجي');
        console.log('   ✅ نظام المراقبة والتنبيهات');
        console.log('   ✅ نظام التسجيل المتقدم');
        console.log(`   ✅ واجهة الإدارة (المنفذ ${this.adminInterface.config.port})`);
        
        console.log('\n🎯 الوظائف المتاحة:');
        console.log('   🔄 مزامنة تلقائية كل 5 دقائق');
        console.log('   📊 مراقبة مستمرة للنظام');
        console.log('   🚨 تنبيهات فورية للمشاكل');
        console.log('   📝 تسجيل شامل للأحداث');
        console.log('   🖥️ واجهة إدارة ويب');
        
        console.log('\n🌐 الوصول للنظام:');
        console.log(`   🖥️ واجهة الإدارة: https://your-render-url.onrender.com`);
        console.log(`   👤 اسم المستخدم: ${process.env.ADMIN_USERNAME}`);
        console.log(`   🔑 كلمة المرور: ${process.env.ADMIN_PASSWORD}`);
        
        console.log('\n📊 النظام جاهز لخدمة المستخدمين!');
        console.log('=' * 60);
        
        // إبقاء العملية نشطة
        this.keepAlive();
        
      } catch (error) {
        console.error('\n💥 فشل بدء النظام على Render:');
        console.error(`❌ ${error.message}`);
        console.error('\n🔍 تحقق من:');
        console.error('   1. متغيرات البيئة في Render');
        console.error('   2. الاتصال بقاعدة البيانات');
        console.error('   3. الاتصال بشركة الوسيط');
        
        process.exit(1);
      }
    }

    keepAlive() {
      // معالجة إشارات الإيقاف
      process.on('SIGTERM', async () => {
        console.log('\n📨 تم استلام إشارة SIGTERM من Render');
        await this.stop();
        process.exit(0);
      });

      process.on('SIGINT', async () => {
        console.log('\n📨 تم استلام إشارة SIGINT');
        await this.stop();
        process.exit(0);
      });

      // معالجة الأخطاء غير المعالجة
      process.on('uncaughtException', async (error) => {
        console.error('\n💥 خطأ غير معالج على Render:');
        console.error(error);
        
        await this.stop();
        process.exit(1);
      });

      process.on('unhandledRejection', async (reason, promise) => {
        console.error('\n💥 وعد مرفوض غير معالج على Render:');
        console.error(reason);
        
        await this.stop();
        process.exit(1);
      });

      // رسالة دورية للتأكيد على أن النظام يعمل
      setInterval(() => {
        const uptime = process.uptime();
        const hours = Math.floor(uptime / 3600);
        const minutes = Math.floor((uptime % 3600) / 60);
        
        console.log(`\n💚 النظام يعمل على Render - مدة التشغيل: ${hours}س ${minutes}د`);
        console.log(`📊 الذاكرة المستخدمة: ${Math.round(process.memoryUsage().heapUsed / 1024 / 1024)}MB`);
        console.log(`🔄 آخر فحص: ${new Date().toLocaleString('ar-IQ')}`);
      }, 30 * 60 * 1000); // كل 30 دقيقة
    }

    async stop() {
      try {
        console.log('\n🛑 إيقاف النظام على Render...');
        
        if (this.adminInterface) {
          await this.adminInterface.stop();
          console.log('✅ تم إيقاف واجهة الإدارة');
        }
        
        if (this.productionSystem) {
          await this.productionSystem.stop();
          console.log('✅ تم إيقاف النظام الأساسي');
        }
        
        console.log('\n✅ تم إيقاف النظام على Render بنجاح');
        
      } catch (error) {
        console.error(`❌ خطأ في إيقاف النظام: ${error.message}`);
      }
    }
  }

  // تشغيل النظام
  const launcher = new RenderProductionLauncher();
  launcher.start();

} catch (error) {
  console.error('\n💥 فشل تشغيل النظام على Render:', error.message);
  console.error('📋 تحقق من الكود والتبعيات');
  process.exit(1);
}

module.exports = RenderProductionLauncher;
