# 🔥 إعداد Firebase للإنتاج - دليل شامل

## 🎯 الهدف
إعداد Firebase بشكل صحيح لجعل الإشعارات تعمل في التطبيق المُصدر

---

## 📋 الخطوات المطلوبة

### 1️⃣ إعداد Firebase Console

#### أ) إنشاء Android App:
1. اذهب إلى [Firebase Console](https://console.firebase.google.com/)
2. اختر مشروع `montajati-app-7767d`
3. اضغط "Add app" → اختر Android
4. املأ البيانات:
   ```
   Android package name: com.montajati.app
   App nickname: Montajati Android
   Debug signing certificate SHA-1: [سيتم الحصول عليه لاحقاً]
   ```
5. اضغط "Register app"
6. **حمل ملف `google-services.json`**
7. ضع الملف في: `android/app/google-services.json`

#### ب) إنشاء iOS App:
1. في نفس المشروع، اضغط "Add app" → اختر iOS
2. املأ البيانات:
   ```
   iOS bundle ID: com.montajati.app
   App nickname: Montajati iOS
   App Store ID: [اتركه فارغ الآن]
   ```
3. اضغط "Register app"
4. **حمل ملف `GoogleService-Info.plist`**
5. ضع الملف في: `ios/Runner/GoogleService-Info.plist`

---

### 2️⃣ الحصول على SHA Fingerprints (Android)

#### للتطوير (Debug):
```bash
cd android
./gradlew signingReport
```
أو:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

#### للإنتاج (Release):
```bash
keytool -list -v -keystore path/to/your/release.keystore -alias your-alias
```

**انسخ SHA1 وأضفه في Firebase Console:**
1. اذهب إلى Project Settings
2. اختر Android App
3. اضغط "Add fingerprint"
4. الصق SHA1

---

### 3️⃣ تحديث firebase_options.dart

بعد إنشاء Apps، ستحصل على App IDs الحقيقية:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyAyJztyuQ_t_ZIftJVwi_rXr9zHkvy2P1Y',
  appId: '1:684581846709:android:REAL_ANDROID_APP_ID_HERE',
  messagingSenderId: '684581846709',
  projectId: 'montajati-app-7767d',
  storageBucket: 'montajati-app-7767d.firebasestorage.app',
);

static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'AIzaSyAyJztyuQ_t_ZIftJVwi_rXr9zHkvy2P1Y',
  appId: '1:684581846709:ios:REAL_IOS_APP_ID_HERE',
  messagingSenderId: '684581846709',
  projectId: 'montajati-app-7767d',
  storageBucket: 'montajati-app-7767d.firebasestorage.app',
  iosBundleId: 'com.montajati.app',
);
```

---

### 4️⃣ تحديث إعدادات Android

#### أ) android/app/build.gradle:
تأكد من وجود:
```gradle
apply plugin: 'com.google.gms.google-services'

dependencies {
    implementation 'com.google.firebase:firebase-messaging:23.4.0'
    implementation 'com.google.firebase:firebase-analytics:21.5.0'
}
```

#### ب) android/build.gradle:
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
}
```

#### ج) android/app/src/main/AndroidManifest.xml:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.VIBRATE" />

<application android:name=".MainApplication">
    <service
        android:name=".MyFirebaseMessagingService"
        android:exported="false">
        <intent-filter>
            <action android:name="com.google.firebase.MESSAGING_EVENT" />
        </intent-filter>
    </service>
</application>
```

---

### 5️⃣ تحديث إعدادات iOS

#### أ) ios/Runner/Info.plist:
تأكد من وجود:
```xml
<key>CFBundleIdentifier</key>
<string>com.montajati.app</string>
```

#### ب) تفعيل Push Notifications:
1. افتح `ios/Runner.xcworkspace` في Xcode
2. اختر Target "Runner"
3. اذهب إلى "Signing & Capabilities"
4. اضغط "+ Capability"
5. أضف "Push Notifications"
6. أضف "Background Modes" واختر "Background processing"

---

### 6️⃣ اختبار الإعداد

#### أ) تنظيف وإعادة البناء:
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter build apk --debug
```

#### ب) اختبار على جهاز حقيقي:
```bash
flutter run --debug
```

#### ج) فحص FCM Token:
في التطبيق، تأكد من ظهور FCM Token في logs

---

## 🔍 التحقق من النجاح

### ✅ علامات النجاح:
1. التطبيق يحصل على FCM Token
2. Token يتم حفظه في قاعدة البيانات
3. الإشعارات تصل للجهاز
4. لا توجد أخطاء Firebase في logs

### ❌ علامات المشاكل:
1. "Firebase app not initialized"
2. "FCM Token is null"
3. "Default FirebaseApp is not initialized"
4. "Registration token not registered"

---

## 🚀 خطوات التصدير النهائية

### 1️⃣ بناء APK للإنتاج:
```bash
flutter build apk --release
```

### 2️⃣ بناء App Bundle:
```bash
flutter build appbundle --release
```

### 3️⃣ بناء iOS:
```bash
flutter build ios --release
```

### 4️⃣ اختبار نهائي:
- اختبر على أجهزة مختلفة
- اختبر الإشعارات مع التطبيق مفتوح/مغلق
- اختبر على شبكات مختلفة

---

## 📞 استكشاف الأخطاء

### مشكلة: "App not found"
**الحل:** تأكد من Package Name/Bundle ID في Firebase

### مشكلة: "Invalid API Key"
**الحل:** تأكد من تحديث firebase_options.dart

### مشكلة: "Token registration failed"
**الحل:** تأكد من SHA fingerprints في Firebase

---

## ⚠️ تحذيرات مهمة

1. **لا تشارك ملفات:**
   - `google-services.json`
   - `GoogleService-Info.plist`
   - Release keystores

2. **اختبر دائماً على أجهزة حقيقية**
   - المحاكيات قد لا تدعم FCM بشكل كامل

3. **احتفظ بنسخ احتياطية:**
   - من keystores
   - من ملفات Firebase
   - من إعدادات Firebase Console

---

*آخر تحديث: 2024-12-20*
