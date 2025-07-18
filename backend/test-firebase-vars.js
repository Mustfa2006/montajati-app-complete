#!/usr/bin/env node

/**
 * اختبار سريع لمتغيرات Firebase في Render
 * يجب تشغيله قبل بدء الخادم للتأكد من صحة المتغيرات
 */

console.log('🧪 اختبار متغيرات Firebase في Render...\n');

// تحميل dotenv
require('dotenv').config();

// تشغيل نفس الإصلاح الموجود في render-start.js
if (process.env.FIREBASE_PRIVATE_KEY) {
  let privateKey = process.env.FIREBASE_PRIVATE_KEY;

  // إصلاح شامل لمشكلة Private Key في Render
  privateKey = privateKey
    .replace(/\\n/g, '\n')  // تحويل \\n إلى أسطر جديدة حقيقية
    .replace(/\s+-----BEGIN PRIVATE KEY-----/g, '-----BEGIN PRIVATE KEY-----')
    .replace(/-----END PRIVATE KEY-----\s+/g, '-----END PRIVATE KEY-----')
    .replace(/\s+/g, ' ')  // تنظيف المسافات الزائدة
    .trim();

  // التأكد من وجود header و footer
  if (!privateKey.includes('-----BEGIN PRIVATE KEY-----')) {
    privateKey = '-----BEGIN PRIVATE KEY-----\n' + privateKey;
  }
  if (!privateKey.includes('-----END PRIVATE KEY-----')) {
    privateKey = privateKey + '\n-----END PRIVATE KEY-----';
  }

  // إعادة تنسيق المفتاح بشكل صحيح
  const lines = privateKey.split('\n');
  const cleanLines = [];

  for (let line of lines) {
    line = line.trim();
    if (line === '-----BEGIN PRIVATE KEY-----' || line === '-----END PRIVATE KEY-----') {
      cleanLines.push(line);
    } else if (line.length > 0 && !line.includes('-----')) {
      // تقسيم السطور الطويلة إلى 64 حرف
      while (line.length > 64) {
        cleanLines.push(line.substring(0, 64));
        line = line.substring(64);
      }
      if (line.length > 0) {
        cleanLines.push(line);
      }
    }
  }

  process.env.FIREBASE_PRIVATE_KEY = cleanLines.join('\n');
  console.log('🔧 تم إصلاح Firebase Private Key');
}

// فحص المتغيرات
const projectId = process.env.FIREBASE_PROJECT_ID;
const privateKey = process.env.FIREBASE_PRIVATE_KEY;
const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;

console.log('📋 نتائج الفحص:');
console.log(`  FIREBASE_PROJECT_ID: ${projectId ? '✅ موجود' : '❌ مفقود'}`);
console.log(`  FIREBASE_PRIVATE_KEY: ${privateKey ? '✅ موجود' : '❌ مفقود'}`);
console.log(`  FIREBASE_CLIENT_EMAIL: ${clientEmail ? '✅ موجود' : '❌ مفقود'}`);

if (privateKey) {
  console.log(`  📏 طول المفتاح: ${privateKey.length} حرف`);
  console.log(`  🔤 يبدأ بـ BEGIN: ${privateKey.includes('-----BEGIN PRIVATE KEY-----') ? '✅' : '❌'}`);
  console.log(`  🔤 ينتهي بـ END: ${privateKey.includes('-----END PRIVATE KEY-----') ? '✅' : '❌'}`);
}

// محاولة تهيئة Firebase
if (projectId && privateKey && clientEmail) {
  console.log('\n🔥 محاولة تهيئة Firebase...');
  try {
    const admin = require('firebase-admin');
    
    // حذف التهيئة السابقة إن وجدت
    if (admin.apps.length > 0) {
      admin.apps.forEach(app => app.delete());
    }
    
    const serviceAccount = {
      type: "service_account",
      project_id: projectId,
      private_key: privateKey,
      client_email: clientEmail,
    };
    
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: projectId
    });
    
    console.log('✅ تم تهيئة Firebase بنجاح!');
    console.log('🎉 جميع متغيرات Firebase تعمل بشكل صحيح');
    
  } catch (error) {
    console.log('❌ فشل في تهيئة Firebase:');
    console.log(`   النوع: ${error.constructor.name}`);
    console.log(`   الرسالة: ${error.message}`);
    if (error.code) {
      console.log(`   الكود: ${error.code}`);
    }
  }
} else {
  console.log('\n❌ متغيرات Firebase غير مكتملة');
  console.log('💡 تأكد من إضافة جميع المتغيرات في Render Environment Variables');
}

console.log('\n🏁 انتهى الاختبار');
