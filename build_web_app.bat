@echo off
echo ========================================
echo 🌐 بناء موقع منتجاتي
echo Building Montajati Web App
echo ========================================

cd frontend

echo.
echo 🧹 تنظيف شامل...
flutter clean

echo.
echo 🗑️ حذف Flutter Cache...
if exist "C:\Users\muu\AppData\Local\Pub\Cache" (
    echo حذف: Flutter Pub Cache
    rmdir /s /q "C:\Users\muu\AppData\Local\Pub\Cache" 2>nul
)

echo.
echo 📦 تحديث التبعيات...
flutter pub get

echo.
echo 🔍 فحص المشاكل...
flutter analyze --no-pub

echo.
echo 🌐 بناء الموقع...
flutter build web --release --web-renderer canvaskit

echo.
echo ✅ تم بناء الموقع بنجاح!
echo 📁 الملفات في: build\web\
echo.
echo 🚀 لتشغيل الموقع محلياً:
echo    cd build\web
echo    python -m http.server 8000
echo    أو
echo    flutter run -d chrome --release

pause
