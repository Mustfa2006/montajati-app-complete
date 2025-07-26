@echo off
echo ========================================
echo    تصدير تطبيق منتجاتي - الإصدار النهائي
echo ========================================
echo.

echo 🎯 الإصدار الجديد: 3.2.0+9
echo 🔧 التحديثات المضافة:
echo    ✅ إصلاح عرض معرف الوسيط في تفاصيل الطلب
echo    ✅ إضافة زر فتح رابط الوسيط مباشرة
echo    ✅ تحسين واجهة عرض حالة الوسيط
echo    ✅ إصلاح مشكلة عدم ظهور QR ID
echo    ✅ تحسين نظام إرسال الطلبات للوسيط
echo.

echo 📱 بدء عملية التصدير...
echo.

cd frontend

echo 🧹 تنظيف المشروع...
call flutter clean
if %errorlevel% neq 0 (
    echo ❌ فشل في تنظيف المشروع
    pause
    exit /b 1
)

echo 📦 تحديث التبعيات...
call flutter pub get
if %errorlevel% neq 0 (
    echo ❌ فشل في تحديث التبعيات
    pause
    exit /b 1
)

echo 🔍 فحص المشروع...
call flutter analyze
if %errorlevel% neq 0 (
    echo ⚠️ تحذير: هناك مشاكل في التحليل، لكن سنكمل التصدير
)

echo 🏗️ بناء APK للإنتاج...
call flutter build apk --release --target-platform android-arm,android-arm64,android-x64
if %errorlevel% neq 0 (
    echo ❌ فشل في بناء APK
    pause
    exit /b 1
)

echo 🏗️ بناء App Bundle للنشر على Google Play...
call flutter build appbundle --release
if %errorlevel% neq 0 (
    echo ❌ فشل في بناء App Bundle
    pause
    exit /b 1
)

echo.
echo ✅ تم تصدير التطبيق بنجاح!
echo.
echo 📁 ملفات التصدير:
echo    📱 APK: frontend\build\app\outputs\flutter-apk\app-release.apk
echo    📦 AAB: frontend\build\app\outputs\bundle\release\app-release.aab
echo.

echo 📊 معلومات الإصدار:
echo    🏷️ الإصدار: 3.2.0+9
echo    📅 تاريخ البناء: %date% %time%
echo    🔧 نوع البناء: Release
echo    🎯 المنصات: Android ARM, ARM64, x64
echo.

echo 🚀 التطبيق جاهز للنشر!
echo.

echo 📋 خطوات النشر:
echo    1. ارفع ملف AAB إلى Google Play Console
echo    2. أو شارك ملف APK مباشرة مع المستخدمين
echo    3. تأكد من تحديث رقم الإصدار في المتجر
echo.

echo 🎉 تم الانتهاء من عملية التصدير بنجاح!
pause
