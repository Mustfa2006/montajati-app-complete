// مسارات المستخدمين - Users Routes
const express = require('express');
const User = require('../models/User');
const { createClient } = require('@supabase/supabase-js');

const router = express.Router();

// إعداد Supabase
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

// الحصول على جميع المستخدمين (للأدمن فقط)
router.get('/', async (req, res) => {
  try {
    const users = await User.find().select('-password');

    res.status(200).json({
      success: true,
      results: users.length,
      data: {
        users,
      },
    });
  } catch (error) {
    console.error('خطأ في الحصول على المستخدمين:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم',
    });
  }
});

// الحصول على مستخدم محدد
router.get('/:id', async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-password');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'المستخدم غير موجود',
      });
    }

    res.status(200).json({
      success: true,
      data: {
        user,
      },
    });
  } catch (error) {
    console.error('خطأ في الحصول على المستخدم:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم',
    });
  }
});

// تحديث بيانات المستخدم
router.patch('/:id', async (req, res) => {
  try {
    const { name, email, phone } = req.body;

    const user = await User.findByIdAndUpdate(
      req.params.id,
      { name, email, phone },
      {
        new: true,
        runValidators: true,
      }
    ).select('-password');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'المستخدم غير موجود',
      });
    }

    res.status(200).json({
      success: true,
      data: {
        user,
      },
    });
  } catch (error) {
    console.error('خطأ في تحديث المستخدم:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم',
    });
  }
});

// حذف مستخدم
router.delete('/:id', async (req, res) => {
  try {
    const user = await User.findByIdAndDelete(req.params.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'المستخدم غير موجود',
      });
    }

    res.status(204).json({
      success: true,
      data: null,
    });
  } catch (error) {
    console.error('خطأ في حذف المستخدم:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم',
    });
  }
});

// ===================================
// حفظ FCM Token للإشعارات
// ===================================
router.post('/fcm-token', async (req, res) => {
  try {
    const { user_phone, fcm_token, device_info } = req.body;

    // التحقق من البيانات المطلوبة
    if (!user_phone || !fcm_token) {
      return res.status(400).json({
        success: false,
        message: 'user_phone و fcm_token مطلوبان'
      });
    }

    console.log(`📱 استلام FCM Token للمستخدم: ${user_phone}`);

    // حفظ أو تحديث FCM Token
    const { data, error } = await supabase
      .from('fcm_tokens')
      .upsert({
        user_phone: user_phone,
        fcm_token: fcm_token,
        device_info: device_info || {},
        is_active: true,
        last_used_at: new Date().toISOString()
      }, {
        onConflict: 'user_phone,fcm_token'
      })
      .select();

    if (error) {
      console.error('❌ خطأ في حفظ FCM Token:', error);
      return res.status(500).json({
        success: false,
        message: 'خطأ في حفظ FCM Token',
        error: error.message
      });
    }

    console.log(`✅ تم حفظ FCM Token للمستخدم: ${user_phone}`);

    res.json({
      success: true,
      message: 'تم حفظ FCM Token بنجاح',
      data: data
    });

  } catch (error) {
    console.error('❌ خطأ في endpoint FCM Token:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم',
      error: error.message
    });
  }
});

// ===================================
// جلب FCM Tokens للمستخدم
// ===================================
router.get('/fcm-tokens/:user_phone', async (req, res) => {
  try {
    const { user_phone } = req.params;

    const { data, error } = await supabase
      .from('fcm_tokens')
      .select('*')
      .eq('user_phone', user_phone)
      .eq('is_active', true)
      .order('updated_at', { ascending: false });

    if (error) {
      return res.status(500).json({
        success: false,
        message: 'خطأ في جلب FCM Tokens',
        error: error.message
      });
    }

    res.json({
      success: true,
      data: data,
      count: data?.length || 0
    });

  } catch (error) {
    console.error('❌ خطأ في جلب FCM Tokens:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم',
      error: error.message
    });
  }
});

module.exports = router;
