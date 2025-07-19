#!/usr/bin/env node

// ===================================
// تنظيف الملفات المتضاربة والاحتفاظ بالأساسية فقط
// ===================================

const fs = require('fs');
const path = require('path');

class FileCleanup {
  constructor() {
    this.backupDir = './backup_conflicting_files';
    
    // الملفات الأساسية المطلوبة لنظام الإشعارات
    this.essentialFiles = [
      // الملفات الأساسية
      'package.json',
      'package-lock.json',
      '.env',
      'server.js',
      
      // نظام الإشعارات الأساسي
      'notification_processor_simple.js',
      'routes/fcm_tokens.js',
      'database/smart_notification_trigger.sql',
      
      // التشغيل
      'start_system_complete.js',
      'start_notifications_final.js',
      'simple_server.js',
      
      // الإعدادات
      'config/firebase.js',
      'config/supabase.js',
      
      // المسارات الأساسية
      'routes/orders.js',
      'routes/users.js',
      'routes/products.js',
      'routes/auth.js',
      
      // الاختبار الأساسي
      'quick_test_system.js',
      'production_readiness_check.js',
      
      // الأدلة المهمة
      'SYSTEM_READY_REPORT.md',
      'SIMPLE_NOTIFICATIONS_GUIDE.md',
      'DEPLOYMENT_GUIDE_FINAL.md'
    ];

    // الملفات المتضاربة التي يجب نقلها
    this.conflictingFiles = [
      // ملفات إشعارات متعددة ومتضاربة
      'official_real_notification_system.js',
      'run_real_notification_system.js',
      'setup_real_fcm_token.js',
      'test_real_notification_with_demo_token.js',
      
      // خدمات إشعارات متعددة
      'services/official_firebase_notification_service.js',
      'services/notification_master_service.js',
      'services/smart_notification_processor.js',
      'services/targeted_notification_service.js',
      
      // ملفات اختبار متعددة
      'test_notification_system.js',
      'test_notification_system_simple.js',
      'test_complete_notification_system.js',
      'test_official_notifications.js',
      'test_real_notification.js',
      'test_system_complete.js',
      
      // ملفات إعداد متعددة
      'setup_database_complete.js',
      'setup_firebase_complete.js',
      'setup_smart_notifications.js',
      
      // ملفات تشغيل متعددة
      'start_notification_system_final.js',
      'start_official_notification_system.js',
      'start_smart_notification_system.js',
      
      // ملفات render متعددة
      'render-start.js',
      'render-start-clean.js',
      'render_firebase_check.js',
      'render_firebase_diagnostic.js',
      
      // أدلة متعددة
      'DEPLOYMENT_STATUS.md',
      'FIREBASE_RENDER_SETUP.md',
      'FIREBASE_TROUBLESHOOTING.md',
      'NOTIFICATION_SYSTEM_COMPLETE.md',
      'PRODUCTION_GUIDE.md',
      'README_COMPLETE.md',
      'RENDER_FIREBASE_TROUBLESHOOTING.md',
      'RENDER_SETUP.md',
      'SMART_NOTIFICATIONS_README.md',
      'TELEGRAM_SETUP_GUIDE.md',
      
      // ملفات debug متعددة
      'debug-firebase.js',
      'debug_service_account.js',
      'debug_waseet_login.js',
      'check_firebase_vars.js',
      'extract_firebase_vars.js',
      'get_render_firebase_vars.js',
      
      // ملفات تطبيق متعددة
      'apply-database-updates.js',
      'apply_notification_schema.js',
      'create_notification_tables_direct.js',
      
      // خدمات إضافية
      'telegram_notification_service.js',
      'inventory_monitor_service.js',
      'performance-optimizations.js'
    ];
  }

  // ===================================
  // تشغيل التنظيف
  // ===================================
  async cleanup() {
    try {
      console.log('🧹 بدء تنظيف الملفات المتضاربة...\n');

      // إنشاء مجلد النسخ الاحتياطي
      await this.createBackupDir();

      // نقل الملفات المتضاربة
      await this.moveConflictingFiles();

      // عرض الملفات الأساسية المتبقية
      await this.showEssentialFiles();

      console.log('\n✅ تم تنظيف الملفات بنجاح!');
      console.log('📁 الملفات المتضاربة محفوظة في:', this.backupDir);
      console.log('🎯 النظام الآن يحتوي على الملفات الأساسية فقط');

    } catch (error) {
      console.error('❌ خطأ في التنظيف:', error.message);
    }
  }

  // ===================================
  // إنشاء مجلد النسخ الاحتياطي
  // ===================================
  async createBackupDir() {
    if (!fs.existsSync(this.backupDir)) {
      fs.mkdirSync(this.backupDir, { recursive: true });
      console.log('📁 تم إنشاء مجلد النسخ الاحتياطي');
    }
  }

  // ===================================
  // نقل الملفات المتضاربة
  // ===================================
  async moveConflictingFiles() {
    let movedCount = 0;

    for (const filePath of this.conflictingFiles) {
      const fullPath = path.join(__dirname, filePath);
      
      if (fs.existsSync(fullPath)) {
        try {
          const backupPath = path.join(this.backupDir, filePath);
          const backupDir = path.dirname(backupPath);
          
          // إنشاء المجلد في النسخة الاحتياطية
          if (!fs.existsSync(backupDir)) {
            fs.mkdirSync(backupDir, { recursive: true });
          }
          
          // نقل الملف
          fs.renameSync(fullPath, backupPath);
          console.log(`📦 تم نقل: ${filePath}`);
          movedCount++;
          
        } catch (error) {
          console.log(`⚠️ تعذر نقل: ${filePath} - ${error.message}`);
        }
      }
    }

    console.log(`\n📊 تم نقل ${movedCount} ملف متضارب`);
  }

  // ===================================
  // عرض الملفات الأساسية المتبقية
  // ===================================
  async showEssentialFiles() {
    console.log('\n📋 الملفات الأساسية المتبقية:');
    console.log('═══════════════════════════════════');

    let existingCount = 0;
    let missingCount = 0;

    for (const filePath of this.essentialFiles) {
      const fullPath = path.join(__dirname, filePath);
      
      if (fs.existsSync(fullPath)) {
        console.log(`✅ ${filePath}`);
        existingCount++;
      } else {
        console.log(`❌ ${filePath} - مفقود`);
        missingCount++;
      }
    }

    console.log('═══════════════════════════════════');
    console.log(`📊 موجود: ${existingCount} | مفقود: ${missingCount}`);

    if (missingCount > 0) {
      console.log('\n⚠️ بعض الملفات الأساسية مفقودة!');
      console.log('💡 تأكد من وجود هذه الملفات لضمان عمل النظام');
    }
  }

  // ===================================
  // استعادة ملف معين
  // ===================================
  async restoreFile(filePath) {
    try {
      const backupPath = path.join(this.backupDir, filePath);
      const originalPath = path.join(__dirname, filePath);
      
      if (fs.existsSync(backupPath)) {
        fs.renameSync(backupPath, originalPath);
        console.log(`✅ تم استعادة: ${filePath}`);
        return true;
      } else {
        console.log(`❌ لم يتم العثور على: ${filePath} في النسخة الاحتياطية`);
        return false;
      }
    } catch (error) {
      console.error(`❌ خطأ في استعادة ${filePath}:`, error.message);
      return false;
    }
  }

  // ===================================
  // عرض قائمة الملفات المنقولة
  // ===================================
  async showBackupContents() {
    console.log('📁 محتويات النسخة الاحتياطية:');
    console.log('═══════════════════════════════════');

    if (!fs.existsSync(this.backupDir)) {
      console.log('❌ مجلد النسخة الاحتياطية غير موجود');
      return;
    }

    const files = this.getAllFiles(this.backupDir);
    files.forEach(file => {
      const relativePath = path.relative(this.backupDir, file);
      console.log(`📦 ${relativePath}`);
    });

    console.log(`\n📊 المجموع: ${files.length} ملف`);
  }

  // ===================================
  // الحصول على جميع الملفات في مجلد
  // ===================================
  getAllFiles(dirPath, arrayOfFiles = []) {
    const files = fs.readdirSync(dirPath);

    files.forEach(file => {
      const fullPath = path.join(dirPath, file);
      if (fs.statSync(fullPath).isDirectory()) {
        arrayOfFiles = this.getAllFiles(fullPath, arrayOfFiles);
      } else {
        arrayOfFiles.push(fullPath);
      }
    });

    return arrayOfFiles;
  }
}

// تشغيل التنظيف
if (require.main === module) {
  const cleanup = new FileCleanup();
  
  const command = process.argv[2];
  
  switch (command) {
    case 'cleanup':
      cleanup.cleanup();
      break;
      
    case 'show-backup':
      cleanup.showBackupContents();
      break;
      
    case 'restore':
      const filePath = process.argv[3];
      if (filePath) {
        cleanup.restoreFile(filePath);
      } else {
        console.log('❌ يجب تحديد مسار الملف للاستعادة');
        console.log('الاستخدام: node cleanup_conflicting_files.js restore <file_path>');
      }
      break;
      
    default:
      console.log('📋 الأوامر المتاحة:');
      console.log('  node cleanup_conflicting_files.js cleanup      - تنظيف الملفات المتضاربة');
      console.log('  node cleanup_conflicting_files.js show-backup  - عرض محتويات النسخة الاحتياطية');
      console.log('  node cleanup_conflicting_files.js restore <file> - استعادة ملف معين');
  }
}

module.exports = FileCleanup;
