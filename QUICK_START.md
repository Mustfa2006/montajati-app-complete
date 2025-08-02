# ⚡ دليل البدء السريع - تشخيص مشكلة تحديث حالة الطلب

## 🎯 الهدف السريع
تشغيل التطبيق على المحاكي وتشخيص مشكلة "فشل في تحديث حالة الطلب"

---

## 🚀 خطوات سريعة (5 دقائق)

### **1️⃣ تشغيل المحاكي**
```
1. افتح Android Studio
2. Tools → AVD Manager
3. اضغط ▶️ لتشغيل أي محاكي
4. انتظر حتى يظهر سطح المكتب
```

### **2️⃣ تشغيل التطبيق**
```
طريقة 1: استخدام الملف المساعد
- اضغط مضاعف على: setup_and_run.ps1
- اتبع التعليمات

طريقة 2: يدوياً
- افتح Terminal/CMD
- cd "C:\Users\Mustafa\Desktop\montajati\frontend"
- flutter run
```

### **3️⃣ اختبار المشكلة**
```
1. سجل دخول: admin@montajati.com / admin123
2. اذهب لـ "الطلبات"
3. اختر طلب → "تفاصيل"
4. اضغط "تحديث الحالة"
5. اختر حالة جديدة
6. راقب الخطأ في Terminal
```

---

## 🔍 ما نبحث عنه

### **رسائل مهمة في Console:**
```
✅ الطبيعي:
🔄 تحديث حالة الطلب: order_123 إلى قيد التحضير
📤 إرسال الطلب...
✅ تم تحديث حالة الطلب بنجاح

❌ المشكلة:
❌ خطأ في تحديث حالة الطلب: [السبب]
❌ فشل في تحديث الحالة - Status: 500
❌ TimeoutException / SocketException
```

---

## 🛠️ حلول سريعة

### **إذا لم يعمل Flutter:**
```bash
# تحميل Flutter
https://flutter.dev/docs/get-started/install/windows

# إضافة للـ PATH
C:\flutter\bin
```

### **إذا لم يعمل المحاكي:**
```
1. Android Studio → Tools → AVD Manager
2. Create Virtual Device → Pixel 4 → API 30
3. تشغيل المحاكي
```

### **إذا ظهر خطأ في التطبيق:**
```bash
# تحديث التبعيات
flutter pub get

# تنظيف وإعادة البناء
flutter clean
flutter pub get
flutter run
```

---

## 📋 معلومات مهمة

### **تسجيل الدخول:**
- **البريد:** admin@montajati.com
- **كلمة المرور:** admin123

### **مسار المشروع:**
```
C:\Users\Mustafa\Desktop\montajati\frontend
```

### **Backend URL:**
```
https://montajati-backend.onrender.com
```

---

## 🎯 النتيجة المطلوبة

بعد تشغيل التطبيق ومحاولة تحديث حالة الطلب:

1. **انسخ رسائل الخطأ** من Terminal
2. **حدد نوع الخطأ** (اتصال/backend/database)
3. **شاركها معي** لإصلاح المشكلة

---

## 🆘 إذا واجهت مشاكل

### **مشكلة شائعة: Flutter غير موجود**
```bash
# تحقق من التثبيت
flutter --version

# إذا لم يعمل، حمل من:
https://flutter.dev/docs/get-started/install/windows
```

### **مشكلة شائعة: لا توجد أجهزة**
```
1. تأكد من تشغيل محاكي Android
2. أو وصل جهاز Android حقيقي
3. تحقق: flutter devices
```

### **مشكلة شائعة: خطأ في البناء**
```bash
flutter clean
flutter pub get
flutter run
```

---

## 🚀 ابدأ الآن!

1. **شغل محاكي Android Studio**
2. **شغل:** `setup_and_run.ps1` أو `flutter run`
3. **اختبر تحديث حالة الطلب**
4. **انسخ رسائل الخطأ**
5. **شاركها معي للإصلاح!**

---

💡 **نصيحة:** احتفظ بـ Terminal مفتوح لمراقبة الرسائل!
