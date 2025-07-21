// ===================================
// اختبار API الوسيط الصحيح
// Test Correct Waseet API
// ===================================

const WaseetAPIClient = require('./backend/services/waseet_api_client');
const fs = require('fs');
require('dotenv').config();

async function testCorrectWaseetAPI() {
  console.log('🎯 اختبار API الوسيط الصحيح...\n');
  
  const username = process.env.WASEET_USERNAME;
  const password = process.env.WASEET_PASSWORD;
  
  if (!username || !password) {
    console.error('❌ بيانات اعتماد الوسيط غير متوفرة');
    console.log('💡 تأكد من وجود WASEET_USERNAME و WASEET_PASSWORD في ملف .env');
    return;
  }
  
  console.log(`👤 المستخدم: ${username}`);
  console.log(`🌐 API Base URL: https://api.alwaseet-iq.net/v1/merchant\n`);
  
  const client = new WaseetAPIClient(username, password);
  
  try {
    // 1. اختبار تسجيل الدخول
    console.log('🔐 الخطوة 1: اختبار تسجيل الدخول...');
    const loginSuccess = await client.login();
    
    if (!loginSuccess) {
      console.error('❌ فشل في تسجيل الدخول - توقف الاختبار');
      return;
    }
    
    console.log('✅ تم تسجيل الدخول بنجاح!\n');
    
    // 2. اختبار جلب الحالات (الهدف الرئيسي)
    console.log('🎯 الخطوة 2: جلب جميع حالات الطلبات...');
    const statuses = await client.getOrderStatuses();
    
    if (statuses && statuses.length > 0) {
      console.log('\n🎉 نجح! تم جلب جميع حالات الوسيط:');
      console.log('='.repeat(70));
      
      statuses.forEach((status, index) => {
        console.log(`${index + 1}. ID: ${status.id} - "${status.status}"`);
      });
      
      // حفظ الحالات في ملف
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const statusesFile = `waseet_statuses_${timestamp}.json`;
      
      fs.writeFileSync(statusesFile, JSON.stringify({
        timestamp: new Date().toISOString(),
        source: 'Official Waseet API',
        endpoint: 'https://api.alwaseet-iq.net/v1/merchant/statuses',
        totalStatuses: statuses.length,
        statuses: statuses
      }, null, 2), 'utf8');
      
      console.log(`\n💾 تم حفظ الحالات في: ${statusesFile}`);
      
    } else {
      console.log('⚠️ لم يتم جلب أي حالات');
    }
    
    // 3. اختبار جلب الطلبات (للحصول على حالات إضافية)
    console.log('\n📦 الخطوة 3: جلب الطلبات للحصول على حالات إضافية...');
    const orders = await client.getOrders();
    
    // 4. اختبار جلب البيانات الإضافية
    console.log('\n🏙️ الخطوة 4: جلب المدن...');
    const cities = await client.getCities();
    
    console.log('\n📏 الخطوة 5: جلب أحجام الطرود...');
    const packageSizes = await client.getPackageSizes();
    
    // 5. تحليل شامل
    console.log('\n📊 الخطوة 6: التحليل الشامل...');
    const analysis = await client.getCompleteAnalysis();
    
    if (analysis) {
      // حفظ التحليل الشامل
      const analysisFile = `waseet_complete_analysis_${timestamp}.json`;
      fs.writeFileSync(analysisFile, JSON.stringify(analysis, null, 2), 'utf8');
      console.log(`\n💾 تم حفظ التحليل الشامل في: ${analysisFile}`);
      
      // عرض النتائج النهائية
      console.log('\n' + '🎯'.repeat(35));
      console.log('النتائج النهائية - جميع حالات الوسيط');
      console.log('🎯'.repeat(35));
      
      if (analysis.statuses && analysis.statuses.length > 0) {
        console.log('\n📋 قائمة جميع الحالات:');
        console.log('-'.repeat(50));
        
        analysis.statuses.forEach((status, index) => {
          console.log(`${index + 1}. "${status.status}" (ID: ${status.id})`);
        });
        
        console.log('\n📝 الحالات للنسخ (مفصولة بفواصل):');
        const statusTexts = analysis.statuses.map(s => s.status);
        console.log(statusTexts.join(', '));
        
        console.log('\n📊 إحصائيات:');
        console.log(`   📋 إجمالي الحالات: ${analysis.statuses.length}`);
        console.log(`   📦 إجمالي الطلبات: ${analysis.summary.totalOrders}`);
        console.log(`   🏙️ إجمالي المدن: ${analysis.summary.totalCities}`);
        console.log(`   📏 إجمالي أحجام الطرود: ${analysis.summary.totalPackageSizes}`);
        
      } else {
        console.log('⚠️ لم يتم العثور على أي حالات');
      }
    }
    
    console.log('\n✅ تم إكمال جميع الاختبارات بنجاح!');
    
  } catch (error) {
    console.error('❌ خطأ في الاختبار:', error.message);
    console.error('📊 تفاصيل الخطأ:', error.stack);
  }
}

// تشغيل الاختبار
testCorrectWaseetAPI();
