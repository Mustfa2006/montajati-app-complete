// ===================================
// استخراج بيانات الحالات من صفحة التاجر
// Extract Status Data from Merchant Page
// ===================================

const axios = require('axios');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

async function extractStatusData() {
  try {
    console.log('🔍 استخراج بيانات الحالات من صفحة التاجر...\n');

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

    // 3. استخراج بيانات الطلبات من JSON
    console.log('\n🔍 استخراج بيانات الطلبات من JSON...');

    // البحث عن printed_orders
    const printedOrdersMatch = pageContent.match(/id="printed_orders" value='([^']+)'/);
    let printedOrders = [];
    
    if (printedOrdersMatch) {
      try {
        const jsonData = printedOrdersMatch[1];
        printedOrders = JSON.parse(jsonData);
        console.log(`✅ تم استخراج ${printedOrders.length} طلب مطبوع`);
      } catch (e) {
        console.log('❌ خطأ في تحليل JSON للطلبات المطبوعة');
      }
    }

    // البحث عن not_printed_orders
    const notPrintedOrdersMatch = pageContent.match(/id="not_printed_orders" value='([^']+)'/);
    let notPrintedOrders = [];
    
    if (notPrintedOrdersMatch) {
      try {
        const jsonData = notPrintedOrdersMatch[1];
        notPrintedOrders = JSON.parse(jsonData);
        console.log(`✅ تم استخراج ${notPrintedOrders.length} طلب غير مطبوع`);
      } catch (e) {
        console.log('❌ خطأ في تحليل JSON للطلبات غير المطبوعة');
      }
    }

    // 4. تحليل الحالات الموجودة
    console.log('\n📊 تحليل الحالات الموجودة...');

    const allOrders = [...printedOrders, ...notPrintedOrders];
    const foundStatuses = new Map();
    const statusMapping = new Map();

    allOrders.forEach(order => {
      if (order.status_id && order.status) {
        const statusId = order.status_id.toString();
        const statusText = order.status;
        
        if (!foundStatuses.has(statusId)) {
          foundStatuses.set(statusId, {
            id: statusId,
            text: statusText,
            count: 0,
            orders: []
          });
        }
        
        foundStatuses.get(statusId).count++;
        foundStatuses.get(statusId).orders.push({
          id: order.id,
          client_name: order.client_name,
          created_at: order.created_at
        });

        statusMapping.set(statusId, statusText);
      }
    });

    console.log(`📊 تم العثور على ${foundStatuses.size} حالة مختلفة:`);
    
    foundStatuses.forEach((statusData, statusId) => {
      console.log(`   ID ${statusId}: "${statusData.text}" (${statusData.count} طلب)`);
      
      // التحقق من الحالات المطلوبة
      if (expectedStatuses[statusId]) {
        if (statusData.text.includes(expectedStatuses[statusId]) || 
            expectedStatuses[statusId].includes(statusData.text)) {
          console.log(`      ✅ متطابقة مع الحالة المطلوبة`);
        } else {
          console.log(`      ⚠️ مختلفة عن المتوقع: "${expectedStatuses[statusId]}"`);
        }
      } else {
        console.log(`      ❓ حالة غير متوقعة`);
      }
    });

    // 5. مقارنة مع الحالات المطلوبة
    console.log('\n🎯 مقارنة مع الحالات المطلوبة:');
    
    const matchedStatuses = [];
    const missingStatuses = [];
    
    Object.entries(expectedStatuses).forEach(([id, expectedText]) => {
      if (statusMapping.has(id)) {
        const actualText = statusMapping.get(id);
        matchedStatuses.push({
          id,
          expected: expectedText,
          actual: actualText,
          match: actualText.includes(expectedText) || expectedText.includes(actualText)
        });
      } else {
        missingStatuses.push({ id, text: expectedText });
      }
    });

    console.log(`✅ حالات موجودة: ${matchedStatuses.length}`);
    console.log(`❌ حالات مفقودة: ${missingStatuses.length}`);

    if (matchedStatuses.length > 0) {
      console.log('\n✅ الحالات الموجودة:');
      matchedStatuses.forEach((status, index) => {
        const icon = status.match ? '✅' : '⚠️';
        console.log(`   ${index + 1}. ${icon} ID ${status.id}:`);
        console.log(`      المتوقع: "${status.expected}"`);
        console.log(`      الفعلي: "${status.actual}"`);
      });
    }

    if (missingStatuses.length > 0) {
      console.log('\n❌ الحالات المفقودة:');
      missingStatuses.forEach((status, index) => {
        console.log(`   ${index + 1}. ID ${status.id}: "${status.text}"`);
      });
    }

    // 6. اختبار جلب حالة طلب محدد
    console.log('\n🎯 اختبار جلب حالة طلب محدد...');
    
    if (allOrders.length > 0) {
      const testOrder = allOrders[0];
      console.log(`📦 طلب الاختبار: ID ${testOrder.id}`);
      console.log(`👤 العميل: ${testOrder.client_name}`);
      console.log(`📊 الحالة الحالية: ID ${testOrder.status_id} - "${testOrder.status}"`);

      // محاولة جلب تفاصيل أكثر للطلب
      try {
        const orderDetailResponse = await axios.get(`${waseetConfig.baseUrl}/merchant`, {
          params: { order_id: testOrder.id },
          timeout: 10000,
          headers: {
            'Cookie': token,
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
          },
          validateStatus: () => true
        });

        if (orderDetailResponse.status === 200) {
          console.log('✅ تم جلب تفاصيل الطلب بنجاح');
          
          // البحث عن حالات إضافية في الاستجابة
          const detailContent = orderDetailResponse.data;
          foundStatuses.forEach((statusData, statusId) => {
            if (detailContent.includes(`status_id="${statusId}"`)) {
              console.log(`   🎯 وجدت حالة ${statusId} في تفاصيل الطلب`);
            }
          });
        }
      } catch (error) {
        console.log('⚠️ لم يتم جلب تفاصيل إضافية للطلب');
      }
    }

    // 7. إنشاء خريطة الحالات المحدثة
    console.log('\n🗺️ إنشاء خريطة الحالات المحدثة...');
    
    const statusMap = {};
    foundStatuses.forEach((statusData, statusId) => {
      statusMap[statusId] = statusData.text;
    });

    console.log('📋 خريطة الحالات المكتشفة:');
    console.log(JSON.stringify(statusMap, null, 2));

    // 8. تقرير النتائج النهائي
    console.log('\n🎯 تقرير استخراج بيانات الحالات:');
    console.log('=' * 60);

    const totalExpected = Object.keys(expectedStatuses).length;
    const totalFound = foundStatuses.size;
    const totalMatched = matchedStatuses.length;
    const coverageRate = ((totalMatched / totalExpected) * 100).toFixed(1);

    console.log(`📊 إجمالي الحالات المطلوبة: ${totalExpected}`);
    console.log(`✅ حالات موجودة في النظام: ${totalFound}`);
    console.log(`🎯 حالات متطابقة: ${totalMatched}`);
    console.log(`📈 معدل التغطية: ${coverageRate}%`);
    console.log(`📦 إجمالي الطلبات المحللة: ${allOrders.length}`);

    // 9. توصيات للتطوير
    console.log('\n💡 توصيات للتطوير:');
    
    if (totalFound > 0) {
      console.log('✅ تم العثور على حالات في النظام');
      console.log('🔧 يمكن تطوير النظام لجلب الحالات من صفحة التاجر');
      console.log('📊 استخدم JSON المدمج في الصفحة لجلب بيانات الطلبات');
      
      if (totalMatched < totalExpected) {
        console.log('⚠️ بعض الحالات المطلوبة غير موجودة حالياً');
        console.log('🔍 قد تظهر عند وجود طلبات بهذه الحالات');
      }
    } else {
      console.log('🚨 لم يتم العثور على حالات');
      console.log('📞 تواصل مع الدعم التقني');
    }

    console.log('\n🎉 انتهى استخراج بيانات الحالات!');

    return {
      total_expected: totalExpected,
      total_found: totalFound,
      total_matched: totalMatched,
      coverage_rate: coverageRate,
      status_map: statusMap,
      found_statuses: Array.from(foundStatuses.values()),
      matched_statuses: matchedStatuses,
      missing_statuses: missingStatuses,
      total_orders: allOrders.length
    };

  } catch (error) {
    console.error('❌ خطأ في استخراج بيانات الحالات:', error.message);
    return {
      success: false,
      error: error.message
    };
  }
}

// تشغيل الاستخراج
if (require.main === module) {
  extractStatusData().then(report => {
    console.log('\n📊 ملخص الاستخراج:');
    if (report.coverage_rate !== undefined) {
      console.log(`🎯 معدل التغطية: ${report.coverage_rate}%`);
      console.log(`📊 حالات موجودة: ${report.total_found}`);
      console.log(`📦 طلبات محللة: ${report.total_orders}`);
    }
  }).catch(error => {
    console.error('❌ خطأ في تشغيل الاستخراج:', error.message);
  });
}

module.exports = extractStatusData;
