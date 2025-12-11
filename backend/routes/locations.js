/**
 * 📍 مسارات المواقع - المحافظات والمدن
 * Locations API Routes - Provinces and Cities
 */

const express = require('express');
const router = express.Router();
const { createClient } = require('@supabase/supabase-js');

// إعداد Supabase
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

/**
 * 🏛️ GET /api/locations/provinces
 * جلب جميع المحافظات
 */
router.get('/provinces', async (req, res) => {
  try {
    console.log('📍 جلب المحافظات...');
    
    const { provider } = req.query;
    const providerName = provider || 'alwaseet';
    
    const { data, error } = await supabase
      .from('provinces')
      .select('id, name, external_id, provider_name')
      .eq('provider_name', providerName)
      .order('name');
    
    if (error) {
      console.error('❌ خطأ في جلب المحافظات:', error);
      return res.status(500).json({
        success: false,
        message: 'خطأ في جلب المحافظات',
        error: error.message
      });
    }
    
    console.log(`✅ تم جلب ${data.length} محافظة`);
    
    res.json({
      success: true,
      data: data.map(province => ({
        id: province.id,
        name: province.name,
        externalId: province.external_id
      })),
      count: data.length,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('❌ خطأ غير متوقع في جلب المحافظات:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم',
      error: error.message
    });
  }
});

/**
 * 🏙️ GET /api/locations/provinces/:provinceId/cities
 * جلب مدن محافظة محددة
 */
router.get('/provinces/:provinceId/cities', async (req, res) => {
  try {
    const { provinceId } = req.params;
    const { provider } = req.query;
    const providerName = provider || 'alwaseet';
    
    console.log(`📍 جلب مدن المحافظة ${provinceId}...`);
    
    if (!provinceId) {
      return res.status(400).json({
        success: false,
        message: 'معرف المحافظة مطلوب'
      });
    }
    
    const { data, error } = await supabase
      .from('cities')
      .select('id, name, external_id, province_id, provider_name')
      .eq('province_id', provinceId)
      .eq('provider_name', providerName)
      .order('name');
    
    if (error) {
      console.error('❌ خطأ في جلب المدن:', error);
      return res.status(500).json({
        success: false,
        message: 'خطأ في جلب المدن',
        error: error.message
      });
    }
    
    console.log(`✅ تم جلب ${data.length} مدينة للمحافظة ${provinceId}`);
    
    res.json({
      success: true,
      data: data.map(city => ({
        id: city.id,
        name: city.name,
        externalId: city.external_id,
        provinceId: city.province_id
      })),
      count: data.length,
      provinceId: provinceId,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('❌ خطأ غير متوقع في جلب المدن:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم',
      error: error.message
    });
  }
});

/**
 * 🔍 GET /api/locations/search
 * البحث في المحافظات والمدن
 */
router.get('/search', async (req, res) => {
  try {
    const { query, type, provinceId } = req.query;
    
    if (!query || query.length < 2) {
      return res.status(400).json({
        success: false,
        message: 'كلمة البحث يجب أن تكون حرفين على الأقل'
      });
    }
    
    let results = { provinces: [], cities: [] };
    
    // البحث في المحافظات
    if (!type || type === 'provinces') {
      const { data: provinces } = await supabase
        .from('provinces')
        .select('id, name, external_id')
        .ilike('name', `%${query}%`)
        .eq('provider_name', 'alwaseet')
        .limit(10);
      
      results.provinces = provinces || [];
    }
    
    // البحث في المدن
    if (!type || type === 'cities') {
      let citiesQuery = supabase
        .from('cities')
        .select('id, name, external_id, province_id')
        .ilike('name', `%${query}%`)
        .eq('provider_name', 'alwaseet')
        .limit(20);
      
      if (provinceId) {
        citiesQuery = citiesQuery.eq('province_id', provinceId);
      }
      
      const { data: cities } = await citiesQuery;
      results.cities = cities || [];
    }
    
    res.json({
      success: true,
      data: results,
      query: query,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('❌ خطأ في البحث:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في البحث',
      error: error.message
    });
  }
});

module.exports = router;
