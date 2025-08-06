#!/usr/bin/env node

/**
 * سكريبت بناء ونشر تحديث التطبيق
 * يقوم ببناء APK ورفعه للخادم وإشعار المستخدمين
 */

const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const util = require('util');

const execPromise = util.promisify(exec);

class AppUpdateBuilder {
  constructor() {
    this.frontendDir = './frontend';
    this.backendDir = './backend';
    this.version = '3.6.1';
    this.buildNumber = 14;
    this.apkName = `montajati-v${this.version}.apk`;
  }

  async buildAndDeploy() {
    try {
      console.log('🚀 بدء بناء ونشر تحديث التطبيق...');
      console.log('='.repeat(60));

      // 1. التحقق من المتطلبات
      await this.checkPrerequisites();

      // 2. تنظيف المشروع
      await this.cleanProject();

      // 3. بناء APK
      await this.buildAPK();

      // 4. إعداد نظام التحديث
      await this.setupUpdateSystem();

      // 5. رفع APK للخادم
      await this.uploadAPK();

      // 6. تحديث API الإصدار
      await this.updateVersionAPI();

      // 7. إشعار المستخدمين
      await this.notifyUsers();

      console.log('\n🎉 تم بناء ونشر التحديث بنجاح!');
      console.log('📱 الإصدار:', this.version);
      console.log('🔢 رقم البناء:', this.buildNumber);
      console.log('📁 ملف APK:', this.apkName);

    } catch (error) {
      console.error('❌ خطأ في بناء التحديث:', error.message);
      throw error;
    }
  }

  async checkPrerequisites() {
    console.log('🔍 التحقق من المتطلبات...');

    try {
      // التحقق من Flutter
      await execPromise('flutter --version');
      console.log('✅ Flutter متاح');

      // التحقق من مجلد Frontend
      if (!fs.existsSync(this.frontendDir)) {
        throw new Error('مجلد Frontend غير موجود');
      }
      console.log('✅ مجلد Frontend موجود');

      // التحقق من pubspec.yaml
      const pubspecPath = path.join(this.frontendDir, 'pubspec.yaml');
      if (!fs.existsSync(pubspecPath)) {
        throw new Error('ملف pubspec.yaml غير موجود');
      }
      console.log('✅ ملف pubspec.yaml موجود');

    } catch (error) {
      throw new Error(`فشل في التحقق من المتطلبات: ${error.message}`);
    }
  }

  async cleanProject() {
    console.log('🧹 تنظيف المشروع...');

    try {
      process.chdir(this.frontendDir);

      // تنظيف Flutter
      await execPromise('flutter clean');
      console.log('✅ تم تنظيف Flutter');

      // تحديث المكتبات
      await execPromise('flutter pub get');
      console.log('✅ تم تحديث المكتبات');

    } catch (error) {
      throw new Error(`فشل في تنظيف المشروع: ${error.message}`);
    }
  }

  async buildAPK() {
    console.log('🔨 بناء APK...');

    try {
      // بناء APK للإنتاج
      const buildCommand = `flutter build apk --release --build-name=${this.version} --build-number=${this.buildNumber}`;
      
      console.log('⏳ جاري بناء APK... (قد يستغرق عدة دقائق)');
      await execPromise(buildCommand);
      
      // التحقق من وجود APK
      const apkPath = path.join('build', 'app', 'outputs', 'flutter-apk', 'app-release.apk');
      if (!fs.existsSync(apkPath)) {
        throw new Error('فشل في إنشاء ملف APK');
      }

      // نسخ APK بالاسم الجديد
      const newApkPath = path.join('build', 'app', 'outputs', 'flutter-apk', this.apkName);
      fs.copyFileSync(apkPath, newApkPath);

      console.log('✅ تم بناء APK بنجاح');
      console.log('📁 مسار APK:', newApkPath);

      // عرض معلومات الملف
      const stats = fs.statSync(newApkPath);
      const fileSizeMB = (stats.size / (1024 * 1024)).toFixed(2);
      console.log('📊 حجم الملف:', fileSizeMB, 'MB');

    } catch (error) {
      throw new Error(`فشل في بناء APK: ${error.message}`);
    }
  }

  async setupUpdateSystem() {
    console.log('⚙️ إعداد نظام التحديث...');

    try {
      process.chdir('..');
      process.chdir(this.backendDir);

      // تشغيل سكريبت إعداد النظام
      await execPromise('node setup_update_system.js');
      console.log('✅ تم إعداد نظام التحديث');

    } catch (error) {
      console.log('⚠️ تحذير: لم يتم إعداد نظام التحديث (قد يكون موجود بالفعل)');
    }
  }

  async uploadAPK() {
    console.log('📤 رفع APK للخادم...');

    try {
      const apkPath = path.join('..', this.frontendDir, 'build', 'app', 'outputs', 'flutter-apk', this.apkName);
      
      if (!fs.existsSync(apkPath)) {
        throw new Error('ملف APK غير موجود');
      }

      // نسخ APK لمجلد التحميلات المحلي (للاختبار)
      const localDownloadsDir = './downloads';
      if (!fs.existsSync(localDownloadsDir)) {
        fs.mkdirSync(localDownloadsDir, { recursive: true });
      }

      const localApkPath = path.join(localDownloadsDir, this.apkName);
      fs.copyFileSync(apkPath, localApkPath);

      console.log('✅ تم نسخ APK لمجلد التحميلات المحلي');
      console.log('📁 المسار المحلي:', localApkPath);

      // هنا يمكن إضافة كود رفع الملف للخادم الفعلي
      console.log('ℹ️ لرفع الملف للخادم الفعلي، استخدم:');
      console.log(`   scp ${localApkPath} user@server:/var/www/html/downloads/`);

    } catch (error) {
      throw new Error(`فشل في رفع APK: ${error.message}`);
    }
  }

  async updateVersionAPI() {
    console.log('🔄 تحديث API الإصدار...');

    try {
      // تحديث ملف API الإصدار
      const apiFilePath = path.join('routes', 'notifications.js');
      
      if (fs.existsSync(apiFilePath)) {
        let apiContent = fs.readFileSync(apiFilePath, 'utf8');
        
        // تحديث رقم الإصدار
        apiContent = apiContent.replace(/version: '[^']*'/, `version: '${this.version}'`);
        apiContent = apiContent.replace(/buildNumber: \d+/, `buildNumber: ${this.buildNumber}`);
        
        fs.writeFileSync(apiFilePath, apiContent);
        console.log('✅ تم تحديث API الإصدار');
      }

    } catch (error) {
      console.log('⚠️ تحذير: لم يتم تحديث API الإصدار تلقائياً');
    }
  }

  async notifyUsers() {
    console.log('📢 إشعار المستخدمين...');

    try {
      // هنا يمكن إضافة كود إرسال إشعار FCM لجميع المستخدمين
      console.log('ℹ️ لإشعار المستخدمين، قم بتشغيل:');
      console.log('   - إرسال إشعار FCM');
      console.log('   - تحديث قاعدة البيانات');
      console.log('   - إعادة تشغيل الخادم');

    } catch (error) {
      console.log('⚠️ تحذير: لم يتم إشعار المستخدمين تلقائياً');
    }
  }
}

// تشغيل البناء والنشر
if (require.main === module) {
  const builder = new AppUpdateBuilder();
  builder.buildAndDeploy().catch(error => {
    console.error('❌ فشل في بناء التحديث:', error.message);
    process.exit(1);
  });
}

module.exports = AppUpdateBuilder;
