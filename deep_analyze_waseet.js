// ===================================
// تحليل عميق لصفحة الوسيط الرئيسية
// Deep Analysis of Waseet Main Page
// ===================================

const WaseetWebClient = require('./backend/services/waseet_web_client');
const fs = require('fs');
require('dotenv').config();

async function deepAnalyzeWaseet() {
  console.log('🔬 بدء التحليل العميق لصفحة الوسيط...\n');
  
  const username = process.env.WASEET_USERNAME;
  const password = process.env.WASEET_PASSWORD;
  
  const client = new WaseetWebClient(username, password);
  
  try {
    // تسجيل الدخول
    console.log('🔐 تسجيل الدخول...');
    const loginSuccess = await client.login();
    
    if (!loginSuccess) {
      console.error('❌ فشل في تسجيل الدخول');
      return;
    }
    
    console.log('✅ تم تسجيل الدخول بنجاح!\n');
    
    // جلب الصفحة الرئيسية
    console.log('📄 جلب الصفحة الرئيسية...');
    const response = await client.makeRequest('GET', '/merchant');
    
    if (response.statusCode !== 200) {
      console.error(`❌ فشل في جلب الصفحة: ${response.statusCode}`);
      return;
    }
    
    const html = response.body;
    console.log(`📊 حجم الصفحة: ${html.length} حرف\n`);
    
    // حفظ الصفحة للفحص اليدوي
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const filename = `waseet_page_${timestamp}.html`;
    fs.writeFileSync(filename, html, 'utf8');
    console.log(`💾 تم حفظ الصفحة في: ${filename}\n`);
    
    // تحليل مفصل
    console.log('🔍 بدء التحليل المفصل...\n');
    
    // 1. تحليل العناصر الأساسية
    analyzeBasicElements(html);
    
    // 2. تحليل الجداول
    analyzeTables(html);
    
    // 3. تحليل JavaScript
    analyzeJavaScript(html);
    
    // 4. تحليل النماذج
    analyzeForms(html);
    
    // 5. تحليل الروابط
    analyzeLinks(html);
    
    // 6. البحث عن أي إشارات للحالات
    searchForStatusIndicators(html);
    
    console.log('\n✅ تم إكمال التحليل العميق!');
    
  } catch (error) {
    console.error('❌ خطأ في التحليل:', error.message);
  }
}

function analyzeBasicElements(html) {
  console.log('📋 تحليل العناصر الأساسية:');
  console.log('-'.repeat(40));
  
  // عدد العناصر المختلفة
  const elements = {
    'div': (html.match(/<div/g) || []).length,
    'table': (html.match(/<table/g) || []).length,
    'form': (html.match(/<form/g) || []).length,
    'input': (html.match(/<input/g) || []).length,
    'select': (html.match(/<select/g) || []).length,
    'script': (html.match(/<script/g) || []).length,
    'a': (html.match(/<a/g) || []).length
  };
  
  Object.entries(elements).forEach(([tag, count]) => {
    console.log(`   ${tag}: ${count}`);
  });
  
  console.log();
}

function analyzeTables(html) {
  console.log('📊 تحليل الجداول:');
  console.log('-'.repeat(40));
  
  const tables = html.match(/<table[^>]*>[\s\S]*?<\/table>/gi) || [];
  
  console.log(`   عدد الجداول: ${tables.length}`);
  
  tables.forEach((table, index) => {
    console.log(`\n   📋 الجدول ${index + 1}:`);
    
    // استخراج ID و class
    const idMatch = table.match(/id=['"]([^'"]+)['"]/);
    const classMatch = table.match(/class=['"]([^'"]+)['"]/);
    
    if (idMatch) console.log(`      ID: ${idMatch[1]}`);
    if (classMatch) console.log(`      Class: ${classMatch[1]}`);
    
    // عدد الصفوف والأعمدة
    const rows = table.match(/<tr[^>]*>/g) || [];
    const cells = table.match(/<td[^>]*>/g) || [];
    const headers = table.match(/<th[^>]*>/g) || [];
    
    console.log(`      الصفوف: ${rows.length}`);
    console.log(`      الخلايا: ${cells.length}`);
    console.log(`      العناوين: ${headers.length}`);
    
    // البحث عن محتوى مفيد
    if (table.includes('order') || table.includes('طلب')) {
      console.log(`      🎯 يحتوي على كلمات متعلقة بالطلبات`);
    }
    
    if (table.includes('status') || table.includes('حالة')) {
      console.log(`      🎯 يحتوي على كلمات متعلقة بالحالة`);
    }
  });
  
  console.log();
}

function analyzeJavaScript(html) {
  console.log('📜 تحليل JavaScript:');
  console.log('-'.repeat(40));
  
  const scripts = html.match(/<script[^>]*>([\s\S]*?)<\/script>/gi) || [];
  
  console.log(`   عدد الـ scripts: ${scripts.length}`);
  
  scripts.forEach((script, index) => {
    console.log(`\n   📜 Script ${index + 1}:`);
    
    const content = script.replace(/<\/?script[^>]*>/gi, '');
    console.log(`      الحجم: ${content.length} حرف`);
    
    // البحث عن متغيرات مهمة
    const variables = content.match(/var\s+\w+|let\s+\w+|const\s+\w+/g) || [];
    console.log(`      المتغيرات: ${variables.length}`);
    
    // البحث عن كلمات مفتاحية
    const keywords = ['order', 'status', 'delivery', 'طلب', 'حالة', 'توصيل'];
    const foundKeywords = keywords.filter(keyword => 
      content.toLowerCase().includes(keyword.toLowerCase())
    );
    
    if (foundKeywords.length > 0) {
      console.log(`      🎯 كلمات مفتاحية: ${foundKeywords.join(', ')}`);
      
      // عرض جزء من الكود المحتوي على الكلمات المفتاحية
      foundKeywords.forEach(keyword => {
        const regex = new RegExp(`.{0,50}${keyword}.{0,50}`, 'gi');
        const matches = content.match(regex);
        if (matches) {
          console.log(`         "${keyword}": ${matches[0].trim()}`);
        }
      });
    }
  });
  
  console.log();
}

function analyzeForms(html) {
  console.log('📝 تحليل النماذج:');
  console.log('-'.repeat(40));
  
  const forms = html.match(/<form[^>]*>[\s\S]*?<\/form>/gi) || [];
  
  console.log(`   عدد النماذج: ${forms.length}`);
  
  forms.forEach((form, index) => {
    console.log(`\n   📝 النموذج ${index + 1}:`);
    
    const actionMatch = form.match(/action=['"]([^'"]+)['"]/);
    const methodMatch = form.match(/method=['"]([^'"]+)['"]/);
    
    if (actionMatch) console.log(`      Action: ${actionMatch[1]}`);
    if (methodMatch) console.log(`      Method: ${methodMatch[1]}`);
    
    // عدد الحقول
    const inputs = form.match(/<input[^>]*>/g) || [];
    const selects = form.match(/<select[^>]*>/g) || [];
    
    console.log(`      الحقول: ${inputs.length} input, ${selects.length} select`);
    
    // فحص select options للحالات
    selects.forEach((select, selectIndex) => {
      const options = select.match(/<option[^>]*value=['"]([^'"]+)['"][^>]*>([^<]*)</gi) || [];
      if (options.length > 0) {
        console.log(`      📋 Select ${selectIndex + 1} options:`);
        options.slice(0, 5).forEach(option => {
          const valueMatch = option.match(/value=['"]([^'"]+)['"]/);
          const textMatch = option.match(/>([^<]*)</);
          if (valueMatch && textMatch) {
            console.log(`         "${valueMatch[1]}" - "${textMatch[1].trim()}"`);
          }
        });
      }
    });
  });
  
  console.log();
}

function analyzeLinks(html) {
  console.log('🔗 تحليل الروابط:');
  console.log('-'.repeat(40));
  
  const links = html.match(/<a[^>]*href=['"]([^'"]+)['"][^>]*>([^<]*)</gi) || [];
  
  console.log(`   عدد الروابط: ${links.length}`);
  
  const internalLinks = links.filter(link => 
    link.includes('href="/') && !link.includes('logout') && !link.includes('login')
  );
  
  console.log(`   الروابط الداخلية: ${internalLinks.length}`);
  
  if (internalLinks.length > 0) {
    console.log('\n   🔗 عينة من الروابط الداخلية:');
    internalLinks.slice(0, 10).forEach(link => {
      const hrefMatch = link.match(/href=['"]([^'"]+)['"]/);
      const textMatch = link.match(/>([^<]*)</);
      if (hrefMatch && textMatch) {
        console.log(`      ${hrefMatch[1]} - "${textMatch[1].trim()}"`);
      }
    });
  }
  
  console.log();
}

function searchForStatusIndicators(html) {
  console.log('🎯 البحث عن مؤشرات الحالات:');
  console.log('-'.repeat(40));
  
  // قائمة شاملة من الحالات المحتملة
  const possibleStatuses = [
    'pending', 'delivered', 'cancelled', 'processing', 'shipped', 'confirmed',
    'rejected', 'returned', 'completed', 'failed', 'active', 'inactive',
    'new', 'old', 'printed', 'not_printed', 'ready', 'waiting', 'prepared',
    'dispatched', 'transit', 'arrived', 'received', 'accepted', 'declined',
    'في انتظار', 'تم التوصيل', 'ملغي', 'قيد المعالجة', 'تم الشحن', 'مؤكد',
    'مرفوض', 'مرتجع', 'مكتمل', 'فاشل', 'نشط', 'غير نشط', 'جديد', 'قديم',
    'مطبوع', 'غير مطبوع', 'جاهز', 'منتظر', 'محضر', 'مرسل'
  ];
  
  const foundStatuses = [];
  
  possibleStatuses.forEach(status => {
    const regex = new RegExp(`\\b${status}\\b`, 'gi');
    const matches = html.match(regex);
    if (matches) {
      foundStatuses.push({ status, count: matches.length });
    }
  });
  
  if (foundStatuses.length > 0) {
    console.log('   🎯 الحالات الموجودة:');
    foundStatuses.forEach(({ status, count }) => {
      console.log(`      "${status}" - ${count} مرة`);
    });
  } else {
    console.log('   ⚠️ لم يتم العثور على حالات واضحة');
  }
  
  console.log();
}

// تشغيل التحليل
deepAnalyzeWaseet();
