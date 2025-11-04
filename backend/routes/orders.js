// ===================================
// مسارات API للطلبات - Orders Routes
// ===================================

const express = require('express');
const { createClient } = require('@supabase/supabase-js');
const router = express.Router();

// إعداد Supabase
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

// ===================================
// GET /api/orders/debug-waseet - فحص مفصل لحالة الوسيط
// ===================================
router.get('/debug-waseet', async (req, res) => {
  try {
    console.log('🔍 فحص مفصل لحالة الوسيط...');

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

    console.log('📋 معلومات التشخيص:', JSON.stringify(debugInfo, null, 2));

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
      .select('*')
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
      console.error('❌ خطأ في جلب الطلبات:', error);
      return res.status(500).json({
        success: false,
        error: 'خطأ في جلب الطلبات'
      });
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

// مسار لتنفيذ مزامنة فورية مع النظام المدمج
router.post('/run-integrated-sync', async (req, res) => {
  try {
    const waseetSync = require('../services/integrated_waseet_sync');

    console.log('🔄 تنفيذ مزامنة فورية مع النظام المدمج...');

    // تأكد من أن النظام يعمل
    if (!waseetSync.isRunning) {
      console.log('🚀 بدء النظام المدمج...');
      await waseetSync.start();
    }

    // تنفيذ مزامنة فورية
    const result = await waseetSync.forcSync();

    res.json({
      success: true,
      message: 'تم تنفيذ المزامنة الفورية بنجاح',
      data: result
    });

  } catch (error) {
    console.error('❌ خطأ في المزامنة الفورية:', error);
    res.status(500).json({
      success: false,
      error: error.message,
      message: 'فشل في تنفيذ المزامنة'
    });
  }
});

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

    console.log(`📱 جلب طلبات المستخدم: ${userPhone} - الصفحة: ${page}, الحد: ${limit}, الفلتر: ${statusFilter || 'الكل'}`);

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

        console.log(`🔍 فلترة بالحالات (status + waseet_status_text): ${statuses.join(', ')}`);
        console.log(`📋 عدد الحالات: ${statuses.length}`);
        console.log(`📋 Status Array: ${statusArray.substring(0, 100)}...`);
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

    console.log(`✅ تم جلب ${data?.length || 0} طلب من أصل ${count} طلب`);

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

    console.log(`📊 جلب عدادات الطلبات للمستخدم: ${userPhone}`);

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
    const { count: scheduledCount } = await supabase
      .from('scheduled_orders')
      .select('id', { count: 'exact', head: true })
      .eq('user_phone', userPhone)
      .eq('is_converted', false);

    counts.scheduled = scheduledCount || 0;

    console.log(`✅ تم حساب العدادات:`, counts);

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

    console.log(`📅 جلب الطلبات المجدولة للمستخدم: ${userPhone}`);

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

    console.log(`✅ تم جلب ${data?.length || 0} طلب مجدول من أصل ${count}`);

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

    console.log(`🗑️ حذف الطلب المجدول ${id} للمستخدم ${userPhone}`);

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

    console.log(`✅ تم حذف الطلب المجدول ${id}`);

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

    console.log(`✏️ تعديل الطلب ${id} للمستخدم ${userPhone}`);

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

    console.log(`✅ تم تعديل الطلب ${id}`);

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

    console.log(`🗑️ حذف الطلب ${id} للمستخدم ${userPhone}`);

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

    console.log(`✅ تم حذف الطلب ${id}`);

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
  try {
    console.log('\n🚀 ===== بداية تحديث حالة الطلب =====');
    console.log(`⏰ الوقت: ${new Date().toISOString()}`);

    const { id } = req.params;
    const { status, notes, changedBy = 'admin' } = req.body;

    console.log(`🆔 معرف الطلب: ${id}`);
    console.log(`📊 الحالة الجديدة: "${status}"`);
    console.log(`📝 ملاحظات: ${notes || 'لا توجد'}`);
    console.log(`👤 تم التغيير بواسطة: ${changedBy}`);
    console.log(`📦 البيانات الكاملة المستلمة:`, JSON.stringify(req.body, null, 2));

    // التحقق من البيانات المطلوبة
    if (!status) {
      return res.status(400).json({
        success: false,
        error: 'الحالة الجديدة مطلوبة'
      });
    }

    // تحويل الحالات المختلفة إلى الحالة الصحيحة الوحيدة للوسيط
    function normalizeStatus(status) {
      console.log(`🔄 تحويل الحالة: "${status}"`);

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
      console.log(`   ✅ تم التحويل إلى: "${converted}"`);
      return converted;
    }

    // تطبيق التحويل على الحالة
    const normalizedStatus = normalizeStatus(status);
    console.log(`🔄 تحويل الحالة: "${status}" → "${normalizedStatus}"`);

    // التحقق من وجود الطلب
    const { data: existingOrder, error: fetchError } = await supabase
      .from('orders')
      .select('id, status, customer_name, customer_id')
      .eq('id', id)
      .single();

    if (fetchError || !existingOrder) {
      console.error('❌ الطلب غير موجود:', fetchError);
      return res.status(404).json({
        success: false,
        error: 'الطلب غير موجود'
      });
    }

    const oldStatus = existingOrder.status;
    console.log(`📊 الحالة القديمة: ${oldStatus} → الحالة الجديدة: ${status}`);

    // تحديث حالة الطلب (استخدام الحالة المحولة)
    const { error: updateError } = await supabase
      .from('orders')
      .update({
        status: normalizedStatus,
        updated_at: new Date().toISOString()
      })
      .eq('id', id);

    if (updateError) {
      console.error('❌ خطأ في تحديث الطلب:', updateError);
      return res.status(500).json({
        success: false,
        error: 'فشل في تحديث حالة الطلب'
      });
    }

    // إضافة سجل في تاريخ الحالات (اختياري - لا يوقف العملية إذا فشل)
    try {
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
      console.log('✅ تم إضافة سجل تاريخ الحالة');
    } catch (historyError) {
      console.warn('⚠️ تحذير: فشل في حفظ سجل التاريخ (الجدول قد يكون غير موجود):', historyError.message);
      // لا نوقف العملية - هذا اختياري
    }

    // إضافة ملاحظة إذا كانت متوفرة
    if (notes && notes.trim()) {
      try {
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
        console.log('✅ تم إضافة ملاحظة الحالة');
      } catch (noteError) {
        console.warn('⚠️ تحذير: فشل في إضافة الملاحظة (الجدول قد يكون غير موجود):', noteError.message);
      }
    }

    console.log(`✅ تم تحديث حالة الطلب ${id} بنجاح`);

    // 🔔 إرسال إشعار للمستخدم عند تحديث الحالة - الإصلاح الأساسي
    try {
      console.log('📱 بدء إرسال إشعار تحديث الحالة للمستخدم...');

      // الحصول على معلومات الطلب المحدث
      const { data: orderData, error: orderError } = await supabase
        .from('orders')
        .select('customer_phone, user_phone, customer_name, customer_id')
        .eq('id', id)
        .single();

      if (orderError) {
        console.error('❌ خطأ في جلب معلومات الطلب للإشعار:', orderError);
      } else if (orderData) {
        const userPhone = orderData.customer_phone || orderData.user_phone;
        const customerName = orderData.customer_name || 'عميل';

        if (userPhone) {
          // 🎯 قائمة الحالات المسموحة للإشعارات (جميع الحالات المهمة للمستخدم)
          const allowedNotificationStatuses = [
            // الحالات الأساسية
            'قيد التوصيل الى الزبون (في عهدة المندوب)',
            'تم التسليم للزبون',

            // حالات التعديل
            'تم تغيير محافظة الزبون',
            'تغيير المندوب',

            // حالات عدم الرد
            'لا يرد',
            'لا يرد بعد الاتفاق',

            // حالات الإغلاق
            'مغلق',
            'مغلق بعد الاتفاق',

            // حالات التأجيل
            'مؤجل',
            'مؤجل لحين اعادة الطلب لاحقا',

            // حالات الإلغاء والرفض
            'الغاء الطلب',
            'رفض الطلب',
            'مفصول عن الخدمة',
            'طلب مكرر',
            'مستلم مسبقا',

            // حالات مشاكل الاتصال
            'الرقم غير معرف',
            'الرقم غير داخل في الخدمة',
            'لا يمكن الاتصال بالرقم',

            // حالات أخرى
            'العنوان غير دقيق',
            'لم يطلب',
            'حظر المندوب'
          ];

          // 🚫 فلترة الإشعارات - فقط الحالات المسموحة
          if (!allowedNotificationStatuses.includes(normalizedStatus)) {
            console.log(`🚫 تم تجاهل إشعار الحالة "${normalizedStatus}" - غير مدرجة في القائمة المسموحة`);
          } else {
            console.log(`📤 إرسال إشعار للمستخدم: ${userPhone}`);
            console.log(`👤 اسم العميل: ${customerName}`);
            console.log(`🔄 الحالة الجديدة: ${normalizedStatus}`);

            // استدعاء خدمة الإشعارات المستهدفة
            const targetedNotificationService = require('../services/targeted_notification_service');

            // تهيئة الخدمة إذا لم تكن مُهيأة
            if (!targetedNotificationService.initialized) {
              await targetedNotificationService.initialize();
            }

            // إرسال الإشعار
            const notificationResult = await targetedNotificationService.sendOrderStatusNotification(
              userPhone,
              id,
              normalizedStatus,
              customerName,
              notes || 'تم تحديث حالة الطلب'
            );

            if (notificationResult.success) {
              console.log('✅ تم إرسال إشعار تحديث الحالة بنجاح');
            } else {
              console.log('⚠️ فشل في إرسال الإشعار:', notificationResult.error);
            }
          }
        } else {
          console.log('⚠️ لا يوجد رقم هاتف للمستخدم - لن يتم إرسال إشعار');
        }
      }
    } catch (notificationError) {
      console.error('❌ خطأ في إرسال إشعار تحديث الحالة:', notificationError.message);
      // لا نوقف العملية إذا فشل الإشعار
    }

    // 🚀 إرسال الطلب لشركة الوسيط عند تغيير الحالة إلى "قيد التوصيل"
    console.log(`🔍 فحص إرسال الطلب للوسيط - الحالة المحولة: "${normalizedStatus}"`);

    // الحالة الوحيدة المؤهلة لإرسال الطلب للوسيط
    // ID: 3 - "قيد التوصيل الى الزبون (في عهدة المندوب)"
    const deliveryStatuses = [
      'قيد التوصيل الى الزبون (في عهدة المندوب)' // الحالة الوحيدة المؤهلة
    ];

    console.log(`📋 الحالة الوحيدة المؤهلة للوسيط: "${deliveryStatuses[0]}"`);
    console.log(`🔍 هل الحالة المحولة "${normalizedStatus}" مؤهلة؟`, deliveryStatuses.includes(normalizedStatus));

    if (deliveryStatuses.includes(normalizedStatus)) {
      console.log(`📦 ✅ الحالة "${normalizedStatus}" مؤهلة - سيتم إرسال الطلب لشركة الوسيط...`);

      try {
        // التحقق من أن الطلب لم يتم إرساله مسبقاً
        const { data: currentOrder, error: checkError } = await supabase
          .from('orders')
          .select('waseet_order_id, waseet_status')
          .eq('id', id)
          .single();

        if (checkError) {
          console.error('❌ خطأ في فحص حالة الوسيط:', checkError);
        } else {
          console.log(`📋 بيانات الطلب الحالية:`, currentOrder);
          console.log(`🆔 معرف الوسيط الحالي: ${currentOrder.waseet_order_id || 'غير محدد'}`);
          console.log(`📊 حالة الوسيط الحالية: ${currentOrder.waseet_status || 'غير محدد'}`);

          if (currentOrder.waseet_order_id) {
            console.log(`ℹ️ الطلب ${id} تم إرساله مسبقاً للوسيط (ID: ${currentOrder.waseet_order_id})`);
          } else {
            console.log(`🚀 الطلب ${id} لم يتم إرساله للوسيط - سيتم الإرسال الآن...`);

            // التحقق من وجود خدمة المزامنة المهيأة
            console.log(`🔍 فحص خدمة المزامنة: ${global.orderSyncService ? '✅ موجودة' : '❌ غير موجودة'}`);

            if (!global.orderSyncService) {
              console.error('❌ خدمة المزامنة غير متاحة - محاولة إنشاء خدمة جديدة...');

              try {
                const OrderSyncService = require('../services/order_sync_service');
                global.orderSyncService = new OrderSyncService();
                console.log('✅ تم إنشاء خدمة مزامنة جديدة');
              } catch (serviceError) {
                console.error('❌ فشل في إنشاء خدمة المزامنة:', serviceError.message);

                // تحديث الطلب بحالة الخطأ
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

                // لا تتوقف هنا - استمر لإرسال الاستجابة
                console.log('⚠️ سيتم إرسال الاستجابة رغم فشل خدمة المزامنة');
              }
            }

            // إرسال الطلب لشركة الوسيط (فقط إذا كانت الخدمة متاحة)
            if (global.orderSyncService) {
              console.log(`🚀 بدء إرسال الطلب ${id} لشركة الوسيط...`);
              console.log(`🔧 خدمة المزامنة: ${global.orderSyncService.constructor.name}`);
              console.log(`🔧 حالة الخدمة: ${global.orderSyncService.isInitialized ? 'مهيأة' : 'غير مهيأة'}`);

              const waseetResult = await global.orderSyncService.sendOrderToWaseet(id);

              console.log(`📋 نتيجة إرسال الطلب للوسيط:`, waseetResult);

              if (waseetResult && waseetResult.success) {
                console.log(`✅ تم إرسال الطلب ${id} لشركة الوسيط بنجاح`);
                console.log(`🆔 QR ID: ${waseetResult.qrId}`);

                // تحديث الطلب بمعلومات الوسيط
                await supabase
                  .from('orders')
                  .update({
                    waseet_order_id: waseetResult.qrId || null,
                    waseet_status: 'تم الإرسال للوسيط',
                    waseet_data: JSON.stringify(waseetResult),
                    updated_at: new Date().toISOString()
                  })
                  .eq('id', id);

                console.log(`🎉 تم تحديث الطلب ${id} بمعرف الوسيط: ${waseetResult.qrId}`);

              } else {
                console.log(`⚠️ فشل في إرسال الطلب ${id} لشركة الوسيط - سيتم المحاولة لاحقاً`);

                // تحديث الطلب بحالة "في انتظار الإرسال للوسيط"
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
              }
            } else {
              console.log(`⚠️ خدمة المزامنة غير متاحة - سيتم المحاولة لاحقاً`);

              // تحديث الطلب بحالة "في انتظار الإرسال للوسيط"
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
            }
          }
        }

      } catch (waseetError) {
        console.error(`❌ خطأ في إرسال الطلب ${id} لشركة الوسيط:`, waseetError);

        // تحديث الطلب بحالة الخطأ
        try {
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
        } catch (updateError) {
          console.error('❌ خطأ في تحديث حالة الخطأ:', updateError);
        }
      }
    } else {
      console.log(`ℹ️ الحالة "${normalizedStatus}" ليست حالة توصيل - لن يتم إرسال الطلب للوسيط`);
    }

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
    console.error('❌ خطأ في API تحديث حالة الطلب:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ===================================
// POST /api/orders - إنشاء طلب جديد (مع العناصر)
// ===================================
router.post('/', async (req, res) => {
  try {
    const { items, ...orderData } = req.body; // ✅ فصل العناصر عن بيانات الطلب

    console.log('📦 محاولة إنشاء طلب جديد عبر الباك إند...');
    console.log('📋 عدد العناصر:', items ? items.length : 0);

    // إضافة معرف فريد وتاريخ الإنشاء
    const orderId = orderData.id || `order_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const newOrder = {
      ...orderData,
      id: orderId,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      status: orderData.status || 'active'
    };

    // ✅ حفظ الطلب في قاعدة البيانات
    const { data: orderResult, error: orderError } = await supabase
      .from('orders')
      .insert(newOrder)
      .select()
      .single();

    // ❌ التحقق من الأخطاء
    if (orderError) {
      console.error('❌ فشل في إنشاء الطلب:', orderError.message);
      return res.status(500).json({
        success: false,
        error: 'فشل في إنشاء الطلب',
        details: orderError.message,
        code: orderError.code
      });
    }

    // ❌ التحقق من أن البيانات تم إرجاعها
    if (!orderResult || !orderResult.id) {
      console.error('❌ فشل في إنشاء الطلب: لم يتم إرجاع بيانات الطلب');
      return res.status(500).json({
        success: false,
        error: 'فشل في إنشاء الطلب - لم يتم حفظ البيانات'
      });
    }

    // ✅ الآن فقط نعرض رسالة النجاح
    console.log(`✅ تم إنشاء الطلب بنجاح: ${orderResult.id}`);

    // ✅ حفظ عناصر الطلب إذا كانت موجودة
    let itemsSaved = false;
    if (items && items.length > 0) {
      console.log(`📦 محاولة حفظ ${items.length} عنصر للطلب...`);

      const orderItems = items.map(item => ({
        order_id: orderId,
        product_id: item.product_id,
        product_name: item.product_name,
        product_image: item.product_image,
        wholesale_price: item.wholesale_price,
        customer_price: item.customer_price,
        quantity: item.quantity,
        total_price: item.total_price,
        profit_per_item: item.profit_per_item,
        created_at: new Date().toISOString()
      }));

      const { data: itemsData, error: itemsError } = await supabase
        .from('order_items')
        .insert(orderItems)
        .select();

      if (itemsError) {
        console.error('❌ فشل في حفظ عناصر الطلب:', itemsError.message);
        // نحذف الطلب لأن العناصر لم تُحفظ
        await supabase.from('orders').delete().eq('id', orderId);
        return res.status(500).json({
          success: false,
          error: 'فشل في حفظ عناصر الطلب',
          details: itemsError.message
        });
      }

      if (!itemsData || itemsData.length === 0) {
        console.error('❌ فشل في حفظ عناصر الطلب: لم يتم إرجاع بيانات');
        // نحذف الطلب لأن العناصر لم تُحفظ
        await supabase.from('orders').delete().eq('id', orderId);
        return res.status(500).json({
          success: false,
          error: 'فشل في حفظ عناصر الطلب - لم يتم حفظ البيانات'
        });
      }

      itemsSaved = true;
      console.log(`✅ تم حفظ ${itemsData.length} عنصر بنجاح`);
    }

    // ✅ النجاح الكامل
    console.log(`🎉 تم إنشاء الطلب والعناصر بنجاح: ${orderResult.id}`);

    res.status(201).json({
      success: true,
      message: 'تم إنشاء الطلب بنجاح',
      data: orderResult,
      orderId: orderResult.id,
      itemsCount: items ? items.length : 0,
      itemsSaved: itemsSaved
    });

  } catch (error) {
    console.error('❌ خطأ حرج في API إنشاء الطلب:', error.message);
    console.error('❌ Stack:', error.stack);
    res.status(500).json({
      success: false,
      error: 'خطأ في الخادم',
      details: error.message
    });
  }
});

// ===================================
// POST /api/scheduled-orders - إنشاء طلب مجدول جديد (مع العناصر)
// ===================================
router.post('/scheduled-orders', async (req, res) => {
  try {
    const { items, ...orderData } = req.body; // ✅ فصل العناصر عن بيانات الطلب

    console.log('📅 محاولة إنشاء طلب مجدول جديد عبر الباك إند...');
    console.log('📋 عدد العناصر:', items ? items.length : 0);

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
      console.error('❌ فشل في إنشاء الطلب المجدول:', orderError.message);
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
    console.log(`✅ تم إنشاء الطلب المجدول بنجاح: ${orderResult.id}`);

    // ✅ حفظ عناصر الطلب المجدول إذا كانت موجودة
    let itemsSaved = false;
    if (items && items.length > 0) {
      console.log(`📦 محاولة حفظ ${items.length} عنصر للطلب المجدول...`);

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
      console.log(`✅ تم حفظ ${itemsData.length} عنصر بنجاح`);
    }

    // ✅ النجاح الكامل
    console.log(`🎉 تم إنشاء الطلب المجدول والعناصر بنجاح: ${orderResult.id}`);

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

    console.log(`📦 طلب إرسال الطلب ${id} لشركة الوسيط يدوياً...`);

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
      console.log(`✅ تم إرسال الطلب ${id} لشركة الوسيط بنجاح`);

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
    console.log(`🔄 طلب مزامنة حالات الطلبات مع شركة الوسيط...`);

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
    console.log(`🔄 طلب مزامنة تعريفات حالات الوسيط...`);

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
    console.log(`🔄 إعادة محاولة إرسال الطلبات الفاشلة للوسيط...`);

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

    console.log(`📊 تم العثور على ${failedOrders.length} طلب فاشل`);

    const OrderSyncService = require('../services/order_sync_service');
    const orderSyncService = new OrderSyncService();

    let successCount = 0;
    let failCount = 0;

    for (const order of failedOrders) {
      try {
        console.log(`🔄 إعادة محاولة إرسال الطلب ${order.id}...`);

        const waseetResult = await orderSyncService.sendOrderToWaseet(order.id);

        if (waseetResult && waseetResult.success) {
          successCount++;
          console.log(`✅ تم إرسال الطلب ${order.id} بنجاح`);
        } else {
          failCount++;
          console.log(`❌ فشل في إرسال الطلب ${order.id}`);
        }

        // انتظار قصير بين الطلبات لتجنب الضغط على API
        await new Promise(resolve => setTimeout(resolve, 1000));

      } catch (orderError) {
        failCount++;
        console.error(`❌ خطأ في إعادة محاولة الطلب ${order.id}:`, orderError);
      }
    }

    console.log(`✅ انتهت إعادة المحاولة - نجح: ${successCount}, فشل: ${failCount}`);

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
    console.log('📦 إنشاء طلب تجريبي للاختبار...');

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

    console.log(`✅ تم إنشاء طلب تجريبي: ${data.id}`);

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

// ===================================
// نظام المزامنة الحقيقي مع الوسيط
// ===================================

// POST /api/orders/start-waseet-sync - بدء نظام المزامنة الحقيقي مع الوسيط
router.post('/start-waseet-sync', async (req, res) => {
  try {
    console.log('🚀 طلب بدء نظام المزامنة مع الوسيط...');

    const RealWaseetSyncSystem = require('../services/real_waseet_sync_system');

    // إنشاء النظام إذا لم يكن موجود
    if (!global.waseetSyncSystem) {
      global.waseetSyncSystem = new RealWaseetSyncSystem();
    }

    // بدء النظام
    await global.waseetSyncSystem.startRealTimeSync();

    const stats = global.waseetSyncSystem.getSystemStats();

    res.json({
      success: true,
      message: 'تم بدء نظام المزامنة مع الوسيط بنجاح',
      data: {
        isRunning: stats.isRunning,
        syncInterval: stats.syncInterval,
        syncIntervalMinutes: stats.syncIntervalMinutes,
        lastSyncTime: stats.lastSyncTime,
        stats: stats.stats
      }
    });

  } catch (error) {
    console.error('❌ خطأ في بدء نظام المزامنة:', error);
    res.status(500).json({
      success: false,
      error: 'خطأ في بدء النظام'
    });
  }
});

// POST /api/orders/stop-waseet-sync - إيقاف نظام المزامنة
router.post('/stop-waseet-sync', async (req, res) => {
  try {
    console.log('⏹️ طلب إيقاف نظام المزامنة...');

    if (global.waseetSyncSystem) {
      global.waseetSyncSystem.stopRealTimeSync();

      res.json({
        success: true,
        message: 'تم إيقاف نظام المزامنة بنجاح'
      });
    } else {
      res.json({
        success: true,
        message: 'النظام غير مفعل'
      });
    }

  } catch (error) {
    console.error('❌ خطأ في إيقاف نظام المزامنة:', error);
    res.status(500).json({
      success: false,
      error: 'خطأ في إيقاف النظام'
    });
  }
});

// تم نقل هذا المسار إلى الأعلى لتجنب التعارض مع /:id

// POST /api/orders/force-waseet-sync - تنفيذ مزامنة فورية مع الوسيط
router.post('/force-waseet-sync', async (req, res) => {
  try {
    console.log('⚡ طلب مزامنة فورية مع الوسيط...');

    if (!global.waseetSyncSystem) {
      return res.status(400).json({
        success: false,
        error: 'نظام المزامنة غير مفعل'
      });
    }

    const result = await global.waseetSyncSystem.performFullSync();

    res.json({
      success: true,
      message: 'تم تنفيذ المزامنة الفورية بنجاح',
      data: result
    });

  } catch (error) {
    console.error('❌ خطأ في المزامنة الفورية:', error);
    res.status(500).json({
      success: false,
      error: 'خطأ في تنفيذ المزامنة'
    });
  }
});

// POST /api/orders/force-sync-now - تنفيذ مزامنة فورية
router.post('/force-sync-now', async (req, res) => {
  try {
    console.log('⚡ طلب مزامنة فورية...');

    if (!global.realTimeSyncSystem) {
      return res.status(400).json({
        success: false,
        error: 'نظام المزامنة غير مفعل'
      });
    }

    const result = await global.realTimeSyncSystem.performFullSync();

    res.json({
      success: true,
      message: 'تم تنفيذ المزامنة الفورية بنجاح',
      data: result
    });

  } catch (error) {
    console.error('❌ خطأ في المزامنة الفورية:', error);
    res.status(500).json({
      success: false,
      error: 'خطأ في تنفيذ المزامنة'
    });
  }
});

// ===================================
// نظام المزامنة المدمج مع الوسيط - Production APIs
// ===================================

// GET /api/orders/integrated-sync-status - حالة نظام المزامنة المدمج
router.get('/integrated-sync-status', async (req, res) => {
  try {
    const waseetSync = require('../services/integrated_waseet_sync');
    const stats = waseetSync.getStats();

    res.json({
      success: true,
      data: stats
    });

  } catch (error) {
    console.error('❌ خطأ في جلب حالة النظام:', error);
    res.status(500).json({
      success: false,
      error: 'خطأ في جلب حالة النظام'
    });
  }
});

// POST /api/orders/force-waseet-sync - مزامنة فورية
router.post('/force-waseet-sync', async (req, res) => {
  try {
    const waseetSync = require('../services/integrated_waseet_sync');
    const result = await waseetSync.forcSync();

    res.json(result);

  } catch (error) {
    console.error('❌ خطأ في المزامنة الفورية:', error);
    res.status(500).json({
      success: false,
      error: 'خطأ في تنفيذ المزامنة'
    });
  }
});

// POST /api/orders/restart-waseet-sync - إعادة تشغيل النظام
router.post('/restart-waseet-sync', async (req, res) => {
  try {
    const waseetSync = require('../services/integrated_waseet_sync');
    const result = await waseetSync.restart();

    res.json({
      success: true,
      message: 'تم إعادة تشغيل النظام بنجاح',
      data: result
    });

  } catch (error) {
    console.error('❌ خطأ في إعادة تشغيل النظام:', error);
    res.status(500).json({
      success: false,
      error: 'خطأ في إعادة تشغيل النظام'
    });
  }
});

// POST /api/orders/stop-waseet-sync - إيقاف النظام
router.post('/stop-waseet-sync', async (req, res) => {
  try {
    const waseetSync = require('../services/integrated_waseet_sync');
    const result = waseetSync.stop();

    res.json({
      success: true,
      message: 'تم إيقاف النظام بنجاح',
      data: result
    });

  } catch (error) {
    console.error('❌ خطأ في إيقاف النظام:', error);
    res.status(500).json({
      success: false,
      error: 'خطأ في إيقاف النظام'
    });
  }
});

// POST /api/orders/start-waseet-sync - بدء النظام
router.post('/start-waseet-sync', async (req, res) => {
  try {
    const waseetSync = require('../services/integrated_waseet_sync');
    const result = await waseetSync.start();

    res.json({
      success: true,
      message: 'تم بدء النظام بنجاح',
      data: result
    });

  } catch (error) {
    console.error('❌ خطأ في بدء النظام:', error);
    res.status(500).json({
      success: false,
      error: 'خطأ في بدء النظام'
    });
  }
});

// ===================================
// GET /api/orders/:id - جلب طلب محدد مع العناصر (عادي أو مجدول)
// ⚠️ يجب أن يكون هذا المسار في النهاية لتجنب التعارض مع المسارات الأخرى
// ===================================
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    console.log(`📥 جلب تفاصيل الطلب: ${id}`);

    // ✅ محاولة جلب الطلب العادي أولاً
    let { data: orderData, error: orderError } = await supabase
      .from('orders')
      .select('*')
      .eq('id', id)
      .single();

    let isScheduledOrder = false;

    // إذا لم يوجد، جرب الطلبات المجدولة
    if (orderError) {
      console.log('🔄 لم يوجد في الطلبات العادية، جرب الطلبات المجدولة...');

      const { data: scheduledData, error: scheduledError } = await supabase
        .from('scheduled_orders')
        .select('*')
        .eq('id', id)
        .single();

      if (scheduledError) {
        console.error('❌ خطأ في جلب الطلب:', scheduledError);
        return res.status(404).json({
          success: false,
          error: 'الطلب غير موجود'
        });
      }

      orderData = scheduledData;
      isScheduledOrder = true;
    }

    // ✅ جلب عناصر الطلب
    const itemsTableName = isScheduledOrder ? 'scheduled_order_items' : 'order_items';
    const { data: itemsData, error: itemsError } = await supabase
      .from(itemsTableName)
      .select('*')
      .eq(isScheduledOrder ? 'scheduled_order_id' : 'order_id', id);

    if (itemsError) {
      console.error('⚠️ تحذير: خطأ في جلب عناصر الطلب:', itemsError);
      // لا نرجع خطأ، فقط نرسل الطلب بدون عناصر
    }

    // ✅ دمج البيانات
    const itemsKey = isScheduledOrder ? 'scheduled_order_items' : 'order_items';
    const responseData = {
      ...orderData,
      [itemsKey]: itemsData || []
    };

    console.log(`✅ تم جلب الطلب بنجاح: ${id}`);

    res.json({
      success: true,
      data: responseData,
      isScheduledOrder: isScheduledOrder
    });

  } catch (error) {
    console.error('❌ خطأ في API جلب الطلب:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

module.exports = router;
