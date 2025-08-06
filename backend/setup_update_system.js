#!/usr/bin/env node

/**
 * إعداد نظام التحديث التلقائي
 * يقوم بإنشاء المجلدات المطلوبة وإعداد النظام
 */

const fs = require('fs');
const path = require('path');

class UpdateSystemSetup {
  constructor() {
    this.baseDir = '/var/www/html';
    this.downloadsDir = path.join(this.baseDir, 'downloads');
  }

  async setup() {
    try {
      console.log('🚀 بدء إعداد نظام التحديث التلقائي...');
      console.log('='.repeat(50));

      // 1. إنشاء مجلد التحميلات
      await this.createDownloadsDirectory();

      // 2. إنشاء ملف index.html للمجلد
      await this.createIndexFile();

      // 3. تعيين الصلاحيات
      await this.setPermissions();

      // 4. إنشاء ملف معلومات الإصدار
      await this.createVersionInfo();

      console.log('\n✅ تم إعداد نظام التحديث بنجاح!');
      console.log('📁 مجلد التحميلات:', this.downloadsDir);
      console.log('🔗 رابط التحميل: https://clownfish-app-krnk9.ondigitalocean.app/downloads/');

    } catch (error) {
      console.error('❌ خطأ في إعداد النظام:', error.message);
      throw error;
    }
  }

  async createDownloadsDirectory() {
    try {
      if (!fs.existsSync(this.downloadsDir)) {
        fs.mkdirSync(this.downloadsDir, { recursive: true });
        console.log('✅ تم إنشاء مجلد التحميلات');
      } else {
        console.log('ℹ️ مجلد التحميلات موجود بالفعل');
      }
    } catch (error) {
      console.error('❌ خطأ في إنشاء مجلد التحميلات:', error.message);
      throw error;
    }
  }

  async createIndexFile() {
    const indexPath = path.join(this.downloadsDir, 'index.html');
    const indexContent = `
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>تحميل تطبيق منتجاتي</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin: 0;
            padding: 20px;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 20px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            text-align: center;
            max-width: 500px;
            width: 100%;
        }
        .logo {
            width: 80px;
            height: 80px;
            background: #ffd700;
            border-radius: 50%;
            margin: 0 auto 20px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 30px;
            color: white;
        }
        h1 {
            color: #333;
            margin-bottom: 10px;
        }
        .version {
            color: #666;
            margin-bottom: 30px;
        }
        .download-btn {
            background: #ffd700;
            color: white;
            padding: 15px 30px;
            border: none;
            border-radius: 10px;
            font-size: 18px;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
            transition: all 0.3s ease;
        }
        .download-btn:hover {
            background: #e6b31e;
            transform: translateY(-2px);
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">📱</div>
        <h1>تطبيق منتجاتي</h1>
        <p class="version">الإصدار 3.6.1</p>
        <p>تحميل أحدث إصدار من التطبيق</p>
        <a href="montajati-v3.6.1.apk" class="download-btn">تحميل التطبيق</a>
    </div>
</body>
</html>
    `;

    try {
      fs.writeFileSync(indexPath, indexContent.trim());
      console.log('✅ تم إنشاء ملف index.html');
    } catch (error) {
      console.error('❌ خطأ في إنشاء ملف index.html:', error.message);
      throw error;
    }
  }

  async setPermissions() {
    try {
      const { exec } = require('child_process');
      const util = require('util');
      const execPromise = util.promisify(exec);

      // تعيين صلاحيات القراءة والكتابة
      await execPromise(`chmod -R 755 ${this.downloadsDir}`);
      console.log('✅ تم تعيين الصلاحيات');
    } catch (error) {
      console.log('⚠️ تحذير: لم يتم تعيين الصلاحيات (قد تحتاج صلاحيات sudo)');
    }
  }

  async createVersionInfo() {
    const versionPath = path.join(this.downloadsDir, 'version.json');
    const versionInfo = {
      version: '3.6.1',
      buildNumber: 14,
      downloadUrl: 'https://clownfish-app-krnk9.ondigitalocean.app/downloads/montajati-v3.6.1.apk',
      forceUpdate: true,
      changelog: 'تحسينات عامة وإصلاحات مهمة',
      releaseDate: new Date().toISOString(),
      fileSize: '25 MB',
      minAndroidVersion: '21'
    };

    try {
      fs.writeFileSync(versionPath, JSON.stringify(versionInfo, null, 2));
      console.log('✅ تم إنشاء ملف معلومات الإصدار');
    } catch (error) {
      console.error('❌ خطأ في إنشاء ملف معلومات الإصدار:', error.message);
      throw error;
    }
  }
}

// تشغيل الإعداد
if (require.main === module) {
  const setup = new UpdateSystemSetup();
  setup.setup().catch(error => {
    console.error('❌ فشل في إعداد النظام:', error.message);
    process.exit(1);
  });
}

module.exports = UpdateSystemSetup;
