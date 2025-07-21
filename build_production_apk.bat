@echo off
chcp 65001 >nul
echo.
echo ===================================
echo 🚀 تصدير تطبيق منتجاتي للإنتاج
echo ===================================
echo.

:: التحقق من Flutter
where flutter >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter غير مثبت أو غير موجود في PATH
    echo يرجى تثبيت Flutter أولاً: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

echo ✅ Flutter متوفر
flutter --version
echo.

:: الانتقال إلى مجلد Frontend
if not exist "frontend" (
    echo ❌ مجلد frontend غير موجود
    echo تأكد من تشغيل السكريبت من المجلد الرئيسي للمشروع
    pause
    exit /b 1
)

cd frontend
echo 📁 الانتقال إلى مجلد frontend
echo.

:: تنظيف المشروع
echo 🧹 تنظيف المشروع...
flutter clean
if %errorlevel% neq 0 (
    echo ❌ فشل في تنظيف المشروع
    pause
    exit /b 1
)
echo ✅ تم تنظيف المشروع
echo.

:: تحديث التبعيات
echo 📦 تحديث التبعيات...
flutter pub get
if %errorlevel% neq 0 (
    echo ❌ فشل في تحديث التبعيات
    pause
    exit /b 1
)
echo ✅ تم تحديث التبعيات
echo.

:: فحص المشروع
echo 🔍 فحص المشروع...
flutter analyze --no-fatal-infos
if %errorlevel% neq 0 (
    echo ⚠️ توجد تحذيرات في الكود، لكن سنتابع البناء
)
echo.

:: بناء APK للإنتاج
echo 🔨 بناء APK للإنتاج...
echo هذا قد يستغرق عدة دقائق...
echo.

flutter build apk --release --verbose
if %errorlevel% neq 0 (
    echo ❌ فشل في بناء APK
    echo تحقق من الأخطاء أعلاه
    pause
    exit /b 1
)

echo.
echo ✅ تم بناء APK بنجاح!
echo.

:: بناء App Bundle للـ Play Store
echo 🔨 بناء App Bundle للـ Play Store...
flutter build appbundle --release --verbose
if %errorlevel% neq 0 (
    echo ❌ فشل في بناء App Bundle
    echo لكن APK جاهز للاستخدام
) else (
    echo ✅ تم بناء App Bundle بنجاح!
)

echo.
echo ===================================
echo 🎉 تم تصدير التطبيق بنجاح!
echo ===================================
echo.

:: عرض معلومات الملفات
echo 📋 الملفات المُصدرة:
echo.

if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo ✅ APK للتوزيع المباشر:
    echo    📍 frontend\build\app\outputs\flutter-apk\app-release.apk
    for %%A in ("build\app\outputs\flutter-apk\app-release.apk") do echo    📊 الحجم: %%~zA bytes
    echo.
)

if exist "build\app\outputs\bundle\release\app-release.aab" (
    echo ✅ App Bundle للـ Play Store:
    echo    📍 frontend\build\app\outputs\bundle\release\app-release.aab
    for %%A in ("build\app\outputs\bundle\release\app-release.aab") do echo    📊 الحجم: %%~zA bytes
    echo.
)

:: معلومات التطبيق
echo 📱 معلومات التطبيق:
echo    🏷️ اسم التطبيق: منتجاتي
echo    📦 Package ID: com.montajati.app
echo    🔢 إصدار: 2.1.0 (Build 7)
echo    🎯 Target SDK: Android 15 (API 35)
echo    📱 Min SDK: Android 5.0 (API 21)
echo.

:: تعليمات التثبيت
echo 📋 تعليمات التثبيت:
echo.
echo 🔧 للتثبيت على جهاز Android:
echo    1. انسخ ملف app-release.apk إلى الجهاز
echo    2. فعّل "مصادر غير معروفة" في إعدادات الأمان
echo    3. اضغط على الملف لتثبيته
echo.
echo 🏪 للنشر على Google Play Store:
echo    1. استخدم ملف app-release.aab
echo    2. ارفعه إلى Google Play Console
echo    3. اتبع خطوات النشر في المتجر
echo.

:: فتح مجلد الملفات
echo 📂 فتح مجلد الملفات...
if exist "build\app\outputs\flutter-apk\" (
    start "" "build\app\outputs\flutter-apk\"
)

echo.
echo 🚀 التطبيق جاهز للنشر!
echo.
pause
