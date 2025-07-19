// ===================================
// الحصول على متغيرات Firebase جاهزة للنسخ في Render
// ===================================

require('dotenv').config();

function getRenderFirebaseVars() {
  console.log('🔥 متغيرات Firebase جاهزة للنسخ في Render\n');
  
  // التحقق من وجود المتغيرات محلياً
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  
  if (!projectId || !privateKey || !clientEmail) {
    console.log('❌ متغيرات Firebase غير موجودة محلياً');
    console.log('💡 تأكد من وجود ملف .env مع المتغيرات');
    return;
  }
  
  console.log('✅ تم العثور على متغيرات Firebase محلياً\n');
  
  // عرض القيم جاهزة للنسخ
  console.log('📋 انسخ والصق هذه القيم بالضبط في Render:\n');
  
  console.log('=' .repeat(60));
  console.log('FIREBASE_PROJECT_ID');
  console.log('=' .repeat(60));
  console.log(projectId);
  console.log('');
  
  console.log('=' .repeat(60));
  console.log('FIREBASE_CLIENT_EMAIL');
  console.log('=' .repeat(60));
  console.log(clientEmail);
  console.log('');
  
  console.log('=' .repeat(60));
  console.log('FIREBASE_PRIVATE_KEY');
  console.log('=' .repeat(60));
  // تحويل المفتاح لتنسيق Render (استبدال \n بـ \\n)
  const renderKey = privateKey.replace(/\n/g, '\\n');
  console.log(renderKey);
  console.log('');
  
  console.log('🎯 تعليمات النسخ واللصق:');
  console.log('1. اذهب إلى: https://dashboard.render.com/');
  console.log('2. اختر: montajati-backend');
  console.log('3. اضغط: Environment');
  console.log('4. أضف متغير جديد');
  console.log('5. انسخ اسم المتغير والقيمة بالضبط كما هو أعلاه');
  console.log('6. كرر للمتغيرات الثلاثة');
  console.log('7. احفظ');
  
  // حفظ في ملف للمرجع
  const content = `
FIREBASE_PROJECT_ID=${projectId}

FIREBASE_CLIENT_EMAIL=${clientEmail}

FIREBASE_PRIVATE_KEY=${renderKey}
`;
  
  require('fs').writeFileSync('render_firebase_vars.txt', content.trim());
  console.log('\n💾 تم حفظ القيم في: render_firebase_vars.txt');
}

if (require.main === module) {
  getRenderFirebaseVars();
}

module.exports = getRenderFirebaseVars;
