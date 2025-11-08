# 🚨 إصلاح عاجل لـ Firebase - خطوات سريعة

## 🎯 المشكلة
App IDs في Firebase مؤقتة، مما يعني أن الإشعارات لن تعمل في التطبيق المُصدر.

## ⚡ الحل السريع (15 دقيقة)

### 1️⃣ إنشاء Android App في Firebase Console

1. **اذهب إلى:** https://console.firebase.google.com/project/montajati-app-7767d
2. **اضغط:** "Add app" → اختر Android 📱
3. **املأ البيانات:**
   ```
   Android package name: com.montajati.app
   App nickname: Montajati Android App
   Debug signing certificate SHA-1: [اتركه فارغ الآن]
   ```
4. **اضغط:** "Register app"
5. **حمل:** ملف `google-services.json` الجديد
6. **استبدل:** الملف في `frontend/android/app/google-services.json`

### 2️⃣ إنشاء iOS App في Firebase Console

1. **في نفس المشروع، اضغط:** "Add app" → اختر iOS 🍎
2. **املأ البيانات:**
   ```
   iOS bundle ID: com.montajati.app
   App nickname: Montajati iOS App
   App Store ID: [اتركه فارغ]
   ```
3. **اضغط:** "Register app"
4. **حمل:** ملف `GoogleService-Info.plist`
5. **ضع الملف في:** `frontend/ios/Runner/GoogleService-Info.plist`

### 3️⃣ تحديث firebase_options.dart

بعد إنشاء Apps، ستحصل على App IDs الحقيقية من Firebase Console:

1. **اذهب إلى:** Project Settings → General
2. **انسخ App IDs الجديدة:**
   - Android: `1:684581846709:android:REAL_ID_HERE`
   - iOS: `1:684581846709:ios:REAL_ID_HERE`

3. **حدث الملف:**
```dart
// في frontend/lib/firebase_options.dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyAyJztyuQ_t_ZIftJVwi_rXr9zHkvy2P1Y',
  appId: '1:684581846709:android:REAL_ANDROID_ID_HERE', // 🔄 حدث هذا
  messagingSenderId: '684581846709',
  projectId: 'montajati-app-7767d',
  storageBucket: 'montajati-app-7767d.firebasestorage.app',
);

static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'AIzaSyAyJztyuQ_t_ZIftJVwi_rXr9zHkvy2P1Y',
  appId: '1:684581846709:ios:REAL_IOS_ID_HERE', // 🔄 حدث هذا
  messagingSenderId: '684581846709',
  projectId: 'montajati-app-7767d',
  storageBucket: 'montajati-app-7767d.firebasestorage.app',
  iosBundleId: 'com.montajati.app',
);
```

### 4️⃣ اختبار سريع

```bash
cd frontend
flutter clean
flutter pub get
flutter run --debug
```

**تحقق من:**
- ظهور FCM Token في logs
- عدم وجود أخطاء Firebase
- إمكانية إرسال إشعار تجريبي

---

## 🔍 كيفية الحصول على App IDs الحقيقية

### من Firebase Console:
1. اذهب إلى Project Settings
2. اختر تبويب "General"
3. ستجد قائمة "Your apps"
4. انسخ App ID لكل منصة

### مثال على App IDs الحقيقية:
```
Android: 1:684581846709:android:a1b2c3d4e5f6g7h8
iOS: 1:684581846709:ios:h8g7f6e5d4c3b2a1
```

---

## ✅ علامات النجاح

بعد الإصلاح، يجب أن ترى:

### في التطبيق:
- ✅ FCM Token يظهر في logs
- ✅ لا توجد أخطاء Firebase
- ✅ الإشعارات تصل للجهاز

### في Firebase Console:
- ✅ Apps تظهر في Project Settings
- ✅ Cloud Messaging مفعل
- ✅ إحصائيات الإرسال تظهر

### في Backend:
```bash
npm run test:notification send +966500000000
```
يجب أن يعمل بنجاح!

---

## 🚨 تحذيرات مهمة

1. **لا تنس تحديث firebase_options.dart** - هذا الأهم!
2. **اختبر على جهاز حقيقي** - ليس محاكي
3. **احتفظ بنسخة من الملفات الجديدة**

---

## 📞 إذا واجهت مشاكل

### مشكلة: "App not found"
- تأكد من Package Name: `com.montajati.app`
- تأكد من Bundle ID: `com.montajati.app`

### مشكلة: "Invalid API Key"
- تأكد من تحديث firebase_options.dart
- تأكد من استخدام App IDs الحقيقية

### مشكلة: "Token registration failed"
- أضف SHA fingerprints في Firebase Console
- اختبر على جهاز حقيقي

---

## ⏰ الوقت المتوقع
- إنشاء Apps: 5 دقائق
- تحديث الملفات: 5 دقائق  
- الاختبار: 5 دقائق
- **المجموع: 15 دقيقة**

بعد هذا الإصلاح، ستعمل الإشعارات في التطبيق المُصدر! 🎉
