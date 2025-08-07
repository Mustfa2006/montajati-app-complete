@echo off
echo ========================================
echo بناء تطبيق منتجاتي APK
echo Building Montajati APK
echo ========================================

cd frontend

echo.
echo 🧹 تنظيف المشروع...
flutter clean

echo.
echo 📦 تحديث التبعيات...
flutter pub get

echo.
echo 🔨 بناء الملفات المولدة...
flutter pub run build_runner build --delete-conflicting-outputs

echo.
echo 📱 بناء APK للإنتاج...
flutter build apk --release

echo.
echo 📱 بناء APK مقسم حسب المعمارية...
flutter build apk --split-per-abi --release

echo.
echo 📦 بناء App Bundle...
flutter build appbundle --release

echo.
echo ✅ تم بناء جميع الملفات بنجاح!
echo.
echo 📁 مواقع الملفات:
echo    APK عام: build\app\outputs\flutter-apk\app-release.apk
echo    APK ARM64: build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
echo    APK ARM32: build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk
echo    App Bundle: build\app\outputs\bundle\release\app-release.aab
echo.

echo 📊 أحجام الملفات:
for %%f in (build\app\outputs\flutter-apk\*.apk) do (
    echo    %%~nxf: %%~zf bytes
)

echo.
echo 🎉 تم الانتهاء من بناء التطبيق!
pause
