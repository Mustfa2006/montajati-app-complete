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

    // معلومات التشخيص محفوظة

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

    // تأكد من أن النظام يعمل
    if (!waseetSync.isRunning) {
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
// GET /api/orders/:id - جلب طلب محدد
// ===================================
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const { data, error } = await supabase
      .from('orders')
      .select('*')
      .eq('id', id)
      .single();

    if (error) {
      console.error('❌ خطأ في جلب الطلب:', error);
      return res.status(404).json({
        success: false,
        error: 'الطلب غير موجود'
      });
    }

    res.json({
      success: true,
      data: data
    });

  } catch (error) {
    console.error('❌ خطأ في API جلب الطلب:', error);
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
        // تحويل الرقم 3 إلى النص العربي الصحيح
        '3': 'قيد التوصيل الى الزبون (في عهدة المندوب)',

        // الحالة الصحيحة تبقى كما هي
        'قيد التوصيل الى الزبون (في عهدة المندوب)': 'قيد التوصيل الى الزبون (في عهدة المندوب)',

        // باقي الحالات تبقى كما هي (لا تتحول)
        'active': 'active',
        'cancelled': 'cancelled'
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
// POST /api/orders - إنشاء طلب جديد
// ===================================
router.post('/', async (req, res) => {
  try {
    const orderData = req.body;
    
    // إضافة معرف فريد وتاريخ الإنشاء
    const newOrder = {
      ...orderData,
      id: orderData.id || `order_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      status: orderData.status || 'active'
    };

    const { data, error } = await supabase
      .from('orders')
      .insert(newOrder)
      .select()
      .single();

    if (error) {
      console.error('❌ خطأ في إنشاء الطلب:', error);
      console.error('📋 تفاصيل الخطأ:', error.message);
      console.error('📋 كود الخطأ:', error.code);
      console.error('📋 البيانات المرسلة:', JSON.stringify(newOrder, null, 2));
      return res.status(500).json({
        success: false,
        error: 'فشل في إنشاء الطلب',
        details: error.message,
        code: error.code
      });
    }

    // تم إنشاء الطلب بصمت

    res.status(201).json({
      success: true,
      message: 'تم إنشاء الطلب بنجاح',
      data: data
    });

  } catch (error) {
    console.error('❌ خطأ في API إنشاء الطلب:', error);
    res.status(500).json({
      success: false,
      error: error.message
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

module.exports = router;
