// ===================================
// جلب حالات الطلبات من شركة الوسيط - باستخدام النظام الموجود
// ===================================

const https = require('https');
require('dotenv').config();

async function getWaseetStatuses() {
  try {
    console.log('🔐 محاولة تسجيل الدخول إلى API الوسيط...');
    
    const baseURL = 'https://api.alwaseet-iq.net';
    const username = process.env.WASEET_USERNAME;
    const password = process.env.WASEET_PASSWORD;
    
    if (!username || !password) {
      console.error('❌ بيانات اعتماد الوسيط غير متوفرة في متغيرات البيئة');
      console.log('💡 تأكد من وجود WASEET_USERNAME و WASEET_PASSWORD في ملف .env');
      return;
    }

    console.log(`📡 محاولة الاتصال بـ: ${baseURL}`);
    console.log(`👤 اسم المستخدم: ${username}`);
    
    let token = null;
    
    // محاولة عدة مسارات API مختلفة
    const apiPaths = ['/login', '/auth/login', '/api/login', '/api/auth/login'];

    for (const path of apiPaths) {
      try {
        console.log(`🔄 محاولة المسار: ${path}`);

        const response = await makeHttpRequest('POST', baseURL, path, {
          username: username,
          password: password
        });

        console.log(`📊 استجابة ${path}:`, {
          status: response.statusCode,
          hasData: !!response.data,
          dataKeys: response.data ? Object.keys(response.data) : []
        });

        if (response.data && (response.data.token || response.data.access_token)) {
          token = response.data.token || response.data.access_token;
          console.log(`✅ تم الحصول على التوكن من ${path}`);
          break;
        }
      } catch (pathError) {
        console.log(`❌ فشل المسار ${path}:`, {
          message: pathError.message
        });
        continue;
      }
    }

    if (!token) {
      console.error('❌ فشل في الحصول على token من جميع المسارات');
      console.log('\n🔍 محاولة فحص الاتصال الأساسي...');
      
      // فحص الاتصال الأساسي
      try {
        const healthCheck = await makeHttpRequest('GET', baseURL, '/health');
        console.log('✅ الخادم متاح، المشكلة في المصادقة');
      } catch (healthError) {
        console.log('❌ الخادم غير متاح أو لا يوجد endpoint للفحص');
      }
      
      return;
    }

    // جلب الطلبات
    console.log('\n📦 محاولة جلب الطلبات...');
    
    const ordersPaths = ['/orders', '/api/orders', '/orders/list', '/api/orders/list'];
    let orders = null;
    
    for (const path of ordersPaths) {
      try {
        console.log(`🔄 محاولة جلب الطلبات من: ${path}`);

        const response = await makeHttpRequest('GET', baseURL, path, null, {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        });

        console.log(`📊 استجابة ${path}:`, {
          status: response.statusCode,
          hasData: !!response.data,
          dataType: Array.isArray(response.data) ? 'array' : typeof response.data,
          dataLength: Array.isArray(response.data) ? response.data.length : 'N/A'
        });

        if (response.data) {
          orders = Array.isArray(response.data) ? response.data : response.data.data || response.data.orders;
          if (orders && orders.length > 0) {
            console.log(`✅ تم جلب ${orders.length} طلب من ${path}`);
            break;
          }
        }
      } catch (pathError) {
        console.log(`❌ فشل جلب الطلبات من ${path}:`, {
          message: pathError.message
        });
        continue;
      }
    }

    if (!orders || orders.length === 0) {
      console.error('❌ لا توجد طلبات للتحليل');
      return;
    }

    // تحليل الحالات
    console.log('\n📊 تحليل حالات الطلبات...');
    
    const statuses = new Set();
    const statusExamples = {};
    const statusCounts = {};
    
    orders.forEach(order => {
      // البحث عن حقل الحالة في عدة أماكن محتملة
      const possibleStatusFields = ['status', 'order_status', 'state', 'order_state', 'delivery_status'];
      let status = null;
      
      for (const field of possibleStatusFields) {
        if (order[field]) {
          status = order[field];
          break;
        }
      }
      
      if (status) {
        statuses.add(status);
        statusCounts[status] = (statusCounts[status] || 0) + 1;
        
        if (!statusExamples[status]) {
          statusExamples[status] = {
            orderId: order.id || order.order_id || order.order_number,
            customerName: order.customer_name || order.name || order.client_name || 'غير محدد',
            createdAt: order.created_at || order.date || order.order_date
          };
        }
      }
    });

    // طباعة النتائج
    console.log('\n' + '='.repeat(70));
    console.log('📋 حالات الطلبات في شركة الوسيط');
    console.log('='.repeat(70));
    console.log(`📊 إجمالي الحالات المختلفة: ${statuses.size}`);
    console.log(`📦 إجمالي الطلبات: ${orders.length}`);
    
    if (statuses.size > 0) {
      console.log('\n🔍 قائمة الحالات مع الأمثلة:');
      console.log('-'.repeat(70));
      
      Array.from(statuses).sort().forEach((status, index) => {
        const example = statusExamples[status];
        const count = statusCounts[status];
        console.log(`${index + 1}. "${status}" (${count} طلب)`);
        console.log(`   📝 مثال: طلب ${example.orderId} - ${example.customerName}`);
        if (example.createdAt) {
          console.log(`   📅 تاريخ: ${example.createdAt}`);
        }
        console.log('-'.repeat(35));
      });
      
      console.log('\n📝 الحالات فقط (للنسخ):');
      Array.from(statuses).sort().forEach((status, index) => {
        console.log(`${index + 1}. ${status}`);
      });
    } else {
      console.log('⚠️ لم يتم العثور على حقول الحالة في الطلبات');
      console.log('🔍 عينة من بيانات الطلب الأول:');
      console.log(JSON.stringify(orders[0], null, 2));
    }
    
    console.log('\n✅ تم الانتهاء من جلب الحالات!');
    
  } catch (error) {
    console.error('❌ خطأ عام:', error.message);
    if (error.response) {
      console.error('📊 تفاصيل الخطأ:', {
        status: error.response.status,
        statusText: error.response.statusText,
        data: error.response.data
      });
    }
  }
}

// دالة مساعدة لإرسال طلبات HTTPS
function makeHttpRequest(method, baseURL, path, data = null, headers = {}) {
  return new Promise((resolve, reject) => {
    const url = new URL(baseURL + path);

    const options = {
      hostname: url.hostname,
      port: url.port || 443,
      path: url.pathname + url.search,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...headers
      }
    };

    if (data && method !== 'GET') {
      const postData = JSON.stringify(data);
      options.headers['Content-Length'] = Buffer.byteLength(postData);
    }

    const req = https.request(options, (res) => {
      let responseData = '';

      res.on('data', (chunk) => {
        responseData += chunk;
      });

      res.on('end', () => {
        try {
          const parsedData = responseData ? JSON.parse(responseData) : {};
          resolve({
            statusCode: res.statusCode,
            data: parsedData
          });
        } catch (parseError) {
          resolve({
            statusCode: res.statusCode,
            data: null,
            rawData: responseData
          });
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    if (data && method !== 'GET') {
      req.write(JSON.stringify(data));
    }

    req.end();
  });
}

// تشغيل السكريبت
getWaseetStatuses();
