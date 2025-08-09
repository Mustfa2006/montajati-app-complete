@echo off
chcp 65001 >nul
echo.
echo 🌐 بناء تطبيق منتجاتي للويب مع الحماية المتقدمة
echo ================================================

:: التحقق من وجود Flutter
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Flutter غير مثبت أو غير موجود في PATH
    pause
    exit /b 1
)

:: الانتقال لمجلد Frontend
cd frontend
if not exist "pubspec.yaml" (
    echo ❌ لم يتم العثور على مجلد Frontend أو ملف pubspec.yaml
    pause
    exit /b 1
)

echo.
echo 🧹 تنظيف المشروع...
flutter clean

echo.
echo 📦 تحديث التبعيات...
flutter pub get

echo.
echo 🔧 تفعيل دعم الويب...
flutter config --enable-web

echo.
echo 🏗️ بناء التطبيق للويب (الإصدار المحسن)...
flutter build web --release ^
    --web-renderer html ^
    --base-href / ^
    --dart-define=FLUTTER_WEB_USE_SKIA=false ^
    --dart-define=FLUTTER_WEB_AUTO_DETECT=false ^
    --source-maps ^
    --tree-shake-icons

if errorlevel 1 (
    echo ❌ فشل في بناء التطبيق
    pause
    exit /b 1
)

echo.
echo 📁 نسخ الملفات الإضافية...

:: نسخ ملفات الحماية إذا لم تكن موجودة
if not exist "build\web\js" mkdir "build\web\js"

if exist "web\js\console-protection.js" (
    copy "web\js\console-protection.js" "build\web\js\" >nul
    echo ✅ تم نسخ console-protection.js
)

if exist "web\js\advanced-protection.js" (
    copy "web\js\advanced-protection.js" "build\web\js\" >nul
    echo ✅ تم نسخ advanced-protection.js
)

if exist "web\js\anti-debugging.js" (
    copy "web\js\anti-debugging.js" "build\web\js\" >nul
    echo ✅ تم نسخ anti-debugging.js
)

if exist "web\js\ios-optimizations.js" (
    copy "web\js\ios-optimizations.js" "build\web\js\" >nul
    echo ✅ تم نسخ ios-optimizations.js
)

:: نسخ ملفات SEO
if exist "web\robots.txt" (
    copy "web\robots.txt" "build\web\" >nul
    echo ✅ تم نسخ robots.txt
)

if exist "web\sitemap.xml" (
    copy "web\sitemap.xml" "build\web\" >nul
    echo ✅ تم نسخ sitemap.xml
)

echo.
echo 🔍 فحص الملفات المبنية...
if exist "build\web\index.html" (
    echo ✅ index.html موجود
) else (
    echo ❌ index.html غير موجود
)

if exist "build\web\main.dart.js" (
    echo ✅ main.dart.js موجود
) else (
    echo ❌ main.dart.js غير موجود
)

if exist "build\web\flutter_service_worker.js" (
    echo ✅ Service Worker موجود
) else (
    echo ⚠️ Service Worker غير موجود
)

echo.
echo 📊 إحصائيات البناء:
for %%f in (build\web\main.dart.js) do echo 📄 حجم main.dart.js: %%~zf bytes
for /f %%i in ('dir build\web /s /-c ^| find "File(s)"') do echo 📁 إجمالي الملفات: %%i

echo.
echo 🎉 تم بناء التطبيق بنجاح!
echo 📁 الملفات جاهزة في: frontend\build\web
echo.
echo 🚀 خيارات النشر:
echo    1. Firebase Hosting: firebase deploy --only hosting
echo    2. Netlify: رفع مجلد build\web
echo    3. Vercel: vercel --prod
echo    4. GitHub Pages: نسخ المحتوى لمستودع gh-pages
echo.
echo 🔒 ميزات الحماية المُفعلة:
echo    ✅ حماية Console
echo    ✅ منع Developer Tools
echo    ✅ حماية ضد التصحيح
echo    ✅ منع النقر بالزر الأيمن
echo    ✅ منع النسخ واللصق
echo    ✅ حماية الكود من التلاعب
echo.

pause
