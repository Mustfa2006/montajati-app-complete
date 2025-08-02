# 📱 دليل تشغيل التطبيق على محاكي Android Studio

## 🎯 الهدف
تشغيل تطبيق منتجاتي على محاكي Android Studio لتشخيص مشكلة تحديث حالة الطلب في لوحة التحكم.

---

## 📋 الخطوات المطلوبة

### **1️⃣ التأكد من تثبيت Android Studio**

#### **أ. فتح Android Studio:**
1. ابحث عن "Android Studio" في قائمة Start
2. أو اذهب إلى: `C:\Program Files\Android\Android Studio\bin\studio64.exe`
3. أو: `C:\Users\[اسم المستخدم]\AppData\Local\Android\Android Studio\bin\studio64.exe`

#### **ب. إذا لم يكن مثبتاً:**
1. حمل من: https://developer.android.com/studio
2. ثبت Android Studio مع Android SDK

---

### **2️⃣ إنشاء/تشغيل المحاكي**

#### **أ. فتح AVD Manager:**
1. افتح Android Studio
2. اذهب إلى: `Tools` → `AVD Manager`
3. أو اضغط على أيقونة الهاتف في شريط الأدوات

#### **ب. إنشاء محاكي جديد (إذا لم يوجد):**
1. اضغط `Create Virtual Device`
2. اختر `Phone` → `Pixel 4` أو أي جهاز حديث
3. اختر `API Level 30` أو أحدث
4. اضغط `Next` → `Finish`

#### **ج. تشغيل المحاكي:**
1. اضغط زر ▶️ بجانب المحاكي
2. انتظر حتى يبدأ تشغيل Android

---

### **3️⃣ التحقق من Flutter**

#### **أ. فتح Terminal/Command Prompt:**
```bash
# التحقق من Flutter
flutter --version

# التحقق من الأجهزة المتصلة
flutter devices
```

#### **ب. إذا لم يعمل Flutter:**
1. حمل Flutter من: https://flutter.dev/docs/get-started/install/windows
2. أضف Flutter إلى PATH
3. شغل: `flutter doctor` للتحقق من الإعداد

---

### **4️⃣ تشغيل التطبيق**

#### **أ. الانتقال لمجلد المشروع:**
```bash
cd "C:\Users\Mustafa\Desktop\montajati\frontend"
```

#### **ب. التحقق من التبعيات:**
```bash
flutter pub get
```

#### **ج. تشغيل التطبيق:**
```bash
# تشغيل في وضع التطوير
flutter run

# أو تشغيل مع hot reload
flutter run --hot
```

---

### **5️⃣ الوصول للوحة التحكم**

#### **أ. تسجيل الدخول كمدير:**
- **البريد الإلكتروني:** `admin@montajati.com`
- **كلمة المرور:** `admin123`

#### **ب. الانتقال لقسم الطلبات:**
1. اضغط على تبويب "الطلبات"
2. اختر أي طلب موجود
3. اضغط على "تفاصيل الطلب"

#### **ج. اختبار تحديث الحالة:**
1. اضغط على "تحديث الحالة"
2. اختر حالة جديدة
3. راقب رسائل الخطأ في Console

---

## 🔍 تشخيص المشكلة

### **1️⃣ مراقبة Console Logs:**
```bash
# في Terminal حيث يعمل flutter run
# ستظهر رسائل debug مثل:
# 🔄 تحديث حالة الطلب: order_123 إلى نشط
# ❌ خطأ في تحديث حالة الطلب: [تفاصيل الخطأ]
```

### **2️⃣ فحص Network Requests:**
- راقب طلبات HTTP في logs
- تحقق من استجابة Backend
- ابحث عن أخطاء 500 أو timeout

### **3️⃣ أخطاء شائعة محتملة:**

#### **أ. مشكلة الاتصال بالـ Backend:**
```
❌ خطأ: SocketException: Failed to connect
✅ الحل: تحقق من اتصال الإنترنت والـ Backend URL
```

#### **ب. مشكلة في قاعدة البيانات:**
```
❌ خطأ: PostgrestException: permission denied
✅ الحل: تحقق من صلاحيات Supabase
```

#### **ج. مشكلة في Waseet API:**
```
❌ خطأ: TimeoutException: Request timeout
✅ الحل: زيادة timeout أو فحص Waseet API
```

---

## 🛠️ خطوات الإصلاح المتوقعة

### **بعد تحديد المشكلة:**

1. **إذا كانت مشكلة timeout:**
   - زيادة timeout في `official_order_service.dart`
   - تحسين معالجة الأخطاء

2. **إذا كانت مشكلة في Backend:**
   - فحص logs في Backend
   - إصلاح endpoint `/api/orders/:id/status`

3. **إذا كانت مشكلة في قاعدة البيانات:**
   - فحص صلاحيات Supabase
   - تحديث schema إذا لزم الأمر

---

## 📞 خطوات سريعة للبدء

### **الطريقة السريعة:**
1. **افتح Android Studio**
2. **شغل محاكي** (AVD Manager → Play)
3. **افتح Terminal** في مجلد المشروع
4. **شغل:** `flutter run`
5. **اختبر تحديث الحالة** في لوحة التحكم
6. **راقب الأخطاء** في Console

---

## 🎯 النتيجة المتوقعة

بعد تشغيل التطبيق ومحاولة تحديث حالة الطلب، ستحصل على:

✅ **رسائل تفصيلية** عن سبب فشل التحديث
✅ **معلومات دقيقة** عن نقطة الفشل
✅ **إمكانية إصلاح** المشكلة بدقة

---

## 📋 ملاحظات مهمة

- **تأكد من اتصال الإنترنت** قبل التشغيل
- **راقب Console** بعناية أثناء اختبار تحديث الحالة
- **جرب حالات مختلفة** لفهم نمط المشكلة
- **احفظ رسائل الخطأ** لتحليلها لاحقاً

---

🚀 **ابدأ الآن وسنحل المشكلة معاً!**
