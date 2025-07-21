// ===================================
// جلب جميع حالات الطلبات من شركة الوسيط - شامل
// Get All Order Statuses from Waseet Company - Comprehensive
// ===================================

const WaseetWebClient = require('./backend/services/waseet_web_client');
require('dotenv').config();

async function getAllWaseetStatuses() {
  console.log('🔍 بدء جلب جميع حالات الطلبات من شركة الوسيط...\n');
  
  const username = process.env.WASEET_USERNAME;
  const password = process.env.WASEET_PASSWORD;
  
  if (!username || !password) {
    console.error('❌ بيانات اعتماد الوسيط غير متوفرة');
    console.log('💡 تأكد من وجود WASEET_USERNAME و WASEET_PASSWORD في ملف .env');
    return;
  }
  
  console.log(`👤 المستخدم: ${username}`);
  console.log(`🌐 الموقع: https://merchant.alwaseet-iq.net\n`);
  
  const client = new WaseetWebClient(username, password);
  
  try {
    // 1. تسجيل الدخول
    console.log('🔐 الخطوة 1: تسجيل الدخول...');
    const loginSuccess = await client.login();
    
    if (!loginSuccess) {
      console.error('❌ فشل في تسجيل الدخول للوسيط');
      return;
    }
    
    console.log('✅ تم تسجيل الدخول بنجاح!\n');
    
    // 2. جلب جميع الحالات
    console.log('🔍 الخطوة 2: جلب جميع حالات الطلبات...');
    const statusReport = await client.getAllOrderStatuses();
    
    if (!statusReport) {
      console.error('❌ فشل في جلب حالات الطلبات');
      return;
    }
    
    // 3. عرض النتائج المفصلة
    console.log('\n' + '🎯'.repeat(40));
    console.log('النتائج النهائية - جميع حالات الوسيط');
    console.log('🎯'.repeat(40));
    
    if (statusReport.allStatuses && statusReport.allStatuses.length > 0) {
      console.log(`\n📊 تم اكتشاف ${statusReport.allStatuses.length} حالة فريدة:`);
      console.log('='.repeat(60));
      
      statusReport.allStatuses.forEach((status, index) => {
        // حساب عدد الطلبات لكل حالة
        const orderCount = statusReport.orders ? 
          statusReport.orders.filter(order => 
            order.status && order.status.toLowerCase() === status.toLowerCase()
          ).length : 0;
        
        console.log(`${index + 1}. "${status}" ${orderCount > 0 ? `(${orderCount} طلب)` : ''}`);
      });
      
      // تصنيف الحالات
      console.log('\n🏷️ تصنيف الحالات:');
      console.log('-'.repeat(40));
      
      const categories = categorizeStatuses(statusReport.allStatuses);
      
      Object.keys(categories).forEach(category => {
        if (categories[category].length > 0) {
          console.log(`\n${getCategoryIcon(category)} ${category}:`);
          categories[category].forEach(status => {
            console.log(`   • ${status}`);
          });
        }
      });
      
      // إحصائيات مفيدة
      console.log('\n📈 إحصائيات مفيدة:');
      console.log('-'.repeat(40));
      console.log(`📄 إجمالي الصفحات المفحوصة: ${statusReport.totalPages}`);
      console.log(`📦 إجمالي الطلبات المكتشفة: ${statusReport.totalOrders}`);
      console.log(`📊 إجمالي الحالات الفريدة: ${statusReport.totalStatuses}`);
      
      // حفظ النتائج في ملف
      await saveResultsToFile(statusReport);
      
    } else {
      console.log('⚠️ لم يتم العثور على أي حالات');
      console.log('💡 قد تحتاج إلى:');
      console.log('   1. التحقق من صحة بيانات تسجيل الدخول');
      console.log('   2. التأكد من وجود طلبات في حساب الوسيط');
      console.log('   3. فحص تغييرات في هيكل موقع الوسيط');
    }
    
  } catch (error) {
    console.error('❌ خطأ في جلب حالات الوسيط:', error.message);
    console.error('📊 تفاصيل الخطأ:', error.stack);
  }
}

// تصنيف الحالات حسب النوع
function categorizeStatuses(statuses) {
  const categories = {
    'حالات التوصيل': [],
    'حالات المعالجة': [],
    'حالات الطباعة': [],
    'حالات عامة': [],
    'حالات عربية': [],
    'أخرى': []
  };
  
  statuses.forEach(status => {
    const lowerStatus = status.toLowerCase();
    
    if (['delivered', 'shipped', 'delivery', 'توصيل', 'تم التوصيل'].some(keyword => 
        lowerStatus.includes(keyword))) {
      categories['حالات التوصيل'].push(status);
    } else if (['pending', 'processing', 'confirmed', 'active', 'في انتظار', 'قيد المعالجة'].some(keyword => 
        lowerStatus.includes(keyword))) {
      categories['حالات المعالجة'].push(status);
    } else if (['printed', 'not_printed', 'مطبوع', 'غير مطبوع'].some(keyword => 
        lowerStatus.includes(keyword))) {
      categories['حالات الطباعة'].push(status);
    } else if (['cancelled', 'rejected', 'failed', 'ملغي', 'مرفوض', 'فاشل'].some(keyword => 
        lowerStatus.includes(keyword))) {
      categories['حالات عامة'].push(status);
    } else if (/[أ-ي]/.test(status)) {
      categories['حالات عربية'].push(status);
    } else {
      categories['أخرى'].push(status);
    }
  });
  
  return categories;
}

// الحصول على أيقونة للفئة
function getCategoryIcon(category) {
  const icons = {
    'حالات التوصيل': '🚚',
    'حالات المعالجة': '⚙️',
    'حالات الطباعة': '🖨️',
    'حالات عامة': '📋',
    'حالات عربية': '🇮🇶',
    'أخرى': '📌'
  };
  
  return icons[category] || '📌';
}

// حفظ النتائج في ملف
async function saveResultsToFile(statusReport) {
  try {
    const fs = require('fs');
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const filename = `waseet_statuses_${timestamp}.json`;
    
    const dataToSave = {
      timestamp: new Date().toISOString(),
      summary: statusReport.summary,
      allStatuses: statusReport.allStatuses,
      totalPages: statusReport.totalPages,
      totalOrders: statusReport.totalOrders,
      pageDetails: statusReport.pageDetails.map(page => ({
        source: page.source,
        pageSize: page.pageSize,
        statusCount: page.allStatuses ? page.allStatuses.length : 0,
        orderCount: page.orders ? page.orders.length : 0,
        statuses: page.allStatuses || []
      })),
      orders: statusReport.orders.slice(0, 100) // حفظ أول 100 طلب فقط
    };
    
    fs.writeFileSync(filename, JSON.stringify(dataToSave, null, 2), 'utf8');
    console.log(`\n💾 تم حفظ النتائج في: ${filename}`);
    
  } catch (error) {
    console.warn('⚠️ فشل في حفظ النتائج في ملف:', error.message);
  }
}

// تشغيل السكريبت
getAllWaseetStatuses();
