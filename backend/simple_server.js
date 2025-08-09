#!/usr/bin/env node

// ===================================
// خادم بسيط لاختبار نظام الإشعارات
// ===================================

require('dotenv').config();
const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3003;

// إعدادات أساسية
app.use(cors());
app.use(express.json());

// إضافة routes FCM
const fcmTokensRouter = require('./routes/fcm_tokens');
app.use('/api/fcm', fcmTokensRouter);

// مسار الصحة
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    message: 'خادم الإشعارات يعمل بنجاح',
    timestamp: new Date().toISOString()
  });
});

// مسار الجذر
app.get('/', (req, res) => {
  res.json({
    message: 'نظام الإشعارات - منتجاتي',
    endpoints: {
      health: '/health',
      register_fcm: 'POST /api/fcm/register',
      test_notification: 'POST /api/fcm/test-notification',
      check_status: 'GET /api/fcm/status/:user_phone'
    }
  });
});

// بدء الخادم
app.listen(PORT, () => {
  console.log('🚀 خادم الإشعارات يعمل على المنفذ:', PORT);
  console.log('🔗 الرابط: http://localhost:' + PORT);
  console.log('✅ جاهز لاستقبال FCM tokens');
});

// معالجة الأخطاء
process.on('uncaughtException', (error) => {
  console.error('❌ خطأ غير متوقع:', error);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ رفض غير معالج:', reason);
});
