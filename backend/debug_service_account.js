// ===================================
// فحص محتوى FIREBASE_SERVICE_ACCOUNT في Render
// ===================================

require('dotenv').config();

console.log('🔍 فحص محتوى FIREBASE_SERVICE_ACCOUNT في Render');
console.log('=' * 60);

const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT;

if (!serviceAccount) {
  console.log('❌ FIREBASE_SERVICE_ACCOUNT غير موجود');
  process.exit(1);
}

console.log(`📏 طول FIREBASE_SERVICE_ACCOUNT: ${serviceAccount.length} حرف`);
console.log(`🔍 أول 100 حرف: "${serviceAccount.substring(0, 100)}..."`);
console.log(`🔍 آخر 100 حرف: "...${serviceAccount.substring(serviceAccount.length - 100)}"`);

try {
  const parsed = JSON.parse(serviceAccount);
  console.log('\n✅ تم تحليل JSON بنجاح');
  console.log('📋 المفاتيح الموجودة:');
  Object.keys(parsed).forEach(key => {
    const value = parsed[key];
    if (typeof value === 'string') {
      console.log(`  ${key}: ${value.length} حرف`);
      if (key === 'private_key') {
        console.log(`    🔍 أول 50 حرف: "${value.substring(0, 50)}..."`);
        console.log(`    🔍 آخر 50 حرف: "...${value.substring(value.length - 50)}"`);
        console.log(`    🔤 يحتوي على BEGIN: ${value.includes('BEGIN PRIVATE KEY')}`);
        console.log(`    🔤 يحتوي على END: ${value.includes('END PRIVATE KEY')}`);
        
        // فحص عدد الأسطر
        const lines = value.split('\n');
        console.log(`    📝 عدد الأسطر: ${lines.length}`);
        
        // فحص المحتوى الفعلي
        const content = value
          .replace('-----BEGIN PRIVATE KEY-----', '')
          .replace('-----END PRIVATE KEY-----', '')
          .replace(/\s/g, '');
        console.log(`    🔐 محتوى المفتاح الفعلي: ${content.length} حرف`);
        
        if (content.length < 1000) {
          console.log('    ⚠️ المفتاح قصير جداً! يجب أن يكون أكثر من 1000 حرف');
        }
      }
    } else {
      console.log(`  ${key}: ${typeof value}`);
    }
  });
  
} catch (error) {
  console.log(`❌ خطأ في تحليل JSON: ${error.message}`);
  console.log('\n🔍 محتوى FIREBASE_SERVICE_ACCOUNT الخام:');
  console.log(serviceAccount);
}

console.log('\n' + '=' * 60);
console.log('🏁 انتهى الفحص');
