// ===================================
// الإصلاح النهائي للثغرات الأمنية
// Final Security Fix
// ===================================

const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

class FinalSecurityFix {
  constructor() {
    this.results = [];
  }

  async runFinalFix() {
    console.log('🔒 الإصلاح النهائي للثغرات الأمنية...');
    console.log('='.repeat(60));

    try {
      // 1. فحص وإصلاح المجلد الجذر
      await this.fixRootDirectory();
      
      // 2. فحص وإصلاح مجلد backend
      await this.fixBackendDirectory();
      
      // 3. فحص وإصلاح مجلد frontend
      await this.fixFrontendDirectory();
      
      // 4. التحقق النهائي
      await this.finalVerification();

      this.printFinalReport();
      
    } catch (error) {
      console.error('❌ خطأ في الإصلاح النهائي:', error.message);
      throw error;
    }
  }

  async fixRootDirectory() {
    console.log('\n📁 إصلاح المجلد الجذر...');
    
    const rootPath = path.resolve('..');
    
    if (fs.existsSync(path.join(rootPath, 'package.json'))) {
      console.log('📦 وجدت package.json في المجلد الجذر');
      
      try {
        const result = await this.runCommand('npm', ['audit'], rootPath);
        const vulnerabilities = this.parseVulnerabilities(result.stdout);
        
        if (vulnerabilities > 0) {
          console.log(`❌ وجدت ${vulnerabilities} ثغرة في المجلد الجذر`);
          
          // إصلاح الثغرات
          await this.runCommand('npm', ['audit', 'fix'], rootPath);
          
          // فحص نهائي
          const finalResult = await this.runCommand('npm', ['audit'], rootPath);
          const finalVulns = this.parseVulnerabilities(finalResult.stdout);
          
          if (finalVulns === 0) {
            console.log('✅ تم إصلاح جميع الثغرات في المجلد الجذر');
            this.results.push('✅ المجلد الجذر: آمن');
          } else {
            console.log(`⚠️ تبقى ${finalVulns} ثغرة في المجلد الجذر`);
            this.results.push(`⚠️ المجلد الجذر: ${finalVulns} ثغرة متبقية`);
          }
        } else {
          console.log('✅ المجلد الجذر آمن');
          this.results.push('✅ المجلد الجذر: آمن');
        }
        
      } catch (error) {
        console.log('⚠️ فشل فحص المجلد الجذر:', error.message);
        this.results.push('⚠️ المجلد الجذر: فشل الفحص');
      }
    } else {
      console.log('⚠️ لا يوجد package.json في المجلد الجذر');
      this.results.push('⚠️ المجلد الجذر: لا يوجد package.json');
    }
  }

  async fixBackendDirectory() {
    console.log('\n📁 إصلاح مجلد backend...');
    
    const backendPath = path.resolve('.');
    
    if (fs.existsSync(path.join(backendPath, 'package.json'))) {
      console.log('📦 وجدت package.json في مجلد backend');
      
      try {
        const result = await this.runCommand('npm', ['audit'], backendPath);
        const vulnerabilities = this.parseVulnerabilities(result.stdout);
        
        if (vulnerabilities > 0) {
          console.log(`❌ وجدت ${vulnerabilities} ثغرة في مجلد backend`);
          
          // إصلاح الثغرات
          await this.runCommand('npm', ['audit', 'fix'], backendPath);
          
          // إصلاح قسري إذا لزم الأمر
          await this.runCommand('npm', ['audit', 'fix', '--force'], backendPath);
          
          // فحص نهائي
          const finalResult = await this.runCommand('npm', ['audit'], backendPath);
          const finalVulns = this.parseVulnerabilities(finalResult.stdout);
          
          if (finalVulns === 0) {
            console.log('✅ تم إصلاح جميع الثغرات في مجلد backend');
            this.results.push('✅ مجلد backend: آمن');
          } else {
            console.log(`⚠️ تبقى ${finalVulns} ثغرة في مجلد backend`);
            this.results.push(`⚠️ مجلد backend: ${finalVulns} ثغرة متبقية`);
          }
        } else {
          console.log('✅ مجلد backend آمن');
          this.results.push('✅ مجلد backend: آمن');
        }
        
      } catch (error) {
        console.log('⚠️ فشل فحص مجلد backend:', error.message);
        this.results.push('⚠️ مجلد backend: فشل الفحص');
      }
    } else {
      console.log('⚠️ لا يوجد package.json في مجلد backend');
      this.results.push('⚠️ مجلد backend: لا يوجد package.json');
    }
  }

  async fixFrontendDirectory() {
    console.log('\n📁 إصلاح مجلد frontend...');
    
    const frontendPath = path.resolve('../frontend');
    
    if (fs.existsSync(path.join(frontendPath, 'package.json'))) {
      console.log('📦 وجدت package.json في مجلد frontend');
      
      try {
        // إنشاء package-lock.json إذا لم يكن موجوداً
        if (!fs.existsSync(path.join(frontendPath, 'package-lock.json'))) {
          console.log('📦 إنشاء package-lock.json...');
          await this.runCommand('npm', ['install', '--package-lock-only'], frontendPath);
        }
        
        const result = await this.runCommand('npm', ['audit'], frontendPath);
        const vulnerabilities = this.parseVulnerabilities(result.stdout);
        
        if (vulnerabilities > 0) {
          console.log(`❌ وجدت ${vulnerabilities} ثغرة في مجلد frontend`);
          
          // إصلاح الثغرات
          await this.runCommand('npm', ['audit', 'fix'], frontendPath);
          
          // فحص نهائي
          const finalResult = await this.runCommand('npm', ['audit'], frontendPath);
          const finalVulns = this.parseVulnerabilities(finalResult.stdout);
          
          if (finalVulns === 0) {
            console.log('✅ تم إصلاح جميع الثغرات في مجلد frontend');
            this.results.push('✅ مجلد frontend: آمن');
          } else {
            console.log(`⚠️ تبقى ${finalVulns} ثغرة في مجلد frontend`);
            this.results.push(`⚠️ مجلد frontend: ${finalVulns} ثغرة متبقية`);
          }
        } else {
          console.log('✅ مجلد frontend آمن');
          this.results.push('✅ مجلد frontend: آمن');
        }
        
      } catch (error) {
        console.log('⚠️ فشل فحص مجلد frontend:', error.message);
        this.results.push('⚠️ مجلد frontend: فشل الفحص');
      }
    } else {
      console.log('⚠️ لا يوجد package.json في مجلد frontend');
      this.results.push('⚠️ مجلد frontend: لا يوجد package.json');
    }
  }

  async finalVerification() {
    console.log('\n🔍 التحقق النهائي من الأمان...');
    
    let totalVulnerabilities = 0;
    const paths = [
      { name: 'المجلد الجذر', path: path.resolve('..') },
      { name: 'مجلد backend', path: path.resolve('.') },
      { name: 'مجلد frontend', path: path.resolve('../frontend') }
    ];
    
    for (const pathInfo of paths) {
      if (fs.existsSync(path.join(pathInfo.path, 'package.json'))) {
        try {
          const result = await this.runCommand('npm', ['audit'], pathInfo.path);
          const vulnerabilities = this.parseVulnerabilities(result.stdout);
          totalVulnerabilities += vulnerabilities;
          
          if (vulnerabilities === 0) {
            console.log(`✅ ${pathInfo.name}: آمن 100%`);
          } else {
            console.log(`❌ ${pathInfo.name}: ${vulnerabilities} ثغرة متبقية`);
          }
          
        } catch (error) {
          console.log(`⚠️ فشل فحص ${pathInfo.name}: ${error.message}`);
        }
      }
    }
    
    if (totalVulnerabilities === 0) {
      console.log('\n🎉 المشروع آمن 100% - لا توجد ثغرات أمنية!');
      this.results.push('🎉 المشروع آمن 100%');
    } else {
      console.log(`\n⚠️ تبقى ${totalVulnerabilities} ثغرة أمنية في المشروع`);
      this.results.push(`⚠️ ${totalVulnerabilities} ثغرة أمنية متبقية`);
    }
  }

  runCommand(command, args, cwd) {
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
        resolve({
          code,
          stdout,
          stderr
        });
      });

      child.on('error', (error) => {
        reject(error);
      });
    });
  }

  parseVulnerabilities(output) {
    if (output.includes('found 0 vulnerabilities')) {
      return 0;
    }
    
    const match = output.match(/(\d+) vulnerabilities/);
    return match ? parseInt(match[1]) : 0;
  }

  printFinalReport() {
    console.log('\n📋 التقرير النهائي للأمان:');
    console.log('='.repeat(50));
    
    this.results.forEach((result, index) => {
      console.log(`   ${index + 1}. ${result}`);
    });
    
    const secureCount = this.results.filter(r => r.includes('✅')).length;
    const totalCount = this.results.length;
    const securityPercentage = ((secureCount / totalCount) * 100).toFixed(1);
    
    console.log('\n📊 إحصائيات الأمان:');
    console.log(`   🔒 المجلدات الآمنة: ${secureCount}/${totalCount}`);
    console.log(`   📈 معدل الأمان: ${securityPercentage}%`);
    
    if (securityPercentage === '100.0') {
      console.log('\n🎉 تهانينا! المشروع آمن 100%');
    } else {
      console.log('\n⚠️ يحتاج المشروع إلى مزيد من الإصلاحات الأمنية');
    }
  }
}

// تشغيل الإصلاح النهائي
if (require.main === module) {
  const fixer = new FinalSecurityFix();
  
  fixer.runFinalFix()
    .then(() => {
      console.log('\n🎉 انتهى الإصلاح النهائي للأمان بنجاح!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ فشل الإصلاح النهائي للأمان:', error.message);
      process.exit(1);
    });
}

module.exports = FinalSecurityFix;
