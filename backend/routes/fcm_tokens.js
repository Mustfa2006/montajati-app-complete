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

// ===================================
// تحديث FCM Token تلقائياً
// ===================================
router.post('/update-token', async (req, res) => {
  try {
    const { userPhone, fcmToken, deviceInfo } = req.body;

    if (!userPhone || !fcmToken) {
      return res.status(400).json({
        success: false,
        message: 'userPhone و fcmToken مطلوبان'
      });
    }

    console.log(`🔄 تحديث FCM Token للمستخدم: ${userPhone}`);

    // تعطيل جميع tokens القديمة للمستخدم
    await supabase
      .from('fcm_tokens')
      .update({ is_active: false })
      .eq('user_phone', userPhone);

    // إضافة Token الجديد
    const { data, error } = await supabase
      .from('fcm_tokens')
      .insert({
        user_phone: userPhone,
        fcm_token: fcmToken,
        is_active: true,
        device_info: deviceInfo || {},
        created_at: new Date().toISOString(),
        last_used_at: new Date().toISOString()
      })
      .select()
      .single();

    if (error) {
      console.error('❌ خطأ في تحديث FCM Token:', error.message);
      return res.status(500).json({
        success: false,
        message: 'خطأ في تحديث FCM Token',
        error: error.message
      });
    }

    console.log(`✅ تم تحديث FCM Token بنجاح للمستخدم: ${userPhone}`);

    res.json({
      success: true,
      message: 'تم تحديث FCM Token بنجاح',
      data: {
        tokenId: data.id,
        userPhone: data.user_phone,
        isActive: data.is_active
      }
    });

  } catch (error) {
    console.error('❌ خطأ في تحديث FCM Token:', error.message);
    res.status(500).json({
      success: false,
      message: 'خطأ داخلي في الخادم',
      error: error.message
    });
  }
});

// ===================================
// التحقق من صحة FCM Token
// ===================================
router.post('/validate-token', async (req, res) => {
  try {
    const { fcmToken, userPhone } = req.body;

    if (!fcmToken) {
      return res.status(400).json({
        success: false,
        message: 'fcmToken مطلوب'
      });
    }

    console.log(`🔍 التحقق من صحة FCM Token للمستخدم: ${userPhone}`);

    // اختبار Token بإرسال رسالة تجريبية
    try {
      const admin = require('firebase-admin');
      const testMessage = {
        token: fcmToken,
        data: {
          type: 'validation_test',
          timestamp: new Date().toISOString()
        }
      };

      await admin.messaging().send(testMessage);

      // تحديث آخر استخدام للـ Token
      if (userPhone) {
        await supabase
          .from('fcm_tokens')
          .update({ last_used_at: new Date().toISOString() })
          .eq('fcm_token', fcmToken)
          .eq('user_phone', userPhone);
      }

      console.log(`✅ FCM Token صالح للمستخدم: ${userPhone}`);

      res.json({
        success: true,
        message: 'FCM Token صالح',
        isValid: true
      });

    } catch (firebaseError) {
      console.log(`❌ FCM Token غير صالح: ${firebaseError.code}`);

      // تعطيل Token غير الصالح
      if (userPhone) {
        await supabase
          .from('fcm_tokens')
          .update({ is_active: false })
          .eq('fcm_token', fcmToken)
          .eq('user_phone', userPhone);
      }

      res.status(400).json({
        success: false,
        message: 'FCM Token غير صالح أو منتهي الصلاحية',
        isValid: false,
        error: firebaseError.code
      });
    }

  } catch (error) {
    console.error('❌ خطأ في التحقق من FCM Token:', error.message);
    res.status(500).json({
      success: false,
      message: 'خطأ داخلي في الخادم',
      error: error.message
    });
  }
});

// ===================================
// تحديث آخر استخدام للـ Token (بدون اختبار Firebase)
// ===================================
router.post('/update-last-used', async (req, res) => {
  try {
    const { fcmToken, userPhone } = req.body;

    if (!fcmToken || !userPhone) {
      return res.status(400).json({
        success: false,
        message: 'fcmToken و userPhone مطلوبان'
      });
    }

    // تحديث آخر استخدام للـ Token بدون اختبار Firebase
    const { error } = await supabase
      .from('fcm_tokens')
      .update({ last_used_at: new Date().toISOString() })
      .eq('fcm_token', fcmToken)
      .eq('user_phone', userPhone)
      .eq('is_active', true);

    if (error) {
      console.error('❌ خطأ في تحديث آخر استخدام للـ Token:', error.message);
      return res.status(500).json({
        success: false,
        message: 'خطأ في تحديث آخر استخدام للـ Token',
        error: error.message
      });
    }

    res.json({
      success: true,
      message: 'تم تحديث آخر استخدام للـ Token بنجاح'
    });

  } catch (error) {
    console.error('❌ خطأ في تحديث آخر استخدام للـ Token:', error.message);
    res.status(500).json({
      success: false,
      message: 'خطأ داخلي في الخادم',
      error: error.message
    });
  }
});

module.exports = router;
