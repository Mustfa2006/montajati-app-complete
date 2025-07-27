// اختبار مسار الدعم
const express = require('express');
const app = express();

// إضافة middleware
app.use(express.json());

// تحميل مسارات الدعم
try {
  const supportRoutes = require('./routes/support');
  app.use('/api/support', supportRoutes);
  console.log('✅ تم تحميل مسارات الدعم بنجاح');
} catch (error) {
  console.error('❌ خطأ في تحميل مسارات الدعم:', error);
}

// مسار اختبار
app.get('/test', (req, res) => {
  res.json({ message: 'الخادم يعمل', timestamp: new Date() });
});

const PORT = process.env.PORT || 3003;
app.listen(PORT, () => {
  console.log(`🚀 خادم الاختبار يعمل على المنفذ ${PORT}`);
});
