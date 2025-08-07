@echo off
echo ========================================
echo تشغيل سريع لتطبيق منتجاتي
echo Quick Run Montajati App
echo ========================================

cd frontend

echo.
echo 📦 تحديث التبعيات...
flutter pub get

echo.
echo 🔍 فحص الأجهزة المتصلة...
flutter devices

echo.
echo 🚀 تشغيل التطبيق...
flutter run

pause
