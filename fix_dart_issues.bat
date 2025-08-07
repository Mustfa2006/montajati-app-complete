@echo off
echo ========================================
echo حل مشاكل Dart Analyzer
echo Fixing Dart Analyzer Issues
echo ========================================

cd frontend

echo.
echo 🔍 فحص المشاكل الحالية...
flutter analyze

echo.
echo 🧹 تنظيف المشروع...
flutter clean

echo.
echo 📦 تحديث التبعيات...
flutter pub get

echo.
echo 🔧 تشغيل build_runner لحل مشاكل الكود المولد...
flutter pub run build_runner build --delete-conflicting-outputs

echo.
echo 🔍 فحص المشاكل بعد الإصلاح...
flutter analyze

echo.
echo ✅ تم الانتهاء من إصلاح مشاكل Dart!
echo.
echo 📋 إذا كانت هناك مشاكل متبقية:
echo    1. تحقق من الاستيرادات غير المستخدمة
echo    2. احذف المتغيرات غير المستخدمة
echo    3. استخدم BuildContext.mounted قبل استخدام context
echo    4. استبدل WillPopScope بـ PopScope
echo    5. استخدم super parameters في constructors
echo.

pause
