// ===================================
// عميل ويب للوسيط - محاكاة المتصفح
// Waseet Web Client - Browser Simulation
// ===================================

const https = require('https');
const { URL } = require('url');
const zlib = require('zlib');

class WaseetWebClient {
  constructor(username, password) {
    this.username = username;
    this.password = password;
    this.baseURL = 'https://merchant.alwaseet-iq.net';
    this.cookies = new Map();
    this.isLoggedIn = false;
    this.sessionData = null;
  }

  // تسجيل الدخول عبر محاكاة المتصفح
  async login() {
    try {
      console.log('🔐 محاولة تسجيل الدخول للوسيط عبر الويب...');
      
      // 1. الحصول على صفحة تسجيل الدخول
      const loginPage = await this.getLoginPage();
      
      if (!loginPage) {
        throw new Error('فشل في الحصول على صفحة تسجيل الدخول');
      }
      
      // 2. استخراج CSRF token أو أي tokens مطلوبة
      const formData = this.extractFormData(loginPage);
      
      // 3. إرسال بيانات تسجيل الدخول
      const loginResult = await this.submitLogin(formData);
      
      if (loginResult.success) {
        this.isLoggedIn = true;
        console.log('✅ تم تسجيل الدخول بنجاح');
        return true;
      } else {
        console.log('❌ فشل في تسجيل الدخول:', loginResult.error);
        return false;
      }
      
    } catch (error) {
      console.error('❌ خطأ في تسجيل الدخول:', error.message);
      return false;
    }
  }

  // الحصول على صفحة تسجيل الدخول
  async getLoginPage() {
    try {
      const response = await this.makeRequest('GET', '/merchant/login');
      
      if (response.statusCode === 200) {
        // حفظ cookies
        this.saveCookies(response.headers);
        return response.body;
      }
      
      return null;
    } catch (error) {
      console.error('خطأ في جلب صفحة تسجيل الدخول:', error.message);
      return null;
    }
  }

  // استخراج بيانات النموذج
  extractFormData(html) {
    const formData = {
      username: this.username,
      password: this.password
    };

    // البحث عن CSRF token
    const csrfMatch = html.match(/name=["\']_token["\'][^>]*value=["\']([^"\']+)["\']/) ||
                     html.match(/name=["\']csrf_token["\'][^>]*value=["\']([^"\']+)["\']/) ||
                     html.match(/content=["\']([^"\']+)["\'][^>]*name=["\']csrf-token["\']/) ||
                     html.match(/<meta[^>]*name=["\']_token["\'][^>]*content=["\']([^"\']+)["\']/) ||
                     html.match(/window\.Laravel\s*=\s*{[^}]*csrfToken["\']:\s*["\']([^"\']+)["\']/) ||
                     html.match(/_token["\']:\s*["\']([^"\']+)["\']/) ||
                     html.match(/csrf_token["\']:\s*["\']([^"\']+)["\']/);

    if (csrfMatch) {
      formData._token = csrfMatch[1];
      console.log('🔑 تم العثور على CSRF token');
    }

    // البحث عن حقول أخرى مطلوبة
    const emailMatch = html.match(/name=["\']email["\']/) || html.match(/type=["\']email["\']/);
    if (emailMatch) {
      formData.email = this.username;
      delete formData.username;
      console.log('📧 استخدام email بدلاً من username');
    }

    return formData;
  }

  // إرسال بيانات تسجيل الدخول
  async submitLogin(formData) {
    try {
      const postData = new URLSearchParams(formData).toString();
      
      const response = await this.makeRequest('POST', '/merchant/login', postData, {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Referer': `${this.baseURL}/merchant/login`
      });

      // فحص نتيجة تسجيل الدخول
      if (response.statusCode === 302 || response.statusCode === 303 || response.statusCode === 301) {
        // إعادة توجيه - عادة تعني نجاح تسجيل الدخول
        const location = response.headers.location;
        console.log(`🔄 إعادة توجيه (${response.statusCode}) إلى: ${location}`);

        // حفظ cookies الجديدة
        this.saveCookies(response.headers);

        if (location) {
          // متابعة إعادة التوجيه للتأكد
          const redirectResult = await this.followRedirect(location);
          if (redirectResult.success) {
            return { success: true };
          }
        }

        // حتى لو لم نتمكن من متابعة إعادة التوجيه، إذا لم يكن للـ login فهو نجاح
        if (location && !location.includes('login')) {
          return { success: true };
        }
      }
      
      if (response.statusCode === 200) {
        // فحص إذا كانت الصفحة تحتوي على رسالة خطأ
        if (response.body.includes('error') || response.body.includes('invalid') || 
            response.body.includes('incorrect') || response.body.includes('wrong')) {
          return { success: false, error: 'بيانات تسجيل الدخول غير صحيحة' };
        }
        
        // إذا لم تكن صفحة تسجيل دخول، فقد نجح
        if (!response.body.includes('login') || response.body.includes('dashboard')) {
          this.saveCookies(response.headers);
          return { success: true };
        }
      }

      return { success: false, error: `كود الاستجابة: ${response.statusCode}` };
      
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  // متابعة إعادة التوجيه
  async followRedirect(location) {
    try {
      console.log(`🔄 متابعة إعادة التوجيه إلى: ${location}`);

      // إذا كان الرابط نسبي، أضف الـ base URL
      let fullURL = location;
      if (location.startsWith('/')) {
        fullURL = this.baseURL + location;
      }

      const url = new URL(fullURL);
      const path = url.pathname + url.search;

      const response = await this.makeRequest('GET', path);

      if (response.statusCode === 200) {
        // فحص إذا كانت صفحة dashboard أو ليست صفحة login
        if (!response.body.includes('login') ||
            response.body.includes('dashboard') ||
            response.body.includes('orders') ||
            response.body.includes('merchant')) {
          console.log('✅ تم الوصول لصفحة بعد تسجيل الدخول');
          return { success: true };
        }
      }

      return { success: false, error: `كود الاستجابة: ${response.statusCode}` };

    } catch (error) {
      console.log(`⚠️ خطأ في متابعة إعادة التوجيه: ${error.message}`);
      return { success: false, error: error.message };
    }
  }

  // جلب جميع حالات الطلبات من جميع الصفحات
  async getAllOrderStatuses() {
    if (!this.isLoggedIn) {
      throw new Error('يجب تسجيل الدخول أولاً');
    }

    console.log('🔍 بدء جلب جميع حالات الطلبات من الوسيط...\n');

    const allStatuses = new Set();
    const allOrders = [];
    const pageResults = [];

    try {
      const ordersPaths = [
        '/merchant',
        '/merchant/orders',
        '/merchant/dashboard',
        '/orders',
        '/dashboard/orders',
        '/orders/list',
        '/deliveries',
        '/merchant/deliveries',
        '/shipments',
        '/merchant/shipments',
        '/merchant/reports',
        '/reports',
        '/merchant/history',
        '/history'
      ];

      for (const path of ordersPaths) {
        try {
          console.log(`🔄 فحص صفحة: ${path}`);
          const response = await this.makeRequest('GET', path);

          if (response.statusCode === 200 && !response.body.includes('login')) {
            console.log(`✅ تم الوصول لصفحة ${path}`);
            console.log(`📄 حجم الصفحة: ${response.body.length} حرف`);

            // تحليل الصفحة دائماً للبحث عن حالات
            const pageData = this.parseOrdersFromHTML(response.body, path);
            pageResults.push(pageData);

            // إضافة الحالات المكتشفة
            if (pageData.allStatuses && pageData.allStatuses.length > 0) {
              pageData.allStatuses.forEach(status => allStatuses.add(status));
              console.log(`🎯 تم العثور على ${pageData.allStatuses.length} حالة في ${path}`);
            }

            // إضافة الطلبات
            if (pageData.orders && pageData.orders.length > 0) {
              allOrders.push(...pageData.orders);
              console.log(`📦 تم العثور على ${pageData.orders.length} طلب في ${path}`);
            }

          } else {
            console.log(`⚠️ لا يمكن الوصول لـ ${path} (${response.statusCode})`);
          }
        } catch (error) {
          console.log(`❌ خطأ في ${path}: ${error.message}`);
          continue;
        }

        // انتظار قصير بين الطلبات
        await new Promise(resolve => setTimeout(resolve, 1000));
      }

      // محاولة البحث عن صفحات إضافية من خلال الروابط
      await this.discoverAdditionalPages(pageResults, allStatuses, allOrders);

      return this.generateStatusReport(allStatuses, allOrders, pageResults);
      
    } catch (error) {
      console.error('خطأ في جلب الطلبات:', error.message);
      return null;
    }
  }

  // اكتشاف صفحات إضافية من خلال الروابط
  async discoverAdditionalPages(pageResults, allStatuses, allOrders) {
    console.log('\n🔍 البحث عن صفحات إضافية...');

    const discoveredLinks = new Set();

    // البحث عن روابط في الصفحات المحملة
    pageResults.forEach(pageData => {
      if (pageData.source === '/merchant') {
        // البحث عن روابط في الصفحة الرئيسية
        const pageContent = pageData.pageContent || '';

        // أنماط الروابط المحتملة
        const linkPatterns = [
          /href=['"]([^'"]*order[^'"]*)['"]/gi,
          /href=['"]([^'"]*delivery[^'"]*)['"]/gi,
          /href=['"]([^'"]*report[^'"]*)['"]/gi,
          /href=['"]([^'"]*history[^'"]*)['"]/gi,
          /href=['"]([^'"]*merchant[^'"]*)['"]/gi
        ];

        linkPatterns.forEach(pattern => {
          const matches = pageContent.match(pattern);
          if (matches) {
            matches.forEach(match => {
              const linkMatch = match.match(/href=['"]([^'"]+)['"]/);
              if (linkMatch) {
                const link = linkMatch[1];
                if (link.startsWith('/') && !link.includes('logout') && !link.includes('login')) {
                  discoveredLinks.add(link);
                }
              }
            });
          }
        });
      }
    });

    console.log(`🔗 تم اكتشاف ${discoveredLinks.size} رابط إضافي`);

    // فحص الروابط المكتشفة
    for (const link of Array.from(discoveredLinks).slice(0, 5)) { // حد أقصى 5 روابط إضافية
      try {
        console.log(`🔄 فحص رابط مكتشف: ${link}`);
        const response = await this.makeRequest('GET', link);

        if (response.statusCode === 200 && !response.body.includes('login')) {
          const pageData = this.parseOrdersFromHTML(response.body, link);

          if (pageData.allStatuses && pageData.allStatuses.length > 0) {
            pageData.allStatuses.forEach(status => allStatuses.add(status));
            console.log(`🎯 حالات إضافية من ${link}: ${pageData.allStatuses.length}`);
          }

          if (pageData.orders && pageData.orders.length > 0) {
            allOrders.push(...pageData.orders);
            console.log(`📦 طلبات إضافية من ${link}: ${pageData.orders.length}`);
          }
        }
      } catch (error) {
        console.log(`⚠️ خطأ في فحص ${link}: ${error.message}`);
      }

      // انتظار بين الطلبات
      await new Promise(resolve => setTimeout(resolve, 1500));
    }
  }

  // إنشاء تقرير شامل عن الحالات
  generateStatusReport(allStatuses, allOrders, pageResults) {
    console.log('\n' + '='.repeat(80));
    console.log('📋 تقرير شامل عن حالات الطلبات في شركة الوسيط');
    console.log('='.repeat(80));

    const statusArray = Array.from(allStatuses).sort();

    console.log(`\n📊 إحصائيات عامة:`);
    console.log(`   🔍 عدد الصفحات المفحوصة: ${pageResults.length}`);
    console.log(`   📦 إجمالي الطلبات المكتشفة: ${allOrders.length}`);
    console.log(`   📊 إجمالي الحالات الفريدة: ${statusArray.length}`);

    if (statusArray.length > 0) {
      console.log(`\n🎯 قائمة جميع الحالات المكتشفة:`);
      console.log('-'.repeat(50));

      statusArray.forEach((status, index) => {
        // حساب عدد مرات ظهور كل حالة
        const count = allOrders.filter(order =>
          order.status && order.status.toLowerCase() === status.toLowerCase()
        ).length;

        console.log(`${index + 1}. "${status}" ${count > 0 ? `(${count} طلب)` : ''}`);
      });

      console.log('\n📝 الحالات للنسخ (مفصولة بفواصل):');
      console.log(statusArray.join(', '));

      console.log('\n📝 الحالات للنسخ (قائمة):');
      statusArray.forEach((status, index) => {
        console.log(`${index + 1}. ${status}`);
      });
    }

    // تفاصيل كل صفحة
    console.log(`\n📄 تفاصيل الصفحات المفحوصة:`);
    console.log('-'.repeat(50));

    pageResults.forEach((pageData, index) => {
      console.log(`${index + 1}. ${pageData.source}`);
      console.log(`   📄 حجم: ${pageData.pageSize} حرف`);
      console.log(`   📊 حالات: ${pageData.allStatuses ? pageData.allStatuses.length : 0}`);
      console.log(`   📦 طلبات: ${pageData.orders ? pageData.orders.length : 0}`);

      if (pageData.allStatuses && pageData.allStatuses.length > 0) {
        console.log(`   🎯 الحالات: ${pageData.allStatuses.join(', ')}`);
      }
    });

    console.log('\n✅ تم إكمال تحليل جميع حالات الوسيط!');
    console.log('='.repeat(80));

    return {
      totalPages: pageResults.length,
      totalOrders: allOrders.length,
      totalStatuses: statusArray.length,
      allStatuses: statusArray,
      orders: allOrders,
      pageDetails: pageResults,
      summary: {
        uniqueStatuses: statusArray,
        statusCount: statusArray.length,
        orderCount: allOrders.length,
        pageCount: pageResults.length
      }
    };
  }

  // دالة مساعدة للحفاظ على التوافق مع الكود القديم
  async getOrders() {
    const result = await this.getAllOrderStatuses();
    return result ? result.orders : [];
  }

  // تحليل الطلبات من HTML واستخراج الحالات
  parseOrdersFromHTML(html, sourcePath = '') {
    console.log(`📊 تحليل HTML للطلبات من ${sourcePath}...`);
    console.log(`📄 حجم الصفحة: ${html.length} حرف`);

    const orders = [];
    const allStatuses = new Set();

    // 1. البحث عن جداول الطلبات
    const tableMatches = html.match(/<table[^>]*id="[^"]*orders?[^"]*"[^>]*>(.*?)<\/table>/gis);

    if (tableMatches) {
      console.log(`🔍 تم العثور على ${tableMatches.length} جدول طلبات`);

      tableMatches.forEach((table, index) => {
        console.log(`\n📋 تحليل الجدول ${index + 1}:`);

        // استخراج صفوف الجدول
        const rows = table.match(/<tr[^>]*>(.*?)<\/tr>/gis) || [];
        console.log(`   📊 عدد الصفوف: ${rows.length}`);

        rows.forEach((row, rowIndex) => {
          // تخطي صف العناوين
          if (rowIndex === 0) return;

          // استخراج الخلايا
          const cells = row.match(/<td[^>]*>(.*?)<\/td>/gis) || [];

          if (cells.length > 0) {
            const orderData = this.extractOrderDataFromRow(cells, rowIndex);
            if (orderData) {
              orders.push(orderData);
              if (orderData.status) {
                allStatuses.add(orderData.status);
              }
            }
          }
        });
      });
    }

    // 2. البحث عن JavaScript data
    const jsDataPatterns = [
      /var\s+orders\s*=\s*(\[.*?\]);/gis,
      /window\.orders\s*=\s*(\[.*?\]);/gis,
      /"orders"\s*:\s*(\[.*?\])/gis,
      /orders:\s*(\[.*?\])/gis,
      /data-orders=['"]([^'"]+)['"]/gis
    ];

    for (const pattern of jsDataPatterns) {
      const matches = html.match(pattern);
      if (matches) {
        console.log(`🔍 تم العثور على بيانات JavaScript للطلبات`);

        matches.forEach(match => {
          try {
            const jsonMatch = match.match(/(\[.*?\])/);
            if (jsonMatch) {
              const data = JSON.parse(jsonMatch[1]);
              console.log(`📊 تم تحليل ${data.length} طلب من JavaScript`);

              data.forEach(order => {
                if (order.status) allStatuses.add(order.status);
                orders.push(order);
              });
            }
          } catch (e) {
            console.log(`⚠️ خطأ في تحليل JSON: ${e.message}`);
          }
        });
      }
    }

    // 3. البحث عن حالات في النص (موسع)
    const statusPatterns = [
      // حالات إنجليزية أساسية
      /\b(pending|delivered|cancelled|processing|shipped|confirmed|rejected|returned|completed|failed|active|inactive|new|old|printed|not_printed)\b/gi,
      // حالات إنجليزية إضافية
      /\b(ready|waiting|prepared|dispatched|transit|arrived|received|accepted|declined|expired|suspended|archived)\b/gi,
      // حالات خاصة بالتوصيل
      /\b(pickup|delivery|out_for_delivery|in_delivery|on_way|collected|distributed|assigned|unassigned)\b/gi,
      // حالات عربية
      /\b(في انتظار|تم التوصيل|ملغي|قيد المعالجة|تم الشحن|مؤكد|مرفوض|مرتجع|مكتمل|فاشل|نشط|غير نشط|جديد|قديم|مطبوع|غير مطبوع)\b/gi,
      // حالات عربية إضافية
      /\b(جاهز|منتظر|محضر|مرسل|في الطريق|وصل|مستلم|مقبول|مرفوض|منتهي|معلق|مؤرشف)\b/gi,
      // أنماط في الكود
      /status['":\s]*['"]([^'"]+)['"]/gi,
      /state['":\s]*['"]([^'"]+)['"]/gi,
      /condition['":\s]*['"]([^'"]+)['"]/gi,
      /حالة['":\s]*['"]([^'"]+)['"]/gi,
      // أنماط في CSS classes
      /class=['"][^'"]*status-([^'"\\s]+)[^'"]*['"]/gi,
      /class=['"][^'"]*state-([^'"\\s]+)[^'"]*['"]/gi,
      // أنماط في data attributes
      /data-status=['"]([^'"]+)['"]/gi,
      /data-state=['"]([^'"]+)['"]/gi
    ];

    statusPatterns.forEach(pattern => {
      const matches = html.match(pattern);
      if (matches) {
        matches.forEach(match => {
          const cleanStatus = match.replace(/['":\s]/g, '').toLowerCase();
          if (cleanStatus.length > 2) {
            allStatuses.add(cleanStatus);
          }
        });
      }
    });

    // 4. البحث عن أرقام الطلبات
    const orderNumbers = html.match(/\b\d{6,}\b/g) || [];

    // 5. البحث عن أسماء العملاء
    const customerNames = html.match(/[أ-ي\s]{3,20}/g) || [];

    // 6. فحص إضافي للمحتوى الخام
    this.analyzeRawContent(html, allStatuses);

    console.log(`\n📊 نتائج التحليل:`);
    console.log(`   📦 عدد الطلبات المستخرجة: ${orders.length}`);
    console.log(`   📊 عدد الحالات الفريدة: ${allStatuses.size}`);
    console.log(`   🔢 أرقام الطلبات المحتملة: ${orderNumbers.length}`);
    console.log(`   👥 أسماء العملاء المحتملة: ${customerNames.length}`);

    if (allStatuses.size > 0) {
      console.log(`\n🎯 الحالات المكتشفة:`);
      Array.from(allStatuses).forEach((status, index) => {
        console.log(`   ${index + 1}. "${status}"`);
      });
    }

    return {
      source: sourcePath,
      pageSize: html.length,
      orders: orders,
      allStatuses: Array.from(allStatuses),
      orderNumbers: orderNumbers.slice(0, 20),
      customerNames: customerNames.slice(0, 10),
      hasOrderData: orders.length > 0 || allStatuses.size > 0
    };
  }

  // استخراج بيانات الطلب من صف الجدول
  extractOrderDataFromRow(cells, rowIndex) {
    try {
      const orderData = {
        rowIndex: rowIndex,
        rawCells: cells.map(cell => cell.replace(/<[^>]*>/g, '').trim())
      };

      // محاولة تحديد الحقول بناءً على المحتوى
      cells.forEach((cell, cellIndex) => {
        const cleanText = cell.replace(/<[^>]*>/g, '').trim();

        // رقم الطلب (أرقام طويلة)
        if (/^\d{6,}$/.test(cleanText)) {
          orderData.orderId = cleanText;
        }

        // الحالة (كلمات معروفة)
        if (/^(pending|delivered|cancelled|processing|shipped|confirmed|rejected|returned|completed|failed|active|inactive|new|old|printed|not_printed)$/i.test(cleanText)) {
          orderData.status = cleanText.toLowerCase();
        }

        // اسم العميل (نص عربي)
        if (/^[أ-ي\s]{3,30}$/.test(cleanText)) {
          orderData.customerName = cleanText;
        }

        // المبلغ (أرقام مع عملة)
        if (/^\d+[\s]*(دينار|iqd|$)/.test(cleanText)) {
          orderData.amount = cleanText;
        }

        // التاريخ
        if (/\d{4}-\d{2}-\d{2}|\d{2}\/\d{2}\/\d{4}/.test(cleanText)) {
          orderData.date = cleanText;
        }
      });

      // إرجاع البيانات فقط إذا وجدنا معلومات مفيدة
      if (orderData.orderId || orderData.status || orderData.customerName) {
        return orderData;
      }

      return null;
    } catch (error) {
      console.log(`⚠️ خطأ في استخراج بيانات الصف ${rowIndex}: ${error.message}`);
      return null;
    }
  }

  // حفظ cookies
  saveCookies(headers) {
    const setCookieHeaders = headers['set-cookie'];
    if (setCookieHeaders) {
      setCookieHeaders.forEach(cookie => {
        const [nameValue] = cookie.split(';');
        const [name, value] = nameValue.split('=');
        if (name && value) {
          this.cookies.set(name.trim(), value.trim());
        }
      });
      console.log(`🍪 تم حفظ ${this.cookies.size} cookies`);
    }
  }

  // إنشاء string للـ cookies
  getCookieString() {
    return Array.from(this.cookies.entries())
      .map(([name, value]) => `${name}=${value}`)
      .join('; ');
  }

  // دالة مساعدة لإرسال الطلبات
  makeRequest(method, path, data = null, extraHeaders = {}) {
    return new Promise((resolve, reject) => {
      const url = new URL(this.baseURL + path);
      
      const options = {
        hostname: url.hostname,
        port: url.port || 443,
        path: url.pathname + url.search,
        method: method,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'ar-IQ,ar;q=0.9,en;q=0.8',
          'Accept-Encoding': 'gzip, deflate, br',
          'Connection': 'keep-alive',
          'Upgrade-Insecure-Requests': '1',
          ...extraHeaders
        },
        timeout: 30000
      };

      // إضافة cookies
      const cookieString = this.getCookieString();
      if (cookieString) {
        options.headers['Cookie'] = cookieString;
      }

      // إضافة Content-Length للـ POST requests
      if (data && method !== 'GET') {
        options.headers['Content-Length'] = Buffer.byteLength(data);
      }

      const req = https.request(options, (res) => {
        let responseData = Buffer.alloc(0);

        res.on('data', (chunk) => {
          responseData = Buffer.concat([responseData, chunk]);
        });

        res.on('end', () => {
          // فك الضغط إذا كان مضغوط
          let finalData = responseData;
          const encoding = res.headers['content-encoding'];

          try {
            if (encoding === 'gzip') {
              finalData = zlib.gunzipSync(responseData);
            } else if (encoding === 'deflate') {
              finalData = zlib.inflateSync(responseData);
            } else if (encoding === 'br') {
              finalData = zlib.brotliDecompressSync(responseData);
            }

            resolve({
              statusCode: res.statusCode,
              headers: res.headers,
              body: finalData.toString('utf8')
            });
          } catch (decompressError) {
            console.warn('⚠️ خطأ في فك الضغط، استخدام البيانات الخام');
            resolve({
              statusCode: res.statusCode,
              headers: res.headers,
              body: responseData.toString('utf8')
            });
          }
        });
      });

      req.on('error', (error) => {
        reject(error);
      });

      req.on('timeout', () => {
        req.destroy();
        reject(new Error('Request timeout'));
      });

      if (data && method !== 'GET') {
        req.write(data);
      }
      
      req.end();
    });
  }

  // تحليل المحتوى الخام للبحث عن حالات مخفية
  analyzeRawContent(html, allStatuses) {
    console.log('\n🔍 فحص إضافي للمحتوى الخام...');

    // 1. البحث عن scripts مع بيانات
    const scriptMatches = html.match(/<script[^>]*>([\s\S]*?)<\/script>/gi) || [];
    console.log(`📜 تم العثور على ${scriptMatches.length} script tags`);

    scriptMatches.forEach((script, index) => {
      // البحث عن متغيرات تحتوي على حالات
      const statusVars = script.match(/(status|state|condition|order|delivery)\s*[:=]\s*['"][^'"]+['"]/gi) || [];
      if (statusVars.length > 0) {
        console.log(`📜 Script ${index + 1} يحتوي على متغيرات حالات:`);
        statusVars.forEach(varMatch => {
          const value = varMatch.match(/['"]([^'"]+)['"]/);
          if (value && value[1]) {
            allStatuses.add(value[1]);
            console.log(`   🎯 حالة من script: "${value[1]}"`);
          }
        });
      }
    });

    // 2. البحث عن form options
    const selectMatches = html.match(/<select[^>]*>[\s\S]*?<\/select>/gi) || [];
    selectMatches.forEach(select => {
      const options = select.match(/<option[^>]*value=['"]([^'"]+)['"][^>]*>([^<]+)</gi) || [];
      options.forEach(option => {
        const valueMatch = option.match(/value=['"]([^'"]+)['"]/);
        const textMatch = option.match(/>([^<]+)</);

        if (valueMatch && valueMatch[1] && valueMatch[1] !== '') {
          allStatuses.add(valueMatch[1]);
          console.log(`📋 حالة من select option: "${valueMatch[1]}"`);
        }

        if (textMatch && textMatch[1] && textMatch[1].trim() !== '') {
          const cleanText = textMatch[1].trim();
          if (cleanText.length > 2 && cleanText.length < 50) {
            allStatuses.add(cleanText);
            console.log(`📋 نص option: "${cleanText}"`);
          }
        }
      });
    });

    console.log(`✅ انتهى الفحص الإضافي`);
  }
}

module.exports = WaseetWebClient;
