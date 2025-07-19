#!/usr/bin/env node

// ===================================
// فحص جاهزية النظام للإنتاج
// ===================================

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

class ProductionReadinessChecker {
  constructor() {
    this.checks = [];
    this.errors = [];
    this.warnings = [];
  }

  // ===================================
  // فحص متغيرات البيئة
  // ===================================
  checkEnvironmentVariables() {
    console.log('🔍 فحص متغيرات البيئة...');
    
    const requiredVars = [
      'SUPABASE_URL',
      'SUPABASE_SERVICE_ROLE_KEY',
      'FIREBASE_SERVICE_ACCOUNT',
      'PORT'
    ];

    const optionalVars = [
      'NODE_ENV',
      'TELEGRAM_BOT_TOKEN',
      'TELEGRAM_CHAT_ID'
    ];

    let allPresent = true;

    // فحص المتغيرات المطلوبة
    requiredVars.forEach(varName => {
      if (!process.env[varName]) {
        this.errors.push(`❌ متغير البيئة المطلوب مفقود: ${varName}`);
        allPresent = false;
      } else {
        console.log(`✅ ${varName}: موجود`);
      }
    });

    // فحص المتغيرات الاختيارية
    optionalVars.forEach(varName => {
      if (!process.env[varName]) {
        this.warnings.push(`⚠️ متغير البيئة الاختياري مفقود: ${varName}`);
      } else {
        console.log(`✅ ${varName}: موجود`);
      }
    });

    return allPresent;
  }

  // ===================================
  // فحص الملفات المطلوبة
  // ===================================
  checkRequiredFiles() {
    console.log('\n📁 فحص الملفات المطلوبة...');
    
    const requiredFiles = [
      'package.json',
      'database/smart_notification_trigger.sql',
      'notification_processor_simple.js',
      'start_system_complete.js',
      'start_notifications_final.js',
      'config/supabase.js',
      'config/firebase.js'
    ];

    let allPresent = true;

    requiredFiles.forEach(filePath => {
      const fullPath = path.join(__dirname, filePath);
      if (fs.existsSync(fullPath)) {
        console.log(`✅ ${filePath}: موجود`);
      } else {
        this.errors.push(`❌ ملف مطلوب مفقود: ${filePath}`);
        allPresent = false;
      }
    });

    return allPresent;
  }

  // ===================================
  // فحص اتصال قاعدة البيانات
  // ===================================
  async checkDatabaseConnection() {
    console.log('\n🗄️ فحص اتصال قاعدة البيانات...');
    
    try {
      const supabase = createClient(
        process.env.SUPABASE_URL,
        process.env.SUPABASE_SERVICE_ROLE_KEY
      );

      // اختبار الاتصال
      const { data, error } = await supabase
        .from('orders')
        .select('id')
        .limit(1);

      if (error) {
        this.errors.push(`❌ خطأ في الاتصال بقاعدة البيانات: ${error.message}`);
        return false;
      }

      console.log('✅ اتصال قاعدة البيانات: يعمل');
      return true;

    } catch (error) {
      this.errors.push(`❌ خطأ في اتصال قاعدة البيانات: ${error.message}`);
      return false;
    }
  }

  // ===================================
  // فحص جداول الإشعارات
  // ===================================
  async checkNotificationTables() {
    console.log('\n📊 فحص جداول الإشعارات...');
    
    try {
      const supabase = createClient(
        process.env.SUPABASE_URL,
        process.env.SUPABASE_SERVICE_ROLE_KEY
      );

      const requiredTables = [
        'notification_queue',
        'notification_logs',
        'fcm_tokens'
      ];

      let allPresent = true;

      for (const tableName of requiredTables) {
        const { data, error } = await supabase
          .from(tableName)
          .select('*')
          .limit(1);

        if (error) {
          this.errors.push(`❌ جدول مفقود أو خطأ: ${tableName} - ${error.message}`);
          allPresent = false;
        } else {
          console.log(`✅ جدول ${tableName}: موجود`);
        }
      }

      return allPresent;

    } catch (error) {
      this.errors.push(`❌ خطأ في فحص الجداول: ${error.message}`);
      return false;
    }
  }

  // ===================================
  // فحص Firebase
  // ===================================
  checkFirebaseConfig() {
    console.log('\n🔥 فحص إعدادات Firebase...');
    
    try {
      const firebaseConfig = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      
      const requiredFields = [
        'type',
        'project_id',
        'private_key',
        'client_email'
      ];

      let allPresent = true;

      requiredFields.forEach(field => {
        if (!firebaseConfig[field]) {
          this.errors.push(`❌ حقل Firebase مفقود: ${field}`);
          allPresent = false;
        } else {
          console.log(`✅ Firebase ${field}: موجود`);
        }
      });

      return allPresent;

    } catch (error) {
      this.errors.push(`❌ خطأ في تحليل إعدادات Firebase: ${error.message}`);
      return false;
    }
  }

  // ===================================
  // فحص التبعيات
  // ===================================
  checkDependencies() {
    console.log('\n📦 فحص التبعيات...');
    
    try {
      const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'));
      const requiredDeps = [
        '@supabase/supabase-js',
        'firebase-admin',
        'express',
        'dotenv',
        'cors'
      ];

      let allPresent = true;

      requiredDeps.forEach(dep => {
        if (!packageJson.dependencies[dep]) {
          this.errors.push(`❌ تبعية مطلوبة مفقودة: ${dep}`);
          allPresent = false;
        } else {
          console.log(`✅ ${dep}: ${packageJson.dependencies[dep]}`);
        }
      });

      // فحص node_modules
      if (fs.existsSync('node_modules')) {
        console.log('✅ node_modules: موجود');
      } else {
        this.warnings.push('⚠️ node_modules مفقود - قم بتشغيل npm install');
      }

      return allPresent;

    } catch (error) {
      this.errors.push(`❌ خطأ في فحص التبعيات: ${error.message}`);
      return false;
    }
  }

  // ===================================
  // تشغيل جميع الفحوصات
  // ===================================
  async runAllChecks() {
    console.log('🚀 بدء فحص جاهزية النظام للإنتاج...\n');

    const checks = [
      { name: 'متغيرات البيئة', fn: () => this.checkEnvironmentVariables() },
      { name: 'الملفات المطلوبة', fn: () => this.checkRequiredFiles() },
      { name: 'التبعيات', fn: () => this.checkDependencies() },
      { name: 'اتصال قاعدة البيانات', fn: () => this.checkDatabaseConnection() },
      { name: 'جداول الإشعارات', fn: () => this.checkNotificationTables() },
      { name: 'إعدادات Firebase', fn: () => this.checkFirebaseConfig() }
    ];

    let allPassed = true;

    for (const check of checks) {
      try {
        const result = await check.fn();
        if (!result) {
          allPassed = false;
        }
      } catch (error) {
        this.errors.push(`❌ خطأ في فحص ${check.name}: ${error.message}`);
        allPassed = false;
      }
    }

    return allPassed;
  }

  // ===================================
  // عرض النتائج
  // ===================================
  displayResults(allPassed) {
    console.log('\n' + '='.repeat(50));
    console.log('📋 نتائج فحص الجاهزية');
    console.log('='.repeat(50));

    if (allPassed && this.errors.length === 0) {
      console.log('🎉 النظام جاهز 100% للإنتاج!');
      console.log('✅ جميع الفحوصات نجحت');
    } else {
      console.log('❌ النظام غير جاهز للإنتاج');
    }

    if (this.errors.length > 0) {
      console.log('\n🚨 أخطاء يجب إصلاحها:');
      this.errors.forEach(error => console.log(`   ${error}`));
    }

    if (this.warnings.length > 0) {
      console.log('\n⚠️ تحذيرات:');
      this.warnings.forEach(warning => console.log(`   ${warning}`));
    }

    console.log('\n' + '='.repeat(50));

    if (allPassed && this.errors.length === 0) {
      console.log('🚀 يمكنك الآن نشر النظام بأمان!');
      console.log('📝 استخدم: npm start');
    } else {
      console.log('🔧 يرجى إصلاح الأخطاء أولاً');
    }
  }
}

// تشغيل الفحص
async function main() {
  const checker = new ProductionReadinessChecker();
  const allPassed = await checker.runAllChecks();
  checker.displayResults(allPassed);
  
  process.exit(allPassed && checker.errors.length === 0 ? 0 : 1);
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = ProductionReadinessChecker;
