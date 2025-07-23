// ===================================
// خدمة شركة الوسيط الإنتاجية
// Production Waseet Service
// ===================================

const axios = require('axios');
const config = require('./config');
const logger = require('./logger');

class ProductionWaseetService {
  constructor() {
    this.config = config.get('waseet');
    this.token = null;
    this.lastLogin = null;
    this.requestCount = 0;
    this.errorCount = 0;
    this.lastError = null;
    
    // إحصائيات الأداء
    this.stats = {
      totalRequests: 0,
      successfulRequests: 0,
      failedRequests: 0,
      averageResponseTime: 0,
      lastRequestTime: null
    };

    logger.info('🌐 تم تهيئة خدمة شركة الوسيط الإنتاجية');
  }

  /**
   * تسجيل الدخول مع إعادة المحاولة الذكية
   */
  async authenticate() {
    const operationId = await logger.startOperation('waseet_authentication');
    
    try {
      // التحقق من صحة التوكن الحالي
      if (this.isTokenValid()) {
        await logger.endOperation(operationId, 'waseet_authentication', true, {
          message: 'استخدام التوكن الحالي'
        });
        return this.token;
      }

      logger.info('🔐 بدء تسجيل الدخول في شركة الوسيط');
      
      const startTime = Date.now();
      const loginData = new URLSearchParams({
        username: this.config.username,
        password: this.config.password
      });

      const response = await this.makeRequest('POST', '/merchant/login', loginData, {
        'Content-Type': 'application/x-www-form-urlencoded'
      });

      if (response.status !== 302 && response.status !== 303) {
        throw new Error(`فشل تسجيل الدخول: HTTP ${response.status}`);
      }

      this.token = response.headers['set-cookie']?.join('; ') || '';
      this.lastLogin = Date.now();
      
      const duration = Date.now() - startTime;
      await logger.logPerformance('waseet_authentication', duration);
      await logger.endOperation(operationId, 'waseet_authentication', true, {
        duration,
        tokenLength: this.token.length
      });

      logger.info('✅ تم تسجيل الدخول بنجاح في شركة الوسيط');
      return this.token;

    } catch (error) {
      this.errorCount++;
      this.lastError = error.message;
      
      await logger.error('❌ فشل تسجيل الدخول في شركة الوسيط', {
        error: error.message,
        attempt: this.errorCount
      });
      
      await logger.endOperation(operationId, 'waseet_authentication', false, {
        error: error.message
      });
      
      throw error;
    }
  }

  /**
   * التحقق من صحة التوكن
   */
  isTokenValid() {
    if (!this.token || !this.lastLogin) {
      return false;
    }

    // التوكن صالح لمدة 50 دقيقة (أقل من ساعة للأمان)
    const tokenAge = Date.now() - this.lastLogin;
    const maxAge = 50 * 60 * 1000; // 50 دقيقة
    
    return tokenAge < maxAge;
  }

  /**
   * جلب صفحة التاجر
   */
  async fetchMerchantPage() {
    const operationId = await logger.startOperation('fetch_merchant_page');
    
    try {
      await this.authenticate();
      
      logger.info('📄 جلب صفحة التاجر من شركة الوسيط');
      const startTime = Date.now();

      const response = await this.makeRequest('GET', '/merchant', null, {
        'Cookie': this.token
      });

      if (response.status !== 200) {
        throw new Error(`فشل جلب صفحة التاجر: HTTP ${response.status}`);
      }

      const duration = Date.now() - startTime;
      const pageSize = response.data.length;
      
      await logger.logPerformance('fetch_merchant_page', duration, {
        pageSize,
        contentType: response.headers['content-type']
      });

      await logger.endOperation(operationId, 'fetch_merchant_page', true, {
        duration,
        pageSize
      });

      logger.info(`✅ تم جلب صفحة التاجر بنجاح (${pageSize} حرف)`);
      return response.data;

    } catch (error) {
      await logger.error('❌ فشل جلب صفحة التاجر', {
        error: error.message
      });
      
      await logger.endOperation(operationId, 'fetch_merchant_page', false, {
        error: error.message
      });
      
      throw error;
    }
  }

  /**
   * استخراج بيانات الطلبات من الصفحة
   */
  async extractOrdersFromPage(pageContent) {
    const operationId = await logger.startOperation('extract_orders_data');
    
    try {
      logger.info('🔍 استخراج بيانات الطلبات من صفحة التاجر');
      
      const orders = [];
      let extractedCount = 0;

      // استخراج الطلبات المطبوعة
      const printedOrdersMatch = pageContent.match(/id="printed_orders" value='([^']+)'/);
      if (printedOrdersMatch) {
        try {
          const printedOrders = JSON.parse(printedOrdersMatch[1]);
          orders.push(...printedOrders);
          extractedCount += printedOrders.length;
          logger.info(`📋 تم استخراج ${printedOrders.length} طلب مطبوع`);
        } catch (e) {
          logger.warn('⚠️ خطأ في تحليل الطلبات المطبوعة', { error: e.message });
        }
      }

      // استخراج الطلبات غير المطبوعة
      const notPrintedOrdersMatch = pageContent.match(/id="not_printed_orders" value='([^']+)'/);
      if (notPrintedOrdersMatch) {
        try {
          const notPrintedOrders = JSON.parse(notPrintedOrdersMatch[1]);
          orders.push(...notPrintedOrders);
          extractedCount += notPrintedOrders.length;
          logger.info(`📋 تم استخراج ${notPrintedOrders.length} طلب غير مطبوع`);
        } catch (e) {
          logger.warn('⚠️ خطأ في تحليل الطلبات غير المطبوعة', { error: e.message });
        }
      }

      // تحليل الحالات الموجودة
      const statusCounts = this.analyzeOrderStatuses(orders);
      
      await logger.endOperation(operationId, 'extract_orders_data', true, {
        totalOrders: orders.length,
        extractedCount,
        statusCounts
      });

      logger.info(`✅ تم استخراج ${orders.length} طلب بنجاح`);
      return {
        orders,
        totalCount: orders.length,
        statusCounts
      };

    } catch (error) {
      logger.error('❌ فشل استخراج بيانات الطلبات', {
        error: error.message
      });
      
      await logger.endOperation(operationId, 'extract_orders_data', false, {
        error: error.message
      });
      
      throw error;
    }
  }

  /**
   * تحليل حالات الطلبات
   */
  analyzeOrderStatuses(orders) {
    const statusCounts = {};
    const statusDetails = {};

    orders.forEach(order => {
      if (order.status_id && order.status) {
        const statusKey = `${order.status_id}-${order.status}`;
        statusCounts[statusKey] = (statusCounts[statusKey] || 0) + 1;
        
        if (!statusDetails[order.status_id]) {
          statusDetails[order.status_id] = {
            id: order.status_id,
            text: order.status,
            count: 0,
            localStatus: this.mapStatusToLocal(order.status_id, order.status)
          };
        }
        statusDetails[order.status_id].count++;
      }
    });

    return {
      counts: statusCounts,
      details: statusDetails
    };
  }

  /**
   * تحويل حالة الوسيط إلى الحالة المحلية
   */
  mapStatusToLocal(statusId, statusText) {
    const mapping = config.get('supportedStatuses', 'waseetToLocal');
    
    // محاولة التحويل بالـ ID أولاً
    if (mapping[statusId]) {
      return mapping[statusId];
    }
    
    // محاولة التحويل بالنص
    if (mapping[statusText]) {
      return mapping[statusText];
    }
    
    // البحث في النص الجزئي
    for (const [key, value] of Object.entries(mapping)) {
      if (statusText.includes(key) || key.includes(statusText)) {
        return value;
      }
    }
    
    logger.warn('⚠️ حالة غير معروفة', {
      statusId,
      statusText,
      message: 'لم يتم العثور على تحويل مناسب'
    });
    
    return 'unknown';
  }

  /**
   * جلب حالة طلب محدد
   */
  async fetchOrderStatus(waseetOrderId) {
    const operationId = await logger.startOperation('fetch_order_status', {
      waseetOrderId
    });
    
    try {
      logger.info(`🔍 جلب حالة الطلب ${waseetOrderId}`);
      
      const pageContent = await this.fetchMerchantPage();
      const ordersData = this.extractOrdersFromPage(pageContent);
      
      // البحث عن الطلب المحدد
      const order = ordersData.orders.find(o => 
        o.id === waseetOrderId || o.id === waseetOrderId.toString()
      );
      
      if (order) {
        const result = {
          success: true,
          order_id: order.id,
          status_id: order.status_id,
          status_text: order.status,
          local_status: this.mapStatusToLocal(order.status_id, order.status),
          client_name: order.client_name,
          created_at: order.created_at,
          updated_at: order.updated_at,
          full_data: order
        };

        await logger.endOperation(operationId, 'fetch_order_status', true, {
          waseetOrderId,
          statusId: order.status_id,
          statusText: order.status,
          localStatus: result.local_status
        });

        logger.info(`✅ تم العثور على الطلب ${waseetOrderId}: ${order.status}`);
        return result;
      } else {
        await logger.endOperation(operationId, 'fetch_order_status', false, {
          waseetOrderId,
          error: 'الطلب غير موجود'
        });

        logger.warn(`⚠️ لم يتم العثور على الطلب ${waseetOrderId}`);
        return {
          success: false,
          error: 'الطلب غير موجود في الصفحة الحالية'
        };
      }

    } catch (error) {
      await logger.error(`❌ فشل جلب حالة الطلب ${waseetOrderId}`, {
        error: error.message
      });
      
      await logger.endOperation(operationId, 'fetch_order_status', false, {
        waseetOrderId,
        error: error.message
      });
      
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * جلب جميع الطلبات وحالاتها
   */
  async fetchAllOrderStatuses() {
    const operationId = await logger.startOperation('fetch_all_orders');
    
    try {
      logger.info('📊 جلب جميع الطلبات وحالاتها');
      
      const pageContent = await this.fetchMerchantPage();
      const ordersData = await this.extractOrdersFromPage(pageContent);
      
      const orderStatuses = ordersData.orders.map(order => ({
        order_id: order.id,
        status_id: order.status_id,
        status_text: order.status,
        local_status: this.mapStatusToLocal(order.status_id, order.status),
        client_name: order.client_name,
        created_at: order.created_at,
        updated_at: order.updated_at,
        price: order.price,
        city_name: order.city_name,
        region_name: order.region_name
      }));

      await logger.endOperation(operationId, 'fetch_all_orders', true, {
        totalOrders: orderStatuses.length,
        statusCounts: ordersData.statusCounts.counts
      });

      // تم إزالة الرسالة المفصلة
      
      return {
        success: true,
        total_orders: orderStatuses.length,
        orders: orderStatuses,
        status_analysis: ordersData.statusCounts
      };

    } catch (error) {
      await logger.error('❌ فشل جلب جميع الطلبات', {
        error: error.message
      });
      
      await logger.endOperation(operationId, 'fetch_all_orders', false, {
        error: error.message
      });
      
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * إجراء طلب HTTP مع إعادة المحاولة
   */
  async makeRequest(method, endpoint, data = null, headers = {}) {
    let lastError;
    
    for (let attempt = 1; attempt <= this.config.retryAttempts; attempt++) {
      try {
        this.requestCount++;
        this.stats.totalRequests++;
        this.stats.lastRequestTime = new Date().toISOString();
        
        const startTime = Date.now();
        
        const requestConfig = {
          method,
          url: `${this.config.baseUrl}${endpoint}`,
          timeout: this.config.timeout,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            ...headers
          },
          maxRedirects: 0,
          validateStatus: () => true
        };

        if (data) {
          requestConfig.data = data;
        }

        const response = await axios(requestConfig);
        
        const duration = Date.now() - startTime;
        this.updateResponseTimeStats(duration);
        this.stats.successfulRequests++;
        
        return response;

      } catch (error) {
        lastError = error;
        this.stats.failedRequests++;
        
        logger.warn(`⚠️ فشل الطلب (محاولة ${attempt}/${this.config.retryAttempts})`, {
          method,
          endpoint,
          error: error.message,
          attempt
        });

        if (attempt < this.config.retryAttempts) {
          const delay = this.config.retryDelay * attempt;
          logger.info(`⏳ انتظار ${delay}ms قبل إعادة المحاولة`);
          await new Promise(resolve => setTimeout(resolve, delay));
        }
      }
    }

    throw lastError;
  }

  /**
   * تحديث إحصائيات وقت الاستجابة
   */
  updateResponseTimeStats(duration) {
    if (this.stats.averageResponseTime === 0) {
      this.stats.averageResponseTime = duration;
    } else {
      this.stats.averageResponseTime = 
        (this.stats.averageResponseTime + duration) / 2;
    }
  }

  /**
   * الحصول على إحصائيات الخدمة
   */
  getStats() {
    return {
      ...this.stats,
      requestCount: this.requestCount,
      errorCount: this.errorCount,
      lastError: this.lastError,
      tokenValid: this.isTokenValid(),
      lastLogin: this.lastLogin ? new Date(this.lastLogin).toISOString() : null,
      uptime: Date.now() - (this.lastLogin || Date.now())
    };
  }

  /**
   * إعادة تعيين الإحصائيات
   */
  resetStats() {
    this.stats = {
      totalRequests: 0,
      successfulRequests: 0,
      failedRequests: 0,
      averageResponseTime: 0,
      lastRequestTime: null
    };
    this.requestCount = 0;
    this.errorCount = 0;
    this.lastError = null;
    
    logger.info('📊 تم إعادة تعيين إحصائيات خدمة الوسيط');
  }
}

module.exports = ProductionWaseetService;
