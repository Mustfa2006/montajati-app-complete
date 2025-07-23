// ===================================
// اختبار شامل لتحويل الحالات
// Comprehensive Status Mapping Test
// ===================================

const statusMapper = require('./sync/status_mapper');

function testStatusMapping() {
  console.log('🗺️ اختبار شامل لتحويل الحالات...\n');

  // حالات الوسيط للاختبار
  const waseetStatuses = [
    // حالات النشاط
    'pending', 'confirmed', 'accepted', 'processing', 'prepared',
    
    // حالات التوصيل
    'shipped', 'sent', 'in_transit', 'out_for_delivery', 'on_the_way', 'dispatched', 'picked_up',
    
    // حالات التسليم
    'delivered', 'completed', 'success', 'received',
    
    // حالات الإلغاء
    'cancelled', 'canceled', 'rejected', 'failed', 'returned', 'refunded',
    
    // حالات غير معروفة للاختبار
    'unknown_status', 'test_status', '', null, undefined
  ];

  console.log('📊 اختبار تحويل الحالات:');
  console.log('='.repeat(80));

  const results = [];
  let successCount = 0;
  let errorCount = 0;

  waseetStatuses.forEach((waseetStatus, index) => {
    try {
      console.log(`\n${index + 1}. اختبار حالة: "${waseetStatus}"`);
      
      const localStatus = statusMapper.mapWaseetToLocal(waseetStatus);
      const description = statusMapper.getStatusDescription(localStatus);
      const notification = statusMapper.getNotificationMessage(localStatus);
      const color = statusMapper.getStatusColor(localStatus);
      const icon = statusMapper.getStatusIcon(localStatus);
      
      console.log(`   📤 الحالة المحلية: ${localStatus}`);
      console.log(`   📝 الوصف: ${description}`);
      console.log(`   📱 رسالة الإشعار: ${notification}`);
      console.log(`   🎨 اللون: ${color}`);
      console.log(`   🔸 الأيقونة: ${icon}`);
      
      // التحقق من صحة الحالة
      const isValid = statusMapper.isValidLocalStatus(localStatus);
      const needsSync = statusMapper.needsSync(localStatus);
      const isFinal = statusMapper.isFinalStatus(localStatus);
      
      console.log(`   ✅ صحيحة: ${isValid ? 'نعم' : 'لا'}`);
      console.log(`   🔄 تحتاج مزامنة: ${needsSync ? 'نعم' : 'لا'}`);
      console.log(`   🏁 حالة نهائية: ${isFinal ? 'نعم' : 'لا'}`);
      
      results.push({
        waseet_status: waseetStatus,
        local_status: localStatus,
        description,
        notification,
        color,
        icon,
        is_valid: isValid,
        needs_sync: needsSync,
        is_final: isFinal,
        success: true
      });
      
      successCount++;
      
    } catch (error) {
      console.log(`   ❌ خطأ: ${error.message}`);
      
      results.push({
        waseet_status: waseetStatus,
        error: error.message,
        success: false
      });
      
      errorCount++;
    }
  });

  // اختبار التحويل العكسي
  console.log('\n\n🔄 اختبار التحويل العكسي (من المحلي إلى الوسيط):');
  console.log('='.repeat(80));

  const localStatuses = ['active', 'in_delivery', 'delivered', 'cancelled'];
  
  localStatuses.forEach((localStatus, index) => {
    try {
      console.log(`\n${index + 1}. تحويل عكسي: "${localStatus}"`);
      
      const waseetStatus = statusMapper.mapLocalToWaseet(localStatus);
      console.log(`   📤 حالة الوسيط: ${waseetStatus}`);
      
      // تحويل مرة أخرى للتأكد
      const backToLocal = statusMapper.mapWaseetToLocal(waseetStatus);
      console.log(`   🔄 العودة للمحلي: ${backToLocal}`);
      
      const isConsistent = backToLocal === localStatus;
      console.log(`   ✅ متسق: ${isConsistent ? 'نعم' : 'لا'}`);
      
      if (!isConsistent) {
        console.log(`   ⚠️ تحذير: عدم تطابق في التحويل`);
      }
      
    } catch (error) {
      console.log(`   ❌ خطأ: ${error.message}`);
    }
  });

  // اختبار انتقال الحالات
  console.log('\n\n🔀 اختبار انتقال الحالات:');
  console.log('='.repeat(80));

  const transitions = [
    { from: 'active', to: 'in_delivery' },
    { from: 'active', to: 'delivered' },
    { from: 'active', to: 'cancelled' },
    { from: 'in_delivery', to: 'delivered' },
    { from: 'in_delivery', to: 'cancelled' },
    { from: 'delivered', to: 'active' }, // غير صحيح
    { from: 'cancelled', to: 'active' }, // غير صحيح
    { from: 'delivered', to: 'cancelled' }, // غير صحيح
  ];

  transitions.forEach((transition, index) => {
    console.log(`\n${index + 1}. انتقال: ${transition.from} → ${transition.to}`);
    
    // هذا يتطلب إضافة دالة validateTransition في status_mapper
    // للآن سنفترض القواعد الأساسية
    const validTransitions = {
      'active': ['in_delivery', 'delivered', 'cancelled'],
      'in_delivery': ['delivered', 'cancelled'],
      'delivered': [],
      'cancelled': []
    };
    
    const isValid = validTransitions[transition.from]?.includes(transition.to) || false;
    console.log(`   ✅ صحيح: ${isValid ? 'نعم' : 'لا'}`);
    
    if (!isValid) {
      console.log(`   ⚠️ انتقال غير مسموح`);
    }
  });

  // إحصائيات الخريطة
  console.log('\n\n📊 إحصائيات خريطة الحالات:');
  console.log('='.repeat(80));

  const stats = statusMapper.getMapStats();
  console.log(`📈 حالات الوسيط المدعومة: ${stats.waseet_statuses}`);
  console.log(`📈 الحالات المحلية: ${stats.local_statuses}`);
  console.log(`📈 الحالات المدعومة: ${stats.supported_statuses.length}`);
  console.log(`📈 الحالات النهائية: ${stats.final_statuses.length}`);
  console.log(`📈 الحالات التي تحتاج مزامنة: ${stats.sync_statuses.length}`);

  // تقرير النتائج النهائي
  console.log('\n\n🎯 التقرير النهائي:');
  console.log('='.repeat(80));

  console.log(`✅ نجح: ${successCount} حالة`);
  console.log(`❌ فشل: ${errorCount} حالة`);
  console.log(`📈 معدل النجاح: ${((successCount / (successCount + errorCount)) * 100).toFixed(1)}%`);

  // عرض الحالات المدعومة
  console.log('\n📋 جميع الحالات المدعومة:');
  const supportedStatuses = statusMapper.getAllSupportedStatuses();
  
  console.log('\n🔸 حالات الوسيط:');
  supportedStatuses.waseet_statuses.forEach((status, index) => {
    const localStatus = statusMapper.mapWaseetToLocal(status);
    console.log(`   ${index + 1}. ${status} → ${localStatus}`);
  });

  console.log('\n🔸 الحالات المحلية:');
  Object.entries(supportedStatuses.descriptions).forEach(([status, description], index) => {
    console.log(`   ${index + 1}. ${status}: ${description}`);
  });

  // حفظ التقرير
  const report = {
    timestamp: new Date().toISOString(),
    total_tests: waseetStatuses.length,
    successful_tests: successCount,
    failed_tests: errorCount,
    success_rate: ((successCount / (successCount + errorCount)) * 100).toFixed(1),
    results,
    statistics: stats,
    supported_statuses: supportedStatuses
  };

  console.log('\n💾 تم حفظ التقرير في الذاكرة');
  console.log('\n🎉 انتهى اختبار تحويل الحالات!');

  return report;
}

// تشغيل الاختبار
if (require.main === module) {
  const report = testStatusMapping();
  
  // عرض ملخص سريع
  console.log('\n📊 ملخص سريع:');
  console.log(`🎯 معدل النجاح: ${report.success_rate}%`);
  console.log(`📈 حالات مدعومة: ${report.statistics.waseet_statuses}`);
  console.log(`🔄 حالات تحتاج مزامنة: ${report.statistics.sync_statuses.length}`);
}

module.exports = testStatusMapping;
