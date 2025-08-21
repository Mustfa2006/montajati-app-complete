// ===================================
// نظام التحليل الشامل لجميع جوانب النظام
// Comprehensive System Analyzer
// ===================================

const https = require('https');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

class ComprehensiveSystemAnalyzer {
  constructor() {
  this.baseUrl = 'https://montajati-official-backend-production.up.railway.app';
    this.issues = [];
    this.recommendations = [];
    this.supabase = null;
  }

  // تهيئة عميل Supabase
  async initializeSupabase() {
    try {
      this.supabase = createClient(
        process.env.SUPABASE_URL,
        process.env.SUPABASE_SERVICE_ROLE_KEY
      );
      return true;
    } catch (error) {
      this.addIssue('critical', 'supabase', 'فشل في تهيئة Supabase', error.message);
      return false;
    }
  }

  // إضافة مشكلة للقائمة
  addIssue(severity, category, title, description, solution = null) {
    this.issues.push({
      severity, // critical, high, medium, low
      category, // server, database, code, waseet, app
      title,
      description,
      solution,
      timestamp: new Date().toISOString()
    });
  }

  // إضافة توصية للقائمة
  addRecommendation(category, title, description, priority = 'medium') {
    this.recommendations.push({
      category,
      title,
      description,
      priority, // high, medium, low
      timestamp: new Date().toISOString()
    });
  }

  // 1. تحليل شامل للخادم والخدمات
  async analyzeServer() {
    console.log('\n🔍 1️⃣ تحليل شامل للخادم والخدمات...');
    console.log('='.repeat(60));

    try {
      // فحص health check
      const healthResult = await this.makeRequest('GET', `${this.baseUrl}/health`);
      
      if (!healthResult.success) {
        this.addIssue('critical', 'server', 'الخادم غير متاح', 'لا يمكن الوصول للخادم');
        return false;
      }

      const health = healthResult.data;
      console.log(`📊 حالة الخادم: ${health.status}`);
      console.log(`⏱️ وقت التشغيل: ${Math.floor(health.uptime / 60)} دقيقة`);
      console.log(`🌍 البيئة: ${health.environment}`);

      // فحص الخدمات
      if (health.services) {
        console.log('\n📋 حالة الخدمات:');
        
        // خدمة الإشعارات
        if (health.services.notifications !== 'healthy') {
          this.addIssue('high', 'server', 'خدمة الإشعارات لا تعمل', 'خدمة الإشعارات غير صحية');
        } else {
          console.log('   ✅ الإشعارات: تعمل بشكل طبيعي');
        }

        // خدمة المزامنة
        if (health.services.sync !== 'healthy') {
          this.addIssue('critical', 'server', 'خدمة المزامنة لا تعمل', 'خدمة المزامنة مع الوسيط غير مهيأة', 'إعادة تهيئة خدمة المزامنة');
        } else {
          console.log('   ✅ المزامنة: تعمل بشكل طبيعي');
        }

        // خدمة المراقبة
        if (health.services.monitor !== 'healthy') {
          this.addIssue('medium', 'server', 'خدمة المراقبة لا تعمل', 'خدمة المراقبة غير مهيأة', 'إعادة تهيئة خدمة المراقبة');
        } else {
          console.log('   ✅ المراقبة: تعمل بشكل طبيعي');
        }
      }

      // فحص الذاكرة والأداء
      if (health.system) {
        const memoryUsage = health.system.memory.heapUsed / health.system.memory.heapTotal * 100;
        console.log(`💾 استخدام الذاكرة: ${memoryUsage.toFixed(1)}%`);
        
        if (memoryUsage > 80) {
          this.addIssue('medium', 'server', 'استخدام ذاكرة عالي', `استخدام الذاكرة ${memoryUsage.toFixed(1)}%`);
        }
      }

      return true;
    } catch (error) {
      this.addIssue('critical', 'server', 'خطأ في تحليل الخادم', error.message);
      return false;
    }
  }

  // 2. تحليل شامل لقاعدة البيانات
  async analyzeDatabase() {
    console.log('\n🔍 2️⃣ تحليل شامل لقاعدة البيانات...');
    console.log('='.repeat(60));

    try {
      if (!this.supabase) {
        const initialized = await this.initializeSupabase();
        if (!initialized) return false;
      }

      // فحص الطلبات
      const { data: orders, error: ordersError } = await this.supabase
        .from('orders')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(100);

      if (ordersError) {
        this.addIssue('critical', 'database', 'فشل في جلب الطلبات', ordersError.message);
        return false;
      }

      console.log(`📦 عدد الطلبات: ${orders.length}`);

      // تحليل حالات الطلبات
      const statusCounts = {};
      const waseetStatusCounts = {};
      let ordersWithoutWaseetId = 0;
      let ordersWithWaseetErrors = 0;

      orders.forEach(order => {
        // إحصائيات الحالات
        statusCounts[order.status] = (statusCounts[order.status] || 0) + 1;
        waseetStatusCounts[order.waseet_status || 'غير محدد'] = (waseetStatusCounts[order.waseet_status || 'غير محدد'] || 0) + 1;

        // فحص مشاكل الوسيط
        if (!order.waseet_order_id && (order.status === 'in_delivery' || order.status.includes('قيد التوصيل'))) {
          ordersWithoutWaseetId++;
        }

        if (order.waseet_data) {
          try {
            const waseetData = JSON.parse(order.waseet_data);
            if (waseetData.error) {
              ordersWithWaseetErrors++;
            }
          } catch (e) {
            // بيانات وسيط غير صالحة
          }
        }
      });

      console.log('\n📊 إحصائيات الحالات:');
      Object.entries(statusCounts).forEach(([status, count]) => {
        console.log(`   - ${status}: ${count} طلب`);
      });

      console.log('\n📊 إحصائيات الوسيط:');
      Object.entries(waseetStatusCounts).forEach(([status, count]) => {
        console.log(`   - ${status}: ${count} طلب`);
      });

      // تحديد المشاكل
      if (ordersWithoutWaseetId > 0) {
        this.addIssue('high', 'database', 'طلبات لم ترسل للوسيط', `${ordersWithoutWaseetId} طلب في حالة توصيل لكن لم يرسل للوسيط`, 'إعادة إرسال الطلبات للوسيط');
      }

      if (ordersWithWaseetErrors > 0) {
        this.addIssue('medium', 'database', 'طلبات بأخطاء وسيط', `${ordersWithWaseetErrors} طلب به أخطاء من الوسيط`, 'مراجعة أخطاء الوسيط وإعادة المحاولة');
      }

      // فحص المنتجات
      const { data: products, error: productsError } = await this.supabase
        .from('products')
        .select('*')
        .limit(10);

      if (productsError) {
        this.addIssue('medium', 'database', 'مشكلة في جدول المنتجات', productsError.message);
      } else {
        console.log(`📦 عدد المنتجات: ${products.length}`);
      }

      return true;
    } catch (error) {
      this.addIssue('critical', 'database', 'خطأ في تحليل قاعدة البيانات', error.message);
      return false;
    }
  }

  // 3. تحليل شامل للكود والـ APIs
  async analyzeCode() {
    console.log('\n🔍 3️⃣ تحليل شامل للكود والـ APIs...');
    console.log('='.repeat(60));

    try {
      // اختبار APIs الأساسية
      const apis = [
        { name: 'جلب الطلبات', endpoint: '/api/orders?limit=1' },
        { name: 'جلب المنتجات', endpoint: '/api/products?limit=1' },
        { name: 'إحصائيات النظام', endpoint: '/api/stats' }
      ];

      for (const api of apis) {
        const result = await this.makeRequest('GET', `${this.baseUrl}${api.endpoint}`);
        
        if (!result.success) {
          this.addIssue('high', 'code', `API ${api.name} لا يعمل`, `فشل في ${api.endpoint}: ${result.error}`, 'فحص وإصلاح API');
        } else {
          console.log(`   ✅ ${api.name}: يعمل بشكل طبيعي`);
        }
      }

      // اختبار تحديث حالة طلب
      const ordersResult = await this.makeRequest('GET', `${this.baseUrl}/api/orders?limit=1`);
      if (ordersResult.success && ordersResult.data?.data?.length > 0) {
        const testOrder = ordersResult.data.data[0];
        
        const updateResult = await this.makeRequest('PUT', `${this.baseUrl}/api/orders/${testOrder.id}/status`, {
          status: 'active',
          notes: 'اختبار تحليل شامل',
          changedBy: 'system_analyzer'
        });

        if (!updateResult.success) {
          this.addIssue('high', 'code', 'API تحديث الحالة لا يعمل', `فشل في تحديث حالة الطلب: ${updateResult.error}`, 'فحص وإصلاح API تحديث الحالة');
        } else {
          console.log('   ✅ تحديث حالة الطلب: يعمل بشكل طبيعي');
        }
      }

      return true;
    } catch (error) {
      this.addIssue('critical', 'code', 'خطأ في تحليل الكود', error.message);
      return false;
    }
  }

  // 4. تحليل شامل لخدمة الوسيط
  async analyzeWaseetService() {
    console.log('\n🔍 4️⃣ تحليل شامل لخدمة الوسيط...');
    console.log('='.repeat(60));

    try {
      // فحص إعدادات الوسيط
      const waseetConfig = {
        username: process.env.WASEET_USERNAME,
        password: process.env.WASEET_PASSWORD,
        baseUrl: process.env.WASEET_BASE_URL
      };

      console.log('📋 إعدادات الوسيط:');
      console.log(`   - اسم المستخدم: ${waseetConfig.username ? 'موجود' : 'غير موجود'}`);
      console.log(`   - كلمة المرور: ${waseetConfig.password ? 'موجودة' : 'غير موجودة'}`);
      console.log(`   - رابط الخدمة: ${waseetConfig.baseUrl || 'غير محدد'}`);

      if (!waseetConfig.username || !waseetConfig.password) {
        this.addIssue('critical', 'waseet', 'بيانات مصادقة الوسيط ناقصة', 'اسم المستخدم أو كلمة المرور غير موجودة', 'إضافة بيانات المصادقة الصحيحة');
      }

      if (!waseetConfig.baseUrl) {
        this.addIssue('high', 'waseet', 'رابط خدمة الوسيط غير محدد', 'WASEET_BASE_URL غير موجود', 'إضافة رابط خدمة الوسيط');
      }

      // فحص الطلبات التي فشلت مع الوسيط
      if (this.supabase) {
        const { data: failedOrders, error } = await this.supabase
          .from('orders')
          .select('*')
          .or('waseet_status.eq.failed,waseet_status.eq.في انتظار الإرسال للوسيط')
          .limit(10);

        if (!error && failedOrders.length > 0) {
          console.log(`⚠️ طلبات فاشلة مع الوسيط: ${failedOrders.length}`);
          
          // تحليل أسباب الفشل
          const errorTypes = {};
          failedOrders.forEach(order => {
            if (order.waseet_data) {
              try {
                const waseetData = JSON.parse(order.waseet_data);
                if (waseetData.error) {
                  const errorType = this.categorizeWaseetError(waseetData.error);
                  errorTypes[errorType] = (errorTypes[errorType] || 0) + 1;
                }
              } catch (e) {
                errorTypes['بيانات غير صالحة'] = (errorTypes['بيانات غير صالحة'] || 0) + 1;
              }
            }
          });

          console.log('📊 أنواع أخطاء الوسيط:');
          Object.entries(errorTypes).forEach(([type, count]) => {
            console.log(`   - ${type}: ${count} طلب`);
          });

          // إضافة مشاكل حسب نوع الخطأ
          Object.entries(errorTypes).forEach(([type, count]) => {
            if (type.includes('مصادقة')) {
              this.addIssue('high', 'waseet', 'مشكلة في مصادقة الوسيط', `${count} طلب فشل بسبب مشكلة المصادقة`, 'التحقق من بيانات المصادقة مع شركة الوسيط');
            } else if (type.includes('شبكة')) {
              this.addIssue('medium', 'waseet', 'مشكلة في الاتصال بالوسيط', `${count} طلب فشل بسبب مشكلة الشبكة`, 'التحقق من الاتصال بخدمة الوسيط');
            } else {
              this.addIssue('medium', 'waseet', `مشكلة في الوسيط: ${type}`, `${count} طلب فشل`, 'مراجعة تفاصيل الخطأ مع شركة الوسيط');
            }
          });
        }
      }

      return true;
    } catch (error) {
      this.addIssue('critical', 'waseet', 'خطأ في تحليل خدمة الوسيط', error.message);
      return false;
    }
  }

  // تصنيف أخطاء الوسيط
  categorizeWaseetError(error) {
    const errorLower = error.toLowerCase();
    
    if (errorLower.includes('authentication') || errorLower.includes('unauthorized') || 
        errorLower.includes('مصادقة') || errorLower.includes('اسم المستخدم') || 
        errorLower.includes('رمز الدخول')) {
      return 'مشكلة مصادقة';
    } else if (errorLower.includes('timeout') || errorLower.includes('econnreset') || 
               errorLower.includes('network') || errorLower.includes('enotfound')) {
      return 'مشكلة شبكة';
    } else if (errorLower.includes('validation') || errorLower.includes('invalid')) {
      return 'بيانات غير صالحة';
    } else {
      return 'خطأ غير محدد';
    }
  }

  // دالة مساعدة لإرسال الطلبات
  async makeRequest(method, url, data = null) {
    return new Promise((resolve) => {
      const urlObj = new URL(url);
      
      const options = {
        hostname: urlObj.hostname,
        port: 443,
        path: urlObj.pathname + urlObj.search,
        method: method,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Comprehensive-System-Analyzer/1.0'
        },
        timeout: 30000
      };

      if (data && (method === 'POST' || method === 'PUT')) {
        const jsonData = JSON.stringify(data);
        options.headers['Content-Length'] = Buffer.byteLength(jsonData);
      }

      const req = https.request(options, (res) => {
        let responseData = '';

        res.on('data', (chunk) => {
          responseData += chunk;
        });

        res.on('end', () => {
          try {
            const parsedData = responseData ? JSON.parse(responseData) : {};
            
            if (res.statusCode >= 200 && res.statusCode < 300) {
              resolve({
                success: true,
                status: res.statusCode,
                data: parsedData
              });
            } else {
              resolve({
                success: false,
                status: res.statusCode,
                error: parsedData,
                rawResponse: responseData
              });
            }
          } catch (parseError) {
            resolve({
              success: false,
              status: res.statusCode,
              error: 'فشل في تحليل الاستجابة',
              rawResponse: responseData
            });
          }
        });
      });

      req.on('error', (error) => {
        resolve({
          success: false,
          error: error.message
        });
      });

      req.on('timeout', () => {
        req.destroy();
        resolve({
          success: false,
          error: 'انتهت مهلة الاتصال'
        });
      });

      if (data && (method === 'POST' || method === 'PUT')) {
        req.write(JSON.stringify(data));
      }

      req.end();
    });
  }

  // تشغيل التحليل الشامل
  async runComprehensiveAnalysis() {
    console.log('🔍 بدء التحليل الشامل لجميع جوانب النظام...');
    console.log('='.repeat(80));

    const results = {
      server: await this.analyzeServer(),
      database: await this.analyzeDatabase(),
      code: await this.analyzeCode(),
      waseet: await this.analyzeWaseetService()
    };

    return results;
  }

  // إنشاء تقرير شامل
  generateReport() {
    console.log('\n📋 تقرير التحليل الشامل');
    console.log('='.repeat(80));

    // إحصائيات المشاكل
    const severityCounts = {};
    const categoryCounts = {};

    this.issues.forEach(issue => {
      severityCounts[issue.severity] = (severityCounts[issue.severity] || 0) + 1;
      categoryCounts[issue.category] = (categoryCounts[issue.category] || 0) + 1;
    });

    console.log(`\n📊 إجمالي المشاكل المكتشفة: ${this.issues.length}`);
    
    if (this.issues.length > 0) {
      console.log('\n📈 توزيع المشاكل حسب الخطورة:');
      Object.entries(severityCounts).forEach(([severity, count]) => {
        const emoji = severity === 'critical' ? '🔴' : severity === 'high' ? '🟠' : severity === 'medium' ? '🟡' : '🟢';
        console.log(`   ${emoji} ${severity}: ${count} مشكلة`);
      });

      console.log('\n📈 توزيع المشاكل حسب الفئة:');
      Object.entries(categoryCounts).forEach(([category, count]) => {
        console.log(`   - ${category}: ${count} مشكلة`);
      });

      console.log('\n🔍 تفاصيل المشاكل:');
      this.issues.forEach((issue, index) => {
        const emoji = issue.severity === 'critical' ? '🔴' : issue.severity === 'high' ? '🟠' : issue.severity === 'medium' ? '🟡' : '🟢';
        console.log(`\n${index + 1}. ${emoji} [${issue.category.toUpperCase()}] ${issue.title}`);
        console.log(`   📋 الوصف: ${issue.description}`);
        if (issue.solution) {
          console.log(`   💡 الحل: ${issue.solution}`);
        }
      });
    } else {
      console.log('🎉 لم يتم اكتشاف أي مشاكل! النظام يعمل بشكل مثالي.');
    }

    return {
      totalIssues: this.issues.length,
      severityCounts,
      categoryCounts,
      issues: this.issues,
      recommendations: this.recommendations
    };
  }
}

// تشغيل التحليل الشامل
async function runComprehensiveSystemAnalysis() {
  const analyzer = new ComprehensiveSystemAnalyzer();
  
  try {
    await analyzer.runComprehensiveAnalysis();
    const report = analyzer.generateReport();
    
    console.log('\n🎯 انتهى التحليل الشامل');
    return report;
  } catch (error) {
    console.error('❌ خطأ في التحليل الشامل:', error);
    return null;
  }
}

// تشغيل التحليل إذا تم استدعاء الملف مباشرة
if (require.main === module) {
  runComprehensiveSystemAnalysis()
    .then((report) => {
      if (report) {
        console.log('\n✅ تم إنجاز التحليل الشامل بنجاح');
        process.exit(0);
      } else {
        console.log('\n❌ فشل التحليل الشامل');
        process.exit(1);
      }
    })
    .catch((error) => {
      console.error('\n❌ خطأ في تشغيل التحليل الشامل:', error);
      process.exit(1);
    });
}

module.exports = { ComprehensiveSystemAnalyzer, runComprehensiveSystemAnalysis };
