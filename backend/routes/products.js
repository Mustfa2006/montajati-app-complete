// مسارات المنتجات - Products Routes
const express = require('express');
const { supabaseAdmin } = require('../config/supabase');

const router = express.Router();

// ✅ الحصول على المنتجات مع Pagination من Supabase عبر الباك إند فقط
router.get('/', async (req, res) => {
  try {
    // قراءة page & limit مع قيم افتراضية وحد أقصى
    const page = Math.max(parseInt(req.query.page, 10) || 1, 1);
    const rawLimit = parseInt(req.query.limit, 10) || 10;
    const limit = Math.min(Math.max(rawLimit, 1), 50); // لا نسمح بأكثر من 50 دفعة واحدة

    const from = (page - 1) * limit;
    const to = from + limit - 1;

    const { data, error } = await supabaseAdmin
      .from('products')
      .select('*')
      .eq('is_active', true)
      .order('created_at', { ascending: false })
      .range(from, to);

    if (error) {
      console.error('❌ خطأ في جلب المنتجات من Supabase:', error);
      return res.status(500).json({
        success: false,
        message: 'خطأ في جلب المنتجات من قاعدة البيانات',
        error: error.message,
      });
    }

    const products = data || [];

    return res.status(200).json({
      success: true,
      data: {
        products,
        pagination: {
          page,
          limit,
          // مبدئياً نستخدم منطق بسيط لمعرفة هل هناك المزيد (نفس منطق الفرونت تقريباً)
          hasMore: products.length >= limit,
        },
      },
    });
  } catch (error) {
    console.error('❌ خطأ في الحصول على المنتجات:', error);
    return res.status(500).json({
      success: false,
      message: 'خطأ في الخادم أثناء جلب المنتجات',
      error: error.message,
    });
  }
});

// ✅ جلب البانرات الإعلانية للصفحة الرئيسية (الإعلانات أعلى صفحة المنتجات)
router.get('/banners', async (req, res) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('advertisement_banners')
      .select('*')
      .eq('is_active', true)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('❌ خطأ في جلب البانرات الإعلانية من Supabase:', error);
      return res.status(500).json({
        success: false,
        message: 'خطأ في جلب البانرات الإعلانية',
        error: error.message,
      });
    }

    const banners = data || [];

    return res.status(200).json({
      success: true,
      data: banners,
    });
  } catch (error) {
    console.error('❌ خطأ غير متوقع في مسار /products/banners:', error);
    return res.status(500).json({
      success: false,
      message: 'خطأ في الخادم أثناء جلب البانرات',
      error: error.message,
    });
  }
});

module.exports = router;
