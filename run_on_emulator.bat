@echo off
echo ========================================
echo تشغيل تطبيق منتجاتي على المحاكي
echo Running Montajati App on Emulator
echo ========================================

cd frontend

echo.
echo 🔍 فحص الأجهزة المتاحة...
flutter devices

echo.
echo 📱 فحص المحاكيات المتاحة...
flutter emulators

echo.
echo 🚀 تشغيل المحاكي إذا لم يكن يعمل...
flutter emulators --launch Medium_Phone_API_36.0

echo.
echo ⏳ انتظار 30 ثانية لتشغيل المحاكي...
timeout /t 30 /nobreak

echo.
echo 🔍 فحص الأجهزة مرة أخرى...
flutter devices

echo.
echo 🧹 تنظيف المشروع...
flutter clean

echo.
echo 📦 تحديث التبعيات...
flutter pub get

echo.
echo 🚀 تشغيل التطبيق على المحاكي...
flutter run

echo.
echo ✅ تم تشغيل التطبيق!
pause
