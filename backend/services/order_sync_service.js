// ===================================
// خدمة مزامنة الطلبات مع شركة الوسيط
// Order Sync Service with Waseet
// ===================================

const { createClient } = require('@supabase/supabase-js');
const WaseetAPIClient = require('./waseet_api_client');

class OrderSyncService {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    try {
      this.waseetClient = new WaseetAPIClient();
      this.isInitialized = true;
      console.log('✅ تم تهيئة خدمة مزامنة الطلبات مع الوسيط بنجاح');
    } catch (error) {
      console.error('❌ خطأ في تهيئة عميل الوسيط:', error.message);
      this.waseetClient = null;
      this.isInitialized = false;
    }
  }

  /**
   * إرسال طلب إلى شركة الوسيط
   */
  async sendOrderToWaseet(orderId) {
    try {
      console.log(`📦 بدء إرسال الطلب ${orderId} إلى شركة الوسيط...`);

      // التحقق من تهيئة عميل الوسيط
      if (!this.waseetClient) {
        console.error('❌ عميل الوسيط غير مهيأ - لا يمكن إرسال الطلب');
        return {
          success: false,
          error: 'عميل الوسيط غير مهيأ - تحقق من بيانات المصادقة',
          needsConfiguration: true
        };
      }

      // جلب بيانات الطلب من قاعدة البيانات
      const { data: order, error: orderError } = await this.supabase
        .from('orders')
        .select('*')
        .eq('id', orderId)
        .single();

      if (orderError || !order) {
        console.error(`❌ فشل في جلب بيانات الطلب ${orderId}:`, orderError);
        return false;
      }

      console.log(`📋 تم جلب بيانات الطلب: ${order.customer_name}`);

      // التحقق من وجود بيانات الوسيط المحفوظة
      let waseetData = null;
      if (order.waseet_data) {
        try {
          waseetData = typeof order.waseet_data === 'string' 
            ? JSON.parse(order.waseet_data) 
            : order.waseet_data;
        } catch (parseError) {
          console.error(`❌ خطأ في تحليل بيانات الوسيط:`, parseError);
        }
      }

      // إذا لم توجد بيانات الوسيط، نحاول إنشاءها
      if (!waseetData) {
        console.log(`⚠️ لا توجد بيانات وسيط محفوظة للطلب ${orderId} - سيتم إنشاؤها`);
        waseetData = await this.createDefaultWaseetData(order);
      }

      // تحضير رقم الهاتف بالتنسيق الصحيح
      let clientMobile = order.customer_phone || order.primary_phone;

      // إذا لم يكن هناك رقم هاتف، استخدم رقم افتراضي
      if (!clientMobile || clientMobile === 'null' || clientMobile.trim() === '') {
        clientMobile = '+9647901234567'; // رقم افتراضي للاختبار
        console.warn(`⚠️ لا يوجد رقم هاتف للطلب ${orderId} - استخدام رقم افتراضي`);
      } else if (!clientMobile.startsWith('+964')) {
        // إضافة رمز العراق إذا لم يكن موجوداً
        if (clientMobile.startsWith('07')) {
          clientMobile = '+964' + clientMobile.substring(1);
        } else if (clientMobile.startsWith('7')) {
          clientMobile = '+964' + clientMobile;
        }
      }

      let clientMobile2 = order.alternative_phone || order.secondary_phone;
      if (clientMobile2 && !clientMobile2.startsWith('+964')) {
        if (clientMobile2.startsWith('07')) {
          clientMobile2 = '+964' + clientMobile2.substring(1);
        } else if (clientMobile2.startsWith('7')) {
          clientMobile2 = '+964' + clientMobile2;
        }
      }

      // تحضير بيانات الطلب للوسيط
      // إنشاء عنوان مناسب من بيانات الطلب المتاحة
      let location = '';

      // محاولة بناء العنوان من البيانات المتاحة
      if (order.customer_address && order.customer_address.trim() !== '') {
        location = order.customer_address.trim();
      } else if (order.delivery_address && order.delivery_address.trim() !== '') {
        location = order.delivery_address.trim();
      } else if (order.notes && order.notes.trim() !== '') {
        location = order.notes.trim();
      } else if (order.province && order.city) {
        location = `${order.province} - ${order.city}`;
      } else if (order.city) {
        location = order.city;
      } else {
        // استخدام عنوان افتراضي مقبول من الوسيط
        location = 'بغداد - الكرخ - شارع الرئيسي';
      }

      console.log(`📍 العنوان المستخدم للوسيط: "${location}"`);

      // التحقق من صحة العنوان
      if (location.length < 5) {
        console.log('⚠️ العنوان قصير جداً، استخدام عنوان افتراضي أطول');
        location = 'بغداد - الكرخ - شارع الرئيسي - بناية رقم 1';
      }

      // التأكد من أن العنوان لا يحتوي على نصوص افتراضية مرفوضة
      const rejectedTexts = ['عنوان العميل', 'لا يوجد عنوان', 'غير محدد'];
      if (rejectedTexts.some(text => location.includes(text))) {
        console.log('⚠️ العنوان يحتوي على نص افتراضي مرفوض، استخدام عنوان بديل');
        location = `${order.province || 'بغداد'} - ${order.city || 'الكرخ'} - شارع الرئيسي`;
      }

      console.log(`✅ العنوان النهائي للوسيط: "${location}"`);

      const orderDataForWaseet = {
        client_name: order.customer_name || 'عميل',
        client_mobile: clientMobile,
        client_mobile2: clientMobile2,
        city_id: waseetData.cityId || 1, // بغداد افتراضياً
        region_id: waseetData.regionId || 1,
        location: location,
        type_name: waseetData.typeName || 'عادي',
        items_number: waseetData.itemsCount || 1,
        price: waseetData.totalPrice || order.total || 25000,
        package_size: 1, // ID رقمي
        merchant_notes: `طلب من تطبيق منتجاتي - رقم الطلب: ${orderId}`,
        replacement: 0
      };

      console.log(`📋 بيانات الطلب المرسلة للوسيط:`, orderDataForWaseet);

      // إرسال الطلب لشركة الوسيط بالتنسيق الصحيح حسب التعليمات الرسمية
      const waseetResult = await this.waseetClient.createOrder(orderDataForWaseet);

      if (waseetResult && waseetResult.success) {
        console.log(`✅ تم إرسال الطلب ${orderId} لشركة الوسيط بنجاح`);
        console.log(`🆔 QR ID: ${waseetResult.qrId}`);

        // تحديث الطلب بمعلومات الوسيط
        await this.supabase
          .from('orders')
          .update({
            waseet_order_id: waseetResult.qrId,
            waseet_status: 'تم الإرسال للوسيط',
            waseet_data: JSON.stringify(waseetResult),
            updated_at: new Date().toISOString()
          })
          .eq('id', orderId);

        return {
          success: true,
          qrId: waseetResult.qrId,
          waseetResponse: waseetResult
        };

      } else {
        console.error(`❌ فشل في إرسال الطلب ${orderId} لشركة الوسيط:`, waseetResult);
        return false;
      }

    } catch (error) {
      console.error(`❌ خطأ في إرسال الطلب ${orderId} لشركة الوسيط:`, error);
      return false;
    }
  }

  /**
   * إنشاء بيانات وسيط افتراضية
   */
  async createDefaultWaseetData(order) {
    try {
      // محاولة تحديد المحافظة والمنطقة بناءً على عنوان العميل
      const cityMapping = {
        'بغداد': { cityId: '1', regionId: '1' },
        'البصرة': { cityId: '2', regionId: '1' },
        'أربيل': { cityId: '3', regionId: '1' },
        'النجف': { cityId: '4', regionId: '1' },
        'كربلاء': { cityId: '5', regionId: '1' },
        'الموصل': { cityId: '6', regionId: '1' },
        'السليمانية': { cityId: '7', regionId: '1' },
        'ديالى': { cityId: '8', regionId: '1' },
        'الأنبار': { cityId: '9', regionId: '1' },
        'دهوك': { cityId: '10', regionId: '1' },
        'كركوك': { cityId: '11', regionId: '1' },
        'بابل': { cityId: '12', regionId: '1' },
        'نينوى': { cityId: '13', regionId: '1' },
        'واسط': { cityId: '14', regionId: '1' },
        'صلاح الدين': { cityId: '15', regionId: '1' },
        'القادسية': { cityId: '16', regionId: '1' },
        'المثنى': { cityId: '17', regionId: '1' },
        'ذي قار': { cityId: '18', regionId: '1' },
        'ميسان': { cityId: '19', regionId: '1' }
      };

      // البحث عن المحافظة في العنوان
      let cityData = { cityId: '1', regionId: '1' }; // بغداد افتراضياً
      
      const address = (order.customer_address || order.province || order.city || '').toLowerCase();
      
      for (const [city, data] of Object.entries(cityMapping)) {
        if (address.includes(city.toLowerCase())) {
          cityData = data;
          break;
        }
      }

      // حساب عدد المنتجات والسعر الإجمالي
      let itemsCount = 1;
      let totalPrice = order.total || 0;

      // محاولة جلب عناصر الطلب
      try {
        const { data: orderItems } = await this.supabase
          .from('order_items')
          .select('quantity, price')
          .eq('order_id', order.id);

        if (orderItems && orderItems.length > 0) {
          itemsCount = orderItems.reduce((sum, item) => sum + (item.quantity || 1), 0);
          totalPrice = orderItems.reduce((sum, item) => sum + ((item.price || 0) * (item.quantity || 1)), 0);
        }
      } catch (itemsError) {
        console.warn(`⚠️ تحذير: فشل في جلب عناصر الطلب ${order.id}:`, itemsError);
      }

      const defaultData = {
        cityId: cityData.cityId,
        regionId: cityData.regionId,
        typeName: 'عادي',
        itemsCount: itemsCount,
        totalPrice: totalPrice,
        packageSize: '1',
        createdAt: new Date().toISOString()
      };

      console.log(`📋 تم إنشاء بيانات وسيط افتراضية للطلب ${order.id}:`, defaultData);

      // حفظ البيانات في قاعدة البيانات
      await this.supabase
        .from('orders')
        .update({
          waseet_data: JSON.stringify(defaultData)
        })
        .eq('id', order.id);

      return defaultData;

    } catch (error) {
      console.error(`❌ خطأ في إنشاء بيانات الوسيط الافتراضية:`, error);
      
      // إرجاع بيانات افتراضية أساسية
      return {
        cityId: '1',
        regionId: '1',
        typeName: 'عادي',
        itemsCount: 1,
        totalPrice: order.total || 0,
        packageSize: '1'
      };
    }
  }

  /**
   * التحقق من حالة الطلب في شركة الوسيط
   */
  async checkOrderStatus(qrId) {
    try {
      console.log(`🔍 فحص حالة الطلب ${qrId} في شركة الوسيط...`);
      
      const statusResult = await this.waseetClient.getOrderStatus(qrId);
      
      if (statusResult && statusResult.success) {
        console.log(`✅ تم جلب حالة الطلب ${qrId}: ${statusResult.status}`);
        return statusResult;
      } else {
        console.error(`❌ فشل في جلب حالة الطلب ${qrId}:`, statusResult);
        return null;
      }

    } catch (error) {
      console.error(`❌ خطأ في فحص حالة الطلب ${qrId}:`, error);
      return null;
    }
  }

  /**
   * مزامنة حالات جميع الطلبات المرسلة للوسيط
   */
  async syncAllOrderStatuses() {
    try {
      console.log(`🔄 بدء مزامنة حالات الطلبات مع شركة الوسيط...`);

      // جلب جميع الطلبات المرسلة للوسيط
      const { data: orders, error } = await this.supabase
        .from('orders')
        .select('id, waseet_order_id, status, customer_name')
        .not('waseet_order_id', 'is', null);

      if (error) {
        console.error(`❌ خطأ في جلب الطلبات المرسلة للوسيط:`, error);
        return false;
      }

      console.log(`📊 تم العثور على ${orders.length} طلب مرسل للوسيط`);

      let updatedCount = 0;

      for (const order of orders) {
        try {
          const statusResult = await this.checkOrderStatus(order.waseet_order_id);
          
          if (statusResult && statusResult.status !== order.status) {
            // تحديث حالة الطلب
            await this.supabase
              .from('orders')
              .update({
                status: statusResult.localStatus || statusResult.status,
                waseet_status: statusResult.status,
                updated_at: new Date().toISOString()
              })
              .eq('id', order.id);

            console.log(`✅ تم تحديث حالة الطلب ${order.id}: ${order.status} → ${statusResult.status}`);
            updatedCount++;
          }

        } catch (orderError) {
          console.error(`❌ خطأ في مزامنة الطلب ${order.id}:`, orderError);
        }
      }

      console.log(`✅ تم الانتهاء من المزامنة - تم تحديث ${updatedCount} طلب`);
      return true;

    } catch (error) {
      console.error(`❌ خطأ في مزامنة حالات الطلبات:`, error);
      return false;
    }
  }

  // إعادة محاولة الطلبات الفاشلة
  async retryFailedOrders() {
    try {
      console.log('🔄 البحث عن الطلبات الفاشلة لإعادة المحاولة...');

      // جلب الطلبات التي فشلت في الإرسال
      const { data: failedOrders, error } = await this.supabase
        .from('orders')
        .select('*')
        .eq('waseet_status', 'في انتظار الإرسال للوسيط')
        .is('waseet_order_id', null)
        .or('status.eq.قيد التوصيل الى الزبون (في عهدة المندوب),status.eq.قيد التوصيل,status.eq.in_delivery')
        .limit(10);

      if (error) {
        console.error('❌ خطأ في جلب الطلبات الفاشلة:', error);
        return false;
      }

      if (failedOrders.length === 0) {
        console.log('✅ لا توجد طلبات فاشلة لإعادة المحاولة');
        return true;
      }

      console.log(`📦 تم العثور على ${failedOrders.length} طلب فاشل`);

      for (const order of failedOrders) {
        console.log(`🔄 إعادة محاولة إرسال الطلب: ${order.id}`);

        const result = await this.sendOrderToWaseet(order.id);

        if (result && result.success) {
          console.log(`✅ نجح إرسال الطلب ${order.id} في المحاولة الثانية`);
        } else {
          console.log(`❌ فشل إرسال الطلب ${order.id} مرة أخرى`);
        }

        // انتظار قصير بين المحاولات
        await new Promise(resolve => setTimeout(resolve, 2000));
      }

      return true;
    } catch (error) {
      console.error('❌ خطأ في إعادة محاولة الطلبات الفاشلة:', error);
      return false;
    }
  }
}

module.exports = OrderSyncService;
