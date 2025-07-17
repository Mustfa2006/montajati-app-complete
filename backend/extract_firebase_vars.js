// ===================================
// استخراج متغيرات Firebase من ملف JSON
// ===================================

const fs = require('fs');
const path = require('path');

function extractFirebaseVars() {
  console.log('🔥 استخراج متغيرات Firebase من ملف JSON\n');
  
  // البحث عن ملف Firebase Service Account
  const possiblePaths = [
    './firebase-service-account.json',
    './config/firebase-service-account.json',
    './withdrawal-notifications-firebase-adminsdk.json'
  ];
  
  let serviceAccountPath = null;
  
  for (const filePath of possiblePaths) {
    if (fs.existsSync(filePath)) {
      serviceAccountPath = filePath;
      break;
    }
  }
  
  if (!serviceAccountPath) {
    console.log('❌ لم يتم العثور على ملف Firebase Service Account JSON');
    console.log('💡 ضع الملف في أحد المواقع التالية:');
    possiblePaths.forEach(p => console.log(`   - ${p}`));
    console.log('\n📥 لتحميل الملف:');
    console.log('1. اذهب إلى Firebase Console');
    console.log('2. Project Settings > Service accounts');
    console.log('3. Generate new private key');
    console.log('4. احفظ الملف في مجلد المشروع');
    return;
  }
  
  try {
    console.log(`📁 تم العثور على الملف: ${serviceAccountPath}`);
    
    // قراءة الملف
    const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
    
    // استخراج البيانات المطلوبة
    const projectId = serviceAccount.project_id;
    const privateKey = serviceAccount.private_key;
    const clientEmail = serviceAccount.client_email;
    
    if (!projectId || !privateKey || !clientEmail) {
      console.log('❌ الملف لا يحتوي على البيانات المطلوبة');
      return;
    }
    
    console.log('✅ تم استخراج البيانات بنجاح\n');
    
    // عرض المتغيرات للنسخ
    console.log('📋 متغيرات Render Environment Variables:\n');
    
    console.log('FIREBASE_PROJECT_ID:');
    console.log(projectId);
    console.log('');
    
    console.log('FIREBASE_CLIENT_EMAIL:');
    console.log(clientEmail);
    console.log('');
    
    console.log('FIREBASE_PRIVATE_KEY:');
    // تحويل المفتاح لتنسيق Render (سطر واحد مع \\n)
    const renderPrivateKey = privateKey.replace(/\n/g, '\\n');
    console.log(renderPrivateKey);
    console.log('');
    
    // حفظ في ملف .env للاختبار المحلي
    const envContent = `
# Firebase Configuration
FIREBASE_PROJECT_ID=${projectId}
FIREBASE_CLIENT_EMAIL=${clientEmail}
FIREBASE_PRIVATE_KEY="${privateKey.replace(/\n/g, '\\n')}"
`;
    
    fs.writeFileSync('.env.firebase', envContent.trim());
    console.log('💾 تم حفظ المتغيرات في .env.firebase للاختبار المحلي');
    
    // إنشاء ملف تعليمات
    const instructions = `
# تعليمات إضافة متغيرات Firebase في Render

1. اذهب إلى Render Dashboard: https://dashboard.render.com/
2. اختر الخدمة: montajati-backend
3. اذهب إلى Environment
4. أضف المتغيرات التالية:

## FIREBASE_PROJECT_ID
${projectId}

## FIREBASE_CLIENT_EMAIL  
${clientEmail}

## FIREBASE_PRIVATE_KEY
${renderPrivateKey}

5. احفظ وأعد النشر
`;
    
    fs.writeFileSync('RENDER_FIREBASE_INSTRUCTIONS.txt', instructions.trim());
    console.log('📝 تم إنشاء ملف التعليمات: RENDER_FIREBASE_INSTRUCTIONS.txt');
    
    console.log('\n🎯 الخطوات التالية:');
    console.log('1. انسخ المتغيرات أعلاه');
    console.log('2. اذهب إلى Render Dashboard');
    console.log('3. أضف المتغيرات في Environment Variables');
    console.log('4. احفظ وأعد النشر');
    console.log('5. تحقق من النجاح في سجل Render');
    
  } catch (error) {
    console.log(`❌ خطأ في قراءة الملف: ${error.message}`);
  }
}

if (require.main === module) {
  extractFirebaseVars();
}

module.exports = extractFirebaseVars;
