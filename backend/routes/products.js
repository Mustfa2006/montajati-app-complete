// مسارات المنتجات - Products Routes
const express = require('express');
const { supabaseAdmin } = require('../config/supabase');

const router = express.Router();

// ✅ الحصول على المنتجات مع Pagination من Supabase عبر الباك إند فقط
// 🎯 الترتيب الذكي: حسب display_order (الأصغر أولاً = 1, 2, 3... → 1000 = آخراً)
router.get('/', async (req, res) => {
  try {
    // قراءة page & limit مع قيم افتراضية وحد أقصى
    const page = Math.max(parseInt(req.query.page, 10) || 1, 1);
    const rawLimit = parseInt(req.query.limit, 10) || 10;
    const limit = Math.min(Math.max(rawLimit, 1), 50); // لا نسمح بأكثر من 50 دفعة واحدة

    // 🎯 نظام الترتيب الذكي الجديد:
    // 1. نجلب كل المنتجات النشطة
    // 2. نرتبها يدوياً حسب display_order (1 أولاً، 1000 آخراً)
    // 3. نطبق pagination بعد الترتيب
    const { data, error } = await supabaseAdmin
      .from('products')
      .select('*')
      .eq('is_active', true);

    if (error) {
      console.error('❌ خطأ في جلب المنتجات من Supabase:', error);
      return res.status(500).json({
        success: false,
        message: 'خطأ في جلب المنتجات من قاعدة البيانات',
        error: error.message,
      });
    }

    // 🎯 ترتيب ذكي يدوي - مضمون 100%
    const allProducts = data || [];
    allProducts.sort((a, b) => {
      // الترتيب الأساسي: display_order (الأصغر أولاً)
      const orderA = a.display_order ?? 999999;
      const orderB = b.display_order ?? 999999;

      if (orderA !== orderB) {
        return orderA - orderB; // 1, 2, 3... 1000
      }

      // الترتيب الثانوي: created_at (الأحدث أولاً)
      const dateA = new Date(a.created_at || 0);
      const dateB = new Date(b.created_at || 0);
      return dateB - dateA;
    });

    // تطبيق pagination بعد الترتيب
    const from = (page - 1) * limit;
    const to = from + limit;
    const paginatedProducts = allProducts.slice(from, to);

    // Debug log للتحقق من الترتيب
    console.log(`📦 صفحة ${page}: ${paginatedProducts.length} منتج (من ${allProducts.length} إجمالي)`);
    paginatedProducts.slice(0, 3).forEach((p, i) => {
      console.log(`  ${i + 1}. ${p.name} - display_order: ${p.display_order}`);
    });

    if (error) {
      console.error('❌ خطأ في جلب المنتجات من Supabase:', error);
      return res.status(500).json({
        success: false,
        message: 'خطأ في جلب المنتجات من قاعدة البيانات',
        error: error.message,
      });
    }

    return res.status(200).json({
      success: true,
      data: {
        products: paginatedProducts,
        pagination: {
          page,
          limit,
          total: allProducts.length,
          hasMore: to < allProducts.length,
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
