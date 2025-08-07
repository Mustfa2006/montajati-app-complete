@echo off
echo ========================================
echo 🔧 حل مشكلة Gradle Cache
echo Fixing Gradle Cache Issues
echo ========================================

echo.
echo 🛑 إيقاف جميع عمليات Gradle...
taskkill /f /im java.exe 2>nul
taskkill /f /im gradle.exe 2>nul
taskkill /f /im flutter.exe 2>nul

echo.
echo 🧹 تنظيف Gradle Cache العام...
if exist "C:\Users\muu\.gradle\caches" (
    echo حذف: C:\Users\muu\.gradle\caches
    rmdir /s /q "C:\Users\muu\.gradle\caches" 2>nul
)

echo.
echo 🧹 تنظيف Flutter Cache...
if exist "C:\Users\muu\AppData\Local\Pub\Cache" (
    echo حذف: Flutter Pub Cache
    rmdir /s /q "C:\Users\muu\AppData\Local\Pub\Cache" 2>nul
)

echo.
echo 🧹 تنظيف مجلدات المشروع...
cd frontend

if exist "build" (
    echo حذف: build
    rmdir /s /q "build" 2>nul
)

if exist ".dart_tool" (
    echo حذف: .dart_tool
    rmdir /s /q ".dart_tool" 2>nul
)

if exist "android\.gradle" (
    echo حذف: android\.gradle
    rmdir /s /q "android\.gradle" 2>nul
)

if exist "android\app\build" (
    echo حذف: android\app\build
    rmdir /s /q "android\app\build" 2>nul
)

echo.
echo 📦 إعادة تحميل التبعيات...
flutter pub get

echo.
echo 🔍 فحص الأجهزة المتصلة...
flutter devices

echo.
echo 🚀 تشغيل التطبيق...
echo سيتم تحميل جميع التبعيات من جديد (قد يستغرق وقتاً)...
flutter run -d emulator-5554 --hot

pause
