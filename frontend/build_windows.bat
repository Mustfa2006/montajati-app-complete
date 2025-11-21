@echo off
echo ===================================
echo بناء تطبيق منتجاتي للويندوز
echo Building Montajati App for Windows
echo ===================================

echo.
echo 🔧 تنظيف المشروع...
echo Cleaning project...
flutter clean

echo.
echo 📦 تحديث الحزم...
echo Getting dependencies...
flutter pub get

echo.
echo 🏗️ بناء التطبيق للويندوز...
echo Building Windows app...
flutter build windows --release

echo.
echo 📁 إنشاء مجلد التوزيع...
echo Creating distribution folder...
if not exist "dist" mkdir dist
if not exist "dist\montajati_windows" mkdir dist\montajati_windows

echo.
echo 📋 نسخ الملفات...
echo Copying files...
xcopy "build\windows\x64\runner\Release\*" "dist\montajati_windows\" /E /I /Y

echo.
echo 📝 إنشاء ملف README...
echo Creating README file...
(
echo تطبيق منتجاتي - إصدار ويندوز
echo ============================
echo.
echo تعليمات التشغيل:
echo 1. تأكد من اتصالك بالإنترنت
echo 2. قم بتشغيل ملف montajati_app.exe
echo 3. استمتع بتجربة التسوق!
echo.
echo متطلبات النظام:
echo - ويندوز 10 أو أحدث
echo - اتصال بالإنترنت
echo.
echo للدعم الفني:
echo البريد الإلكتروني: support@montajati.com
echo الموقع: https://montajati.com
echo.
echo إصدار التطبيق: 3.3.0
echo تاريخ البناء: %date% %time%
) > "dist\montajati_windows\README.txt"

echo.
echo ✅ تم بناء التطبيق بنجاح!
echo Build completed successfully!
echo.
echo 📍 مسار التطبيق: dist\montajati_windows\
echo App location: dist\montajati_windows\
echo.
echo 🚀 يمكنك الآن توزيع مجلد montajati_windows
echo You can now distribute the montajati_windows folder
echo.
pause
