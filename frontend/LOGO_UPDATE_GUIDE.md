# 🎨 دليل تحديث شعار التطبيق "منتجاتي"

## 📋 الخطوات المطلوبة

### 1️⃣ **إضافة الصورة الجديدة**
```bash
# احفظ الصورة التي أرسلتها في:
frontend/assets/images/app_logo.png
```

**متطلبات الصورة:**
- ✅ الصيغة: PNG
- ✅ الدقة: 1024x1024 بكسل (على الأقل)
- ✅ الخلفية: شفافة أو متطابقة مع ألوان التطبيق
- ✅ المحتوى: النص العربي "منتجاتي" مع التاج الذهبي

### 2️⃣ **تثبيت الحزم المطلوبة**
```bash
cd frontend
flutter pub get
```

### 3️⃣ **توليد الأيقونات**
```bash
flutter pub run flutter_launcher_icons:main
```

### 4️⃣ **إعادة بناء التطبيق**
```bash
# للأندرويد
flutter build apk --release

# للـ iOS (إذا كان متاحاً)
flutter build ios --release

# للويب
flutter build web --release
```

## 🎯 الأماكن التي ستتغير

### ✅ **تم التحديث تلقائياً:**
- أيقونة التطبيق على الشاشة الرئيسية
- أيقونة التطبيق في قائمة التطبيقات
- أيقونة الإشعارات (محدثة للون الذهبي)
- أيقونة التطبيق على الويب
- ملف manifest.json (محدث بالألوان الجديدة)

### 📱 **الملفات المحدثة:**
- `pubspec.yaml` - إضافة إعدادات flutter_launcher_icons
- `web/manifest.json` - تحديث الألوان والأسماء
- `android/app/src/main/res/drawable/ic_notification.xml` - أيقونة إشعارات ذهبية

## 🎨 **الألوان المستخدمة:**

```css
/* الألوان الجديدة */
الخلفية الرئيسية: #1a1a2e (أزرق داكن)
اللون الذهبي: #ffd700 (ذهبي)
اللون الثانوي: #16213e (أزرق متوسط)
```

## 🔧 **إعدادات flutter_launcher_icons:**

```yaml
flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/images/app_logo.png"
  min_sdk_android: 21
  web:
    generate: true
    image_path: "assets/images/app_logo.png"
    background_color: "#1a1a2e"
    theme_color: "#ffd700"
  windows:
    generate: true
    image_path: "assets/images/app_logo.png"
    icon_size: 48
  macos:
    generate: true
    image_path: "assets/images/app_logo.png"
```

## ⚠️ **ملاحظات مهمة:**

1. **بعد توليد الأيقونات:** ستحتاج لإعادة تثبيت التطبيق لرؤية التغييرات
2. **الإشعارات:** ستظهر بالأيقونة الجديدة تلقائياً
3. **الويب:** ستحتاج لمسح cache المتصفح لرؤية الأيقونة الجديدة
4. **iOS:** قد تحتاج لإعادة بناء المشروع في Xcode

## 🚀 **الخطوة التالية:**

بعد إضافة الصورة، قم بتشغيل:
```bash
flutter pub run flutter_launcher_icons:main
flutter clean
flutter build apk --release
```

سيصبح شعار "منتجاتي" مع التاج الذهبي هو الأيقونة الرسمية للتطبيق في كل مكان! 🎉
