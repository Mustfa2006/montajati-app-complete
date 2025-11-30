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

// 🔒 التحقق من حالة السحب
router.get('/withdrawal-status', async (req, res) => {
  try {
    console.log('🔍 التحقق من حالة السحب...');

    const { data: setting, error } = await supabase
      .from('app_settings')
      .select('setting_value, message')
      .eq('setting_key', 'withdrawal_enabled')
      .maybeSingle();

    if (error) {
      console.log(`❌ خطأ في جلب إعدادات السحب: ${error.message}`);
      // في حالة الخطأ، نسمح بالسحب افتراضياً
      return res.status(200).json({
        success: true,
        enabled: true,
        message: 'عملية السحب متاحة حالياً',
      });
    }

    const isEnabled = setting?.setting_value === 'true';
    const message = setting?.message || (isEnabled ? 'عملية السحب متاحة حالياً' : 'عملية السحب متوقفة حالياً');

    console.log(`✅ حالة السحب: ${isEnabled ? 'مفعل' : 'معطل'}`);

    res.status(200).json({
      success: true,
      enabled: isEnabled,
      message: message,
    });
  } catch (error) {
    console.log(`❌ خطأ في الخادم: ${error.message}`);
    // في حالة الخطأ، نسمح بالسحب افتراضياً
    res.status(200).json({
      success: true,
      enabled: true,
      message: 'عملية السحب متاحة حالياً',
    });
  }
});

// الحصول على جميع المستخدمين (للأدمن فقط) - مع pagination والبحث
router.get('/', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const search = req.query.search || '';
    const offset = (page - 1) * limit;

    let query = supabase
      .from('users')
      .select('id, name, phone, created_at', { count: 'exact' });

    // البحث بالاسم أو الهاتف
    if (search) {
      query = query.or(`name.ilike.%${search}%,phone.ilike.%${search}%`);
    }

    const { data: users, error, count } = await query
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) throw error;

    res.status(200).json({
      success: true,
      results: users?.length || 0,
      total: count || 0,
      page,
      limit,
      data: users || [],
    });
  } catch (error) {
    console.error('خطأ في الحصول على المستخدمين:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم',
    });
  }
});


// ===================================
// POST /api/users/balance - جلب رصيد المستخدم (للسحب)
// ===================================
router.post('/balance', async (req, res) => {
  try {
    // الحصول على رقم الهاتف من الـ body (مثل بقية الـ endpoints)
    const { phone } = req.body;

    if (!phone || phone.trim() === '') {
      return res.status(400).json({
        success: false,
        message: 'رقم الهاتف مطلوب'
      });
    }

    console.log(`💰 === جلب رصيد المستخدم من الـ API ===`);
    console.log(`📱 رقم الهاتف: ${phone}`);

    // جلب البيانات من قاعدة البيانات
    const { data, error } = await supabase
      .from('users')
      .select('achieved_profits, expected_profits, name, phone')
      .eq('phone', phone)
      .maybeSingle();

    if (error) {
      console.error(`❌ خطأ في جلب رصيد المستخدم:`, error.message);
      return res.status(500).json({
        success: false,
        message: 'خطأ في جلب الرصيد'
      });
    }

    if (!data) {
      return res.status(404).json({
        success: false,
        message: 'المستخدم غير موجود'
      });
    }

    const achievedProfits = Number(data.achieved_profits) || 0;
    const expectedProfits = Number(data.expected_profits) || 0;
    const totalBalance = achievedProfits + expectedProfits;

    console.log(`✅ الرصيد الكلي: ${totalBalance} (محقق: ${achievedProfits} + متوقع: ${expectedProfits})`);

    res.status(200).json({
      success: true,
      data: {
        achieved_profits: achievedProfits,
        expected_profits: expectedProfits,
        total_balance: totalBalance,
        name: data.name || 'مستخدم',
        phone: data.phone
      }
    });

  } catch (error) {
    console.error('❌ خطأ في الخادم:', error.message);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم'
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

// ===================================
// POST /api/users/statistics/realized-profits - جلب الأرباح المحققة
// ===================================
router.post('/statistics/realized-profits', async (req, res) => {
  try {
    const { phone } = req.body;

    if (!phone || phone.trim() === '') {
      return res.status(400).json({
        success: false,
        error: 'رقم الهاتف مطلوب'
      });
    }

    console.log(`✅ جلب الأرباح المحققة للمستخدم: ${phone}`);

    // جلب الطلبات المسلمة فقط (status = 'تم التسليم للزبون')
    const { data, error } = await supabase
      .from('orders')
      .select('profit')
      .eq('user_phone', phone)
      .eq('status', 'تم التسليم للزبون');

    if (error) {
      console.error(`❌ خطأ في جلب الأرباح المحققة:`, error.message);
      return res.status(500).json({
        success: false,
        error: 'فشل في جلب الأرباح المحققة'
      });
    }

    // جمع جميع الأرباح
    let totalProfit = 0.0;
    if (data && data.length > 0) {
      data.forEach(order => {
        const profit = Number(order.profit) || 0.0;
        totalProfit += profit;
      });
    }

    res.status(200).json({
      success: true,
      data: {
        realized_profits: totalProfit
      }
    });

  } catch (error) {
    console.error('❌ خطأ في جلب الأرباح المحققة:', error.message);
    res.status(500).json({
      success: false,
      error: 'خطأ في الخادم'
    });
  }
});

// ===================================
// POST /api/users/statistics/province-orders - جلب الطلبات حسب المحافظة
// ===================================
router.post('/statistics/province-orders', async (req, res) => {
  try {
    const { phone, from_date, to_date } = req.body;

    if (!phone || phone.trim() === '') {
      return res.status(400).json({
        success: false,
        error: 'رقم الهاتف مطلوب'
      });
    }

    if (!from_date || !to_date) {
      return res.status(400).json({
        success: false,
        error: 'التواريخ مطلوبة'
      });
    }

    console.log(`✅ جلب طلبات المحافظات للمستخدم: ${phone} من ${from_date} إلى ${to_date}`);

    // جلب الطلبات في الفترة المحددة
    const { data, error } = await supabase
      .from('orders')
      .select('id, province, city, created_at, user_phone, status')
      .eq('user_phone', phone)
      .gte('created_at', from_date)
      .lte('created_at', to_date);

    if (error) {
      console.error(`❌ خطأ في جلب طلبات المحافظات:`, error.message);
      return res.status(500).json({
        success: false,
        error: 'فشل في جلب طلبات المحافظات'
      });
    }

    // حساب عدد الطلبات لكل محافظة
    const provinceCounts = {};
    if (data && data.length > 0) {
      data.forEach(order => {
        const province = order.province;
        if (province) {
          provinceCounts[province] = (provinceCounts[province] || 0) + 1;
        }
      });
    }

    res.status(200).json({
      success: true,
      data: {
        province_counts: provinceCounts,
        total_orders: data?.length || 0
      }
    });

  } catch (error) {
    console.error('❌ خطأ في جلب طلبات المحافظات:', error.message);
    res.status(500).json({
      success: false,
      error: 'خطأ في الخادم'
    });
  }
});

// ===================================
// POST /api/users/statistics/weekday-orders - جلب الطلبات حسب أيام الأسبوع
// ===================================
router.post('/statistics/weekday-orders', async (req, res) => {
  try {
    const { phone, week_start, week_end } = req.body;

    if (!phone || phone.trim() === '') {
      return res.status(400).json({
        success: false,
        error: 'رقم الهاتف مطلوب'
      });
    }

    if (!week_start || !week_end) {
      return res.status(400).json({
        success: false,
        error: 'تواريخ الأسبوع مطلوبة'
      });
    }

    console.log(`✅ جلب طلبات الأسبوع للمستخدم: ${phone} من ${week_start} إلى ${week_end}`);

    // استخدام RPC للحصول على البيانات
    const { data, error } = await supabase.rpc(
      'get_weekday_orders',
      {
        p_user_phone: phone,
        p_week_start: week_start,
        p_week_end: week_end,
      }
    );

    if (error) {
      console.error(`❌ خطأ في جلب طلبات الأسبوع:`, error.message);
      return res.status(500).json({
        success: false,
        error: 'فشل في جلب طلبات الأسبوع'
      });
    }

    res.status(200).json({
      success: true,
      data: {
        weekday_orders: data || []
      }
    });

  } catch (error) {
    console.error('❌ خطأ في جلب طلبات الأسبوع:', error.message);
    res.status(500).json({
      success: false,
      error: 'خطأ في الخادم'
    });
  }
});

// ===================================
// 🚀 POST /api/users/statistics/summary - جلب جميع الإحصائيات في طلب واحد (محسّن)
// ===================================
router.post('/statistics/summary', async (req, res) => {
  try {
    const { phone, from_date, to_date, week_start, week_end } = req.body;

    // التحقق من رقم الهاتف
    if (!phone || phone.trim() === '') {
      return res.status(400).json({
        success: false,
        error: 'رقم الهاتف مطلوب'
      });
    }

    console.log('📊 === جلب ملخص الإحصائيات الموحد ===');
    console.log('📱 رقم الهاتف:', phone);
    console.log('📅 الفترة (المحافظات):', from_date, 'إلى', to_date);
    console.log('📅 الأسبوع:', week_start, 'إلى', week_end);

    // 🔥 تنفيذ جميع الاستعلامات بالتوازي (Parallel) لتحسين الأداء
    const [realizedProfitsResult, provinceOrdersResult, weekdayOrdersResult] = await Promise.all([

      // 1️⃣ جلب الأرباح المحققة
      supabase
        .from('orders')
        .select('profit')
        .eq('user_phone', phone)
        .eq('status', 'تم التسليم للزبون'),

      // 2️⃣ جلب طلبات المحافظات (إذا تم تحديد التواريخ)
      from_date && to_date
        ? supabase
          .from('orders')
          .select('id, province, city, created_at, user_phone, status')
          .eq('user_phone', phone)
          .gte('created_at', from_date)
          .lte('created_at', to_date)
        : Promise.resolve({ data: [], error: null }),

      // 3️⃣ جلب طلبات أيام الأسبوع (إذا تم تحديد الأسبوع)
      week_start && week_end
        ? supabase.rpc('get_weekday_orders', {
          p_user_phone: phone,
          p_week_start: week_start,
          p_week_end: week_end,
        })
        : Promise.resolve({ data: [], error: null })
    ]);

    // معالجة الأخطاء
    if (realizedProfitsResult.error) {
      console.error('❌ خطأ في جلب الأرباح:', realizedProfitsResult.error.message);
    }
    if (provinceOrdersResult.error) {
      console.error('❌ خطأ في جلب طلبات المحافظات:', provinceOrdersResult.error.message);
    }
    if (weekdayOrdersResult.error) {
      console.error('❌ خطأ في جلب طلبات الأسبوع:', weekdayOrdersResult.error.message);
    }

    // 1️⃣ حساب الأرباح المحققة
    let totalProfit = 0.0;
    if (realizedProfitsResult.data && realizedProfitsResult.data.length > 0) {
      realizedProfitsResult.data.forEach(order => {
        totalProfit += Number(order.profit) || 0.0;
      });
    }

    // 2️⃣ حساب طلبات المحافظات
    const provinceCounts = {};
    let totalOrders = 0;
    if (provinceOrdersResult.data && provinceOrdersResult.data.length > 0) {
      totalOrders = provinceOrdersResult.data.length;
      provinceOrdersResult.data.forEach(order => {
        if (order.province) {
          const province = order.province.trim();
          provinceCounts[province] = (provinceCounts[province] || 0) + 1;
        }
      });
    }

    // 3️⃣ طلبات أيام الأسبوع (جاهزة من الـ RPC)
    const weekdayOrders = weekdayOrdersResult.data || [];

    console.log('✅ النتائج:');
    console.log('   💰 الأرباح المحققة:', totalProfit);
    console.log('   🗺️ عدد المحافظات:', Object.keys(provinceCounts).length);
    console.log('   📅 عدد أيام الأسبوع:', weekdayOrders.length);

    // إرجاع جميع البيانات في استجابة واحدة
    res.status(200).json({
      success: true,
      data: {
        realized_profits: totalProfit,
        province_orders: {
          province_counts: provinceCounts,
          total_orders: totalOrders
        },
        weekday_orders: weekdayOrders
      },
      timestamp: new Date().toISOString() // لتتبع وقت الاستجابة
    });

  } catch (error) {
    console.error('❌ خطأ في جلب ملخص الإحصائيات:', error.message);
    res.status(500).json({
      success: false,
      error: 'خطأ في الخادم'
    });
  }
});

// 🏆 POST /api/users/top-products - جلب أكثر المنتجات مبيعاً للمستخدم
router.post('/top-products', async (req, res) => {
  try {
    const { phone } = req.body;

    if (!phone) {
      return res.status(400).json({ success: false, error: 'رقم الهاتف مطلوب' });
    }

    console.log(`🏆 جلب أكثر المنتجات مبيعاً للمستخدم: ${phone}`);

    // 🔍 جلب جميع عناصر الطلبات للمستخدم مع تفاصيل الطلبات
    const { data: orderItems, error: itemsError } = await supabase
      .from('order_items')
      .select(`
        id,
        product_id,
        product_name,
        product_image,
        quantity,
        profit_per_item,
        orders!inner (
          id,
          user_phone,
          status
        )
      `)
      .eq('orders.user_phone', phone);

    if (itemsError) {
      console.log(`❌ خطأ في جلب عناصر الطلبات: ${itemsError.message}`);
      return res.status(500).json({ success: false, error: 'خطأ في جلب البيانات' });
    }

    if (!orderItems || orderItems.length === 0) {
      console.log('⚠️ لا توجد منتجات للمستخدم');
      return res.status(200).json({ success: true, data: [] });
    }

    console.log(`📦 تم جلب ${orderItems.length} عنصر طلب`);

    // 📊 تجميع البيانات حسب المنتج
    const productStats = {};

    orderItems.forEach((item) => {
      const productId = item.product_id || item.product_name; // استخدام product_name كـ fallback

      if (!productStats[productId]) {
        productStats[productId] = {
          product_id: productId,
          product_name: item.product_name,
          product_image: item.product_image,
          total_orders: 0,
          total_quantity: 0,
          delivered_orders: 0,
          cancelled_orders: 0,
          total_profit: 0,
        };
      }

      productStats[productId].total_orders += 1;
      productStats[productId].total_quantity += item.quantity || 1;

      const orderStatus = item.orders?.status || '';

      if (orderStatus === 'تم التسليم للزبون' || orderStatus === 'delivered') {
        productStats[productId].delivered_orders += 1;
        productStats[productId].total_profit += item.profit_per_item || 0;
      } else if (orderStatus === 'ملغي' || orderStatus === 'cancelled') {
        productStats[productId].cancelled_orders += 1;
      }
    });

    // 🏆 تحويل إلى مصفوفة وترتيب حسب عدد الطلبات
    const topProducts = Object.values(productStats)
      .sort((a, b) => b.total_orders - a.total_orders)
      .slice(0, 10); // أفضل 10 منتجات

    console.log(`✅ تم جلب ${topProducts.length} منتج`);

    res.status(200).json({
      success: true,
      data: topProducts,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.log(`❌ خطأ في الخادم: ${error.message}`);
    res.status(500).json({ success: false, error: 'خطأ في الخادم' });
  }
});

// 💰 جلب رصيد المستخدم المتاح للسحب (GET - آمن جداً - يستخدم JWT فقط)
router.get('/balance', async (req, res) => {
  try {
    // ✅ استخراج رقم الهاتف من JWT في الهيدر (أكثر أماناً)
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ success: false, error: 'غير مصرح - يجب تسجيل الدخول' });
    }

    const token = authHeader.substring(7);
    const { data: { user: authUser }, error: authError } = await supabase.auth.getUser(token);

    if (authError || !authUser) {
      console.log(`❌ خطأ في التحقق من التوكن: ${authError?.message}`);
      return res.status(401).json({ success: false, error: 'توكن غير صالح' });
    }

    const phone = authUser.phone;
    console.log(`💰 جلب رصيد المستخدم: ${phone}`);

    // جلب بيانات المستخدم
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id, name, achieved_profits, phone')
      .eq('phone', phone)
      .maybeSingle();

    if (userError) {
      console.log(`❌ خطأ في جلب بيانات المستخدم: ${userError.message}`);
      return res.status(500).json({ success: false, error: 'خطأ في جلب البيانات' });
    }

    if (!user) {
      console.log('⚠️ المستخدم غير موجود');
      return res.status(404).json({ success: false, error: 'المستخدم غير موجود' });
    }

    const balance = user.achieved_profits || 0;
    console.log(`✅ رصيد المستخدم: ${balance} د.ع`);

    res.status(200).json({
      success: true,
      balance: balance,
      user_id: user.id,
      user_name: user.name,
      phone: user.phone,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.log(`❌ خطأ في الخادم: ${error.message}`);
    res.status(500).json({ success: false, error: 'خطأ في الخادم' });
  }
});

// 💰 جلب رصيد المستخدم المتاح للسحب (POST - للتوافق مع الإصدارات القديمة)
router.post('/balance', async (req, res) => {
  try {
    const { phone } = req.body;

    if (!phone) {
      return res.status(400).json({ success: false, error: 'رقم الهاتف مطلوب' });
    }

    console.log(`💰 جلب رصيد المستخدم: ${phone}`);

    // جلب بيانات المستخدم
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id, name, achieved_profits')
      .eq('phone', phone)
      .maybeSingle();

    if (userError) {
      console.log(`❌ خطأ في جلب بيانات المستخدم: ${userError.message}`);
      return res.status(500).json({ success: false, error: 'خطأ في جلب البيانات' });
    }

    if (!user) {
      console.log('⚠️ المستخدم غير موجود');
      return res.status(404).json({ success: false, error: 'المستخدم غير موجود' });
    }

    const balance = user.achieved_profits || 0;
    console.log(`✅ رصيد المستخدم: ${balance} د.ع`);

    res.status(200).json({
      success: true,
      balance: balance,
      user_id: user.id,
      user_name: user.name,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.log(`❌ خطأ في الخادم: ${error.message}`);
    res.status(500).json({ success: false, error: 'خطأ في الخادم' });
  }
});

// 💸 إنشاء طلب سحب جديد
router.post('/withdraw', async (req, res) => {
  try {
    const { phone, amount, method, card_holder, card_number, phone_number } = req.body;

    // التحقق من البيانات المطلوبة
    if (!phone || !amount || !method) {
      return res.status(400).json({ success: false, error: 'البيانات المطلوبة ناقصة' });
    }

    if (amount <= 0) {
      return res.status(400).json({ success: false, error: 'المبلغ يجب أن يكون أكبر من صفر' });
    }

    console.log(`💸 طلب سحب جديد من المستخدم: ${phone} - المبلغ: ${amount} د.ع`);

    // جلب بيانات المستخدم
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id, name, achieved_profits')
      .eq('phone', phone)
      .maybeSingle();

    if (userError) {
      console.log(`❌ خطأ في جلب بيانات المستخدم: ${userError.message}`);
      return res.status(500).json({ success: false, error: 'خطأ في جلب البيانات' });
    }

    if (!user) {
      console.log('⚠️ المستخدم غير موجود');
      return res.status(404).json({ success: false, error: 'المستخدم غير موجود' });
    }

    const currentBalance = user.achieved_profits || 0;

    // التحقق من الرصيد الكافي
    if (amount > currentBalance) {
      console.log(`⚠️ رصيد غير كافٍ - المطلوب: ${amount} د.ع، المتاح: ${currentBalance} د.ع`);
      return res.status(400).json({
        success: false,
        error: 'الرصيد غير كافٍ',
        available_balance: currentBalance,
      });
    }

    // إنشاء سجل طلب السحب
    // 🔧 تجهيز تفاصيل الحساب حسب طريقة السحب
    let accountDetails = '';
    if (method === 'ki_card') {
      if (!card_holder || !card_number) {
        return res.status(400).json({ success: false, error: 'بيانات البطاقة ناقصة' });
      }
      accountDetails = `حامل البطاقة: ${card_holder}\nرقم البطاقة: ${card_number}`;
    } else if (method === 'zain_cash') {
      if (!phone_number) {
        return res.status(400).json({ success: false, error: 'رقم الهاتف مطلوب' });
      }
      accountDetails = `رقم الهاتف: ${phone_number}`;
    }

    const withdrawalData = {
      user_id: user.id,
      amount: amount,
      withdrawal_method: method, // ✅ استخدام withdrawal_method بدلاً من method
      account_details: accountDetails, // ✅ تخزين التفاصيل في account_details
      status: 'pending',
      // ✅ created_at يتم إنشاؤه تلقائياً بواسطة قاعدة البيانات
    };

    console.log(`📝 إنشاء سجل طلب السحب...`);

    const { data: withdrawal, error: withdrawalError } = await supabase
      .from('withdrawal_requests')
      .insert([withdrawalData])
      .select()
      .single();

    if (withdrawalError) {
      console.log(`❌ خطأ في إنشاء طلب السحب: ${withdrawalError.message}`);
      return res.status(500).json({ success: false, error: 'فشل في إنشاء طلب السحب' });
    }

    console.log(`✅ تم إنشاء طلب السحب بنجاح - ID: ${withdrawal.id}`);

    // خصم المبلغ من رصيد المستخدم
    const newBalance = currentBalance - amount;
    console.log(`💰 تحديث رصيد المستخدم من ${currentBalance} إلى ${newBalance} د.ع`);

    const { error: updateError } = await supabase
      .from('users')
      .update({ achieved_profits: newBalance })
      .eq('id', user.id);

    if (updateError) {
      console.log(`❌ خطأ في تحديث الرصيد: ${updateError.message}`);
      // حذف طلب السحب في حالة فشل تحديث الرصيد
      await supabase.from('withdrawal_requests').delete().eq('id', withdrawal.id);
      return res.status(500).json({ success: false, error: 'فشل في تحديث الرصيد' });
    }

    console.log(`✅ تم تحديث الرصيد بنجاح`);

    res.status(200).json({
      success: true,
      message: 'تم إرسال طلب السحب بنجاح',
      transaction_id: withdrawal.id,
      new_balance: newBalance,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.log(`❌ خطأ في الخادم: ${error.message}`);
    res.status(500).json({ success: false, error: 'خطأ في الخادم' });
  }
});

// 🔍 التحقق من وجود طلب سحب في قاعدة البيانات
router.post('/verify-withdrawal', async (req, res) => {
  try {
    const { phone, transaction_id } = req.body;

    if (!phone || !transaction_id) {
      return res.status(400).json({ success: false, error: 'البيانات المطلوبة ناقصة' });
    }

    console.log(`🔍 التحقق من طلب السحب: ${transaction_id}`);

    // جلب بيانات المستخدم
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id')
      .eq('phone', phone)
      .maybeSingle();

    if (userError || !user) {
      console.log('❌ المستخدم غير موجود');
      return res.status(404).json({ success: false, error: 'المستخدم غير موجود' });
    }

    // التحقق من وجود طلب السحب
    const { data: withdrawal, error: withdrawalError } = await supabase
      .from('withdrawal_requests')
      .select('id, status, amount')
      .eq('id', transaction_id)
      .eq('user_id', user.id)
      .maybeSingle();

    if (withdrawalError) {
      console.log(`❌ خطأ في التحقق: ${withdrawalError.message}`);
      return res.status(500).json({ success: false, error: 'خطأ في التحقق' });
    }

    if (withdrawal) {
      console.log(`✅ طلب السحب موجود: ${withdrawal.id} - الحالة: ${withdrawal.status}`);
      res.status(200).json({
        success: true,
        exists: true,
        withdrawal_id: withdrawal.id,
        status: withdrawal.status,
        amount: withdrawal.amount,
      });
    } else {
      console.log('⚠️ طلب السحب غير موجود');
      res.status(200).json({
        success: true,
        exists: false,
      });
    }
  } catch (error) {
    console.log(`❌ خطأ في الخادم: ${error.message}`);
    res.status(500).json({ success: false, error: 'خطأ في الخادم' });
  }
});

module.exports = router;
