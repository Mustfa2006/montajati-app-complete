@echo off
echo ========================================
echo حل مشكلة تراخيص Android
echo Fixing Android Licenses
echo ========================================

echo.
echo 📋 قبول جميع تراخيص Android...
echo سيتم قبول جميع التراخيص تلقائياً...

echo y | flutter doctor --android-licenses

echo.
echo ✅ تم قبول التراخيص!

echo.
echo 🔍 فحص Flutter Doctor مرة أخرى...
flutter doctor

echo.
echo 🎉 تم حل المشكلة!
pause
