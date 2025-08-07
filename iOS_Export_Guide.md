# 🍎 دليل تصدير تطبيق منتجاتي للآيفون (IPA)

## 📋 **المتطلبات الأساسية:**

### **1. الأجهزة والبرامج:**
- ✅ جهاز Mac (macOS 12.0 أو أحدث)
- ✅ Xcode 14.0 أو أحدث
- ✅ Flutter SDK (مثبت)
- ✅ CocoaPods (مثبت)

### **2. الحسابات والشهادات:**
- 🔐 حساب Apple Developer (99$ سنوياً)
- 📜 iOS Distribution Certificate
- 📱 Provisioning Profile
- 🆔 App Store Connect App ID

---

## 🔧 **إعداد الشهادات والملفات:**

### **الخطوة 1: إنشاء App ID في Apple Developer**

1. **اذهب إلى:** https://developer.apple.com/account
2. **انقر على:** "Certificates, Identifiers & Profiles"
3. **اختر:** "Identifiers" → "App IDs"
4. **انقر:** "+" لإنشاء App ID جديد
5. **املأ البيانات:**
   ```
   Description: Montajati App
   Bundle ID: com.montajati.app
   Capabilities: Push Notifications, App Groups
   ```

### **الخطوة 2: إنشاء Distribution Certificate**

1. **في نفس الموقع:** "Certificates" → "Production"
2. **انقر:** "+" → "iOS Distribution"
3. **ارفع:** Certificate Signing Request (CSR)
4. **حمل:** الشهادة وثبتها في Keychain

### **الخطوة 3: إنشاء Provisioning Profile**

1. **اذهب إلى:** "Profiles" → "Distribution"
2. **انقر:** "+" → "App Store"
3. **اختر:** App ID المُنشأ
4. **اختر:** Distribution Certificate
5. **حمل:** الملف وثبته

---

## 🛠 **تحضير المشروع:**

### **الخطوة 1: تحديث إعدادات المشروع**

```bash
# الانتقال لمجلد المشروع
cd frontend

# تنظيف المشروع
flutter clean
flutter pub get

# تحديث iOS dependencies
cd ios
pod install --repo-update
cd ..
```

### **الخطوة 2: فتح المشروع في Xcode**

```bash
# فتح workspace في Xcode
open ios/Runner.xcworkspace
```

### **الخطوة 3: إعداد التوقيع في Xcode**

1. **اختر:** Runner target
2. **اذهب إلى:** "Signing & Capabilities"
3. **فعل:** "Automatically manage signing"
4. **اختر:** Team (حساب Apple Developer)
5. **تأكد من:** Bundle Identifier = `com.montajati.app`

---

## 📦 **بناء وتصدير IPA:**

### **الطريقة 1: عبر Flutter Command Line**

```bash
# بناء iOS للإنتاج
flutter build ios --release

# إنشاء Archive
cd ios
xcodebuild -workspace Runner.xcworkspace \
           -scheme Runner \
           -configuration Release \
           -archivePath build/Runner.xcarchive \
           archive

# تصدير IPA
xcodebuild -exportArchive \
           -archivePath build/Runner.xcarchive \
           -exportPath build/ios_export \
           -exportOptionsPlist ExportOptions.plist
```

### **الطريقة 2: عبر Xcode (الأسهل)**

1. **في Xcode:** Product → Archive
2. **انتظر:** حتى ينتهي البناء
3. **في Organizer:** اختر Archive
4. **انقر:** "Distribute App"
5. **اختر:** "App Store Connect" أو "Development"
6. **اتبع:** المعالج حتى النهاية

---

## 📄 **إنشاء ملف ExportOptions.plist:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>destination</key>
    <string>export</string>
</dict>
</plist>
```

---

## 🎯 **معلومات التطبيق الحالية:**

- **اسم التطبيق:** منتجاتي (Montajati)
- **Bundle ID:** com.montajati.app
- **الإصدار:** 3.7.0 (Build 15)
- **الحد الأدنى iOS:** 12.0
- **الأيقونة:** ✅ مُعدة
- **Firebase:** ✅ مُهيأ
- **الأذونات:** ✅ مُعدة

---

## 🚨 **مشاكل شائعة وحلولها:**

### **مشكلة: "No signing certificate found"**
```bash
# الحل: تأكد من تثبيت الشهادة
security find-identity -v -p codesigning
```

### **مشكلة: "Provisioning profile doesn't match"**
- تأكد من Bundle ID
- حدث Provisioning Profile
- أعد تحميل الملفات

### **مشكلة: "Build failed"**
```bash
# تنظيف شامل
flutter clean
cd ios
rm -rf Pods
rm Podfile.lock
pod install
cd ..
flutter pub get
```

---

## 📱 **رفع التطبيق لـ App Store:**

### **الخطوة 1: إنشاء App في App Store Connect**

1. **اذهب إلى:** https://appstoreconnect.apple.com
2. **انقر:** "My Apps" → "+"
3. **املأ البيانات:**
   ```
   Name: منتجاتي - Montajati
   Bundle ID: com.montajati.app
   SKU: montajati-app-2025
   ```

### **الخطوة 2: رفع IPA**

```bash
# رفع عبر Xcode
# أو استخدام Transporter app
# أو Application Loader
```

### **الخطوة 3: إعداد معلومات التطبيق**

- **الوصف:** وصف شامل للتطبيق
- **الكلمات المفتاحية:** منتجات، توصيل، عراق
- **الفئة:** Business أو Shopping
- **الصور:** Screenshots للتطبيق
- **أيقونة:** 1024x1024 px

---

## ✅ **التحقق النهائي:**

- [ ] الشهادات مثبتة
- [ ] Provisioning Profile صحيح
- [ ] Bundle ID متطابق
- [ ] Firebase مُهيأ
- [ ] الأيقونات موجودة
- [ ] الأذونات صحيحة
- [ ] التطبيق يعمل على الجهاز
- [ ] IPA تم إنشاؤه بنجاح

---

## 📞 **الدعم:**

إذا واجهت أي مشاكل:
1. تحقق من logs في Xcode
2. راجع Apple Developer Documentation
3. تأكد من صحة الشهادات
4. جرب إعادة بناء المشروع

**ملاحظة:** تصدير iOS يتطلب جهاز Mac وحساب Apple Developer مدفوع.
