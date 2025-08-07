# 🔧 دليل استكشاف الأخطاء وحلها

## 🚨 المشاكل الشائعة وحلولها

### **1. 🐌 Flutter يستغرق وقتاً طويلاً في التشغيل**

#### **الأعراض:**
- الأوامر تتجمد ولا تظهر مخرجات
- `flutter run` لا يستجيب
- `flutter doctor` يستغرق وقتاً طويلاً

#### **الحلول:**

**أ. إعادة تشغيل Flutter:**
```bash
# إنهاء جميع عمليات Flutter
taskkill /f /im flutter.exe
taskkill /f /im dart.exe

# إعادة تشغيل
flutter --version
```

**ب. تنظيف Flutter Cache:**
```bash
flutter clean
flutter pub cache clean
flutter pub cache repair
```

**ج. إعادة تشغيل ADB:**
```bash
adb kill-server
adb start-server
```

---

### **2. 📱 مشاكل المحاكي**

#### **المحاكي لا يبدأ:**
```bash
# تحقق من المحاكيات المتاحة
flutter emulators

# تشغيل محاكي محدد
flutter emulators --launch <emulator_name>

# إذا فشل، جرب من Android Studio
# Tools → AVD Manager → تشغيل المحاكي يدوياً
```

#### **المحاكي بطيء:**
- تأكد من تفعيل Hardware Acceleration
- زيادة RAM المخصص للمحاكي
- استخدام SSD بدلاً من HDD

---

### **3. 🔧 مشاكل البناء**

#### **خطأ في التبعيات:**
```bash
cd frontend
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

#### **خطأ في Gradle:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

---

### **4. 🌐 مشاكل الشبكة**

#### **بطء في تحميل التبعيات:**
```bash
# استخدام مرآة مختلفة
flutter pub deps
flutter pub get --verbose
```

#### **مشاكل في الاتصال بالخادم:**
- تحقق من اتصال الإنترنت
- تحقق من إعدادات Firewall
- جرب VPN إذا لزم الأمر

---

## 🛠️ أدوات التشخيص

### **1. فحص حالة Flutter:**
```bash
flutter doctor -v
flutter --version
flutter config
```

### **2. فحص الأجهزة:**
```bash
flutter devices -v
adb devices
```

### **3. فحص التبعيات:**
```bash
flutter pub deps
flutter pub outdated
```

### **4. فحص المشروع:**
```bash
flutter analyze
flutter test
```

---

## 🚀 خطوات الإصلاح السريع

### **الإصلاح الشامل:**
```bash
# 1. إنهاء جميع العمليات
taskkill /f /im flutter.exe
taskkill /f /im dart.exe
taskkill /f /im java.exe

# 2. إعادة تشغيل ADB
adb kill-server
adb start-server

# 3. تنظيف المشروع
cd frontend
flutter clean
flutter pub get

# 4. إعادة تشغيل المحاكي
flutter emulators --launch Medium_Phone_API_36.0

# 5. انتظار 30 ثانية
timeout /t 30

# 6. تشغيل التطبيق
flutter run
```

---

## 📋 قائمة التحقق

### **قبل تشغيل التطبيق:**
- [ ] Flutter مثبت ويعمل (`flutter --version`)
- [ ] Android Studio مثبت
- [ ] Android SDK مثبت ومحدث
- [ ] محاكي Android متاح
- [ ] اتصال إنترنت مستقر
- [ ] مساحة قرص كافية (10GB+)

### **أثناء التشغيل:**
- [ ] المحاكي يعمل ويظهر سطح المكتب
- [ ] `flutter devices` يظهر المحاكي
- [ ] لا توجد أخطاء في Terminal
- [ ] التطبيق يبدأ في البناء

### **بعد التشغيل:**
- [ ] التطبيق يظهر على المحاكي
- [ ] يمكن التنقل في التطبيق
- [ ] الوظائف الأساسية تعمل
- [ ] Hot Reload يعمل

---

## 🎯 بدائل التشغيل

### **1. تشغيل على الويب:**
```bash
flutter run -d chrome
```

### **2. تشغيل على Windows:**
```bash
flutter run -d windows
```

### **3. تشغيل على جهاز حقيقي:**
```bash
# وصل جهاز Android وفعل USB Debugging
flutter run
```

---

## 📞 الحصول على المساعدة

### **معلومات مفيدة للدعم:**
```bash
# معلومات النظام
flutter doctor -v
flutter --version
flutter devices

# معلومات المشروع
flutter analyze
flutter pub deps
```

### **ملفات اللوجز:**
- Flutter logs: `flutter logs`
- Android logs: `adb logcat`
- System logs: Event Viewer (Windows)

---

## 🎉 النجاح المتوقع

عند نجاح التشغيل ستحصل على:
```
Launching lib/main.dart on sdk gphone64 x86 64 in debug mode...
Running Gradle task 'assembleDebug'...
✓ Built build/app/outputs/flutter-apk/app-debug.apk.
Installing build/app/outputs/flutter-apk/app-debug.apk...
Waiting for sdk gphone64 x86 64 to report its views...
Syncing files to device sdk gphone64 x86 64...
Flutter run key commands.
r Hot reload.
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

💪 Running with sound null safety 💪

An Observatory debugger and profiler on sdk gphone64 x86 64 is available at: http://127.0.0.1:xxxxx/
The Flutter DevTools debugger and profiler on sdk gphone64 x86 64 is available at: http://127.0.0.1:xxxxx/
```

التطبيق جاهز للاختبار! 🚀
