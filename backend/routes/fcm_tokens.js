// ===================================
// مسار FCM Tokens للإشعارات
// ===================================

const express = require('express');
const { createClient } = require('@supabase/supabase-js');

const router = express.Router();

// إعداد Supabase
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

// ===================================
// تسجيل FCM Token (يستدعيه التطبيق تلقائياً)
// ===================================
router.post('/register', async (req, res) => {
  try {
    const { user_phone, fcm_token, device_info } = req.body;

    // التحقق من البيانات
    if (!user_phone || !fcm_token) {
      return res.status(400).json({
        success: false,
        message: 'رقم الهاتف و FCM Token مطلوبان'
      });
    }

    console.log(`📱 تسجيل إشعارات للمستخدم: ${user_phone}`);

    // حفظ FCM Token في قاعدة البيانات
    const { data, error } = await supabase
      .from('fcm_tokens')
      .upsert({
        user_phone: user_phone,
        token: fcm_token,
        device_info: device_info || { platform: 'mobile' },
        is_active: true,
        last_used_at: new Date().toISOString()
      }, {
        onConflict: 'user_phone,token'
      })
      .select();

    if (error) {
      console.error('❌ خطأ في حفظ FCM Token:', error);
      return res.status(500).json({
        success: false,
        message: 'خطأ في تسجيل الإشعارات'
      });
    }

    console.log(`✅ تم تسجيل الإشعارات للمستخدم: ${user_phone}`);
    
    res.json({
      success: true,
      message: 'تم تسجيل الإشعارات بنجاح',
      user_phone: user_phone
    });

  } catch (error) {
    console.error('❌ خطأ في تسجيل FCM Token:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم'
    });
  }
});

// ===================================
// إلغاء تسجيل الإشعارات
// ===================================
router.post('/unregister', async (req, res) => {
  try {
    const { user_phone, fcm_token } = req.body;

    if (!user_phone) {
      return res.status(400).json({
        success: false,
        message: 'رقم الهاتف مطلوب'
      });
    }

    // إلغاء تفعيل FCM Token
    const { error } = await supabase
      .from('fcm_tokens')
      .update({ is_active: false })
      .eq('user_phone', user_phone);

    if (error) {
      return res.status(500).json({
        success: false,
        message: 'خطأ في إلغاء التسجيل'
      });
    }

    console.log(`🔕 تم إلغاء تسجيل الإشعارات للمستخدم: ${user_phone}`);
    
    res.json({
      success: true,
      message: 'تم إلغاء تسجيل الإشعارات'
    });

  } catch (error) {
    console.error('❌ خطأ في إلغاء تسجيل FCM Token:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم'
    });
  }
});

// ===================================
// فحص حالة التسجيل
// ===================================
router.get('/status/:user_phone', async (req, res) => {
  try {
    const { user_phone } = req.params;

    const { data, error } = await supabase
      .from('fcm_tokens')
      .select('*')
      .eq('user_phone', user_phone)
      .eq('is_active', true);

    if (error) {
      return res.status(500).json({
        success: false,
        message: 'خطأ في فحص الحالة'
      });
    }

    const isRegistered = data && data.length > 0;
    
    res.json({
      success: true,
      is_registered: isRegistered,
      tokens_count: data?.length || 0,
      user_phone: user_phone
    });

  } catch (error) {
    console.error('❌ خطأ في فحص حالة التسجيل:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم'
    });
  }
});

// ===================================
// اختبار إرسال إشعار
// ===================================
router.post('/test-notification', async (req, res) => {
  try {
    const { user_phone, title, message } = req.body;

    if (!user_phone) {
      return res.status(400).json({
        success: false,
        message: 'رقم الهاتف مطلوب'
      });
    }

    // إنشاء إشعار تجريبي
    const { error } = await supabase
      .from('notification_queue')
      .insert({
        order_id: `TEST-${Date.now()}`,
        user_phone: user_phone,
        customer_name: 'اختبار الإشعارات',
        old_status: 'test',
        new_status: 'test_notification',
        notification_data: {
          title: title || 'إشعار تجريبي',
          message: message || 'هذا إشعار تجريبي للتأكد من عمل النظام',
          type: 'test',
          priority: 1,
          timestamp: Date.now()
        },
        priority: 1
      });

    if (error) {
      return res.status(500).json({
        success: false,
        message: 'خطأ في إرسال الإشعار التجريبي'
      });
    }

    console.log(`🧪 تم إرسال إشعار تجريبي للمستخدم: ${user_phone}`);
    
    res.json({
      success: true,
      message: 'تم إرسال إشعار تجريبي'
    });

  } catch (error) {
    console.error('❌ خطأ في الإشعار التجريبي:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم'
    });
  }
});

module.exports = router;
