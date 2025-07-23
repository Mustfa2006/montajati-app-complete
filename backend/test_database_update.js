// ===================================
// اختبار شامل لتحديث قاعدة البيانات
// Comprehensive Database Update Test
// ===================================

const { createClient } = require('@supabase/supabase-js');
const InstantStatusUpdater = require('./sync/instant_status_updater');
require('dotenv').config();

async function testDatabaseUpdate() {
  try {
    console.log('💾 اختبار شامل لتحديث قاعدة البيانات...\n');

    // إعداد Supabase
    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    // إعداد نظام التحديث الفوري
    const instantUpdater = new InstantStatusUpdater();

    // 1. جلب طلب للاختبار
    console.log('📋 جلب طلب للاختبار...');
    const { data: orders, error } = await supabase
      .from('orders')
      .select('*')
      .not('waseet_order_id', 'is', null)
      .limit(1);

    if (error || !orders || orders.length === 0) {
      throw new Error('لا توجد طلبات للاختبار');
    }

    const testOrder = orders[0];
    console.log(`✅ تم اختيار الطلب: ${testOrder.order_number}`);
    console.log(`🆔 معرف الطلب: ${testOrder.id}`);
    console.log(`📊 الحالة الحالية: ${testOrder.status}`);
    console.log(`🔄 حالة الوسيط الحالية: ${testOrder.waseet_status || 'غير محددة'}`);

    // 2. حفظ الحالة الأصلية
    const originalOrder = { ...testOrder };
    console.log('\n💾 تم حفظ الحالة الأصلية للطلب');

    // 3. اختبار تحديثات مختلفة
    const testUpdates = [
      {
        name: 'تحديث إلى قيد التوصيل',
        waseetStatus: 'shipped',
        expectedLocalStatus: 'in_delivery'
      },
      {
        name: 'تحديث إلى تم التسليم',
        waseetStatus: 'delivered',
        expectedLocalStatus: 'delivered'
      },
      {
        name: 'تحديث إلى ملغي',
        waseetStatus: 'cancelled',
        expectedLocalStatus: 'cancelled'
      },
      {
        name: 'إعادة إلى نشط',
        waseetStatus: 'confirmed',
        expectedLocalStatus: 'active'
      }
    ];

    const results = [];

    for (let i = 0; i < testUpdates.length; i++) {
      const update = testUpdates[i];
      console.log(`\n🔄 اختبار ${i + 1}: ${update.name}`);
      console.log(`📊 حالة الوسيط الجديدة: ${update.waseetStatus}`);
      console.log(`📋 الحالة المحلية المتوقعة: ${update.expectedLocalStatus}`);

      try {
        // جلب الحالة الحالية قبل التحديث
        const { data: beforeUpdate } = await supabase
          .from('orders')
          .select('*')
          .eq('id', testOrder.id)
          .single();

        console.log(`📊 الحالة قبل التحديث: ${beforeUpdate.status}`);

        // تحديث الحالة
        const updateResult = await instantUpdater.instantUpdateOrderStatus(
          testOrder.id,
          update.waseetStatus,
          {
            status: update.waseetStatus,
            order_id: testOrder.waseet_order_id,
            updated_at: new Date().toISOString(),
            test_mode: true,
            test_name: update.name
          }
        );

        console.log(`📊 نتيجة التحديث:`, JSON.stringify(updateResult, null, 2));

        if (updateResult.success) {
          // التحقق من التحديث في قاعدة البيانات
          const { data: afterUpdate } = await supabase
            .from('orders')
            .select('*')
            .eq('id', testOrder.id)
            .single();

          console.log(`✅ الحالة بعد التحديث: ${afterUpdate.status}`);
          console.log(`🔄 حالة الوسيط بعد التحديث: ${afterUpdate.waseet_status}`);
          console.log(`⏰ آخر فحص: ${afterUpdate.last_status_check}`);
          console.log(`📅 آخر تحديث: ${afterUpdate.updated_at}`);

          // التحقق من صحة التحديث
          const isCorrect = afterUpdate.status === update.expectedLocalStatus &&
                           afterUpdate.waseet_status === update.waseetStatus;

          console.log(`✅ التحديث صحيح: ${isCorrect ? 'نعم' : 'لا'}`);

          if (!isCorrect) {
            console.log(`❌ خطأ: متوقع ${update.expectedLocalStatus}، حصلت على ${afterUpdate.status}`);
          }

          // فحص سجل التغييرات
          const { data: history } = await supabase
            .from('order_status_history')
            .select('*')
            .eq('order_id', testOrder.id)
            .order('created_at', { ascending: false })
            .limit(1);

          if (history && history.length > 0) {
            const latestHistory = history[0];
            console.log(`📚 آخر سجل تغيير: ${latestHistory.old_status} → ${latestHistory.new_status}`);
            console.log(`👤 تم بواسطة: ${latestHistory.changed_by}`);
            console.log(`📝 السبب: ${latestHistory.change_reason}`);
          } else {
            console.log(`⚠️ تحذير: لم يتم العثور على سجل تغيير`);
          }

          results.push({
            test_name: update.name,
            success: true,
            correct: isCorrect,
            before_status: beforeUpdate.status,
            after_status: afterUpdate.status,
            expected_status: update.expectedLocalStatus,
            waseet_status: update.waseetStatus,
            update_time: updateResult.updateTime,
            has_history: history && history.length > 0
          });

        } else {
          console.log(`❌ فشل التحديث: ${updateResult.error}`);
          
          results.push({
            test_name: update.name,
            success: false,
            error: updateResult.error
          });
        }

      } catch (error) {
        console.log(`❌ خطأ في الاختبار: ${error.message}`);
        
        results.push({
          test_name: update.name,
          success: false,
          error: error.message
        });
      }

      console.log('-'.repeat(60));
      
      // انتظار قصير بين الاختبارات
      await new Promise(resolve => setTimeout(resolve, 1000));
    }

    // 4. إعادة الطلب للحالة الأصلية
    console.log('\n🔄 إعادة الطلب للحالة الأصلية...');
    
    try {
      const { error: restoreError } = await supabase
        .from('orders')
        .update({
          status: originalOrder.status,
          waseet_status: originalOrder.waseet_status,
          waseet_data: originalOrder.waseet_data,
          last_status_check: originalOrder.last_status_check,
          status_updated_at: originalOrder.status_updated_at,
          updated_at: originalOrder.updated_at
        })
        .eq('id', testOrder.id);

      if (restoreError) {
        console.log(`⚠️ تحذير: فشل في إعادة الحالة الأصلية: ${restoreError.message}`);
      } else {
        console.log('✅ تم إعادة الطلب للحالة الأصلية');
      }
    } catch (error) {
      console.log(`⚠️ تحذير: خطأ في إعادة الحالة الأصلية: ${error.message}`);
    }

    // 5. اختبار التحديث المتعدد
    console.log('\n🔄 اختبار التحديث المتعدد...');
    
    try {
      // جلب عدة طلبات للاختبار
      const { data: multipleOrders } = await supabase
        .from('orders')
        .select('id, order_number, status, waseet_order_id')
        .not('waseet_order_id', 'is', null)
        .limit(3);

      if (multipleOrders && multipleOrders.length > 0) {
        const batchUpdates = multipleOrders.map(order => ({
          orderId: order.id,
          waseetStatus: 'confirmed',
          waseetData: {
            status: 'confirmed',
            order_id: order.waseet_order_id,
            batch_test: true,
            updated_at: new Date().toISOString()
          }
        }));

        console.log(`📊 تحديث ${batchUpdates.length} طلب معاً...`);

        const batchResult = await instantUpdater.batchInstantUpdate(batchUpdates);
        
        console.log(`✅ نتيجة التحديث المتعدد:`);
        console.log(`📊 إجمالي الطلبات: ${batchResult.totalUpdates}`);
        console.log(`✅ نجح: ${batchResult.successfulUpdates}`);
        console.log(`🔄 تغيير: ${batchResult.changedUpdates}`);
        console.log(`⏱️ الوقت الإجمالي: ${batchResult.totalTime}ms`);

        results.push({
          test_name: 'التحديث المتعدد',
          success: true,
          batch_size: batchResult.totalUpdates,
          successful_updates: batchResult.successfulUpdates,
          changed_updates: batchResult.changedUpdates,
          total_time: batchResult.totalTime
        });

      } else {
        console.log('⚠️ لا توجد طلبات كافية لاختبار التحديث المتعدد');
      }
    } catch (error) {
      console.log(`❌ خطأ في اختبار التحديث المتعدد: ${error.message}`);
    }

    // 6. فحص إحصائيات نظام التحديث
    console.log('\n📊 إحصائيات نظام التحديث الفوري:');
    const stats = instantUpdater.getUpdateStats();
    console.log(JSON.stringify(stats, null, 2));

    // 7. تقرير النتائج النهائي
    console.log('\n🎯 تقرير النتائج النهائي:');
    console.log('='.repeat(80));

    const successfulTests = results.filter(r => r.success).length;
    const correctTests = results.filter(r => r.success && r.correct !== false).length;
    const totalTests = results.length;

    console.log(`✅ اختبارات ناجحة: ${successfulTests}/${totalTests}`);
    console.log(`✅ اختبارات صحيحة: ${correctTests}/${totalTests}`);
    console.log(`📈 معدل النجاح: ${((successfulTests / totalTests) * 100).toFixed(1)}%`);
    console.log(`📈 معدل الصحة: ${((correctTests / totalTests) * 100).toFixed(1)}%`);

    console.log('\n📋 تفاصيل النتائج:');
    results.forEach((result, index) => {
      console.log(`${index + 1}. ${result.test_name}:`);
      if (result.success) {
        console.log(`   ✅ نجح`);
        if (result.correct !== undefined) {
          console.log(`   📊 صحيح: ${result.correct ? 'نعم' : 'لا'}`);
        }
        if (result.update_time) {
          console.log(`   ⏱️ وقت التحديث: ${result.update_time}ms`);
        }
      } else {
        console.log(`   ❌ فشل: ${result.error}`);
      }
    });

    console.log('\n🎉 انتهى اختبار تحديث قاعدة البيانات!');

    return {
      success_rate: ((successfulTests / totalTests) * 100).toFixed(1),
      accuracy_rate: ((correctTests / totalTests) * 100).toFixed(1),
      total_tests: totalTests,
      successful_tests: successfulTests,
      correct_tests: correctTests,
      results,
      updater_stats: stats
    };

  } catch (error) {
    console.error('❌ خطأ عام في اختبار قاعدة البيانات:', error.message);
    return {
      success: false,
      error: error.message
    };
  }
}

// تشغيل الاختبار
if (require.main === module) {
  testDatabaseUpdate().then(report => {
    console.log('\n📊 ملخص سريع:');
    if (report.success_rate) {
      console.log(`🎯 معدل النجاح: ${report.success_rate}%`);
      console.log(`📈 معدل الصحة: ${report.accuracy_rate}%`);
      console.log(`📊 إجمالي الاختبارات: ${report.total_tests}`);
    }
  }).catch(error => {
    console.error('❌ خطأ في تشغيل الاختبار:', error.message);
  });
}

module.exports = testDatabaseUpdate;
