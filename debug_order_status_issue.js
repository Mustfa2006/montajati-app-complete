const axios = require('axios');

// تشخيص شامل لمشكلة تحديث حالة الطلب
class OrderStatusDebugger {
  constructor() {
    this.baseURL = 'https://montajati-official-backend-production.up.railway.app';
    this.testOrderId = 'order_17'; // من الصورة
    this.results = {
      serverHealth: null,
      orderExists: null,
      apiEndpoints: {},
      networkRequests: [],
      errorDetails: []
    };
  }

  // فحص صحة الخادم
  async checkServerHealth() {
    console.log('🏥 === فحص صحة الخادم ===');
    
    try {
      const response = await axios.get(`${this.baseURL}/health`, {
        timeout: 15000,
        validateStatus: () => true
      });
      
      this.results.serverHealth = {
        status: response.status,
        working: response.status >= 200 && response.status < 300,
        data: response.data,
        timestamp: new Date().toISOString()
      };
      
      console.log(`📊 Status: ${response.status}`);
      console.log(`✅ يعمل: ${this.results.serverHealth.working ? 'نعم' : 'لا'}`);
      
      if (this.results.serverHealth.working) {
        console.log('📄 معلومات الخادم:', JSON.stringify(response.data, null, 2));
      } else {
        console.log('❌ الخادم لا يعمل');
        if (typeof response.data === 'string') {
          console.log('📄 رسالة الخطأ:', response.data.substring(0, 200) + '...');
        }
      }
      
      return this.results.serverHealth.working;
    } catch (error) {
      console.log(`❌ خطأ في الاتصال: ${error.message}`);
      this.results.serverHealth = {
        status: null,
        working: false,
        error: error.message,
        timestamp: new Date().toISOString()
      };
      return false;
    }
  }

  // فحص وجود الطلب
  async checkOrderExists() {
    console.log('\n📦 === فحص وجود الطلب ===');
    
    try {
      const response = await axios.get(`${this.baseURL}/api/orders/${this.testOrderId}`, {
        timeout: 15000,
        validateStatus: () => true
      });
      
      this.results.orderExists = {
        status: response.status,
        exists: response.status === 200,
        data: response.data,
        timestamp: new Date().toISOString()
      };
      
      console.log(`📊 Status: ${response.status}`);
      console.log(`✅ موجود: ${this.results.orderExists.exists ? 'نعم' : 'لا'}`);
      
      if (this.results.orderExists.exists && response.data?.data) {
        const order = response.data.data;
        console.log(`🆔 ID: ${order.id}`);
        console.log(`📊 الحالة الحالية: "${order.status}"`);
        console.log(`👤 العميل: ${order.customer_name}`);
        console.log(`📞 الهاتف: ${order.customer_phone}`);
        console.log(`📅 تاريخ الإنشاء: ${order.created_at}`);
        console.log(`🔄 آخر تحديث: ${order.updated_at}`);
      } else {
        console.log('❌ الطلب غير موجود أو خطأ في البيانات');
        if (response.data) {
          console.log('📄 استجابة الخادم:', JSON.stringify(response.data, null, 2));
        }
      }
      
      return this.results.orderExists.exists;
    } catch (error) {
      console.log(`❌ خطأ في فحص الطلب: ${error.message}`);
      this.results.orderExists = {
        status: null,
        exists: false,
        error: error.message,
        timestamp: new Date().toISOString()
      };
      return false;
    }
  }

  // اختبار جميع API endpoints المتعلقة بتحديث الحالة
  async testStatusUpdateEndpoints() {
    console.log('\n🔧 === اختبار API Endpoints ===');
    
    const endpoints = [
      {
        name: 'PUT /api/orders/:id/status',
        method: 'PUT',
        url: `/api/orders/${this.testOrderId}/status`,
        data: {
          status: 'قيد التحضير',
          notes: 'اختبار تشخيص شامل',
          changedBy: 'debug_test'
        }
      },
      {
        name: 'POST /api/waseet-statuses/update-order-status',
        method: 'POST',
        url: '/api/waseet-statuses/update-order-status',
        data: {
          orderId: this.testOrderId,
          waseetStatusId: 1,
          waseetStatusText: 'نشط'
        }
      }
    ];
    
    for (const endpoint of endpoints) {
      console.log(`\n🧪 اختبار: ${endpoint.name}`);
      console.log(`🌐 URL: ${this.baseURL}${endpoint.url}`);
      console.log(`📋 البيانات:`, JSON.stringify(endpoint.data, null, 2));
      
      try {
        const startTime = Date.now();
        
        const response = await axios({
          method: endpoint.method,
          url: `${this.baseURL}${endpoint.url}`,
          data: endpoint.data,
          headers: { 'Content-Type': 'application/json' },
          timeout: 15000,
          validateStatus: () => true
        });
        
        const endTime = Date.now();
        const duration = endTime - startTime;
        
        const result = {
          status: response.status,
          success: response.status >= 200 && response.status < 300,
          data: response.data,
          duration: duration,
          timestamp: new Date().toISOString()
        };
        
        this.results.apiEndpoints[endpoint.name] = result;
        this.results.networkRequests.push({
          endpoint: endpoint.name,
          method: endpoint.method,
          url: endpoint.url,
          requestData: endpoint.data,
          response: result,
          timestamp: new Date().toISOString()
        });
        
        console.log(`📊 Status: ${result.status}`);
        console.log(`✅ نجح: ${result.success ? 'نعم' : 'لا'}`);
        console.log(`⏱️ المدة: ${duration}ms`);
        
        if (result.success) {
          console.log('🎉 نجح التحديث!');
          console.log('📄 النتيجة:', JSON.stringify(result.data, null, 2));
        } else {
          console.log('❌ فشل التحديث');
          console.log('📄 تفاصيل الخطأ:', JSON.stringify(result.data, null, 2));
          
          // تحليل نوع الخطأ
          this.analyzeError(endpoint.name, result);
        }
        
        // انتظار قصير بين الطلبات
        await new Promise(resolve => setTimeout(resolve, 2000));
        
      } catch (error) {
        console.log(`❌ خطأ في الطلب: ${error.message}`);
        
        const errorResult = {
          status: null,
          success: false,
          error: error.message,
          code: error.code,
          timestamp: new Date().toISOString()
        };
        
        this.results.apiEndpoints[endpoint.name] = errorResult;
        this.analyzeError(endpoint.name, errorResult);
      }
    }
  }

  // تحليل الأخطاء
  analyzeError(endpointName, result) {
    const errorAnalysis = {
      endpoint: endpointName,
      status: result.status,
      timestamp: new Date().toISOString(),
      type: 'unknown',
      possibleCauses: [],
      suggestedFixes: []
    };
    
    if (result.status === 404) {
      errorAnalysis.type = 'not_found';
      errorAnalysis.possibleCauses.push('الطلب غير موجود');
      errorAnalysis.possibleCauses.push('خطأ في معرف الطلب');
      errorAnalysis.possibleCauses.push('مشكلة في routing');
      errorAnalysis.suggestedFixes.push('التحقق من وجود الطلب في قاعدة البيانات');
      errorAnalysis.suggestedFixes.push('فحص API routing');
    } else if (result.status === 500) {
      errorAnalysis.type = 'server_error';
      errorAnalysis.possibleCauses.push('خطأ في الخادم');
      errorAnalysis.possibleCauses.push('مشكلة في قاعدة البيانات');
      errorAnalysis.possibleCauses.push('خطأ في معالجة البيانات');
      errorAnalysis.suggestedFixes.push('فحص server logs');
      errorAnalysis.suggestedFixes.push('التحقق من database connection');
    } else if (result.status === 400) {
      errorAnalysis.type = 'bad_request';
      errorAnalysis.possibleCauses.push('بيانات غير صحيحة');
      errorAnalysis.possibleCauses.push('validation error');
      errorAnalysis.suggestedFixes.push('التحقق من صحة البيانات المرسلة');
    } else if (!result.status) {
      errorAnalysis.type = 'network_error';
      errorAnalysis.possibleCauses.push('مشكلة في الشبكة');
      errorAnalysis.possibleCauses.push('timeout');
      errorAnalysis.possibleCauses.push('الخادم لا يستجيب');
      errorAnalysis.suggestedFixes.push('فحص اتصال الإنترنت');
      errorAnalysis.suggestedFixes.push('فحص حالة الخادم');
    }
    
    this.results.errorDetails.push(errorAnalysis);
    
    console.log(`🔍 تحليل الخطأ:`);
    console.log(`   النوع: ${errorAnalysis.type}`);
    console.log(`   الأسباب المحتملة:`);
    errorAnalysis.possibleCauses.forEach(cause => console.log(`     - ${cause}`));
    console.log(`   الحلول المقترحة:`);
    errorAnalysis.suggestedFixes.forEach(fix => console.log(`     - ${fix}`));
  }

  // إنشاء تقرير شامل
  generateReport() {
    console.log('\n📋 ===== التقرير الشامل =====');
    
    const report = {
      timestamp: new Date().toISOString(),
      testOrderId: this.testOrderId,
      baseURL: this.baseURL,
      summary: {
        serverWorking: this.results.serverHealth?.working || false,
        orderExists: this.results.orderExists?.exists || false,
        endpointsWorking: Object.values(this.results.apiEndpoints).filter(ep => ep.success).length,
        totalEndpoints: Object.keys(this.results.apiEndpoints).length,
        totalErrors: this.results.errorDetails.length
      },
      details: this.results
    };
    
    console.log('📊 ملخص النتائج:');
    console.log(`   🏥 الخادم يعمل: ${report.summary.serverWorking ? '✅' : '❌'}`);
    console.log(`   📦 الطلب موجود: ${report.summary.orderExists ? '✅' : '❌'}`);
    console.log(`   🔧 APIs تعمل: ${report.summary.endpointsWorking}/${report.summary.totalEndpoints}`);
    console.log(`   ❌ إجمالي الأخطاء: ${report.summary.totalErrors}`);
    
    if (report.summary.totalErrors > 0) {
      console.log('\n🔍 تحليل الأخطاء:');
      this.results.errorDetails.forEach((error, index) => {
        console.log(`   ${index + 1}. ${error.endpoint}: ${error.type}`);
      });
    }
    
    // تحديد السبب الجذري
    console.log('\n🎯 السبب الجذري المحتمل:');
    if (!report.summary.serverWorking) {
      console.log('   🚨 الخادم لا يعمل - مشكلة في الـ hosting');
    } else if (!report.summary.orderExists) {
      console.log('   📦 الطلب غير موجود - مشكلة في البيانات');
    } else if (report.summary.endpointsWorking === 0) {
      console.log('   🔧 جميع APIs لا تعمل - مشكلة في الكود');
    } else if (report.summary.endpointsWorking < report.summary.totalEndpoints) {
      console.log('   ⚠️ بعض APIs لا تعمل - مشكلة جزئية');
    } else {
      console.log('   ✅ جميع الاختبارات نجحت - المشكلة قد تكون في Frontend');
    }
    
    return report;
  }

  // تشغيل التشخيص الكامل
  async runFullDiagnosis() {
    console.log('🔍 ===== بداية التشخيص الشامل =====');
    console.log(`⏰ الوقت: ${new Date().toISOString()}`);
    console.log(`🌐 الخادم: ${this.baseURL}`);
    console.log(`📦 طلب الاختبار: ${this.testOrderId}`);
    
    try {
      // 1. فحص صحة الخادم
      const serverWorking = await this.checkServerHealth();
      
      if (!serverWorking) {
        console.log('\n🚨 الخادم لا يعمل - توقف التشخيص');
        return this.generateReport();
      }
      
      // 2. فحص وجود الطلب
      const orderExists = await this.checkOrderExists();
      
      if (!orderExists) {
        console.log('\n⚠️ الطلب غير موجود - سيتم اختبار APIs بطلب وهمي');
      }
      
      // 3. اختبار APIs
      await this.testStatusUpdateEndpoints();
      
      // 4. إنشاء التقرير
      return this.generateReport();
      
    } catch (error) {
      console.error('❌ خطأ في التشخيص:', error.message);
      this.results.errorDetails.push({
        type: 'diagnosis_error',
        error: error.message,
        timestamp: new Date().toISOString()
      });
      return this.generateReport();
    }
  }
}

// تشغيل التشخيص
async function main() {
  const statusDebugger = new OrderStatusDebugger();
  const report = await statusDebugger.runFullDiagnosis();
  
  console.log('\n💾 حفظ التقرير...');
  // يمكن حفظ التقرير في ملف JSON هنا
  
  console.log('\n🏁 ===== انتهاء التشخيص =====');
  return report;
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = { OrderStatusDebugger };
