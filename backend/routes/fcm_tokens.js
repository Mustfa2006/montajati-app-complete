// ===================================
// مسارات إدارة FCM Tokens
// FCM Tokens Management Routes
// ===================================

const express = require('express');
const router = express.Router();
const { createClient } = require('@supabase/supabase-js');

// إعداد Supabase
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

/**
 * تسجيل FCM Token جديد
 * POST /api/fcm-tokens/register
 */
router.post('/register', async (req, res) => {
  try {
    const { userPhone, fcmToken, deviceInfo } = req.body;

    if (!userPhone || !fcmToken) {
      return res.status(400).json({
        success: false,
        message: 'userPhone و fcmToken مطلوبان'
      });
    }

    // التحقق من وجود الرمز مسبقاً
    const { data: existingToken } = await supabase
      .from('fcm_tokens')
      .select('id')
      .eq('user_phone', userPhone)
      .eq('fcm_token', fcmToken)
      .maybeSingle();

    if (existingToken) {
      // تحديث الرمز الموجود
      const { error: updateError } = await supabase
        .from('fcm_tokens')
        .update({
          is_active: true,
          last_used_at: new Date().toISOString(),
          device_info: deviceInfo || {}
        })
        .eq('id', existingToken.id);

      if (updateError) throw updateError;

      return res.json({
        success: true,
        message: 'تم تحديث FCM Token بنجاح',
        action: 'updated'
      });
    }

    // إنشاء رمز جديد
    const { error: insertError } = await supabase
      .from('fcm_tokens')
      .insert({
        user_phone: userPhone,
        fcm_token: fcmToken,
        device_info: deviceInfo || {},
        is_active: true,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        last_used_at: new Date().toISOString()
      });

    if (insertError) throw insertError;

    res.json({
      success: true,
      message: 'تم تسجيل FCM Token بنجاح',
      action: 'created'
    });

  } catch (error) {
    console.error('❌ خطأ في تسجيل FCM Token:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في تسجيل FCM Token',
      error: error.message
    });
  }
});

/**
 * الحصول على FCM Tokens للمستخدم
 * GET /api/fcm-tokens/user/:userPhone
 */
router.get('/user/:userPhone', async (req, res) => {
  try {
    const { userPhone } = req.params;

    const { data: tokens, error } = await supabase
      .from('fcm_tokens')
      .select('*')
      .eq('user_phone', userPhone)
      .eq('is_active', true)
      .order('created_at', { ascending: false });

    if (error) throw error;

    res.json({
      success: true,
      data: tokens || [],
      count: tokens?.length || 0
    });

  } catch (error) {
    console.error('❌ خطأ في جلب FCM Tokens:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في جلب FCM Tokens',
      error: error.message
    });
  }
});

/**
 * حذف FCM Token
 * DELETE /api/fcm-tokens/:tokenId
 */
router.delete('/:tokenId', async (req, res) => {
  try {
    const { tokenId } = req.params;

    const { error } = await supabase
      .from('fcm_tokens')
      .update({ is_active: false })
      .eq('id', tokenId);

    if (error) throw error;

    res.json({
      success: true,
      message: 'تم حذف FCM Token بنجاح'
    });

  } catch (error) {
    console.error('❌ خطأ في حذف FCM Token:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في حذف FCM Token',
      error: error.message
    });
  }
});

/**
 * إحصائيات FCM Tokens
 * GET /api/fcm-tokens/stats
 */
router.get('/stats', async (req, res) => {
  try {
    // إجمالي الرموز النشطة
    const { count: activeTokens } = await supabase
      .from('fcm_tokens')
      .select('*', { count: 'exact', head: true })
      .eq('is_active', true);

    // إجمالي الرموز
    const { count: totalTokens } = await supabase
      .from('fcm_tokens')
      .select('*', { count: 'exact', head: true });

    // المستخدمين الفريدين
    const { data: uniqueUsers } = await supabase
      .from('fcm_tokens')
      .select('user_phone')
      .eq('is_active', true);

    const uniqueUserCount = new Set(uniqueUsers?.map(u => u.user_phone)).size;

    res.json({
      success: true,
      data: {
        total: {
          tokens: totalTokens || 0,
          activeTokens: activeTokens || 0,
          inactiveTokens: (totalTokens || 0) - (activeTokens || 0),
          uniqueUsers: uniqueUserCount
        },
        health: {
          activePercentage: totalTokens > 0 ? ((activeTokens / totalTokens) * 100).toFixed(2) : 0
        }
      }
    });

  } catch (error) {
    console.error('❌ خطأ في جلب إحصائيات FCM Tokens:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في جلب الإحصائيات',
      error: error.message
    });
  }
});

/**
 * تنظيف FCM Tokens القديمة
 * POST /api/fcm-tokens/cleanup
 */
router.post('/cleanup', async (req, res) => {
  try {
    // حذف الرموز القديمة (أكثر من 30 يوم)
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const { error } = await supabase
      .from('fcm_tokens')
      .update({ is_active: false })
      .lt('last_used_at', thirtyDaysAgo.toISOString());

    if (error) throw error;

    res.json({
      success: true,
      message: 'تم تنظيف FCM Tokens القديمة بنجاح'
    });

  } catch (error) {
    console.error('❌ خطأ في تنظيف FCM Tokens:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في تنظيف FCM Tokens',
      error: error.message
    });
  }
});

module.exports = router;
