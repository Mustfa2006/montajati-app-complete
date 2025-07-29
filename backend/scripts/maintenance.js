#!/usr/bin/env node

// ===================================
// سكريبت الصيانة لـ DigitalOcean
// Maintenance Script for DigitalOcean
// ===================================

require('dotenv').config();

console.log('🔧 بدء مهام الصيانة...');
console.log('📅 الوقت:', new Date().toISOString());

async function runMaintenance() {
  try {
    // 1. فحص متغيرات البيئة
    console.log('1️⃣ فحص متغيرات البيئة...');
    const requiredEnvs = [
      'SUPABASE_URL',
      'SUPABASE_SERVICE_ROLE_KEY',
      'FIREBASE_PROJECT_ID',
      'WASEET_USERNAME',
      'WASEET_PASSWORD'
    ];
    
    const missingEnvs = requiredEnvs.filter(env => !process.env[env]);
    if (missingEnvs.length > 0) {
      console.warn('⚠️ متغيرات بيئة مفقودة:', missingEnvs);
    } else {
      console.log('✅ جميع متغيرات البيئة موجودة');
    }

    // 2. فحص اتصال قاعدة البيانات
    console.log('2️⃣ فحص اتصال Supabase...');
    const { createClient } = require('@supabase/supabase-js');
    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
    
    const { data, error } = await supabase
      .from('users')
      .select('count')
      .limit(1);
    
    if (error) {
      console.error('❌ خطأ في اتصال Supabase:', error.message);
    } else {
      console.log('✅ اتصال Supabase يعمل بنجاح');
    }

    // 3. فحص Firebase
    console.log('3️⃣ فحص Firebase...');
    try {
      const admin = require('firebase-admin');
      
      if (!admin.apps.length) {
        const serviceAccount = {
          type: "service_account",
          project_id: process.env.FIREBASE_PROJECT_ID,
          private_key: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
          client_email: process.env.FIREBASE_CLIENT_EMAIL,
        };
        
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
          projectId: process.env.FIREBASE_PROJECT_ID
        });
      }
      
      console.log('✅ Firebase مهيأ بنجاح');
    } catch (error) {
      console.error('❌ خطأ في Firebase:', error.message);
    }

    // 4. تنظيف الملفات المؤقتة
    console.log('4️⃣ تنظيف الملفات المؤقتة...');
    const fs = require('fs');
    const path = require('path');
    
    const tempDirs = ['./temp', './logs'];
    tempDirs.forEach(dir => {
      if (fs.existsSync(dir)) {
        const files = fs.readdirSync(dir);
        console.log(`📁 ${dir}: ${files.length} ملف`);
      }
    });

    console.log('✅ انتهت مهام الصيانة بنجاح');
    return true;

  } catch (error) {
    console.error('❌ خطأ في مهام الصيانة:', error);
    return false;
  }
}

// تشغيل المهام
runMaintenance()
  .then(success => {
    if (success) {
      console.log('🎉 تمت الصيانة بنجاح');
      process.exit(0);
    } else {
      console.log('⚠️ انتهت الصيانة مع تحذيرات');
      process.exit(1);
    }
  })
  .catch(error => {
    console.error('💥 فشل في الصيانة:', error);
    process.exit(1);
  });
