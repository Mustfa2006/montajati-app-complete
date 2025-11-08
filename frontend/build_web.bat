@echo off
echo ========================================
echo 🌐 بناء موقع منتجاتي للويب
echo ========================================
echo.

echo 📋 التحقق من Flutter...
flutter --version
if %errorlevel% neq 0 (
    echo ❌ Flutter غير مثبت أو غير موجود في PATH
    pause
    exit /b 1
)

echo.
echo 🧹 تنظيف البناء السابق...
flutter clean

echo.
echo 📦 جلب التبعيات...
flutter pub get

echo.
echo 🌐 بناء الموقع للإنتاج...
flutter build web --release --web-renderer html --base-href "/"

echo.
echo ✅ تم بناء الموقع بنجاح!
echo 📁 الملفات موجودة في: build\web
echo.

echo 📊 حجم الملفات:
dir build\web /s /-c | find "File(s)"

echo.
echo 🚀 خيارات النشر:
echo 1. Netlify: اسحب مجلد build\web إلى netlify.com
echo 2. Vercel: اربط المشروع مع vercel.com  
echo 3. Firebase: استخدم firebase deploy
echo.

echo 🔍 لاختبار الموقع محلياً:
echo flutter run -d chrome --web-port 8080
echo ثم اذهب إلى: http://localhost:8080
echo.

echo 📱 للاختبار على الهاتف:
echo 1. شغل: flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0
echo 2. اذهب إلى: http://[عنوان-الكمبيوتر]:8080 من الهاتف
echo.

echo ✅ انتهى البناء بنجاح!
pause
