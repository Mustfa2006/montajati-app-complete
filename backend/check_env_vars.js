// ===================================
// فحص متغيرات البيئة المطلوبة
// Check Required Environment Variables
// ===================================

require('dotenv').config();

console.log('🔍 فحص متغيرات البيئة المطلوبة...\n');

const requiredVars = [
  'SUPABASE_URL',
  'SUPABASE_SERVICE_ROLE_KEY',
  'FIREBASE_SERVICE_ACCOUNT'
];

let allPresent = true;

requiredVars.forEach(varName => {
  const value = process.env[varName];
  if (value) {
    if (varName === 'FIREBASE_SERVICE_ACCOUNT') {
      try {
        const parsed = JSON.parse(value);
        console.log(`✅ ${varName}: موجود وصالح`);
        console.log(`   📋 Project ID: ${parsed.project_id}`);
        console.log(`   📧 Client Email: ${parsed.client_email}`);
      } catch (e) {
        console.log(`❌ ${varName}: موجود لكن JSON غير صالح`);
        allPresent = false;
      }
    } else {
      console.log(`✅ ${varName}: موجود`);
    }
  } else {
    console.log(`❌ ${varName}: مفقود`);
    allPresent = false;
  }
});

console.log('\n' + '='.repeat(50));

if (allPresent) {
  console.log('✅ جميع متغيرات البيئة المطلوبة موجودة!');
  process.exit(0);
} else {
  console.log('❌ بعض متغيرات البيئة مفقودة!');
  process.exit(1);
}
