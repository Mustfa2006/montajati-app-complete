#!/usr/bin/env node

/**
 * سكريبت رفع التحديث للخادم
 */

const fs = require('fs');
const path = require('path');

class ServerUploader {
  constructor() {
    this.serverHost = 'clownfish-app-krnk9.ondigitalocean.app';
    this.serverPath = '/var/www/html/downloads/';
    this.localDownloadsDir = './backend/downloads/';
  }

  async uploadFiles() {
    try {
      console.log('📤 بدء رفع الملفات للخادم...');
      console.log('='.repeat(50));

      // التحقق من وجود الملفات
      await this.checkFiles();

      // عرض تعليمات الرفع
      this.showUploadInstructions();

      console.log('\n✅ تم إعداد ملفات الرفع بنجاح!');

    } catch (error) {
      console.error('❌ خطأ في رفع الملفات:', error.message);
      throw error;
    }
  }

  async checkFiles() {
    console.log('🔍 التحقق من الملفات...');

    const requiredFiles = [
      'montajati-v3.6.1.apk',
      'index.html'
    ];

    for (const file of requiredFiles) {
      const filePath = path.join(this.localDownloadsDir, file);
      if (!fs.existsSync(filePath)) {
        throw new Error(`الملف غير موجود: ${file}`);
      }

      const stats = fs.statSync(filePath);
      const fileSizeMB = (stats.size / (1024 * 1024)).toFixed(2);
      console.log(`✅ ${file} - ${fileSizeMB} MB`);
    }
  }

  showUploadInstructions() {
    console.log('\n📋 تعليمات رفع الملفات للخادم:');
    console.log('='.repeat(50));

    console.log('\n🔧 الطريقة 1: استخدام SCP (الأسرع):');
    console.log('```bash');
    console.log(`scp backend/downloads/montajati-v3.6.1.apk root@${this.serverHost}:${this.serverPath}`);
    console.log(`scp backend/downloads/index.html root@${this.serverHost}:${this.serverPath}`);
    console.log('```');

    console.log('\n🔧 الطريقة 2: استخدام لوحة التحكم:');
    console.log('1. ادخل للوحة تحكم الاستضافة');
    console.log('2. اذهب لـ File Manager');
    console.log('3. انتقل لمجلد public_html/downloads/');
    console.log('4. ارفع الملفات:');
    console.log('   - montajati-v3.6.1.apk');
    console.log('   - index.html');

    console.log('\n🔧 الطريقة 3: استخدام FTP:');
    console.log('```bash');
    console.log('ftp clownfish-app-krnk9.ondigitalocean.app');
    console.log('cd /var/www/html/downloads/');
    console.log('put backend/downloads/montajati-v3.6.1.apk');
    console.log('put backend/downloads/index.html');
    console.log('```');

    console.log('\n🌐 بعد الرفع، تحقق من الروابط:');
    console.log(`✅ صفحة التحميل: https://${this.serverHost}/downloads/`);
    console.log(`✅ ملف APK: https://${this.serverHost}/downloads/montajati-v3.6.1.apk`);

    console.log('\n⚠️ ملاحظات مهمة:');
    console.log('- تأكد من صلاحيات القراءة للملفات (chmod 644)');
    console.log('- تأكد من أن مجلد downloads موجود');
    console.log('- اختبر الروابط قبل إرسال الإشعار');
  }
}

// تشغيل الرفع
if (require.main === module) {
  const uploader = new ServerUploader();
  uploader.uploadFiles().catch(error => {
    console.error('❌ فشل في رفع الملفات:', error.message);
    process.exit(1);
  });
}

module.exports = ServerUploader;
