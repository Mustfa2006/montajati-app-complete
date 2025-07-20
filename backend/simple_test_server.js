// ===================================
// خادم اختبار بسيط
// Simple Test Server
// ===================================

require('dotenv').config();
const express = require('express');
const cors = require('cors');

const app = express();
const port = process.env.PORT || 3003;

// Middleware
app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    message: 'الخادم يعمل بشكل صحيح',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// Test endpoint
app.get('/test', (req, res) => {
  res.json({
    success: true,
    message: 'اختبار الخادم نجح!',
    data: {
      hasSupabaseUrl: !!process.env.SUPABASE_URL,
      hasSupabaseServiceKey: !!process.env.SUPABASE_SERVICE_ROLE_KEY,
      hasFirebaseServiceAccount: !!process.env.FIREBASE_SERVICE_ACCOUNT,
      firebaseServiceAccountValid: (() => {
        try {
          if (!process.env.FIREBASE_SERVICE_ACCOUNT) return false;
          const parsed = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
          return !!(parsed.project_id && parsed.private_key && parsed.client_email);
        } catch (e) {
          return false;
        }
      })()
    }
  });
});

// Start server
app.listen(port, () => {
  console.log('🚀 خادم الاختبار البسيط يعمل على المنفذ:', port);
  console.log('🔗 الرابط: http://localhost:' + port);
  console.log('💚 Health Check: http://localhost:' + port + '/health');
  console.log('🧪 Test Endpoint: http://localhost:' + port + '/test');
});

module.exports = app;
