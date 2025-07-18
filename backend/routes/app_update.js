// ===================================
// نظام تحديث التطبيق
// App Update System
// ===================================

const express = require('express');
const router = express.Router();
const { createClient } = require('@supabase/supabase-js');

// إعداد Supabase
const supabaseUrl = process.env.SUPABASE_URL || 'https://fqdhskaolzfavapmqodl.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZxZGhza2FvbHpmYXZhcG1xb2RsIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczNzE5NzI2NiwiZXhwIjoyMDUyNzU3MjY2fQ.tRHMAogrSzjRwSIJ9-m0YMoPhlHeR6U8kfob0wyvf_I';
const supabase = createClient(supabaseUrl, supabaseKey);

// ===================================
// فحص التحديث
// Check for Updates
// ===================================

router.get('/check-update', async (req, res) => {
  try {
    const currentVersion = req.query.current_version || '1.0.0';
    const platform = req.query.platform || 'android';
    
    console.log(`🔍 فحص التحديث للإصدار: ${currentVersion} - المنصة: ${platform}`);
    
    // جلب معلومات آخر إصدار من قاعدة البيانات
    const { data: latestVersion, error } = await supabase
      .from('app_versions')
      .select('*')
      .eq('platform', platform)
      .eq('is_active', true)
      .order('version_code', { ascending: false })
      .limit(1)
      .single();

    if (error) {
      console.error('❌ خطأ في جلب معلومات الإصدار:', error);
      return res.status(500).json({
        success: false,
        error: 'خطأ في فحص التحديث'
      });
    }

    if (!latestVersion) {
      return res.json({
        success: true,
        has_update: false,
        message: 'لا توجد تحديثات متاحة'
      });
    }

    // مقارنة الإصدارات
    const currentVersionCode = parseInt(currentVersion.split('+')[1] || '1');
    const latestVersionCode = latestVersion.version_code;
    
    const hasUpdate = latestVersionCode > currentVersionCode;
    
    console.log(`📊 الإصدار الحالي: ${currentVersionCode}, الأحدث: ${latestVersionCode}, يحتاج تحديث: ${hasUpdate}`);

    const response = {
      success: true,
      has_update: hasUpdate,
      current_version: currentVersion,
      latest_version: latestVersion.version_name,
      latest_version_code: latestVersionCode,
      download_url: latestVersion.download_url,
      file_size: latestVersion.file_size,
      release_notes: latestVersion.release_notes,
      is_force_update: latestVersion.is_force_update,
      min_supported_version: latestVersion.min_supported_version,
      release_date: latestVersion.created_at,
      message: hasUpdate ? 'يتوفر تحديث جديد!' : 'التطبيق محدث'
    };

    res.json(response);

  } catch (error) {
    console.error('❌ خطأ في فحص التحديث:', error);
    res.status(500).json({
      success: false,
      error: 'خطأ في الخادم'
    });
  }
});

// ===================================
// رفع إصدار جديد (للمطورين)
// Upload New Version (For Developers)
// ===================================

router.post('/upload-version', async (req, res) => {
  try {
    const {
      version_name,
      version_code,
      platform,
      download_url,
      file_size,
      release_notes,
      is_force_update,
      min_supported_version
    } = req.body;

    console.log(`📤 رفع إصدار جديد: ${version_name} (${version_code})`);

    // إلغاء تفعيل الإصدارات السابقة
    await supabase
      .from('app_versions')
      .update({ is_active: false })
      .eq('platform', platform);

    // إضافة الإصدار الجديد
    const { data, error } = await supabase
      .from('app_versions')
      .insert({
        version_name,
        version_code,
        platform,
        download_url,
        file_size,
        release_notes,
        is_force_update: is_force_update || false,
        min_supported_version,
        is_active: true,
        created_at: new Date().toISOString()
      })
      .select()
      .single();

    if (error) {
      console.error('❌ خطأ في رفع الإصدار:', error);
      return res.status(500).json({
        success: false,
        error: 'خطأ في رفع الإصدار'
      });
    }

    console.log('✅ تم رفع الإصدار بنجاح');

    res.json({
      success: true,
      message: 'تم رفع الإصدار بنجاح',
      version: data
    });

  } catch (error) {
    console.error('❌ خطأ في رفع الإصدار:', error);
    res.status(500).json({
      success: false,
      error: 'خطأ في الخادم'
    });
  }
});

// ===================================
// جلب جميع الإصدارات
// Get All Versions
// ===================================

router.get('/versions', async (req, res) => {
  try {
    const platform = req.query.platform || 'android';
    
    const { data: versions, error } = await supabase
      .from('app_versions')
      .select('*')
      .eq('platform', platform)
      .order('version_code', { ascending: false });

    if (error) {
      console.error('❌ خطأ في جلب الإصدارات:', error);
      return res.status(500).json({
        success: false,
        error: 'خطأ في جلب الإصدارات'
      });
    }

    res.json({
      success: true,
      versions: versions || []
    });

  } catch (error) {
    console.error('❌ خطأ في جلب الإصدارات:', error);
    res.status(500).json({
      success: false,
      error: 'خطأ في الخادم'
    });
  }
});

// ===================================
// إحصائيات التحديث
// Update Statistics
// ===================================

router.post('/update-stats', async (req, res) => {
  try {
    const {
      user_id,
      old_version,
      new_version,
      update_status, // 'started', 'completed', 'failed'
      device_info
    } = req.body;

    const { error } = await supabase
      .from('update_logs')
      .insert({
        user_id,
        old_version,
        new_version,
        update_status,
        device_info,
        created_at: new Date().toISOString()
      });

    if (error) {
      console.error('❌ خطأ في حفظ إحصائيات التحديث:', error);
    }

    res.json({
      success: true,
      message: 'تم حفظ الإحصائيات'
    });

  } catch (error) {
    console.error('❌ خطأ في حفظ الإحصائيات:', error);
    res.status(500).json({
      success: false,
      error: 'خطأ في الخادم'
    });
  }
});

module.exports = router;
