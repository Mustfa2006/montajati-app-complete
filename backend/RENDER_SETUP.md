# 🚀 دليل إعداد Render.com

## 📋 الخطوات المطلوبة:

### 1. **إعداد Web Service في Render**
```
Name: montajati-backend
Environment: Node
Build Command: npm install
Start Command: npm start
```

### 2. **متغيرات البيئة المطلوبة:**

#### 🗄️ **قاعدة البيانات (Supabase)**
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

#### 🔥 **Firebase (للإشعارات)**
```
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----
YOUR_PRIVATE_KEY_HERE
-----END PRIVATE KEY-----
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@project.iam.gserviceaccount.com
```

#### 📱 **Telegram**
```
TELEGRAM_BOT_TOKEN=your-bot-token
TELEGRAM_CHAT_ID=your-chat-id
TELEGRAM_NOTIFICATIONS_ENABLED=true
```

#### 🚚 **شركة الوسيط**
```
ALMASEET_BASE_URL=https://api.alwaseet-iq.net
WASEET_USERNAME=your-username
WASEET_PASSWORD=your-password
```

#### ⚙️ **إعدادات النظام**
```
NODE_ENV=production
JWT_SECRET=your-super-secret-jwt-key-change-this
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
```

### 3. **ملاحظات مهمة لـ Firebase:**

⚠️ **مشكلة شائعة:** Render لا يتعامل مع الأسطر الجديدة بشكل صحيح

**الحل:** عند إدخال `FIREBASE_PRIVATE_KEY` في Render:
1. انسخ المفتاح كاملاً مع `-----BEGIN PRIVATE KEY-----` و `-----END PRIVATE KEY-----`
2. ضعه في سطر واحد بدون أسطر جديدة
3. النظام سيصلح التنسيق تلقائياً

### 4. **فحص الصحة:**
```
Health Check Path: /health
```

### 5. **الأوامر المفيدة:**

#### **فحص الحالة:**
```bash
curl https://your-app.onrender.com/health
```

#### **فحص الخدمات:**
```bash
curl https://your-app.onrender.com/services/status
```

### 6. **استكشاف الأخطاء:**

#### **خطأ Firebase:**
```
Failed to parse private key: Error: Invalid PEM formatted message
```
**الحل:** تأكد من أن `FIREBASE_PRIVATE_KEY` يحتوي على المفتاح كاملاً

#### **خطأ Port:**
```
No open ports detected
```
**الحل:** تأكد من أن التطبيق يستمع على `process.env.PORT`

#### **خطأ Database:**
```
relation "orders" does not exist
```
**الحل:** شغل `node setup_database_complete.js` محلياً أولاً

### 7. **الملفات المحدثة:**
- ✅ `render-start.js` - سكريبت بدء محسن
- ✅ `package.json` - سكريبت start محدث
- ✅ `production_server.js` - معالجة أخطاء محسنة
- ✅ `config/firebase.js` - إصلاح مشكلة Private Key

### 8. **التحقق من النجاح:**
بعد النشر، يجب أن ترى:
```
✅ تم تهيئة Firebase Admin SDK بنجاح
✅ تم تهيئة خدمة مزامنة الطلبات بنجاح
✅ تم تشغيل مراقب حالة الطلبات بنجاح
🌐 الخادم يعمل على المنفذ: XXXX
```

## 🎯 **النتيجة المتوقعة:**
- ✅ خادم يعمل بدون أخطاء
- ✅ Firebase مهيأ (إذا تم توفير المفاتيح)
- ✅ قاعدة البيانات متصلة
- ✅ Telegram يعمل
- ✅ مزامنة شركة الوسيط تعمل
