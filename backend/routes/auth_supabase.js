// مسارات المصادقة مع Supabase
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { supabase, supabaseAdmin } = require('../config/supabase');

const router = express.Router();

// دالة لإنشاء JWT Token
const signToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN,
  });
};

// دالة لإرسال الرد مع التوكن
const createSendToken = (user, statusCode, res) => {
  const token = signToken(user.id);
  
  // إزالة كلمة المرور من الرد
  delete user.password_hash;
  
  res.status(statusCode).json({
    success: true,
    token,
    data: {
      user,
    },
  });
};

// تسجيل حساب جديد
router.post('/register', async (req, res) => {
  try {
    const { name, email, password, confirmPassword } = req.body;
    
    // التحقق من البيانات
    if (!name || !email || !password || !confirmPassword) {
      return res.status(400).json({
        success: false,
        message: 'يرجى ملء جميع الحقول المطلوبة',
      });
    }
    
    if (password !== confirmPassword) {
      return res.status(400).json({
        success: false,
        message: 'كلمة المرور غير متطابقة',
      });
    }
    
    // التحقق من وجود المستخدم
    const { data: existingUser } = await supabase
      .from('users')
      .select('id')
      .eq('email', email)
      .single();
    
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'البريد الإلكتروني مستخدم بالفعل',
      });
    }
    
    // تشفير كلمة المرور
    const passwordHash = await bcrypt.hash(password, 12);
    
    // إنشاء المستخدم الجديد
    const { data: newUser, error } = await supabase
      .from('users')
      .insert([
        {
          name,
          email,
          password_hash: passwordHash,
        }
      ])
      .select()
      .single();
    
    if (error) {
      console.error('خطأ في إنشاء المستخدم:', error);
      return res.status(500).json({
        success: false,
        message: 'خطأ في إنشاء الحساب',
      });
    }
    
    createSendToken(newUser, 201, res);
  } catch (error) {
    console.error('خطأ في التسجيل:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
});

// تسجيل الدخول
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // التحقق من البيانات
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'يرجى إدخال البريد الإلكتروني وكلمة المرور',
      });
    }
    
    // البحث عن المستخدم
    const { data: user, error } = await supabase
      .from('users')
      .select('*')
      .eq('email', email)
      .single();
    
    if (error || !user) {
      return res.status(401).json({
        success: false,
        message: 'البريد الإلكتروني أو كلمة المرور غير صحيحة',
      });
    }
    
    // التحقق من كلمة المرور
    const isPasswordCorrect = await bcrypt.compare(password, user.password_hash);
    
    if (!isPasswordCorrect) {
      return res.status(401).json({
        success: false,
        message: 'البريد الإلكتروني أو كلمة المرور غير صحيحة',
      });
    }
    
    // التحقق من أن الحساب نشط
    if (!user.is_active) {
      return res.status(401).json({
        success: false,
        message: 'تم إيقاف هذا الحساب. يرجى التواصل مع الدعم الفني',
      });
    }
    
    // تحديث آخر تسجيل دخول
    await supabase
      .from('users')
      .update({ last_login: new Date().toISOString() })
      .eq('id', user.id);
    
    createSendToken(user, 200, res);
  } catch (error) {
    console.error('خطأ في تسجيل الدخول:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
});

// تسجيل الخروج
router.post('/logout', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'تم تسجيل الخروج بنجاح',
  });
});

// الحصول على المستخدم الحالي
router.get('/me', async (req, res) => {
  try {
    // TODO: إضافة middleware للتحقق من التوكن
    const { data: user, error } = await supabase
      .from('users')
      .select('id, name, email, phone, avatar_url, role, total_products, total_orders, total_sales, created_at')
      .eq('id', req.user.id)
      .single();
    
    if (error) {
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
    console.error('خطأ في الحصول على بيانات المستخدم:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في الخادم',
    });
  }
});

// التحقق من صحة التوكن
router.get('/verify-token', async (req, res) => {
  try {
    let token;
    
    // الحصول على التوكن من الهيدر
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }
    
    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'لم يتم العثور على رمز المصادقة',
      });
    }
    
    // التحقق من التوكن
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // التحقق من وجود المستخدم
    const { data: user, error } = await supabase
      .from('users')
      .select('id, name, email, role, is_active')
      .eq('id', decoded.id)
      .single();
    
    if (error || !user) {
      return res.status(401).json({
        success: false,
        message: 'المستخدم غير موجود',
      });
    }
    
    if (!user.is_active) {
      return res.status(401).json({
        success: false,
        message: 'الحساب غير نشط',
      });
    }
    
    res.status(200).json({
      success: true,
      message: 'التوكن صحيح',
      data: {
        user,
      },
    });
  } catch (error) {
    console.error('خطأ في التحقق من التوكن:', error);
    res.status(401).json({
      success: false,
      message: 'رمز المصادقة غير صحيح',
    });
  }
});

module.exports = router;
