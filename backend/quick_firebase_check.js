// ===================================
// فحص سريع لمتغيرات Firebase في Render
// ===================================

require('dotenv').config();

console.log('🔥 فحص سريع لمتغيرات Firebase');
console.log('=' * 40);

// فحص المتغيرات الأساسية
const vars = {
  'FIREBASE_PROJECT_ID': process.env.FIREBASE_PROJECT_ID,
  'FIREBASE_CLIENT_EMAIL': process.env.FIREBASE_CLIENT_EMAIL,
  'FIREBASE_PRIVATE_KEY': process.env.FIREBASE_PRIVATE_KEY
};

console.log('📋 حالة المتغيرات:');
Object.keys(vars).forEach(key => {
  const value = vars[key];
  if (value) {
    console.log(`✅ ${key}: موجود (${value.length} حرف)`);
    if (key === 'FIREBASE_PRIVATE_KEY') {
      console.log(`   🔍 يبدأ بـ: "${value.substring(0, 30)}..."`);
      console.log(`   🔍 ينتهي بـ: "...${value.substring(value.length - 30)}"`);
    }
  } else {
    console.log(`❌ ${key}: مفقود`);
  }
});

// فحص جميع متغيرات البيئة
console.log('\n🔍 جميع متغيرات البيئة:');
const allVars = Object.keys(process.env).filter(key => 
  key.includes('FIREBASE') || key.includes('NODE_ENV') || key.includes('PORT')
);

allVars.forEach(key => {
  const value = process.env[key];
  console.log(`  ${key}: ${value ? `"${value.substring(0, 50)}${value.length > 50 ? '...' : ''}"` : 'غير موجود'}`);
});

console.log('\n' + '=' * 40);
console.log('🏁 انتهى الفحص السريع');
