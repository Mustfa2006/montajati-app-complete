// مسارات المستخدمين - Users Routes
const express = require('express');
const User = require('../models/User');

const router = express.Router();

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

module.exports = router;
