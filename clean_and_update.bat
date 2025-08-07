@echo off
echo ========================================
echo تنظيف وتحديث مشروع منتجاتي
echo Cleaning and Updating Montajati Project
echo ========================================

echo.
echo 🧹 تنظيف مجلد Frontend...
cd frontend

echo.
echo 🔧 إصلاح إعدادات Git...
git config --global --add safe.directory C:/flutter

echo.
echo 🧹 تنظيف Flutter...
flutter clean

echo.
echo 📦 تحديث التبعيات...
flutter pub get

echo.
echo 🔨 بناء الملفات المولدة...
flutter pub run build_runner build --delete-conflicting-outputs

echo.
echo ✅ تم الانتهاء من تنظيف Frontend!

echo.
echo 🧹 تنظيف مجلد Backend...
cd ../backend

echo.
echo 📦 تحديث تبعيات Node.js...
npm install

echo.
echo 🧹 تنظيف cache...
npm cache clean --force

echo.
echo ✅ تم الانتهاء من تنظيف Backend!

echo.
echo 🎉 تم تنظيف وتحديث المشروع بالكامل!
echo.
echo 📱 لتشغيل التطبيق:
echo    cd frontend
echo    flutter run
echo.
echo 🖥️ لتشغيل الخادم:
echo    cd backend
echo    npm start
echo.

pause
