// ===================================
// تشخيص شامل لـ API الوسيط
// Comprehensive Waseet API Diagnosis
// ===================================

const https = require('https');
const http = require('http');
require('dotenv').config();

class WaseetAPIDiagnostic {
  constructor() {
    this.baseURL = 'https://api.alwaseet-iq.net';
    this.altURLs = [
      'https://api.alwaseet-iq.net',
      'https://alwaseet-iq.net/api',
      'https://www.alwaseet-iq.net/api',
      'https://api.waseet.iq',
      'https://waseet.iq/api'
    ];
    this.username = process.env.WASEET_USERNAME;
    this.password = process.env.WASEET_PASSWORD;
  }

  // فحص شامل لـ API الوسيط
  async runFullDiagnosis() {
    console.log('🔍 بدء التشخيص الشامل لـ API الوسيط...\n');
    
    console.log(`👤 اسم المستخدم: ${this.username}`);
    console.log(`🔑 كلمة المرور: ${this.password ? '***' + this.password.slice(-3) : 'غير موجودة'}\n`);

    // 1. فحص الاتصال الأساسي
    await this.checkBasicConnectivity();
    
    // 2. فحص endpoints مختلفة
    await this.discoverEndpoints();
    
    // 3. فحص طرق مصادقة مختلفة
    await this.testAuthenticationMethods();
    
    // 4. فحص headers مختلفة
    await this.testDifferentHeaders();
    
    console.log('\n✅ تم إكمال التشخيص الشامل!');
  }

  // فحص الاتصال الأساسي
  async checkBasicConnectivity() {
    console.log('🌐 فحص الاتصال الأساسي...');
    console.log('-'.repeat(50));
    
    for (const url of this.altURLs) {
      try {
        console.log(`🔄 فحص: ${url}`);
        
        const response = await this.makeRequest('GET', url, '/', null, {});
        
        console.log(`✅ ${url} - متاح (${response.statusCode})`);
        
        if (response.data) {
          console.log(`📄 محتوى الاستجابة:`, JSON.stringify(response.data, null, 2).substring(0, 200) + '...');
        }
        
      } catch (error) {
        console.log(`❌ ${url} - غير متاح: ${error.message}`);
      }
    }
    console.log();
  }

  // اكتشاف endpoints
  async discoverEndpoints() {
    console.log('🔍 اكتشاف endpoints...');
    console.log('-'.repeat(50));
    
    const commonPaths = [
      '/',
      '/api',
      '/login',
      '/auth',
      '/auth/login',
      '/api/login',
      '/api/auth',
      '/api/auth/login',
      '/api/v1/login',
      '/api/v1/auth/login',
      '/v1/login',
      '/v1/auth/login',
      '/user/login',
      '/api/user/login',
      '/merchant/login',
      '/api/merchant/login',
      '/signin',
      '/api/signin',
      '/authenticate',
      '/api/authenticate',
      '/token',
      '/api/token',
      '/oauth/token',
      '/api/oauth/token'
    ];

    for (const path of commonPaths) {
      try {
        const response = await this.makeRequest('GET', this.baseURL, path, null, {});
        
        if (response.statusCode !== 404) {
          console.log(`✅ ${path} - متاح (${response.statusCode})`);
          if (response.data) {
            console.log(`   📄 محتوى:`, JSON.stringify(response.data, null, 2).substring(0, 100) + '...');
          }
        }
      } catch (error) {
        // تجاهل الأخطاء للمسارات غير الموجودة
      }
    }
    console.log();
  }

  // اختبار طرق مصادقة مختلفة
  async testAuthenticationMethods() {
    console.log('🔐 اختبار طرق المصادقة...');
    console.log('-'.repeat(50));
    
    const authPaths = ['/login', '/auth/login', '/api/login', '/api/auth/login'];
    const authMethods = [
      {
        name: 'JSON Body',
        data: { username: this.username, password: this.password },
        headers: { 'Content-Type': 'application/json' }
      },
      {
        name: 'Form Data',
        data: `username=${encodeURIComponent(this.username)}&password=${encodeURIComponent(this.password)}`,
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
      },
      {
        name: 'Basic Auth',
        data: null,
        headers: { 
          'Authorization': `Basic ${Buffer.from(`${this.username}:${this.password}`).toString('base64')}`,
          'Content-Type': 'application/json'
        }
      },
      {
        name: 'Custom Headers',
        data: { username: this.username, password: this.password },
        headers: { 
          'Content-Type': 'application/json',
          'X-API-Key': this.password,
          'X-Username': this.username
        }
      }
    ];

    for (const path of authPaths) {
      console.log(`🔄 اختبار مسار: ${path}`);
      
      for (const method of authMethods) {
        try {
          const response = await this.makeRequest('POST', this.baseURL, path, method.data, method.headers);
          
          console.log(`   ${method.name}: ${response.statusCode}`);
          
          if (response.statusCode !== 404 && response.data) {
            console.log(`   📄 استجابة:`, JSON.stringify(response.data, null, 2).substring(0, 150) + '...');
            
            // فحص إذا كان هناك token في الاستجابة
            if (response.data.token || response.data.access_token || response.data.auth_token) {
              console.log(`   🎉 تم العثور على token!`);
            }
          }
        } catch (error) {
          console.log(`   ${method.name}: خطأ - ${error.message}`);
        }
      }
      console.log();
    }
  }

  // اختبار headers مختلفة
  async testDifferentHeaders() {
    console.log('📋 اختبار headers مختلفة...');
    console.log('-'.repeat(50));
    
    const headerSets = [
      {
        name: 'Standard',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        }
      },
      {
        name: 'With User-Agent',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'Montajati-App/1.0'
        }
      },
      {
        name: 'With Origin',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Origin': 'https://montajati-backend.onrender.com'
        }
      },
      {
        name: 'Arabic Accept-Language',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Accept-Language': 'ar-IQ,ar;q=0.9,en;q=0.8'
        }
      }
    ];

    for (const headerSet of headerSets) {
      try {
        console.log(`🔄 اختبار ${headerSet.name} headers...`);
        
        const response = await this.makeRequest('POST', this.baseURL, '/login', 
          { username: this.username, password: this.password }, 
          headerSet.headers
        );
        
        console.log(`   النتيجة: ${response.statusCode}`);
        
        if (response.data) {
          console.log(`   📄 محتوى:`, JSON.stringify(response.data, null, 2).substring(0, 100) + '...');
        }
        
      } catch (error) {
        console.log(`   خطأ: ${error.message}`);
      }
    }
    console.log();
  }

  // دالة مساعدة لإرسال الطلبات
  makeRequest(method, baseURL, path, data = null, headers = {}) {
    return new Promise((resolve, reject) => {
      const url = new URL(baseURL + path);
      const isHttps = url.protocol === 'https:';
      const client = isHttps ? https : http;
      
      const options = {
        hostname: url.hostname,
        port: url.port || (isHttps ? 443 : 80),
        path: url.pathname + url.search,
        method: method,
        headers: {
          'Accept': 'application/json',
          ...headers
        },
        timeout: 10000
      };

      let postData = null;
      if (data && method !== 'GET') {
        if (typeof data === 'string') {
          postData = data;
        } else {
          postData = JSON.stringify(data);
        }
        options.headers['Content-Length'] = Buffer.byteLength(postData);
      }

      const req = client.request(options, (res) => {
        let responseData = '';
        
        res.on('data', (chunk) => {
          responseData += chunk;
        });
        
        res.on('end', () => {
          try {
            const parsedData = responseData ? JSON.parse(responseData) : null;
            resolve({
              statusCode: res.statusCode,
              headers: res.headers,
              data: parsedData,
              rawData: responseData
            });
          } catch (parseError) {
            resolve({
              statusCode: res.statusCode,
              headers: res.headers,
              data: null,
              rawData: responseData
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

      if (postData) {
        req.write(postData);
      }
      
      req.end();
    });
  }
}

// تشغيل التشخيص
const diagnostic = new WaseetAPIDiagnostic();
diagnostic.runFullDiagnosis();
