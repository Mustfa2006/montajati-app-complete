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

    // البحث
    if (search) {
      query = query.or(`customer_name.ilike.%${search}%,order_number.ilike.%${search}%,customer_phone.ilike.%${search}%`);
    }

    // التصفح
    const offset = (page - 1) * limit;
    query = query.range(offset, offset + limit - 1);

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
    const { id } = req.params;
    const { status, notes, changedBy = 'admin' } = req.body;

    console.log(`🔄 تحديث حالة الطلب ${id} إلى ${status}`);
    console.log(`📝 ملاحظات: ${notes || 'لا توجد'}`);
    console.log(`👤 تم التغيير بواسطة: ${changedBy}`);

    // التحقق من البيانات المطلوبة
    if (!status) {
      return res.status(400).json({
        success: false,
        error: 'الحالة الجديدة مطلوبة'
      });
    }

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

    // تحديث حالة الطلب
    const { error: updateError } = await supabase
      .from('orders')
      .update({
        status: status,
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

    // إضافة سجل في تاريخ الحالات
    try {
      await supabase
        .from('order_status_history')
        .insert({
          order_id: id,
          old_status: oldStatus,
          new_status: status,
          changed_by: changedBy,
          change_reason: notes || 'تم تحديث الحالة من لوحة التحكم',
          created_at: new Date().toISOString()
        });
      console.log('✅ تم إضافة سجل تاريخ الحالة');
    } catch (historyError) {
      console.warn('⚠️ تحذير: فشل في حفظ سجل التاريخ:', historyError);
    }

    // إضافة ملاحظة إذا كانت متوفرة
    if (notes && notes.trim()) {
      try {
        await supabase
          .from('order_notes')
          .insert({
            order_id: id,
            content: `تم تحديث الحالة إلى: ${status} - ${notes}`,
            type: 'status_change',
            is_internal: true,
            created_by: changedBy,
            created_at: new Date().toISOString()
          });
        console.log('✅ تم إضافة ملاحظة الحالة');
      } catch (noteError) {
        console.warn('⚠️ تحذير: فشل في إضافة الملاحظة:', noteError);
      }
    }

    console.log(`✅ تم تحديث حالة الطلب ${id} بنجاح`);

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
      return res.status(500).json({
        success: false,
        error: 'فشل في إنشاء الطلب'
      });
    }

    console.log(`✅ تم إنشاء طلب جديد: ${data.id}`);

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

module.exports = router;
