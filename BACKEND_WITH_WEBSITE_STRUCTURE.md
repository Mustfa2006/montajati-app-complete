# 🏗️ **هيكل الخادم + الموقع معاً**

## 📁 **الهيكل المطلوب:**

```
📂 clownfish-app-krnk9/
├── 📄 server.js                    ← الخادم الرئيسي
├── 📄 package.json                 ← إعدادات Node.js
├── 📄 .env                         ← متغيرات البيئة
└── 📁 public/                      ← ملفات الموقع
    ├── 📄 index.html               ← الصفحة الرئيسية
    ├── 📄 main.dart.js             ← كود Flutter
    ├── 📄 flutter.js               ← مكتبة Flutter
    ├── 📄 manifest.json            ← معلومات التطبيق
    ├── 📄 _redirects               ← إعادة التوجيه
    ├── 📁 js/                      ← ملفات JavaScript
    │   ├── 📄 web-config.js        ← إعدادات الويب
    │   ├── 📄 performance-optimizer.js
    │   └── 📄 enhanced-service-worker.js
    ├── 📁 assets/                  ← ملفات Flutter
    ├── 📁 canvaskit/               ← مكتبة الرسم
    └── 📁 icons/                   ← الأيقونات
```

## 🎯 **النتيجة:**

### **الروابط:**
- **الموقع:** `https://clownfish-app-krnk9.ondigitalocean.app/`
- **API:** `https://clownfish-app-krnk9.ondigitalocean.app/api/`
- **الصحة:** `https://clownfish-app-krnk9.ondigitalocean.app/api/web/health`

### **المزايا:**
- ✅ لا توجد مشاكل CORS (نفس النطاق)
- ✅ رابط واحد للموقع والـ API
- ✅ سهولة الإدارة
- ✅ توفير في التكلفة

## 📋 **خطوات التطبيق:**

### **1. تحديث server.js**
- إضافة `express.static('public')`
- تحديث routing للموقع
- الحفاظ على API routes

### **2. إنشاء مجلد public**
- نسخ جميع ملفات الموقع إلى `public/`
- تحديث `web-config.js` ليستخدم نفس النطاق

### **3. تحديث web-config.js**
```javascript
// بدلاً من
apiBaseUrl: 'https://clownfish-app-krnk9.ondigitalocean.app'

// سيصبح
apiBaseUrl: '' // نفس النطاق
```

### **4. رفع التحديثات**
- رفع الملفات المحدثة
- إعادة تشغيل الخادم
- اختبار الموقع

## 🚀 **الخطوات العملية:**

### **في DigitalOcean:**
1. اذهب إلى `clownfish-app-krnk9`
2. حدث `server.js`
3. أضف مجلد `public/`
4. انسخ ملفات الموقع إلى `public/`
5. أعد النشر

### **النتيجة المتوقعة:**
- `https://clownfish-app-krnk9.ondigitalocean.app/` ← الموقع
- `https://clownfish-app-krnk9.ondigitalocean.app/api/orders` ← API
- التطبيق والموقع يعملان على نفس الخادم

## ✅ **هذه هي الطريقة المثلى!**
