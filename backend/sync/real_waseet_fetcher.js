// ===================================
// جلب الحالات الحقيقية من شركة الوسيط
// Real Waseet Status Fetcher
// ===================================

const axios = require('axios');

class RealWaseetFetcher {
  constructor() {
    this.baseUrl = process.env.ALMASEET_BASE_URL || 'https://api.alwaseet-iq.net';
    this.username = process.env.WASEET_USERNAME;
    this.password = process.env.WASEET_PASSWORD;
    this.token = null;
    this.lastLogin = null;
    
    console.log('🌐 تم تهيئة نظام جلب الحالات الحقيقية من شركة الوسيط');
  }

  /**
   * تسجيل الدخول في شركة الوسيط
   */
  async authenticate() {
    try {
      // التحقق من صحة التوكن الحالي (صالح لمدة ساعة)
      if (this.token && this.lastLogin && 
          (Date.now() - this.lastLogin) < 3600000) {
        return this.token;
      }

      console.log('🔐 تسجيل الدخول في شركة الوسيط...');
      
      const loginData = new URLSearchParams({
        username: this.username,
        password: this.password
      });

      const response = await axios.post(
        `${this.baseUrl}/merchant/login`,
        loginData,
        {
          timeout: 15000,
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
          },
          maxRedirects: 0,
          validateStatus: () => true
        }
      );

      if (response.status !== 302 && response.status !== 303) {
        throw new Error(`فشل تسجيل الدخول: ${response.status}`);
      }

      this.token = response.headers['set-cookie']?.join('; ') || '';
      this.lastLogin = Date.now();
      
      console.log('✅ تم تسجيل الدخول بنجاح');
      return this.token;

    } catch (error) {
      console.error('❌ خطأ في تسجيل الدخول:', error.message);
      throw error;
    }
  }

  /**
   * جلب صفحة التاجر واستخراج بيانات الطلبات
   */
  async fetchMerchantPage() {
    try {
      await this.authenticate();

      console.log('📄 جلب صفحة التاجر...');
      
      const response = await axios.get(`${this.baseUrl}/merchant`, {
        timeout: 15000,
        headers: {
          'Cookie': this.token,
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
      });

      return response.data;

    } catch (error) {
      console.error('❌ خطأ في جلب صفحة التاجر:', error.message);
      throw error;
    }
  }

  /**
   * استخراج بيانات الطلبات من JSON المدمج في الصفحة
   */
  extractOrdersFromPage(pageContent) {
    try {
      const orders = [];

      // استخراج الطلبات المطبوعة
      const printedOrdersMatch = pageContent.match(/id="printed_orders" value='([^']+)'/);
      if (printedOrdersMatch) {
        try {
          const printedOrders = JSON.parse(printedOrdersMatch[1]);
          orders.push(...printedOrders);
          console.log(`📋 تم استخراج ${printedOrders.length} طلب مطبوع`);
        } catch (e) {
          console.log('⚠️ خطأ في تحليل الطلبات المطبوعة');
        }
      }

      // استخراج الطلبات غير المطبوعة
      const notPrintedOrdersMatch = pageContent.match(/id="not_printed_orders" value='([^']+)'/);
      if (notPrintedOrdersMatch) {
        try {
          const notPrintedOrders = JSON.parse(notPrintedOrdersMatch[1]);
          orders.push(...notPrintedOrders);
          console.log(`📋 تم استخراج ${notPrintedOrders.length} طلب غير مطبوع`);
        } catch (e) {
          console.log('⚠️ خطأ في تحليل الطلبات غير المطبوعة');
        }
      }

      return orders;

    } catch (error) {
      console.error('❌ خطأ في استخراج بيانات الطلبات:', error.message);
      return [];
    }
  }

  /**
   * جلب حالة طلب محدد
   */
  async fetchOrderStatus(waseetOrderId) {
    try {
      console.log(`🔍 جلب حالة الطلب ${waseetOrderId}...`);
      
      const pageContent = await this.fetchMerchantPage();
      const orders = this.extractOrdersFromPage(pageContent);
      
      // البحث عن الطلب المحدد
      const order = orders.find(o => o.id === waseetOrderId || o.id === waseetOrderId.toString());
      
      if (order) {
        console.log(`✅ تم العثور على الطلب ${waseetOrderId}`);
        return {
          success: true,
          order_id: order.id,
          status_id: order.status_id,
          status_text: order.status,
          client_name: order.client_name,
          created_at: order.created_at,
          updated_at: order.updated_at,
          full_data: order
        };
      } else {
        console.log(`❌ لم يتم العثور على الطلب ${waseetOrderId}`);
        return {
          success: false,
          error: 'الطلب غير موجود في الصفحة الحالية'
        };
      }

    } catch (error) {
      console.error(`❌ خطأ في جلب حالة الطلب ${waseetOrderId}:`, error.message);
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
    try {
      console.log('📊 جلب جميع الطلبات وحالاتها...');
      
      const pageContent = await this.fetchMerchantPage();
      const orders = this.extractOrdersFromPage(pageContent);
      
      const orderStatuses = orders.map(order => ({
        order_id: order.id,
        status_id: order.status_id,
        status_text: order.status,
        client_name: order.client_name,
        created_at: order.created_at,
        updated_at: order.updated_at,
        price: order.price,
        city_name: order.city_name,
        region_name: order.region_name
      }));

      console.log(`✅ تم جلب ${orderStatuses.length} طلب`);
      
      // إحصائيات الحالات
      const statusCounts = {};
      orderStatuses.forEach(order => {
        const statusKey = `${order.status_id}-${order.status_text}`;
        statusCounts[statusKey] = (statusCounts[statusKey] || 0) + 1;
      });

      console.log('📊 إحصائيات الحالات:');
      Object.entries(statusCounts).forEach(([status, count]) => {
        console.log(`   ${status}: ${count} طلب`);
      });

      return {
        success: true,
        total_orders: orderStatuses.length,
        orders: orderStatuses,
        status_counts: statusCounts
      };

    } catch (error) {
      console.error('❌ خطأ في جلب جميع الطلبات:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * جلب الحالات المتاحة من الطلبات الموجودة
   */
  async getAvailableStatuses() {
    try {
      console.log('🔍 جلب الحالات المتاحة...');
      
      const result = await this.fetchAllOrderStatuses();
      if (!result.success) {
        return result;
      }

      const statusMap = new Map();
      result.orders.forEach(order => {
        if (order.status_id && order.status_text) {
          statusMap.set(order.status_id, order.status_text);
        }
      });

      const availableStatuses = Array.from(statusMap.entries()).map(([id, text]) => ({
        id,
        text,
        count: result.status_counts[`${id}-${text}`] || 0
      }));

      console.log(`✅ تم العثور على ${availableStatuses.length} حالة متاحة`);

      return {
        success: true,
        statuses: availableStatuses,
        total_statuses: availableStatuses.length
      };

    } catch (error) {
      console.error('❌ خطأ في جلب الحالات المتاحة:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * فحص ما إذا كانت الحالة المطلوبة موجودة
   */
  async checkStatusExists(statusId) {
    try {
      const result = await this.getAvailableStatuses();
      if (!result.success) {
        return false;
      }

      return result.statuses.some(status => 
        status.id === statusId || status.id === statusId.toString()
      );

    } catch (error) {
      console.error(`❌ خطأ في فحص الحالة ${statusId}:`, error.message);
      return false;
    }
  }
}

module.exports = RealWaseetFetcher;
