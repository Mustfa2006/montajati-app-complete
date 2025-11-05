// ===================================
// اختبار إصلاح Backend
// Test Backend Fix
// ===================================

const http = require('http');

async function testBackendFix() {
  console.log('🧪 اختبار إصلاح Backend...');
  console.log('='.repeat(60));

  const testPhone = '07511111111';
  const backendUrl = 'https://montajati-official-backend-production.up.railway.app';

  try {
    // 1. اختبار جلب العدادات
    console.log('\n1️⃣ اختبار جلب العدادات...');
    console.log(`📡 GET ${backendUrl}/api/orders/user/${testPhone}/counts`);

    const countsResponse = await fetch(
      `${backendUrl}/api/orders/user/${testPhone}/counts`,
      {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        timeout: 10000
      }
    );

    const countsData = await countsResponse.json();

    if (countsResponse.ok && countsData.success) {
      console.log('✅ نجح جلب العدادات!');
      console.log('📊 البيانات:', countsData.data);
    } else {
      console.log('❌ فشل جلب العدادات');
      console.log('❌ الخطأ:', countsData.error);
    }

    // 2. اختبار جلب الطلبات
    console.log('\n2️⃣ اختبار جلب الطلبات...');
    console.log(`📡 GET ${backendUrl}/api/orders/user/${testPhone}?page=0&limit=10`);

    const ordersResponse = await fetch(
      `${backendUrl}/api/orders/user/${testPhone}?page=0&limit=10`,
      {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        timeout: 10000
      }
    );

    const ordersData = await ordersResponse.json();

    if (ordersResponse.ok && ordersData.success) {
      console.log('✅ نجح جلب الطلبات!');
      console.log(`📋 عدد الطلبات: ${ordersData.data.length}`);
      console.log('📊 معلومات الترقيم:', ordersData.pagination);
    } else {
      console.log('❌ فشل جلب الطلبات');
      console.log('❌ الخطأ:', ordersData.error);
    }

    // 3. اختبار جلب الطلبات المجدولة
    console.log('\n3️⃣ اختبار جلب الطلبات المجدولة...');
    console.log(`📡 GET ${backendUrl}/api/orders/scheduled-orders/user/${testPhone}?page=0&limit=10`);

    const scheduledResponse = await fetch(
      `${backendUrl}/api/orders/scheduled-orders/user/${testPhone}?page=0&limit=10`,
      {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        timeout: 10000
      }
    );

    const scheduledData = await scheduledResponse.json();

    if (scheduledResponse.ok && scheduledData.success) {
      console.log('✅ نجح جلب الطلبات المجدولة!');
      console.log(`📋 عدد الطلبات المجدولة: ${scheduledData.data.length}`);
      console.log('📊 معلومات الترقيم:', scheduledData.pagination);
    } else {
      console.log('❌ فشل جلب الطلبات المجدولة');
      console.log('❌ الخطأ:', scheduledData.error);
    }

    console.log('\n' + '='.repeat(60));
    console.log('✅ اختبار Backend اكتمل بنجاح!');
    console.log('='.repeat(60));

  } catch (error) {
    console.error('❌ خطأ في الاختبار:', error.message);
    console.log('\n💡 تأكد من:');
    console.log('1. Backend يعمل بشكل صحيح');
    console.log('2. الاتصال بالإنترنت يعمل');
    console.log('3. رقم الهاتف صحيح');
  }
}

// تشغيل الاختبار
testBackendFix();

