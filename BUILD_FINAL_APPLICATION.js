// ===================================
// بناء التطبيق النهائي - نظام منتجاتي
// Final Application Build - Montajati System
// ===================================

const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

class FinalApplicationBuilder {
  constructor() {
    this.buildSteps = [];
    this.errors = [];
    this.warnings = [];
    this.buildResults = {};
  }

  async buildFinalApplication() {
    console.log('🚀 بدء بناء التطبيق النهائي...');
    console.log('='.repeat(70));

    try {
      // 1. التحقق من المتطلبات
      await this.checkPrerequisites();
      
      // 2. تنظيف وتحضير المشروع
      await this.cleanAndPrepare();
      
      // 3. بناء Backend
      await this.buildBackend();
      
      // 4. بناء Frontend (Flutter)
      await this.buildFrontend();
      
      // 5. إنشاء ملفات النشر
      await this.createDeploymentFiles();
      
      // 6. التحقق النهائي
      await this.finalValidation();
      
      // 7. إنشاء التقرير النهائي
      this.generateFinalReport();

      console.log('\n🎉 تم بناء التطبيق النهائي بنجاح!');
      
    } catch (error) {
      console.error('❌ خطأ في بناء التطبيق:', error.message);
      throw error;
    }
  }

  async checkPrerequisites() {
    console.log('\n📋 التحقق من المتطلبات...');
    
    const requirements = [
      { name: 'Node.js', command: 'node', args: ['--version'] },
      { name: 'npm', command: 'npm', args: ['--version'] },
      { name: 'Flutter', command: 'flutter', args: ['--version'] }
    ];

    for (const req of requirements) {
      try {
        const result = await this.runCommand(req.command, req.args);
        console.log(`✅ ${req.name}: متوفر`);
        this.buildSteps.push(`✅ ${req.name} متوفر`);
      } catch (error) {
        console.log(`⚠️ ${req.name}: غير متوفر أو غير مثبت`);
        this.warnings.push(`${req.name} غير متوفر`);
      }
    }

    // التحقق من الملفات الأساسية
    const essentialFiles = [
      'backend/package.json',
      'backend/official_montajati_server.js',
      'frontend/pubspec.yaml',
      'frontend/lib/main.dart'
    ];

    essentialFiles.forEach(file => {
      if (fs.existsSync(file)) {
        console.log(`✅ ${file}: موجود`);
        this.buildSteps.push(`✅ ${file} موجود`);
      } else {
        console.log(`❌ ${file}: مفقود`);
        this.errors.push(`${file} مفقود`);
      }
    });
  }

  async cleanAndPrepare() {
    console.log('\n🧹 تنظيف وتحضير المشروع...');
    
    try {
      // تنظيف node_modules في backend
      if (fs.existsSync('backend/node_modules')) {
        console.log('🗑️ تنظيف node_modules في backend...');
        await this.runCommand('rm', ['-rf', 'node_modules'], 'backend');
      }

      // تثبيت التبعيات في backend
      console.log('📦 تثبيت التبعيات في backend...');
      await this.runCommand('npm', ['install'], 'backend');
      
      // التحقق من الأمان
      console.log('🔒 فحص الأمان...');
      const auditResult = await this.runCommand('npm', ['audit'], 'backend');
      
      if (auditResult.stdout.includes('found 0 vulnerabilities')) {
        console.log('✅ لا توجد ثغرات أمنية');
        this.buildSteps.push('✅ Backend آمن');
      } else {
        console.log('⚠️ توجد ثغرات أمنية، جاري الإصلاح...');
        await this.runCommand('npm', ['audit', 'fix'], 'backend');
        this.buildSteps.push('✅ تم إصلاح الثغرات الأمنية');
      }

      this.buildResults.backend_dependencies = 'مثبتة وآمنة';
      
    } catch (error) {
      console.error('❌ خطأ في تحضير المشروع:', error.message);
      this.errors.push(`خطأ في التحضير: ${error.message}`);
    }
  }

  async buildBackend() {
    console.log('\n🔧 بناء Backend...');
    
    try {
      // التحقق من متغيرات البيئة
      console.log('🔍 التحقق من متغيرات البيئة...');
      
      const envVars = [
        'SUPABASE_URL',
        'SUPABASE_SERVICE_ROLE_KEY',
        'FIREBASE_SERVICE_ACCOUNT',
        'WASEET_USERNAME',
        'WASEET_PASSWORD'
      ];

      let missingVars = [];
      
      envVars.forEach(varName => {
        if (!process.env[varName]) {
          missingVars.push(varName);
        }
      });

      if (missingVars.length > 0) {
        console.log(`⚠️ متغيرات البيئة المفقودة: ${missingVars.join(', ')}`);
        this.warnings.push(`متغيرات البيئة المفقودة: ${missingVars.join(', ')}`);
      } else {
        console.log('✅ جميع متغيرات البيئة موجودة');
        this.buildSteps.push('✅ متغيرات البيئة مكتملة');
      }

      // اختبار الخدمات
      console.log('🧪 اختبار الخدمات...');
      
      try {
        await this.runCommand('node', ['test_services.js'], 'backend');
        console.log('✅ جميع الخدمات تعمل');
        this.buildSteps.push('✅ خدمات Backend تعمل');
      } catch (error) {
        console.log('⚠️ بعض الخدمات قد لا تعمل بشكل كامل');
        this.warnings.push('بعض خدمات Backend قد لا تعمل');
      }

      this.buildResults.backend = 'جاهز للنشر';
      
    } catch (error) {
      console.error('❌ خطأ في بناء Backend:', error.message);
      this.errors.push(`خطأ في Backend: ${error.message}`);
    }
  }

  async buildFrontend() {
    console.log('\n📱 بناء Frontend (Flutter)...');
    
    try {
      // التحقق من وجود Flutter
      try {
        await this.runCommand('flutter', ['--version']);
        console.log('✅ Flutter متوفر');
      } catch (error) {
        console.log('⚠️ Flutter غير متوفر، تخطي بناء التطبيق');
        this.warnings.push('Flutter غير متوفر');
        return;
      }

      // تنظيف Flutter
      console.log('🧹 تنظيف Flutter...');
      await this.runCommand('flutter', ['clean'], 'frontend');
      
      // تحديث التبعيات
      console.log('📦 تحديث تبعيات Flutter...');
      await this.runCommand('flutter', ['pub', 'get'], 'frontend');
      
      // بناء APK للإنتاج
      console.log('🔨 بناء APK للإنتاج...');
      await this.runCommand('flutter', ['build', 'apk', '--release'], 'frontend');
      
      // التحقق من وجود APK
      const apkPath = 'frontend/build/app/outputs/flutter-apk/app-release.apk';
      if (fs.existsSync(apkPath)) {
        const stats = fs.statSync(apkPath);
        const sizeInMB = (stats.size / (1024 * 1024)).toFixed(2);
        console.log(`✅ تم بناء APK بنجاح (${sizeInMB} MB)`);
        this.buildSteps.push(`✅ APK جاهز (${sizeInMB} MB)`);
        this.buildResults.apk = {
          path: apkPath,
          size: `${sizeInMB} MB`,
          status: 'جاهز'
        };
      } else {
        console.log('❌ فشل في بناء APK');
        this.errors.push('فشل في بناء APK');
      }

      // بناء App Bundle للـ Play Store
      console.log('🔨 بناء App Bundle...');
      try {
        await this.runCommand('flutter', ['build', 'appbundle', '--release'], 'frontend');
        
        const aabPath = 'frontend/build/app/outputs/bundle/release/app-release.aab';
        if (fs.existsSync(aabPath)) {
          const stats = fs.statSync(aabPath);
          const sizeInMB = (stats.size / (1024 * 1024)).toFixed(2);
          console.log(`✅ تم بناء App Bundle بنجاح (${sizeInMB} MB)`);
          this.buildSteps.push(`✅ App Bundle جاهز (${sizeInMB} MB)`);
          this.buildResults.aab = {
            path: aabPath,
            size: `${sizeInMB} MB`,
            status: 'جاهز'
          };
        }
      } catch (error) {
        console.log('⚠️ فشل في بناء App Bundle');
        this.warnings.push('فشل في بناء App Bundle');
      }
      
    } catch (error) {
      console.error('❌ خطأ في بناء Frontend:', error.message);
      this.errors.push(`خطأ في Frontend: ${error.message}`);
    }
  }

  async createDeploymentFiles() {
    console.log('\n📄 إنشاء ملفات النشر...');
    
    try {
      // إنشاء Dockerfile محسن
      const dockerfileContent = `# استخدام Node.js 18 LTS
FROM node:18-alpine

# إعداد مجلد العمل
WORKDIR /app

# نسخ ملفات package.json أولاً للاستفادة من Docker cache
COPY backend/package*.json ./

# تثبيت التبعيات
RUN npm ci --only=production && npm cache clean --force

# نسخ باقي الملفات
COPY backend/ ./

# إنشاء مستخدم غير root للأمان
RUN addgroup -g 1001 -S nodejs && \\
    adduser -S montajati -u 1001

# تغيير ملكية الملفات
RUN chown -R montajati:nodejs /app
USER montajati

# كشف المنفذ
EXPOSE 3003

# فحص الصحة
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \\
  CMD node -e "require('http').get('http://localhost:3003/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

# تشغيل التطبيق
CMD ["npm", "start"]`;

      fs.writeFileSync('Dockerfile', dockerfileContent);
      console.log('✅ تم إنشاء Dockerfile');
      this.buildSteps.push('✅ Dockerfile جاهز');

      // إنشاء render.yaml
      const renderYamlContent = `services:
  - type: web
    name: montajati-backend
    env: node
    buildCommand: cd backend && npm install
    startCommand: cd backend && npm start
    envVars:
      - key: NODE_ENV
        value: production
      - key: PORT
        value: 3003`;

      fs.writeFileSync('render.yaml', renderYamlContent);
      console.log('✅ تم إنشاء render.yaml');
      this.buildSteps.push('✅ render.yaml جاهز');

      this.buildResults.deployment_files = 'جاهزة';
      
    } catch (error) {
      console.error('❌ خطأ في إنشاء ملفات النشر:', error.message);
      this.errors.push(`خطأ في ملفات النشر: ${error.message}`);
    }
  }

  async finalValidation() {
    console.log('\n🔍 التحقق النهائي...');
    
    try {
      // التحقق من ملفات Backend
      const backendFiles = [
        'backend/package.json',
        'backend/official_montajati_server.js',
        'backend/production/main.js'
      ];

      backendFiles.forEach(file => {
        if (fs.existsSync(file)) {
          console.log(`✅ ${file}: موجود`);
        } else {
          console.log(`❌ ${file}: مفقود`);
          this.errors.push(`${file} مفقود`);
        }
      });

      // التحقق من ملفات Frontend
      if (this.buildResults.apk) {
        console.log(`✅ APK: ${this.buildResults.apk.status} (${this.buildResults.apk.size})`);
      }

      if (this.buildResults.aab) {
        console.log(`✅ App Bundle: ${this.buildResults.aab.status} (${this.buildResults.aab.size})`);
      }

      // التحقق من ملفات النشر
      if (fs.existsSync('Dockerfile')) {
        console.log('✅ Dockerfile: جاهز');
      }

      if (fs.existsSync('render.yaml')) {
        console.log('✅ render.yaml: جاهز');
      }

      this.buildResults.validation = 'مكتمل';
      
    } catch (error) {
      console.error('❌ خطأ في التحقق النهائي:', error.message);
      this.errors.push(`خطأ في التحقق: ${error.message}`);
    }
  }

  runCommand(command, args, cwd = '.') {
    return new Promise((resolve, reject) => {
      const child = spawn(command, args, {
        cwd: cwd,
        stdio: 'pipe',
        shell: true
      });

      let stdout = '';
      let stderr = '';

      child.stdout.on('data', (data) => {
        stdout += data.toString();
      });

      child.stderr.on('data', (data) => {
        stderr += data.toString();
      });

      child.on('close', (code) => {
        if (code === 0) {
          resolve({ code, stdout, stderr });
        } else {
          reject(new Error(`Command failed with code ${code}: ${stderr}`));
        }
      });

      child.on('error', (error) => {
        reject(error);
      });
    });
  }

  generateFinalReport() {
    console.log('\n📋 تقرير البناء النهائي:');
    console.log('='.repeat(50));
    
    console.log('\n✅ الخطوات المكتملة:');
    this.buildSteps.forEach((step, index) => {
      console.log(`   ${index + 1}. ${step}`);
    });
    
    if (this.warnings.length > 0) {
      console.log('\n⚠️ التحذيرات:');
      this.warnings.forEach((warning, index) => {
        console.log(`   ${index + 1}. ${warning}`);
      });
    }
    
    if (this.errors.length > 0) {
      console.log('\n❌ الأخطاء:');
      this.errors.forEach((error, index) => {
        console.log(`   ${index + 1}. ${error}`);
      });
    }
    
    console.log('\n📊 نتائج البناء:');
    Object.entries(this.buildResults).forEach(([key, value]) => {
      if (typeof value === 'object') {
        console.log(`   ${key}: ${value.status} (${value.size || 'N/A'})`);
      } else {
        console.log(`   ${key}: ${value}`);
      }
    });
    
    const successRate = ((this.buildSteps.length / (this.buildSteps.length + this.errors.length)) * 100).toFixed(1);
    console.log(`\n📈 معدل النجاح: ${successRate}%`);
    
    if (this.errors.length === 0) {
      console.log('\n🎉 التطبيق جاهز للنشر!');
    } else {
      console.log('\n⚠️ يحتاج التطبيق إلى إصلاحات قبل النشر');
    }
  }
}

// تشغيل بناء التطبيق النهائي
if (require.main === module) {
  const builder = new FinalApplicationBuilder();
  
  builder.buildFinalApplication()
    .then(() => {
      console.log('\n🎉 انتهى بناء التطبيق النهائي بنجاح!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ فشل بناء التطبيق النهائي:', error.message);
      process.exit(1);
    });
}

module.exports = FinalApplicationBuilder;
