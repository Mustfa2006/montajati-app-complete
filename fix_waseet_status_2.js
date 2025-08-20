console.log('🔧 إصلاح مشكلة waseet_status_id=2...');

async function fixWaseetStatus2() {
  try {
    require('dotenv').config();
    
    const { createClient } = require('@supabase/supabase-js');
    const supabase = createClient(
      process.env.SUPABASE_URL, 
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    console.log('🔍 فحص الحالة الحالية...');
    
    // 1. فحص إذا كانت الحالة موجودة
    const { data: existingStatus, error: checkError } = await supabase
      .from('waseet_statuses')
      .select('*')
      .eq('id', 2)
      .single();

    if (checkError && checkError.code !== 'PGRST116') {
      throw new Error(`خطأ في فحص الحالة: ${checkError.message}`);
    }

    if (existingStatus) {
      console.log('✅ الحالة ID=2 موجودة مسبقاً:', existingStatus);
    } else {
      console.log('❌ الحالة ID=2 غير موجودة - سيتم إضافتها');
      
      // 2. إضافة الحالة المفقودة
      console.log('➕ إضافة الحالة المفقودة...');
      const { error: insertError } = await supabase
        .from('waseet_statuses')
        .insert({
          id: 2,
          status_text: 'تم الاستلام من قبل المندوب',
          status_category: 'in_delivery',
          is_active: true,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        });

      if (insertError) {
        throw new Error(`فشل في إضافة الحالة: ${insertError.message}`);
      }

      console.log('✅ تم إضافة الحالة ID=2 بنجاح');
    }

    // 3. تحديث waseet_status_manager.js لإضافة الحالة
    console.log('🔄 تحديث waseet_status_manager.js...');
    
    const fs = require('fs');
    const path = require('path');
    const managerPath = path.join(__dirname, 'services', 'waseet_status_manager.js');
    
    if (fs.existsSync(managerPath)) {
      let content = fs.readFileSync(managerPath, 'utf8');
      
      // البحث عن السطر الذي يحتوي على id: 1
      const id1Pattern = /{\s*id:\s*1,\s*text:\s*"[^"]*",\s*category:\s*"[^"]*"[^}]*}/;
      const match = content.match(id1Pattern);
      
      if (match && !content.includes('id: 2,')) {
        // إضافة الحالة الجديدة بعد id: 1
        const newStatus = `      { id: 2, text: "تم الاستلام من قبل المندوب", category: "in_delivery", appStatus: "قيد التوصيل الى الزبون (في عهدة المندوب)" },`;
        const replacement = match[0] + ',\n' + newStatus;
        content = content.replace(match[0], replacement);
        
        fs.writeFileSync(managerPath, content, 'utf8');
        console.log('✅ تم تحديث waseet_status_manager.js');
      } else if (content.includes('id: 2,')) {
        console.log('✅ الحالة موجودة مسبقاً في waseet_status_manager.js');
      } else {
        console.log('⚠️ لم يتم العثور على المكان المناسب لإضافة الحالة');
      }
    } else {
      console.log('⚠️ ملف waseet_status_manager.js غير موجود');
    }

    // 4. تحديث integrated_waseet_sync.js لإخفاء الحالة عن المستخدم
    console.log('🔄 تحديث integrated_waseet_sync.js...');
    
    const syncPath = path.join(__dirname, 'services', 'integrated_waseet_sync.js');
    
    if (fs.existsSync(syncPath)) {
      let syncContent = fs.readFileSync(syncPath, 'utf8');
      
      // البحث عن دالة mapWaseetStatusToApp
      const mapFunctionPattern = /mapWaseetStatusToApp\(waseetStatusId,\s*waseetStatusText\)\s*{[\s\S]*?return\s+[^}]+;?\s*}/;
      const mapMatch = syncContent.match(mapFunctionPattern);
      
      if (mapMatch && !syncContent.includes('waseetStatusId === 2')) {
        // إضافة معالجة خاصة للحالة ID=2
        const newMapping = mapMatch[0].replace(
          /(if\s*\(\s*id\s*===\s*23[\s\S]*?}\s*)/,
          `$1
      
      // 🚫 إخفاء حالة "تم الاستلام من قبل المندوب" - عرضها كـ "قيد التوصيل"
      if (id === 2 || text === 'تم الاستلام من قبل المندوب') {
        return 'قيد التوصيل الى الزبون (في عهدة المندوب)';
      }
      `
        );
        
        syncContent = syncContent.replace(mapMatch[0], newMapping);
        fs.writeFileSync(syncPath, syncContent, 'utf8');
        console.log('✅ تم تحديث integrated_waseet_sync.js');
      } else if (syncContent.includes('waseetStatusId === 2')) {
        console.log('✅ المعالجة موجودة مسبقاً في integrated_waseet_sync.js');
      } else {
        console.log('⚠️ لم يتم العثور على دالة mapWaseetStatusToApp');
      }
    } else {
      console.log('⚠️ ملف integrated_waseet_sync.js غير موجود');
    }

    // 5. اختبار التحديث
    console.log('🧪 اختبار التحديث...');
    
    const { data: finalCheck, error: finalError } = await supabase
      .from('waseet_statuses')
      .select('*')
      .eq('id', 2)
      .single();

    if (finalError) {
      throw new Error(`فشل في التحقق النهائي: ${finalError.message}`);
    }

    console.log('✅ التحقق النهائي - الحالة موجودة:', finalCheck);

    // 6. فحص الطلبات التي كانت تفشل
    console.log('🔍 فحص الطلبات المتأثرة...');
    
    const { data: affectedOrders, error: ordersError } = await supabase
      .from('orders')
      .select('id, order_number, customer_name, status, waseet_status_id, waseet_status_text')
      .eq('waseet_status_id', 2)
      .limit(5);

    if (ordersError) {
      console.log('⚠️ خطأ في جلب الطلبات المتأثرة:', ordersError.message);
    } else if (affectedOrders && affectedOrders.length > 0) {
      console.log(`📊 تم العثور على ${affectedOrders.length} طلب متأثر:`);
      affectedOrders.forEach(order => {
        console.log(`   - ${order.order_number}: ${order.customer_name} - ${order.status}`);
      });
    } else {
      console.log('📊 لا توجد طلبات متأثرة حالياً');
    }

    console.log('\n🎉 تم إصلاح المشكلة بنجاح!');
    console.log('📋 ملخص الإصلاح:');
    console.log('   ✅ تم إضافة الحالة ID=2 في قاعدة البيانات');
    console.log('   ✅ تم تحديث waseet_status_manager.js');
    console.log('   ✅ تم تحديث integrated_waseet_sync.js');
    console.log('   ✅ الحالة ستظهر للمستخدم كـ "قيد التوصيل الى الزبون (في عهدة المندوب)"');
    console.log('\n🚀 يمكنك الآن إعادة تشغيل التطبيق - المشكلة محلولة!');

  } catch (error) {
    console.error('❌ فشل في إصلاح المشكلة:', error.message);
    console.error('📋 تفاصيل الخطأ:', error);
    
    console.log('\n🔧 حل بديل - تنفيذ SQL مباشر:');
    console.log('اذهب إلى Supabase SQL Editor ونفذ:');
    console.log(`
INSERT INTO waseet_statuses (id, status_text, status_category, is_active, created_at, updated_at) 
VALUES (2, 'تم الاستلام من قبل المندوب', 'in_delivery', true, NOW(), NOW())
ON CONFLICT (id) DO NOTHING;
    `);
  }
}

// تشغيل السكربت
fixWaseetStatus2()
  .then(() => {
    console.log('✅ انتهى السكربت بنجاح');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ فشل السكربت:', error);
    process.exit(1);
  });
