// ===================================
// اختبار اتصال Supabase
// ===================================

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

async function testSupabaseConnection() {
  console.log('🔍 اختبار اتصال Supabase...\n');

  // التحقق من متغيرات البيئة
  console.log('📋 متغيرات البيئة:');
  console.log('SUPABASE_URL:', process.env.SUPABASE_URL ? '✅ موجود' : '❌ غير موجود');
  console.log('SUPABASE_SERVICE_ROLE_KEY:', process.env.SUPABASE_SERVICE_ROLE_KEY ? '✅ موجود' : '❌ غير موجود');
  console.log('');

  if (!process.env.SUPABASE_URL || !process.env.SUPABASE_SERVICE_ROLE_KEY) {
    console.error('❌ متغيرات البيئة غير موجودة!');
    process.exit(1);
  }

  try {
    // إنشاء عميل Supabase
    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    console.log('✅ تم إنشاء عميل Supabase بنجاح\n');

    // اختبار 1: جلب عدد الطلبات
    console.log('📊 اختبار 1: جلب عدد الطلبات...');
    const { count: ordersCount, error: countError } = await supabase
      .from('orders')
      .select('*', { count: 'exact', head: true });

    if (countError) {
      console.error('❌ خطأ في جلب عدد الطلبات:', countError.message);
    } else {
      console.log(`✅ عدد الطلبات في قاعدة البيانات: ${ordersCount}`);
    }
    console.log('');

    // اختبار 2: جلب طلبات مستخدم محدد
    console.log('📊 اختبار 2: جلب طلبات المستخدم 07511111111...');
    const { data: userOrders, error: userError } = await supabase
      .from('orders')
      .select('id, customer_name, status, created_at')
      .eq('user_phone', '07511111111')
      .limit(5);

    if (userError) {
      console.error('❌ خطأ في جلب طلبات المستخدم:', userError.message);
    } else {
      console.log(`✅ عدد طلبات المستخدم: ${userOrders?.length || 0}`);
      if (userOrders && userOrders.length > 0) {
        console.log('📋 أول 5 طلبات:');
        userOrders.forEach((order, index) => {
          console.log(`  ${index + 1}. ${order.id} - ${order.customer_name} - ${order.status}`);
        });
      }
    }
    console.log('');

    // اختبار 3: جلب عدد المستخدمين
    console.log('📊 اختبار 3: جلب عدد المستخدمين...');
    const { count: usersCount, error: usersCountError } = await supabase
      .from('users')
      .select('*', { count: 'exact', head: true });

    if (usersCountError) {
      console.error('❌ خطأ في جلب عدد المستخدمين:', usersCountError.message);
    } else {
      console.log(`✅ عدد المستخدمين في قاعدة البيانات: ${usersCount}`);
    }
    console.log('');

    // اختبار 4: جلب عدد المنتجات
    console.log('📊 اختبار 4: جلب عدد المنتجات...');
    const { count: productsCount, error: productsCountError } = await supabase
      .from('products')
      .select('*', { count: 'exact', head: true });

    if (productsCountError) {
      console.error('❌ خطأ في جلب عدد المنتجات:', productsCountError.message);
    } else {
      console.log(`✅ عدد المنتجات في قاعدة البيانات: ${productsCount}`);
    }
    console.log('');

    console.log('✅ جميع الاختبارات اكتملت بنجاح!');

  } catch (error) {
    console.error('❌ خطأ في الاتصال بـ Supabase:', error.message);
    console.error('Stack:', error.stack);
    process.exit(1);
  }
}

// تشغيل الاختبار
testSupabaseConnection();

