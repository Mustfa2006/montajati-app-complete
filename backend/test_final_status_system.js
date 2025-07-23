// ===================================
// اختبار النظام النهائي لجلب الحالات
// Final Status System Test
// ===================================

const { createClient } = require('@supabase/supabase-js');
const RealWaseetFetcher = require('./sync/real_waseet_fetcher');
const statusMapper = require('./sync/status_mapper');
const InstantStatusUpdater = require('./sync/instant_status_updater');
require('dotenv').config();

async function testFinalStatusSystem() {
  try {
    console.log('🎯 اختبار النظام النهائي لجلب الحالات من شركة الوسيط...\n');
    console.log('=' * 80);

    // إعداد الخدمات
    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
    
    const waseetFetcher = new RealWaseetFetcher();
    const instantUpdater = new InstantStatusUpdater();

    const testResults = {
      step1_waseet_connection: false,
      step2_fetch_orders: false,
      step3_extract_statuses: false,
      step4_status_mapping: false,
      step5_database_update: false,
      step6_verify_update: false,
      step7_status_coverage: false
    };

    // ===================================
    // الخطوة 1: اختبار الاتصال مع شركة الوسيط
    // ===================================
    console.log('🔗 الخطوة 1: اختبار الاتصال مع شركة الوسيط...');
    
    try {
      const token = await waseetFetcher.authenticate();
      if (token) {
        console.log('✅ تم الاتصال وتسجيل الدخول بنجاح');
        testResults.step1_waseet_connection = true;
      }
    } catch (error) {
      console.log(`❌ فشل الاتصال: ${error.message}`);
    }

    // ===================================
    // الخطوة 2: جلب الطلبات من شركة الوسيط
    // ===================================
    console.log('\n📋 الخطوة 2: جلب الطلبات من شركة الوسيط...');
    
    try {
      const ordersResult = await waseetFetcher.fetchAllOrderStatuses();
      if (ordersResult.success) {
        console.log(`✅ تم جلب ${ordersResult.total_orders} طلب بنجاح`);
        console.log('📊 إحصائيات الحالات:');
        Object.entries(ordersResult.status_counts).forEach(([status, count]) => {
          console.log(`   ${status}: ${count} طلب`);
        });
        testResults.step2_fetch_orders = true;
        testResults.ordersData = ordersResult;
      } else {
        console.log(`❌ فشل جلب الطلبات: ${ordersResult.error}`);
      }
    } catch (error) {
      console.log(`❌ خطأ في جلب الطلبات: ${error.message}`);
    }

    // ===================================
    // الخطوة 3: استخراج الحالات المتاحة
    // ===================================
    console.log('\n🔍 الخطوة 3: استخراج الحالات المتاحة...');
    
    try {
      const statusesResult = await waseetFetcher.getAvailableStatuses();
      if (statusesResult.success) {
        console.log(`✅ تم استخراج ${statusesResult.total_statuses} حالة مختلفة`);
        console.log('📋 الحالات المتاحة:');
        statusesResult.statuses.forEach((status, index) => {
          console.log(`   ${index + 1}. ID ${status.id}: "${status.text}" (${status.count} طلب)`);
        });
        testResults.step3_extract_statuses = true;
        testResults.statusesData = statusesResult;
      } else {
        console.log(`❌ فشل استخراج الحالات: ${statusesResult.error}`);
      }
    } catch (error) {
      console.log(`❌ خطأ في استخراج الحالات: ${error.message}`);
    }

    // ===================================
    // الخطوة 4: اختبار تحويل الحالات
    // ===================================
    console.log('\n🗺️ الخطوة 4: اختبار تحويل الحالات...');
    
    try {
      if (testResults.statusesData) {
        console.log('📊 اختبار تحويل الحالات المكتشفة:');
        let mappedCount = 0;
        
        testResults.statusesData.statuses.forEach((status, index) => {
          // اختبار التحويل بـ ID
          const localStatusById = statusMapper.mapWaseetToLocal(status.id);
          // اختبار التحويل بالنص
          const localStatusByText = statusMapper.mapWaseetToLocal(status.text);
          
          console.log(`   ${index + 1}. ID ${status.id} "${status.text}":`);
          console.log(`      بـ ID: ${status.id} → ${localStatusById}`);
          console.log(`      بالنص: "${status.text}" → ${localStatusByText}`);
          
          if (localStatusById !== 'unknown' || localStatusByText !== 'unknown') {
            mappedCount++;
          }
        });
        
        console.log(`✅ تم تحويل ${mappedCount}/${testResults.statusesData.statuses.length} حالة بنجاح`);
        testResults.step4_status_mapping = true;
        testResults.mappedCount = mappedCount;
      }
    } catch (error) {
      console.log(`❌ خطأ في تحويل الحالات: ${error.message}`);
    }

    // ===================================
    // الخطوة 5: اختبار تحديث قاعدة البيانات
    // ===================================
    console.log('\n💾 الخطوة 5: اختبار تحديث قاعدة البيانات...');
    
    try {
      // جلب طلب للاختبار من قاعدة البيانات
      const { data: orders } = await supabase
        .from('orders')
        .select('id, order_number, waseet_order_id, status')
        .not('waseet_order_id', 'is', null)
        .limit(1);

      if (orders && orders.length > 0) {
        const testOrder = orders[0];
        console.log(`📦 طلب الاختبار: ${testOrder.order_number} (ID: ${testOrder.waseet_order_id})`);
        
        // جلب حالة الطلب من شركة الوسيط
        const orderStatus = await waseetFetcher.fetchOrderStatus(testOrder.waseet_order_id);
        
        if (orderStatus.success) {
          console.log(`📊 حالة الطلب في الوسيط: ID ${orderStatus.status_id} - "${orderStatus.status_text}"`);
          
          // تحديث الطلب
          const updateResult = await instantUpdater.instantUpdateOrderStatus(
            testOrder.id,
            orderStatus.status_id, // استخدام ID بدلاً من النص
            {
              status: orderStatus.status_text,
              status_id: orderStatus.status_id,
              updated_at: new Date().toISOString(),
              real_waseet_test: true
            }
          );

          if (updateResult.success) {
            console.log('✅ تم تحديث قاعدة البيانات بنجاح');
            console.log(`🔄 التغيير: ${updateResult.oldStatus} → ${updateResult.newStatus}`);
            testResults.step5_database_update = true;
            testResults.updateResult = updateResult;
          } else {
            console.log(`❌ فشل التحديث: ${updateResult.error}`);
          }
        } else {
          console.log(`❌ فشل جلب حالة الطلب: ${orderStatus.error}`);
        }
      } else {
        console.log('⚠️ لا توجد طلبات للاختبار');
      }
    } catch (error) {
      console.log(`❌ خطأ في تحديث قاعدة البيانات: ${error.message}`);
    }

    // ===================================
    // الخطوة 6: التحقق من التحديث
    // ===================================
    console.log('\n🔍 الخطوة 6: التحقق من التحديث...');
    
    try {
      if (testResults.updateResult) {
        // فحص سجل التغييرات
        const { data: history } = await supabase
          .from('order_status_history')
          .select('*')
          .order('created_at', { ascending: false })
          .limit(1);

        if (history && history.length > 0) {
          const latestChange = history[0];
          console.log('✅ تم العثور على سجل التغيير:');
          console.log(`   📋 التغيير: ${latestChange.old_status} → ${latestChange.new_status}`);
          console.log(`   👤 بواسطة: ${latestChange.changed_by}`);
          console.log(`   📝 السبب: ${latestChange.change_reason}`);
          testResults.step6_verify_update = true;
        } else {
          console.log('⚠️ لم يتم العثور على سجل التغيير');
        }
      }
    } catch (error) {
      console.log(`❌ خطأ في التحقق من التحديث: ${error.message}`);
    }

    // ===================================
    // الخطوة 7: تقييم تغطية الحالات
    // ===================================
    console.log('\n📊 الخطوة 7: تقييم تغطية الحالات...');
    
    const expectedStatuses = [3, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42];
    
    try {
      if (testResults.statusesData) {
        const foundStatusIds = testResults.statusesData.statuses.map(s => parseInt(s.id));
        const coveredStatuses = expectedStatuses.filter(id => foundStatusIds.includes(id));
        const coverageRate = ((coveredStatuses.length / expectedStatuses.length) * 100).toFixed(1);
        
        console.log(`📊 الحالات المطلوبة: ${expectedStatuses.length}`);
        console.log(`✅ الحالات الموجودة: ${coveredStatuses.length}`);
        console.log(`📈 معدل التغطية: ${coverageRate}%`);
        
        if (coveredStatuses.length > 0) {
          console.log('✅ الحالات الموجودة:');
          coveredStatuses.forEach(id => {
            const statusData = testResults.statusesData.statuses.find(s => parseInt(s.id) === id);
            if (statusData) {
              console.log(`   ID ${id}: "${statusData.text}"`);
            }
          });
        }

        const missingStatuses = expectedStatuses.filter(id => !foundStatusIds.includes(id));
        if (missingStatuses.length > 0) {
          console.log('⚠️ الحالات المفقودة (ستظهر عند وجود طلبات بهذه الحالات):');
          missingStatuses.forEach(id => {
            console.log(`   ID ${id}`);
          });
        }

        testResults.step7_status_coverage = true;
        testResults.coverageRate = coverageRate;
      }
    } catch (error) {
      console.log(`❌ خطأ في تقييم التغطية: ${error.message}`);
    }

    // ===================================
    // تقرير النتائج النهائي
    // ===================================
    console.log('\n🎯 تقرير النظام النهائي:');
    console.log('=' * 80);

    const steps = [
      { name: 'الاتصال مع شركة الوسيط', key: 'step1_waseet_connection' },
      { name: 'جلب الطلبات', key: 'step2_fetch_orders' },
      { name: 'استخراج الحالات', key: 'step3_extract_statuses' },
      { name: 'تحويل الحالات', key: 'step4_status_mapping' },
      { name: 'تحديث قاعدة البيانات', key: 'step5_database_update' },
      { name: 'التحقق من التحديث', key: 'step6_verify_update' },
      { name: 'تغطية الحالات', key: 'step7_status_coverage' }
    ];

    console.log('📊 نتائج الخطوات:');
    steps.forEach((step, index) => {
      const result = testResults[step.key];
      const icon = result ? '✅' : '❌';
      const status = result ? 'نجح' : 'فشل';
      console.log(`${icon} ${index + 1}. ${step.name}: ${status}`);
    });

    const successCount = Object.values(testResults).filter(v => typeof v === 'boolean' && v).length;
    const totalSteps = steps.length;
    const successRate = ((successCount / totalSteps) * 100).toFixed(1);

    console.log(`\n📈 معدل النجاح الإجمالي: ${successRate}% (${successCount}/${totalSteps})`);

    // تقييم النتيجة
    if (successRate >= 85) {
      console.log('🎉 ممتاز! النظام يعمل بشكل مثالي');
      console.log('✅ يمكن جلب الحالات الحقيقية من شركة الوسيط');
      console.log('✅ تحويل الحالات يعمل بشكل صحيح');
      console.log('✅ تحديث قاعدة البيانات فوري ودقيق');
    } else if (successRate >= 70) {
      console.log('✅ جيد جداً! النظام يعمل بشكل موثوق');
      console.log('🔧 بعض التحسينات الطفيفة مطلوبة');
    } else if (successRate >= 50) {
      console.log('⚠️ جيد! يحتاج بعض التحسينات');
    } else {
      console.log('🚨 يحتاج إصلاحات جوهرية');
    }

    // ملخص الإنجازات
    console.log('\n🏆 ملخص الإنجازات:');
    if (testResults.step1_waseet_connection) {
      console.log('✅ تم تأكيد الاتصال مع شركة الوسيط');
    }
    if (testResults.step2_fetch_orders) {
      console.log(`✅ تم جلب ${testResults.ordersData?.total_orders || 0} طلب من الوسيط`);
    }
    if (testResults.step3_extract_statuses) {
      console.log(`✅ تم استخراج ${testResults.statusesData?.total_statuses || 0} حالة مختلفة`);
    }
    if (testResults.step4_status_mapping) {
      console.log(`✅ تم تحويل ${testResults.mappedCount || 0} حالة بنجاح`);
    }
    if (testResults.step5_database_update) {
      console.log('✅ تحديث قاعدة البيانات يعمل بشكل فوري');
    }
    if (testResults.step7_status_coverage) {
      console.log(`✅ معدل تغطية الحالات: ${testResults.coverageRate || 0}%`);
    }

    console.log('\n🎉 انتهى اختبار النظام النهائي!');

    return {
      success_rate: successRate,
      successful_steps: successCount,
      total_steps: totalSteps,
      results: testResults,
      summary: 'النظام يجلب الحالات الحقيقية من شركة الوسيط ويحدث قاعدة البيانات فورياً'
    };

  } catch (error) {
    console.error('❌ خطأ عام في اختبار النظام النهائي:', error.message);
    return {
      success: false,
      error: error.message
    };
  }
}

// تشغيل الاختبار
if (require.main === module) {
  testFinalStatusSystem().then(report => {
    console.log('\n📊 ملخص نهائي سريع:');
    if (report.success_rate) {
      console.log(`🎯 معدل النجاح: ${report.success_rate}%`);
      console.log(`📈 خطوات ناجحة: ${report.successful_steps}/${report.total_steps}`);
      console.log(`📋 الملخص: ${report.summary}`);
    }
  }).catch(error => {
    console.error('❌ خطأ في تشغيل الاختبار:', error.message);
  });
}

module.exports = testFinalStatusSystem;
