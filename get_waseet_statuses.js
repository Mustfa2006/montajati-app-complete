// ===================================
// جلب جميع حالات الطلبات من شركة الوسيط
// Get All Order Statuses from Waseet Company
// ===================================

const https = require('https');
const { createClient } = require('./backend/node_modules/@supabase/supabase-js');
require('./backend/node_modules/dotenv').config();

class WaseetStatusChecker {
  constructor() {
    this.baseURL = 'https://api.alwaseet-iq.net';
    this.username = process.env.WASEET_USERNAME;
    this.password = process.env.WASEET_PASSWORD;
    this.token = null;
    
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
  }

  // تسجيل الدخول للحصول على Token
  async login() {
    try {
      console.log('🔐 تسجيل الدخول إلى API الوسيط...');
      
      const loginData = JSON.stringify({
        username: this.username,
        password: this.password
      });

      const options = {
        hostname: 'api.alwaseet-iq.net',
        port: 443,
        path: '/login',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(loginData)
        }
      };

      const response = await this.makeRequest(options, loginData);
      
      if (response.success && response.token) {
        this.token = response.token;
        console.log('✅ تم تسجيل الدخول بنجاح');
        return true;
      } else {
        console.error('❌ فشل في تسجيل الدخول:', response.message || 'خطأ غير معروف');
        return false;
      }
    } catch (error) {
      console.error('❌ خطأ في تسجيل الدخول:', error.message);
      return false;
    }
  }

  // جلب جميع الطلبات لفهم الحالات المتاحة
  async getAllOrders() {
    try {
      console.log('📦 جلب جميع الطلبات من الوسيط...');
      
      if (!this.token) {
        console.error('❌ لا يوجد token، يجب تسجيل الدخول أولاً');
        return null;
      }

      const options = {
        hostname: 'api.alwaseet-iq.net',
        port: 443,
        path: '/orders',
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${this.token}`,
          'Content-Type': 'application/json'
        }
      };

      const response = await this.makeRequest(options);
      
      if (response.success && response.data) {
        console.log(`✅ تم جلب ${response.data.length} طلب من الوسيط`);
        return response.data;
      } else {
        console.error('❌ فشل في جلب الطلبات:', response.message || 'خطأ غير معروف');
        return null;
      }
    } catch (error) {
      console.error('❌ خطأ في جلب الطلبات:', error.message);
      return null;
    }
  }

  // تحليل الحالات من الطلبات
  analyzeStatuses(orders) {
    console.log('\n📊 تحليل حالات الطلبات...');
    
    const statusCounts = {};
    const statusExamples = {};
    
    orders.forEach(order => {
      const status = order.status || order.order_status || order.state;
      
      if (status) {
        // عد الحالات
        statusCounts[status] = (statusCounts[status] || 0) + 1;
        
        // حفظ أمثلة
        if (!statusExamples[status]) {
          statusExamples[status] = {
            orderId: order.id || order.order_id,
            customerName: order.customer_name || order.name,
            createdAt: order.created_at || order.date,
            example: order
          };
        }
      }
    });

    return { statusCounts, statusExamples };
  }

  // طباعة تقرير مفصل عن الحالات
  printStatusReport(statusCounts, statusExamples) {
    console.log('\n' + '='.repeat(80));
    console.log('📋 تقرير حالات الطلبات في شركة الوسيط');
    console.log('='.repeat(80));
    
    const sortedStatuses = Object.entries(statusCounts)
      .sort((a, b) => b[1] - a[1]);
    
    console.log(`\n📊 إجمالي الحالات المختلفة: ${sortedStatuses.length}`);
    console.log(`📦 إجمالي الطلبات: ${Object.values(statusCounts).reduce((a, b) => a + b, 0)}`);
    
    console.log('\n📋 قائمة الحالات (مرتبة حسب التكرار):');
    console.log('-'.repeat(80));
    
    sortedStatuses.forEach(([status, count], index) => {
      const example = statusExamples[status];
      console.log(`${index + 1}. 📌 الحالة: "${status}"`);
      console.log(`   📊 العدد: ${count} طلب`);
      console.log(`   🆔 مثال - رقم الطلب: ${example.orderId}`);
      console.log(`   👤 اسم العميل: ${example.customerName || 'غير محدد'}`);
      console.log(`   📅 تاريخ الإنشاء: ${example.createdAt || 'غير محدد'}`);
      console.log('-'.repeat(40));
    });
    
    console.log('\n🔍 الحالات الفريدة فقط:');
    sortedStatuses.forEach(([status], index) => {
      console.log(`${index + 1}. "${status}"`);
    });
  }

  // حفظ التقرير في قاعدة البيانات
  async saveStatusReport(statusCounts, statusExamples) {
    try {
      console.log('\n💾 حفظ تقرير الحالات في قاعدة البيانات...');
      
      const reportData = {
        total_statuses: Object.keys(statusCounts).length,
        total_orders: Object.values(statusCounts).reduce((a, b) => a + b, 0),
        status_breakdown: statusCounts,
        status_examples: statusExamples,
        generated_at: new Date().toISOString(),
        source: 'waseet_api'
      };

      const { error } = await this.supabase
        .from('waseet_status_reports')
        .insert(reportData);

      if (error) {
        console.error('❌ خطأ في حفظ التقرير:', error.message);
      } else {
        console.log('✅ تم حفظ التقرير في قاعدة البيانات');
      }
    } catch (error) {
      console.error('❌ خطأ في حفظ التقرير:', error.message);
    }
  }

  // دالة مساعدة لإرسال الطلبات
  makeRequest(options, data = null) {
    return new Promise((resolve, reject) => {
      const req = https.request(options, (res) => {
        let responseData = '';
        
        res.on('data', (chunk) => {
          responseData += chunk;
        });
        
        res.on('end', () => {
          try {
            const parsedData = JSON.parse(responseData);
            resolve(parsedData);
          } catch (parseError) {
            resolve({
              success: false,
              message: 'خطأ في تحليل الاستجابة',
              rawData: responseData
            });
          }
        });
      });

      req.on('error', (error) => {
        reject(error);
      });

      if (data) {
        req.write(data);
      }
      
      req.end();
    });
  }

  // تشغيل التحليل الكامل
  async runFullAnalysis() {
    try {
      console.log('🚀 بدء تحليل حالات الطلبات في شركة الوسيط...\n');
      
      // تسجيل الدخول
      const loginSuccess = await this.login();
      if (!loginSuccess) {
        console.error('❌ فشل في تسجيل الدخول، لا يمكن المتابعة');
        return;
      }

      // جلب الطلبات
      const orders = await this.getAllOrders();
      if (!orders || orders.length === 0) {
        console.error('❌ لا توجد طلبات للتحليل');
        return;
      }

      // تحليل الحالات
      const { statusCounts, statusExamples } = this.analyzeStatuses(orders);
      
      // طباعة التقرير
      this.printStatusReport(statusCounts, statusExamples);
      
      // حفظ التقرير
      await this.saveStatusReport(statusCounts, statusExamples);
      
      console.log('\n✅ تم إكمال التحليل بنجاح!');
      
    } catch (error) {
      console.error('❌ خطأ في التحليل:', error.message);
    }
  }
}

// تشغيل التحليل
const checker = new WaseetStatusChecker();
checker.runFullAnalysis();
