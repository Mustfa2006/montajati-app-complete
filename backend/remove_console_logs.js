// ===================================
// سكريبت لإزالة جميع console.log من ملف orders.js
// ===================================

const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, 'routes', 'orders.js');

// قراءة الملف
let content = fs.readFileSync(filePath, 'utf8');

// عد console.log قبل الإزالة
const beforeCount = (content.match(/console\.(log|info|debug)/g) || []).length;
console.log(`📊 عدد console.log قبل الإزالة: ${beforeCount}`);

// إزالة جميع console.log و console.info و console.debug
// لكن نبقي console.error و console.warn
content = content.replace(/^\s*console\.(log|info|debug)\([^)]*\);?\s*$/gm, '');

// إزالة الأسطر الفارغة المتعددة المتتالية
content = content.replace(/\n\n\n+/g, '\n\n');

// عد console.log بعد الإزالة
const afterCount = (content.match(/console\.(log|info|debug)/g) || []).length;
console.log(`📊 عدد console.log بعد الإزالة: ${afterCount}`);
console.log(`✅ تم إزالة ${beforeCount - afterCount} سطر`);

// حفظ الملف
fs.writeFileSync(filePath, content, 'utf8');
console.log(`✅ تم حفظ الملف: ${filePath}`);

