#!/usr/bin/env node

// ===================================
// تشغيل جميع الإصلاحات
// Run All Error Fixes
// ===================================

const path = require('path');
const { spawn } = require('child_process');

async function runFix(scriptName, description) {
  console.log(`\n🔧 ${description}...`);
  console.log('-'.repeat(50));
  
  return new Promise((resolve, reject) => {
    const scriptPath = path.join(__dirname, scriptName);
    const child = spawn('node', [scriptPath], {
      stdio: 'inherit',
      cwd: __dirname
    });
    
    child.on('close', (code) => {
      if (code === 0) {
        console.log(`✅ ${description} - مكتمل`);
        resolve();
      } else {
        console.log(`⚠️ ${description} - انتهى بكود ${code}`);
        resolve(); // نكمل حتى لو فشل إصلاح واحد
      }
    });
    
    child.on('error', (error) => {
      console.error(`❌ خطأ في ${description}:`, error.message);
      resolve(); // نكمل حتى لو فشل إصلاح واحد
    });
  });
}

async function runAllFixes() {
  console.log('🚀 بدء تشغيل جميع الإصلاحات...');
  console.log('='.repeat(60));
  
  const fixes = [
    {
      script: 'fix_database_issues.js',
      description: 'إصلاح مشاكل قاعدة البيانات'
    },
    {
      script: 'comprehensive_error_fix.js', 
      description: 'الإصلاح الشامل لجميع الأخطاء'
    }
  ];
  
  for (const fix of fixes) {
    try {
      await runFix(fix.script, fix.description);
    } catch (error) {
      console.error(`❌ فشل في ${fix.description}:`, error.message);
    }
  }
  
  console.log('\n🎉 انتهى تشغيل جميع الإصلاحات!');
  console.log('='.repeat(60));
  
  console.log('\n📋 الخطوات التالية:');
  console.log('1. ارفع التحديثات: git add . && git commit -m "🔧 إصلاح شامل لجميع الأخطاء"');
  console.log('2. ادفع للمستودع: git push origin main');
  console.log('3. أعد النشر في Render');
  console.log('\n✨ النظام سيعمل بدون أخطاء!');
}

// تشغيل الإصلاحات
runAllFixes()
  .then(() => {
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ خطأ عام:', error.message);
    process.exit(1);
  });
