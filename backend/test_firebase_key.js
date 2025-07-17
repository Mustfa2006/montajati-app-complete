// ===================================
// اختبار Firebase Private Key
// ===================================

require('dotenv').config();

function testFirebaseKey() {
  console.log('🔍 اختبار Firebase Private Key...');
  
  const privateKey = process.env.FIREBASE_PRIVATE_KEY;
  
  if (!privateKey) {
    console.log('❌ FIREBASE_PRIVATE_KEY غير موجود');
    return false;
  }
  
  console.log('📋 طول المفتاح:', privateKey.length);
  console.log('📋 أول 50 حرف:', privateKey.substring(0, 50));
  console.log('📋 آخر 50 حرف:', privateKey.substring(privateKey.length - 50));
  
  // فحص التنسيق
  const hasBegin = privateKey.includes('-----BEGIN PRIVATE KEY-----');
  const hasEnd = privateKey.includes('-----END PRIVATE KEY-----');
  const hasNewlines = privateKey.includes('\n');
  
  console.log('✅ يحتوي على BEGIN:', hasBegin);
  console.log('✅ يحتوي على END:', hasEnd);
  console.log('✅ يحتوي على أسطر جديدة:', hasNewlines);
  
  if (hasBegin && hasEnd) {
    console.log('✅ تنسيق المفتاح صحيح');
    return true;
  } else {
    console.log('❌ تنسيق المفتاح خاطئ');
    return false;
  }
}

if (require.main === module) {
  testFirebaseKey();
}
