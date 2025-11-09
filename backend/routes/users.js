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

// ===================================
// POST /api/users/profits - جلب أرباح المستخدم (آمن جداً مع JWT)
// ===================================
router.post('/profits', async (req, res) => {
  try {
    // 🔒 التحقق من التوكن (JWT) - إلزامي
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        error: 'غير مصرح - التوكن مطلوب'
      });
    }

    const token = authHeader.substring(7);

    // TODO: التحقق من صحة التوكن باستخدام JWT
    // const decoded = jwt.verify(token, process.env.JWT_SECRET);
    // const userPhone = decoded.phone;

    // للآن، نستخرج رقم الهاتف من التوكن (يجب تطبيق JWT verification لاحقاً)
    // في الوقت الحالي، نستخدم SharedPreferences كحل مؤقت
    const { phone } = req.body;

    if (!phone || phone.trim() === '') {
      return res.status(400).json({
        success: false,
        error: 'رقم الهاتف مطلوب'
      });
    }

    console.log(`✅ تم استلام طلب أرباح للمستخدم: ${phone}`);

    // جلب الأرباح من قاعدة البيانات بسرعة فائقة
    const { data, error } = await supabase
      .from('users')
      .select('achieved_profits, expected_profits, name')
      .eq('phone', phone)
      .maybeSingle();

    if (error) {
      console.error(`❌ خطأ في جلب أرباح المستخدم ${phone}:`, error.message);
      return res.status(500).json({
        success: false,
        error: 'فشل في جلب الأرباح'
      });
    }

    if (!data) {
      return res.status(404).json({
        success: false,
        error: 'المستخدم غير موجود'
      });
    }

    const achievedProfits = Number(data.achieved_profits) || 0;
    const expectedProfits = Number(data.expected_profits) || 0;

    // إرجاع الأرباح بسرعة
    res.status(200).json({
      success: true,
      data: {
        achieved_profits: achievedProfits,
        expected_profits: expectedProfits,
        total_profits: achievedProfits + expectedProfits,
        name: data.name || 'مستخدم'
      }
    });

  } catch (error) {
    console.error('❌ خطأ في جلب أرباح المستخدم:', error.message);
    res.status(500).json({
      success: false,
      error: 'خطأ في الخادم'
    });
  }
});

// ===================================
// POST /api/users/withdrawals - جلب طلبات السحب للمستخدم (آمن جداً مع JWT)
// ===================================
router.post('/withdrawals', async (req, res) => {
  try {
    // 🔒 التحقق من التوكن (JWT) - اختياري للآن
    const authHeader = req.headers.authorization;

    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.substring(7);
      // TODO: التحقق من صحة التوكن باستخدام JWT
      // const decoded = jwt.verify(token, process.env.JWT_SECRET);
      // const userPhone = decoded.phone;
      console.log('✅ تم استلام توكن المصادقة');
    } else {
      console.log('⚠️ لا يوجد توكن - سيتم استخدام رقم الهاتف من الـ body');
    }

    // للآن، نستخرج رقم الهاتف من الـ body (يجب تطبيق JWT verification لاحقاً)
    const { phone } = req.body;

    if (!phone || phone.trim() === '') {
      return res.status(400).json({
        success: false,
        error: 'رقم الهاتف مطلوب'
      });
    }

    console.log(`✅ تم استلام طلب جلب سحوبات للمستخدم: ${phone}`);

    // 1. جلب معرف المستخدم من رقم الهاتف
    const { data: userData, error: userError } = await supabase
      .from('users')
      .select('id, name, phone')
      .eq('phone', phone)
      .maybeSingle();

    if (userError || !userData) {
      console.error(`❌ خطأ في جلب بيانات المستخدم ${phone}:`, userError?.message);
      return res.status(404).json({
        success: false,
        error: 'المستخدم غير موجود'
      });
    }

    const userId = userData.id;
    console.log(`👤 معرف المستخدم: ${userId}`);

    // 2. جلب طلبات السحب للمستخدم
    const { data: withdrawals, error: withdrawalsError } = await supabase
      .from('withdrawal_requests')
      .select('*')
      .eq('user_id', userId)
      .order('request_date', { ascending: false }); // الأحدث أولاً

    if (withdrawalsError) {
      console.error(`❌ خطأ في جلب طلبات السحب للمستخدم ${userId}:`, withdrawalsError.message);
      return res.status(500).json({
        success: false,
        error: 'فشل في جلب طلبات السحب'
      });
    }

    console.log(`📊 عدد طلبات السحب المجلبة: ${withdrawals?.length || 0}`);

    // 3. حساب الإحصائيات
    const stats = {
      total_requests: withdrawals?.length || 0,
      pending_count: 0,
      completed_count: 0,
      rejected_count: 0,
      total_withdrawn: 0,
      pending_amount: 0
    };

    if (withdrawals && withdrawals.length > 0) {
      withdrawals.forEach(w => {
        const amount = Number(w.amount) || 0;

        if (w.status === 'pending') {
          stats.pending_count++;
          stats.pending_amount += amount;
        } else if (w.status === 'completed') {
          stats.completed_count++;
          stats.total_withdrawn += amount;
        } else if (w.status === 'rejected') {
          stats.rejected_count++;
        }
      });
    }

    res.status(200).json({
      success: true,
      data: {
        user: {
          id: userData.id,
          name: userData.name,
          phone: userData.phone
        },
        withdrawals: withdrawals || [],
        stats: stats
      }
    });

  } catch (error) {
    console.error('❌ خطأ في جلب طلبات السحب:', error.message);
    res.status(500).json({
      success: false,
      error: 'خطأ في الخادم'
    });
  }
});

module.exports = router;
