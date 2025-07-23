// ===================================
// تحليل صفحة التاجر للعثور على الحالات
// Analyze Merchant Page for Status Data
// ===================================

const axios = require('axios');
const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
require('dotenv').config();

async function analyzeMerchantPage() {
  try {
    console.log('🔍 تحليل صفحة التاجر للعثور على الحالات...\n');

    // إعداد Supabase
    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    // إعدادات شركة الوسيط
    const waseetConfig = {
      baseUrl: process.env.ALMASEET_BASE_URL || 'https://api.alwaseet-iq.net',
      username: process.env.WASEET_USERNAME,
      password: process.env.WASEET_PASSWORD
    };

    // الحالات المطلوبة
    const expectedStatuses = {
      3: "قيد التوصيل الى الزبون (في عهدة المندوب)",
      24: "تم تغيير محافظة الزبون",
      25: "لا يرد",
      26: "لا يرد بعد الاتفاق",
      27: "مغلق",
      28: "مغلق بعد الاتفاق",
      29: "مؤجل",
      30: "مؤجل لحين اعادة الطلب لاحقا",
      31: "الغاء الطلب",
      32: "رفض الطلب",
      33: "مفصول عن الخدمة",
      34: "طلب مكرر",
      35: "مستلم مسبقا",
      36: "الرقم غير معرف",
      37: "الرقم غير داخل في الخدمة",
      38: "العنوان غير دقيق",
      39: "لم يطلب",
      40: "حظر المندوب",
      41: "لا يمكن الاتصال بالرقم",
      42: "تغيير المندوب"
    };

    // 1. تسجيل الدخول
    console.log('🔐 تسجيل الدخول...');
    const loginData = new URLSearchParams({
      username: waseetConfig.username,
      password: waseetConfig.password
    });

    const loginResponse = await axios.post(
      `${waseetConfig.baseUrl}/merchant/login`,
      loginData,
      {
        timeout: 15000,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
        maxRedirects: 0,
        validateStatus: () => true
      }
    );

    const token = loginResponse.headers['set-cookie']?.join('; ') || '';
    console.log('✅ تم تسجيل الدخول بنجاح');

    // 2. جلب صفحة التاجر
    console.log('\n📄 جلب صفحة التاجر...');
    const merchantResponse = await axios.get(`${waseetConfig.baseUrl}/merchant`, {
      timeout: 15000,
      headers: {
        'Cookie': token,
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      }
    });

    const pageContent = merchantResponse.data;
    console.log(`✅ تم جلب الصفحة (${pageContent.length} حرف)`);

    // حفظ الصفحة للفحص
    fs.writeFileSync('merchant_page.html', pageContent);
    console.log('💾 تم حفظ الصفحة في merchant_page.html');

    // 3. تحليل الصفحة للبحث عن الحالات
    console.log('\n🔍 تحليل الصفحة للبحث عن الحالات...');

    const foundStatuses = [];
    const foundIds = [];
    const foundPatterns = [];

    // البحث عن الحالات العربية
    Object.entries(expectedStatuses).forEach(([id, status]) => {
      if (pageContent.includes(status)) {
        foundStatuses.push({ id, status, type: 'arabic_text' });
        console.log(`✅ وجدت حالة عربية: ID ${id} - "${status}"`);
      }

      // البحث عن ID في أنماط مختلفة
      const idPatterns = [
        `status_id="${id}"`,
        `status_id='${id}'`,
        `status-id="${id}"`,
        `data-status="${id}"`,
        `value="${id}"`,
        `"status_id":${id}`,
        `"status":"${id}"`,
        `status=${id}`,
        `id="${id}"`
      ];

      idPatterns.forEach(pattern => {
        if (pageContent.includes(pattern)) {
          foundIds.push({ id, pattern, type: 'id_pattern' });
          console.log(`✅ وجدت ID pattern: ${pattern}`);
        }
      });
    });

    // 4. البحث عن جداول أو قوائم الطلبات
    console.log('\n📋 البحث عن جداول الطلبات...');

    const tableMatches = pageContent.match(/<table[^>]*>[\s\S]*?<\/table>/gi);
    if (tableMatches) {
      console.log(`✅ وجدت ${tableMatches.length} جدول`);
      
      tableMatches.forEach((table, index) => {
        console.log(`\n📊 تحليل الجدول ${index + 1}:`);
        
        // البحث عن الحالات في الجدول
        Object.entries(expectedStatuses).forEach(([id, status]) => {
          if (table.includes(status)) {
            console.log(`   ✅ الجدول ${index + 1} يحتوي على: "${status}"`);
          }
        });

        // البحث عن أرقام الطلبات
        const orderMatches = table.match(/\d{8,}/g);
        if (orderMatches) {
          console.log(`   📦 أرقام طلبات في الجدول: ${orderMatches.slice(0, 3).join(', ')}...`);
        }
      });
    }

    // 5. البحث عن JavaScript أو AJAX calls
    console.log('\n🔍 البحث عن JavaScript/AJAX calls...');

    const scriptMatches = pageContent.match(/<script[^>]*>[\s\S]*?<\/script>/gi);
    if (scriptMatches) {
      console.log(`✅ وجدت ${scriptMatches.length} script`);
      
      scriptMatches.forEach((script, index) => {
        // البحث عن URLs في JavaScript
        const urlMatches = script.match(/['"`]([^'"`]*(?:order|status|ajax)[^'"`]*)['"`]/gi);
        if (urlMatches) {
          console.log(`   🔗 URLs في script ${index + 1}:`);
          urlMatches.slice(0, 5).forEach(url => {
            console.log(`      ${url.replace(/['"`]/g, '')}`);
          });
        }
      });
    }

    // 6. البحث عن نماذج (forms)
    console.log('\n📝 البحث عن نماذج...');

    const formMatches = pageContent.match(/<form[^>]*>[\s\S]*?<\/form>/gi);
    if (formMatches) {
      console.log(`✅ وجدت ${formMatches.length} نموذج`);
      
      formMatches.forEach((form, index) => {
        const actionMatch = form.match(/action=['"`]([^'"`]*)['"`]/i);
        if (actionMatch) {
          console.log(`   📤 نموذج ${index + 1} action: ${actionMatch[1]}`);
        }

        // البحث عن حقول الحالة
        const statusInputs = form.match(/<(?:select|input)[^>]*(?:status|حالة)[^>]*>/gi);
        if (statusInputs) {
          console.log(`   📊 حقول الحالة: ${statusInputs.length}`);
        }
      });
    }

    // 7. البحث عن select options للحالات
    console.log('\n📋 البحث عن قوائم الحالات...');

    const selectMatches = pageContent.match(/<select[^>]*>[\s\S]*?<\/select>/gi);
    if (selectMatches) {
      selectMatches.forEach((select, index) => {
        if (select.includes('status') || select.includes('حالة')) {
          console.log(`\n📊 قائمة حالات ${index + 1}:`);
          
          const optionMatches = select.match(/<option[^>]*value=['"`]([^'"`]*)['"`][^>]*>(.*?)<\/option>/gi);
          if (optionMatches) {
            optionMatches.forEach(option => {
              const valueMatch = option.match(/value=['"`]([^'"`]*)['"`]/);
              const textMatch = option.match(/>(.*?)<\/option>/);
              
              if (valueMatch && textMatch) {
                const value = valueMatch[1];
                const text = textMatch[1].trim();
                
                // التحقق من الحالات المطلوبة
                Object.entries(expectedStatuses).forEach(([id, status]) => {
                  if (text.includes(status) || value === id) {
                    console.log(`   ✅ وجدت: value="${value}" text="${text}"`);
                    foundPatterns.push({ id, value, text, type: 'select_option' });
                  }
                });
              }
            });
          }
        }
      });
    }

    // 8. تقرير النتائج
    console.log('\n🎯 تقرير تحليل الصفحة:');
    console.log('=' * 60);

    console.log(`📊 إجمالي الحالات المطلوبة: ${Object.keys(expectedStatuses).length}`);
    console.log(`✅ حالات عربية موجودة: ${foundStatuses.length}`);
    console.log(`🔢 ID patterns موجودة: ${foundIds.length}`);
    console.log(`📋 select options موجودة: ${foundPatterns.length}`);

    if (foundStatuses.length > 0) {
      console.log('\n✅ الحالات العربية الموجودة:');
      foundStatuses.forEach((item, index) => {
        console.log(`   ${index + 1}. ID ${item.id}: "${item.status}"`);
      });
    }

    if (foundIds.length > 0) {
      console.log('\n🔢 ID patterns الموجودة:');
      foundIds.forEach((item, index) => {
        console.log(`   ${index + 1}. ID ${item.id}: ${item.pattern}`);
      });
    }

    if (foundPatterns.length > 0) {
      console.log('\n📋 Select options الموجودة:');
      foundPatterns.forEach((item, index) => {
        console.log(`   ${index + 1}. ID ${item.id}: value="${item.value}" text="${item.text}"`);
      });
    }

    // 9. توصيات للتطوير
    console.log('\n💡 توصيات للتطوير:');
    
    const totalFound = foundStatuses.length + foundIds.length + foundPatterns.length;
    if (totalFound === 0) {
      console.log('🚨 لم يتم العثور على الحالات في الصفحة الرئيسية');
      console.log('🔍 جرب صفحات أخرى أو ابحث عن AJAX endpoints');
    } else {
      console.log(`✅ تم العثور على ${totalFound} عنصر متعلق بالحالات`);
      console.log('🔧 يمكن تطوير النظام لاستخراج الحالات من هذه الصفحة');
      
      if (foundPatterns.length > 0) {
        console.log('📋 استخدم select options لجلب الحالات');
      }
      if (foundStatuses.length > 0) {
        console.log('📄 استخدم النصوص العربية لتحديد الحالات');
      }
    }

    console.log('\n🎉 انتهى تحليل الصفحة!');

    return {
      arabic_statuses: foundStatuses,
      id_patterns: foundIds,
      select_options: foundPatterns,
      total_found: totalFound,
      page_size: pageContent.length
    };

  } catch (error) {
    console.error('❌ خطأ في تحليل الصفحة:', error.message);
    return {
      success: false,
      error: error.message
    };
  }
}

// تشغيل التحليل
if (require.main === module) {
  analyzeMerchantPage().then(report => {
    console.log('\n📊 ملخص التحليل:');
    if (report.total_found !== undefined) {
      console.log(`🎯 عناصر موجودة: ${report.total_found}`);
      console.log(`📄 حجم الصفحة: ${report.page_size} حرف`);
      console.log(`📋 حالات عربية: ${report.arabic_statuses.length}`);
      console.log(`🔢 ID patterns: ${report.id_patterns.length}`);
      console.log(`📊 Select options: ${report.select_options.length}`);
    }
  }).catch(error => {
    console.error('❌ خطأ في تشغيل التحليل:', error.message);
  });
}

module.exports = analyzeMerchantPage;
