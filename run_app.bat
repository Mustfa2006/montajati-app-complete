@echo off
echo 🚀 ===== تشغيل تطبيق منتجاتي =====
echo.

:: الانتقال لمجلد المشروع
cd /d "C:\Users\Mustafa\Desktop\montajati\frontend"
echo 📁 المجلد الحالي: %CD%
echo.

:: التحقق من وجود Flutter
echo 🔍 التحقق من Flutter...
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter غير مثبت أو غير موجود في PATH
    echo 💡 يرجى تثبيت Flutter من: https://flutter.dev/docs/get-started/install/windows
    pause
    exit /b 1
)
echo ✅ Flutter موجود
echo.

:: التحقق من الأجهزة المتصلة
echo 📱 التحقق من الأجهزة المتصلة...
flutter devices
echo.

:: تحديث التبعيات
echo 📦 تحديث التبعيات...
flutter pub get
echo.

:: تشغيل التطبيق
echo 🚀 تشغيل التطبيق...
echo 💡 للوصول للوحة التحكم:
echo    📧 البريد: admin@montajati.com
echo    🔑 كلمة المرور: admin123
echo.
echo 🔄 بدء التشغيل...
flutter run --hot

pause
