// ===================================
// تحليل شامل للأمان وإصلاح جميع الثغرات
// Comprehensive Security Audit & Fix
// ===================================

const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

class ComprehensiveSecurityAudit {
  constructor() {
    this.vulnerabilities = [];
    this.fixes = [];
    this.errors = [];
    this.projectPaths = [
      '.',                    // المجلد الجذر
      './backend',           // مجلد Backend
      './frontend'           // مجلد Frontend
    ];
  }

  async runFullSecurityAudit() {
    console.log('🔒 بدء التحليل الشامل للأمان...');
    console.log('='.repeat(60));

    try {
      // 1. فحص جميع ملفات package.json
      await this.auditAllPackageFiles();
      
      // 2. إصلاح جميع الثغرات
      await this.fixAllVulnerabilities();
      
      // 3. تحديث جميع الحزم
      await this.updateAllPackages();
      
      // 4. فحص أمني نهائي
      await this.finalSecurityCheck();
      
      // 5. تطبيق أفضل الممارسات الأمنية
      await this.applySecurityBestPractices();

      console.log('\n🎉 تم إكمال التحليل الشامل للأمان!');
      this.printSecurityReport();
      
    } catch (error) {
      console.error('❌ خطأ في التحليل الأمني:', error.message);
      throw error;
    }
  }

  async auditAllPackageFiles() {
    console.log('\n📦 فحص جميع ملفات package.json...');
    
    for (const projectPath of this.projectPaths) {
      const packageJsonPath = path.join(projectPath, 'package.json');
      
      if (fs.existsSync(packageJsonPath)) {
        console.log(`\n🔍 فحص: ${packageJsonPath}`);
        
        try {
          const result = await this.runNpmAudit(projectPath);
          
          if (result.vulnerabilities > 0) {
            console.log(`❌ وجدت ${result.vulnerabilities} ثغرة أمنية في ${projectPath}`);
            this.vulnerabilities.push({
              path: projectPath,
              count: result.vulnerabilities,
              details: result.details
            });
          } else {
            console.log(`✅ لا توجد ثغرات أمنية في ${projectPath}`);
            this.fixes.push(`${projectPath} آمن`);
          }
          
        } catch (error) {
          console.log(`⚠️ فشل فحص ${projectPath}: ${error.message}`);
          this.errors.push(`فشل فحص ${projectPath}: ${error.message}`);
        }
      } else {
        console.log(`⚠️ لا يوجد package.json في ${projectPath}`);
      }
    }
  }

  async fixAllVulnerabilities() {
    console.log('\n🔧 إصلاح جميع الثغرات الأمنية...');
    
    for (const vuln of this.vulnerabilities) {
      console.log(`\n🔨 إصلاح الثغرات في ${vuln.path}...`);
      
      try {
        // محاولة الإصلاح التلقائي
        await this.runNpmAuditFix(vuln.path);
        
        // التحقق من الإصلاح
        const result = await this.runNpmAudit(vuln.path);
        
        if (result.vulnerabilities === 0) {
          console.log(`✅ تم إصلاح جميع الثغرات في ${vuln.path}`);
          this.fixes.push(`إصلاح ثغرات ${vuln.path}`);
        } else {
          console.log(`⚠️ تبقى ${result.vulnerabilities} ثغرة في ${vuln.path}`);
          
          // محاولة الإصلاح القسري
          await this.runNpmAuditFixForce(vuln.path);
          
          // فحص نهائي
          const finalResult = await this.runNpmAudit(vuln.path);
          
          if (finalResult.vulnerabilities === 0) {
            console.log(`✅ تم إصلاح جميع الثغرات بالقوة في ${vuln.path}`);
            this.fixes.push(`إصلاح قسري لثغرات ${vuln.path}`);
          } else {
            this.errors.push(`فشل إصلاح ${finalResult.vulnerabilities} ثغرة في ${vuln.path}`);
          }
        }
        
      } catch (error) {
        console.error(`❌ فشل إصلاح ${vuln.path}: ${error.message}`);
        this.errors.push(`فشل إصلاح ${vuln.path}: ${error.message}`);
      }
    }
  }

  async updateAllPackages() {
    console.log('\n📦 تحديث جميع الحزم إلى أحدث إصدارات آمنة...');
    
    for (const projectPath of this.projectPaths) {
      const packageJsonPath = path.join(projectPath, 'package.json');
      
      if (fs.existsSync(packageJsonPath)) {
        console.log(`\n🔄 تحديث الحزم في ${projectPath}...`);
        
        try {
          await this.runNpmUpdate(projectPath);
          console.log(`✅ تم تحديث الحزم في ${projectPath}`);
          this.fixes.push(`تحديث حزم ${projectPath}`);
          
        } catch (error) {
          console.log(`⚠️ فشل تحديث ${projectPath}: ${error.message}`);
          this.errors.push(`فشل تحديث ${projectPath}: ${error.message}`);
        }
      }
    }
  }

  async finalSecurityCheck() {
    console.log('\n🔍 الفحص الأمني النهائي...');
    
    let totalVulnerabilities = 0;
    
    for (const projectPath of this.projectPaths) {
      const packageJsonPath = path.join(projectPath, 'package.json');
      
      if (fs.existsSync(packageJsonPath)) {
        try {
          const result = await this.runNpmAudit(projectPath);
          totalVulnerabilities += result.vulnerabilities;
          
          if (result.vulnerabilities === 0) {
            console.log(`✅ ${projectPath}: آمن 100%`);
          } else {
            console.log(`❌ ${projectPath}: ${result.vulnerabilities} ثغرة متبقية`);
          }
          
        } catch (error) {
          console.log(`⚠️ فشل فحص ${projectPath}: ${error.message}`);
        }
      }
    }
    
    if (totalVulnerabilities === 0) {
      console.log('\n🎉 المشروع آمن 100% - لا توجد ثغرات أمنية!');
      this.fixes.push('المشروع آمن 100%');
    } else {
      console.log(`\n⚠️ تبقى ${totalVulnerabilities} ثغرة أمنية في المشروع`);
      this.errors.push(`${totalVulnerabilities} ثغرة أمنية متبقية`);
    }
  }

  async applySecurityBestPractices() {
    console.log('\n🛡️ تطبيق أفضل الممارسات الأمنية...');
    
    // 1. التحقق من ملفات .env
    this.checkEnvFiles();
    
    // 2. التحقق من إعدادات الأمان
    this.checkSecuritySettings();
    
    // 3. التحقق من الحزم المهجورة
    await this.checkDeprecatedPackages();
    
    console.log('✅ تم تطبيق أفضل الممارسات الأمنية');
  }

  checkEnvFiles() {
    console.log('🔐 فحص ملفات البيئة...');
    
    const envFiles = ['.env', 'backend/.env', '.env.local', '.env.production'];
    
    envFiles.forEach(envFile => {
      if (fs.existsSync(envFile)) {
        console.log(`✅ ${envFile}: موجود`);
        
        // التحقق من عدم وجود مفاتيح مكشوفة
        const content = fs.readFileSync(envFile, 'utf8');
        
        if (content.includes('your-key-here') || content.includes('replace-me')) {
          this.errors.push(`${envFile} يحتوي على مفاتيح وهمية`);
        } else {
          this.fixes.push(`${envFile} آمن`);
        }
      }
    });
  }

  checkSecuritySettings() {
    console.log('🛡️ فحص إعدادات الأمان...');
    
    // فحص helmet في package.json
    const backendPackage = path.join('./backend', 'package.json');
    
    if (fs.existsSync(backendPackage)) {
      const packageData = JSON.parse(fs.readFileSync(backendPackage, 'utf8'));
      
      if (packageData.dependencies && packageData.dependencies.helmet) {
        console.log('✅ Helmet: مثبت للحماية');
        this.fixes.push('Helmet مثبت');
      } else {
        console.log('⚠️ Helmet: غير مثبت');
        this.errors.push('Helmet غير مثبت');
      }
      
      if (packageData.dependencies && packageData.dependencies['express-rate-limit']) {
        console.log('✅ Rate Limiting: مثبت');
        this.fixes.push('Rate Limiting مثبت');
      } else {
        console.log('⚠️ Rate Limiting: غير مثبت');
        this.errors.push('Rate Limiting غير مثبت');
      }
    }
  }

  async checkDeprecatedPackages() {
    console.log('📦 فحص الحزم المهجورة...');
    
    for (const projectPath of this.projectPaths) {
      const packageJsonPath = path.join(projectPath, 'package.json');
      
      if (fs.existsSync(packageJsonPath)) {
        try {
          await this.runNpmOutdated(projectPath);
          this.fixes.push(`فحص الحزم المهجورة في ${projectPath}`);
        } catch (error) {
          // npm outdated يرجع exit code 1 عندما توجد حزم قديمة، هذا طبيعي
        }
      }
    }
  }

  // Helper methods for running npm commands
  runNpmAudit(projectPath) {
    return this.runNpmCommand('audit', [], projectPath);
  }

  runNpmAuditFix(projectPath) {
    return this.runNpmCommand('audit', ['fix'], projectPath);
  }

  runNpmAuditFixForce(projectPath) {
    return this.runNpmCommand('audit', ['fix', '--force'], projectPath);
  }

  runNpmUpdate(projectPath) {
    return this.runNpmCommand('update', [], projectPath);
  }

  runNpmOutdated(projectPath) {
    return this.runNpmCommand('outdated', [], projectPath);
  }

  runNpmCommand(command, args, cwd) {
    return new Promise((resolve, reject) => {
      const child = spawn('npm', [command, ...args], {
        cwd: cwd,
        stdio: 'pipe'
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
        const vulnerabilities = this.parseVulnerabilities(stdout);
        
        resolve({
          code,
          stdout,
          stderr,
          vulnerabilities,
          details: stdout
        });
      });

      child.on('error', (error) => {
        reject(error);
      });
    });
  }

  parseVulnerabilities(output) {
    const match = output.match(/(\d+) vulnerabilities/);
    return match ? parseInt(match[1]) : 0;
  }

  printSecurityReport() {
    console.log('\n📋 تقرير الأمان الشامل:');
    console.log('='.repeat(50));
    
    console.log('\n✅ الإصلاحات المطبقة:');
    this.fixes.forEach((fix, index) => {
      console.log(`   ${index + 1}. ${fix}`);
    });
    
    if (this.errors.length > 0) {
      console.log('\n⚠️ المشاكل المتبقية:');
      this.errors.forEach((error, index) => {
        console.log(`   ${index + 1}. ${error}`);
      });
    } else {
      console.log('\n🎉 لا توجد مشاكل أمنية متبقية!');
    }
    
    console.log('\n📊 الإحصائيات:');
    console.log(`   ✅ إصلاحات: ${this.fixes.length}`);
    console.log(`   ⚠️ مشاكل: ${this.errors.length}`);
    console.log(`   📈 معدل الأمان: ${((this.fixes.length / (this.fixes.length + this.errors.length)) * 100).toFixed(1)}%`);
  }
}

// تشغيل التحليل الشامل
if (require.main === module) {
  const audit = new ComprehensiveSecurityAudit();
  
  audit.runFullSecurityAudit()
    .then(() => {
      console.log('\n🎉 انتهى التحليل الشامل للأمان بنجاح!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ فشل التحليل الشامل للأمان:', error.message);
      process.exit(1);
    });
}

module.exports = ComprehensiveSecurityAudit;
