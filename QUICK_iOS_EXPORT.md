# 🚀 دليل سريع: تصدير تطبيق منتجاتي للآيفون (IPA)

## ⚡ **الطريقة السريعة (الأسهل):**

### **المتطلبات:**
- ✅ جهاز Mac
- ✅ Xcode مثبت
- ✅ حساب Apple Developer

---

## 🎯 **خطوات التصدير السريعة:**

### **1. فتح المشروع:**
```bash
cd frontend
open ios/Runner.xcworkspace
```

### **2. في Xcode:**
1. **اختر:** Runner target
2. **اذهب إلى:** Product → Archive
3. **انتظر:** حتى ينتهي البناء
4. **في Organizer:** اختر Archive
5. **انقر:** "Distribute App"
6. **اختر:** "Development" أو "App Store Connect"
7. **اتبع:** المعالج

### **3. النتيجة:**
- ✅ ملف IPA جاهز
- 📍 مكان الحفظ: سطح المكتب أو مجلد Downloads

---

## 🛠 **الطريقة المتقدمة (Command Line):**

### **على جهاز Mac:**
```bash
# 1. تحضير المشروع
cd frontend
flutter clean
flutter pub get
cd ios
pod install
cd ..

# 2. بناء للإنتاج
flutter build ios --release

# 3. إنشاء Archive
cd ios
xcodebuild -workspace Runner.xcworkspace \
           -scheme Runner \
           -configuration Release \
           -archivePath build/Montajati.xcarchive \
           archive

# 4. تصدير IPA
xcodebuild -exportArchive \
           -archivePath build/Montajati.xcarchive \
           -exportPath build/export \
           -exportOptionsPlist ExportOptions.plist
```

---

## 📱 **معلومات التطبيق:**

- **الاسم:** منتجاتي - Montajati
- **Bundle ID:** com.montajati.app
- **الإصدار:** 3.7.0
- **Build:** 15
- **الحد الأدنى iOS:** 12.0

---

## 🚨 **مشاكل شائعة:**

### **"No signing certificate":**
- تأكد من تسجيل الدخول لحساب Apple Developer في Xcode
- اذهب إلى Xcode → Preferences → Accounts

### **"Provisioning profile doesn't match":**
- في Xcode: Runner → Signing & Capabilities
- فعل "Automatically manage signing"
- اختر Team الصحيح

### **"Build failed":**
```bash
flutter clean
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter pub get
```

---

## 📤 **رفع للـ App Store:**

### **1. إنشاء App في App Store Connect:**
- اذهب إلى: https://appstoreconnect.apple.com
- انقر: "My Apps" → "+"
- املأ البيانات

### **2. رفع IPA:**
- استخدم Xcode Organizer
- أو Transporter app
- أو Application Loader

### **3. معلومات مطلوبة:**
- وصف التطبيق
- الكلمات المفتاحية
- Screenshots (مقاسات مختلفة)
- أيقونة 1024x1024

---

## ✅ **التحقق النهائي:**

- [ ] التطبيق يعمل على جهاز iOS
- [ ] جميع الميزات تعمل
- [ ] لا توجد أخطاء
- [ ] الأيقونة تظهر بشكل صحيح
- [ ] Firebase يعمل
- [ ] الإشعارات تعمل

---

## 🎉 **بعد التصدير:**

1. **اختبر** التطبيق على أجهزة مختلفة
2. **ارفع** للـ App Store Connect
3. **أضف** الوصف والصور
4. **اطلب** المراجعة من Apple
5. **انتظر** الموافقة (1-7 أيام)

---

## 📞 **الدعم:**

إذا واجهت مشاكل:
- راجع Apple Developer Documentation
- تحقق من Xcode logs
- تأكد من صحة الشهادات
- جرب إعادة بناء المشروع

**ملاحظة مهمة:** تصدير iOS يتطلب جهاز Mac وحساب Apple Developer مدفوع (99$ سنوياً).
