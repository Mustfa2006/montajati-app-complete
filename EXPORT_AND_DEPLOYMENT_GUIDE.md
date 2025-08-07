# 📦 دليل التصدير والنشر الشامل - مشروع منتجاتي

## 🎯 نظرة عامة
هذا الدليل يوضح كيفية تنظيف وتحديث وتصدير ونشر مشروع منتجاتي بالكامل.

---

## 🧹 الخطوة 1: تنظيف وتحديث المشروع

### **الطريقة السريعة (مستحسنة):**
```bash
# تشغيل سكريبت التنظيف التلقائي
./clean_and_update.bat
# أو
./clean_and_update.ps1
```

### **الطريقة اليدوية:**

#### **تنظيف Frontend:**
```bash
cd frontend
git config --global --add safe.directory C:/flutter
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

#### **تنظيف Backend:**
```bash
cd backend
npm install
npm cache clean --force
```

---

## 📱 الخطوة 2: بناء تطبيق Android

### **بناء APK للإنتاج:**
```bash
cd frontend
flutter build apk --release
```

### **بناء APK مقسم حسب المعمارية (أصغر حجماً):**
```bash
flutter build apk --split-per-abi --release
```

### **بناء App Bundle (للنشر على Google Play):**
```bash
flutter build appbundle --release
```

### **مواقع الملفات المبنية:**
- **APK عام:** `frontend/build/app/outputs/flutter-apk/app-release.apk`
- **APK مقسم:** `frontend/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- **App Bundle:** `frontend/build/app/outputs/bundle/release/app-release.aab`

---

## 🖥️ الخطوة 3: تحضير Backend للنشر

### **إنشاء ملف .env للإنتاج:**
```env
# قاعدة البيانات
SUPABASE_URL=https://fqdhskaolzfavapmqodl.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# Firebase
FIREBASE_PROJECT_ID=montajati-app-7767d
FIREBASE_PRIVATE_KEY=your_private_key
FIREBASE_CLIENT_EMAIL=your_client_email

# شركة الوسيط
WASEET_USERNAME=محمد@mustfaabd
WASEET_PASSWORD=mustfaabd2006@

# Telegram
TELEGRAM_BOT_TOKEN=your_bot_token
TELEGRAM_CHAT_ID=your_chat_id

# الخادم
NODE_ENV=production
PORT=3003
```

### **اختبار الخادم محلياً:**
```bash
cd backend
npm start
```

---

## 🚀 الخطوة 4: النشر على الخدمات السحابية

### **النشر على DigitalOcean:**

#### **1. إنشاء App جديد:**
```bash
# استخدام DigitalOcean CLI
doctl apps create --spec render.yaml
```

#### **2. أو النشر اليدوي:**
1. اذهب إلى DigitalOcean Dashboard
2. Apps → Create App
3. اختر GitHub Repository
4. حدد مجلد `backend`
5. اضبط متغيرات البيئة
6. Deploy

### **النشر على Render:**

#### **1. استخدام render.yaml:**
```yaml
services:
  - type: web
    name: montajati-backend
    env: node
    buildCommand: cd backend && npm install
    startCommand: cd backend && npm start
    healthCheckPath: /health
```

#### **2. النشر اليدوي:**
1. اذهب إلى Render Dashboard
2. New → Web Service
3. Connect GitHub Repository
4. Root Directory: `backend`
5. Build Command: `npm install`
6. Start Command: `npm start`

### **النشر على Heroku:**
```bash
# تثبيت Heroku CLI
npm install -g heroku

# تسجيل الدخول
heroku login

# إنشاء تطبيق جديد
heroku create montajati-backend

# إضافة متغيرات البيئة
heroku config:set NODE_ENV=production
heroku config:set SUPABASE_URL=your_url
heroku config:set SUPABASE_SERVICE_ROLE_KEY=your_key

# النشر
git subtree push --prefix backend heroku main
```

---

## 📦 الخطوة 5: تحضير حزمة التصدير الكاملة

### **إنشاء مجلد التصدير:**
```bash
mkdir montajati-export
cd montajati-export
```

### **نسخ الملفات المطلوبة:**
```bash
# نسخ APK files
cp frontend/build/app/outputs/flutter-apk/*.apk ./

# نسخ Backend
cp -r backend ./backend-source

# نسخ الوثائق
cp *.md ./
cp clean_and_update.* ./
```

---

## 🔧 الخطوة 6: إعداد Docker (اختياري)

### **إنشاء Docker Image:**
```bash
# بناء الصورة
docker build -t montajati-backend .

# تشغيل الحاوية
docker run -p 3003:3003 --env-file .env montajati-backend
```

### **استخدام Docker Compose:**
```yaml
version: '3.8'
services:
  backend:
    build: .
    ports:
      - "3003:3003"
    env_file:
      - .env
    restart: unless-stopped
```

---

## ✅ الخطوة 7: التحقق من النشر

### **فحص صحة الخادم:**
```bash
curl https://your-domain.com/health
```

### **اختبار APIs:**
```bash
# اختبار API الأساسي
curl https://your-domain.com/api/orders

# اختبار حالة النظام
curl https://your-domain.com/api/system/status
```

### **اختبار التطبيق:**
1. تثبيت APK على جهاز Android
2. تسجيل الدخول
3. اختبار الوظائف الأساسية
4. اختبار الإشعارات

---

## 📋 قائمة التحقق النهائية

### **قبل النشر:**
- [ ] تم تنظيف وتحديث جميع التبعيات
- [ ] تم اختبار التطبيق محلياً
- [ ] تم اختبار الخادم محلياً
- [ ] تم إعداد متغيرات البيئة
- [ ] تم بناء APK بنجاح

### **بعد النشر:**
- [ ] الخادم يعمل ويستجيب
- [ ] قاعدة البيانات متصلة
- [ ] الإشعارات تعمل
- [ ] تكامل الوسيط يعمل
- [ ] التطبيق يتصل بالخادم

---

## 🆘 حل المشاكل الشائعة

### **مشكلة: Flutter لا يعمل**
```bash
# تحديث Flutter
flutter upgrade
flutter doctor
```

### **مشكلة: فشل في بناء APK**
```bash
flutter clean
flutter pub get
flutter build apk --release --verbose
```

### **مشكلة: خطأ في الخادم**
```bash
# فحص اللوجز
npm run logs

# إعادة تشغيل
npm restart
```

---

## 🎉 النتيجة النهائية

بعد اتباع هذا الدليل، ستحصل على:
- ✅ تطبيق Android جاهز للتوزيع
- ✅ خادم منشور على الإنترنت
- ✅ قاعدة بيانات متصلة
- ✅ جميع الخدمات تعمل
- ✅ حزمة تصدير كاملة

المشروع جاهز للاستخدام التجاري! 🚀
