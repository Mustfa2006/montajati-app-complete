# 📱 دليل تشغيل التطبيق على محاكي Android Studio

## 🎯 الهدف
تشغيل تطبيق منتجاتي على محاكي Android Studio للاختبار والتطوير.

---

## 🚀 الطريقة السريعة

### **تشغيل السكريبت التلقائي:**
```bash
./run_on_emulator.bat
```

---

## 🔧 الطريقة اليدوية

### **الخطوة 1: فحص المحاكيات المتاحة**
```bash
cd frontend
flutter emulators
```

### **الخطوة 2: تشغيل المحاكي**
```bash
flutter emulators --launch Medium_Phone_API_36.0
```

### **الخطوة 3: انتظار تشغيل المحاكي (30-60 ثانية)**
```bash
# انتظر حتى يظهر سطح المكتب في المحاكي
```

### **الخطوة 4: فحص الأجهزة المتصلة**
```bash
flutter devices
```
**يجب أن ترى:**
```
sdk gphone64 x86 64 (mobile) • emulator-5554 • android-x64 • Android 16 (API 36) (emulator)
```

### **الخطوة 5: تنظيف وتحديث المشروع**
```bash
flutter clean
flutter pub get
```

### **الخطوة 6: تشغيل التطبيق**
```bash
flutter run
```

---

## 🛠️ إعداد محاكي جديد (إذا لم يوجد)

### **1. فتح Android Studio**
- Tools → AVD Manager

### **2. إنشاء محاكي جديد**
- Create Virtual Device
- اختر Pixel 4 أو أي جهاز مناسب
- اختر API Level 30+ (Android 11+)
- اضغط Finish

### **3. تشغيل المحاكي**
- اضغط ▶️ بجانب المحاكي الجديد

---

## 🔍 حل المشاكل الشائعة

### **مشكلة: لا يوجد محاكي**
```bash
# إنشاء محاكي جديد
flutter emulators --create --name test_emulator

# أو استخدام Android Studio
# Tools → AVD Manager → Create Virtual Device
```

### **مشكلة: المحاكي لا يبدأ**
```bash
# تحقق من إعدادات BIOS
# تأكد من تفعيل Virtualization (VT-x/AMD-V)

# أو جرب محاكي مختلف
flutter emulators --launch <emulator_name>
```

### **مشكلة: Flutter لا يجد المحاكي**
```bash
# إعادة تشغيل ADB
adb kill-server
adb start-server

# فحص الأجهزة مرة أخرى
flutter devices
```

### **مشكلة: خطأ في البناء**
```bash
# تنظيف شامل
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# إعادة المحاولة
flutter run
```

### **مشكلة: بطء في التشغيل**
```bash
# استخدام Hot Reload بدلاً من إعادة التشغيل الكامل
# اضغط 'r' في Terminal أثناء تشغيل التطبيق

# أو استخدام Debug mode
flutter run --debug
```

---

## 📊 معلومات المحاكي الحالي

### **المحاكي المتاح:**
- **الاسم:** Medium Phone API 36.0
- **المعرف:** emulator-5554
- **النظام:** Android 16 (API 36)
- **المعمارية:** x86_64

### **متطلبات النظام:**
- **RAM:** 4GB+ مستحسن
- **مساحة القرص:** 10GB+ متاحة
- **المعالج:** دعم Virtualization مفعل

---

## 🎮 أوامر مفيدة أثناء التشغيل

### **أثناء تشغيل التطبيق:**
- **`r`** - Hot Reload (إعادة تحميل سريع)
- **`R`** - Hot Restart (إعادة تشغيل كامل)
- **`h`** - عرض المساعدة
- **`d`** - فصل التطبيق
- **`q`** - إنهاء التطبيق

### **اختصارات المحاكي:**
- **Ctrl + M** - قائمة المحاكي
- **Ctrl + H** - الصفحة الرئيسية
- **Ctrl + B** - زر الرجوع
- **Ctrl + P** - زر الطاقة

---

## ✅ التحقق من نجاح التشغيل

### **علامات النجاح:**
1. ✅ المحاكي يعمل ويظهر سطح المكتب
2. ✅ `flutter devices` يظهر المحاكي
3. ✅ `flutter run` يبدأ بدون أخطاء
4. ✅ التطبيق يظهر على شاشة المحاكي
5. ✅ يمكن التنقل في التطبيق

### **اختبار الوظائف الأساسية:**
- [ ] تسجيل الدخول
- [ ] عرض الطلبات
- [ ] إضافة منتج جديد
- [ ] تحديث حالة طلب
- [ ] الإشعارات

---

## 🎯 نصائح للأداء الأفضل

### **1. إعدادات المحاكي:**
- استخدم Hardware Acceleration
- خصص RAM كافية (4GB+)
- استخدم SSD للتخزين

### **2. إعدادات Flutter:**
- استخدم `--debug` للتطوير
- استخدم `--profile` للاختبار
- استخدم `--release` للاختبار النهائي

### **3. تحسين الأداء:**
```bash
# تشغيل مع تحسينات
flutter run --enable-software-rendering
flutter run --trace-startup
```

---

## 🆘 الدعم

إذا واجهت مشاكل:
1. تحقق من `flutter doctor`
2. راجع لوجز Android Studio
3. تأكد من تحديث Flutter و Android SDK
4. جرب محاكي مختلف

---

## 🎉 النتيجة المتوقعة

بعد اتباع هذا الدليل:
- ✅ المحاكي يعمل بسلاسة
- ✅ التطبيق يعمل على المحاكي
- ✅ يمكن اختبار جميع الوظائف
- ✅ Hot Reload يعمل للتطوير السريع

التطبيق جاهز للاختبار والتطوير! 🚀
