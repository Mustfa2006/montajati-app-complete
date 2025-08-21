#!/usr/bin/env node

// ===================================
// سكريبت التحقق من النشر على DigitalOcean
// DigitalOcean Deployment Verification Script
// ===================================

require('dotenv').config();
const axios = require('axios');

class DigitalOceanVerifier {
  constructor() {
    this.baseUrl = process.env.RAILWAY_APP_URL || 'https://montajati-official-backend-production.up.railway.app';
    this.tests = [];
    this.results = {
      passed: 0,
      failed: 0,
      total: 0
    };
  }

  // إضافة اختبار
  addTest(name, testFunction) {
    this.tests.push({ name, testFunction });
  }

  // تشغيل جميع الاختبارات
  async runAllTests() {
    console.log('🚀 بدء التحقق من النشر على DigitalOcean...');
    console.log('=' .repeat(60));
    console.log(`🌐 الرابط: ${this.baseUrl}`);
    console.log('📅 الوقت:', new Date().toISOString());
    console.log('');

    for (const test of this.tests) {
      await this.runTest(test);
    }

    this.printSummary();
  }

  // تشغيل اختبار واحد
  async runTest(test) {
    this.results.total++;
    
    try {
      console.log(`🧪 ${test.name}...`);
      const result = await test.testFunction();
      
      if (result.success) {
        console.log(`✅ نجح: ${result.message}`);
        this.results.passed++;
      } else {
        console.log(`❌ فشل: ${result.message}`);
        this.results.failed++;
      }
    } catch (error) {
      console.log(`💥 خطأ: ${error.message}`);
      this.results.failed++;
    }
    
    console.log('');
  }

  // طباعة الملخص
  printSummary() {
    console.log('📊 ملخص النتائج:');
    console.log('=' .repeat(40));
    console.log(`✅ نجح: ${this.results.passed}`);
    console.log(`❌ فشل: ${this.results.failed}`);
    console.log(`📊 المجموع: ${this.results.total}`);
    console.log(`📈 معدل النجاح: ${((this.results.passed / this.results.total) * 100).toFixed(1)}%`);
    
    if (this.results.failed === 0) {
      console.log('🎉 جميع الاختبارات نجحت! النشر جاهز للإنتاج');
    } else {
      console.log('⚠️ بعض الاختبارات فشلت. يرجى المراجعة');
    }
  }

  // اختبار الصحة العامة
  async testHealth() {
    try {
      const response = await axios.get(`${this.baseUrl}/health`, {
        timeout: 10000
      });
      
      if (response.status === 200 && response.data.status) {
        return {
          success: true,
          message: `الخادم يعمل بنجاح (${response.status})`
        };
      } else {
        return {
          success: false,
          message: `استجابة غير متوقعة: ${response.status}`
        };
      }
    } catch (error) {
      return {
        success: false,
        message: `فشل الاتصال: ${error.message}`
      };
    }
  }

  // اختبار API الأساسي
  async testBasicAPI() {
    try {
      const response = await axios.get(`${this.baseUrl}/`, {
        timeout: 10000
      });
      
      if (response.status === 200 && response.data.message) {
        return {
          success: true,
          message: `API يعمل بنجاح`
        };
      } else {
        return {
          success: false,
          message: `استجابة API غير صحيحة`
        };
      }
    } catch (error) {
      return {
        success: false,
        message: `فشل API: ${error.message}`
      };
    }
  }

  // اختبار حالة النظام
  async testSystemStatus() {
    try {
      const response = await axios.get(`${this.baseUrl}/api/system/status`, {
        timeout: 10000
      });
      
      if (response.status === 200) {
        return {
          success: true,
          message: `حالة النظام: ${response.data.status || 'جيدة'}`
        };
      } else {
        return {
          success: false,
          message: `فشل في الحصول على حالة النظام`
        };
      }
    } catch (error) {
      return {
        success: false,
        message: `خطأ في حالة النظام: ${error.message}`
      };
    }
  }

  // اختبار قاعدة البيانات
  async testDatabase() {
    try {
      const response = await axios.get(`${this.baseUrl}/api/test/database`, {
        timeout: 15000
      });
      
      if (response.status === 200) {
        return {
          success: true,
          message: `قاعدة البيانات متصلة`
        };
      } else {
        return {
          success: false,
          message: `مشكلة في قاعدة البيانات`
        };
      }
    } catch (error) {
      return {
        success: false,
        message: `فشل اتصال قاعدة البيانات: ${error.message}`
      };
    }
  }

  // اختبار الإشعارات
  async testNotifications() {
    try {
      const response = await axios.get(`${this.baseUrl}/api/test/notifications`, {
        timeout: 10000
      });
      
      if (response.status === 200) {
        return {
          success: true,
          message: `نظام الإشعارات يعمل`
        };
      } else {
        return {
          success: false,
          message: `مشكلة في نظام الإشعارات`
        };
      }
    } catch (error) {
      return {
        success: false,
        message: `فشل نظام الإشعارات: ${error.message}`
      };
    }
  }

  // اختبار المزامنة
  async testSync() {
    try {
      const response = await axios.get(`${this.baseUrl}/api/sync/status`, {
        timeout: 10000
      });
      
      if (response.status === 200) {
        return {
          success: true,
          message: `نظام المزامنة نشط`
        };
      } else {
        return {
          success: false,
          message: `مشكلة في نظام المزامنة`
        };
      }
    } catch (error) {
      return {
        success: false,
        message: `فشل نظام المزامنة: ${error.message}`
      };
    }
  }
}

// تشغيل الاختبارات
async function main() {
  const verifier = new DigitalOceanVerifier();
  
  // إضافة الاختبارات
  verifier.addTest('فحص الصحة العامة', () => verifier.testHealth());
  verifier.addTest('فحص API الأساسي', () => verifier.testBasicAPI());
  verifier.addTest('فحص حالة النظام', () => verifier.testSystemStatus());
  verifier.addTest('فحص قاعدة البيانات', () => verifier.testDatabase());
  verifier.addTest('فحص نظام الإشعارات', () => verifier.testNotifications());
  verifier.addTest('فحص نظام المزامنة', () => verifier.testSync());
  
  // تشغيل جميع الاختبارات
  await verifier.runAllTests();
}

// تشغيل السكريبت
if (require.main === module) {
  main().catch(error => {
    console.error('💥 خطأ في تشغيل الاختبارات:', error);
    process.exit(1);
  });
}

module.exports = DigitalOceanVerifier;
