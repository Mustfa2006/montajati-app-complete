// ===================================
// فحص متغيرات البيئة المطلوبة
// Check Required Environment Variables
// ===================================

require('dotenv').config();

console.log('🔍 فحص متغيرات البيئة المطلوبة...\n');

const requiredVars = [
  'SUPABASE_URL',
  'SUPABASE_SERVICE_ROLE_KEY',
  'FIREBASE_PROJECT_ID',
  'FIREBASE_PRIVATE_KEY',
  'FIREBASE_CLIENT_EMAIL',
  'FIREBASE_CLIENT_ID'
];

let allPresent = true;

requiredVars.forEach(varName => {
  const value = process.env[varName];
  if (value) {
    console.log(`✅ ${varName}: موجود`);
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
