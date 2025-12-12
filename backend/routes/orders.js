// ===================================
// مسارات API للطلبات - Orders Routes
// ===================================

const express = require('express');
const { createClient } = require('@supabase/supabase-js');
const router = express.Router();

// إعداد Supabase مع معالجة أخطاء
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('❌ خطأ حرج: متغيرات Supabase غير موجودة!');
  // ⚠️ لا نطبع القيم أو حالة وجودها لحماية السرية
  throw new Error('Supabase credentials are missing. Please set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY environment variables.');
}

const supabase = createClient(supabaseUrl, supabaseKey);

// ================================
// 📊 Mapping الحالات الموحد (8️⃣)
// ================================
const STATUS_MAP = {
  IN_DELIVERY: ['in_delivery', 'قيد التوصيل', 'قيد التوصيل الى الزبون (في عهدة المندوب)', 'in_delivery_to_customer'],
  DELIVERED: ['delivered', 'تم التسليم للزبون', 'تم التسليم', 'delivered_to_customer'],
  PENDING: ['pending', 'قيد الانتظار', 'waiting'],
  CANCELLED: ['cancelled', 'ملغي', 'canceled'],
  ACTIVE: ['active', 'نشط', 'active_order'],
};

// دالة للتحقق من حالة معينة
function isStatusType(status, type) {
  const normalized = (status || '').toString().toLowerCase().trim();
  const variants = STATUS_MAP[type] || [];
  return variants.some(v => normalized.includes(v.toLowerCase()));
}

// ================================
// 🛠️ أدوات مساعدة عامة + التحقق من الهوية
// ================================

// 📋 Logger منظم (بدل console.log المتكرر) - 11️⃣
const logger = {
  info: (msg, data = '') => console.log(`ℹ️ ${msg}`, data),
  warn: (msg, data = '') => console.warn(`⚠️ ${msg}`, data),
  error: (msg, data = '') => console.error(`❌ ${msg}`, data),
  debug: (msg, data = '') => process.env.DEBUG && console.log(`🔍 ${msg}`, data),
};

// 🔐 معالجة الأخطاء الموحدة
function apiError(res, context, error, statusCode = 500) {
  const msg = error?.message || String(error);
  logger.error(`${context}`, msg);
  return res.status(statusCode).json({ success: false, error: `خطأ في ${context}` });
}

// ✅ رد نجاح موحد
function apiSuccess(res, data = null, message = 'تم بنجاح') {
  return res.json({ success: true, message, data });
}

// 🔑 التحقق من الهوية
async function verifyAuth(req, res, next) {
  try {
    const hdr = req.headers || {};
    const authHeader = hdr.authorization || hdr.Authorization || '';
    const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;

    // سماح داخلي اختياري عبر مفتاح داخلي
    const internalKey = hdr['x-internal-key'] || hdr['X-Internal-Key'];
    if (internalKey && process.env.INTERNAL_API_KEY && internalKey === process.env.INTERNAL_API_KEY) {
      return next();
    }

    if (!token) {
      return res.status(401).json({ success: false, error: 'غير مصرح بالوصول' });
    }

    const { data, error } = await supabase.auth.getUser(token);
    if (error || !data || !data.user) {
      return res.status(401).json({ success: false, error: 'رمز الدخول غير صالح' });
    }

    req.user = data.user;
    return next();
  } catch (e) {
    logger.error('Auth error', e.message);
    return res.status(401).json({ success: false, error: 'غير مصرح بالوصول' });
  }
}

// 🆔 توليد معرف فريد
function generateId(prefix) {
  return `${prefix}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
}

// ✔️ التحقق من صحة البيانات
function validateOrderData(data) {
  const errors = [];
  if (!data.customer_name || typeof data.customer_name !== 'string' || data.customer_name.trim().length === 0) {
    errors.push('اسم العميل مطلوب وصحيح');
  }
  if (!data.primary_phone || typeof data.primary_phone !== 'string' || data.primary_phone.trim().length === 0) {
    errors.push('رقم هاتف العميل مطلوب');
  }
  if (!data.user_phone || typeof data.user_phone !== 'string' || data.user_phone.trim().length === 0) {
    errors.push('رقم هاتف المستخدم مطلوب');
  }
  if (typeof data.total !== 'number' || data.total < 0) {
    errors.push('الإجمالي يجب أن يكون رقماً موجباً');
  }
  return errors;
}

// 💾 حفظ الطلب مع العناصر (مع معالجة أخطاء محسّنة) - 9️⃣
async function saveOrderWithItems({ orderTable, itemsTable, newOrder, items, mapItemRow, foreignKeyField }) {
  try {
    const { data: orderResult, error: orderError } = await supabase
      .from(orderTable)
      .insert(newOrder)
      .select()
      .single();

    if (orderError) {
      return { error: orderError, where: 'order' };
    }

    let itemsSaved = false;
    if (items && items.length > 0) {
      const rows = items.map((item) => {
        const base = mapItemRow(item) || {};
        base[foreignKeyField] = newOrder.id;
        base.created_at = new Date().toISOString();
        return base;
      });

      const { data: itemsData, error: itemsError } = await supabase
        .from(itemsTable)
        .insert(rows)
        .select();

      if (itemsError || !itemsData || itemsData.length === 0) {
        // رجوع عن إنشاء الطلب إذا فشل حفظ العناصر
        await supabase.from(orderTable).delete().eq('id', newOrder.id);
        return { error: itemsError || new Error('فشل في حفظ عناصر الطلب'), where: 'items' };
      }

      itemsSaved = true;
    }

    return { orderResult, itemsSaved };
  } catch (e) {
    logger.error('saveOrderWithItems', e.message);
    return { error: e, where: 'transaction' };
  }
}

// 3️⃣ دوال CRUD موحدة لتقليل التكرار
async function createOrderUnified(table, itemsTable, orderData, items, mapItemRow, foreignKeyField) {
  // ✔️ التحقق من صحة البيانات (12️⃣)
  const validationErrors = validateOrderData(orderData);
  if (validationErrors.length > 0) {
    return { error: new Error(validationErrors.join(', ')), validationErrors };
  }

  const orderId = orderData.id || generateId(table === 'orders' ? 'order' : 'scheduled');
  const newOrder = {
    ...orderData,
    id: orderId,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    status: orderData.status || 'active'
  };

  return saveOrderWithItems({
    orderTable: table,
    itemsTable: itemsTable,
    newOrder,
    items,
    mapItemRow,
    foreignKeyField
  });
}

async function deleteOrderUnified(table, id) {
  try {
    const { error } = await supabase.from(table).delete().eq('id', id);
    if (error) {
      return { error };
    }
    return { success: true };
  } catch (e) {
    logger.error(`deleteOrderUnified from ${table}`, e.message);
    return { error: e };
  }
}

// ⚠️ ملاحظة: لا نطبق middleware على جميع المسارات لتجنب مشاكل الوصول
// يمكن تطبيق التحقق على مسارات محددة إذا لزم الأمر

// ===================================
// GET /api/orders/debug-waseet - فحص مفصل لحالة الوسيط
// ===================================
router.get('/debug-waseet', async (req, res) => {
  try {

    const debugInfo = {
      timestamp: new Date().toISOString(),
      globalService: {
        exists: !!global.orderSyncService,
        type: global.orderSyncService ? global.orderSyncService.constructor.name : null,
        isInitialized: global.orderSyncService ? global.orderSyncService.isInitialized : null,
        methods: global.orderSyncService ? Object.getOwnPropertyNames(Object.getPrototypeOf(global.orderSyncService)) : null
      },
      environment: {
        NODE_ENV: process.env.NODE_ENV,
        hasSupabaseUrl: !!process.env.SUPABASE_URL,
        hasSupabaseKey: !!process.env.SUPABASE_SERVICE_ROLE_KEY
      }
    };

    // اختبار تهيئة خدمة جديدة
    try {
      const OrderSyncService = require('../services/order_sync_service');
      const testService = new OrderSyncService();
      debugInfo.testService = {
        canCreate: true,
        isInitialized: testService.isInitialized || false,
        methods: Object.getOwnPropertyNames(Object.getPrototypeOf(testService))
      };
    } catch (serviceError) {
      debugInfo.testService = {
        canCreate: false,
        error: serviceError.message
      };
    }

    res.json({
      success: true,
      debug: debugInfo
    });

  } catch (error) {
    console.error('❌ خطأ في فحص الوسيط:', error);
    res.status(500).json({
      success: false,
      error: error.message,
      stack: error.stack
    });
  }
});

// ===================================
// GET /api/orders - جلب قائمة الطلبات
// ===================================
router.get('/', async (req, res) => {
  try {
    const { status, page = 1, limit = 50, search } = req.query;

    let query = supabase
      .from('orders')
      .select('id, order_number, status, customer_name, customer_phone, user_phone, total, subtotal, discount, taxes, shipping_fee, profit, profit_amount, waseet_order_id, waseet_status, created_at, updated_at')
      .order('created_at', { ascending: false });

    // فلترة حسب الحالة
    if (status) {
      query = query.eq('status', status);
    }

    // ✅ البحث الآمن - منع SQL Injection
    if (search) {
      // تنظيف وتعقيم نص البحث
      const sanitizedSearch = search.replace(/[%_\\]/g, '\\$&').trim();

      if (sanitizedSearch.length > 0) {
        query = query.or(`customer_name.ilike.%${sanitizedSearch}%,order_number.ilike.%${sanitizedSearch}%,customer_phone.ilike.%${sanitizedSearch}%`);
      }
    }

    // ✅ التصفح المحسن مع ترتيب
    const offset = (page - 1) * limit;

    // ترتيب حسب تاريخ الإنشاء (الأحدث أولاً) لتحسين الأداء
    query = query
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    const { data, error } = await query;

    if (error) {
      return apiError(res, 'جلب الطلبات', error);
    }

    res.json({
      success: true,
      data: data || [],
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: data?.length || 0
      }
    });

  } catch (error) {
    console.error('❌ خطأ في API جلب الطلبات:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ===================================
// مسارات المزامنة مع الوسيط (يجب أن تأتي قبل /:id)
// ===================================

// مسار اختبار بسيط
router.get('/test-route', (req, res) => {
  res.json({ success: true, message: 'المسار يعمل!' });
});

// مسار لاختبار النظام المدمج مباشرة
router.get('/check-integrated-sync', async (req, res) => {
  try {
    const waseetSync = require('../services/integrated_waseet_sync');
    const stats = waseetSync.getStats();

    res.json({
      success: true,
      data: {
        isRunning: waseetSync.isRunning,
        stats: stats,
        message: 'النظام المدمج متاح'
      }
    });
  } catch (error) {
    res.json({
      success: false,
      error: error.message,
      message: 'النظام المدمج غير متاح'
    });
  }
});

// ⚠️ تم نقل هذا المسار إلى /waseet-sync/force (موحد)

// GET /api/orders/waseet-sync-status - حالة نظام المزامنة مع الوسيط
router.get('/waseet-sync-status', async (req, res) => {
  try {
    if (global.waseetSyncSystem) {
      const stats = global.waseetSyncSystem.getSystemStats();

      res.json({
        success: true,
        data: {
          isRunning: stats.isRunning,
          syncInterval: stats.syncInterval,
          syncIntervalMinutes: stats.syncIntervalMinutes,
          lastSyncTime: stats.lastSyncTime,
          nextSyncIn: stats.nextSyncIn,
          nextSyncInMinutes: stats.nextSyncIn ? Math.round(stats.nextSyncIn / 60000) : null,
          stats: {
            totalSyncs: stats.stats.totalSyncs,
            successfulSyncs: stats.stats.successfulSyncs,
            failedSyncs: stats.stats.failedSyncs,
            ordersUpdated: stats.stats.ordersUpdated,
            lastError: stats.stats.lastError
          }
        }
      });
    } else {
      res.json({
        success: true,
        data: {
          isRunning: false,
          message: 'النظام غير مهيأ'
        }
      });
    }

  } catch (error) {
    console.error('❌ خطأ في جلب حالة النظام:', error);
    res.status(500).json({
      success: false,
      error: 'خطأ في جلب حالة النظام'
    });
  }
});

// ===================================
// 🕒 مسارات الطلبات المجدولة (يجب أن تكون قبل /:id)
// ===================================

// GET /api/orders/scheduled/:id - جلب تفاصيل طلب مجدول (Secure & DTO)
router.get('/scheduled/:id', verifyAuth, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id; // 🔐 ID المستخدم من التوكن

    // 1️⃣ جلب الطلب مع التحقق من المالك
    const { data: order, error } = await supabase
      .from('scheduled_orders')
      .select('*, scheduled_order_items(*)')
      .eq('id', id)
      .single();

    if (error || !order) {
      return res.status(404).json({ success: false, error: 'الطلب غير موجود' });
    }

    // 🔐 2️⃣ التحقق الصارم من الملكية
    if (order.user_id !== userId) {
      logger.warn(`⛔ محاولة وصول غير مصرح لطلب مجدول: User ${userId} -> Order ${id}`);
      return res.status(403).json({ success: false, error: 'ليس لديك صلاحية للوصول لهذا الطلب' });
    }

    // 3️⃣ تجهيز DTO (Data Transfer Object)
    const orderDetails = {
      id: order.id,
      isScheduled: true,
      status: order.status,
      scheduledDate: order.scheduled_date,
      customer: {
        name: order.customer_name,
        phone: order.customer_phone,
        alternatePhone: order.customer_alternate_phone,
      },
      location: {
        province: order.customer_province || order.province, // نفضل customer_province إذا وجد
        city: order.customer_city || order.city,
      },
      notes: order.customer_notes,
      items: order.scheduled_order_items.map(item => ({
        id: item.id,
        productId: item.product_id,
        name: item.product_name,
        imageUrl: item.image_url,
        quantity: item.quantity,
        price: item.price,
        cost: item.cost_price,
        profit: item.profit,
        supplierId: item.supplier_id
      })),
      financial: {
        total: order.total,
        subtotal: order.subtotal,
        discount: order.discount,
        shipping: order.shipping_fee,
        profit: order.profit
      },
      dates: {
        created: order.created_at,
        updated: order.updated_at
      }
    };

    return apiSuccess(res, orderDetails);

  } catch (error) {
    return apiError(res, 'جلب تفاصيل الطلب المجدول', error);
  }
});

// PUT /api/orders/scheduled/:id - تحديث طلب مجدول (Secure & Validated)
router.put('/scheduled/:id', verifyAuth, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const body = req.body;

    // 1️⃣ التحقق من البيانات (Validation)
    const errors = [];
    if (!body.customerName?.trim()) errors.push('اسم العميل مطلوب');
    if (!body.primaryPhone?.trim()) errors.push('رقم الهاتف مطلوب');
    if (!body.province?.trim()) errors.push('المحافظة مطلوبة');
    if (!body.city?.trim()) errors.push('المدينة مطلوبة');
    if (!body.scheduledDate) errors.push('تاريخ الجدولة مطلوب');

    if (errors.length > 0) {
      return res.status(400).json({ success: false, error: errors.join(', ') });
    }

    // 2️⃣ التحقق من الملكية والحالة
    const { data: order, error: fetchError } = await supabase
      .from('scheduled_orders')
      .select('user_id, status')
      .eq('id', id)
      .single();

    if (fetchError || !order) {
      return res.status(404).json({ success: false, error: 'الطلب غير موجود' });
    }

    if (order.user_id !== userId) {
      logger.warn(`⛔ محاولة تعديل غير مصرح لطلب مجدول: User ${userId} -> Order ${id}`);
      return res.status(403).json({ success: false, error: 'ليس لديك صلاحية لتعديل هذا الطلب' });
    }

    // 3️⃣ التحديث الآمن (whitelist fields only)
    const updateData = {
      customer_name: body.customerName.trim(),
      customer_phone: body.primaryPhone.trim(),
      customer_alternate_phone: body.secondaryPhone?.trim() || null,
      province: body.province.trim(),
      city: body.city.trim(),
      customer_province: body.province.trim(),
      customer_city: body.city.trim(),
      customer_notes: body.notes?.trim() || null,
      scheduled_date: body.scheduledDate,
      updated_at: new Date().toISOString()
    };

    const { error: updateError } = await supabase
      .from('scheduled_orders')
      .update(updateData)
      .eq('id', id);

    if (updateError) throw updateError;

    logger.info(`✅ تم تحديث الطلب المجدول: ${id} بواسطة User: ${userId}`);
    return apiSuccess(res, null, 'تمت حفظ التغييرات بنجاح');

  } catch (error) {
    return apiError(res, 'تحديث الطلب المجدول', error);
  }
});

// ===================================
// GET /api/orders/user/:userPhone - جلب طلبات المستخدم بـ Pagination
// ===================================
router.get('/user/:userPhone', async (req, res) => {
  try {
    const { userPhone } = req.params;
    const { page = 0, limit = 10, statusFilter } = req.query;

    if (!userPhone) {
      return res.status(400).json({
        success: false,
        error: 'رقم الهاتف مطلوب'
      });
    }

    const offset = parseInt(page) * parseInt(limit);

    // بناء الاستعلام الأساسي
    let query = supabase
      .from('orders')
      .select(
        `
        *,
        order_items (
          id,
          product_id,
          product_name,
          product_image,
          wholesale_price,
          customer_price,
          quantity,
          total_price,
          profit_per_item
        )
        `,
        { count: 'exact' }
      )
      .eq('user_phone', userPhone);

    // ✅ فلترة حسب الحالة
    if (statusFilter) {
      // ✅ تعريف مجموعات الحالات لكل فلتر (متطابقة 100% مع /counts endpoint)
      const statusGroups = {
        'processing': [
          'تم تغيير محافظة الزبون',
          'تغيير المندوب',
          'لا يرد',
          'لا يرد بعد الاتفاق',
          'مغلق',
          'مغلق بعد الاتفاق',
          'الرقم غير معرف',
          'الرقم غير داخل في الخدمة',
          'لا يمكن الاتصال بالرقم',
          'مؤجل',
          'مؤجل لحين اعادة الطلب لاحقا',
          'مفصول عن الخدمة',
          'طلب مكرر',
          'مستلم مسبقا',
          'العنوان غير دقيق',
          'لم يطلب',
          'حظر المندوب'
        ],
        'active': ['active', 'فعال', 'نشط'],
        'in_delivery': [
          'قيد التوصيل الى الزبون (في عهدة المندوب)',
          'تم الاستلام من قبل المندوب'
        ],
        'delivered': ['تم التسليم للزبون', 'delivered'],
        'cancelled': [
          'الغاء الطلب',
          'رفض الطلب',
          'cancelled'
        ]
      };

      const statuses = statusGroups[statusFilter];
      if (statuses && statuses.length > 0) {
        // ✅ استخدام .in() للبحث في كلا العمودين
        // بناء قائمة الحالات بشكل صحيح للـ Supabase
        const statusArray = statuses.map(s => `"${s.replace(/"/g, '\\"')}"`).join(',');
        query = query.or(`status.in.(${statusArray}),waseet_status_text.in.(${statusArray})`);
      }
    }

    // ترتيب وتحديد النطاق
    query = query
      .order('created_at', { ascending: false })
      .range(offset, offset + parseInt(limit) - 1);

    const { data, error, count } = await query;

    if (error) {
      console.error('❌ خطأ في جلب طلبات المستخدم:', error);
      return res.status(500).json({
        success: false,
        error: 'خطأ في جلب الطلبات'
      });
    }

    // ✅ تحويل صيغة التاريخ إلى ISO 8601 لضمان التوافق مع Frontend
    const formattedData = (data || []).map(order => ({
      ...order,
      created_at: order.created_at ? new Date(order.created_at).toISOString() : null,
      updated_at: order.updated_at ? new Date(order.updated_at).toISOString() : null,
      status_updated_at: order.status_updated_at ? new Date(order.status_updated_at).toISOString() : null,
    }));

    res.json({
      success: true,
      data: formattedData,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: count || 0,
        hasMore: offset + parseInt(limit) < (count || 0)
      }
    });

  } catch (error) {
    console.error('❌ خطأ في API جلب طلبات المستخدم:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ===================================
// GET /api/orders/user/:userPhone/counts - جلب عدادات الطلبات
// ===================================
router.get('/user/:userPhone/counts', async (req, res) => {
  try {
    const { userPhone } = req.params;

    if (!userPhone) {
      return res.status(400).json({
        success: false,
        error: 'رقم الهاتف مطلوب'
      });
    }

    // ✅ استعلام واحد لجلب جميع الطلبات (مع status و waseet_status_text)
    const { data: allOrders, error } = await supabase
      .from('orders')
      .select('status, waseet_status_text')
      .eq('user_phone', userPhone);

    if (error) {
      console.error('❌ خطأ في جلب الطلبات:', error);
      return res.status(500).json({
        success: false,
        error: 'خطأ في جلب العدادات'
      });
    }

    // ✅ حالات المعالجة (جميع الحالات ما عدا: نشط، قيد التوصيل، تم التسليم، ملغي، مجدول)
    const processingStatuses = [
      'تم تغيير محافظة الزبون',
      'تغيير المندوب',
      'لا يرد',
      'لا يرد بعد الاتفاق',
      'مغلق',
      'مغلق بعد الاتفاق',
      'الرقم غير معرف',
      'الرقم غير داخل في الخدمة',
      'لا يمكن الاتصال بالرقم',
      'مؤجل',
      'مؤجل لحين اعادة الطلب لاحقا',
      'مفصول عن الخدمة',
      'طلب مكرر',
      'مستلم مسبقا',
      'العنوان غير دقيق',
      'لم يطلب',
      'حظر المندوب'
    ];

    const activeStatuses = ['active', 'فعال', 'نشط'];
    const inDeliveryStatuses = [
      'قيد التوصيل الى الزبون (في عهدة المندوب)',
      'تم الاستلام من قبل المندوب'
    ];
    const deliveredStatuses = ['تم التسليم للزبون', 'delivered'];

    // ✅ حالات الملغي (فقط الغاء الطلب و رفض الطلب)
    const cancelledStatuses = [
      'الغاء الطلب',
      'رفض الطلب',
      'cancelled'
    ];

    // ✅ حساب العدادات (البحث في كلا العمودين: status و waseet_status_text)
    const counts = {
      all: allOrders.length,
      processing: allOrders.filter(o =>
        processingStatuses.includes(o.status) || processingStatuses.includes(o.waseet_status_text)
      ).length,
      active: allOrders.filter(o =>
        activeStatuses.includes(o.status) || activeStatuses.includes(o.waseet_status_text)
      ).length,
      in_delivery: allOrders.filter(o =>
        inDeliveryStatuses.includes(o.status) || inDeliveryStatuses.includes(o.waseet_status_text)
      ).length,
      delivered: allOrders.filter(o =>
        deliveredStatuses.includes(o.status) || deliveredStatuses.includes(o.waseet_status_text)
      ).length,
      cancelled: allOrders.filter(o =>
        cancelledStatuses.includes(o.status) || cancelledStatuses.includes(o.waseet_status_text)
      ).length
    };

    // جلب عدد الطلبات المجدولة
    // ✅ استخدام طريقة آمنة بدون head: true
    const { count: scheduledCount, error: scheduledError } = await supabase
      .from('scheduled_orders')
      .select('id', { count: 'exact' })
      .eq('user_phone', userPhone)
      .eq('is_converted', false);

    if (scheduledError) {
      console.error('❌ خطأ في جلب عدد الطلبات المجدولة:', scheduledError);
      counts.scheduled = 0;
    } else {
      counts.scheduled = scheduledCount || 0;
    }

    res.json({
      success: true,
      data: counts
    });

  } catch (error) {
    console.error('❌ خطأ في API عدادات الطلبات:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ===================================
// GET /api/orders/scheduled-orders/user/:userPhone - جلب الطلبات المجدولة
// ===================================
router.get('/scheduled-orders/user/:userPhone', async (req, res) => {
  try {
    const { userPhone } = req.params;
    const { page = 0, limit = 10 } = req.query;

    if (!userPhone) {
      return res.status(400).json({
        success: false,
        error: 'رقم الهاتف مطلوب'
      });
    }

    const offset = parseInt(page) * parseInt(limit);

    // جلب الطلبات المجدولة مع العناصر
    const { data, error, count } = await supabase
      .from('scheduled_orders')
      .select(
        `
        *,
        scheduled_order_items (
          id,
          product_name,
          quantity,
          price,
          notes,
          product_id,
          product_image
        )
        `,
        { count: 'exact' }
      )
      .eq('user_phone', userPhone)
      .eq('is_converted', false)
      .order('scheduled_date', { ascending: true })
      .range(offset, offset + parseInt(limit) - 1);

    if (error) {
      console.error('❌ خطأ في جلب الطلبات المجدولة:', error);
      return res.status(500).json({
        success: false,
        error: 'خطأ في جلب الطلبات المجدولة'
      });
    }

    res.json({
      success: true,
      data: data || [],
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: count || 0,
        hasMore: offset + parseInt(limit) < (count || 0)
      }
    });

  } catch (error) {
    console.error('❌ خطأ في API الطلبات المجدولة:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ===================================
// DELETE /api/orders/scheduled-orders/:id - حذف طلب مجدول
// ===================================
router.delete('/scheduled-orders/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { userPhone } = req.query;

    if (!id || !userPhone) {
      return res.status(400).json({
        success: false,
        error: 'معرف الطلب ورقم الهاتف مطلوبان'
      });
    }

    // التحقق من أن الطلب يخص المستخدم
    const { data: order, error: fetchError } = await supabase
      .from('scheduled_orders')
      .select('user_phone')
      .eq('id', id)
      .single();

    if (fetchError || !order) {
      return res.status(404).json({
        success: false,
        error: 'الطلب المجدول غير موجود'
      });
    }

    if (order.user_phone !== userPhone) {
      return res.status(403).json({
        success: false,
        error: 'غير مصرح لك بحذف هذا الطلب'
      });
    }

    // حذف الطلب المجدول
    const { error: deleteError } = await supabase
      .from('scheduled_orders')
      .delete()
      .eq('id', id);

    if (deleteError) {
      console.error('❌ خطأ في حذف الطلب المجدول:', deleteError);
      return res.status(500).json({
        success: false,
        error: 'خطأ في حذف الطلب المجدول'
      });
    }

    res.json({
      success: true,
      message: 'تم حذف الطلب المجدول بنجاح'
    });

  } catch (error) {
    console.error('❌ خطأ في API حذف الطلب المجدول:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ===================================
// PATCH /api/orders/:id - تعديل طلب
// ===================================
router.patch('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { userPhone, updates } = req.body;

    if (!id || !userPhone || !updates) {
      return res.status(400).json({
        success: false,
        error: 'معرف الطلب ورقم الهاتف والتحديثات مطلوبة'
      });
    }

    // التحقق من أن الطلب يخص المستخدم
    const { data: order, error: fetchError } = await supabase
      .from('orders')
      .select('user_phone')
      .eq('id', id)
      .single();

    if (fetchError || !order) {
      return res.status(404).json({
        success: false,
        error: 'الطلب غير موجود'
      });
    }

    if (order.user_phone !== userPhone) {
      return res.status(403).json({
        success: false,
        error: 'غير مصرح لك بتعديل هذا الطلب'
      });
    }

    // تعديل الطلب
    const { data, error: updateError } = await supabase
      .from('orders')
      .update(updates)
      .eq('id', id)
      .select()
      .single();

    if (updateError) {
      console.error('❌ خطأ في تعديل الطلب:', updateError);
      return res.status(500).json({
        success: false,
        error: 'خطأ في تعديل الطلب'
      });
    }

    res.json({
      success: true,
      message: 'تم تعديل الطلب بنجاح',
      data: data
    });

  } catch (error) {
    console.error('❌ خطأ في API تعديل الطلب:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ===================================
// DELETE /api/orders/:id - حذف طلب
// ===================================
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { userPhone } = req.query;

    if (!id || !userPhone) {
      return res.status(400).json({
        success: false,
        error: 'معرف الطلب ورقم الهاتف مطلوبان'
      });
    }

    // التحقق من أن الطلب يخص المستخدم
    const { data: order, error: fetchError } = await supabase
      .from('orders')
      .select('user_phone')
      .eq('id', id)
      .single();

    if (fetchError || !order) {
      return res.status(404).json({
        success: false,
        error: 'الطلب غير موجود'
      });
    }

    if (order.user_phone !== userPhone) {
      return res.status(403).json({
        success: false,
        error: 'غير مصرح لك بحذف هذا الطلب'
      });
    }

    // حذف الطلب
    const { error: deleteError } = await supabase
      .from('orders')
      .delete()
      .eq('id', id);

    if (deleteError) {
      console.error('❌ خطأ في حذف الطلب:', deleteError);
      return res.status(500).json({
        success: false,
        error: 'خطأ في حذف الطلب'
      });
    }

    res.json({
      success: true,
      message: 'تم حذف الطلب بنجاح'
    });

  } catch (error) {
    console.error('❌ خطأ في API حذف الطلب:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ===================================
// PUT /api/orders/:id/status - تحديث حالة الطلب
// ===================================
router.put('/:id/status', async (req, res) => {
  const requestId = `REQ_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  const startTime = Date.now();

  try {
    const { id } = req.params;
    const { status, notes, changedBy = 'admin' } = req.body;

    console.log('\n' + '='.repeat(100));
    console.log(`🚀 [${requestId}] بدء تحديث حالة الطلب`);
    console.log(`⏰ الوقت: ${new Date().toISOString()}`);
    console.log(`🆔 معرف الطلب: ${id}`);
    console.log(`📊 الحالة الجديدة: "${status}"`);
    console.log(`📝 السبب: ${notes || 'بدون سبب'}`);
    console.log(`👤 تم التغيير بواسطة: ${changedBy}`);
    console.log('='.repeat(100));

    // التحقق من البيانات المطلوبة
    if (!status) {
      console.error(`❌ [${requestId}] الحالة الجديدة مطلوبة`);
      return res.status(400).json({
        success: false,
        error: 'الحالة الجديدة مطلوبة'
      });
    }

    // تحويل الحالات المختلفة إلى الحالة الصحيحة الوحيدة للوسيط
    function normalizeStatus(status) {

      // الحالة الوحيدة المؤهلة للإرسال للوسيط:
      // ID: 3 - "قيد التوصيل الى الزبون (في عهدة المندوب)"

      const statusMap = {
        // تحويل الأرقام إلى النصوص الصحيحة (من AdvancedOrderDetailsPage)
        '3': 'قيد التوصيل الى الزبون (في عهدة المندوب)',
        '4': 'delivered',
        '24': 'تم تغيير محافظة الزبون',
        '42': 'تغيير المندوب',
        '25': 'لا يرد',
        '26': 'لا يرد بعد الاتفاق',
        '27': 'مغلق',
        '28': 'مغلق بعد الاتفاق',
        '36': 'الرقم غير معرف',
        '37': 'الرقم غير داخل في الخدمة',
        '41': 'لا يمكن الاتصال بالرقم',
        '29': 'مؤجل',
        '30': 'مؤجل لحين اعادة الطلب لاحقا',
        '31': 'الغاء الطلب',
        '32': 'رفض الطلب',
        '33': 'مفصول عن الخدمة',
        '34': 'طلب مكرر',
        '35': 'مستلم مسبقا',
        '38': 'العنوان غير دقيق',
        '39': 'لم يطلب',
        '40': 'حظر المندوب',
        '43': 'تم الارجاع الى التاجر',

        // الحالات النصية تبقى كما هي
        'قيد التوصيل الى الزبون (في عهدة المندوب)': 'قيد التوصيل الى الزبون (في عهدة المندوب)',
        'active': 'active',
        'cancelled': 'cancelled',
        'delivered': 'delivered',
        'in_delivery': 'in_delivery'
      };

      const converted = statusMap[status] || status;
      console.log(`   📝 تحويل الحالة: "${status}" → "${converted}"`);

      return converted;
    }

    // Helper: اكتشاف حالة "قيد التوصيل" بشكل مرن (يدعم اختلافات الكتابة)
    function isInDeliveryStatus(s) {
      const t = (s || '').toString().toLowerCase();
      // عربي: نكتفي باحتواء "قيد التوصيل" أياً كانت باقي الصيغة
      // إنجليزي: in_delivery
      return t.includes('in_delivery') || t.includes('قيد التوصيل');
    }

    // Helper: اكتشاف حالة "تم التسليم" بشكل مرن (يدعم اختلافات الكتابة)
    function isDeliveredStatus(s) {
      const t = (s || '').toString().toLowerCase();
      // إنجليزي: delivered
      // عربي: تم التسليم للزبون / تم التسليم
      return t.includes('delivered') || t.includes('تم التسليم');
    }


    // تطبيق التحويل على الحالة
    const normalizedStatus = normalizeStatus(status);
    console.log(`✅ [${requestId}] الحالة المحولة: "${normalizedStatus}"`);

    // التحقق من وجود الطلب
    console.log(`🔍 [${requestId}] البحث عن الطلب في قاعدة البيانات...`);
    const { data: existingOrder, error: fetchError } = await supabase
      .from('orders')
      .select('id, status, customer_name, customer_id, user_phone, profit, profit_amount')
      .eq('id', id)
      .single();

    if (fetchError || !existingOrder) {
      console.error(`❌ [${requestId}] الطلب غير موجود:`, fetchError);
      return res.status(404).json({
        success: false,
        error: 'الطلب غير موجود'
      });
    }

    const oldStatus = existingOrder.status;
    console.log(`✅ [${requestId}] تم العثور على الطلب`);
    console.log(`   📋 الحالة الحالية: "${oldStatus}"`);
    console.log(`   📋 الحالة الجديدة: "${normalizedStatus}"`);
    console.log(`   📱 رقم المستخدم: ${existingOrder.user_phone}`);


    // 🛡️ Profit / Delivered Guards (Monitoring ONLY):
    // هذه الحراس الآن للقراءة والتسجيل فقط، بدون أي تعديل على أرباح المستخدم.
    // نظام الأرباح بالكامل يُدار داخل قاعدة البيانات بواسطة smart_profit_manager.

    // تحديث حالة الطلب (استخدام الحالة المحولة) — مع تجنب أي UPDATE إذا لم تتغير الحالة
    let __statusUpdated = false;
    if (oldStatus !== normalizedStatus) {
      console.log(`🔄 [${requestId}] بدء تحديث حالة الطلب في قاعدة البيانات...`);
      const updateStartTime = Date.now();

      // ✅ تحديث آمن: لا نقوم بالتحديث إذا كانت القيمة الحالية مساوية لتجنّب تشغيل تريجر الأرباح مرتين
      let __q = supabase
        .from('orders')
        .update({
          status: normalizedStatus,
          updated_at: new Date().toISOString()
        })
        .eq('id', id)
        .neq('status', normalizedStatus);
      const { error: updateError } = await __q;

      const updateDuration = Date.now() - updateStartTime;
      console.log(`⏱️ [${requestId}] مدة التحديث: ${updateDuration}ms`);

      if (updateError) {
        console.error(`❌ [${requestId}] خطأ في تحديث الطلب:`, updateError);
        return res.status(500).json({
          success: false,
          error: 'فشل في تحديث حالة الطلب'
        });
      }

      console.log(`✅ [${requestId}] تم تحديث حالة الطلب بنجاح`);
      __statusUpdated = true;
    } else {
      console.log(`ℹ️ [${requestId}] الحالة الجديدة مطابقة للحالية - تخطّي تحديث سجل الطلب لتجنب أحداث UPDATE إضافية`);
    }
    console.log(`   ⏱️ المدة الإجمالية حتى الآن: ${Date.now() - startTime}ms`);

    // إضافة سجل في تاريخ الحالات (اختياري - لا يوقف العملية إذا فشل)
    if (__statusUpdated) {
      console.log(`📝 [${requestId}] بدء إضافة سجل التاريخ...`);
      try {
        const historyStartTime = Date.now();
        await supabase
          .from('order_status_history')
          .insert({
            order_id: id,
            old_status: oldStatus,
            new_status: normalizedStatus,
            changed_by: changedBy,
            change_reason: notes || 'تم تحديث الحالة من لوحة التحكم',
            created_at: new Date().toISOString()
          });

        const historyDuration = Date.now() - historyStartTime;
        console.log(`✅ [${requestId}] تم إضافة سجل التاريخ بنجاح (${historyDuration}ms)`);
      } catch (historyError) {
        console.warn(`⚠️ [${requestId}] تحذير: فشل في حفظ سجل التاريخ:`, historyError.message);
      }
    } else {
      console.log(`ℹ️ [${requestId}] تخطّي إضافة سجل التاريخ لأن الحالة لم تتغير`);
    }

    // إضافة ملاحظة إذا كانت متوفرة
    if (notes && notes.trim()) {
      console.log(`📝 [${requestId}] بدء إضافة الملاحظة...`);
      try {
        const noteStartTime = Date.now();
        await supabase
          .from('order_notes')
          .insert({
            order_id: id,
            content: `تم تحديث الحالة إلى: ${normalizedStatus} - ${notes}`,
            type: 'status_change',
            is_internal: true,
            created_by: changedBy,
            created_at: new Date().toISOString()
          });

        const noteDuration = Date.now() - noteStartTime;
        console.log(`✅ [${requestId}] تم إضافة الملاحظة بنجاح (${noteDuration}ms)`);

      } catch (noteError) {
        console.warn(`⚠️ [${requestId}] تحذير: فشل في إضافة الملاحظة:`, noteError.message);
      }
    }


    // 🔔 **ملاحظة مهمة:** الإشعارات تُرسل الآن من مكان واحد فقط:
    // 1. من integrated_waseet_sync.js عند المزامنة التلقائية مع الوسيط
    // 2. هذا يضمن عدم تكرار الإشعارات
    // 3. لا نرسل إشعار هنا لتجنب التكرار

    // 🚀 إرسال الطلب لشركة الوسيط عند تغيير الحالة إلى "قيد التوصيل"

    // الحالة الوحيدة المؤهلة لإرسال الطلب للوسيط
    // ID: 3 - "قيد التوصيل الى الزبون (في عهدة المندوب)"
    // اكتشاف حالة الإرسال للوسيط بشكل مرن
    if (isInDeliveryStatus(normalizedStatus)) {
      console.log(`🚀 [${requestId}] الحالة الجديدة تتطلب إرسال للوسيط`);

      try {
        // التحقق من أن الطلب لم يتم إرساله مسبقاً
        console.log(`🔍 [${requestId}] بدء فحص حالة الوسيط...`);
        const checkStartTime = Date.now();

        const { data: currentOrder, error: checkError } = await supabase
          .from('orders')
          .select('waseet_order_id, waseet_status')
          .eq('id', id)
          .single();

        const checkDuration = Date.now() - checkStartTime;
        console.log(`✅ [${requestId}] انتهى فحص حالة الوسيط (${checkDuration}ms)`);

        if (checkError) {
          console.error(`❌ [${requestId}] خطأ في فحص حالة الوسيط:`, checkError);
        } else {
          console.log(`📊 [${requestId}] waseet_order_id: ${currentOrder?.waseet_order_id || 'NULL'}`);

          if (currentOrder.waseet_order_id) {
            // الطلب تم إرساله مسبقاً
            console.log(`ℹ️ [${requestId}] الطلب تم إرساله مسبقاً للوسيط`);
          } else {
            console.log(`📤 [${requestId}] الطلب لم يتم إرساله بعد - سيتم الإرسال الآن`);

            // التحقق من وجود خدمة المزامنة المهيأة

            if (!global.orderSyncService) {
              console.error(`❌ [${requestId}] خدمة المزامنة غير متاحة - محاولة إنشاء خدمة جديدة...`);

              try {
                console.log(`🔧 [${requestId}] محاولة إنشاء خدمة المزامنة...`);
                const OrderSyncService = require('../services/order_sync_service');
                global.orderSyncService = new OrderSyncService();
                console.log(`✅ [${requestId}] تم إنشاء خدمة المزامنة بنجاح`);

              } catch (serviceError) {
                console.error(`❌ [${requestId}] فشل في إنشاء خدمة المزامنة:`, serviceError.message);

                // تحديث الطلب بحالة الخطأ
                console.log(`📝 [${requestId}] تحديث الطلب بحالة الخطأ...`);
                await supabase
                  .from('orders')
                  .update({
                    waseet_status: 'في انتظار الإرسال للوسيط',
                    waseet_data: JSON.stringify({
                      error: `خطأ في خدمة المزامنة: ${serviceError.message}`,
                      retry_needed: true,
                      last_attempt: new Date().toISOString()
                    }),
                    updated_at: new Date().toISOString()
                  })
                  .eq('id', id);

                console.log(`✅ [${requestId}] تم تحديث الطلب بحالة الخطأ`);

                // لا تتوقف هنا - استمر لإرسال الاستجابة

              }
            }

            // إرسال الطلب لشركة الوسيط (فقط إذا كانت الخدمة متاحة)
            if (global.orderSyncService) {
              console.log(`📤 [${requestId}] بدء إرسال الطلب للوسيط...`);
              const waseetStartTime = Date.now();

              const waseetResult = await global.orderSyncService.sendOrderToWaseet(id);
              const waseetDuration = Date.now() - waseetStartTime;

              console.log(`📊 [${requestId}] نتيجة الإرسال (${waseetDuration}ms):`, waseetResult);

              if (waseetResult && waseetResult.success) {
                console.log(`✅ [${requestId}] تم إرسال الطلب للوسيط بنجاح`);

                // ✅ لا حاجة لتحديث الطلب هنا - sendOrderToWaseet يحدثه بالفعل
                console.log(`ℹ️ [${requestId}] تم تحديث الطلب بمعلومات الوسيط من sendOrderToWaseet`);

              } else {
                console.error(`❌ [${requestId}] فشل في إرسال الطلب للوسيط:`, waseetResult?.error);

                // تحديث الطلب بحالة "في انتظار الإرسال للوسيط"
                console.log(`📝 [${requestId}] تحديث الطلب بحالة الفشل...`);
                await supabase
                  .from('orders')
                  .update({
                    waseet_status: 'في انتظار الإرسال للوسيط',
                    waseet_data: JSON.stringify({
                      error: waseetResult?.error || 'فشل في الإرسال',
                      retry_needed: true,
                      last_attempt: new Date().toISOString()
                    }),
                    updated_at: new Date().toISOString()
                  })
                  .eq('id', id);

                console.log(`✅ [${requestId}] تم تحديث الطلب بحالة الفشل`);
              }
            } else {
              console.warn(`⚠️ [${requestId}] خدمة المزامنة غير متاحة`);

              // تحديث الطلب بحالة "في انتظار الإرسال للوسيط"
              console.log(`📝 [${requestId}] تحديث الطلب بحالة عدم توفر الخدمة...`);
              await supabase
                .from('orders')
                .update({
                  waseet_status: 'في انتظار الإرسال للوسيط',
                  waseet_data: JSON.stringify({
                    error: 'خدمة المزامنة غير متاحة',
                    retry_needed: true,
                    last_attempt: new Date().toISOString()
                  }),
                  updated_at: new Date().toISOString()
                })
                .eq('id', id);

              console.log(`✅ [${requestId}] تم تحديث الطلب بحالة عدم توفر الخدمة`);
            }
          }
        }

      } catch (waseetError) {
        console.error(`❌ [${requestId}] خطأ في إرسال الطلب ${id} لشركة الوسيط:`, waseetError);

        // تحديث الطلب بحالة الخطأ
        try {
          console.log(`📝 [${requestId}] تحديث الطلب بحالة الخطأ...`);
          await supabase
            .from('orders')
            .update({
              waseet_status: 'في انتظار الإرسال للوسيط',
              waseet_data: JSON.stringify({
                error: `خطأ في الإرسال: ${waseetError.message}`,
                retry_needed: true,
                last_attempt: new Date().toISOString()
              }),
              updated_at: new Date().toISOString()
            })
            .eq('id', id);

          console.log(`✅ [${requestId}] تم تحديث الطلب بحالة الخطأ`);
        } catch (updateError) {
          console.error(`❌ [${requestId}] خطأ في تحديث حالة الخطأ:`, updateError);
        }
      }
    } else {
      console.log(`ℹ️ [${requestId}] الحالة الجديدة ليست من حالات الإرسال للوسيط`);
    }



    const totalDuration = Date.now() - startTime;
    console.log('\n' + '='.repeat(100));
    console.log(`✅ [${requestId}] انتهى تحديث حالة الطلب بنجاح`);
    console.log(`⏱️ المدة الإجمالية: ${totalDuration}ms`);
    console.log(`📊 الحالة: "${oldStatus}" → "${normalizedStatus}"`);
    console.log('='.repeat(100) + '\n');

    res.json({
      success: true,
      message: 'تم تحديث حالة الطلب بنجاح',
      data: {
        orderId: id,
        oldStatus: oldStatus,
        newStatus: status,
        updatedAt: new Date().toISOString()
      }
    });

  } catch (error) {
    const totalDuration = Date.now() - startTime;
    console.error('\n' + '='.repeat(100));
    console.error(`❌ [${requestId}] خطأ في API تحديث حالة الطلب`);
    console.error(`⏰ المدة الإجمالية: ${totalDuration}ms`);
    console.error(`📋 الخطأ: ${error.message}`);
    console.error(`📚 Stack: ${error.stack}`);
    console.error('='.repeat(100) + '\n');

    res.status(500).json({
      success: false,
      error: error.message,
      requestId: requestId
    });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// 🧮 POST /api/orders/calculate - حساب ملخص الطلب (بدون إنشاء)
// ═══════════════════════════════════════════════════════════════════════════
// ✅ للمعاينة فقط - يحسب كل شيء ويرجعه لـ Flutter للعرض
// ✅ لا يحفظ شيء في قاعدة البيانات
// ═══════════════════════════════════════════════════════════════════════════
router.post('/calculate', async (req, res) => {
  const startTime = Date.now();
  logger.info('🧮 ══════════════════════════════════════════');
  logger.info('🧮 بدء حساب ملخص الطلب (Calculate Only)');

  try {
    const {
      items,                    // [{product_id, quantity, customer_price}]
      province,                 // اسم المحافظة
      province_id,              // معرف المحافظة (اختياري)
      city,                     // اسم المدينة (اختياري)
      city_id,                  // معرف المدينة (اختياري)
      slider_delivery_fee,      // رسوم التوصيل التي اختارها التاجر (السلايدر)
    } = req.body;

    // ═══════════════════════════════════════════
    // 1️⃣ التحقق من البيانات المطلوبة
    // ═══════════════════════════════════════════
    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'يجب إضافة منتج واحد على الأقل',
        validated: false
      });
    }

    if (!province?.trim() && !province_id) {
      return res.status(400).json({
        success: false,
        error: 'المحافظة مطلوبة',
        validated: false
      });
    }

    logger.info(`📍 المحافظة: ${province || province_id}`);
    logger.info(`📦 عدد المنتجات: ${items.length}`);
    logger.info(`🎚️ السلايدر: ${slider_delivery_fee}`);

    // ═══════════════════════════════════════════
    // 2️⃣ جلب رسوم التوصيل من جدول المحافظات
    // ═══════════════════════════════════════════
    let baseDeliveryFee = 5000; // القيمة الافتراضية
    let provinceName = province;

    // محاولة جلب رسوم التوصيل من قاعدة البيانات
    let provinceQuery = supabase.from('provinces').select('id, name, delivery_fee');
    if (province_id) {
      provinceQuery = provinceQuery.eq('id', province_id);
    } else if (province) {
      provinceQuery = provinceQuery.ilike('name', `%${province}%`);
    }

    const { data: provinceData, error: provinceError } = await provinceQuery.limit(1).maybeSingle();

    if (provinceData) {
      baseDeliveryFee = provinceData.delivery_fee || 5000;
      provinceName = provinceData.name;
      logger.info(`✅ المحافظة: ${provinceName} - التوصيل: ${baseDeliveryFee}`);
    } else {
      logger.warn(`⚠️ لم يتم العثور على المحافظة - استخدام القيمة الافتراضية: ${baseDeliveryFee}`);
    }

    // ═══════════════════════════════════════════
    // 3️⃣ جلب أسعار المنتجات من قاعدة البيانات
    // ═══════════════════════════════════════════
    const productIds = items.map(item => item.product_id).filter(Boolean);

    const { data: products, error: productsError } = await supabase
      .from('products')
      .select('id, name, wholesale_price, retail_price, stock_quantity')
      .in('id', productIds);

    if (productsError) {
      logger.error('❌ خطأ في جلب المنتجات:', productsError.message);
      return res.status(500).json({
        success: false,
        error: 'فشل في جلب بيانات المنتجات',
        validated: false
      });
    }

    // إنشاء خريطة للمنتجات
    const productMap = new Map(products.map(p => [p.id, p]));

    // ═══════════════════════════════════════════
    // 4️⃣ حساب القيم لكل منتج
    // ═══════════════════════════════════════════
    let subtotal = 0;           // المجموع الفرعي (سعر الجملة)
    let customerTotal = 0;      // مجموع سعر العميل
    let profitInitial = 0;      // الربح الأولي
    const stockErrors = [];     // أخطاء المخزون
    const calculatedItems = []; // العناصر المحسوبة

    for (const item of items) {
      const product = productMap.get(item.product_id);
      const quantity = parseInt(item.quantity) || 1;
      const customerPrice = parseInt(item.customer_price) || 0;

      if (!product) {
        logger.warn(`⚠️ منتج غير موجود: ${item.product_id}`);
        continue;
      }

      // التحقق من المخزون
      if (product.stock_quantity !== null && product.stock_quantity < quantity) {
        stockErrors.push({
          product_id: product.id,
          product_name: product.name,
          requested: quantity,
          available: product.stock_quantity
        });
      }

      // الحسابات
      const wholesalePrice = product.wholesale_price || 0;
      const itemSubtotal = wholesalePrice * quantity;
      const itemCustomerTotal = customerPrice * quantity;
      const itemProfit = (customerPrice - wholesalePrice) * quantity;

      subtotal += itemSubtotal;
      customerTotal += itemCustomerTotal;
      profitInitial += itemProfit;

      calculatedItems.push({
        product_id: product.id,
        product_name: product.name,
        quantity: quantity,
        wholesale_price: wholesalePrice,
        customer_price: customerPrice,
        item_subtotal: itemSubtotal,
        item_customer_total: itemCustomerTotal,
        item_profit: itemProfit,
        stock_available: product.stock_quantity
      });
    }

    // ═══════════════════════════════════════════
    // 5️⃣ حساب رسوم التوصيل والخصم
    // ═══════════════════════════════════════════
    // السلايدر يحدد كم يدفع العميل للتوصيل
    // الباقي يخصم من ربح التاجر
    const sliderFee = parseInt(slider_delivery_fee) || 0;
    const deliveryPaidFromProfit = Math.max(0, baseDeliveryFee - sliderFee);

    // ═══════════════════════════════════════════
    // 6️⃣ حساب الربح النهائي (بعد خصم التوصيل)
    // ═══════════════════════════════════════════
    let profitFinal = profitInitial - deliveryPaidFromProfit;

    // منع الربح السلبي
    if (profitFinal < 0) {
      logger.warn(`⚠️ الربح سالب! الأولي: ${profitInitial}, الخصم: ${deliveryPaidFromProfit}`);
      profitFinal = 0;
    }

    // ═══════════════════════════════════════════
    // 7️⃣ حساب المجاميع النهائية
    // ═══════════════════════════════════════════
    // total_customer = ما يدفعه العميل = سعر المنتجات + رسوم التوصيل للعميل
    const totalCustomer = customerTotal + sliderFee;

    // total_waseet = المبلغ الكامل = سعر المنتجات + رسوم التوصيل الأساسية
    const totalWaseet = customerTotal + baseDeliveryFee;

    // ═══════════════════════════════════════════
    // 8️⃣ تحديد حالة التحقق
    // ═══════════════════════════════════════════
    const validated = stockErrors.length === 0 && profitFinal >= 0;

    const duration = Date.now() - startTime;
    logger.info('🧮 ══════════════════════════════════════════');
    logger.info(`✅ تم حساب الملخص في ${duration}ms`);
    logger.info(`   المجموع الفرعي: ${subtotal}`);
    logger.info(`   مجموع العميل: ${customerTotal}`);
    logger.info(`   رسوم التوصيل الأساسية: ${baseDeliveryFee}`);
    logger.info(`   السلايدر: ${sliderFee}`);
    logger.info(`   الخصم من الربح: ${deliveryPaidFromProfit}`);
    logger.info(`   الربح الأولي: ${profitInitial}`);
    logger.info(`   الربح النهائي: ${profitFinal}`);
    logger.info('🧮 ══════════════════════════════════════════');

    return res.json({
      success: true,
      validated: validated,

      // القيم المحسوبة
      subtotal: subtotal,
      customer_total: customerTotal,
      delivery_fee: sliderFee,               // ما يدفعه العميل
      base_delivery_fee: baseDeliveryFee,    // رسوم التوصيل الأساسية
      delivery_paid_from_profit: deliveryPaidFromProfit,
      profit_initial: profitInitial,
      profit_final: profitFinal,
      total_customer: totalCustomer,
      total_waseet: totalWaseet,

      // بيانات إضافية
      province_name: provinceName,
      items_count: calculatedItems.length,
      items: calculatedItems,

      // أخطاء (إن وجدت)
      stock_errors: stockErrors.length > 0 ? stockErrors : null,
      warnings: profitFinal === 0 && profitInitial > 0 ? ['الربح صفر بسبب خصم التوصيل'] : null,

      // معلومات الأداء
      duration: `${duration}ms`
    });

  } catch (error) {
    logger.error('❌ خطأ في حساب الملخص:', error.message);
    logger.error('Stack:', error.stack);
    return res.status(500).json({
      success: false,
      error: 'حدث خطأ في حساب الملخص',
      validated: false
    });
  }
});

// ===================================
// 🔐 POST /api/orders - إنشاء طلب جديد (نظام آمن 100%)
// ===================================
// ✅ Flutter يرسل فقط: customer_name, phone, province_id, city_id, items [{product_id, quantity, customer_price}]
// ✅ Backend يحسب: الأسعار الحقيقية، الربح، التوصيل، المجموع، التحقق من المخزون
// ❌ لا نثق بأي حسابات من Flutter
// ===================================
router.post('/', async (req, res) => {
  const startTime = Date.now();
  logger.info('🔐 ══════════════════════════════════════════');
  logger.info('🔐 بدء إنشاء طلب آمن (Server-Side Calculations)');

  // ✅ تسجيل مفصل لمحتوى الطلب للتشخيص
  logger.info('📥 ═══ بيانات الطلب الواردة ═══');
  logger.info(`📥 Content-Type: ${req.get('Content-Type')}`);
  logger.info(`📥 Body type: ${typeof req.body}`);
  logger.info(`📥 Body keys: ${req.body ? Object.keys(req.body).join(', ') : 'NO BODY'}`);
  logger.info(`📥 Body (first 500 chars): ${JSON.stringify(req.body).substring(0, 500)}`);

  try {
    const {
      items,                    // [{product_id, quantity, customer_price}]
      customer_name,
      primary_phone,
      secondary_phone,
      province,                 // اسم المحافظة
      city,                     // اسم المدينة
      province_id,              // معرف المحافظة (اختياري)
      city_id,                  // معرف المدينة (اختياري)
      customer_address,
      customer_notes,
      user_phone,               // رقم هاتف التاجر
      user_id,                  // معرف التاجر (اختياري)
      delivery_option,          // 'customer_pays' أو 'from_profit' أو المبلغ المخصوم
      ...otherData              // أي بيانات إضافية (سيتم تجاهل الحسابات)
    } = req.body;

    // ═══════════════════════════════════════════
    // 1️⃣ التحقق من البيانات الأساسية المطلوبة
    // ═══════════════════════════════════════════
    // ✅ تحويل القيم إلى نصوص لتجنب أخطاء .trim() على أنواع أخرى
    const safeStr = (val) => (val != null ? String(val).trim() : '');

    const validationErrors = [];
    if (!safeStr(customer_name)) validationErrors.push('اسم العميل مطلوب');
    if (!safeStr(primary_phone)) validationErrors.push('رقم الهاتف مطلوب');
    if (!safeStr(user_phone)) validationErrors.push('رقم هاتف التاجر مطلوب');
    if (!safeStr(province)) validationErrors.push('المحافظة مطلوبة');
    if (!items || !Array.isArray(items) || items.length === 0) {
      validationErrors.push('يجب إضافة منتج واحد على الأقل');
    }

    if (validationErrors.length > 0) {
      logger.warn('❌ بيانات غير صحيحة:', validationErrors);
      return res.status(400).json({
        success: false,
        error: 'بيانات غير صحيحة',
        details: validationErrors
      });
    }

    logger.info(`👤 العميل: ${customer_name}`);
    logger.info(`📱 الهاتف: ${primary_phone}`);
    logger.info(`🏪 التاجر: ${user_phone}`);
    logger.info(`📦 عدد المنتجات: ${items.length}`);

    // ═══════════════════════════════════════════
    // 2️⃣ جلب أسعار المنتجات الحقيقية من قاعدة البيانات
    // ═══════════════════════════════════════════
    logger.info('💰 جلب الأسعار الحقيقية من قاعدة البيانات...');

    const productIds = items.map(item => item.product_id).filter(Boolean);
    if (productIds.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'لا توجد منتجات صالحة في الطلب'
      });
    }

    const { data: products, error: productsError } = await supabase
      .from('products')
      .select('*') // ✅ جلب كل الأعمدة لتجنب أخطاء الأعمدة غير الموجودة
      .in('id', productIds);

    if (productsError || !products) {
      logger.error('❌ فشل جلب المنتجات:', productsError?.message);
      return res.status(500).json({
        success: false,
        error: 'فشل في جلب بيانات المنتجات'
      });
    }

    // إنشاء map للوصول السريع
    const productMap = {};
    products.forEach(p => { productMap[p.id] = p; });

    // ═══════════════════════════════════════════
    // 3️⃣ حساب الأسعار والأرباح (SERVER-SIDE فقط!)
    // ═══════════════════════════════════════════
    logger.info('🧮 حساب الأسعار والأرباح (Server-Side)...');

    let calculatedSubtotal = 0;      // المجموع الفرعي (سعر الجملة × الكمية)
    let calculatedCustomerTotal = 0; // مجموع سعر العميل
    let calculatedProfit = 0;         // الربح الإجمالي
    const processedItems = [];
    const stockErrors = [];

    for (const item of items) {
      const product = productMap[item.product_id];

      if (!product) {
        stockErrors.push(`المنتج ${item.product_id} غير موجود`);
        continue;
      }

      const quantity = parseInt(item.quantity) || 1;

      // ✅ التحقق من المخزون (يدعم أسماء أعمدة مختلفة)
      const availableStock = product.stock_quantity ?? product.quantity ?? null;
      if (availableStock !== null && availableStock < quantity) {
        stockErrors.push(`المنتج "${product.name}" غير متوفر بالكمية المطلوبة (المتاح: ${availableStock})`);
        continue;
      }

      // ✅ سعر الجملة الحقيقي من قاعدة البيانات (لا نثق بـ Flutter)
      const wholesalePrice = parseInt(product.wholesale_price) || 0;

      // ✅ سعر العميل من Flutter (هذا يحدده التاجر)
      const customerPrice = parseInt(item.customer_price) || wholesalePrice;

      // ✅ حساب الربح لكل منتج
      const itemProfit = (customerPrice - wholesalePrice) * quantity;
      const itemTotal = customerPrice * quantity;
      const itemWholesaleTotal = wholesalePrice * quantity;

      // ✅ منع الخسارة (سعر العميل لا يمكن أن يكون أقل من سعر الجملة)
      if (customerPrice < wholesalePrice) {
        logger.warn(`⚠️ محاولة بيع بخسارة: ${product.name} (جملة: ${wholesalePrice}, عميل: ${customerPrice})`);
        // نسمح بها ولكن نسجلها (أو يمكن رفضها)
      }

      calculatedSubtotal += itemWholesaleTotal;
      calculatedCustomerTotal += itemTotal;
      calculatedProfit += itemProfit;

      processedItems.push({
        product_id: product.id,
        product_name: product.name,
        product_image: product.image_url || (Array.isArray(product.images) && product.images.length > 0 ? product.images[0] : ''),
        wholesale_price: wholesalePrice,
        customer_price: customerPrice,
        quantity: quantity,
        total_price: itemTotal,
        profit_per_item: itemProfit
      });

      logger.info(`   ✅ ${product.name}: ${quantity} × ${customerPrice} = ${itemTotal} (ربح: ${itemProfit})`);
    }

    // التحقق من أخطاء المخزون
    if (stockErrors.length > 0) {
      logger.warn('❌ أخطاء في المخزون:', stockErrors);
      return res.status(400).json({
        success: false,
        error: 'بعض المنتجات غير متوفرة',
        details: stockErrors
      });
    }

    if (processedItems.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'لا توجد منتجات صالحة في الطلب'
      });
    }

    // ═══════════════════════════════════════════
    // 4️⃣ جلب رسوم التوصيل من قاعدة البيانات
    // ═══════════════════════════════════════════
    logger.info('🚚 جلب رسوم التوصيل...');

    let deliveryFee = 5000; // القيمة الافتراضية

    // محاولة جلب رسوم التوصيل من جدول المحافظات
    if (province_id || province) {
      let provinceQuery = supabase.from('provinces').select('delivery_fee, name');

      if (province_id) {
        provinceQuery = provinceQuery.eq('id', province_id);
      } else {
        provinceQuery = provinceQuery.ilike('name', province);
      }

      const { data: provinceData } = await provinceQuery.maybeSingle();

      if (provinceData?.delivery_fee) {
        deliveryFee = parseInt(provinceData.delivery_fee);
        logger.info(`   ✅ رسوم توصيل ${provinceData.name}: ${deliveryFee} د.ع`);
      }
    }

    // ═══════════════════════════════════════════
    // 5️⃣ حساب الربح النهائي بعد خصم التوصيل
    // ═══════════════════════════════════════════
    logger.info('💎 حساب الربح النهائي...');

    let deliveryPaidFromProfit = 0;
    let finalProfit = calculatedProfit;
    let customerTotal = calculatedCustomerTotal;

    // معالجة خيار التوصيل
    if (delivery_option === 'from_profit' || delivery_option === 'مجاني') {
      // التوصيل من الربح (مجاني للعميل)
      deliveryPaidFromProfit = Math.min(deliveryFee, calculatedProfit);
      finalProfit = calculatedProfit - deliveryPaidFromProfit;
      // العميل يدفع فقط سعر المنتجات
      customerTotal = calculatedCustomerTotal;
      logger.info(`   🎁 توصيل مجاني - خصم ${deliveryPaidFromProfit} من الربح`);
    } else if (typeof delivery_option === 'number' || !isNaN(parseInt(delivery_option))) {
      // مبلغ مخصص يُخصم من الربح
      deliveryPaidFromProfit = Math.min(parseInt(delivery_option), deliveryFee, calculatedProfit);
      finalProfit = calculatedProfit - deliveryPaidFromProfit;
      const customerPaysDelivery = deliveryFee - deliveryPaidFromProfit;
      customerTotal = calculatedCustomerTotal + customerPaysDelivery;
      logger.info(`   💰 خصم ${deliveryPaidFromProfit} من الربح، العميل يدفع ${customerPaysDelivery}`);
    } else {
      // العميل يدفع كل التوصيل
      customerTotal = calculatedCustomerTotal + deliveryFee;
      logger.info(`   💵 العميل يدفع كل التوصيل: ${deliveryFee}`);
    }

    // ✅ منع الربح السلبي
    if (finalProfit < 0) {
      logger.warn('⚠️ محاولة إنشاء طلب بربح سلبي - تم التصحيح إلى 0');
      finalProfit = 0;
    }

    logger.info('📊 ═══════════════════════════════════════════');
    logger.info(`📊 المجموع الفرعي (جملة): ${calculatedSubtotal} د.ع`);
    logger.info(`📊 مجموع سعر العميل: ${calculatedCustomerTotal} د.ع`);
    logger.info(`📊 رسوم التوصيل: ${deliveryFee} د.ع`);
    logger.info(`📊 المخصوم من الربح: ${deliveryPaidFromProfit} د.ع`);
    logger.info(`📊 المجموع النهائي للعميل: ${customerTotal} د.ع`);
    logger.info(`📊 الربح الإجمالي: ${calculatedProfit} د.ع`);
    logger.info(`📊 الربح النهائي: ${finalProfit} د.ع`);
    logger.info('📊 ═══════════════════════════════════════════');

    // ═══════════════════════════════════════════
    // 6️⃣ إنشاء معرف الطلب ورقم الطلب
    // ═══════════════════════════════════════════
    const orderId = `order_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const orderNumber = `ORD-${Date.now()}`;

    // ═══════════════════════════════════════════
    // 7️⃣ إعداد بيانات الطلب النهائية
    // ═══════════════════════════════════════════
    const finalOrderData = {
      id: orderId,
      order_number: orderNumber,
      customer_name: safeStr(customer_name),
      primary_phone: safeStr(primary_phone),
      secondary_phone: safeStr(secondary_phone) || null,
      province: safeStr(province),
      city: safeStr(city) || safeStr(province),
      customer_address: safeStr(customer_address) || `${safeStr(province)} - ${safeStr(city) || ''}`,
      customer_notes: customer_notes || null,
      user_phone: safeStr(user_phone),
      user_id: user_id || null,
      // ✅ القيم المحسوبة في السيرفر (لا نثق بـ Flutter)
      subtotal: calculatedSubtotal,
      delivery_fee: deliveryFee,
      total: customerTotal,
      profit: finalProfit,
      profit_amount: finalProfit,
      delivery_paid_from_profit: deliveryPaidFromProfit,
      status: 'active',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    // ═══════════════════════════════════════════
    // 8️⃣ حفظ الطلب والعناصر
    // ═══════════════════════════════════════════
    logger.info('💾 حفظ الطلب في قاعدة البيانات...');

    const { data: orderResult, error: orderError } = await supabase
      .from('orders')
      .insert(finalOrderData)
      .select()
      .single();

    if (orderError) {
      logger.error('❌ فشل في حفظ الطلب:', orderError.message);
      return res.status(500).json({
        success: false,
        error: 'فشل في حفظ الطلب',
        details: orderError.message
      });
    }

    // حفظ عناصر الطلب
    const orderItems = processedItems.map(item => ({
      ...item,
      order_id: orderId,
      created_at: new Date().toISOString()
    }));

    const { error: itemsError } = await supabase
      .from('order_items')
      .insert(orderItems);

    if (itemsError) {
      logger.error('❌ فشل في حفظ عناصر الطلب:', itemsError.message);
      // حذف الطلب لأن العناصر فشلت
      await supabase.from('orders').delete().eq('id', orderId);
      return res.status(500).json({
        success: false,
        error: 'فشل في حفظ عناصر الطلب'
      });
    }

    // ═══════════════════════════════════════════
    // 9️⃣ تحديث المخزون
    // ═══════════════════════════════════════════
    logger.info('📦 تحديث المخزون...');

    for (const item of processedItems) {
      const product = productMap[item.product_id];
      if (product) {
        // ✅ دعم أسماء أعمدة مختلفة للمخزون
        const stockColumn = product.stock_quantity !== undefined ? 'stock_quantity' :
          product.quantity !== undefined ? 'quantity' : null;

        if (stockColumn) {
          const currentStock = product[stockColumn] || 0;
          const newQuantity = currentStock - item.quantity;

          await supabase
            .from('products')
            .update({ [stockColumn]: newQuantity, updated_at: new Date().toISOString() })
            .eq('id', item.product_id);

          logger.info(`   📦 ${item.product_name}: ${currentStock} → ${newQuantity}`);
        } else {
          logger.info(`   ⚠️ ${item.product_name}: لا يوجد عمود مخزون - تم تخطي التحديث`);
        }
      }
    }

    // ═══════════════════════════════════════════
    // 🎉 النجاح!
    // ═══════════════════════════════════════════
    const duration = Date.now() - startTime;
    logger.info('🎉 ══════════════════════════════════════════');
    logger.info(`🎉 تم إنشاء الطلب بنجاح!`);
    logger.info(`🆔 معرف الطلب: ${orderId}`);
    logger.info(`📦 عدد المنتجات: ${processedItems.length}`);
    logger.info(`💰 المجموع: ${customerTotal} د.ع`);
    logger.info(`💎 الربح: ${finalProfit} د.ع`);
    logger.info(`⏱️ الوقت: ${duration}ms`);
    logger.info('🎉 ══════════════════════════════════════════');

    return res.status(201).json({
      success: true,
      message: 'تم إنشاء الطلب بنجاح',
      orderId: orderId,
      orderNumber: orderNumber,
      // ✅ إرجاع القيم المحسوبة للعرض في Flutter
      calculatedValues: {
        subtotal: calculatedSubtotal,
        customerTotal: calculatedCustomerTotal,
        deliveryFee: deliveryFee,
        deliveryPaidFromProfit: deliveryPaidFromProfit,
        total: customerTotal,
        profit: calculatedProfit,
        finalProfit: finalProfit
      },
      itemsCount: processedItems.length,
      duration: duration
    });

  } catch (error) {
    // ✅ تسجيل مفصل جداً للخطأ
    logger.error('❌ ═══════════════════════════════════════════════');
    logger.error('❌ خطأ حرج في إنشاء الطلب!');
    logger.error(`❌ Error type: ${error.constructor.name}`);
    logger.error(`❌ Error message: ${error.message}`);
    logger.error(`❌ Error code: ${error.code || 'N/A'}`);
    logger.error('❌ Stack trace:');
    logger.error(error.stack);
    logger.error('❌ ═══════════════════════════════════════════════');

    return res.status(500).json({
      success: false,
      error: 'حدث خطأ غير متوقع',
      details: error.message,
      errorType: error.constructor.name
    });
  }
});

// ===================================
// 🔍 GET /api/orders/verify-recent - التحقق من آخر طلب تم إنشاؤه
// ===================================
// يستخدم للتحقق من نجاح إنشاء الطلب عند انتهاء المهلة
router.get('/verify-recent', async (req, res) => {
  try {
    const { phone } = req.query;

    if (!phone) {
      return res.status(400).json({
        success: false,
        error: 'رقم الهاتف مطلوب'
      });
    }

    logger.info(`🔍 التحقق من آخر طلب للرقم: ${phone}`);

    // البحث عن آخر طلب تم إنشاؤه لهذا الرقم في آخر دقيقتين
    const twoMinutesAgo = new Date(Date.now() - 2 * 60 * 1000).toISOString();

    const { data: order, error } = await supabase
      .from('orders')
      .select('id, order_number, created_at')
      .eq('primary_phone', phone)
      .gte('created_at', twoMinutesAgo)
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (error) {
      logger.error('خطأ في البحث عن الطلب:', error.message);
      return res.status(500).json({
        success: false,
        error: 'فشل في البحث عن الطلب'
      });
    }

    if (order) {
      logger.info(`✅ تم العثور على الطلب: ${order.id}`);
      return res.json({
        success: true,
        orderId: order.id,
        orderNumber: order.order_number,
        createdAt: order.created_at
      });
    }

    logger.info('❌ لم يتم العثور على طلب حديث');
    return res.json({
      success: false,
      message: 'لم يتم العثور على طلب حديث'
    });

  } catch (error) {
    logger.error('خطأ في التحقق من الطلب:', error.message);
    return res.status(500).json({
      success: false,
      error: 'حدث خطأ غير متوقع'
    });
  }
});

// ===================================
// POST /api/scheduled-orders - إنشاء طلب مجدول جديد (مع العناصر)
// ===================================
router.post('/scheduled-orders', async (req, res) => {
  try {
    const { items, ...orderData } = req.body; // ✅ فصل العناصر عن بيانات الطلب

    // ✔️ التحقق من صحة البيانات
    const validationErrors = validateOrderData(orderData);
    if (validationErrors.length > 0) {
      return res.status(400).json({
        success: false,
        error: 'بيانات غير صحيحة',
        details: validationErrors
      });
    }

    // إضافة معرف فريد وتاريخ الإنشاء
    const orderId = orderData.id || `scheduled_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const newOrder = {
      ...orderData,
      id: orderId,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    // ✅ حفظ الطلب المجدول في قاعدة البيانات
    const { data: orderResult, error: orderError } = await supabase
      .from('scheduled_orders')
      .insert(newOrder)
      .select()
      .single();

    // ❌ التحقق من الأخطاء
    if (orderError) {
      logger.error('فشل في إنشاء الطلب المجدول', orderError.message);
      return res.status(500).json({
        success: false,
        error: 'فشل في إنشاء الطلب المجدول',
        details: orderError.message,
        code: orderError.code
      });
    }

    // ❌ التحقق من أن البيانات تم إرجاعها
    if (!orderResult || !orderResult.id) {
      console.error('❌ فشل في إنشاء الطلب المجدول: لم يتم إرجاع بيانات الطلب');
      return res.status(500).json({
        success: false,
        error: 'فشل في إنشاء الطلب المجدول - لم يتم حفظ البيانات'
      });
    }

    // ✅ الآن فقط نعرض رسالة النجاح

    // ✅ حفظ عناصر الطلب المجدول إذا كانت موجودة
    let itemsSaved = false;
    if (items && items.length > 0) {

      const orderItems = items.map(item => ({
        scheduled_order_id: orderId,
        product_id: item.product_id,
        product_name: item.product_name,
        product_image: item.product_image,
        quantity: item.quantity,
        price: item.price,
        notes: item.notes || '',
        created_at: new Date().toISOString()
      }));

      const { data: itemsData, error: itemsError } = await supabase
        .from('scheduled_order_items')
        .insert(orderItems)
        .select();

      if (itemsError) {
        console.error('❌ فشل في حفظ عناصر الطلب المجدول:', itemsError.message);
        // نحذف الطلب لأن العناصر لم تُحفظ
        await supabase.from('scheduled_orders').delete().eq('id', orderId);
        return res.status(500).json({
          success: false,
          error: 'فشل في حفظ عناصر الطلب المجدول',
          details: itemsError.message
        });
      }

      if (!itemsData || itemsData.length === 0) {
        console.error('❌ فشل في حفظ عناصر الطلب المجدول: لم يتم إرجاع بيانات');
        // نحذف الطلب لأن العناصر لم تُحفظ
        await supabase.from('scheduled_orders').delete().eq('id', orderId);
        return res.status(500).json({
          success: false,
          error: 'فشل في حفظ عناصر الطلب المجدول - لم يتم حفظ البيانات'
        });
      }

      itemsSaved = true;

    }

    // ✅ النجاح الكامل

    res.status(201).json({
      success: true,
      message: 'تم إنشاء الطلب المجدول بنجاح',
      data: orderResult,
      orderId: orderResult.id,
      itemsCount: items ? items.length : 0,
      itemsSaved: itemsSaved
    });

  } catch (error) {
    console.error('❌ خطأ حرج في API إنشاء الطلب المجدول:', error.message);
    console.error('❌ Stack:', error.stack);
    res.status(500).json({
      success: false,
      error: 'خطأ في الخادم',
      details: error.message
    });
  }
});

// ===================================
// POST /api/orders/:id/send-to-waseet - إرسال طلب محدد لشركة الوسيط يدوياً
// ===================================
router.post('/:id/send-to-waseet', async (req, res) => {
  try {
    const { id } = req.params;

    // التحقق من وجود الطلب
    const { data: existingOrder, error: fetchError } = await supabase
      .from('orders')
      .select('id, customer_name, waseet_order_id')
      .eq('id', id)
      .single();

    if (fetchError || !existingOrder) {
      return res.status(404).json({
        success: false,
        error: 'الطلب غير موجود'
      });
    }

    // التحقق من أن الطلب لم يتم إرساله مسبقاً
    if (existingOrder.waseet_order_id) {
      return res.status(400).json({
        success: false,
        error: 'تم إرسال هذا الطلب لشركة الوسيط مسبقاً'
      });
    }

    // إرسال الطلب لشركة الوسيط
    const OrderSyncService = require('../services/order_sync_service');
    const orderSyncService = new OrderSyncService();

    const waseetResult = await orderSyncService.sendOrderToWaseet(id);

    if (waseetResult && waseetResult.success) {

      res.json({
        success: true,
        message: 'تم إرسال الطلب لشركة الوسيط بنجاح',
        data: {
          orderId: id,
          qrId: waseetResult.qrId,
          waseetResponse: waseetResult.waseetResponse
        }
      });
    } else {
      console.error(`❌ فشل في إرسال الطلب ${id} لشركة الوسيط`);

      res.status(500).json({
        success: false,
        error: 'فشل في إرسال الطلب لشركة الوسيط'
      });
    }

  } catch (error) {
    console.error('❌ خطأ في إرسال الطلب لشركة الوسيط:', error);
    res.status(500).json({
      success: false,
      error: 'خطأ في الخادم'
    });
  }
});

// ===================================
// POST /api/orders/sync-waseet-statuses - مزامنة حالات جميع الطلبات مع شركة الوسيط
// ===================================
router.post('/sync-waseet-statuses', async (req, res) => {
  try {

    const OrderSyncService = require('../services/order_sync_service');
    const orderSyncService = new OrderSyncService();

    const syncResult = await orderSyncService.syncAllOrderStatuses();

    if (syncResult) {
      res.json({
        success: true,
        message: 'تم مزامنة حالات الطلبات بنجاح'
      });
    } else {
      res.status(500).json({
        success: false,
        error: 'فشل في مزامنة حالات الطلبات'
      });
    }

  } catch (error) {
    console.error('❌ خطأ في مزامنة حالات الطلبات:', error);
    res.status(500).json({
      success: false,
      error: 'خطأ في الخادم'
    });
  }
});

// ===================================
// POST /api/orders/sync-waseet-status-definitions - مزامنة تعريفات حالات الوسيط
// ===================================
router.post('/sync-waseet-status-definitions', async (req, res) => {
  try {

    const OrderSyncService = require('../services/order_sync_service');
    const orderSyncService = new OrderSyncService();

    const syncResult = await orderSyncService.syncWaseetStatuses();

    if (syncResult.success) {
      res.json({
        success: true,
        message: 'تم مزامنة تعريفات حالات الوسيط بنجاح',
        data: {
          totalStatuses: syncResult.totalStatuses,
          updated: syncResult.updated,
          matched: syncResult.matched,
          ignored: syncResult.ignored
        }
      });
    } else {
      res.status(500).json({
        success: false,
        error: syncResult.error || 'فشل في مزامنة تعريفات الحالات'
      });
    }

  } catch (error) {
    console.error(`❌ خطأ في مزامنة تعريفات حالات الوسيط:`, error);
    res.status(500).json({
      success: false,
      error: 'خطأ في الخادم'
    });
  }
});

// ===================================
// POST /api/orders/retry-failed-waseet - إعادة محاولة إرسال الطلبات الفاشلة للوسيط
// ===================================
router.post('/retry-failed-waseet', async (req, res) => {
  try {

    // جلب الطلبات التي فشل إرسالها للوسيط
    const { data: failedOrders, error: fetchError } = await supabase
      .from('orders')
      .select('id, customer_name, waseet_status, waseet_data')
      .eq('status', 'in_delivery')
      .eq('waseet_status', 'في انتظار الإرسال للوسيط');

    if (fetchError) {
      console.error('❌ خطأ في جلب الطلبات الفاشلة:', fetchError);
      return res.status(500).json({
        success: false,
        error: 'خطأ في جلب الطلبات الفاشلة'
      });
    }

    if (!failedOrders || failedOrders.length === 0) {
      return res.json({
        success: true,
        message: 'لا توجد طلبات فاشلة لإعادة المحاولة',
        retried: 0
      });
    }

    const OrderSyncService = require('../services/order_sync_service');
    const orderSyncService = new OrderSyncService();

    let successCount = 0;
    let failCount = 0;

    for (const order of failedOrders) {
      try {

        const waseetResult = await orderSyncService.sendOrderToWaseet(order.id);

        if (waseetResult && waseetResult.success) {
          successCount++;

        } else {
          failCount++;

        }


      } catch (orderError) {
        failCount++;
        console.error(`❌ خطأ في إعادة محاولة الطلب ${order.id}:`, orderError);
      }
    }

    res.json({
      success: true,
      message: `تم إعادة محاولة ${failedOrders.length} طلب`,
      retried: failedOrders.length,
      successful: successCount,
      failed: failCount
    });

  } catch (error) {
    console.error('❌ خطأ في إعادة محاولة الطلبات الفاشلة:', error);
    res.status(500).json({
      success: false,
      error: 'خطأ في الخادم'
    });
  }
});

// ===================================
// POST /api/orders/create-test-order - إنشاء طلب تجريبي للاختبار
// ===================================
router.post('/create-test-order', async (req, res) => {
  try {

    const testOrder = {
      id: `test_order_${Date.now()}`,
      customer_name: 'عميل اختبار النظام',
      customer_phone: '07501234567',
      primary_phone: '07501234567',
      secondary_phone: '07701234567',
      customer_address: 'بغداد - الكرادة - شارع الكرادة الداخل',
      province: 'بغداد',
      city: 'الكرادة',
      total: 85000,
      status: 'active',
      notes: 'طلب تجريبي لاختبار نظام الوسيط',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    const { data, error } = await supabase
      .from('orders')
      .insert(testOrder)
      .select()
      .single();

    if (error) {
      console.error('❌ خطأ في إنشاء الطلب التجريبي:', error);
      return res.status(500).json({
        success: false,
        error: 'فشل في إنشاء الطلب التجريبي',
        details: error
      });
    }

    res.status(201).json({
      success: true,
      message: 'تم إنشاء الطلب التجريبي بنجاح',
      data: data
    });

  } catch (error) {
    console.error('❌ خطأ في API إنشاء الطلب التجريبي:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ⚠️ تم نقل جميع مسارات المزامنة إلى /waseet-sync/:action (موحد)

// ⚠️ تم نقل هذا المسار إلى /waseet-sync/force (موحد)

// ===================================
// نظام المزامنة المدمج مع الوسيط - Production APIs
// ===================================
// ⚠️ جميع مسارات المزامنة موحدة في /waseet-sync/:action

// ===================================
// GET /api/orders/:id - جلب طلب محدد مع العناصر (عادي أو مجدول)
// ⚠️ يجب أن يكون هذا المسار في النهاية لتجنب التعارض مع المسارات الأخرى
// ===================================
// ===================================
// GET /api/orders/:id - جلب طلب محدد مع العناصر (عادي)
// ⚠️ يجب أن يكون هذا المسار في النهاية لتجنب التعارض مع المسارات الأخرى
// ===================================
router.get('/:id', verifyAuth, async (req, res) => {
  const stepId = Math.random().toString(36).substring(7); // تتبع الطلب
  try {
    const { id } = req.params;
    const userId = req.user.id;

    console.log(`[${stepId}] 📥 جلب تفاصيل الطلب: ${id} للمستخدم: ${userId}`);

    // 1️⃣ جلب الطلب مع العناصر
    const { data: order, error } = await supabase
      .from('orders')
      .select('*, order_items(*)')
      .eq('id', id)
      .single();

    if (error || !order) {
      console.error(`[${stepId}] ❌ الطلب غير موجود: ${id}`);
      return res.status(404).json({ success: false, error: 'الطلب غير موجود' });
    }

    // 🔐 2️⃣ التحقق الصارم من الملكية
    if (order.user_id !== userId) {
      logger.warn(`⛔ [${stepId}] محاولة وصول غير مصرح: User ${userId} -> Order ${id}`);
      return res.status(403).json({ success: false, error: 'ليس لديك صلاحية للوصول لهذا الطلب' });
    }

    // 3️⃣ تجهيز DTO (Data Transfer Object)
    const orderDetails = {
      id: order.id,
      isScheduled: false,
      status: order.status,
      customer: {
        name: order.customer_name,
        phone: order.primary_phone,
        alternatePhone: order.secondary_phone,
      },
      location: {
        province: order.province,
        city: order.city,
      },
      notes: order.customer_notes || order.notes,
      items: order.order_items.map(item => ({
        id: item.id,
        productId: item.product_id,
        name: item.product_name,
        imageUrl: item.image_url,
        quantity: item.quantity,
        price: item.price,
        profit: item.profit,
        supplierId: item.supplier_id
      })),
      financial: {
        total: order.total,
        subtotal: order.subtotal,
        discount: order.discount,
        shipping: order.shipping_fee,
        profit: order.profit,
        profitAmount: order.profit_amount
      },
      waseet: {
        id: order.waseet_order_id,
        status: order.waseet_status
      },
      dates: {
        created: order.created_at,
        updated: order.updated_at
      }
    };

    console.log(`[${stepId}] ✅ تم جلب تفاصيل الطلب بنجاح`);
    return apiSuccess(res, orderDetails);

  } catch (error) {
    console.error(`[${stepId}] ❌ خطأ في جلب تفاصيل الطلب:`, error);
    return apiError(res, 'جلب تفاصيل الطلب', error);
  }
});

// ===================================
// PUT /api/orders/:id - تحديث طلب عادي (Secure & Validated)
// ===================================
router.put('/:id', verifyAuth, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const body = req.body;

    // 1️⃣ التحقق من البيانات (Validation)
    const errors = [];
    if (!body.customerName?.trim()) errors.push('اسم العميل مطلوب');
    if (!body.primaryPhone?.trim()) errors.push('رقم الهاتف مطلوب');
    if (!body.province?.trim()) errors.push('المحافظة مطلوبة');
    if (!body.city?.trim()) errors.push('المدينة مطلوبة');

    if (errors.length > 0) {
      return res.status(400).json({ success: false, error: errors.join(', ') });
    }

    // 2️⃣ التحقق من الملكية والحالة
    const { data: order, error: fetchError } = await supabase
      .from('orders')
      .select('user_id, status')
      .eq('id', id)
      .single();

    if (fetchError || !order) {
      return res.status(404).json({ success: false, error: 'الطلب غير موجود' });
    }

    if (order.user_id !== userId) {
      logger.warn(`⛔ محاولة تعديل غير مصرح: User ${userId} -> Order ${id}`);
      return res.status(403).json({ success: false, error: 'ليس لديك صلاحية لتعديل هذا الطلب' });
    }

    // 3️⃣ التحديث الآمن
    const updateData = {
      customer_name: body.customerName.trim(),
      primary_phone: body.primaryPhone.trim(),
      secondary_phone: body.secondaryPhone?.trim() || null,
      province: body.province.trim(),
      city: body.city.trim(),
      customer_notes: body.notes?.trim() || null,
      updated_at: new Date().toISOString()
    };

    const { error: updateError } = await supabase
      .from('orders')
      .update(updateData)
      .eq('id', id);

    if (updateError) throw updateError;

    logger.info(`✅ تم تحديث الطلب: ${id} بواسطة User: ${userId}`);
    return apiSuccess(res, null, 'تمت حفظ التغييرات بنجاح');

  } catch (error) {
    return apiError(res, 'تحديث الطلب', error);
  }
});

// 🗑️ الكود القديم تم استبداله أعلاه
/*
router.get('/:id', async (req, res) => {
  const stepId = Math.random().toString(36).substring(7); // تتبع الطلب
  try {
    const { id } = req.params;
    console.log(`[${stepId}] 📥 جلب تفاصيل الطلب: ${id}`);


    if (!id || id === 'null' || id === 'undefined') {
      console.error(`[${stepId}] ❌ معرف الطلب غير صالح: ${id}`);
      return res.status(400).json({ success: false, error: 'معرف الطلب غير صالح' });
    }

    // ✅ محاولة جلب الطلب العادي أولاً
    // نستخدم * لتجنب مشاكل أسماء الأعمدة المتغيرة
    let { data: orderData, error: orderError } = await supabase
      .from('orders')
      .select('*')
      .eq('id', id)
      .single();

    let isScheduledOrder = false;

    // إذا لم يوجد، جرب الطلبات المجدولة
    if (orderError) {
      console.log(`[${stepId}] ⚠️ لم يتم العثور في orders (أو خطأ): ${orderError.message}. محاولة scheduled_orders...`);

      const { data: scheduledData, error: scheduledError } = await supabase
        .from('scheduled_orders')
        .select('*')
        .eq('id', id)
        .single();

      if (scheduledError) {
        console.error(`[${stepId}] ❌ خطأ/لم يوجد في scheduled_orders:`, scheduledError.message);
        return res.status(404).json({
          success: false,
          error: 'الطلب غير موجود'
        });
      }

      orderData = scheduledData;
      isScheduledOrder = true;
      console.log(`[${stepId}] ✅ وجد في scheduled_orders`);
    } else {
      console.log(`[${stepId}] ✅ وجد في orders`);
    }

    // ✅ جلب عناصر الطلب
    const itemsTableName = isScheduledOrder ? 'scheduled_order_items' : 'order_items';
    const itemsForeignKey = isScheduledOrder ? 'scheduled_order_id' : 'order_id';

    console.log(`[${stepId}] 🔄 جلب العناصر من ${itemsTableName}...`);

    const { data: itemsData, error: itemsError } = await supabase
      .from(itemsTableName)
      .select('*')
      .eq(itemsForeignKey, id);

    if (itemsError) {
      console.error(`[${stepId}] ⚠️ تحذير: خطأ في جلب عناصر الطلب:`, itemsError);
      // لا نرجع خطأ، فقط نرسل الطلب بدون عناصر
    } else {
      console.log(`[${stepId}] ✅ تم جلب ${itemsData?.length || 0} عنصر`);
    }

    // ✅ دمج البيانات
    const itemsKey = isScheduledOrder ? 'scheduled_order_items' : 'order_items';
    const responseData = {
      ...orderData,
      [itemsKey]: itemsData || []
    };

    res.json({
      success: true,
      data: responseData,
      isScheduledOrder: isScheduledOrder
    });

    console.log(`[${stepId}] 📤 تم إرسال الرد بنجاح`);

  } catch (error) {
    console.error(`[${stepId}] ❌ خطأ في API جلب الطلب:`, error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});
*/

// ===================================
// 1️⃣ POST /api/orders/waseet-sync/:action - مسار موحد للتحكم بمزامنة الوسيط
// ===================================
// الإجراءات المدعومة: start | stop | restart | force | status
async function handleWaseetSyncAction(req, res) {
  try {
    const action = (req.params.action || '').toLowerCase().trim();
    const waseetSync = require('../services/integrated_waseet_sync');

    logger.info(`🔄 Waseet Sync Action: ${action}`);

    const actions = {
      start: () => {
        logger.info('Starting Waseet sync...');
        return waseetSync.start();
      },
      stop: () => {
        logger.info('Stopping Waseet sync...');
        return waseetSync.stop();
      },
      restart: () => {
        logger.info('Restarting Waseet sync...');
        return waseetSync.restart();
      },
      force: () => {
        logger.info('Forcing Waseet sync...');
        return waseetSync.forcSync();
      },
      status: () => {
        logger.info('Getting Waseet sync status...');
        return waseetSync.getStats ? waseetSync.getStats() : { ok: true };
      },
    };

    if (!actions[action]) {
      return res.status(400).json({
        success: false,
        error: `إجراء غير معروف: ${action}`,
        supportedActions: Object.keys(actions)
      });
    }

    const result = await actions[action]();
    return apiSuccess(res, result, `تم تنفيذ الإجراء: ${action}`);

  } catch (e) {
    logger.error(`Waseet sync action error: ${req.params.action}`, e.message);
    return apiError(res, `إجراء المزامنة (${req.params.action})`, e);
  }
}

router.post('/waseet-sync/:action', handleWaseetSyncAction);

module.exports = router;
