// مسارات المصادقة - Authentication Routes
const express = require('express');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const router = express.Router();

// دالة لإنشاء JWT Token
const signToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN,
  });
};

// دالة لإرسال الرد مع التوكن
const createSendToken = (user, statusCode, res) => {
  const token = signToken(user._id);
  
  // إعدادات الكوكيز
  const cookieOptions = {
    expires: new Date(
      Date.now() + process.env.JWT_COOKIE_EXPIRES_IN * 24 * 60 * 60 * 1000
    ),
    httpOnly: true,
  };
  
  if (process.env.NODE_ENV === 'production') cookieOptions.secure = true;
  
  res.cookie('jwt', token, cookieOptions);
  
  // إزالة كلمة المرور من الرد
  user.password = undefined;
  
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
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'البريد الإلكتروني مستخدم بالفعل',
      });
    }
    
    // إنشاء المستخدم الجديد
    const newUser = await User.create({
      name,
      email,
      password,
    });
    
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
    
    // البحث عن المستخدم وتضمين كلمة المرور
    const user = await User.findOne({ email }).select('+password');
    
    if (!user || !(await user.correctPassword(password, user.password))) {
      return res.status(401).json({
        success: false,
        message: 'البريد الإلكتروني أو كلمة المرور غير صحيحة',
      });
    }
    
    // التحقق من أن الحساب نشط
    if (!user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'تم إيقاف هذا الحساب. يرجى التواصل مع الدعم الفني',
      });
    }
    
    // تحديث آخر تسجيل دخول
    user.lastLogin = new Date();
    await user.save({ validateBeforeSave: false });
    
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
  res.cookie('jwt', 'loggedout', {
    expires: new Date(Date.now() + 10 * 1000),
    httpOnly: true,
  });
  
  res.status(200).json({
    success: true,
    message: 'تم تسجيل الخروج بنجاح',
  });
});

// الحصول على المستخدم الحالي
router.get('/me', async (req, res) => {
  try {
    // TODO: إضافة middleware للتحقق من التوكن
    const user = await User.findById(req.user.id);
    
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

// تحديث كلمة المرور
router.patch('/updatePassword', async (req, res) => {
  try {
    const { passwordCurrent, password, passwordConfirm } = req.body;
    
    // التحقق من البيانات
    if (!passwordCurrent || !password || !passwordConfirm) {
      return res.status(400).json({
        success: false,
        message: 'يرجى ملء جميع حقول كلمة المرور',
      });
    }
    
    if (password !== passwordConfirm) {
      return res.status(400).json({
        success: false,
        message: 'كلمة المرور الجديدة غير متطابقة',
      });
    }
    
    // الحصول على المستخدم مع كلمة المرور
    const user = await User.findById(req.user.id).select('+password');
    
    // التحقق من كلمة المرور الحالية
    if (!(await user.correctPassword(passwordCurrent, user.password))) {
      return res.status(401).json({
        success: false,
        message: 'كلمة المرور الحالية غير صحيحة',
      });
    }
    
    // تحديث كلمة المرور
    user.password = password;
    await user.save();
    
    createSendToken(user, 200, res);
  } catch (error) {
    console.error('خطأ في تحديث كلمة المرور:', error);
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
    const user = await User.findById(decoded.id);
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'المستخدم غير موجود',
      });
    }
    
    // التحقق من أن كلمة المرور لم تتغير بعد إصدار التوكن
    if (user.changedPasswordAfter(decoded.iat)) {
      return res.status(401).json({
        success: false,
        message: 'تم تغيير كلمة المرور. يرجى تسجيل الدخول مرة أخرى',
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
