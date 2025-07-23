#!/usr/bin/env node

// ===================================
// ملف التشغيل الرئيسي للنظام الإنتاجي
// Main Production System Launcher
// ===================================

const path = require('path');
const fs = require('fs');

// التأكد من وجود ملف .env (في التطوير فقط)
const envPath = path.join(__dirname, '.env');
if (!fs.existsSync(envPath) && process.env.NODE_ENV !== 'production') {
  console.error('❌ ملف .env غير موجود');
  console.error('📋 أنشئ ملف .env مع المتغيرات المطلوبة:');
  console.error('   SUPABASE_URL=your_supabase_url');
  console.error('   SUPABASE_SERVICE_ROLE_KEY=your_service_role_key');
  console.error('   WASEET_USERNAME=your_waseet_username');
  console.error('   WASEET_PASSWORD=your_waseet_password');
  process.exit(1);
}

// تحميل متغيرات البيئة (إذا كان ملف .env موجود)
if (fs.existsSync(envPath)) {
  require('dotenv').config();
}

// استيراد النظام الإنتاجي
const ProductionSystem = require('./production/main');
const AdminInterface = require('./production/admin_interface');
const config = require('./production/config');

class MontajatiProductionLauncher {
  constructor() {
    this.productionSystem = null;
    this.adminInterface = null;
    this.isRunning = false;
    
    console.log('🚀 مشغل النظام الإنتاجي لمزامنة حالات الطلبات');
    console.log('   Montajati Production System Launcher');
  }

  /**
   * بدء النظام الكامل
   */
  async start() {
    try {
      console.log('\n🎯 بدء النظام الإنتاجي الكامل...');
      console.log('=' * 60);
      
      // بدء النظام الأساسي
      this.productionSystem = new (require('./production/main'))();
      await this.productionSystem.start();
      
      // بدء واجهة الإدارة
      if (config.get('admin', 'enabled')) {
        this.adminInterface = new AdminInterface(this.productionSystem);
        await this.adminInterface.start();
      }
      
      this.isRunning = true;
      
      console.log('\n🎉 تم بدء النظام الكامل بنجاح!');
      console.log('=' * 60);
      console.log('📊 الخدمات النشطة:');
      console.log('   ✅ نظام المزامنة الإنتاجي');
      console.log('   ✅ نظام المراقبة والتنبيهات');
      console.log('   ✅ نظام التسجيل المتقدم');
      
      if (this.adminInterface) {
        console.log(`   ✅ واجهة الإدارة (المنفذ ${config.get('admin', 'port')})`);
        console.log(`\n🖥️ واجهة الإدارة: http://localhost:${config.get('admin', 'port')}`);
        console.log(`👤 اسم المستخدم: ${config.get('admin', 'username')}`);
        console.log(`🔑 كلمة المرور: ${config.get('admin', 'password')}`);
      }
      
      console.log('\n🎯 الوظائف المتاحة:');
      console.log('   🔄 مزامنة تلقائية كل 5 دقائق');
      console.log('   📊 مراقبة مستمرة للنظام');
      console.log('   🚨 تنبيهات فورية للمشاكل');
      console.log('   📝 تسجيل شامل للأحداث');
      console.log('   🖥️ واجهة إدارة ويب');
      
      console.log('\n📋 للمراقبة والتحكم:');
      console.log('   📊 السجلات: backend/logs/');
      console.log('   🖥️ واجهة الإدارة للتحكم الكامل');
      console.log('   📈 مراقبة الأداء في قاعدة البيانات');
      
      console.log('\n⏹️ لإيقاف النظام: اضغط Ctrl+C');
      console.log('=' * 60);
      
      // إبقاء العملية نشطة
      this.keepAlive();
      
    } catch (error) {
      console.error('\n💥 فشل بدء النظام الكامل:');
      console.error(`❌ ${error.message}`);
      console.error('\n🔍 تحقق من:');
      console.error('   1. ملف .env وصحة المتغيرات');
      console.error('   2. الاتصال بقاعدة البيانات');
      console.error('   3. الاتصال بشركة الوسيط');
      console.error('   4. المنافذ المتاحة');
      console.error('\n📋 راجع السجلات للمزيد من التفاصيل');
      
      process.exit(1);
    }
  }

  /**
   * إيقاف النظام الكامل
   */
  async stop() {
    if (!this.isRunning) {
      return;
    }

    try {
      console.log('\n🛑 إيقاف النظام الكامل...');
      
      // إيقاف واجهة الإدارة
      if (this.adminInterface) {
        await this.adminInterface.stop();
        console.log('✅ تم إيقاف واجهة الإدارة');
      }
      
      // إيقاف النظام الأساسي
      if (this.productionSystem) {
        await this.productionSystem.stop();
        console.log('✅ تم إيقاف النظام الأساسي');
      }
      
      this.isRunning = false;
      
      console.log('\n✅ تم إيقاف النظام الكامل بنجاح');
      console.log('👋 شكراً لاستخدام نظام مزامنة الطلبات');
      
    } catch (error) {
      console.error(`❌ خطأ في إيقاف النظام: ${error.message}`);
    }
  }

  /**
   * إبقاء العملية نشطة
   */
  keepAlive() {
    // معالجة إشارات الإيقاف
    process.on('SIGTERM', async () => {
      console.log('\n📨 تم استلام إشارة SIGTERM');
      await this.stop();
      process.exit(0);
    });

    process.on('SIGINT', async () => {
      console.log('\n📨 تم استلام إشارة SIGINT (Ctrl+C)');
      await this.stop();
      process.exit(0);
    });

    // معالجة الأخطاء غير المعالجة
    process.on('uncaughtException', async (error) => {
      console.error('\n💥 خطأ غير معالج:');
      console.error(error);
      
      await this.stop();
      process.exit(1);
    });

    process.on('unhandledRejection', async (reason, promise) => {
      console.error('\n💥 وعد مرفوض غير معالج:');
      console.error(reason);
      
      await this.stop();
      process.exit(1);
    });

    // رسالة دورية للتأكيد على أن النظام يعمل
    setInterval(() => {
      const uptime = process.uptime();
      const hours = Math.floor(uptime / 3600);
      const minutes = Math.floor((uptime % 3600) / 60);
      
      console.log(`\n💚 النظام يعمل بشكل طبيعي - مدة التشغيل: ${hours}س ${minutes}د`);
      console.log(`📊 الذاكرة المستخدمة: ${Math.round(process.memoryUsage().heapUsed / 1024 / 1024)}MB`);
      console.log(`🔄 آخر فحص: ${new Date().toLocaleString('ar-IQ')}`);
    }, 30 * 60 * 1000); // كل 30 دقيقة
  }

  /**
   * عرض معلومات النظام
   */
  displaySystemInfo() {
    const systemInfo = config.getSystemInfo();
    
    console.log('\n📊 معلومات النظام:');
    console.log('=' * 40);
    console.log(`📋 النظام: ${systemInfo.name}`);
    console.log(`🔢 الإصدار: ${systemInfo.version}`);
    console.log(`🌍 البيئة: ${systemInfo.environment}`);
    console.log(`🖥️ المنصة: ${systemInfo.platform}`);
    console.log(`⚡ Node.js: ${systemInfo.nodeVersion}`);
    console.log(`🆔 معرف العملية: ${systemInfo.pid}`);
    console.log(`💾 الذاكرة: ${Math.round(systemInfo.memory.heapUsed / 1024 / 1024)}MB`);
    console.log('=' * 40);
  }

  /**
   * فحص المتطلبات
   */
  checkRequirements() {
    console.log('🔍 فحص المتطلبات...');
    
    // فحص Node.js version
    const nodeVersion = process.version;
    const majorVersion = parseInt(nodeVersion.slice(1).split('.')[0]);
    
    if (majorVersion < 14) {
      console.error(`❌ إصدار Node.js غير مدعوم: ${nodeVersion}`);
      console.error('📋 يتطلب Node.js 14 أو أحدث');
      process.exit(1);
    }
    
    // فحص متغيرات البيئة المطلوبة
    const requiredEnvVars = [
      'SUPABASE_URL',
      'SUPABASE_SERVICE_ROLE_KEY',
      'WASEET_USERNAME',
      'WASEET_PASSWORD'
    ];

    const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);
    
    if (missingVars.length > 0) {
      console.error('❌ متغيرات البيئة المطلوبة مفقودة:');
      missingVars.forEach(varName => {
        console.error(`   - ${varName}`);
      });
      console.error('\n📋 أضف هذه المتغيرات إلى ملف .env');
      process.exit(1);
    }
    
    console.log('✅ جميع المتطلبات متوفرة');
  }
}

// تشغيل النظام
async function main() {
  try {
    const launcher = new MontajatiProductionLauncher();
    
    // عرض معلومات النظام
    launcher.displaySystemInfo();
    
    // فحص المتطلبات
    launcher.checkRequirements();
    
    // بدء النظام
    await launcher.start();
    
  } catch (error) {
    console.error('💥 فشل تشغيل النظام:', error.message);
    process.exit(1);
  }
}

// تشغيل النظام إذا تم استدعاء الملف مباشرة
if (require.main === module) {
  main();
}

module.exports = MontajatiProductionLauncher;
