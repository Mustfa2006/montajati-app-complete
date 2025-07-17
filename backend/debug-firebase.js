#!/usr/bin/env node

/**
 * أداة تشخيص شاملة لمشكلة Firebase في Render
 */

console.log('🔍 بدء التشخيص الشامل لـ Firebase...\n');

// 1. فحص متغيرات البيئة الخام
console.log('=== 1. فحص متغيرات البيئة الخام ===');
console.log('NODE_ENV:', process.env.NODE_ENV);
console.log('RENDER:', process.env.RENDER);
console.log('PORT:', process.env.PORT);

// 2. فحص جميع متغيرات Firebase
console.log('\n=== 2. فحص جميع متغيرات Firebase ===');
const firebaseVars = Object.keys(process.env).filter(key => key.includes('FIREBASE'));
console.log('عدد متغيرات Firebase الموجودة:', firebaseVars.length);
firebaseVars.forEach(key => {
  const value = process.env[key];
  console.log(`${key}:`, value ? `موجود (${value.length} حرف)` : 'غير موجود');
  
  if (value && key === 'FIREBASE_PRIVATE_KEY') {
    console.log(`  - النوع: ${typeof value}`);
    console.log(`  - أول 50 حرف: "${value.substring(0, 50)}..."`);
    console.log(`  - آخر 50 حرف: "...${value.substring(value.length - 50)}"`);
    console.log(`  - يحتوي على BEGIN: ${value.includes('BEGIN PRIVATE KEY')}`);
    console.log(`  - يحتوي على END: ${value.includes('END PRIVATE KEY')}`);
    console.log(`  - يحتوي على \\n: ${value.includes('\\n')}`);
    console.log(`  - يحتوي على newlines: ${value.includes('\n')}`);
    console.log(`  - عدد الأسطر: ${value.split('\n').length}`);
  }
});

// 3. محاولة تحميل dotenv
console.log('\n=== 3. فحص dotenv ===');
try {
  require('dotenv').config();
  console.log('✅ تم تحميل dotenv بنجاح');
} catch (error) {
  console.log('❌ خطأ في تحميل dotenv:', error.message);
}

// 4. فحص ملفات البيئة
console.log('\n=== 4. فحص ملفات البيئة ===');
const fs = require('fs');
const path = require('path');

const envFiles = ['.env', '.env.local', '.env.production'];
envFiles.forEach(file => {
  const filePath = path.join(__dirname, file);
  if (fs.existsSync(filePath)) {
    console.log(`✅ ${file} موجود`);
    try {
      const content = fs.readFileSync(filePath, 'utf8');
      const lines = content.split('\n').filter(line => line.includes('FIREBASE'));
      console.log(`  - يحتوي على ${lines.length} متغير Firebase`);
      lines.forEach(line => console.log(`    ${line.substring(0, 50)}...`));
    } catch (error) {
      console.log(`  - خطأ في قراءة ${file}:`, error.message);
    }
  } else {
    console.log(`❌ ${file} غير موجود`);
  }
});

// 5. محاولة إنشاء Firebase Admin SDK
console.log('\n=== 5. محاولة تهيئة Firebase ===');
try {
  const admin = require('firebase-admin');
  
  // فحص إذا كان Firebase مهيأ مسبقاً
  if (admin.apps.length > 0) {
    console.log('⚠️ Firebase مهيأ مسبقاً، سيتم حذف التهيئة السابقة');
    admin.apps.forEach(app => app.delete());
  }
  
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  
  console.log('المتغيرات المطلوبة:');
  console.log(`  - PROJECT_ID: ${projectId ? '✅' : '❌'}`);
  console.log(`  - PRIVATE_KEY: ${privateKey ? '✅' : '❌'}`);
  console.log(`  - CLIENT_EMAIL: ${clientEmail ? '✅' : '❌'}`);
  
  if (projectId && privateKey && clientEmail) {
    // تنظيف المفتاح
    let cleanPrivateKey = privateKey;
    if (cleanPrivateKey.includes('\\n')) {
      cleanPrivateKey = cleanPrivateKey.replace(/\\n/g, '\n');
      console.log('🔧 تم تحويل \\n إلى newlines');
    }
    
    const serviceAccount = {
      type: "service_account",
      project_id: projectId,
      private_key: cleanPrivateKey,
      client_email: clientEmail,
    };
    
    console.log('محاولة تهيئة Firebase...');
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: projectId
    });
    
    console.log('✅ تم تهيئة Firebase بنجاح!');
    
    // اختبار إرسال إشعار تجريبي
    console.log('اختبار إرسال إشعار...');
    const messaging = admin.messaging();
    console.log('✅ تم الحصول على خدمة Messaging');
    
  } else {
    console.log('❌ متغيرات Firebase غير مكتملة');
  }
  
} catch (error) {
  console.log('❌ خطأ في تهيئة Firebase:');
  console.log('النوع:', error.constructor.name);
  console.log('الرسالة:', error.message);
  console.log('الكود:', error.code);
  if (error.stack) {
    console.log('Stack trace:', error.stack.split('\n').slice(0, 5).join('\n'));
  }
}

// 6. فحص الشبكة والاتصال
console.log('\n=== 6. فحص الاتصال ===');
const https = require('https');

const testUrls = [
  'https://www.googleapis.com',
  'https://firebase.googleapis.com',
  'https://oauth2.googleapis.com'
];

testUrls.forEach(url => {
  https.get(url, (res) => {
    console.log(`✅ ${url}: ${res.statusCode}`);
  }).on('error', (err) => {
    console.log(`❌ ${url}: ${err.message}`);
  });
});

// 7. فحص إصدارات المكتبات
console.log('\n=== 7. فحص إصدارات المكتبات ===');
try {
  const packageJson = require('./package.json');
  console.log('firebase-admin:', packageJson.dependencies['firebase-admin'] || 'غير موجود');
  console.log('dotenv:', packageJson.dependencies['dotenv'] || 'غير موجود');
} catch (error) {
  console.log('❌ خطأ في قراءة package.json:', error.message);
}

console.log('\n🔍 انتهى التشخيص الشامل');
