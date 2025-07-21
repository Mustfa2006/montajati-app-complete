// ===================================
// مسارات إدارة FCM Tokens
// FCM Token Management Routes
// ===================================

const express = require('express');
const router = express.Router();
const { createClient } = require('@supabase/supabase-js');
const admin = require('firebase-admin');

// إعداد Supabase
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

// ===================================
// تحديث FCM Token
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
// الحصول على معلومات FCM Tokens للمستخدم
// ===================================
router.get('/user-tokens/:userPhone', async (req, res) => {
  try {
    const { userPhone } = req.params;

    const { data, error } = await supabase
      .from('fcm_tokens')
      .select('id, fcm_token, is_active, created_at, last_used_at, device_info')
      .eq('user_phone', userPhone)
      .order('created_at', { ascending: false });

    if (error) {
      return res.status(500).json({
        success: false,
        message: 'خطأ في جلب FCM Tokens',
        error: error.message
      });
    }

    res.json({
      success: true,
      data: data.map(token => ({
        id: token.id,
        tokenPreview: token.fcm_token.substring(0, 20) + '...',
        isActive: token.is_active,
        createdAt: token.created_at,
        lastUsedAt: token.last_used_at,
        deviceInfo: token.device_info
      }))
    });

  } catch (error) {
    console.error('❌ خطأ في جلب FCM Tokens:', error.message);
    res.status(500).json({
      success: false,
      message: 'خطأ داخلي في الخادم',
      error: error.message
    });
  }
});

// ===================================
// تنظيف FCM Tokens المنتهية الصلاحية
// ===================================
router.post('/cleanup-expired-tokens', async (req, res) => {
  try {
    console.log('🧹 بدء تنظيف FCM Tokens المنتهية الصلاحية...');

    // الحصول على جميع Tokens النشطة
    const { data: tokens, error } = await supabase
      .from('fcm_tokens')
      .select('id, fcm_token, user_phone')
      .eq('is_active', true);

    if (error) {
      return res.status(500).json({
        success: false,
        message: 'خطأ في جلب FCM Tokens',
        error: error.message
      });
    }

    let expiredCount = 0;
    let validCount = 0;

    // فحص كل Token
    for (const tokenData of tokens) {
      try {
        const testMessage = {
          token: tokenData.fcm_token,
          data: { type: 'cleanup_test' }
        };

        await admin.messaging().send(testMessage);
        validCount++;

      } catch (firebaseError) {
        // تعطيل Token المنتهي الصلاحية
        await supabase
          .from('fcm_tokens')
          .update({ is_active: false })
          .eq('id', tokenData.id);

        expiredCount++;
        console.log(`🗑️ تم تعطيل Token منتهي الصلاحية للمستخدم: ${tokenData.user_phone}`);
      }
    }

    console.log(`✅ تم تنظيف ${expiredCount} token منتهي الصلاحية، ${validCount} token صالح`);

    res.json({
      success: true,
      message: 'تم تنظيف FCM Tokens بنجاح',
      data: {
        totalTokens: tokens.length,
        expiredTokens: expiredCount,
        validTokens: validCount
      }
    });

  } catch (error) {
    console.error('❌ خطأ في تنظيف FCM Tokens:', error.message);
    res.status(500).json({
      success: false,
      message: 'خطأ داخلي في الخادم',
      error: error.message
    });
  }
});

module.exports = router;
