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
    this.waseetClient = new WaseetAPIClient();
  }

  /**
   * إرسال طلب إلى شركة الوسيط
   */
  async sendOrderToWaseet(orderId) {
    try {
      console.log(`📦 بدء إرسال الطلب ${orderId} إلى شركة الوسيط...`);

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

      // إرسال الطلب لشركة الوسيط
      const waseetResult = await this.waseetClient.createOrder({
        clientName: order.customer_name,
        clientMobile: order.customer_phone || order.primary_phone,
        clientMobile2: order.alternative_phone || order.secondary_phone,
        cityId: waseetData.cityId || '1', // بغداد افتراضياً
        regionId: waseetData.regionId || '1',
        location: order.customer_address || order.notes || 'عنوان العميل',
        typeName: waseetData.typeName || 'عادي',
        itemsNumber: waseetData.itemsCount || 1,
        price: waseetData.totalPrice || order.total || 0,
        packageSize: '1',
        merchantNotes: `طلب من تطبيق منتجاتي - رقم الطلب: ${orderId}`,
        replacement: 0
      });

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
}

module.exports = OrderSyncService;
